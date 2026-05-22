# Testing Mechanisms — Kwon & Roth (Feb 20, 2026)

Summary of `TestingMechanisms_Draft.pdf` (70 pages) and the companion R package [`TestMechs`](https://github.com/jonathandroth/TestMechs).

---

## 1. Question and contribution

Given a randomized (or quasi-experimental) treatment $D$ that affects an outcome $Y$, the paper develops tests for the **sharp null of full mediation**:

$$Y(0,m) = Y(1,m) \equiv Y(m) \quad \text{a.s. for all } m,$$

i.e. $D$ affects $Y$ *only* through the candidate mediator (or set of mediators) $M$.

Why it matters: standard mediation analysis requires strong assumptions to identify the effect of $M$ on $Y$ (e.g. conditional unconfoundedness of $M$). This paper sidesteps that by asking a different, more tractable question — is the data consistent with $M$ fully explaining the effect? — and provides:

1. A **test** of the sharp null.
2. **Lower bounds** on the fraction of "always-takers" (people with $M(0)=M(1)$) whose outcome is nevertheless affected — i.e. a measure of how much *other* mechanisms matter when the null is rejected.
3. **Bounds on $ADE_k$**, the average direct effect for $k$-always-takers (Appendix B.1).

## 2. Key insight (binary $M$, Sec. 2)

Under the sharp null + independence + monotonicity, **$D$ is a valid instrument for the LATE of $M$ on $Y$**. Therefore, testing the sharp null is equivalent to testing IV/LATE validity. Off-the-shelf tools (Balke–Pearl 1997; Kitagawa 2015; Huber–Mellace 2015; Mourifié–Wan 2017) apply directly when $D$ and $M$ are binary.

Testable implications (Kitagawa 2015):
$$P(Y\in A, M=0\mid D=0) \geq P(Y\in A, M=0\mid D=1)$$
$$P(Y\in A, M=1\mid D=1) \geq P(Y\in A, M=1\mid D=0)$$
for all Borel sets $A$.

## 3. General framework (Sec. 3)

$M \in \mathbb{R}^p$ with finite support $\{m_0, \dots, m_{K-1}\}$. Define type shares
$$\theta_{lk} := P(M(0)=m_l, M(1)=m_k).$$

The researcher imposes restrictions $\theta \in R \subseteq \Delta$. Examples:
- **Monotonicity** (scalar, ordered $M$): $R = \{\theta : \theta_{lk}=0 \text{ if } l>k\}$.
- **Up to $\bar d$ defiers**: $R = \{\theta : \sum_{l>k}\theta_{lk} \leq \bar d\}$.
- **Elementwise monotonicity** for vector $M$.
- **Bounded effect of $D$ on $M$**.
- **No restrictions**: $R = \Delta$.

Identified set $\Theta_I$ = type-share vectors consistent with observed marginals $M\mid D$.

### Main results

**Proposition 3.1** (sharp lower bound on $\nu_k$, the fraction of $k$-always-takers affected):
$$\theta_{kk}\nu_k \geq \left(\sup_A \Delta_k(A) - \sum_{l \neq k}\theta_{lk}\right)_+$$
where $\Delta_k(A) := P(Y\in A, M=m_k\mid D=1) - P(Y\in A, M=m_k\mid D=0)$. Since $\theta$ is partially identified, take inf over $\tilde\theta \in \Theta_I$.

**Corollary 3.1** (sharp testable implication of the sharp null): there exists $\tilde\theta \in \Theta_I$ such that
$$\sup_A \Delta_k(A) \leq \sum_{l\neq k}\tilde\theta_{lk} \quad \text{for all } k.$$

Verified by **linear programming**.

**Closed form (Remark 1):** when $M$ is fully ordered with monotonicity,
$$\tilde\theta_{kk}^{\min} = \max\{P(M=m_k\mid D=1) - (P(M\geq m_k\mid D=1) - P(M\geq m_k\mid D=0)),\, 0\}.$$

### Other useful remarks
- **Remark 3 (binning):** if $M$ is continuous, discretize into bins; results remain valid under the assumption that within-bin variation in $M$ doesn't affect $Y$ (or affects $\leq \nu_{\max}$ fraction).
- **Remark 5:** these results imply sharp testable implications for IV validity with binary instrument and multi-valued endogenous variable — strengthens Sun (2023).
- **Remark 7 (mis-measured $M$):** if measurement-error matrix $L$ is known and full-rank, identification is recoverable.

## 4. Inference (Sec. 4)

Test reduces to checking whether a linear program
$$H_0: \exists\, \omega \text{ s.t. } C_1\omega - C_2 p \geq 0$$
has a solution. Use **moment-inequality methods**:

| Test | Authors | When to prefer |
|---|---|---|
| **CS** | Cox & Shi (2022) | **Default recommendation**; good size + power across designs |
| **ARP** | Andrews, Roth & Pakes (2023) | Better size with few clusters |
| **FSST** | Fang, Santos, Shaikh & Torgovitsky (2023) | Better power with many independent obs |
| **K** | Kitagawa (2015) | Only for binary $M$ |

**Discretization heuristic:** target ≥15 observations per $(Y^{disc}, M, D)$ cell. Trade-off: more bins → sharper testable implications but worse finite-sample size control.

## 5. Extensions to non-experimental settings (Sec. 5)

Replace $(Y,M)\mid D=d$ with the identified distribution of $(Y^{tot}(d), M(d))$:

- **IV with binary instrument $Z$**: identify marginals of $(Y^{tot}(d), M(d))\mid C^z=1$ for instrument-compliers via standard LATE formulas (eq. 18). Apply Prop 5.1 / Cor 5.1.
- **Conditional unconfoundedness** ($D \perp (Y(\cdot,\cdot), M(\cdot)) \mid X$): IPW with propensity score $p(X) = E[D\mid X]$.
- **Difference-in-differences**: requires distributional DiD (Athey–Imbens 2006; Callaway–Li 2019; Roth–Sant'Anna 2023) to recover counterfactual *distributions*, not just means.

## 6. Empirical applications (Sec. 6)

### 6.1 Bursztyn et al. (2020) — Saudi Arabia

- **$D$**: information about other men's openness to women working.
- **$M$**: signs wife up for job-search service (binary).
- **$Y$**: wife applies for jobs 3–5 months later (binary).

Result: **reject the sharp null** ($p=0.02$, CS test). At least **11%** of never-takers (men who don't sign up) are nevertheless induced to have wives who apply for jobs. Bounds on average effect for never-takers: 0.11–0.18 (vs. ATE = 0.12). Robust to up to 7% defiers.

### 6.2 Baranov et al. (2020) — Pakistan CBT

- **$D$**: cognitive behavioral therapy for new mothers.
- **$M$ candidates**: (a) grandmother present (binary), (b) relationship quality with husband (1–5 scale), (c) both jointly.
- **$Y$**: financial empowerment index (continuous; discretized into 5 bins).

Results:
- Grandmother alone: **reject** ($p=0.02$); ≥19% of never-takers affected.
- Relationship quality alone: **reject** ($p=0.03$); 10% of always-takers affected (pooled).
- Combined: **cannot reject** ($p=0.65$). Combined lower bound = 7%.

Interpretation: data are statistically consistent with the two mechanisms together explaining the CBT effect.

## 7. The `TestMechs` R package

> Note: the published name is `TestMechs` (with an 's'). `jonathandroth/TestMech` returns 404.

### Install
```r
install.packages("devtools")
devtools::install_github("jonathandroth/TestMechs")
```

### Main functions

| Function | Returns | Purpose |
|---|---|---|
| `partial_density_plot(df, d, m, y, num_Ybins, plot_nts, density_1_label, density_0_label, reg_formula)` | ggplot | Graphical evidence of sharp-null violations (paper's Figures 1, 3). |
| `test_sharp_null(df, d, m, y, method, num_Ybins, reg_formula, cluster, max_defiers_share)` | list incl. `pval` | Formal test. `method` ∈ `{"CS","ARP","FSST","toru"}`. |
| `lb_frac_affected(df, d, m, y, num_Ybins, at_group, reg_formula, allow_min_defiers)` | numeric | Lower bound on $\nu_k$. `at_group`: `0` = never-takers, `1` = always-takers, `NULL` = pooled. |

### Recommended workflow
1. `partial_density_plot()` to eyeball violations.
2. `test_sharp_null()` with `method = "CS"`, `num_Ybins = 5` (and `cluster` if applicable).
3. `lb_frac_affected()` to quantify alternative mechanisms.
4. Re-run with `max_defiers_share > 0` for robustness to monotonicity violations.

### Example (from package, Baranov et al. data)
```r
library(TestMechs); library(dplyr); data("baranov_data")
mother_data <- mother_data %>% filter(THP_sample == 1)

test_result <- test_sharp_null(
  df = mother_data,
  d = "treat", m = "grandmother", y = "motherfinancial",
  method = "CS", num_Ybins = 5, cluster = "uc"
)
test_result$pval

lb_nts <- lb_frac_affected(
  df = mother_data,
  d = "treat", m = "grandmother", y = "motherfinancial",
  num_Ybins = 5, at_group = 0
)

# With covariates (OLS adjustment):
test_sharp_null(
  df = mother_data, d = "treat", m = "grandmother", y = "motherfinancial",
  reg_formula = "~ treat + age_baseline + edu_mo_baseline + wealth_baseline",
  method = "CS", num_Ybins = 5, cluster = "uc"
)
```

## 8. Practical guidance for applying it

- **Identifying power is highest** when $\tilde\theta_{kk}^{\min}$ is large — i.e. when there is substantial point mass at $M=m_k$ in the treated group *and* the treatment effect on the survival function of $M$ at $m_k$ is small. Heuristically: tests have most bite when the treatment effect on $M$ is *small* relative to its effect on $Y$.
- **If $M$ is continuous**: discretize into ≤ 5–10 bins; aim for ≥ 15 obs per $(Y^{disc}, M, D)$ cell. The $\nu_k$ then has a natural interpretation as "fraction of always-takers whose outcome moves bin under treatment."
- **Sample size matters**: with few clusters (≤ 40), CS can over-reject — prefer ARP at the cost of some power.
- **Always report sensitivity to monotonicity** by re-estimating with `max_defiers_share` ∈ {0, 0.05, 0.10, …}.

## 9. Notation cheat sheet

| Symbol | Meaning |
|---|---|
| $D$ | binary treatment |
| $M$ | mediator(s), discrete with $K$ support points $m_0,\dots,m_{K-1}$ |
| $Y(d,m)$ | potential outcome under treatment $d$ and mediator $m$ |
| $M(d)$ | potential mediator under treatment $d$ |
| $G = lk$ | individual has $M(0)=m_l$, $M(1)=m_k$ |
| $\theta_{lk}$ | $P(G=lk)$, type share |
| **$k$-always-takers** | $G=kk$, i.e. $M(0)=M(1)=m_k$ |
| **$lk$-compliers** | $G=lk$ for $l\neq k$ |
| $\nu_k$ | $P(Y(1,m_k)\neq Y(0,m_k)\mid G=kk)$ — fraction of $k$-always-takers affected |
| $ADE_k$ | $E[Y(1,m_k) - Y(0,m_k)\mid G=kk]$ — average direct effect for $k$-always-takers |
| $\Delta_k(A)$ | $P(Y\in A, M=m_k\mid D=1) - P(Y\in A, M=m_k\mid D=0)$ |
| $R$ | restriction set on type shares (encodes monotonicity, etc.) |
| $\Theta_I$ | identified set of type-share vectors $\tilde\theta$ |
