"""Early-stop study, extended: (1) stop rates by ground-truth grade with Clopper-Pearson bounds, per seed set; (2) sensitivity of
the stop decisions to the rule's thresholds, re-evaluated on the stored checkpoint traces; (3) time saved on the board for the
simulated stop checkpoints of the six circuits of the board experiment, from the board's per-shot time and stop latency.
Inputs: results/rq3_v2/rq3_<backend>[_s20-119].csv and *_checkpoints.csv (rq3_stats.py; SEEDS=20-119 SUFFIX=_s20-119 for the
second set), results/bench/table_stop.csv. Output: results/rq3_v2/rq3_extended.json and a printout.
usage: python rq3_extended.py"""
import csv, json, math, statistics as st
from collections import defaultdict
from pathlib import Path
from scipy.stats import beta

REPO = Path(__file__).resolve().parent.parent.parent; R = REPO / 'results' / 'rq3_v2'
BACKENDS = ['FakeManilaV2', 'FakeLagosV2', 'FakeGuadalupeV2', 'FakeAlgiers', 'FakeSherbrooke', 'FakeTorino']
SETS = {'seeds 0-19': '', 'seeds 20-119': '_s20-119'}

def cp_bounds(k, n):
    lo = beta.ppf(0.025, k, n - k + 1) if k > 0 else 0.0; hi = beta.ppf(0.975, k + 1, n - k) if k < n else 1.0
    return [round(float(lo), 5), round(float(hi), 5)]

runs, traces = [], defaultdict(list)          # traces[(set, backend, idx, seed)] = [(cp, shots, tvd, hf, d_tvd, d_hf)]
for sname, suf in SETS.items():
    for b in BACKENDS:
        p = R / f'rq3_{b}{suf}.csv'
        if not p.exists(): continue
        for r in csv.DictReader(open(p)):
            if r['grade'] == 'SKIP': continue
            runs.append(dict(set=sname, backend=b, idx=int(r['idx']), name=r['name'], seed=int(r['seed']), shots=int(r['shots']), grade=r['grade'],
                             stop=int(r['stop_cp_paper']) if r['stop_cp_paper'] else None))
        for r in csv.DictReader(open(R / f'rq3_{b}{suf}_checkpoints.csv')):
            traces[(sname, b, int(r['idx']), int(r['seed']))].append(
                (int(r['checkpoint']), int(r['shots']), float(r['tvd']), float(r['hf']), float(r['d_tvd']), float(r['d_hf'])))
out = {}

# (1) stop rates by grade
rates = {}
for sname in list(SETS) + ['all']:
    sub = [x for x in runs if sname == 'all' or x['set'] == sname]
    if not sub: continue
    d = {}
    for g in ('PASS', 'MARGINAL', 'FAIL'):
        n = sum(1 for x in sub if x['grade'] == g); k = sum(1 for x in sub if x['grade'] == g and x['stop'])
        d[g] = dict(runs=n, stopped=k, rate_ci95=cp_bounds(k, n))
    d['FAIL_stopped_at_last_checkpoint'] = sum(1 for x in sub if x['grade'] == 'FAIL' and x['stop'] == 10)
    rates[sname] = d
out['stop_rates'] = rates

# (2) threshold sensitivity on the traces (grades stay those of the paper's grading of the full run)
grade_of = {(x['set'], x['backend'], x['idx'], x['seed']): x['grade'] for x in runs}
def stop_cp(tr, hf_t, tvd_t, eps, first=3):
    for cp, n, tvd, hf, dt, dh in sorted(tr):
        if cp >= first and dt <= eps and dh <= eps and hf <= hf_t and tvd >= tvd_t: return cp
    return None
sens = []
for hf_t in (0.35, 0.40, 0.45):
    for tvd_t in (0.55, 0.60, 0.65):
        for eps in (0.02, 0.03, 0.05):
            c = defaultdict(lambda: [0, 0])
            for key, tr in traces.items():
                g = grade_of.get(key)
                if g is None: continue
                c[g][0] += 1; c[g][1] += stop_cp(tr, hf_t, tvd_t, eps) is not None
            sens.append(dict(hf_max=hf_t, tvd_min=tvd_t, eps=eps, **{f'{g}_stopped': c[g][1] for g in ('PASS', 'MARGINAL', 'FAIL')},
                             **{f'{g}_runs': c[g][0] for g in ('PASS', 'MARGINAL', 'FAIL')}))
out['threshold_sensitivity'] = sens

# (3) board time saved at the simulated stop checkpoints: shots executed = min(N, shots at the checkpoint + overshoot), time saved =
# (N - executed) x per-shot time / T_full, with the per-shot time and overshoot measured on the board at the preset checkpoint;
# the board and the simulation number the circuits differently, so they are matched by name
bname = {r['idx']: r['name'] for r in csv.DictReader(open(REPO / 'results' / 'bench' / 'shots_verification.csv'))}
board = {}
for r in csv.DictReader(open(REPO / 'results' / 'bench' / 'table_stop.csv')):
    if r['strm_poll_us'] != '200': continue
    shots = [int(x) for x in r['actual_shots'].split()]; lo, hi = (float(x) for x in r['overshoot_range'].split('..'))
    board[bname[r['idx']]] = dict(T_full_ms=float(r['T_full_ms']), T_stop_ms=float(r['T_stop_ms']), executed_mean=st.mean(shots),
                                overshoot_mean=float(r['overshoot_mean']), overshoot_max=hi, cp_step=int(r['cp_step']))
sav = {}
for name, bd in sorted(board.items()):
    stopped = [x for x in runs if x['name'] == name and x['stop']]
    if not stopped: continue
    N = stopped[0]['shots']; t_shot = (bd['T_full_ms'] - bd['T_stop_ms']) / (N - bd['executed_mean'])
    def saved(cp, over):
        at = N if cp == 10 else cp * (N // 10); ex = min(N, at + over)
        return (N - ex) * t_shot / bd['T_full_ms']
    s_mean = [saved(x['stop'], bd['overshoot_mean']) for x in stopped]; s_worst = [saved(x['stop'], bd['overshoot_max']) for x in stopped]
    cps = defaultdict(int)
    for x in stopped: cps[x['stop']] += 1
    sav[name] = dict(shots=N, per_shot_us=round(1e3 * t_shot, 4), stopped_runs=len(stopped),
                    fail_runs=sum(1 for x in runs if x['name'] == name and x['grade'] == 'FAIL'),
                    stop_checkpoints=dict(sorted(cps.items())), saved_median=round(st.median(s_mean), 4),
                    saved_range=[round(min(s_mean), 4), round(max(s_mean), 4)], saved_worst_overshoot_median=round(st.median(s_worst), 4),
                    too_late=sum(1 for v in s_worst if v <= 0))
out['board_savings'] = sav
json.dump(out, open(R / 'rq3_extended.json', 'w'), indent=1)

for sname, d in rates.items():
    print(sname, {g: (d[g]['stopped'], d[g]['runs'], d[g]['rate_ci95']) for g in ('PASS', 'MARGINAL', 'FAIL')}, 'FAIL at cp 10:', d['FAIL_stopped_at_last_checkpoint'])
ref = next(x for x in sens if (x['hf_max'], x['tvd_min'], x['eps']) == (0.40, 0.60, 0.03))
print('paper rule on the traces:', {k: v for k, v in ref.items() if k.endswith('stopped')})
for k in ('PASS_stopped', 'MARGINAL_stopped', 'FAIL_stopped'):
    print(f'  {k} over the 27 settings: {min(x[k] for x in sens)}..{max(x[k] for x in sens)}')
for name, v in sav.items(): print(name, v)
