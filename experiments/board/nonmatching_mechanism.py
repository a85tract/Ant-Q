"""The plan §5 'cheap test' for NON-MATCHING cells: predict the extra time from the extra data volume.
std: extra accbuf MMIO readback words x load rate (rate calibrated on std/1 Bell, stated in the output).
c1: extra bramctrl command/table MMIO store words x store rate (calibrated on c1/24 Grover).
Writes results/nonmatching_mechanism.csv: observed vs predicted extra ms per non-matching cell."""
import csv, os, statistics as st
from collections import defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
RES = os.environ.get('ANTQ_RESULTS', os.path.join(HERE, '..', '..', 'results'))   # <repo>/results
SUR = {'std': 'std_14q_v2', 'c1': 'c1_14q_v7'}
REAL = {'std': 'std_14q_real1', 'c1': 'c1_14q_real1'}

raw = defaultdict(list)
for r in csv.DictReader(open(os.path.join(RES, 'raw_runs.csv'))):
    if r['status'] == 'ok' and int(r['repeat']) >= 0:
        raw[(r['mode'], r['workload_id'], r['tag'])].append(r)

def volumes(mode, wid, tag):
    rs = sorted(raw[(mode, wid, tag)], key=lambda r: r['wall_time'])[-5:]
    return (st.mean(float(r['elapsed_ms']) for r in rs),
            int(rs[0]['readout_bytes']) // 4,            # accbuf readback words (2 u32 per 8-byte IQ entry)
            int(rs[0]['cmd_bytes_transferred']) // 4)    # bramctrl words actually stored (commands+tables)

cells = [r for r in csv.DictReader(open(os.path.join(RES, 'real_vs_surrogate.csv')))
         if r['verdict'] == 'NON-MATCHING']
out, rates = [], {}
for mode, cal_wid in (('std', '1'), ('c1', '24')):
    es, ws_r, cw_s = volumes(mode, cal_wid, SUR[mode])
    er, ws_real, cw_r = volumes(mode, cal_wid, REAL[mode])
    extra = (ws_real - ws_r) if mode == 'std' else (cw_r - cw_s)
    rates[mode] = (er - es) / extra if extra else 0.0    # ms per word
    print(f'{mode} rate calibrated on {cal_wid}: {rates[mode] * 1000:.3f} us/word ({extra} extra words)')
for c in cells:
    mode, wid = c['mode'], c['workload_id']
    es, wsur, csur = volumes(mode, wid, SUR[mode])
    er, wreal, creal = volumes(mode, wid, REAL[mode])
    extra = (wreal - wsur) if mode == 'std' else (creal - csur)
    pred = extra * rates[mode]
    obs = float(c['diff_ms'])
    out.append(dict(mode=mode, workload_id=wid, observed_extra_ms=f'{obs:.4f}', extra_words=extra,
                    predicted_extra_ms=f'{pred:.4f}',
                    mechanism=('2x accbuf MMIO readback (reset+final read per shot)' if mode == 'std'
                               else 'larger command/table bramctrl MMIO stores'),
                    calibration=('rate from std/1' if mode == 'std' else 'rate from c1/24'),
                    pred_over_obs=f'{pred / obs:.2f}' if obs else ''))
with open(os.path.join(RES, 'nonmatching_mechanism.csv'), 'w', newline='') as f:
    w = csv.DictWriter(f, fieldnames=list(out[0].keys()))
    w.writeheader()
    for r in out:
        w.writerow(r)
ratios = [float(r['pred_over_obs']) for r in out if r['pred_over_obs'] and (r['mode'], r['workload_id']) not in (('std', '1'), ('c1', '24'))]
print(f'wrote nonmatching_mechanism.csv: {len(out)} cells; out-of-sample pred/obs ratios: '
      f'min {min(ratios):.2f} median {sorted(ratios)[len(ratios)//2]:.2f} max {max(ratios):.2f}')
