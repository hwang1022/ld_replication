*************************************************
*  diag: explore variables to build job-source
*  (stand vs outside) and multiday-job spell
*  Author: Claude (diagnostic only)
*************************************************

clear all
set more off

global temp "/Users/owner/Library/CloudStorage/Dropbox/Labor Discipline/07. Data/3. Main Study 3.0/ld_replication/data/temp"

log using "$temp/../../code/analysis/luisa/diag_explore_jobsource.log", replace text

*** ---- 05 makepanel (the file we will build the var in) ----
use "$temp/05_phase1_phase2_makepanel.dta", clear

di "==== 05_phase1_phase2_makepanel: N ===="
count

di "==== value labels / tabs ===="
foreach v in whenfound howfound howfound_notattend multiday_job multiday_job_cond work work_orig work1 attend mode {
    di "----------- `v' -----------"
    tab `v', missing
}

di "==== cross tab howfound vs multiday_job ===="
tab howfound multiday_job, missing

di "==== cross tab howfound_notattend vs multiday_job ===="
tab howfound_notattend multiday_job, missing

di "==== cross tab whenfound vs work ===="
tab whenfound work, missing

di "==== work_source_? vars present? ===="
ds work_source*
describe work_source*
foreach v of varlist work_source* {
    di "----------- `v' -----------"
    cap tab `v', missing
}

log close
