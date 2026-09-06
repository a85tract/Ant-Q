#!/usr/bin/env python3
"""rq3_adequacy_gate.py -- sampling-adequacy gate for the RQ3 readability rule (both round-2 reviewers: do not subtract
a floor; restrict the rule to circuits whose NOISELESS sampling distribution of the metric stays inside PASS).
For every paper circuit and every checkpoint size n = k/10 x shots (k = 3..10), draw 200 noiseless replicate pairs
(sample of n shots, reference sample of 10 % as the rule uses) and record the 95th percentile of TVD and the 5th
percentile of HF under this null. Gate: evaluable at checkpoint k when TVD_95 < 0.3 and HF_05 > 0.7 (the PASS region,
i.e. the noiseless null never leaves PASS); also reported: the noiseless false-FAIL probability (TVD >= 0.6 & HF <= 0.4).
Output: results/rq3/adequacy_gate.csv"""
import csv, sys
from collections import Counter
import numpy as np
from rq3_common import REPO, OUT_DIR  # noqa: F401  (adds the benchmark dir and this dir to sys.path)
from qiskit_aer import AerSimulator
from rq3_common import load_circuits, exact_probs, REF, OUT_DIR
from metrics import total_variation_distance, hellinger_fidelity

REPS = 200
ideal = AerSimulator()
rows = []
for c in load_circuits():
    shots = c['shots']; step = max(shots // 10, 1); nref = max(shots // 10, 100)
    # one big noiseless sample as the population to resample from (statevector-exact sampling of the circuit itself)
    big = ideal.run(c['circuit'], shots=200000, memory=True, seed_simulator=11).result().get_memory(0)
    big = np.array(big); rng = np.random.default_rng(5)
    for k in range(3, 11):
        n = shots if k == 10 else step * k
        tv, hf = [], []
        pex = exact_probs(c['circuit'])
        for _ in range(REPS):
            a = Counter(rng.choice(big, n)); pa = {x: v / n for x, v in a.items()}
            if REF == 'exact': pb = pex
            else: b = Counter(rng.choice(big, nref)); pb = {x: v / nref for x, v in b.items()}
            tv.append(total_variation_distance(pa, pb)); hf.append(hellinger_fidelity(pa, pb))
        tv = np.array(tv); hf = np.array(hf)
        tv95, hf05 = float(np.percentile(tv, 95)), float(np.percentile(hf, 5))
        rows.append(dict(idx=c['idx'], name=c['name'], n_qubits=c['n_qubits'], shots=shots, checkpoint=k, n=n, n_ref=nref,
                         tvd_p95=round(tv95, 3), hf_p05=round(hf05, 3), tvd_median=round(float(np.median(tv)), 3),
                         p_false_fail=round(float(np.mean((tv >= 0.6) & (hf <= 0.4))), 3),
                         evaluable=int(tv95 < 0.3 and hf05 > 0.7)))
    e = [r['checkpoint'] for r in rows if r['idx'] == c['idx'] and r['evaluable']]
    print(f"idx {c['idx']:2d} {c['name']:28s} shots {shots:6d}: evaluable checkpoints {e if e else 'NONE'}; cp3 TVD95 {rows[-8]['tvd_p95']} HF05 {rows[-8]['hf_p05']}; full TVD95 {rows[-1]['tvd_p95']} HF05 {rows[-1]['hf_p05']}", flush=True)
with open(OUT_DIR / 'adequacy_gate.csv', 'w', newline='') as f:
    w = csv.DictWriter(f, fieldnames=list(rows[0].keys())); w.writeheader(); w.writerows(rows)
