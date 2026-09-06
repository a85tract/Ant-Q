#!/bin/bash
# Real-stream campaign, phase 1 (plan rev3 §4): c3 singles + all 32 batch manifests on the deployed
# 8c58a7da C3 image. Same resilience policy as the surrogate drivers (restart service + one retry).
export PATH=$HOME/anaconda3/envs/qubic_clean/bin:$PATH PYTHONPATH=/home/yicheng/Desktop/software_c3
cd /home/yicheng/Desktop/Ant-Q-experiments/scripts
GW=/home/yicheng/gateware_yguang_check/gw_build_c3_14/top/zcu216_14_2/build_8c58a7da_20260829023533
TAG=c3_14q_real1
restart(){ T=$(ssh computerC "date +%H:%M:%S; echo xilinx | sudo -S systemctl restart qubic_rpc_server.service 2>/dev/null" | head -1); until ssh -o ConnectTimeout=5 computerC "journalctl -u qubic_rpc_server.service --since '$T' --no-pager 2>/dev/null | grep -q 'RPC server running'"; do sleep 5; done; echo "restarted $(date +%T)"; }

echo "== c3 real singles $(date +%T)"
python antq_runner.py --real --mode c3 --bits $GW --gw $GW --num-ch 14 --what single \
  --idx 1,2,3,4,5,6,7,8,9,10,11,12,13,19,20,21,22,23,24,25 --repeats 5 --wns -0.277 --tag $TAG 2>&1 | grep "^\[c3\]"

echo "== c3 real batches $(date +%T)"
for B in ${BATCH_LIST:-$(python3 -c "import csv; print(' '.join(sorted({r['batch_id'] for r in csv.DictReader(open('../results/batch_manifest.csv'))})))")}; do
  for attempt in 1 2; do
    out=$(python antq_runner.py --real --mode c3 --bits $GW --gw $GW --num-ch 14 --what batch --batches $B --repeats 5 --wns -0.277 --tag $TAG 2>&1 | grep "^\[c3\]\|second failure")
    echo "$out" | tail -2
    if echo "$out" | grep -q "second failure"; then echo "!! $B attempt $attempt failed -> restart"; restart; else break; fi
  done
done
echo "== c3 real campaign done $(date +%T)"
