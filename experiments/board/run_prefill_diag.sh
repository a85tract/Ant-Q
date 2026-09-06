#!/bin/bash
# Residual CNR=1 diagnostic (2026-09-03): the same short units with the PS in the loop (default) vs out of the loop
# (prefill: all units in DDR before GLOBAL_START). 46.8 us units (1 unit/shot) and 22.7/24.2 us units (2 units/shot),
# R = 1000 shots -> 1000 / 2000 units (<= 1024 units only for the 1-unit case; the 2-unit case uses R = 500 -> 1000 units).
# 20 runs each condition; CNR frequency is the readout.
set -uo pipefail
cd /home/yicheng/Desktop/Ant-Q-experiments/scripts
export PATH=$HOME/anaconda3/envs/qubic_clean/bin:$PATH PYTHONPATH=/home/yicheng/Desktop/software_c3
LOG=../results/prefill_diag.log
log(){ echo "$(date +%Y-%m-%dT%H:%M:%S) $*" | tee -a $LOG; }
log "deploying batch_server with PREFILL flag"
scp /home/yicheng/Desktop/software_c3/scripts/batch_server.c computerC:/home/xilinx/software/scripts/ >> $LOG 2>&1
python - <<'PY' >> $LOG 2>&1
import run_pool_campaign as C, run_phys_campaign as P
C.restart_service(); C.switch_image('C3')
base = ['--pool-tables', '--seg-pulses', '1800']
for cond in ([], ['--prefill']):
    tag = 'c3_14q_stalldiag' + ('_prefill' if cond else '_feed')
    P.cell('C3', 'c3', 5, 20, tag, extra=base + ['--seg-cap', '1802', '--repeat-override', '1000'] + cond)
    P.cell('C3', 'c3', 5, 20, tag, extra=base + ['--seg-cap', '902', '--repeat-override', '500'] + cond)
PY
log "PREFILL DIAG DONE"
