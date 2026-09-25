"""AQT X6Y3 device programs for the Ant-Q runner, in the physic_experiment format.

Load through the runner:
    ANTQ_PHYS_MODULE=<this file> ANTQ_QCHIP=<device qubitcfg.json> antq_runner.py --phys --mode c3 --idx <k> --save-iq ...
Every program is one hardware loop on one qubit (AQT_QUBIT, default Q6); the runner renames Q<n> -> qubit_<n>.
Loop periods are set by pad delays (env, seconds) so that the compiled period hits the pre-registered cadence;
the environment of the device session (pads, tau_R, qubit, counts) is listed in results/device_x6y3/README.md.

idx      program                                   reads/iter  body
101      P0-C  6 us cadence x 8000                  1           X90 - 1 us - X90 - read - pad_C
102      P0-A  prepare |0> x N_A                    1           read - reset
103      P0-A  prepare |1> x N_A                    1           X90 X90 - read - reset
120-150  P0-A  T1 sweep, 31 delays 0..T1_MAX        1           X90 X90 - delay_k - read - reset          (N_T1 each)
104      P0-B  Ramsey pairs, one read per 2.000 ms  2           [+quadrature Ramsey - read - pad_B][-quadrature ...] x N_B_ITER
105-109  P0-B  slope calibration, 5 phase offsets   1           +quadrature Ramsey with extra phase phi_k - read - reset (N_CAL)
200-212  fringe X90 - 100 ns - Z(phi_k) - X90 - read    1           first on-device check, 13 phases over [-pi, pi] (also run on the stock path)
300+     RB    random Clifford sequences + inverse  1           idx = 300 + 10*L + s (length index L in RB_LENGTHS, sequence s);
                                                                sequences longer than STREAM_ABOVE Cliffords carry 'stream': True
                                                                and run as sub-circuit streams (phys_split / REPT, --pool-tables)
"""
import os
import numpy as np

pi = np.pi
Q = os.environ.get('AQT_QUBIT', 'Q6')
RESET_S = float(os.environ.get('AQT_RESET_S', '500e-6'))          # X6Y3 passive reset wait (afeca config.yaml)
TAU_R_S = float(os.environ.get('AQT_TAU_R_S', '10e-6'))            # Ramsey free evolution: min(10 us, 0.3 T2*)
PAD_C_S = float(os.environ.get('AQT_PAD_C', '3.810e-6'))             # P0-C pad -> 6.000 us with the live (configs_new) pulses; 3.738e-6 for the Feb-2025 qchip
PAD_B_S = float(os.environ.get('AQT_PAD_B', '1.98881e-3'))           # P0-B pad per half -> 2.000 ms per read with the live pulses; 1.988738e-3 for the Feb-2025 qchip
N_A = int(os.environ.get('AQT_N_A', '10000'))
N_T1 = int(os.environ.get('AQT_N_T1', '512'))
T1_MAX_S = float(os.environ.get('AQT_T1_MAX_S', '200e-6'))
N_B_ITER = int(os.environ.get('AQT_N_B_ITER', '25000'))            # pairs per record -> 50000 reads
N_CAL = int(os.environ.get('AQT_N_CAL', '512'))
CAL_PHASES = [-0.4, -0.2, 0.0, 0.2, 0.4]                           # rad, on the second X90 (slope calibration)
RB_LENGTHS = [int(x) for x in os.environ.get('AQT_RB_LENGTHS', '2,4,8,16,32,64').split(',')]
RB_SEQS = int(os.environ.get('AQT_RB_SEQS', '8'))
RB_SHOTS = int(os.environ.get('AQT_RB_SHOTS', '256'))
RB_SEED = int(os.environ.get('AQT_RB_SEED', '2026'))
STREAM_ABOVE = int(os.environ.get('AQT_STREAM_ABOVE', '900'))      # Cliffords; ~2 commands each -> beyond one 2048-command slot
FRINGE_PHASES = [float(x) for x in np.linspace(-np.pi, np.pi, 13)]      # first-on-device check: X90 - 100 ns - Z(phi) - X90 - read
FRINGE_TAU_S = float(os.environ.get('AQT_FRINGE_TAU_S', '100e-9'))
N_FRINGE = int(os.environ.get('AQT_N_FRINGE', '512'))


