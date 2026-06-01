local final_data_w_shocks "$final/final_data_w_shocks.dta"

cap mkdir "$output"
cap mkdir "$output/figures"

use "`final_data_w_shocks'", clear

gen bins1 = .
replace bins1 = 0 if week_in == 0 | phase == 0
replace bins1 = 1.5 if inlist(week_in, 1, 2) & phase == 1
replace bins1 = 4 if inlist(week_in, 3, 4, 5) & phase == 1
replace bins1 = 6.5 if inlist(week_in, 6, 7) & phase == 1
replace bins1 = 8.5 if inlist(week_in, 1, 2) & phase == 2
replace bins1 = 10.5 if inlist(week_in, 3, 4) & phase == 2
replace bins1 = 12.5 if inlist(week_in, 5, 6) & phase == 2
replace bins1 = 14.5 if inlist(week_in, 7, 8) & phase == 2
replace bins1 = 17.5 if inlist(week_in, 1, 2, 3, 4) & phase == 3
replace bins1 = 21.5 if inlist(week_in, 5, 6, 7, 8) & phase == 3
replace bins1 = 25.5 if inlist(week_in, 9, 10, 11, 12) & phase == 3
replace bins1 = 29.5 if inlist(week_in, 13, 14, 15, 16) & phase == 3
replace bins1 = 33.5 if inlist(week_in, 17, 18, 19, 20) & phase == 3
replace bins1 = 37.5 if inlist(week_in, 21, 22, 23, 24) & phase == 3
replace bins1 = 41.5 if inlist(week_in, 25, 26, 27, 28) & phase == 3

reg attend_adj bl_attend bl_earn miss_bl_earn bl_modalwage i.strata i.stand i.calendar_week, vce(clu pid)
predict attend_adj_resid2 if e(sample), resid

// 2026-05-21 Simon: Old figure only had upto week 22. So modifying code to match; however original code had the commented out line below
// regardless, easy to change as needed
// keep if bins1 != . & bins1 < 40
local max_week 23
keep if bins1 != . & bins1 < `max_week'


binscatter attend_adj_resid2 bins1, by(treatment) discrete colors(navy maroon) msymbols(O X) ///
	xline(7.5, lpattern(dash) lcolor(black)) xline(15.5, lpattern("..--..--") lcolor(black)) ///
	xline(0.5, lpattern(dash_dot) lcolor(black)) line(connect) ///
	legend(label(1 "Control") label(2 "Treatment") size(small) row(1) symysize(0.75) symxsize(5) region(lstyle(none)) position(bottom)) ///
	ytitle("Weekly Mean Attend", size(small)) xtitle("Weeks in Phase", size(small)) yscale(range(-1 1.2)) xlab(0(5)`max_week') ///
	text(1.2 4 "{bf:Phase 1}", size(small)) text(1.2 11.5 "{bf:Phase 2}", size(small)) ///
	text(1.2 20 "{bf:Phase 3}", size(small)) text(1.2 0 "{bf:BL}", size(small))
graph export "$output/figures/attend_adj_bs_p1_p2_p3_stand_calweek_v2_noci.pdf", replace
graph export "$output/figures/figure_d_noci.pdf", replace

statsby, by(bins1 treatment) clear: ci means attend_adj_resid2, level(90)
drop N se level
twoway (connected mean bins1 if treatment == 1, lc(maroon) mcolor(maroon)) (rcap lb ub bins1 if treatment == 1, lc(maroon)) ///
	(connected mean bins1 if treatment == 0, lc(navy) mcolor(navy)) (rcap lb ub bins1 if treatment == 0, lc(navy)), ///
	xline(7.5, lpattern(dash) lcolor(black)) xline(15.5, lpattern("..--..--") lcolor(black)) ///
	xline(0.5, lpattern(dash_dot) lcolor(black)) ///
	legend(label(1 "Control") label(2 "Treatment") size(small) row(1) symysize(0.75) symxsize(5) region(lstyle(none)) position(bottom)) ///
	ytitle("Weekly Mean Attend", size(small)) xtitle("Weeks in Phase", size(small)) yscale(range(-1 1.2)) xlab(0(5)`max_week') ///
	text(1.2 4 "{bf:Phase 1}", size(small)) text(1.2 11.5 "{bf:Phase 2}", size(small)) ///
	text(1.2 20 "{bf:Phase 3}", size(small)) text(1.2 0 "{bf:BL}", size(small))
graph export "$output/figures/attend_adj_bs_p1_p2_p3_stand_calweek_v2.pdf", replace
graph export "$output/figures/figure_d.pdf", replace
