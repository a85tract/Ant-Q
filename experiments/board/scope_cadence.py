#!/usr/bin/env python3
"""scope_cadence.py -- bench cadence metrology (AQT plan P0-D; pre-registration
~/agent_journals/antq_scope_cadence_plan_20260904.md). Tektronix MSO71254C via the ssh tunnel 127.0.0.1:14000
(one client at a time). CH1 = veneno DAC 230_0 (rdrv, readout-drive bus): one 2 us readout pulse per shot.

  capture : arm single-sequence acquisitions in a loop and save each record
            python scope_cadence.py capture --tag phys4_run1 --scale 1e-3 --n 3 --max-s 60 [--mode AUTO|CONSTANT --sr 62.5e6]
                                            [--trig-mv 3 | --auto-trigger] [--ch1-mv 5]
  analyze : readout-pulse start times -> intervals vs the programmed period
            python scope_cadence.py analyze --tag phys4_run1 --period-us 8.932 [--thr-frac 0.35]
Raw records: results/scope_cadence/raw/<tag>_<k>.npz (int8 samples, xincr, ymult, yoff, meta); summary rows appended
to results/scope_cadence/cadence_summary.csv; pulse timestamps per capture: results/scope_cadence/ts/<tag>_<k>.npy."""
import argparse, csv, json, os, socket, sys, time
import numpy as np

RES = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'results', 'scope_cadence')


class Scope:
    def __init__(self, host='127.0.0.1', port=14000):
        self.s = socket.create_connection((host, port), timeout=10)

    def w(self, c): self.s.sendall((c + '\n').encode())

    def q(self, c, t=3.0):
        self.w(c); self.s.settimeout(t); buf = b''
        try:
            while not buf.endswith(b'\n'):
                ch = self.s.recv(1 << 16)
                if not ch: break
                buf += ch
        except socket.timeout: pass
        return buf.decode(errors='replace').strip()

    def curve(self, rl, ch='CH1'):
        for c in [f'DATA:SOURCE {ch}', 'DATA:ENCDG RIBINARY', 'DATA:WIDTH 1', 'DATA:START 1', f'DATA:STOP {rl}']: self.w(c)
        xi = float(self.q('WFMOUTPRE:XINCR?')); ym = float(self.q('WFMOUTPRE:YMULT?')); yo = float(self.q('WFMOUTPRE:YOFF?'))
        for attempt in range(3):                       # the first CURVE? after SAVE occasionally returns nothing
            self.w('CURVE?'); self.s.settimeout(10); d = b''
            while True:
                try:
                    ch = self.s.recv(1 << 20)
                    if not ch: break
                    d += ch
                    if d[:1] == b'#' and len(d) > 2:   # stop as soon as the announced block is complete
                        nd = int(d[1:2]); ln = int(d[2:2 + nd])
                        if len(d) >= 2 + nd + ln + 1: break
                except socket.timeout: break
            if d[:1] == b'#': break
            print(f'  CURVE? returned {len(d)} bytes (prefix {d[:16]!r}); retry {attempt + 1}', flush=True); time.sleep(1.0)
        if d[:1] != b'#': raise RuntimeError('CURVE? gave no block data')
        nd = int(d[1:2]); ln = int(d[2:2 + nd]); raw = np.frombuffer(d[2 + nd:2 + nd + ln], dtype=np.int8)
        return raw, xi, ym, yo

    def close(self):
        for c in ['ACQUIRE:STOPAFTER RUNSTOP', 'ACQUIRE:STATE RUN']: self.w(c)
        self.s.close()


