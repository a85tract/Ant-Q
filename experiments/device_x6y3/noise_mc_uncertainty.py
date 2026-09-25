"""Monte Carlo uncertainty of the noise-spectroscopy numbers in ramsey_noise_spectrum.json: the 50 %-detection levels (whole
record and per run), their ratio in spectral density, and the nominal 95 % upper limits, from binomial resampling of the stored
simulated rates (300 records per level for detection, 500 for the limit), interpolated as in ramsey_noise_spectrum.py.
usage: python noise_mc_uncertainty.py [results_dir]   (default: $ANTQ_RESULTS)"""
import json, os, sys
import numpy as np

res = sys.argv[1] if len(sys.argv) > 1 else os.environ['ANTQ_RESULTS']
d = json.load(open(os.path.join(res, 'analysis', 'ramsey_noise_spectrum.json'))); rng = np.random.default_rng(1)
GW, GR = np.geomspace(1e7, 3e9, 13), np.geomspace(1e7, 1e10, 13)      # the detection grids of ramsey_noise_spectrum.py

def up(grid, rate, level):
    """log-interpolated level at which a rising rate first reaches `level`"""
    j = int(np.argmax(rate >= level))
    return float(np.exp(np.interp(level, [rate[j - 1], rate[j]], np.log([grid[j - 1], grid[j]])))) if rate[0] < level <= rate[j] else np.nan

def ci(x): x = np.asarray(x); x = x[np.isfinite(x)]; return np.percentile(x, [2.5, 97.5])
for tag in ('EB1', 'EB2'):
    o = d[tag]; pw, pr = np.array(o['detect_power_record']), np.array(o['detect_power_run'])
    ng, nf = np.array(o['neyman_grid']), np.array(o['neyman_frac'])
    bw, br, bl = [], [], []
    for _ in range(4000):
        bw.append(up(GW, np.maximum.accumulate(rng.binomial(300, pw) / 300), 0.5))
        br.append(up(GR, np.maximum.accumulate(rng.binomial(300, pr) / 300), 0.5))
        bl.append(up(ng, -np.minimum.accumulate(rng.binomial(500, nf) / 500), -0.05))   # falling fraction: 95 % limit where it reaches 5 %
    bw, br, bl = map(np.array, (bw, br, bl)); ok = np.isfinite(bw) & np.isfinite(br)
    kw = lambda a: np.sqrt(a) / 1e3
    print(f"{tag}: 50 % detection {kw(up(GW, pw, 0.5)):.1f} {np.round(kw(ci(bw)), 1)} (record), {kw(up(GR, pr, 0.5)):.1f} {np.round(kw(ci(br)), 1)} (runs) "
          f"kHz/rtHz; spectral-density ratio {up(GR, pr, 0.5) / up(GW, pw, 0.5):.2f} {np.round(ci(br[ok] / bw[ok]), 2)}; "
          f"95 % limit {kw(up(ng, -nf, -0.05)):.1f} {np.round(kw(ci(bl)), 1)} kHz/rtHz")
print(f"false-alarm rate of the 95th percentile of 600 null records: 5.0 +- {100 * np.sqrt(0.05 * 0.95 / 600):.1f} % (1 s.d.)")
