#!/usr/bin/env python3
"""rq3_sampling_floor.py -- finite-sample floor of the RQ3 metrics: TVD and HF between two INDEPENDENT NOISELESS samples
of each paper circuit, at 30 % of the shot budget (the earliest stop checkpoint) and at 100 %, and against a 10 %
reference sample (the rule's reference). A circuit whose noiseless-vs-noiseless TVD at 30 % already exceeds 0.6 (HF
below 0.4) sits in the rule's "unreadable" zone without any noise: the rule cannot separate noise from undersampling
for such broad output distributions. Output: results/rq3/sampling_floor.csv"""
import csv, statistics as st, sys
from collections import Counter
from rq3_common import REPO, OUT_DIR  # noqa: F401  (adds the benchmark dir and this dir to sys.path)
from qiskit_aer import AerSimulator
from rq3_common import load_circuits
from metrics import total_variation_distance, hellinger_fidelity

ideal = AerSimulator()
def sample(qc, n, seed):
    m = ideal.run(qc, shots=n, memory=True, seed_simulator=seed).result().get_memory(0)
    return {k: v / n for k, v in Counter(m).items()}
out = []
for c in load_circuits():
    shots = c['shots']; n30 = max(shots // 10, 1) * 3; nref = max(shots // 10, 100)
    rec = dict(idx=c['idx'], name=c['name'], n_qubits=c['n_qubits'], shots=shots, n_outcomes_full=len(sample(c['circuit'], shots, 7)))
    for tag, na, nb in (('30_vs_ref', n30, nref), ('100_vs_100', shots, shots)):
        tv, hf = [], []
        for s in range(5):
            pa, pb = sample(c['circuit'], na, 100 + s), sample(c['circuit'], nb, 200 + s)
            tv.append(total_variation_distance(pa, pb)); hf.append(hellinger_fidelity(pa, pb))
        rec[f'tvd_{tag}'] = round(st.mean(tv), 3); rec[f'hf_{tag}'] = round(st.mean(hf), 3)
    out.append(rec); print(rec, flush=True)
with open(OUT_DIR / 'sampling_floor.csv', 'w', newline='') as f:
    w = csv.DictWriter(f, fieldnames=list(out[0].keys())); w.writeheader(); w.writerows(out)
