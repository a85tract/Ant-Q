"""
metrics.py — Readability metrics for noisy quantum circuit evaluation.

Universal metrics:
  - Total Variation Distance (TVD): 0 = identical, 1 = completely different
  - Hellinger Fidelity: 1 = identical, 0 = orthogonal

Circuit-specific metrics:
  - GHZ visibility: P(00...0) + P(11...1)
  - Success probability: P(target bitstring)
  - Grover amplification: P(marked) / P(uniform)
  - Heavy output probability: fraction of outputs above median ideal prob
"""

import math
from typing import Optional


def counts_to_probs(counts: dict, n_qubits: int) -> dict:
    """Normalize counts dict to probability dict over all 2^n bitstrings."""
    total = sum(counts.values())
    if total == 0:
        return {}
    probs = {}
    for bitstring, count in counts.items():
        probs[bitstring] = count / total
    return probs


def total_variation_distance(p: dict, q: dict) -> float:
    """TVD = 0.5 * sum |p(x) - q(x)|. Range [0, 1]."""
    all_keys = set(p.keys()) | set(q.keys())
    return 0.5 * sum(abs(p.get(k, 0.0) - q.get(k, 0.0)) for k in all_keys)


def hellinger_fidelity(p: dict, q: dict) -> float:
    """Hellinger fidelity = (sum sqrt(p(x)*q(x)))^2. Range [0, 1]."""
    all_keys = set(p.keys()) | set(q.keys())
    bc = sum(math.sqrt(p.get(k, 0.0) * q.get(k, 0.0)) for k in all_keys)
    return bc * bc


def ghz_visibility(probs: dict, n_qubits: int) -> float:
    """P(00...0) + P(11...1) for GHZ/Bell states. Ideal = 1.0."""
    zero_str = '0' * n_qubits
    one_str = '1' * n_qubits
    return probs.get(zero_str, 0.0) + probs.get(one_str, 0.0)


def success_probability(probs: dict, target: str) -> float:
    """P(target bitstring). Ideal = 1.0 for deterministic algorithms."""
    return probs.get(target, 0.0)


def grover_amplification(probs: dict, marked: str, n_qubits: int) -> float:
    """P(marked) / P(uniform). Uniform = 1/2^n. Returns ratio (ideal > 1)."""
    uniform = 1.0 / (2 ** n_qubits)
    p_marked = probs.get(marked, 0.0)
    return p_marked / uniform if uniform > 0 else 0.0


def heavy_output_probability(probs: dict, ideal_probs: dict) -> float:
    """Fraction of sampled outputs with ideal probability > median.
    Used for Quantum Volume. Ideal > 2/3."""
    if not ideal_probs:
        return 0.0
    ideal_vals = sorted(ideal_probs.values())
    median = ideal_vals[len(ideal_vals) // 2]
    heavy_set = {k for k, v in ideal_probs.items() if v > median}
    return sum(probs.get(k, 0.0) for k in heavy_set)


def classify_readability(hellinger: float, tvd: float) -> str:
    """Classify as PASS / MARGINAL / FAIL based on Hellinger fidelity and TVD."""
    if hellinger > 0.7 and tvd < 0.3:
        return 'PASS'
    elif hellinger > 0.4 and tvd < 0.6:
        return 'MARGINAL'
    else:
        return 'FAIL'


def compute_circuit_metric(category: str, noisy_probs: dict, ideal_probs: dict,
                           n_qubits: int) -> tuple[str, Optional[float]]:
    """Compute the circuit-specific metric based on category.

    Returns (metric_name, metric_value).
    """
    if category == 'ghz':
        return ('ghz_visibility', ghz_visibility(noisy_probs, n_qubits))

    elif category == 'query':
        # Deutsch-Jozsa / Bernstein-Vazirani: target = highest-prob ideal bitstring
        if ideal_probs:
            target = max(ideal_probs, key=ideal_probs.get)
            return ('success_prob', success_probability(noisy_probs, target))
        return ('success_prob', None)

    elif category == 'grover':
        # Marked state = highest-prob ideal bitstring
        if ideal_probs:
            marked = max(ideal_probs, key=ideal_probs.get)
            return ('grover_amplification', grover_amplification(noisy_probs, marked, n_qubits))
        return ('grover_amplification', None)

    elif category == 'qv':
        return ('heavy_output_prob', heavy_output_probability(noisy_probs, ideal_probs))

    elif category == 'shor':
        # For Shor: success = probability of top-3 ideal outcomes (period peaks)
        if ideal_probs:
            top3 = sorted(ideal_probs.items(), key=lambda x: -x[1])[:3]
            period_prob = sum(noisy_probs.get(k, 0.0) for k, _ in top3)
            return ('period_success', period_prob)
        return ('period_success', None)

    else:
        # vqe, qaoa, qml, teleport, qft: no circuit-specific metric beyond TVD/Hellinger
        return ('none', None)
