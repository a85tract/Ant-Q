"""Plan C2(a)-(c) preflight (software only): pooled vs native assembly of the 20 paper circuits.
(a) the deployed grouping predicate (qubic.rpc_client.group_compatible) on all 32 manifests: REQUIRE 1 group;
(b) semantic remap check at the binary level: per circuit and channel, the native and pooled command streams
    must be identical after masking the env_word and freq index fields of pulse commands, and every pulse's
    envelope bytes / frequency entry looked up through the native table at the native address must equal the
    bytes looked up through the pooled table at the pooled address;
(c) audit inventory in results/pool_tables/: both binaries with SHA-256, decoded per-pulse maps, diffs, commits.
Exit code 0 only if (a) and (b) pass."""
import sys, os, json, hashlib, subprocess, csv
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import antq_runner
from distproc.command_gen import opcodes, pulse_field_pos as FP, pulse_field_widths as FW
from qubic.rpc_client import group_compatible

GW = sys.argv[1]; OUT = os.path.join(antq_runner.RES, 'pool_tables'); os.makedirs(OUT, exist_ok=True)
NAT = antq_runner.Programs(GW, 14, pool_tables=False)
POO = antq_runner.Programs(GW, 14, pool_tables=True); POO.build_pool()
cc = json.load(open(os.path.join(GW, 'gensrc', 'channel_config.json')))
PULSE = {opcodes['pulse_write'], opcodes['pulse_write_trig']}
ENV_EN = 1 << (FP['env_word'] + 25); FREQ_EN = 1 << (FP['freq'] + 10)
ENV_MASK = ((1 << FW['env_word']) - 1) << FP['env_word']
FREQ_MASK = ((1 << FW['freq']) - 1) << FP['freq']

def binaries(exe):
    return {n: bytes(d.data if hasattr(d, 'data') else d) for n, d in exe.get_binaries_fromboard().items()}
def cmds(b):
    return [int.from_bytes(b[i:i+16], 'little') for i in range(0, len(b), 16)]
def chan_of(name):            # 'qubit_command3' -> ('qubit_3', 'qdrv') ; env/freq names 'qubit_qdrv_env3'
    digits = ''.join(ch for ch in name if ch.isdigit()); return int(digits)
def unit_samples(chan_key):   # envelope address unit in samples
    p = cc[chan_key]['elem_params']; return int(p['samples_per_clk'] / p['interp_ratio'])

