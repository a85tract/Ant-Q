# results/device_x6y3/ -- real-device session (8-qubit fixed-frequency transmon device, one measured qubit)

Raw rows and per-run readout data of the device session. No derived tables, no analysis output and no conclusions are
stored here: `experiments/device_x6y3/` regenerates every derived quantity from these files.

| File | Contents |
|---|---|
| `raw_runs_phys.csv` | One row per program execution of the single-qubit programs (classifier preparations, phase fringe, fixed-cadence timing loop, paired Ramsey and its slope calibration, Clifford RB, the streamed and unbroken boundary programs, the long RB sweep). |
| `iq/` | One compressed `.npz` per successful run: the complex readout values as returned, keyed `c<circuit>_<channel>`. Shape `(shots, reads_per_shot)` for one-shot programs and `(1, reads)` for hardware-loop programs. |

Row identification: `tag` names the acquisition round, `workload_id` the program (`phys<idx>` refers to the program
index in `experiments/device_x6y3/aqt_programs.py`), `repeat` the repetition, `status` whether the run completed.
`mode` is the command path: `c3` = Ant-Q (image `zcu216_8_2_c3_c26942c0`), `rpc` = stock QubiC RPC on the operator's
stock image `694fa11a` (not part of this repository). `bitfile` names the gateware build whose description files the
runner compiled against; on `rpc` rows that is the Ant-Q 8-core build `d974f2e3`, not the loaded image. `shots`, `rps`,
`qpu_ms` are the requested shots, reads per shot and the compiled duration; `t_start_ns`/`t_end_ns` are board-side
timestamps on `c3` rows (first command image submitted, last readout data in PS memory) and host timestamps on `rpc`
rows, so `elapsed_ms` must be read together with `mode`. `software_commit` names the host client,
`seamless`/`cnr`/`cnr_wait_cycles` the command-supply witness of the streaming path.

Rounds present: the four alternating blocks of the two-command-path comparison, the boundary experiment (streamed and
unbroken programs with their classifier preparations) and the long RB sweep on both command paths. Only these rounds and programs are included; rows of other programs
acquired under the same tags were removed, so some tags hold fewer rows than the session produced.

The device chip configuration the programs were compiled with is the operator's calibration and is not included; the
calibrated pulses of the measured qubit are in `experiments/device_x6y3/pulses_q5_20260917.json`.

Session settings: every round compiled `experiments/device_x6y3/aqt_programs.py` with the pulses above (`ANTQ_QCHIP_PATCH`) and

    AQT_QUBIT=Q5 AQT_TAU_R_S=0.5e-6 AQT_RESET_S=500e-6 AQT_PAD_C=3.588e-6 AQT_PAD_B=1.998088e-3
    AQT_N_FRINGE=2048 AQT_N_A=20000 AQT_N_B_ITER=25000 AQT_RB_LENGTHS=2,4,8,16,32 AQT_RB_SEQS=8 AQT_RB_SHOTS=256

(the module's defaults differ). With these pulses the pads give a 6.000 us fixed-cadence period and a 4.000 ms Ramsey pair
(`qpu_ms` 48.0000 and 100000.0000). The boundary rounds (`BNDF`, `BND2`) added
`AQT_BOUNDARY=1 AQT_BFRINGE_N=2048 AQT_BRB_SHOTS=2048 AQT_BRB_LENGTHS=16,32,64,128 AQT_TAIL_S=12e-6`, the long RB sweep
(`DRA`, `DRB`) `AQT_RB_LENGTHS=16,32,64,128,256,512,1024,2048,5101 AQT_RB_SEQS=8 AQT_RB_SHOTS=2048 AQT_RB_TAIL=1
AQT_TAIL_S=12e-6 AQT_STREAM_ABOVE=900`.
