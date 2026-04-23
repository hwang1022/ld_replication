**************************************************
*Project: LD 
*Purpose: Create dataset of screening survey; create dataset with demographic variables
*Author : Luisa
*Last last modified: 2024-03-25 (YS)
*Last modified: 2024-10-18 (HW)
**************************************************
	
/*----------------------------------------------------*/
   /* [>   1.  Open data    <] */ 
/*----------------------------------------------------*/

	use "$temp/02_screening_cleaned.dta", clear
	isid rid
	
/*----------------------------------------------------*/
   /* [>   2.  Gen dummies    <] */ 
/*----------------------------------------------------*/

	local dem_vars_to_keep ""


	* Education
	gen ss_dem_educ_numeracy = ss_dem_calculation == 1 			if !mi(ss_dem_calculation) 	& ss_dem_calculation 	!=999
	gen ss_dem_educ_literacy = ss_dem_read_tamil == 1  			if !mi(ss_dem_read_tamil) 	& ss_dem_read_tamil 	!=999
	gen ss_dem_educ_noschool = inlist(ss_dem_highest_edu, 1, 2) if !mi(ss_dem_highest_edu) 	& ss_dem_highest_edu	!=999
	local dem_vars_to_keep "`dem_vars_to_keep' ss_dem_educ*"
	
	* Commuting mode of transport
	split(ss_commute)
	local pvars = r(nvars)

	local transport "bus auto train moto bike foot"
	foreach var in `transport' {
		gen ss_dem_commute_`var' = 0 if !mi(ss_commute)
	}
	
	forv i = 1/`pvars' {
		destring ss_commute`i', replace
		replace ss_dem_commute_bus   = 1 if ss_commute`i' == 1 
		replace ss_dem_commute_auto  = 1 if ss_commute`i' == 2  
		replace ss_dem_commute_train = 1 if ss_commute`i' == 3 
		replace ss_dem_commute_moto  = 1 if ss_commute`i' == 4 
		replace ss_dem_commute_bike  = 1 if ss_commute`i' == 5 
		replace ss_dem_commute_foot  = 1 if ss_commute`i' == 6 
		replace ss_dem_commute_auto  = 1 if ss_commute`i' == 7 // HW: Oct 17 2024 Shared auto also considered auto
		drop ss_commute`i'
	}
	
	* Commuting time (in fractions of hours)
	gen ss_dem_commute_time = ss_timetakenhrs + ss_timetakenmins/60
	local dem_vars_to_keep "`dem_vars_to_keep' ss_dem_commute*"
	
	* Commuting Costs
	bys rid: gen commute_bike_day=ss_dem_cost_bike/7 if ss_dem_cost_bike!=. 
	bys rid: gen ss_dem_overall_cost= commute_bike_day if commute_bike_day!=. & ss_commute=="4"
	bys rid: replace ss_dem_overall_cost= (commute_bike_day+ss_dem_commute_cost)/2 if commute_bike_day!=. & ss_commute!="4"
	drop commute_bike_day 
	local dem_vars_to_keep "`dem_vars_to_keep' ss_dem_overall_cost"
	

/*----------------------------------------------------*/
   /* [>   3.  Label variables    <] */ 
/*----------------------------------------------------*/

	* Education
	label var ss_dem_educ_numeracy "Can correctly multiply"
	label var ss_dem_educ_literacy "Can read tamil newspaper"
	label var ss_dem_educ_noschool "Never went to school"
	
	* Mode of commuting
	label var ss_dem_commute_foot       "Commutes to stand on foot"
	local transport "bus auto train moto bike"
	foreach mode in `transport' {
		label var ss_dem_commute_`mode' "Cmmutes to stand by `mode'"
	}
	
	* Commuting time
	label var ss_dem_commute_time     	"Commuting time to stand (in fr. of hour)"
	
	*Commute cost
	label var ss_dem_overall_cost       "Commuting cost (overall)"
	
	
/*----------------------------------------------------*/
   /* [>   4.  Save data    <] */ 
/*----------------------------------------------------*/


	save "$temp/04_screening_makevar.dta", replace
	
	* Save demographic variables for eligible participants 
	keep if eligible == 1
	keep rid ss_dem*
	save "$temp/05_screening_dem_vars.dta", replace
