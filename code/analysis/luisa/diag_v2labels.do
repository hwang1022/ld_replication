clear all
set more off
global temp "/Users/owner/Library/CloudStorage/Dropbox/Labor Discipline/07. Data/3. Main Study 3.0/ld_replication/data/temp"
log using "$temp/../../code/analysis/luisa/diag_v2labels.log", replace text

use "$temp/03_phase2_completed_cleaned.dta", clear
di "==== rf4_v2_1 (phase2 howfound v2) label ===="
label list rf4_v2_1
di "==== rf4_1 (phase2 howfound) label ===="
label list rf4_1
di "==== tab f_howfound_v2_1 ===="
tab f_howfound_v2_1, missing
log close
