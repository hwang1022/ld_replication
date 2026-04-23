*************************************************
*************************************************
*	Project: LD Main Study
*	Purpose: Phase1 Cleaning  
*	Last last modified: 2024-08-22 (YS)
*	Last modified: 		2024-11-12 (HW)
*************************************************
*************************************************

/*----------------------------------------------------*/
/* [>   1.  Open data    <] */ 
/*----------------------------------------------------*/

	use "$raw/01_phase1_named.dta", clear
	
	
	
/*----------------------------------------------------*/
   /* [>   2.  Clean data    <] */ 
/*----------------------------------------------------*/


* Clean up arrival time variable
	gen arrival_time_1 = Clock(arrival_time, "hms")
	format arrival_time_1 %tCHH:MM
	rename arrival_time arrival_time_string
	rename arrival_time_1 arrival_time
	format arrival_time %tCHH:MM

* Drop dropped stands 
	drop if inlist(stand, ${droplist}) //defined in master dofile

* Manual corrections 
	replace arrival_time =tc(08:30) if pid==403 & date==td(21mar2022)
	replace arrival_time =tc(08:20) if pid==413 & date==td(21mar2022)
	replace arrival_time =tc(08:16) if pid==421 & date==td(21mar2022)
	replace arrival_time =tc(07:55) if pid==422 & date==td(21mar2022)
	replace arrival_time =tc(08:40) if pid==443 & date==td(21mar2022)
	replace arrival_time =tc(08:30) if pid==410 & date==td(23mar2022)
	replace arrival_time =tc(08:38) if pid==413 & date==td(23mar2022)
	replace arrival_time =tc(08:06) if pid==443 & date==td(23mar2022)
	replace arrival_time =tc(08:35) if pid==443 & date==td(25mar2022)
	replace arrival_time =tc(08:40) if pid==410 & date==td(25mar2022)
	replace arrival_time =tc(08:03) if pid==413 & date==td(25mar2022)
	replace arrival_time =tc(08:57) if pid==442 & date==td(25mar2022)
	
	//02-04-22 changing stand for 409 
	replace stand = 4 if pid == 409 & date == td(02apr2022) & key == "uuid:72da6bb2-0cbf-43ee-920f-3b77d16c2dff"

	replace arrival_time= arrival_time- tc(05:30) if interviewer=="22. Karthik" & date>=td(04apr2022) & date<=td(09apr2022) & arrival_time>tc(10:00) & mode==1
	replace arrival_time= arrival_time- tc(09:30) if interviewer=="23. Ananthan" & date>=td(04apr2022) & date<=td(09apr2022) & arrival_time>tc(10:00) & mode==1
	replace arrival_time= arrival_time- tc(05:30) if interviewer=="22. Karthik" & date>=td(11apr2022) & date<=td(13apr2022) & arrival_time>tc(10:00) & mode==1
	replace arrival_time=tc(7:15) if interviewer=="22. Karthik" & date>=td(11apr2022) & date<=td(13apr2022) & arrival_time>tc(10:00) & mode==1 & pid==146
	replace arrival_time=tc(7:11) if interviewer=="22. Karthik" & date>=td(11apr2022) & date<=td(13apr2022) & arrival_time>tc(10:00) & mode==1 & pid==151
	replace arrival_time=tc(7:31) if interviewer=="22. Karthik" & date>=td(11apr2022) & date<=td(13apr2022) & arrival_time>tc(10:00) & mode==1 & pid==2124
	
	* 11/04/22 (LC): replace arrival_time equal to missing if mode == 2 (if survey was taken over the phone)
	replace arrival_time = . if mode == 2
	replace arrival_time_text = "" if mode == 2
	
	*18-04-2022, correction of stand name
	replace stand=5 if stand==6 & interviewer=="11. Selvaraj" & pid==529 & date==td(18apr2022)
	
	*19-04-22, correction of date 
	replace date=td(12apr2022) if date==td(20apr2022) & pid == 229 & key=="uuid:3504a827-8a81-4b54-9b8d-b88b35b04145"
	
	*Time found corrections , 22-04-2022
	replace d_time_found_1="7:06:00 AM" if date==td(05apr2022) & interviewer=="23. Ananthan" & pid==116
	replace d_time_found_2="7:03:00 AM" if date==td(04apr2022) & interviewer=="23. Ananthan" & pid==125
	replace d_time_found_1="7:09:00 AM" if date==td(05apr2022) & interviewer=="23. Ananthan" & pid==125
	replace d_time_found_1="8:39:00 AM" if date==td(08apr2022) & interviewer=="22. Karthik" & pid==130
	replace d_time_found_1="7:40:00 AM" if date==td(05apr2022) & interviewer=="23. Ananthan" & pid==139
	replace d_time_found_2="7:35:00 AM" if date==td(04apr2022) & interviewer=="23. Ananthan" & pid==141
	replace d_time_found_1="7:48:00 AM" if date==td(05apr2022) & interviewer=="23. Ananthan" & pid==143
	replace d_time_found_1="7:05:00 AM" if date==td(05apr2022) & interviewer=="23. Ananthan" & pid==144
	replace d_time_found_1="6:21:00 AM" if date==td(05apr2022) & interviewer=="23. Ananthan" & pid==146
	replace d_time_found_1="7:09:00 AM" if date==td(05apr2022) & interviewer=="23. Ananthan" & pid==151
	replace d_time_found_1="6:56:00 AM" if date==td(08apr2022) & interviewer=="22. Karthik" & pid==155
	replace d_time_found_1="6:56:00 AM" if date==td(08apr2022) & interviewer=="22. Karthik" & pid==155
	replace d_time_found_1="7:20:00 AM" if date==td(08apr2022) & interviewer=="22. Karthik" & pid==169
	replace d_time_found_2="7:38:00 AM" if date==td(11apr2022) & interviewer=="22. Karthik" & pid==169
	replace d_time_found_1="8:34:00 AM" if date==td(05apr2022) & interviewer=="22. Karthik" & pid==170
	replace d_time_found_2="7:55:00 AM" if date==td(04apr2022) & interviewer=="23. Ananthan" & pid==171
	
	replace d_time_found_1="8:51:00 AM" if date==td(08apr2022) & interviewer=="22. Karthik" & pid==173
	replace d_time_found_1="6:37:00 AM" if date==td(08apr2022) & interviewer=="22. Karthik" & pid==196
	replace d_time_found_2="" if date==td(29mar2022) & interviewer=="16. Pandiadurai" & pid==213
	replace d_time_found_3="7:21:00 AM" if date==td(04apr2022) & interviewer=="33. Mohan Raja" & pid==256
	replace d_time_found_2="" if date==td(04apr2022) & interviewer=="33. Mohan Raja" & pid==256
	replace d_time_found_3="9:08:00 AM" if date==td(24mar2022) & interviewer=="9. Aslam" & pid==336
	replace d_time_found_1="8:16:00 AM" if date==td(23mar2022) & interviewer=="13. Vasudevan" & pid==410
	replace d_time_found_1="8:40:00 AM" if date==td(25mar2022) & interviewer=="13. Vasudevan" & pid==410
	replace d_time_found_2="8:38:00 AM" if date==td(25mar2022) & interviewer=="13. Vasudevan" & pid==413
	replace d_time_found_1="8:57:00 AM" if date==td(25mar2022) & interviewer=="13. Vasudevan" & pid==442
	replace d_time_found_1="8:35:00 AM" if date==td(25mar2022) & interviewer=="13. Vasudevan" & pid==443
	replace d_time_found_1="8:56:00 AM" if date==td(05apr2022) & interviewer=="23. Ananthan" & pid==2108
	replace d_time_found_1="6:55:00 AM" if date==td(05apr2022) & interviewer=="23. Ananthan" & pid==2113
	
	//dropping refused participant
	drop if pid==555

	replace stand = 6 if stand == 998 & stand_others == "Korattur"

	//22-04-2022, changing the stand of 201 from 4 to 2
	replace stand = 2 if pid == 201 & date == td(22apr2022) & key == "uuid:bdc9e159-ef5b-4d2b-bf98-f7b1209ab76c"
	
	//23-04-2022, time spotted participant corrections
	replace arrival_time= arrival_time- tc(09:30) if interviewer=="23. Ananthan" & date>=td(18apr2022) & date<=td(23apr2022) & arrival_time>tc(10:00) & mode==1
	drop if key == "uuid:20237524-eae6-4927-98a9-f9f114b79905" & pid == 248 // this is a monthly participant, correction made by LC on 25-05-22
	//23-04-2022, entry error in mode of survey
	replace mode=2 if interviewer=="33. Mohan Raja" & date==td(18apr2022) & pid==226
	replace mode=2 if interviewer=="20. Anand" & date==td(18apr2022) & pid==418
	replace mode=2 if interviewer=="20. Anand" & date==td(22apr2022) & pid==418
	
	//25-04-22, stand is entered as 
	 replace stand = 7 if pid >= 702 & pid <= 756 & date == td(25apr2022)
	 replace stand = 6 if pid >= 607 & pid <= 646 & date == td(25apr2022)
	 
	 //26-04-22 
	replace stand = 7 if pid >= 702 & pid <= 756 & date == td(26apr2022)
	
	//30-04-2022, changing arrival time for PID 
	replace arrival_time = tc(08:10) if date == td(25apr2022) & pid == 180 & key == "uuid:15f4928e-2c80-470f-8d12-578e9e98b9e8"
	replace arrival_time = tc(08:14) if date == td(26apr2022) & pid == 226 & key == "uuid:157f9951-aea9-43e5-8ab3-a44778a00f03"
	
	//30-04-2022, changing stand for 754
	replace stand = 7 if pid == 754 & date == td(30apr2022)
	
	//02-05-2022, changing stand for 754
	replace stand = 7 if pid == 754 & date == td(02may2022)
	
	//02-05-2022, changing stand for 754
	replace stand = 7 if pid == 754 & date == td(02may2022)
	
	//02-05-2022 changing arrival time for Ananthan's tab
	replace arrival_time= arrival_time- tc(09:30) if interviewer=="23. Ananthan" & date==td(02may2022) & arrival_time>tc(10:00) & mode==1

	//04-05-2022, changing arrival time for Ananthan's tab
	replace arrival_time= arrival_time- tc(09:30) if interviewer=="23. Ananthan" & date==td(04may2022) & arrival_time>tc(10:00) & mode==1
	
	//05-05-2022, changing stand for 505 and 547 
	replace stand = 5 if pid == 505 & date == td(05may2022)
	replace stand = 5 if pid == 547 & date == td(05may2022)
	
	//05-05-2022, changing arrival time for Ananthan's tab
	replace arrival_time= arrival_time- tc(09:30) if interviewer=="23. Ananthan" & date==td(05may2022) & arrival_time>tc(10:00) & mode==1
	
	//06-05-2022, changing arrival time for Ananthan's tab
	replace arrival_time= arrival_time- tc(09:30) if interviewer=="23. Ananthan" & date==td(06may2022) & arrival_time>tc(10:00) & mode==1
	
	//07-05-2022, changing arrival time for Ananthan's tab
	replace arrival_time= arrival_time- tc(09:30) if interviewer=="23. Ananthan" & date==td(07may2022) & arrival_time>tc(10:00) & mode==1

	//replace mode ==2 for 421
	replace mode = 2 if pid == 421 & date == td(05may2022) & interviewer == "20. Anand" 
	
	//09-05-2022, changing arrival time for Ananthan's tab
	replace arrival_time= arrival_time- tc(09:30) if interviewer=="23. Ananthan" & date==td(09may2022) & arrival_time>tc(10:00) & mode==1
	
	//09-05-22 changing launchsets for a few pids
	replace launchset = 2 if pid == 202 | pid == 240 | pid == 311 | pid == 509 | pid == 529 | pid == 542 & date == td(09may2022)
	
	//09-05-22 dropping extra obs for 332 and 333 from attendance trackers
	drop if  pid == 332 & date == td(07may2022) & stand == . 
	drop if pid == 333 & date == td(07may2022) & stand == .
	
	//10-05-2022, changing arrival time for Ananthan's tab
	replace arrival_time= arrival_time- tc(09:30) if interviewer=="23. Ananthan" & date==td(10may2022) & arrival_time>tc(10:00) & mode==1
	
	//11-05-2022, changing arrival time for Ananthan's tab
	replace arrival_time= arrival_time- tc(09:30) if interviewer=="23. Ananthan" & date==td(11may2022) & arrival_time>tc(10:00) & mode==1
	
	//12-05-2022, changing arrival time for Ananthan's tab
	replace arrival_time= arrival_time- tc(09:30) if interviewer=="23. Ananthan" & date==td(12may2022) & arrival_time>tc(10:00) & mode==1
	
	//13-05-2022, changing arrival time for Ananthan's tab
	replace arrival_time= arrival_time- tc(09:30) if interviewer=="23. Ananthan" & date==td(13may2022) & arrival_time>tc(10:00) & mode==1
	
	//14-05-22 dropping repeat observation for 183
	drop if pid == 183 & date == td(14may2022) & interviewer == "23. Ananthan"
	replace arrival_time= arrival_time- tc(09:30) if interviewer=="23. Ananthan" & date==td(14may2022) & arrival_time>tc(10:00) & mode==1
	
	//16-05-22 ananthan's tab
	replace arrival_time= arrival_time- tc(09:30) if interviewer=="23. Ananthan" & date==td(16may2022) & arrival_time>tc(10:00) & mode==1
	
	//17-05-22 ananthan's tab
	replace arrival_time= arrival_time- tc(09:30) if interviewer=="23. Ananthan" & date==td(17may2022) & arrival_time>tc(10:00) & mode==1
	
	//17-05-22 changing Bala sir's stand 
	replace stand = 6 if date == td(17may2022) & pid == 641 & interviewer == "15. Balasubramaniam"
	
	//18-05-22 ananthan's tab
	replace arrival_time= arrival_time- tc(09:30) if interviewer=="23. Ananthan" & date==td(18may2022) & arrival_time>tc(10:00) & mode==1
	
	//19-05-22 ananthan's tab
	replace arrival_time= arrival_time- tc(09:30) if interviewer=="23. Ananthan" & date==td(19may2022) & arrival_time>tc(10:00) & mode==1
	
	//20-05-22 ananthan's tab
	replace arrival_time= arrival_time- tc(09:30) if interviewer=="23. Ananthan" & date==td(20may2022) & arrival_time>tc(10:00) & mode==1
	
	//21-05-22 ananthan's tab
	replace arrival_time= arrival_time- tc(09:30) if interviewer=="23. Ananthan" & date==td(21may2022) & arrival_time>tc(10:00) & mode==1
	
	//24-05-22 changing arrival_time for a whole load of PIDs
	replace arrival_time = tc(06:44) if pid == 715 & date == td(24may2022)
	replace arrival_time = tc(06:39) if pid == 716 & date == td(24may2022)
	replace arrival_time = tc(08:09) if pid == 755 & date == td(24may2022)
	replace arrival_time = tc(07:49) if pid == 725 & date == td(24may2022)
	replace arrival_time = tc(07:28) if pid == 756 & date == td(24may2022)
	replace arrival_time = tc(08:55) if pid == 741 & date == td(24may2022)
	replace arrival_time = tc(09:10) if pid == 737 & date == td(24may2022)
	replace arrival_time = tc(09:05) if pid == 701 & date == td(24may2022)
	replace arrival_time = tc(07:29) if pid == 703 & date == td(24may2022)
	replace arrival_time = tc(07:51) if pid == 328 & date == td(24may2022)
	
	//24-05-22 ananthan's tab
	replace arrival_time= arrival_time- tc(09:30) if interviewer=="23. Ananthan" & date==td(24may2022) & arrival_time>tc(10:00) & mode==1
	
	// 29-05-22 (LC) dropping some observations coming from the attendance tracker from different stands
	drop if stand == 9  & date == td(25apr2022)
	drop if pid == 265  & date == td(22apr2022)
	drop if pid == 248  & date == td(13may2022)
	drop if pid == 252  & date == td(27apr2022)
	drop if pid == 347  & date == td(28mar2022)
	drop if pid == 678  & date == td(02may2022)
	drop if pid == 2105 & date == td(27apr2022)
	drop if pid == 318  & (date == td(24mar2022) | date == td(26mar2022))
	
	// 3-06-22 (LC) correcting launchset variable
	replace launchset = 2 if pid == 201
	
	// 4-06-22 (LC) correcting launchset variable
	replace launchset = 6 if pid == 1049
	
	//08-06-22 changing PM to AM for Gautham's tab
	replace arrival_time = arrival_time - tc(12:00) if interviewer == "42. Gautham" & date == td(08jun2022)
	
	//11-06-22 changing check_completion status because of extra days of recalls due to prefill issues
	replace check_completion = 1 if key == "uuid:4f56f9ba-f65f-45f0-ac3a-3370bcbca2ef" // 6-6-22 wrong number of recall days
	replace check_completion = 1 if key == "uuid:6331d1a9-c87f-4c43-9062-d733026d13c2" // 8-6-22 wrong number of recall days
	replace check_completion = 1 if key == "uuid:a0d45681-06a3-4b30-98aa-32f21ab70a5a" // 6-6-22 wrong number of recall days
	replace check_completion = 1 if key == "uuid:667ae8d3-8dd4-41ce-9c82-e797a88d8fbd" // 6-6-22 wrong number of recall days
	
	//18-06-22, correcting completion status
	replace check_completion = 1 if key == "uuid:e8bb2cba-04d3-48bf-b8a3-00780a3a7eb7"
	replace check_completion = 1 if key == "uuid:246acbd4-dbbc-4825-89c7-5aca0296fa35"
	
	//20-06-22
	drop if key == "uuid:acdcaadc-4631-49ec-aaee-5924691220cb" // one form was entered with wrong recall number, then updated
	
	//1-07-22 (LC- correcting arrival time)
	//	replace arrival_time = arrival_time- tc(3:30) if interviewer == "14. Arivazhagan" & date == td(30jun2022)
	//	replace arrival_time = arrival_time- tc(3:30) if interviewer == "14. Arivazhagan" & date == td(29jun2022)
	
	replace arrival_time = arrival_time+ tc(3:30) if interviewer == "21. Surya" & date == td(30jun2022)
	replace arrival_time = arrival_time+ tc(3:30) if interviewer == "22. Karthik" & date == td(30jun2022)
	//	replace arrival_time = arrival_time+ tc(3:30) if interviewer == "30. Regi" & date == td(30jun2022)
	replace arrival_time = arrival_time+ tc(3:30) if interviewer == "35. Arul" & date == td(30jun2022)
	replace arrival_time = arrival_time+ tc(3:30) if interviewer == "35. Arul" & date == td(29jun2022)
	replace arrival_time = arrival_time+ tc(3:30) if interviewer == "36. Diwakar" & date == td(30jun2022)
	replace arrival_time = arrival_time+ tc(3:30) if interviewer == "43. Vellaisami" & date == td(30jun2022)

	//11-07-22 (LC - correcting launchset)
	replace launchset = 10 if inlist(pid, 1304, 1308, 1230, 1333, 1201, 1209, 1217, 1226, 1229)
	
	//06-07-22 (ES - correcting arrival_time - similar to time found corrections on 22-04-2022)
	replace arrival_time = tc(7:18) if date==td(02apr2022) & interviewer=="8. Avinash" & pid==336
	replace arrival_time = tc(8:30) if date==td(05apr2022) & interviewer=="22. Karthik" & pid==170
	replace arrival_time = tc(9:35) if date==td(08apr2022) & interviewer=="22. Karthik" & pid==130
	replace arrival_time = tc(8:25) if date==td(08apr2022) & interviewer=="22. Karthik" & pid==2138
	
	// 19-07-2022 (ES - these are phone surveys replace mode = 2)
	replace mode = 2 if date==td(01apr2022) & interviewer=="7. Kuppusamy" & pid==578
	replace mode = 2 if date==td(09apr2022) & interviewer=="33. Mohan Raja" & pid==225
	replace mode = 2 if date==td(07may2022) & interviewer=="41. Nandhakumar" & pid==518
	replace mode = 2 if date==td(07may2022) & interviewer=="41. Nandhakumar" & pid==578
	*replace arrival_time = tc(***) if date==td(10may2022) & interviewer=="34. Edison" & pid==353
	
	*drop observations bc missing from spreadsheet
	drop if date==td(19may2022) & pid==2133 & interviewer == ""
	drop if date==td(06may2022) & pid==130 & interviewer == ""
	
	//08-07-22 (ES - correcting arrival_time for data between 08-jun-2022 and 07-jul-2022 by replacing with arrival_time_text variable)
	
	gen arrival_time_temp = subinstr(arrival_time_text,".",":",.)  if date >= td(08jun2022) & date <= td(07jul2022)
	replace arrival_time_temp = subinstr(arrival_time_temp," am","",.) if date >= td(08jun2022) & date <= td(07jul2022)
	replace arrival_time_temp = subinstr(arrival_time_temp,",","",.)   if date >= td(08jun2022) & date <= td(07jul2022)
	gen time_temp = clock(arrival_time_temp, "hm")
	format time_temp %tCHH:MM
	replace arrival_time = time_temp if date >= td(08jun2022) & date <= td(07jul2022) & time_temp != . 
	drop arrival_time_temp time_temp

	*1 entry where text time is only :29 - fix this manually*
	replace arrival_time = tc(8:29) if date==td(05jul2022) & interviewer=="40. Anupriya" & pid==1308
	replace arrival_time = tc(8:15:25 AM) if pid == 1338 & date == td(04jul2022)
	replace arrival_time = tc(7:59:59 AM) if pid == 1338 & date == td(06jul2022)

	// 11-07-22
	replace arrival_time= arrival_time- tc(09:30) if interviewer=="23. Ananthan" & date==td(11jul2022) & arrival_time>tc(10:00) & mode==1
	// 13-07-22
	replace arrival_time= arrival_time- tc(09:30) if interviewer=="23. Ananthan" & ( date==td(12jul2022) | date == td(13jul2022) ) & arrival_time>tc(10:00) & mode==1
	
	// 16-07-22 correcting Anandhan's tab forever
	replace arrival_time= arrival_time- tc(09:30) if interviewer=="23. Ananthan" & stand == 15 & mode==1 & date> td(13jul2022)
	replace launchset = 13 if pid == 1411
	//16-07-2022, correcting completion status
	replace check_completion=1 if key=="uuid:968745f0-e08a-44ee-84fe-d01db2da57b8"
	//23-07-2022
	replace check_completion = 1 if key == "uuid:892d60f5-1d0a-4c43-b828-56267a9afc40" // 6848
	replace check_completion = 1 if key == "uuid:c71f5d5c-e960-41e9-9733-1c94a16e28e1" // 6848
	replace launchset = 14 if inlist(pid, 1487, 1631, 1675, 1704, 1705, 1741, 1772, 9505) // shifted batch

	*04-08-2022,correcting for entry error (NL)
	replace pid=1338 if key=="uuid:dfdb1c42-52d9-400b-b685-88ca3fac44f4"
	replace d_treatment=0 if key=="uuid:dfdb1c42-52d9-400b-b685-88ca3fac44f4" // was entered as 1339, which is a treatment, so his treatment status was 1 in the data because it reflected the PID from 1339
	
	*05-08-2022, dropping dupliicate observation
	drop if key=="uuid:d01e9084-cb56-4dcb-808f-f2f4d626a581"
	
	//30-07-2022
	drop if pid == 1822 & date == td(26jul2022) // monthly PID	
	
	//08-08-22 (DL)
	//missing stands
	replace stand = 6 if stand == . & inlist(pid, 603,604,607,612,618,619,630,636,641,642,644,651,655,664,666,672,673,677,679,683,685)
	replace stand = 7 if stand == . & inlist(pid,701,702,703,704,715,716,717,719,721,722,723,725,729,731,734,737,739,741,744,749,754,756)
	replace stand = 10 if stand == . & inlist(pid,1005,1015,1016,1020, 1023,1048,1049,1050, 1052,1057,1063,1064,1066,1070,1074,1076,1081,1083,3006,3007,3016,3018,3021,3022,3025,3029,3032,3037,3041,3048,3051,3052,3059,3061,3066,3067)
	replace stand = 12 if stand == . & inlist(pid, 1201,1209,1216,1217,1219,1226,1229,1230,1244,1245,1246,1251,1253,1257,1258,1259,1261,1267,1269,1272,1276,1283,1287,1288,1295,1297,4300, 4306,4307,4309)						
	replace stand = 13 if stand == . & inlist(pid,1302,1304,1308,1318,1333,1335,1338,1339,1351,1365,1366,1367, 1376,1379,1381)				
	replace stand = 14 if stand == . & inlist(pid,1404,1405,1406,1407,1409,1411,1414,1415,1416,1423,1439,1441, 1444,1445,1447,1448, 1451,1452,1458,1459,1460,1464,1466,1475,1482,1484,1487,1491,5498,5499,9503,9504,9505,9507,9510,9516)
	replace stand = 15 if stand == . & inlist(pid,1511,1514,1520,1523,1530,1534,1542,1550,1554,1561,1562,1580)		
	replace stand = 16 if stand == . & inlist(pid,1610,1611,1612,1617,1620,1621,1623,1628,1631,1632,1634,1640, 1642,1645,1657,1658,1675,1685,1693,1695, 7700,7707,7714)		
	replace stand = 17 if stand == . & inlist(pid,1702,1704,1705,1722,1727,1731,1741,1744,1747,1753,1769,1772, 1776,1782,1789,6801, 6803,6805,6816,6819,6823,6826,6829,6841, 6842,6843,6848)					
	replace stand = 18 if stand == . & inlist(pid,1803,1808,1818,1819,1823,1825,1826,1828,1831,1834,1839,1841, 1843,1844,1845)											
	replace stand = 19 if stand == . & inlist(pid,1902,1903,1905,1917,1919,1921,1925,1928,1934,1935,1936,1938, 1940,1944, 1953, 1958,1965,1966)						
	replace stand = 20 if stand == . & inlist(pid,2003,2004,2019,2020,2021,2029)
		
	//10-08-22 (DL)
	//missing stands
	replace stand = 16 if stand == . & inlist(pid,7734, 7738, 7742) 
	replace stand = 17 if stand == . & inlist(pid,6846, 6863, 6867, 6873, 6874, 6875, 6889) 
	
	//11-08-22 (DL)
	//missing stands
	replace stand = 16 if stand == . & inlist(pid, 7722, 7740)
	replace stand = 17 if stand == . & 	pid == 6876

	//11-08-22 (DL)
	//missing stands
	replace stand = 16 if stand == . & inlist(pid, 1679, 7728)
	replace stand = 17 if stand == . & inlist(pid, 6860, 6869)
	
	//12-08-22 (LC)
	replace arrival_time = arrival_time - tc(9:30) if interviewer == "23. Ananthan" & date >= td(7aug2022) & date < td(14aug2022)
		
	drop if key=="uuid:a188ec5e-1840-4393-95bb-0be4c53c88c5"
	
	//16-08
	replace check_completion=0 if key == "uuid:5ce5aa34-90d2-4bb3-bae1-2550aef82eac"
	//17-08, dropping duplicate observations
	drop if key=="uuid:7ebfed66-c5fe-4c4b-9050-8302147cfe22"
	drop if key=="uuid:35907035-0de1-49d2-bb0d-3275e9dc00a8"
	drop if key=="" & pid==1452 & date==td(09aug2022)
	replace date=td(16aug2022) if key=="uuid:07b8b2b3-7fc3-481b-8987-249c940158f6"
	drop if key=="" & pid==1452 & date==td(16aug2022)
	
	//19-08-22
	//missing stands
	replace stand = 16 if stand == . & pid == 1683
	replace stand = 16 if stand == . & pid == 7732
	replace stand = 17 if stand == . & pid == 1779
	replace stand = 20 if stand == . & pid == 2042
	
	//20-08-22 (NL)
	replace arrival_time = arrival_time - tc(9:30) if interviewer == "23. Ananthan" & date >= td(15aug2022) & date < td(21aug2022)
	
	//23-08-22 (NL), correcting for entry error in pid
	replace pid = 1458 if key=="uuid:428a7fcd-de9e-4833-95e4-bef9278e7f95"
	replace pid = 1256 if key=="uuid:ca33b677-e613-4fc2-9c6e-3eff566b4485"
	
	//26-08-2022 (NL), dropping duplicate observation
	drop if key=="uuid:cd814b8f-e9e6-4adc-9182-6c30f969f6d3"
	
	//27-08-2022 (LC), dropping monthly PID 1256
	drop if key == "uuid:ca33b677-e613-4fc2-9c6e-3eff566b4485" // surveyed on 26/08
	replace pid= 1828 if key=="uuid:45fb3732-5acf-4757-acbf-54a401804597" //correcting for entry error
	
	//29-08-22 (DL), missing stand
	replace stand = 16 if pid == 7729 & stand == .
	replace stand = 17 if pid == 1757 & stand == .
	*Correcting for entry error in pid (NL)
	replace pid=1338 if key=="uuid:f26e2cbc-0bd0-4fab-b1b1-f10cc9441a72"
	replace d_treatment =0 if key=="uuid:f26e2cbc-0bd0-4fab-b1b1-f10cc9441a72"
	
	//02-09-2022 (NL), wrongly sent form
	drop if key=="uuid:96640a78-b422-4712-b02e-9cd2030ab997"
	
	//03-09-2022 (LC) PID with wrong stand
	replace stand = 15 if inlist(pid, 1514, 1520, 1554)
	
	//08-09-2022 (LC) PID with wrong stand	
	replace stand = 12 if inlist(pid, 1216, 1226, 1245, 1246, 1276, 1283)
	replace stand = 16 if inlist(pid, 7729)
	replace stand = 17 if inlist(pid, 1789)
	
	// 10-09-2022 (LC)
	replace arrival_time = tc(7:38) if key == "uuid:fe3b15c2-4d9c-46e4-b5e3-54221ac9b104"
	
	replace launchset = 16 if inlist(pid, 1411, 5497)
	replace launchset = 14 if pid == 1645
	
	//12-09-2022 (NL), changing launchset based on the new timeline
	replace launchset = 17 if launchset==13 & stand==14
	replace launchset = 17 if launchset==13 & stand==15
	replace launchset = 18 if launchset==14 & stand==14
	replace launchset = 19 if launchset==14 & stand==19
	replace launchset = 20 if launchset==15 & stand==19
	
	//13-09-22 (DL), wrong stand
	replace stand = 16 if pid == 1683 & stand == 17
	
	//17-09-22 (LC) wrong launchset
	replace launchset = 15 if pid == 1818
	
	//21-09-22 (NL) wrongly entered form
	drop if key=="uuid:bf5bfc80-3ed1-479f-b8ef-76fd22117844"
	
	//24-09-22 (LC) time issue
	replace arrival_time = arrival_time - tc(9:30) if pid == 1523 &	date == td(23sep2022)
	replace arrival_time = arrival_time - tc(9:30) if pid == 1542 &	date == td(23sep2022)
	replace arrival_time = arrival_time - tc(9:30) if pid == 1550 &	date == td(22sep2022)
	replace arrival_time = arrival_time - tc(9:30) if pid == 1550 &	date == td(24sep2022)
	replace arrival_time = arrival_time - tc(9:30) if pid == 1554 &	date == td(23sep2022)
	replace arrival_time = arrival_time - tc(9:30) if pid == 1561 &	date == td(23sep2022)
	replace arrival_time = arrival_time - tc(9:30) if pid == 1562 &	date == td(23sep2022)
	replace arrival_time = arrival_time - tc(9:30) if pid == 1562 &	date == td(24sep2022)

	//01-09-22 (LC) time iissue
	replace arrival_time = arrival_time - tc(9:30) if pid == 1561 &	date == td(29sep2022)
	replace arrival_time = arrival_time - tc(9:30) if pid == 1562 &	date == td(28sep2022)
	replace arrival_time = arrival_time - tc(9:30) if pid == 1562 &	date == td(29sep2022)
	replace arrival_time = arrival_time - tc(9:30) if pid == 1580 &	date == td(26sep2022)
	replace arrival_time = arrival_time - tc(9:30) if pid == 1580 &	date == td(27sep2022)
	replace arrival_time = arrival_time - tc(9:30) if pid == 1580 &	date == td(30sep2022)
	
	//issues with the stand
	replace stand = 19 if pid == 1917 & stand == 17
	replace stand = 14 if pid == 9510 & stand == 3

