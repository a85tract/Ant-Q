#!/usr/bin/env python3
"""Plan C4 campaign driver: consumes results/pool_sequence.csv (generated before execution by make_sequences.py)
and runs each (block, image, config, manifest) cell = warm-up + 5 repeats through antq_runner.py, switching the
board image (C1 = 0071783e_14q for std/c1 configs, C3 = 63329aaf for c3_pool) exactly where the sequence says.
Failure handling (plan C5): a runner invocation that reports a second failure gets the services restarted and the
cell retried, at most 3 attempts; every attempt stays in raw_runs.csv. Progress: results/pool_campaign.log."""
import csv, os, subprocess, sys, time, collections
HERE = os.path.dirname(os.path.abspath(__file__)); RES = os.environ.get('ANTQ_RESULTS', os.path.join(HERE, '..', '..', 'results'))   # <repo>/results
ENV = dict(os.environ, PATH=os.path.expanduser('~/anaconda3/envs/qubic_clean/bin') + ':' + os.environ['PATH'],
           PYTHONPATH=os.environ.get('SOFTWARE_C3', '/home/yicheng/Desktop/software_c3'))   # the software checkout (submodule `software`)
GW = {'C1': os.environ.get('ANTQ_GW_C1', '/home/yicheng/gateware_yguang_check/gw_build_c1/top/zcu216_14_2/build_0071783e_20260829023649'),   # gateware build dirs (bram.json, dspregs.json,
      'C3': os.environ.get('ANTQ_GW_C3', '/home/yicheng/gateware_yguang_check/gw_build_c3_8s/top/zcu216_14_2/build_63329aaf_20260830175903')}  # gensrc/channel_config.json) of the two images
XSA = {'C1': '0071783e_14q', 'C3': '63329aaf'}
WNS = {'C1': '0.002', 'C3': '0.000'}
CFG = {'std_native': ('std', False), 'std_pool': ('std', True), 'c1_native': ('c1', False), 'c1_pool': ('c1', True), 'c3_pool': ('c3', True)}
TAG = {'std_native': 'std_14q_native_pool1', 'std_pool': 'std_14q_pool1', 'c1_native': 'c1_14q_native_pool1', 'c1_pool': 'c1_14q_pool1', 'c3_pool': 'c3_14q_pool1'}
LOG = open(os.path.join(RES, 'pool_campaign.log'), 'a')
def log(m):
    line = f'{time.strftime("%Y-%m-%dT%H:%M:%S")} {m}'; print(line, flush=True); LOG.write(line + '\n'); LOG.flush()
def ssh(cmd, timeout=300):
    return subprocess.run(['ssh', '-o', 'ConnectTimeout=60', 'computerC', cmd], capture_output=True, text=True, timeout=timeout).stdout
def restart_service():
    t = ssh("date +%H:%M:%S; echo xilinx | sudo -S systemctl restart qubic_rpc_server.service 2>/dev/null").split('\n')[0]
    for _ in range(60):
        if 'RPC server running' in ssh(f"journalctl -u qubic_rpc_server.service --since '{t}' -n 300 --no-pager 2>/dev/null | grep 'RPC server running'"):
            break
        time.sleep(5)
    # std_server is not part of the service: (re)start it as root with the long single-shot timeout; a nohup inside a
    # plain subshell died with the ssh session (deploy 00:25 -> no std_server for 35 min), so use setsid + bash -c
    ssh("pgrep -f 'std_server' >/dev/null || (cd /home/xilinx/software/scripts && echo xilinx | sudo -S bash -c 'cd /home/xilinx/software/scripts; SS_CHUNK_TIMEOUT_S=300 setsid ./std_server > std_server.log 2>&1 < /dev/null &'); sleep 2; pgrep -fa 'std_server' | grep -v pgrep")
    # bounded journal query: a full-journal scan on the board took > 5 min (dry run 2026-09-01)
    log('service restarted; ' + ssh("journalctl -u qubic_rpc_server.service --no-pager -n 300 2>/dev/null | grep 'loading bitfile' | tail -1; pgrep -fa 'std_server|dma_server|batch_server' | grep -v pgrep | tr '\\n' ' '").strip())
def switch_image(img):
    cur = ssh("grep xsa_commit /home/xilinx/server_config.yaml").strip()
    if XSA[img] in cur:
        log(f'image already {img} ({cur})'); return
    ssh(f"sed -i \"s/^xsa_commit:.*/xsa_commit: '{XSA[img]}'/\" /home/xilinx/server_config.yaml")
    log(f'switching image -> {img} ({XSA[img]})'); restart_service()
def run_cell(image, cfg, manifest, block, seq0, attempts=3):
    mode, pooled = CFG[cfg]
    for att in range(1, attempts + 1):
        cmd = [sys.executable, os.path.join(HERE, 'antq_runner.py'), '--real', '--mode', mode, '--bits', GW[image], '--gw', GW[image],
               '--num-ch', '14', '--what', 'batch', '--batches', manifest, '--repeats', '5', '--wns', WNS[image], '--tag', TAG[cfg],
               '--note', f'block={block} seq={seq0} cfg={cfg} attempt={att}'] + (['--pool-tables'] if pooled else [])
        r = subprocess.run(cmd, cwd=HERE, env=ENV, capture_output=True, text=True, timeout=7200)
        tail = '\n'.join(l for l in r.stdout.split('\n') if l.startswith(f'[{mode}]') or 'failure' in l)[-600:]
        log(f'{image} {cfg} {manifest} block {block} attempt {att} rc={r.returncode}\n{tail}')
        if r.returncode == 0 and 'second failure' not in r.stdout:
            return True
        log('cell failed -> restart services and retry' if att < attempts else 'cell INCOMPLETE after 3 attempts')
        restart_service()
    return False
def main():
    rows = list(csv.DictReader(open(os.path.join(RES, 'pool_sequence.csv'))))
    cells = collections.OrderedDict()
    for r in rows:
        cells.setdefault((int(r['block']), r['image'], r['config'], r['manifest']), int(r['seq']))
    start = int(sys.argv[1]) if len(sys.argv) > 1 else 0     # resume: first cell index to run
    log(f'campaign start: {len(cells)} cells, from cell {start}')
    cur_img = None; cur_mode = None
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
        run_cell(image, cfg, manifest, block, seq0)
    log('campaign done; leaving the board on C3')
    switch_image('C3')
if __name__ == '__main__':
    main()
