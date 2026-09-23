# Campaign environment. Site-specific values come from site_env.sh (untracked; see site_env.sh.example).
# Select the image with ANTQ_IMG (slot name = 8-char gateware hash); paths derive from it.
# ANTQ_WNS_C3 = that image's sign-off setup WNS in ns, as a string, recorded in every result row.
_here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
if [ -f "$_here/site_env.sh" ]; then
  source "$_here/site_env.sh"
else
  echo "site_env.sh not found in $_here -- copy site_env.sh.example and fill it in" >&2
  return 1 2>/dev/null || exit 1
fi
for v in ANTQ_PY ANTQ_SOFTWARE ANTQ_GW_ROOT ANTQ_GW_C3_GLOB ANTQ_RESULTS_ROOT ANTQ_BOARD_SSH ANTQ_BOARD_LAN ANTQ_TUNNEL_IP ANTQ_BOARD_SW ANTQ_BOARD_CFG; do
  eval "[ -n \"\${$v:-}\" ]" || { echo "site_env.sh: $v is not set" >&2; return 1 2>/dev/null || exit 1; }
done
: ${ANTQ_IMG:?set ANTQ_IMG to the gateware slot name (8-char hash) of the image under test}
: ${ANTQ_WNS_C3:?set ANTQ_WNS_C3 to the sign-off WNS of $ANTQ_IMG (psbd_timing_summary_postroute_physopted.rpt)}
export ANTQ_IMG ANTQ_WNS_C3
export PYTHONPATH=$ANTQ_SOFTWARE
export PY=$ANTQ_PY RUNNER=$_here/antq_runner.py
# results dir: default <ANTQ_RESULTS_ROOT>/results_14_2_<image>; preset ANTQ_RESULTS for a further campaign on the same image
export ANTQ_RESULTS=${ANTQ_RESULTS:-$ANTQ_RESULTS_ROOT/results_14_2_$ANTQ_IMG}
# directories only: `make release` leaves build_<hash>_<ts>.tar.gz next to the build dir, which a plain glob + tail -1 would pick
export ANTQ_GW_C3=$(ls -d $ANTQ_GW_ROOT/$ANTQ_GW_C3_GLOB/build_${ANTQ_IMG}_*/ 2>/dev/null | tail -1 | sed "s:/$::")
[ -n "$ANTQ_GW_C3" ] || { echo "no build dir for $ANTQ_IMG under $ANTQ_GW_ROOT/$ANTQ_GW_C3_GLOB" >&2; return 1 2>/dev/null || exit 1; }
export GW=$ANTQ_GW_C3 ANTQ_XSA_C3=$ANTQ_IMG NUM_CH=14
# Board ports: ONE ssh forward PER PORT. With the RPC, stream and batch ports on a single shared connection every
# batch_server session can pay one TCP delayed-ACK period (~40 ms) on its HELO reply and another on its DONE status.
# Idempotent: only missing forwards are created.
# Ports: 9095 RPC, 8080 stream (dma_server), 8081 batch (batch_server), 8082 the stock-path timing server.
if [ -n "${ANTQ_JUMP_SSH:-}" ]; then
  for p in 9095 8080 8081 8082; do
    ss -tlnp 2>/dev/null | grep -q "$ANTQ_TUNNEL_IP:$p " || \
      ssh -fN -o ServerAliveInterval=30 -o ServerAliveCountMax=3 -o ExitOnForwardFailure=yes -o ConnectTimeout=15 \
          -L $ANTQ_TUNNEL_IP:$p:$ANTQ_BOARD_LAN:$p $ANTQ_JUMP_SSH
  done
  export ANTQ_BOARD=$ANTQ_TUNNEL_IP
else
  export ANTQ_BOARD=$ANTQ_BOARD_LAN            # board reachable directly: no forwards needed
fi
export ANTQ_RPC_PORT=9095 RPC_HOST=$ANTQ_BOARD RPC_PORT=9095
# The device-program variables (ANTQ_PHYS_MODULE, ANTQ_QCHIP*, AQT_*) live in recampaign_env_markers.sh; with them set,
# --real mode builds the pool from the device programs instead of the paper circuits.
