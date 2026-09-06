"""Plan C6/C7 analysis: per-manifest paired ratios from the pool campaign (tags *_pool1) and the confirmatory /
exploratory intervals. Output: results/table4_pool.csv (per manifest x configuration: n, mean, sd, delta vs QPU,
G_stack, G_sys, uplink ratios), results/table4_pool_summary.csv (per k: manifest-level mean + t CI df n-1 [exploratory
precision], block means, block-level t CI df 4 [CONFIRMATORY for k=30], sign consistency), results/pool_reliability.csv
(attempts / failures per configuration). Integrity-only inclusion: status ok, repeat >= 0; every complete run counts."""
import csv, os, math, statistics as st
from collections import defaultdict
HERE = os.path.dirname(os.path.abspath(__file__)); RES = os.environ.get('ANTQ_RESULTS', os.path.join(HERE, '..', '..', 'results'))   # <repo>/results
TAGS = {'std_native': 'std_14q_native_pool1', 'std_pool': 'std_14q_pool1', 'c1_native': 'c1_14q_native_pool1', 'c1_pool': 'c1_14q_pool1', 'c3_pool': 'c3_14q_pool1'}
T975 = {1: 12.706, 2: 4.303, 3: 3.182, 4: 2.776, 5: 2.571, 6: 2.447, 7: 2.365, 8: 2.306, 9: 2.262, 10: 2.228}
def tci(vals):
    n = len(vals); m = st.mean(vals)
    if n < 2: return m, float('nan'), float('nan'), n
    h = T975.get(n - 1, 1.96) * st.stdev(vals) / math.sqrt(n); return m, m - h, m + h, n
rows = list(csv.DictReader(open(os.path.join(RES, 'raw_runs.csv'))))
seq = list(csv.DictReader(open(os.path.join(RES, 'pool_sequence.csv'))))
block_of = {r['manifest']: int(r['block']) for r in seq}
cells = defaultdict(list); attempts = defaultdict(lambda: [0, 0])
for r in rows:
    cfg = next((c for c, t in TAGS.items() if r['tag'] == t), None)
    if not cfg or int(r['repeat']) < 0: continue
    attempts[cfg][0] += 1
    if r['status'] == 'ok': cells[(cfg, r['workload_id'])].append((r['wall_time'], float(r['elapsed_ms'])))
    else: attempts[cfg][1] += 1
# a cell re-run after a driver restart has more than 5 complete rows: the cell's T is the LATEST complete set of 5
# (predeclared 2026-09-01 22:36, before any pooled analysis was read); every row stays in raw_runs.csv
cells = {k: [e for _, e in sorted(v)[-5:]] for k, v in cells.items()}
qpu = {r['workload_id']: float(r['qpu_ms']) for r in rows if r['tag'] in TAGS.values()}
manifests = sorted({m for _, m in cells})
out = []; G = defaultdict(dict)
for m in manifests:
    T = {}
    for cfg in TAGS:
        v = cells.get((cfg, m), [])
        if v: T[cfg] = st.mean(v)
        out.append(dict(manifest=m, block=block_of.get(m, ''), config=cfg, n=len(v), mean_ms=round(st.mean(v), 4) if v else '',
                        sd_ms=round(st.stdev(v), 4) if len(v) > 1 else '', qpu_ms=qpu.get(m, ''),
                        delta_pct=round(100 * (st.mean(v) / qpu[m] - 1), 3) if v and m in qpu else ''))
    if all(c in T for c in TAGS):
        G[m] = dict(G_stack=T['std_pool'] / T['c3_pool'] - 1, G_sys=T['std_native'] / T['c3_pool'] - 1,
                    G_up_native=T['std_native'] / T['c1_native'] - 1, G_up_pool=T['std_pool'] / T['c1_pool'] - 1,
                    G_c3_vs_c1pool=T['c1_pool'] / T['c3_pool'] - 1)
w = csv.DictWriter(open(os.path.join(RES, 'table4_pool.csv'), 'w', newline=''), fieldnames=list(out[0].keys()) if out else ['manifest']); w.writeheader(); w.writerows(out)
summ = []
for k in (10, 20, 30):
    ms = [m for m in G if m.startswith(f'rand{k}_')]
    for est in ('G_stack', 'G_sys', 'G_up_native', 'G_up_pool', 'G_c3_vs_c1pool'):
        vals = [G[m][est] for m in ms]
        if not vals: continue
        mean, lo, hi, n = tci(vals)
        blocks = defaultdict(list)
        for m in ms: blocks[block_of.get(m, -1)].append(G[m][est])
        bmeans = [st.mean(v) for b, v in sorted(blocks.items())]
        bm, blo, bhi, bn = tci(bmeans)
        summ.append(dict(k=k, estimand=est, n_manifests=n, mean=round(mean, 4), ci95_lo_manifest=round(lo, 4), ci95_hi_manifest=round(hi, 4),
                         n_blocks=bn, block_means=' '.join(f'{x:.4f}' for x in bmeans), ci95_lo_block=round(blo, 4), ci95_hi_block=round(bhi, 4),
                         all_blocks_positive=all(x > 0 for x in bmeans), confirmatory=('YES (k=30, block CI lo > 0)' if k == 30 and est == 'G_stack' and blo > 0 else ('no' if k == 30 and est == 'G_stack' else 'exploratory'))))
for m in ('ghz8_x30', 'qaoa12_x30'):
    if m in G: summ.append(dict(k=m, estimand='G_stack', n_manifests=1, mean=round(G[m]['G_stack'], 4), confirmatory='secondary (homogeneous)'))
fn = ['k', 'estimand', 'n_manifests', 'mean', 'ci95_lo_manifest', 'ci95_hi_manifest', 'n_blocks', 'block_means', 'ci95_lo_block', 'ci95_hi_block', 'all_blocks_positive', 'confirmatory']
w = csv.DictWriter(open(os.path.join(RES, 'table4_pool_summary.csv'), 'w', newline=''), fieldnames=fn, extrasaction='ignore'); w.writeheader(); w.writerows(summ)
w = csv.writer(open(os.path.join(RES, 'pool_reliability.csv'), 'w', newline='')); w.writerow(['config', 'attempts', 'failed_attempts', 'complete_manifests'])
for cfg in TAGS: w.writerow([cfg, attempts[cfg][0], attempts[cfg][1], sum(1 for (c, m), v in cells.items() if c == cfg and len(v) >= 5)])
for r in summ: print(r)
print('manifests with all 5 configs:', len(G), '/', len(manifests))
