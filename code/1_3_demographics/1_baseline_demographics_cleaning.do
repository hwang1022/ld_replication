**************************************************
*Project: LD 
*Purpose: Baseline Demographics Cleaning  
*Author: Supraja
*Last modified: 2024-03-27 (YS)
**************************************************

/*----------------------------------------------------*/
   /* [>   1.  Open data    <] */ 
/*----------------------------------------------------*/

	use "$raw/02_bs_demographics_p1_complete.dta", clear
	drop if inlist(stand, ${droplist}) // defined in master.do

	* isid pid 
		* fails
		* there are 6 duplicate pids
	format date_p1 %td
	label var date_p1 "BL demog survey part 1 date"
	
	isid pid date_p1
	ta check_completion_p1, m
		* 706 unique PIDs
		* FIXME 6 PIDs with two entries
		/*       PID |      Freq.     Percent        Cum.
			------------+-----------------------------------
			       1344 |          1       16.67       16.67
			       1553 |          1       16.67       33.33
			       1704 |          1       16.67       50.00
			       1776 |          1       16.67       66.67
			       1828 |          1       16.67       83.33
			       2111 |          1       16.67      100.00
			------------+-----------------------------------
			      Total |          6      100.00
		*/

	* Added 2024-04-11 - keep the first survey done with these duplicate PIDs 
	bys pid: gen temp = _n==1
	* br if pid==1344 | pid==1553 | pid==1704 | pid==1776 | pid==1828 | pid==2111
	* check that the later survey is being dropped in all cases
	drop if temp == 0

	preserve 
	use "$raw/02_bs_demographics_p2_complete.dta", clear
	format date_p2 %td
	label var date_p2 "BL demog survey part 2 date"
	drop if inlist(stand, ${droplist}) // defined in master.do
	isid pid date_p2
	tab check_completion_p2, m
		* 695 unique PIDs 
 		* FIXME 6 PIDs with more than one entry. why? Same 6 PIDs as in dem survey p1.
		/*       PID |      Freq.     Percent        Cum.
			------------+-----------------------------------
			       1344 |          1       16.67       16.67
			       1553 |          1       16.67       33.33
			       1704 |          1       16.67       50.00
			       1776 |          1       16.67       66.67
			       1828 |          1       16.67       83.33
			       2111 |          1       16.67      100.00
			------------+-----------------------------------
			      Total |          6      100.00
		*/
	* Added 2024-04-11 - keep the first survey done with these duplicate PIDs 
	bys pid: gen temp = _n==1
	br if pid==1344 | pid==1553 | pid==1704 | pid==1776 | pid==1828 | pid==2111
	* check that the later survey is being dropped in all cases
	drop if temp == 0
	tempfile temp
	save `temp'
	restore 

	merge 1:1 pid using `temp'
	/*    
	Result                           # of obs.
    -----------------------------------------
    not matched                            17
        from master                        14  (_merge==1)
        from using                          3  (_merge==2)

    matched                               692  (_merge==3)
    -----------------------------------------
	*/
 	drop _merge

/*----------------------------------------------------*/
   /* [>   2.  Clean data    <] */ 
