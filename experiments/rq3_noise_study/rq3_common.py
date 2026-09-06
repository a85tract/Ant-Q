"""rq3_common.py -- shared switches for the RQ3 (noise / early-stop simulation) scripts.
CIRCUITS=v1 : the original placeholder parameters of the two 14-qubit templates (uniform ideal output; first study)
CIRCUITS=v2 : the re-parameterized templates (default since 2026-09-04) -- both from benchmark/circuits_qiskit.py
REF=sample  : the archived rule's reference = a noiseless sample of 10 % of the budget
REF=exact   : reference = the exact noiseless distribution (statevector), the paper's stated method (default)
OUT_DIR     : <repo>/results/rq3 (v1 + sample) or <repo>/results/rq3_v2 (anything else)"""
import os, sys
from pathlib import Path
REPO = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(REPO / 'benchmark'))
sys.path.insert(0, str(Path(__file__).resolve().parent))
CIRCUITS = os.environ.get('CIRCUITS', 'v2')
REF = os.environ.get('REF', 'exact')
OUT_DIR = REPO / 'results' / ('rq3' if (CIRCUITS, REF) == ('v1', 'sample') else 'rq3_v2')


def load_circuits():
    from circuits_qiskit import build_all_circuits
    return build_all_circuits(params=CIRCUITS)


def exact_probs(qc):
    """Exact noiseless output distribution as {bitstring: p}, same bit order as Aer's get_memory (all 20 circuits
    measure every qubit with the identity qubit->clbit map)."""
    from qiskit.quantum_info import Statevector
    return Statevector(qc.remove_final_measurements(inplace=False)).probabilities_dict()
