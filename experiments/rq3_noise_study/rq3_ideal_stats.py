#!/usr/bin/env python3
"""rq3_ideal_stats.py -- exact ideal output distribution of every paper circuit (statevector, final measurements
removed): number of outcomes, max probability vs uniform, collision ratio sum p^2 / 2^-n (1.000 = exactly uniform),
Shannon entropy in bits. A circuit whose ideal output is uniform carries no information, so no readability metric can be
defined for it (its FAIL grade in Table noise_study is sampling noise). Output: results/rq3/ideal_distribution_stats.csv"""
import csv, math, sys
from rq3_common import REPO, OUT_DIR  # noqa: F401  (adds the benchmark dir and this dir to sys.path)
from qiskit.quantum_info import Statevector
from rq3_common import load_circuits, OUT_DIR
rows = []
for c in load_circuits():
    qc = c['circuit']; p = Statevector(qc.remove_final_measurements(inplace=False)).probabilities_dict()
    n = len(next(iter(p))); u = 1 / 2 ** n; v = sorted(p.values(), reverse=True)
    rows.append(dict(idx=c['idx'], name=c['name'], n_qubits=c['n_qubits'], shots=c['shots'], n_outcomes=sum(1 for x in v if x > 1e-9),
                     max_p=round(v[0], 6), uniform_p=round(u, 6), collision_ratio=round(sum(x * x for x in v) / u, 3),
                     entropy_bits=round(-sum(x * math.log2(x) for x in v if x > 0), 3),
                     verdict='UNIFORM (no information)' if sum(x * x for x in v) / u < 1.02 else ('broad' if -sum(x * math.log2(x) for x in v if x > 0) > n - 1.5 else 'peaked')))
with open(OUT_DIR / 'ideal_distribution_stats.csv', 'w', newline='') as f:
    w = csv.DictWriter(f, fieldnames=list(rows[0].keys())); w.writeheader(); w.writerows(rows)
for r in rows: print(f"idx {r['idx']:2d} {r['name']:28s} {r['n_qubits']:2d}q shots {r['shots']:6d} outcomes {r['n_outcomes']:5d} max_p/uniform {r['max_p']/r['uniform_p']:8.1f} collision {r['collision_ratio']:7.3f} entropy {r['entropy_bits']:6.2f}/{r['n_qubits']} {r['verdict']}")