/*----------------------------------------------------*/

	* Entry errors on 9th march
	replace stand = 1 if pid==105 & key=="uuid:a6a7e46c-8b9a-4318-b373-a830e4a33f77"
	replace stand = 1 if pid==146 & key=="uuid:fdcc65b2-06a1-415d-8601-3d8c8eed3b86"
	replace stand = 4 if pid==417 & key=="uuid:d95f2359-4c2d-42e8-921c-9ad0db6c1c59"
	
	replace stand = 1 if stand_others=="Adambakkam" & stand==998
	replace stand_others="" if stand_others=="Adambakkam" 
	
	replace stand = 2 if stand_others=="Avadi" & stand==998
	replace stand_others="" if stand_others=="Avadi"
	
	replace stand = 3 if (stand_others=="Ayanavaram" |  stand_others=="Aynavaram")  & stand==998
	replace stand_others=""  if (stand_others=="Ayanavaram" |  stand_others=="Aynavaram") 
	
	replace stand = 4 if stand_others=="Mandaveli"  & stand==998
	replace stand_others = "" if stand_others=="Mandaveli"
	
	replace stand = 5 if (stand_others=="MKB  NAGAR" |  stand_others=="MKB NAGAR" |  stand_others=="MKB Nagar" | stand_others=="MkB Nagar" | stand_others=="Mkb" | stand_others=="Mkb nagar" ) & stand==998
	replace stand_others=""   if (stand_others=="MKB  NAGAR" |  stand_others=="MKB NAGAR" |  stand_others=="MKB Nagar" | stand_others=="MkB Nagar" | stand_others=="Mkb" | stand_others=="Mkb nagar" ) 
		
	//17-03-2022
	*Correcting for missing launchsets
	replace launchset = 1 if pid>100 & pid<=152
	replace launchset = 2 if pid>152 & pid<=197
	replace launchset = 3 if pid==198 | pid==199 | (pid>=2101 & pid<=2151)
	replace launchset = 1 if pid>200 & pid<=247
	replace launchset = 2 if pid>=248 & pid<=279
	replace launchset = 1 if pid>300 & pid<=340
	replace launchset = 2 if pid>=341 & pid<=360
	replace launchset = 1 if pid>400 & pid<=445
	replace launchset = 2 if pid>=446 & pid<=465
	replace launchset = 1 if pid>500 & pid<=550
	replace launchset = 2 if pid>=551 & pid<=581

	//11-04-2022
	*Correcting for outliers in rent amount
	replace bs_dem_rent_frequency = 3 if bs_dem_rent_frequency_others =="3years"
	replace bs_dem_rent_frequency_others ="" if bs_dem_rent_frequency_others =="3years"
	replace bs_dem_rent_amount =3472 if pid==301
	
	//13-04-2022
	*correction for incorrect stand entry
	replace stand_others="" if stand==998 & pid>=705 & pid<=765
	replace stand=7 if stand==998 & pid>=705 & pid<=765 
	
	/*
	* add stand label - incomplete
	label define stand_lab 1 "1. Adambakam" ///
	2 "2. Avadi" ///
	3 "3. Aynavaram" ///
	4 "4. Mandaveli" ///
	5 "5. MKB" ///
    6 "6. Korattur" ///
	7 "7. MMDA" ///
	8 "8. Porur" ///
	9 "9. TVK Nagar"
	
	label val stand stand_lab
	*/

   //Cleaning obligation time, 22-04-2022
   replace bs_dem_obligation_time="4:00:00 AM" if date_p1==td(08mar2022) & pid==201
   replace bs_dem_obligation_time="5:45:00 AM" if date_p1==td(08mar2022) & pid==240
   replace bs_dem_obligation_time="5:30:00 AM" if date_p1==td(09mar2022) & pid==216
   replace bs_dem_obligation_time="5:00:00 AM" if date_p1==td(09mar2022) & pid==239
   replace bs_dem_obligation_time="4:15:00 AM" if date_p1==td(10mar2022) & pid==202
   replace bs_dem_obligation_time="6:00:00 AM" if date_p1==td(12mar2022) & pid==215
   
	// 14-07-22 (DL) missing launchsets and stands
	replace launchset = 6 if key == "uuid:568189d5-1e24-4c55-889d-7917c920bfd7" & launchset == . // pid == 1022
	//stands labelled as 998
	replace stand = 12 if inlist(pid, 1203,1205,1211,1212,1220,1221,1225,1226,1232,1234,1235,1237,1238,1239,1244,1252,1254,1255,1262,1266,1271,1274,1275,1276,1278,1279,1281,1282) & stand == 998 
	replace stand = 13 if inlist(pid, 1305,1306,1321,1322,1329,1330,1337,1339,1342,1344,1347,1349,1350,1357,1361) & stand == 998
	
	// 20-7-22 (DL) missing launchsets
	replace launchset = 13 if pid == 6848 & stand == 17
	replace launchset = 14 if stand == 19 & inlist(pid, 1901,1914,1925,1933,1939,1906,1923,1928,1945)
	//dummy command
	count
	
	//22-07-22 (NL) dropping duplicates
	drop if key=="uuid:1b9a3b8d-c9c4-49a0-88d5-764ab20759d6" & pid==9500
	drop if key=="uuid:be7756d2-1e06-47e1-ac1f-b20802828248" & pid==9500
	
	//12-10-22 (NL) correcting marital status 
	replace bs_dem_marital_st  = 2 if pid==6823
	//30-10-22 Correcting outlier (LC)
	replace bs_dem_others_contribute_earn = 75000 if key == "uuid:2526b93f-24a5-4463-9345-48979461a9fe"
	count

	//dropping dropped stands
	drop if inlist(stand, ${droplist})

	// For variables where we ask duration in years and months, transform everything in fractions years
	 local year_vars job stand lngterm
	 foreach x in job stand lngterm {
	      replace bs_dem_`x'_yrs = bs_dem_`x'_yrs + round(bs_dem_`x'_mnths/12,0.01)
		  drop bs_dem_`x'_mnths
	 }

/*----------------------------------------------------*/
   /* [>   3.  Save data    <] */ 
/*----------------------------------------------------*/

	sort date_p1 date_p2 interviewer_p1 interviewer_p2 pid
	// isid pid
		* 6 PIDs with 2 entries
	order pid date_p1 date_p2 interviewer_p1 interviewer_p2 
	isid pid
	save "$temp/03_bs_demographics_completed_cleaned.dta", replace
