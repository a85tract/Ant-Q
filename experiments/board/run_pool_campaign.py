#!/usr/bin/env python3
"""Plan C4 campaign driver: consumes results/pool_sequence.csv (generated before execution by make_sequences.py)
and runs each (block, image, config, manifest) cell = warm-up + 5 repeats through antq_runner.py, switching the
board image (C1 = 0071783e_14q for std/c1 configs, C3 = ANTQ_XSA_C3 for c3_pool) exactly where the sequence says.
Failure handling (plan C5): a runner invocation that reports a second failure gets the services restarted and the
cell retried, at most 3 attempts; every attempt stays in raw_runs.csv. Progress: results/pool_campaign.log."""
import csv, os, subprocess, sys, time, collections
HERE = os.path.dirname(os.path.abspath(__file__)); RES = os.environ.get('ANTQ_RESULTS', os.path.join(HERE, '..', '..', 'results'))   # <repo>/results
# Site values come from site_env.sh (see site_env.sh.example): no host, address or path is hard-coded here.
BOARD_SSH = os.environ.get('ANTQ_BOARD_SSH', 'board')          # ssh destination of the board
SUDO = os.environ.get('ANTQ_SUDO', 'sudo -n')                  # privileged-command prefix on the board
BOARD_SW = os.environ.get('ANTQ_BOARD_SW', '')                 # the board's software tree
BOARD_CFG = os.environ.get('ANTQ_BOARD_CFG', '')               # the qubic server config the service reads
PY = os.environ.get('ANTQ_PY', 'python3')                      # host interpreter with the qubic client importable
ENV = dict(os.environ, PYTHONPATH=os.environ['ANTQ_SOFTWARE'])   # the host client checkout (submodule `software`)
GW = {'C1': os.environ['ANTQ_GW_C1'],                          # gateware build dirs (bram.json, dspregs.json,
      'C3': os.environ['ANTQ_GW_C3']}                          # gensrc/channel_config.json) of the two images
XSA = {'C1': '0071783e_14q', 'C3': os.environ['ANTQ_XSA_C3']}   # slot names on the board (ANTQ_XSA_C3 = ANTQ_IMG, set by recampaign_env.sh)
WNS = {'C1': '0.002', 'C3': os.environ.get('ANTQ_WNS_C3', '0.000')}            # sign-off WNS recorded per row (ANTQ_WNS_C3 for the re-campaign image)
CFG = {'std_native': ('std', False), 'std_pool': ('std', True), 'c1_native': ('c1', False), 'c1_pool': ('c1', True), 'c3_pool': ('c3', True)}
TAG = {'std_native': 'std_14q_native_pool1', 'std_pool': 'std_14q_pool1', 'c1_native': 'c1_14q_native_pool1', 'c1_pool': 'c1_14q_pool1', 'c3_pool': 'c3_14q_pool1'}
LOG = open(os.path.join(RES, 'pool_campaign.log'), 'a')
def log(m):
    line = f'{time.strftime("%Y-%m-%dT%H:%M:%S")} {m}'; print(line, flush=True); LOG.write(line + '\n'); LOG.flush()
def ssh(cmd, timeout=300):
    return subprocess.run(['ssh', '-o', 'ConnectTimeout=60', BOARD_SSH, cmd], capture_output=True, text=True, timeout=timeout).stdout
def restart_service():
    t = ssh(f"date +%H:%M:%S; {SUDO} systemctl restart qubic_rpc_server.service 2>/dev/null").split('\n')[0]
    for _ in range(60):
        if 'RPC server running' in ssh(f"journalctl -u qubic_rpc_server.service --since '{t}' -n 300 --no-pager 2>/dev/null | grep 'RPC server running'"):
            break
        time.sleep(5)
    # std_server is not part of the service: (re)start it as root with the long single-shot timeout; a nohup inside a
    # plain subshell died with the ssh session (deploy 00:25 -> no std_server for 35 min), so use setsid + bash -c
    ssh(f"pgrep -f 'std_server' >/dev/null || (cd {BOARD_SW}/scripts && {SUDO} bash -c 'cd {BOARD_SW}/scripts; SS_CHUNK_TIMEOUT_S=300 setsid ./std_server > std_server.log 2>&1 < /dev/null &')")
    # bounded journal query: a full-journal scan on the board took > 5 min (dry run 2026-09-01)
    log('service restarted; ' + ssh("journalctl -u qubic_rpc_server.service --no-pager -n 300 2>/dev/null | grep 'loading bitfile' | tail -1; pgrep -fa 'std_server|dma_server|batch_server' | grep -v pgrep | tr '\\n' ' '").strip())