# ------------------------------------------------ the single-qubit Clifford group, exactly ---------------------------
def _rz(a):
    return np.array([[np.exp(-1j * a / 2), 0], [0, np.exp(1j * a / 2)]])


def _rx(a):
    return np.array([[np.cos(a / 2), -1j * np.sin(a / 2)], [-1j * np.sin(a / 2), np.cos(a / 2)]])


def _same(u, v):
    """equal up to a global phase"""
    return abs(abs(np.trace(u.conj().T @ v)) - 2) < 1e-6


def clifford_group():
    """The 24 single-qubit Cliffords as unitaries, generated from X90 and Z90 by closure."""
    gens = [_rx(pi / 2), _rz(pi / 2)]
    group = [np.eye(2, dtype=complex)]
    frontier = list(group)
    while frontier:
        new = []
        for u in frontier:
            for g in gens:
                v = g @ u
                if not any(_same(v, w) for w in group):
                    group.append(v); new.append(v)
        frontier = new
    assert len(group) == 24, len(group)
    return group


def zxz_unitary(phi, theta, lam):
    """Z(lam) X90 Z(theta) X90 Z(phi), first applied = Z(phi)  (the benchmark's ZXZXZ convention)"""
    return _rz(lam) @ _rx(pi / 2) @ _rz(theta) @ _rx(pi / 2) @ _rz(phi)


_ANGLES = [k * pi / 2 for k in range(-2, 3)]                       # Cliffords need only multiples of pi/2


def zxz_angles(u):
    """(phi, theta, lam) on the pi/2 grid with zxz_unitary(...) ~ u; exhaustive over 5^3 = 125 candidates."""
    for phi in _ANGLES:
        for theta in _ANGLES:
            for lam in _ANGLES:
                if _same(zxz_unitary(phi, theta, lam), u):
                    return (float(phi), float(theta), float(lam))
    raise ValueError('no ZXZXZ decomposition on the pi/2 grid')


_GROUP = clifford_group()
_TRIPLES = [zxz_angles(u) for u in _GROUP]


def clifford_ops(q, triple):
    """One Clifford as pulse-level ops: virtual_z is a frame update (no command), X90 the physical pulse."""
    phi, theta, lam = triple
    ops = []
    if abs(phi) > 1e-12: ops.append({'name': 'virtual_z', 'qubit': q, 'phase': phi})
    ops.append({'name': 'X90', 'qubit': q})
    if abs(theta) > 1e-12: ops.append({'name': 'virtual_z', 'qubit': q, 'phase': theta})
    ops.append({'name': 'X90', 'qubit': q})
    if abs(lam) > 1e-12: ops.append({'name': 'virtual_z', 'qubit': q, 'phase': lam})
    return ops


def rb_sequence(m, rng):
    """m random Cliffords + the exact inverse element; returns (triples incl. inverse, group indices incl. inverse)."""
    idx = rng.integers(0, 24, size=m)
    u = np.eye(2, dtype=complex)
    for i in idx:
        u = _GROUP[i] @ u
    inv = u.conj().T
    k = next(j for j, w in enumerate(_GROUP) if _same(w, inv))
    return [_TRIPLES[i] for i in idx] + [_TRIPLES[k]], [int(i) for i in idx] + [k]


