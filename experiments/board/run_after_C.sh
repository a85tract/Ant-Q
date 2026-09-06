#!/bin/bash
# Orchestrates everything after campaign C (plan D order): deploy the v2 servers -> T10 + T10v2 gate -> stop
# campaign (STRM_POLL_US 200) -> poll-0 sweep for GHZ-3 (idx 2) and GHZ-8 (idx 10) -> restore poll 200 -> part A.
# Runs unattended; every step logs to results/after_C.log; a failed gate stops the chain.
set -uo pipefail
cd /home/yicheng/Desktop/Ant-Q-experiments/scripts
export PATH=$HOME/anaconda3/envs/qubic_clean/bin:$PATH PYTHONPATH=/home/yicheng/Desktop/software_c3
LOG=../results/after_C.log
log(){ echo "$(date +%Y-%m-%dT%H:%M:%S) $*" | tee -a $LOG; }
# 0. wait for campaign C
until grep -q "campaign done" ../results/pool_campaign.log; do sleep 60; done
log "campaign C done -> pool tables"
python make_pool_tables.py >> $LOG 2>&1
# 1. deploy servers (board on C3 image after the campaign)
log "deploying v2 servers"; bash deploy_servers.sh >> $LOG 2>&1 || { log "DEPLOY FAILED"; exit 1; }
# 2. gates
log "T10 + T10v2 gate"
(cd /home/yicheng/Desktop/software_c3/test/ddr_batch && GW_BUILD=/home/yicheng/gateware_yguang_check/gw_build_c3_8s/top/zcu216_14_2/build_63329aaf_20260830175903 timeout 900 python t10_stop.py > ../../../Ant-Q-experiments/results/t10_v2_gate.txt 2>&1); RC=$?
grep -v WARNING ../results/t10_v2_gate.txt | tail -4 | tee -a $LOG
if [ $RC -ne 0 ] || ! grep -q "T10v2 PASS" ../results/t10_v2_gate.txt; then log "T10v2 GATE FAILED (rc=$RC)"; exit 1; fi
# 3. stop campaign at the default cadence, then the poll-0 sweep on GHZ-3 / GHZ-8, then restore
log "stop campaign (STRM_POLL_US=200)"; python run_stop_campaign.py --poll 200 --set-poll >> $LOG 2>&1
log "stop sweep (STRM_POLL_US=0, idx 2,10)"; python run_stop_campaign.py --poll 0 --set-poll --tag c3_14q_stop_poll0 --only 2,10 >> $LOG 2>&1
python - <<'PY' >> $LOG 2>&1
import run_stop_campaign as S; S.restart_dma(200)
PY
python make_phys_tables.py >> $LOG 2>&1
# 4. part A (c3 cells first, then the C1 image cells; std_server has SS_CHUNK_TIMEOUT_S=300 from the deploy)
log "phys campaign"; python run_phys_campaign.py --part all >> $LOG 2>&1
python make_phys_tables.py >> $LOG 2>&1
log "ALL DONE"
