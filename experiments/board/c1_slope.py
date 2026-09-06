"""Per-shot length on the C1 bitfile (BRAM commands, standard DSP loop): slope of the std_server C1-mode interval
(t_start -> lastshotdone; readout drained after, not timed) between 100 and 50100 shots, mean of 3."""
import os, sys, csv, statistics as st
sys.argv=['x']
from antq_runner import Programs, load_bench, active_channels, prep_tables
from qubic.std_client import StdServerClient
GW = os.environ.get('ANTQ_GW_C1', '/home/yicheng/gateware_yguang_check/gw_build_c1/top/zcu216_14_2/build_0071783e_20260829023649')
P=Programs(GW, 14); bench=load_bench(); cl=StdServerClient('localhost', GW)
rows=[]
for idx,b in sorted(bench.items()):
    exe=P.readout_sim(b['n_qubits'], b['per_shot_us']); prep_tables(exe)
    def run(n):
        info,_=cl.run_batch([{'binaries': exe.get_binaries_fromboard(), 'nshots': n, 'chans': {}, 'regs': {}}], readout_ddr=True, timeout_s=600)
        return info['elapsed_ms']
    run(100); sl=[]
    for rep in range(3):
        t1=run(100); t2=run(50100); sl.append((t2-t1)/50000*1000)
    rows.append((idx, b['per_shot_us'], st.mean(sl), st.stdev(sl)))
    print(f'C1SLOPE {idx} {b["name"][:20]!r} nominal {b["per_shot_us"]:.3f} realized {st.mean(sl):.4f} +- {st.stdev(sl):.4f} us (+{st.mean(sl)-b["per_shot_us"]:.3f})', flush=True)
with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'results', 'per_shot_c1_slope.csv'),'w',newline='') as f:
    w=csv.writer(f); w.writerow(['idx','per_shot_nominal_us','per_shot_c1_slope_us','sd_us','method'])
    for idx,nom,m,sd in rows: w.writerow([idx, f'{nom:.3f}', f'{m:.4f}', f'{sd:.4f}', 'C1 14_2 std_server: (interval(50100 shots) - interval(100 shots)) / 50000, lastshotdone-ended, mean of 3'])
