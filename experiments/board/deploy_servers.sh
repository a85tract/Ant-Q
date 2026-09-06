#!/bin/bash
# Deploy the C3 v2 servers to veneno (plan B/A): sync-before-edit already checked (board dma_server.c / std_server.c ==
# software_c3 pre-v2 base; batch_server.c == v5). Backs up the board copies once, pushes ours, restarts the service
# (start_qubic_server.sh recompiles dma_server + batch_server), rebuilds std_server with SS_CHUNK_TIMEOUT_S=300.
set -uo pipefail
SRC=/home/yicheng/Desktop/software_c3/scripts
ssh computerC 'cd /home/xilinx/software/scripts && for f in dma_server.c batch_server.c std_server.c; do [ -f $f.bak_pre_v2_20260901 ] || cp $f $f.bak_pre_v2_20260901; done'
scp $SRC/dma_server.c $SRC/batch_server.c $SRC/std_server.c computerC:/home/xilinx/software/scripts/
T=$(ssh computerC "date +%H:%M:%S; echo xilinx | sudo -S systemctl restart qubic_rpc_server.service 2>/dev/null" | head -1)
until ssh -o ConnectTimeout=10 computerC "journalctl -u qubic_rpc_server.service --since '$T' -n 300 --no-pager 2>/dev/null | grep -q 'RPC server running'"; do sleep 5; done
ssh computerC 'cd /home/xilinx/software/scripts && gcc -O2 -o std_server std_server.c 2>&1 | tail -3; echo xilinx | sudo -S pkill -f "./std_server"; sleep 1; echo xilinx | sudo -S bash -c "SS_CHUNK_TIMEOUT_S=300 setsid nohup ./std_server > std_server.log 2>&1 < /dev/null &"; sleep 2; pgrep -fa "std_server|dma_server|batch_server" | grep -v pgrep'
echo "deployed $(date +%T)"
