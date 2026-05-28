*************************************************
*   Diagnostic: why does daily_recall_lag get set on rows where
*   recall_reliable is missing? (146 rows in the current build)
*
*   Runs read-only on $temp/05_phase1_phase2_makepanel_unrestricted.dta
*   which contains daily_recall_lag, recall_reliable, and the post-
*   replace `mode` variable (1=in-person survey, 2=phone survey,
*   3=row filled by recall but no original survey, .=nothing).
*
*   Hypotheses:
*     A: source row had mode ∈ {1,2} (real daily survey) but no d_work /
*        d_main_act_work recorded.
*     B: source row had mode == 3 or . — i.e., no actual daily survey,
*        data came from comp-recall or other upstream imputation.
*************************************************

* <FIXME> LC 2026-04-20 — bootstrap paths so this can run standalone
if mi("$replication_dir") {
    global db_dir "~/Dropbox"
    global replication_dir "$db_dir/Labor Discipline/07. Data/3. Main Study 3.0/replication"
    global temp "$replication_dir/data/temp"
}

use "$temp/05_phase1_phase2_makepanel_unrestricted.dta", clear

di _newline as text ">>> Shape of the problem:"
count
count if !mi(daily_recall_lag) & mi(recall_reliable)

* For each of the "daily_recall_lag set but recall_reliable missing" rows,
* look up the source row's mode (mode[_n+daily_recall_lag] within same pid).
gen source_row_mode = .
forvalues z = 1/7 {
    bys pid (date): replace source_row_mode = mode[_n+`z'] ///
        if daily_recall_lag == `z' & pid == pid[_n+`z']
}
lab var source_row_mode "Mode on the source row (D + daily_recall_lag days ahead)"

di _newline as text ">>> Distribution of source_row_mode on the 146 rows (daily_recall_lag set, recall_reliable missing):"
tab source_row_mode if !mi(daily_recall_lag) & mi(recall_reliable), m

di _newline as text ">>> For reference: source_row_mode distribution on rows where BOTH daily_recall_lag and recall_reliable are set (expected mostly 1/2):"
tab source_row_mode if !mi(daily_recall_lag) & !mi(recall_reliable), m

di _newline as text ">>> Cross-tab: source_row_mode by recall_reliable-missingness, among daily_recall_lag set:"
gen recall_reliable_missing = mi(recall_reliable)
tab source_row_mode recall_reliable_missing if !mi(daily_recall_lag), m

di _newline as text ">>> Sample of 10 rows from the 146:"
gsort -daily_recall_lag pid date
list pid date phase mode daily_recall_lag source_row_mode recall_reliable work work_orig if !mi(daily_recall_lag) & mi(recall_reliable) in 1/10, sep(0) noobs abbrev(16)

di _newline as text ">>> Done."
