#!/usr/bin/env python3
"""
run_noise_exp.py — Run 23 benchmark circuits on ideal + noisy IBM simulators.

Produces:
  results/noise_results.csv       — per-circuit, per-backend metrics
  results/summary_table.txt       — PASS/MARGINAL/FAIL grid
"""

import os
import sys
import csv
import time
from pathlib import Path

from qiskit import transpile
from qiskit_aer import AerSimulator
from qiskit_ibm_runtime.fake_provider import (
    FakeManilaV2,    # 5Q, older
    FakeLagosV2,     # 7Q, mid-gen
    FakeGuadalupeV2, # 16Q, mid-gen
    FakeAlgiers,     # 27Q, mid-gen
    FakeSherbrooke,  # 127Q, newer
    FakeTorino,      # 133Q, newest
)

from circuits import build_all_circuits
from metrics import (
    counts_to_probs,
    total_variation_distance,
    hellinger_fidelity,
    classify_readability,
    compute_circuit_metric,
)

# ----------------------------------------------------------------
# Configuration
# ----------------------------------------------------------------
BACKENDS = [
    ('FakeManilaV2',    FakeManilaV2,    5),
    ('FakeLagosV2',     FakeLagosV2,     7),
    ('FakeGuadalupeV2', FakeGuadalupeV2, 16),
    ('FakeAlgiers',     FakeAlgiers,     27),
    ('FakeSherbrooke',  FakeSherbrooke,  127),
    ('FakeTorino',      FakeTorino,      133),
]

RESULTS_DIR = Path(__file__).parent / 'results'
RESULTS_DIR.mkdir(exist_ok=True)

# Optional filter: only process circuits with idx in [START_IDX, END_IDX].
# MERGE=1 merges new rows into existing noise_results.csv (replacing same idx).
START_IDX = int(os.environ.get('START_IDX', '0'))
END_IDX   = int(os.environ.get('END_IDX', '10000'))
MERGE     = os.environ.get('MERGE', '0') == '1'


def run_ideal(circuit, shots):
    """Run circuit on ideal (noiseless) AerSimulator."""
    sim = AerSimulator(method='automatic')
    result = sim.run(circuit, shots=shots).result()
    return result.get_counts(0)


def run_noisy(circuit, backend_cls, shots):
    """Transpile and run circuit on noisy AerSimulator from fake backend."""
    backend = backend_cls()
    transpiled = transpile(circuit, backend=backend, optimization_level=1)
    depth = transpiled.depth()
    cx_count = transpiled.count_ops().get('cx', 0)

    noisy_sim = AerSimulator.from_backend(backend)
    result = noisy_sim.run(transpiled, shots=shots).result()
    counts = result.get_counts(0)
    return counts, depth, cx_count


