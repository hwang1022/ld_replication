*****************************************************************
*  diag_verify_multiday.do
*  Verify how multiday_job is built and whether the
*  "howfound==5" fallback misflags v2 "phone-friend" days.
*****************************************************************
clear all
set more off
global temp "/Users/owner/Library/CloudStorage/Dropbox/Labor Discipline/07. Data/3. Main Study 3.0/ld_replication/data/temp"
log using "$temp/../../code/analysis/luisa/diag_verify_multiday.log", replace text

*=== A. In the RAW phase-2 file, do v1 & v2 howfound + the explicit multiday Q coexist? ===
use "$temp/03_phase2_completed_cleaned.dta", clear
di "==== phase2: variables for howfound / multiday ===="
foreach p in *howfound* *multiday* {
    cap ds `p'
}

* explicit multiday yes/no question name + label
di "==== label on f_multiday_job_1 (explicit Q) ===="
cap local Lm : value label f_multiday_job_1
di "f_multiday_job_1 value label = `Lm'"
cap label list `Lm'

* For grid slot 1: when howfound came from v2 (f_howfound missing, f_howfound_v2 present),
* is the explicit multiday question answered? and what is it when v2 howfound==5?
di "==== slot1: is explicit multiday Q present on v2-sourced rows? ===="
gen byte v2src_1 = mi(f_howfound_1) & !mi(f_howfound_v2_1)
tab v2src_1, missing
di "  among v2-sourced slot-1 rows, explicit multiday Q (missing?) :"
tab f_multiday_job_1 v2src_1, missing

di "==== slot1: v2 howfound==5 (phone-friend) -> what explicit multiday value? ===="
tab f_multiday_job_1 if f_howfound_v2_1==5, missing

*=== B. Reproduce the combine fallback to COUNT contaminated days ===
* Mirror 3_combine logic for howfound + multiday across the 7 grid slots,
* tracking provenance (v1 vs v2) so we can flag misclassification.
use "$temp/03_phase2_completed_cleaned.dta", clear
rename f_* d_*

local bad_total 0
local md5_total 0
forval i = 1/7 {
    cap confirm variable d_howfound_`i'
    if _rc continue
    * provenance: this slot's howfound will be taken from v2 iff v1 missing & v2 present
    gen byte v2src_`i' = mi(d_howfound_`i') & !mi(d_howfound_v2_`i')
    * combined howfound (mirror line 179)
    gen hf_`i' = d_howfound_`i'
    replace hf_`i' = d_howfound_v2_`i' if mi(hf_`i')
    * explicit multiday question for this slot (may not exist in v2)
    * combined multiday per line 258-260 (notattend not in phase2 grid the same way; approximate)
    gen byte md_`i' = d_multiday_job_`i'
    replace md_`i' = (hf_`i'==5) if mi(md_`i') & !mi(hf_`i')
    * CONTAMINATION: md set to 1 via the ==5 fallback on a v2-sourced row
    *   (v2 code 5 = phone-friend, NOT multiday)
    gen byte bad_`i' = (md_`i'==1 & v2src_`i'==1 & mi(d_multiday_job_`i') & hf_`i'==5)
    qui count if bad_`i'==1
    local b = r(N)
    qui count if hf_`i'==5 & md_`i'==1
    local m = r(N)
    di "slot `i': multiday-by-code5 = `m';  of which v2 phone-friend MISFLAGGED = `b'"
    local bad_total = `bad_total' + `b'
    local md5_total = `md5_total' + `m'
}
di "==== TOTAL across slots: multiday flagged via howfound==5 = `md5_total'; misflagged v2 phone-friend = `bad_total' ===="

log close