def capture(a):
    os.makedirs(os.path.join(RES, 'raw'), exist_ok=True)
    sc = Scope()
    print('scope:', sc.q('*IDN?'), flush=True)
    sc.w('ACQUIRE:STATE 0')
    sc.w(f'{a.ch}:SCALE {a.ch1_mv * 1e-3:.3E}'); sc.w(f'SELECT:{a.ch} ON')
    if a.mode == 'CONSTANT':
        sc.w('HORIZONTAL:MODE CONSTANT'); sc.w(f'HORIZONTAL:MODE:SAMPLERATE {a.sr:.3E}')
    else:
        sc.w('HORIZONTAL:MODE AUTO')
    sc.w(f'HORIZONTAL:MODE:SCALE {a.scale:.3E}'); sc.w('HORIZONTAL:POSITION 2')
    if a.auto_trigger:
        sc.w('TRIGGER:A:MODE AUTO')
    else:
        sc.w('TRIGGER:A:MODE NORMAL'); sc.w('TRIGGER:A:TYPE EDGE'); sc.w(f'TRIGGER:A:EDGE:SOURCE {a.ch}')
        sc.w('TRIGGER:A:EDGE:SLOPE RISE'); sc.w(f'TRIGGER:A:LEVEL {a.trig_mv * 1e-3:.3E}')
    time.sleep(0.5)
    rl_s = ''
    for _ in range(10):                                   # right after another client disconnected the scope may answer '' for a few seconds
        rl_s = sc.q('HORIZONTAL:MODE:RECORDLENGTH?')
        if rl_s: break
        time.sleep(1.0)
    if not rl_s: sys.exit('scope not answering (previous session still open?)')
    rl = int(float(rl_s)); sr = sc.q('HORIZONTAL:MODE:SAMPLERATE?')
    print(f'horizontal: mode {sc.q("HORIZONTAL:MODE?")} scale {sc.q("HORIZONTAL:MODE:SCALE?")} s/div RL {rl} SR {sr}', flush=True)
    t_end = time.time() + a.max_s; k = 0
    while k < a.n and time.time() < t_end:
        sc.w('ACQUIRE:STOPAFTER SEQUENCE'); sc.w('ACQUIRE:STATE 1'); time.sleep(0.6)
        for _ in range(3):
            if sc.q('TRIGGER:STATE?') == 'READY': break
            sc.w('ACQUIRE:STATE 0'); sc.w('ACQUIRE:STATE 1'); time.sleep(0.6)
        t_arm = time.time(); print(f'[{k}] armed at {time.strftime("%H:%M:%S")}', flush=True)
        st = ''; t_last = time.time()
        while time.time() < t_end:
            st = sc.q('TRIGGER:STATE?')
            if st == 'SAVE': break
            if time.time() - t_last > 5: print(f'[{k}] waiting, trigger state {st!r}', flush=True); t_last = time.time()
            time.sleep(0.2)
        if st != 'SAVE':
            print(f'[{k}] no trigger before max-s ({st})', flush=True); break
        t_trig = time.time(); time.sleep(0.5)
        try:
            raw, xi, ym, yo = sc.curve(rl, a.ch)
        except Exception as e:
            print(f'[{k}] capture failed: {e}', flush=True); continue
        meta = dict(tag=a.tag, k=k, ch=a.ch, t_arm=t_arm, t_trig=t_trig, rl=rl, sr=sr, scale=a.scale, mode=a.mode, xincr=xi, ymult=ym, yoff=yo,
                    ch1_mv=a.ch1_mv, trig_mv=a.trig_mv, auto_trigger=a.auto_trigger, n_pts=int(raw.size))
        v = (raw.astype(np.float32) - yo) * ym
        if not a.auto_trigger and np.abs(v).max() < 0.8 * a.trig_mv * 1e-3:
            # the first arm after a horizontal reconfiguration can report SAVE immediately with a stale/noise record
            print(f'[{k}] spurious record (|v| max {np.abs(v).max()*1e3:.1f} mV < trigger {a.trig_mv} mV) -> discarded, re-arming', flush=True)
            continue
        np.savez_compressed(os.path.join(RES, 'raw', f'{a.tag}_{k}.npz'), raw=raw, **{m: json.dumps(meta) for m in ['meta']})
        print(f'[{k}] {raw.size} pts, dt {xi*1e9:.1f} ns, window {raw.size*xi*1e3:.2f} ms, |v| max {np.abs(v).max()*1e3:.1f} mV, transfer {time.time()-t_trig:.1f} s', flush=True)
        k += 1
    sc.close(); print(f'captured {k} records', flush=True)


