#!/bin/bash
# RQ3 statistics: six fake backends in parallel, seeds 0-19, all 20 paper circuits (<= 14 qubits).
cd "$(dirname "$0")"
PY=/home/yicheng/anaconda3/envs/noise_exp/bin/python
OUTD=$($PY -c 'from rq3_common import OUT_DIR; print(OUT_DIR)'); mkdir -p $OUTD
LOG=$OUTD/run_rq3_stats.log
echo "$(date +%Y-%m-%dT%H:%M:%S) START seeds 0-19 CIRCUITS=${CIRCUITS:-v2} REF=${REF:-exact}" >> $LOG
for b in FakeManilaV2 FakeLagosV2 FakeGuadalupeV2 FakeAlgiers FakeSherbrooke FakeTorino; do
  BACKEND=$b SEEDS=0-19 $PY rq3_stats.py > $OUTD/log_$b.txt 2>&1 &
done
wait
echo "$(date +%Y-%m-%dT%H:%M:%S) DONE" >> $LOG
