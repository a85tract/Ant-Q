#!/usr/bin/env python3
"""
run_early_stop.py — Early noise detection via running TVD/HF vs ideal reference.

Strategy (two-pass):
  1. Run a small ideal simulation to get a reference distribution.
  2. Run the full noisy experiment with each circuit's ORIGINAL shot count.
     At each checkpoint (every 1/10 of original shots), compute TVD and HF
     of the accumulated noisy distribution vs the ideal reference.
  3. When both TVD and HF have CONVERGED (stopped changing) AND their values
     indicate FAIL (HF < 0.4, TVD > 0.6), trigger early stop.

Checkpoints: 10 evenly spaced at shots/10, shots*2/10, ..., shots.
Savings are relative to each circuit's original shot count.
"""

import csv
import os
import time
from collections import Counter
from pathlib import Path

from qiskit import transpile
from qiskit_aer import AerSimulator
from qiskit_ibm_runtime.fake_provider import (
    FakeAlgiers, FakeSherbrooke, FakeTorino, FakeGuadalupeV2, FakeLagosV2, FakeManilaV2)
BACKEND_MAP = {
    'FakeAlgiers': FakeAlgiers, 'FakeSherbrooke': FakeSherbrooke,
    'FakeTorino': FakeTorino, 'FakeGuadalupeV2': FakeGuadalupeV2,
    'FakeLagosV2': FakeLagosV2, 'FakeManilaV2': FakeManilaV2,
}

from circuits import build_all_circuits
from metrics import (counts_to_probs, total_variation_distance,
                     hellinger_fidelity, classify_readability)

RESULTS_DIR = Path(__file__).resolve().parent.parent.parent / 'results' / 'rq3_v0'   # re-runs of the first study go here; the archived outputs are in results/rq3_v0_archive/
RESULTS_DIR.mkdir(exist_ok=True)

# Convergence: TVD between consecutive checkpoints < threshold
CONVERGENCE_DTVD = 0.03
# Failure: HF vs ideal reference below this AND TVD above this
FAIL_HF = 0.4
FAIL_TVD = 0.6
# Minimum checkpoint index before stopping (at least 2 checkpoints = 2/10 of shots)
MIN_CHECKPOINT_IDX = 2

# Optional filter: only process circuits with idx in IDX_LIST (comma-separated).
# MERGE=1 merges into existing CSVs (replacing same idx).
IDX_LIST = [int(x) for x in os.environ.get('IDX_LIST', '').split(',') if x.strip()]
MERGE    = os.environ.get('MERGE', '0') == '1'
BACKEND_NAME = os.environ.get('BACKEND', 'FakeAlgiers')


