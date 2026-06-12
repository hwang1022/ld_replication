************************************************************
* Appendix Table A.1: Weekly Incentive Amount in Phase 1
* Source: verification.md Table A.1 and FAQ_analysis.do
* balance_test_incentive_record_only block.
************************************************************

version 17
clear all
set more off

local phase1_incentive "$temp/incentive_record_stand_clean.dta"


use "`phase1_incentive'", clear

lab var amount_allotted "Payment Record: Amount Allotted"
lab var amount_payed 	"Payment Record: Amount Paid"

iebaltab amount_allotted amount_payed, ///
	savetex("$output/tables/balance_test_incentive_record_only.tex") replace ///
	groupvar(treatment) texcolwidth("200 pt") rowvarlabel total ///
	nonote addnote("* p<0.10, ** p<0.05, *** p<0.01")

copy "$output/tables/balance_test_incentive_record_only.tex" "$output/tables/table_h.tex", replace