def pulse_starts(v, xi, thr_frac, min_samples=1, min_thr=0.0):
    """Start sample of every pulse burst: |v| above thr = thr_frac x max|v| (peak-detect records keep the burst
    extremes even when a 24 ns pulse falls inside one 80 ns bin); consecutive above-threshold samples form one pulse."""
    a = np.abs(v); thr = max(thr_frac * a.max(), min_thr); on = a > thr    # min_thr keeps noise-only records from yielding pulses
    d = np.diff(np.concatenate(([0], on.astype(np.int8), [0])))
    starts = np.flatnonzero(d == 1); ends = np.flatnonzero(d == -1)         # end = first sample below threshold again
    if min_samples > 1:
        keep = (ends - starts) >= min_samples; starts, ends = starts[keep], ends[keep]
    return starts, ends, thr


def analyze(a):
    """Shot segmentation by gap: a pulse preceded by a gap > gap_us starts a new shot. Shot period = start-to-start of
    consecutive shots, compared with the programmed period; any intra-shot pulse gap longer than the programmed maximum
    (--max-intra-gap-us, default = gap_us) is a stall candidate and is reported."""
    os.makedirs(os.path.join(RES, 'ts'), exist_ok=True)
    files = sorted(f for f in os.listdir(os.path.join(RES, 'raw')) if f.startswith(a.tag + '_') and f.endswith('.npz'))
    if not files: sys.exit(f'no captures for tag {a.tag}')
    out = os.path.join(RES, 'cadence_summary.csv'); new = not os.path.exists(out)
    with open(out, 'a', newline='') as f:
        w = csv.writer(f)
        if new:
            w.writerow(['tag', 'k', 't_trig', 'mode', 'window_ms', 'dt_ns', 'n_pulses', 'n_shots', 'pulses_per_shot', 'expected_shots_in_span', 'missing_shots',
                        'period_prog_us', 'mean_period_us', 'sd_ns', 'min_dev_ns', 'max_dev_ns', 'n_outside_1us', 'max_intra_gap_us', 'thr_mV', 'vmax_mV'])
        for fn in files:
            z = np.load(os.path.join(RES, 'raw', fn)); meta = json.loads(str(z['meta'])); raw = z['raw']
            xi, ym, yo = meta['xincr'], meta['ymult'], meta['yoff']; v = (raw.astype(np.float32) - yo) * ym
            starts, ends, thr = pulse_starts(v, xi, a.thr_frac, min_thr=a.min_thr_mv * 1e-3); ts = starts * xi * 1e6; te = ends * xi * 1e6   # us
            np.save(os.path.join(RES, 'ts', fn.replace('.npz', '.npy')), ts)
            win_ms = raw.size * xi * 1e3
            if ts.size < 4:
                row = [meta['tag'], meta['k'], round(meta['t_trig'], 1), meta['mode'], round(win_ms, 3), round(xi * 1e9, 2), ts.size] + [''] * 12 + [round(thr * 1e3, 2), round(np.abs(v).max() * 1e3, 1)]
                w.writerow(row); print(row, flush=True); continue
            gaps = np.diff(ts); shot_idx = np.concatenate(([0], np.flatnonzero(gaps > a.gap_us) + 1))
            if a.merge_short_us > 0:                  # a pulse cluster shorter than this (e.g. the two conditional X90 of an
                keep = []                             # active-reset branch) is not a shot: fold it into the following shot
                for i, si in enumerate(shot_idx):
                    nxt = shot_idx[i + 1] if i + 1 < shot_idx.size else ts.size
                    dur = te[nxt - 1] - ts[si]        # first pulse start to last pulse end of the cluster
                    if dur < a.merge_short_us and i + 1 < shot_idx.size: continue
                    keep.append(si)
                shot_idx = np.array(keep)
            shots = ts[shot_idx]; pps = np.diff(np.concatenate((shot_idx, [ts.size])))
            if shots.size < 3:
                row = [meta['tag'], meta['k'], round(meta['t_trig'], 1), meta['mode'], round(win_ms, 3), round(xi * 1e9, 2), ts.size, shots.size] + [''] * 11 + [round(thr * 1e3, 2), round(np.abs(v).max() * 1e3, 1)]
                w.writerow(row); print(row, '(fewer than 3 shots)', flush=True); continue
            # drop the first/last shot if the record cut into them (incomplete pulse count)
            full = (pps == np.median(pps)); intra = gaps[gaps <= a.gap_us]
            iv = np.diff(shots); dev = (iv - a.period_us) * 1e3
            span_us = shots[-1] - shots[0]; expected = int(round(span_us / a.period_us)) + 1
            row = [meta['tag'], meta['k'], round(meta['t_trig'], 1), meta['mode'], round(win_ms, 3), round(xi * 1e9, 2), ts.size, shots.size,
                   f"{int(np.median(pps))} (min {pps[1:-1].min() if pps.size > 2 else pps.min()}, max {pps[1:-1].max() if pps.size > 2 else pps.max()})", expected, expected - shots.size,
                   a.period_us, round(iv.mean(), 4), round(dev.std(), 1), round(dev.min(), 1), round(dev.max(), 1), int((np.abs(dev) > 1000).sum()),
                   round(intra.max(), 3) if intra.size else '', round(thr * 1e3, 2), round(np.abs(v).max() * 1e3, 1)]
            w.writerow(row); print(row, flush=True)
            if a.verbose:
                bad = np.flatnonzero(np.abs(dev) > 1000)
                print(f'   intervals outside +-1 us: {[(int(b), round(float(iv[b]), 3)) for b in bad[:10]]}; intra-shot gap quantiles (us): {np.percentile(intra, [50, 99, 100]).round(3).tolist() if intra.size else "-"}')