def make_checkpoints(total_shots):
    """Generate 10 evenly spaced checkpoints at 1/10, 2/10, ..., 10/10 of total_shots."""
    step = max(total_shots // 10, 1)
    cps = [step * i for i in range(1, 11)]
    # Ensure the last checkpoint equals total_shots
    cps[-1] = total_shots
    return cps


def run_with_memory(circuit, shots, sim):
    """Run circuit and return per-shot bitstring list."""
    result = sim.run(circuit, shots=shots, memory=True).result()
    return result.get_memory(0)


def analyze_vs_reference(memory, ref_probs, n_qubits, checkpoints):
    """At each checkpoint, compute TVD and HF vs ideal reference distribution."""
    prev_tvd = None
    results = []

    for cp_idx, cp_shots in enumerate(checkpoints):
        if cp_shots > len(memory):
            break

        counts = Counter(memory[:cp_shots])
        probs = {k: v / cp_shots for k, v in counts.items()}

        tvd = total_variation_distance(probs, ref_probs)
        hf = hellinger_fidelity(probs, ref_probs)

        # Convergence: how much did TVD change from previous checkpoint?
        delta_tvd = abs(tvd - prev_tvd) if prev_tvd is not None else 1.0

        # Stop condition: converged AND in fail zone AND past minimum checkpoints
        converged = delta_tvd < CONVERGENCE_DTVD and cp_idx >= MIN_CHECKPOINT_IDX
        in_fail_zone = hf < FAIL_HF and tvd > FAIL_TVD
        should_stop = converged and in_fail_zone

        results.append({
            'shots': cp_shots,
            'checkpoint_frac': round(cp_shots / checkpoints[-1], 2),
            'n_distinct': len(counts),
            'tvd_vs_ideal': round(tvd, 4),
            'hf_vs_ideal': round(hf, 4),
            'delta_tvd': round(delta_tvd, 4),
            'converged': converged,
            'should_stop': should_stop,
        })

        prev_tvd = tvd

    return results


def find_stop_point(checkpoints):
    """Find earliest checkpoint where should_stop is True."""
    for cp in checkpoints:
        if cp['should_stop']:
            return cp['shots']
    return None


def main():
    print("Building circuits...")
    all_circuits = build_all_circuits()
    if IDX_LIST:
        all_circuits = [c for c in all_circuits if c['idx'] in IDX_LIST]
        print(f"Filtered to idx {IDX_LIST}: {len(all_circuits)} circuits")
    print(f"Built {len(all_circuits)} circuits")
    print(f"Checkpoints: 10 per circuit at 1/10 intervals of original shot count")
    print(f"Stop criteria: converged (dTVD < {CONVERGENCE_DTVD}, min {MIN_CHECKPOINT_IDX+1} checkpoints) AND "
          f"fail zone (HF < {FAIL_HF}, TVD > {FAIL_TVD})\n")

    backend = BACKEND_MAP[BACKEND_NAME]()
    noisy_sim = AerSimulator.from_backend(backend)
    ideal_sim = AerSimulator(method='automatic')
    print(f"Noisy backend: {BACKEND_NAME} ({backend.num_qubits}Q)\n")

    detail_rows = []
    summary_rows = []

    for c in all_circuits:
        idx = c['idx']
        n_q = c['n_qubits']
        name = c['name']
        original_shots = c['shots']

        if n_q > backend.num_qubits:
            print(f"  [{idx:2d}] {name:30s} — SKIP ({n_q}Q > {backend.num_qubits}Q)")
            summary_rows.append({
                'idx': idx, 'name': name, 'n_qubits': n_q,
                'original_shots': original_shots,
                'final_tvd': '', 'final_hf': '', 'final_grade': 'SKIP',
                'stop_at': '', 'shots_saved_pct': '', 'stop_correct': '',
            })
            print()
            continue

        qc = c['circuit']
        qc_transpiled = transpile(qc, backend=backend, optimization_level=1)
        checkpoints = make_checkpoints(original_shots)

        # Ideal reference: use 1/10 of original shots (min 100)
        ref_shots = max(original_shots // 10, 100)

        print(f"  [{idx:2d}] {name:30s} ({n_q}Q, {original_shots} shots, "
              f"ref={ref_shots}, step={checkpoints[0]})")

        # Step 1: Ideal reference
        t0 = time.time()
        ref_mem = run_with_memory(qc, ref_shots, ideal_sim)
        ref_probs = {k: v / ref_shots for k, v in Counter(ref_mem).items()}
        t_ref = time.time() - t0

        # Step 2: Full noisy run with original shot count
        t0 = time.time()
        noisy_mem = run_with_memory(qc_transpiled, original_shots, noisy_sim)
        noisy_cps = analyze_vs_reference(noisy_mem, ref_probs, n_q, checkpoints)
        t_noisy = time.time() - t0

        # Ground-truth: compare full noisy vs full ideal
        ideal_mem_full = run_with_memory(qc, original_shots, ideal_sim)
        ideal_probs_full = {k: v / original_shots for k, v in Counter(ideal_mem_full).items()}
        noisy_probs_full = {k: v / original_shots for k, v in Counter(noisy_mem).items()}
        final_tvd = total_variation_distance(ideal_probs_full, noisy_probs_full)
        final_hf = hellinger_fidelity(ideal_probs_full, noisy_probs_full)
        final_grade = classify_readability(final_hf, final_tvd)

        # Find early stop
        stop_at = find_stop_point(noisy_cps)
        shots_saved = (original_shots - stop_at) / original_shots * 100 if stop_at else 0

        # Verify correctness
        if stop_at:
            if final_grade in ('FAIL', 'MARGINAL'):
                stop_correct = 'CORRECT'
            else:
                stop_correct = 'FALSE_POS'
        else:
            if final_grade == 'FAIL':
                stop_correct = 'MISSED'
            else:
                stop_correct = 'CORRECT'

        # Print
        print(f"        ref={t_ref:.1f}s noisy={t_noisy:.1f}s  "
              f"ground-truth: TVD={final_tvd:.3f} HF={final_hf:.3f} [{final_grade}]")
        print(f"        Checkpoints (vs ideal ref): ", end='')
        for cp in noisy_cps:
            marker = '<<<' if stop_at and cp['shots'] == stop_at else '   '
            frac = cp['checkpoint_frac']
            print(f"[{frac:.1f}: TVD={cp['tvd_vs_ideal']:.2f} "
                  f"HF={cp['hf_vs_ideal']:.2f} d={cp['delta_tvd']:.3f}{marker}]", end=' ')
        print()
        if stop_at:
            print(f"        >>> STOP at {stop_at}/{original_shots} shots "
                  f"({stop_at/original_shots:.0%} of budget) — saves {shots_saved:.1f}%"
                  f" [{stop_correct}]")
        else:
            print(f"        >>> Run all {original_shots} shots [{stop_correct}]")
        print()

        # Save rows
        for cp in noisy_cps:
            detail_rows.append({
                'idx': idx, 'name': name, 'n_qubits': n_q,
                'original_shots': original_shots, **cp,
            })

        summary_rows.append({
            'idx': idx, 'name': name, 'n_qubits': n_q,
            'original_shots': original_shots,
            'final_tvd': round(final_tvd, 4), 'final_hf': round(final_hf, 4),
            'final_grade': final_grade,
            'stop_at': stop_at if stop_at else '',
            'shots_saved_pct': round(shots_saved, 1) if stop_at else 0,
            'stop_correct': stop_correct,
        })

    # Write CSVs (with optional merge into existing)
    def merge_csv(path, new_rows, fieldnames):
        if MERGE and path.exists():
            with open(path) as f:
                existing = list(csv.DictReader(f))
            new_idxs = {str(r['idx']) for r in new_rows}
            kept = [e for e in existing if str(e['idx']) not in new_idxs]
            new_str = [{k: str(v) if v != '' else '' for k, v in r.items()} for r in new_rows]
            merged = kept + new_str
            merged.sort(key=lambda r: int(r['idx']))
            new_rows = merged
            print(f"  (merged {path.name} — {len(new_rows)} rows total)")
        with open(path, 'w', newline='') as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(new_rows)

    detail_path = RESULTS_DIR / 'early_stop_checkpoints.csv'
    merge_csv(detail_path, detail_rows, [
        'idx', 'name', 'n_qubits', 'original_shots', 'shots', 'checkpoint_frac',
        'n_distinct', 'tvd_vs_ideal', 'hf_vs_ideal', 'delta_tvd',
        'converged', 'should_stop'])

    summary_path = RESULTS_DIR / 'early_stop_summary.csv'
    merge_csv(summary_path, summary_rows, [
        'idx', 'name', 'n_qubits', 'original_shots',
        'final_tvd', 'final_hf', 'final_grade',
        'stop_at', 'shots_saved_pct', 'stop_correct'])

    # Summary table
    print(f"\n{'='*110}")
    print(f"EARLY STOP SUMMARY (FakeAlgiers, per-circuit shot counts, 1/10 checkpoints)")
    print(f"{'='*110}")
    print(f"{'#':>3s} {'Circuit':30s} {'Q':>2s} {'Shots':>6s} {'TVD':>6s} {'HF':>6s} "
          f"{'Grade':>8s} {'Stop@':>7s} {'Budget':>7s} {'Saved':>6s} {'Check':>10s}")
    print('-' * 110)
    for s in summary_rows:
        stop_str = str(s['stop_at']) if s['stop_at'] else '—'
        saved_str = f"{s['shots_saved_pct']}%" if s.get('shots_saved_pct') else '—'
        budget_str = (f"{int(s['stop_at'])/s['original_shots']:.0%}"
                      if s['stop_at'] else '100%')
        tvd_str = str(s.get('final_tvd', '—'))
        hf_str = str(s.get('final_hf', '—'))
        print(f"{s['idx']:3d} {s['name']:30s} {s['n_qubits']:2d} "
              f"{s['original_shots']:6d} {tvd_str:>6s} {hf_str:>6s} "
              f"{s['final_grade']:>8s} {stop_str:>7s} {budget_str:>7s} "
              f"{saved_str:>6s} {s['stop_correct']:>10s}")

    # Accuracy
    correct = sum(1 for s in summary_rows if s['stop_correct'] == 'CORRECT')
    false_pos = sum(1 for s in summary_rows if s['stop_correct'] == 'FALSE_POS')
    missed = sum(1 for s in summary_rows if s['stop_correct'] == 'MISSED')
    skip = sum(1 for s in summary_rows if s['final_grade'] == 'SKIP')
    total = len(summary_rows) - skip
    print(f"\nAccuracy: {correct}/{total} correct, "
          f"{false_pos} false positives, {missed} missed failures")
    print(f"Files: {detail_path}, {summary_path}")


if __name__ == '__main__':
    main()
