/* std_server.c — the standard QubiC PS path (BRAM command load + accbuf readback) in C.
 *
 * Purpose: a control variable for the Ant-Q timing tables. The Python RPC server pays interpreter cost
 * per MMIO word; this server performs EXACTLY the same PL operations as `run.py: run_circuit_batch` ->
 * `load_executable(zero=True, commands only)` + `run_circuit` (see plan D3a), nothing more, in C.
 *
 * One command, BATCH: the client stages K circuits up front (write lists resolved to bramctrl word
 * addresses by the client from bram.json; dspregs word offsets from dspregs.json), the server stores
 * everything in RAM, replies RDY, then runs the K circuits back-to-back with no client round trip and
 * timestamps t_start (before the first bramctrl MMIO store of circuit 0) and t_end (after the last
 * accbuf MMIO load of circuit K-1; with flags bit0 = readout via DDR (C1): per circuit the stale
 * SHOT_DONE/FINAL_ADDR/CUR_ADDR are cleared like run.py ddr_start_circuit, shots run in ONE start (no
 * accbuf chunking: send n_chans = 0), nothing is read back, t_end = after the last lastshotdone poll;
 * the readout end time then comes from dma_server's STRM trailer).
 *
 * Wire format (all integers u32 little-endian unless noted):
 *   "BATC" u32 K, u32 flags, u32 accbuf_len_words, u32 off_nshot, u32 off_dspreset, u32 off_resetacc,
 *          u32 off_start, u32 off_lastshotdone
 *   K x { u32 n_writes, n_writes x { u32 addr_words, u32 n_words, u32 data[n_words] },
 *         u32 n_regs,   n_regs   x { u32 off_words, u32 value },
 *         u32 nshots, u32 n_chans, n_chans x { u32 accbuf_addr_words, u32 words_per_shot } }
 *   -> u32 status (0 = RDY, else error; session closes)
 *   -> after execution: u32 status, u64 t_start_ns, u64 t_end_ns, u64 mmio_words_written,
 *      then for each circuit, for each chan: u32 n_words, u32 data[n_words]   (omitted when flags bit0)
 *
 * Build (board): gcc -O2 -o std_server std_server.c      Run: sudo ./std_server   (port 8082, SS_PORT)
 */
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <signal.h>
#include <time.h>
#include <sys/mman.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/tcp.h>

#define BRAMCTRL_BASE 0x80000000UL      /* psbd.hwh: bramctrl 0x8000_0000 .. 0x83FF_FFFF (64 MiB)   */
#define BRAMCTRL_SIZE 0x04000000UL
#define DSPREGS_BASE  0x84010000UL      /* psbd.hwh: dspregs 0x8401_0000 (64 KiB)                    */
#define DSPREGS_SIZE  0x00010000UL
#define AXIL_BASE     0xA0020000UL      /* axi_lite_ctrl_0 (readout MMU): C1 per-circuit clears             */
#define AXIL_SIZE     0x00010000UL
#define POLL_US       1000              /* pl_interface.POLL_INTERVAL = 1 ms (QubiC protocol)         */
#define CHUNK_TIMEOUT_S_DEFAULT 60.0
static double CHUNK_TIMEOUT_S = CHUNK_TIMEOUT_S_DEFAULT;   /* env SS_CHUNK_TIMEOUT_S overrides (100 s single-shot loops, plan A) */

enum { E_OK = 0, E_PROTO = 1, E_RANGE = 2, E_TIMEOUT = 3, E_NOMEM = 4 };
enum { F_READOUT_DDR = 1 };

static volatile uint32_t *bram, *dspregs, *axil;
static int g_trace = 0;                  /* SS_TRACE=1: log every phase (find the last MMIO phase before a bus wedge) */
#define TRACE(...) do { if (g_trace){ printf("[STD-TRACE] " __VA_ARGS__); fflush(stdout); } } while (0)

static uint64_t now_ns(void){ struct timespec t; clock_gettime(CLOCK_MONOTONIC, &t); return (uint64_t)t.tv_sec * 1000000000ull + (uint64_t)t.tv_nsec; }

