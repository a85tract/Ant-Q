/*
 * bench_early_stop.c
 *
 * Microbenchmark for the early-stop kernel that decides whether to halt
 * a noisy quantum-circuit execution based on Total Variation Distance
 * (TVD) and Hellinger Fidelity (HF) versus a reference distribution.
 *
 * Two timed kernels are reported per circuit:
 *
 *   (1) checkpoint_full   --  one full checkpoint update:
 *         a. consume the new batch of shot bitstrings
 *         b. update cumulative counts
 *         c. normalise to probabilities
 *         d. compute TVD and HF vs the reference
 *         e. compute delta_tvd vs previous checkpoint
 *         f. evaluate stop condition
 *       (matches one iteration of analyze_vs_reference() in run_early_stop.py)
 *
 *   (2) metric_only       --  just steps (c)+(d)+(e)+(f), assuming the
 *       probability arrays are already populated.
 *
 * Each circuit's timing is reported per kernel invocation in microseconds.
 * Each measurement is repeated REPEATS times in a tight loop and the
 * MEDIAN time is reported (more stable than mean against scheduling jitter).
 *
 * Build:
 *   gcc -O2 -o bench_early_stop bench_early_stop.c -lm
 *
 * Run:
 *   ./bench_early_stop > bench_early_stop_results.csv
 *
 * Algorithm reference: experiments_qce/noise_influence/run_early_stop.py
 *   total_variation_distance(p, q) = 0.5 * sum_x |p(x) - q(x)|
 *   hellinger_fidelity(p, q)       = (sum_x sqrt(p(x) * q(x)))^2
 *   stop = converged AND in_fail_zone AND past_min_checkpoints
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <time.h>
#include <stdint.h>

/* ================================================================== */
/* Tunable parameters                                                  */
/* ================================================================== */
#define REPEATS              5000   /* timed iterations per circuit */
#define WARMUP               100    /* warmup iterations to fill caches */
#define N_CHECKPOINTS        5      /* time cp1..cp5 separately */
#define MIN_CHECKPOINT_IDX   2      /* same as Python: must reach cp 3 */
#define CONVERGENCE_DTVD     0.03
#define FAIL_HF              0.4
#define FAIL_TVD             0.6
#define MAX_QUBITS           14

/* ================================================================== */
/* Test cases: the 6 circuits with n_qubits <= 14 that FAIL on the IBM */
/* noise simulators and have a non-zero stop_after threshold from      */
/* writedown_comparison/results/stop_experiment.csv.                   */
/* (idx, n_qubits, total_shots, name)                                  */
/* Note: idx values are the noise_influence/circuits.py scheme used    */
/* in stop_experiment.csv, not benchmark_results_20.json.              */
/* The per-checkpoint shot increment is total_shots / 10.              */
/* ================================================================== */
typedef struct {
    int  idx;
    int  n_qubits;
    int  total_shots;
    const char *name;
} circuit_t;

static const circuit_t CIRCUITS[] = {
    { 2,  3, 8192, "GHZ-3"               },
    { 6,  6,  128, "GHZ-6"               },
    { 7,  8,   32, "GHZ-8"               },
    {14, 14, 4096, "VQE BeH2 14Q"        },
    {22, 14,  400, "QML Image Class 14Q" },
    {23, 12, 4000, "VQE SrH PDM 12Q"     },
};
static const int N_CIRCUITS = sizeof(CIRCUITS) / sizeof(CIRCUITS[0]);

/* ================================================================== */
/* Timing helper                                                       */
/* ================================================================== */
static inline double now_ns(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec * 1e9 + (double)ts.tv_nsec;
}

static int cmp_double(const void *a, const void *b) {
    double da = *(const double *)a, db = *(const double *)b;
    return (da > db) - (da < db);
}

static double median_ns(double *xs, int n) {
    qsort(xs, n, sizeof(double), cmp_double);
    return (n & 1) ? xs[n / 2] : 0.5 * (xs[n / 2 - 1] + xs[n / 2]);
}

/* ================================================================== */
/* Kernel building blocks (match Python semantics)                     */
/* ================================================================== */

/* Update incremental counts from a batch of bitstring outcomes.
 * `shots` is a flat array of length n_new, each entry is an integer in
 * [0, 2^n_qubits). */
static inline void update_counts(uint32_t *counts,
                                 const uint32_t *shots,
                                 int n_new) {
    for (int i = 0; i < n_new; ++i) {
        counts[shots[i]]++;
    }
}

/* Normalise integer counts to a probability vector.
 * total_shots must equal sum(counts[]). */
static inline void counts_to_probs(double *probs,
                                   const uint32_t *counts,
                                   int n_states,
                                   int total_shots) {
    const double inv = 1.0 / (double)total_shots;
    for (int i = 0; i < n_states; ++i) {
        probs[i] = (double)counts[i] * inv;
    }
}

