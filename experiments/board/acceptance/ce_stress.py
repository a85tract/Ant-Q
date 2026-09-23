"""CE stress with structural signatures (2026-09-17): back-to-back K=3 batches whose three units differ in structure
(loops 1/2/3 -> reads per shot) and in which core is the used one (mask patterns: core 0 used = 0xFE, core 7 used =
0x7F, or full fetch 0). A unit that executes a stale/neighbouring image returns the wrong record count (data
mismatch) or zeros; a unit that never runs wedges the batch (RPC timeout). Counts everything, never asserts.
usage: python ce_stress.py [n_batches=600] [pattern=fe,7f,00]    (env GW_BUILD, RPC_HOST, RPC_PORT)
Writes one row per batch to $ANTQ_RESULTS/stress_K<K>.csv (batch, K, mask, outcome, seamless, last_boundary_wait_cycles, note)."""
import sys, time, collections, socket, traceback, subprocess, os, csv
from concurrent.futures import ThreadPoolExecutor, TimeoutError as FutTimeout
WATCHDOG_S = float(os.environ.get('STRESS_TIMEOUT_S', '25'))
socket.setdefaulttimeout(float(os.environ.get('STRESS_TIMEOUT_S', '25')))   # a wedged batch shows up as a 25-s RPC timeout
from integ_test_lib import *
from integ_test_lib import _compile
import numpy as np
N = int(sys.argv[1]) if len(sys.argv) > 1 else 600
PAT = (sys.argv[2] if len(sys.argv) > 2 else 'fe,7f,00').split(',')
qchip = build_qchip()
def one_core(core, loops):
    q = f'qubit_{core}'
    body = [{'name': 'read', 'qubit': [q]}, {'name': 'alu', 'op': 'add', 'lhs': 1, 'rhs': 'i', 'out': 'i'}]
    prog = [{'name': 'declare', 'var': 'i', 'dtype': 'int', 'scope': ALL}, {'name': 'set_var', 'var': 'i', 'value': 0},
            {'name': 'loop', 'cond_lhs': loops, 'cond_rhs': 'i', 'alu_cond': 'ge', 'scope': ALL, 'body': body}]
    exe = _compile(prog, qchip)
    for ch, rc in exe.result_channels.items():
        if ch.endswith('.rdlo'): rc.reads_per_shot = loops
    return exe, q + '.rdlo'
exes = {}
for core in (0, 7):
    for loops in (1, 2, 3): exes[(core, loops)] = one_core(core, loops)
full = [compile_readout(l) for l in (1, 2, 3)]          # all 8 cores read (mask 0)
BOARD_SSH = os.environ['ANTQ_BOARD_SSH']; SUDO = os.environ.get('ANTQ_SUDO', 'sudo -n')   # site_env.sh
def recover():
    # PL reload by service restart, wait for the RPC banner, new client
    subprocess.run(['ssh', '-o', 'ConnectTimeout=8', BOARD_SSH, f"{SUDO} systemctl restart qubic_rpc_server.service 2>/dev/null"], timeout=90)
    # wait for a banner NEWER than the restart (an older banner from a previous restart must not count)
    t_restart = subprocess.run(['ssh', '-o', 'ConnectTimeout=8', BOARD_SSH, "date +%s"], capture_output=True, text=True, timeout=30).stdout.strip()
    for _ in range(45):
        time.sleep(2)
        rc = subprocess.run(['ssh', '-o', 'ConnectTimeout=8', BOARD_SSH, f"journalctl -u qubic_rpc_server.service --since @{t_restart} --no-pager 2>/dev/null | grep -q 'RPC server running'"], timeout=30).returncode
        if rc == 0: break
    time.sleep(3)
    return runner()
