clear all
set more off
set linesize 160
global temp "/Users/owner/Library/CloudStorage/Dropbox/Labor Discipline/07. Data/3. Main Study 3.0/ld_replication/data/temp"
log using "$temp/../../code/analysis/luisa/diag_verify_recode.log", replace text
use "$temp/03_phase2_completed_cleaned.dta", clear

di "==== (A) Do all 7 slots share the SAME value labels? (so one crosswalk fits all) ===="
forval i = 1/7 {
    local v1 : value label f_howfound_`i'
    local v2 : value label f_howfound_v2_`i'
    di "  slot `i':  v1 label = `v1'   |   v2 label = `v2'"
}

di ""
di "==== (B) Side-by-side: each v2 code, its meaning, the target v1 code, its meaning ===="
di "  v2 -> v1   | v2 label  ||  v1 label"
di "  ------------------------------------------------------------------"
* hardcode the intended map and print labels from the data to confirm meaning
foreach pair in "1 1" "2 1" "3 2" "4 2" "5 3" "6 3" "7 4" "8 6" "9 6" "10 7" "11 8" {
    tokenize "`pair'"
    local from `1'
    local to   `2'
    local lv2 : label (f_howfound_v2_1) `from'
    local lv1 : label (f_howfound_1)    `to'
    di "  v2 `from' -> v1 `to'"
    di "       v2: `lv2'"
    di "       v1: `lv1'"
}

di ""
di "==== (C) EMPIRICAL: run the recode, cross-tab raw v2 vs recoded (all 7 slots stacked) ===="
* stack the 7 v2 slots into one long var so we see the full mapping in one table
preserve
    keep f_howfound_v2_*
    gen long _id = _n
    reshape long f_howfound_v2_, i(_id) j(slot)
    rename f_howfound_v2_ v2raw
    gen v2map = v2raw
    recode v2map (1 2=1)(3 4=2)(5 6=3)(7=4)(8 9=6)(10=7)(11=8)
    di "  rows of raw v2 (any slot) by mapped value:"
    tab v2raw v2map, missing
    di "  --- confirm 998/999/missing pass through unchanged ---"
    count if v2raw==998 & v2map!=998
    count if v2raw==999 & v2map!=999
    count if mi(v2raw) & !mi(v2map)
    di "  (all three counts should be 0)"
    di "  --- confirm no mapped value falls outside the v1 scheme {1,2,3,4,6,7,8,998,999} ---"
    count if !mi(v2map) & !inlist(v2map,1,2,3,4,6,7,8,998,999)
    di "  (should be 0; note 5=Multi-day is intentionally never produced from v2)"
restore
log close
