# Pre-registration of the device comparison and of the Ramsey noise analysis

This file documents what was fixed in writing before the device data that the paper reports were acquired: the programs
and their analysis, the equivalence margins with the decision rule, and the declaration that the reported session uses them.

Provenance.
- Section 1: the authors' plan of 2026-09-03, section "What to run" (later amendments of the plan changed which experiments run and when, not the definitions quoted here).
- Section 2: the equivalence criteria and the decision rule, fixed on 2026-09-17 before the first block of that day's
  morning session (10:00 UTC).
- Section 3: the declaration for the session reported in the paper, written on 2026-09-17 at 22:37 PDT, before its first
  block (EA1, 22:41 PDT).

Sections 1 to 3 quote these documents verbatim; `[...]` marks omitted text (review references, board operations, host names,
file locations). Section 4 lists where the reported analysis departs from them. The tags EA1, EB1, EA2, EB2 of
`results/device_x6y3/` are the four blocks of section 3 (A = stock QubiC, B = Ant-Q).

## 1. Programs and analysis (plan of 2026-09-03)

```
P0-A  Readout-data equivalence (stock QubiC vs Ant-Q uplink, same qubit, same session).
      Design: prepared |0> and |1>, >= 10000 shots each per path; T1 sweep (31 delays 0..~4 T1, 512 shots each); four
      A-B-B-A blocks with no recalibration inside a block. Classifier: fitted on an independent calibration subset,
      evaluated on held-out shots; fitted on both paths and cross-applied (both directions) plus a stock-vs-stock
      transport control. Statistics: TOST on paired block-level assignment-fidelity differences, margin +-1.0
      percentage point, alpha 0.05 (90 % CI), power check before the session; T1 ratio margin 0.90-1.10; IQ cloud
      means/covariances reported descriptively (whitened mean displacement, covariance distance), no equivalence
      claim on them. Cost ~1 h.
      Claim: "On qubit q in session S, Ant-Q and stock QubiC were equivalent within the pre-specified +-1.0-point
      assignment-fidelity margin on held-out, block-paired data; fitted T1 ratio within 0.90-1.10."

P0-B  Long fixed-cadence Ramsey acquisition (RQ1 experiment (3) on a device).
      Design: opposite-slope Ramsey pairs alternating every 2 ms (one frequency estimate per 4 ms, 125 Hz Nyquist),
      tau_R = min(10 us, 0.3 T2*), quadrature operating point; K = dP1/df calibrated from >= 5 detunings BEFORE AND
      AFTER every record (reject records that leave the linear range); 50000 shots = 100 s per record; >= 3 Ant-Q
      records and matched stock acquisitions (1024-shot segments, host gaps timestamped) interleaved; a ~5 s
      fast-cadence run (shortest inter-shot interval, same sensor and tau_R) bracketing the long records, twice.
      Analysis (pre-registered): paired-difference estimator timestamped at pair centres, Bernoulli readout noise
      propagated, pair-response transfer function forward-modelled; per-record Hann/Whittle-likelihood spectra
      (no OLS on log-binned means), quantitative band 0.1 Hz to well below 125 Hz; stock analysed per contiguous
      segment with its explicit sampling operator, the same operator applied to Ant-Q data as the control; the
      segment-rate artefact line (~0.49 Hz) tested in both; S_f = A/f^alpha + N with Monte-Carlo-validated CIs;
      the fast run reported as an "aliasing diagnostic" (folded high-frequency power upper bound stated) unless a
      real bound is derived. Log every attempt, timeout, retry and partial return (completion fraction is a result).
      Cost ~2 h.
      Claim: "Ant-Q acquired N uninterrupted 50000-shot Ramsey records at a programmed 2.000 ms interval with zero
      detected CNR events; record-length Fourier resolution 10 mHz, quantitative inference from 0.1 Hz; no
      segment-correlated feature detected above the pre-specified sensitivity, whereas the stock acquisition is
      limited to 2.048 s segments." White-noise fallback sentence pre-registered (no 1/f claim if not resolved).

P0-C  Short 6 us return/order test (RQ1 experiment (4) as executability only).
      8000 iterations at 6.000 us; check returned-word count and order. Claim: "an 8000-iteration program scheduled at
      6.000 us returned 8000 ordered results with zero detected CNR events." No parity, no telegraph bound, no
      hour-long drift trace (dropped: underdefined, and looped 48 ms records restart with a gap). Cost ~15 min.
```

## 2. Equivalence criteria and decision rule (2026-09-17, before the first block of the day)

