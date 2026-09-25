# Ant-Q: Breaking Memory Bottlenecks in Quantum Control Systems

Ant-Q is a memory-hierarchy design for the FPGA-based quantum control system QubiC. It uses the control board's PL-DRAM as
the main memory for circuit commands and readout results and keeps BRAM as a cache with ping-pong buffers: command images
stream from PL-DRAM into the BRAM command buffers, and readout results stream from the accumulators to PS memory during
execution.

> **Breaking Memory Bottlenecks in Quantum Control Systems for More Precise Experiments and Higher Throughput Computing**
> Yicheng Guang, Neel Vora, Yilun Xu, Yueqi Chen, Gang Huang
> *University of Colorado Boulder & Lawrence Berkeley National Laboratory*

This repository is the artifact of the paper: it pins the gateware, software and benchmark versions of the measurements
and holds the measurement scripts and the raw data. Derived quantities are regenerated from the raw rows by the scripts.

## Repository structure

| Path | What it is |
|---|---|
| [`gateware/`](https://gitlab.com/LBL-QubiC/gateware) | Submodule: QubiC gateware with the Ant-Q downlink (command streaming through PL-DRAM, ping-pong command buffers, command-supply witness) and uplink (readout streaming). |
| [`software/`](https://gitlab.com/LBL-QubiC/software) | Submodule: QubiC host software with the Ant-Q batch client (`qubic/rpc_client.py`) and the PS servers (`scripts/batch_server.c`, `scripts/dma_server.c`). |
| [`benchmark/`](https://gitlab.com/yguang1/benchmark_qce) | Submodule: the 20 computing circuits and 6 physics experiments as QubiC programs, their Qiskit twins, the shot-count sources, and `bitstreams/` -- the three ZCU216 images used (14-core Ant-Q, 8-core Ant-Q, 14-core uplink-only baseline) with their description files and checksums. |
| [`experiments/`](experiments/README.md) | Measurement and analysis code: `board/` (runner, campaign and acceptance drivers, table builders, site configuration), `device_x6y3/` (device programs and analysis), `rq3_noise_study/` (simulator study), `sim_handover/` (handover simulation). |
| [`results/`](results/README.md) | Raw rows and raw captures, one directory per measurement set. |

`git submodule status` shows the pinned commit of each submodule. `gateware` and `software` pin commits of the official
QubiC repositories (branch `feat/ddr_mem`, which holds the Ant-Q work). `gateware` pins `38543b7`, whose tree equals the build
commit of the 14-core Ant-Q image, `13b440c3`, except for one source comment; the build commits of the three images are tagged
in [yguang1/gateware](https://gitlab.com/yguang1/gateware): `antq-qst-c3-image-13b440c3`, `antq-qst-c3-8_2-image-c26942c0` and
`antq-qst-c1-image-0071783e`. `software` pins `29d123a`; the bench measurements ran the host client and PS servers of `7de69de`
(tag `antq-qst-software-7de69de` in [yguang1/software](https://gitlab.com/yguang1/software)). The PS server sources of the two
commits differ by one comment. The pinned host client defaults to the host name `localhost` instead of a numeric loopback address, takes
`ddr_cmd` and `num_ch` from the environment (`QUBIC_DDR_CMD`, `QUBIC_NUM_CH`) when a caller passes neither (unset: the previous
defaults, `False` and 8), and reports the byte position of a stream disconnect. `scripts/start_qubic_server.sh` is the start
script the bench board ran (each PS server pinned to its own core). The stock-path timing server and its client are in
`experiments/board/`. The acceptance run used `13492bf`, an ancestor of `7de69de`; the device session used `c97a261` and
`a83a733` (tag `antq-qst-software-a83a733`). Clone with submodules:

```bash
git clone --recurse-submodules https://github.com/a85tract/Ant-Q.git
```

## Data provenance

Every row of a `raw_runs*.csv` file names the gateware build the runner compiled against (`bitfile`; on the bench this
is the loaded image, for the device session's classic-path rows see `results/device_x6y3/README.md`) and the host client
commit (`software_commit`); the tag of the round is in `tag`. The images map to the result directories as follows.

| Image (`benchmark/bitstreams/`) | Result directories |
|---|---|
| `zcu216_14_2_c3_13b440c3` | `bench/` (`c3` rows, the oscilloscope captures, `stress/`, `refill/refill_sweep_13b440c3.csv`) |
| `zcu216_14_2_c1_0071783e` | `bench/` (`std` and `c1` rows) |
| `zcu216_8_2_c3_c26942c0` | `device_x6y3/` (`c3` rows; the `rpc` rows ran on the device operator's stock image), `bench/refill/refill_sweep_c26942c0.csv` |

The bench measurements use a ZCU216 without a quantum device attached; `device_x6y3/` was acquired on one qubit of an
8-qubit fixed-frequency transmon device. `distributed_processor` is the official QubiC commit `0653425` (branch
`feat/ddr_mem` of [LBL-QubiC/distributed_processor](https://gitlab.com/LBL-QubiC/distributed_processor): `c22cce8` plus the
`elem_cfg_pool` option of `GlobalAssembler`, the shared envelope/frequency table layout for heterogeneous batches; the
measurements used the identical tree). The simulator study records its package versions in every row.

## Reproducing

**Simulator study (no hardware).** Python 3.11+, `qiskit 2.3.1`, `qiskit-aer 0.17.2`, `qiskit-ibm-runtime 0.46.1`, `numpy`.
From `experiments/rq3_noise_study/`:

```bash
CIRCUITS=v2 REF=exact ./run_rq3_stats.sh       # 6 backends in parallel, seeds 0-19 -> results/rq3_v2/rq3_<backend>.csv
python make_rq3_tables.py                       # per-cell counts and stop checkpoints from those rows
python rq3_adequacy_gate.py                     # which circuits are evaluable at which checkpoint
```

**Hardware measurements.** A ZCU216 running one of the images in `benchmark/bitstreams/` (deployment notes in the benchmark
README) with the PS servers and the service start script (`start_qubic_server.sh`) of `software/scripts/`, and a host with `software/` on `PYTHONPATH` and that
`distributed_processor`. Fill in `experiments/board/site_env.sh` from `site_env.sh.example` (board address, ssh destinations,
build directories -- nothing site-specific is stored in the scripts), then:

```bash
cd experiments/board
export ANTQ_IMG=<slot> ANTQ_WNS_C3=<sign-off WNS>
source recampaign_env.sh
bash recampaign_accept.sh        # prepare the image; batch-completion stress; handover measurement
bash recampaign_run.sh A1        # campaign steps A1-A7 (with A3b, A3r), then the tables; 'A3b A3b' runs one step
python antq_runner.py --real --mode c3 --bits $GW --gw $GW --num-ch 14 --what single --idx 1,2,3 --repeats 5 --tag mytest
```

The runner appends rows to `$ANTQ_RESULTS/raw_runs*.csv`; `make_tables.py`, `make_pool_tables.py`, `make_phys_tables.py`
and `make_decomp_table.py` rebuild the tables from the rows.

**Tables and analyses from the published rows (no hardware).** With `software/` on `PYTHONPATH`, from the repository root:

```bash
export ANTQ_RESULTS=results/bench
for t in make_tables make_pool_tables make_phys_tables make_decomp_table; do python experiments/board/$t.py; done
D=results/device_x6y3
for b in EA1 EB1 EA2 EB2; do python experiments/device_x6y3/analyze_block.py $b $D; done
python experiments/device_x6y3/summarize_abab.py $D E                 # four-block table, the four comparisons, figure
python experiments/device_x6y3/boundary_analysis.py BNDF $D BND2     # boundary experiment
python experiments/device_x6y3/deep_rb_analysis.py DRB DRB DRA DRA --res $D
python experiments/device_x6y3/handover_scope_analyze.py hand_13b440c3 results/bench
python experiments/device_x6y3/make_device_figure.py $D              # the paper's device figure (after the two analyses above)
python experiments/board/make_stop_figure.py                         # the paper's early-stop figure (after make_phys_tables)
```

The builders and analyses write their outputs (`table*.csv`, `analysis/`, `*_analysis.json`) next to the data; these
paths are git-ignored, so the tracked files stay raw.

## Hardware platform

- AMD Xilinx ZCU216 RFSoC evaluation board (Zynq UltraScale+, quad-core ARM Cortex-A53 PS + PL), 4 GB PL-DDR
- DSP cores at 500 MHz; DDR data paths at 333 MHz; 14 drive / 14 readout channels (up to 14 qubits per board)
- Timing metrology: Tektronix MSO71254C on a drive DAC output

Upstream project: [QubiC](https://gitlab.com/LBL-QubiC), an open-source FPGA-based qubit control system developed at Lawrence
Berkeley National Laboratory.

## License

The files of this repository (scripts, data and documentation) are released under the BSD 3-Clause license (`LICENSE`).
The submodules keep their own licenses: `gateware/` and `software/` are QubiC (the Lawrence Berkeley National Laboratory
license in their `LICENSE` files), `benchmark/` is BSD 3-Clause, with the QubiC license reproduced for its bitstreams.
`experiments/sim_handover/vendor/` holds QubiC sources under `vendor/QUBIC_LICENSE`.

## Acknowledgements

This work is supported by a collaboration between the US DOE and the National Science Foundation (NSF). This material is based
upon work supported by the U.S. Department of Energy, Office of Science, National Quantum Information Science Research Centers,
Quantum Systems Accelerator (Award No. DE-SCL0000121). Additional support is acknowledged from the NSF Safe-OSE program
(Award No. 2533222).
