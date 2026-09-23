"""Cycle count of the command-buffer HANDOVER in the full plsv_v2b design (real dsp + cmd_sequencer + ping-pong bundle):
K=3 back-to-back circuits, channel 0 = [phase_reset, pulse A (200 ns square on qubit_0.qdrv at start_time T0), done],
other channels null. Per clk500 cycle we log the DAC output (any lane nonzero), the dsp shot FSM (state/procdone_r/nobusy_r/done),
dspif.lastshotdone, the sequencer's ppbuf_read_finished / stb_start, v2b_all_ready and the CNR wait counter; then print, for
each boundary, the cycle offsets from the last DAC sample of circuit k to every event up to the first DAC sample of circuit k+1.
Definitions (match the oscilloscope handover measurement in results/bench/handover_scope): H = (B_start_dac - A_end_dac) - T0 = the boundary cost excluding the
program's own first-pulse offset. A second test measures the dsp's native inter-SHOT gap (nshots=2, no sequencer involvement).
Run: cd plsv && make -f Makefile_v2b MODULE=test_plsv_v2b_handover   (Verilator, ~2 min)"""
import re
import numpy as np
import cocotb
from cocotb.triggers import RisingEdge, ClockCycles
import distproc.assembler as asm
from qubic.rfsoc.hwconfig import RFSoCElementCfg, load_channel_configs
from test_plsv_v2b_cnr import _i, drive_clock, lb3_load, lb2_write, _cmd_words, _pack_beats, build_bram_map, GEN, NUM_CH, LB2

T0 = 2000            # qclk: long enough that the next unit's fetch (~840 cyc) completes during the pulse wait -> seamless boundary
ENV_SAMPLES = 1600   # 16 samples per clk500 -> 100 cycles = 200 ns square pulse (like the bench marker)


def _prog(ccfgs, start_time=None):
    chans = ['qubit_0.qdrv', 'qubit_0.rdrv', 'qubit_0.rdlo']
    q0 = {k: v for k, v in ccfgs.items() if k in chans}
    elem = {k: RFSoCElementCfg(**v.elem_params) for k, v in q0.items()}
    p = asm.SingleCoreAssembler(q0, elem)
    p.add_phase_reset()
    if start_time is not None:
        p.add_pulse(100.e6, 0, 0.9, start_time, 0.2 * np.ones(ENV_SAMPLES) + 1j * 0.1 * np.ones(ENV_SAMPLES), 'qubit_0.qdrv')
    p.add_done_stb()
    return p.get_program_binaries()


def probe(dut, path):
    obj = dut
    for part in path.split('.'):
        obj = getattr(obj, part)
    return obj