r = runner(); pool = ThreadPoolExecutor(1)
K = int(os.environ.get('STRESS_K', '3'))   # units per batch (3 = T11-like; 1 = single-unit batches)
n_shots = [3, 2, 4][:K]; loops_seq = [1, 2, 3][:K]
c = collections.Counter(); anomalies = []; t0 = time.time(); durs = []
_out = open(os.path.join(os.environ.get('ANTQ_RESULTS', '.'), f'stress_K{K}.csv'), 'w', newline=''); _csv = csv.writer(_out)
_csv.writerow(['batch', 'K', 'mask', 'outcome', 'seamless', 'last_boundary_wait_cycles', 'note'])
def row(*v): _csv.writerow(v); _out.flush()
for b in range(N):
    pat = PAT[b % len(PAT)]
    if pat == 'fe': ex = [exes[(0, l)][0] for l in loops_seq]; chs = [exes[(0, l)][1] for l in loops_seq]; kw = {}
    elif pat == '7f': ex = [exes[(7, l)][0] for l in loops_seq]; chs = [exes[(7, l)][1] for l in loops_seq]; kw = {}
    else: ex = full[:K]; chs = ['qubit_0.rdlo'] * K; kw = {'ch_mask': 0}
    t1 = time.time()
    try:
        fut = pool.submit(r.run_circuit_batch, ex, n_shots, **kw)
        try: res = fut.result(timeout=WATCHDOG_S)
        except FutTimeout: pool = ThreadPoolExecutor(1); raise TimeoutError(f'watchdog {WATCHDOG_S}s')   # abandon the hung thread
    except Exception as e:
        prev = PAT[(b - 1) % len(PAT)] if b else None
        c[f'exc_{pat}'] += 1; anomalies.append((b, pat, 'exception', repr(e)[:120], 'prev', prev)); print(f'batch {b} {pat} (prev {prev}): EXCEPTION {repr(e)[:120]}', flush=True)
        row(b, K, pat, 'wedge' if (isinstance(e, (socket.timeout, TimeoutError)) or 'timed out' in repr(e)) else 'exception', '', '', repr(e)[:120])
        if isinstance(e, (socket.timeout, TimeoutError)) or 'timed out' in repr(e):
            c[f'wedge_{prev}->{pat}'] += 1; print(f'WEDGE at batch {b} transition {prev}->{pat}; register dump, then recovery (service restart)', flush=True)
            try:
                import base64; sp = os.environ.get('ANTQ_REGDUMP_SCRIPT')      # optional: a register-dump script run on the board as root
                if not sp: raise RuntimeError('ANTQ_REGDUMP_SCRIPT not set: no register dump')
                b64 = base64.b64encode(open(sp, 'rb').read()).decode()
                dump = subprocess.run(['ssh', '-o', 'ConnectTimeout=8', BOARD_SSH, f"{SUDO} sh -c 'echo {b64} | base64 -d | python3 -' 2>/dev/null"], capture_output=True, text=True, timeout=60).stdout
                print('REGDUMP at wedge (FULL):\n' + '\n'.join('  ' + l for l in dump.splitlines() if 'password' not in l), flush=True)
            except Exception as e3: print('regdump failed', repr(e3)[:120], flush=True)
            try: r = recover()
            except Exception as e2: print('recovery failed', repr(e2)[:120], flush=True); break
        elif isinstance(e, (ConnectionResetError, ConnectionRefusedError, BrokenPipeError)) or 'Connection' in repr(e):
            c['conn_errors'] += 1; time.sleep(3)
            try: r = runner()
            except Exception: pass
            if c['conn_errors'] > 30: print('too many connection errors, stopping', flush=True); break
        continue
    durs.append(time.time() - t1)
    info = r.last_batch_info or {}; n_anom = len(anomalies)
    if info.get('seamless') is False: c[f'nonseamless_{pat}'] += 1
    masks = info.get('ch_mask')
    # expected auto mask = every core except the one that reads (8_2: 0xFE / 0x7F; 14_2: 0x3FFE / 0x3F7F)
    if pat == 'fe' and masks != [((1 << NUM_CH) - 1) & ~1] * K: c[f'maskmismatch_{pat}'] += 1; anomalies.append((b, pat, 'mask', masks))
    if pat == '7f' and masks != [((1 << NUM_CH) - 1) & ~(1 << 7)] * K: c[f'maskmismatch_{pat}'] += 1; anomalies.append((b, pat, 'mask', masks))
    for i in range(K):
        ok_shape = (n_shots[i], loops_seq[i])
        if chs[i] not in res[i]: c[f'missingch_{pat}'] += 1; anomalies.append((b, pat, i, 'missing channel', list(res[i])[:3])); continue
        a = res[i][chs[i]]; a = np.asarray(a._array if hasattr(a, '_array') else a)
        if a.shape != ok_shape: c[f'shape_{pat}'] += 1; anomalies.append((b, pat, i, 'shape', a.shape, ok_shape))
        z = int(np.count_nonzero(a == 0))
        if z: c[f'zeros_{pat}'] += z; anomalies.append((b, pat, i, 'zeros', z, a.shape))
        if pat == '00':
            nch = len(res[i]);
            if nch != NUM_CH: c[f'nch_{pat}'] += 1; anomalies.append((b, pat, i, 'nch', nch))
    c[f'ok_{pat}'] += 1
    row(b, K, pat, 'ok', int(bool(info.get('seamless'))), info.get('cnr_wait_cycles', ''), '; '.join(str(a[2:]) for a in anomalies[n_anom:]))
    if (b + 1) % 100 == 0: print(f'{b+1} batches: {dict(c)}; mean batch {np.mean(durs):.3f} s; {time.time()-t0:.0f} s', flush=True)
_out.close()
print('CE STRESS', dict(N=N, batches_done=len(durs), counts=dict(c), elapsed=round(time.time() - t0, 1)))
for a in anomalies[:40]: print('  anomaly', a)
