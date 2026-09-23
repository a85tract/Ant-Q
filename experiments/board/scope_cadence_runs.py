#!/usr/bin/env python
"""Per-run re-analysis of scope cadence records that contain more than one program run (the 1 s window of the (5) captures holds
two 1024-shot runs of the runner's repeats; scope_cadence.py analyze treats the host gap between them as one shot interval).
Same pulse detection and shot segmentation as scope_cadence.py (thr_frac 0.4, gap 3 us); runs are split where a shot interval exceeds
--run-gap-ms (default 10). Appends one row per run to <results>/scope_cadence/cadence_summary_runs.csv.
usage: ANTQ_RESULTS=<dir> python scope_cadence_runs.py --tag phys5_n1 --period-us 248.544 [--tag ...]"""
import os, sys, csv, json, argparse
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__))); from scope_cadence import pulse_starts
ap = argparse.ArgumentParser(); ap.add_argument('--tag', action='append', required=True); ap.add_argument('--period-us', type=float, required=True)
ap.add_argument('--thr-frac', type=float, default=0.4); ap.add_argument('--gap-us', type=float, default=3.0); ap.add_argument('--run-gap-ms', type=float, default=10.0)
a = ap.parse_args(); RES = os.path.join(os.environ['ANTQ_RESULTS'], 'scope_cadence')
out = os.path.join(RES, 'cadence_summary_runs.csv'); new = not os.path.exists(out)
with open(out, 'a', newline='') as f:
    w = csv.writer(f)
    if new: w.writerow(['tag', 'k', 'run', 'n_runs_in_record', 'inter_run_gap_ms', 'n_shots', 'period_prog_us', 'mean_period_us', 'sd_ns', 'min_dev_ns', 'max_dev_ns', 'n_outside_1us', 'max_intra_gap_us', 'pulses_per_shot_median'])
    for tag in a.tag:
        for fn in sorted(x for x in os.listdir(os.path.join(RES, 'raw')) if x.startswith(tag + '_') and x.endswith('.npz')):
            z = np.load(os.path.join(RES, 'raw', fn)); meta = json.loads(str(z['meta'])); raw = z['raw']
            xi, ym, yo = meta['xincr'], meta['ymult'], meta['yoff']; v = (raw.astype(np.float32) - yo) * ym
            starts, ends, thr = pulse_starts(v, xi, a.thr_frac); ts = starts * xi * 1e6
            gaps = np.diff(ts); shot_idx = np.concatenate(([0], np.flatnonzero(gaps > a.gap_us) + 1)); shots = ts[shot_idx]
            pps = np.diff(np.concatenate((shot_idx, [ts.size])))
            iv_all = np.diff(shots); cuts = np.flatnonzero(iv_all > a.run_gap_ms * 1e3)      # run boundaries
            bounds = np.concatenate(([0], cuts + 1, [shots.size])); n_runs = bounds.size - 1
            inter = [round(float(iv_all[c]) / 1e3, 1) for c in cuts]
            for r in range(n_runs):
                s = shots[bounds[r]:bounds[r + 1]]; p = pps[bounds[r]:bounds[r + 1]]
                if s.size < 3: w.writerow([meta['tag'], meta['k'], r, n_runs, inter, s.size] + [''] * 8); continue
                iv = np.diff(s); dev = (iv - a.period_us) * 1e3
                # intra-shot gaps of this run: pulse gaps <= gap_us between the run's first and last pulse
                i0, i1 = shot_idx[bounds[r]], (shot_idx[bounds[r + 1]] if bounds[r + 1] < shot_idx.size else ts.size)
                g = np.diff(ts[i0:i1]); intra = g[g <= a.gap_us]
                row = [meta['tag'], meta['k'], r, n_runs, inter, int(s.size), a.period_us, round(float(iv.mean()), 4), round(float(dev.std()), 1), round(float(dev.min()), 1), round(float(dev.max()), 1), int((np.abs(dev) > 1000).sum()), round(float(intra.max()), 3) if intra.size else '', int(np.median(p))]
                w.writerow(row); print(row, flush=True)
