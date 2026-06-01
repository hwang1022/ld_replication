clear all
set more off
set linesize 160
global temp "/Users/owner/Library/CloudStorage/Dropbox/Labor Discipline/07. Data/3. Main Study 3.0/ld_replication/data/temp"
log using "$temp/../../code/analysis/luisa/diag_codes_reliable.log", replace text

di "=================== PHASE 2 RAW: howfound v1 vs v2 value labels ==================="
use "$temp/03_phase2_completed_cleaned.dta", clear
local L1 : value label f_howfound_1
local L2 : value label f_howfound_v2_1
di "f_howfound_1 (v1) uses value label: `L1'"
label list `L1'
di "----"
di "f_howfound_v2_1 (v2) uses value label: `L2'"
label list `L2'
di "----"
di "f_howfound_notattend_1 label:"
local L3 : value label f_howfound_notattend_1
di "  -> `L3'"
label list `L3'

di "=================== PHASE 1 RAW: howfound value label ==================="
use "$temp/03_phase1_completed_cleaned.dta", clear
local L4 : value label d_howfound_1
di "d_howfound_1 uses value label: `L4'"
label list `L4'
di "----"
local L5 : value label d_howfound_notattend_1
di "d_howfound_notattend_1 uses value label: `L5'"
label list `L5'

di "=================== MAKEPANEL: recall_reliable present? & combined howfound label ==================="
use "$temp/05_phase1_phase2_makepanel.dta", clear
cap confirm variable recall_reliable
di "recall_reliable exists? rc=" _rc
cap confirm variable work_source_inperson
di "work_source_inperson exists? rc=" _rc
cap confirm variable mode
di "mode exists? rc=" _rc
di "---- recall_reliable tab ----"
cap tab recall_reliable, missing
di "---- combined howfound value label in panel ----"
local L6 : value label howfound
di "howfound (panel) uses value label: `L6'"
label list `L6'
log close
