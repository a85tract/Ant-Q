#!/bin/bash
# Campaign Step 3 (A1-A7) + Step 4 tables for image $ANTQ_IMG.
# for image $ANTQ_IMG. Run recampaign_accept.sh first. Stops at the first failing campaign.
# usage: ANTQ_IMG=<hash> ANTQ_WNS_C3=<wns> bash recampaign_run.sh [start_step [stop_step]]
#   steps in order A1 A2 A3 A3b A3r A4 A5 A6 A7 T; start_step resumes, stop_step (default T) ends the run after that step
set -o pipefail
HERE=$(cd "$(dirname "$0")" && pwd); source $HERE/recampaign_env.sh || exit 1
L=$ANTQ_RESULTS/logs/campaign; mkdir -p $L; LOG=$ANTQ_RESULTS/recampaign.log; START=${1:-A1}; STOP=${2:-T}
[[ "$START" =~ ^(A[1-7]|A3b|A3r|T)$ && "$STOP" =~ ^(A[1-7]|A3b|A3r|T)$ ]] || { echo "steps must be A1..A7, A3b, A3r or T, got '$START' '$STOP'"; exit 2; }
log(){ echo "$(date +%Y-%m-%dT%H:%M:%S) $*" | tee -a $LOG; }
fail(){ log "!!! FAILED: $*"; exit 1; }
after(){ [[ "$1" < "$START" || "$1" > "$STOP" ]] && return 1 || return 0; }     # A1 < A2 < A3 < A3b < A3r < A4 < ... < A7 < T (string order)
W=$ANTQ_WNS_C3; C1GW=${ANTQ_GW_C1:?}
IDX20=1,2,3,4,5,6,7,8,9,10,11,12,13,19,20,21,22,23,24,25
MANIFESTS=$(python3 -c "import csv; print(' '.join(sorted({r['batch_id'] for r in csv.DictReader(open('$ANTQ_RESULTS/batch_manifest.csv'))})))") || exit 1
[ "$(echo $MANIFESTS | wc -w)" = 32 ] || { echo "expected 32 manifests, got: $MANIFESTS"; exit 1; }
check(){ python recampaign_check.py $1 | tee -a $LOG; [ ${PIPESTATUS[0]} = 0 ] || fail "$1 coverage check"; }
cd $HERE
switch(){ python -c "import run_pool_campaign as C; C.switch_image('$1')" >> $LOG 2>&1 || fail "switch to $1"; }
restart(){ python -c "import run_pool_campaign as C; C.restart_service()" >> $LOG 2>&1; }
run_batches(){ # $1 mode, $2 gw, $3 wns, $4 tag: 32 manifests x 5 repeats, restart + one retry per manifest (run_c3_batches_resilient.sh policy)
  for B in $MANIFESTS; do
    done_ok=0
    for att in 1 2; do
      timeout 3600 python antq_runner.py --real --mode $1 --bits $2 --gw $2 --num-ch 14 --what batch --batches $B --repeats 5 --wns $3 --tag $4 > $L/A4_$1_$B.att$att.log 2>&1; rc=$?
      out=$(grep -E "^\[$1\] $B r[0-4]: ok" $L/A4_$1_$B.att$att.log | wc -l)
      if [ $rc = 0 ] && [ $out = 5 ] && ! grep -qE "second failure|Traceback" $L/A4_$1_$B.att$att.log; then done_ok=1; break; fi
      log "A4 $1 $B attempt $att: rc=$rc ok-repeats=$out -> restart"; restart
    done
    [ $done_ok = 1 ] || fail "A4 $1 $B failed twice"
  done
}
log "=== CAMPAIGN for image $ANTQ_IMG (WNS $W) from step $START"
switch C3
if after A1; then log "A1 physics (c3 cells + calibration + (5)/(6) streams + boundary controls)"
  timeout 21600 python run_phys_campaign.py --part c3 > $L/A1_phys.log 2>&1 || fail "A1 driver rc=$?"
  grep -q "phys campaign done" $ANTQ_RESULTS/phys_campaign.log || fail "A1 incomplete"; check A1; fi
