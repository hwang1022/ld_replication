clear all
set more off
global temp "/Users/owner/Library/CloudStorage/Dropbox/Labor Discipline/07. Data/3. Main Study 3.0/ld_replication/data/temp"
use "$temp/05_phase1_phase2_makepanel.dta", clear
foreach p in *holiday* *sunday* *dow* *weekday* *dayofweek* *reason* *noshow* *attend* *work* *day_off* {
    cap ds `p'
}
di "---- is panel a full daily calendar per pid? ----"
sort pid date
by pid: gen gap = date - date[_n-1]
di "gaps > 1 day between consecutive panel rows for a worker:"
count if gap>1 & !mi(gap)
tab gap
di "---- work variable values ----"
tab work, missing