# ------------------------------------------------ device pulses from qcal (ANTQ_QCHIP_PATCH) --------------------------
def patch_qchip(qd, export_path, ren=lambda s: s):
    """Replace this qubit's X90 and read gates in the qchip dict `qd` by the pulses qcal plays on the device
    (export_qcal_pulses.py output): X90 = virtual-Z(pre) + numeric-envelope pulse + virtual-Z(post); read = readout
    drive pulse + demodulation pulse (t0 = demod delay, its own phase). Frequencies come from the export too.
    `ren` maps the benchmark namespace (Q6) to the channel_config's (qubit_6), as the runner does for the qchip."""
    import json
    e = json.load(open(export_path)); q = Q
    if e.get('qubit') not in (None, int(q[1:])):
        raise ValueError(f"export is for qubit {e.get('qubit')}, module qubit is {q}")
    arr = lambda o: np.array([complex(a, b) for a, b in o['__ndarray__']], dtype=np.complex64)
    def R(d): return {k: (ren(v) if isinstance(v, str) else v) for k, v in d.items()}
    vz = [p for p in e['X90'] if p.get('name') == 'virtual_z']; pulse = [p for p in e['X90'] if p.get('name') == 'pulse'][0]
    g_x90 = [R({'gate': 'virtualz', 'freq': f'{q}.freq', 'phase': vz[0]['phase']}),
             R({'freq': f'{q}.freq', 'phase': pulse.get('phase', 0.0), 'dest': f'{q}.qdrv', 'twidth': pulse['twidth'], 't0': 0.0,
                'amp': pulse['amp'], 'env': arr(pulse['env'])})] + ([R({'gate': 'virtualz', 'freq': f'{q}.freq', 'phase': vz[1]['phase']})] if len(vz) > 1 else [])
    rd = [p for p in e['Meas'] if p.get('name') == 'pulse']; demod_delay = sum(p['t'] for p in e['Meas'] if p.get('name') == 'delay')
    rdrv = [p for p in rd if p['dest'].endswith('.rdrv')][0]; rdlo = [p for p in rd if p['dest'].endswith('.rdlo')][0]
    g_read = [R({'freq': f'{q}.readfreq', 'phase': rdrv.get('phase', 0.0), 'dest': f'{q}.rdrv', 'twidth': rdrv['twidth'], 't0': 0.0,
                 'amp': rdrv['amp'], 'env': arr(rdrv['env'])}),
              R({'freq': f'{q}.readfreq', 'phase': rdlo.get('phase', 0.0), 'dest': f'{q}.rdlo', 'twidth': rdlo['twidth'], 't0': demod_delay,
                 'amp': rdlo.get('amp', 1.0), 'env': arr(rdlo['env'])})]
    qd['Gates'][ren(f'{q}X90')] = g_x90; qd['Gates'][ren(f'{q}read')] = g_read
    qd['Qubits'].setdefault(ren(q), {})['freq'] = e['freq']; qd['Qubits'][ren(q)]['readfreq'] = e['readfreq']
    return qd


# ------------------------------------------------ program builders ------------------------------------------------
def x90(q=None): return {'name': 'X90', 'qubit': q or Q}
def read(q=None): return {'name': 'read', 'qubit': q or Q}
def delay(t): return {'name': 'delay', 't': float(t)}
def vz(phase, q=None): return {'name': 'virtual_z', 'qubit': q or Q, 'phase': float(phase)}


def _loop(var, n, body, q):
    return [{'name': 'declare', 'var': var, 'dtype': 'int', 'scope': [q]},
            {'name': 'set_var', 'var': var, 'value': 0},
            {'name': 'loop', 'cond_lhs': n, 'cond_rhs': var, 'alu_cond': 'ge', 'scope': [q],
             'body': body + [{'name': 'alu', 'op': 'add', 'lhs': 1, 'rhs': var, 'out': var}]}]


def _prog(idx, name, n_iter, reads_per_iter, body, dt, **extra):
    d = dict(idx=idx, name=name, n_qubits=1, shots=n_iter * reads_per_iter, dt_inter_shot=dt, is_loop=True,
             n_inner=n_iter, loop_reads_per_shot=n_iter * reads_per_iter, submit_n_shots=1,
             circuit=_loop(f'i{idx}', n_iter, body, Q))
    d.update(extra)
    return d


