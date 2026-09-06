#!/bin/bash
# Deploy the MM2S-poll fix (batch_server 6e7888b) and re-measure: boundary controls, #5 stream, #6 cap500, then the
# short single circuits (fill cost) on c3 with the fixed feeder (tag c3_14q_real3).
set -uo pipefail
cd /home/yicheng/Desktop/Ant-Q-experiments/scripts
export PATH=$HOME/anaconda3/envs/qubic_clean/bin:$PATH PYTHONPATH=/home/yicheng/Desktop/software_c3
LOG=../results/floor_fix.log
log(){ echo "$(date +%Y-%m-%dT%H:%M:%S) $*" | tee -a $LOG; }
log "deploying batch_server 6e7888b (MM2S completion poll without usleep)"
scp /home/yicheng/Desktop/software_c3/scripts/batch_server.c computerC:/home/xilinx/software/scripts/ >> $LOG 2>&1
python - <<'PY' >> $LOG 2>&1
import run_phys_campaign as P, run_pool_campaign as C
C.restart_service(); C.switch_image('C3')
base = ['--pool-tables', '--seg-pulses', '1800']
P.cell('C3', 'c3', 5, 3, 'c3_14q_physctrl3', extra=base + ['--seg-cap', '1802'])
P.cell('C3', 'c3', 5, 3, 'c3_14q_physctrl3', extra=base + ['--seg-cap', '902'])
P.cell('C3', 'c3', 5, 3, 'c3_14q_phys3', extra=['--pool-tables'])
P.cell('C3', 'c3', 6, 3, 'c3_14q_phys3', extra=['--pool-tables'])
P.cell('C3', 'c3', 6, 3, 'c3_14q_floordiag3', extra=['--pool-tables', '--seg-cap', '500'])
PY
GW=/home/yicheng/gateware_yguang_check/gw_build_c3_8s/top/zcu216_14_2/build_63329aaf_20260830175903
log "short singles with the fixed feeder (tag c3_14q_real3)"
python antq_runner.py --real --mode c3 --bits $GW --gw $GW --num-ch 14 --what single --idx 10,9,1,4,5,6,8 --repeats 5 --wns 0.000 --tag c3_14q_real3 2>&1 | grep "^\[c3\]" >> $LOG
python antq_runner.py --real --mode c3 --bits $GW --gw $GW --num-ch 14 --what batch --batches ghz8_x30,rand30_t4 --repeats 5 --wns 0.000 --tag c3_14q_real3 2>&1 | grep "^\[c3\]" >> $LOG
python make_phys_tables.py >> $LOG 2>&1
log "FLOOR FIX DONE"