static int recv_exact(int fd, void *buf, size_t n){
    uint8_t *p = buf; while (n){ ssize_t r = recv(fd, p, n, 0); if (r <= 0) return -1; p += r; n -= (size_t)r; } return 0; }
static int send_all(int fd, const void *buf, size_t n){
    const uint8_t *p = buf; while (n){ ssize_t r = send(fd, p, n, MSG_NOSIGNAL); if (r <= 0) return -1; p += r; n -= (size_t)r; } return 0; }
static int recv_u32(int fd, uint32_t *v){ return recv_exact(fd, v, 4); }

typedef struct { uint32_t addr, n; uint32_t *data; } write_t;
typedef struct { uint32_t off, value; } reg_t;
typedef struct { uint32_t addr, wps; uint32_t *out; uint32_t n_out; } chan_t;
typedef struct {
    uint32_t n_writes; write_t *w;
    uint32_t n_regs;   reg_t   *r;
    uint32_t nshots, n_chans; chan_t *c;
} circuit_t;

typedef struct {
    uint32_t K, flags, accbuf_len, off_nshot, off_dspreset, off_resetacc, off_start, off_lsd;
    circuit_t *circ;
} batch_t;

static void free_batch(batch_t *b){
    if (!b->circ) return;
    for (uint32_t i = 0; i < b->K; i++){
        circuit_t *c = &b->circ[i];
        for (uint32_t j = 0; c->w && j < c->n_writes; j++) free(c->w[j].data);
        for (uint32_t j = 0; c->c && j < c->n_chans; j++) free(c->c[j].out);
        free(c->w); free(c->r); free(c->c);
    }
    free(b->circ); b->circ = NULL;
}

/* bounds: word addresses inside the 64 MiB bramctrl window; dspregs offsets inside 64 KiB */
static int bram_ok(uint32_t addr, uint32_t n){ return (uint64_t)addr + n <= BRAMCTRL_SIZE / 4; }
static int reg_ok(uint32_t off){ return off < DSPREGS_SIZE / 4; }

static uint32_t recv_batch(int fd, batch_t *b){
    uint32_t h[8];
    if (recv_exact(fd, h, sizeof h)) return E_PROTO;
    b->K = h[0]; b->flags = h[1]; b->accbuf_len = h[2];
    b->off_nshot = h[3]; b->off_dspreset = h[4]; b->off_resetacc = h[5]; b->off_start = h[6]; b->off_lsd = h[7];
    if (b->K < 1 || b->K > 4096 || b->accbuf_len < 2) return E_RANGE;
    if (!reg_ok(b->off_nshot) || !reg_ok(b->off_dspreset) || !reg_ok(b->off_resetacc) || !reg_ok(b->off_start) || !reg_ok(b->off_lsd)) return E_RANGE;
    b->circ = calloc(b->K, sizeof *b->circ);
    if (!b->circ) return E_NOMEM;
    for (uint32_t i = 0; i < b->K; i++){
        circuit_t *c = &b->circ[i];
        if (recv_u32(fd, &c->n_writes) || c->n_writes > 65536) return E_PROTO;
        c->w = calloc(c->n_writes ? c->n_writes : 1, sizeof *c->w);
        if (!c->w) return E_NOMEM;
        for (uint32_t j = 0; j < c->n_writes; j++){
            uint32_t hdr[2];
            if (recv_exact(fd, hdr, 8)) return E_PROTO;
            c->w[j].addr = hdr[0]; c->w[j].n = hdr[1];
            if (c->w[j].n == 0 || c->w[j].n > (1u << 20) || !bram_ok(hdr[0], hdr[1])) return E_RANGE;
            c->w[j].data = malloc((size_t)c->w[j].n * 4);
            if (!c->w[j].data) return E_NOMEM;
            if (recv_exact(fd, c->w[j].data, (size_t)c->w[j].n * 4)) return E_PROTO;
        }
        if (recv_u32(fd, &c->n_regs) || c->n_regs > 1024) return E_PROTO;
        c->r = calloc(c->n_regs ? c->n_regs : 1, sizeof *c->r);
        if (!c->r) return E_NOMEM;
        for (uint32_t j = 0; j < c->n_regs; j++){
            uint32_t hdr[2];
            if (recv_exact(fd, hdr, 8)) return E_PROTO;
            if (!reg_ok(hdr[0])) return E_RANGE;
            c->r[j].off = hdr[0]; c->r[j].value = hdr[1];
        }
        if (recv_u32(fd, &c->nshots) || recv_u32(fd, &c->n_chans)) return E_PROTO;
        if (c->nshots < 1 || c->n_chans > 64) return E_RANGE;
        c->c = calloc(c->n_chans ? c->n_chans : 1, sizeof *c->c);
        if (!c->c) return E_NOMEM;
        for (uint32_t j = 0; j < c->n_chans; j++){
            uint32_t hdr[2];
            if (recv_exact(fd, hdr, 8)) return E_PROTO;
            c->c[j].addr = hdr[0]; c->c[j].wps = hdr[1];
            if (c->c[j].wps < 1 || c->c[j].wps > b->accbuf_len) return E_RANGE;
            c->c[j].n_out = 0;
            if (!(b->flags & F_READOUT_DDR)){
                uint64_t total = (uint64_t)c->nshots * c->c[j].wps;
                if (total > (1u << 28) || !bram_ok(c->c[j].addr, b->accbuf_len)) return E_RANGE;
                c->c[j].out = malloc((size_t)total * 4);
                if (!c->c[j].out) return E_NOMEM;
            }
        }
    }
    return E_OK;
}

