# Addendum 2026-09-03 to report_20260902.md: (D) single-circuit fixed-cost decomposition, (E) RQ3 simulator statistics

Both items were requested after the 2026-09-02 report ("the fixed-cost decomposition can be run"; "RQ3 stays"). Board
state at the end: image 63329aaf, batch_server protocol v7 (software_c3 a1eefb5), dma_server STRM_POLL_US=200,
std_server SS_CHUNK_TIMEOUT_S=300 (unchanged from the 2026-09-02 report).

## D. Single-circuit fixed cost on the integrated image (c3), decomposed into stages

**Instrumentation.** batch_server protocol v7 adds four PS timestamps (CLOCK_MONOTONIC, same clock as t_start and
t_end) to the STAT reply: first image MM2S complete, GLOBAL_START written, first `cur_cid` observed, batch_done observed
(the last two are polled with `sched_yield` by the feeder thread). With the dma_server's t_last_read (t_end) the run
splits into: `upload` = t_start -> first MM2S done (PS -> DDR command images, one MM2S for the unit); `start` = ->
GLOBAL_START (config-FIFO write + start decision); `launch` = -> first cur_cid (PL pops the config, fetches the first
buffer halves, DSP starts, PLUS the PS detection latency); `exec` = -> batch_done; `drain` = -> t_end (last readout word
in PS memory). Definitions and code: scripts/make_decomp_table.py; rows: results/raw_runs_decomp.csv (319 rows, all
`ok`); table: results/table_decomp.csv; log: results/decomp.log.

**Runs.** All 20 paper circuits x 10 repeats (+1 warm-up each) with dma_server STRM_POLL_US=0 (tag c3_14q_decomp_p0);
6 circuits x 10 (+1) at STRM_POLL_US=200, the Table 4 condition (tag c3_14q_decomp_p200: idx 6, 7, 19 from a first
launch that used the wrong circuit numbering and stopped after three circuits, then 10, 9, 12). idx 6/7/8 have 22
poll-0 runs for the same reason. Realized shot lengths P_realized are the C1-slope values of
results/per_shot_realized_real.csv (2026-08-31).

**D.1 The dominant "overhead" term is per shot, not fixed.** `exec - shots x P_compiled` grows with the shot count at
142-156 ns per shot for the 16 circuits whose first-cid detection was prompt (launch s.d. < 10 us; table column
"per shot (ns)"), matching the compiled-vs-realized shot-length difference measured independently on C1
(P_realized - P_compiled = 142-170 ns for the same programs). It is a property of the DSP program (readout/branch
overhead that the compiled duration does not count) and is identical in the QubiC baseline, which runs the same
program; it is not a control-system cost.

**D.2 Fixed cost = elapsed - shots x P_realized.** Cleanest on the <= 1024-shot circuits, where the +-10 ns/shot
uncertainty of P_realized is negligible:

| circuit (shots) | active cores | fixed, poll 0 (us, mean +- s.d., n) | fixed, poll 200 | fixed / realized QPU |
|---|---|---|---|---|
| QAOA 2Q p=1 (1000) | 2 | 25.8 +- 5.3 (11) | - | 0.28 % |
| VQE HeH+ 2Q (4000) | 2 | 32.1 +- 105.2 (11) | - | 0.09 % |
| Quantum teleportation 3Q (1000) | 3 | 70.4 +- 11.0 (11) | - | 0.48 % |
| Deutsch-Jozsa 3Q (1024) | 3 | 66.2 +- 6.0 (22) | 63.4 +- 5.1 (11) | 0.53 % |
| QFT 4Q (500) | 4 | 67.3 +- 25.6 (11) | - | 0.51 % |
| GHZ-5 (1024) | 5 | 79.4 +- 43.1 (22) | - | 0.43 % |
| Bernstein-Vazirani 5Q (1024) | 5 | 64.5 +- 5.2 (11) | - | 0.33 % |
| Shor N=15 5Q (1000) | 5 | 68.3 +- 6.0 (11) | - | 0.38 % |
| QSVM Radar 4Q (1024) | 4 | 108.2 +- 114.9 (11) | - | 0.61 % |
| GHZ-6 (128) | 6 | 84.4 +- 13.4 (11) | 82.2 +- 4.9 (11) | 3.10 % |
| Grover 6Q (1024) | 6 | 143.0 +- 246.8 (11) | - | 0.23 % |
| GHZ-8 (32) | 8 | 99.0 +- 6.0 (11) | 100.8 +- 6.7 (11) | 11.2 % |
| QML Image Class 14Q (400) | 14 | 204.6 +- 138.9 (11) | - | 1.02 % |
| VQE BeH2 14Q (4096) | 14 | 174.5 +- 7.8 (11) | 172.7 +- 4.0 (11) | 0.09 % |
| VQE SrH PDM 12Q (4000) | 12 | 171.5 +- 5.4 (11) | - | 0.10 % |
| QAOA MaxCut 12Q (10000) | 12 | 188.2 +- 7.2 (11) | - | 0.04 % |

