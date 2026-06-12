************************************************************
* Q: Is the V0c null driven by small stands?
* Approach: build the shock under V0 and V0c, then run the
* shock regression on (a) all stands, (b) "large" stands only,
* (c) "small" stands only. "Size" = number of unique control
* workers in that stand.
************************************************************

	clear all
	set more off
	cap log close
	set linesize 180

	global db_dir          "~/Dropbox"
	global ld_dir          "$db_dir/Labor Discipline"
	global replication_dir "$ld_dir/07. Data/3. Main Study 3.0/ld_replication"
	global final           "$replication_dir/data/final"
	global main_data       "$final/final_data_prioritize_date.dta"
	global out_dir         "$replication_dir/code/analysis/luisa"

	log using "$out_dir/compare_bystand.log", replace text


program drop _all
program define build_shock
	preserve
		keep if phase == 2
		set type double
		collapse (sum) w_sum = resid_day_attendph2 ///
		         (count) w_n = resid_day_attendph2 ///
		         (first) standid, by(calendar_week pid treat)
		bysort standid calendar_week: egen sw_sum = total(w_sum)
		bysort standid calendar_week: egen sw_n   = total(w_n)
		sort pid calendar_week
		gen double avg_wkattend_loo = (sw_sum - w_sum) / (sw_n - w_n)
		bys pid calendar_week: keep if _n == 1
		sum avg_wkattend_loo, d
		scalar pct_j_attend = r(p25)
		keep pid calendar_week avg_wkattend_loo
		gen dow = 2
		tempfile loo
		save `loo'
	restore
	merge m:1 pid calendar_week using `loo', keep(1 2 3) nogen
	gen wkof_attend_j = (avg_wkattend_loo <= pct_j_attend) if avg_wkattend_loo!=.
	gen calwk_of_shock = stand_ph_calweek if wkof_attend_j==1
	bys pid : egen firstofshock_calwk_j = min(calwk_of_shock)
	drop calwk_of_shock
	gen wks_since_shock_j = stand_ph_calweek - firstofshock_calwk_j
	replace wks_since_shock_j = . if firstofshock_calwk_j == .
	gen firstwk_attend_j = (wks_since_shock_j == 0)
	gen post_attend_j    = (wks_since_shock_j > 0 & !mi(wks_since_shock_j))
end


program define prelim
	use "$main_data" , clear
	gen treat = treatment
	egen standid = group(stand)
	sort standid phase calendar_week date pid
	by standid phase calendar_week: gen stand_ph_calweek_id1 = 1 if _n==1
	egen temp2 = seq() if stand_ph_calweek_id1 == 1, by(standid phase)
	egen stand_ph_calweek = max(temp2), by(standid phase calendar_week)
	drop temp*

	* Number of unique control workers per stand (constant within stand)
	preserve
		keep if phase==2 & treat==0
		bys standid pid: keep if _n==1
		bys standid: gen n_controls_stand = _N
		bys standid: keep if _n==1
		keep standid n_controls_stand
		tempfile sizes
		save `sizes'
	restore
	merge m:1 standid using `sizes', nogen

	* Same for treated, for context
	preserve
		keep if phase==2 & treat==1
		bys standid pid: keep if _n==1
		bys standid: gen n_treated_stand = _N
		bys standid: keep if _n==1
		keep standid n_treated_stand
		tempfile szT
		save `szT'
	restore
	merge m:1 standid using `szT', nogen
end


************************************************************
* RUN 1 — V0 (predict for everyone)
************************************************************
	prelim
	di _n "[setup] stand sizes (controls and treated, phase 2):"
	preserve
		bys standid: keep if _n==1
		list standid n_controls_stand n_treated_stand, sepby(standid) noobs
	restore

	cap drop resid_day_attendph2
	reg attend bl_attend bl_earn miss_bl_earn i.standid##i.phase i.standid##i.treatment if phase<2
	predict resid_day_attendph2 if phase==2, residuals
	build_shock

	di _n "[v0] LOO SD by stand:"
	preserve
		keep if phase==2 & dow==2
		statsby sd_loo=r(sd) n=r(N), by(standid n_controls_stand n_treated_stand) clear : sum avg_wkattend_loo
		list, sepby(standid)
	restore

	preserve
		keep if phase==2 & dow==2
		keep pid calendar_week standid n_controls_stand n_treated_stand treat attend_nadj ///
		     avg_wkattend_loo firstwk_attend_j post_attend_j
		rename (avg_wkattend_loo firstwk_attend_j post_attend_j) (loo_v0 firstwk_v0 post_v0)
		tempfile v0
		save `v0'
	restore


************************************************************
* RUN 2 — V0c (predict only for treat==0)
************************************************************
	prelim
	cap drop resid_day_attendph2
	reg attend bl_attend bl_earn miss_bl_earn i.standid##i.phase i.standid##i.treatment if phase<2
	predict resid_day_attendph2 if phase==2 & treat == 0, residuals
	build_shock

	di _n "[v0c] LOO SD by stand:"
	preserve
		keep if phase==2 & dow==2
		statsby sd_loo=r(sd) n=r(N), by(standid n_controls_stand n_treated_stand) clear : sum avg_wkattend_loo
		list, sepby(standid)
	restore

	preserve
		keep if phase==2 & dow==2
		keep pid calendar_week standid n_controls_stand treat attend_nadj ///
		     avg_wkattend_loo firstwk_attend_j post_attend_j
		rename (avg_wkattend_loo firstwk_attend_j post_attend_j) (loo_v0c firstwk_v0c post_v0c)
		tempfile v0c
		save `v0c'
	restore


