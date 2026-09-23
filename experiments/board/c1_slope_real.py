"""Per-shot length of the REAL benchmark programs on the C1 bitfile: slope of the std_server C1-mode interval between
100 and 50100 shots, mean of 3, with the workload Programs.real(idx). Every run is appended to
$ANTQ_RESULTS/per_shot_realized_raw.csv (repeat -1 = warm-up); the per-circuit table $ANTQ_RESULTS/per_shot_realized_real.csv
is computed from those rows.
usage: python c1_slope_real.py [--from-raw]   (--from-raw: rebuild the table from the raw rows only, no board)"""
import os, sys, csv, time, subprocess, statistics as st
FROM_RAW = '--from-raw' in sys.argv
sys.argv = ['x']                                   # antq_runner parses sys.argv when imported
HERE = os.path.dirname(os.path.abspath(__file__)); sys.path.insert(0, HERE)
RES = os.environ.get('ANTQ_RESULTS', os.path.join(HERE, '..', '..', 'results'))
RAW, OUT = os.path.join(RES, 'per_shot_realized_raw.csv'), os.path.join(RES, 'per_shot_realized_real.csv')
FIELDS = ['wall_time', 'bitfile', 'software_commit', 'idx', 'name', 'per_shot_compiled_us', 'repeat', 'shots', 'elapsed_ms']
N0, N1 = 100, 50100

if not FROM_RAW:
    from antq_runner import Programs, load_bench, prep_tables
    from std_client import StdServerClient   # experiments/board/std_client.py
    GW = os.environ['ANTQ_GW_C1']
    P = Programs(GW, 14)
    bench = load_bench()
    cl = StdServerClient(os.environ.get('ANTQ_BOARD', 'localhost'), GW)
    sw = subprocess.run(['git', '-C', os.environ.get('ANTQ_SOFTWARE', '.'), 'rev-parse', '--short', 'HEAD'],
                        capture_output=True, text=True).stdout.strip()
    new = not os.path.exists(RAW)
    with open(RAW, 'a', newline='') as f:
        w = csv.DictWriter(f, FIELDS)
        if new: w.writeheader()
        for idx, b in sorted(bench.items()):
            exe, ps_us, rps = P.real(idx)
            prep_tables(exe)
            def run(n, rep):
                info, _ = cl.run_batch([{'binaries': exe.get_binaries_fromboard(), 'nshots': n, 'chans': {}, 'regs': {}}],
                                       readout_ddr=True, timeout_s=600)
                w.writerow(dict(wall_time=time.strftime('%Y-%m-%dT%H:%M:%S'), bitfile=os.path.basename(GW), software_commit=sw,
                                idx=idx, name=b['name'], per_shot_compiled_us=f'{ps_us:.4f}', repeat=rep, shots=n,
                                elapsed_ms=f"{info['elapsed_ms']:.6f}")); f.flush()
            run(N0, -1)
            for rep in range(3):
                run(N0, rep); run(N1, rep)
            print(f'C1SLOPE-REAL {idx} {b["name"][:20]!r} done', flush=True)

# table: per circuit and repeat, the latest row at each shot count; slope in us per shot
last = {}
for r in csv.DictReader(open(RAW)):
    if int(r['repeat']) >= 0: last[(int(r['idx']), int(r['repeat']), int(r['shots']))] = r
rows = []
for idx in sorted({k[0] for k in last}):
    sl = [(float(last[(idx, rep, N1)]['elapsed_ms']) - float(last[(idx, rep, N0)]['elapsed_ms'])) / (N1 - N0) * 1000
          for rep in range(3) if (idx, rep, N0) in last and (idx, rep, N1) in last]
    assert len(sl) == 3, f'circuit {idx}: {len(sl)} complete repeats'
    r0 = last[(idx, 0, N0)]
    rows.append((idx, r0['name'], float(r0['per_shot_compiled_us']), st.mean(sl), st.stdev(sl)))
    print(f'C1SLOPE-REAL {idx} {r0["name"][:20]!r} compiled {rows[-1][2]:.4f} realized {rows[-1][3]:.4f} '
          f'+- {rows[-1][4]:.4f} us (+{rows[-1][3] - rows[-1][2]:.4f})', flush=True)
with open(OUT, 'w', newline='') as f:
    w = csv.writer(f)
    w.writerow(['idx', 'name', 'per_shot_compiled_us', 'per_shot_c1_slope_us', 'sd_us', 'method'])
    for idx, name, comp, m, sd in rows:
        w.writerow([idx, name, f'{comp:.4f}', f'{m:.4f}', f'{sd:.4f}',
                    'REAL programs, C1 14_2 std_server: (interval(50100) - interval(100)) / 50000, mean of 3'])
