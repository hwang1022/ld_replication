******************************************
******************************************
**										**
**		LABOR DISCIPLINE PROJECT		**
**				   						**
**  			MACROS DOFILE  			**
**				   						**
**				   						**
**	Created by HW Jul 18 2024 			**
**	Last Edited by HW Aug 16 2024		**
**				   						**
******************************************
******************************************

	* This dofile defines auxiliary functions that will be used by the main program. 
	* The functions were written by Luisa and previous RA's
	
*******************************************
**# Auxiliary Functions for Data Cleaning 
*******************************************
	
	* Purpose: auxiliary function saving input in file called 'input.tex'
	* Author: Unknown
	* Last modified: Unknown
	cap program drop save_input 
	program define save_input 

		syntax [anything], number(str) filename(str) [format(str)]


		if "`format'" != "" local number_formatted = string(`number', "`format'")
		else local number_formatted "`number'"

		/*
		if `number_formatted' >= 0 & `number_formatted' < 1 {
			local number_formatted = subinstr("`number_formatted'", "0.", ".", .)
		}
		if `number_formatted' <= 0 & `number_formatted' > -1 {
			local number_formatted = subinstr("`number_formatted'", "-0.", "-.", .)
		}
		*/

		file open newfile using "$stats/`filename'.tex", write replace
		file write newfile "`number_formatted'%"
		file close newfile
	end
	

	* Purpose: Auxiliary function to install any uninstalled ssc packages before using them
	* Author: Unknown
	* Last modified: Unknown
	cap program drop verify_package 
	program verify_package
		args package
		capture which `package'
		if _rc ssc install `package'
		if !_rc di "Package `package' already installed in the system. Code can proceed."
	end

	
	
	* Purpose: create a local with max number of days of recall
	* Author: Luisa
	* Last modified: 09-07-2021 - LC
	cap program drop 	defineRecallDays
	program define 		defineRecallDays, rclass
		syntax, varname(str)
		
		local i = 1	
		local rc = 0
		while `rc' != 1 {
			capture confirm variable `varname'_`i'
			if !_rc {
				* if this variable does not exist 
				local ++i 
					* this increases the local i by value 1
				local rc = 0
			}
			else {
				local d = `i' - 1
				return local max_days_recall = `d'
				disp(`d')
				local rc = 1
			}
		}
	end
	
	
	
	* Purpose: Unknown
	* Author: Luisa
	* Last modified: Unknown
	cap program drop	makeDates
	program define 		makeDates, rclass

	syntax, launchDate(str)
	return clear
	tempvar date
	
	local launchDate_dow = dow(`launchDate')
	assert `launchDate_dow' == 1
	
	local date = `launchDate'

	local baseline     = `date' + 3
	local baseline_end = `date' + 15
	local announcement = `date' + 16
	local announcement_end_b1  = `date' + 20
	local announcement_end_b2  = `date' + 22
	local announcement_end_b3  = `date' + 22
	
	// LC 29-04-2024: these dates are now overwritten in the master_dates.do
	// to reflect actual timeline
	local phase1       = `date' + 21 
	local phase1_end   = `date' + 69
	local phase2  	   = `date' + 70
	local phase2_end   = `date' + 119


	* Save in r(.)
	return local baseline     = `baseline'
	return local baseline_end = `baseline_end'
	return local announcement = `announcement'
	return local announcement_end_b1 = `announcement_end_b1'
	return local announcement_end_b2 = `announcement_end_b2'
	return local announcement_end_b3 = `announcement_end_b3'
	return local phase1       = `phase1'
	return local phase1_end   = `phase1_end'
	return local phase2       = `phase2'
	return local phase2_end   = `phase2_end'
		
	
	end
	
	
	* Purpose: Generate holiday list to record days when staff was not in the fieldwe
	* Author: Luisa
	* Last modified: Luisa 4/11/26	
	cap program drop	makeHolidays
	program define 		makeHolidays, rclass
	return clear
	preserve
        import excel "$raw/MLD_Stand_Tracker_original.xlsx", ///
		sheet("Holidays") firstrow case(lower) clear
		* <FIXME> LC 4/21/26 moved this before levelsof command, otherwise previously not excluded.
		drop if date == td(08nov2022) // J-pal Holiday but not local holiday. Keep data on that day
		levelsof date, local(holidays)
		return local holiday_list = "`holidays'"
	restore
	
	end
	
	
	* Purpose: Unknown
	* Author: Luisa
	* Last modified: Unknown	
	cap program drop	makeLaunchList	
	program define 		makeLaunchList, rclass

		syntax, [launchSet(str)]
		
		local SetNum = wordcount("`launchSet'")
		
		local LaunchSetList
		
		forval v = 1/`SetNum' {
			if `v' == 1 {
				local thisVar : word 1 of `launchSet'
				local LaunchSetList " `thisVar' "
			}
			else {
				local thisVar : word `v' of `launchSet'		
				local LaunchSetList " `LaunchSetList' , `thisVar' "
			}
		}
		return local List = "`LaunchSetList'"

	end	
	
	
	
	
	
	
	
	* Purpose: Unknown
	* Author: Luisa
	* Last modified: Unknown	
	cap program drop	standLabeling		
	program define 		standLabeling
	cap label drop stand_lab
    label define stand_lab   	1 "1. Adambakam" 2 "2. Avadi" 3 "3. Aynavaram" 4 "4. Mandaveli"	5 "5. MKB" 6 "6. Korattur" 7 "7. MMDA" ///
								8 "8. Porur" 9 "9. TVK Nagar" 10 "10. Poonamallee"	11 "11. Keelkattalai" 12 "12. Krishna Nagar" ///
								13 "13. Thiruvanmiyur" 15 "15. Velachery" 16 "16. Padappai" 17 "17. Guduvanchery" 18 "18. Pammal" 20 "20. Iyapandagal"
    qui label list stand_lab
	forv i = 1/`r(max)' {
	   global stand_lab_`i': label stand_lab `i'
	}
	
	end
	standLabeling
	
	
	
	
	
	* Purpose: Unknown
	* Author: Unknown
	* Last modified: Unknown
	cap program drop	setDates		
	program define 		setDates
	
	tempvar var 
	gen `var' = 1
	
	global launchDateSet1  = td(28feb2022)
	global launchDateSet2  = td(07mar2022)
	global launchDateSet3  = td(14mar2022)
	global launchDateSet4  = td(28mar2022)
	global launchDateSet5  = td(04apr2022)
	global launchDateSet6  = td(09may2022)
	global launchDateSet7  = td(16may2022)
	global launchDateSet8  = td(23may2022)
	global launchDateSet9  = td(30may2022)
	global launchDateSet10 = td(06jun2022)
	global launchDateSet11 = td(13jun2022)
	global launchDateSet12 = td(20jun2022)
	global launchDateSet13 = td(27jun2022)
	global launchDateSet14 = td(04jul2022)
	global launchDateSet15 = td(11jul2022)
	global launchDateSet16 = td(18jul2022)
	global launchDateSet17 = td(27jun2022)
	global launchDateSet18 = td(04jul2022)
	global launchDateSet19 = td(04jul2022)
	global launchDateSet20 = td(11jul2022)


	* Number of total sets of stands launched
	global numSetsTotal = 20

	forv i = 1/$numSetsTotal {

		makeDates, launchDate("${launchDateSet`i'}")
		
		global baselineStartSet`i' = r(baseline)
		global baselineEndSet`i'   = r(baseline_end)
		
		global phase1StartSet`i'   = r(phase1)
		global phase1EndSet`i'     = r(phase1_end)

		global phase2StartSet`i'   = r(phase2)
		global phase2EndSet`i'     = r(phase2_end)
		
		global announcementStartSet`i'  = r(announcement)
		global announcementEndSet`i'_b1 = r(announcement_end_b1)
		
		global announcementStartSet`i'  = r(announcement)
		global announcementEndSet`i'_b2 = r(announcement_end_b2)

		global announcementStartSet`i'  = r(announcement)
		global announcementEndSet`i'_b3 = r(announcement_end_b3)
	}

	*Launchset 1
	global phase1StartSet1       = td(21mar2022)
	global phase1EndSet1         = td(08may2022)
	global phase2StartSet1       = td(09may2022)
	global phase2EndSet1      	 = td(03jul2022)

	*Launchset 2
	global phase1StartSet2       = td(28mar2022)
	global phase1EndSet2         = td(15may2022)
	global phase2StartSet2       = td(16may2022)
	global phase2EndSet2      	 = td(10jul2022)

	*Launchset 3
	global phase1StartSet3       = td(04apr2022)
	global phase1EndSet3         = td(22may2022)
	global phase2StartSet3       = td(23may2022)
	global phase2EndSet3      	 = td(17jul2022)

	*Launchset 4
	// holiday, announcement extended
	global announcementStartSet4 = td(18apr2022)
	global announcementEndSet4   = td(24apr2022)
	global phase1StartSet4       = td(25apr2022)
	global phase1EndSet4         = td(12jun2022)
	global phase2StartSet4       = td(13jun2022)
	global phase2EndSet4         = td(07aug2022)

	*Launchset 5
	// holiday, baseline extended
	global baselineEndSet5        = td(22apr2022)
	global announcementStartSet5  = td(25apr2022)
	global announcementEndSet5    = td(1may2022)
	global phase1StartSet5        = td(02may2022)
	global phase1EndSet5          = td(19jun2022)
	global phase2StartSet5        = td(20jun2022)
	global phase2EndSet5          = td(14aug2022)
	
	*Launchset 10
	// phase 1 extended by 1 week
	global phase1StartSet10		= td(27jun2022)
	global phase1EndSet10       = td(11sep2022)
	global phase2StartSet10     = td(12sep2022)
	global phase2EndSet10     	= td(06nov2022)
	
	*Launchset 11
	global phase1StartSet11     = td(04jul2022)
	global phase1EndSet11       = td(18sep2022)
	global phase2StartSet11     = td(19sep2022)
	global phase2EndSet11    	= td(13nov2022)
	
	*Launchset 12
	* 11 july
	global phase1StartSet12     = td(11jul2022) // HW added Nov 2024 following [PRLS] Study Timeline Spreadsheet
	global phase1EndSet12       = td(25sep2022)
	global phase2StartSet12     = td(26sep2022)
	global phase2EndSet12     	= td(20nov2022)
	
	*Launchset 13
	global phase1StartSet13     = td(18Jul2022)
	global phase1EndSet13       = td(04sept2022)
	global phase2StartSet13     = td(05sept2022)
	global phase2EndSet13     	= td(30oct2022)
	
	*Launchset 14
	global phase1StartSet14     = td(25jul2022)
	global phase1EndSet14       = td(11sep2022)
	global phase2StartSet14     = td(12sep2022)
	global phase2EndSet14     	= td(6nov2022)
	
	*Launchset 15 
	// we added one day of screening
	global baselineStartSet15 	= td(15jul2022)
	* 1 aug
	global baselineEndSet15     = td(27jul2022)	// HW added Nov 2024 following [PRLS] Study Timeline Spreadsheet
	global phase1StartSet15     = td(1aug2022)
	global phase1EndSet15       = td(18sep2022)
	global phase2StartSet15     = td(19sep2022)
	global phase2EndSet15     	= td(13nov2022)
	
	*Launchset 16
	global phase1StartSet16     = td(08aug2022) //monday
	global phase1EndSet16       = td(25sep2022) //sunday
	global phase2StartSet16     = td(26sep2022) //monday
	global phase2EndSet16     	= td(20nov2022) //sunday

	*Launchset 17
	// NOTE: before stand Phase 1 extension, this used to be launchset 13
	global phase1StartSet17     = td(18Jul2022) //monday
	global phase1EndSet17       = td(02oct2022) //sunday
	global phase2StartSet17     = td(03oct2022) //monday
	global phase2EndSet17    	= td(27nov2022) //sunday

	makeHolidays

	global holiday_list = r(holiday_list)
	
	end
	setDates
	
	
	* Save Temp File
	* Author: HW. May 2025
	* This program does not work if you'd like to use the temp file
	* This program is simply in place to comply with "statsby , ci means"
	* If you don't save before running the code it will not let you run
	cap program drop	savetemp		
	program define 		savetemp
	
		tempfile garbage
		save `garbage'
	
	end
	
	

	* Generate baseline covariates for original dataset. New datatsets have these variables already.
	* For replicating analysis using the original dataset.
	* Created by HW in April 2026
	cap program drop gen_bl_cov
	program define gen_bl_cov
		preserve

			cap drop bl_attend bl_earn miss_bl_earn bl_modalwage

			keep if phase == 0

			egen temp = mean(attend), by(pid)
			egen bl_attend = max(temp), by(pid)
			drop temp

			* earnings 
			egen temp = mean(earn) , by(pid)
			egen bl_earn = max(temp), by(pid)
			gen miss_bl_earn = (bl_earn==.)
			replace bl_earn = 0 if miss_bl_earn==1
			drop temp
			
			* Modal Work
			egen temp1 = mode(earn) if earn>0, by(pid)
			egen bl_modalwage = max(temp1), by(pid)
			replace bl_modalwage = 0 if bl_modalwage==.
			drop temp1

			keep pid bl_attend bl_earn miss_bl_earn bl_modalwage
			duplicates drop pid, force

			tempfile bl_cov
			save `bl_cov', replace

		restore

		merge m:1 pid using `bl_cov', update replace keep(1 2 3 4 5) nogen


	end
