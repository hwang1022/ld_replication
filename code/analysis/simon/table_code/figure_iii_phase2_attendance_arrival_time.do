global data "`c(pwd)'/data"
local analysis_main "$data/final/analysis_main.dta"

cap mkdir "$data/output"
cap mkdir "$data/output/figures"

use `analysis_main', clear

gen arrival_time_hours_std_daily = arrival_time_hours
replace arrival_time_hours_std_daily = arrival_time_hours - 0.25 if inlist(stand, 2, 6, 15, 17, 19, 20)
replace arrival_time_hours_std_daily = arrival_time_hours + 0.25 if inlist(stand, 12)
replace arrival_time_hours_std_daily = 10 if arrival_time_hours_std_daily >= 10 & arrival_time_hours_std_daily != .

ksmirnov attend_nadj if phase == 2, by(treatment)
local pval: display %4.3f `r(p)'
distplot attend_nadj if phase == 2, lcolor(gs12 maroon) over(treatment) ///
	ylabel(, nogrid) legend(order(1 "Control" 2 "Treatment") pos(6) row(1) region(lstyle(none))) ///
	note("K-Smirnov test p-value: `pval'") graphregion(color(white)) ///
	xtitle("Days of attendance in a week (Phase 2)")
graph export "$data/output/figures/comm_dist_attend_nadj_p2.pdf", replace
graph export "$data/output/figures/figure_iii_a.pdf", replace

twoway (hist arrival_time_hours_std_daily if treatment == 0 & inrange(arrival_time_hours_std_daily, 5.5, 12) & phase == 2, lcolor(gs12) fcolor(gs12) fraction start(5.5) width(0.25)) || ///
	(hist arrival_time_hours_std_daily if treatment == 1 & inrange(arrival_time_hours_std_daily, 5.5, 12) & phase == 2, fcolor(none) lcolor(maroon) lwidth(medium) fraction start(5.5) width(0.25)), ///
	legend(on row(1) label(1 "Control") label(2 "Treatment") pos(6) ring(1)) ///
	xlabel(6(1)10) xmtick(6.5(1)10) note("*Treatment cut-off times are standardised to 8am") ///
	graphregion(color(white)) xtitle("Arrival time (observed) in fraction of hours (Phase 2)")
graph export "$data/output/figures/hist_arrival_time_by_treatment_p2_daily.pdf", replace
graph export "$data/output/figures/figure_iii_b.pdf", replace
