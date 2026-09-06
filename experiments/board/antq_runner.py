"""Ant-Q re-measurement runner (plan: ~/agent_journals/antq_rerun_plan_20260829.md, rev 5, APPROVED).

Modes (all timed on the PS in C, CLOCK_MONOTONIC):
  std : standard QubiC path in C (std_server BATCH): BRAM command MMIO stores + accbuf MMIO reads.
  c1  : QubiC downlink (std_server BATCH, readout_ddr) + Ant-Q uplink (dma_server STRM), host-sequenced
        per circuit (the C1 gateware's readout writer parks at base after every circuit, so each circuit
        must be drained before the next start — same as the prototype's C1 path).
  c3  : Ant-Q downlink + uplink (batch_server + dma_server; CircuitRunnerClient ddr_cmd=True).

Workload = readout-simulation programs (plan D1): delay(per_shot_us - 1.5 us) + read on n_q qubits;
per-shot times from the QCE benchmark table, shots from results/shots_verification.csv (rerun_shots).
--real (addendum 2026-08-30, APPROVED): the paper's 20 circuits from benchmark_qce/circuits_le14
instead of the surrogate; per-shot from the compiled schedule; per-channel reads counted from the
compiled program; c3 heterogeneous batches run grouped-reload (n_groups + per-group CNR logged).

Usage: PYTHONPATH=<software_c3> python antq_runner.py --mode std --bits <bits_dir> --gw <build_dir>
         --num-ch 8 --what single|batch --idx 1,2 --batches rand30_t0 --repeats 5 --tag <label>
Every attempt appends one row to results/raw_runs.csv (never overwritten).
"""
import argparse, csv, json, os, socket, struct, subprocess, sys, threading, time
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
RES = os.environ.get('ANTQ_RESULTS', os.path.join(HERE, '..', '..', 'results'))   # <repo>/results
REPO = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..'))
BENCH_JSON = os.environ.get('ANTQ_BENCH_JSON', os.path.join(REPO, 'experiments', 'board', 'data', 'benchmark_results_20.json'))   # per-circuit shots / compiled per-shot (surrogate mode)
BENCH_DIR = os.environ.get('ANTQ_BENCH_DIR', os.path.join(REPO, 'benchmark'))   # the benchmark submodule (--real workload, physics experiments, qchip)
BOARD = 'localhost'            # SSH tunnels via computerA: 9015->9095 (RPC), 8080, 8081, 8082
RPC_PORT = 9015
RO_READOUT_S = 1.5e-6          # prototype: delay = per_shot - 1.5 us (readout pulse + settle)
RAW_FIELDS = ['run_id', 'wall_time', 'mode', 'bitfile', 'wns_ns', 'software_commit', 'workload', 'workload_id',
              'repeat', 'status', 'exclusion_reason', 'n_circuits', 'shots', 'rps', 'n_active_ch', 'per_shot_us',
              'qpu_ms', 't_start_ns', 't_end_ns', 'elapsed_ms', 'cmd_bytes_logical', 'cmd_bytes_transferred',
              'readout_bytes', 'send_block_us_max', 'send_block_us_total', 'seamless', 'tag',
              'pool_tables', 'n_groups', 'cnr', 'cnr_wait_cycles', 'note']
IDX20 = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 19, 20, 21, 22, 23, 24, 25]   # the paper's 20 circuits, pool order
PHYS_FIELDS = ['loop_n', 'interval_us', 'period_us', 'period_src', 'calib_n', 'cmd_bytes_max', 'n_units', 'n_segments', 'seg_dur_us']   # results/raw_runs_phys.csv
DECOMP_FIELDS = ['t_first_dma_done_ns', 't_start_written_ns', 't_first_cid_ns', 't_batch_done_ns']   # results/raw_runs_decomp.csv (batch_server v7 stat)
STOP_FIELDS = ['pair_id', 'stop_at', 'cp_step', 'cp_ns_req', 'delay_actual_ns', 'stop_result', 'actual_shots', 'overshoot', 'fired_k',
               't_decision_ns', 't_write_ns', 't_event_ps_ns', 'latency_cycles', 'latency_us', 'stop_flags', 'strm_poll_us']   # results/raw_runs_stop.csv


class _Capacity(Exception):
    pass


def load_bench():
    ps = {b['idx']: b for b in json.load(open(BENCH_JSON))}
    shots = {}
    with open(os.path.join(RES, 'shots_verification.csv')) as f:
        for r in csv.DictReader(f):
            shots[int(r['idx'])] = dict(name=r['name'], n_qubits=int(r['n_qubits']), shots=int(r['rerun_shots']),
                                        per_shot_us=float(r['per_shot_us']))
    return shots


def load_batches():
    b = {}
    with open(os.path.join(RES, 'batch_manifest.csv')) as f:
        for r in csv.DictReader(f):
            b.setdefault(r['batch_id'], []).append(int(r['circuit_idx']))
    return b


