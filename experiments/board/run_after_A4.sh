#!/bin/bash
# After run_after_A3: the poll-0 stop sweep (GHZ-3, GHZ-8) with the corrected dma_server restart, restore
# STRM_POLL_US=200, rebuild the tables.
set -uo pipefail
cd /home/yicheng/Desktop/Ant-Q-experiments/scripts
export PATH=$HOME/anaconda3/envs/qubic_clean/bin:$PATH PYTHONPATH=/home/yicheng/Desktop/software_c3
LOG=../results/after_A4.log
log(){ echo "$(date +%Y-%m-%dT%H:%M:%S) $*" | tee -a $LOG; }
until grep -q "AFTER_A3 DONE" ../results/after_A3.log 2>/dev/null; do sleep 30; done
log "poll-0 sweep (GHZ-3, GHZ-8), tag c3_14q_stop_poll0d"
python run_stop_campaign.py --poll 0 --set-poll --tag c3_14q_stop_poll0d --only 2,10 >> $LOG 2>&1
python - <<'PY' >> $LOG 2>&1
import run_stop_campaign as S; S.restart_dma(200)
PY
sed -i "s/'c3_14q_stop_poll0c'/'c3_14q_stop_poll0d'/" make_phys_tables.py
python make_phys_tables.py >> $LOG 2>&1
log "AFTER_A4 DONE"
