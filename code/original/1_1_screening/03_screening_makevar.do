**************************************************
*Project: LD 
*Purpose: Create dataset of screening survey; create dataset with demographic variables
*Author : Luisa
*Last modified: 2024-03-25 (YS)
**************************************************
	
/*----------------------------------------------------*/
   /* [>   1.  Open data    <] */ 
/*----------------------------------------------------*/

		if "`c(username)'" == "hwang" {
			cd "/Users/hwang/Dropbox (Personal)/Labor Discipline"		
		}
		else {
			cd "/Users/${user}/Dropbox/Labor Discipline"	
		}	
		
	use "./07. Data/3. Main Study 3.0/02. Cleaning Data/01. Screening/02. Output/02_screening_cleaned.dta", clear
	
/*----------------------------------------------------*/
   /* [>   2.  Gen dummies    <] */ 
/*----------------------------------------------------*/

	* Place of birth
	gen ss_dem_born_chennai   = ss_dem_birthplace == 1 if !mi(ss_dem_birthplace)
	gen ss_dem_born_tamilnadu = ss_dem_birthplace == 2 if !mi(ss_dem_birthplace)
	
	* House ownership
	gen ss_dem_own_house      = ss_dem_ownhouse == 1 if !mi(ss_dem_ownhouse)
	gen ss_dem_rent_house     = ss_dem_ownhouse == 2 if !mi(ss_dem_ownhouse)
	
	* Education
	gen ss_dem_educ_numeracy = ss_dem_calculation == 1 if ss_dem_calculation !=999
	gen ss_dem_educ_literacy = ss_dem_read_tamil == 1  if ss_dem_read_tamil != 999
	gen ss_dem_educ_noschool = inlist(ss_dem_highest_edu, 1, 2) if !mi(ss_dem_highest_edu)
	
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
		drop ss_commute`i'
	}
	
	* Commuting time (in fractions of hours)
	gen ss_dem_commute_time = ss_timetakenhrs + ss_timetakenmins/60
	drop ss_timetakenhrs ss_timetakenmins
	
	*Commuting Costs
	bys rid: gen commute_bike_day=ss_dem_cost_bike/7 if ss_dem_cost_bike!=. 
	bys rid: gen ss_dem_overall_cost= commute_bike_day if commute_bike_day!=. & ss_commute=="4"
	bys rid: replace ss_dem_overall_cost= (commute_bike_day+ss_dem_commute_cost)/2 if commute_bike_day!=. & ss_commute!="4"
	drop commute_bike_day 
	
	* Professions
	split ss_profession_const
	local nvars = r(nvars)
	local professions_c foundation wall_build tile_work centering ///
					    concrete demolish loading stone_cut ///
					    welding painting carpenter
	foreach var in `professions_c' {
		gen ss_profess_c_`var' = 0 if !mi(ss_profession_const)
	}
	
	forv i = 1/`nvars' {
		destring ss_profession_const`i', replace
		replace ss_profess_c_foundation = 1 if ss_profession_const`i' == 3  //if !mi(ss_profession_const`i')
		replace ss_profess_c_wall_build = 1 if ss_profession_const`i' == 4  //if !mi(ss_profession_const`i')
		replace ss_profess_c_tile_work  = 1 if ss_profession_const`i' == 5  //if !mi(ss_profession_const`i')
		replace ss_profess_c_centering  = 1 if ss_profession_const`i' == 6  //if !mi(ss_profession_const`i')
		replace ss_profess_c_concrete   = 1 if ss_profession_const`i' == 7  //if !mi(ss_profession_const`i')
		replace ss_profess_c_demolish   = 1 if ss_profession_const`i' == 8  //if !mi(ss_profession_const`i')
		replace ss_profess_c_loading    = 1 if ss_profession_const`i' == 9  //if !mi(ss_profession_const`i')
		replace ss_profess_c_stone_cut  = 1 if ss_profession_const`i' == 10 //if !mi(ss_profession_const`i')
		replace ss_profess_c_welding    = 1 if ss_profession_const`i' == 11 //if !mi(ss_profession_const`i')
		replace ss_profess_c_painting   = 1 if ss_profession_const`i' == 12 //if !mi(ss_profession_const`i')
		replace ss_profess_c_carpenter  = 1 if ss_profession_const`i' == 13 //if !mi(ss_profession_const`i')
		drop ss_profession_const`i'
	}
	
	* Profession- Non-Construction 
	split ss_profession_nonconst
	local mvars = r(nvars)
	local lvars ss_profess_nc_agri ss_profess_nc_fisheries ss_profess_nc_electrician ///
	ss_profess_nc_plumber ss_profess_nc_scavenger ss_profess_nc_maid ss_profess_nc_cargo ///
	ss_profess_nc_loadman ss_profess_nc_rikshaw_pull ss_profess_nc_porter ss_profess_nc_tailor ///
	ss_profess_nc_textile ss_profess_nc_factory ss_profess_nc_technician ss_profess_nc_auto ss_profess_nc_car ///
	ss_profess_nc_cleaning ss_profess_nc_scaffolding ss_profess_nc_gardening
	foreach var in `lvars' {
		gen `var' = 0 if !mi(ss_profession_nonconst)
	}
	
	destring ss_profession_nonconst*, replace
	forv i = 1/`mvars' {
		replace ss_profess_nc_electrician = 1 if ss_profession_nonconst`i'==14
		replace ss_profess_nc_plumber = 1 if ss_profession_nonconst`i'==15
		replace ss_profess_nc_scavenger = 1 if  ss_profession_nonconst`i'==16
		replace ss_profess_nc_maid = 1 if  ss_profession_nonconst`i'==17
		replace ss_profess_nc_cargo = 1 if ss_profession_nonconst`i'==18
		replace ss_profess_nc_loadman = 1 if ss_profession_nonconst`i'==19
		replace ss_profess_nc_rikshaw_pull = 1 if ss_profession_nonconst`i'==20
		replace ss_profess_nc_porter = 1 if ss_profession_nonconst`i'==21
		replace ss_profess_nc_tailor = 1 if ss_profession_nonconst`i'==22
		replace ss_profess_nc_textile = 1 if ss_profession_nonconst`i'==23
		replace ss_profess_nc_factory = 1 if ss_profession_nonconst`i'==24
		replace ss_profess_nc_technician = 1 if ss_profession_nonconst`i'==25
		replace ss_profess_nc_auto = 1 if ss_profession_nonconst`i'==26 
		replace ss_profess_nc_car = 1 if ss_profession_nonconst`i'==27
		replace ss_profess_nc_cleaning = 1 if ss_profession_nonconst`i'==28
		replace ss_profess_nc_scaffolding = 1 if ss_profession_nonconst`i'==29
		replace ss_profess_nc_gardening = 1 if ss_profession_nonconst`i'==30
		replace ss_profess_nc_agri = 1 if ss_profession_nonconst`i'==1
		replace ss_profess_nc_fisheries = 1 if ss_profession_nonconst`i'==2
		drop ss_profession_nonconst`i'
	}
		
	*ss_type
	split ss_type
	local pvars = r(nvars)
	local ovars ss_outsidest_agri ss_outsidest_fisheries ss_outsidest_wall_build ss_outsidest_electrician ///
	ss_outsidest_plumber ss_outsidest_scavenger ss_outsidest_maid ss_outsidest_cargo ///
	ss_outsidest_loadman ss_outsidest_rikshaw_pull ss_outsidest_porter ss_outsidest_tailor ///
	ss_outsidest_textile ss_outsidest_factory ss_outsidest_technician ss_outsidest_auto ss_outsidest_car ///
	ss_outsidest_cleaning ss_outsidest_scaffolding ss_outsidest_gardening ///
	ss_outsidest_foundation ss_outsidest_tile_work  ss_outsidest_centering  ss_outsidest_concrete ///
	ss_outsidest_demolish  ss_outsidest_loading  ss_outsidest_stone_cut  ss_outsidest_welder  ss_outsidest_painting  ss_outsidest_carpenter
	foreach var in `ovars' {
		gen `var' = 0 if !mi(ss_type)
	}
	destring ss_type*, replace
	forv i = 1/`pvars' {
		replace ss_outsidest_agri        = 1 if ss_type`i'==1 
		replace ss_outsidest_fisheries   = 1 if ss_type`i'==2
		replace ss_outsidest_foundation  = 1 if ss_type`i'==3
		replace ss_outsidest_wall_build  = 1 if ss_type`i'==4
		replace ss_outsidest_tile_work   = 1 if ss_type`i'==5
		replace ss_outsidest_centering   = 1 if ss_type`i'==6
		replace ss_outsidest_concrete    = 1 if ss_type`i'==7
		replace ss_outsidest_demolish    = 1 if ss_type`i'==8
		replace ss_outsidest_loading     = 1 if ss_type`i'==9
		replace ss_outsidest_stone_cut   = 1 if ss_type`i'==10
		replace ss_outsidest_welder      = 1 if ss_type`i'==11
		replace ss_outsidest_painting    = 1 if ss_type`i'==12
		replace ss_outsidest_carpenter   = 1 if ss_type`i'==13
		replace ss_outsidest_electrician = 1 if ss_type`i'==14 
		replace ss_outsidest_plumber     = 1 if ss_type`i'==15 
		replace ss_outsidest_scavenger   = 1 if ss_type`i'==16
		replace ss_outsidest_maid        = 1 if ss_type`i'==17
		replace ss_outsidest_cargo       = 1 if ss_type`i'==18 
		replace ss_outsidest_loadman     = 1 if ss_type`i'==19
		replace ss_outsidest_rikshaw_pull = 1 if ss_type`i'==20 
		replace ss_outsidest_porter      = 1 if ss_type`i'==21 
		replace ss_outsidest_tailor      = 1 if ss_type`i'==22 
		replace ss_outsidest_textile     = 1 if ss_type`i'==23 
		replace ss_outsidest_factory     = 1 if ss_type`i'==24 
		replace ss_outsidest_technician  = 1 if ss_type`i'==25 
		replace ss_outsidest_auto        = 1 if ss_type`i'==26 
		replace ss_outsidest_car         = 1 if ss_type`i'==27
		replace ss_outsidest_cleaning    = 1 if ss_type`i'==28 
		replace ss_outsidest_scaffolding = 1 if ss_type`i'==29
		replace ss_outsidest_gardening   = 1 if ss_type`i'==30 
		drop ss_type`i'
	}

	* Alcohol amount
	gen ss_dem_alcohol_units = ss_cuttingalcohol*0.5 + ss_quarteralcohol + ///
	ss_halfalcohol*2 + ss_fullalcohol * 4 + ss_beer 