* Drop if unanswered phone call or participant not available via phone 
	drop if call_pick_up==0
	drop if participant_available<=1

* If there is an in-person survey and one on the phone in the same day
	* keep attendance variable but merge in info from phone
	bys pid date: gen count = _N
	preserve
		keep if count > 1 & mode == 2 & call_pick_up == 1
		isid pid date
		tempfile phone_data
		save `phone_data'
	restore
	
	drop if count > 1 & mode == 2
	duplicates list pid date
	merge 1:1 pid date using `phone_data', update
	drop _merge count
	
* Drop monthly participants
	drop if d_treatment == . //monthly participants 

* FIXME why are we doing this? seems redundant. commenting out on 2024-04-11.
	/*
	* Merge in announcement data (DL-26-08-22)
		merge m:1 pid using "$final/04_announcement_completed_makevar.dta", keepusing(pid)
		* drop if _merge == 1
		* previously was drop if _merge == 1 & d_treatment == .
		drop if _merge == 2 // in announcement data but not phase 1 data
		drop _merge 
	*/

* Label variables 
	label var d_treatment "Treatment"

/*----------------------------------------------------*/
   /* [>   3.  Save data    <] */ 
/*----------------------------------------------------*/
	
	//added 2024-03-28
	drop subscriberid devicephonenum username duration caseid text_audit p0_alatitude p0_alongitude p0_aaltitude p0_aaccuracy note* response1*

	isid pid date
	order pid date interviewer 
	sort pid date
	
	drop if check_completion!=1 & mode == 2
	save "$temp/03_phase1_completed_cleaned.dta", replace
