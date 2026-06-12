************************************************************
************************************************************
* 	Project:			Labor Discipline
* 	Purpose:			Create Weather Shock Indicators
* 	Author:				HW 
* 	Date created:		2025-Sep-02 (HW)
* 	Last modified:		2025-Sep-16 (HW)
************************************************************
************************************************************

******************
**# 1. Call Data
******************

	use "$temp/weather_day_stand_level.dta" , clear
	xtset stand date

	rename mean_apparent_temp 				mean_at
	rename mean_apparent_temp_recruit 		mean_at_rec
	rename max_apparent_temp 				max_at
	rename max_apparent_temp_recruit 		max_at_rec
	rename accu_prec 						accu_prec
	rename mean_prec 						mean_prec
	rename max_prec 						max_prec
	rename accu_prec_recruit 				accu_prec_rec
	rename mean_prec_recruit 				mean_prec_rec
	rename max_prec_recruit 				max_prec_rec
	rename max_weather_code 				max_wc
	rename max_weather_code_recruit 		max_wc_rec

	drop mean_prec max_prec mean_prec_rec max_prec_rec



	gen __COVER_____ = .
	gen __RAW_WEATHER_____ = .

	order __COVER_____
	order __RAW_WEATHER_____ , before (mean_at)


***************************************
**# 2. Generate Percentile Indicators
***************************************

	cap prog drop gen_percentile_indicator
	prog define gen_percentile_indicator

		syntax varname(numeric) , percentile(real) newvar(name)

		bys year: egen cutoff = pctile(`varlist'), p(`percentile')
		gen `newvar' = `varlist' > cutoff
		drop cutoff

		local vlab : var label `varlist'
		if "`vlab'" == "" local vlab "`varlist'"
		label var `newvar' "Indicator: `vlab' > `percentile'th percentile (within sample/group)"

	end



	* Temp Percentage
	gen_percentile_indicator mean_at_rec , percentile(85) newvar(mean_at_rec_85p)
	gen_percentile_indicator mean_at_rec , percentile(90) newvar(mean_at_rec_90p)
	gen_percentile_indicator mean_at_rec , percentile(95) newvar(mean_at_rec_95p)
	gen_percentile_indicator mean_at_rec , percentile(99) newvar(mean_at_rec_99p)

	gen_percentile_indicator max_at_rec , percentile(85) newvar(max_at_rec_85p)
	gen_percentile_indicator max_at_rec , percentile(90) newvar(max_at_rec_90p)
	gen_percentile_indicator max_at_rec , percentile(95) newvar(max_at_rec_95p)
	gen_percentile_indicator max_at_rec , percentile(99) newvar(max_at_rec_99p)

	gen_percentile_indicator mean_at , percentile(85) newvar(mean_at_85p)
	gen_percentile_indicator mean_at , percentile(90) newvar(mean_at_90p)
	gen_percentile_indicator mean_at , percentile(95) newvar(mean_at_95p)
	gen_percentile_indicator mean_at , percentile(99) newvar(mean_at_99p)

	gen_percentile_indicator max_at , percentile(85) newvar(max_at_85p)
	gen_percentile_indicator max_at , percentile(90) newvar(max_at_90p)
	gen_percentile_indicator max_at , percentile(95) newvar(max_at_95p)
	gen_percentile_indicator max_at , percentile(99) newvar(max_at_99p)


	lab var mean_at_rec_85p "Mean Appr Temp Recruit 85p"
	lab var mean_at_rec_90p "Mean Appr Temp Recruit 90p"
	lab var mean_at_rec_95p "Mean Appr Temp Recruit 95p"
	lab var mean_at_rec_99p "Mean Appr Temp Recruit 99p"
	lab var max_at_rec_85p "Max Appr Temp Recruit 85p"
	lab var max_at_rec_90p "Max Appr Temp Recruit 90p"
	lab var max_at_rec_95p "Max Appr Temp Recruit 95p"
	lab var max_at_rec_99p "Max Appr Temp Recruit 99p"

	lab var mean_at_85p "Mean Appr Temp 85p"
	lab var mean_at_90p "Mean Appr Temp 90p"
	lab var mean_at_95p "Mean Appr Temp 95p"
	lab var mean_at_99p "Mean Appr Temp 99p"
	lab var max_at_85p "Max Appr Temp 85p"
	lab var max_at_90p "Max Appr Temp 90p"
	lab var max_at_95p "Max Appr Temp 95p"
	lab var max_at_99p "Max Appr Temp 99p"


	* Precip Percentage
	gen_percentile_indicator accu_prec , percentile(85) newvar(accu_prec_85p)
	gen_percentile_indicator accu_prec , percentile(90) newvar(accu_prec_90p)
	gen_percentile_indicator accu_prec , percentile(95) newvar(accu_prec_95p)
	gen_percentile_indicator accu_prec , percentile(99) newvar(accu_prec_99p)

	gen_percentile_indicator accu_prec_rec , percentile(85) newvar(accu_prec_rec_85p)
	gen_percentile_indicator accu_prec_rec , percentile(90) newvar(accu_prec_rec_90p)
	gen_percentile_indicator accu_prec_rec , percentile(95) newvar(accu_prec_rec_95p)
	gen_percentile_indicator accu_prec_rec , percentile(99) newvar(accu_prec_rec_99p)

	lab var accu_prec_85p "Cumu Precip 85p"
	lab var accu_prec_90p "Cumu Precip 90p"
	lab var accu_prec_95p "Cumu Precip 95p"
	lab var accu_prec_99p "Cumu Precip 99p"
	lab var accu_prec_rec_85p "Cumu Precip Recruit 85p"
	lab var accu_prec_rec_90p "Cumu Precip Recruit 90p"
	lab var accu_prec_rec_95p "Cumu Precip Recruit 95p"
	lab var accu_prec_rec_99p "Cumu Precip Recruit 99p"


	gen __PERCENTILE_____ = .
	order __PERCENTILE_____ , after (max_wc_rec)
	



*********************************
**# 3. Generate Rain Indicators
*********************************

	* Gen indicator for raining 
	tab max_wc , gen(wc_)
	tab max_wc_rec , gen(wc_rec_)

	lab var wc_1 "Slight Drizzle"
	lab var wc_2 "Moderate Drizzle"
	lab var wc_3 "Heavy Drizzle"
	lab var wc_4 "Slight Rain"
	lab var wc_5 "Moderate Rain"
	lab var wc_6 "Heavy Rain"
	lab var wc_7 "No Rain"
	lab var wc_rec_1 "Slight Drizzle Recruit"
	lab var wc_rec_2 "Moderate Drizzle Recruit"
	lab var wc_rec_3 "Heavy Drizzle Recruit"
	lab var wc_rec_4 "Slight Rain Recruit"
	lab var wc_rec_5 "Moderate Rain Recruit"
	lab var wc_rec_6 "Heavy Rain Recruit"
	lab var wc_rec_7 "No Rain Recruit"


	egen wc_geq_1 = rowtotal(wc_1-wc_6)
	egen wc_geq_2 = rowtotal(wc_2-wc_6)
	egen wc_geq_3 = rowtotal(wc_3-wc_6)
	egen wc_geq_4 = rowtotal(wc_4-wc_6)
	egen wc_geq_5 = rowtotal(wc_5-wc_6)
	egen wc_geq_6 = rowtotal(wc_6-wc_6)
	lab var wc_geq_1 "At least Slight Drizzle"
	lab var wc_geq_2 "At least Moderate Drizzle"
	lab var wc_geq_3 "At least Heavy Drizzle"
	lab var wc_geq_4 "At least Slight Rain"
	lab var wc_geq_5 "At least Moderate Rain"
	lab var wc_geq_6 "At least Heavy Rain"

	egen wc_geq_1_rec = rowtotal(wc_rec_1-wc_rec_6)
	egen wc_geq_2_rec = rowtotal(wc_rec_2-wc_rec_6)
	egen wc_geq_3_rec = rowtotal(wc_rec_3-wc_rec_6)
	egen wc_geq_4_rec = rowtotal(wc_rec_4-wc_rec_6)
	egen wc_geq_5_rec = rowtotal(wc_rec_5-wc_rec_6)
	egen wc_geq_6_rec = rowtotal(wc_rec_6-wc_rec_6)
	lab var wc_geq_1_rec "At least Slight Drizzle Recruit"
	lab var wc_geq_2_rec "At least Moderate Drizzle Recruit"
	lab var wc_geq_3_rec "At least Heavy Drizzle Recruit"
	lab var wc_geq_4_rec "At least Slight Rain Recruit"
	lab var wc_geq_5_rec "At least Moderate Rain Recruit"
	lab var wc_geq_6_rec "At least Heavy Rain Recruit"

	gen __RAIN_CODE_____ = .
	order __RAIN_CODE_____ , after (accu_prec_rec_99p)




************************
**# 4. Rolling Average
************************

	xtset stand date
	foreach i of varlist mean_at mean_at_rec max_at max_at_rec accu_prec accu_prec_rec {
		tssmooth ma `i'_r3 = `i', window(2 1 0)
		tssmooth ma `i'_r4 = `i', window(3 1 0)
		tssmooth ma `i'_r5 = `i', window(4 1 0)
		tssmooth ma `i'_r6 = `i', window(5 1 0)
		tssmooth ma `i'_r7 = `i', window(6 1 0)
		lab var `i'_r3 "`i' 3-Day Rolling: `i'"
		lab var `i'_r4 "`i' 4-Day Rolling: `i'"
		lab var `i'_r5 "`i' 5-Day Rolling: `i'"
		lab var `i'_r6 "`i' 6-Day Rolling: `i'"
		lab var `i'_r7 "`i' 7-Day Rolling: `i'"

		gen_percentile_indicator `i'_r3 , percentile(85) newvar(`i'_r3_85p)
		gen_percentile_indicator `i'_r3 , percentile(90) newvar(`i'_r3_90p)
		gen_percentile_indicator `i'_r3 , percentile(95) newvar(`i'_r3_95p)
		gen_percentile_indicator `i'_r3 , percentile(99) newvar(`i'_r3_99p)
		gen_percentile_indicator `i'_r4 , percentile(85) newvar(`i'_r4_85p)
		gen_percentile_indicator `i'_r4 , percentile(90) newvar(`i'_r4_90p)
		gen_percentile_indicator `i'_r4 , percentile(95) newvar(`i'_r4_95p)
		gen_percentile_indicator `i'_r4 , percentile(99) newvar(`i'_r4_99p)
		gen_percentile_indicator `i'_r5 , percentile(85) newvar(`i'_r5_85p)
		gen_percentile_indicator `i'_r5 , percentile(90) newvar(`i'_r5_90p)
		gen_percentile_indicator `i'_r5 , percentile(95) newvar(`i'_r5_95p)
		gen_percentile_indicator `i'_r5 , percentile(99) newvar(`i'_r5_99p)
		gen_percentile_indicator `i'_r6 , percentile(85) newvar(`i'_r6_85p)
		gen_percentile_indicator `i'_r6 , percentile(90) newvar(`i'_r6_90p)
		gen_percentile_indicator `i'_r6 , percentile(95) newvar(`i'_r6_95p)
		gen_percentile_indicator `i'_r6 , percentile(99) newvar(`i'_r6_99p)
		gen_percentile_indicator `i'_r7 , percentile(85) newvar(`i'_r7_85p)
		gen_percentile_indicator `i'_r7 , percentile(90) newvar(`i'_r7_90p)
		gen_percentile_indicator `i'_r7 , percentile(95) newvar(`i'_r7_95p)
		gen_percentile_indicator `i'_r7 , percentile(99) newvar(`i'_r7_99p)

		lab var `i'_r3_85p "3-Day Rolling: `i' 85p"
		lab var `i'_r3_90p "3-Day Rolling: `i' 90p"
		lab var `i'_r3_95p "3-Day Rolling: `i' 95p"
		lab var `i'_r3_99p "3-Day Rolling: `i' 99p"
		lab var `i'_r4_85p "4-Day Rolling: `i' 85p"
		lab var `i'_r4_90p "4-Day Rolling: `i' 90p"
		lab var `i'_r4_95p "4-Day Rolling: `i' 95p"
		lab var `i'_r4_99p "4-Day Rolling: `i' 99p"
		lab var `i'_r5_85p "5-Day Rolling: `i' 85p"
		lab var `i'_r5_90p "5-Day Rolling: `i' 90p"
		lab var `i'_r5_95p "5-Day Rolling: `i' 95p"
		lab var `i'_r5_99p "5-Day Rolling: `i' 99p"
		lab var `i'_r6_85p "6-Day Rolling: `i' 85p"
		lab var `i'_r6_90p "6-Day Rolling: `i' 90p"
		lab var `i'_r6_95p "6-Day Rolling: `i' 95p"
		lab var `i'_r6_99p "6-Day Rolling: `i' 99p"
		lab var `i'_r7_85p "7-Day Rolling: `i' 85p"
		lab var `i'_r7_90p "7-Day Rolling: `i' 90p"
		lab var `i'_r7_95p "7-Day Rolling: `i' 95p"
		lab var `i'_r7_99p "7-Day Rolling: `i' 99p"
	}

	
	* Create Lagged Weather
	foreach i of varlist max_at max_at_rec accu_prec accu_prec_rec {
		foreach rolling_num in 3 4 5 6 7 {

			gen `i'_r`rolling_num'_l0 = `i'_r`rolling_num'
			lab var `i'_r`rolling_num'_l0 "`rolling_num'-Day Rolling: `i' (L0)"

			forvalues l = 1/7 {
				bys stand (date) : gen `i'_r`rolling_num'_l`l' = L`l'.`i'_r`rolling_num'
				lab var `i'_r`rolling_num'_l`l' "`rolling_num'-Day Rolling: `i' (L`l')"
			}


			foreach percentile in 85 90 95 99 {
				bys stand (date) : gen `i'_r`rolling_num'_`percentile'p_l0 = `i'_r`rolling_num'_`percentile'p
				lab var `i'_r`rolling_num'_`percentile'p_l0 "`rolling_num'-Day Rolling: `i' `percentile'p (L0)"

				forvalues l = 1/7 {
					bys stand (date) : gen `i'_r`rolling_num'_`percentile'p_l`l' = L`l'.`i'_r`rolling_num'_`percentile'p
					lab var `i'_r`rolling_num'_`percentile'p_l`l' "`rolling_num'-Day Rolling: `i' `percentile'p (L`l')"
				}
			}
		}
	}

	
	gen __ROLLING_AVERAGE_____ = .
	order __ROLLING_AVERAGE_____ , after (wc_geq_6_rec)


*************
**# 7. Save
*************

	save "$final/weather_shock_final_day_stand.dta", replace