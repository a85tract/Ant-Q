"""The paper's timing figure on the 14-core bitfile: (a) oscilloscope gap between two marker pulses with and without a
command-buffer handover, each relative to its own median; (b) the wait recorded at the last sub-circuit boundary of every
streamed run (bench and qubit) and of the refill sweep; (c) the refill sweep: that wait versus the circuit duration for all
14 cores and for one core, with the fitted threshold t0 + nS/B_D. Run experiments/device_x6y3/handover_scope_analyze.py first.
usage: ANTQ_RESULTS=results/bench python make_timing_figure.py [out.pdf]   (default: <results>/analysis/timing_figure.pdf)"""
import csv, json, os, sys, statistics as st
import numpy as np
import matplotlib; matplotlib.use('Agg'); import matplotlib.pyplot as plt, matplotlib.ticker
HERE = os.path.dirname(os.path.abspath(__file__)); RES = os.environ.get('ANTQ_RESULTS', os.path.join(HERE, '..', '..', 'results', 'bench'))
DEV = os.path.join(RES, '..', 'device_x6y3')
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(RES, 'analysis', 'timing_figure.pdf')
os.makedirs(os.path.dirname(os.path.abspath(OUT)), exist_ok=True)
T0_US, S_B, BD = 2.0, 32768, 9.0e9          # fitted latency, command bytes per core, DRAM-to-BRAM rate (the paper's refill model)
UNIT_US = 1.5                                # duration of a sweep unit without added delay (one read)

fig, (a, b, c) = plt.subplots(1, 3, figsize=(6.0, 2.5))   # 153 mm text width of the journal: all text >= 7 pt at 1:1

# (a) handover on the oscilloscope
sc = json.load(open(os.path.join(RES, 'handover_scope', 'hand_13b440c3_analysis.json')))
g_with, g_without = np.array(sc['700']['gaps_ns']), np.array(sc['701']['gaps_ns'])
bins = np.arange(-1.6, 1.61, 0.32)            # the scope's sample interval
a.hist(g_without - np.median(g_without), bins, color='#999999', alpha=0.8, label=f'without, median {np.median(g_without):.0f} ns')
a.hist(g_with - np.median(g_with), bins, histtype='step', color='#0a6ba0', lw=1.4, label=f'with handover, {np.median(g_with):.0f} ns')
a.set_xlabel('Gap minus its median (ns)', fontsize=7); a.set_ylabel('Captures', fontsize=7)
a.set_ylim(0, 6.2); a.yaxis.set_major_locator(matplotlib.ticker.MaxNLocator(integer=True)); a.set_title('(a) Handover, oscilloscope', fontsize=8); a.legend(fontsize=7, frameon=False, loc='upper left')

# (b) wait at the last boundary: streamed runs (flag clear) and the refill sweep
waits_ns = []
for f in (os.path.join(RES, 'raw_runs.csv'), os.path.join(RES, 'raw_runs_phys.csv'), os.path.join(DEV, 'raw_runs_phys.csv')):
    for r in csv.DictReader(open(f)):
        if r['status'] != 'ok' or r['mode'] != 'c3' or r.get('cnr_wait_cycles', '') in ('', '0'):
            continue                               # 0 = the run has no boundary
        waits_ns.append(2.0 * int(r['cnr_wait_cycles']))
sweep = [r for r in csv.DictReader(open(os.path.join(RES, 'refill', 'refill_sweep_13b440c3.csv'))) if r['status'] == 'ok']
sweep_ns = [1e3 * float(r['cnr_wait_us']) for r in sweep if r['cnr_wait_us']]
e = np.geomspace(1, 1e5, 26)
b.hist([waits_ns, sweep_ns], e, stacked=True, color=['#0a6ba0', '#e69f00'],
       label=[f'streamed runs ({len(waits_ns)})', f'refill sweep ({len(sweep_ns)})'])
b.axvline(16, color='black', ls='--', lw=0.8); b.text(20, 2.0, 'flag\nthreshold\n16 ns', fontsize=7)
b.set_xscale('log'); b.set_yscale('log'); b.set_ylim(0.7, 2e4); b.set_xlabel('Wait at the last boundary (ns)', fontsize=7); b.set_ylabel('Runs', fontsize=7)
b.set_title('(b) Boundary wait', fontsize=8); b.legend(fontsize=7, frameon=False, loc='upper right')

# (c) refill sweep: wait versus circuit duration (all units staged in DRAM before the start)
for mode, n, col, lab in (('full', 14, '#0a6ba0', 'all 14 cores'), ('compact', 1, '#e69f00', 'one core')):
    pts = {}
    for r in sweep:
        if r['mode'] == mode and r['prefill'] == 'all' and r['cnr_wait_us']:
            pts.setdefault(float(r['D_us']) + UNIT_US, []).append(float(r['cnr_wait_us']))
    xs = sorted(pts); c.plot(xs, [st.mean(pts[x]) for x in xs], 'o', ms=3, color=col, label=lab)
    th = T0_US + n * S_B / BD * 1e6
    c.axvline(th, color=col, ls=':', lw=0.8)
    xx = np.linspace(0, 100, 400); c.plot(xx, np.maximum(th - xx, 0), '-', color=col, lw=0.7, alpha=0.7)
c.set_xlim(0, 100); c.set_xlabel('Circuit duration ($\\mu$s)', fontsize=7); c.set_ylabel('Wait at the last boundary ($\\mu$s)', fontsize=7)
c.set_title('(c) Refill threshold', fontsize=8); c.legend(fontsize=7, frameon=False, loc='upper right')
for ax in (a, b, c): ax.tick_params(labelsize=7)
fig.tight_layout(); fig.savefig(OUT); print('wrote', OUT)
