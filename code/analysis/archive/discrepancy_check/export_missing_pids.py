"""
Export the list of PIDs that do NOT appear in the ORIG Phase-2 regression
sample (i.e., have zero worker-weeks in ORIG's e(sample)).

Also flags whether each of those PIDs is in MOD's e(sample), so you can see
which PIDs are uniquely dropped by the ORIG pipeline vs dropped by both.
"""

from __future__ import annotations
import pandas as pd
import numpy as np
import pyreadstat

BASE = "/Users/lc2295/Library/CloudStorage/Dropbox/Labor Discipline/07. Data/3. Main Study 3.0"
ORIG = f"{BASE}/replication/data/final/05_bs_phase1_phase2_makevar_combined_daily_weekly.dta"
MOD  = f"{BASE}/replication/data/final/final_data_prioritize_in_person.dta"
OUT  = f"{BASE}/replication/data/temp/discrepancy_check/out"

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


def mark_in_sample(df):
    need = ["work1_wkly2","treatment","attend_week","bl_attend","bl_earn",
            "miss_bl_earn","bl_modalwage","stand","strata","week_in",
            "calendar_week"]
    df = df.copy()
    df["in_sample"] = df[need].notna().all(axis=1)
    return df


print("Loading MOD ...")
mod = load(MOD, COMMON + MOD_EXTRA)
mod = gen_bl_cov(mod)
mod = build_mod(mod)
mod_p2 = mark_in_sample(mod[mod["phase"] == 2])

print("Loading ORIG ...")
orig = load(ORIG, COMMON + ORIG_EXTRA)
orig = gen_bl_cov(orig)
orig = build_orig(orig)
orig_p2 = mark_in_sample(orig[orig["phase"] == 2])


# pid-level aggregation: worker-weeks contributed to e(sample)
def pid_summary(df_p2, tag):
    wk = (df_p2.groupby(["pid","week_in"], as_index=False)
               .agg(in_sample_week=("in_sample","any"),
                    work1_wkly2=("work1_wkly2","first")))
    return (wk.groupby("pid", as_index=False)
              .agg(**{f"n_worker_weeks_{tag}":   ("in_sample_week","sum"),
                      f"n_weeks_present_{tag}":  ("week_in","count"),
                      f"any_nonmiss_y_{tag}":    ("work1_wkly2",
                                                  lambda s: int(s.notna().any()))}))


mod_pid  = pid_summary(mod_p2,  "mod")
orig_pid = pid_summary(orig_p2, "orig")

all_pids = (mod[["pid","stand","strata","treatment"]]
              .drop_duplicates("pid")
              .merge(orig[["pid"]].drop_duplicates("pid"), on="pid", how="outer"))

out = (all_pids.merge(mod_pid,  on="pid", how="left")
                .merge(orig_pid, on="pid", how="left"))
for c in ["n_worker_weeks_mod","n_weeks_present_mod","any_nonmiss_y_mod",
          "n_worker_weeks_orig","n_weeks_present_orig","any_nonmiss_y_orig"]:
    out[c] = out[c].fillna(0).astype(int)

out["in_orig_regression"] = out["n_worker_weeks_orig"] > 0
out["in_mod_regression"]  = out["n_worker_weeks_mod"]  > 0

# PIDs NOT in ORIG regression
missing_from_orig = (out[~out["in_orig_regression"]]
                       .sort_values(["in_mod_regression","pid"],
                                    ascending=[False, True]))

path = f"{OUT}/pids_not_in_orig_regression.csv"
missing_from_orig.to_csv(path, index=False)

# Console summary
n_total = len(out)
n_in_orig = int(out["in_orig_regression"].sum())
n_in_mod  = int(out["in_mod_regression"].sum())
n_missing_orig = len(missing_from_orig)
n_missing_orig_but_in_mod = int(missing_from_orig["in_mod_regression"].sum())
n_missing_both = n_missing_orig - n_missing_orig_but_in_mod

print(f"\n=== PID coverage ===")
print(f"Total PIDs in datasets          : {n_total}")
print(f"PIDs in MOD  regression sample  : {n_in_mod}")
print(f"PIDs in ORIG regression sample  : {n_in_orig}")
print(f"PIDs NOT in ORIG regression     : {n_missing_orig}")
print(f"  of which: also not in MOD     : {n_missing_both}")
print(f"  of which: in MOD only         : {n_missing_orig_but_in_mod}")

print(f"\nList of PIDs not in ORIG regression:")
print(missing_from_orig[["pid","treatment","stand","strata",
                         "n_worker_weeks_mod","n_worker_weeks_orig",
                         "n_weeks_present_orig","any_nonmiss_y_orig",
                         "in_mod_regression"]].to_string(index=False))

print(f"\nSaved to: {path}")
