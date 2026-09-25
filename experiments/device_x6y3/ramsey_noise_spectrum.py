"""Pre-registered noise analysis of the paired Ramsey records (program P0-B, idx 104) of the four ABAB blocks.

Each iteration = [+quadrature Ramsey - read - pad][-quadrature Ramsey - read - pad], one read every 2.000 ms, 25000 iterations
(100 s), tau_R = 0.5 us. Ant-Q blocks (EB1, EB2): one uninterrupted hardware-loop record. Stock blocks (EA1, EA2): the same body
acquired by the stock runner in accumulator-sized runs of 512 iterations (1024 reads, 2.048 s; the last run 424) with untimed host gaps.
Estimator: d_k = y+ - y- (binary outcomes of the block's held-out classifier). A frequency offset df shifts both halves' phase by
dphi = 2 pi df tau_R and moves their outcomes in opposite directions, so E[d] = 2 K dphi, K = dP1/dphi from the block's 5-point
slope calibration (idx 105-109); a readout drift moves both halves alike and cancels in d.
  1. Spectrum (the pre-registered analysis, with the deviations below): Hann periodogram of d; Whittle fit of n + a |H(f)|^2 / f
     over 0.1-100 Hz, H(f) = cos(pi f 2 ms) (d sums two reads 2 ms apart); likelihood-ratio (LR) test against white noise. Ant-Q records: the whole record. Stock records:
     the periodograms of the single runs averaged (the untimed gaps leave no common time axis across runs, so 0.49 Hz is the lowest
     frequency), with the same per-run operator applied to the Ant-Q records as the control. Calibration end to end: simulated
     records of Bernoulli outcomes (the block's outcome probabilities, K drawn from its calibration uncertainty, phase noise with
     S_f = A/f from 0.01 to 250 Hz synthesised at every read, so aliasing from 125-250 Hz is included) through the same periodogram
     and fit give the null distribution of the LR and the 95 % upper limit on A: the A at which 5 % of simulated records give an LR
     at or below the observed one, the slope uncertainty included by averaging over it (hybrid treatment); the same limit and the level
     detected with 50 % probability (5 % false alarm) also from the per-run analysis, i.e. the sensitivity that runs of 2.048 s allow for
     the same total measurement time. The limit holds for this
     model and for a slope that stays at its calibrated value during the record.
  2. Run-rate lines: in the pair-index series of every block (stock: runs concatenated), the ordinates at k/512 cycles per pair
     (k = 1..5) against the local median, summed; p-value from the same statistic on the simulated white records. Plus the first 16
     pairs of each run minus the rest.
  3. Consecutive pairs (added after the pre-registration, descriptive): the correlation coefficient of consecutive pair differences
     (4 ms apart; stock: within runs), per record and averaged over the four, with its white-noise standard error. A readout drift
     slower than a few ms cancels in it. Frequency noise that is constant over several pairs adds 4 K^2 sinh(sigma_phi^2) for
     Gaussian noise; with the Ramsey envelope D, quasi-static noise gives (2 K^2 / D(tau_R)^2) (1 - D(2 tau_R)). The predictions for
     quasi-static noise that by itself produced T2* = 1.4 us are given for a Gaussian envelope (sigma_phi^2 = 2 (tau_R / T2*)^2) and
     for an exponential one (Lorentzian detuning distribution); they are predictions of these two models, not a bound on all noise
     (components between about 60 and 190 Hz enter with a negative weight).
  Mean operating-point check: mean(d) / 2K of every record lies inside the +-0.4 rad of its slope calibration; excursions within a
  record and the stability of K during it are not measured.
Deviations from the pre-registration (plan of 2026-09-03): two Ant-Q records instead of three; one slope calibration per record (after
it) instead of one before and one after; tau_R = 0.5 us instead of 0.3 T2* = 0.42 us; the stock host gaps were not timestamped (hence
the per-run analysis); no fast-cadence aliasing run (noise above 250 Hz is not modelled); upper band edge 100 Hz ("well below
125 Hz" in the plan); the exponent of the 1/f term is fixed at 1 (no component is resolved, so a free exponent is not identifiable).
usage: python ramsey_noise_spectrum.py [results_dir] [out.pdf]   (default: $ANTQ_RESULTS, <results>/analysis/)"""
import glob, json, os, sys
import numpy as np
from scipy import optimize, signal