/* C1 batches: dma_server writes the number of drained circuits (one line per circuit) to this file; std_server
 * truncates it at BATCH start (readout_ddr) and waits for it before starting circuit i >= 1 */
#define C1_DRAINED_FILE "/dev/shm/qubic_c1_drained"
#define C1_STARTED_FILE "/dev/shm/qubic_c1_started"   /* std_server appends one line per circuit start (after the CUR_ADDR reset); dma_server waits for it */
static int c1_drained_count(void){
    FILE *f = fopen(C1_DRAINED_FILE, "r"); if (!f) return 0;
    int n = 0, ch; while ((ch = fgetc(f)) != EOF) if (ch == '\n') n++;
    fclose(f); return n;
}
/* ---- the measured path (plan D3a) ---- */
/* One outstanding AXI transaction at a time. The bramctrl slave is the custom axi4_lb localbus (combinational
 * BID/RID, fixed-latency RVALID without hold — dossier 11): it tolerates the Python path, which issues one
 * MMIO access per interpreter step, but back-to-back posted stores from a C loop (several outstanding AW/W
 * beats) wedged the PS bus on 2026-08-29 (three watchdog reboots). `dsb sy` after every Device-nGnRE access
 * waits for the write response / read data before the next access is issued — the same one-at-a-time
 * structure as the Python path's stores, without its per-word interpreter cost. Reads of the accbufs use plain
 * 64-bit loads like numpy's memmap slice in the Python path (see run_batch). */
#define MMIO_SYNC() __asm__ volatile("dsb sy" ::: "memory")
static inline void mmio_wr(volatile uint32_t *p, uint32_t v){ *p = v; MMIO_SYNC(); }
static inline uint32_t mmio_rd(volatile uint32_t *p){ uint32_t v = *p; MMIO_SYNC(); return v; }
static inline void reg_wr(uint32_t off, uint32_t v){ mmio_wr(dspregs + off, v); }
static inline uint32_t reg_rd(uint32_t off){ return mmio_rd(dspregs + off); }

