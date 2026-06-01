************************************************************
* Appendix Table A.1: Weekly Incentive Amount in Phase 1
* Source: verification.md Table A.1 and FAQ_analysis.do
* balance_test_incentive_record_only block.
************************************************************

version 17
clear all
set more off

local phase1_incentive "$temp/incentive_record_stand_clean.dta"

local outdir "$output/tables"
capture mkdir "$output"
capture mkdir "`outdir'"

use "`phase1_incentive'", clear

lab var amount_allotted "Payment allocated"

baltab amount_allotted ///
	using "`outdir'/balance_test_incentive_record_only.tex", ///
	groupvar(treatment) texcolwidth("200 pt") rowvarlabel stats(pair(p))

copy "`outdir'/balance_test_incentive_record_only.tex" "`outdir'/table_h.tex", replace
