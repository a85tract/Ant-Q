"""Plan A0/G5: split the oversized RB experiments (#5, #6 of physic_experiment.py) into sub-circuit segments of
<= CAP pulses per core (CAP = 2046 -> 2048 commands with phase_reset + done), one hardware shot each, and verify
offline that the concatenated segments reproduce the unbroken shot's pulse commands (phase words included).
Segment 0 of every shot carries a LEADING delay of dt_inter_shot (a trailing delay is dropped by the compiler);
the accumulated virtual-Z phase per qubit (user-level virtual_z ops AND the virtualz entries of gate definitions)
is prepended to each segment so compile-time Z resolution yields the same pulse phases.
build_segments(P, idx, cap) -> (segments: list of (exe, meta), shot_meta)."""
import sys, os, json, copy
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import antq_runner
from distproc.command_gen import opcodes, pulse_field_pos as FP, pulse_field_widths as FW

CAP = 2046
PULSE_OPS = {opcodes['pulse_write'], opcodes['pulse_write_trig']}

def _op_pulses_per_core(op):
    """conservative per-core pulse count of one user-level op (X90 = 1 on its core; read = 2; any 2-qubit gate =
    2 on each core; virtual_z/delay = 0). Exact counts are checked after compilation (<= 2048 commands)."""
    name = op['name']; q = op.get('qubit')
    if name in ('virtual_z', 'delay', 'barrier', 'declare', 'set_var', 'alu'):
        return {}
    if name == 'read':
        return {q: 2}
    if isinstance(q, list):
        return {qq: 2 for qq in q}
    return {q: 1}

def split_body(body, cap=CAP):
    """cut the user-level op list at gate boundaries so no core exceeds cap pulses (conservative count)"""
    segs, cur, counts = [], [], {}
    for op in body:
        if op.get('name') == 'alu':
            continue
        p = _op_pulses_per_core(op)
        if cur and any(counts.get(q, 0) + n > cap for q, n in p.items()):
            segs.append(cur); cur, counts = [], {}
        cur.append(op)
        for q, n in p.items(): counts[q] = counts.get(q, 0) + n
    if cur: segs.append(cur)
    return segs

def _pulses(comp):
    """resolved pulses of a compiled program in schedule order per dest: list of (dest, freqname, phase, start)"""
    out = []
    for core, instrs in comp.program.items():
        for ins in instrs:
            if isinstance(ins, dict) and ins.get('op') == 'pulse' and 'start_time' in ins:
                out.append((ins['dest'], ins.get('freq'), float(ins.get('phase', 0.0)), int(ins['start_time'])))
    out.sort(key=lambda t: (t[0], t[3]))
    return out

def _first_phase_per_frame(pulses, dests_seen=None):
    first = {}
    for dest, fr, ph, st in sorted(pulses, key=lambda t: t[3]):
        first.setdefault(fr, ph)
    return first

