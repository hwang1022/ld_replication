************************************************************
* Appendix Table A.1: Weekly Incentive Amount in Phase 1
* Source: verification.md Table A.1 and FAQ_analysis.do
* balance_test_incentive_record_only block.
************************************************************

version 17
clear all
set more off

global data "`c(pwd)'/data"
local phase1_incentive "$data/05a. Phase 1 Incentive/02. Output/temp/phase1_incentive_survey_vs_record_makevar.dta"

local outdir "$data/output/tables"
capture mkdir "$data/output"
capture mkdir "`outdir'"

use `phase1_incentive', clear

lab var amount_allotted "Payment allocated"

baltab amount_allotted ///
	using "`outdir'/balance_test_incentive_record_only.tex", ///
	groupvar(treatment) texcolwidth("200 pt") rowvarlabel stats(pair(p))

copy "`outdir'/balance_test_incentive_record_only.tex" "`outdir'/table_a_i.tex", replace
