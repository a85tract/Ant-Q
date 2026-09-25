# results/ -- raw data

Only experiments that appear in the paper are included; every directory holds their raw rows and raw captures. No derived
tables, analysis output or conclusions are stored; the scripts in `experiments/` regenerate every derived quantity.

| Directory | Measurements | Image (see `benchmark/bitstreams/`) |
|---|---|---|
| `bench/` | Every bench experiment of the paper: steps A1-A7, A3b and A3r (single circuits, 30-circuit batches with and without pooled tables, the six physics experiments, oscilloscope cadence, fixed-cost decomposition, early stop), the command-buffer handover time, the batch-completion stress test, the command-refill condition, and the early-stop checkpoint cost on the PS | `zcu216_14_2_c3_13b440c3`, `zcu216_14_2_c1_0071783e` (baseline paths), `zcu216_8_2_c3_c26942c0` (refill sweep) |
| `resources/` | Vivado placed-design utilization reports of the stock, uplink-only and full Ant-Q 14-core builds (the paper's resource table) | stock QubiC gateware `91b7728`, `zcu216_14_2_c1_0071783e`, `zcu216_14_2_c3_13b440c3` |
| `device_x6y3/` | Real-device session on one qubit of an 8-qubit device: two-command-path comparison, command-buffer boundary, long randomized benchmarking | `zcu216_8_2_c3_c26942c0` (Ant-Q) and the operator's stock image |
| `rq3_v2/` | Simulator study: per-run outputs (`rq3_<backend>.csv`, one row per circuit and seed; `rq3_<backend>_s20-119.csv` for seeds 20-119) and checkpoint traces (`*_checkpoints.csv`) on six fake backends, the extended analysis (`rq3_extended.json`), and the circuit parameters (`angles_v2.json`) | none (simulation) |
| `sim_handover/` | Output of the command-buffer handover simulation (`experiments/sim_handover/`) | none (simulation of the 8-core configuration) |

Each measurement directory has its own README with the file list and the meaning of the identifying columns; the files
of `rq3_v2/` are described in the row above and in `experiments/rq3_noise_study/`.
