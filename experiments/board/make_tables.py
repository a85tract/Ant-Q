"""Build the summary CSVs from results/raw_runs.csv (plan D7/D12; nothing is deleted from raw_runs.csv).

  table3_single.csv : per circuit x mode: n, mean_ms, sd_ms (ddof=1), qpu_ms, delta_ms, delta_pct
  table4_batch.csv  : per batch_id x mode: n, mean_ms, sd_ms, qpu_ms, delta_ms, delta_pct
                      + aggregate rows rand10/rand20/rand30: mean over the 10 batch means, sd ACROSS batches
Inclusion: status == ok and not superseded; exactly one five-run set per (mode, workload) (the latest tag
when several complete sets exist — recorded in the `set_tag` column).
"""
import csv, os, statistics as st
from collections import defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
RES = os.environ.get('ANTQ_RESULTS', os.path.join(HERE, '..', '..', 'results'))   # <repo>/results
MODES = ['std', 'c1', 'c3']
MODE_LABEL = {'std': 'QubiC downlink + uplink (C server)', 'c1': 'QubiC downlink + Ant-Q uplink (C1)',
              'c3': 'Ant-Q downlink + uplink (C3)'}


def load_raw():
    with open(os.path.join(RES, 'raw_runs.csv')) as f:
        return list(csv.DictReader(f))


def pick_sets(rows, repeats=5):
    """{(mode, workload, workload_id): (tag, [elapsed_ms...], provisional)}: the latest complete set."""
    by = defaultdict(lambda: defaultdict(list))
    for r in rows:
        if r['status'] != 'ok' or int(r['repeat']) < 0:
            continue
        by[(r['mode'], r['workload'], r['workload_id'])][r['tag']].append(r)
    out = {}
    for key, tags in by.items():
        complete = [(t, rs) for t, rs in tags.items() if len({int(r['repeat']) for r in rs}) >= repeats]
        if not complete:
            continue
        t, rs = sorted(complete, key=lambda x: max(r['wall_time'] for r in x[1]))[-1]
        rs = sorted(rs, key=lambda r: r['wall_time'])[-repeats:]
        prov = any(r['wns_ns'] and float(r['wns_ns']) < 0 for r in rs)
        out[key] = (t, [float(r['elapsed_ms']) for r in rs], float(rs[0]['qpu_ms']), rs[0], prov)
    return out


def load_realized():
    p = os.environ.get('REALIZED_CSV', os.path.join(RES, 'per_shot_realized.csv'))   # real campaign: per_shot_realized_real.csv
    if not os.path.exists(p):
        return {}
    with open(p) as f:
        return {r['idx']: float(r['per_shot_c1_slope_us']) for r in csv.DictReader(f)}   # realized shot length measured on the C1 bitfile's standard DSP loop (not the C3 slope)


