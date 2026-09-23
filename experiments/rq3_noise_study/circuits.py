"""circuits.py -- import shim for run_early_stop.py (the first study; rq3_stats.py imports its checkpoint schedule
and thresholds): the circuits come from benchmark/circuits_qiskit.py with the original (v1) parameters."""
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent / 'benchmark'))
from circuits_qiskit import build_all_circuits as _build


def build_all_circuits():
    return _build(params='v1')
