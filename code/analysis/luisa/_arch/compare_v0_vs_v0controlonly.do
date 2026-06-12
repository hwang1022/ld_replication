************************************************************
* Compare V0 (predict residuals for everyone) vs.
* V0-control-only (same model, but predict only for treat==0)
* All other code unchanged.
************************************************************

	clear all
	set more off
	cap log close
	set linesize 180

* ---- Minimal globals (mirrors 0.master.do) ---------------
	global db_dir          "~/Dropbox"
	global ld_dir          "$db_dir/Labor Discipline"
	global replication_dir "$ld_dir/07. Data/3. Main Study 3.0/ld_replication"
	global final           "$replication_dir/data/final"
	global main_data       "$final/final_data_prioritize_date.dta"
	global out_dir         "$replication_dir/code/analysis/luisa"

* Just in case some packages are missing, this is a no-op if installed
	cap which reghdfe
	cap which distplot

	log using "$out_dir/compare_v0_vs_v0controlonly.log", replace text

************************************************************
* PROGRAM: build_shock — exact copy of LC's pipeline.
*  Input  : data already loaded with `resid_day_attendph2` defined for the
*           prediction sample of interest (everyone in v0; only treat==0 in v0c).
*  Output : same shock vars LC builds (firstwk_attend_j, post_attend_j, etc.)
************************************************************
program drop _all
program define build_shock
	* Aggregate daily residuals to worker-week level
	preserve
		keep if phase == 2
		set type double
		collapse (sum) w_sum = resid_day_attendph2 ///
		         (count) w_n = resid_day_attendph2 ///
		         (first) standid, by(calendar_week pid treat)

		bys standid calendar_week: egen count_pid = count(pid) if treat == 0
		bysort standid calendar_week: egen sw_sum = total(w_sum)
		bysort standid calendar_week: egen sw_n   = total(w_n)
		sort pid calendar_week
		gen double avg_wkattend_loo = (sw_sum - w_sum) / (sw_n - w_n)

		bys pid calendar_week: keep if _n == 1
		sum avg_wkattend_loo, d
		scalar pct_j_attend = r(p25)

		keep pid calendar_week avg_wkattend_loo
		gen dow = 2
		tempfile loo_worker_week
		save `loo_worker_week'
	restore

	merge m:1 pid calendar_week using `loo_worker_week', keep(1 2 3) nogen

	gen wkof_attend_j = (avg_wkattend_loo <= pct_j_attend) if avg_wkattend_loo!=.

	gen calwk_of_shock = stand_ph_calweek if wkof_attend_j==1
	bys pid : egen firstofshock_calwk_j = min(calwk_of_shock)
	drop calwk_of_shock
	gen calwk_of_shock = calendar_week if wkof_attend_j==1
	bys pid : egen firstofshock1_calwk_j = min(calwk_of_shock)
	drop calwk_of_shock

	gen wks_since_shock_j = stand_ph_calweek - firstofshock_calwk_j
	replace wks_since_shock_j = . if firstofshock_calwk_j == .

	gen firstwk_attend_j     = (wks_since_shock_j == 0)
	gen post_attend_j        = (wks_since_shock_j > 0 & !mi(wks_since_shock_j))
	gen treatXfirstwk_attend = treat * firstwk_attend_j
	gen treatXpost_attend    = treat * post_attend_j
end