# ---------------- program builder (prototype's build_readout_sim on the C3 toolchain) ----------------
class Programs:
    def __init__(self, gw_build, num_ch, pool_tables=False):
        import qubic.toolchain as tc
        import qubitconfig.qchip as qc
        from distproc.hwconfig import FPGAConfig, load_channel_configs
        self.tc = tc
        self.cc = load_channel_configs(os.path.join(gw_build, 'gensrc', 'channel_config.json'))
        self.fpga = FPGAConfig()
        self.num_ch = num_ch
        qubits, gates = {}, {}
        for i in range(num_ch):
            q = f'qubit_{i}'
            qubits[q] = {'freq': 4_460_029_188 + i * 50_000_000, 'readfreq': 6_554_327_471 + i * 10_000_000}
            gates[f'{q}read'] = [
                {'freq': f'{q}.readfreq', 'phase': 0, 'dest': f'{q}.rdrv', 'twidth': 0.9e-06, 't0': 0,
                 'amp': 0.02, 'env': [{'env_func': 'cos_edge_square', 'paradict': {'ramp_fraction': 0.25}}]},
                {'freq': f'{q}.readfreq', 'phase': 0, 'dest': f'{q}.rdlo', 'twidth': 0.9e-06, 't0': 6e-07,
                 'amp': 1.0, 'env': [{'env_func': 'square', 'paradict': {'phase': 0.0, 'amplitude': 1.0}}]}]
        self.qchip = qc.QChip({'Qubits': qubits, 'Gates': gates})
        # command-slot geometry of the target image (fill-latency plan): emitted by configure into
        # gensrc/ds_geometry.json; absent = legacy 32768 B/channel. The batch_server HELO cross-checks.
        gp = os.path.join(gw_build, 'gensrc', 'ds_geometry.json')
        self.slot_bytes = json.load(open(gp))['slot_bytes'] if os.path.exists(gp) else 32768
        self.cache = {}
        self.real_cache = {}
        # plan C (2026-09-01): pool-wide env/freq tables. pass 1 assembles the 20 paper circuits in IDX20
        # order against one shared element-config pool; pass 2 (lazy, via real()) re-assembles every
        # measured program against the complete pool, so all programs carry byte-identical tables.
        self.pool = {} if pool_tables else None
        self.pool_ready = False

    def build_pool(self):
        if self.pool is None or self.pool_ready:
            return
        for i in IDX20:
            self.real(i)
        self.real_cache.clear()
        self.pool_ready = True

    # -- real-mode (plan addendum 2026-08-30): the paper's 20 circuits from benchmark_qce --
    def _real_init(self):
        import json as _json, re as _re
        import qubitconfig.qchip as qc
        from distproc.hwconfig import FPGAConfig, FPROCChannel
        # scope-metrology knobs (2026-09-04, results/scope_cadence): SCOPE_QUBIT_OFFSET moves every Q<n> to qubit_<n+k>
        # (e.g. 1 -> the program runs on qubit_1 whose drive is wired to scope CH2); SCOPE_READ_AMP replaces the readout
        # pulse amplitude (qchip Q*read pulse 0, default 0.02) so the rdrv pulse is visible on CH1. Pulse widths and all
        # timing are unchanged; rows must carry a --note saying these were set.
        _off = int(os.environ.get('SCOPE_QUBIT_OFFSET', '0') or 0)
        ren0 = lambda s: _re.sub(r'Q(\d+)', r'qubit_\1', s)                                    # benchmark namespace -> channel_config's
        ren = lambda s: _re.sub(r'Q(\d+)', lambda m: f'qubit_{int(m.group(1)) + _off}', s)     # physics programs only (scope offset)
        sys.path.insert(0, BENCH_DIR)
        import circuits_le14
        if '/home/yicheng/Desktop/software' in sys.path:       # circuits_le14 inserts it at import time;
            sys.path.remove('/home/yicheng/Desktop/software')  # qubic is already bound to software_c3
        self._real_circuits = {c['idx']: c for c in circuits_le14.build_circuits()}
        fp = FPGAConfig()
        fp.fproc_channels = {ren0(k): FPROCChannel(id=(f'{ren0(k).split(".")[0]}.rdlo', 'core_ind'),
                                                   hold_after_chans=[f'{ren0(k).split(".")[0]}.rdlo'],
                                                   hold_nclks=fp.fproc_meas_clks)
                             for k in fp.fproc_channels}
        self._real_fpga, self._ren, self._ren0 = fp, ren, ren0
        _qd = _json.loads(ren0(open(os.path.join(BENCH_DIR, 'qubitcfg_14q_gate.json')).read()))
        if os.environ.get('SCOPE_READ_AMP'):
            for g, pulses in _qd['Gates'].items():
                if g.endswith('read'):
                    pulses[0]['amp'] = float(os.environ['SCOPE_READ_AMP'])
            print(f"[scope] readout pulse amp set to {os.environ['SCOPE_READ_AMP']} for every qubit (timing unchanged)", flush=True)
        if os.environ.get('SCOPE_READ_FREQ'):           # carrier only; the envelope schedule (timing) does not depend on it
            for qn, qv in _qd['Qubits'].items():
                qv['readfreq'] = float(os.environ['SCOPE_READ_FREQ'])
            print(f"[scope] readout carrier set to {os.environ['SCOPE_READ_FREQ']} Hz for every qubit (timing unchanged)", flush=True)
        if os.environ.get('SCOPE_DRIVE_FREQ'):
            for qn, qv in _qd['Qubits'].items():
                qv['freq'] = float(os.environ['SCOPE_DRIVE_FREQ'])
            print(f"[scope] drive carrier set to {os.environ['SCOPE_DRIVE_FREQ']} Hz for every qubit (timing unchanged)", flush=True)
        self._real_qchip = qc.QChip(_qd)

    def _rename(self, obj, fn=None):
        """benchmark namespace Q<n> -> channel_config's qubit_<n> (fn defaults to the unshifted map; the physics programs
        pass self._ren, which carries the scope offset), applied to every string in the circuit structure.
        Replaces the former json.dumps/loads round trip, which could not carry the tuple keys of QubiC gate `modi`
        dicts (circuits_le14 idx 19/22 since 2026-09-04) and silently cast numpy scalars."""
        fn = fn or self._ren0
        if isinstance(obj, dict):
            return {k: self._rename(v, fn) for k, v in obj.items()}
        if isinstance(obj, (list, tuple)):
            return type(obj)(self._rename(x, fn) for x in obj)
        if isinstance(obj, str):
            return fn(obj)
        if isinstance(obj, np.generic):
            return obj.item()
        return obj

    def real(self, idx):
        """(exe, per_shot_us, rps): the paper's circuit `idx` compiled for this build. rps = rdlo-pulse
        count per channel COUNTED FROM THE COMPILED PROGRAM — exe.result_channels.reads_per_shot is a
        constant-1 placeholder upstream (distproc/assembler.py:467 never passes it)."""
        if idx in self.real_cache:
            return self.real_cache[idx]
        if not hasattr(self, '_real_qchip'):
            self._real_init()
        import json as _json
        circ = self._rename(self._real_circuits[idx]['circuit'])
        qg = {f'qubit_{i}': {f'qubit_{i}.qdrv', f'qubit_{i}.rdrv', f'qubit_{i}.rdlo'} for i in range(self.num_ch)}
        comp = self.tc.run_compile_stage(circ, self._real_fpga, self._real_qchip,
                                         compiler_flags={'schedule': True}, qubit_grouping=qg)
        max_end, rps = 0, {}
        for instrs in comp.program.values():
            for ins in instrs:
                if not isinstance(ins, dict):
                    continue
                if 'start_time' in ins:
                    env = ins.get('env', {})
                    tw = env.get('paradict', {}).get('twidth', 0) if isinstance(env, dict) else 0
                    max_end = max(max_end, ins['start_time'] + (int(tw / 2e-9) if tw else 15))
                d = ins.get('dest')
                if d and d.endswith('.rdlo'):
                    rps[d] = rps.get(d, 0) + 1
        exe = self.tc.run_assemble_stage(comp, self.cc, elem_cfg_pool=self.pool)
        out = (exe, max_end * 2e-9 * 1e6, rps)
        self.real_cache[idx] = out
        return out

    # -- physics characterization experiments (plan A, 2026-09-01): benchmark_qce/physic_experiment.py --
    def phys(self, idx, n_cal=None):
        """(exe, b) for physics experiment idx (1-4: one hardware shot with a hardware loop of N reads). n_cal
        overrides the loop count (calibration series, plan A3): only the loop's jump immediate changes, tables
        and image size are identical. b carries shots=1, rps={qubit_0.rdlo: N}, per_shot_us = N x P_us where
        P_us = the compiled loop period (the loop's inc_qclk operand x 2 ns — plan G3), loop_n, interval_us,
        period_us, per-core command bytes."""
        import json as _json, copy
        if not hasattr(self, '_real_qchip'):
            self._real_init()
        if not hasattr(self, '_phys_circuits'):
            sys.path.insert(0, BENCH_DIR)
            import physic_experiment
            self._phys_circuits = {c['idx']: c for c in physic_experiment.build_circuits()}
        c = self._phys_circuits[idx]
        if idx in (5, 6):                                  # sub-circuit stream (plan A0): programs come from phys_split
            import phys_split
            if not hasattr(self, '_seg_cache'): self._seg_cache = {}
            cap = getattr(self, 'seg_cap', None) or phys_split.CAP
            max_pulses = getattr(self, 'seg_pulses', None)
            key = (idx, cap, max_pulses)
            if key not in self._seg_cache:
                self._seg_cache[key] = phys_split.build_segments(self, idx, cap=cap, max_pulses=max_pulses)
            segs, rep_ = self._seg_cache[key]
            self._seg_cache[idx] = self._seg_cache[key]
            exe0 = segs[-1][0]
            per_shot = rep_['sum_dur_us']                       # segment 0 already carries the leading dt delay
            shots = int(getattr(self, 'repeat_override', 0) or 0) or rep_['shots']   # diagnostic replay count
            b = dict(idx=idx, name=c['name'], n_qubits=c['n_qubits'], shots=shots,
                     rps={ch: 1 for ch in exe0.result_channels if ch.endswith('.rdlo')},
                     per_shot_us=per_shot, loop_n=shots, interval_us=rep_['dt_us'],
                     period_us=per_shot, period_src='compile-segments', calib_n='',
                     cmd_bytes_max=max(m['cmd_bytes_max'] for _, m in segs), n_segments=len(segs))
            return exe0, b
        circ = self._rename(copy.deepcopy(c['circuit']), self._ren)     # physics program: scope offset applies
        N = int(c['loop_reads_per_shot']) if n_cal is None else int(n_cal)
        loops = [op for op in circ if isinstance(op, dict) and op.get('name') == 'loop']
        assert len(loops) == 1, f'phys {idx}: expected one hardware loop'
        loops[0]['cond_lhs'] = N
        qg = {f'qubit_{i}': {f'qubit_{i}.qdrv', f'qubit_{i}.rdrv', f'qubit_{i}.rdlo'} for i in range(self.num_ch)}
        comp = self.tc.run_compile_stage(circ, self._real_fpga, self._real_qchip,
                                         compiler_flags={'schedule': True}, qubit_grouping=qg)
        period_clk = None
        for instrs in comp.program.values():
            for ins in instrs:
                if isinstance(ins, dict) and ins.get('op') == 'inc_qclk':
                    v = ins.get('in0', ins.get('value'))
                    if isinstance(v, (int, float)) and abs(int(v)) > 0:
                        period_clk = abs(int(v))
        assert period_clk, f'phys {idx}: no inc_qclk found in the compiled loop body'
        exe = self.tc.run_assemble_stage(comp, self.cc, elem_cfg_pool=self.pool)
        P_us = period_clk * 2e-9 * 1e6
        rd = [ch for ch in exe.result_channels if ch.endswith('.rdlo')] or ['qubit_0.rdlo']
        b = dict(idx=idx, name=c['name'], n_qubits=c['n_qubits'], shots=1, rps={ch: N for ch in rd},
                 per_shot_us=N * P_us, loop_n=N, interval_us=float(c['dt_inter_shot']) * 1e6, period_us=P_us,
                 period_src='compile', calib_n='' if n_cal is None else N,
                 cmd_bytes_max=max(len(d.data if hasattr(d, 'data') else bytes(d))
                                   for n, d in exe.get_binaries_fromboard().items() if 'command' in n))
        return exe, b

    def readout_sim(self, n_q, per_shot_us):
        key = (n_q, round(per_shot_us, 3))
        if key in self.cache:
            return self.cache[key]
        delay_s = max(per_shot_us * 1e-6 - RO_READOUT_S, 1e-6)
        prog = [{'name': 'delay', 't': delay_s}, *[{'name': 'read', 'qubit': [f'qubit_{j}']} for j in range(n_q)]]
        qg = {f'qubit_{j}': {f'qubit_{j}.rdrv', f'qubit_{j}.rdlo'} for j in range(n_q)}
        comp = self.tc.run_compile_stage(prog, self.fpga, self.qchip, compiler_flags={'schedule': True},
                                         qubit_grouping=qg, proc_grouping=[('{qubit}.rdrv', '{qubit}.rdlo')])
        exe = self.tc.run_assemble_stage(comp, self.cc)
        self.cache[key] = exe
        return exe