static uint32_t run_batch(batch_t *b, uint64_t *t_start, uint64_t *t_end, uint64_t *words_written){
    uint64_t nw = 0;
    int ddr = (b->flags & F_READOUT_DDR) != 0;
    if (ddr){ FILE *f = fopen(C1_DRAINED_FILE, "w"); if (f) fclose(f); f = fopen(C1_STARTED_FILE, "w"); if (f) fclose(f); }   /* reset both counts */
    *t_start = now_ns();
    for (uint32_t i = 0; i < b->K; i++){
        circuit_t *c = &b->circ[i];
        /* 1+2. load_executable: zero programs + command memories, one MMIO store per 32-bit word */
        TRACE("circuit %u: %u writes\n", i, c->n_writes);
        for (uint32_t j = 0; j < c->n_writes; j++){
            TRACE("  write %u: addr_words=0x%x n=%u\n", j, c->w[j].addr, c->w[j].n);
            volatile uint32_t *dst = bram + c->w[j].addr;
            const uint32_t *src = c->w[j].data;
            for (uint32_t k = 0; k < c->w[j].n; k++) mmio_wr(dst + k, src[k]);
            nw += c->w[j].n;
        }
        /* 3. executable registers */
        for (uint32_t j = 0; j < c->n_regs; j++) reg_wr(c->r[j].off, c->r[j].value);
        if (ddr && i > 0){
            /* C1 batches: the readout writer parks at its base after every circuit, so circuit i may only start
             * once dma_server has drained circuit i-1 (it appends the count to C1_DRAINED_FILE). PS-local wait,
             * no host round trip inside the interval. */
            uint64_t t0w = now_ns();
            while ((uint32_t)c1_drained_count() < i){
                if ((now_ns() - t0w) > (uint64_t)(CHUNK_TIMEOUT_S * 1e9)) return E_TIMEOUT;
                usleep(50);
            }
        }
        if (ddr){
            /* C1 (run.py ddr_start_circuit): clear stale SHOT_DONE (clear-on-read) / FINAL_ADDR / CUR_ADDR
             * so the readout writer restarts at its base for this circuit */
            (void)mmio_rd(axil + 0x1C / 4);
            mmio_wr(axil + 0x18 / 4, 0);
            mmio_wr(axil + 0x20 / 4, 0);
            { FILE *f = fopen(C1_STARTED_FILE, "a"); if (f){ fputc('\n', f); fclose(f); } }   /* registers reset: dma_server may poll this circuit */
        }
        /* 4. run_circuit: chunks of shots_per_run = accbuf_len // max words_per_shot */
        uint32_t wps_max = 1;
        for (uint32_t j = 0; j < c->n_chans; j++) if (c->c[j].wps > wps_max) wps_max = c->c[j].wps;
        uint32_t shots_per_run = c->n_chans ? b->accbuf_len / wps_max : c->nshots;
        if (shots_per_run < 1) shots_per_run = 1;
        uint32_t n_runs = (c->nshots + shots_per_run - 1) / shots_per_run;
        for (uint32_t r = 0; r < n_runs; r++){
            uint32_t chunk = (r < n_runs - 1) ? shots_per_run : c->nshots - r * shots_per_run;
            /* start_program */
            TRACE("  run %u/%u: chunk=%u start_program\n", r + 1, n_runs, chunk);
            reg_wr(b->off_nshot, chunk);
            reg_wr(b->off_dspreset, 0);
            reg_wr(b->off_resetacc, 1);
            usleep(POLL_US);
            reg_wr(b->off_resetacc, 0);
            usleep(POLL_US);
            reg_wr(b->off_start, 0);
            /* wait_and_readback: poll lastshotdone every 1 ms */
            uint64_t t0 = now_ns();
            while (reg_rd(b->off_lsd) == 0){
                usleep(POLL_US);
                if ((now_ns() - t0) > (uint64_t)(CHUNK_TIMEOUT_S * 1e9)) return E_TIMEOUT;
            }
            TRACE("  lastshotdone seen after %.3f ms\n", (now_ns() - t0) / 1e6);
            if (!ddr){
                for (uint32_t j = 0; j < c->n_chans; j++){
                    chan_t *ch = &c->c[j];
                    TRACE("  read chan %u: accbuf_words=0x%x n=%u\n", j, ch->addr, chunk * ch->wps);
                    uint32_t nreads = chunk * ch->wps;           /* words; always even here (2 words/entry) */
                    /* accbuf readback like the Python path (numpy slice of the pynq MMIO memmap = plain 64-bit
                     * loads, no barrier between them; board-proven for years): the entries are 64-bit and
                     * 8-byte aligned, nreads is even */
                    volatile uint64_t *src = (volatile uint64_t *)(bram + ch->addr);
                    uint64_t *dst = (uint64_t *)(ch->out + ch->n_out);
                    for (uint32_t k = 0; k < nreads / 2; k++) dst[k] = src[k];
                    MMIO_SYNC();
                    ch->n_out += nreads;
                }
            }
        }
    }
    *t_end = now_ns();
    *words_written = nw;
    return E_OK;
}