A simple model fits: fixed ~= 25 us + 10 us x (active cores) (2-8 cores within +-15 us; 12-14 cores within +30 us).
For the >= 8192-shot circuits (Bell -191 us, GHZ-3 +116, GHZ-4 +104, VQE 1Q -5 us) the fixed cost is below the
P_realized uncertainty (+-10 ns x shots = +-80-250 us) and is not resolvable by this method.

**D.3 Stage composition (poll 0, medians; ranges over circuits).**
- upload: 30 us median; 7.7 us (1 core) -> 14 (2) -> 20 (3) -> 27 (4) -> 33 (5) -> 40 (6) -> 52 (8) -> 79 (12) -> 90 us
  (14 cores): ~6.3 us per active core (one 32 KiB command slot per core, ~5 GB/s effective MM2S), s.d. 0.2-0.6 us.
- start (config write + GLOBAL_START): 0.7 us in every cell.
- launch + end flush (PL side; reported as `launch + exec residual` because the PS detection latency of the first
  cur_cid cancels in the sum): 10-32 us for <= 8 cores, 54-94 us for 12-14 cores -- consistent with the PL fetching the
  first 16 KiB half of each core's image from DDR (~4 us per core) before the DSPs start.
- drain (batch_done -> last readout word in PS memory): 11-33 us median; single-run outliers up to ~250 us (PS
  scheduling of the dma_server read; s.d. 50-250 us in 7 of 20 cells at poll 0).
- first-cid detection latency (PS): the `launch` column's s.d. reaches 290 us (feeder thread contention) -- it does
  not enter the fixed cost (batch_done is timestamped in the same tight loop, and t_end comes from the dma_server)
  but it makes the launch / exec split unreliable, hence the combined column.

**D.4 Poll interval.** On the same circuits the fixed cost at STRM_POLL_US=200 equals that at 0 within the run-to-run
spread (DJ 63.4 vs 66.2 us; GHZ-6 82.2 vs 84.4; GHZ-8 100.8 vs 99.0; BeH2 172.7 vs 174.5; GHZ-4 73.5 vs 104.2 where
the poll-0 cell has drain outliers). The Table 4 measurements, taken at poll 200, are therefore not inflated by the
dma_server poll interval; with one busy-spinning process fewer, the poll-200 drain was tighter (s.d. 4-10 us).

**D.5 GHZ-8.** Its 32 shots make the ~100 us fixed cost 11 % of the realized QPU time (0.881 ms); the decomposition runs
give 0.980 +- 0.006 ms end to end (the 1.013 ms mean quoted for tag c3_14q_real3 on 2026-09-02 contained one 1.088 ms
outlier of the drain type above). The 12-16 % rows of the earlier tables are this fixed cost against a sub-millisecond
workload, not a per-shot inefficiency.

**For the paper.** Report the Ant-Q overhead against the realized QPU time (shots x P_realized), state the fixed cost
as ~25 us + ~10 us per active core (image upload ~6 us/core, PL first-half fetch ~4 us/core, start 0.7 us, drain
~15 us), and note that the compiled-vs-realized 0.15 us/shot is a DSP-program property shared with the baseline.

## E. RQ3 early-stop statistics on the six Qiskit fake backends (simulator only; no board time)

