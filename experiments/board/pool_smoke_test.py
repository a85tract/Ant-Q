"""Plan C2(d) hardware integration SMOKE TEST (descriptive; the correctness gate is pool_preflight.py):
Bell (idx 1), Grover (idx 24) and a deterministic X90 calibration program on c3, 1000 shots per run, order
W N P P N per program (W = native warm-up that freezes the bin edges and qualifies channels). Per channel and read
index the loopback IQ phase is random shot to shot (the readout cores drift; complex means cancel, measured
2026-09-01), so the statistic is PHASE-INSENSITIVE: TVD between per-shot |IQ| histograms (16 bins from W's
1st-99th percentiles + overflow bins) for the 4 native-pooled pairs and the native-native pair; channels whose
mean |IQ| on W is below 5 % of the largest channel's are excluded; grand mean over kept channels x 4 comparisons. STOP rules: (1) grand mean > 0.30;
(2) native-native mean > 0.15. Counts must be exact. Output: results/smoke_test.json / .csv"""
import sys, os, json, csv, io, contextlib
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import antq_runner
from qubic.rpc_client import CircuitRunnerClient
GW = sys.argv[1]; SHOTS = 1000
NAT = antq_runner.Programs(GW, 14); POO = antq_runner.Programs(GW, 14, pool_tables=True); POO.build_pool()
def x90cal(P):
    P._real_init() if not hasattr(P, '_real_qchip') else None
    circ = [{'name': 'X90', 'qubit': f'qubit_{i}'} for i in range(14)] + [{'name': 'read', 'qubit': f'qubit_{i}'} for i in range(14)]
    qg = {f'qubit_{i}': {f'qubit_{i}.qdrv', f'qubit_{i}.rdrv', f'qubit_{i}.rdlo'} for i in range(14)}
    comp = P.tc.run_compile_stage(circ, P._real_fpga, P._real_qchip, compiler_flags={'schedule': True}, qubit_grouping=qg)
    return P.tc.run_assemble_stage(comp, P.cc, elem_cfg_pool=P.pool), {f'qubit_{i}.rdlo': 1 for i in range(14)}
PROGS = {'bell': lambda P: (P.real(1)[0], P.real(1)[2]), 'grover': lambda P: (P.real(24)[0], P.real(24)[2]), 'x90cal': x90cal}
r = CircuitRunnerClient(antq_runner.BOARD, antq_runner.RPC_PORT, ddr_cmd=True, num_ch=14, slot_bytes=NAT.slot_bytes)
def run(exe, rps):
    with contextlib.redirect_stdout(io.StringIO()):
        res = r.run_circuit_batch([exe], SHOTS, reads_per_shot=[rps])[0]
    out = {}
    for ch, s11 in res.items():
        a = np.asarray(s11._array).reshape(SHOTS, -1)
        if a.shape[1] != rps.get(ch, 1): raise RuntimeError(f'{ch}: shape {a.shape} vs rps {rps.get(ch)}')
        out[ch] = a
    return out
def tvd(a, b, edges):
    ha, _ = np.histogram(np.abs(a), bins=edges); hb, _ = np.histogram(np.abs(b), bins=edges)
    return 0.5 * np.abs(ha / ha.sum() - hb / hb.sum()).sum()
report = {}; rows = []
for name, build in PROGS.items():
    en, rps = build(NAT); ep, _ = build(POO)
    runs = {}
    for tag, exe in [('W', en), ('N1', en), ('P1', ep), ('P2', ep), ('N2', en)]:
        runs[tag] = run(exe, rps); print(name, tag, 'ok', flush=True)
    chans = sorted(runs['W']); mag = {}; edges = {}
    for ch in chans:
        w = runs['W'][ch]
        for k in range(w.shape[1]):
            v = np.abs(w[:, k]); mag[(ch, k)] = float(v.mean())
            lo, hi = np.percentile(v, [1, 99]); edges[(ch, k)] = np.concatenate([[0.0], np.linspace(lo, hi, 17), [np.inf]])
    amax = max(mag.values()); q = [key for key, m in mag.items() if m >= 0.05 * amax]
    pairs = {'N1-P1': ('N1', 'P1'), 'N1-P2': ('N1', 'P2'), 'N2-P1': ('N2', 'P1'), 'N2-P2': ('N2', 'P2'), 'N1-N2': ('N1', 'N2')}
    t = {p: float(np.mean([tvd(runs[a][ch][:, k], runs[b][ch][:, k], edges[(ch, k)]) for ch, k in q])) for p, (a, b) in pairs.items()}
    grand = float(np.mean([t[p] for p in pairs if p != 'N1-N2']))
    per_ch = {f'{ch}[{k}]': {p: round(float(tvd(runs[a][ch][:, k], runs[b][ch][:, k], edges[(ch, k)])), 4) for p, (a, b) in pairs.items()} for ch, k in q}
    means = {f'{ch}[{k}]': {tag: round(float(np.abs(runs[tag][ch][:, k]).mean()), 1) for tag in runs} for ch, k in mag}
    report[name] = dict(kept=len(q), total=len(mag), tvd=t, grand_mean_native_pooled=grand, native_native=t['N1-N2'],
                        stop1=grand > 0.30, stop2=t['N1-N2'] > 0.15, per_channel_tvd=per_ch, mean_abs_iq=means)
    rows.append(dict(program=name, kept=len(q), total=len(mag), grand_mean_native_pooled=round(grand, 4), native_native=round(t['N1-N2'], 4), **{k: round(v, 4) for k, v in t.items()}))
    print(name, 'kept', len(q), '/', len(mag), 'TVD', {k: round(v, 3) for k, v in t.items()}, 'grand', round(grand, 3), flush=True)
json.dump(report, open(os.path.join(antq_runner.RES, 'smoke_test.json'), 'w'), indent=1)
w = csv.DictWriter(open(os.path.join(antq_runner.RES, 'smoke_test.csv'), 'w'), fieldnames=list(rows[0].keys())); w.writeheader(); w.writerows(rows)
stops = [n for n, x in report.items() if x['stop1'] or x['stop2']]
print('SMOKE', 'STOP ' + str(stops) if stops else 'PASS (no stop condition)')
