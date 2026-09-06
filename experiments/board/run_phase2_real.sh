#!/bin/bash
# Real-stream campaign, phase 2 (plan rev3 §4): std + c1 on the C1 image (0071783e_14q), then the
# real-program C1 slope. Service restart at each phase start and between modes (stale-ring discipline).
export PATH=$HOME/anaconda3/envs/qubic_clean/bin:$PATH PYTHONPATH=/home/yicheng/Desktop/software_c3
cd /home/yicheng/Desktop/Ant-Q-experiments/scripts
GW=/home/yicheng/gateware_yguang_check/gw_build_c1/top/zcu216_14_2/build_0071783e_20260829023649
IDX=1,2,3,4,5,6,7,8,9,10,11,12,13,19,20,21,22,23,24,25
restart(){ T=$(ssh computerC "date +%H:%M:%S; echo xilinx | sudo -S systemctl restart qubic_rpc_server.service 2>/dev/null" | head -1); until ssh -o ConnectTimeout=5 computerC "journalctl -u qubic_rpc_server.service --since '$T' --no-pager 2>/dev/null | grep -q 'RPC server running'"; do sleep 5; done; echo "restarted $(date +%T)"; }

for MODE in std c1; do
  TAG=${MODE}_14q_real1
  restart
  echo "== $MODE real singles $(date +%T)"
  python antq_runner.py --real --mode $MODE --bits $GW --gw $GW --num-ch 14 --what single \
    --idx $IDX --repeats 5 --wns 0.002 --tag $TAG 2>&1 | grep "^\[$MODE\]"
  echo "== $MODE real batches $(date +%T)"
  for B in $(python3 -c "import csv; print(' '.join(sorted({r['batch_id'] for r in csv.DictReader(open('../results/batch_manifest.csv'))})))"); do
    for attempt in 1 2 3 4; do
      out=$(python antq_runner.py --real --mode $MODE --bits $GW --gw $GW --num-ch 14 --what batch --batches $B --repeats 5 --wns 0.002 --tag $TAG 2>&1 | grep "^\[$MODE\]\|second failure")
      echo "$out" | tail -2
      if echo "$out" | grep -q "second failure"; then echo "!! $B attempt $attempt failed -> restart"; restart; else break; fi
    done
  done
done

restart
echo "== real C1 slope $(date +%T)"
python c1_slope_real.py
echo "== phase 2 done $(date +%T)"
