#!/bin/bash
# Image preparation and the acceptance measurements of the paper, for image $ANTQ_IMG. Step 0 seeds the results dir with the
# workload definitions, step 1 deploys the bits slot and switches + verifies the image, step 2 is the batch-completion stress
# test (acceptance/ce_stress.py -> stress/stress_K3.csv, stress/stress_K1.csv), step 3 the command-buffer handover
# measurement (device_x6y3/handover_scope.py -> handover_scope/). Stops at the first failure. Run recampaign_run.sh next;
# both write into the same results dir, which then has the layout of results/bench/.
# usage: (site_env.sh sourced) ANTQ_IMG=<slot> ANTQ_WNS_C3=<wns> bash recampaign_accept.sh [start_step]
#   start_step in 0,1,2,3 resumes after a fixed check (the board must already carry the image; step 1 re-verifies it).
set -o pipefail
HERE=$(cd "$(dirname "$0")" && pwd); source $HERE/recampaign_env.sh || exit 1
START=${1:-0}; ORDER=(0 1 2 3); idx(){ for i in "${!ORDER[@]}"; do [ "${ORDER[$i]}" = "$1" ] && { echo $i; return; }; done; echo 99; }
[ "$(idx $START)" = 99 ] && { echo "bad start_step $START (0,1,2,3)" >&2; exit 1; }
run_step(){ [ $(idx $1) -ge $(idx $START) ]; }   # true if step $1 is at or after START
mkdir -p $ANTQ_RESULTS; L=$ANTQ_RESULTS/logs/acceptance; mkdir -p $L; LOG=$ANTQ_RESULTS/recampaign.log
log(){ echo "$(date +%Y-%m-%dT%H:%M:%S) $*" | tee -a $LOG; }
fail(){ log "!!! FAILED: $*"; exit 1; }
SRC=${ANTQ_SEQ_DIR:-$HERE/../../results/bench}   # workload definitions and the reused shot-length table (see README)
log "=== ACCEPTANCE for image $ANTQ_IMG (WNS $ANTQ_WNS_C3), build $ANTQ_GW_C3, results $ANTQ_RESULTS"
if run_step 0; then
# --- Step 0: results dir seeded with the paper's workload definitions (unchanged) + the C1-image realized-shot table (reused, attributed)
for f in batch_manifest.csv batch_manifest_provenance.csv pool_sequence.csv stop_sequence.csv calib_sequence.csv shots_verification.csv per_shot_realized_raw.csv per_shot_realized_real.csv; do
  [ -f $ANTQ_RESULTS/$f ] || { cp $SRC/$f $ANTQ_RESULTS/ && log "seeded $ANTQ_RESULTS/$f (workload definition / C1-image measurement, unchanged)"; }
done
timeout 8 bash -c "echo > /dev/tcp/$ANTQ_BOARD/8082" 2>/dev/null || fail "8082 (std_server) not reachable"
pgrep -fa "handover_scope|scope_cadence" | grep -v pgrep && fail "another scope client is running"
fi
if run_step 1; then
# --- Step 1: slot + switch + verify (the service start script derives BS_NUM_CH from the configured bitfile)
ssh -o ConnectTimeout=8 $ANTQ_BOARD_SSH "test -d $ANTQ_BOARD_SW/qubic/rfsoc/bits/$ANTQ_IMG" || { log "deploying slot $ANTQ_IMG"; bash $HERE/deploy_slot_board.sh $ANTQ_GW_C3 $ANTQ_IMG >> $LOG 2>&1 || fail "slot deploy"; }
cd $HERE; python -c "import run_pool_campaign as C; C.switch_image('C3')" >> $LOG 2>&1 || fail "switch/verify image $ANTQ_IMG"
grep "image check \[C3\]" $ANTQ_RESULTS/pool_campaign.log | tail -1 | grep -q "loading bitfile: $ANTQ_IMG" || fail "loaded bitfile is not $ANTQ_IMG"
ssh -o ConnectTimeout=8 $ANTQ_BOARD_SSH "pgrep -f '^./std_server' >/dev/null" || fail "std_server not running on the board"
fi
if run_step 2; then
# --- Step 2: batch-completion stress, 3000 batches each with K=3 and K=1 units; one row per batch in stress/stress_K<K>.csv
mkdir -p $ANTQ_RESULTS/stress; cd ${ANTQ_TESTS_DIR:-$HERE/acceptance}
for K in 3 1; do ANTQ_RESULTS=$ANTQ_RESULTS/stress GW_BUILD=$ANTQ_GW_C3 STRESS_K=$K timeout 3600 python -u ce_stress.py 3000 > $L/ce_stress_K${K}_3000.log 2>&1 || fail "2 K=$K rc=$?"
  grep "CE STRESS" $L/ce_stress_K${K}_3000.log | tee -a $LOG
  python3 - $L/ce_stress_K${K}_3000.log <<'PY' || fail "2 K=$K (see log)"
