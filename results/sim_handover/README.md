# results/sim_handover/ -- output of the handover simulation

`handover_sim_output.txt`: the log lines of the two tests in `experiments/sim_handover/` (cocotb 2.0.1, Verilator 5.040):
DAC pulse start and end cycles, the cycle of each control event (processor done, pipeline drained, shot state machine
done, last shot done, sequencer read finished, start strobe), the DSP state changes, and for each boundary H in cycles
and ns.