def cmd_bytes_logical(exe):
    return sum(len(d.data if hasattr(d, 'data') else bytes(d)) for n, d in exe.get_binaries_fromboard().items() if 'command' in n)


def active_channels(exe):
    return sorted(int(''.join(ch for ch in n.split('.')[0] if ch.isdigit())) for n in exe.result_channels if n.endswith('.rdlo'))


# ---------------- board helpers ----------------
def rpc_proxy():
    import xmlrpc.client
    return xmlrpc.client.ServerProxy(f'http://{BOARD}:{RPC_PORT}', allow_none=True)


def prep_tables(exe, others=()):
    """Warm-up half of the [warmup, measured] pair: dsp resets + env/freq loads on the Python path (outside
    the timed interval). Same call for every mode. `others`: further executables of the same batch whose
    env/freq tables are merged in (pooled batches: every core any job uses must hold the pool tables, since
    per-job stores are off — plan C3, scout finding 2026-09-01)."""
    d = exe.to_dict()
    merged = dict(d['program_binaries'])
    for o in others:
        for name, b in o.to_dict()['program_binaries'].items():
            low = name.lower()
            if 'command' in low:
                continue
            if name in merged and merged[name] != b:
                raise RuntimeError(f'prep_tables: table {name} differs between jobs (not pooled?)')
            merged.setdefault(name, b)
    d['program_binaries'] = merged
    rpc_proxy().ddr_batch_prepare(d, True, True)


