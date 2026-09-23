#!/bin/bash
# Deploy the board-side C servers (dma_server, batch_server, std_server) and restart the qubic service.
# The service's start script recompiles dma_server.c and batch_server.c on restart, so only sources are copied;
# std_server (the stock-path timing server, not part of the service) is compiled and started here.
# usage: (site_env.sh sourced) bash deploy_servers.sh
set -uo pipefail
: ${ANTQ_BOARD_SSH:?source site_env.sh first}; : ${ANTQ_BOARD_SW:?}
SUDO=${ANTQ_SUDO:-sudo -n}
HERE=$(cd "$(dirname "$0")" && pwd)
SRC=${ANTQ_SOFTWARE:-$HERE/../../software}/scripts        # dma_server.c / batch_server.c live in the software checkout
STAMP=$(date +%Y%m%d)
ssh $ANTQ_BOARD_SSH "cd $ANTQ_BOARD_SW/scripts && for f in dma_server.c batch_server.c std_server.c; do [ -f \$f.bak_$STAMP ] || cp \$f \$f.bak_$STAMP; done"
scp $SRC/dma_server.c $SRC/batch_server.c $HERE/std_server.c $ANTQ_BOARD_SSH:$ANTQ_BOARD_SW/scripts/
T=$(ssh $ANTQ_BOARD_SSH "date +%H:%M:%S; $SUDO systemctl restart qubic_rpc_server.service 2>/dev/null" | head -1)
until ssh -o ConnectTimeout=10 $ANTQ_BOARD_SSH "journalctl -u qubic_rpc_server.service --since '$T' -n 300 --no-pager 2>/dev/null | grep -q 'RPC server running'"; do sleep 5; done
ssh $ANTQ_BOARD_SSH "cd $ANTQ_BOARD_SW/scripts && gcc -O2 -o std_server std_server.c 2>&1 | tail -3; $SUDO pkill -f './std_server'; sleep 1; $SUDO bash -c 'cd $ANTQ_BOARD_SW/scripts; SS_CHUNK_TIMEOUT_S=300 setsid ./std_server > std_server.log 2>&1 < /dev/null &'"
echo "deployed $(date +%T)"
