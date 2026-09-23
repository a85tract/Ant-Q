#!/usr/bin/env python3
"""Coverage check after each re-campaign step (the drivers' 'done' markers alone do not establish success).
Reads $ANTQ_RESULTS/raw_runs*.csv (+ scope_cadence/cadence_summary.csv) and asserts the exact row coverage the runbook
requires; exit 1 with the list of gaps. usage: recampaign_check.py A1|A2|A3|A3b|A3r|A4|A5|A6|A7"""
import csv, os, sys, collections
RES = os.environ['ANTQ_RESULTS']; step = sys.argv[1]; problems = []
def rows(f):
    p = os.path.join(RES, f); return list(csv.DictReader(open(p))) if os.path.exists(p) else []
def ok_measured(rs): return [r for r in rs if r['status'] == 'ok' and int(r['repeat']) >= 0]
def need(cond, msg):
    if not cond: problems.append(msg)
def reps(rs): return {int(r['repeat']) for r in rs}
raw, phys, dec, stp = rows('raw_runs.csv'), rows('raw_runs_phys.csv'), rows('raw_runs_decomp.csv'), rows('raw_runs_stop.csv')
STAMPS = ('t_first_dma_done_ns', 't_start_written_ns', 't_first_cid_ns', 't_batch_done_ns')
def check_pairs(tag, pair_ids):
    by = collections.defaultdict(list)   # (pair, attempt) -> ok rows; both members must come from the same completed attempt
    for r in stp:
        if r['tag'] == tag and r['status'] == 'ok' and int(r['repeat']) >= 0: by[(r['pair_id'], r['note'].split('rep=')[-1])].append(r)
    for pid in pair_ids:
        good = [m for (p, att), m in by.items() if p == pid and any(int(r['stop_at']) == 0 for r in m)
                and any(int(r['stop_at']) > 0 and r['stop_result'] in ('FIRED', 'NATURAL') for r in m)]
        need(good, f'{tag}: pair {pid} has no attempt with both members ok and stop_result FIRED/NATURAL')
def check_batches(tag, mode, manifests, nrep=5):
    for m in manifests:
        got = reps(ok_measured([r for r in raw if r['tag'] == tag and r['mode'] == mode and r['workload'] == 'batch' and r['workload_id'] == m]))
        need(got >= set(range(nrep)), f'{tag}/{mode} manifest {m}: ok repeats {sorted(got)}')
manifests = sorted({r['batch_id'] for r in rows('batch_manifest.csv')})
if step == 'A1':
    for i in (1, 2, 3, 4):
        s = ok_measured([r for r in phys if r['mode'] == 'c3' and r['tag'] == 'c3_14q_phys1' and r['workload'] == 'phys' and r['workload_id'].split('_')[0] == f'phys{i}'])
        need(reps(s) >= {0, 1, 2}, f'phys{i} c3: ok repeats {sorted(reps(s))}'); need(all(r['cnr'] == '0' for r in s), f'phys{i} c3: CNR != 0')
    EXP = {'vion_1': 1, 'yan_3': 3, 'riste_4': 4}
    cal = ok_measured([r for r in phys if r['mode'] == 'c3' and r['workload'] == 'phys_cal' and r['tag'] == 'c3_14q_physcal1'])
    for e in rows('calib_sequence.csv'):
        hit = [r for r in cal if r['workload_id'].split('_')[0] == f"phys{EXP[e['exp']]}" and int(float(r['calib_n'] or 0)) == int(e['count'])]
        need(hit and all(r['cnr'] == '0' for r in hit), f"calibration {e['exp']} n={e['count']}: {len(hit)} ok rows (cnr {[r['cnr'] for r in hit]})")
    for i in (5, 6):
        s = ok_measured([r for r in phys if r['tag'] == 'c3_14q_phys4_start16' and r['workload_id'].split('_')[0] == f'phys{i}'])
        need(reps(s) >= {0, 1, 2}, f'phys{i} stream: ok repeats {sorted(reps(s))}'); need(all(r['cnr'] == '0' for r in s), f'phys{i} stream: CNR != 0 in {[r["cnr"] for r in s]}')