RES = sys.argv[1] if len(sys.argv) > 1 else os.environ['ANTQ_RESULTS']
AN = os.path.join(RES, 'analysis'); os.makedirs(AN, exist_ok=True)
OUT_PDF = sys.argv[2] if len(sys.argv) > 2 else os.path.join(AN, 'ramsey_noise_spectrum.pdf')
TAU_R = 0.5e-6            # s, AQT_TAU_R_S of the session (results/device_x6y3/README.md)
T2S = 1.4e-6              # s, T2* of the operator's calibration of the day
DT_READ = 2e-3            # s per read; one pair per 4 ms
FS = 1 / (2 * DT_READ)    # 250 Hz pair rate
RUN = 512                 # pairs per stock run (1024 accumulator records / 2 reads per iteration)
CAL_PHASES = np.array([-0.4, -0.2, 0.0, 0.2, 0.4])
BAND = (0.1, 100.0)       # Hz, the analysis band (plan: 0.1 Hz to well below 125 Hz)
BLOCKS = {'EA1': 'QubiC', 'EB1': 'Ant-Q', 'EA2': 'QubiC', 'EB2': 'Ant-Q'}
N_NULL, N_NEYMAN = 1000, 500
rng = np.random.default_rng(20260917)


class QDA:
    def fit(self, X0, X1):
        self.m = [X0.mean(0), X1.mean(0)]; C = [np.cov(X0.T), np.cov(X1.T)]
        self.Ci = [np.linalg.inv(c) for c in C]; self.ld = [np.log(np.linalg.det(c)) for c in C]; return self
    def predict(self, X):
        ll = [-(np.einsum('ij,jk,ik->i', X - m, Ci, X - m)) - ld for m, Ci, ld in zip(self.m, self.Ci, self.ld)]
        return (ll[1] > ll[0]).astype(int)
xy = lambda z: np.column_stack([z.real, z.imag])
def load(tag, group, idx):
    z = np.load(sorted(glob.glob(os.path.join(RES, 'iq', f'{tag}_{group}_{idx}_*.npz')))[-1])
    return np.asarray(z[[k for k in z.files if k.endswith('.rdlo')][0]]).reshape(-1)