if __name__ == '__main__':
    p = argparse.ArgumentParser(); sub = p.add_subparsers(dest='cmd', required=True)
    c = sub.add_parser('capture'); c.add_argument('--tag', required=True); c.add_argument('--scale', type=float, required=True, help='s/div')
    c.add_argument('--n', type=int, default=1); c.add_argument('--max-s', type=float, default=120); c.add_argument('--mode', default='AUTO', choices=['AUTO', 'CONSTANT'])
    c.add_argument('--sr', type=float, default=62.5e6); c.add_argument('--trig-mv', type=float, default=3.0); c.add_argument('--auto-trigger', action='store_true')
    c.add_argument('--ch1-mv', type=float, default=5.0, help='volts/div of the captured channel, in mV')
    c.add_argument('--ch', default='CH1', choices=['CH1', 'CH2'], help='captured/trigger channel (CH1 = rdrv bus, CH2 = qubit_1 drive)')
    an = sub.add_parser('analyze'); an.add_argument('--tag', required=True); an.add_argument('--period-us', type=float, required=True); an.add_argument('--thr-frac', type=float, default=0.4); an.add_argument('--gap-us', type=float, default=3.0, help='a pulse gap longer than this starts a new shot'); an.add_argument('--verbose', action='store_true'); an.add_argument('--merge-short-us', type=float, default=0.0, help='fold pulse clusters shorter than this into the next shot (conditional-reset pulses)'); an.add_argument('--min-thr-mv', type=float, default=8.0, help='absolute floor of the pulse threshold (noise-only records give no pulses)')
    a = p.parse_args(); capture(a) if a.cmd == 'capture' else analyze(a)
