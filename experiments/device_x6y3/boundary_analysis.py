"""Boundary experiment (Q5, 8-core image c26942c0): quantum consequence of one command-buffer handover. Three configurations of
identical programs -- S (streamed as 2 segments, handover inside the coherent evolution), U (unbroken) and UD (unbroken with an
idle of 152 ns inserted at the cut, the control for the time the handover adds to the evolution).
Fringe family: idx 220-232 (S) / 240-252 (U) / 260-272 (UD), 13 phases; RB family: idx 400/500/600 + 10L + s, lengths from AQT_BRB_LENGTHS,
8 sequences. Classifier: held-out QDA from <PREP>_p0a idx 102/103 (first half fit, second half evaluated).
Pre-registered: fringe |phase diff| <= 0.10 rad and contrast ratio 0.90-1.10 (95 % bootstrap CI of the difference fully inside ->
EQUIVALENT, fully outside -> DIFFERENT, else INCONCLUSIVE); RB boundary factor hS from the joint fit P = B + A p^m hS^b (b = 1 for S,
0 for U), hS in [0.95, 1.05] with the same CI rule; floor B = (P00 + 1 - P11)/2 from the held-out matrix.
usage: python boundary_analysis.py <TAG> [results_dir] [<PREP>]   (reads iq/<PREP>_p0a_*, iq/<TAG>_fringe_<idx>_*, iq/<TAG>_rb_<idx>_*;
PREP defaults to TAG)"""
import os, sys, glob, json
import numpy as np
tag = sys.argv[1]
res = sys.argv[2] if len(sys.argv) > 2 else os.environ['ANTQ_RESULTS']
prep = sys.argv[3] if len(sys.argv) > 3 else tag          # optional: tag of the P0-A preparation to use as the classifier (e.g. BND2 for BNDF)
iq = os.path.join(res, 'iq'); an = os.path.join(res, 'analysis'); os.makedirs(an, exist_ok=True)
rng = np.random.default_rng(20260917)
PH = np.linspace(-np.pi, np.pi, 13)
LENGTHS = [int(x) for x in os.environ.get('AQT_BRB_LENGTHS', '16,32,64,128').split(',')]

def load_tag(t, grp, idx):
    fs = sorted(glob.glob(f'{iq}/{t}_{grp}_{idx}_*.npz')); z = np.load(fs[-1]); ks = [k for k in z.keys() if k.endswith('.rdlo')]; return np.asarray(z[ks[0]]).reshape(-1)
