"""
Diagnose discrepancy in the Phase-2 regression

    reg work1_wkly2 treatment attend_week bl_attend bl_earn miss_bl_earn bl_modalwage ///
        i.stand i.strata i.week_in i.calendar_week if phase==2 , vce(cluster pid)

between two datasets:

  ORIG: replication/data/final/05_bs_phase1_phase2_makevar_combined_daily_weekly.dta
  MOD : replication/data/final/final_data_prioritize_in_person.dta

This version mirrors the unified analysis recipe in
replication/code/analysis/ld_replication.do:

  - gen_bl_cov (lines 14-51): build bl_attend, bl_earn, miss_bl_earn,
    bl_modalwage from phase==0 rows of each dataset (applied to BOTH).
  - work1_wkly2 construction per dataset (lines 170-194):
      ORIG: gated on recall_length<=7 and work_recall_mode==1 (both at daily
            and weekly level).
      MOD : work_orig if recall_reliable == 1.

Outputs overwrite files in ./out.
"""

from __future__ import annotations

import os
import pandas as pd
import pyreadstat

BASE   = "/Users/lc2295/Library/CloudStorage/Dropbox/Labor Discipline/07. Data/3. Main Study 3.0"
ORIG   = f"{BASE}/replication/data/final/05_bs_phase1_phase2_makevar_combined_daily_weekly.dta"
MOD    = f"{BASE}/replication/data/final/final_data_prioritize_in_person.dta"
OUTDIR = f"{BASE}/replication/data/temp/discrepancy_check/out"

os.makedirs(OUTDIR, exist_ok=True)

# --- columns ------------------------------------------------------------- #
COMMON = [
    "pid", "date", "phase", "week_in", "dow", "holiday", "stand", "strata",
    "treatment", "calendar_week", "attend_week", "attend_nadj",
    "attend", "earn", "work1", "work1_week",
]
ORIG_EXTRA = ["recall_length", "work_recall_mode"]
MOD_EXTRA  = ["work_orig", "recall_reliable",
              "bl_attend", "bl_earn", "miss_bl_earn", "bl_modalwage"]

REG_COVARS = ["treatment", "attend_week", "bl_attend", "bl_earn",
              "miss_bl_earn", "bl_modalwage", "stand", "strata",
              "week_in", "calendar_week"]


def load(path: str, cols: list[str]) -> pd.DataFrame:
    df, _ = pyreadstat.read_dta(path, usecols=cols)
    return df


# --- load ---------------------------------------------------------------- #
print("Loading MOD ...", flush=True)
mod = load(MOD, COMMON + MOD_EXTRA)
print(f"  rows: {len(mod):,}")

print("Loading ORIG ...", flush=True)
orig = load(ORIG, COMMON + ORIG_EXTRA)
print(f"  rows: {len(orig):,}")


# --- gen_bl_cov (mirrors ld_replication.do:15-51) ------------------------ #
def gen_bl_cov(df: pd.DataFrame) -> pd.DataFrame:
    """Rebuild bl_attend, bl_earn, miss_bl_earn, bl_modalwage from phase==0."""
    p0 = df[df["phase"] == 0]

    agg = (p0.groupby("pid", as_index=False)
              .agg(bl_attend=("attend", "mean"),
                   bl_earn=("earn", "mean")))
    agg["miss_bl_earn"] = agg["bl_earn"].isna().astype(int)
    agg["bl_earn"] = agg["bl_earn"].fillna(0)

    # modal positive earnings per pid. Stata `egen mode` returns . for ties
    # with no unique mode; we return the smallest mode (pandas default)
    pos = p0[(p0["earn"].notna()) & (p0["earn"] > 0)]
    mode = (pos.groupby("pid")["earn"]
               .apply(lambda s: s.mode().iloc[0] if not s.mode().empty else pd.NA)
               .rename("bl_modalwage").reset_index())
    agg = agg.merge(mode, on="pid", how="left")
    agg["bl_modalwage"] = agg["bl_modalwage"].fillna(0)

    drop = [c for c in ["bl_attend", "bl_earn", "miss_bl_earn", "bl_modalwage"]
            if c in df.columns]
    return df.drop(columns=drop).merge(agg, on="pid", how="left")