def ramsey_half(sign, extra_phase=0.0, pad=PAD_B_S):
    """X90 - tau_R - Z(sign*pi/2 + extra) - X90 - read - pad : quadrature operating point, slope sign +-1"""
    return [x90(), delay(TAU_R_S), vz(sign * pi / 2 + extra_phase), x90(), read(), delay(pad)]


def build_circuits():
    cs = []
    cs.append(_prog(101, f'P0-C 6 us cadence x 8000 on {Q}', 8000, 1,
                    [x90(), delay(1e-6), x90(), read(), delay(PAD_C_S)], 6e-6))
    cs.append(_prog(102, f'P0-A prepare |0> x {N_A} on {Q}', N_A, 1, [read(), delay(RESET_S)], RESET_S))
    cs.append(_prog(103, f'P0-A prepare |1> x {N_A} on {Q}', N_A, 1, [x90(), x90(), read(), delay(RESET_S)], RESET_S))
    for k, t in enumerate(np.linspace(0.0, T1_MAX_S, 31)):
        cs.append(_prog(120 + k, f'P0-A T1 sweep delay {t*1e6:.1f} us on {Q}', N_T1, 1,
                        [x90(), x90(), delay(max(float(t), 4e-9)), read(), delay(RESET_S)], RESET_S, t1_delay_s=float(t)))
    cs.append(_prog(104, f'P0-B Ramsey pairs {N_B_ITER}x2 at 2 ms on {Q}', N_B_ITER, 2,
                    ramsey_half(+1) + ramsey_half(-1), 2e-3, tau_r_s=TAU_R_S))
    for k, ph in enumerate(CAL_PHASES):
        cs.append(_prog(105 + k, f'P0-B slope calibration phase {ph:+.1f} rad on {Q}', N_CAL, 1,
                        ramsey_half(+1, extra_phase=ph, pad=RESET_S), RESET_S, cal_phase=ph, tau_r_s=TAU_R_S))
    # diagnostic (2026-09-17 core-7 fault): extra delay commands after the read lengthen the loop body's command image
    # (delays are coalesced by the compiler; zero-amplitude 8-ns readout-drive pulses survive as one command each and play nothing)
    FRINGE_PAD = [{'name': 'pulse', 'freq': f'{Q}.readfreq', 'phase': 0.0, 'dest': f'{Q}.rdrv', 'twidth': 8e-9, 'amp': 0.0,
                   'env': {'env_func': 'square', 'paradict': {'phase': 0.0, 'amplitude': 1.0, 'twidth': 8e-9}}}
                  for _ in range(int(os.environ.get('AQT_FRINGE_PAD_DELAYS', '0')))]
    # diagnostic (the bench board, no qubit): AQT_FRINGE_RDRV_TAG=1 adds, before the readout, a full-amplitude readout-drive pulse whose
    # WIDTH encodes the program index (200 ns + 400 ns x k) so an oscilloscope on the readout-drive bus can tell which
    # program's body actually executed in every iteration. Never set on the device.
    # mask experiment (the device board, 2026-09-18 plan): AQT_ALL_CORES=1 gives every OTHER qubit's core a real, inert program (one
    # zero-amplitude 8-ns drive pulse at the start), so the compiled batch has all 8 command binaries, CE mask 0 and NO idle
    # program on cores 0-6; compare against the default (mask 0x7F, idle program) within one image load.
    ALL_CORES = int(os.environ.get('AQT_ALL_CORES', '0'))
    OTHERS = [f'Q{i}' for i in range(8) if f'Q{i}' != Q]
    INERT = [{'name': 'pulse', 'freq': f'{q}.freq', 'phase': 0.0, 'dest': f'{q}.qdrv', 'twidth': 8e-9, 'amp': 0.0,
              'env': {'env_func': 'square', 'paradict': {'phase': 0.0, 'amplitude': 1.0, 'twidth': 8e-9}}} for q in OTHERS] if ALL_CORES else []
    RDRV_TAG = int(os.environ.get('AQT_FRINGE_RDRV_TAG', '0'))
    def tag_pulse(k):
        w = 200e-9 + 400e-9 * k                      # 200..5000 ns: 5 bins apart at the scope's 80 ns bins (12.5 MS/s)
        return [{'name': 'pulse', 'freq': f'{Q}.readfreq', 'phase': 0.0, 'dest': f'{Q}.rdrv', 'twidth': w, 'amp': 0.1,
                 'env': {'env_func': 'square', 'paradict': {'phase': 0.0, 'amplitude': 1.0, 'twidth': w}}}, delay(400e-9)] if RDRV_TAG else []
    for k, ph in enumerate(FRINGE_PHASES):                            # idx 200-212: phase/frame translation check (both command paths)
        cs.append(_prog(200 + k, f'fringe X90-{FRINGE_TAU_S*1e9:.0f}ns-Z({ph:+.3f})-X90 on {Q}', N_FRINGE, 1,
                        INERT + [x90(), delay(FRINGE_TAU_S), vz(ph), x90()] + tag_pulse(k) + [read()] + FRINGE_PAD + [delay(RESET_S)], RESET_S, fringe_phase=ph))
    rng = np.random.default_rng(RB_SEED)
    # AQT_RB_TAIL=1 (2026-09-18, experiment (5) deep RB): read - delay(AQT_TAIL_S) - one zero-amplitude readout-drive pulse after the
    # read, so the LAST segment of a streamed sequence lasts >= AQT_TAIL_S (a short tail segment stalls the stream; harmless unbroken)
    RB_TAIL = ([delay(float(os.environ.get('AQT_TAIL_S', '12e-6'))),
                {'name': 'pulse', 'freq': f'{Q}.readfreq', 'phase': 0.0, 'dest': f'{Q}.rdrv', 'twidth': 8e-9, 'amp': 0.0,
                 'env': {'env_func': 'square', 'paradict': {'phase': 0.0, 'amplitude': 1.0, 'twidth': 8e-9}}}]
               if int(os.environ.get('AQT_RB_TAIL', '0')) else [])
    for L, m in enumerate(RB_LENGTHS):
        for s_ in range(RB_SEQS):
            triples, ids = rb_sequence(m, rng)
            body = [op for tr in triples for op in clifford_ops(Q, tr)] + [read()] + RB_TAIL + [delay(RESET_S)]
            cs.append(_prog(300 + 10 * L + s_, f'RB m={m} seq {s_} on {Q}', RB_SHOTS, 1, body, RESET_S,
                            rb_m=m, rb_seq=s_, rb_ids=ids, stream=(m > STREAM_ABOVE)))
    # ---------------- boundary experiment: the quantum consequence of one command-buffer handover. AQT_BOUNDARY=1 adds three
    # configurations of otherwise identical programs, run on the same image/load:
    #   S = streamed as two sub-circuit segments cut at a chosen gate boundary (seg_cut_after -> phys_split), 'stream': True;
    #   U = the same program unbroken (hardware loop, no handover);
    #   UD = U with an idle of AQT_HANDOVER_S inserted at the cut (the control for the time the handover adds).
    # Every body ends with read - delay(AQT_TAIL_S) - one zero-amplitude 8-ns readout-drive pulse, so the second segment lasts
    # >= AQT_TAIL_S (a trailing delay would be dropped by the compiler; a short tail segment stalls the stream).
    #   fringe: idx 220-232 (S), 240-252 (U), 260-272 (UD): X90 | delay(tau) - Z(phi) - X90 - read - tail   (cut after the first X90)
    #   RB    : idx 400+10L+s (S), 500+10L+s (U), 600+10L+s (UD), lengths AQT_BRB_LENGTHS, 8 sequences, AQT_BRB_SHOTS shots,
    #           cut after Clifford m//2 (same sequences in all three configurations; seed AQT_BRB_SEED)
    if int(os.environ.get('AQT_BOUNDARY', '0')):
        TAIL_S = float(os.environ.get('AQT_TAIL_S', '12e-6'))
        TAIL = [delay(TAIL_S), {'name': 'pulse', 'freq': f'{Q}.readfreq', 'phase': 0.0, 'dest': f'{Q}.rdrv', 'twidth': 8e-9, 'amp': 0.0,
                                'env': {'env_func': 'square', 'paradict': {'phase': 0.0, 'amplitude': 1.0, 'twidth': 8e-9}}}]
        NB_FR = int(os.environ.get('AQT_BFRINGE_N', str(N_FRINGE)))
        HANDOVER_S = float(os.environ.get('AQT_HANDOVER_S', '152e-9'))   # UD: idle inserted at the cut of the unbroken twin
        for k, ph in enumerate(FRINGE_PHASES):
            head = [x90()]; rest = [delay(FRINGE_TAU_S), vz(ph), x90(), read()] + TAIL + [delay(RESET_S)]
            cs.append(_prog(220 + k, f'boundary fringe S Z({ph:+.3f}) on {Q}', NB_FR, 1, head + rest, RESET_S, fringe_phase=ph, config='S',
                            stream=True, seg_cut_after=len(head)))
            cs.append(_prog(240 + k, f'boundary fringe U Z({ph:+.3f}) on {Q}', NB_FR, 1, head + rest, RESET_S, fringe_phase=ph, config='U'))
            cs.append(_prog(260 + k, f'boundary fringe UD Z({ph:+.3f}) on {Q}', NB_FR, 1, head + [delay(HANDOVER_S)] + rest, RESET_S,
                            fringe_phase=ph, config='UD'))
        BRB_LENGTHS = [int(x) for x in os.environ.get('AQT_BRB_LENGTHS', '16,32,64,128').split(',')]
        BRB_SHOTS = int(os.environ.get('AQT_BRB_SHOTS', '2048')); BRB_SEED = int(os.environ.get('AQT_BRB_SEED', '20260917'))
        rng_b = np.random.default_rng(BRB_SEED)
        for L, m in enumerate(BRB_LENGTHS):
            for s_ in range(RB_SEQS):
                triples, ids = rb_sequence(m, rng_b)
                half = m // 2
                head = [op for tr in triples[:half] for op in clifford_ops(Q, tr)]
                rest = [op for tr in triples[half:] for op in clifford_ops(Q, tr)] + [read()] + TAIL + [delay(RESET_S)]
                common = dict(rb_m=m, rb_seq=s_, rb_ids=ids, cut_clifford=half)
                cs.append(_prog(400 + 10 * L + s_, f'boundary RB S m={m} seq {s_} on {Q}', BRB_SHOTS, 1, head + rest, RESET_S,
                                config='S', stream=True, seg_cut_after=len(head), **common))
                cs.append(_prog(500 + 10 * L + s_, f'boundary RB U m={m} seq {s_} on {Q}', BRB_SHOTS, 1, head + rest, RESET_S, config='U', **common))
                cs.append(_prog(600 + 10 * L + s_, f'boundary RB UD m={m} seq {s_} on {Q}', BRB_SHOTS, 1, head + [delay(HANDOVER_S)] + rest,
                                RESET_S, config='UD', **common))
    # ---------------- handover marker programs (2026-09-18, bench only, the bench board + oscilloscope on the readout-drive DAC):
    # measure the command-buffer handover DIRECTLY as the gap between two visible marker pulses on the readout-drive channel.
    # AQT_HANDOVER_MARK=1 adds: idx 700 S2  = [lead reset, marker A] | [marker B, tail]      (2-segment stream, cut after A)
    #                            idx 701 U2  = [marker A, marker B, tail]                    (unbroken twin: A and B back to back)
    #                            idx 702 S2R = [lead reset, marker A, read] | [marker B, tail] (segment 0 ends with a readout)
    #                            idx 703 U2R = [marker A, read, marker B, tail]              (unbroken twin)
    # marker = 200 ns square pulse on <Q>.rdrv, amplitude AQT_MARK_AMP (default 0.5). Handover = gap(S) - gap(U) - 10 ns
    # (the compile-time offset of a program's first pulse). Shots AQT_MARK_N (default 4096) with the module's RESET_S wait.
    if int(os.environ.get('AQT_HANDOVER_MARK', '0')):
        MA = float(os.environ.get('AQT_MARK_AMP', '0.5')); NM = int(os.environ.get('AQT_MARK_N', '4096'))
        # AQT_MARK_DEST=qdrv puts the markers on the qubit drive DAC (14_2 bench: the readout bus is DAC 14/15, not on the scope;
        # CH1 = qubit_8 drive, reached with AQT_QUBIT=Q7 + SCOPE_QUBIT_OFFSET=1); default rdrv = the 8_2 shared readout bus
        MD = os.environ.get('AQT_MARK_DEST', 'rdrv'); MF = f'{Q}.freq' if MD == 'qdrv' else f'{Q}.readfreq'
        def marker(w=200e-9):
            return {'name': 'pulse', 'freq': MF, 'phase': 0.0, 'dest': f'{Q}.{MD}', 'twidth': w, 'amp': MA,
                    'env': {'env_func': 'square', 'paradict': {'phase': 0.0, 'amplitude': 1.0, 'twidth': w}}}
        TAILM = [delay(float(os.environ.get('AQT_TAIL_S', '12e-6'))),
                 {'name': 'pulse', 'freq': f'{Q}.readfreq', 'phase': 0.0, 'dest': f'{Q}.rdrv', 'twidth': 8e-9, 'amp': 0.0,
                  'env': {'env_func': 'square', 'paradict': {'phase': 0.0, 'amplitude': 1.0, 'twidth': 8e-9}}}]
        # A - 400 ns compiled gap - B, then a readout (the c3 path needs one: CFGB E_RANGE without) and the tail; the gap A.end -> B.start
        # is 400 ns in U2 and 400 ns + 10 ns (segment start offset) + handover in S2
        cs.append(_prog(700, f'handover marker S2 on {Q}', NM, 1, [marker()] + [delay(400e-9), marker(), read()] + TAILM + [delay(RESET_S)], RESET_S,
                        config='S2', stream=True, seg_cut_after=1))
        cs.append(_prog(701, f'handover marker U2 on {Q}', NM, 1, [marker(), delay(400e-9), marker(), read()] + TAILM + [delay(RESET_S)], RESET_S, config='U2'))
        cs.append(_prog(702, f'handover marker S2R (segment 0 ends with a readout) on {Q}', NM, 1,
                        [marker(), read()] + [marker()] + TAILM + [delay(RESET_S)], RESET_S, config='S2R', stream=True, seg_cut_after=2))
        cs.append(_prog(703, f'handover marker U2R on {Q}', NM, 1, [marker(), read(), marker()] + TAILM + [delay(RESET_S)], RESET_S, config='U2R'))
    return cs


if __name__ == '__main__':
    cs = build_circuits()
    print(len(cs), 'programs; Clifford group', len(_GROUP), '; decompositions', len(_TRIPLES))
    for u, t in zip(_GROUP, _TRIPLES):
        assert _same(zxz_unitary(*t), u)
    rng = np.random.default_rng(1)
    for m in (1, 5, 50, 1000):
        tr, ids = rb_sequence(m, rng)
        u = np.eye(2, dtype=complex)
        for t in tr:
            u = zxz_unitary(*t) @ u
        assert _same(u, np.eye(2)), f'{m} Cliffords + inverse != identity'
    print('self-check OK: every Clifford decomposes on the pi/2 grid; sequences (m = 1, 5, 50, 1000) + inverse = identity')
    for c in cs[:4] + [c for c in cs if c['idx'] in (104, 105, 300, 350)]:
        print(f"idx {c['idx']:>3} n_inner {c['n_inner']:>6} reads {c['loop_reads_per_shot']:>6} stream={c.get('stream', False)}  {c['name']}")
