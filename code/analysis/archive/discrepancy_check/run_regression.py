"""
Run the Phase-2 work1_wkly2 regression on ORIG and MOD and report:
  - N (worker-weeks in e(sample))
  - coefficient on treatment
  - cluster-robust SE (by pid)
  - p-value

Uses the unified construction from ld_replication.do (gen_bl_cov +
per-dataset work1_wkly2) as in diagnose_discrepancy.py.
"""

from __future__ import annotations
import pandas as pd
import numpy as np
import pyreadstat
import statsmodels.api as sm

BASE = "/Users/lc2295/Library/CloudStorage/Dropbox/Labor Discipline/07. Data/3. Main Study 3.0"
ORIG = f"{BASE}/replication/data/final/05_bs_phase1_phase2_makevar_combined_daily_weekly.dta"
MOD  = f"{BASE}/replication/data/final/final_data_prioritize_in_person.dta"

COMMON = ["pid","date","phase","week_in","dow","holiday","stand","strata",
          "treatment","calendar_week","attend_week","attend","earn","work1"]
ORIG_EXTRA = ["recall_length","work_recall_mode"]
MOD_EXTRA  = ["work_orig","recall_reliable"]


def load(path, cols):
    df, _ = pyreadstat.read_dta(path, usecols=cols)
    return df


def gen_bl_cov(df):
    p0 = df[df["phase"] == 0]
    agg = (p0.groupby("pid", as_index=False)
              .agg(bl_attend=("attend","mean"), bl_earn=("earn","mean")))
    agg["miss_bl_earn"] = agg["bl_earn"].isna().astype(int)
    agg["bl_earn"] = agg["bl_earn"].fillna(0)
    pos = p0[(p0["earn"].notna()) & (p0["earn"] > 0)]
    mode = (pos.groupby("pid")["earn"]
               .apply(lambda s: s.mode().iloc[0] if not s.mode().empty else np.nan)
               .rename("bl_modalwage").reset_index())
    agg = agg.merge(mode, on="pid", how="left")
    agg["bl_modalwage"] = agg["bl_modalwage"].fillna(0)
    drop = [c for c in ["bl_attend","bl_earn","miss_bl_earn","bl_modalwage"] if c in df.columns]
    return df.drop(columns=drop).merge(agg, on="pid", how="left")


def _sum_missing(s):
    return s.sum(min_count=1)


def build_mod(df):
    df = df.copy()
    df["_t1"] = df["work_orig"].where(df["recall_reliable"] == 1)
    df["work1_wkly2"] = (df.groupby(["pid","phase","week_in"])["_t1"]
                          .transform(_sum_missing))
    return df.drop(columns="_t1")


def build_orig(df):
    df = df.copy()
    g = df.groupby(["pid","phase","week_in"])
    df["_min_mode"] = g["work_recall_mode"].transform("min")
    df["work_recall_mode_any1"] = (df["_min_mode"] == 1).astype(int)
    df["_rl7"] = (df["recall_length"] <= 7).astype(int)
    df["grid_recall_anyinwk"] = g["_rl7"].transform("max")
    df["_t1"] = df["work1"].where(
        (df["recall_length"] <= 7) & (df["work_recall_mode"] == 1))
    eligible = (df["grid_recall_anyinwk"] == 1) & (df["work_recall_mode_any1"] == 1)
    df["_t2"] = df["_t1"].where(eligible)
    df["work1_wkly2"] = (df.groupby(["pid","phase","week_in"])["_t2"]
                          .transform(_sum_missing))
    return df.drop(columns=["_min_mode","_rl7","_t1","_t2"])


def run_reg(df, name):
    d = df[df["phase"] == 2].copy()
    # drop missing outcome / covariates
    need = ["work1_wkly2","treatment","attend_week","bl_attend","bl_earn",
            "miss_bl_earn","bl_modalwage","stand","strata","week_in",
            "calendar_week","pid"]
    d = d.dropna(subset=need)
    # drop singleton covariates after reading (Stata would too via dummies)
    y = d["work1_wkly2"].astype(float)
    # build design matrix
    X_parts = [d[["treatment","attend_week","bl_attend","bl_earn",
                  "miss_bl_earn","bl_modalwage"]].astype(float)]
    for fe in ["stand","strata","week_in","calendar_week"]:
        dummies = pd.get_dummies(d[fe].astype(int), prefix=fe, drop_first=True,
                                 dtype=float)
        X_parts.append(dummies)
    X = pd.concat(X_parts, axis=1)
    X = sm.add_constant(X, has_constant="add")
    # Some dummies may be collinear across strata/stand etc.; statsmodels will
    # keep rank-deficient columns but report NaN — use OLS with drop for safety
    X = X.loc[:, ~X.columns.duplicated()]
    groups = d["pid"].astype(int).values

    model = sm.OLS(y, X, hasconst=True)
    res = model.fit(cov_type="cluster", cov_kwds={"groups": groups})
    b = res.params.get("treatment", np.nan)
    se = res.bse.get("treatment", np.nan)
    p = res.pvalues.get("treatment", np.nan)
    n = int(res.nobs)
    clusters = int(pd.Series(groups).nunique())
    print(f"\n=== {name} ===")
    print(f"N (worker-weeks): {n:,}   clusters (pids): {clusters}")
    print(f"treatment coef  : {b:.4f}")
    print(f"cluster SE (pid): {se:.4f}")
    print(f"p-value         : {p:.4f}")
    return {"dataset": name, "N": n, "clusters": clusters,
            "coef": b, "se": se, "p": p}


if __name__ == "__main__":
    print("Loading MOD ...", flush=True)
    mod = load(MOD, COMMON + MOD_EXTRA)
    mod = gen_bl_cov(mod)
    mod = build_mod(mod)

    print("Loading ORIG ...", flush=True)
    orig = load(ORIG, COMMON + ORIG_EXTRA)
    orig = gen_bl_cov(orig)
    orig = build_orig(orig)

    res_mod  = run_reg(mod,  "MOD (final_data_prioritize_in_person.dta)")
    res_orig = run_reg(orig, "ORIG (05_bs_phase1_phase2_makevar_combined_daily_weekly.dta)")

    out = pd.DataFrame([res_mod, res_orig])
    out_path = f"{BASE}/replication/data/temp/discrepancy_check/out/regression_summary.csv"
    out.to_csv(out_path, index=False)
    print(f"\nSaved summary -> {out_path}")