def main():
    rows = load_raw()
    sets = pick_sets(rows)
    realized = load_realized()
    names = {}
    with open(os.path.join(RES, 'shots_verification.csv')) as f:
        for r in csv.DictReader(f):
            names[r['idx']] = r
    # ---- table 3 ----
    with open(os.path.join(RES, 'table3_single.csv'), 'w', newline='') as f:
        w = csv.writer(f)
        w.writerow(['idx', 'name', 'n_qubits', 'shots', 'per_shot_us', 'qpu_ms', 'per_shot_realized_us', 'workload_realized_ms'] +
                   [f'{m}_{c}' for m in MODES for c in ('n', 'mean_ms', 'sd_ms', 'delta_ms', 'delta_pct', 'delta_real_ms', 'delta_real_pct', 'provisional', 'set_tag')])
        for idx in sorted(names, key=int):
            row = [idx, names[idx]['name'], names[idx]['n_qubits'], names[idx]['rerun_shots'], names[idx]['per_shot_us']]
            shots = int(names[idx]['rerun_shots'])
            qpu = shots * float(names[idx]['per_shot_us']) / 1000
            real = realized.get(idx)
            wr = shots * real / 1000 if real else None
            row += [f'{qpu:.4f}', f'{real:.4f}' if real else '', f'{wr:.4f}' if wr else '']
            for m in MODES:
                s = sets.get((m, 'single', idx))
                if not s:
                    row += [''] * 9; continue
                tag, xs, q, r0, prov = s
                mean = st.mean(xs); sd = st.stdev(xs) if len(xs) > 1 else 0.0
                row += [len(xs), f'{mean:.4f}', f'{sd:.4f}', f'{mean - qpu:.4f}', f'{100 * (mean - qpu) / qpu:.2f}',
                        f'{mean - wr:.4f}' if wr else '', f'{100 * (mean - wr) / wr:.2f}' if wr else '', 'yes' if prov else 'no', tag]
            w.writerow(row)
    # ---- table 4 ----
    with open(os.path.join(RES, 'table4_batch.csv'), 'w', newline='') as f:
        w = csv.writer(f)
        w.writerow(['batch_id', 'n_circuits', 'qpu_ms', 'workload_realized_ms'] +
                   [f'{m}_{c}' for m in MODES for c in ('n', 'mean_ms', 'sd_ms', 'delta_ms', 'delta_pct', 'delta_real_ms', 'delta_real_pct', 'provisional', 'set_tag')])
        bids = sorted({k[2] for k in sets if k[1] == 'batch'})
        manifest = defaultdict(list)
        with open(os.path.join(RES, 'batch_manifest.csv')) as f:
            for r in csv.DictReader(f):
                manifest[r['batch_id']].append(r['circuit_idx'])
        agg = defaultdict(lambda: defaultdict(list))     # size -> mode -> [batch means]
        for bid in bids:
            r0 = next(sets[k][3] for k in sets if k[1] == 'batch' and k[2] == bid)
            qpu = float(r0['qpu_ms'])
            wr = sum(int(names[i]['rerun_shots']) * realized[i] for i in manifest[bid]) / 1000 if realized and all(i in realized for i in manifest[bid]) else None
            row = [bid, r0['n_circuits'], f'{qpu:.4f}', f'{wr:.4f}' if wr else '']
            for m in MODES:
                s = sets.get((m, 'batch', bid))
                if not s:
                    row += [''] * 9; continue
                tag, xs, q, _, prov = s
                mean = st.mean(xs); sd = st.stdev(xs) if len(xs) > 1 else 0.0
                row += [len(xs), f'{mean:.4f}', f'{sd:.4f}', f'{mean - qpu:.4f}', f'{100 * (mean - qpu) / qpu:.2f}',
                        f'{mean - wr:.4f}' if wr else '', f'{100 * (mean - wr) / wr:.2f}' if wr else '', 'yes' if prov else 'no', tag]
                if bid.startswith('rand'):
                    agg[bid.split('_')[0]][m].append((mean, qpu, wr))
            w.writerow(row)
        for size in sorted(agg):
            row = [f'{size}_aggregate(mean over batches; sd across batches)', '', '', '']
            for m in MODES:
                xs = agg[size].get(m, [])
                if not xs:
                    row += [''] * 9; continue
                means = [x[0] for x in xs]; qpus = [x[1] for x in xs]; wrs = [x[2] for x in xs if x[2]]
                mq = st.mean(qpus); mm = st.mean(means); mw = st.mean(wrs) if len(wrs) == len(xs) else None
                row += [len(xs), f'{mm:.4f}', f'{st.stdev(means) if len(means) > 1 else 0:.4f}', f'{mm - mq:.4f}', f'{100 * (mm - mq) / mq:.2f}',
                        f'{mm - mw:.4f}' if mw else '', f'{100 * (mm - mw) / mw:.2f}' if mw else '', '', '']
            w.writerow(row)
        # throughput gain of C3 over the C-server baseline on the random-30 aggregate
        if agg.get('rand30', {}).get('std') and agg['rand30'].get('c3'):
            ts = st.mean(x[0] for x in agg['rand30']['std']); tc = st.mean(x[0] for x in agg['rand30']['c3'])
            w.writerow([f'throughput_gain_c3_vs_std_rand30 = T_std/T_c3 - 1 = {100 * (ts / tc - 1):.2f}%'])
    print('wrote table3_single.csv and table4_batch.csv;', len(sets), 'complete sets')


if __name__ == '__main__':
    main()