def spectrum(d, per_run):
    """Mean Hann periodogram of d: the whole record, or its full 512-pair runs; returns f, p, number of periodograms averaged."""
    x = d[:len(d) // RUN * RUN].reshape(-1, RUN) if per_run else d[None]
    f, p = signal.periodogram(x - x.mean(1, keepdims=True), fs=FS, window='hann', scaling='density', axis=-1)
    return f[1:-1], p.mean(0)[1:-1], len(x)
H2 = lambda f: np.cos(np.pi * f * DT_READ) ** 2
def fit(f, p, m):
    """Whittle fit of n + a H2(f)/f to a mean of m periodograms over BAND: LR against white noise (profile over a), white level."""
    k = (f >= BAND[0]) & (f <= BAND[1]); f, p = f[k], p[k]; g = H2(f) / f; n0 = p.mean()
    nll = lambda ln, la: m * np.sum(np.log(np.exp(ln) + np.exp(la) * g) + p / (np.exp(ln) + np.exp(la) * g))
    prof = lambda la: optimize.minimize_scalar(lambda ln: nll(ln, la), bounds=(np.log(n0) - 1, np.log(n0) + 1), method='bounded').fun
    las = np.linspace(np.log(n0) - 12, np.log(n0) + 2, 15); v = [prof(x) for x in las]; i = int(np.argmin(v))
    r = optimize.minimize_scalar(prof, bounds=(las[max(i - 1, 0)], las[min(i + 1, len(las) - 1)]), method='bounded')
    return max(0.0, 2 * (m * np.sum(np.log(n0) + p / n0) - min(r.fun, v[i]))), float(n0)
def line_ratios(f, p):
    """Run-rate lines: the ordinates nearest k/512 cycles per pair (k = 1..5) over their local median level (~Exp(1) if white)."""
    r = []
    for k in range(1, 6):
        i = int(np.argmin(abs(f - k * FS / RUN))); r.append(float(p[i] / (np.median(p[max(0, i - 40):i + 40]) / np.log(2))))
    return r
def lag1(d, per_run):
    """Autocovariance of consecutive pair differences (4 ms apart); stock records: only pairs inside one run."""
    x = d - d.mean(); pr = x[:-1] * x[1:]
    if per_run: pr = np.delete(pr, np.arange(RUN - 1, len(pr), RUN))
    return float(pr.mean()), float(d.var() / np.sqrt(len(pr)))


def block(tag):
    z0, z1 = load(tag, 'p0a', 102), load(tag, 'p0a', 103); n0, n1 = len(z0) // 2, len(z1) // 2
    clf = QDA().fit(xy(z0[:n0]), xy(z1[:n1]))
    y = clf.predict(xy(load(tag, 'ramsey', 104))).reshape(-1, 2).astype(float)
    cal = [clf.predict(xy(load(tag, 'ramsey', 105 + k))) for k in range(5)]
    return y, cal_slope(np.array([c.mean() for c in cal]), np.array([len(c) for c in cal]))
def cal_slope(P, n):
    se = np.sqrt(P * (1 - P) / n)
    (K, _), cov = np.polyfit(CAL_PHASES, P, 1, w=1 / se, cov='unscaled'); return float(K), float(np.sqrt(cov[0, 0]))


out, spectra = {}, {}
for tag, stack in BLOCKS.items():
    y, (K, sK) = block(tag); d = y[:, 0] - y[:, 1]; pp, pm = y[:, 0].mean(), y[:, 1].mean(); stock = stack == 'QubiC'
    vB = pp * (1 - pp) + pm * (1 - pm)
    f, p, _ = spectrum(d, False); fr, pr, mr = spectrum(d, True)
    lr_run, n_run = fit(fr, pr, mr)
    o = dict(stack=stack, pairs=len(d), P1_plus=pp, P1_minus=pm, K=K, K_se=sK, offset_rad=float(d.mean() / (2 * K)),
             var_d=float(d.var()), var_bernoulli=vB, white_level_bernoulli=2 * vB / FS, lr_run=lr_run, white_level_run=n_run, runs=mr)
    assert abs(o['offset_rad']) < CAL_PHASES.max(), f'{tag}: operating point outside the calibrated linear range'
    if not stock:     # the whole-record spectrum has a time axis only on the uninterrupted records
        o['lr'], o['white_level'] = fit(f, p, 1)
    lines = line_ratios(f, p); seg = d[:len(d) // RUN * RUN].reshape(-1, RUN)
    c1, c1_se = lag1(d, stock)
    o.update(runrate_line_ratios=lines,
             segment_head_minus_rest=float(seg[:, :16].mean() - seg[:, 16:].mean()), lag1_cov=c1, lag1_cov_se=c1_se, lag1_corr=c1 / o['var_d'])
    out[tag] = o; spectra[tag] = (f, p, fr, pr)


# ---- end-to-end simulation of a record: phase noise S_f = A/f at every read, Bernoulli outcomes
def sim_d(o, K, A=0.0):
    n = o['pairs']; ph = np.zeros(2 * n)
    if A > 0:
        fq = np.fft.rfftfreq(2 * n, DT_READ); S = np.r_[0.0, A / fq[1:]]
        df = np.fft.irfft(np.sqrt(S * n / DT_READ) * (rng.normal(size=len(fq)) + 1j * rng.normal(size=len(fq))) / np.sqrt(2), n=2 * n)
        ph = 2 * np.pi * TAU_R * df
    return ((rng.random(n) < o['P1_plus'] + K * np.sin(ph[0::2])).astype(float)
            - (rng.random(n) < o['P1_minus'] - K * np.sin(ph[1::2])).astype(float))
draw_K = lambda o: max(rng.normal(abs(o['K']), o['K_se']), 1e-3)
null_full, null_line = [], []
for _ in range(N_NULL):
    f_, p_, m_ = spectrum(sim_d(out['EB1'], draw_K(out['EB1'])), False)
    null_full.append(fit(f_, p_, m_)[0]); null_line.append(sum(line_ratios(f_, p_)))
null_full, null_line = np.array(null_full), np.array(null_line)
null_run = np.array([fit(*spectrum(sim_d(out['EA1'], draw_K(out['EA1'])), True))[0] for _ in range(N_NULL)])
for tag, o in out.items():
    o['p_lr_run'] = float(np.mean(null_run >= o['lr_run'])); o['runrate_line_p'] = float(np.mean(null_line >= sum(o['runrate_line_ratios'])))
    if 'lr' in o: o['p_lr'] = float(np.mean(null_full >= o['lr']))
def neyman(o, per_run, lr_obs, grid):
    """Neyman 95 % upper limit on A: the A at which 5 % of simulated records give an LR at or below the observed one."""
    frac = np.array([np.mean([fit(*spectrum(sim_d(o, draw_K(o), A), per_run))[0] <= lr_obs for _ in range(N_NEYMAN)]) for A in grid])
    j = int(np.argmax(frac <= 0.05)); assert frac[0] > 0.05 and frac[j] <= 0.05, frac
    return float(np.exp(np.interp(0.05, [frac[j], frac[j - 1]], [np.log(grid[j]), np.log(grid[j - 1])]))), frac
grid = np.geomspace(1e7, 1e10, 13)      # A in Hz^2: sqrt(S_f(1 Hz)) from 3.2 to 100 kHz/sqrt(Hz)
for tag in ('EB1', 'EB2'):     # whole uninterrupted record
    o = out[tag]; A95, frac = neyman(o, False, o['lr'], grid)
    o.update(A95_Hz2=A95, sqrtSf_1Hz_limit_Hz_per_rtHz=float(np.sqrt(A95)), neyman_grid=grid.tolist(), neyman_frac=frac.tolist())
# the same records (Ant-Q) and the stock records analysed run by run (2.048 s, from 0.49 Hz): the limit the stock acquisition
# allows for the same total measurement time; on the Ant-Q records the difference to the whole-record limit is due to the
# acquisition continuity alone
grid_run = np.geomspace(1e7, 1e11, 17)
for tag in BLOCKS:
    o = out[tag]; A95r, fracr = neyman(o, True, o['lr_run'], grid_run)
    o.update(A95_run_Hz2=A95r, sqrtSf_1Hz_limit_run_Hz_per_rtHz=float(np.sqrt(A95r)), neyman_grid_run=grid_run.tolist(), neyman_frac_run=fracr.tolist())

# ---- detection sensitivity for the same total measurement time: the 1/f level detected with 50 % probability at a 5 % false-alarm
# rate (LR above the 95th percentile of its null distribution), from the whole record and from the same record split into runs
def a50(o, per_run, grid, n=300):
    null = np.array([fit(*spectrum(sim_d(o, draw_K(o)), per_run))[0] for _ in range(600)]); t95 = np.percentile(null, 95)
    pw = np.array([np.mean([fit(*spectrum(sim_d(o, draw_K(o), A), per_run))[0] > t95 for _ in range(n)]) for A in grid])
    j = int(np.argmax(pw >= 0.5)); assert pw[0] < 0.5 <= pw[j], pw
    return float(np.exp(np.interp(0.5, [pw[j - 1], pw[j]], [np.log(grid[j - 1]), np.log(grid[j])]))), pw.tolist()
for tag in ('EB1', 'EB2'):
    o = out[tag]
    A50w, pww = a50(o, False, np.geomspace(1e7, 3e9, 13)); A50r, pwr = a50(o, True, np.geomspace(1e7, 1e10, 13))
    o.update(sqrtSf_1Hz_detect50_record_Hz_per_rtHz=float(np.sqrt(A50w)), sqrtSf_1Hz_detect50_run_Hz_per_rtHz=float(np.sqrt(A50r)),
             detect_power_record=pww, detect_power_run=pwr)

# ---- test 3: consecutive pairs, and what quasi-static noise producing T2* would give
col = lambda key: np.array([out[t][key] for t in BLOCKS])
K2 = float(np.mean(col('K') ** 2)); vB = float(np.mean(col('var_bernoulli')))
c_gauss = 4 * K2 * np.sinh(2 * (TAU_R / T2S) ** 2); c_exp = 2 * K2 * (np.exp(2 * TAU_R / T2S) - 1)
out['pooled'] = dict(lag1_corr_mean=float(np.mean(col('lag1_corr'))), lag1_corr_se=float(np.sqrt(np.sum(col('lag1_cov_se') ** 2)) / 4 / vB),
                     sigma_f_quasistatic_gauss_Hz=float(np.sqrt(2) / (2 * np.pi * T2S)),
                     lag1_corr_if_quasistatic_gauss=float(c_gauss / (vB + c_gauss / 2)), lag1_corr_if_quasistatic_exp=float(c_exp / (vB + c_exp / 2)))
out['mc'] = dict(null_lr_full_95th=float(np.percentile(null_full, 95)), null_lr_run_95th=float(np.percentile(null_run, 95)),
                 null_line_95th=float(np.percentile(null_line, 95)), n_null=N_NULL, n_neyman=N_NEYMAN)

# ---- binned spectra in frequency-noise units, JSON, printout
for tag in BLOCKS:
    o = out[tag]; conv = (2 * abs(o['K']) * 2 * np.pi * TAU_R) ** 2        # d-units per (Hz of frequency offset)^2
    e = np.geomspace(0.01, 125, 31); c = np.sqrt(e[1:] * e[:-1]); sp = {}
    for name, (f, p) in (('record', spectra[tag][:2]), ('run', spectra[tag][2:])):
        sp[name] = [float(p[(f >= a) & (f < b)].mean() / conv) if ((f >= a) & (f < b)).any() else None for a, b in zip(e[:-1], e[1:])]
    o['spectrum_binned'] = dict(f_Hz=c.tolist(), Sf_record_Hz2_per_Hz=sp['record'], Sf_run_Hz2_per_Hz=sp['run'],
                                floor_Hz2_per_Hz=o['white_level_bernoulli'] / conv)
json.dump(out, open(os.path.join(AN, 'ramsey_noise_spectrum.json'), 'w'), indent=1, default=float)
for tag in BLOCKS:
    o = out[tag]
    print(f"{tag} ({o['stack']}): K {o['K']:+.3f}+-{o['K_se']:.3f}/rad  offset {o['offset_rad']:+.3f} rad  white(run) {o['white_level_run']:.5f} vs "
          f"binomial {o['white_level_bernoulli']:.5f}/Hz  LR run-avg {o['lr_run']:.2f} (p {o['p_lr_run']:.2f})"
          + (f"  LR record {o['lr']:.2f} (p {o['p_lr']:.2f}) white {o['white_level']:.5f}  sqrtS_f(1 Hz) <= {o['sqrtSf_1Hz_limit_Hz_per_rtHz'] / 1e3:.1f} kHz/rtHz" if 'lr' in o else '')
          + f"  per-run limit {o['sqrtSf_1Hz_limit_run_Hz_per_rtHz'] / 1e3:.1f} kHz/rtHz"
          + (f"  50 %-detection level record {o['sqrtSf_1Hz_detect50_record_Hz_per_rtHz'] / 1e3:.1f} / runs {o['sqrtSf_1Hz_detect50_run_Hz_per_rtHz'] / 1e3:.1f} kHz/rtHz" if 'sqrtSf_1Hz_detect50_record_Hz_per_rtHz' in o else '')
          + f"  run-rate lines p {o['runrate_line_p']:.2f}  head-rest {o['segment_head_minus_rest']:+.4f}  lag-1 corr {o['lag1_corr']:+.4f}")
print('pooled:', out['pooled']); print('MC:', out['mc'])

import matplotlib; matplotlib.use('Agg'); import matplotlib.pyplot as plt
# paper figure: the two uninterrupted Ant-Q records with their binomial floors, the stock runs (per-run spectra, from 0.49 Hz), the
# 95 % limit on a 1/f term (seen through the same pair response H^2 as the data)
fig, ax = plt.subplots(figsize=(4.4, 2.8))                        # printed at about 11 cm: all text >= 8 pt
fx = np.array(out['EB1']['spectrum_binned']['f_Hz']); arr = lambda v: np.array([np.nan if x is None else x for x in v])
for tag, color, mk in (('EB1', '#0a6ba0', 's'), ('EB2', '#e08030', 'o')):
    sp = out[tag]['spectrum_binned']
    ax.loglog(fx, arr(sp['Sf_record_Hz2_per_Hz']), mk + '-', color=color, ms=3, lw=0.8, label=f'Ant-Q record {tag[-1]}')
    ax.axhline(sp['floor_Hz2_per_Hz'], color=color, ls='--', lw=0.8)
st = np.mean([arr(out[t]['spectrum_binned']['Sf_run_Hz2_per_Hz']) for t in ('EA1', 'EA2')], axis=0)     # empty below 0.49 Hz in both
ax.loglog(fx, st, '^-', color='#777777', ms=3, lw=0.8, label='QubiC, per run')
fb = np.geomspace(BAND[0], BAND[1], 50); A95 = max(out[t]['A95_Hz2'] for t in ('EB1', 'EB2'))
ax.loglog(fb, A95 * H2(fb) / fb, ':', color='#333333', lw=1.2, label='95 % limit on a 1/$f$ term')
ax.axvspan(BAND[0], BAND[1], color='#dddddd', alpha=0.35, lw=0)
ax.set_xlabel('Frequency (Hz)', fontsize=9); ax.set_ylabel('Frequency noise $S_f$ (Hz$^2$/Hz)', fontsize=9)
ax.tick_params(labelsize=8); ax.legend(fontsize=8, frameon=False, loc='lower left')
for s_ in ('top', 'right'): ax.spines[s_].set_visible(False)
fig.tight_layout(); fig.savefig(OUT_PDF); print('wrote', OUT_PDF)
