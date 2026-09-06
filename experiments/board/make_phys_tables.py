"""Plan A4 / B5 analysis.
table2_phys.csv: per (experiment, config): n, raw elapsed, mean, sd (NA if n=1), N, interval, P (compiled), calibration fit
  (P_meas +/- SE, F +/- SE, s_resid, SE_pred3), E = N x P_meas + F, tolerance = 1 ms + 100 ppm x E, consistent (3-run mean rule),
  P_meas - P (loop overhead) with its 95 % CI, cnr, status/capacity; 5/6 rows: n_units, segments, cnr.
table_stop.csv: per circuit: 5 pairs -> s_i = 1 - T_stop/T_full, mean + t CI df 4; overshoot mean/range; stop-path latencies;
  requested vs recorded delay; result classes."""
import csv, os, math, statistics as st
from collections import defaultdict
import numpy as np
HERE = os.path.dirname(os.path.abspath(__file__)); RES = os.environ.get('ANTQ_RESULTS', os.path.join(HERE, '..', '..', 'results'))   # <repo>/results
T = {4: 2.776, 7: 2.365, 2: 4.303}
def rows(f):
    p = os.path.join(RES, f); return list(csv.DictReader(open(p))) if os.path.exists(p) else []
# ---------------- part A ----------------
phys = rows('raw_runs_phys.csv')
cells = defaultdict(list); cal = defaultdict(list); meta = {}
for r in phys:
    if int(r['repeat']) < 0: continue
    key = (r['workload_id'].split('_n')[0], r['mode'])
    if r['workload'] == 'phys_cal':
        if r['status'] == 'ok': cal[key].append((float(r['calib_n']), float(r['elapsed_ms'])))
        continue
    meta[key] = r
    if r['status'] == 'ok': cells[key].append(float(r['elapsed_ms']))
    elif r['status'] == 'capacity': cells.setdefault(key, [])
out = []
for key in sorted(set(list(cells) + list(meta))):
    r = meta.get(key, {}); v = cells.get(key, [])
    d = dict(experiment=key[0], config=key[1], status=r.get('status', ''), n=len(v), elapsed_ms=' '.join(f'{x:.4f}' for x in v),
             mean_ms=round(st.mean(v), 4) if v else '', sd_ms=round(st.stdev(v), 4) if len(v) > 1 else 'NA',
             N=r.get('loop_n', ''), interval_us=r.get('interval_us', ''), P_compiled_us=r.get('period_us', ''), period_src=r.get('period_src', ''),
             cnr=r.get('cnr', ''), cnr_wait_cycles=r.get('cnr_wait_cycles', ''), n_units=r.get('n_units', ''), n_segments=r.get('n_segments', ''),
             seg_dur_us=r.get('seg_dur_us', ''), exclusion_reason=r.get('exclusion_reason', ''))
    c = cal.get(key, [])
    if len(c) >= 6 and v and r.get('loop_n'):
        N = float(r['loop_n']); P = float(r['period_us']) / 1000.0            # ms per iteration
        x = np.array([a for a, _ in c]); y = np.array([b for _, b in c])
        X = np.column_stack([np.ones_like(x), x]); beta, res, *_ = np.linalg.lstsq(X, y, rcond=None)
        resid = y - X @ beta; dof = len(x) - 2; s_res = math.sqrt((resid ** 2).sum() / dof)
        cov = s_res ** 2 * np.linalg.inv(X.T @ X); se_F, se_P = math.sqrt(cov[0, 0]), math.sqrt(cov[1, 1])
        xn = np.array([1.0, N]); se_fit = math.sqrt(xn @ np.linalg.inv(X.T @ X) @ xn) * s_res
        se_pred3 = math.sqrt(se_fit ** 2 + s_res ** 2 / 3)
        E = beta[1] * N + beta[0]; tol = 1.0 + 100e-6 * E; t = T.get(dof, 2.365)
        mean = st.mean(v); consistent = abs(mean - E) + t * se_pred3 <= tol
        d.update(calib_points=len(c), P_meas_us=round(beta[1] * 1000, 6), P_meas_se_us=round(se_P * 1000, 6), F_ms=round(beta[0], 4), F_se_ms=round(se_F, 4),
                 s_resid_ms=round(s_res, 4), loop_overhead_ns=round((beta[1] - P) * 1e6, 3), loop_overhead_ci95_ns=f'{(beta[1] - P - t * se_P) * 1e6:.3f}..{(beta[1] - P + t * se_P) * 1e6:.3f}',
                 E_ms=round(E, 4), mean_minus_E_ms=round(mean - E, 4), se_pred3_ms=round(se_pred3, 4), tolerance_ms=round(tol, 4), consistent=consistent)
    out.append(d)
