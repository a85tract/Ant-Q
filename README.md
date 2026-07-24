# Ant-Q: Breaking Memory Bottlenecks in Quantum Control Systems

Ant-Q is a memory-hierarchy design for FPGA-based quantum control systems (QubiC) that integrates on-board PL-DRAM with BRAM to transform the traditional punched-card workflow (load → execute → uplink, strictly sequential) into a pipelined workflow, while preserving deterministic inter-circuit timing.

This repository is the umbrella for our group's contributions around Ant-Q: it indexes the gateware and benchmark repositories (as git submodules), and hosts the materials that accompany the paper.

> **Breaking Memory Bottlenecks in Quantum Control Systems for More Precise Experiments and Higher Throughput Computing**
> Yicheng Guang, Neel Vora, Yilun Xu, Yueqi Chen, Gang Huang
> *University of Colorado Boulder & Lawrence Berkeley National Laboratory*

## Overview

Quantum control systems such as QubiC rely on BRAM for its single-cycle, deterministic access latency, but BRAM capacity on control boards is highly limited (4.75 MB on the ZCU216). This memory bottleneck forces a punched-card workflow that caps circuit depth and shot count, and leaves the QPU idle during circuit loading and readout transfer.

Ant-Q breaks this bottleneck by using PL-DRAM (4 GB on the ZCU216) as the main memory pool and repurposing BRAM as a cache layer, with ping-pong buffers absorbing DRAM's non-deterministic latency:

- **Downlink** (PS → PL-DRAM → PL-BRAM): circuit commands are stripped of padding, decomposed into per-DSP-core pipelines, batched into DRAM via AXI DMA, and streamed into per-core BRAM ping-pong buffers so the next circuit is always ready when the current one completes.
- **Uplink** (DSP → PL-BRAM → PL-DRAM → PS): readout IQ results are tagged, aggregated in a shared ping-pong buffer, drained to a DRAM ring buffer, and streamed to the host while remaining shots are still executing.
- **Early termination**: a host-side monitor evaluates streamed readout results (Total Variation Distance and Hellinger Fidelity) and terminates circuits mid-execution once noise dominates the outcome.

On a ZCU216 with 26 real-world experimental and computing circuits, Ant-Q enables deep 1Q/2Q randomized benchmarking and long-duration high-sampling-rate experiments that are infeasible under the QubiC 2.0 baseline, reduces the classical overhead of circuit loading and readout uplink from 22.90%–1417.05% of QPU time to near zero, and improves batch throughput by 42.98%.

## Repository Structure

| Path | Contents |
|---|---|
| [`gateware/`](https://gitlab.com/yguang1/gateware_qce) | Submodule — QubiC 2.0 gateware with Ant-Q Uplink integrated (ZCU216) |
| [`benchmark/`](https://gitlab.com/yguang1/benchmark_qce) | Submodule — benchmark suite: 6 physical experiments and 20 computing circuits, translated to QubiC-compatible pulse-level commands, plus the 14-qubit configuration |

## Getting Started

Clone with submodules:

```bash
git clone --recurse-submodules https://github.com/a85tract/Ant-Q.git
```

Or, if already cloned:

```bash
git submodule update --init --recursive
```

See the READMEs inside each submodule for build and usage instructions.

## Contribution Status

| Component | Location | Status |
|---|---|---|
| Ant-Q Uplink | [`gateware/`](https://gitlab.com/yguang1/gateware_qce) | Integrated with QubiC 2.0, publicly available |
| Ant-Q Downlink | — | Under stress testing; to be integrated into QubiC 3.0 |
| Benchmark suite | [`benchmark/`](https://gitlab.com/yguang1/benchmark_qce) | Publicly available |
| Early-termination monitor | — | Host-side software service (TVD/HF convergence detection) |

Upstream project: [QubiC](https://gitlab.com/LBL-QubiC) — an open-source FPGA-based qubit control system developed at Lawrence Berkeley National Laboratory. Ant-Q is being integrated into the QubiC 3.0 release.

## Hardware Platform

- AMD Xilinx ZCU216 RFSoC evaluation board (Zynq UltraScale+, quad-core ARM Cortex-A53 PS + PL)
- DSP cores at 500 MHz; DRAM data paths at 333 MHz
- 14 drive / 14 readout channel configuration (up to 14 qubits per board)

## Acknowledgements

This work is supported by a collaboration between the US DOE and the National Science Foundation (NSF). This material is based upon work supported by the U.S. Department of Energy, Office of Science, National Quantum Information Science Research Centers, Quantum Systems Accelerator (Award No. DE-SCL0000121). Additional support is acknowledged from the NSF Safe-OSE program (Award No. 2533222).