print("Building bl_* covariates from phase==0 on each dataset ...", flush=True)
mod  = gen_bl_cov(mod)
orig = gen_bl_cov(orig)

# Quick sanity on MOD: compare our regenerated bl_* to whatever MOD shipped with
# (we loaded MOD's shipped bl_* as MOD_EXTRA but dropped them in gen_bl_cov).
# Reload just the shipped cols at pid level for a side-by-side comparison.
print("Comparing regenerated MOD bl_* to what MOD shipped with ...", flush=True)
mod_shipped_bl, _ = pyreadstat.read_dta(
    MOD, usecols=["pid", "bl_attend", "bl_earn", "miss_bl_earn", "bl_modalwage"])
mod_shipped_bl = mod_shipped_bl.drop_duplicates("pid").rename(columns={
    "bl_attend": "bl_attend_shipped",
    "bl_earn": "bl_earn_shipped",
    "miss_bl_earn": "miss_bl_earn_shipped",
    "bl_modalwage": "bl_modalwage_shipped",
})
mod_regen_bl = (mod[["pid", "bl_attend", "bl_earn", "miss_bl_earn", "bl_modalwage"]]
                .drop_duplicates("pid"))
bl_cmp = mod_regen_bl.merge(mod_shipped_bl, on="pid", how="outer")
for v in ["bl_attend", "bl_earn", "miss_bl_earn", "bl_modalwage"]:
    a = bl_cmp[v]
    b = bl_cmp[f"{v}_shipped"]
    diff = ((a != b) & ~(a.isna() & b.isna())).sum()
    print(f"  MOD {v}: pids with regen != shipped = {int(diff):,}")
bl_cmp.to_csv(f"{OUTDIR}/bl_cov_compare.csv", index=False)


# --- restrict to phase 2 ------------------------------------------------- #
mod_p2  = mod[mod["phase"] == 2].copy()
orig_p2 = orig[orig["phase"] == 2].copy()
print(f"  MOD  phase-2 rows: {len(mod_p2):,}")
print(f"  ORIG phase-2 rows: {len(orig_p2):,}")


# --- work1_wkly2 constructions ------------------------------------------- #
def _sum_missing(s: pd.Series) -> float:
    """Stata egen total ..., missing: missing only if every input missing."""
    return s.sum(min_count=1)


def build_work1_wkly2_mod(df: pd.DataFrame) -> pd.DataFrame:
    """MOD: canonical work_orig | recall_reliable, plus a naive sum(work1) for
    a secondary diagnostic column."""
    df = df.copy()
    df["_temp1"] = df["work_orig"].where(df["recall_reliable"] == 1)
    df["work1_wkly2"] = (df.groupby(["pid", "phase", "week_in"])["_temp1"]
                           .transform(_sum_missing))
    df["work1_wkly2_via_work1"] = (df.groupby(["pid", "phase", "week_in"])["work1"]
                                     .transform(_sum_missing))
    return df.drop(columns="_temp1")


def build_work1_wkly2_orig(df: pd.DataFrame) -> pd.DataFrame:
    """ORIG: mirrors ld_replication.do:172-183
      work_recall_mode_any1 = 1 iff min(work_recall_mode) by wk == 1
      grid_recall_anyinwk   = 1 iff any day in wk has recall_length <= 7
      temp1 = work1 if recall_length<=7 & work_recall_mode==1
      work1_wkly2 = sum(temp1) by wk, only where both flags == 1
    """
    df = df.copy()
    g = df.groupby(["pid", "phase", "week_in"])

    # min() of a float series ignores NaNs in pandas -> matches Stata egen min
    df["_min_mode"] = g["work_recall_mode"].transform("min")
    df["work_recall_mode_any1"] = (df["_min_mode"] == 1).astype(int)

    df["_rl7"] = (df["recall_length"] <= 7).astype(int)
    df["grid_recall_anyinwk"] = g["_rl7"].transform("max")

    df["_temp1"] = df["work1"].where(
        (df["recall_length"] <= 7) & (df["work_recall_mode"] == 1)
    )
    eligible = (df["grid_recall_anyinwk"] == 1) & (df["work_recall_mode_any1"] == 1)
    df["_temp2"] = df["_temp1"].where(eligible)

    df["work1_wkly2"] = (df.groupby(["pid", "phase", "week_in"])["_temp2"]
                           .transform(_sum_missing))

    # secondary: naive sum(work1) ignoring all gating (for comparability column)
    df["work1_wkly2_via_work1"] = (df.groupby(["pid", "phase", "week_in"])["work1"]
                                     .transform(_sum_missing))

    return df.drop(columns=["_min_mode", "_rl7", "_temp1", "_temp2"])


