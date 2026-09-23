"""Offline analysis of handover_scope records: per idx, envelope-detected pulses and the gap between the pulse group before the
boundary and marker B. usage: python handover_scope_analyze.py <tag> [results_dir]
  700 S2 : A - [400 ns compiled] - B, B in segment 1      -> gap = 400 + 10 + handover
  701 U2 : A - 400 ns - B unbroken                        -> gap = 400 (reference; also calibrates the detector)
  702 S2R: [A + readout pulse] | [B]                      -> gap = handover + 10 ns (compiled gap between the readout pulse end and B is 0)
  703 U2R: A + readout + B contiguous (one blob)          -> no gap (sanity: one pulse of ~700 ns)"""
import os, sys, os, glob, json
import numpy as np
tag = sys.argv[1]; res = sys.argv[2] if len(sys.argv) > 2 else os.environ['ANTQ_RESULTS']
D = os.path.join(res, 'handover_scope')
def pulses(v, dt, thr):
    w = max(1, int(8e-9 / dt)); a_ = np.abs(v)
    env = np.maximum.reduce([np.pad(a_, (k, 0))[:len(a_)] for k in range(w)])
    on = env > thr
    if not on.any(): return []
    edges = np.flatnonzero(np.diff(on.astype(np.int8))); starts = list(edges[on[edges + 1]] + 1); ends = list(edges[~on[edges + 1]] + 1)
    if on[0]: starts = [0] + starts
    if on[-1]: ends = ends + [len(v)]
    out = [(s_ * dt * 1e9, (e_ - w) * dt * 1e9) for s_, e_ in zip(starts, ends) if (e_ - s_) * dt >= 40e-9]
    merged = []
    for s_, e_ in out:
        if merged and s_ - merged[-1][1] < 30: merged[-1] = (merged[-1][0], e_)
        else: merged.append((s_, e_))
    return merged
summary = {}
for idx in (701, 700, 703, 702):
    fs = sorted(glob.glob(f'{D}/{tag}_{idx}_*.npz'), key=lambda f: int(f.rsplit('_', 1)[1][:-4]))
    if not fs: continue
    gaps, widths, npulses = [], [], []
    for f in fs:
        z = np.load(f); v = z['v']; dt = float(z['dt']); ps = pulses(v, dt, 0.35 * np.abs(v).max()); npulses.append(len(ps))
        if len(ps) >= 2:
            gaps.append(ps[-1][0] - ps[0][1]); widths.append([round(b - a, 1) for a, b in ps])
    g = np.array(gaps)
    summary[idx] = dict(records=len(fs), pulses_per_record=npulses, gaps_ns=g.tolist(), widths_ns=widths[:3])
    print(f"idx {idx}: {len(fs)} records; pulses per record {sorted(set(npulses))}; gaps (ns): " + (f"n={len(g)} median {np.median(g):.1f} mean {g.mean():.1f} sd {g.std(ddof=1) if len(g)>1 else 0:.1f} min {g.min():.1f} max {g.max():.1f}; widths {widths[0]}" if len(g) else "none"))
def med(i): g = summary.get(i, {}).get('gaps_ns', []); return float(np.median(g)) if g else float('nan')
if 700 in summary and 701 in summary: print(f"S2 - U2 = {med(700) - med(701):.1f} ns -> handover = {med(700) - med(701) - 10:.1f} ns (10 ns = segment first-pulse offset)")
if 702 in summary and summary[702]['gaps_ns']: print(f"S2R gap (readout pulse end -> B) = {med(702):.1f} ns -> handover = {med(702) - 10:.1f} ns")
json.dump(summary, open(f'{D}/{tag}_analysis.json', 'w'), indent=1)