/*----------------------------------------------------*/
   /* [>   3.  Label variables    <] */ 
/*----------------------------------------------------*/

	* Place of birth
	label var ss_dem_born_chennai   "Born in Chennai"
	label var ss_dem_born_tamilnadu "Born in Tamil Nadu, but not Chennai"
	
	* House ownership
	label var ss_dem_own_house  "Owns house in Chennai"   
	label var ss_dem_rent_house "Rents house in Chennai"
	
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
	
	* Profession (construction)
	local professions_c foundation centering concrete demolish loading welding painting carpenter tile_work wall_build stone_cut
	foreach job in `professions_c' {
		label var ss_profess_c_`job'  "Works in `job'"
	}
	
	* Profession (non-construction)
	local professions_nc agri fisheries electrician plumber scavenger maid cargo loadman rikshaw_pull porter tailor textile factory technician auto car cleaning scaffolding gardening
	foreach job1 in `professions_nc' {
		label var ss_profess_nc_`job1'  "Works in `job1'"
	}
	
	*Type of jobs outside stand
	local outside foundation centering concrete demolish loading welder painting carpenter tile_work wall_build stone_cut agri fisheries electrician plumber scavenger maid cargo loadman rikshaw_pull porter tailor textile factory technician auto car cleaning scaffolding gardening
	foreach job2 in `outside' {
		label var ss_outsidest_`job2'  "Works in `job2'"
	}
	
	* Alcohol amount
	label var ss_dem_alcohol_units "Alcohol units/day consumed when drinking"
	rename ss_daysalcohol ss_dem_daysalcohol
	rename ss_morningalcohol ss_dem_morningalcohol

	drop ss_commute  ss_profession_const ss_type  ss_cuttingalcohol ss_quarteralcohol ss_halfalcohol ss_fullalcohol ss_beer formdef_version key submissiondate starttime endtime filename deviceid subscriberid devicephonenum username duration caseid	
	
/*----------------------------------------------------*/
   /* [>   4.  Save data    <] */ 
/*----------------------------------------------------*/

	saveold "./07. Data/3. Main Study 3.0/02. Cleaning Data/01. Screening/02. Output/04_screening_makevar.dta", replace	
	* Save demographic variables for eligible participants 
	keep if eligible == 1
	rename ss_morestand ss_dem_morestand 
	rename ss_timevisited ss_dem_timvisited
	keep rid stand ss_dem_* /*launch_set*/ // Note: you can increase the set of vars for demographics by modifying var name and adding suffix ss_dem
	saveold "./07. Data/3. Main Study 3.0/02. Cleaning Data/01. Screening/02. Output/05_screening_dem_vars.dta", replace
