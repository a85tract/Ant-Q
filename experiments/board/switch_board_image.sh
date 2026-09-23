#!/bin/bash
# Switch the board's bitfile: set xsa_commit in the server config, restart the qubic service, wait for the RPC banner
# and verify the journal's "loading bitfile" line names the requested slot.
# usage: (site_env.sh sourced) bash switch_board_image.sh <slot_name>
set -o pipefail
: ${ANTQ_BOARD_SSH:?source site_env.sh first}; : ${ANTQ_BOARD_SW:?}; : ${ANTQ_BOARD_CFG:?}
SUDO=${ANTQ_SUDO:-sudo -n}
H=${1:?slot name}; SSH="ssh -o ConnectTimeout=8 -o BatchMode=yes $ANTQ_BOARD_SSH"
$SSH "test -d $ANTQ_BOARD_SW/qubic/rfsoc/bits/$H" || { echo "slot $H missing on the board" >&2; exit 1; }
T0=$($SSH 'date -u "+%Y-%m-%d %H:%M:%S"')   # journalctl --since rejects the ISO 'T' separator
$SSH "cp -n $ANTQ_BOARD_CFG $ANTQ_BOARD_CFG.bak_$(date +%Y%m%d) 2>/dev/null; sed -i -E \"s/^xsa_commit:.*/xsa_commit: '$H'/\" $ANTQ_BOARD_CFG && grep -E '^xsa_commit' $ANTQ_BOARD_CFG && $SUDO systemctl restart qubic_rpc_server.service" >/dev/null 2>&1
for i in $(seq 1 30); do
  J=$($SSH "journalctl -u qubic_rpc_server.service --since '$T0' --no-pager 2>/dev/null | grep -E 'loading bitfile|RPC server running|PL0_REF_CTRL'")
  echo "$J" | grep -q 'RPC server running' && break; sleep 3
done
echo "$J" | grep -E 'loading bitfile|PL0_REF_CTRL|RPC server running' | sed -E 's/^.*start_qubic_server.sh\[[0-9]+\]: //' | cut -c1-120
echo "$J" | grep -q "loading bitfile: $H" && echo "$J" | grep -q 'RPC server running' || { echo "!!! the board did not report loading bitfile $H + RPC up" >&2; exit 1; }
echo "board on $H (verified)"
