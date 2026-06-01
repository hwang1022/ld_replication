*************************************************
*  diag: recover value labels for howfound /
*  whenfound / howfound_notattend
*************************************************

clear all
set more off

global temp "/Users/owner/Library/CloudStorage/Dropbox/Labor Discipline/07. Data/3. Main Study 3.0/ld_replication/data/temp"

log using "$temp/../../code/analysis/luisa/diag_explore_labels.log", replace text

use "$temp/04_phase1_phase2_cleaned.dta", clear

di "==== label list howfound (rd4_1) ===="
label list rd4_1

di "==== label list whenfound (rd3_1) ===="
label list rd3_1

di "==== label list howfound_notattend (rd6_1) ===="
label list rd6_1

di "==== label list multiday (rf4_1_1) ===="
label list rf4_1_1

di "==== tab d_howfound_1 ===="
tab d_howfound_1, missing
di "==== tab d_whenfound_1 ===="
tab d_whenfound_1, missing
di "==== tab d_howfound_notattend_1 ===="
tab d_howfound_notattend_1, missing

log close
