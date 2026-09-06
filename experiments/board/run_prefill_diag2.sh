#!/bin/bash
# 100 runs per condition on the 46.8 us unit (1000 units per run): PS feeding during execution vs prefill.
set -uo pipefail
cd /home/yicheng/Desktop/Ant-Q-experiments/scripts
export PATH=$HOME/anaconda3/envs/qubic_clean/bin:$PATH PYTHONPATH=/home/yicheng/Desktop/software_c3
LOG=../results/prefill_diag3.log
log(){ echo "$(date +%Y-%m-%dT%H:%M:%S) $*" | tee -a $LOG; }
scp /home/yicheng/Desktop/software_c3/scripts/batch_server.c computerC:/home/xilinx/software/scripts/ >> $LOG 2>&1
python - <<'PY' >> $LOG 2>&1
import run_phys_campaign as P, run_pool_campaign as C
C.restart_service(); C.switch_image('C3')
base = ['--pool-tables', '--seg-pulses', '1800', '--seg-cap', '1802', '--repeat-override', '1000']
P.cell('C3', 'c3', 5, 100, 'c3_14q_stalldiag3_feed', extra=base)
P.cell('C3', 'c3', 5, 100, 'c3_14q_stalldiag3_prefill', extra=base + ['--prefill'])
P.cell('C3', 'c3', 5, 100, 'c3_14q_stalldiag3_feed', extra=base)
P.cell('C3', 'c3', 5, 100, 'c3_14q_stalldiag3_prefill', extra=base + ['--prefill'])
PY
log "PREFILL DIAG3 DONE"
