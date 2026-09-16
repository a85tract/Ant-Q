#!/bin/bash
# Stage the C3 bitstream + C3 board servers on veneno (computerC). Mirrors the C2 slot layout exactly
# (bits/<hash>/: psbd_<ts>_<hash>.xsa, bram.json, channel_map.txt, cfgregs/channel_config/dspregs/rfdc.json).
# The service's start script recompiles dma_server.c / batch_server.c on restart, so only the .c files are copied.
# DOES NOT switch the overlay or restart the service: that is a board-state change (user OK) — commands are printed.
# Usage: deploy_c3_veneno.sh <build_dir>
set -euo pipefail
BD=${1:?build dir}
HASH=$(basename "$BD" | cut -d_ -f2)
XSA=$(ls "$BD"/bits/psbd_*_"$HASH".xsa)
SLOT=/home/xilinx/software/qubic/rfsoc/bits/$HASH
echo "== C3 build $HASH: $XSA -> veneno $SLOT"
for f in "$BD"/gensrc/bram.json "$BD"/gensrc/channel_map.txt "$BD"/cfgregs.json "$BD"/channel_config.json "$BD"/dspregs.json "$BD"/rfdc.json; do ls "$f" >/dev/null; done
ssh -o ConnectTimeout=8 computerC "mkdir -p $SLOT && cd /home/xilinx/software/scripts && cp -n dma_server.c dma_server.c.bak_pre_c3 && cp -n batch_server.c batch_server.c.bak_pre_c3; true"
scp -o ConnectTimeout=8 "$XSA" "$BD"/gensrc/bram.json "$BD"/gensrc/channel_map.txt "$BD"/cfgregs.json "$BD"/channel_config.json "$BD"/dspregs.json "$BD"/rfdc.json computerC:$SLOT/
scp -o ConnectTimeout=8 /home/yicheng/Desktop/software_c3/scripts/dma_server.c /home/yicheng/Desktop/software_c3/scripts/batch_server.c computerC:/home/xilinx/software/scripts/
ssh -o ConnectTimeout=8 computerC "cd /home/xilinx/software/scripts && gcc -O2 -fsyntax-only dma_server.c -lcma && gcc -O2 -fsyntax-only batch_server.c -lcma -lpthread && echo 'board-side syntax OK' && ls -la $SLOT"
# --- board-side PYTHON tree: the board's live tree (~/software, commit 23e61fa) carries the user's 6 uncommitted
# edits that REMOVE ddr_batch_prepare + its RPC registration, so the DDR batch path cannot run on it. Stage the C3
# python tree next to it; the swap (rename) is printed, not executed. bits/ (16 MB x ~57 slots) is not copied:
# the staged tree gets a symlink to the live tree's bits dir.
STAGE=/home/xilinx/software_c3_staged
tar -C /home/yicheng/Desktop/software_c3 --exclude=.git --exclude='qubic/rfsoc/bits' --exclude='__pycache__' -czf /tmp/software_c3.tgz .
ssh -o ConnectTimeout=8 computerC "rm -rf $STAGE && mkdir -p $STAGE" && scp -o ConnectTimeout=8 /tmp/software_c3.tgz computerC:/tmp/ && \
ssh -o ConnectTimeout=8 computerC "cd $STAGE && tar xzf /tmp/software_c3.tgz && rm -f /tmp/software_c3.tgz && ln -s /home/xilinx/software/qubic/rfsoc/bits $STAGE/qubic/rfsoc/bits && ls $STAGE/qubic/rfsoc/ && grep -c ddr_batch_prepare $STAGE/qubic/soc_rpc_server.py"
echo "== staged: bits slot $SLOT, servers in ~/software/scripts, python tree in $STAGE"
echo "== To switch the board (ASK THE USER FIRST) — python swap (editable install follows the folder name):"
echo "   ssh computerC 'cd /home/xilinx && mv software software_user_edits && mv software_c3_staged software && rm software/qubic/rfsoc/bits && mv software_user_edits/qubic/rfsoc/bits software/qubic/rfsoc/bits && ln -s /home/xilinx/software/qubic/rfsoc/bits software_user_edits/qubic/rfsoc/bits'"
echo "   (revert = the same renames in reverse). Overlay + restart:"
echo "   ssh computerC 'sed -i \"s/^xsa_commit:.*/xsa_commit: $HASH/\" /home/xilinx/server_config.yaml && echo xilinx | sudo -S systemctl restart qubic_rpc_server.service'"
echo "   then: ssh computerC 'journalctl -u qubic_rpc_server.service -n 200 --no-pager | grep -i \"loading bitfile\\|RPC server running\\|server compiled\"'"