elif step == 'A2':
    cad = rows('scope_cadence/cadence_summary.csv'); by = collections.defaultdict(list)
    for r in cad: by[r['tag']].append(r)
    import math
    for tag, nmin in (('phys4_n1', 1), ('phys4_n2', 1), ('phys4_n3', 1), ('phys3_n1', 10), ('phys5_n1', 1), ('phys5_n2', 1), ('phys5_n3', 1)):   # = the captures the driver requests
        rs = by.get(tag, []); need(len({r['k'] for r in rs}) >= nmin, f'cadence {tag}: {len({r["k"] for r in rs})} distinct captures (< {nmin})')   # the driver clears a tag before re-capturing
        for r in rs:
            if tag.startswith(('phys3', 'phys4')):   # runbook A2: (3)/(4) period = compiled within 80 ns, 0 missing shots; (5) rows are informational
                need(r['missing_shots'] == '0', f'cadence {tag} k{r["k"]}: missing_shots {r["missing_shots"]!r}')
                try: dev = abs(float(r['mean_period_us']) - float(r['period_prog_us']))
                except ValueError: dev = math.inf
                need(math.isfinite(dev) and dev <= 0.080, f'cadence {tag} k{r["k"]}: period {r["mean_period_us"]!r} vs {r["period_prog_us"]} us')
        need([r for r in ok_measured(phys) if r['tag'] == f'scope_{tag}'], f'runner row for scope_{tag} missing/not ok')
elif step == 'A3':
    for wid in '1,2,3,4,5,6,7,8,9,10,11,12,13,19,20,21,22,23,24,25'.split(','):
        got = reps(ok_measured([r for r in raw if r['tag'] == 'c3_14q_re1' and r['mode'] == 'c3' and r['workload'] == 'single' and r['workload_id'] == wid]))
        need(got >= set(range(5)), f'single {wid}: ok repeats {sorted(got)}')
elif step == 'A3b':
    for mode in ('std', 'c1'):
        for wid in '1,2,3,4,5,6,7,8,9,10,11,12,13,19,20,21,22,23,24,25'.split(','):
            got = reps(ok_measured([r for r in raw if r['tag'] == f'{mode}_14q_single1' and r['mode'] == mode and r['workload'] == 'single' and r['workload_id'] == wid]))
            need(got >= set(range(5)), f'{mode} single {wid}: ok repeats {sorted(got)}')
elif step == 'A3r':
    rr = rows('per_shot_realized_raw.csv')
    for wid in '1,2,3,4,5,6,7,8,9,10,11,12,13,19,20,21,22,23,24,25'.split(','):
        for rep in ('0', '1', '2'):
            for n in ('100', '50100'):
                need(any(r['idx'] == wid and r['repeat'] == rep and r['shots'] == n for r in rr), f'realized {wid} repeat {rep} shots {n}: no row')
elif step == 'A4':
    need(len(manifests) == 32, f'{len(manifests)} manifests'); check_batches('c3_14q_re1', 'c3', manifests); check_batches('std_14q_re1', 'std', manifests)
elif step == 'A5':
    seq = rows('pool_sequence.csv'); TAG = {'std_native': 'std_14q_native_pool1', 'std_pool': 'std_14q_pool1', 'c1_native': 'c1_14q_native_pool1', 'c1_pool': 'c1_14q_pool1', 'c3_pool': 'c3_14q_pool1'}
    for cfg, tag in TAG.items():
        cells = {(r['manifest'], r['block']) for r in seq if r['config'] == cfg}
        for m, b in sorted(cells):
            got = reps(ok_measured([r for r in raw if r['tag'] == tag and r['workload_id'] == m and f'block={b} ' in r['note']]))
            need(got >= set(range(5)), f'pool {cfg} {m} block {b}: ok repeats {sorted(got)}')
elif step == 'A6':
    for tag, ids, n in (('c3_14q_decomp_p0', '10,9,12,6,5,11,20,25,8,13,7,4,3,2,1,21,23,22,19,24'.split(','), 10), ('c3_14q_decomp_p200', ['10', '9', '12'], 10)):
        for wid in ids:
            s = [r for r in ok_measured(dec) if r['tag'] == tag and r['workload_id'] == wid and all(r.get(x) for x in STAMPS)]
            need(len(reps(s)) >= n, f'decomp {tag} circuit {wid}: {len(reps(s))} stamped ok repeats (< {n})')
elif step == 'A7':
    seq = rows('stop_sequence.csv'); pairs = sorted({r['pair_id'] for r in seq if r['pair_id']})
    check_pairs('c3_14q_stop1', pairs); check_pairs('c3_14q_stop_poll0d', [p for p in pairs if p.split('_')[0] in ('2', '10')])
else:
    sys.exit(f'unknown step {step}')
print(f'[check {step}] ' + ('OK' if not problems else f'{len(problems)} problem(s):\n  ' + '\n  '.join(problems)))
sys.exit(1 if problems else 0)
