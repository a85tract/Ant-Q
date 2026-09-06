#!/usr/bin/env python3
"""rq3_stats.py -- RQ3 early-stop statistics: every paper circuit (<= 14 qubits) x six Qiskit fake backends x
several seeds, with the paper's stop rule (methodology.tex: 10 checkpoints; converged when BOTH |dTVD| <= 0.03 and
|dHF| <= 0.03 between consecutive checkpoints; unreadable when HF <= 0.4 and TVD >= 0.6; earliest stop at checkpoint 3
= 30 % of the shot budget). Reuses the QCE26 archive's circuits.py / metrics.py / make_checkpoints unchanged.

Per (circuit, backend, seed) row: ground-truth grade of the FULL noisy run (PASS / MARGINAL / FAIL, same thresholds as
the paper's Table noise_study), the stop checkpoint under the paper rule and under the archived code's TVD-only rule,
and whether the stop decision was correct (CORRECT / FALSE_POS on a PASS circuit / MISSED on a FAIL circuit).

    BACKEND=FakeAlgiers SEEDS=0-9 python rq3_stats.py        -> results/rq3/rq3_FakeAlgiers.csv
"""
import csv, os, sys, time
from collections import Counter
from pathlib import Path

import qiskit, qiskit_aer, qiskit_ibm_runtime
from qiskit import transpile
from qiskit_aer import AerSimulator
from rq3_common import load_circuits, exact_probs, REF, CIRCUITS, OUT_DIR as OUT
from metrics import total_variation_distance, hellinger_fidelity, classify_readability
from run_early_stop import BACKEND_MAP, make_checkpoints, FAIL_HF, FAIL_TVD, MIN_CHECKPOINT_IDX

EPS = 0.03                      # epsilon_TVD = epsilon_HF (methodology.tex)
MAX_Q = 14                      # the paper's benchmark: circuits with more than 14 qubits are excluded


def parse_seeds(s):
    a, _, b = s.partition('-')
    return list(range(int(a), int(b) + 1)) if b else [int(x) for x in s.split(',')]


def stop_points(memory, ref_probs, checkpoints):
    """(stop_cp_paper, stop_cp_tvd_only, per-checkpoint rows); checkpoints are 1-based in the output."""
    prev = None; rows = []; stop_paper = stop_tvd = None
    for i, n in enumerate(checkpoints):
        c = Counter(memory[:n]); p = {k: v / n for k, v in c.items()}
        tvd = total_variation_distance(p, ref_probs); hf = hellinger_fidelity(p, ref_probs)
        d_tvd = abs(tvd - prev[0]) if prev else 1.0; d_hf = abs(hf - prev[1]) if prev else 1.0
        fail_zone = hf <= FAIL_HF and tvd >= FAIL_TVD
        conv_paper = d_tvd <= EPS and d_hf <= EPS and i >= MIN_CHECKPOINT_IDX
        conv_tvd = d_tvd < EPS and i >= MIN_CHECKPOINT_IDX          # archived run_early_stop.py rule (TVD only)
        if stop_paper is None and conv_paper and fail_zone: stop_paper = i + 1
        if stop_tvd is None and conv_tvd and fail_zone: stop_tvd = i + 1
        rows.append((i + 1, n, round(tvd, 4), round(hf, 4), round(d_tvd, 4), round(d_hf, 4)))
        prev = (tvd, hf)
    return stop_paper, stop_tvd, rows


