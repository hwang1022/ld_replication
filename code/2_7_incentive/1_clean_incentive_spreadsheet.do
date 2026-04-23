************************************************************
* Project			: Regular Labor Supply, Tamil Nadu
* PIs				: Heather Schofield, Supreet Kaur and Luisa Cefala	
* Purpose			: This do file cleans and converts Excel spreadsheet 
* 						tracking incentive payments
* Created on		: HW May 15 2025                
* Last modified by	: HW May 15 2025
************************************************************


***************
**# Call Data
***************

****
**## Stand 1. ADAMBAKKAM
****

	import excel "$raw/(PRLS) Phase 1 Incentive Consolidation New format.xlsx" , firstrow sheet("ADAMBAKKAM") clear
	
	drop AF
	rename PID pid
	rename Week4Allotted4 Week4Allotted
	rename Week1Alloted Week1Allotted
	rename Week*Allotted WeekAllotted*
	tostring Notes* , replace
	reshape long WeekAllotted AmountPaid Laterdate Notes , i(pid) j(week_in)
	
	strclean AmountPaid , replace
	replace AmountPaid = "Yes" if WeekAllotted == 0
	
	replace Laterdate = "13/04/2022" if Laterdate == "13/04/22"
	gen later_date = Laterdate
	
	strclean Notes , replace
	replace Notes = "" if Notes == "."
	
	gen stand = 1
	keep 	pid stand week_in WeekAllotted AmountPaid later_date Notes
	order  	pid stand week_in WeekAllotted AmountPaid later_date Notes
	
	rename WeekAllotted amount_allotted
	rename AmountPaid paid
	rename Notes notes
	
	save "$temp/incentive_record_stand_1" , replace
	
	
****
**## Stand 2. AVADI
****	
	
	import excel "$raw/(PRLS) Phase 1 Incentive Consolidation New format.xlsx" , firstrow sheet("AVADI") clear
	
	drop AF
	rename PID pid
	rename Week4Allotted4 Week4Allotted
	rename Week1Alloted Week1Allotted
	rename Week*Allotted WeekAllotted*
	tostring Notes* , replace
	reshape long WeekAllotted AmountPaid Laterdate Notes , i(pid) j(week_in)
	
	strclean AmountPaid , replace
	replace AmountPaid = "Yes" if WeekAllotted == 0
	
	gen later_date = Laterdate
	
	strclean Notes , replace
	replace Notes = "" if Notes == "."
	
	gen stand = 2
	keep 	pid stand week_in WeekAllotted AmountPaid later_date Notes
	order  	pid stand week_in WeekAllotted AmountPaid later_date Notes
	
	rename WeekAllotted amount_allotted
	rename AmountPaid paid
	rename Notes notes
	
	save "$temp/incentive_record_stand_2" , replace
	
	
	
****
**## Stand 3. Ayanavram
****	
	
	import excel "$raw/(PRLS) Phase 1 Incentive Consolidation New format.xlsx" , firstrow sheet("Ayanavram") clear
	drop if mi(PID)
	
	drop AF
	rename PID pid
	rename Week4Allotted4 Week4Allotted
	rename Week1Alloted Week1Allotted
	rename Week*Allotted WeekAllotted*
	tostring Notes* , replace
	
	rename Laterdate2 Laterdate2_old
	gen Laterdate2 = string(Laterdate2_old, "%tdDDmonCCYY")
	
	
	reshape long WeekAllotted AmountPaid Laterdate Notes , i(pid) j(week_in)
	 
	strclean AmountPaid , replace
	replace AmountPaid = "Yes" if WeekAllotted == 0
	
	gen later_date = Laterdate
	
	strclean Notes , replace
	replace Notes = "" if Notes == "."
	
	gen stand = 3
	keep 	pid stand week_in WeekAllotted AmountPaid later_date Notes
	order  	pid stand week_in WeekAllotted AmountPaid later_date Notes
	
	rename WeekAllotted amount_allotted
	rename AmountPaid paid
	rename Notes notes
	
	save "$temp/incentive_record_stand_3" , replace	
	
	
	