async def run(dut, K, nshots, ncyc):
    ccfgs = load_channel_configs(f'{GEN}/channel_config.json'); bram_map = build_bram_map(f'{GEN}/ifbramctrl.sv')
    exe = _prog(ccfgs, T0); cmdw = _cmd_words(exe); nullw = _cmd_words(_prog(ccfgs, None))
    for s, h in (('clk100', 5.0), ('clk500', 1.0), ('clk250', 2.0), ('clk333', 1.5)):
        cocotb.start_soon(drive_clock(getattr(dut, s), h))
    for s in ('lb2_wren','lb2_rden','lb3_wren','lb3_rden','s_axis_cmd_tvalid','n_shots_enable','global_start','circuit_id_reset','rd_start','adc0_tvalid','cnr_reset','stop_en','idle_load'):
        getattr(dut, s).value = 0
    for s in ('lb2_waddr','lb2_wdata','lb2_raddr','lb3_waddr','lb3_wdata','lb3_raddr','s_axis_cmd_tdata','n_shots','wr_base_addr','rd_base_addr','rd_size_bytes','adc0_tdata','stop_cid','ch_mask'):
        getattr(dut, s).value = 0
    dut.m_axis_tready.value = 1; dut.max_bank_size.value = 0xF; dut.last_circuit_id.value = K - 1
    dut.aresetn.value = 0; await ClockCycles(dut.clk500, 30); dut.aresetn.value = 1; await ClockCycles(dut.clk500, 30)
    for r in ('dspreset', 'resetacc', 'reset_bram_read'):
        await lb2_write(dut, LB2[r], 1); await lb2_write(dut, LB2[r], 0)
    for name, data in exe.get_binaries_fromboard().items():
        if 'command' in name.lower() or name not in bram_map: continue
        d = data.data if hasattr(data, 'data') else data
        await lb3_load(dut, bram_map[name], np.frombuffer(d, dtype=np.dtype('<u4')))
    await ClockCycles(dut.clk500, 20)
    for ci in range(K):
        await RisingEdge(dut.clk333)
        dut.n_shots.value = nshots; dut.n_shots_enable.value = 1
        await RisingEdge(dut.clk333); dut.n_shots_enable.value = 0
        for c in range(NUM_CH):
            for bv in _pack_beats(cmdw if c == 0 else nullw):
                dut.s_axis_cmd_tdata.value = bv; dut.s_axis_cmd_tvalid.value = 1
                await RisingEdge(dut.clk333)
                while not _i(dut.s_axis_cmd_tready): await RisingEdge(dut.clk333)
        dut.s_axis_cmd_tvalid.value = 0
    # probes (any that Verilator did not expose are reported and skipped)
    names = {'lastshotdone': 'u_plsv.dspif.lastshotdone', 'stb_start': 'u_plsv.dspif.stb_start', 'state': 'u_plsv.dsp.state',
             'done': 'u_plsv.dsp.done', 'procdone_r': 'u_plsv.dsp.procdone_r', 'nobusy_r': 'u_plsv.dsp.nobusy_r',
             'read_finished': 'u_plsv.ppbuf_read_finished', 'all_ready': 'u_plsv.v2b_all_ready', 'cnr_wait': 'cnr_wait_counter',
             'batch_done': 'v2b_batch_done'}
    sig = {}
    for k, p in names.items():
        try: sig[k] = probe(dut, p); _i(sig[k])
        except Exception as e: dut._log.info(f"probe {k} ({p}) unavailable: {e}"); sig.pop(k, None)
    n_dac = len(dut.obs_dac)
    rows = {k: [] for k in sig}; dac_nz = []
    await RisingEdge(dut.clk333); dut.global_start.value = 1
    for cyc in range(ncyc):
        await RisingEdge(dut.clk500)
        if cyc == 4: dut.global_start.value = 0
        dac_nz.append(int(any(_i(dut.obs_dac[i]) != 0 for i in range(n_dac))))
        for k, s in sig.items(): rows[k].append(_i(s))
    dac = np.array(dac_nz); R = {k: np.array(v) for k, v in rows.items()}
    return dac, R, sig


def rises(a):
    a = np.asarray(a).astype(int); return list(np.flatnonzero((a[1:] != 0) & (a[:-1] == 0)) + 1)


