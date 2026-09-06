#!/bin/bash
# c3 re-measurement on the CLOSED 63329aaf image (WNS 0.000; T2/T11 passed): surrogate tag c3_14q_v6
# and real tag c3_14q_real2 — replaces the provisional (-0.277 bitfile) c3 sets in the tables.
export PATH=$HOME/anaconda3/envs/qubic_clean/bin:$PATH PYTHONPATH=/home/yicheng/Desktop/software_c3
cd /home/yicheng/Desktop/Ant-Q-experiments/scripts
GW=/home/yicheng/gateware_yguang_check/gw_build_c3_8s/top/zcu216_14_2/build_63329aaf_20260830175903
IDX=1,2,3,4,5,6,7,8,9,10,11,12,13,19,20,21,22,23,24,25
restart(){ T=$(ssh computerC "date +%H:%M:%S; echo xilinx | sudo -S systemctl restart qubic_rpc_server.service 2>/dev/null" | head -1); until ssh -o ConnectTimeout=5 computerC "journalctl -u qubic_rpc_server.service --since '$T' --no-pager 2>/dev/null | grep -q 'RPC server running'"; do sleep 5; done; echo "restarted $(date +%T)"; }

run_variant(){ # $1 = tag, $2 = extra flag ('' or --real)
  restart
  echo "== c3 $1 singles $(date +%T)"
  python antq_runner.py $2 --mode c3 --bits $GW --gw $GW --num-ch 14 --what single \
    --idx $IDX --repeats 5 --wns 0.000 --tag $1 2>&1 | grep "^\[c3\]"
  echo "== c3 $1 batches $(date +%T)"
  for B in $(python3 -c "import csv; print(' '.join(sorted({r['batch_id'] for r in csv.DictReader(open('../results/batch_manifest.csv'))})))"); do
    for attempt in 1 2 3 4; do
      out=$(python antq_runner.py $2 --mode c3 --bits $GW --gw $GW --num-ch 14 --what batch --batches $B --repeats 5 --wns 0.000 --tag $1 2>&1 | grep "^\[c3\]\|second failure")
      echo "$out" | tail -2
      if echo "$out" | grep -q "second failure"; then echo "!! $B attempt $attempt failed -> restart"; restart; else break; fi
    done
  done
}

run_variant c3_14q_v6 ""
run_variant c3_14q_real2 "--real"
echo "== closed-image c3 campaign done $(date +%T)"
