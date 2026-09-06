"""Plan A3 pre-run feasibility (Monte Carlo, numpy seed 48): for each timing experiment choose the frozen
calibration design {N0, N0+D/2, N0+D} x 3 repeats and compute P(cell classified CONSISTENT | correct
implementation, true offset 0) under per-run timer noise Normal(0, sigma_t^2), sigma_t = 0.3 ms.
Decision (plan A3 (ii)): |mean of 3 full runs - E| + t_{0.975,7} * SE_pred3(N) <= 1 ms + 100 ppm * E,
E = N * P_meas + F from the 9-point least-squares fit, SE_pred3(N) = sqrt(SE_fit(N)^2 + s_resid^2 / 3).
Also (i): the 95 % CI of (P_meas - P) must lie inside +/- margin_P, margin_P = 100 ppm * P + 2 ns.
Escalation: D doubles at most twice, then INFEASIBLE."""
import numpy as np, csv, sys
from scipy import stats
SIGMA_T = 0.3e-3          # s, frozen
N0 = 1000
T = stats.t.ppf(0.975, 7)
EXPS = {  # name: (N, interval_s, F_s guess for the c3 image = fixed fill/drain)
    'vion_1': (50000, 100e-6, 0.1e-3), 'yan_3': (50000, 2e-3, 0.1e-3), 'riste_4': (8000, 6e-6, 0.1e-3)}
rng = np.random.default_rng(48)
def design(D):
    counts = np.array([N0, N0 + D // 2, N0 + D] * 3, dtype=float)
    X = np.column_stack([np.ones_like(counts), counts])
    return counts, X
def simulate(N, P, F, D, ndraw=100000):
    counts, X = design(D)
    XtX_inv = np.linalg.inv(X.T @ X)
    x_new = np.array([1.0, N])
    se_fit_unit = np.sqrt(x_new @ XtX_inv @ x_new)           # times s_resid
    se_P_unit = np.sqrt(XtX_inv[1, 1])
    margin_P = 100e-6 * P + 2e-9
    ok_ii = ok_i = 0
    for _ in range(ndraw // 1000):
        # vectorised: 1000 draws at once
        eps = rng.normal(0, SIGMA_T, size=(1000, 9))
        y = F + P * counts + eps
        beta = np.linalg.solve(X.T @ X, X.T @ y.T)             # 2 x 1000
        resid = y - (X @ beta).T
        s_res = np.sqrt((resid ** 2).sum(axis=1) / 7)
        E = beta[1] * N + beta[0]
        full = F + P * N + rng.normal(0, SIGMA_T, size=(1000, 3)).mean(axis=1)
        se_pred3 = np.sqrt((se_fit_unit * s_res) ** 2 + s_res ** 2 / 3)
        ok_ii += np.sum(np.abs(full - E) + T * se_pred3 <= 1e-3 + 100e-6 * E)
        ci_half = T * se_P_unit * s_res
        ok_i += np.sum(np.abs(beta[1] - P) + ci_half <= margin_P)
    return ok_i / ndraw, ok_ii / ndraw, margin_P
rows = []
for name, (N, P, F) in EXPS.items():
    D = int(np.ceil(4 * SIGMA_T / (100e-6 * P + 2e-9)))
    for esc in range(3):
        p_i, p_ii, mP = simulate(N, P, F, D)
        rows.append(dict(exp=name, N=N, P_s=P, D=D, esc=esc, margin_P_ns=mP * 1e9, p_consistent_i=p_i, p_consistent_ii=p_ii,
                         top_count=N0 + D, top_run_s=(N0 + D) * P))
        if p_i >= 0.8 and p_ii >= 0.8:
            break
        D *= 2
    rows[-1]['verdict'] = 'FEASIBLE' if (rows[-1]['p_consistent_i'] >= 0.8 and rows[-1]['p_consistent_ii'] >= 0.8) else 'INFEASIBLE'
w = csv.DictWriter(open('results/calib_feasibility.csv', 'w'), fieldnames=list(rows[-1].keys())); w.writeheader()
for r in rows:
    r.setdefault('verdict', 'escalated'); w.writerow(r); print(r)