************************************************************
* COMPARE — stratify regressions by stand size
************************************************************
	use `v0', clear
	merge 1:1 pid calendar_week using `v0c', keep(3) nogen

	* Distribution of stand size
	di _n "[cmp] stand sizes (controls per stand):"
	preserve
		bys standid: keep if _n==1
		list standid n_controls_stand n_treated_stand, sepby(standid) noobs
		sum n_controls_stand, d
	restore

	* Median split by control count
	su n_controls_stand if treat==0, d
	scalar med_size = r(p50)
	di _n "[cmp] median controls per stand = " med_size

	gen byte large_stand = (n_controls_stand >= med_size)

	* Tabulate: how many shock-week tags by stand size, by spec
	di _n "[cmp] V0 shock-week share by stand size (controls only):"
	tab firstwk_v0 large_stand if treat==0, col
	di _n "[cmp] V0c shock-week share by stand size (controls only):"
	tab firstwk_v0c large_stand if treat==0, col

	* Regression: V0 vs V0c, on full sample, large stands, small stands
	* (data already filtered to phase==2 & dow==2 in tempfile)
	foreach spec in v0 v0c {
		foreach samp in all large small {
			local cond "treat==0"
			if "`samp'" == "all"   local more ""
			if "`samp'" == "large" local more "& large_stand==1"
			if "`samp'" == "small" local more "& large_stand==0"

			local lhs "attend_nadj"
			local rhs "firstwk_`spec' post_`spec' i.standid"

			di _n(2) "----- spec=`spec' sample=`samp' -----"
			reg `lhs' `rhs' if `cond' `more'
		}
	}

	* Same regressions but dropping each stand one at a time, V0c only,
	* to see which stand(s) drive the null
	di _n(2) "{hline 80}"
	di "[cmp] V0c shock coef leave-one-stand-out (controls-only OLS)"
	di "{hline 80}"
	levelsof standid if treat==0, local(stands)
	foreach s of local stands {
		qui reg attend_nadj firstwk_v0c post_v0c i.standid ///
			if treat==0 & standid != `s'
		local b = _b[firstwk_v0c]
		local se = _se[firstwk_v0c]
		local n = e(N)
		di "  drop standid==`s' (n_ctrl=" n_controls_stand[`s'] "):  coef = " %7.3f `b' "   SE = " %6.3f `se' "   N = " `n'
	}

	di _n(2) "[cmp] V0  shock coef leave-one-stand-out (controls-only OLS)"
	foreach s of local stands {
		qui reg attend_nadj firstwk_v0 post_v0 i.standid ///
			if treat==0 & standid != `s'
		local b = _b[firstwk_v0]
		local se = _se[firstwk_v0]
		local n = e(N)
		di "  drop standid==`s':  coef = " %7.3f `b' "   SE = " %6.3f `se' "   N = " `n'
	}

	* Also: per-stand correlation between V0 and V0c shock indicator
	di _n(2) "[cmp] per-stand pct of V0 shocks that survive in V0c (control workers):"
	bys standid: gen v0_then_v0c = (firstwk_v0==1 & firstwk_v0c==1) if treat==0 & firstwk_v0==1
	bys standid: egen pct_survive = mean(v0_then_v0c) if firstwk_v0==1 & treat==0
	bys standid: egen n_v0_shocks = total(firstwk_v0) if treat==0
	preserve
		keep if treat==0
		bys standid: keep if _n==1
		list standid n_controls_stand n_v0_shocks pct_survive, sepby(standid) noobs
	restore

	log close
