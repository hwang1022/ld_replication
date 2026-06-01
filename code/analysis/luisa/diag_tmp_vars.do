clear all
set linesize 200
global temp "/Users/owner/Library/CloudStorage/Dropbox/Labor Discipline/07. Data/3. Main Study 3.0/ld_replication/data/temp"
log using "diag_tmp_vars.log", replace text
use "$temp/03_phase1_completed_cleaned.dta", clear
di "==== PHASE1 howfound var names ===="
ds *howfound* *how_found*
di "==== PHASE1 d_howfound_1 label ===="
local L : value label d_howfound_1
di "label name = `L'"
label list `L'
di "==== PHASE1 d_howfound_notattend_1 label ===="
local L2 : value label d_howfound_notattend_1
di "label name = `L2'"
label list `L2'
log close
