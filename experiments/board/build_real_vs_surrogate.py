"""real_vs_surrogate.csv (plan rev3 §5): per-cell comparison of the real-stream campaign against the
surrogate campaign's final sets.

Equivalence cells (mechanism unchanged): 20 singles x 3 modes + homogeneous batches (ghz8_x30,
qaoa12_x30) x 3 modes. Verdict on the Welch 95% CI of (mean_real - mean_surrogate), n=5 vs n=5:
EQUIVALENT iff the whole CI is inside [-M, +M], M = max(1% of workload QPU, 0.15 ms), predefined;
NON-MATCHING iff the CI is entirely outside; INCONCLUSIVE otherwise.
Random batches: DESCRIPTIVE rows (mechanism differs: grouped-reload, see n_groups) — no verdict.
Limitation (also in README): surrogate sets are historical (same bitfiles/services, not interleaved);
this is a comparison, not causal attribution.
"""
import csv, os, statistics as st
from collections import defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
RES = os.environ.get('ANTQ_RESULTS', os.path.join(HERE, '..', '..', 'results'))   # <repo>/results
# same-bitfile pairs: std/c1 on the C1 image (0071783e), c3 on the CLOSED 63329aaf image (v6 + real2
# were measured back-to-back on it; the -0.277-image pair v5/real1 stays in raw_runs as history)
SUR_TAGS = {'std': 'std_14q_v2', 'c1': 'c1_14q_v7', 'c3': 'c3_14q_v6'}
REAL_TAGS = {'std': 'std_14q_real1', 'c1': 'c1_14q_real1', 'c3': 'c3_14q_real2'}
HOMOG = {'ghz8_x30', 'qaoa12_x30'}
T975 = {1: 12.706, 2: 4.303, 3: 3.182, 4: 2.776, 5: 2.571, 6: 2.447, 7: 2.365, 8: 2.306}


def sets_by_tag():
    out = defaultdict(list)   # (mode, workload, wid, tag) -> [(wall_time, elapsed, qpu)]
    with open(os.path.join(RES, 'raw_runs.csv')) as f:
        for r in csv.DictReader(f):
            if r['status'] == 'ok' and int(r['repeat']) >= 0:
                out[(r['mode'], r['workload'], r['workload_id'], r['tag'])].append(
                    (r['wall_time'], float(r['elapsed_ms']), float(r['qpu_ms'])))
    return {k: sorted(v)[-5:] for k, v in out.items() if len(v) >= 5}   # latest 5 of a complete set


def welch(xs, ys):
    """(diff of means, 95% CI half-width, df) for mean(xs) - mean(ys)."""
    mx, my = st.mean(xs), st.mean(ys)
    vx, vy = st.variance(xs), st.variance(ys)
    nx, ny = len(xs), len(ys)
    se2 = vx / nx + vy / ny
    if se2 == 0:
        return mx - my, 0.0, nx + ny - 2
    df = se2 ** 2 / ((vx / nx) ** 2 / (nx - 1) + (vy / ny) ** 2 / (ny - 1))
    t = T975[max(1, min(8, round(df)))]
    return mx - my, t * se2 ** 0.5, df


def ngroups_map():
    out = {}
    p = os.path.join(RES, 'cnr_log.csv')
    if os.path.exists(p):
        with open(p) as f:
            for r in csv.DictReader(f):
                if r['status'] == 'ok':
                    out[(r['tag'], r['workload_id'])] = int(r['n_groups'])
    return out


def main():
    S = sets_by_tag()
    ng = ngroups_map()
    rows = []
    cells = [('single', str(i)) for i in sorted(
        int(r['idx']) for r in csv.DictReader(open(os.path.join(RES, 'shots_verification.csv'))))]
    bids = sorted({k[2] for k in S if k[1] == 'batch'})
    cells += [('batch', b) for b in bids if not b.startswith('gate')]
    for mode in ('std', 'c1', 'c3'):
        for workload, wid in cells:
            sur = S.get((mode, workload, wid, SUR_TAGS[mode]))
            rel = S.get((mode, workload, wid, REAL_TAGS[mode]))
            if not sur and not rel:
                continue
            row = dict(mode=mode, workload=workload, workload_id=wid,
                       population=('equivalence' if workload == 'single' or wid in HOMOG else 'descriptive'),
                       sur_n=len(sur) if sur else 0, real_n=len(rel) if rel else 0,
                       n_groups=ng.get((REAL_TAGS[mode], wid), 1 if mode != 'c3' else ''))
            if sur:
                row.update(sur_mean_ms=f'{st.mean([x[1] for x in sur]):.4f}', sur_sd_ms=f'{st.stdev([x[1] for x in sur]):.4f}',
                           sur_qpu_ms=f'{sur[0][2]:.4f}')
            if rel:
                row.update(real_mean_ms=f'{st.mean([x[1] for x in rel]):.4f}', real_sd_ms=f'{st.stdev([x[1] for x in rel]):.4f}',
                           real_qpu_ms=f'{rel[0][2]:.4f}')
            if sur and rel:
                d, hw, df = welch([x[1] for x in rel], [x[1] for x in sur])
                m = max(0.01 * float(row.get('real_qpu_ms', row.get('sur_qpu_ms'))), 0.15)
                lo, hi = d - hw, d + hw
                row.update(diff_ms=f'{d:.4f}', ci95_lo_ms=f'{lo:.4f}', ci95_hi_ms=f'{hi:.4f}',
                           welch_df=f'{df:.1f}', margin_ms=f'{m:.4f}')
                if row['population'] == 'equivalence':
                    row['verdict'] = ('EQUIVALENT' if -m <= lo and hi <= m
                                      else 'NON-MATCHING' if hi < -m or lo > m else 'INCONCLUSIVE')
                else:
                    row['verdict'] = ''
            rows.append(row)
    fields = ['mode', 'workload', 'workload_id', 'population', 'sur_n', 'sur_mean_ms', 'sur_sd_ms', 'sur_qpu_ms',
              'real_n', 'real_mean_ms', 'real_sd_ms', 'real_qpu_ms', 'n_groups', 'diff_ms',
              'ci95_lo_ms', 'ci95_hi_ms', 'welch_df', 'margin_ms', 'verdict']
    with open(os.path.join(RES, 'real_vs_surrogate.csv'), 'w', newline='') as f:
        w = csv.DictWriter(f, fieldnames=fields, extrasaction='ignore')
        w.writeheader()
        for r in rows:
            w.writerow(r)
    eq = [r for r in rows if r.get('verdict')]
    print(f"wrote real_vs_surrogate.csv: {len(rows)} rows; equivalence cells with both sets: {len(eq)}")
    for v in ('EQUIVALENT', 'INCONCLUSIVE', 'NON-MATCHING'):
        n = sum(1 for r in eq if r['verdict'] == v)
        if n:
            print(f"  {v}: {n}" + (' -> ' + ', '.join(f"{r['mode']}/{r['workload_id']}" for r in eq if r['verdict'] == v) if v != 'EQUIVALENT' else ''))


if __name__ == '__main__':
    main()
