#!/usr/bin/env python
"""Refill (no-stall) threshold sweep -- how long must a unit execute so that the next unit's command image is ready at the boundary?

Units: K identical single-shot circuits [delay D us, one read (1.5 us span)] -> T_unit ~= D + 1.5 us (+ the DSP restart).
Modes: full  = every core reads (ch_mask 0: all NUM_CH command slots fetched, NUM_CH x 32 KiB);
       compact = one core reads (CE auto mask: 1 slot + (NUM_CH-1) x 8-beat idle).
Prefill: all (PS uploads every image before GLOBAL_START -> only the PL fetch is in the loop) or 0 (PS feeds after start).
Per batch the client returns the hardware's stall witness: cnr (sticky, any boundary waited > 8 dsp cycles), cnr_wait_cycles (wait at
the last boundary, 500 MHz cycles), seamless. Coarse grid, then bisection to 1 us between the last stalling and first clean D.
usage: GW_BUILD=<build dir> RPC_HOST=<board or local forward> RPC_PORT=9095 python refill_threshold_sweep.py <image_tag> <out_dir> [--repeats 3] [--k 8]
"""
import os, sys, csv, json, time, argparse
ap = argparse.ArgumentParser(); ap.add_argument('image'); ap.add_argument('out'); ap.add_argument('--repeats', type=int, default=3)
ap.add_argument('--k', type=int, default=8); ap.add_argument('--modes', default='full,compact'); ap.add_argument('--prefills', default='all,0')
ap.add_argument('--grid', default='0,5,10,15,20,25,30,35,40,45,50,55,60,70,80,100'); ap.add_argument('--core', type=int, default=0)
a = ap.parse_args()
import integ_test_lib as L
from integ_test_lib import build_qchip, _compile, ALL, NUM_CH, runner
qchip = build_qchip()
def compact_prog(D, core):
    q = f'qubit_{core}'
    body = ([{'name': 'delay', 't': D * 1e-6, 'scope': [q]}] if D > 0 else []) + [{'name': 'read', 'qubit': [q]}]
    exe = _compile(body, qchip)
    for ch, rc in exe.result_channels.items():
        if ch.endswith('.rdlo'): rc.reads_per_shot = 1
    return exe
def full_prog(D):
    body = ([{'name': 'delay', 't': D * 1e-6, 'scope': ALL}] if D > 0 else []) + [{'name': 'read', 'qubit': [q]} for q in ALL]
    exe = _compile(body, qchip)
    for ch, rc in exe.result_channels.items():
        if ch.endswith('.rdlo'): rc.reads_per_shot = 1
    return exe
os.makedirs(a.out, exist_ok=True)
csv_path = os.path.join(a.out, f'refill_sweep_{a.image}.csv'); new = not os.path.exists(csv_path)
f = open(csv_path, 'a', newline=''); w = csv.writer(f)
if new: w.writerow(['t', 'image', 'num_ch', 'mode', 'prefill', 'K', 'D_us', 'rep', 'status', 'seamless', 'cnr', 'cnr_wait_cycles', 'cnr_wait_us', 'elapsed_s', 'error'])
r = runner(); cache = {}
def run_point(mode, prefill, D, rep):
    key = (mode, D)
    if key not in cache: cache[key] = full_prog(D) if mode == 'full' else compact_prog(D, a.core)
    exe = cache[key]; kw = {'ch_mask': 0} if mode == 'full' else {}
    if prefill == 'all': kw['prefill'] = a.k          # N units before GLOBAL_START; N = K = all
    t0 = time.time(); row = dict(status='ok', seamless=None, cnr=None, cnr_wait_cycles=None, cnr_wait_us=None, error='')
    try:
        res = r.run_circuit_batch([exe] * a.k, 1, **kw)
        info = r.last_batch_info or {}
        row.update(seamless=info.get('seamless'), cnr=info.get('cnr'), cnr_wait_cycles=info.get('cnr_wait_cycles'), cnr_wait_us=info.get('cnr_wait_us'))
        assert len(res) == a.k, f'{len(res)} results for K={a.k}'
    except Exception as e:
        row.update(status='error', error=repr(e)[:160])
    row['elapsed_s'] = round(time.time() - t0, 3)
    w.writerow([round(t0, 3), a.image, NUM_CH, mode, prefill, a.k, D, rep, row['status'], row['seamless'], row['cnr'], row['cnr_wait_cycles'], row['cnr_wait_us'], row['elapsed_s'], row['error']]); f.flush()
    return row