****
**## Stand 5. MKB NAGAR
****	
	
	import excel "$raw/(PRLS) Phase 1 Incentive Consolidation New format.xlsx" , firstrow sheet("MKB NAGAR") clear
	drop if mi(PID)
	
	drop AF
	rename PID pid
	rename Week4Allotted4 Week4Allotted
	rename Week1Alloted Week1Allotted
	rename Week*Allotted WeekAllotted*
	tostring Notes* , replace
	
	rename Laterdate2 Laterdate2_old
	gen Laterdate2 = string(Laterdate2_old, "%tdDDmonCCYY")
	
	reshape long WeekAllotted AmountPaid Laterdate Notes , i(pid) j(week_in)
	 
	strclean AmountPaid , replace
	replace AmountPaid = "Yes" if WeekAllotted == 0
	
	gen later_date = Laterdate
	replace later_date = "" if later_date == "."
	
	strclean Notes , replace
	replace Notes = "" if Notes == "."
	
	gen stand = 5
	keep 	pid stand week_in WeekAllotted AmountPaid later_date Notes
	order  	pid stand week_in WeekAllotted AmountPaid later_date Notes
	
	rename WeekAllotted amount_allotted
	rename AmountPaid paid
	rename Notes notes
	
	save "$temp/incentive_record_stand_5" , replace	
	
	
****
**## Stand 6. KORATTUR
****	
	
	import excel "$raw/(PRLS) Phase 1 Incentive Consolidation New format.xlsx" , firstrow sheet("KORATTUR") clear
	drop if mi(PID)
	
	drop AF
	rename PID pid
	rename Week4Allotted4 Week4Allotted
	rename Week1Alloted Week1Allotted
	rename Week*Allotted WeekAllotted*
	tostring Notes* , replace
	
	destring WeekAllotted1 ,  replace
	reshape long WeekAllotted AmountPaid Laterdate Notes , i(pid) j(week_in)
	 
	strclean AmountPaid , replace
	replace AmountPaid = "Yes" if WeekAllotted == 0
	
	gen later_date = Laterdate
	replace later_date = "" if later_date == "."
	
	strclean Notes , replace
	replace Notes = "" if Notes == "."
	
	gen stand = 6
	keep 	pid stand week_in WeekAllotted AmountPaid later_date Notes
	order  	pid stand week_in WeekAllotted AmountPaid later_date Notes
	
	rename WeekAllotted amount_allotted
	rename AmountPaid paid
	rename Notes notes
	
	save "$temp/incentive_record_stand_6" , replace		
	
	
****
**## Stand 13. THIRUVANMIYUR
****	
	
	import excel "$raw/(PRLS) Phase 1 Incentive Consolidation New format.xlsx" , firstrow sheet("THIRUVANMIYUR") clear
	drop if mi(PID)
	
	drop AV AW AX AY AZ BA BB
	rename PID pid
	rename Week4Allotted4 Week4Allotted
	rename Week1Alloted Week1Allotted
	rename Week*Allotted WeekAllotted*
	tostring Notes* , replace
	
	destring WeekAllotted1 ,  replace
	rename Laterdate9 Laterdate9_old
	gen Laterdate9 = string(Laterdate9_old, "%tdDDmonCCYY")
	
	
	reshape long WeekAllotted AmountPaid Laterdate Notes , i(pid) j(week_in)
	 
	strclean AmountPaid , replace
	replace AmountPaid = "Yes" if WeekAllotted == 0
	
	gen later_date = Laterdate
	replace later_date = "" if later_date == "."
	
	strclean Notes , replace
	replace Notes = "" if Notes == "."
	
	gen stand = 13
	keep 	pid stand week_in WeekAllotted AmountPaid later_date Notes
	order  	pid stand week_in WeekAllotted AmountPaid later_date Notes
	
	rename WeekAllotted amount_allotted
	rename AmountPaid paid
	rename Notes notes
	
	save "$temp/incentive_record_stand_13" , replace		
	

