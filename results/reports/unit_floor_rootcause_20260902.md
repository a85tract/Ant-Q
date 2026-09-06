# Root cause of the ~64 us per-unit floor (workflow synthesis, 2026-09-02)

All disagreements are now resolved against the sources. Summary of what I re-checked before writing:

- Post-fix data DOES exist (rows 296-311, sw 6e7888b) — finding 3's "not yet re-measured" is stale.
- `usleep(5)` is at batch_server.c:225 in 5d88c40 (grep -n); HEAD has `sched_yield()` at :229; `fed >= 1` at :239/:243; the 20 us re-check at :258/:262 sits behind `inflight() >= HW_CFG_DEPTH`.
- Clocks: dspclk 2.000 ns (500 MHz), both MIG ui_clks 3.001 ns / 333.25 MHz (timing rpt:173,179,186; both xci DDR4_UI_CLOCK 333250000) — findings 2/5's "300 MHz nominal" is superseded.
- Host default timer slack is 50000 ns (`/proc/self/timerslack_ns`); the launcher runs batch_server as a plain `&` process with no chrt/prctl anywhere in scripts/.
- Per-masked-channel fetch cost disagreements (13+L vs 54 vs 80-170 cycles) are all < 0.5 us and immaterial.

# Root-cause report: the ~63.5 us per-unit floor on Ant-Q C3 image 63329aaf

Scope: ZCU216, 14 drive channels, REPT/CE hardware batches. Data: `/home/yicheng/Desktop/Ant-Q-experiments/results/raw_runs_phys.csv` (rows cited by line number), `results/report_20260902.md` A.3, `results/floor_fix.log`, `proj_journal.md:88-99`. RTL: `/home/yicheng/gateware_yguang_check/gw_build_c3_8s/top/src/...`. PS: `/home/yicheng/Desktop/software_c3/scripts/batch_server.c` (line numbers given per commit; 5d88c40 is the `software_commit` of every anomalous row, 6e7888b is HEAD). Note: the brief's `qubic/rfsoc/rpc_client.py` does not exist; the file is `qubic/rpc_client.py`.

Labels: **MEASURED** (board data on disk), **DERIVED** (RTL/code/build files read here), **HYPOTHESIS** (not yet measured).

## 0. Verdict in one paragraph

The floor is not in the PL. It is the PS feeder's MM2S completion poll: `usleep(5)` in `mm2s_send` (batch_server.c:225 @5d88c40) sleeps ~57-63 us on the non-RT PS kernel (50 us default timer slack), and the CE/REPT path issues one MM2S per unit (:277-283) with `GLOBAL_START` pulsed after the first unit (:239), so the command ring is fed at most one unit per ~63.5 us (two sleeps = ~127 us when the image DMA outlasts the first sleep). The PL gate `mmu_writedown.v:502` (`!ddr_fifo_empty && !nshots_fifo_empty && pop_credit_avail`) makes the sequencer track the feeder, and the cnr_detector then correctly reports "bank not ready" with reg41 = T_feed − L. The fix (6e7888b, `sched_yield()` at :229, gateware unchanged) has already been measured: the 1024 × 46.8 us control fell from 63.3-65.8 us/unit to 47.0-47.1 us/unit with reg41 = 1 (rows 296-299).

## 1. Ranked candidate causes and the accounting each must satisfy

### 1.1 Constraints every candidate must meet (all MEASURED, raw_runs_phys.csv)