def clean(rows): return all(x['status'] == 'ok' and str(x['cnr']) in ('0', '0.0', 'False') for x in rows)
summary = {'image': a.image, 'num_ch': NUM_CH, 'K': a.k, 'repeats': a.repeats, 'configs': {}}
grid = [float(x) for x in a.grid.split(',')]
for mode in a.modes.split(','):
    for prefill in a.prefills.split(','):
        pts = {}
        for D in grid:
            pts[D] = [run_point(mode, prefill, D, rep) for rep in range(a.repeats)]
            print(f'[{a.image} {mode} prefill={prefill}] D={D:6.1f} us: cnr={[x["cnr"] for x in pts[D]]} wait={[x["cnr_wait_cycles"] for x in pts[D]]} {"CLEAN" if clean(pts[D]) else "stall"}', flush=True)
        stalls = [D for D in grid if not clean(pts[D])]; cleans = [D for D in grid if clean(pts[D])]
        lo = max(stalls) if stalls else None; hi = min([D for D in cleans if lo is None or D > lo]) if cleans else None
        # bisection between the last stalling D and the first clean D above it, to 1 us
        while lo is not None and hi is not None and hi - lo > 1.0:
            mid = round((lo + hi) / 2, 1); pts[mid] = [run_point(mode, prefill, mid, rep) for rep in range(a.repeats)]
            print(f'[{a.image} {mode} prefill={prefill}] bisect D={mid:6.1f} us: cnr={[x["cnr"] for x in pts[mid]]} wait={[x["cnr_wait_cycles"] for x in pts[mid]]} {"CLEAN" if clean(pts[mid]) else "stall"}', flush=True)
            if clean(pts[mid]): hi = mid
            else: lo = mid
        # fit wait = a - b*D on the stalling points (expect b ~ 500 cycles/us; a = fetch time at D = 0)
        xs = [D for D in pts if not clean(pts[D]) and all(x['status'] == 'ok' and x['cnr_wait_cycles'] not in (None, '') for x in pts[D])]
        fit = None
        if len(xs) >= 2:
            ys = [sum(float(x['cnr_wait_cycles']) for x in pts[D]) / len(pts[D]) for D in xs]
            n = len(xs); mx = sum(xs) / n; my = sum(ys) / n
            b = sum((x - mx) * (y - my) for x, y in zip(xs, ys)) / max(sum((x - mx) ** 2 for x in xs), 1e-9); a0 = my - b * mx
            fit = {'slope_cycles_per_us': round(b, 1), 'intercept_cycles': round(a0, 1), 'intercept_us': round(a0 / 500, 2), 'zero_wait_D_us': round(-a0 / b, 2) if b else None, 'n_points': n}
        summary['configs'][f'{mode}/prefill={prefill}'] = {'last_stall_D_us': lo, 'first_clean_D_us': hi, 'fit_on_stalling_points': fit,
                                                            'points': {str(D): [{'cnr': x['cnr'], 'wait': x['cnr_wait_cycles'], 'status': x['status']} for x in v] for D, v in sorted(pts.items())}}
        print(f'==> {a.image} {mode} prefill={prefill}: last stall D={lo} us, first clean D={hi} us, fit={fit}', flush=True)
json.dump(summary, open(os.path.join(a.out, f'refill_summary_{a.image}.json'), 'w'), indent=1)
print('SWEEP DONE', json.dumps({k: {kk: vv for kk, vv in v.items() if kk != 'points'} for k, v in summary['configs'].items()}))
