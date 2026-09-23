#!/bin/bash
# Deploy one gateware build to a named bits slot on the board (no python-tree changes, no service restart).
# usage: (site_env.sh sourced) bash deploy_slot_board.sh <build_dir> <slot_name>
set -euo pipefail
: ${ANTQ_BOARD_SSH:?source site_env.sh first}; : ${ANTQ_BOARD_SW:?}
BD=${1:?build dir}; SLOT_NAME=${2:?slot name}
HASH=$(basename "$BD" | cut -d_ -f2)
XSA=$(ls "$BD"/bits/psbd_*_"$HASH".xsa)
SLOT=$ANTQ_BOARD_SW/qubic/rfsoc/bits/$SLOT_NAME
CC="$BD"/channel_config.json; [ -f "$CC" ] || CC="$BD"/gensrc/channel_config.json
for f in "$BD"/gensrc/bram.json "$BD"/gensrc/channel_map.txt "$BD"/cfgregs.json "$CC" "$BD"/dspregs.json "$BD"/rfdc.json; do ls "$f" >/dev/null; done
ssh -o ConnectTimeout=8 $ANTQ_BOARD_SSH "mkdir -p $SLOT"
scp -o ConnectTimeout=8 "$XSA" "$BD"/gensrc/bram.json "$BD"/gensrc/channel_map.txt "$BD"/cfgregs.json "$CC" "$BD"/dspregs.json "$BD"/rfdc.json $ANTQ_BOARD_SSH:$SLOT/
# command-slot geometry (fill-latency variant images); absent on legacy builds = 32768 B/channel
[ -f "$BD"/gensrc/ds_geometry.json ] && scp -o ConnectTimeout=8 "$BD"/gensrc/ds_geometry.json $ANTQ_BOARD_SSH:$SLOT/
ssh -o ConnectTimeout=8 $ANTQ_BOARD_SSH "ls -la $SLOT"
echo "== slot $SLOT_NAME ready; switch with: xsa_commit: '$SLOT_NAME' + service restart"