| # | cell | image / unit | unit L | period (elapsed/n) | reg41 (dsp cyc → us) | rows |
|---|---|---|---|---|---|---|
| M1 | 1+13 masked, 1024 units | 32 KiB | 46.81 us | 63.30-65.77 us | 7862-8918 → 15.7-17.8 (= 63.5 − 46.8) | 214-217, 235-238, 251-254 |
| M2 | 1+13, 2048 units | 32 KiB | 22.66/24.16 us | 63.25-65.07 us | 18990-19998 → 38-40 (= 63.5 − 23.4) | 239-242, 255-258 |
| M3 | 1+13, 5120 units (#5) | 32 KiB | 49-51 us | 63.22-64.79 us | 6744-7660 → 13.5-15.3 | 227-230, 243-246 |
| M4 | 2+12, 1024 units | 64 KiB | 46.81 us | 63.58-64.32 us | 8663-8966 | 267-270 |
| M5 | 7+7, 1024 units | 224 KiB | 46.81 us | 64.39-65.92 us | 8649-9902 | 263-266 |
| M6 | 14+0, 1024 units | 448 KiB | 46.81 us | **127.20-128.68 us** | 38935-40434 → 78-81 (= 127 − 46.8) | 259-262 |
| M7 | 2+12, 15000 units (#6) | 64 KiB | 140-147 us | 144.33 us = L + 0.17 | 1, CNR 0 | 231-234, 247-250 |
| M8 | 2+12, 65000 units (cap500) | 64 KiB | 12×35.6 + 3.5 us/shot | 63.75-64.86 us | 13599-14070 → 27-28 (= 64 − 35.6) | 273, 281 |
| M9 | 2+12, 35000 units (cap1000) | 64 KiB | 6×71.4 + 3.5 us/shot (432.5 us/shot) | 63.27-64.62 us avg | 1, CNR 1 | 292-293 |
| M10 | 200→20 us re-check change | — | — | no change (M1-M3 identical at fcefa3b and 5d88c40) | — | 214-258 |
| M11 | 8 unmasked, ring PREFILLED (2026-07-02, 8_2 image) | 8×32 KiB | D | seamless ≥ 31.5 us; wait = 14349 − 500·D → F = 28.7 us; ~27 us holes for ~1.5 us circuits | memory cbuf note:77-80, ddr_batch item 7 |
| M12 | board [BS-T] probe | ≤ 64 KiB first image | — | "first DMA done +0.063..0.068 ms" every batch | proj_journal.md:93-95 |
| M13 | post-fix (6e7888b) M1/M2/M3/M7 | — | — | 47.03-47.13 / 23.59-23.70 / 49.87 / 144.32 us per unit; reg41 = 1 | 296-311, floor_fix.log |

Key shape: the period is **flat at ~64 us from 1128 to 7224 fetched beats (M1, M4, M5) and steps to 2× only at 448 KiB (M6)**; it is a fixed **rate**, not a per-boundary latency (M9: a per-boundary 64 us floor predicts 5000 × (6×71.5 + 64) = 2465 ms; measured 2214-2262 ms; a 64 us/unit feed rate predicts 35000 × 63.5-64.5 = 2222-2258 ms).

### 1.2 Candidates

**C1 — PS feeder sleep quantum (ROOT CAUSE, MEASURED + CONFIRMED BY FIX)**

Mechanism (DERIVED from batch_server.c @5d88c40, re-read here):
- :239 `if (fed >= 1 || ...)` pulses GLOBAL_START after the first unit lands (commit 493d60f) → the feeder is inside the run.
- :277-283 CE path (`g_ch_mask` set; REPT asserts a mask, `qubic/rpc_client.py:262`) → **one `mm2s_send` per image**.
- :213-228 `mm2s_send`: 4 uncached MMIO writes (DMASR/DMACR/SA/LENGTH), one DMASR read (a 32 KiB DMA takes ~7 us, so it is never IDLE yet), then **:225 `usleep(5)`**. batch_server is launched as a plain `&` process (`scripts/start_qubic_server.sh:39`), no `chrt`/`sched_setscheduler`/`PR_SET_TIMERSLACK` anywhere in `scripts/` (grep). Default `timerslack_ns` = 50000 (host `/proc/self/timerslack_ns` = 50000; same default kernel setting on the PS — ASSUMED, consistent with M12 and with the 57-63 us `clock_nanosleep` overshoot in report_20260902.md:69). hrtimer hard expiry at t+55 us plus wake latency → return at ~57-63 us.
- PL side (DERIVED): ring count++ only on `stream_cmd_writer` `unit_done` (stream_cmd_writer.v:262-268 last channel's B response; masked channels skipped without a burst :200-208) → `ring_buffer_4chunk_ddr.v:39,51-54` → `mmu_writedown.v:502` pops config n+1 only when the image is in DDR. So the sequencer cannot run faster than the feeder.

Cycle accounting per unit (DERIVED, T_wake = 57-63 us): T_feed = MMIO (3 config wr32 :271-274 + 4 DMA wr32 + 2 rd32 + inflight rd32 ≈ 2-5 us) + n_sleeps × T_wake, n_sleeps = ceil(T_dma / T_wake).
- 32 KiB (T_dma 6-8 us) → 1 sleep → **60-68 us** (M1-M3: 63.2-65.8 ✓); reg41 = T_feed − L = 63.5 − 46.8 = 16.7 us ✓, 63.5 − 23.4 = 40 us ✓, 63.5 − 50 = 13.5 us ✓.
- 64 KiB → 1 sleep → 64 us (M4 ✓, M8 ✓ incl. reg41 = 64 − 35.6 = 28 us ✓; M7: T_feed 64 < L 140 → ring runs ahead → seamless ✓).
- 224 KiB (T_dma ≤ ~55 us) → 1 sleep → 64-66 us (M5 ✓, 1-3 % above M1 = DMA still inside the first wake).
- 448 KiB (T_dma 87-109 us) → 2 sleeps → ~120-128 us (M6 127.2-128.7 ✓; reg41 = 2 × 63.5 − 46.8 = 80 us ✓ — the strongest single confirmation).
- M9: feeder-bound average 7 × 64 = 448 us/shot > 432.5 us execution → 2222-2258 ms ✓ (a PL model gives 2465 ms ✗).
- M10: the 20 us `usleep` (:258) runs only when `inflight() >= HW_CFG_DEPTH` (1024, :125, :205-210); with the feeder slower than the PL, inflight stays ≤ g_group = 4 → branch never executes → null result by construction ✓. (In M7 it does run: 20 + 50 us slack = 70 us per re-check, still < 140 us units.)
- M11: 2026-07-02 sweep used the old `fed == K` rule (regime R1, `~/agent_journals/c2_dynamic_streaming_20260824.md:7`), feeder out of the loop → measured the PL-only fetch (see C2 numbers) ✓.
- M12: 63-68 us "first DMA done" for a ≤ 16 us transfer = one wake + MMIO ✓.
- M13: removing the sleep removes the floor with the gateware untouched ✓ (predicted 48.2 ms for M1, measured 48.15-48.26 ms).

MM2S rate bound (DERIVED from sleep-count constraints, UNCERTAIN): 256 KiB reported done at the first post-sleep poll (+63-68 us, `~/agent_journals/antq_fill_latency_plan_20260901.md:12`) → ≥ 4.2 GB/s; 448 KiB needed a second sleep → T_dma > ~57 us → < 8 GB/s; the HP0 leg is 128-bit after `axi_smc_mm2s` (bd_ddr_streaming.tcl:116-118), ≤ 5.3 GB/s if clocked ≤ 333 MHz. Working range **4.2-5.3 GB/s**; the "3.3 GB/s" (batch_server.c:14) and "4.0 GB/s" (fill-latency plan) figures are poll-quantised artifacts. Consequence: findings 2 (3.7-4.0) and 5's "8 unmasked post-fix = T_dma + F_pl = 93 us" are corrected below.

**C2 — PL serial fetch over 14 channels (~4.5 us/channel → 63 us) — REFUTED**

DERIVED (re-read here): `mmu_writedown.v:529-549` walks `rd_chan` 0..13 strictly sequentially (advance on `cf_chunk_done[rd_chan]`, one AR outstanding); a masked channel latches `idle_addr` and issues **one** burst of `arlen = SHORT_BEATS−1 = 7` (chunk_fetcher.v:7, :122, :141) and finishes after that burst (:177); an unmasked channel does 4 × 256 beats. Clocks: rd_clk = ddr4_0 ui_clk 333.25 MHz (timing rpt:179; xci DDR4_UI_CLOCK 333250000), 32 B/beat (gensrc:17). Cycle count with L_ar ≈ 43 cyc per burst (calibrated from M11: 28.7 us = 9564 cyc for 32 bursts → 299 cyc/burst) plus ~5 FSM cycles per channel:
- 1+13: 1128 beats + 17 × 43 + 70 ≈ 1930 cyc ≈ **5.8 us** (finding 4's sim: 5.7 us at AR latency 40, 8.8 us at 100)
- 2+12: ≈ 9.2 us; 7+7: ≈ 26 us; 8+0: ≈ 28.7 us (= M11 ✓); 14+0: ≈ 50.5 us.
Against the data: a fetch-bound period would be max(L, F_pl) = 46.8 us for M1/M4/M5 and 50.5 us for M6 — measured 64/64/65/127 ✗. Per-channel cost of a masked channel is ~13-60 cycles ≈ 0.04-0.2 us, 25-100× too small for 4.5 us. For F_pl(1+13) to reach 63.5 us, L_ar would have to be ~3.5 us per burst, 100× a DDR4 read and contradicted by M11 on the same smc+MIG topology. Post-fix upper bound: M13's seamless 22.7 us units → F_pl(1+13) < 22.7 us.

**C3 — a fixed ~60 us PL cost per unit boundary (ppbuf flip, CTRL_SWITCH, readout flush, DSP restart) — REFUTED**

DERIVED: boundary path is `cmd_sequencer.v:125-128` S_FIN → `ping_pong_buffer.v:92` able_to_read low for ~3 cycles → :249-257 local flip when `write_ready_rd` → `cmd_sequencer.v:115-120` S_WAIT→S_START; write side :187-207 flips on `write_finished && read_finished_reg_wr`; `mmu_writedown.v:552-557` CTRL_SWITCH→IDLE 1 cycle; pop credit +1 per synced stb_start (:246-263). Total ~10 dsp + ~11 rd cycles ≈ 50 ns. The readout flush (`N_shot_finished = ppbuf_read_finished[0]`, body.vh:221) only fires FLUSH_DELAY after the last circuit. No counter in `mmu/*.v` reaches 31,750 dsp cycles. MEASURED: reg41 = 1 cycle on every seamless run (M7, M13) → the boundary itself costs ~1 cycle.

**C4 — the config-FIFO-full re-check (200/20 us) — REFUTED** (see M10 accounting under C1).

**C5 — write-side (stream_cmd_writer) per-beat cost — REFUTED**: 7168 data beats (M5) land inside a 65 us period; per-beat cost would have to scale 3.4× between M4 and M5 and does not (DERIVED: bursts need only `fifo_level >= 256`, stream_cmd_writer.v:209).

## 2. Single most likely cause

**`/home/yicheng/Desktop/software_c3/scripts/batch_server.c:225` at commit 5d88c40 — `usleep(5)` in `mm2s_send`'s DMASR completion loop**, made critical by `:239` (GLOBAL_START at `fed >= 1`, since 493d60f) and `:277-283` (one MM2S per compact image in CE/REPT mode, since 1b60263). The PL merely enforces it at `mmu/mmu_writedown.v:502` and reports it via `mmu/cnr_detector.v:57,62,78-92` (reg41 = T_feed − L). Confidence: high — three independent MEASURED legs (flat mask sweep + 2× step at 448 KiB; board [BS-T] 63-68 us; the fix removing the floor with the same bitstream).

Timeline (git log, software_c3): 37e5b8c 08-29 15:52 poll 100 → 5 us; 493d60f 08-29 19:35 start at fed ≥ 1; 1b60263 09-01 REPT one-MM2S-per-image; 5d88c40 09-02 01:26 200 → 20 us (no-op); 6e7888b 09-02 11:53 sched_yield fix. The floor required all three preconditions and appeared only when they coexisted.

## 3. Decisive tests, ordered by cost

1. **Done (zero cost, MEASURED):** rows 296-311 / `results/floor_fix.log` — 6e7888b deployed 11:54 with the same bitstream: M1 48.15-48.26 ms (was 65.3; 1024 × 46.81 = 47.93), M2 48.31-48.55 ms (was 131), M3 255.3 ms (sum 254.5), M7 unchanged 2164.7 ms, reg41 = 1 everywhere, CNR 0 in 10/12 runs (2 runs latched CNR with wait 1 cycle = one transient boundary, see §4).
2. **Read a log line (~0 cost):** batch_server stdout `[BS-T] ... first DMA done +Y ms` on any post-fix batch: prediction Y ≈ 0.008-0.012 ms for a 32 KiB first image (was 0.063-0.068). For a 448 KiB (mask 0) and 256 KiB (GHZ-8) first image Y is now the true T_dma: prediction 87-109 us and 49-62 us → pins the MM2S rate (§1 uncertainty).
3. **Re-run two existing cells with the fixed server (~3 min, software knobs only):** `run_floor_diag.sh` mask 0 and mask 0x3F80 on 46.8 us units. Prediction: 14+0 drops 127.5 → ~90-114 us/unit (DMA-bound, still CNR 1, reg41 ≈ 45-65 us); 7+7 drops 64.4-65.9 → ~50-60 us/unit or seamless (max(46.8, T_dma(224 KiB) 43-53 + 2-5)). A 14+0 result staying at ~127 us would refute the two-sleep accounting. Also re-run cap500/cap1000 once the `floordiag3` server disconnect (rows 312-320, `data_mismatch`, unrelated to the floor) is fixed: prediction 2153-2163 ms.
4. **Quantum itself (1 min on the PS):** `cat /proc/$(pidof batch_server)/timerslack_ns` (expect 50000) and a 10-line `usleep(5)` loop (expect 55-65 us; ~10-15 us after `prctl(PR_SET_TIMERSLACK, 1000)`).
5. **Simulation: not decisive.** The quantum is Linux timer slack; a plsv/cocotb sim with a testbench feeder only shows the PL floor max(0, F_pl − L) = 0 for these units (finding 4's `tb_fetch.sv` already gives 5.7 us for 1+13). Only worth running if test 3 contradicts the PL numbers in §1 C2.

## 4. Fix candidates and expected floors

Floor model with live feeding (DERIVED): period = max(L + ~0.02 us, T_feed, F_pl), T_feed = T_dma + 2-5 us MMIO; F_pl and the next DMA overlap in steady state (finding 5's serial sum T_dma + F_pl applies only to single-unit latency).

| fix | change | 1+13 (32 KiB) | 2+12 (64 KiB) | 8+0 (256 KiB) | 14+0 (448 KiB) | status |
|---|---|---|---|---|---|---|
| none (5d88c40) | — | 63.5 | 63.5 | 64-68 (one sleep, borderline) | 127 | MEASURED except 8+0 (HYP) |
| **SW-1** `sched_yield()` poll (6e7888b, batch_server.c:229) | done | **~8-13 us** (MEASURED seamless at 22.7 us) | ~18-21 us | ~52-67 us (DMA-bound, HYP) | ~90-114 us (HYP) | deployed; cost: one core busy-polls for T_dma per unit — acceptable for a dedicated feeder thread |
| SW-2 `prctl(PR_SET_TIMERSLACK, 1000)` or SCHED_FIFO for the feeder thread | 1-3 lines | same as SW-1 | same | same | same | only if the sporadic CNR=1/wait=1 latches (2 of 12 post-fix runs, HYPOTHESIS: PS preemption) matter for the paper's "zero starvation" claim |
| SW-3 true prefill for K ≤ 1024 (`maybe_start` back to `fed == g_K`) | option flag | ~6 us (PL-only) | ~9 us | **28.7-31.5 us** (= M11) | ~50 us | reaches the PL-only floors for wide images; cost: batch start delayed by K × T_feed |
| RTL-1 parallel/multi-outstanding fetch across channels | large | ~4 us | ~4 us | ~4-8 us | ~4-8 us | not justified: only matters when the feeder is already out of the loop (SW-3) and wide images run ≥ 50 us units anyway |
| RTL-2 skip the 8-beat idle fetch for masked channels | small | saves ~13 × 0.2 = 2-3 us of F_pl | — | — | — | not justified: F_pl is hidden under T_feed |

Recommendation: SW-1 is the fix and is already in place; add SW-2 only if a residual CNR latch shows up in the final runs; SW-3 only for the 8/14-unmasked regimes if the paper needs the 31.5 us number under live conditions. No RTL change is warranted.

## 5. Uncertainties

- MM2S rate 4.2-5.3 GB/s is bracketed, not measured (test 3.2 fixes it); the post-fix 8+0 / 14+0 floors above inherit that range.
- Board `timerslack_ns` assumed to be the 50000 default (consistent with M12 and report:69, not read from the board).
- L_ar ≈ 43 rd cycles comes from the 2026-07-02 8_2-image calibration on a different build; ±30 % on F_pl is immaterial to the conclusion (F_pl ≤ 9 us for 1+13 either way).
- The 8+0 pre-fix cell (one vs two sleeps) was never measured live; findings disagree (64-68 vs 120-127 us); the 224 KiB result and the 256 KiB [BS-T] probe favour one sleep.
- Post-fix CNR=1 with wait=1 in 2/12 runs: attributed to PS scheduling jitter (HYPOTHESIS); a per-boundary wait histogram does not exist in this gateware.