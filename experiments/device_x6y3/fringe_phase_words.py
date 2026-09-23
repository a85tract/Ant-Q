#!/usr/bin/env python3
"""Host-only check (no board, no qubit): decode the pulse commands of the fringe program X90 - 100 ns - Z(phi) - X90 - read as the
two command paths compile it -- (B) the Ant-Q c3 path: the hardware-loop program via Programs.phys(); (A) the stock path: the
loop BODY recompiled as a one-shot circuit, exactly as antq_runner.run_rpc does -- and compare the carrier-phase words of the two
X90 pulses (a frame difference between the paths would show up here, e.g. one of the X90 gate's two virtual-Z corrections of
0.0206 rad). usage: GW=<8_2 build dir> NUM_CH=8 AQT_QUBIT=Q5 ANTQ_PHYS_MODULE=... ANTQ_QCHIP=... ANTQ_QCHIP_PATCH=... python fringe_phase_words.py [idx ...]"""
import os, sys, os, copy
import numpy as np
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'board'))
import antq_runner
from distproc.command_gen import opcodes, pulse_field_pos as POS, pulse_field_widths as W
GW = os.environ['GW']; NCH = int(os.environ.get('NUM_CH', '8')); Q = os.environ.get('AQT_QUBIT', 'Q5'); core = int(Q[1:])
P = antq_runner.Programs(GW, NCH, pool_tables=False); P._real_init()
mod = P._load_phys_module(); P._phys_circuits = {c['idx']: c for c in mod.build_circuits()}
OPN = {v: k for k, v in opcodes.items()}
def decode(exe):
    b = {k: bytes(d.data if hasattr(d, 'data') else d) for k, d in exe.get_binaries_fromboard().items()}
    name = [k for k in b if 'command' in k and k.endswith(str(core))]
    assert name, list(b)
    data = b[name[0]]; out = []
    for i in range(0, len(data), 16):
        w = int.from_bytes(data[i:i + 16], 'little'); op = w >> 123
        if op == 0 and w == 0: continue
        rec = dict(n=i // 16, op=OPN.get(op, op))
        if op in (opcodes['pulse_write'], opcodes['pulse_write_trig']):
            f = lambda k: (w >> POS[k]) & ((1 << W[k]) - 1)
            en = lambda k: (w >> (POS[k] + W[k] + (0 if k == 'cfg' else 1))) & 1        # immediate-enable bit (command_gen.pulse_cmd: value + 2**(width+1))
            regmux = lambda k: (w >> (POS[k] + W[k])) & 0b11                              # 0b11 = register-addressed field
            rec.update(t_clk=f('cmd_time'), freq=f('freq') if en('freq') else None, phase_word=f('phase') if en('phase') else None,
                       amp=f('amp') if en('amp') else None, env=f('env_word') if en('env_word') else None, cfg=f('cfg'),
                       phase_reg=(regmux('phase') == 0b11), freq_reg=(regmux('freq') == 0b11), raw=hex(w))
            if rec['phase_word'] is not None:
                ph = rec['phase_word'] / 2 ** W['phase'] * 2 * np.pi; rec['phase_rad'] = float((ph + np.pi) % (2 * np.pi) - np.pi)
        out.append(rec)
    return name[0], out
def stock_compile(idx):
    """the run_rpc recompilation: loop body as a one-shot circuit, trailing delays rotated to the front"""
    c = P._phys_circuits[idx]; circ = P._rename(copy.deepcopy(c['circuit']), P._ren)
    loops = [op for op in circ if isinstance(op, dict) and op.get('name') == 'loop']
    body = [op for op in loops[0]['body'] if not (isinstance(op, dict) and op.get('name') == 'alu')]
    tail = []
    while body and isinstance(body[-1], dict) and body[-1].get('name') == 'delay': tail.insert(0, body.pop())
    body = tail + body
    qg = {f'qubit_{i}': {f'qubit_{i}.qdrv', f'qubit_{i}.rdrv', f'qubit_{i}.rdlo'} for i in range(NCH)}
    comp = P.tc.run_compile_stage(body, P._real_fpga, P._real_qchip, compiler_flags={'schedule': True}, qubit_grouping=qg)
    return P.tc.run_assemble_stage(comp, P.cc)
gate = P._real_qchip.gates[f'qubit_{core}X90'] if hasattr(P._real_qchip, 'gates') else None
try:
    vz = [g for g in P._real_qchip.gates[f'qubit_{core}X90'].contents if getattr(g, 'gate', None) == 'virtualz' or 'virtual' in str(type(g)).lower()]
    print('X90 gate virtual-Z entries:', [(getattr(g, 'phase', None)) for g in vz])
except Exception as e:
    print('X90 gate contents not introspectable:', e)
for idx in [int(a) for a in sys.argv[1:]] or [206, 200]:
    phi = P._phys_circuits[idx].get('fringe_phase')
    print(f'\n===== idx {idx}: {P._phys_circuits[idx]["name"]}  (Z phase phi = {phi:+.4f} rad)')
    exe_b, _ = P.phys(idx); exe_a = stock_compile(idx)
    for label, exe in (('B  c3 path: hardware-loop program (Programs.phys)', exe_b), ('A  stock path: loop body recompiled one-shot (run_rpc)', exe_a)):
        name, cmds = decode(exe)
        print(f'--- {label}  [{name}, {len(cmds)} commands]')
        pulses = [c for c in cmds if c['op'] in ('pulse_write', 'pulse_write_trig')]
        for c in cmds:
            if c['op'] in ('pulse_write', 'pulse_write_trig'):
                print(f"   #{c['n']:3d} {c['op']:16s} t={c['t_clk']:>7} clk  freq_w={c['freq']}{' (reg)' if c['freq_reg'] else ''}  amp_w={c['amp']}  env_w={c['env']}  phase_w={c['phase_word']}{' (REGISTER)' if c['phase_reg'] else ''}  phase={c.get('phase_rad', float('nan')):+.5f} rad  raw={c['raw'][:12]}...")
            else:
                print(f"   #{c['n']:3d} {c['op']}")
        drive = [c for c in pulses if c['amp'] is not None and c['phase_word'] is not None]
        if len(drive) >= 2:
            d = drive[1]['phase_rad'] - drive[0]['phase_rad']; d = (d + np.pi) % (2 * np.pi) - np.pi
            print(f"   => phase(2nd drive pulse) - phase(1st drive pulse) = {d:+.5f} rad  (phi {phi:+.4f}; phi + 2 vz = {phi + 2*0.020561133:+.4f}; phi + 1 vz = {phi + 0.020561133:+.4f})")
