#!/usr/bin/env python3
"""Plan A driver (run matrix A2 + calibration A3 + the 5/6 sub-circuit streams + the unsplit/split boundary control).
Cells: for each experiment and configuration: warm-up + 3 complete runs (--repeats 3 through antq_runner --phys).
Calibration series (results/calib_sequence.csv, 3 randomized blocks x 3 counts) for #1/#3/#4 on c3 and c1.
Images: c3 cells on 63329aaf; c1/std cells on 0071783e_14q (switch via run_pool_campaign.switch_image).
std_server needs SS_CHUNK_TIMEOUT_S >= 200 for the 100 s shots (deployed with deploy_servers.sh)."""
import csv, os, subprocess, sys, time, argparse
HERE = os.path.dirname(os.path.abspath(__file__)); RES = os.environ.get('ANTQ_RESULTS', os.path.join(HERE, '..', '..', 'results'))   # <repo>/results
sys.path.insert(0, HERE)
import run_pool_campaign as C
LOG = open(os.path.join(RES, 'phys_campaign.log'), 'a')
def log(m):
    line = f'{time.strftime("%Y-%m-%dT%H:%M:%S")} {m}'; print(line, flush=True); LOG.write(line + '\n'); LOG.flush()
def cell(image, mode, idx, repeats, tag, calib_n=None, note='', extra=()):
    cmd = [sys.executable, os.path.join(HERE, 'antq_runner.py'), '--phys', '--mode', mode, '--bits', C.GW[image], '--gw', C.GW[image], '--num-ch', '14',
           '--what', 'single', '--idx', str(idx), '--repeats', str(repeats), '--wns', C.WNS[image], '--tag', tag, '--note', note] + (['--calib-n', str(calib_n)] if calib_n else []) + list(extra)
    for att in range(1, 4):
        r = subprocess.run(cmd, cwd=HERE, env=C.ENV, capture_output=True, text=True, timeout=7200)
        lines = [l for l in r.stdout.split('\n') if l.startswith(f'[{mode}]') or 'failure' in l]
        log(f'{image} {mode} phys{idx}{f"_n{calib_n}" if calib_n else ""} attempt {att} rc={r.returncode}\n' + '\n'.join(lines)[-800:] + ('\nSTDERR: ' + r.stderr[-600:] if r.returncode else ''))
        if r.returncode == 0 and 'second failure' not in r.stdout: return True
        C.restart_service()
    return False
def main():
    ap = argparse.ArgumentParser(); ap.add_argument('--part', default='all', help='c3|c1std|all'); a = ap.parse_args()
    calib = list(csv.DictReader(open(os.path.join(RES, 'calib_sequence.csv'))))
    EXP = {'vion_1': 1, 'yan_3': 3, 'riste_4': 4}
    if a.part in ('c3', 'all'):
        C.switch_image('C3')
        for idx in (1, 2, 3, 4): cell('C3', 'c3', idx, 3, 'c3_14q_phys1')
        for r in calib: cell('C3', 'c3', EXP[r['exp']], 1, 'c3_14q_physcal1', calib_n=int(r['count']), note=f"calib block={r['block']} seq={r['seq']}")
        for idx in (5, 6): cell('C3', 'c3', idx, 3, 'c3_14q_phys1')
        # boundary dead-time control (plan A0, Codex part-A #1): 1800-pulse prefix of #5, unsplit (1 unit/shot) vs split (2 units/shot)
        cell('C3', 'c3', 5, 3, 'c3_14q_physctrl1', extra=['--seg-pulses', '1800', '--seg-cap', '1802'])
        cell('C3', 'c3', 5, 3, 'c3_14q_physctrl1', extra=['--seg-pulses', '1800', '--seg-cap', '902'])
    if a.part in ('c1std', 'all'):
        C.switch_image('C1')
        for idx in (1, 2, 3, 4): cell('C1', 'c1', idx, 3, 'c1_14q_phys1')
        for r in calib: cell('C1', 'c1', EXP[r['exp']], 1, 'c1_14q_physcal1', calib_n=int(r['count']), note=f"calib block={r['block']} seq={r['seq']}")
        for idx in (1, 2, 3, 4): cell('C1', 'std', idx, 3 if idx == 2 else 1, 'std_14q_phys1')     # 1/3/4: capacity rows (repeat 0 recorded)
        C.switch_image('C3')
    log('phys campaign done')
if __name__ == '__main__':
    main()