def report(dut, dac, R, K, nshots, label):
    nz = np.flatnonzero(dac)
    if not len(nz): raise AssertionError('no DAC output')
    # pulse intervals = runs of consecutive nonzero cycles (gaps > 2 cycles separate pulses)
    breaks = np.flatnonzero(np.diff(nz) > 2); starts = [nz[0]] + [nz[b + 1] for b in breaks]; ends = [nz[b] for b in breaks] + [nz[-1]]
    dut._log.info(f"[{label}] {len(starts)} DAC pulses: starts {starts} ends {ends} (cycles; width {[e - s + 1 for s, e in zip(starts, ends)]})")
    ev = {k: rises(v) for k, v in R.items() if k in ('lastshotdone', 'stb_start', 'done', 'procdone_r', 'nobusy_r', 'batch_done')}
    rf = rises((R['read_finished'] != 0).astype(int)) if 'read_finished' in R else []
    ar_low = np.flatnonzero(R['all_ready'] == 0) if 'all_ready' in R else np.array([])
    dut._log.info(f"[{label}] events (cycle): stb_start {ev.get('stb_start')} | procdone_r {ev.get('procdone_r')} | nobusy_r {ev.get('nobusy_r')} | done {ev.get('done')} | lastshotdone {ev.get('lastshotdone')} | read_finished {rf} | batch_done {ev.get('batch_done')}")
    if 'state' in R:
        st = R['state']; ch = np.flatnonzero(np.diff(st) != 0) + 1
        dut._log.info(f"[{label}] dsp state changes (cycle:new_state): {[(int(c), int(st[c])) for c in ch][:60]}")
    if len(ar_low): dut._log.info(f"[{label}] all_ready LOW cycles: {len(ar_low)} (first {ar_low[:10].tolist()})")
    if 'cnr_wait' in R: dut._log.info(f"[{label}] cnr_wait_counter max {int(R['cnr_wait'].max())}")
    out = []
    for b in range(len(starts) - 1):
        a_end, b_start = ends[b], starts[b + 1]
        def first_after(lst, t): 
            c = [x for x in lst if x > t]; return c[0] if c else None
        d = dict(boundary=b, A_end=int(a_end), B_start=int(b_start), gap=int(b_start - a_end - 1))
        for k in ('procdone_r', 'nobusy_r', 'done', 'lastshotdone', 'stb_start'):
            t = first_after(ev.get(k, []), a_end); d[k] = (int(t - a_end) if t is not None else None)
        t = first_after(rf, a_end); d['read_finished'] = (int(t - a_end) if t is not None else None)
        d['H_cycles'] = int(b_start - a_end - 1) - T0 + 0      # handover = DAC gap - the program's own start_time (T0 qclk); see docstring
        out.append(d)
        dut._log.info(f"[{label}] boundary {b}: A_end {a_end} -> procdone_r +{d['procdone_r']} nobusy_r +{d['nobusy_r']} done +{d['done']} lastshotdone +{d['lastshotdone']} read_finished +{d['read_finished']} stb_start +{d['stb_start']} -> B_start +{b_start - a_end} ; DAC gap {d['gap']} cycles; H = gap - T0 = {d['H_cycles']} cycles = {2 * d['H_cycles']} ns")
    # first-pulse latency: stb_start(1) -> A_start(1) - T0 = processor start + DAC pipeline
    if ev.get('stb_start'):
        L = starts[0] - ev['stb_start'][0] - T0; dut._log.info(f"[{label}] first circuit: stb_start -> first DAC sample = T0 + {L} cycles (processor start + element/DAC pipeline)")
    return out


@cocotb.test()
async def test_handover_k3(dut):
    K = 3
    dac, R, sig = await run(dut, K, 1, ncyc=3 * (T0 + 400) + 3000)
    out = report(dut, dac, R, K, 1, 'K3 nshots=1')
    assert len(out) == K - 1, f"expected {K-1} boundaries, saw {len(out)}"
    for d in out: assert d['H_cycles'] is not None and 0 < d['H_cycles'] < 400, d
    dut._log.info(f"HANDOVER PASS: H = {[d['H_cycles'] for d in out]} cycles = {[2 * d['H_cycles'] for d in out]} ns")


@cocotb.test()
async def test_intershot_k1_n2(dut):
    """dsp-native inter-shot gap (MORESHOT -> SHOTADD -> START, no sequencer): one circuit, nshots = 2."""
    dac, R, sig = await run(dut, 1, 2, ncyc=2 * (T0 + 400) + 3000)
    out = report(dut, dac, R, 1, 2, 'K1 nshots=2')
    assert len(out) == 1, f"expected 1 inter-shot gap, saw {len(out)}"
    dut._log.info(f"INTERSHOT PASS: gap - T0 = {out[0]['H_cycles']} cycles = {2 * out[0]['H_cycles']} ns")