def verify_image(img):
    """read-only acceptance after any overlay change (2026-09-18): configured xsa_commit, the bitfile the service actually
    loaded, and the PS-PL clock (our software forces PL0 to 100 MHz; 136 MHz means the guard did not run). Returns the
    verification line and raises if the loaded image is not the expected one."""
    cur = ssh(f"grep '^xsa_commit' {BOARD_CFG}").strip()
    # journal of the CURRENT service activation only (bounded; a fixed -n window misses the start lines once the RPC log grows)
    since = "--since \"$(systemctl show qubic_rpc_server.service -p ActiveEnterTimestamp --value)\""
    loaded = ssh(f"journalctl -u qubic_rpc_server.service {since} --no-pager 2>/dev/null | grep 'loading bitfile' | tail -1").strip()
    pl0 = ssh(f"journalctl -u qubic_rpc_server.service {since} --no-pager 2>/dev/null | grep -i 'PL0\\|pl_clk' | tail -1").strip()
    line = f'image check [{img}]: config {cur!r} | loaded {loaded!r} | pl0 {pl0!r}'
    log(line)
    if XSA[img] not in cur or XSA[img] not in loaded:          # an empty 'loaded' is a failed verification, not a pass
        raise RuntimeError(f'image verification FAILED for {img}: {line}')
    return line
def switch_image(img):
    cur = ssh(f"grep xsa_commit {BOARD_CFG}").strip()
    if XSA[img] in cur:
        log(f'image already {img} ({cur})'); verify_image(img); return
    ssh(f"sed -i \"s/^xsa_commit:.*/xsa_commit: '{XSA[img]}'/\" {BOARD_CFG}")
    log(f'switching image -> {img} ({XSA[img]})'); restart_service(); verify_image(img)
def run_cell(image, cfg, manifest, block, seq0, attempts=3):
    mode, pooled = CFG[cfg]
    for att in range(1, attempts + 1):
        cmd = [sys.executable, os.path.join(HERE, 'antq_runner.py'), '--real', '--mode', mode, '--bits', GW[image], '--gw', GW[image],
               '--num-ch', '14', '--what', 'batch', '--batches', manifest, '--repeats', '5', '--wns', WNS[image], '--tag', TAG[cfg],
               '--note', f'block={block} seq={seq0} cfg={cfg} attempt={att}'] + (['--pool-tables'] if pooled else [])
        r = subprocess.run(cmd, cwd=HERE, env=ENV, capture_output=True, text=True, timeout=7200)
        tail = '\n'.join(l for l in r.stdout.split('\n') if l.startswith(f'[{mode}]') or 'failure' in l)[-600:]
        log(f'{image} {cfg} {manifest} block {block} attempt {att} rc={r.returncode}\n{tail}' + ('\nSTDERR: ' + r.stderr[-600:] if r.returncode else ''))
        if r.returncode == 0 and 'second failure' not in r.stdout:
            return True
        log('cell failed -> restart services and retry' if att < attempts else 'cell INCOMPLETE after 3 attempts')
        restart_service()
    return False
def main():
    rows = list(csv.DictReader(open(os.path.join(RES, 'pool_sequence.csv'))))
    cells = collections.OrderedDict()
    # acceptance subset (2026-09-18 re-campaign step 2e): POOL_ONLY_MANIFEST / POOL_ONLY_CFGS restrict the run to one manifest / listed configs
    om = os.environ.get('POOL_ONLY_MANIFEST', ''); oc = [c for c in os.environ.get('POOL_ONLY_CFGS', '').split(',') if c]
    for r in rows:
        if (om and r['manifest'] != om) or (oc and r['config'] not in oc): continue
        cells.setdefault((int(r['block']), r['image'], r['config'], r['manifest']), int(r['seq']))
    start = int(sys.argv[1]) if len(sys.argv) > 1 else 0     # resume: first cell index to run
    log(f'campaign start: {len(cells)} cells, from cell {start}')
    cur_img = None; cur_mode = None; incomplete = []
    for i, ((block, image, cfg, manifest), seq0) in enumerate(cells.items()):
        if i < start: continue
        if image != cur_img:
            switch_image(image); cur_img = image; cur_mode = None
        mode = CFG[cfg][0]
        if cur_mode is not None and mode != cur_mode:
            # C1 image: a std run leaves acc events in the DDR ring that poison the next c1 SDK session (memory
            # reference_antq_rerun_traps); the 22:25 rand30_t4 warm-up lost 10 min to it -> restart between modes
            log(f'mode change {cur_mode} -> {mode}: restarting services'); restart_service()
        cur_mode = mode
        log(f'--- cell {i}/{len(cells)}: block {block} {image} {cfg} {manifest}')
        if not run_cell(image, cfg, manifest, block, seq0): incomplete.append((block, image, cfg, manifest))
    log('campaign done; leaving the board on C3' + (f'; {len(incomplete)} INCOMPLETE cell(s): {incomplete}' if incomplete else ''))
    switch_image('C3')
    if incomplete: sys.exit(1)
if __name__ == '__main__':
    main()