static void serve(int fd){
    char cmd[4];
    if (recv_exact(fd, cmd, 4) || memcmp(cmd, "BATC", 4)){ uint32_t st = E_PROTO; send_all(fd, &st, 4); return; }
    batch_t b; memset(&b, 0, sizeof b);
    uint32_t st = recv_batch(fd, &b);
    TRACE("BATC received: K=%u flags=%u accbuf_len=%u regs nshot=%u dspreset=%u resetacc=%u start=%u lsd=%u -> status %u\n",
          b.K, b.flags, b.accbuf_len, b.off_nshot, b.off_dspreset, b.off_resetacc, b.off_start, b.off_lsd, st);
    if (send_all(fd, &st, 4) || st != E_OK){ free_batch(&b); return; }
    uint64_t ts = 0, te = 0, nw = 0;
    st = run_batch(&b, &ts, &te, &nw);
    printf(">>> [STD] K=%u flags=%u status=%u elapsed=%.3f ms words=%llu\n", b.K, b.flags, st,
           (double)(te - ts) / 1e6, (unsigned long long)nw);
    if (send_all(fd, &st, 4) || send_all(fd, &ts, 8) || send_all(fd, &te, 8) || send_all(fd, &nw, 8)){ free_batch(&b); return; }
    if (st == E_OK && !(b.flags & F_READOUT_DDR)){
        for (uint32_t i = 0; i < b.K; i++)
            for (uint32_t j = 0; j < b.circ[i].n_chans; j++){
                chan_t *ch = &b.circ[i].c[j];
                if (send_all(fd, &ch->n_out, 4) || send_all(fd, ch->out, (size_t)ch->n_out * 4)){ free_batch(&b); return; }
            }
    }
    free_batch(&b);
}

int main(void){
    setvbuf(stdout, NULL, _IOLBF, 0);
    signal(SIGPIPE, SIG_IGN);
    uint32_t port = 8082; { const char *e = getenv("SS_PORT"); if (e) port = (uint32_t)strtoul(e, 0, 0); }
    g_trace = getenv("SS_TRACE") != NULL;
    { const char *e = getenv("SS_CHUNK_TIMEOUT_S"); if (e) CHUNK_TIMEOUT_S = atof(e); }
    int fd = open("/dev/mem", O_RDWR | O_SYNC);
    if (fd < 0){ perror("/dev/mem"); return 1; }
    bram    = mmap(NULL, BRAMCTRL_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, BRAMCTRL_BASE);
    dspregs = mmap(NULL, DSPREGS_SIZE,  PROT_READ | PROT_WRITE, MAP_SHARED, fd, DSPREGS_BASE);
    axil    = mmap(NULL, AXIL_SIZE,     PROT_READ | PROT_WRITE, MAP_SHARED, fd, AXIL_BASE);
    if (bram == MAP_FAILED || dspregs == MAP_FAILED || axil == MAP_FAILED){ perror("mmap"); return 1; }
    int lfd = socket(AF_INET, SOCK_STREAM, 0);
    int one = 1; setsockopt(lfd, SOL_SOCKET, SO_REUSEADDR, &one, sizeof one);
    struct sockaddr_in a = {0}; a.sin_family = AF_INET; a.sin_addr.s_addr = htonl(INADDR_ANY); a.sin_port = htons((uint16_t)port);
    if (bind(lfd, (struct sockaddr *)&a, sizeof a) || listen(lfd, 4)){ perror("bind/listen"); return 1; }
    printf(">>> [STD] std_server listening on %u\n", port);
    for (;;){
        int cfd = accept(lfd, NULL, NULL);
        if (cfd < 0) continue;
        setsockopt(cfd, IPPROTO_TCP, TCP_NODELAY, &one, sizeof one);
        serve(cfd);
        close(cfd);
    }
}
