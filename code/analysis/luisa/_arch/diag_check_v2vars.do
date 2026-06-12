clear all
set more off
set linesize 160
global temp "/Users/owner/Library/CloudStorage/Dropbox/Labor Discipline/07. Data/3. Main Study 3.0/ld_replication/data/temp"
log using "$temp/../../code/analysis/luisa/diag_check_v2vars.log", replace text

di "############ PHASE 2 RAW: enumerate ALL *v2* variables ############"
use "$temp/03_phase2_completed_cleaned.dta", clear
ds *v2*
di ""
di "############ PHASE 1 RAW: enumerate ALL *v2* variables ############"
use "$temp/03_phase1_completed_cleaned.dta", clear
cap ds *v2*
if _rc di "  (no *v2* variables in phase 1 raw)"

di ""
di "############ RECONCILIATION at 3_combine line 175: why_attend <- why_notattend_v2 ############"
use "$temp/03_phase2_completed_cleaned.dta", clear
di "---- variable labels ----"
foreach v in f_why_attend_1 f_why_notattend_1 f_why_notattend_v2_1 {
    local l : variable label `v'
    local vl : value label `v'
    di "  `v'   | varlabel: `l'   | value label: `vl'"
}
di "---- VALUE LABELS side by side ----"
di "== f_why_attend_1 (v1, the target) =="
local L : value label f_why_attend_1
label list `L'
di "== f_why_notattend_1 (v1 'if tried, why not attend') =="
local L : value label f_why_notattend_1
label list `L'
di "== f_why_notattend_v2_1 (v2, the source poured in) =="
local L : value label f_why_notattend_v2_1
label list `L'

di ""
di "############ MAIN ACTIVITY: is there a v2 variant? ############"
di "---- f_main_activity_1 label & value label ----"
local l : variable label f_main_activity_1
local vl : value label f_main_activity_1
di "  f_main_activity_1 | varlabel: `l' | value label: `vl'"
label list `vl'
di "---- any main-activity variable containing v2? ----"
cap ds *main*v2*
if _rc di "  (none: main_activity has NO v2 variant -> not reconciled across versions)"

di ""
di "############ COMP RECALL v2 vars (line 148) ############"
foreach v in f_comp_where_v2 {
    cap confirm variable `v'
    if !_rc {
        local l : variable label `v'
        local vl : value label `v'
        di "  `v' | varlabel: `l' | value label: `vl'"
    }
}
log close
