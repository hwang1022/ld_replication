clear all
set more off
set linesize 160
global temp "/Users/owner/Library/CloudStorage/Dropbox/Labor Discipline/07. Data/3. Main Study 3.0/ld_replication/data/temp"
log using "$temp/../../code/analysis/luisa/diag_spell_spansun.log", replace text
use "$temp/05_phase1_phase2_makepanel.dta", clear
sort pid date
gen byte multiday_work = (work==1 & multiday_job==1)
gen byte mwflag = multiday_work if work==1
* Definition A spells (skip non-work) over WORK days
preserve
    keep if work==1
    sort pid date
    by pid: gen byte lag_mw = mwflag[_n-1]
    by pid: gen long spellstart = (mwflag==1 & (lag_mw!=1 | mi(lag_mw)))
    by pid: gen long spell_id = sum(spellstart) if mwflag==1
    bys pid spell_id (date): gen long lenA = _N if !mi(spell_id)
    keep pid date spell_id spellstart lenA
    tempfile A
    save `A'
restore
merge 1:1 pid date using `A', nogen
* find an A-spell whose interior contains a non-work day (calendar span > work-day count)
gen int dow = dow(date)   // 0=Sunday
preserve
    keep if !mi(spell_id)
    bys pid spell_id (date): gen long span_cal = date[_N]-date[1]+1
    bys pid spell_id (date): gen byte hasgap = (span_cal > lenA)
    bys pid spell_id (date): keep if _n==1
    keep if hasgap==1 & lenA>=3
    sort pid spell_id
    di "  example spells that span a non-work day (cal span > #work days):"
    list pid spell_id lenA span_cal in 1/5, clean noobs
    local egpid  = pid[1]
    global egpid = `egpid'
restore
di "==== day-by-day for example worker (one spell straddling a non-work day) ===="
sort pid date
list date dow work multiday_job spell_id lenA if pid==$egpid & !mi(spell_id), clean noobs
* also list a couple surrounding days for context
log close