def load(grp, idx, streamed):
    fs = sorted(glob.glob(f'{iq}/{tag}_{grp}_{idx}_*.npz'))
    if not fs: return None
    z = np.load(fs[-1]); ks = [k for k in z.keys() if k.endswith('.rdlo')]
    if streamed:           # streamed unit records. Fixed host client (2026-09-17 23:50): only units with a read carry an array -> take
        ks = sorted(ks, key=lambda k: int(k[1:k.index('_')]))          # them in unit order. Old client: every unit carried one word and
        ids = [int(k[1:k.index('_')]) for k in ks]                       # the R real records occupied the FIRST R slots (shot order),
        vals = np.asarray([complex(np.asarray(z[k]).reshape(-1)[0]) for k in ks])   # the rest being stale memory -> take the first half.
        if len(set(i % 2 for i in ids)) == 1:
            return vals
        return vals[:len(vals) // 2]
    return np.asarray(z[ks[0]]).reshape(-1)

def xy(z): return np.column_stack([z.real, z.imag])
class QDA:
    def fit(self, X0, X1):
        self.m = [X0.mean(0), X1.mean(0)]; C = [np.cov(X0.T), np.cov(X1.T)]
        self.Ci = [np.linalg.inv(c) for c in C]; self.ld = [np.log(np.linalg.det(c)) for c in C]; return self
    def predict(self, X):
        s = []
        for k in range(2):
            d = X - self.m[k]; s.append(-0.5 * np.einsum('ij,jk,ik->i', d, self.Ci[k], d) - 0.5 * self.ld[k])
        return (s[1] > s[0]).astype(int)

z0, z1 = load_tag(prep, 'p0a', 102), load_tag(prep, 'p0a', 103)
h0, h1 = len(z0) // 2, len(z1) // 2
clf = QDA().fit(xy(z0[:h0]), xy(z1[:h1]))
lab0, lab1 = clf.predict(xy(z0[h0:])), clf.predict(xy(z1[h1:]))   # held-out labels; also resampled for the floor's uncertainty
P00 = 1 - lab0.mean(); P11 = lab1.mean()
B = (P00 + 1 - P11) / 2
print(f"{tag} (classifier from {prep}): held-out readout P00 {P00:.3f} P11 {P11:.3f} -> RB floor B {B:.3f}")
out = {'readout': {'P00': float(P00), 'P11': float(P11), 'floor': float(B)}, 'fringe': {}, 'rb': {}}

def fringe_fit(P):
    A = np.column_stack([np.ones_like(PH), np.cos(PH), np.sin(PH)]); c, *_ = np.linalg.lstsq(A, P, rcond=None)
    return float(c[0]), float(np.hypot(c[1], c[2])), float(np.arctan2(c[2], c[1]))

CONFIGS = {'S': (220, True), 'U': (240, False), 'UD': (260, False)}
labels = {}
for cfg, (base, st) in CONFIGS.items():
    labels[cfg] = [clf.predict(xy(load('fringe', base + k, st))) if load('fringe', base + k, st) is not None else None for k in range(13)]
    if any(l is None for l in labels[cfg]): print(f"  fringe {cfg}: missing programs {[k for k, l in enumerate(labels[cfg]) if l is None]}"); continue
    off, con, ph = fringe_fit(np.array([l.mean() for l in labels[cfg]]))
    out['fringe'][cfg] = {'offset': off, 'contrast': con, 'phase': ph, 'P1': [float(l.mean()) for l in labels[cfg]], 'n_each': int(len(labels[cfg][0]))}
    print(f"  fringe {cfg}: offset {off:.3f} contrast {con:.3f} phase {ph:+.3f} rad (n {len(labels[cfg][0])} per phase)")

def boot_fringe(la, lb, nb=2000):
    d_ph, r_con = [], []
    for _ in range(nb):
        Pa = np.array([rng.choice(l, len(l)).mean() for l in la]); Pb = np.array([rng.choice(l, len(l)).mean() for l in lb])
        _, ca, pa = fringe_fit(Pa); _, cb, pb = fringe_fit(Pb)
        d_ph.append(np.angle(np.exp(1j * (pa - pb)))); r_con.append(ca / cb)
    return np.percentile(d_ph, [2.5, 97.5]), np.percentile(r_con, [2.5, 97.5])

def verdict(lo, hi, mlo, mhi):
    if mlo <= lo and hi <= mhi: return 'EQUIVALENT'
    if hi < mlo or lo > mhi: return 'DIFFERENT'
    return 'INCONCLUSIVE'
# systematic band for S vs UD, as fixed before the acquisition: the pause of UD may differ from the time the handover adds by up to
# 50 ns (the handover was then known to +-40 ns from the bench scope), i.e. phase 2 pi x 30 kHz x 50 ns = 0.009 rad and contrast
# exp(50 ns / 1.4 us) (exponential decay, the conservative model); the S-UD verdict uses the bootstrap CI widened by this band.
# (The handover is now measured at 134 ns + the 10 ns start offset = 144 ns against the 152 ns pause of UD.)
SYS_PHASE, SYS_F = 0.0095, float(np.exp(50.0 / 1400.0))
for a, b in (('S', 'U'), ('S', 'UD'), ('UD', 'U')):
    if a in out['fringe'] and b in out['fringe']:
        (plo, phi_), (clo, chi) = boot_fringe(labels[a], labels[b])
        dph = float(np.angle(np.exp(1j * (out['fringe'][a]['phase'] - out['fringe'][b]['phase'])))); rc = out['fringe'][a]['contrast'] / out['fringe'][b]['contrast']
        bp, bf = (SYS_PHASE, SYS_F) if (a, b) == ('S', 'UD') else (0.0, 1.0)
        out['fringe'][f'{a}-{b}'] = {'phase_diff': dph, 'phase_ci': [float(plo), float(phi_)], 'phase_sys_band': bp,
                                     'phase_verdict': verdict(plo - bp, phi_ + bp, -0.10, 0.10),
                                     'contrast_ratio': float(rc), 'contrast_ci': [float(clo), float(chi)], 'contrast_sys_factor': bf,
                                     'contrast_verdict': verdict(clo / bf, chi * bf, 0.90, 1.10)}
        print(f"  fringe {a} vs {b}: phase diff {dph:+.3f} [{plo:+.3f}, {phi_:+.3f}] -> {out['fringe'][f'{a}-{b}']['phase_verdict']}; contrast ratio {rc:.3f} [{clo:.3f}, {chi:.3f}] -> {out['fringe'][f'{a}-{b}']['contrast_verdict']}" + (' (CI widened by the systematic band)' if bp else ''))

# ---- RB: survival per (configuration, m, seq); joint fit P = B + A p^m hS^b over both configurations (U: b = 0)
RBCONFIGS = {'S': (400, True), 'U': (500, False), 'UD': (600, False)}
surv = {}   # (config, L, s) -> label array (1 = excited; survival = P(0) = 1 - mean)
for cfg, (base, st) in RBCONFIGS.items():
    for L, m in enumerate(LENGTHS):
        for s in range(8):
            z = load('rb', base + 10 * L + s, st)
            if z is not None: surv[(cfg, L, s)] = 1 - clf.predict(xy(z))
def fit_h(sample, Bv=None):
    """sample: dict (config, L, s) -> survival value. LS fit of A, p, hS with the floor fixed (B, or Bv when given)."""
    Bv = B if Bv is None else Bv
    from scipy.optimize import least_squares
    keys = [k for k in sample if k[0] in ('S', 'U')]; y = np.array([sample[k] for k in keys]); ms = np.array([LENGTHS[k[1]] for k in keys])
    bS = np.array([1.0 if k[0] == 'S' else 0.0 for k in keys])
    def f(x):
        A, p, hS = x; return Bv + A * p ** ms * hS ** bS - y
    r = least_squares(f, x0=[0.5 - Bv + 0.3, 0.99, 1.0], bounds=([0, 0.5, 0.5], [1, 1, 1.5]))
    return r.x
if surv:
    means = {k: float(v.mean()) for k, v in surv.items()}
    for cfg in RBCONFIGS:
        row = [np.mean([means[k] for k in means if k[0] == cfg and k[1] == L]) if any(k[0] == cfg and k[1] == L for k in means) else np.nan for L in range(len(LENGTHS))]
        out['rb'][cfg] = {'survival_by_m': dict(zip(map(str, LENGTHS), map(float, row)))}
        print(f"  RB {cfg}: survival by m {dict(zip(LENGTHS, np.round(row, 4)))}")
    A_, p_, hS = fit_h(means)
    hs, hsB = [], []
    rngB = np.random.default_rng(20260925)   # separate stream: the pre-registered interval hs stays as it was
    for _ in range(1000):   # PAIRED bootstrap: resample sequence ids jointly across the two configurations within each length
        samp = {}                #   (the same random sequence is run in S and U), then shots within each (configuration, sequence)
        for L in range(len(LENGTHS)):
            seqs = sorted({k[2] for k in surv if k[1] == L})
            if not seqs: continue
            pick = rng.choice(seqs, len(seqs))
            for j, sid in enumerate(pick):
                for cfg in RBCONFIGS:
                    if (cfg, L, sid) in surv:
                        v = surv[(cfg, L, sid)]; samp[(cfg, L, j)] = float(rng.choice(v, len(v)).mean())
        hs.append(fit_h(samp)[2])
        Bb = ((1 - rngB.choice(lab0, len(lab0)).mean()) + 1 - rngB.choice(lab1, len(lab1)).mean()) / 2   # (P00 + 1 - P11) / 2, resampled
        hsB.append(fit_h(samp, Bb)[2])
    ciS = np.percentile(hs, [2.5, 97.5]); ciSB = np.percentile(hsB, [2.5, 97.5])
    out['rb']['fit'] = {'A': float(A_), 'p': float(p_), 'EPC': float((1 - p_) / 2), 'hS': float(hS), 'hS_ci': ciS.tolist(),
                        'hS_verdict': verdict(ciS[0], ciS[1], 0.95, 1.05), 'floor_B': float(B),
                        'hS_ci_with_floor_resampled': ciSB.tolist()}
    print(f"  RB joint fit: p {p_:.4f} (EPC {(1-p_)/2:.4f}), A {A_:.3f}; hS {hS:.3f} [{ciS[0]:.3f}, {ciS[1]:.3f}] -> {out['rb']['fit']['hS_verdict']}"
          f"; with the floor resampled [{ciSB[0]:.3f}, {ciSB[1]:.3f}]")
json.dump(out, open(os.path.join(an, f'{tag}_boundary_summary.json'), 'w'), indent=1)
print('saved', os.path.join(an, f'{tag}_boundary_summary.json'))
