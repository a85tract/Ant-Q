"""Export the exact QubiC pulses that qcal plays for one qubit's X90 and Meas, as JSON (numeric envelopes as [re, im]).

Run ON the device host with Neel's environment (read-only; writes only the output file):
    <operator python> export_qcal_pulses.py <config_dir> <qubit> <out.json>
    e.g. ... <operator calibration config dir> 6 <out.json>
<config_dir> must hold config.yaml, qubic_cfg.json, channel_config.json (qcal's settings.config_path).
The output feeds aqt_programs.patch_qchip() through the runner's ANTQ_QCHIP_PATCH.
"""
import os, sys, json, os
import numpy as np

cfgdir, qubit, out_path = sys.argv[1].rstrip('/'), int(sys.argv[2]), sys.argv[3]
import qcal.settings as settings
settings.Settings.config_path = cfgdir + '/'
from qcal.config import Config
cfg = Config(os.path.join(cfgdir, 'config.yaml')); cfg.load()
from qcal.backend.qubic.transpiler import cycle_pulse
from qcal.circuit import Cycle
from qcal.gate.single_qubit import X90, Meas


def ser(o):
    if isinstance(o, np.ndarray):
        return {'__ndarray__': [[float(x.real), float(x.imag)] for x in o], 'dtype': str(o.dtype)}
    if isinstance(o, (np.floating, np.integer)):
        return o.item()
    raise TypeError(type(o))


out = {'source': cfgdir, 'config_mtime': os.path.getmtime(os.path.join(cfgdir, 'config.yaml')), 'qubit': qubit,
       'T1': cfg[f'single_qubit/{qubit}/GE/T1'], 'T2*': cfg[f'single_qubit/{qubit}/GE/T2*'],
       'freq': cfg[f'single_qubit/{qubit}/GE/freq'], 'readfreq': cfg[f'readout/{qubit}/freq'],
       'passive_reset': cfg['reset/passive/delay'], 'herald': cfg['readout/herald']}
for name, cyc in (('X90', Cycle({X90(qubit)})), ('Meas', Cycle({Meas(qubit)}))):
    out[name] = cycle_pulse(cfg, cyc)
    for pp in out[name]:
        print(name, json.dumps({k: (f'ndarray[{len(v)}]' if isinstance(v, np.ndarray) else v) for k, v in pp.items()}, default=str)[:200])
json.dump(out, open(os.path.expanduser(out_path), 'w'), default=ser)
print('saved', out_path)