************************************************************
* SHARED PRELIM (lines 19-42 of LC's script)
************************************************************
program define prelim
	use "$main_data" , clear
	gen treat = treatment
	egen standid = group(stand)
	sort standid phase calendar_week date pid
	by standid phase calendar_week: gen stand_ph_calweek_id1 = 1 if _n==1
	egen temp2 = seq() if stand_ph_calweek_id1 == 1, by(standid phase)
	egen stand_ph_calweek = max(temp2), by(standid phase calendar_week)
	drop temp*
	egen temp1 = mean(week_in) if dow==1, by(pid phase)
	egen temp2 = max(temp1), by(pid phase)
	gen week_in_dm = week_in - temp2
	drop temp*
end

************************************************************
* RUN 1 — V0 (current): predict for everyone
************************************************************
	di _n(2) "{hline 80}"
	di "RUN 1: V0 -- predict residuals for ALL workers in phase 2"
	di "{hline 80}"

	prelim
	cap drop resid_day_attendph2
	reg attend bl_attend bl_earn miss_bl_earn i.standid##i.phase i.standid##i.treatment if phase<2
	predict resid_day_attendph2 if phase==2, residuals

	* Diagnostics on residuals
	di _n "[v0] resid summary by treat (phase 2):"
	tabstat resid_day_attendph2 if phase==2, by(treat) stats(n mean sd min p25 p50 p75 max)

	build_shock

	di _n "[v0] LOO mean summary by treat (one obs per pid-calweek, phase 2 dow==2):"
	tabstat avg_wkattend_loo if phase==2 & dow==2, by(treat) stats(n mean sd min p25 p50 p75 max)
	di _n "[v0] 25th pct cutoff (computed across pooled distribution): " pct_j_attend

	di _n "[v0] share tagged as shock-week, by treat:"
	tab firstwk_attend_j treat if phase==2 & dow==2, col

	di _n "[v0] N controls who ever experience a shock:"
	count if phase==2 & dow==2 & treat==0 & !mi(firstofshock_calwk_j)
	count if phase==2 & dow==2 & treat==0

	di _n "[v0] KEY REGRESSION (controls only, simple OLS):"
	di "    reg attend_nadj firstwk_attend_j post_attend_j i.standid if phase==2 & dow==2 & treat==0"
	reg attend_nadj firstwk_attend_j post_attend_j i.standid if phase==2 & dow==2 & treat==0

	di _n "[v0] KEY REGRESSION (full DiD with treat interaction):"
	reghdfe attend_nadj firstwk_attend_j##treat post_attend_j##treat if phase==2 & dow==2, absorb(standid)

	* Save residuals + key vars for later side-by-side merge
	preserve
		keep if phase==2 & dow==2
		keep pid calendar_week stand_ph_calweek treat standid attend_nadj ///
		     resid_day_attendph2 avg_wkattend_loo wkof_attend_j ///
		     firstwk_attend_j post_attend_j firstofshock_calwk_j wks_since_shock_j
		rename (resid_day_attendph2 avg_wkattend_loo wkof_attend_j ///
		        firstwk_attend_j post_attend_j firstofshock_calwk_j wks_since_shock_j) ///
		       (resid_v0 loo_v0 wkofshock_v0 firstwk_v0 post_v0 firstshockcalwk_v0 wks_since_v0)
		tempfile v0_panel
		save `v0_panel'
	restore


************************************************************
* RUN 2 — V0-control-only: same model, predict only for treat==0
************************************************************
	di _n(2) "{hline 80}"
	di "RUN 2: V0c -- SAME model, predict residuals ONLY for treat==0 in phase 2"
	di "{hline 80}"

	prelim
	cap drop resid_day_attendph2
	reg attend bl_attend bl_earn miss_bl_earn i.standid##i.phase i.standid##i.treatment if phase<2
	predict resid_day_attendph2 if phase==2 & treat == 0, residuals

	di _n "[v0c] resid summary by treat (phase 2):"
	tabstat resid_day_attendph2 if phase==2, by(treat) stats(n mean sd min p25 p50 p75 max)

	build_shock

	di _n "[v0c] LOO mean summary by treat (one obs per pid-calweek, phase 2 dow==2):"
	tabstat avg_wkattend_loo if phase==2 & dow==2, by(treat) stats(n mean sd min p25 p50 p75 max)
	di _n "[v0c] 25th pct cutoff: " pct_j_attend

	di _n "[v0c] share tagged as shock-week, by treat:"
	tab firstwk_attend_j treat if phase==2 & dow==2, col

	di _n "[v0c] N controls who ever experience a shock:"
	count if phase==2 & dow==2 & treat==0 & !mi(firstofshock_calwk_j)
	count if phase==2 & dow==2 & treat==0

	di _n "[v0c] KEY REGRESSION (controls only, simple OLS):"
	di "    reg attend_nadj firstwk_attend_j post_attend_j i.standid if phase==2 & dow==2 & treat==0"
	reg attend_nadj firstwk_attend_j post_attend_j i.standid if phase==2 & dow==2 & treat==0

	di _n "[v0c] KEY REGRESSION (full DiD with treat interaction):"
	reghdfe attend_nadj firstwk_attend_j##treat post_attend_j##treat if phase==2 & dow==2, absorb(standid)

	preserve
		keep if phase==2 & dow==2
		keep pid calendar_week stand_ph_calweek treat standid attend_nadj ///
		     resid_day_attendph2 avg_wkattend_loo wkof_attend_j ///
		     firstwk_attend_j post_attend_j firstofshock_calwk_j wks_since_shock_j
		rename (resid_day_attendph2 avg_wkattend_loo wkof_attend_j ///
		        firstwk_attend_j post_attend_j firstofshock_calwk_j wks_since_shock_j) ///
		       (resid_v0c loo_v0c wkofshock_v0c firstwk_v0c post_v0c firstshockcalwk_v0c wks_since_v0c)
		tempfile v0c_panel
		save `v0c_panel'
	restore


************************************************************
* RUN 3 — Side-by-side comparison of the two shock indicators
************************************************************
	di _n(2) "{hline 80}"
	di "RUN 3: Side-by-side comparison"
	di "{hline 80}"

	use `v0_panel', clear
	merge 1:1 pid calendar_week using `v0c_panel', keep(3) nogen

	di _n "[cmp] correlation of LOO means (controls only):"
	corr loo_v0 loo_v0c if treat==0

	di _n "[cmp] cross-tab of shock-week tag (controls only):"
	tab firstwk_v0 firstwk_v0c if treat==0

	di _n "[cmp] cross-tab of post-shock indicator (controls only):"
	tab post_v0 post_v0c if treat==0

	di _n "[cmp] cross-tab of FIRST shock calendar week (controls only):"
	tab firstshockcalwk_v0 firstshockcalwk_v0c if treat==0, m

	di _n "[cmp] mean attend_nadj by shock indicator (control workers):"
	tabstat attend_nadj if treat==0, by(firstwk_v0)  stats(n mean sd)
	tabstat attend_nadj if treat==0, by(firstwk_v0c) stats(n mean sd)

	log close