class StrmSession:
    """dma_server plain STRM (C1 uplink): `STRM <total> <base>`, chunks, C3 trailer with t_last_read_ns."""
    def __init__(self, total_bytes, wr_base=0, timeout=3600.0, shot_done_ends=True, sizes=None):
        self.total = total_bytes
        self.s = socket.create_connection((BOARD, 8080), timeout=timeout)
        # "SD": the C1 gateware's SHOT_DONE ends the stream on the PS (no host FINL inside the timed interval);
        # "SDK <K>" + K u32 sizes: K circuits in one session (C1 batches, PS-sequenced)
        if sizes is not None:
            self.s.sendall(f'STRM {total_bytes} {wr_base} SDK {len(sizes)}'.encode())
        else:
            self.s.sendall(f'STRM {total_bytes} {wr_base}{" SD" if shot_done_ends else ""}'.encode())
        self.t_last_read_ns = self.sb_max = self.sb_tot = 0
        ack = self._rx(2)                      # dma_server answers "OK" before the first chunk
        if ack != b'OK':
            raise RuntimeError(f'dma_server STRM rejected: {ack!r}')
        if sizes is not None:
            self.s.sendall(struct.pack(f'<{len(sizes)}I', *sizes))
        self.data = None

    def _rx(self, n):
        buf = bytearray(n); v = memoryview(buf); p = 0
        while p < n:
            r = self.s.recv_into(v[p:])
            if r == 0:
                raise RuntimeError('dma_server closed')
            p += r
        return bytes(buf)

    def recv_all(self):
        out = bytearray()
        while True:
            size, = struct.unpack('<I', self._rx(4))
            if size == 0:
                break
            if size == 0xFFFFFFFF:
                raise RuntimeError(f'STRM error after {len(out)}/{self.total} B')
            if size == 0xFFFFFFFE:
                self.sb_max, self.sb_tot, self.t_last_read_ns = struct.unpack('<3Q', self._rx(24))
                n, = struct.unpack('<I', self._rx(4)); self._rx(48 * n)
                continue
            out += self._rx(size)
        if len(out) != self.total:
            raise RuntimeError(f'STRM returned {len(out)} B, expected {self.total}')
        self.data = bytes(out)
        return self.data

    def finl(self):
        try:
            self.s.sendall(b'FINL')
        except OSError:
            pass

    def close(self):
        self.s.close()