/* TVD = 0.5 * sum_x |p(x) - q(x)| */
static inline double total_variation_distance(const double *p,
                                              const double *q,
                                              int n_states) {
    double s = 0.0;
    for (int i = 0; i < n_states; ++i) {
        double d = p[i] - q[i];
        if (d < 0) d = -d;
        s += d;
    }
    return 0.5 * s;
}

/* Hellinger fidelity = ( sum_x sqrt(p(x) * q(x)) )^2 */
static inline double hellinger_fidelity(const double *p,
                                        const double *q,
                                        int n_states) {
    double bc = 0.0;
    for (int i = 0; i < n_states; ++i) {
        bc += sqrt(p[i] * q[i]);
    }
    return bc * bc;
}

/* Stop decision (matches Python). Returns 1 to stop, 0 to continue. */
static inline int decide_stop(double tvd, double hf, double delta_tvd,
                              int cp_idx) {
    int converged    = (delta_tvd < CONVERGENCE_DTVD)
                       && (cp_idx >= MIN_CHECKPOINT_IDX);
    int in_fail_zone = (hf < FAIL_HF) && (tvd > FAIL_TVD);
    return converged && in_fail_zone;
}

/* ================================================================== */
/* Kernel 1: full checkpoint update                                    */
/* ================================================================== */
typedef struct {
    int     n_qubits;
    int     n_states;
    int     cp_idx;
    int     total_shots_so_far;
    double  prev_tvd;
    int     decision;       /* 1 = stop, 0 = continue */
    double  out_tvd;
    double  out_hf;
    double  out_delta_tvd;
} kernel_state_t;

static void kernel_full(kernel_state_t *st,
                        uint32_t *counts,           /* cumulative, n_states  */
                        double   *probs_workspace,  /* n_states              */
                        const double *ref_probs,    /* n_states              */
                        const uint32_t *new_shots,  /* batch of n_new shots  */
                        int n_new) {
    /* (a) consume new shot batch */
    /* (b) update cumulative counts */
    update_counts(counts, new_shots, n_new);
    st->total_shots_so_far += n_new;

    /* (c) normalise to probabilities */
    counts_to_probs(probs_workspace, counts, st->n_states,
                    st->total_shots_so_far);

    /* (d) TVD + HF vs reference */
    double tvd = total_variation_distance(probs_workspace, ref_probs, st->n_states);
    double hf  = hellinger_fidelity      (probs_workspace, ref_probs, st->n_states);

    /* (e) delta_tvd vs previous checkpoint */
    double delta_tvd = (st->cp_idx == 0) ? 1.0
                      : fabs(tvd - st->prev_tvd);

    /* (f) stop decision */
    int stop = decide_stop(tvd, hf, delta_tvd, st->cp_idx);

    /* commit state for next call */
    st->out_tvd       = tvd;
    st->out_hf        = hf;
    st->out_delta_tvd = delta_tvd;
    st->decision      = stop;
    st->prev_tvd      = tvd;
    st->cp_idx       += 1;
}

/* ================================================================== */
/* Kernel 2: metric only (probs already populated)                     */
/* ================================================================== */
static void kernel_metric_only(kernel_state_t *st,
                               const double *probs,
                               const double *ref_probs) {
    double tvd = total_variation_distance(probs, ref_probs, st->n_states);
    double hf  = hellinger_fidelity      (probs, ref_probs, st->n_states);
    double delta_tvd = (st->cp_idx == 0) ? 1.0
                      : fabs(tvd - st->prev_tvd);
    int stop = decide_stop(tvd, hf, delta_tvd, st->cp_idx);

    st->out_tvd       = tvd;
    st->out_hf        = hf;
    st->out_delta_tvd = delta_tvd;
    st->decision      = stop;
    st->prev_tvd      = tvd;
    st->cp_idx       += 1;
}

/* ================================================================== */
/* Random helpers                                                      */
/* ================================================================== */
static uint32_t rng_state = 0xdeadbeefu;
static inline uint32_t xrand(void) {
    /* xorshift32 */
    rng_state ^= rng_state << 13;
    rng_state ^= rng_state >> 17;
    rng_state ^= rng_state << 5;
    return rng_state;
}

static void make_random_distribution(double *p, int n_states) {
    double s = 0.0;
    for (int i = 0; i < n_states; ++i) {
        p[i] = (double)(xrand() & 0xFFFF) + 1.0;
        s += p[i];
    }
    for (int i = 0; i < n_states; ++i) {
        p[i] /= s;
    }
}

static void make_random_shots(uint32_t *shots, int n, int n_states) {
    uint32_t mask = (uint32_t)(n_states - 1);
    for (int i = 0; i < n; ++i) {
        shots[i] = xrand() & mask;
    }
}

