"""Experiment (5) of the paper's Table 2 on the device: 1Q RB to 5101 Cliffords. B = Ant-Q (image c26942c0, m >= 1024 as
sub-circuit streams), A = stock image (classic RPC; lengths that fit its command memory). Per command path: held-out QDA classifier
from <prep>_p0a (idx 102/103), survival P(0) per (m, sequence), floor B_floor = (P00 + 1 - P11)/2.
Readings (pre-registered):
  (i)  EPC equivalence over the shared lengths m <= 512: joint fit P = B_floor + A p^m per path (least squares on sequence means),
       EPC = (1 - p)/2, paired sequence bootstrap of the difference (same sequences on both paths), margin +-0.005;
  (ii) execution flags from raw_runs_phys.csv: status, seamless, cnr, n_segments, cmd_bytes_max per program.
usage: python deep_rb_analysis.py <tagB> <prepB> [<tagA> <prepA>] [--res DIR]   (default DIR: $ANTQ_RESULTS)"""
import sys, os, glob, json, csv
import numpy as np
T975 = {1: 12.706, 2: 4.303, 3: 3.182, 4: 2.776, 5: 2.571, 6: 2.447, 7: 2.365, 8: 2.306, 9: 2.262, 10: 2.228}
def t975(df): return T975.get(df, 1.96 + 2.4 / df)   # 97.5 % t quantile (small-sample CI of a sequence mean); approximation above df 10
args = [a for i, a in enumerate(sys.argv[1:], 1) if not a.startswith('--') and sys.argv[i - 1] != '--res']
res = sys.argv[sys.argv.index('--res') + 1] if '--res' in sys.argv else os.environ['ANTQ_RESULTS']
tagB, prepB = args[0], args[1]; tagA, prepA = (args[2], args[3]) if len(args) >= 4 else (None, None)
iq = os.path.join(res, 'iq'); an = os.path.join(res, 'analysis'); os.makedirs(an, exist_ok=True)
LENGTHS = [int(x) for x in os.environ.get('AQT_RB_LENGTHS', '16,32,64,128,256,512,1024,2048,5101').split(',')]
NSEQ = int(os.environ.get('AQT_RB_SEQS', '8')); rng = np.random.default_rng(5101)

def xy(z): return np.column_stack([z.real, z.imag])
class QDA:
    def fit(self, X0, X1):
        self.m = [X0.mean(0), X1.mean(0)]; C = [np.cov(X0.T), np.cov(X1.T)]; self.Ci = [np.linalg.inv(c) for c in C]; self.ld = [np.log(np.linalg.det(c)) for c in C]; return self
    def predict(self, X):
        s = [-0.5 * np.einsum('ij,jk,ik->i', X - self.m[k], self.Ci[k], X - self.m[k]) - 0.5 * self.ld[k] for k in range(2)]; return (s[1] > s[0]).astype(int)
def load_plain(t, grp, idx):
    fs = sorted(glob.glob(f'{iq}/{t}_{grp}_{idx}_*.npz'))
    if not fs: return None
    z = np.load(fs[-1]); ks = [k for k in z.keys() if k.endswith('.rdlo')]
    if len(ks) == 1: return np.asarray(z[ks[0]]).reshape(-1)
    ks = sorted(ks, key=lambda k: int(k[1:k.index('_')]))                 # streamed: one array per read-carrying unit (fixed client)
    return np.asarray([complex(np.asarray(z[k]).reshape(-1)[0]) for k in ks])
rows = list(csv.DictReader(open(os.path.join(res, 'raw_runs_phys.csv'))))
def flags(tag, idx):
    r = [x for x in rows if x['tag'] == f'{tag}_rb' and x['workload_id'].startswith(f'phys{idx}_')]
    if not r: return {}
    x = r[-1]; return dict(status=x['status'], seamless=x['seamless'], cnr=x['cnr'], n_segments=x['n_segments'], cmd_bytes_max=x['cmd_bytes_max'], elapsed_ms=x['elapsed_ms'], qpu_ms=x['qpu_ms'])
