"""Shared helpers for the DDR-batch board tests (T-series acceptance suite).

Prereqs: the board running an Ant-Q (DDR command-streaming) image with the qubic service up, reachable at
RPC_HOST/RPC_PORT (recampaign_env.sh sets both); GW_BUILD = the gateware build dir of the loaded image.
"""
import sys, os
GW_BUILD = os.environ['GW_BUILD']        # gateware build dir of the loaded image (bram.json, channel_config.json)
import numpy as np
import qubic.toolchain as tc
import qubitconfig.qchip as qc
from distproc.hwconfig import FPGAConfig, load_channel_configs

_cc = load_channel_configs(GW_BUILD + '/gensrc/channel_config.json')
_fpga = FPGAConfig()
NUM_CH = int(os.environ.get('NUM_CH') or len([k for k in _cc if str(k).endswith('.rdlo')]))   # 8_2: 8, 14_2: 14
ALL = [f'qubit_{i}' for i in range(NUM_CH)]
from qubic.rfsoc.bram import BramCfgs as _BramCfgs
ACCBUF0_BYTES = 4 * _BramCfgs(GW_BUILD + '/gensrc/bram.json')['qubit_accbuf0'].address   # acc_read base (8_2 0x120000, 14_2 0x1E0000)
QUBIT_FREQS = [4_460_029_188 + i * 50_000_000 for i in range(NUM_CH)]
READ_FREQS = [6_554_327_471 + i * 10_000_000 for i in range(NUM_CH)]
QG = {q: {f'{q}.qdrv', f'{q}.rdrv', f'{q}.rdlo'} for q in ALL}
PG = [('{qubit}.qdrv', '{qubit}.rdrv', '{qubit}.rdlo')]


def build_qchip(amp=0.02, ramp_fraction=0.25, freq_off=0):
    qd, gd = {}, {}
    for i, q in enumerate(ALL):
        qd[q] = {'freq': QUBIT_FREQS[i], 'readfreq': READ_FREQS[i] + freq_off}
        gd[f'{q}read'] = [
            {'freq': f'{q}.readfreq', 'phase': 0, 'dest': f'{q}.rdrv', 'twidth': 0.9e-6,
             't0': 0, 'amp': amp, 'env': [{'env_func': 'cos_edge_square',
                                           'paradict': {'ramp_fraction': ramp_fraction}}]},
            {'freq': f'{q}.readfreq', 'phase': 0, 'dest': f'{q}.rdlo', 'twidth': 0.9e-6,
             't0': 6e-7, 'amp': 1.0, 'env': [{'env_func': 'square',
                                              'paradict': {'phase': 0.0, 'amplitude': 1.0}}]}]
    return qc.QChip({'Qubits': qd, 'Gates': gd})


def _compile(program, qchip):
    comp = tc.run_compile_stage(program, _fpga, qchip, compiler_flags={'schedule': True},
                                qubit_grouping=QG, proc_grouping=PG)
    return tc.run_assemble_stage(comp, _cc)


def compile_readout(loops=1, amp=0.02, ramp_fraction=0.25, freq_off=0, delay_us=0.0):
    """All-8-qubit readout circuit; loops = reads per shot (set into metadata).
    delay_us is placed BEFORE the reads (delay-after-reads is a runtime no-op)."""
    qchip = build_qchip(amp, ramp_fraction, freq_off)
    body = []
    if delay_us > 0:
        body.append({'name': 'delay', 't': delay_us * 1e-6, 'scope': ALL})
    body += [{'name': 'read', 'qubit': [q]} for q in ALL]
    body.append({'name': 'alu', 'op': 'add', 'lhs': 1, 'rhs': 'i', 'out': 'i'})
    program = [{'name': 'declare', 'var': 'i', 'dtype': 'int', 'scope': ALL},
               {'name': 'set_var', 'var': 'i', 'value': 0},
               {'name': 'loop', 'cond_lhs': loops, 'cond_rhs': 'i',
                'alu_cond': 'ge', 'scope': ALL, 'body': body}]
    exe = _compile(program, qchip)
    for ch, rc in exe.result_channels.items():
        if ch.endswith('.rdlo'):
            rc.reads_per_shot = loops
    return exe


compile_readout_env = compile_readout       # legacy alias (env-shape variants)


def runner(port=None):
    from qubic.rpc_client import CircuitRunnerClient
    host = os.environ.get('RPC_HOST', 'localhost'); port = port or int(os.environ.get('RPC_PORT', '9095'))
    return CircuitRunnerClient(host, port, ddr_cmd=True, num_ch=NUM_CH)


def check_batch(results, n_shots_list, loops_list, quiet=False):
    assert len(results) == len(n_shots_list)
    for i, res in enumerate(results):
        assert len(res) == NUM_CH, f'circuit {i}: {len(res)} channels'
        for ch, s11 in res.items():
            arr = np.asarray(s11._array if hasattr(s11, '_array') else s11)
            exp = (n_shots_list[i], loops_list[i])
            assert arr.shape == exp, f'circuit {i} {ch}: {arr.shape} != {exp}'
            assert np.all(arr != 0), f'circuit {i} {ch}: zero IQ values'
    if not quiet:
        print('STRUCT OK:', list(zip(n_shots_list, loops_list)))
