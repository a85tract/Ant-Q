#!/bin/bash
# Start-threshold test: GLOBAL_START after 16 units are fed (16 x 47 us = 0.75 ms of PS-jitter tolerance, 0.13 ms of
# start latency) on the 46.8 us unit stream, 200 runs; then the #5 stream (5120 units) with the same threshold, 3 runs.
set -uo pipefail
cd /home/yicheng/Desktop/Ant-Q-experiments/scripts
export PATH=$HOME/anaconda3/envs/qubic_clean/bin:$PATH PYTHONPATH=/home/yicheng/Desktop/software_c3
LOG=../results/start_threshold.log
log(){ echo "$(date +%Y-%m-%dT%H:%M:%S) $*" | tee -a $LOG; }
scp /home/yicheng/Desktop/software_c3/scripts/batch_server.c computerC:/home/xilinx/software/scripts/ >> $LOG 2>&1
python - <<'PY' >> $LOG 2>&1
import run_phys_campaign as P, run_pool_campaign as C
C.restart_service(); C.switch_image('C3')
base = ['--pool-tables', '--seg-pulses', '1800', '--seg-cap', '1802', '--repeat-override', '1000']
P.cell('C3', 'c3', 5, 100, 'c3_14q_stalldiag4_start16', extra=base + ['--prefill', '16'])
P.cell('C3', 'c3', 5, 100, 'c3_14q_stalldiag4_start16', extra=base + ['--prefill', '16'])
P.cell('C3', 'c3', 5, 3, 'c3_14q_phys4_start16', extra=['--pool-tables', '--prefill', '16'])
P.cell('C3', 'c3', 6, 3, 'c3_14q_phys4_start16', extra=['--pool-tables', '--prefill', '16'])
PY
log "START THRESHOLD DONE"
