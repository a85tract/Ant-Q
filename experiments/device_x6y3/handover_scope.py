import os
"""Direct measurement of the command-buffer handover on the bench (the bench board, oscilloscope CH1 = readout-drive DAC 230_0, shared bus):
for each marker program (aqt_programs AQT_HANDOVER_MARK=1: 700 S2 / 701 U2 / 702 S2R / 703 U2R) run the program in the background and
capture single-sequence records triggered on marker A; in each record measure gap = start(marker B) - end(marker A) at the scope's
sample resolution. Handover = gap(S) - gap(U) - 10 ns (compile offset of a program's first pulse). S2R/U2R have a readout between A and B
(the read's own pulse may or may not be visible; A.end -> B.start is used in both twins, so the difference is still the handover).
usage: (the bench board env + AQT_HANDOVER_MARK=1 + GW) python handover_scope.py --idx 701,700,703,702 --captures 12 --sr 2.5e9 --span 8e-6
Writes results/handover_scope/<tag>_<idx>_<k>.npz and a summary json; prints per-program gap statistics."""
import argparse, os, sys, time, subprocess, json
import numpy as np
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'board')); from scope_cadence import Scope
ap = argparse.ArgumentParser(); ap.add_argument('--idx', default='701,700,703,702'); ap.add_argument('--captures', type=int, default=12)
ap.add_argument('--sr', type=float, default=2.5e9); ap.add_argument('--span', type=float, default=8e-6); ap.add_argument('--trig-mv', type=float, default=3.0)
ap.add_argument('--scale', type=float, default=5e-3); ap.add_argument('--repeats', type=int, default=6); ap.add_argument('--tag', default='hand')
a = ap.parse_args()
RES = os.environ['ANTQ_RESULTS']; OUT = os.path.join(RES, 'handover_scope'); os.makedirs(OUT, exist_ok=True)
PY, RUNNER, GW = os.environ['PY'], os.environ['RUNNER'], os.environ['GW']
sc = Scope(os.environ['SCOPE_HOST'], int(os.environ.get('SCOPE_PORT', '4000')))
sc.w('ACQUIRE:STATE 0'); sc.w('SELECT:CH1 ON'); sc.w(f'CH1:SCALE {a.scale:.3E}'); sc.w('ACQUIRE:MODE SAMPLE')
sc.w('HORIZONTAL:MODE MANUAL'); sc.w(f'HORIZONTAL:MODE:SAMPLERATE {a.sr:.3E}'); time.sleep(0.3)      # MANUAL mode accepts GS/s rates
sr0 = float(sc.q('HORIZONTAL:MODE:SAMPLERATE?')); sc.w(f'HORIZONTAL:MODE:RECORDLENGTH {int(a.span * sr0)}')   # (the scope quantises the rate)
sc.w('HORIZONTAL:DELAY:MODE OFF'); sc.w('HORIZONTAL:POSITION 10')
sc.w('TRIGGER:A:MODE NORMAL'); sc.w('TRIGGER:A:TYPE EDGE'); sc.w('TRIGGER:A:EDGE:SOURCE CH1'); sc.w('TRIGGER:A:EDGE:SLOPE RISE'); sc.w(f'TRIGGER:A:LEVEL {a.trig_mv*1e-3:.3E}')
time.sleep(0.8); rl = int(float(sc.q('HORIZONTAL:MODE:RECORDLENGTH?'))); sr = float(sc.q('HORIZONTAL:MODE:SAMPLERATE?'))
print(f'scope: record {rl} points at {sr:.3E} S/s ({1e9/sr:.2f} ns/sample), span {rl/sr*1e6:.2f} us, CH1 {a.scale*1e3:.0f} mV/div, trigger {a.trig_mv} mV', flush=True)
if sr < 1e9: sys.exit('scope refused a GS/s sample rate')

def pulses(v, dt, thr):
    """envelope-based pulse detection: moving maximum of |v| over 8 ns (the markers ride on the readout IF carrier, whose zero
    crossings would otherwise chop a 200-ns pulse into ns-wide fragments), threshold, then segments >= 40 ns wide."""
    w = max(1, int(8e-9 / dt)); a_ = np.abs(v)
    env = np.maximum.reduce([np.pad(a_, (k, 0))[:len(a_)] for k in range(w)]) if w > 1 else a_
    on = env > thr
    if not on.any(): return []
    edges = np.flatnonzero(np.diff(on.astype(np.int8))); starts = list(edges[on[edges + 1]] + 1); ends = list(edges[~on[edges + 1]] + 1)
    if on[0]: starts = [0] + starts
    if on[-1]: ends = ends + [len(v)]
    out = []
    for s_, e_ in zip(starts, ends):
        if (e_ - s_) * dt >= 40e-9:
            out.append((s_ * dt * 1e9, (e_ - w) * dt * 1e9))      # end corrected for the moving-max window
    merged = []
    for s_, e_ in out:
        if merged and s_ - merged[-1][1] < 30: merged[-1] = (merged[-1][0], e_)
        else: merged.append((s_, e_))
    return merged

