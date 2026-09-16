"""Host-side client for scripts/std_server.c — the standard QubiC PS path (BRAM command load +
accbuf readback) in C. See the server header for the wire format.

The client resolves memory names -> bramctrl word addresses from the bits slot's bram.json and register
names -> dspregs word offsets from dspregs.json, and builds the SAME write sequence the Python path
performs (run.py: zero_command_buf + write_mem_buf of the command memories), so the server does exactly
the old measured operations, in C.
"""
import json
import os
import socket
import struct
from typing import Dict, List, Tuple

import numpy as np

from qubic.rfsoc.bram import BramCfgs

STD_PORT = 8082
F_READOUT_DDR = 1
ZERO_PROGRAM = bytes(16)          # run.py zero_command_buf: one 16-byte (4-word) dummy program per command memory


def _recv_exact(sock, n):
    buf = bytearray(n)
    view = memoryview(buf)
    pos = 0
    while pos < n:
        r = sock.recv_into(view[pos:])
        if r == 0:
            raise RuntimeError('std_server disconnected')
        pos += r
    return bytes(buf)


class StdServerClient:
    """One BATCH per call. `bits_dir` = the bits slot (bram.json + dspregs.json of the loaded gateware)."""

    def __init__(self, ip: str, bits_dir: str, port: int = STD_PORT):
        self.ip, self.port = ip, port
        bj = os.path.join(bits_dir, 'bram.json')
        if not os.path.exists(bj):                        # a gateware build dir: gensrc/bram.json + dspregs.json
            bj = os.path.join(bits_dir, 'gensrc', 'bram.json')
        self.bram = BramCfgs(bj)
        with open(os.path.join(bits_dir, 'dspregs.json')) as f:
            self.dspregs = json.load(f)
        self.command_mems = sorted((m for m in self.bram if 'command' in m),
                                   key=lambda m: int(''.join(ch for ch in m if ch.isdigit())))
        self.accbuf_len = min(self.bram[m].length for m in self.bram if 'accbuf' in m)   # words (2 per entry)

    def reg_off(self, name: str) -> int:
        return int(self.dspregs[name]['base_addr'])

    # -- the write list the Python path would perform (run.py load_executable(zero=True, commands only);
    #    include_tables=True adds the env/freq binaries = load_executable's full per-job loading, used for
    #    heterogeneous batches whose tables differ between circuits) --
    def write_list(self, binaries: Dict[str, bytes], include_tables: bool = False) -> List[Tuple[int, np.ndarray]]:
        out = []
        for m in self.command_mems:                                   # zero_command_buf(): every command memory
            out.append((self.bram[m].address, np.frombuffer(ZERO_PROGRAM, dtype='<u4')))
        for name, d in binaries.items():                              # write_mem_buf() for each command memory
            if 'command' not in name and not (include_tables and name in self.bram
                                              and ('env' in name or 'freq' in name)):
                continue
            raw = d.data if hasattr(d, 'data') else bytes(d)
            words = np.frombuffer(raw, dtype='<u4')
            if len(words) > self.bram[name].length:
                raise ValueError(f'{name}: {len(words)} words exceed {self.bram[name].length}')
            out.append((self.bram[name].address, words))
        return out

    def run_batch(self, circuits: List[dict], readout_ddr: bool = False, timeout_s: float = 3600.0):
        """circuits: list of {'binaries': {mem: bytes}, 'nshots': int, 'chans': {accbuf_mem_name: words_per_shot},
        'regs': {regname: value}} (regs optional). Returns (info, results) with
        info = {'t_start_ns', 't_end_ns', 'elapsed_ms', 'mmio_words_written'} and
        results[i][accbuf_mem] = np.uint32 array of nshots * words_per_shot words (empty when readout_ddr)."""
        flags = F_READOUT_DDR if readout_ddr else 0
        hdr = struct.pack('<8I', len(circuits), flags, self.accbuf_len,
                          self.reg_off('nshot'), self.reg_off('dspreset'), self.reg_off('resetacc'),
                          self.reg_off('start'), self.reg_off('lastshotdone'))
        parts = [b'BATC', hdr]
        chan_order = []
        for c in circuits:
            wl = self.write_list(c['binaries'], c.get('load_tables', False))
            parts.append(struct.pack('<I', len(wl)))
            for addr, words in wl:
                parts.append(struct.pack('<2I', addr, len(words)))
                parts.append(np.ascontiguousarray(words, dtype='<u4').tobytes())
            regs = c.get('regs', {}) or {}
            parts.append(struct.pack('<I', len(regs)))
            for name, val in regs.items():
                parts.append(struct.pack('<2I', self.reg_off(name), int(val)))
            chans = list(c['chans'].items())
            chan_order.append(chans)
            parts.append(struct.pack('<2I', int(c['nshots']), len(chans)))
            for mem, wps in chans:
                parts.append(struct.pack('<2I', self.bram[mem].address, int(wps)))
        payload = b''.join(parts)
        with socket.create_connection((self.ip, self.port), timeout=timeout_s) as s:
            s.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
            s.sendall(payload)
            st, = struct.unpack('<I', _recv_exact(s, 4))
            if st != 0:
                raise RuntimeError(f'std_server rejected BATCH: status {st}')
            st, ts, te, nw = struct.unpack('<I3Q', _recv_exact(s, 28))
            if st != 0:
                raise RuntimeError(f'std_server BATCH failed: status {st} (3 = lastshotdone timeout)')
            results = []
            if not readout_ddr:
                for i, chans in enumerate(chan_order):
                    res = {}
                    for mem, wps in chans:
                        n, = struct.unpack('<I', _recv_exact(s, 4))
                        expect = circuits[i]['nshots'] * wps
                        if n != expect:
                            raise RuntimeError(f'circuit {i} {mem}: {n} words returned, expected {expect}')
                        res[mem] = np.frombuffer(_recv_exact(s, 4 * n), dtype='<u4').copy()
                    results.append(res)
        info = {'t_start_ns': ts, 't_end_ns': te, 'elapsed_ms': (te - ts) / 1e6, 'mmio_words_written': nw}
        return info, results
