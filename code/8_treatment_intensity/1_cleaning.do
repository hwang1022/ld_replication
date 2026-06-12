************************************************************
************************************************************
* 	Project:			Labor Discipline
* 	Purpose:			Combine Stand trength
* 	Author:				HW 
* 	Created:			2025-Apr-22 (HW)
* 	Last modified:		2025-May-29 (HW)
************************************************************
************************************************************

cap program drop clean_sheet_regular
program define clean_sheet_regular

	syntax [anything] , sheet(string) [max_launchset(string)]
	
	if regexmatch("`sheet'", "\d+") local stand_num = regexcapture(0) 

	import excel using "$raw/[PRLS] Stand Strength Tracker.xlsx" , clear firstrow sheet("`sheet'")
	strclean Numberof , replace proper
	drop if mi(Numberof)

	* Assertion
	if `stand_num' == 1 {
		gen employer = Date[_n+1] == "" & !mi(Date)
		replace Date = Date[_n-1] if mi(Date)
		replace Date = "" if employer == 1
	}
	
	
	if `stand_num' == 13 {
		preserve
		destring C-N , replace force
		egen max_value = rowmax(C-N)
		assert max_value > max_value[_n+1] if !mi(Date) &  !mi(max_value[_n+1])
		restore
	}
	
	assert mi(Date) if strpos(Numberof, "mployer")
	assert !mi(Date) if strpos(Numberof, "articipant")
	
	* Fill Date
	gen date_num = date(Date, "DMY") 
	format date_num %td
	drop if Date == "/11/2022" // Handle error in stand 18. Twp obs. with wrong date and no info
	
	
	* Keep Obs
	gen stand = `stand_num'
	rename Overall* overall
	keep if strpos(Numberof, "articipant")
	assert !mi(date_num)
	
	keep stand date_num C-N overall
	order stand date_num C-N overall
	

	* Clean num people
	destring C-N overall , replace force
	
	* Restrict Time
	if "`max_launchset'" != "" {
		drop if date_num > ${phase2EndSet`max_launchset'}
	}
	
	
	save "$temp/st_`stand_num'" , replace

end



******************
**# Clean Sheets 
******************

	clean_sheet_regular , sheet("20. Iyappandagal") max_launchset(15)
	clean_sheet_regular , sheet("18. Pammal") 		max_launchset(15)
	clean_sheet_regular , sheet("17.Gudvancherry") 	max_launchset(16)
	clean_sheet_regular , sheet("16. Padappai") 	max_launchset(16)
	clean_sheet_regular , sheet("15. Velacheery")	max_launchset(17)
	clean_sheet_regular , sheet("13. Thrivanmiyur")	max_launchset(11)
	clean_sheet_regular , sheet("6.Korattur")		max_launchset(5)
	clean_sheet_regular , sheet("5. MKB Nagar")		max_launchset(2)
	clean_sheet_regular , sheet("3.Ayannavaram")	max_launchset(2)
	clean_sheet_regular , sheet("2.Avadi")			max_launchset(2)
	clean_sheet_regular , sheet("1. Adambakkam")	max_launchset(3)
	
********************
**# Combine Sheets 
********************

	
	foreach stand_num in 1 2 3 5 6 13 15 16 17 18 20 {
		append using "$temp/st_`stand_num'"
	}

	sort stand date_num
	drop overall
	rename date_num date

	foreach var of varlist C-N {
		local lab : variable label `var'
		local new_time_str = "time" + lower(subinstr(subinstr("`lab'", ":", "_", .), " ", "_", .))
		rename `var' `new_time_str'
	}
	rename *_am *

	save "$temp/stand_strength.dta" , replace	
