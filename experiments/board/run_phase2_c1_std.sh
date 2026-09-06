#!/bin/bash
# Phase 2: switch veneno to the C1 14_2 bitfile, verify the 14-qubit std path against the Python path,
# then run the std and c1 campaigns (20 singles + 32 batches, 5 repeats each).
set -uo pipefail
GW=/home/yicheng/gateware_yguang_check/gw_build_c1/top/zcu216_14_2/build_0071783e_20260829023649
export PATH=$HOME/anaconda3/envs/qubic_clean/bin:$PATH PYTHONPATH=/home/yicheng/Desktop/software_c3
cd /home/yicheng/Desktop/Ant-Q-experiments/scripts
T=$(ssh computerC "sed -i \"s/^xsa_commit:.*/xsa_commit: '0071783e_14q'/\" /home/xilinx/server_config.yaml; date +%H:%M:%S; echo xilinx | sudo -S systemctl restart qubic_rpc_server.service 2>/dev/null" | head -1)
until ssh -o ConnectTimeout=5 computerC "journalctl -u qubic_rpc_server.service --since '$T' --no-pager 2>/dev/null | grep -q 'RPC server running'"; do sleep 5; done
ssh computerC "journalctl -u qubic_rpc_server.service --since '$T' --no-pager | grep -i 'BS_NUM_CH\|loading bitfile\|PL0' | tail -3; pgrep -fa './std_server' | grep -v pgrep | head -1"
echo "== D3a(b') check: 14-qubit readout-sim, std_server vs Python path"
timeout 600 python - << 'PYEOF' 2>&1 | grep "^CHECK\|Error"
import sys, io, contextlib, numpy as np
sys.argv=['x']
from antq_runner import Programs, load_bench, active_channels, prep_tables, RPC_PORT
from qubic.std_client import StdServerClient
from qubic.rpc_client import CircuitRunnerClient
GW='/home/yicheng/gateware_yguang_check/gw_build_c1/top/zcu216_14_2/build_0071783e_20260829023649'
P=Programs(GW, 14); b=load_bench()[19]; exe=P.readout_sim(b['n_qubits'], b['per_shot_us']); ch=active_channels(exe); n=1000
r=CircuitRunnerClient('localhost', RPC_PORT)
with contextlib.redirect_stdout(io.StringIO()):
    res=r.run_circuit_batch([exe, exe], n, reads_per_shot=1, ddr=False)[1]
py={c: np.abs(np.asarray(res[f'qubit_{c}.rdlo']._array)).mean() for c in ch}
cl=StdServerClient('localhost', GW); prep_tables(exe)
info, results = cl.run_batch([{'binaries': exe.get_binaries_fromboard(), 'nshots': n, 'chans': {f'qubit_accbuf{c}': 2 for c in ch}, 'regs': {}}], timeout_s=300)
ok=True
for c in ch:
    w=results[0][f'qubit_accbuf{c}']; assert len(w)==2*n
    lo=w[0::2].astype(np.int64); hi=w[1::2].astype(np.int64)
    I=np.where(lo>=2**31, lo-2**32, lo); Q=np.where(hi>=2**31, hi-2**32, hi)
    ratio=np.abs(I+1j*Q).mean()/py[c]; ok = ok and 0.9 < ratio < 1.1
    print(f'CHECK ch{c}: words {len(w)} |IQ| C/Python = {ratio:.3f}')
print('CHECK 14q std path:', 'PASS' if ok else 'FAIL', f'({len(ch)} channels, {n} shots, C elapsed {info["elapsed_ms"]:.2f} ms)')
PYEOF
ALL=$(python3 -c "import csv; print(','.join(r['idx'] for r in csv.DictReader(open('../results/shots_verification.csv'))))")
BATCHES=$(python3 -c "import csv; print(','.join(sorted({r['batch_id'] for r in csv.DictReader(open('../results/batch_manifest.csv'))})))")
for MODE in std c1; do
  python antq_runner.py --mode $MODE --bits $GW --gw $GW --num-ch 14 --what single --idx $ALL --repeats 5 --wns 0.002 --tag ${MODE}_14q_v2
  python antq_runner.py --mode $MODE --bits $GW --gw $GW --num-ch 14 --what batch --batches $BATCHES --repeats 5 --wns 0.002 --tag ${MODE}_14q_v2
done
echo "== phase 2 done $(date +%T)"
