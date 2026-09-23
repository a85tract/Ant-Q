"""Per-block analysis of one configuration's run (fringe, P0-C, P0-A, Ramsey pairs + slope, 1Q RB) from the runner's saved IQ.
usage: python analyze_block.py <block_tag e.g. A1> [results_dir]
Reads <results>/iq/<tag>_<group>_<idx>_<ns>.npz (keys c<i>_<channel>, complex IQ, shape (n_circ, shots[*reads])) and
<results>/raw_runs_phys.csv; writes <results>/analysis/<tag>_summary.json and prints a table.
Classifier: two-Gaussian (QDA) fitted on the FIRST half of idx 102 (|0>) and 103 (|1>), evaluated on the second half."""
import os, sys, os, glob, json
import numpy as np

tag = sys.argv[1]
res = sys.argv[2] if len(sys.argv) > 2 else os.environ['ANTQ_RESULTS']
iqdir = os.path.join(res, 'iq'); os.makedirs(os.path.join(res, 'analysis'), exist_ok=True)

def load(idx, group):
    fs = sorted(glob.glob(os.path.join(iqdir, f'{tag}_{group}_{idx}_*.npz')))
    if not fs: return None
    z = np.load(fs[-1]); k = [k for k in z.keys() if k.endswith('.rdlo')][0]
    return np.asarray(z[k]).reshape(-1)          # flattened shots (x reads)

class QDA:
    def fit(self, X0, X1):
        self.m = [X0.mean(0), X1.mean(0)]; self.C = [np.cov(X0.T), np.cov(X1.T)]
        self.Ci = [np.linalg.inv(c) for c in self.C]; self.ld = [np.log(np.linalg.det(c)) for c in self.C]; return self
    def predict(self, X):
        ll = [-(np.einsum('ij,jk,ik->i', X - m, Ci, X - m)) - ld for m, Ci, ld in zip(self.m, self.Ci, self.ld)]
        return (ll[1] > ll[0]).astype(int)
def xy(z): return np.column_stack([z.real, z.imag])

out = {'tag': tag}
CLF_TAG = os.environ.get('CLF_TAG', tag)           # block whose idx 102/103 train the classifier (F-a/F-b runs reuse their block's)
def load_tag(t, idx, group):
    fs = sorted(glob.glob(os.path.join(iqdir, f'{t}_{group}_{idx}_*.npz')))
    if not fs: return None
    z = np.load(fs[-1]); k = [k for k in z.keys() if k.endswith('.rdlo')][0]; return np.asarray(z[k]).reshape(-1)
z0, z1 = load_tag(CLF_TAG, 102, 'p0a'), load_tag(CLF_TAG, 103, 'p0a')
out['classifier_from'] = CLF_TAG
if z0 is None or z1 is None:
    sys.exit(f'{tag}: idx 102/103 IQ missing (CLF_TAG={CLF_TAG})')
n0, n1 = len(z0) // 2, len(z1) // 2
clf = QDA().fit(xy(z0[:n0]), xy(z1[:n1]))
p00 = float((clf.predict(xy(z0[n0:])) == 0).mean()); p11 = float((clf.predict(xy(z1[n1:])) == 1).mean())
out['readout'] = dict(train_shots=[n0, n1], test_shots=[len(z0) - n0, len(z1) - n1], P00=p00, P11=p11,
                      fidelity=(p00 + p11) / 2, sep_snr=float(abs(z0.mean() - z1.mean()) / (0.5 * (z0.std() + z1.std()))))
P1 = lambda z: float(clf.predict(xy(z)).mean())
# fringe idx 200-212: X90 - 100 ns - Z(phi) - X90 - read, 13 phases over [-pi, pi]
phases = np.linspace(-np.pi, np.pi, 13); fr = []
for k in range(13):
    z = load(200 + k, 'fringe'); fr.append(P1(z) if z is not None else np.nan)
fr = np.array(fr); ok = ~np.isnan(fr)
if ok.sum() >= 5:
    B = np.column_stack([np.ones(ok.sum()), np.cos(phases[ok]), np.sin(phases[ok])])
    coef, *_ = np.linalg.lstsq(B, fr[ok], rcond=None); resid = fr[ok] - B @ coef
    cov = np.linalg.inv(B.T @ B) * max(resid.var(ddof=3), 1e-12)
    A = float(np.hypot(coef[1], coef[2])); phi0 = float(np.arctan2(coef[2], coef[1]))
    sA = float(np.sqrt((coef[1]**2 * cov[1, 1] + coef[2]**2 * cov[2, 2] + 2 * coef[1] * coef[2] * cov[1, 2]) / A**2)) if A > 0 else np.nan
    sphi = float(np.sqrt((coef[2]**2 * cov[1, 1] + coef[1]**2 * cov[2, 2] - 2 * coef[1] * coef[2] * cov[1, 2]) / A**4)) if A > 0 else np.nan
    out['fringe'] = dict(P1=fr.tolist(), offset=float(coef[0]), contrast=A, contrast_err=sA, phase=phi0, phase_err=sphi, n_shots_each=int(len(load(200, 'fringe'))))
# P0-C from the runner rows
rows = [l.rstrip('\n').split(',') for l in open(os.path.join(res, 'raw_runs_phys.csv'))]
hdr = rows[0]; ci = {h: i for i, h in enumerate(hdr)}
r101 = [r for r in rows[1:] if r[ci['tag']] == f'{tag}_p0c' and r[ci['workload_id']].startswith('phys101')]
if r101:
    r = r101[-1]; n = float(r[ci['loop_n']]) if r[ci['loop_n']] not in ('', 'None') else 8000.0
    out['p0c'] = dict(status=r[ci['status']], loop_n=int(n), qpu_ms=float(r[ci['qpu_ms']]), period_us=float(r[ci['qpu_ms']]) * 1e3 / n, elapsed_ms=float(r[ci['elapsed_ms']]))
