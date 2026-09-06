#!/bin/bash
# After run_after_A2: deploy the feeder-cadence fix (batch_server usleep 200 -> 20 us when the config FIFO is full),
# re-run the four replay cells under a new tag (c3_14q_phys2 / c3_14q_physctrl2), rebuild tables.
set -uo pipefail
cd /home/yicheng/Desktop/Ant-Q-experiments/scripts
export PATH=$HOME/anaconda3/envs/qubic_clean/bin:$PATH PYTHONPATH=/home/yicheng/Desktop/software_c3
LOG=../results/after_A3.log
log(){ echo "$(date +%Y-%m-%dT%H:%M:%S) $*" | tee -a $LOG; }
until grep -q "AFTER_A2 DONE" ../results/after_A2.log 2>/dev/null; do sleep 30; done
log "deploying batch_server feeder-cadence fix"
scp /home/yicheng/Desktop/software_c3/scripts/batch_server.c computerC:/home/xilinx/software/scripts/ >> $LOG 2>&1
python - <<'PY' >> $LOG 2>&1
import run_pool_campaign as C, run_phys_campaign as P
C.restart_service(); C.switch_image('C3')
P.cell('C3', 'c3', 5, 3, 'c3_14q_phys2', extra=['--pool-tables'])
P.cell('C3', 'c3', 6, 3, 'c3_14q_phys2', extra=['--pool-tables'])
P.cell('C3', 'c3', 5, 3, 'c3_14q_physctrl2', extra=['--pool-tables', '--seg-pulses', '1800', '--seg-cap', '1802'])
P.cell('C3', 'c3', 5, 3, 'c3_14q_physctrl2', extra=['--pool-tables', '--seg-pulses', '1800', '--seg-cap', '902'])
PY
python make_phys_tables.py >> $LOG 2>&1
log "AFTER_A3 DONE"