out = {}
def analyze(tag, prep, name):
    z0, z1 = load_plain(prep, 'p0a', 102), load_plain(prep, 'p0a', 103); h0, h1 = len(z0) // 2, len(z1) // 2
    clf = QDA().fit(xy(z0[:h0]), xy(z1[:h1])); P00 = 1 - clf.predict(xy(z0[h0:])).mean(); P11 = clf.predict(xy(z1[h1:])).mean(); Bf = (P00 + 1 - P11) / 2
    surv = {}; fl = {}
    for L, m in enumerate(LENGTHS):
        for s in range(NSEQ):
            z = load_plain(tag, 'rb', 300 + 10 * L + s)
            if z is None: continue
            surv[(m, s)] = 1 - clf.predict(xy(z)); fl[(m, s)] = flags(tag, 300 + 10 * L + s)
    ms = sorted({m for m, _ in surv})
    print(f"{name} ({tag}, classifier {prep}): P00 {P00:.3f} P11 {P11:.3f} floor {Bf:.3f}; lengths with data {ms}")
    tab = {}
    for m in ms:
        v = np.array([surv[(m, s)].mean() for s in range(NSEQ) if (m, s) in surv]); n = sum(len(surv[(m, s)]) for s in range(NSEQ) if (m, s) in surv)
        f = [fl[(m, s)] for s in range(NSEQ) if (m, s) in surv]
        seam = sum(1 for x in f if x.get('seamless') == '1'); cnr = max(int(x.get('cnr') or 0) for x in f); segs = {x.get('n_segments') for x in f}; ok = sum(1 for x in f if x.get('status') == 'ok')
        tab[m] = dict(mean=float(v.mean()), sd_seq=float(v.std(ddof=1)) if len(v) > 1 else 0.0, n_seq=len(v), shots=int(n), ok=ok, seamless=seam, cnr=cnr, n_segments=sorted(segs),
                      cmd_bytes_max=max(int(x.get('cmd_bytes_max') or 0) for x in f), ci_mean=[float(v.mean() - t975(len(v) - 1) * v.std(ddof=1) / np.sqrt(len(v))), float(v.mean() + t975(len(v) - 1) * v.std(ddof=1) / np.sqrt(len(v)))] if len(v) > 1 else None)
        t = tab[m]; print(f"   m={m:>5}: survival {t['mean']:.4f} (seq sd {t['sd_seq']:.4f}, {t['n_seq']} seqs x {n // max(1, len(v))} shots) ok {ok}/{len(f)} seamless {seam}/{len(f)} cnr {cnr} segments {t['n_segments']} cmd_bytes_max {t['cmd_bytes_max']}" + (f"  95% CI [{t['ci_mean'][0]:.4f}, {t['ci_mean'][1]:.4f}]" if t['ci_mean'] else ''))
    # joint fit over m <= 512
    fit_m = [m for m in ms if m <= 512]
    n0h, n1h = len(z0) - h0, len(z1) - h1
    def fitp(sample, floor=None):
        from scipy.optimize import least_squares
        fl = Bf if floor is None else floor
        keys = [(m, s) for m in fit_m for s in range(NSEQ) if (m, s) in sample]; y = np.array([sample[k] for k in keys]); mm = np.array([k[0] for k in keys], float)
        r = least_squares(lambda x: fl + x[0] * x[1] ** mm - y, x0=[0.3, 0.995], bounds=([0, 0.9], [1, 1.0])); return r.x
    def floor_resample():   # binomial resample of the held-out preparation counts -> a new floor estimate for one bootstrap fit
        return (rng.binomial(n0h, P00) / n0h + 1 - rng.binomial(n1h, P11) / n1h) / 2
    means = {k: float(v.mean()) for k, v in surv.items()}
    A_, p_ = fitp(means); epc = (1 - p_) / 2
    print(f"   joint fit m <= 512: A {A_:.3f} p {p_:.5f} EPC {epc:.5f}")
    return dict(P00=float(P00), P11=float(P11), floor=float(Bf), table={str(k): v for k, v in tab.items()}, A=float(A_), p=float(p_), EPC=float(epc), _surv=surv, _fitp=fitp, _means=means, _floor_resample=floor_resample)
out['B'] = analyze(tagB, prepB, 'B = Ant-Q image c26942c0')
if tagA: out['A'] = analyze(tagA, prepA, 'A = stock image')
# (i) EPC equivalence, paired sequence bootstrap
if 'A' in out:
    dB, dA = out['B'], out['A']; shared = [m for m in [16, 32, 64, 128, 256, 512] if (m, 0) in dB['_surv'] and (m, 0) in dA['_surv']]
    diffs = []
    for _ in range(1000):
        sB, sA = {}, {}
        for m in shared:
            pick = rng.choice(NSEQ, NSEQ)
            for j, s in enumerate(pick):
                vb, va = dB['_surv'][(m, s)], dA['_surv'][(m, s)]
                sB[(m, j)] = float(rng.choice(vb, len(vb)).mean()); sA[(m, j)] = float(rng.choice(va, len(va)).mean())
        pB = dB['_fitp'](sB, dB['_floor_resample']())[1]; pA = dA['_fitp'](sA, dA['_floor_resample']())[1]; diffs.append((1 - pB) / 2 - (1 - pA) / 2)   # floor uncertainty propagated
    ci = np.percentile(diffs, [2.5, 97.5]); d = dB['EPC'] - dA['EPC']
    verdict = 'EQUIVALENT' if (-0.005 <= ci[0] and ci[1] <= 0.005) else ('DIFFERENT' if (ci[1] < -0.005 or ci[0] > 0.005) else 'INCONCLUSIVE')
    out['epc_diff_B_minus_A'] = dict(value=float(d), ci=ci.tolist(), margin=0.005, verdict=verdict, shared_lengths=shared)
    print(f"EPC diff B-A over m <= 512 (paired sequences, 95 % bootstrap CI, 1000 resamples, held-out floors resampled): {d:+.5f} [{ci[0]:+.5f}, {ci[1]:+.5f}] vs +-0.005 -> {verdict}")
for k in ('B', 'A'):
    if k in out:
        for kk in ('_surv', '_fitp', '_means', '_floor_resample'): out[k].pop(kk, None)
json.dump(out, open(os.path.join(an, f'deep_rb_{tagB}{"_" + tagA if tagA else ""}.json'), 'w'), indent=1)
print('saved', os.path.join(an, f'deep_rb_{tagB}{"_" + tagA if tagA else ""}.json'))