def main():
    name = os.environ.get('BACKEND', 'FakeAlgiers'); seeds = parse_seeds(os.environ.get('SEEDS', '0-9'))
    idx_filter = [int(x) for x in os.environ.get('IDX_LIST', '').split(',') if x.strip()]
    backend = BACKEND_MAP[name](); noisy = AerSimulator.from_backend(backend); ideal = AerSimulator()
    circuits = [c for c in load_circuits() if (not idx_filter or c['idx'] in idx_filter)]
    OUT.mkdir(parents=True, exist_ok=True)
    suffix = os.environ.get('SUFFIX', '')
    fsum = open(OUT / f'rq3_{name}{suffix}.csv', 'w', newline=''); fcp = open(OUT / f'rq3_{name}{suffix}_checkpoints.csv', 'w', newline='')
    ws = csv.writer(fsum); wc = csv.writer(fcp)
    ws.writerow(['idx', 'name', 'n_qubits', 'backend', 'backend_qubits', 'seed', 'shots', 'ref_shots', 'final_tvd', 'final_hf', 'grade',
                 'stop_cp_paper', 'stop_shots_paper', 'stop_correct_paper', 'stop_cp_tvd_only', 'stop_correct_tvd_only',
                 'transpiled_depth', 'transpiled_2q', 'sim_s', 'qiskit', 'qiskit_aer', 'qiskit_ibm_runtime'])
    wc.writerow(['idx', 'backend', 'seed', 'checkpoint', 'shots', 'tvd', 'hf', 'd_tvd', 'd_hf'])
    vers = (qiskit.__version__, qiskit_aer.__version__, qiskit_ibm_runtime.__version__)
    for c in circuits:
        idx, nq, shots = c['idx'], c['n_qubits'], c['shots']
        if nq > backend.num_qubits:
            for seed in seeds:
                ws.writerow([idx, c['name'], nq, name, backend.num_qubits, seed, shots, '', '', '', 'SKIP', '', '', '', '', '', '', '', 0, *vers])
            fsum.flush(); continue
        cps = make_checkpoints(shots); ref_shots = max(shots // 10, 100)
        for seed in seeds:
            t0 = time.time()
            qc_t = transpile(c['circuit'], backend=backend, optimization_level=1, seed_transpiler=seed)
            if REF == 'exact':                      # the paper's stated reference: the noiseless distribution itself
                ref_p = exact_probs(c['circuit'])
            else:                                   # the archived code's reference: a 10 % noiseless sample
                ref_mem = ideal.run(c['circuit'], shots=ref_shots, memory=True, seed_simulator=1000 + seed).result().get_memory(0)
                ref_p = {k: v / ref_shots for k, v in Counter(ref_mem).items()}
            noisy_mem = noisy.run(qc_t, shots=shots, memory=True, seed_simulator=seed).result().get_memory(0)
            ideal_mem = ideal.run(c['circuit'], shots=shots, memory=True, seed_simulator=2000 + seed).result().get_memory(0)
            p_noisy = {k: v / shots for k, v in Counter(noisy_mem).items()}; p_ideal = {k: v / shots for k, v in Counter(ideal_mem).items()}
            tvd = total_variation_distance(p_ideal, p_noisy); hf = hellinger_fidelity(p_ideal, p_noisy); grade = classify_readability(hf, tvd)
            sp, st, rows = stop_points(noisy_mem, ref_p, cps)

            def correct(stop):
                if stop: return 'CORRECT' if grade in ('FAIL', 'MARGINAL') else 'FALSE_POS'
                return 'MISSED' if grade == 'FAIL' else 'CORRECT'
            n2q = sum(1 for inst in qc_t.data if inst.operation.num_qubits == 2)
            ws.writerow([idx, c['name'], nq, name, backend.num_qubits, seed, shots, ref_shots, round(tvd, 4), round(hf, 4), grade,
                         sp or '', cps[sp - 1] if sp else '', correct(sp), st or '', correct(st),
                         qc_t.depth(), n2q, round(time.time() - t0, 1), *vers])
            for r in rows: wc.writerow([idx, name, seed, *r])
            fsum.flush(); fcp.flush()
            print(f'[{name}/{CIRCUITS}/{REF}] idx {idx:2d} seed {seed} {grade:8s} tvd={tvd:.3f} hf={hf:.3f} stop_paper={sp} stop_tvd={st} {time.time() - t0:.1f}s', flush=True)


if __name__ == '__main__':
    main()
