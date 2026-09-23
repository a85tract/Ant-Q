#!/usr/bin/env python3
"""Plan B3 driver: consumes results/stop_sequence.csv (pre-generated: per circuit one warm-up of each condition, then
5 consecutive full/stop pairs with a 3/2 first-condition split). Each run = one antq_runner invocation (--real, c3,
single circuit, repeats 0 with the run marked warmup/measure by tag/pair_id). cp_ns = 1000 x mean of the 5 ARM
checkpoint costs (CP_US_ARM below = the ARM medians in
results/bench/early_stop_kernel/bench_early_stop_results_arm.csv, rounded to 0.01 us). Pair integrity (plan B4): if either member of a pair
fails, both members are re-run consecutively (max 3 pair attempts). Optional STRM_POLL_US sweep: pass --poll 0 to
record runs under sched_yield cadence (the service must have been restarted with STRM_POLL_US=0)."""
import csv, os, subprocess, sys, time, argparse
HERE = os.path.dirname(os.path.abspath(__file__)); RES = os.environ.get('ANTQ_RESULTS', os.path.join(HERE, '..', '..', 'results'))   # <repo>/results
# Site values come from site_env.sh (see site_env.sh.example): no host, address or path is hard-coded here.
BOARD_SSH = os.environ.get('ANTQ_BOARD_SSH', 'board')          # ssh destination of the board
SUDO = os.environ.get('ANTQ_SUDO', 'sudo -n')                  # privileged-command prefix on the board
BOARD_SW = os.environ.get('ANTQ_BOARD_SW', '')                 # the board's software tree
ENV = dict(os.environ, PYTHONPATH=os.environ['ANTQ_SOFTWARE'])
GW = os.environ['ANTQ_GW_C3']                                  # gateware build dir of the image under test
CP_US_ARM = {2: [5.98, 5.98, 5.98, 5.98, 5.98], 9: [3.50, 3.55, 3.57, 3.57, 3.56], 10: [12.79, 12.81, 12.83, 12.87, 12.89],
             19: [834.12, 836.62, 839.44, 842.50, 845.61], 22: [822.64, 823.03, 823.46, 823.73, 824.05], 23: [215.51, 217.14, 218.89, 220.16, 220.67]}
LOG = open(os.path.join(RES, 'stop_campaign.log'), 'a')
def log(m):
    line = f'{time.strftime("%Y-%m-%dT%H:%M:%S")} {m}'; print(line, flush=True); LOG.write(line + '\n'); LOG.flush()
def run(idx, stop_at, pair_id, tag, poll, rep_index):
    cp_ns = int(round(1000 * sum(CP_US_ARM[idx]) / 5))
    warm = rep_index < 0
    cmd = [sys.executable, os.path.join(HERE, 'antq_runner.py'), '--real', '--mode', 'c3', '--bits', GW, '--gw', GW, '--num-ch', '14',
           '--what', 'single', '--idx', str(idx), '--repeats', '0' if warm else '1', '--wns', os.environ.get('ANTQ_WNS_C3', '0.000'), '--tag', tag, '--stop-at', str(stop_at),
           '--cp-ns', str(cp_ns if stop_at > 0 else 0), '--pair-id', pair_id, '--strm-poll-us', str(poll), '--note', f'stop_campaign rep={rep_index}'] + ([] if warm else ['--no-warmup'])
    r = subprocess.run(cmd, cwd=HERE, env=ENV, capture_output=True, text=True, timeout=1800)
    line = [l for l in r.stdout.split('\n') if l.startswith('[c3]')]
    ok = r.returncode == 0 and line and ' ok ' in line[-1]
    log(f'idx {idx} stop_at {stop_at} pair {pair_id} -> {"ok" if ok else "FAIL"} | {line[-1] if line else r.stderr[-300:]}')
    return ok
def restart_dma(poll_us):
    """restart dma_server as root with STRM_POLL_US=<poll_us>, pinned to core 3 like the service start script (2026-09-20: two
    busy-polling servers sharing a core made poll-0 stop/drain latencies erratic); setsid + bash -c so it survives the ssh session
    (a plain nohup in a subshell died with the session: all 01:22 sweep runs got 'connection reset by peer');
    readiness = the board's own listening socket (the ssh tunnel accepts connects even when the port is closed)."""
    # anchored pattern: an unanchored 'scripts/dma_server' also matched THIS ssh shell and killed it (01:26 sweep)
    cmd = (f"{SUDO} pkill -f '^{BOARD_SW}/scripts/dma_server$'; sleep 1; "
           f"{SUDO} bash -c 'STRM_POLL_US={poll_us} setsid taskset -c 3 {BOARD_SW}/scripts/dma_server > {BOARD_SW}/scripts/dma_server_poll{poll_us}.log 2>&1 < /dev/null &'; "
           f"for i in $(seq 1 30); do ss -ltn 2>/dev/null | grep -q ':8080 ' && break; sleep 1; done; sleep 2; "
           f"ss -ltn | grep ':8080 '; pgrep -fa 'scripts/dma_server' | grep -v pgrep; tail -2 {BOARD_SW}/scripts/dma_server_poll{poll_us}.log")
    out = subprocess.run(['ssh', '-o', 'ConnectTimeout=60', BOARD_SSH, cmd], capture_output=True, text=True, timeout=300).stdout
    log(f'dma_server restarted with STRM_POLL_US={poll_us}: {out.strip()[-300:]}')
    if ':8080' not in out:
        raise RuntimeError('dma_server did not come up')
def main():
    ap = argparse.ArgumentParser(); ap.add_argument('--poll', default='200'); ap.add_argument('--tag', default='c3_14q_stop1'); ap.add_argument('--only', default='')
    ap.add_argument('--set-poll', action='store_true', help='restart dma_server with STRM_POLL_US=--poll before the runs')
    ap.add_argument('--max-pairs', type=int, default=0, help='acceptance: run only the first N measured pairs (0 = all)')
    a = ap.parse_args()
    if a.set_poll: restart_dma(int(a.poll))
    seq = list(csv.DictReader(open(os.path.join(RES, 'stop_sequence.csv'))))
    only = [int(x) for x in a.only.split(',') if x]
    # warm-ups (repeats -1 semantics: recorded with tag *_warmup so they never enter the analysis)
    pairs = {}
    for r in seq:
        idx = int(r['idx'])
        if only and idx not in only: continue
        if r['run_kind'] == 'warmup':
            run(idx, int(r['stop_at']) if r['condition'] == 'stop' else 0, '', a.tag + '_warmup', a.poll, -1); continue
        pairs.setdefault(r['pair_id'], []).append(r)
    failed = []
    for pid, members in list(pairs.items())[:a.max_pairs or None]:
        members.sort(key=lambda r: int(r['position']))
        for att in range(1, 4):
            ok = all(run(int(r['idx']), int(r['stop_at']) if r['condition'] == 'stop' else 0, pid, a.tag, a.poll, att) for r in members)
            if ok: break
            log(f'pair {pid} attempt {att} failed -> restart services and re-run BOTH members')
            subprocess.run(['ssh', '-o', 'ConnectTimeout=60', BOARD_SSH, f'{SUDO} systemctl restart qubic_rpc_server.service'], capture_output=True, timeout=300); time.sleep(40)
            if a.set_poll: restart_dma(int(a.poll))          # keep the sweep's cadence after a service restart
        else: failed.append(pid)
    log('stop campaign done' + (f'; {len(failed)} pair(s) FAILED after 3 attempts: {failed}' if failed else ''))
    if failed: sys.exit(1)
if __name__ == '__main__':
    main()