print("Constructing work1_wkly2 ...", flush=True)
mod_p2  = build_work1_wkly2_mod(mod_p2)
orig_p2 = build_work1_wkly2_orig(orig_p2)


# --- approximate e(sample) ----------------------------------------------- #
def mark_in_sample(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()
    need = ["work1_wkly2"] + REG_COVARS
    df["in_sample"] = df[need].notna().all(axis=1)
    return df


mod_p2  = mark_in_sample(mod_p2)
orig_p2 = mark_in_sample(orig_p2)
print(f"  MOD  daily in_sample: {int(mod_p2['in_sample'].sum()):,}")
print(f"  ORIG daily in_sample: {int(orig_p2['in_sample'].sum()):,}")


# --- collapse to pid-week_in --------------------------------------------- #
def collapse(df: pd.DataFrame, tag: str) -> pd.DataFrame:
    g = (df.groupby(["pid", "week_in"], as_index=False)
           .agg(work1_wkly2=("work1_wkly2", "first"),
                work1_wkly2_via_work1=("work1_wkly2_via_work1", "first"),
                work1_week=("work1_week", "first"),
                in_sample_week=("in_sample", "any"),
                n_days=("date", "size"),
                n_days_in_sample=("in_sample", "sum"),
                n_work1_nonmiss=("work1", lambda s: int(s.notna().sum()))))
    return g.rename(columns={c: f"{c}_{tag}"
                             for c in g.columns if c not in ("pid", "week_in")})


g_mod  = collapse(mod_p2,  "mod")
g_orig = collapse(orig_p2, "orig")

merged = g_mod.merge(g_orig, on=["pid", "week_in"], how="outer", indicator="present")


# --- diff flags ---------------------------------------------------------- #
def ne_nanaware(a, b):
    both_nan = a.isna() & b.isna()
    return (a != b) & ~both_nan


merged["diff_outcome"] = ne_nanaware(merged["work1_wkly2_mod"],
                                     merged["work1_wkly2_orig"])
merged["diff_outcome_via_work1"] = ne_nanaware(
    merged["work1_wkly2_via_work1_mod"], merged["work1_wkly2_via_work1_orig"])
merged["diff_sample"] = ne_nanaware(
    merged["in_sample_week_mod"].astype("boolean"),
    merged["in_sample_week_orig"].astype("boolean"))
merged["only_in_mod"]  = merged["present"] == "left_only"
merged["only_in_orig"] = merged["present"] == "right_only"


# --- summary ------------------------------------------------------------- #
summary = pd.DataFrame({
    "metric": [
        "MOD  pid-week_in cells (phase 2)",
        "ORIG pid-week_in cells (phase 2)",
        "cells in both",
        "cells only in MOD",
        "cells only in ORIG",
        "diff_outcome (work1_wkly2, canonical per ld_replication.do)",
        "diff_outcome (naive sum(work1) on both)",
        "diff_sample (e(sample) membership)",
        "# unique pids in MOD  phase-2 e(sample)",
        "# unique pids in ORIG phase-2 e(sample)",
        "# worker-weeks in MOD  phase-2 e(sample)",
        "# worker-weeks in ORIG phase-2 e(sample)",
    ],
    "value": [
        len(g_mod),
        len(g_orig),
        int((merged["present"] == "both").sum()),
        int(merged["only_in_mod"].sum()),
        int(merged["only_in_orig"].sum()),
        int(merged["diff_outcome"].sum()),
        int(merged["diff_outcome_via_work1"].sum()),
        int(merged["diff_sample"].sum()),
        int(g_mod[g_mod["in_sample_week_mod"]]["pid"].nunique()),
        int(g_orig[g_orig["in_sample_week_orig"]]["pid"].nunique()),
        int(g_mod["in_sample_week_mod"].sum()),
        int(g_orig["in_sample_week_orig"].sum()),
    ],
})
summary.to_csv(f"{OUTDIR}/sample_diff_summary.csv", index=False)
print("\n=== summary ===")
print(summary.to_string(index=False))


# --- discrepancy file ---------------------------------------------------- #
disc = merged[
    merged["diff_outcome"] | merged["diff_sample"]
    | merged["only_in_mod"] | merged["only_in_orig"]
].copy()
disc["diff_value"] = (disc["work1_wkly2_mod"].fillna(0)
                      - disc["work1_wkly2_orig"].fillna(0))
disc = disc.sort_values(["diff_sample", "diff_outcome", "diff_value"],
                        ascending=[False, False, False])

cols_order = [
    "pid", "week_in", "present",
    "diff_outcome", "diff_outcome_via_work1", "diff_sample",
    "only_in_mod", "only_in_orig",
    "work1_wkly2_mod", "work1_wkly2_orig", "diff_value",
    "work1_wkly2_via_work1_mod", "work1_wkly2_via_work1_orig",
    "work1_week_mod", "work1_week_orig",
    "in_sample_week_mod", "in_sample_week_orig",
    "n_days_mod", "n_days_orig",
    "n_days_in_sample_mod", "n_days_in_sample_orig",
    "n_work1_nonmiss_mod", "n_work1_nonmiss_orig",
]
disc[cols_order].to_csv(f"{OUTDIR}/pidweek_discrepancies.csv", index=False)
print(f"\nWrote {len(disc):,} discrepant pid-week_in rows"
      f" -> {OUTDIR}/pidweek_discrepancies.csv")


# --- daily detail for discrepant weeks ----------------------------------- #
disc_keys = disc[["pid", "week_in"]].drop_duplicates()

mod_daily = (mod_p2.merge(disc_keys, on=["pid", "week_in"], how="inner")
                 [["pid", "date", "week_in", "dow", "holiday", "stand",
                   "calendar_week", "work_orig", "recall_reliable",
                   "work1", "work1_week", "work1_wkly2",
                   "in_sample", "attend_week", "attend_nadj"]])
mod_daily = mod_daily.add_suffix("_mod").rename(columns={
    "pid_mod": "pid", "date_mod": "date", "week_in_mod": "week_in"})

orig_daily = (orig_p2.merge(disc_keys, on=["pid", "week_in"], how="inner")
                  [["pid", "date", "week_in", "dow", "holiday", "stand",
                    "calendar_week", "work1", "recall_length",
                    "work_recall_mode", "work_recall_mode_any1",
                    "grid_recall_anyinwk", "work1_week", "work1_wkly2",
                    "in_sample", "attend_week", "attend_nadj"]])
orig_daily = orig_daily.add_suffix("_orig").rename(columns={
    "pid_orig": "pid", "date_orig": "date", "week_in_orig": "week_in"})

daily_merged = (mod_daily.merge(orig_daily, on=["pid", "date", "week_in"],
                                how="outer", indicator="day_present")
                          .sort_values(["pid", "week_in", "date"]))
daily_merged.to_csv(f"{OUTDIR}/daily_diff_for_discrepant_weeks.csv", index=False)
print(f"Wrote {len(daily_merged):,} daily rows"
      f" -> {OUTDIR}/daily_diff_for_discrepant_weeks.csv")


# --- top-20 -------------------------------------------------------------- #
top = (disc[disc["diff_outcome"]]
        .assign(abs_diff=lambda d: d["diff_value"].abs())
        .sort_values("abs_diff", ascending=False)
        .head(20))
if len(top):
    print("\n=== top 20 pid-week_in by |work1_wkly2 diff| ===")
    print(top[["pid", "week_in", "work1_wkly2_mod", "work1_wkly2_orig",
               "diff_value", "in_sample_week_mod", "in_sample_week_orig"]]
          .to_string(index=False))
else:
    print("\nNo outcome-value discrepancies detected.")

print("\nDone.")
