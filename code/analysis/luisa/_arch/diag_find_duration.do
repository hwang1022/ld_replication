clear all
set more off
set linesize 160
global temp "/Users/owner/Library/CloudStorage/Dropbox/Labor Discipline/07. Data/3. Main Study 3.0/ld_replication/data/temp"
log using "$temp/../../code/analysis/luisa/diag_find_duration.log", replace text

* keyword patterns in NAME or LABEL that would signal a duration/length/sequence/start
local kw "durat length howlong long days dias day spell multiday multi_day multi day_ ndays numday weeks week month start begin since until end finish consecut sequence seq period span tenure how_many howmany lasted last_"

foreach f in 03_phase1_completed_cleaned 03_phase2_completed_cleaned 05_phase1_phase2_makepanel {
    di "============================================================"
    di "FILE: `f'.dta"
    di "============================================================"
    use "$temp/`f'.dta", clear
    di "  (n vars = " c(k) ")"
    foreach v of varlist _all {
        local lab : variable label `v'
        local lname = lower("`v'")
        local llab  = lower("`lab'")
        foreach k of local kw {
            if strpos("`lname'","`k'") | strpos("`llab'","`k'") {
                di "  `v'  |  `lab'"
                continue, break
            }
        }
    }
}
log close