def main():
    print("Building circuits...")
    all_circuits = build_all_circuits()
    if START_IDX or END_IDX < 10000:
        all_circuits = [c for c in all_circuits if START_IDX <= c['idx'] <= END_IDX]
        print(f"Filtered to idx [{START_IDX}, {END_IDX}]: {len(all_circuits)} circuits")
    print(f"Built {len(all_circuits)} circuits\n")

    rows = []
    ideal_cache = {}  # idx -> ideal_probs

    # Phase 1: ideal simulations
    print("=" * 70)
    print("Phase 1: Ideal simulations")
    print("=" * 70)
    for c in all_circuits:
        idx = c['idx']
        shots = c['shots']
        print(f"  [{idx:2d}] {c['name']:30s} ({c['n_qubits']}Q, {shots} shots)...", end='', flush=True)
        t0 = time.time()
        ideal_counts = run_ideal(c['circuit'], shots)
        ideal_probs = counts_to_probs(ideal_counts, c['n_qubits'])
        ideal_cache[idx] = ideal_probs
        print(f" {time.time()-t0:.1f}s  top={sorted(ideal_probs.items(), key=lambda x:-x[1])[:3]}")

    # Phase 2: noisy simulations
    print("\n" + "=" * 70)
    print("Phase 2: Noisy simulations")
    print("=" * 70)
    for c in all_circuits:
        idx = c['idx']
        n_q = c['n_qubits']
        shots = c['shots']
        ideal_probs = ideal_cache[idx]

        for backend_name, backend_cls, backend_qubits in BACKENDS:
            if n_q > backend_qubits:
                continue

            print(f"  [{idx:2d}] {c['name']:30s} on {backend_name:20s}...", end='', flush=True)
            t0 = time.time()

            try:
                noisy_counts, tr_depth, tr_cx = run_noisy(c['circuit'], backend_cls, shots)
                noisy_probs = counts_to_probs(noisy_counts, n_q)

                tvd = total_variation_distance(ideal_probs, noisy_probs)
                hf = hellinger_fidelity(ideal_probs, noisy_probs)
                readable = classify_readability(hf, tvd)

                metric_name, metric_val = compute_circuit_metric(
                    c['category'], noisy_probs, ideal_probs, n_q)

                elapsed = time.time() - t0
                print(f" {elapsed:5.1f}s  TVD={tvd:.3f} HF={hf:.3f} [{readable}]"
                      f"  depth={tr_depth} cx={tr_cx}")

                rows.append({
                    'idx': idx,
                    'name': c['name'],
                    'n_qubits': n_q,
                    'shots': shots,
                    'category': c['category'],
                    'backend': backend_name,
                    'tvd': round(tvd, 4),
                    'hellinger_fidelity': round(hf, 4),
                    'circuit_metric_name': metric_name,
                    'circuit_metric_value': round(metric_val, 4) if metric_val is not None else '',
                    'readable': readable,
                    'transpiled_depth': tr_depth,
                    'transpiled_cx_count': tr_cx,
                })

            except Exception as e:
                elapsed = time.time() - t0
                print(f" {elapsed:5.1f}s  ERROR: {e}")
                rows.append({
                    'idx': idx, 'name': c['name'], 'n_qubits': n_q,
                    'shots': shots, 'category': c['category'],
                    'backend': backend_name, 'tvd': '', 'hellinger_fidelity': '',
                    'circuit_metric_name': '', 'circuit_metric_value': '',
                    'readable': 'ERROR', 'transpiled_depth': '', 'transpiled_cx_count': '',
                })

    # Write CSV (with optional merge into existing)
    csv_path = RESULTS_DIR / 'noise_results.csv'
    fieldnames = ['idx', 'name', 'n_qubits', 'shots', 'category', 'backend',
                  'tvd', 'hellinger_fidelity', 'circuit_metric_name',
                  'circuit_metric_value', 'readable', 'transpiled_depth',
                  'transpiled_cx_count']
    if MERGE and csv_path.exists():
        existing = []
        with open(csv_path) as f:
            reader = csv.DictReader(f)
            existing = list(reader)
        new_idxs = {str(r['idx']) for r in rows}
        merged = [e for e in existing if str(e['idx']) not in new_idxs] + [
            {k: str(v) for k, v in r.items()} for r in rows]
        merged.sort(key=lambda r: (int(r['idx']), r['backend']))
        rows = merged
        print(f"  (merged with existing — {len(rows)} total rows)")
    with open(csv_path, 'w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)
    print(f"\nCSV written to {csv_path} ({len(rows)} rows)")

    # Summary table
    backend_names = [b[0] for b in BACKENDS]
    circuit_names = [c['name'] for c in all_circuits]
    circuit_idxs = [c['idx'] for c in all_circuits]

    # Build lookup
    lookup = {}
    for r in rows:
        lookup[(r['idx'], r['backend'])] = r.get('readable', '-')

    summary_lines = []
    header = f"{'#':>3s} {'Circuit':30s} | " + " | ".join(f"{b:>16s}" for b in backend_names)
    summary_lines.append(header)
    summary_lines.append("-" * len(header))

    pass_count = 0
    total_count = 0
    for c in all_circuits:
        idx = c['idx']
        cells = []
        for bname in backend_names:
            val = lookup.get((idx, bname), '-')
            if val == '-':
                cells.append(f"{'—':>16s}")
            else:
                cells.append(f"{val:>16s}")
                total_count += 1
                if val == 'PASS':
                    pass_count += 1
        line = f"{idx:3d} {c['name']:30s} | " + " | ".join(cells)
        summary_lines.append(line)

    summary_lines.append("-" * len(header))
    summary_lines.append(f"PASS: {pass_count}/{total_count} "
                         f"({100*pass_count/total_count:.0f}%)" if total_count > 0 else "")

    summary_text = "\n".join(summary_lines)
    print(f"\n{summary_text}")

    if not MERGE:
        summary_path = RESULTS_DIR / 'summary_table.txt'
        with open(summary_path, 'w') as f:
            f.write(summary_text + '\n')
        print(f"\nSummary written to {summary_path}")
    else:
        print("\n(MERGE mode: summary_table.txt left untouched)")


if __name__ == '__main__':
    main()