report = {'groups': {}, 'circuits': {}, 'fail': []}
sha = {}
for idx in antq_runner.IDX20:
    en, _, _ = NAT.real(idx); ep, _, _ = POO.real(idx)
    bn, bp = binaries(en), binaries(ep)
    for k, v in bn.items(): sha[f'native/{idx}/{k}'] = hashlib.sha256(v).hexdigest()
    for k, v in bp.items(): sha[f'pooled/{idx}/{k}'] = hashlib.sha256(v).hexdigest()
    cinfo = {'channels': {}, 'pulses_checked': 0}
    if set(bn) != set(bp):
        report['fail'].append(f'{idx}: binary name sets differ'); continue
    for name in sorted(bn):
        if 'command' not in name.lower(): continue
        core = chan_of(name)
        cn, cp = cmds(bn[name]), cmds(bp[name])
        if len(cn) != len(cp):
            report['fail'].append(f'{idx} {name}: command count {len(cn)} vs {len(cp)}'); continue
        # element within the core is encoded in the cfg field of the pulse command (elem_ind: 0 qdrv, 1 rdrv, 2 rdlo)
        pulses = 0
        for j, (a, b) in enumerate(zip(cn, cp)):
            if a == b: continue
            opc = (a >> 123) & 0x1F
            if opc not in PULSE or (a & ~(ENV_MASK | FREQ_MASK)) != (b & ~(ENV_MASK | FREQ_MASK)):
                report['fail'].append(f'{idx} {name} cmd {j}: non-index difference (opcode {opc})'); continue
            elem = (a >> FP['cfg']) & ((1 << FW['cfg']) - 1)
            elem_name = {0: 'qdrv', 1: 'rdrv', 2: 'rdlo'}[elem]
            chan_key = f'qubit_{core}.{elem_name}'
            ekey, fkey = f'qubit_{elem_name}_env{core}', f'qubit_{elem_name}_freq{core}'
            ew_n, ew_p = (a >> FP['env_word']) & ((1 << FW['env_word']) - 1), (b >> FP['env_word']) & ((1 << FW['env_word']) - 1)
            fw_n, fw_p = (a >> FP['freq']) & ((1 << FW['freq']) - 1), (b >> FP['freq']) & ((1 << FW['freq']) - 1)
            u = unit_samples(chan_key)
            if a & ENV_EN:
                nclk_n, nclk_p = ew_n >> 12, ew_p >> 12
                if nclk_n != nclk_p:
                    report['fail'].append(f'{idx} {name} cmd {j}: env length differs {nclk_n} vs {nclk_p}')
                nbytes = max(nclk_n, 1) * u * 4
                an, ap = (ew_n & 0xFFF) * u * 4, (ew_p & 0xFFF) * u * 4
                if bn[ekey][an:an+nbytes] != bp[ekey][ap:ap+nbytes]:
                    report['fail'].append(f'{idx} {name} cmd {j}: envelope bytes differ at native {an} / pooled {ap}')
            if a & FREQ_EN:
                if bn[fkey][fw_n*64:(fw_n+1)*64] != bp[fkey][fw_p*64:(fw_p+1)*64]:
                    report['fail'].append(f'{idx} {name} cmd {j}: frequency entry differs {fw_n} vs {fw_p}')
            pulses += 1
        cinfo['channels'][name] = {'n_cmds': len(cn), 'pulses_remapped': pulses}
        cinfo['pulses_checked'] += pulses
    report['circuits'][idx] = cinfo
    for k, v in bp.items():
        open(os.path.join(OUT, f'pooled_{idx}_{k.replace(":", "")}.bin'), 'wb').write(v)
    for k, v in bn.items():
        open(os.path.join(OUT, f'native_{idx}_{k.replace(":", "")}.bin'), 'wb').write(v)
# (a) grouping predicate on the 32 manifests with pooled executables
for bid, idxs in antq_runner.load_batches().items():
    groups, _ = group_compatible([POO.real(i)[0] for i in idxs])
    report['groups'][bid] = len(groups)
    if len(groups) != 1: report['fail'].append(f'{bid}: {len(groups)} groups')
# pooled tables identical across programs?
tab = {}
for idx in antq_runner.IDX20:
    for k, v in binaries(POO.real(idx)[0]).items():
        if 'command' in k.lower(): continue
        tab.setdefault(k, set()).add(hashlib.sha256(v).hexdigest())
report['pooled_tables_distinct'] = {k: len(v) for k, v in tab.items() if len(v) > 1}
if report['pooled_tables_distinct']: report['fail'].append('pooled tables not identical across programs')
sw = lambda d: subprocess.run(['git', '-C', d, 'rev-parse', '--short', 'HEAD'], capture_output=True, text=True).stdout.strip()
report['commits'] = {'software_c3': sw('/home/yicheng/Desktop/software_c3'),
                     'distproc_copy': '/home/yicheng/Desktop/Ryan_project/clean_software/distributed_processor (patched 2026-09-01: GlobalAssembler elem_cfg_pool)',
                     'gw_build': GW}
report['pool_order'] = antq_runner.IDX20
json.dump(sha, open(os.path.join(OUT, 'sha256.json'), 'w'), indent=1)
json.dump(report, open(os.path.join(OUT, 'preflight_report.json'), 'w'), indent=1)
print('groups per manifest:', report['groups'])
print('pulses checked:', sum(c['pulses_checked'] for c in report['circuits'].values()))
print('FAILURES:', report['fail'][:20] if report['fail'] else 'none')
sys.exit(1 if report['fail'] else 0)