/* ================================================================== */
/* Main timing driver                                                  */
/* ================================================================== */
/* Time the kernel for a specific checkpoint position. We faithfully
 * reproduce the state the algorithm would be in at that checkpoint:
 *   cp_idx_pos == 0  -> first checkpoint, prev_tvd is unused, delta_tvd
 *                       is forced to 1.0 in the kernel.
 *   cp_idx_pos == 1  -> second checkpoint, prev_tvd is the previous cp's
 *                       result; counts already contain 1*step prior shots.
 *   cp_idx_pos == 2  -> third checkpoint, counts contain 2*step prior shots.
 *   cp_idx_pos >= MIN_CHECKPOINT_IDX -> stop check is gated only by
 *                                       converged AND in_fail_zone.
 *
 * Note: cp_idx in the state object is the **count of completed checkpoints**
 * before this call, so the kernel sees cp_idx=cp_idx_pos and increments it.
 */
static double bench_checkpoint(int cp_idx_pos,
                               int n_qubits,
                               int n_states,
                               int shots_per_cp,
                               double *ref_probs,
                               uint32_t *shot_batch,
                               uint32_t *counts,
                               double *probs_workspace,
                               int repeats) {
    double *times = malloc(repeats * sizeof(double));

    /* Warmup: run the kernel a number of times so caches/branch
     * predictors are in steady state before we start timing. */
    for (int w = 0; w < WARMUP; ++w) {
        memset(counts, 0, n_states * sizeof(uint32_t));
        for (int i = 0; i < cp_idx_pos * shots_per_cp; ++i) {
            counts[xrand() & (n_states - 1)]++;
        }
        kernel_state_t st = {
            .n_qubits = n_qubits,
            .n_states = n_states,
            .cp_idx   = cp_idx_pos,
            .total_shots_so_far = cp_idx_pos * shots_per_cp,
            .prev_tvd = (cp_idx_pos == 0) ? 0.0 : 0.5,
        };
        kernel_full(&st, counts, probs_workspace, ref_probs,
                    shot_batch, shots_per_cp);
        __asm__ __volatile__("" : : "r"(st.out_tvd), "r"(st.out_hf),
                             "r"(st.decision) : "memory");
    }

    for (int rep = 0; rep < repeats; ++rep) {
        /* Reset cumulative counts to "cp_idx_pos * shots_per_cp" prior shots */
        memset(counts, 0, n_states * sizeof(uint32_t));
        for (int i = 0; i < cp_idx_pos * shots_per_cp; ++i) {
            counts[xrand() & (n_states - 1)]++;
        }
        kernel_state_t st = {
            .n_qubits = n_qubits,
            .n_states = n_states,
            .cp_idx   = cp_idx_pos,
            .total_shots_so_far = cp_idx_pos * shots_per_cp,
            .prev_tvd = (cp_idx_pos == 0) ? 0.0 : 0.5,
        };

        double t0 = now_ns();
        kernel_full(&st, counts, probs_workspace, ref_probs,
                    shot_batch, shots_per_cp);
        double t1 = now_ns();
        times[rep] = t1 - t0;

        __asm__ __volatile__("" : : "r"(st.out_tvd), "r"(st.out_hf),
                             "r"(st.decision) : "memory");
    }
    double med = median_ns(times, repeats);
    free(times);
    return med;
}

int main(void) {
    /* CSV header: cp1..cp5 */
    printf("idx,name,n_qubits,n_states,shots_per_checkpoint,"
           "cp1_us,cp2_us,cp3_us,cp4_us,cp5_us\n");

    for (int ci = 0; ci < N_CIRCUITS; ++ci) {
        const circuit_t *c = &CIRCUITS[ci];
        int n_qubits = c->n_qubits;
        int n_states = 1 << n_qubits;
        int shots_per_cp = c->total_shots / 10;
        if (shots_per_cp < 1) shots_per_cp = 1;

        /* Allocate per-circuit workspace */
        uint32_t *counts          = calloc(n_states, sizeof(uint32_t));
        double   *probs_workspace = malloc(n_states * sizeof(double));
        double   *ref_probs       = malloc(n_states * sizeof(double));
        uint32_t *shot_batch      = malloc(shots_per_cp * sizeof(uint32_t));
        if (!counts || !probs_workspace || !ref_probs || !shot_batch) {
            fprintf(stderr, "OOM at circuit idx=%d\n", c->idx);
            return 1;
        }

        /* Initialise reference distribution and a fresh batch of shots */
        make_random_distribution(ref_probs, n_states);
        make_random_shots(shot_batch, shots_per_cp, n_states);

        /* Bench cp1..cp5 separately. cp_idx_pos = 0..4 corresponds to
         * the 1st..5th checkpoint call. */
        double cps[N_CHECKPOINTS];
        for (int k = 0; k < N_CHECKPOINTS; ++k) {
            cps[k] = bench_checkpoint(k, n_qubits, n_states, shots_per_cp,
                                      ref_probs, shot_batch,
                                      counts, probs_workspace, REPEATS);
        }

        printf("%d,%s,%d,%d,%d", c->idx, c->name, n_qubits, n_states,
               shots_per_cp);
        for (int k = 0; k < N_CHECKPOINTS; ++k) {
            printf(",%.4f", cps[k] / 1e3);
        }
        printf("\n");

        free(counts);
        free(probs_workspace);
        free(ref_probs);
        free(shot_batch);
    }

    return 0;
}
