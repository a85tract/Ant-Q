"""Probe: does a metric that uses the EXACT ideal probabilities decide noise dominance at the paper's shot budgets?
Linear cross-entropy fidelity F = (mean_i p(x_i) - 1/2^n) / (sum_x p(x)^2 - 1/2^n): 1 for ideal sampling of ANY
distribution, 0 for uniform noise. Standard error from the sample spread of p(x_i). Noiseless sample = mapping check."""
import sys, statistics as st, math
from rq3_common import REPO  # noqa: F401  (adds the benchmark dir and this dir to sys.path)
from qiskit import transpile
from qiskit.quantum_info import Statevector
from qiskit_aer import AerSimulator
from rq3_common import load_circuits
from run_early_stop import BACKEND_MAP
ideal = AerSimulator()
cases = {14: 'FakeAlgiers', 22: 'FakeAlgiers', 21: 'FakeAlgiers', 24: 'FakeAlgiers', 2: 'FakeLagosV2', 23: 'FakeSherbrooke', 4: 'FakeAlgiers', 7: 'FakeSherbrooke'}
C = {c['idx']: c for c in load_circuits()}
print(f"{'circuit':28s} {'shots':>6s} {'n_out':>5s} | F noiseless 30% / 100% | F noisy 30% / 100% (+-se) | backend")
for idx, bname in cases.items():
    c = C[idx]; qc = c['circuit']; shots = c['shots']; n30 = max(shots // 10, 1) * 3
    p = Statevector(qc.remove_final_measurements(inplace=False)).probabilities_dict()
    nq = len(next(iter(p))); u = 1 / 2 ** nq; denom = sum(v * v for v in p.values()) - u
    def F(mem):
        vals = [p.get(x, 0.0) for x in mem]; m = st.mean(vals); se = st.pstdev(vals) / math.sqrt(len(vals))
        return (m - u) / denom, se / denom
    b = BACKEND_MAP[bname](); noisy = AerSimulator.from_backend(b)
    qt = transpile(qc, backend=b, optimization_level=1, seed_transpiler=0)
    mem_i = ideal.run(qc, shots=shots, memory=True, seed_simulator=1).result().get_memory(0)
    mem_n = noisy.run(qt, shots=shots, memory=True, seed_simulator=1).result().get_memory(0)
    fi30, _ = F(mem_i[:n30]); fi, _ = F(mem_i); fn30, se30 = F(mem_n[:n30]); fn, se = F(mem_n)
    print(f"{c['name']:28s} {shots:6d} {len(p):5d} | {fi30:5.2f} / {fi:5.2f}            | {fn30:5.2f} / {fn:5.2f} (+-{se:.2f})       | {bname}")
