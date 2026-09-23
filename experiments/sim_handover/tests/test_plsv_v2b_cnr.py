"""
plsv ⊕ ring_buffer_simple — CNR (circuit_not_ready) detector test.
Ports the ring_buffer_simple fake-dsp CNR feature to the REAL-dsp integration via a STANDALONE cnr_detector
(observing the cmd_sequencer<->bundle boundary; the real dsp + cmd_sequencer are untouched). circuit_not_ready
latches when, at a circuit boundary, the next command bank was NOT pre-filled in time (wait > SWITCH_LATENCY),
i.e. two circuits did NOT run continuously.

Every command is just [delay, pulse] — the pulse's start_time IS the delay (the dsp waits start_time qclks, then
pulses). Varying the delay varies the per-circuit execution length = exactly what production_gap used to do, now
program-controlled. Two scenarios (same program, different delay) prove the detector both ways:
  (STALL) K=3, start_time=8 (short delay): execution << the per-unit fetch (8ch x 64 beats), so the next bank is
          late at every boundary -> circuit_not_ready=1, wait_counter large.
  (CONT)  K=3, start_time=DELAY_CONT (long delay): execution >> the fetch, so the ping-pong pre-fill keeps up
          -> circuit_not_ready=0 (the two circuits DID run continuously).
"""
import re
import numpy as np
import cocotb
from cocotb.triggers import RisingEdge, Timer, ClockCycles
import distproc.assembler as asm
from qubic.rfsoc.hwconfig import RFSoCElementCfg, load_channel_configs

GEN = 'sim/gensrc'
NUM_CH = 8
BEATS_PER_CHUNK = 64
WORDS_PER_BEAT = 8
LB2 = dict(resetacc=1, dspreset=26, nshot=28, reset_bram_read=32, start=34)
DELAY_CONT = 2000   # start_time (delay qclks) for the continuous scenario: execution >> the ~840-cyc fetch


def build_bram_map(path):
    m = {}
    for line in open(path):
        g = re.search(r'(qubit_\w+)_W_we<=.*?address:\s*(0x[0-9A-Fa-f]+)', line)
        if g:
            m[g.group(1)] = int(g.group(2), 16)
    return m


def _i(sig):
    try:
        return int(sig.value)
    except Exception:
        try:
            return sig.value.to_unsigned()
        except Exception:
            return int(re.sub(r'[^01]', '0', str(sig.value)) or '0', 2)


async def drive_clock(sig, half_ns):
    sig.value = 0
    while True:
        await Timer(half_ns, units='ns'); sig.value = 1
        await Timer(half_ns, units='ns'); sig.value = 0


async def lb3_load(dut, base, words):
    for i, w in enumerate(words):
        await RisingEdge(dut.clk100)
        dut.lb3_wren.value = 1; dut.lb3_waddr.value = int(base + i); dut.lb3_wdata.value = int(w) & 0xFFFFFFFF
    await RisingEdge(dut.clk100); dut.lb3_wren.value = 0; await RisingEdge(dut.clk100)


async def lb2_write(dut, addr, data):
    await RisingEdge(dut.clk500)
    dut.lb2_wren.value = 1; dut.lb2_waddr.value = int(addr); dut.lb2_wdata.value = int(data) & 0xFFFFFFFF
    await RisingEdge(dut.clk500); dut.lb2_wren.value = 0; await RisingEdge(dut.clk500)


def _prog(ccfgs, start_time=None):
    # [delay, pulse]: the pulse's start_time IS the delay before it fires (dsp waits start_time qclks, then pulses).
    # start_time=None -> a null padding program (phase_reset + done, no pulse) for the unused channels.
    chans = ['qubit_0.qdrv', 'qubit_0.rdrv', 'qubit_0.rdlo']
    q0 = {k: v for k, v in ccfgs.items() if k in chans}
    elem = {k: RFSoCElementCfg(**v.elem_params) for k, v in q0.items()}
    p = asm.SingleCoreAssembler(q0, elem)
    p.add_phase_reset()
    if start_time is not None:
        p.add_pulse(100.e6, 0, 0.9, start_time, 0.2 * np.ones(100) + 1j * 0.1 * np.ones(100), 'qubit_0.qdrv')
    p.add_done_stb()
    return p.get_program_binaries()


