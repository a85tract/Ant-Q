# Addendum 2026-09-01/02 — three additional measurements (plan antq_three_experiments_plan_20260901.md)

NUMBERS ARE FILLED IN BY THE ANALYSIS SCRIPTS AT THE END OF THE CAMPAIGNS (see the CSVs named below); this file
records the method so the CSVs can be read.

## C. Heterogeneous batches with pool-wide tables (two-pass compilation)
- Mechanism: every program is assembled against ONE shared element-config pool (distproc GlobalAssembler
  `elem_cfg_pool`; runner `--pool-tables`: pass 1 assembles the 20 paper circuits in idx order, pass 2 re-assembles
  every measured program against the complete pool). Result: byte-identical env/freq tables on every core for all 20
  programs (`pool_tables/preflight_report.json`: 32/32 manifests = ONE hardware group; 114 remapped pulses verified
  byte-for-byte through native and pooled tables; smoke test `smoke_test.csv`: native-pooled |IQ| TVD == native-native).
- Configurations (all contemporaneous, 5 execution blocks, `pool_sequence.csv`): std_native (first-use tables,
  per-job stores inside the interval — the deployed baseline), std_pool, c1_native, c1_pool, c3_pool. Tags
  `std_14q_native_pool1`, `std_14q_pool1`, `c1_14q_native_pool1`, `c1_14q_pool1`, `c3_14q_pool1`.
- Timing definition D0 unchanged. Inclusion: integrity only (status ok); a cell = the latest complete set of 5.
- Estimands (`table4_pool_summary.csv`): G_stack = T_std_pool/T_c3_pool - 1 (same programs, Ant-Q stack vs QubiC
  stack), G_sys = T_std_native/T_c3_pool - 1 (deployed baseline), uplink-only ratios. Confirmatory: block-level t
  interval (df 4) of G_stack at k = 30, lower bound > 0; manifest-level df 9 interval reported as precision only;
  k = 10/20 exploratory. Reliability: `pool_reliability.csv`. Per-manifest rows: `table4_pool.csv`.
- Claim wording: "under this execution schedule the Ant-Q stack completed the heterogeneous batches faster than the
  QubiC stack on identical programs" (no drift-free causal claim; C1/C3 images are measured at different times).

## B. RQ3 early stop on C3 (PS-side pre-decided stop with emulated checkpoint delay)
- Mechanism (as the prototype's test_wr_stop.c): stop_at from the offline noise study (GHZ-3 2457/8192, GHZ-6
  60/128, GHZ-8 12/32, BeH2 1227/4096, QML 120/400, SrH 1200/4000); dma_server POL2 checkpoint walk: at every
  cp_step = N//10 landed shots the PS delays cp_ns = mean ARM kernel cost (busy-spin < 100 us, absolute-deadline
  clock_nanosleep otherwise; the delay actually elapsed is recorded as delay_actual_ns), then evaluates the stop;
  the guarded hardware stop (stop_ctrl) ends the circuit after the current shot. NO kernel executes and the host is
  NOT in the loop — this reproduces the prototype's timing model, nothing more.
- Runs (`stop_sequence.csv`): per circuit one warm-up of each condition, then 5 consecutive full/stop pairs (3/2
  first-condition split, seed 44); tag `c3_14q_stop1` (STRM_POLL_US 200) and `c3_14q_stop_poll0` (sched_yield
  cadence, GHZ-3 and GHZ-8 only). Rows: `raw_runs_stop.csv` (+ raw_runs.csv). Table: `table_stop.csv`: paired
  s_i = 1 - T_stop/T_full, mean + t CI (df 4), overshoot mean/range, hw latency, PS write->record, requested vs
  recorded delay, result class (FIRED / FIRED_NO_SAVING / NATURAL / NOT_ISSUED_LATE).

## A. Physics characterization experiments on the integrated image
- 1-4 (Vion T2*, Magesan IRB, Yan repeated Ramsey, Riste charge parity): one hardware shot, hardware loop of N
  reads (N = 50000 / 32 / 50000 / 8000), on c3 (63329aaf) and c1 (0071783e): warm-up + 3. std: 1/3/4 rejected at
  preflight (2N words > 2048-word accbuf), 2 runs. Rows `raw_runs_phys.csv`; table `table2_phys.csv`.
  Reference period P = the compiled loop period (inc_qclk operand x 2 ns: 103.648 us / 5.904 / 2003.648 / 8.932);
  calibration series (`calib_sequence.csv`, counts {N0, N0+D/2, N0+D} x 3, randomized order) -> P_meas +/- SE, F;
  reported: loop overhead P_meas - P with CI, E = N x P_meas + F, |mean - E| + t x SE_pred3 <= 1 ms + 100 ppm x E.
  Claim: complete acquisition (exact word count) with aggregate duration consistent with the programmed schedule —
  NOT per-read cadence. #2 is completion-only (32 us of schedule).
- 5-6 (Tornow restless RB depth 5101, Hughes 2Q RB depth 500): 10206 / 5012 pulses per core exceed the 2048-command
  slot (and the baseline's BRAM). Executed as SUB-CIRCUIT STREAMS per the paper's own sentence (design.tex:53-56):
  the unrolled body cut at gate boundaries into <= 2048-command segments (#5: 5, #6: 3; the accumulated Z phase is
  carried per drive frame, 0 pulse-phase mismatches vs the unbroken program; segment 0 carries the 1 us restless
  delay as a LEADING delay; each unit's phase_reset restarts the DDS time origin — a computable per-segment virtual
  Z, harmless to the timing claim); the K segment images are replayed R = shots times by batch_server (REPT), K x R
  = 5120 / 15000 units in ONE hardware batch. Evidence: sticky CNR flag (cleared at batch prep, read after the
  batch) = 0 -> no CNR-detected command starvation at any of the K x R - 1 boundaries; exact word counts; elapsed.
  Boundary dead time control: the first 1800 pulses of #5 as 1 unit/shot vs 2 units/shot (tag c3_14q_physctrl1):
  (elapsed_split - elapsed_unsplit) / 1024 = the deterministic per-boundary cost.
- std for 5/6: not executable as one circuit (capacity); the paper's cross stands on the 2048-command limit.