# ---------------- modes ----------------
class Runner:
    def __init__(self, a):
        from qubic.std_client import StdServerClient
        self.a = a
        self.bench = load_bench()
        self.progs = Programs(a.gw, a.num_ch, pool_tables=getattr(a, 'pool_tables', False))
        self.progs.build_pool()
        self.progs.seg_cap = getattr(a, 'seg_cap', None) or None        # plan A0 boundary control: split geometry
        self.progs.seg_pulses = getattr(a, 'seg_pulses', None) or None
        self.progs.repeat_override = getattr(a, 'repeat_override', 0) or 0
        self.std = StdServerClient(BOARD, a.bits)
        self.bits_hash = os.path.basename(os.path.normpath(a.bits))
        self.sw_commit = subprocess.run(['git', '-C', os.environ.get('SOFTWARE_C3', '/home/yicheng/Desktop/software_c3'),
                                         'rev-parse', '--short', 'HEAD'], capture_output=True, text=True).stdout.strip()
        self.order = 0
        os.makedirs(RES, exist_ok=True)

    def circuit(self, idx):
        if getattr(self.a, 'phys', False):
            return self.progs.phys(idx, getattr(self.a, 'calib_n', None))
        b = dict(self.bench[idx])
        if self.a.real:
            exe, ps, rps = self.progs.real(idx)
            b['per_shot_us'], b['rps'] = ps, rps       # compiled per-shot (== paper column to 2 dp)
        else:
            exe = self.progs.readout_sim(b['n_qubits'], b['per_shot_us'])
            b['rps'] = {f'qubit_{j}.rdlo': 1 for j in range(b['n_qubits'])}
        return exe, b

    def _std_circuits(self, idxs, readout_ddr):
        # heterogeneous real batches load each circuit's env/freq tables inside the timed interval
        # (standard-QubiC per-job load_executable semantics); homogeneous batches and singles keep
        # the surrogate mechanism (tables preloaded once outside the interval, commands only)
        # (pooled tables are identical for every job: loaded once in the warm-up, never inside the interval)
        load_tables = self.a.real and len(set(idxs)) > 1 and not getattr(self.a, 'pool_tables', False)
        cs, meta = [], []
        for idx in idxs:
            exe, b = self.circuit(idx)
            chans = {} if readout_ddr else {f'qubit_accbuf{c}': 2 * b['rps'][f'qubit_{c}.rdlo']
                                            for c in active_channels(exe)}   # s11: 2 words per read
            cs.append({'binaries': exe.get_binaries_fromboard(), 'nshots': b['shots'], 'chans': chans,
                       'regs': {}, 'load_tables': load_tables})
            meta.append((exe, b))
        return cs, meta

    def run_std(self, idxs):
        cs, meta = self._std_circuits(idxs, False)
        prep_tables(meta[0][0], [m[0] for m in meta[1:]] if getattr(self.a, "pool_tables", False) else ())
        info, results = self.std.run_batch(cs, readout_ddr=False)
        for c, (exe, b), res in zip(cs, meta, results):
            for mem, arr in res.items():
                if len(arr) != b['shots'] * c['chans'][mem]:
                    raise RuntimeError('word count mismatch')
        return dict(t_start_ns=info['t_start_ns'], t_end_ns=info['t_end_ns'], elapsed_ms=info['elapsed_ms'],
                    cmd_bytes_transferred=4 * info['mmio_words_written'], send_block_us_max=0, send_block_us_total=0, seamless='')

    def run_c1(self, idxs):
        """One K-circuit BATCH on std_server (commands staged on the PS, circuits sequenced PS-locally: std_server
        waits for dma_server's drained count before each start) + K sequential STRM sessions (SD) on the host.
        t_start = first command store (BATCH), t_end = last DMA read of the last circuit (last STRM trailer)."""
        cs, meta = self._std_circuits(idxs, True)
        prep_tables(meta[0][0], [m[0] for m in meta[1:]] if getattr(self.a, "pool_tables", False) else ())
        box = {}
        def _batch():
            try:
                box['info'] = self.std.run_batch(cs, readout_ddr=True, timeout_s=3600)[0]
            except Exception as e:
                box['err'] = e
        sizes = [8 * b['shots'] * sum(b['rps'].values()) for exe, b in meta]
        strm = StrmSession(sum(sizes), sizes=sizes)      # one session for all K circuits, opened before the BATCH
        th = threading.Thread(target=_batch); th.start()
        strm.recv_all(); strm.close()
        t_end = strm.t_last_read_ns; sb_max = strm.sb_max; sb_tot = strm.sb_tot
        th.join(3600)
        if 'err' in box:
            raise box['err']
        info = box['info']
        return dict(t_start_ns=info['t_start_ns'], t_end_ns=t_end, elapsed_ms=(t_end - info['t_start_ns']) / 1e6,
                    cmd_bytes_transferred=4 * info['mmio_words_written'], send_block_us_max=sb_max, send_block_us_total=sb_tot, seamless='')

    def run_c3(self, idxs):
        from qubic.rpc_client import CircuitRunnerClient
        if getattr(self.a, 'phys', False) and idxs[0] in (5, 6):
            return self.run_c3_segments(idxs[0])
        exes, shots, bs = [], [], []
        for idx in idxs:
            exe, b = self.circuit(idx)
            exes.append(exe); shots.append(b['shots']); bs.append(b)
        r = CircuitRunnerClient(BOARD, RPC_PORT, ddr_cmd=True, num_ch=self.a.num_ch,
                                slot_bytes=self.progs.slot_bytes)
        stop_at = int(getattr(self.a, 'stop_at', 0) or 0)
        kw = {}
        if stop_at > 0:                                  # plan B: single-circuit early-stop run (PS-side pre-decided stop)
            assert len(exes) == 1, 'stop runs are single-circuit'
            cp_step = max(shots[0] // 10, 1)
            kw = dict(stop_after=[stop_at], checkpoint=[(cp_step, int(getattr(self.a, 'cp_ns', 0) or 0))])
        # explicit per-circuit reads_per_shot dicts (exe metadata is a constant-1 placeholder upstream)
        res = r.run_circuit_batch(exes, shots, reads_per_shot=[b['rps'] for b in bs], **kw)
        info = r.last_batch_info
        stop = None
        if stop_at > 0:
            st = (info.get('stops') or [None])[0]
            if st is None:
                raise RuntimeError('stop run without a stop record')
            expect = st['actual'] if st['result'] in ('FIRED', 'FIRED_NO_SAVING', 'NATURAL') else shots[0]
            if st['result'] == 'NATURAL' and st['actual'] != shots[0]:
                raise RuntimeError(f"NATURAL record with actual {st['actual']} != N {shots[0]}")
            if st['result'] in ('FIRED', 'FIRED_NO_SAVING') and not (st['fired_k'] * st['cp_step'] <= st['actual'] <= shots[0]):
                raise RuntimeError(f"FIRED record actual {st['actual']} outside [{st['fired_k'] * st['cp_step']}, {shots[0]}]")
            shots = [expect]
            stop = dict(stop_at=stop_at, cp_step=st['cp_step'], cp_ns_req=st['cp_ns'], delay_actual_ns=st['delay_actual_ns'],
                        stop_result=st['result'], actual_shots=st['actual'], overshoot=st['actual'] - stop_at,
                        fired_k=st.get('fired_k', ''), t_decision_ns=st['t_decision_ns'], t_write_ns=st['t_write_ns'],
                        t_event_ps_ns=st['t_event_ps_ns'], latency_cycles=st['latency_cycles'],
                        latency_us=st['latency_cycles'] / 500.0, stop_flags=st['flags'])
        for i, (b, rr) in enumerate(zip(bs, res)):
            for ch, s11 in rr.items():
                if np.asarray(s11._array).size != shots[i] * b['rps'].get(ch, 1):
                    raise RuntimeError(f"circuit {i} {ch}: {np.asarray(s11._array).size} values, "
                                       f"expected {shots[i]}x{b['rps'].get(ch, 1)}")
        # heterogeneous-table batches run as several hardware groups (grouped-reload): the interval
        # spans first send of group 0 .. last read of the last group, reloads included (plan E2)
        gstats = [g['stat'] for g in info['groups']]
        t0, t1 = gstats[0]['t_first_send_ns'], gstats[-1]['t_last_read_ns']
        return dict(t_start_ns=t0, t_end_ns=t1, elapsed_ms=(t1 - t0) / 1e6,
                    cmd_bytes_transferred=sum(g['bytes_submitted'] for g in gstats),
                    send_block_us_max=max(g['send_block_us_max'] for g in gstats),
                    send_block_us_total=sum(g['send_block_us_total'] for g in gstats),
                    seamless=int(info['mode'] == 'hardware-batch' and bool(info['groups'][0]['seamless'])),
                    n_groups=len(gstats),
                    # fixed-cost decomposition (v7 stat): first three stamps from group 0, batch_done from the last group
                    **{k: gstats[-1 if k == 't_batch_done_ns' else 0].get(k, '') for k in DECOMP_FIELDS},
                    cnr=max(int(g['cnr']) for g in info['groups']),
                    cnr_wait_cycles=max(int(g['cnr_wait_cycles']) for g in info['groups']),
                    cnr_groups=[(g['cnr'], g['cnr_wait_cycles']) for g in info['groups']],
                    **(stop or {}), **({'actual_shots_total': shots[0]} if stop else {}))

    def run_c3_segments(self, idx):
        """plan A0: oversized RB experiment idx (5/6) as a sub-circuit stream: K segment images replayed R = shots
        times (REPT); evidence = the sticky CNR flag of the whole K*R-unit batch, exact word counts, elapsed."""
        from qubic.rpc_client import CircuitRunnerClient
        import phys_split
        cap = getattr(self.progs, 'seg_cap', None) or phys_split.CAP
        segs, rep_ = self.progs._seg_cache.get((idx, cap, getattr(self.progs, 'seg_pulses', None))) or \
            phys_split.build_segments(self.progs, idx, cap=cap, max_pulses=getattr(self.progs, 'seg_pulses', None))
        if not rep_['verify_ok']:
            raise RuntimeError(f"segment split does not reproduce the unbroken program: {rep_['verify']}")
        exes = [e for e, _ in segs]; metas = [m for _, m in segs]
        R = rep_['shots']
        r = CircuitRunnerClient(BOARD, RPC_PORT, ddr_cmd=True, num_ch=self.a.num_ch, slot_bytes=self.progs.slot_bytes)
        cm = getattr(self.a, 'ch_mask', None)
        R = int(getattr(self.a, 'repeat_override', 0) or 0) or R
        res = r.run_circuit_batch(exes, [1] * len(exes), reads_per_shot=[m['rps'] for m in metas], repeat=R,
                                  ch_mask=([int(cm)] * len(exes) if cm is not None else None),
                                  prefill=int(getattr(self.a, 'prefill', 0) or 0))
        n_read_units = 0
        for u, rr in enumerate(res):
            m = metas[u % len(exes)]
            for ch, s11 in rr.items():
                if np.asarray(s11._array).size != m['rps'].get(ch, 1):
                    raise RuntimeError(f'unit {u} {ch}: {np.asarray(s11._array).size} values, expected {m["rps"].get(ch, 1)}')
            if m['rps']: n_read_units += 1
        if n_read_units != R:   # R = replay count actually used
            raise RuntimeError(f'{n_read_units} readout units, expected {R}')
        info = r.last_batch_info
        gstats = [g['stat'] for g in info['groups']]
        if len(gstats) != 1:
            raise RuntimeError(f'segment stream split into {len(gstats)} hardware groups (tables not identical?)')
        t0, t1 = gstats[0]['t_first_send_ns'], gstats[-1]['t_last_read_ns']
        self.last_segments = rep_
        return dict(t_start_ns=t0, t_end_ns=t1, elapsed_ms=(t1 - t0) / 1e6,
                    cmd_bytes_transferred=sum(g['bytes_submitted'] for g in gstats),
                    send_block_us_max=max(g['send_block_us_max'] for g in gstats),
                    send_block_us_total=sum(g['send_block_us_total'] for g in gstats),
                    seamless=int(bool(info['groups'][0]['seamless'])), n_groups=1,
                    cnr=int(info['groups'][0]['cnr']), cnr_wait_cycles=int(info['groups'][0]['cnr_wait_cycles']),
                    cnr_groups=[(g['cnr'], g['cnr_wait_cycles']) for g in info['groups']],
                    n_units=len(exes) * R, n_segments=len(exes), seg_dur_us=';'.join(f"{m['dur_us']:.3f}" for m in metas))

    def attempt(self, workload, wid, idxs, rep):
        a = self.a
        fn = {'std': self.run_std, 'c1': self.run_c1, 'c3': self.run_c3}[a.mode]
        self.order += 1
        row = dict(run_id=f'{a.tag}-{a.mode}-{wid}-r{rep}-{int(time.time())}', wall_time=time.strftime('%Y-%m-%dT%H:%M:%S'),
                   mode=a.mode, bitfile=self.bits_hash, wns_ns=a.wns, software_commit=self.sw_commit, workload=workload,
                   workload_id=wid, repeat=rep, status='ok', exclusion_reason='', n_circuits=len(idxs), tag=a.tag,
                   pool_tables=int(bool(getattr(a, 'pool_tables', False))), note=getattr(a, 'note', ''))
        pairs = [self.circuit(i) for i in idxs]
        exes, bs = [p[0] for p in pairs], [p[1] for p in pairs]
        if getattr(a, 'phys', False):                # plan A: capacity preflight, decided from bram.json, never run
            b0 = bs[0]
            row.update(loop_n=b0['loop_n'], interval_us=f"{b0['interval_us']:.3f}", period_us=f"{b0['period_us']:.4f}",
                       period_src=b0['period_src'], calib_n=b0['calib_n'], cmd_bytes_max=b0['cmd_bytes_max'])
            reason = ''
            if a.mode == 'std' and 2 * b0['loop_n'] > self.std.accbuf_len:
                reason = f"2N={2 * b0['loop_n']} words > accbuf {self.std.accbuf_len} words"
            if b0['cmd_bytes_max'] > self.progs.slot_bytes:
                reason = (reason + '; ' if reason else '') + f"{b0['cmd_bytes_max']} B > {self.progs.slot_bytes} B command slot"
            if reason:
                row['status'] = 'capacity'; row['exclusion_reason'] = reason
        row['strm_poll_us'] = getattr(a, 'strm_poll_us', '')
        row.update(shots=';'.join(str(b['shots']) for b in bs) if len(bs) > 1 else bs[0]['shots'],
                   rps=';'.join(str(max(b['rps'].values())) for b in bs) if len(bs) > 1 else max(bs[0]['rps'].values()),
                   n_active_ch=';'.join(str(len(active_channels(e))) for e in exes) if len(bs) > 1 else len(active_channels(exes[0])),
                   per_shot_us=';'.join(f"{b['per_shot_us']:.2f}" for b in bs) if len(bs) > 1 else f"{bs[0]['per_shot_us']:.2f}",
                   qpu_ms=f"{sum(b['shots'] * b['per_shot_us'] for b in bs) / 1000:.4f}",
                   cmd_bytes_logical=sum(cmd_bytes_logical(e) for e in exes),
                   readout_bytes=sum(b['shots'] * 8 * sum(b['rps'].values()) for b in bs))
        try:
            if row['status'] == 'capacity':
                raise _Capacity(row['exclusion_reason'])
            row.update(fn(idxs))
            # sanity: the interval cannot be shorter than the nominal QPU time (a stream that ended early)
            qpu_ref = float(row['qpu_ms'])
            if row.get('actual_shots_total'):             # stop run: the workload actually executed
                qpu_ref = float(row['actual_shots_total']) * bs[0]['per_shot_us'] / 1000
            if row.get('elapsed_ms') is not None and float(row['elapsed_ms']) < 0.98 * qpu_ref:
                raise RuntimeError(f"elapsed {row['elapsed_ms']:.3f} ms < QPU {qpu_ref:.4f} ms (stream ended early)")
        except _Capacity:
            pass
        except Exception as e:                       # predeclared handling: keep the row, mark it, retry once (caller)
            row['status'] = 'timeout' if 'timeout' in str(e).lower() else 'data_mismatch'
            row['exclusion_reason'] = str(e)[:200]
        phys = getattr(a, 'phys', False)
        row['pair_id'] = getattr(a, 'pair_id', ''); row['stop_at'] = row.get('stop_at', getattr(a, 'stop_at', 0) or 0)
        if getattr(a, 'stop_at', None) is not None:      # plan B rows: full and stop runs of the same pair share pair_id
            with open(os.path.join(RES, 'raw_runs_stop.csv'), 'a', newline='') as f:
                w = csv.DictWriter(f, fieldnames=RAW_FIELDS + STOP_FIELDS, extrasaction='ignore')
                if f.tell() == 0:
                    w.writeheader()
                w.writerow(row)
        out, extra = (('raw_runs_phys.csv', PHYS_FIELDS) if phys else
                      ('raw_runs_decomp.csv', DECOMP_FIELDS) if getattr(a, 'decomp', False) else ('raw_runs.csv', []))
        with open(os.path.join(RES, out), 'a', newline='') as f:
            w = csv.DictWriter(f, fieldnames=RAW_FIELDS + extra, extrasaction='ignore')
            if f.tell() == 0:
                w.writeheader()
            w.writerow(row)
        if a.mode == 'c3' and 'cnr_groups' in row:     # plan addendum: per-hardware-group CNR evidence
            with open(os.path.join(RES, 'cnr_log.csv'), 'a', newline='') as f:
                w = csv.writer(f)
                if f.tell() == 0:
                    w.writerow(['run_id', 'tag', 'workload_id', 'repeat', 'group_index', 'n_groups',
                                'cnr', 'cnr_wait_cycles', 'status'])
                for gi, (cnr, cw) in enumerate(row['cnr_groups']):
                    w.writerow([row['run_id'], a.tag, wid, rep, gi, row['n_groups'], cnr, cw, row['status']])
        print(f"[{a.mode}] {wid} r{rep}: {row['status']} elapsed={row.get('elapsed_ms')} ms qpu={row['qpu_ms']} ms", flush=True)
        return row['status'] == 'ok' or row['status'] == 'capacity'

    def run(self):
        a = self.a
        if getattr(a, 'phys', False):
            ctrl = f'_ctrl{a.seg_pulses}p_cap{a.seg_cap}' if getattr(a, 'seg_pulses', None) else ''
            if getattr(a, 'seg_cap', None) and not getattr(a, 'seg_pulses', None): ctrl = f'_cap{a.seg_cap}'
            if getattr(a, 'ch_mask', None) is not None: ctrl += f'_mask{int(a.ch_mask):x}'
            if getattr(a, 'repeat_override', 0): ctrl += f'_R{a.repeat_override}'
            if getattr(a, 'prefill', 0): ctrl += f'_prefill{a.prefill}'
            items = [('phys_cal' if a.calib_n else 'phys', f'phys{i}' + (f'_n{a.calib_n}' if a.calib_n else '') + ctrl, [i]) for i in a.idx]
        elif a.what == 'single':
            items = [('single', str(i), [i]) for i in a.idx]
        else:
            man = load_batches()
            items = [('batch', bid, man[bid]) for bid in a.batches]
        for workload, wid, idxs in items:
            # warm-up pair: one unrecorded execution loads tables/caches (D5), then the recorded repeats
            if not getattr(a, 'no_warmup', False):
                self.attempt(workload, wid, idxs, -1)
            for rep in range(a.repeats):
                if not self.attempt(workload, wid, idxs, rep):
                    if not self.attempt(workload, wid, idxs, rep):
                        print(f'!! {wid}: second failure, stopping this workload', flush=True)
                        break


def main():
    p = argparse.ArgumentParser()
    p.add_argument('--mode', required=True, choices=['std', 'c1', 'c3'])
    p.add_argument('--bits', required=True, help='bits dir (bram.json + dspregs.json) of the loaded gateware')
    p.add_argument('--gw', required=True, help='gateware build dir (gensrc/channel_config.json)')
    p.add_argument('--num-ch', type=int, default=8)
    p.add_argument('--what', default='single', choices=['single', 'batch'])
    p.add_argument('--idx', default='', help='comma list of circuit idx (single)')
    p.add_argument('--batches', default='', help='comma list of batch ids (batch)')
    p.add_argument('--repeats', type=int, default=5)
    p.add_argument('--wns', default='', help='post-route WNS of the bitfile (ns), recorded per row')
    p.add_argument('--tag', default='run')
    p.add_argument('--real', action='store_true', help='paper circuits from benchmark_qce instead of the delay+read surrogate')
    p.add_argument('--pool-tables', action='store_true', help='plan C: assemble every program against the pool-wide env/freq tables (two-pass)')
    p.add_argument('--note', default='', help='free text recorded in every row')
    p.add_argument('--phys', action='store_true', help='plan A: physics experiments from benchmark_qce/physic_experiment.py (--idx = experiment idx)')
    p.add_argument('--calib-n', type=int, default=0, help='plan A3: run the --phys experiment with this loop count (calibration series)')
    p.add_argument('--seg-cap', type=int, default=0, help='plan A0 control: segment pulse cap (default 2046)')
    p.add_argument('--ch-mask', default=None, help='diagnostic: force the CE channel mask (int, bit c = 1 -> core c masked) on the segment stream')
    p.add_argument('--repeat-override', type=int, default=0, help='diagnostic: replay count R for the segment stream (default = shots)')
    p.add_argument('--prefill', type=int, default=16, help='segment streams: GLOBAL_START only after this many units are in DDR (-1 = all; 0 = off; default 16 = the start-up head start that removed the residual boundary stalls, 2026-09-03)')
    p.add_argument('--seg-pulses', type=int, default=0, help='plan A0 control: use only the first M pulses of the RB body (capacity-fitting control)')
    p.add_argument('--stop-at', type=int, default=None, help='plan B: single-circuit early-stop run (0 = full run of a pair); rows also go to raw_runs_stop.csv')
    p.add_argument('--cp-ns', type=int, default=0, help='plan B: emulated checkpoint delay in ns (cp_step = shots // 10)')
    p.add_argument('--pair-id', default='', help='plan B: pair identifier shared by the full and stop run')
    p.add_argument('--strm-poll-us', default='', help='plan B: dma_server STRM_POLL_US in effect (recorded)')
    p.add_argument('--decomp', action='store_true', help='fixed-cost decomposition: rows (with the v7 stage timestamps) go to raw_runs_decomp.csv')
    p.add_argument('--no-warmup', action='store_true', help='plan B pairs: skip the warm-up attempt (the sequence file schedules warm-ups explicitly)')
    a = p.parse_args()
    a.idx = [int(x) for x in a.idx.split(',') if x.strip()]
    a.calib_n = a.calib_n or None
    if a.prefill == -1: a.prefill = 0xFFFFFFFF
    a.batches = [x for x in a.batches.split(',') if x.strip()]
    Runner(a).run()


if __name__ == '__main__':
    main()
