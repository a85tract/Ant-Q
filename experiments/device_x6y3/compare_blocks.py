"""Compare two blocks (configurations) from analyze_block.py summaries with the pre-registered margins: every criterion
is a two-sided margin on the BETWEEN-configuration difference; the 95 % CI of the difference must lie inside the margin -> EQUIVALENT; CI crossing -> INCONCLUSIVE; CI outside -> DIFFERENT.
usage: python compare_blocks.py <tagA> <tagB> [results_dir]"""
import os, sys, os, json
import numpy as np
res = sys.argv[3] if len(sys.argv) > 3 else os.environ['ANTQ_RESULTS']
A = json.load(open(os.path.join(res, 'analysis', f'{sys.argv[1]}_summary.json'))); B = json.load(open(os.path.join(res, 'analysis', f'{sys.argv[2]}_summary.json')))
def verdict(diff, lo, hi, margin_lo, margin_hi):
    if margin_lo <= lo and hi <= margin_hi: return 'EQUIVALENT'
    if hi < margin_lo or lo > margin_hi: return 'DIFFERENT'
    return 'INCONCLUSIVE'
rows = []
# fringe phase (+-0.10 rad) and contrast ratio (0.90-1.10)
fa, fb = A['fringe'], B['fringe']
d = fb['phase'] - fa['phase']; se = np.hypot(fa['phase_err'], fb['phase_err'])
rows.append(('fringe phase diff [rad]', d, d - 1.96*se, d + 1.96*se, -0.10, 0.10))
r = fb['contrast'] / fa['contrast']; se_r = r * np.hypot(fa['contrast_err']/fa['contrast'], fb['contrast_err']/fb['contrast'])
rows.append(('fringe contrast ratio B/A', r, r - 1.96*se_r, r + 1.96*se_r, 0.90, 1.10))
# P0-C: identical period (deterministic)
rows.append(('P0-C period diff [us]', B['p0c']['period_us'] - A['p0c']['period_us'], 0.0, 0.0, -1e-6, 1e-6))
# P0-A: held-out assignment fidelity difference, margin +-0.01 (TOST at 95 %: CI = 1.645 sigma each side)
def se_fid(x):
    n = sum(x['readout']['test_shots']); f = x['readout']['fidelity']; return np.sqrt(f*(1-f)/n)
d = B['readout']['fidelity'] - A['readout']['fidelity']; se = np.hypot(se_fid(A), se_fid(B))
rows.append(('P0-A assignment fidelity diff', d, d - 1.645*se, d + 1.645*se, -0.01, 0.01))
# Ramsey pairs: diff-mean difference (+-0.02) and variance ratio (0.80-1.25)
# CIs by bootstrap over iterations (the pairs of each block resampled independently), as in the pre-registered rule
da, db = (np.load(os.path.join(res, 'analysis', f'{t}_pair_diff.npy')).astype(float) for t in (sys.argv[1], sys.argv[2]))
brng = np.random.default_rng(2); bm, bv = [], []
for _ in range(10):                                        # 10 x 200 = 2000 resamples, in chunks to bound memory
    ra_, rb_ = da[brng.integers(0, len(da), (200, len(da)))], db[brng.integers(0, len(db), (200, len(db)))]
    bm.append(rb_.mean(1) - ra_.mean(1)); bv.append(rb_.var(1, ddof=1) / ra_.var(1, ddof=1))
bm, bv = np.concatenate(bm), np.concatenate(bv)
rows.append(('Ramsey pair-diff mean, B-A', db.mean() - da.mean(), *np.percentile(bm, [2.5, 97.5]), -0.02, 0.02))
rows.append(('Ramsey pair-diff variance ratio B/A', db.var(ddof=1) / da.var(ddof=1), *np.percentile(bv, [2.5, 97.5]), 0.80, 1.25))
# RB: paired sequence-level bootstrap of the EPC difference, margin +-0.005
sa, sb = np.array(A['rb']['survival_per_seq']), np.array(B['rb']['survival_per_seq']); m = np.array(A['rb']['lengths'], dtype=float)
def fit_p(y, B0=0.5):
    best = None
    for p in np.linspace(0.5, 0.99999, 3000):
        x = p**m; a = float((x*(y-B0)).sum()/(x*x).sum()); rr = ((y-B0-a*x)**2).sum()
        if best is None or rr < best[0]: best = (rr, p)
    return best[1]
BA, BB = A['rb'].get('floor_from_readout', 0.5), B['rb'].get('floor_from_readout', 0.5)
epc_a = lambda s: (1 - fit_p(np.nanmean(s, axis=1), BA)) / 2
epc_b = lambda s: (1 - fit_p(np.nanmean(s, axis=1), BB)) / 2
d0 = epc_b(sb) - epc_a(sa); rng = np.random.default_rng(1); boots = []
nseq = sa.shape[1]
for _ in range(400):
    pick = rng.integers(0, nseq, nseq)                    # SAME sequences picked on both sides (pairing kept)
    boots.append(epc_b(sb[:, pick]) - epc_a(sa[:, pick]))
lo, hi = np.percentile(boots, [2.5, 97.5])
rows.append(('RB EPC diff, B-A', d0, lo, hi, -0.005, 0.005))
print(f"{sys.argv[1]} vs {sys.argv[2]}  (EPC A {epc_a(sa):.4f}, B {epc_b(sb):.4f}; floors {BA:.3f}/{BB:.3f}; fidelity A {A['readout']['fidelity']:.3f}, B {B['readout']['fidelity']:.3f})")
print(f"{'criterion':38s} {'value':>9s} {'CI lo':>9s} {'CI hi':>9s} {'margin':>16s}  verdict")
out = {}
for name, v, lo, hi, ml, mh in rows:
    vd = verdict(v, lo, hi, ml, mh); out[name] = dict(value=float(v), ci=[float(lo), float(hi)], margin=[ml, mh], verdict=vd)
    print(f"{name:38s} {v:9.4f} {lo:9.4f} {hi:9.4f} [{ml:7.4f},{mh:7.4f}]  {vd}")
json.dump(out, open(os.path.join(res, 'analysis', f'compare_{sys.argv[1]}_{sys.argv[2]}.json'), 'w'), indent=1)