**Method.** scripts/rq3_stats.py (+ run_rq3_stats.sh): every paper circuit (20, <= 14 qubits) x six backends
(FakeManilaV2 5Q, FakeLagosV2 7Q, FakeGuadalupeV2 16Q, FakeAlgiers 27Q, FakeSherbrooke 127Q, FakeTorino 133Q) x seeds
0-19 (transpiler and simulator seeds) = 2400 runs, of which 2160 are executable (240 SKIP: circuit wider than the
backend, the paper's "-"). Rule exactly as methodology.tex: 10 checkpoints; converged when |dTVD| <= 0.03 AND
|dHF| <= 0.03 between consecutive checkpoints; unreadable when HF <= 0.4 and TVD >= 0.6; earliest stop at checkpoint 3.
Reference = a noiseless sample of 10 % of the budget (as in the archived run_early_stop.py; the paper says "noiseless
distribution"). Ground truth per run = grade of the full noisy sample vs a full noiseless sample (PASS / MARGINAL /
FAIL with the paper's thresholds). qiskit 2.3.1, qiskit-aer 0.17.2, qiskit-ibm-runtime 0.46.1 (conda env noise_exp);
the archived circuits.py / metrics.py are reused unchanged. Rows: results/rq3/rq3_<backend>.csv (+ per-checkpoint
files); cell table: results/table_rq3_cells.csv (scripts/make_rq3_tables.py); sampling floor:
results/rq3/sampling_floor.csv (scripts/rq3_sampling_floor.py).

**E.1 Grades: the paper's single-run table is the majority outcome in every listed cell.** Counts over 20 seeds
(P/M/F = PASS/MARGINAL/FAIL):

| circuit | Manila | Lagos | Guadalupe | Algiers | Sherbrooke | Torino | paper's row |
|---|---|---|---|---|---|---|---|
| GHZ-3 | P20 | M3/F17 | P20 | P20 | P20 | P20 | P F P P P P |
| GHZ-6 | - | F20 | P20 | P20 | P20 | P10/M10 | - F P P P P |
| GHZ-8 | - | - | P18/M2 | P18/M2 | F20 | M20 | - - P P F M |
| VQE BeH2 14Q | - | - | F20 | F20 | F20 | F20 | - - F F F F |
| QML Image Class 14Q | - | - | F20 | F20 | F20 | F20 | - - F F F F |
| VQE SrH PDM 12Q | - | - | M20 | P20 | F20 | M20 | - - M P F M |

Borderline cells: GHZ-6/Torino (PASS in 10/20), GHZ-3/Lagos (FAIL 17/20), GHZ-8 Guadalupe and Algiers (PASS 18/20).
Not in the paper's table (no FAIL) but MARGINAL in 20/20 seeds: GHZ-4, GHZ-5, Shor, Deutsch-Jozsa, Bernstein-Vazirani
on Lagos, and QAOA MaxCut 12Q on all four large backends. All other cells: PASS 20/20.

**E.2 Stop decisions.** 320 stops in 2160 runs: 237 of 237 FAIL runs stopped (no missed stop), 0 of 1659 PASS runs
stopped (no false stop), 83 of 264 MARGINAL runs stopped (80 = QAOA MaxCut 12Q on the four large backends, 2 = GHZ-8
Torino, 1 = GHZ-3 Lagos). Stop checkpoint distributions (median, range over the stopping seeds): VQE BeH2, QML Image
and SrH/Sherbrooke 3 (3-3, all seeds); GHZ-3/Lagos 3 (3-9); GHZ-6/Lagos 4 (3-7); GHZ-8/Sherbrooke 6 (3-10);
QAOA 12Q 3-4 (3-5). The paper's "Converge at" column (3, 5, 4, 3, 3, 3) is one draw from these distributions; Fig. 5's
shot savings should be given as medians with ranges. Paper rule vs the archived code's TVD-only convergence: identical
decisions in 2332 of 2400 runs; the 68 differences are all QAOA MaxCut 12Q stopping one checkpoint later under the
paper rule -- the text/code discrepancy does not touch the six table circuits.

**E.3 The FAIL grade of the two 14-qubit circuits is undersampling, not noise.** Two independent NOISELESS samples at
the full shot budget already sit in the FAIL zone for VQE BeH2 14Q (4096 shots, ~3610 distinct outcomes: TVD 0.80,
HF 0.05) and QML Image Class 14Q (400 shots, ~395 outcomes: TVD 0.97, HF 0.001); their noisy TVD exceeds that
noiseless floor by only 0.002-0.008 on every backend. QAOA MaxCut 12Q (10000 shots, ~2830 outcomes) has a noiseless
floor of TVD 0.66 / HF 0.23 at the 30 % checkpoint (fail zone) and 0.30 / 0.77 at the full budget -- its 80 MARGINAL
stops are the same effect. The other four table cells are genuine noise: excess TVD over the floor +0.60 (GHZ-3/Lagos),
+0.69 (GHZ-6/Lagos), +0.69 (GHZ-8/Sherbrooke), +0.975 (VQE SrH/Sherbrooke, a deterministic circuit whose correct
outcome survives in 2.5 % of shots). Floors for all 20 circuits: results/rq3/sampling_floor.csv (only BeH2, QML,
QAOA 12Q and Grover 6Q (0.37 at 30 %, 0.14 at full) exceed 0.25 anywhere).

**Consequence for the paper (decision needed).** Either (a) restrict the readability rule to circuits whose noiseless
floor at the checkpoint size is outside the fail zone (e.g. floor TVD < 0.3), report VQE BeH2 14Q and QML Image 14Q as
"output distribution not estimable within the source's shot budget" and drop them from the noise-dominated set (six
-> four; QAOA 12Q excluded at early checkpoints), or (b) grade on the excess over the noiseless floor (TVD minus the
floor at the same sample sizes; the per-checkpoint files make the re-evaluation a one-script job). The hardware
early-stop mechanism (report B) is unaffected; the RQ3 text, Table noise_study and Fig. 5 are.

**E.4 Sampling-adequacy gate (both round-2 reviewers of the AQT plan, independently: gate, do not subtract a floor).**
scripts/rq3_adequacy_gate.py draws 200 noiseless replicate pairs (n-shot sample, 10 % reference -- the rule's own
statistic) at every checkpoint k = 3..10 and requires the 95th percentile of TVD < 0.3 and the 5th percentile of HF
> 0.7 (the noiseless null stays inside PASS). Result (results/rq3/adequacy_gate.csv): 16 of 20 circuits are evaluable
at every checkpoint (worst: GHZ-8 at checkpoint 3 with n = 9 shots, TVD95 0.298; QFT 4Q 0.254; QSVM 4Q 0.213);
4 circuits are evaluable at NO checkpoint: VQE BeH2 14Q (TVD95 0.98, HF05 0.001), QML Image Class 14Q (1.0 / 0.0),
QAOA MaxCut 12Q (0.66-0.68 / 0.21-0.29) and Grover 6Q (0.38-0.41 / 0.64-0.67; here the limit is the 10 % reference
sample of ~100 shots over 64 outcomes -- with the exact noiseless distribution as reference Grover would pass). The
four genuine noise-dominated cells (GHZ-3/Lagos, GHZ-6/Lagos, GHZ-8/Sherbrooke, VQE SrH/Sherbrooke) all pass the gate
at every checkpoint (TVD95 <= 0.30, HF05 >= 0.91), so their FAIL grades and stops stand under the bootstrap null.
Recommended paper change: state the gate as part of the method, list BeH2 14Q, QML 14Q, QAOA 12Q (and Grover 6Q with
the sampled reference) as "not evaluable at the source's shot budget", reduce the noise-dominated set from six to four
circuits, and optionally replace the 10 % sampled reference by the exact noiseless distribution (re-run both scripts).

**E.5 Root cause: seven of the twenty reconstructed circuits have an exactly uniform ideal output (scripts/rq3_ideal_stats.py
-> results/rq3/ideal_distribution_stats.csv).** Statevector of each circuit with the final measurements removed:
VQE BeH2 14Q and QML Image Class 14Q put probability 2^-14 on every one of the 16384 bitstrings (entropy 14.00 of
14 bits; the reconstruction uses fixed RY(pi/2) layers, i.e. an equal superposition, not optimized parameters);
QFT 4Q (QFT of |0000>), QAOA 2Q p=1, VQE 1Q eigensolver and Grover 6Q (collision ratio 1.01: the oracle marks
nothing) are uniform as well. A uniform ideal output is the fixed point of depolarizing noise, so for these circuits
no readability question exists: noise cannot make the output "worse", and no metric can grade them. The metric then
reports whatever finite sampling produces -- FAIL for the two 14-qubit circuits (4096 or 400 shots cannot reproduce
a 16384-outcome uniform distribution) and PASS 20/20 for the four small ones (a 2-16-outcome uniform distribution is
easy to reproduce), both vacuous. Of the remaining 13 circuits, 12 are peaked (1-4 outcomes: GHZ family, VQE HeH+,
VQE SrH, Shor, teleportation, DJ, BV) or moderately broad (QSVM 4Q, 16 outcomes) and are graded soundly by TVD/HF;
one, QAOA MaxCut 12Q, is structured (entropy 11.3 of 12 bits, max p = 7.3x uniform) but spread over ~4000 outcomes,
and there the metric itself is the limit: 10000 shots cannot estimate its histogram (E.3, E.4).

**Metric check (scripts/rq3_xeb_probe.py, one seed).** The linear cross-entropy fidelity against the EXACT ideal
probabilities, F = (mean_i p(x_i) - 2^-n) / (sum_x p(x)^2 - 2^-n) (1 for ideal sampling of any distribution, 0 for
uniform noise; needs only a 2^n-entry probability table), decides every structured circuit at the paper's budgets,
including the broad one: QAOA 12Q noiseless 0.99, FakeAlgiers 0.85 +- 0.01 (already at the 30 % checkpoint);
GHZ-3/Lagos 0.19, VQE SrH/Sherbrooke 0.03, GHZ-8/Sherbrooke 0.28 +- 0.08, GHZ-4/Algiers 0.94 -- the same verdicts as
TVD/HF where those were genuine. It is undefined for the uniform circuits (denominator 0), which is the correct
behaviour: there is nothing to grade.

**What this means for the paper.** (1) RQ3 inherited RQ2's circuit set, which was reconstructed to match qubit count,
depth and shots for TIMING; seven of its members carry no output information and cannot serve a readability study.
For RQ2 this is harmless (pulse durations are angle-independent: 24 ns 1Q, 332 ns 2Q). (2) Options: replace the
angles of the six angle-degenerate circuits by values that give a structured output (VQE/QAOA parameters from a short
classical optimization or the source, QFT on a non-trivial input, a Grover oracle that marks a state) -- RQ2's
timing tables are unaffected except where the gate structure changes (Grover oracle); then re-run the simulator study
(scripts here, minutes) and the six hardware stop pairs whose preset stop points change (~1 h board time). (3) Keep
TVD/HF with the sampling-adequacy gate (E.4) for peaked circuits, or switch the readability metric to the exact-
probability fidelity above, which also handles QAOA 12Q; either choice must be stated in the method. (4) Table
noise_study and Fig. 5 lose the two 14-qubit rows until the circuits are fixed; the hardware early-stop mechanism
(report B) is unaffected in mechanism, but its BeH2 and QML pairs demonstrate stopping on circuits without
information.

**Decision (user, 2026-09-04).** Do not re-parameterize the circuits for this revision. VQE BeH2 14Q and QML Image
Class 14Q are to be described in the paper as circuits for which the metric cannot determine whether noise dominates
(uniform ideal output at the source shot budgets); the noise-dominated set becomes four. Checklist:
~/agent_journals/antq_paper_revision_todo.md item 1.

## F. RQ3 v2: re-parameterized 14-qubit templates and the exact noiseless reference (user decision 2026-09-04)

**Change.** (1) The two angle-degenerate templates get generic parameters, structure and pulse count unchanged:
VQE BeH2 14Q RY angles ~ U[0, pi/8) (numpy default_rng(0), 3 x 14; a converged VQE stays close to its reference
determinant), QML Image 14Q data-encoding RY = pi/2 + U(-0.2, 0.2), ZZ weights and final RY ~ U[0, pi/8) (same
generator, continued). Generic angles over the full range were tested first and REJECTED: they give broad Porter-
Thomas-like outputs (entropy 10.7 of 14 bits) that TVD/HF cannot estimate at 4096 / 400 shots any better than the
uniform case; only small rotations give an estimable output (BeH2 entropy 3.9 bits, QML 1.7 bits). Angle values:
results/rq3_v2/angles_v2.json; Qiskit twin scripts/circuits_v2.py; pulse-level twin benchmark_qce/circuits_le14.py
f2343ec (RY_angle = the same 24 ns X90 pulse with amplitude 0.5 x theta/(pi/2) inside the same virtual-Z frame; idx 19
and 22 compile to identical instruction counts 290 / 304, pulse counts 178 / 192 and per-shot 46.416 / 50.124 us).
(2) The rule's reference is the exact noiseless distribution (statevector), as methodology.tex states, instead of the
archived code's 10 % noiseless sample (REF=exact in scripts/rq3_common.py; v1 results kept in results/rq3/, v2 in
results/rq3_v2/, cell table results/table_rq3_cells_v2.csv).

**Adequacy gate under v2 (results/rq3_v2/adequacy_gate.csv).** 19 of 20 circuits are evaluable at every checkpoint
(BeH2 cp3 TVD95 0.13 / HF05 0.89; QML 0.13 / 0.90; Grover 6Q now 0.21 / 0.92 -- its v1 failure was the 100-sample
reference); QAOA MaxCut 12Q is evaluable from checkpoint 6 on (cp3 TVD95 0.40).

**Grades, 6 backends x 20 seeds (2160 runs).** Every FAIL is now genuine (every stopping cell passes the gate):

| circuit | Manila | Lagos | Guadalupe | Algiers | Sherbrooke | Torino | v1 (paper) row |
|---|---|---|---|---|---|---|---|
| GHZ-3 | P20 | M3/F17 stop 18 @3 (3-9) | P20 | P20 | P20 | P20 | unchanged |
| GHZ-6 | - | F20 stop 20 @4 (3-7) | P20 | P20 | P20 | P10/M10 | unchanged |
| GHZ-8 | - | - | P18/M2 | P18/M2 | F20 stop 20 @6 (3-10) | M20 (2 stops) | unchanged |
| VQE BeH2 14Q | - | - | M20 | P20 | F20 stop 20 @3 | M20 | was F F F F (vacuous) |
| QML Image 14Q | - | - | M20 | P19/M1 | F20 stop 20 @3 (3-4) | M20 | was F F F F (vacuous) |
| VQE SrH 12Q | - | - | M20 | P20 | F20 stop 20 @3 | M20 | unchanged |
| QAOA MaxCut 12Q | - | - | M20 | M20 | M20 | M20 | v1 had 80 spurious stops; now none |

Stops 120: on FAIL 117 of 117 (no miss), on PASS 0 of 1698 (no false stop), on MARGINAL 3 of 345 (GHZ-3/Lagos 1,
GHZ-8/Torino 2). Paper rule vs the archived TVD-only convergence: identical decisions in 2391 of 2400 runs. The set of
circuits with at least one FAIL is still the paper's six; the two 14-qubit rows change from "FAIL on all four large
backends" to "FAIL on Sherbrooke, MARGINAL/PASS elsewhere".

**Hardware early-stop pairs (report B).** The board pairs for idx 19 (BeH2) and 22 (QML) were run with the 30 %
checkpoint as the preset stop point; v2 stops both at checkpoint 3 on Sherbrooke, so those pairs stand and no board
time is needed. Pending the user's OK: push benchmark_qce f2343ec and bump the Ant-Q artifact's benchmark submodule.

## G. Bench cadence metrology with the oscilloscope (2026-09-04; AQT plan P0-D)

**Pre-registration and amendments:** ~/agent_journals/antq_scope_cadence_plan_20260904.md. Instrument Tektronix
MSO71254C on veneno DAC 230_0 (CH1). Two amendments were needed before any acceptance data was taken: (1) in the
14-channel build DAC 230_0 carries the DRIVE of qubit_8 (dsp_config.yaml: DAC i <- qubit_i.qdrv; the readout bus is on
DAC 14/15, not wired to the scope), so every program was run on qubit_8 instead of qubit_0 (runner env
SCOPE_QUBIT_OFFSET=8; identical program and schedule) and the observable is the X90 drive pulse train (4.46 GHz, the
paper's carrier; 24 ns bursts, 59-62 mV at the scope); (2) records were taken in PEAKDETECT mode at 12.5 MS/s (80 ns
bins, CONSTANT-sample-rate mode, 100 ms or 1 s records), so a 24 ns burst survives the decimation; the timing
resolution floor is therefore 80 ns. Shots are segmented by pulse gaps (scripts/scope_cadence.py; per-capture pulse
timestamps in results/scope_cadence/ts/, raw records in results/scope_cadence/raw/, table
results/scope_cadence/cadence_summary.csv). Supplementary records taken with a 300 MHz drive carrier (tags ctest,
phys4_r3-5, phys3_r1) gave identical numbers.

| program (programmed period) | records | shots detected / expected | mean period (us) | s.d. (ns) | deviation min / max (ns) | outside +-1 us | max pulse gap inside a shot |
|---|---|---|---|---|---|---|---|
| phys4, 6 us trace (8.932 us x 8000) | 3 complete runs (100 ms records) | 8000 / 8000 in each | 8.9320 | 60.7 | -132 / +28 | 0 | 0.56 us (= the tau between the two X90) |
| phys3, repeated Ramsey (2003.648 us x 50000) | 10 x 1 s windows across the 100 s run | 490-499 per window, 0 missing | 2003.6476 | 63.7-64.3 | -128 / +32 | 0 | 1.12 us (tau) |
| phys5, 1Q RB 5101 Cliffords, 5-segment stream (248.544 us compiled sum x 1024) | 3 complete runs (1 s records) | 1024 / 1024 in each | 249.250 | 61.6-62.1 | +576 / +736 | 0 | 0.16 us over 4096 buffer boundaries |

Acceptance: A1 (no missing or extra shots) met in every record; A2 (every interval within +-1 us of the programmed
period) met in every record; A3: the interval spread (s.d. 61-64 ns, range 160 ns) equals the 80 ns sampling
quantization, i.e. no resolvable jitter. For the looped single programs (3) and (4) the physical period equals the
compiled period (8.9320 and 2003.6476 vs 8.932 and 2003.648 us). For the segment stream (5) the physical shot period is
a constant 0.706 us longer than the compiled sum of the five segments: 141 ns per unit handover (config pop, first
fetch and start of the next command-buffer half), deterministic to within the 80 ns bins, present at every one of the
5 x 1024 handovers; no gap longer than 0.16 us occurred anywhere inside the RB bodies, so none of the 4096 buffer
boundaries stalled. This handover explains the +0.35 % of (5) and +0.11 % of (6) reported in section A (0.706 us x
1024 = 0.72 ms of the 0.88 ms excess; the rest is the fixed start/drain cost of section D). In 3 of 1024 shots per run
the active-reset branch fired (two conditional X90 pulses 3.6 us after the readout); those shots were 0.16 us longer
than their neighbours -- the branch_fproc hold of the DSP, identical in stock QubiC, not a control-system effect.
PS-side evidence of the same runs (raw_runs_phys.csv, tags scope_phys*): elapsed within +0.03 % (4), -0.002 % (3),
+0.35 % (5) of the compiled duration, CNR 0.

**For the paper:** "the physical inter-shot period, measured with an oscilloscope on the drive output, equals the
compiled period to within the 80 ns measurement resolution over 8000 (6 us trace) and 4990 (2 ms repeated Ramsey)
consecutive shots, with no missing shot and no interval deviating by more than 132 ns; in the streamed 5101-Clifford
RB, 4096 command-buffer handovers each added a fixed 141 ns and none stalled". The scope measurement covers the same
programs as Table 2 rows (3)-(5); (6) was not scoped (same mechanism as (5)).
