# results/resources/ -- FPGA resource utilization

Vivado 2022.1 placed-design utilization reports (`report_utilization` after placement, `Design State: Fully Placed`) of the
three 14-core ZCU216 builds compared in the paper's resource table. Only the host-name line of each report header is removed.

| File | Build | Source |
|---|---|---|
| `stock_91b77283_utilization_placed.rpt` | stock QubiC | official QubiC gateware commit `91b7728` (the point where `feat/ddr_mem` branched from `master`), `top/zcu216_14_2` configuration unchanged |
| `c1_0071783e_utilization_placed.rpt` | stock downlink + Ant-Q uplink | image `zcu216_14_2_c1_0071783e` of `benchmark/bitstreams/` |
| `c3_13b440c3_utilization_placed.rpt` | Ant-Q downlink + uplink | image `zcu216_14_2_c3_13b440c3` of `benchmark/bitstreams/` |

Rebuild the stock design: check out the gateware at `91b7728` with its submodules, then in `top/zcu216_14_2` run
`./configure_build.sh dsp_config.yaml`, `make pre` and `make` in the new build directory; the report is
`vivado_project/psbd/psbd.runs/impl_1/psbd_utilization_placed.rpt`.
