"""Consolidate the ABAB blocks: per-block key numbers, the four pairwise comparisons (compare_blocks.py JSON) and one figure
(fringe P1 vs phase and RB survival vs length for all blocks). Run analyze_block.py on the four blocks first.
usage: python summarize_abab.py [results_dir] [tag prefix, E for EA1/EB1/EA2/EB2]"""
import sys, os, json, subprocess
import numpy as np
res = sys.argv[1] if len(sys.argv) > 1 else os.environ['ANTQ_RESULTS']
PFX = sys.argv[2] if len(sys.argv) > 2 else 'E'           # tag prefix: E for EA1/EB1/EA2/EB2
an = os.path.join(res, 'analysis'); TAGS = [PFX + t for t in ('A1', 'B1', 'A2', 'B2')]
S = {t: json.load(open(os.path.join(an, f'{t}_summary.json'))) for t in TAGS if os.path.exists(os.path.join(an, f'{t}_summary.json'))}
print("block | config | readout P00/P11 | fringe contrast | fringe phase [rad] | P0-C period us | Ramsey pair-diff mean | RB EPC [95%]")
for t, s in S.items():
    cfg = 'stock 694fa11a (BRAM path)' if t[len(PFX)] == 'A' else os.environ.get('ANTQ_B_IMAGE', 'Ant-Q c26942c0 (DDR path)')
    print(f"{t} | {cfg} | {s['readout']['P00']:.3f}/{s['readout']['P11']:.3f} | {s['fringe']['contrast']:.3f}({s['fringe']['contrast_err']:.3f}) | {s['fringe']['phase']:+.3f}({s['fringe']['phase_err']:.3f}) | {s['p0c']['period_us']:.4f} | {s['ramsey_pairs']['diff_mean']:+.4f}({s['ramsey_pairs']['diff_mean_se']:.4f}) n={s['ramsey_pairs']['iterations']} | {s['rb']['EPC']:.4f} [{s['rb']['EPC_ci95'][0]:.4f}, {s['rb']['EPC_ci95'][1]:.4f}]")
pairs = [(PFX+'A1', PFX+'B1', 'configuration contrast, pass 1'), (PFX+'A2', PFX+'B2', 'configuration contrast, pass 2'), (PFX+'A1', PFX+'A2', 'within stock: drift'), (PFX+'B1', PFX+'B2', 'within Ant-Q: drift')]
for a, b, what in pairs:
    if a in S and b in S:
        print(f"\n### {a} vs {b} — {what}")
        out = subprocess.run([sys.executable, os.path.join(os.path.dirname(__file__), 'compare_blocks.py'), a, b, res], capture_output=True, text=True, env=dict(os.environ, AQT_RB_LENGTHS='2,4,8,16,32'))
        print("\n".join(out.stdout.strip().splitlines()[1:]))
import matplotlib; matplotlib.use('Agg'); import matplotlib.pyplot as plt
fig, ax = plt.subplots(1, 2, figsize=(11, 4))
ph = np.linspace(-np.pi, np.pi, 13)
for t, s in S.items():
    st = '-' if t[len(PFX)] == 'A' else '--'; mk = 'o' if t[len(PFX)] == 'A' else 's'
    ax[0].plot(ph, s['fringe']['P1'], st + mk, label=f"{t} ({'stock' if t[len(PFX)]=='A' else 'Ant-Q'})", ms=4)
    ax[1].errorbar(s['rb']['lengths'], s['rb']['survival_mean'], yerr=np.nanstd(np.array(s['rb']['survival_per_seq']), axis=1) / np.sqrt(8), fmt=st + mk, ms=4, capsize=2, label=f"{t}: EPC {s['rb']['EPC']:.4f}")
ax[0].set_xlabel('virtual-Z phase (rad)'); ax[0].set_ylabel('P(1)'); ax[0].set_title(f'Fringe X90 - 100 ns - Z(phi) - X90, {PFX or "Q5"}'); ax[0].legend(fontsize=8)
ax[1].set_xlabel('Clifford length m'); ax[1].set_ylabel('P(0) survival'); ax[1].set_xscale('log', base=2); ax[1].set_title(f'1Q RB, {PFX or "Q5"} (8 seqs)'); ax[1].legend(fontsize=8)
fig.tight_layout(); fn = os.path.join(an, f'{PFX or "Q5"}_abab_fringe_rb.png'); fig.savefig(fn, dpi=130); print("\nfigure:", fn)
