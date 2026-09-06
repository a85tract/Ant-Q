# Ant-Q re-measurement (2026-08-29, real streams + closed timing 2026-08-30/31) — results folder

> 2026-09-02 addendum: three further measurements (pool-wide tables for heterogeneous batches, early stop on C3,
> the six physics experiments incl. sub-circuit streams) — method: README_20260901_addendum.md, results:
> report_20260902.md, tables table4_pool*.csv, table_stop.csv, table2_phys.csv, raw rows raw_runs_stop.csv /
> raw_runs_phys.csv (raw_runs.csv header widened by 5 columns; pre-migration copy kept).

Plans: `~/agent_journals/antq_rerun_plan_20260829.md` (rev 5, APPROVED) and
`~/agent_journals/antq_real_stream_plan_20260830.md` (rev 3, APPROVED) — both Codex gpt-5.6-sol + Claude.
Scripts: `../scripts/antq_runner.py` (measurement), `make_tables.py`, `build_real_vs_surrogate.py`,
`nonmatching_mechanism.py`. Nothing in the LaTeX was changed; these CSVs are for review first.

## Real command streams + closed-timing image (2026-08-30/31) — the headline campaign
- **Workload**: the paper's own 20 circuits (`~/Desktop/benchmark_qce/circuits_le14.py`: FAST_RESET
  with `branch_fproc` feedback, real gates/SWAP networks, final READ), compiled against the
  benchmark 14q gate config. Compiled per-shot equals the paper's per-shot column to 2 decimals on
  all 20. Every channel reads **2×/shot** (reset read + final read) — counted from the compiled
  program (the assembler's `reads_per_shot` metadata is a constant-1 placeholder upstream).
- **Bitfiles**: `std`/`c1` on the C1 image (0071783e_14q, WNS +0.002); `c3` on the **closed** 14_2 C3
  image `63329aaf` — **WNS 0.000 / TNS 0.000, 0 of 1.21 M endpoints failing, hold clean** — verified
  on the board by T2 (DDR==accbuf bit-exact, 14 qubits) and T11 (CE). No row in `table3/table4` is
  `provisional` any more. Tags: `std_14q_real1`, `c1_14q_real1`, `c3_14q_real2` (headline);
  `c3_14q_v6` = surrogate re-run on the same closed image (its equivalence partner); v5/real1 on the
  old −0.277 image stay in `raw_runs.csv` as history.
- **Equivalence vs the surrogate campaign** (`real_vs_surrogate.csv`; margin M = max(1 % QPU,
  0.15 ms) predefined; verdict = whole Welch-95 %-CI inside ±M; populations per the plan):
  **c3: 18 EQUIVALENT + 4 INCONCLUSIVE (|diff| ≤ 0.11 ms), 0 NON-MATCHING** — the readout-sim
  surrogate and the real streams give the same C3 numbers. `c1`: 17 EQ + 4 INC + 2 NON-MATCHING
  (Grover +1.0 ms, ghz8×30 +2.4 ms — larger command streams paid in bramctrl stores). `std`: all
  22 cells NON-MATCHING **by mechanism** — real circuits read back 2× the accbuf words; observed
  +7…+100 ms, predicted by extra words × 1.018 µs/word (calibrated on Bell; per-cell numbers in
  `nonmatching_mechanism.csv`). Direction confirmed everywhere; out-of-sample magnitude within
  0.8–4.4× (secondary terms: 512-shot chunking, per-run restarts). LIMITATION: surrogate sets are
  historical (same bitfiles/services, hours earlier, not interleaved) — comparison, not causal proof.
- **Heterogeneous random batches are NOT equivalence cells (finding E2)**: real circuits' per-core
  qdrv env tables differ by CNOT set (113/190 pairs incompatible), so a random batch splits into
  5–30 table-compatible hardware groups with an env/freq reload between groups (Python RPC, inside
  the interval): rand30 real ≈ 7–10 s vs ≈ 3.1 s surrogate. The two homogeneous manifests
  (ghz8×30, qaoa12×30) run as ONE hardware group and ARE equivalent. The C1/std paths load tables
  per job in C and pay far less (rand10 c1 ≈ +14 % over QPU). Continuous heterogeneous batching
  needs canonical env-table layouts — future work, documented, not built. Grouped mode also
  multiplies exposure to the known rare mid-batch wedge (~15× more hardware-batch starts per run;
  service-restart + retry recovers; every attempt is in `raw_runs.csv`).
- **circuit_not_ready (CNR) instrument**: every c3 run/group logs the PL detector (reg40[3] sticky,
  reg41 wait counter) to `cnr_log.csv` via batch_server's stat: **0 asserts across all runs and
  hardware groups** (real1: 342/342 runs logged; real2 likewise; meaningful evidence = the
  homogeneous 30-circuit batches' 29 boundaries × 5 runs each; single-circuit groups are trivially 0).

## Files
| file | what |
|---|---|
| `shots_verification.csv` | the 20 circuits: table value before, shots found in the cited source, shots used in the rerun, provenance and note (see below) |
| `batch_manifest.csv` | the immutable 32 batches (`random.seed(42)`, `random.choices(pool20, k)`, k = 10/20/30 x 10 trials, plus GHZ-8 x 30 and QAOA-MaxCut-12Q x 30), reused by every mode |
| `raw_runs.csv` | one row per attempt, never deleted (status ok / timeout / data_mismatch / superseded; warm-up runs have repeat = -1 and are excluded) |
| `table3_single.csv` | per circuit x mode: n, mean, sample s.d. (ddof = 1), QPU time, Δ ms, Δ % |
| `table4_batch.csv` | per batch x mode, plus per-size aggregates (mean over the 10 batch means; s.d. ACROSS batches) and the C3-vs-baseline throughput gain |
| `log_*.txt` | runner logs |
| `per_shot_realized_real.csv` | realized per-shot length of the REAL programs on the C1 bitfile (slope method, mean of 3); the `delta_real` denominators of the headline tables |
| `cnr_log.csv` | one row per c3 run × hardware group: `circuit_not_ready` flag + wait counter (all 0) |
| `real_vs_surrogate.csv` | per-cell surrogate-vs-real comparison: means, s.d., Welch 95 % CI, margin, verdict (equivalence populations) or descriptive rows (random batches, with `n_groups`) |
| `nonmatching_mechanism.csv` | the plan's "cheap test" on every NON-MATCHING cell: observed vs predicted extra time from the extra MMIO words |
| `paper_experiment_review_codex_20260830.md` / `..._kimi_20260830.md` | the two independent reviews of the paper's experimental sections (12 + 16 findings, both NEEDS-CHANGES) |

## Shot counts (task 2)
- Teleportation: the cited IBM lesson code sets `nshots = 1000`; the QCE table said 1024 — corrected to **1000**.
- Deutsch–Jozsa and Bernstein–Vazirani: the cited IBM lesson runs `AerSimulator().run(qc, shots=1)`; no shot count is prescribed by the source. The rerun keeps 1024 = the Qiskit **Aer** default (`AerSimulator`, Aer `SamplerV2(default_shots=1024)`) for comparability with the QCE tables; the CSV records `source_shots = 1`, `rerun_shots = 1024`, provenance "comparability choice". (IBM Runtime's cloud SamplerV2 has no fixed documented default, so "IBM default" should not be claimed.)
- The other 17 counts are verbatim quotes from the papers and are unchanged.

## Modes (all timed on the PS in C, `CLOCK_MONOTONIC`)
| mode | downlink (commands PS→PL) | uplink (readout PL→PS) | bitfile |
|---|---|---|---|
| `std` | QubiC standard: BRAM command memories written word by word (`std_server.c`, C) | QubiC standard: accbuf MMIO reads in ≤1024-shot chunks | C1 build (keeps the BRAM path) |
| `c1` | QubiC standard (`std_server.c`) | Ant-Q DDR stream (`dma_server.c`) | C1 build |
| `c3` | Ant-Q DDR command ring (`batch_server.c`), CE on, early stop off | Ant-Q DDR stream (`dma_server.c`) | C3 build |

## Timing definition (plan D2)
- `t_start`: immediately before the first *transfer-initiating* PS operation for the measured circuit's commands — `std`/`c1`: the first `bramctrl` MMIO store of the first command word (`std_server.c: run_batch`); `c3`: the first image MM2S descriptor submit (`batch_server.c: feeder_thread`, the idle-program upload is batch preparation and not counted).
- `t_end`: immediately after the last readout word is in PS memory — `std`: the last accbuf MMIO load; `c1`/`c3`: return of the S2MM read that completes the expected byte count (`dma_server.c`). Stream end is detected on the PS (`c1`: SHOT_DONE, "STRM ... SD"; `c3`: batch_server's batch-done flag `/dev/shm/qubic_batch_done`, "STRM ... BD"); no host round trip is inside the interval.
- `c1` batches: one K-circuit BATCH on std_server (all commands staged) and one dma_server session for the K circuits (`STRM ... SDK K`); std_server starts circuit i+1 only after dma_server reports circuit i drained — a PS-local handshake, no host round trip. The C1 readout writer does not park: std_server resets CUR_ADDR/FINAL_ADDR before each start and dma_server arms its reads only after it has seen cur_addr at the base; a circuit is drained only after FINAL_ADDR (latched at SHOT_DONE) covers its byte count — the C1 reader is not safe at the write frontier, so the C1 uplink does not overlap execution (as in the prototype's C1 measurement). The runner rejects any interval shorter than 0.98 × nominal QPU (`data_mismatch`).
- Host→PS TCP: `std`/`c1` stage the whole ordered batch on the PS before `t_start`; `c3` pipelines image arrival with execution by design, so images arriving after `t_start` are inside the interval — the `c3` number is therefore a *pipelined-feed* measurement, conservative for C3, and the elapsed-time difference between modes must not be attributed solely to PS→PL transport.
- PS→host TCP during the interval (`c1`/`c3` stream concurrently): `send_block_us_max` / `send_block_us_total` per run; every attempt stays in `raw_runs.csv`; if a configuration's mean `send_block_us_total` exceeds 1 % of its mean elapsed time it is re-run as a block after the host cause is fixed (`superseded` marks the replaced set).
- Env/freq tables are loaded during the warm-up execution (`repeat = -1`), not re-sent for the measured circuit; QPU time = shots × per-shot schedule length (from the QCE benchmark table); Δ = elapsed − QPU.

## Workload label
Two workload generations share `raw_runs.csv`, distinguished by tag:
- Tags `*_v*`: `readout-sim` surrogate — the named circuit's compiled schedule length and readout
  width, NOT its command stream (the prototype's Table 3/4 method). One read per channel per shot.
- Tags `*_real*`: the paper's REAL circuits (see the headline section above) — real command streams,
  2 reads per channel per shot, per-shot time from the compiled schedule (equals the paper column).
`table3_single.csv`/`table4_batch.csv` now summarize the latest complete set per cell = the REAL
campaign (`std_14q_real1`/`c1_14q_real1`/`c3_14q_real2`). `cmd_bytes_logical` = the program's
command bytes; `cmd_bytes_transferred` = what the PS actually pushed (`std`/`c1`: 4 B × MMIO stores
incl. zero programs and, for heterogeneous real batches, per-job env/freq tables; `c3`: MM2S bytes after CE).

## The standard path in C (plan D3/D3b)
`std_server.c` performs exactly the Python path's PL operations (`run.py`: zero programs on every command memory, command words, `nshot`/`dspreset`/`resetacc` pulse with the 1 ms QubiC sleeps, `start`, 1 ms `lastshotdone` polls, accbuf reads in ≤1024-shot chunks), verified against the Python path on the host (`tests/test_std_client.py`, write list identical) and on the board (same word counts, |IQ| statistics within noise). One MMIO access is issued at a time (`dsb sy` after every access): the bramctrl slave is a custom localbus that tolerates only single outstanding transactions — a plain back-to-back C loop wedged the PS bus. The result characterises the fastest validated C path for this slave, not generic "C speed"; `mmio_words_written` counts the stores.

## Provisional label
Rows measured on a bitfile with WNS < 0 carry `provisional = yes` (C3 14_2: WNS −0.277 ns; C1 14_2: +0.002 ns, closed). Closure builds are running; the C3 tables are to be re-measured on a closed image before use as revision evidence.

## Two Δ columns (nominal vs realized workload)
`qpu_ms` = shots × per-shot from the QCE benchmark table (the paper's definition). The DSP's shot loop makes every
readout-sim shot 0.15–0.18 µs longer than its compiled schedule (shot restart between shots) — measured on the
**C1 bitfile's standard DSP loop** (BRAM commands, `lastshotdone`-ended interval, no Ant-Q pipeline involved) as
(interval(50100 shots) − interval(100 shots)) / 50000, mean of 3, s.d. ≤ 0.002 µs: `per_shot_realized.csv`
(`per_shot_c1_slope_us`; the compiled length and the C3-pipeline slope are listed for information). Tables carry
`delta_ms`/`delta_pct` (vs nominal, paper-comparable) and `delta_real_ms`/`delta_real_pct` (vs shots × realized
shot length) — the second is the control-electronics overhead proper, the same baseline for all three modes.

## C3 server structure (prototype-style, final sets `c3_14q_v5`)
batch_server issues GLOBAL_START as soon as the FIRST unit is in the DDR ring and keeps feeding the ring during
execution (the prototype's behaviour; the ring's credit handshake absorbs the writes); the feeder polls batch_done
with `sched_yield`; dma_server polls with `sched_yield` while a stream is active and ends a C3 stream on the
writer's park (cur_addr back at its base) itself. Per-circuit fixed cost ≈ 0.1 ms. Cost: 1 mid-batch wedge in
~200 batches (hardware batch never completed — the residual wedge noted in dossier 02; the PL must be reloaded),
handled by the resilient driver (service restart, batch retried once); such attempts stay in raw_runs.csv as
`timeout` / `data_mismatch`.

## Acceptance criteria applied
- Interval sanity: every accepted row has elapsed ≥ 0.98 × nominal QPU (a shorter interval means a stream ended
  early; such attempts are `data_mismatch`).
- `send_block_us_max` / `send_block_us_total` are the time inside dma_server's `send()` calls (per call, summed):
  they measure send-call time, not host back-pressure. Outcome of the plan's ≤ 1 % criterion on the summed value:
  `std` 0 % (no concurrent stream); `c1` 0.50 % (batches) / 0.53 % (singles), 3 of 52 single configurations at
  1.0–1.3 %; `c3` 5.5 % (singles) / 6.2 % (batches) for every configuration (thousands of small chunk sends, one
  per 200 µs poll, max 240 µs per call). The criterion as written did not separate back-pressure from ordinary
  send-call time and is retired; no set was superseded. What remains true and must be read with the tables: the
  `c1` and `c3` intervals include whatever interference the concurrent PS→host streaming (send calls in the DMA
  thread, TCP through the SSH tunnel) had on the DMA loop, while `std` streams nothing during its interval — so the
  reported C3-vs-std and C1-vs-std differences are conservative for Ant-Q, not a pure PS↔PL comparison.
- std path validation (plan D3a): the write list equals the Python path's MMIO store sequence word for word
  (`tests/test_std_client.py`, host); on the board, for a 2-qubit (8_2) and the 14-qubit program (14_2 C1 image,
  1000 shots), word counts match and |IQ| per channel agrees with the Python path within noise (0.97–1.03 at 1000
  shots; live acquisitions are not bit-reproducible). Access counts per run: stores = `cmd_bytes_transferred / 4`
  (each followed by `dsb sy`) + 6 register writes per ≤1024-shot chunk; loads = `readout_bytes / 8` 64-bit loads per
  chunk (plain loads, one `dsb sy` per chunk — the Python path's `mmio.array[a:b]` numpy slice is the same plain-load
  pattern) + one `lastshotdone` poll per ms.

## C3 batch start policy (as measured)
The whole batch is staged in the PS CMA FIFO before the first MM2S (host upload outside the interval); GLOBAL_START
after the first unit is in DDR; the remaining MM2S transfers overlap execution. Host→PS→DDR is back-pressured at every
stage (TCP, PS CMA FIFO, ring credit), so batches larger than the FIFOs stream dynamically during execution.
Final C3 sets: `c3_14q_v5` (see 'C3 server structure'); the earlier `c3_14q_v1..v4` sets (usleep polls, start after all
K images, 0.23–0.55 ms fixed per circuit) are kept in raw_runs.csv as superseded.

- 2026-09-03 addendum: `report_20260903_addendum.md` -- (D) single-circuit fixed-cost decomposition (batch_server v7 stage timestamps; table_decomp.csv, raw_runs_decomp.csv), (E) RQ3 statistics over 6 backends x 20 seeds (rq3/, table_rq3_cells.csv, sampling_floor.csv): the two 14-qubit FAIL circuits are undersampling-limited, not noise-limited.
- 2026-09-04: RQ3 v2 (`rq3_v2/`, `table_rq3_cells_v2.csv`): BeH2/QML templates re-parameterized (scripts/circuits_v2.py, benchmark_qce f2343ec) and exact noiseless reference; addendum section F. v1 results stay in `rq3/`.
- 2026-09-04: scope cadence metrology (`scope_cadence/`: raw records, per-capture pulse timestamps, cadence_summary.csv; scripts/scope_cadence.py): physical shot period = compiled period within 80 ns for the 6 us trace and the 2 ms repeated Ramsey; 141 ns fixed handover per command-buffer unit in the segment stream, no stall at 4096 boundaries. Addendum section G.
