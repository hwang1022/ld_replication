************************************************************
* Table VI: Willingness to Forgo Flexibility
* Source: replication/code/analysis/archive/paper_analysis_newdata.do
*         Flexibility block around line 880
************************************************************

global tstat 1.589 // 10 % CI
clear

set obs 3
gen control_mean = 2.577
global control_mean = 0


gen mean = $control_mean +.466 if _n == 1 // ATE
replace mean = $control_mean + 0.791 if _n == 2 // Pre shock
replace mean = $control_mean  + 0.791 - 0.791 if _n == 3 // Post shock

gen se = 0.196 if _n == 1 // ATE
replace se = .243 if _n == 2 // Pre shock
replace se = .348 if _n == 3 // Pre shock

** 10 % CI (tstat 1.589)
gen ub = mean + ${tstat}*se
gen lb = mean - ${tstat}*se

gen bord = _n

twoway (scatteri  ${control_mean} 0.5 ${control_mean} 3.5, recast(line) lw(vthin)) ///
(scatter mean bord , lcolor(gs8) fcolor(gs8%60)) ///
(rcap ub lb bord , lcolor(maroon) lw(thin) ), ///
plotregion(margin(0)) xscale(r(.5 3.5)) ///
xlabel(1 "ATE" 2 `""Treatment" "{&Chi} Pre-Shock""' 3 `""Treatment" "{&Chi} Post-Shock""', notick) ///
ylabel(-1(.5)1.5) ytitle("Treatment effect on attendance" "(days)") ///
legend(off)


///
(scatter p_y1 p_x1 , msym(none) mlab(lab1) mlabpos(0) mlabcolor(gs8) mlabsize(large)) ///
(scatteri 4.5 0 4.5 1,  recast(line) lw(medium)  mc(none) lc(black) lp(solid) lw(thin)) ///
(scatteri 4.5 0 4.5 1,  recast(dropline) base(4.48) lw(medium) mc(none) lc(black) lp(solid) lw(thin)), ///
xlabel(0 "Control" 1 "Treatment", notick) ///
legend(off) xtitle("") ytitle("Automaticity (0-5)") 
graph export "${output_dir}/fig_automaticity_te_zoom.png", replace





gen mean = $te if _n == 1
replace mean = $te_shock if _n == 2

gen ub = mean + 1.96*$se_beta if _n == 1
replace ub = mean + 1.96*$se_beta_shock if _n == 2

gen lb = mean - 1.96*$se_beta if _n == 2
replace lb = mean - 1.96*$se_beta_shock if _n == 2


cap drop lab1
cap drop p_y1
cap drop p_x1
gen lab1 = "{&Delta}{sub:p}  = $beta_lab , p = $pval"
gen p_y1 = 4.55
gen p_x1 = .5 	


cap drop p_y1_s
gen p_y1_s = 4.9


gen treat = 0 if _n == 1
replace treat = 1 if _n == 2

twoway (bar mean treat if treat == 0, lcolor(gs8) fcolor(gs8%60)) ///
(bar mean treat if treat == 1, lcolor(maroon) fcolor(maroon)) ///
(rcap ub lb treat if treat == 1, lcolor(maroon) lw(thin) ) ///
(scatter p_y1 p_x1 , msym(none) mlab(lab1) mlabpos(0) mlabcolor(gs8) mlabsize(large)) ///
(scatteri 4.5 0 4.5 1,  recast(line) lw(medium)  mc(none) lc(black) lp(solid) lw(thin)) ///
(scatteri 4.5 0 4.5 1,  recast(dropline) base(4.48) lw(medium) mc(none) lc(black) lp(solid) lw(thin)), ///
xlabel(0 "Control" 1 "Treatment", notick) ///
legend(off) xtitle("") ytitle("Automaticity (0-5)") 
graph export "${output_dir}/fig_automaticity_te_zoom.png", replace



twoway (bar mean treat if treat == 0, lcolor(gs8) fcolor(gs8%60)) ///
(bar mean treat if treat == 1, lcolor(maroon) fcolor(maroon)) ///
(rcap ub lb treat if treat == 1, lcolor(maroon) lw(thin)) ///
(scatter p_y1_s p_x1 , msym(none) mlab(lab1) mlabpos(0) mlabcolor(gs8) mlabsize(large)) ///
(scatteri 4.6 0 4.6 1,  recast(line) lw(medium)  mc(none) lc(black) lp(solid) lw(thin)) ///
(scatteri 4.6 0 4.6 1,  recast(dropline) base(4.5) lw(medium) mc(none) lc(black) lp(solid) lw(thin)), ///
xlabel(0 "Control" 1 "Treatment", notick) ///
legend(off) xtitle("") ytitle("Automaticity (0-5)") ///
yscale(r(0 5)) ylabel(0(1)5)
graph export "${output_dir}/fig_automaticity_te_scale0-5.png", replace