****
**## Stand 15. VELACHERY
****	
	
	import excel "$raw/(PRLS) Phase 1 Incentive Consolidation New format.xlsx" , firstrow sheet("VELACHERY") clear
	drop if mi(PID)
	
	drop AZ BA BB
	rename PID pid
	rename Week4Allotted4 Week4Allotted
	rename Week1Alloted Week1Allotted
	rename Week*Allotted WeekAllotted*
	tostring Notes* , replace
	
	rename Laterdate3 Laterdate3_old
	gen Laterdate3 = string(Laterdate3_old, "%tdDDmonCCYY")
	rename Laterdate8 Laterdate8_old
	gen Laterdate8 = string(Laterdate8_old, "%tdDDmonCCYY")
	rename Laterdate12 Laterdate12_old
	gen Laterdate12 = string(Laterdate12_old, "%tdDDmonCCYY")
	
	reshape long WeekAllotted AmountPaid Laterdate Notes , i(pid) j(week_in)
	 
	strclean AmountPaid , replace
	replace AmountPaid = "Yes" if WeekAllotted == 0
	
	gen later_date = Laterdate
	replace later_date = "" if later_date == "."
	
	strclean Notes , replace
	replace Notes = "" if Notes == "."
	
	gen stand = 15
	keep 	pid stand week_in WeekAllotted AmountPaid later_date Notes
	order  	pid stand week_in WeekAllotted AmountPaid later_date Notes
	
	rename WeekAllotted amount_allotted
	rename AmountPaid paid
	rename Notes notes
	
	save "$temp/incentive_record_stand_15" , replace		
	
	
****
**## Stand 16. GUDUVANCHERY
****	
	
	import excel "$raw/(PRLS) Phase 1 Incentive Consolidation New format.xlsx" , firstrow sheet("GUDUVANCHERY") clear
	drop if mi(PID)
	
	drop Week10Allotted-CY
	rename PID pid
	rename Week4Allotted4 Week4Allotted
	rename Week1Alloted Week1Allotted
	rename Week*Allotted WeekAllotted*
	tostring Notes* , replace
	
	//rename Laterdate3 Laterdate3_old
	//gen Laterdate3 = string(Laterdate3_old, "%tdDDmonCCYY")
	//rename Laterdate8 Laterdate8_old
	//gen Laterdate8 = string(Laterdate8_old, "%tdDDmonCCYY")
	//rename Laterdate12 Laterdate12_old
	//gen Laterdate12 = string(Laterdate12_old, "%tdDDmonCCYY")
	tostring Laterdate9 , replace
	replace Laterdate9 = ""
	
	reshape long WeekAllotted AmountPaid Laterdate Notes , i(pid) j(week_in)
	 
	strclean AmountPaid , replace
	replace AmountPaid = "Yes" if WeekAllotted == 0
	
	gen later_date = Laterdate
	replace later_date = "" if later_date == "."
	
	strclean Notes , replace
	replace Notes = "" if Notes == "."
	
	gen stand = 16
	keep 	pid stand week_in WeekAllotted AmountPaid later_date Notes
	order  	pid stand week_in WeekAllotted AmountPaid later_date Notes
	
	rename WeekAllotted amount_allotted
	rename AmountPaid paid
	rename Notes notes
	
	save "$temp/incentive_record_stand_16" , replace	
	
	
****
**## Stand 17. PADAPPAI
****	
	
	import excel "$raw/(PRLS) Phase 1 Incentive Consolidation New format.xlsx" , firstrow sheet("PADAPPAI") clear
	drop if mi(PID)
	
	drop AF
	rename PID pid
	rename Week4Allotted4 Week4Allotted
	rename Week1Alloted Week1Allotted
	rename Week*Allotted WeekAllotted*
	tostring Notes* , replace
	
	reshape long WeekAllotted AmountPaid Laterdate Notes , i(pid) j(week_in)
	 
	strclean AmountPaid , replace
	replace AmountPaid = "Yes" if WeekAllotted == 0
	
	gen later_date = Laterdate
	replace later_date = "" if later_date == "."
	
	strclean Notes , replace
	replace Notes = "" if Notes == "."
	
	gen stand = 17
	keep 	pid stand week_in WeekAllotted AmountPaid later_date Notes
	order  	pid stand week_in WeekAllotted AmountPaid later_date Notes
	
	rename WeekAllotted amount_allotted
	rename AmountPaid paid
	rename Notes notes
	
	save "$temp/incentive_record_stand_17" , replace	
	
	
