*************************************************
*  diag: understand multiday-job structure,
*  unlabeled howfound cats 9/10/11, and
*  whenfound x howfound mapping
*************************************************

clear all
set more off

global temp "/Users/owner/Library/CloudStorage/Dropbox/Labor Discipline/07. Data/3. Main Study 3.0/ld_replication/data/temp"

log using "$temp/../../code/analysis/luisa/diag_explore_multiday.log", replace text

*** ---- 04 cleaned: hunt for any multiday duration/sequence vars ----
use "$temp/04_phase1_phase2_cleaned.dta", clear

di "==== search related patterns (guarded) ===="
foreach p in *howmany* *num_day* *days* *duration* *seq* *rf4* *rd4* *rd5* *rf5* *multiday* {
    cap ds `p'
    if _rc==0 di "  (pattern `p' matched above)"
}

di "---- describe d_multiday* and rf4 family ----"
cap describe d_multiday*
cap describe d_multidayjob_notattend_1

*** check v2 label for howfound (categories 9/10/11 may come from v2)
di "==== d_howfound_v2 label ===="
cap describe d_howfound_v2_1
cap local lblv2 : value label d_howfound_v2_1
di "v2 label name = `lblv2'"
cap label list `lblv2'

di "==== tab raw d_howfound_v2_1 ===="
cap tab d_howfound_v2_1, missing

*** ---- 05 makepanel: whenfound x howfound, and 9/10/11 ----
use "$temp/05_phase1_phase2_makepanel.dta", clear

di "==== whenfound x howfound (collapsed) ===="
tab howfound whenfound, missing

di "==== among attend==1 & work==1, howfound distribution ===="
tab howfound if attend==1 & work==1, missing

di "==== among attend==0 & work==1, howfound_notattend distribution ===="
tab howfound_notattend if attend==0 & work==1, missing

di "==== whenfound present vs howfound present ===="
gen has_when = !mi(whenfound)
gen has_how  = !mi(howfound)
tab has_when has_how

di "==== for multiday_job==1 days: whenfound/howfound present? ===="
tab howfound if multiday_job==1, missing
tab whenfound if multiday_job==1, missing

log close