if out:
    fn = sorted({k for d in out for k in d}, key=lambda k: (k not in ('experiment', 'config', 'status', 'n'), k))
    w = csv.DictWriter(open(os.path.join(RES, 'table2_phys.csv'), 'w', newline=''), fieldnames=fn); w.writeheader(); w.writerows(out)
    for d in out: print('A', d['experiment'], d['config'], d['status'], 'n', d['n'], 'mean', d['mean_ms'], 'consistent', d.get('consistent', ''), 'cnr', d['cnr'])
# ---------------- part B ----------------
stop = [r for r in rows('raw_runs_stop.csv') if r['tag'] in ('c3_14q_stop1', 'c3_14q_stop_poll0d') and r['status'] == 'ok']
pairs = defaultdict(dict)
for r in stop:
    if r['pair_id']: pairs[(r['tag'], r['pair_id'])][('stop' if int(r['stop_at'] or 0) > 0 else 'full')] = r
per = defaultdict(list)
for (tag, pid), m in pairs.items():
    if 'full' in m and 'stop' in m: per[(m['full']['workload_id'], tag)].append(m)
outb = []
for (idx, tag), ms in sorted(per.items(), key=lambda kv: (int(kv[0][0]), kv[0][1])):
    s_i = [1 - float(m['stop']['elapsed_ms']) / float(m['full']['elapsed_ms']) for m in ms]
    mean = st.mean(s_i); h = (T.get(len(s_i) - 1, 2.776) * st.stdev(s_i) / math.sqrt(len(s_i))) if len(s_i) > 1 else float('nan')
    sr = [m['stop'] for m in ms]
    ov = [int(float(r['overshoot'])) for r in sr if r['overshoot'] != '']
    outb.append(dict(idx=idx, tag=tag, n_pairs=len(ms), time_saved_mean=round(mean, 4), time_saved_ci95=f'{mean - h:.4f}..{mean + h:.4f}',
                     T_full_ms=round(st.mean(float(m['full']['elapsed_ms']) for m in ms), 3), T_stop_ms=round(st.mean(float(m['stop']['elapsed_ms']) for m in ms), 3),
                     stop_at=sr[0]['stop_at'], results=' '.join(r['stop_result'] for r in sr), actual_shots=' '.join(r['actual_shots'] for r in sr),
                     overshoot_mean=round(st.mean(ov), 1) if ov else '', overshoot_range=f'{min(ov)}..{max(ov)}' if ov else '',
                     cp_step=sr[0]['cp_step'], cp_ns_req=sr[0]['cp_ns_req'], delay_actual_ns=' '.join(r['delay_actual_ns'] for r in sr),
                     fired_k=sr[0]['fired_k'], hw_latency_us=' '.join(f"{float(r['latency_us']):.2f}" for r in sr if r['latency_us']),
                     ps_write_to_record_us=' '.join(f"{(float(r['t_event_ps_ns']) - float(r['t_write_ns'])) / 1e3:.1f}" for r in sr if r['t_write_ns'] not in ('', '0')),
                     strm_poll_us=sr[0]['strm_poll_us']))
if outb:
    w = csv.DictWriter(open(os.path.join(RES, 'table_stop.csv'), 'w', newline=''), fieldnames=list(outb[0].keys())); w.writeheader(); w.writerows(outb)
    for d in outb: print('B', d)
print('phys cells', len(out), 'stop circuits', len(outb))