def _cmd_words(exe, name='qubit_command0'):
    b = exe.get_binaries_fromboard()
    if name not in b:
        return np.zeros(0, dtype=np.uint32)
    d = b[name]; d = d.data if hasattr(d, 'data') else d
    return np.frombuffer(d, dtype=np.dtype(np.uint32).newbyteorder('little'))


def _pack_beats(words):
    total = BEATS_PER_CHUNK * WORDS_PER_BEAT
    w = np.zeros(total, dtype=np.uint64)
    w[:min(len(words), total)] = words[:total]
    return [int(sum(int(w[b * WORDS_PER_BEAT + j]) << (32 * j) for j in range(WORDS_PER_BEAT)))
            for b in range(BEATS_PER_CHUNK)]


async def run_batch(dut, K, start_time, nshots=1, fill_K=None, wait_done=True):
    """Full self-contained init + run of a K-circuit batch; returns (circuit_not_ready, cnr_wait_counter).
    ch0 runs a [delay=start_time, pulse] program (delay sets the execution length); others are null padding.
    fill_K (default K): how many circuits actually get commands/config — if < K, the sequencer expects K but the
    later banks never fill -> PERMANENT stall (no stb_start). wait_done=False then polls circuit_not_ready
    instead of waiting for v2b_batch_done (which never comes)."""
    fill_K = K if fill_K is None else fill_K
    ccfgs = load_channel_configs(f'{GEN}/channel_config.json')
    bram_map = build_bram_map(f'{GEN}/ifbramctrl.sv')
    exe = _prog(ccfgs, start_time)
    cmdw = _cmd_words(exe)
    nullw = _cmd_words(_prog(ccfgs, None))

    # clocks
    for s, h in (('clk100', 5.0), ('clk500', 1.0), ('clk250', 2.0), ('clk333', 1.5)):
        cocotb.start_soon(drive_clock(getattr(dut, s), h))
    for s in ('lb2_wren','lb2_rden','lb3_wren','lb3_rden','s_axis_cmd_tvalid','n_shots_enable',
              'global_start','circuit_id_reset','rd_start','adc0_tvalid','cnr_reset'):
        getattr(dut, s).value = 0
    for s in ('lb2_waddr','lb2_wdata','lb2_raddr','lb3_waddr','lb3_wdata','lb3_raddr','s_axis_cmd_tdata',
              'n_shots','wr_base_addr','rd_base_addr','rd_size_bytes','adc0_tdata'):
        getattr(dut, s).value = 0
    dut.m_axis_tready.value = 1
    dut.max_bank_size.value = 0xF
    dut.last_circuit_id.value = K - 1
    dut.aresetn.value = 0
    await ClockCycles(dut.clk500, 30)
    dut.aresetn.value = 1
    await ClockCycles(dut.clk500, 30)
    for r in ('dspreset', 'resetacc', 'reset_bram_read'):
        await lb2_write(dut, LB2[r], 1); await lb2_write(dut, LB2[r], 0)
    for name, data in exe.get_binaries_fromboard().items():
        if 'command' in name.lower() or name not in bram_map:
            continue
        d = data.data if hasattr(data, 'data') else data
        await lb3_load(dut, bram_map[name], np.frombuffer(d, dtype=np.dtype('<u4')))
    await ClockCycles(dut.clk500, 20)

    for ci in range(fill_K):
        await RisingEdge(dut.clk333)
        dut.n_shots.value = nshots; dut.n_shots_enable.value = 1
        await RisingEdge(dut.clk333)
        dut.n_shots_enable.value = 0
        for c in range(NUM_CH):
            img = cmdw if c == 0 else nullw
            for bv in _pack_beats(img):
                dut.s_axis_cmd_tdata.value = bv; dut.s_axis_cmd_tvalid.value = 1
                await RisingEdge(dut.clk333)
                while not _i(dut.s_axis_cmd_tready):
                    await RisingEdge(dut.clk333)
        dut.s_axis_cmd_tvalid.value = 0
    await RisingEdge(dut.clk333)
    dut.global_start.value = 1

    bd = 0
    if wait_done:
        for _ in range(200000):
            await RisingEdge(dut.clk500)
            if _i(dut.v2b_batch_done) == 1:
                bd = 1; break
        await ClockCycles(dut.clk500, 50)
    else:
        # permanent-stall: v2b_batch_done never comes; poll circuit_not_ready (bounded)
        for _ in range(20000):
            await RisingEdge(dut.clk500)
            if _i(dut.circuit_not_ready) == 1:
                break
    cnr = _i(dut.circuit_not_ready)
    wc = _i(dut.cnr_wait_counter)
    dut._log.info(f"run_batch(K={K}, fill_K={fill_K}, start_time(delay)={start_time}, nshots={nshots}): "
                  f"batch_done={bd} circuit_id={_i(dut.current_circuit_id)} circuit_not_ready={cnr} cnr_wait_counter={wc}")
    if wait_done:
        assert bd == 1, "batch did not complete"
    return cnr, wc


