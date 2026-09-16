"""Plan D3a check (a): the write list StdServerClient sends equals, word for word and in order, the MMIO
write sequence the Python path performs for the measured circuit
(run.py load_executable(zero=True, load_commands=True, load_freqs=False, load_envs=False)).
Runs on the host against a captured mock pl_driver — no board.
Lives in the artifact (experiments/board), not in the QubiC software repository. Needs the software submodule
(qubic package + test/ddr_batch/integ_test_lib.py) on PYTHONPATH.
Run: PATH=~/anaconda3/envs/qubic_clean/bin:$PATH PYTHONPATH=<repo>/software pytest -q experiments/board/test_std_client.py
"""
import os, sys, glob
import numpy as np
_HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, _HERE)                                                         # std_client.py
sys.path.insert(0, os.path.join(_HERE, '..', '..', 'software', 'test', 'ddr_batch'))   # integ_test_lib.py


class _CaptureDriver:
    def __init__(self, bits_dir):
        from qubic.rfsoc.bram import BramCfgs
        self.bram_cfgs = BramCfgs(os.path.join(bits_dir, 'bram.json'))
        self.writes = []            # (name, bytes) in call order == MMIO word-store order
        self.regs = []

    def get_program_memories(self, core_inds=None):
        return [m for m in self.bram_cfgs.keys() if 'command' in m]

    def write_mem_buf(self, name, data, start_addr=0):
        self.writes.append((name, bytes(data)))

    def write_reg(self, name, value):
        self.regs.append((name, int(value)))

    def set_default_regs(self):
        pass


def test_write_list_matches_python_path():
    from integ_test_lib import compile_readout, GW_BUILD
    from qubic.run import CircuitRunner
    from std_client import StdServerClient
    bits = GW_BUILD + '/gensrc'
    exe = compile_readout(1)
    drv = _CaptureDriver(bits)
    CircuitRunner(drv).load_executable(exe, load_commands=True, load_freqs=False, load_envs=False, zero=True)
    py_seq = [(drv.bram_cfgs[n].address, np.frombuffer(d, dtype='<u4')) for n, d in drv.writes]
    assert drv.regs == []
    cl = StdServerClient.__new__(StdServerClient)
    cl.bram = drv.bram_cfgs
    cl.command_mems = sorted((m for m in cl.bram if 'command' in m), key=lambda m: int(''.join(c for c in m if c.isdigit())))
    c_seq = cl.write_list(exe.get_binaries_fromboard())
    assert len(py_seq) == len(c_seq), (len(py_seq), len(c_seq))
    for (a1, w1), (a2, w2) in zip(py_seq, c_seq):
        assert a1 == a2
        assert np.array_equal(w1, w2)
    assert sum(len(w) for _, w in c_seq) > 8 * 4        # zero programs + at least one real command memory