def build_segments(P, idx, cap=CAP, verify=True, max_pulses=None):
    if not hasattr(P, '_real_qchip'): P._real_init()
    sys.path.insert(0, antq_runner.BENCH_DIR)
    import physic_experiment
    c = {x['idx']: x for x in physic_experiment.build_circuits()}[idx]
    circ = json.loads(P._ren(json.dumps(copy.deepcopy(c['circuit']), default=float)))
    loop = [op for op in circ if op.get('name') == 'loop'][0]
    body = loop['body']; qubits = [P._ren(q) for q in loop['scope']]
    if max_pulses:                        # boundary control (plan A0): a capacity-fitting prefix of the body, read kept
        kept, n = [], 0
        for op in body:
            if op.get('name') in ('read', 'delay', 'alu'):
                continue
            p_ = sum(_op_pulses_per_core(op).values())
            if n + p_ > max_pulses: break
            kept.append(op); n += p_
        body = kept + [op for op in body if op.get('name') in ('read', 'delay')]
    dt = float(c['dt_inter_shot'])
    qg = {f'qubit_{i}': {f'qubit_{i}.qdrv', f'qubit_{i}.rdrv', f'qubit_{i}.rdlo'} for i in range(P.num_ch)}
    segs = split_body(body, cap)
    # unbroken reference (the whole body once, same leading delay): its resolved pulse phases are the truth
    ref = P.tc.run_compile_stage([{'name': 'delay', 't': dt}] + [o for o in body if o.get('name') != 'alu'],
                                 P._real_fpga, P._real_qchip, compiler_flags={'schedule': True}, qubit_grouping=qg)
    ref_pulses = _pulses(ref)
    ref_by_dest = {}
    for dest, fr, ph, st in ref_pulses: ref_by_dest.setdefault(dest, []).append((fr, ph))
    consumed = {d: 0 for d in ref_by_dest}
    out = []
    for k, ops in enumerate(segs):
        lead = [{'name': 'delay', 't': dt}] if k == 0 else []
        comp0 = P.tc.run_compile_stage(lead + ops, P._real_fpga, P._real_qchip, compiler_flags={'schedule': True}, qubit_grouping=qg)
        seg_pulses = _pulses(comp0)
        # carry per frame = reference phase of this segment's first pulse in that frame - its zero-carry phase
        carry = {}
        seen_frames = set()
        drive_frames = {float(P._real_qchip.qubits[q].freq): q for q in P._real_qchip.qubits}   # Hz -> qubit (Z frames)
        for dest, fr, ph, st in sorted(seg_pulses, key=lambda t: t[3]):
            if fr in seen_frames or float(fr) not in drive_frames:
                continue
            seen_frames.add(fr)
            # locate the same pulse in the reference: the next unconsumed pulse on this dest
            idx_in_dest = sum(1 for d2, f2, p2, s2 in seg_pulses if d2 == dest and s2 < st)
            ref_fr, ref_ph = ref_by_dest[dest][consumed[dest] + idx_in_dest]
            assert ref_fr == fr, (dest, fr, ref_fr)
            carry[fr] = (ref_ph - ph) % (2 * np.pi)
        vz = [{'name': 'virtual_z', 'phase': float(ph), 'qubit': drive_frames[float(fr)]} for fr, ph in carry.items() if ph]
        comp = P.tc.run_compile_stage(lead + vz + ops, P._real_fpga, P._real_qchip, compiler_flags={'schedule': True}, qubit_grouping=qg) if vz else comp0
        seg_pulses = _pulses(comp)
        # verify every pulse of the segment against the reference slice (phase mod 2 pi, same frame)
        mism = 0
        per_dest = {}
        for dest, fr, ph, st in seg_pulses: per_dest.setdefault(dest, []).append((fr, ph))
        for dest, lst in per_dest.items():
            for j, (fr, ph) in enumerate(lst):
                rfr, rph = ref_by_dest[dest][consumed[dest] + j]
                if rfr != fr or abs(((rph - ph + np.pi) % (2 * np.pi)) - np.pi) > 1e-6:
                    mism += 1
            consumed[dest] += len(lst)
        exe = P.tc.run_assemble_stage(comp, P.cc, elem_cfg_pool=P.pool)
        binaries = {n: bytes(d.data if hasattr(d, 'data') else d) for n, d in exe.get_binaries_fromboard().items()}
        cmd_max = max(len(b) for n, b in binaries.items() if 'command' in n)
        assert cmd_max <= 32768, f'segment {k}: {cmd_max} B > slot'
        dur = 0
        for instrs in comp.program.values():
            for ins in instrs:
                if isinstance(ins, dict) and 'start_time' in ins:
                    env = ins.get('env', {}); tw = env.get('paradict', {}).get('twidth', 0) if isinstance(env, dict) else 0
                    dur = max(dur, ins['start_time'] + (int(tw / 2e-9) if tw else 15))
        rps = {ch: 1 for ch in exe.result_channels if ch.endswith('.rdlo')} if any(o.get('name') == 'read' for o in ops) else {}
        out.append((exe, dict(seg=k, n_ops=len(ops), cmd_bytes_max=cmd_max, n_cmds_max=cmd_max // 16, dur_us=dur * 2e-9 * 1e6,
                              rps=rps, carry_in={drive_frames[float(fr)]: float(ph) for fr, ph in carry.items()}, phase_mismatches=mism)))
    assert all(consumed[d] == len(ref_by_dest[d]) for d in ref_by_dest), 'segments do not cover the reference'
    report = dict(idx=idx, name=c['name'], n_segments=len(segs), shots=int(c['shots']), dt_us=dt * 1e6,
                  segments=[m for _, m in out], sum_dur_us=sum(m['dur_us'] for _, m in out))
    report['verify'] = dict(pulse_word_mismatches=sum(m['phase_mismatches'] for _, m in out),
                            ref_pulses={d: len(v) for d, v in ref_by_dest.items()})
    report['verify_ok'] = report['verify']['pulse_word_mismatches'] == 0
    return out, report

if __name__ == '__main__':
    GW = sys.argv[1]
    P = antq_runner.Programs(GW, 14, pool_tables=True)     # one shared pool: identical tables across segments
    for idx in (5, 6):
        segs, rep = build_segments(P, idx)
        print(json.dumps({k: v for k, v in rep.items()}, indent=1, default=str)[:3000])
        assert rep['verify_ok'], f'#{idx}: segment pulse words differ from the unbroken program'
        assert all(m['n_cmds_max'] <= 2048 for _, m in segs), 'segment over capacity'
    print('SPLIT OK')