****
**## Stand 18. IYAPPANTHANGAL
****	
	
	import excel "$raw/(PRLS) Phase 1 Incentive Consolidation New format.xlsx" , firstrow sheet("IYAPPANTHANGAL") clear
	drop if mi(PID)
	
	drop Week8Allotted-BB
	rename PID pid
	rename Week4Allotted4 Week4Allotted
	rename Week1Alloted Week1Allotted
	rename Week*Allotted WeekAllotted*
	tostring Notes* , replace
	
	reshape long WeekAllotted AmountPaid Laterdate Notes , i(pid) j(week_in)
	 
	strclean AmountPaid , replace
	replace AmountPaid = "Yes" if WeekAllotted == 0
	
	gen later_date = Laterdate
	replace later_date = "" if later_date == "."
	
	strclean Notes , replace
	replace Notes = "" if Notes == "."
	
	gen stand = 18
	keep 	pid stand week_in WeekAllotted AmountPaid later_date Notes
	order  	pid stand week_in WeekAllotted AmountPaid later_date Notes
	
	rename WeekAllotted amount_allotted
	rename AmountPaid paid
	rename Notes notes
	
	save "$temp/incentive_record_stand_18" , replace	
	
	
****
**## Stand 20. PAMMAL
****	
	
	import excel "$raw/(PRLS) Phase 1 Incentive Consolidation New format.xlsx" , firstrow sheet("PAMMAL") clear
	drop if mi(PID)
	
	drop Week8Allotted-BB
	rename PID pid
	rename Week4Allotted4 Week4Allotted
	rename Week1Alloted Week1Allotted
	rename Week*Allotted WeekAllotted*
	tostring Notes* , replace
	
	rename Laterdate1 Laterdate1_old
	gen Laterdate1 = string(Laterdate1_old, "%tdDDmonCCYY")
	rename Laterdate5 Laterdate5_old
	gen Laterdate5 = string(Laterdate5_old, "%tdDDmonCCYY")
	rename Laterdate6 Laterdate6_old
	gen Laterdate6 = string(Laterdate6_old, "%tdDDmonCCYY")
	drop Laterdate*_old
	
	reshape long WeekAllotted AmountPaid Laterdate Notes , i(pid) j(week_in)
	 
	strclean AmountPaid , replace
	replace AmountPaid = "Yes" if WeekAllotted == 0
	
	gen later_date = Laterdate
	replace later_date = "" if later_date == "."
	
	strclean Notes , replace
	replace Notes = "" if Notes == "."
	
	gen stand = 20
	keep 	pid stand week_in WeekAllotted AmountPaid later_date Notes
	order  	pid stand week_in WeekAllotted AmountPaid later_date Notes
	
	rename WeekAllotted amount_allotted
	rename AmountPaid paid
	rename Notes notes
	
	save "$temp/incentive_record_stand_20" , replace	
	
	
	
******************
**# Combine Data
******************	

	drop _all
	foreach i in 1 2 3 5 6 13 15 16 17 18 20 {
		append using "$temp/incentive_record_stand_`i'"
	}
	
	* Paid
	replace paid = "No" if paid == "0"
	replace paid = "No" if paid == "NO"
	replace paid = "Paid later" if paid == "Paylater"
	replace paid = "Yes" if paid == "Yes."
	replace paid = "Paid later" if paid == "paylater"
	replace paid = "Yes" if paid == "yes"
	replace paid = "Missing Data" if mi(paid)

	strclean paid later_date notes , replace
	
	save "$temp/incentive_record_stand" , replace	


	
*********************
**# Restrict sample
*********************	

	use "$temp/incentive_record_stand" , clear
	keep if week_in <= 7
	merge m:1 pid using "$temp/00_mainstudy_master.dta" , keep(3) nogen

	
	gen amount_payed = amount_allotted 
	replace amount_payed = 0 if inlist(paid,"No", "Missing Data")

	keep pid treatment week_in amount_allotted amount_payed 
	save "$temp/incentive_record_stand_clean" , replace