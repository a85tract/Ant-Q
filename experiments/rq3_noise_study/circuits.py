"""circuits.py -- import shim for the first-study scripts (run_noise_exp.py, run_early_stop.py): the circuits come from
benchmark/circuits_qiskit.py with the original (v1) parameters, which is what those scripts were run with."""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent / 'benchmark'))
from circuits_qiskit import build_all_circuits as _build


def build_all_circuits():
    return _build(params='v1')