# Ramsey pairs idx 104: 2 reads per iteration, [+quadrature, -quadrature]
z = load(104, 'ramsey')
if z is not None:
    lab = clf.predict(xy(z)).reshape(-1, 2); d = lab[:, 0].astype(float) - lab[:, 1].astype(float)
    out['ramsey_pairs'] = dict(iterations=int(lab.shape[0]), P1_plus=float(lab[:, 0].mean()), P1_minus=float(lab[:, 1].mean()),
                               diff_mean=float(d.mean()), diff_var=float(d.var(ddof=1)), diff_mean_se=float(d.std(ddof=1) / np.sqrt(len(d))))
sl = []
for k in range(5):
    z = load(105 + k, 'ramsey'); sl.append(P1(z) if z is not None else np.nan)
out['ramsey_slope_P1'] = sl
# RB: idx 300 + 10*L + s, lengths from env (default 2,4,8,16,32), 8 sequences; survival = P(|0>)
lengths = [int(x) for x in os.environ.get('AQT_RB_LENGTHS', '2,4,8,16,32').split(',')]; nseq = int(os.environ.get('AQT_RB_SEQS', '8'))
surv = np.full((len(lengths), nseq), np.nan)
for L in range(len(lengths)):
    for s in range(nseq):
        z = load(300 + 10 * L + s, 'rb')
        if z is not None: surv[L, s] = 1.0 - P1(z)
def fit_rb(m, y, B=0.5):
    # y = A p^m + B with B FIXED at 0.5 (single-qubit depolarizing asymptote; readout errors here are symmetric within 1 %),
    # A linear, p by a fine grid; the free-B fit is ill-conditioned when the decay over the measured lengths is small.
    best = None
    for p in np.linspace(0.5, 0.99999, 5000):
        x = p ** m; A = float((x * (y - B)).sum() / (x * x).sum()); r = ((y - B - A * x) ** 2).sum()
        if best is None or r < best[0]: best = (r, p, A)
    r, p, A = best; return p, A, B
m = np.array(lengths, dtype=float); ok = ~np.isnan(surv).any(axis=1)
if ok.sum() >= 3:
    ymean = np.nanmean(surv, axis=1)
    B0 = (p00 + 1 - p11) / 2                              # survival floor of the fully mixed state under this block's assignment errors
    p, A, B = fit_rb(m[ok], ymean[ok], B=B0); rng = np.random.default_rng(0); boots = []
    for _ in range(400):                                   # sequence-level bootstrap
        pick = rng.integers(0, nseq, nseq); yb = surv[:, pick].mean(axis=1); pb, _, _ = fit_rb(m[ok], yb[ok], B=B0); boots.append((1 - pb) / 2)
    boots = np.array(boots)
    foot = {}
    for L in range(len(lengths)):
        rr = [r for r in rows[1:] if r[ci['tag']] == f'{tag}_rb' and r[ci['workload_id']].startswith(f'phys{300 + 10 * L}_')]
        if rr and rr[-1][ci['cmd_bytes_logical']] not in ('', 'None'):
            foot[lengths[L]] = int(float(rr[-1][ci['cmd_bytes_logical']]))
    out['rb'] = dict(lengths=lengths, survival_mean=ymean.tolist(), survival_per_seq=surv.tolist(), p=p, A=A, B=B, floor_from_readout=B0, cmd_bytes_logical_by_length=foot,
                     EPC=(1 - p) / 2, EPC_ci95=[float(np.percentile(boots, 2.5)), float(np.percentile(boots, 97.5))], shots_per_seq=int(len(load(300, 'rb'))))
json.dump(out, open(os.path.join(res, 'analysis', f'{tag}_summary.json'), 'w'), indent=1, default=float)
print(f"== {tag}")
print(f"readout (held-out): P00 {p00:.3f} P11 {p11:.3f} fidelity {(p00+p11)/2:.3f} sepSNR {out['readout']['sep_snr']:.2f}")
if 'fringe' in out: print(f"fringe: contrast {out['fringe']['contrast']:.3f} +- {out['fringe']['contrast_err']:.3f}, phase {out['fringe']['phase']:+.3f} +- {out['fringe']['phase_err']:.3f} rad, offset {out['fringe']['offset']:.3f}; P1 = {np.round(fr, 3).tolist()}")
if 'p0c' in out: print(f"P0-C: {out['p0c']['status']} period {out['p0c']['period_us']:.4f} us ({out['p0c']['loop_n']} shots, qpu {out['p0c']['qpu_ms']:.3f} ms)")
if 'ramsey_pairs' in out: rp = out['ramsey_pairs']; print(f"Ramsey pairs: P1+ {rp['P1_plus']:.3f} P1- {rp['P1_minus']:.3f} diff mean {rp['diff_mean']:+.4f} +- {rp['diff_mean_se']:.4f} var {rp['diff_var']:.4f} ({rp['iterations']} iters); slope P1 {np.round(sl, 3).tolist()}")
if 'rb' in out: rb = out['rb']; print(f"RB: survival {np.round(rb['survival_mean'], 3).tolist()} p {rb['p']:.4f} EPC {rb['EPC']:.4f} 95% [{rb['EPC_ci95'][0]:.4f}, {rb['EPC_ci95'][1]:.4f}] A {rb['A']:.3f} B {rb['B']:.3f}")