@cocotb.test()
async def test_cnr_stall(dut):
    # SHORT delay (start_time=8) -> short execution << per-unit fetch -> next bank late -> NOT continuous
    cnr, wc = await run_batch(dut, K=3, start_time=8)
    assert cnr == 1, f"expected circuit_not_ready=1 (short-delay circuits CANNOT run continuously), got {cnr}"
    assert wc > 8, f"expected wait_counter > SWITCH_LATENCY(8) for a real stall, got {wc}"
    # cnr_reset clears the sticky flag cleanly (cursor review: verify the clear path)
    dut.cnr_reset.value = 1
    await ClockCycles(dut.clk500, 4)
    dut.cnr_reset.value = 0
    await ClockCycles(dut.clk500, 4)
    cnr_after = _i(dut.circuit_not_ready); wc_after = _i(dut.cnr_wait_counter)
    assert cnr_after == 0, f"cnr_reset should clear circuit_not_ready, got {cnr_after}"
    assert wc_after == 0, f"cnr_reset should zero wait_counter, got {wc_after}"
    dut._log.info(f"CNR-STALL PASS: short-delay circuits -> circuit_not_ready=1, waited {wc} cycles at the boundary "
                  f"(next bank not pre-filled -> NOT continuous); cnr_reset cleared flag->{cnr_after}, counter->{wc_after}.")


@cocotb.test()
async def test_cnr_continuous(dut):
    # LONG delay (start_time=DELAY_CONT) -> long execution >> fetch -> ping-pong pre-fill keeps up -> CONTINUOUS
    cnr, wc = await run_batch(dut, K=3, start_time=DELAY_CONT)
    assert cnr == 0, f"expected circuit_not_ready=0 (long-delay circuits SHOULD run continuously), got {cnr} (wait={wc})"
    dut._log.info(f"CNR-CONTINUOUS PASS: start_time(delay)={DELAY_CONT} -> circuit_not_ready=0; the ping-pong "
                  "pre-fill kept up so the two circuits DID run continuously (no boundary stall).")


@cocotb.test()
async def test_cnr_permanent_stall(dut):
    # PERMANENT stall (codex v2 review): expect 3 circuits but fill only 2. Circuits 0,1 run normally; after
    # circuit 1's read_finished arms the detector, circuit 2's bank never gets commands -> the sequencer waits
    # forever in S_WAIT and stb_start NEVER fires. circuit_not_ready must STILL assert, because the flag is driven
    # by wait_counter crossing the threshold (NOT by stb_start). (1 filled circuit can't bootstrap, so fill 2.)
    cnr, wc = await run_batch(dut, K=3, start_time=8, fill_K=2, wait_done=False)
    assert cnr == 1, f"permanent stall (next bank never ready, no stb_start) must set circuit_not_ready, got {cnr}"
    assert wc > 8, f"expected wait_counter > SWITCH_LATENCY(8) for the permanent stall, got {wc}"
    # cnr_reset is host-dominant: ONE pulse clears the flag even MID-stall (codex v3 review), no second pulse.
    dut.cnr_reset.value = 1
    await ClockCycles(dut.clk500, 2)
    dut.cnr_reset.value = 0
    await ClockCycles(dut.clk500, 2)
    cnr_cleared = _i(dut.circuit_not_ready)
    assert cnr_cleared == 0, f"cnr_reset must clear circuit_not_ready even mid-stall (host-dominant), got {cnr_cleared}"
    dut._log.info(f"CNR-PERMANENT-STALL PASS: next bank never ready (no stb_start ever) -> circuit_not_ready=1 "
                  f"(waited {wc}); flag does NOT depend on stb_start; cnr_reset cleared it mid-stall -> {cnr_cleared}.")