```
Equivalence criteria ([...] every criterion is a two-sided margin on the BETWEEN-configuration difference, and the
95 % confidence interval of that difference must lie inside the margin; CI crossing the margin -> INCONCLUSIVE; CI outside
-> DIFFERENT):
  Fringe (idx 200-212): fitted fringe phase difference margin +-0.10 rad; contrast ratio margin 0.90-1.10. Fit errors from
    the 13-point sinusoid fit per configuration; CI by error propagation.
  P0-C (idx 101): compiled per-shot period identical (6.000 us, deterministic) and zero word-count mismatches on both.
  P0-A (idx 102/103): assignment fidelity per configuration from a classifier TRAINED on the first half of the shots and
    EVALUATED on the second half (same procedure both sides); margin +-1 % on the fidelity difference (TOST, 95 %).
    Explicitly: this compares two separately trained readout pipelines under the same procedure.
  Ramsey pairs (idx 104): pair-difference mean margin +-0.02 (P0 units), variance ratio margin 0.80-1.25; CIs by
    bootstrap over iterations.
  1Q RB: EPC per configuration from the SAME 8 random sequences (paired across configurations); bootstrap at the
    sequence level keeping the pairing; margin on the EPC difference +-0.005 absolute (expected EPC ~0.01-0.03,
    coherence-limited). Fewer than 3 usable lengths -> inconclusive.
Drift rule [...]: with blocks A1, B1, A2, B2, report the within-configuration block differences (A2-A1, B2-B1) next
to the paired configuration contrasts (B1-A1, B2-A2). Equivalence is stated only if the paired-contrast CI lies inside the
margin in BOTH repetitions and the within-configuration block change is also inside the margin; any other pattern is
INCONCLUSIVE (drift may conceal, mimic or oppose an effect) — never "no stack effect".
Classifier refit [...]: if held-out assignment fidelity in a block falls below .80 the block is REJECTED (re-acquired
if time allows), not rescued by refitting on the same shots.
Attribution: the comparison is between two complete firmware + transport configurations (bitfile, start script, command
path, server lineage shared); a difference is not attributed to DDR streaming alone.
```

## 3. Declaration for the reported session (2026-09-17, 22:37 PDT, before block EA1)

```
Plan (identical to the morning's section 12 plan except the B image and the statistics):
[...]
- Same programs, pulses [...], pads (AQT_PAD_C 3.588 us, AQT_PAD_B 1.998088 ms), margins and
  analysis scripts as the morning [...]. No recalibration: [...] the per-block held-out classifier absorbs readout drift.
- Statistics: BOTH passes at the morning's pass-2 level (fringe 2048 iterations/phase, P0-A 20000, Ramsey pairs 25000),
  declared here before acquisition; the two-pass rule of 12b is unchanged (equivalence needs both passes inside the margin and
  within-configuration drift inside the margin). Tags EA1, EB1, EA2, EB2 [...].
[...]
- Reporting: per pass; [...] the four
  pairwise comparisons (EA1-EB1, EA2-EB2, EA1-EA2, EB1-EB2) with the same margins.
```

## 4. Departures of the reported analysis from sections 1 to 3

P0-A (readout).
- The blocks run in the order stock, Ant-Q, stock, Ant-Q (two passes) instead of A-B-B-A; the rule of section 2 compares each
  pass and each stack's change between its two blocks.
- One classifier per block, trained on the first half and evaluated on the second half of that block's preparation shots
  (section 2). The cross-applied classifiers, the stock-vs-stock transport control, the T1 sweep and the descriptive IQ-cloud
  statistics of section 1 are not part of the reported blocks.
- The margin of +-1.0 percentage point is applied to each pass's difference with its 90 % confidence interval (two one-sided
  tests at the 5 % level), not to block-paired averages. The "TOST, 95 %" of section 2 denotes these two one-sided tests, i.e.
  the 90 % interval of section 1.

P0-B (paired Ramsey records, `experiments/device_x6y3/ramsey_noise_spectrum.py`).
- Two Ant-Q records instead of at least three; one slope calibration per record (after it) instead of one before and one
  after, and versus the phase of the second pi/2 pulse (5 phases, -0.4 to 0.4 rad) instead of the detuning, which gives the
  slope dP1/dphi with dphi = 2 pi df tau_R; tau_R = 0.5 us instead of 0.3 T2* = 0.42 us; the stock host gaps were not timestamped, so the stock records are
  analysed per run only; no fast-cadence aliasing run.
- Analysis choices within the plan: the band ends at 100 Hz ("well below 125 Hz"); the exponent of the 1/f term is fixed at 1
  because no component is resolved.
- The correlation of consecutive pair differences reported in the paper was added after this plan.

P0-C (timing loop): as in sections 1 and 2 (same compiled period of 6.000 us on both stacks, all 8000 results returned).

1Q RB: 5 lengths (2 to 32 Cliffords) x 8 sequences x 256 shots per block; the floor of the fit comes from the block's
readout calibration.

This file covers the four-block comparison and the P0-B noise analysis. The boundary experiment and the long RB sweep of
`results/device_x6y3/` had their own written checks and are not covered here.
