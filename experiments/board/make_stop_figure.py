"""The paper's early-stop figure from table_stop.csv (make_phys_tables.py part B): per circuit, the preset stop point and the
shots actually executed (mean of the 5 stop runs), both as a percentage of the circuit's shot budget.
usage: ANTQ_RESULTS=results/bench python make_stop_figure.py [out.pdf] [tag]   (default: <results>/analysis/early_stop_shots.pdf, c3_14q_stop1)"""
import csv, os, sys, statistics as st
import matplotlib; matplotlib.use('Agg'); import matplotlib.pyplot as plt
HERE = os.path.dirname(os.path.abspath(__file__)); RES = os.environ.get('ANTQ_RESULTS', os.path.join(HERE, '..', '..', 'results'))
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(RES, 'analysis', 'early_stop_shots.pdf')
os.makedirs(os.path.dirname(os.path.abspath(OUT)), exist_ok=True)
TAG = sys.argv[2] if len(sys.argv) > 2 else 'c3_14q_stop1'
LABEL = {'GHZ-3': 'GHZ-3', 'GHZ-6': 'GHZ-6', 'GHZ-8': 'GHZ-8', 'VQE BeH2 14Q': 'VQE BeH$_2$', 'QML Image Class 14Q': 'QML Image\nClass',
         'VQE SrH PDM 12Q': 'VQE SrH\nPDM'}
shots = {r['idx']: (r['name'], int(r['rerun_shots'])) for r in csv.DictReader(open(os.path.join(RES, 'shots_verification.csv')))}
rows = [r for r in csv.DictReader(open(os.path.join(RES, 'table_stop.csv'))) if r['tag'] == TAG]
names, stop_pct, act_pct = [], [], []
for r in rows:
    name, n = shots[r['idx']]
    names.append(LABEL.get(name, name)); stop_pct.append(100 * int(r['stop_at']) / n)
    act_pct.append(100 * st.mean(int(x) for x in r['actual_shots'].split()) / n)
fig, ax = plt.subplots(figsize=(7.5, 4.5)); x = range(len(names)); w = 0.7
ax.bar(x, [100] * len(names), w, color='#e6e6e6', edgecolor='black', lw=0.8, label='Original (100%)')
ax.bar(x, act_pct, w, color='#7fb0d0', edgecolor='black', lw=0.8, label='Actual shots')
ax.bar(x, stop_pct, w, color='#0a6ba0', edgecolor='black', lw=0.8, label='Stop threshold')
for i, (s, a) in enumerate(zip(stop_pct, act_pct)):
    ax.text(i, s / 2, f'{s:.0f}%', ha='center', va='center', color='white', fontsize=13, fontweight='bold')
    ax.text(i, a + 2, f'{a:.2f}%', ha='center', va='bottom', color='#0b4f75', fontsize=13, fontweight='bold')
ax.axhline(100, color='gray', ls='--', lw=0.8); ax.set_ylim(0, 118); ax.set_xticks(list(x)); ax.set_xticklabels(names, fontsize=12)
ax.set_ylabel('Shots (% of original)', fontsize=14); ax.grid(axis='y', color='#dddddd', lw=0.6); ax.set_axisbelow(True)
for s in ('top', 'right'): ax.spines[s].set_visible(False)
ax.legend(loc='upper center', ncol=3, frameon=False, fontsize=12, bbox_to_anchor=(0.5, 1.02))
fig.tight_layout(); fig.savefig(OUT); print('wrote', OUT, list(zip(names, [round(s, 2) for s in stop_pct], [round(a, 2) for a in act_pct])))
