#!/bin/bash
# c1 batches one batch_id at a time; if a batch stops after a second failure (the rare PL-side read hang that
# poisons the readout reader until the overlay is reloaded), restart the service and retry that batch once.
export PATH=$HOME/anaconda3/envs/qubic_clean/bin:$PATH PYTHONPATH=/home/yicheng/Desktop/software_c3
cd /home/yicheng/Desktop/Ant-Q-experiments/scripts
GW=/home/yicheng/gateware_yguang_check/gw_build_c3_14/top/zcu216_14_2/build_8c58a7da_20260829023533
restart(){ T=$(ssh computerC "date +%H:%M:%S; echo xilinx | sudo -S systemctl restart qubic_rpc_server.service 2>/dev/null" | head -1); until ssh -o ConnectTimeout=5 computerC "journalctl -u qubic_rpc_server.service --since '$T' --no-pager 2>/dev/null | grep -q 'RPC server running'"; do sleep 5; done; echo "restarted $(date +%T)"; }
restart
for B in ${BATCH_LIST:-$(python3 -c "import csv; print(' '.join(sorted({r['batch_id'] for r in csv.DictReader(open('../results/batch_manifest.csv'))})))")}; do
  for attempt in 1 2; do
    out=$(python antq_runner.py --mode c3 --bits $GW --gw $GW --num-ch 14 --what batch --batches $B --repeats 5 --wns -0.277 --tag c3_14q_v5 2>&1 | grep "^\[c3\]\|second failure")
    echo "$out" | tail -2
    if echo "$out" | grep -q "second failure"; then echo "!! $B attempt $attempt failed -> restart"; restart; else break; fi
  done
done
echo "== c1 batches done $(date +%T)"