if after A2; then log "A2 scope metrology: cadence of (4) x3, (3) x1, (5) x3 (SCOPE_QUBIT_OFFSET=8, PEAKDETECT, CONSTANT 12.5 MS/s, edge 25 mV)"
  : ${SCOPE_HOST:?set SCOPE_HOST in site_env.sh for the scope steps}
  cadence(){ # $1 idx, $2 tag, $3 s/div, $4 captures, $5 max-s, $6 compiled period us, $7 extra runner args
    rm -f $ANTQ_RESULTS/scope_cadence/raw/${2}_*.npz   # a rerun replaces this tag's captures: analyze re-reads every raw file of the tag and appends
    [ -f $ANTQ_RESULTS/scope_cadence/cadence_summary.csv ] && python3 -c "import csv,sys; p=sys.argv[1]; r=list(csv.DictReader(open(p))); f=open(p,'w',newline=''); w=csv.DictWriter(f, fieldnames=list(r[0].keys()) if r else ['tag']); w.writeheader(); w.writerows(x for x in r if x['tag']!=sys.argv[2])" $ANTQ_RESULTS/scope_cadence/cadence_summary.csv $2
    python scope_cadence.py capture --tag $2 --mode CONSTANT --sr 12.5e6 --scale $3 --n $4 --max-s $5 --ch1-mv 20 --trig-mv 25 > $L/scope_$2.log 2>&1 & CAP=$!; sleep 8
    SCOPE_QUBIT_OFFSET=8 timeout 1800 python antq_runner.py --phys --mode c3 --bits $GW --gw $GW --num-ch 14 --what single --idx $1 --repeats 1 --wns $W --tag scope_$2 --pool-tables $7 \
      --note "scope cadence (native carrier); SCOPE_QUBIT_OFFSET=8; PEAKDETECT CONSTANT 12.5MS/s $3 s/div" > $L/scope_${2}_runner.log 2>&1 || fail "A2 runner $2 rc=$?"
    grep -q "r0: ok" $L/scope_${2}_runner.log || fail "A2 runner $2: no ok measured repeat"
    wait $CAP || fail "A2 capture $2 failed"; python scope_cadence.py analyze --tag $2 --period-us $6 >> $L/scope_$2.log 2>&1 || fail "A2 analyze $2"; tail -1 $L/scope_$2.log | tee -a $LOG; }
  for n in 1 2 3; do cadence 4 phys4_n$n 8e-3 1 90 8.932 ""; done
  cadence 3 phys3_n1 100e-3 10 140 2003.648 ""
  for n in 1 2 3; do cadence 5 phys5_n$n 100e-3 1 90 248.544 "--prefill 16"; done
  check A2; fi
if after A3; then log "A3 Table 3 singles on c3: 20 circuits x 5 repeats"
  timeout 7200 python antq_runner.py --real --mode c3 --bits $GW --gw $GW --num-ch 14 --what single --idx $IDX20 --repeats 5 --wns $W --tag c3_14q_re1 > $L/A3_singles.log 2>&1 || fail "A3 rc=$?"
  grep -q "second failure" $L/A3_singles.log && fail "A3 second failure (see log)"; check A3; fi
if after A3b; then log "A3b Table 3 singles on std and c1 (image C1): 20 circuits x 5 repeats each, service restart between the modes"
  switch C1
  for m in std c1; do [ $m = c1 ] && restart     # on the C1 image the readout writer runs in every mode: restart between std and c1
    timeout 7200 python antq_runner.py --real --mode $m --bits $C1GW --gw $C1GW --num-ch 14 --what single --idx $IDX20 --repeats 5 --wns 0.002 --tag ${m}_14q_single1 > $L/A3b_${m}_singles.log 2>&1 || fail "A3b $m rc=$?"
    grep -q "second failure" $L/A3b_${m}_singles.log && fail "A3b $m second failure (see log)"; done
  switch C3; check A3b; fi
if after A3r; then log "A3r realized shot length on the C1 image: c1_slope_real.py, 20 circuits x (100, 50100 shots) x 3 repeats"
  switch C1; timeout 3600 python c1_slope_real.py > $L/A3r_slope.log 2>&1 || fail "A3r rc=$?"
  switch C3; check A3r; fi
if after A4; then log "A4 Table 4 batches: c3 without pool tables (32 x 5) then std_native on C1 (32 x 5), back to C3"
  run_batches c3 $GW $W c3_14q_re1
  switch C1; run_batches std $C1GW 0.002 std_14q_re1; switch C3; check A4; fi
if after A5; then log "A5 pool campaign (960 rows, 160 cells)"; timeout 36000 python run_pool_campaign.py > $L/A5_pool.log 2>&1 || fail "A5 driver rc=$?"
  grep -q "campaign done" $ANTQ_RESULTS/pool_campaign.log || fail "A5 incomplete"; check A5; fi
if after A6; then log "A6 decomposition (20 circuits x 10, poll 0 then poll 200)"; timeout 7200 bash run_decomp.sh > $L/A6_decomp.log 2>&1 || fail "A6 rc=$?"
  grep -q "DECOMP DONE" $ANTQ_RESULTS/decomp.log || fail "A6 incomplete"; check A6; fi
if after A7; then log "A7 early stop: PS-preset stops (poll 200) + poll-0 sweep (GHZ-3, GHZ-8), poll 200 restored"
  timeout 14400 python run_stop_campaign.py > $L/A7_stop.log 2>&1 || fail "A7 rc=$?"
  timeout 7200 python run_stop_campaign.py --poll 0 --set-poll --tag c3_14q_stop_poll0d --only 2,10 > $L/A7_stop_poll0.log 2>&1 || fail "A7 poll-0 rc=$?"
  python -c "import run_stop_campaign as S; S.restart_dma(200)" >> $LOG 2>&1 || fail "restore poll 200"; check A7; fi
if after T; then log "T tables"; export REALIZED_CSV=$ANTQ_RESULTS/per_shot_realized_real.csv
  for t in make_phys_tables make_tables make_pool_tables make_decomp_table; do python $t.py > $L/T_$t.log 2>&1 || fail "$t"; done; fi
log "=== CAMPAIGN COMPLETE for $ANTQ_IMG (steps $START..$STOP): $(ls $ANTQ_RESULTS/table*.csv 2>/dev/null | xargs -n1 basename | tr '\n' ' ')"
