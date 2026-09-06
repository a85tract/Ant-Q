#!/usr/bin/env python3
"""make_rq3_tables.py -- RQ3 statistics from results/rq3/rq3_<backend>.csv (rq3_stats.py; 20 seeds per cell).
Outputs results/table_rq3_cells.csv (per circuit x backend: grade counts, stop counts, stop checkpoints, false stops,
missed stops, TVD-only rule for comparison) and prints (1) the paper's Table noise_study in multi-seed form, (2) the
false-stop / missed-stop accounting, (3) stop-checkpoint distributions for the circuits that stop.
Ground truth per seed = grade of the FULL noisy run; a stop is a FALSE stop when that grade is PASS, a MISSED stop when
the grade is FAIL and no stop fired; stops on MARGINAL runs are listed separately (the archived code counted them correct).
"""
import csv, glob, statistics as st
from collections import defaultdict, Counter
from pathlib import Path

RES = Path(__file__).resolve().parent.parent.parent / 'results'
from rq3_common import OUT_DIR
TAG = '' if OUT_DIR.name == 'rq3' else '_v2'
BACKENDS = ['FakeManilaV2', 'FakeLagosV2', 'FakeGuadalupeV2', 'FakeAlgiers', 'FakeSherbrooke', 'FakeTorino']
rows = [r for f in sorted(glob.glob(str(OUT_DIR / 'rq3_Fake*.csv'))) if not f.endswith('_checkpoints.csv') for r in csv.DictReader(open(f))]
cells = defaultdict(list)
for r in rows: cells[(int(r['idx']), r['backend'])].append(r)
names = {int(r['idx']): r['name'] for r in rows}

out = []
for (idx, b), rs in sorted(cells.items(), key=lambda kv: (kv[0][0], BACKENDS.index(kv[0][1]))):
    g = Counter(r['grade'] for r in rs)
    if g.get('SKIP'):
        out.append(dict(idx=idx, name=names[idx], backend=b, n=len(rs), skip=1)); continue
    stops = [r for r in rs if r['stop_cp_paper']]; cps = [int(r['stop_cp_paper']) for r in stops]
    stops_t = [r for r in rs if r['stop_cp_tvd_only']]
    out.append(dict(idx=idx, name=names[idx], backend=b, n=len(rs), skip=0, PASS=g.get('PASS', 0), MARGINAL=g.get('MARGINAL', 0), FAIL=g.get('FAIL', 0),
                    stops=len(stops), stop_on_PASS=sum(r['grade'] == 'PASS' for r in stops), stop_on_MARGINAL=sum(r['grade'] == 'MARGINAL' for r in stops),
                    stop_on_FAIL=sum(r['grade'] == 'FAIL' for r in stops), missed_FAIL=sum(r['grade'] == 'FAIL' and not r['stop_cp_paper'] for r in rs),
                    stop_cp_min=min(cps) if cps else '', stop_cp_median=st.median(cps) if cps else '', stop_cp_max=max(cps) if cps else '',
                    stops_tvd_only=len(stops_t), stop_on_PASS_tvd_only=sum(r['grade'] == 'PASS' for r in stops_t),
                    tvd_mean=round(st.mean(float(r['final_tvd']) for r in rs), 3), hf_mean=round(st.mean(float(r['final_hf']) for r in rs), 3)))
keys = ['idx', 'name', 'backend', 'n', 'skip', 'PASS', 'MARGINAL', 'FAIL', 'stops', 'stop_on_PASS', 'stop_on_MARGINAL', 'stop_on_FAIL', 'missed_FAIL',
        'stop_cp_min', 'stop_cp_median', 'stop_cp_max', 'stops_tvd_only', 'stop_on_PASS_tvd_only', 'tvd_mean', 'hf_mean']
with open(RES / f'table_rq3_cells{TAG}.csv', 'w', newline='') as f:
    w = csv.DictWriter(f, fieldnames=keys); w.writeheader(); w.writerows(out)

def cell(o):
    if o.get('skip'): return '—'
    parts = [f"{k[0]}{o[k]}" for k in ('PASS', 'MARGINAL', 'FAIL') if o[k]]
    return '/'.join(parts) + (f" stop{o['stops']}@{o['stop_cp_min']}-{o['stop_cp_max']}" if o['stops'] else '')

print('## Table noise_study, multi-seed (P/M/F = PASS/MARGINAL/FAIL counts over n seeds; stopN@a-b = stops (paper rule) and their checkpoint range)')
print('| idx | circuit | n | ' + ' | '.join(b.replace('Fake', '').replace('V2', '') for b in BACKENDS) + ' |')
print('|---|---|---|' + '---|' * len(BACKENDS))
for idx in sorted(names):
    os_ = {o['backend']: o for o in out if o['idx'] == idx}
    if not any(o.get('FAIL') or o.get('MARGINAL') or o.get('stops') for o in os_.values()): continue
    print(f"| {idx} | {names[idx]} | {os_[BACKENDS[0]]['n']} | " + ' | '.join(cell(os_[b]) if b in os_ else '(running)' for b in BACKENDS) + ' |')
tot = [o for o in out if not o.get('skip')]
n_runs = sum(o['n'] for o in tot); n_pass = sum(o['PASS'] for o in tot); n_fail = sum(o['FAIL'] for o in tot); n_marg = sum(o['MARGINAL'] for o in tot)
print(f"\nruns {n_runs}: PASS {n_pass}, MARGINAL {n_marg}, FAIL {n_fail}; stops {sum(o['stops'] for o in tot)}: on FAIL {sum(o['stop_on_FAIL'] for o in tot)}, "
      f"on MARGINAL {sum(o['stop_on_MARGINAL'] for o in tot)}, on PASS (false) {sum(o['stop_on_PASS'] for o in tot)}; missed FAIL {sum(o['missed_FAIL'] for o in tot)}; "
      f"TVD-only rule: stops {sum(o['stops_tvd_only'] for o in tot)}, on PASS {sum(o['stop_on_PASS_tvd_only'] for o in tot)}")
print('\nfalse stops (paper rule) by cell:'); [print(f"  idx {o['idx']} {o['name']} {o['backend']}: {o['stop_on_PASS']}/{o['PASS']} PASS runs stopped") for o in tot if o['stop_on_PASS']]
print('stops on MARGINAL by cell:'); [print(f"  idx {o['idx']} {o['name']} {o['backend']}: {o['stop_on_MARGINAL']}/{o['MARGINAL']}") for o in tot if o['stop_on_MARGINAL']]
print('missed FAIL by cell:'); [print(f"  idx {o['idx']} {o['name']} {o['backend']}: {o['missed_FAIL']}/{o['FAIL']}") for o in tot if o['missed_FAIL']]