summary = {}
for idx in [int(x) for x in a.idx.split(',')]:
    log = os.path.join(OUT, f'{a.tag}_{idx}_runner.log')
    cmd = [PY, RUNNER, '--phys', '--mode', 'c3', '--num-ch', os.environ.get('NUM_CH', '8'), '--bits', GW, '--gw', GW, '--repeats', str(a.repeats), '--no-warmup', '--pool-tables', '--idx', str(idx), '--tag', f'{a.tag}_{idx}', '--note', os.environ.get('HS_NOTE', '')]   # NUM_CH: 8_2 -> 8, 14_2 -> 14; HS_NOTE records scope knobs (SCOPE_QUBIT_OFFSET, AQT_MARK_DEST)
    proc = subprocess.Popen(cmd, stdout=open(log, 'w'), stderr=subprocess.STDOUT, cwd=os.environ.get('ANTQ_WORKDIR', os.getcwd()))
    gaps = []; widthsA = []; nrec = 0; t0 = time.time()
    while len(gaps) < a.captures and time.time() - t0 < 240:
        sc.w('ACQUIRE:STOPAFTER SEQUENCE'); sc.w('ACQUIRE:STATE 1'); time.sleep(0.5)      # proven recipe (bench scope recipe): arm,
        for _ in range(3):                                                                  # confirm READY, then wait for SAVE
            if sc.q('TRIGGER:STATE?').strip() == 'READY': break
            sc.w('ACQUIRE:STATE 0'); sc.w('ACQUIRE:STATE 1'); time.sleep(0.5)
        t1 = time.time(); st = ''
        while time.time() - t1 < 8:
            st = sc.q('TRIGGER:STATE?').strip()
            if st == 'SAVE': break
            time.sleep(0.15)
        if st != 'SAVE':
            if proc.poll() is not None: break
            continue
        time.sleep(0.3)
        try: raw, xi, ym, yo = sc.curve(rl, 'CH1')
        except Exception as e: print('curve failed:', e); continue
        v = (raw.astype(np.float32) - yo) * ym; dt = xi; nrec += 1
        thr = max(a.trig_mv * 1e-3 * 0.6, 0.35 * np.abs(v).max())
        ps = pulses(v, dt, thr)
        np.savez_compressed(os.path.join(OUT, f'{a.tag}_{idx}_{nrec}.npz'), v=v.astype(np.float32), dt=dt, pulses=np.array(ps))
        if len(ps) >= 2:
            A, B = ps[0], ps[-1]            # first pulse = marker A (trigger), last pulse in the record = marker B
            gaps.append(B[0] - A[1]); widthsA.append(A[1] - A[0])
            print(f'  idx {idx} rec {nrec}: {len(ps)} pulses, A width {A[1]-A[0]:.1f} ns, gap A.end->B.start {B[0]-A[1]:.1f} ns', flush=True)
        else:
            print(f'  idx {idx} rec {nrec}: {len(ps)} pulses detected (thr {thr*1e3:.1f} mV, max {np.abs(v).max()*1e3:.1f} mV)', flush=True)
        if proc.poll() is not None and len(gaps) >= 3: break
    proc.wait(timeout=600)
    ok = open(log).read().count('r0: ok'); print(f'idx {idx}: runner {ok}/{a.repeats} ok; gaps (ns): n={len(gaps)} median {np.median(gaps) if gaps else float("nan"):.1f} min {min(gaps) if gaps else float("nan"):.1f} max {max(gaps) if gaps else float("nan"):.1f}', flush=True)
    summary[idx] = dict(gaps_ns=gaps, widthA_ns=widthsA, runner_ok=ok, records=nrec)
sc.w('ACQUIRE:STOPAFTER RUNSTOP'); sc.w('ACQUIRE:STATE 1'); sc.close()
def med(i): g = summary.get(i, {}).get('gaps_ns', []); return float(np.median(g)) if g else float('nan')
for s_, u_, name in ((700, 701, 'S2 - U2 (plain pulses)'), (702, 703, 'S2R - U2R (readout before the boundary)')):
    if s_ in summary and u_ in summary:
        d = med(s_) - med(u_); print(f'{name}: gap S {med(s_):.1f} ns, gap U {med(u_):.1f} ns, difference {d:.1f} ns -> handover = difference - 10 ns = {d-10:.1f} ns')
        summary[f'{name}'] = dict(gap_S=med(s_), gap_U=med(u_), difference_ns=d, handover_ns=d - 10)
json.dump(summary, open(os.path.join(OUT, f'{a.tag}_summary.json'), 'w'), indent=1); print('saved', os.path.join(OUT, f'{a.tag}_summary.json'))
