#!/bin/bash
# Root-cause diagnostics for the ~64 us unit floor (2026-09-02): same 46.8 us unsplit control unit (first 1800 pulses of
# #5, 1 unit/shot, 1024 units) under different CE masks, plus #6 (2 real channels) cut into ~40 us units.
set -uo pipefail
cd /home/yicheng/Desktop/Ant-Q-experiments/scripts
export PATH=$HOME/anaconda3/envs/qubic_clean/bin:$PATH PYTHONPATH=/home/yicheng/Desktop/software_c3
LOG=../results/floor_diag.log
log(){ echo "$(date +%Y-%m-%dT%H:%M:%S) $*" | tee -a $LOG; }
python - <<'PY' >> $LOG 2>&1
import run_phys_campaign as P, run_pool_campaign as C
C.switch_image('C3')
base = ['--pool-tables', '--seg-pulses', '1800', '--seg-cap', '1802']
P.cell('C3', 'c3', 5, 3, 'c3_14q_floordiag', extra=base + ['--ch-mask', '0'])        # no channel masked: 14 x 1024 beats per unit
P.cell('C3', 'c3', 5, 3, 'c3_14q_floordiag', extra=base + ['--ch-mask', str(0x3F80)])  # 7 masked (cores 7-13), 7 full
P.cell('C3', 'c3', 5, 3, 'c3_14q_floordiag', extra=base + ['--ch-mask', str(0x3FFC)])  # 12 masked, cores 0-1 full
P.cell('C3', 'c3', 6, 3, 'c3_14q_floordiag', extra=['--pool-tables', '--seg-cap', '500'])   # 2 real channels, ~40 us units
P.cell('C3', 'c3', 6, 3, 'c3_14q_floordiag', extra=['--pool-tables', '--seg-cap', '1000'])  # 2 real channels, ~80 us units
PY
log "FLOOR DIAG DONE"
