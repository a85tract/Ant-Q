"""Per-shot length of the REAL benchmark programs on the C1 bitfile (plan rev3 Q1): same method as
c1_slope.py — slope of the std_server C1-mode interval between 100 and 50100 shots, mean of 3 —
but the workload is Programs.real(idx). Writes results/per_shot_realized_real.csv."""
import os, sys, csv, statistics as st, types
sys.argv = ['x']
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from antq_runner import Programs, load_bench, prep_tables
from qubic.std_client import StdServerClient

GW = os.environ.get('ANTQ_GW_C1', '/home/yicheng/gateware_yguang_check/gw_build_c1/top/zcu216_14_2/build_0071783e_20260829023649')
P = Programs(GW, 14)
bench = load_bench()
cl = StdServerClient('localhost', GW)
rows = []
for idx, b in sorted(bench.items()):
    exe, ps_us, rps = P.real(idx)
    prep_tables(exe)
    def run(n):
        info, _ = cl.run_batch([{'binaries': exe.get_binaries_fromboard(), 'nshots': n, 'chans': {}, 'regs': {}}],
                               readout_ddr=True, timeout_s=600)
        return info['elapsed_ms']
    run(100)
    sl = []
    for rep in range(3):
        t1 = run(100); t2 = run(50100)
        sl.append((t2 - t1) / 50000 * 1000)
    rows.append((idx, b['name'], ps_us, st.mean(sl), st.stdev(sl)))
    print(f'C1SLOPE-REAL {idx} {b["name"][:20]!r} compiled {ps_us:.4f} realized {st.mean(sl):.4f} '
          f'+- {st.stdev(sl):.4f} us (+{st.mean(sl) - ps_us:.4f})', flush=True)
with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'results', 'per_shot_realized_real.csv'), 'w', newline='') as f:
    w = csv.writer(f)
    w.writerow(['idx', 'name', 'per_shot_compiled_us', 'per_shot_c1_slope_us', 'sd_us', 'method'])
    for idx, name, comp, m, sd in rows:
        w.writerow([idx, name, f'{comp:.4f}', f'{m:.4f}', f'{sd:.4f}',
                    'REAL programs, C1 14_2 std_server: (interval(50100) - interval(100)) / 50000, mean of 3'])
