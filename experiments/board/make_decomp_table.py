#!/usr/bin/env python3
"""make_decomp_table.py -- single-circuit fixed-cost decomposition from results/raw_runs_decomp.csv (batch_server v7
stage timestamps, CLOCK_MONOTONIC ns on the PS) joined with results/per_shot_realized_real.csv (realized shot length).

Stages (us), per run:
  upload   = t_first_dma_done - t_start        PS -> DDR image DMA (all channels' command images, one MM2S per unit)
  start    = t_start_written - t_first_dma_done   PS config-FIFO write + GLOBAL_START decision
  launch   = t_first_cid - t_start_written     PL pops the config, fetches the image into the command buffer, DSP starts
                                               (+ PS detection latency of cur_cid, sched_yield poll)
  exec_res = (t_batch_done - t_first_cid) - shots x P     execution beyond the nominal QPU time; P = compiled or realized
  drain    = t_end - t_batch_done              last readout words DDR -> PS memory + dma_server detection (STRM_POLL_US)
  fixed    = elapsed - shots x P_realized      = upload + start + launch + exec_res(realized) + drain
Output: results/table_decomp.csv (per tag x circuit: n, mean, sd of every stage) and a markdown print.
"""
import csv, statistics as st, sys
from collections import defaultdict
from pathlib import Path

RES = Path(__file__).resolve().parent.parent.parent / 'results'
P_real = {r['idx']: (float(r['per_shot_compiled_us']), float(r['per_shot_c1_slope_us']), r['name'])
          for r in csv.DictReader(open(RES / 'per_shot_realized_real.csv'))}
STAGES = ['upload', 'start', 'launch', 'exec_res_compiled', 'exec_res_realized', 'drain', 'fixed_realized', 'fixed_compiled']

rows = [r for r in csv.DictReader(open(RES / 'raw_runs_decomp.csv')) if r['status'] == 'ok' and r['t_batch_done_ns']
        and not r['tag'].endswith('smoke')]
cells = defaultdict(list)
for r in rows:
    idx = r['workload_id']; shots = int(r['shots']); pc, pr, _ = P_real[idx]
    t0 = int(r['t_start_ns']); d = {k: (int(r[k + '_ns']) - t0) / 1e3 for k in ('t_first_dma_done', 't_start_written', 't_first_cid', 't_batch_done', 't_end')}
    exe = d['t_batch_done'] - d['t_first_cid']
    s = dict(upload=d['t_first_dma_done'], start=d['t_start_written'] - d['t_first_dma_done'], launch=d['t_first_cid'] - d['t_start_written'],
             exec_res_compiled=exe - shots * pc, exec_res_realized=exe - shots * pr, drain=d['t_end'] - d['t_batch_done'],
             fixed_realized=d['t_end'] - shots * pr, fixed_compiled=d['t_end'] - shots * pc)
    poll = r['note'].split('STRM_POLL_US=')[-1].split()[0] if 'STRM_POLL_US=' in r['note'] else ''
    cells[(r['tag'], poll, idx)].append(s)

out = []
for (tag, poll, idx), ss in sorted(cells.items(), key=lambda kv: (kv[0][0], int(kv[0][2]))):
    pc, pr, name = P_real[idx]; shots = next(int(r['shots']) for r in rows if r['workload_id'] == idx)
    row = dict(tag=tag, strm_poll_us=poll, idx=idx, name=name, shots=shots, per_shot_compiled_us=pc, per_shot_realized_us=pr,
               qpu_realized_ms=round(shots * pr / 1e3, 4), n=len(ss))
    for k in STAGES:
        v = [x[k] for x in ss]; row[k + '_us'] = round(st.mean(v), 1); row[k + '_sd_us'] = round(st.stdev(v), 1) if len(v) > 1 else 0.0
    row['fixed_realized_pct'] = round(100 * row['fixed_realized_us'] / (shots * pr), 3)
    row['res_compiled_per_shot_ns'] = round(1e3 * row['exec_res_compiled_us'] / shots, 1)   # the realized-shot-length offset, per shot
    row['launch_plus_exec_res_us'] = round(row['launch_us'] + row['exec_res_realized_us'], 1)   # PL launch + end flush; robust to the first-cid detection latency
    out.append(row)
with open(RES / 'table_decomp.csv', 'w', newline='') as f:
    w = csv.DictWriter(f, fieldnames=list(out[0].keys())); w.writeheader(); w.writerows(out)

print('| tag | idx | circuit | shots | n | upload | start | launch | exec res (compiled P) | per shot (ns) | exec res (realized P) | launch+exec res | drain | fixed (realized) | fixed % of QPU |')
print('|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|')
for r in out:
    f = lambda k: f"{r[k + '_us']:.1f} ± {r[k + '_sd_us']:.1f}"
    print(f"| {r['tag']} | {r['idx']} | {r['name']} | {r['shots']} | {r['n']} | {f('upload')} | {f('start')} | {f('launch')} | {f('exec_res_compiled')} | {r['res_compiled_per_shot_ns']} | {f('exec_res_realized')} | {r['launch_plus_exec_res_us']} | {f('drain')} | {f('fixed_realized')} | {r['fixed_realized_pct']:.2f} |")
for tag in sorted({r['tag'] for r in out}):
    sub = [r for r in out if r['tag'] == tag]
    print(f"\n{tag}: median over circuits (us): " + ', '.join(f"{k} {st.median(r[k + '_us'] for r in sub):.1f}" for k in STAGES))
