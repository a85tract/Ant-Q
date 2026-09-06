"""Plan-fixed execution sequences (generated BEFORE execution, consumed by the runners):
results/pool_sequence.csv (C4: 5 blocks, seeds 43 assignment / 47 manifest order), results/stop_sequence.csv
(B3: 5 consecutive pairs per circuit, 3/2 split, seed 44, pair_id), results/calib_sequence.csv (A3: seed 46),
results/smoke_sequence.csv (C2(d): N P P N fixed), results/batch_manifest_provenance.csv (C6)."""
import csv, random, collections, sys, os
os.chdir(os.path.dirname(os.path.abspath(__file__)) + '/..')
# --- provenance
rows = list(csv.DictReader(open('results/batch_manifest.csv')))
by = collections.OrderedDict()
for r in rows: by.setdefault(r['batch_id'], []).append(int(r['circuit_idx']))
pool20 = [1,2,3,4,5,6,7,8,9,10,11,12,13,19,20,21,22,23,24,25]
random.seed(42); regen = {f'rand{k}_t{t}': random.choices(pool20, k=k) for k in (10,20,30) for t in range(10)}
with open('results/batch_manifest_provenance.csv','w') as f:
    w = csv.writer(f); w.writerow(['batch_id','generator','ordered_draws','multiplicities','rejection_or_filtering','regeneration_matches'])
    for b, draws in regen.items():
        w.writerow([b, 'random.seed(42); random.choices(pool20, k=k) for k in (10,20,30) for t in range(10), pool20 = the 20 paper idx',
                    ' '.join(map(str, draws)), ' '.join(f'{i}:{c}' for i, c in sorted(collections.Counter(draws).items())), 'none', draws == by[b]])
    for b in ('ghz8_x30', 'qaoa12_x30'):
        w.writerow([b, 'homogeneous: 30 x idx ' + str(by[b][0]), ' '.join(map(str, by[b])), f'{by[b][0]}:30', 'none', True])
assert all(regen[b] == by[b] for b in regen)
# --- pool sequence: 5 blocks, exactly 2 of each k per block, homogeneous in different blocks
random.seed(43)
blocks = {i: [] for i in range(5)}
for k in (10, 20, 30):
    ids = [f'rand{k}_t{t}' for t in range(10)]; random.shuffle(ids)
    for i in range(5): blocks[i] += ids[2*i:2*i+2]
hb = random.sample(range(5), 2); blocks[hb[0]].append('ghz8_x30'); blocks[hb[1]].append('qaoa12_x30')
C1_CFGS = ['std_native', 'std_pool', 'c1_native', 'c1_pool']
random.seed(47)
with open('results/pool_sequence.csv','w') as f:
    w = csv.writer(f); w.writerow(['seq','block','image','config','manifest','run_kind','repeat']); seq = 0
    for b in range(5):
        c3_first = (b % 2 == 0)
        rot = C1_CFGS[b % 4:] + C1_CFGS[:b % 4]
        images = [('C3', ['c3_pool']), ('C1', rot)]
        if not c3_first: images.reverse()
        for image, cfgs in images:
            for cfg in cfgs:
                order = blocks[b][:]; random.shuffle(order)
                for m in order:
                    for kind, rep in [('warmup', -1)] + [('measure', r) for r in range(5)]:
                        w.writerow([seq, b, image, cfg, m, kind, rep]); seq += 1
print('pool_sequence rows', seq, 'blocks', {b: blocks[b] for b in blocks})
# --- stop sequence: six circuits, 5 consecutive pairs, 3 first-condition of one kind (seed 44)
STOP = [(2,'GHZ-3',8192,2457),(9,'GHZ-6',128,60),(10,'GHZ-8',32,12),(19,'VQE BeH2 14Q',4096,1227),(22,'QML Image Class 14Q',400,120),(23,'VQE SrH PDM 12Q',4000,1200)]
random.seed(44)
with open('results/stop_sequence.csv','w') as f:
    w = csv.writer(f); w.writerow(['seq','idx','name','shots','stop_at','pair_id','position','condition','run_kind']); seq = 0
    for idx, name, shots, stop_at in STOP:
        for cond in ('full', 'stop'): w.writerow([seq, idx, name, shots, stop_at, '', 0, cond, 'warmup']); seq += 1
        first = random.choice(['full', 'stop']); firsts = [first]*3 + [('stop' if first=='full' else 'full')]*2; random.shuffle(firsts)
        for pid, fst in enumerate(firsts):
            for pos, cond in enumerate([fst, 'stop' if fst == 'full' else 'full']):
                w.writerow([seq, idx, name, shots, stop_at, f'{idx}_p{pid}', pos, cond, 'measure']); seq += 1
print('stop_sequence rows', seq)
# --- calibration order (seed 46): per experiment, 3 blocks x 3 counts randomized
feas = {r['exp']: r for r in csv.DictReader(open('results/calib_feasibility.csv')) if r['verdict'] == 'FEASIBLE'}
random.seed(46)
with open('results/calib_sequence.csv','w') as f:
    w = csv.writer(f); w.writerow(['seq','exp','block','count']); seq = 0
    for exp, r in feas.items():
        D = int(r['D']); counts = [1000, 1000 + D // 2, 1000 + D]
        for b in range(3):
            order = counts[:]; random.shuffle(order)
            for c in order: w.writerow([seq, exp, b, c]); seq += 1
print('calib_sequence rows', seq, 'feasible:', list(feas))
with open('results/smoke_sequence.csv','w') as f:
    w = csv.writer(f); w.writerow(['seq','program','run','condition']); seq = 0
    for prog in ('bell', 'grover', 'x90cal'):
        for i, c in enumerate('NPPN'): w.writerow([seq, prog, i, 'native' if c == 'N' else 'pooled']); seq += 1
print('smoke_sequence written')
