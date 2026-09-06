#!/bin/bash
# After the phys campaign: re-run the four replay (REPT) cells with the fixed client (phys5, phys6, the two boundary
# controls) on C3, then the poll-0 stop sweep with the fixed driver, restore STRM_POLL_US=200, rebuild the tables.
set -uo pipefail
cd /home/yicheng/Desktop/Ant-Q-experiments/scripts
export PATH=$HOME/anaconda3/envs/qubic_clean/bin:$PATH PYTHONPATH=/home/yicheng/Desktop/software_c3
LOG=../results/after_A.log
log(){ echo "$(date +%Y-%m-%dT%H:%M:%S) $*" | tee -a $LOG; }
until grep -q "phys campaign done" ../results/phys_campaign.log; do sleep 60; done
log "phys campaign done -> REPT cells on C3"
python - <<'PY' >> $LOG 2>&1
import run_phys_campaign as P, run_pool_campaign as C
C.switch_image('C3')
P.cell('C3', 'c3', 5, 3, 'c3_14q_phys1')
P.cell('C3', 'c3', 6, 3, 'c3_14q_phys1')
P.cell('C3', 'c3', 5, 3, 'c3_14q_physctrl1', extra=['--seg-pulses', '1800', '--seg-cap', '1802'])
P.cell('C3', 'c3', 5, 3, 'c3_14q_physctrl1', extra=['--seg-pulses', '1800', '--seg-cap', '902'])
PY
log "poll-0 sweep re-run (GHZ-3, GHZ-8)"
python run_stop_campaign.py --poll 0 --set-poll --tag c3_14q_stop_poll0b --only 2,10 >> $LOG 2>&1
python - <<'PY' >> $LOG 2>&1
import run_stop_campaign as S; S.restart_dma(200)
PY
python make_phys_tables.py >> $LOG 2>&1
python make_pool_tables.py >> $LOG 2>&1
log "AFTER_A DONE"
