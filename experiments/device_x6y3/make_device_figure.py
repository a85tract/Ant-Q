"""The paper's device figure: (a) RB survival vs Clifford length on both command paths over the lengths both paths hold
(deep_rb_analysis.py output), with the stock path's command-memory limit and the Ant-Q-only lengths marked; (b) the boundary
fringe, streamed (S, one handover inside the Ramsey delay) vs unbroken (U) and unbroken with a 152-ns idle (UD) (boundary_analysis.py output). Run the two analyses
first.
usage: python make_device_figure.py [results_dir] [out.pdf]   (default: $ANTQ_RESULTS, <results>/analysis/device_figure.pdf)"""
import json, os, sys
import numpy as np
import matplotlib; matplotlib.use('Agg'); import matplotlib.pyplot as plt
res = sys.argv[1] if len(sys.argv) > 1 else os.environ['ANTQ_RESULTS']
an = os.path.join(res, 'analysis'); out = sys.argv[2] if len(sys.argv) > 2 else os.path.join(an, 'device_figure.pdf')
rb = json.load(open(os.path.join(an, 'deep_rb_DRB_DRA.json'))); bd = json.load(open(os.path.join(an, 'BNDF_boundary_summary.json')))
STYLE = {'A': ('QubiC', '#555555', 'o'), 'B': ('Ant-Q', '#0a6ba0', 's')}
fig, (a, b) = plt.subplots(1, 2, figsize=(6.0, 2.8))   # printed at the full text width (about 15 cm): all text >= 8 pt
shared = [m for m in rb['epc_diff_B_minus_A']['shared_lengths']]
for key in ('A', 'B'):
    d = rb[key]; label, col, mk = STYLE[key]
    mean = np.array([d['table'][str(m)]['mean'] for m in shared]); ci = np.array([d['table'][str(m)]['ci_mean'] for m in shared])
    a.errorbar(shared, mean, yerr=[mean - ci[:, 0], ci[:, 1] - mean], fmt=mk, color=col, ms=3, capsize=2, lw=0.8, label=label)
    xs = np.geomspace(shared[0], shared[-1], 100); a.plot(xs, d['floor'] + d['A'] * d['p'] ** xs, '-', color=col, lw=0.9)
only = sorted(int(m) for m in rb['B']['table'] if int(m) > shared[-1])
seamless = sum(rb['B']['table'][str(m)]['seamless'] for m in only); runs = sum(rb['B']['table'][str(m)]['n_seq'] for m in only)
LIMIT = 1000   # ~ Cliffords in the 2048-command buffer of stock QubiC (about 2 commands per Clifford; m = 1024 compiles to 2055)
a.axvspan(LIMIT, only[-1] * 2.5, color='#0a6ba0', alpha=0.08, lw=0)
a.axvline(LIMIT, color='#555555', ls='--', lw=0.8)
a.text(LIMIT * 1.15, 0.63, f'Ant-Q only\n$m$ = {", ".join(map(str, only[:-1]))},\n{only[-1]}\n{seamless}/{runs} runs with\nno wait > 16 ns',
       ha='left', va='center', fontsize=8)
a.text(LIMIT * 0.9, 0.815, 'QubiC limit (2048 commands)', rotation=90, ha='right', va='top', fontsize=8, color='#555555')
a.set_xscale('log'); a.set_xlim(12, only[-1] * 2.5); a.set_ylim(0.44, 0.82)
a.set_xlabel('Clifford length $m$', fontsize=8); a.set_ylabel('Survival $P(0)$', fontsize=8); a.legend(fontsize=8, loc='lower left', frameon=False)
a.set_title('(a) Randomized benchmarking', fontsize=9)
ph = np.linspace(-np.pi, np.pi, 13); xs = np.linspace(-np.pi, np.pi, 200)
for cfg, label, col, mk, ls in (('U', 'Unbroken', '#555555', 'o', '-'), ('UD', 'Unbroken, 152-ns idle', '#e08030', '^', '--'),
                                 ('S', 'With one handover', '#0a6ba0', 's', '-')):
    f = bd['fringe'][cfg]
    b.plot(ph, f['P1'], mk, color=col, ms=3, label=label); b.plot(xs, f['offset'] + f['contrast'] * np.cos(xs - f['phase']), ls, color=col, lw=0.9)
b.set_xlabel('Phase of the second $\\pi/2$ pulse (rad)', fontsize=8); b.set_ylabel('$P(1)$', fontsize=8)
b.set_xticks([-np.pi, -np.pi / 2, 0, np.pi / 2, np.pi]); b.set_xticklabels(['$-\\pi$', '$-\\pi/2$', '0', '$\\pi/2$', '$\\pi$'])
b.set_ylim(0.1, 0.9); b.legend(fontsize=8, loc='lower center', ncol=1, frameon=False, handlelength=1.6); b.set_title('(b) Ramsey fringe across a handover', fontsize=9)
for ax in (a, b):
    ax.tick_params(labelsize=8)
    for s in ('top', 'right'): ax.spines[s].set_visible(False)
fig.tight_layout(); fig.savefig(out); print('wrote', out)