import ast, re, sys
t = open(sys.argv[1]).read(); m = re.search(r"CE STRESS (\{.*\})", t); assert m, 'no CE STRESS summary'
d = ast.literal_eval(m.group(1)); c = d['counts']; exc = sum(v for k, v in c.items() if k.startswith('exc_'))
# batches_done counts COMPLETED batches; a batch that raised (exc_*) is not completed, so completed + exceptions must equal N.
# nonseamless_* is expected for micro-batches whose units are shorter than the next image's fetch; exc_* are host-side dma_server
# connection drops. The criterion is wedges (watchdog timeouts) and data anomalies, with a 1 % cap on the drops.
assert d['N'] == 3000 and d['batches_done'] + exc == d['N'], f"batches_done {d['batches_done']} + exc {exc} != N {d['N']}"
bad = {k: v for k, v in c.items() if not k.startswith(('ok_', 'nonseamless_', 'exc_'))}; assert not bad, f'anomaly counters {bad}'
assert exc <= 30, f"too many exceptions {exc} (> 1 %): {c}"; assert 'WEDGE' not in t, 'wedge recorded'
PY
done
fi
if run_step 3; then
# --- Step 3: handover on this image (markers on qubit_8 qdrv; CH1 = qubit_8 drive on 14_2), captures in handover_scope/
( source $HERE/recampaign_env_markers.sh; unset ANTQ_QCHIP ANTQ_QCHIP_PATCH; export SCOPE_QUBIT_OFFSET=1 AQT_MARK_DEST=qdrv SCOPE_DRIVE_FREQ=300e6 HS_NOTE="image $ANTQ_IMG; SCOPE_QUBIT_OFFSET=1 (Q7 -> qubit_8 drive on CH1), AQT_MARK_DEST=qdrv, SCOPE_DRIVE_FREQ=300e6"
  cd $HERE; timeout 1500 $PY ../device_x6y3/handover_scope.py --idx 701,700 --captures 12 --repeats 150 --tag hand_$ANTQ_IMG --scale 20e-3 --trig-mv 15 2>&1 | grep -vE "Z-phase|WARNING" > $L/handover_scope.log ) || fail "3"
grep "handover =" $L/handover_scope.log | tee -a $LOG
python3 - $ANTQ_RESULTS/handover_scope/hand_${ANTQ_IMG}_summary.json <<'PY' || fail "3: incomplete handover measurement"
import json, math, sys; s = json.load(open(sys.argv[1]))
for k in ('700', '701'): assert len(s[k]['gaps_ns']) >= 12, f"idx {k}: {len(s[k]['gaps_ns'])} gap records (< 12)"
h = s['S2 - U2 (plain pulses)']['handover_ns']; assert math.isfinite(h), 'handover not finite'; print(f'handover {h:.1f} ns from 12+12 records')
PY
fi
log "=== ACCEPTANCE COMPLETE for $ANTQ_IMG"
