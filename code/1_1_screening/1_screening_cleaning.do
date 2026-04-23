**************************************************
*Project: LD Main Study
*Purpose: Clean raw screening data (data entry errors)  
*Author: Supraja
*Last modified: 2024-03-25 (YS)
**************************************************
	
/*----------------------------------------------------*/
   /* [>   1.  Open data    <] */ 
/*----------------------------------------------------*/

	use "$raw/01_screening_named.dta", clear
	format date %td
	destring launchset, replace

/*----------------------------------------------------*/
   /* [>   2.  Clean data    <] */ 
/*----------------------------------------------------*/

	// Entry errors, 28-02-2022
	*Deleting wrongy submitted form
	drop  if interviewer=="18. Bharathi" & rid ==1108 & key=="uuid:c54b1d96-edd0-41f4-9e24-cc54757e89e6"
	
	* Correcting for completion status
	replace check_completion=0 if key=="uuid:75f07299-87c3-40dc-9af4-0a4ffe6783ec"
	replace check_reason_incomplete=2 if key=="uuid:75f07299-87c3-40dc-9af4-0a4ffe6783ec"
	
	replace check_completion=0 if key=="uuid:ebfb5a30-57b9-4e3f-8fa9-26023a0a473d"
	replace check_reason_incomplete=2 if key=="uuid:ebfb5a30-57b9-4e3f-8fa9-26023a0a473d"
	
	* Correcting for wrongly entered commute time
	replace ss_timetakenhrs=0 if key=="uuid:f4fe32c7-929f-4cec-a4eb-d73905aafade"
	replace ss_timetakenmins=10 if key=="uuid:f4fe32c7-929f-4cec-a4eb-d73905aafade"
	
	//Entry errors, 01-03-2022
	replace rid = 3315 if interviewer=="8. Avinash" & key =="uuid:55f4cdef-422d-40a7-bfcf-299f4e4b1e46"
	replace launchset = 1 if rid ==3315
	
	*practise survey submitted 
	drop if rid ==211 & key =="uuid:f4e6ae63-d031-4e4d-a2af-89f6d1e51c40"
	
	//Errors, 02-03-2022
	*Correcting name entered
	//replace ss1="Ramachandran" if rid==5204 & key=="uuid:9bc767ed-b325-41d2-935d-ec7eb2fad9af"
	//replace ss1_1="" if rid==5204 & key=="uuid:9bc767ed-b325-41d2-935d-ec7eb2fad9af"
	
	*Encoding 998 in area 	
	local area Adambakkam Adampakkam Addambakkam Adhambakkam Adhampakkam
	foreach area in `area'{
	replace ss_dem_stay=99 if ss_dem_stay_others=="`area'"
	replace ss_dem_stay_others="" if ss_dem_stay_others=="`area'"
	}
	replace ss_dem_stay=100 if ss_dem_stay_others=="Drama nagar"
	replace ss_dem_stay=101 if ss_dem_stay_others=="Poonmalie"
	
	local area Pulithivakkam Puluthivakkam
	foreach area in `area'{
	replace ss_dem_stay =102 if ss_dem_stay_others=="`area'"
	replace ss_dem_stay_others="" if ss_dem_stay_others=="`area'"
	}
	
	replace ss_dem_stay =103 if ss_dem_stay_others=="Marina Beach"
	replace ss_dem_stay_others="" if ss_dem_stay_others=="Marina Beach"
	replace ss_dem_stay =103 if ss_dem_stay_others=="Marina beach"	
	replace ss_dem_stay_others="" if ss_dem_stay_others=="Marina beach"
	replace ss_dem_stay =103 if ss_dem_stay_others=="Beach"	
	replace ss_dem_stay_others="" if ss_dem_stay_others=="Beach"
	replace ss_dem_stay =103 if ss_dem_stay_others=="Beach near light house"
	replace ss_dem_stay_others="" if ss_dem_stay_others=="Beach near light house"
	replace ss_dem_stay =103 if ss_dem_stay_others=="Maina Beach"
	replace ss_dem_stay_others="" if ss_dem_stay_others=="Maina Beach"
	replace ss_dem_stay =103 if ss_dem_stay_others=="Light house"
	replace ss_dem_stay_others="" if ss_dem_stay_others=="Light house"
	replace ss_dem_stay =104 if ss_dem_stay_others=="Manadi"
	replace ss_dem_stay_others="" if ss_dem_stay_others=="Manadi"
	replace ss_dem_stay =104 if ss_dem_stay_others=="Manadi"
	replace ss_dem_stay_others="" if ss_dem_stay_others=="Manadi"
	replace ss_dem_stay =105 if ss_dem_stay_others=="Guduvancheri"
	replace ss_dem_stay_others="" if ss_dem_stay_others=="Guduvancheri"
	replace ss_dem_stay=106 if ss_dem_stay_others=="R A puram" | ss_dem_stay_others=="RA puram"
	replace ss_dem_stay_others="" if ss_dem_stay_others=="R A puram" | ss_dem_stay_others=="RA puram"
	replace ss_dem_stay =105 if ss_dem_stay_others=="Arakonam" | ss_dem_stay_others=="Arakkonam"
	replace ss_dem_stay_others="" if ss_dem_stay_others=="Arakonam" | ss_dem_stay_others=="Arakkonam"
	
	*Encoding 998 in house type
	replace ss_dem_housetype= 5 if ss_dem_housetype_others=="Coconut tree olai house"
	replace ss_dem_housetype_others = "" if ss_dem_housetype_others=="Coconut tree olai house"
	
	/*Encoding 998 in profession
	replace ss_profession_nonconst="31" if ss_profession_nonconst_others=="Painter"
	replace ss_profession_nonconst="15" if ss_profession_nonconst_others=="Metro Water" | ss_profession_nonconst_others=="Metro water" ///
	| ss_profession_nonconst_others=="Metro water connection work" | ss_profession_nonconst_others=="Metro water work"
	replace ss_profession_nonconst_others="" if ss_profession_nonconst_others=="Metro Water" | ss_profession_nonconst_others=="Metro water" ///
	| ss_profession_nonconst_others=="Metro water connection work" | ss_profession_nonconst_others=="Metro water work"
	replace ss_type="15" if ss_type_others=="Metro Water" | ss_type_others=="Metro Water line" | ss_type_others=="Metro water work"
	replace ss_type_others ="" if ss_type_others=="Metro Water" | ss_type_others=="Metro Water line" | ss_type_others=="Metro water work"
	replace ss_type="15" if ss_type_others=="Metro connection work" 
	replace ss_type_others ="" if ss_type_others=="Metro connection work" 
	replace ss_type="2" if ss_type_others=="Fish business"
	replace ss_type_others ="" if ss_type_others=="Fish business"
	replace ss_type="17" if ss_type_others=="Housekeeping"
	replace ss_type_others ="" if ss_type_others=="Housekeeping"
	replace ss_type="15" if ss_type_others=="Metro water" 
	replace ss_type_others ="" if ss_type_others=="Metro water" 
	*/
	
	//Correcting for errors on 02-03-2022
	*Error in stand 
	replace stand=5 if stand==6 & date==td(02march2022) & interviewer=="11. Selvaraj" & rid==5215
	
	//Correcting for duplicate rid on 08-03-22
	replace rid = 1235 if key=="uuid:cddfd29e-06dd-4765-b92c-dc2bca02cc84" & rid==1233
	
	//Correcting launcset error 14-3-2022
	replace launchset=3 if date==td(14mar2022) & rid>=1119 & rid<=1442
	replace launchset=3 if date==td(16mar2022)
	
	//Correcting for entry errors in stand and interviewer names, 28-03-2022
	replace stand =8 if stand==3 & key=="uuid:11a21819-210b-4200-9c3d-f42b93d28378"
	replace interviewer="37. Bhuvaneshwari" if interviewer=="998" & (interviewer_others=="Bhuvaneshwari" | interviewer_others=="Bhuvi")
	replace stand=9 if stand==5 & key=="uuid:d352aec9-4970-4f87-a7b1-f1e962056529"
	replace interviewer="24. John" if interviewer=="998" & interviewer_others=="John"
	replace interviewer="32. Manikandan" if interviewer=="998" & (interviewer_others=="Manikanda E" | interviewer_others=="Manikandan E" | interviewer_others=="Manikandan e" | interviewer_others=="Kottur")
	
	//Correcting duplicate rid, 28-03-2022
	replace rid=6315 if rid==6301 & interviewer=="21. Surya" & key=="uuid:89c2fa1a-f1d2-4749-8f3f-c1b54c382838"
	
	//Correcting for launchset, 28-03-2022
	replace launchset=4 if date==td(28mar2022)
	
	//Stand labelling
	label define stand_lab 1 "1. Adambakam" 2 "2. Avadi" 3 "3. Aynavaram" 4 "4. Mandaveli" 5 "5. MKB" 6 "6. Korattur" 7 "7. MMDA" 8 "8. Porur" 9 "9. TVK Nagar"
	label val stand stand_lab
	
	//Correcting for duplicate RID, 29-03-2022
	replace rid=8115 if rid==8114 & date==td(29mar2022) & key=="uuid:7f1f00b6-34e6-4803-9369-498d9e96cdd3"
	
	//Correcting for entry error, 29-03-2022
	replace check_completion=0 if check_completion==1 & date==td(29mar2022) & rid==9217
 	
	//Correcting duplicate RID 30-03-2022
	replace rid=7339 if rid==7338 & date==td(30mar2022) & key=="uuid:71dbf00a-eed5-4dd8-ae16-cd6e72d0ec4f"
	replace rid=8529 if rid==8513 & date==td(30mar2022) & key=="uuid:bd164804-6765-449d-8203-ce364eda41f9"
	
	//Correcting for wrongly entered name , 31-03-2022
	
	//correcting for wrongly entered rid
	replace rid = 7310 if rid==7010  & key=="uuid:fb17c508-0d51-4bff-a9a0-6c866623aa95"
	replace rid = 7311 if rid==7011  & key=="uuid:bc2a3951-66f7-46a8-8cbd-dc89bf891a89"
	replace rid = 7312 if rid== 7012 & key=="uuid:109ed836-7eaf-449c-9afc-f1c672030c41"
	replace rid = 7313 if rid== 7013 & key=="uuid:0bffd092-1ba4-4bb8-8c3a-fb342ef86ee0"
	
 	//rid duplicate correction, 04-04-2022
	replace rid=8539 if rid==8529 & interviewer=="40. Anupriya" & date==td(04apr2022) & key=="uuid:c6041e77-1074-48e2-b182-129bffecd7a8"
	replace launchset=5 if rid==8539 
	
	//rid duplicate, 07-04-2022
	replace rid=8541 if rid==8539 & interviewer=="40. Anupriya" & date==td(06apr2022) & key=="uuid:90569f7d-4652-4593-b650-c62cc77d673f"
	
	//09-05-22 changing stand for two rids 10310 and 10501
	replace stand = 10 if (rid == 10310 | rid == 10501) & date == td(09may2022)
	
	//11-05-22 changing stand for rid 10341
	replace stand = 10 if rid == 10341 & date == td(11may2022)
	
	//replace batch = 1 for first batch rid in poonamallee
	replace batch = 1 if rid == 10430
	replace date = td(17may2022) if rid == 10430
	
	//replace batch = 2 for second batch rid in poonamallee
	replace batch = 2 if rid == 10350
	
	//Correcting for duplicate rid on 18-05-22
	replace rid = 10257 if key=="uuid:c75bcb59-be6e-4916-ad1c-a70a922a1568" & rid==10251
	
	//replacing launchset for 16-18 may 2022
	replace launchset = 7 if date == td(16may2022) |date == td(17may2022) |date == td(18may2022) 
	
	//24-05-22 replacing rid for 32. Manikandan because he used a repeat RID
	replace rid = 11415 if rid == 1111 & interviewer == "32. Manikandan" 
	
	//30-05-22 replacing launchset for this week 30may-01jun
	replace launchset = 9 if date == td(30may2022) | date == td(31may2022) | date == td(01jun2022)
	
	//replacing stand for rid 12312 on 06jun2022
	replace stand = 12 if key == "uuid:2ae4658f-5aa0-45e0-9d4d-c2dc681adf52"
	
	//6-06-2022 (LC) assigning launchset to RIDs from 45. Subash
	replace launchset = 10 if interviewer == "45. Subash" & date == td(06jun2022) & rid > 13500 & rid < 13516
	
	//07-06-22 replacing repeat rid for nandhakumar 
	replace rid = 13421 if key == "uuid:0151639b-5d0c-4656-bbb8-fe0f478e449a"
	
	//07-06-22 assigning launchsets for RIDs from today 
	replace launchset = 10 if date == td(07jun2022) 
	
	//08-06-22 assigning launchsets for RIDs from today 
	replace launchset = 10 if date == td(08jun2022) 
	
	//cleaning stand name for a 12000s RID
	replace stand = 12 if rid == 12414
	
	//13-06-22 pre-emptively replacing launchset for this batch
	replace launchset = 11 if date == td(13jun2022) | date == td(14jun2022) | date == td(15jun2022)
	replace stand = 12 if key == "uuid:0beb9d00-d67a-4551-9fca-b10091689f1e"
	
	//14-06-22
	replace ss_timetakenhrs  = 0  if key == "uuid:03c0480f-54bd-45f4-9a44-b5f09cf8e7f4" & rid == 13124
	replace ss_timetakenmins = 15 if key == "uuid:03c0480f-54bd-45f4-9a44-b5f09cf8e7f4" & rid == 13124
	
	//15-06-22
	* stand correction
	replace stand = 12 if key == "uuid:94b8777e-c6f3-41b2-80ee-8383ee0d8db3"
	replace stand = 13 if key == "uuid:5d6feeaf-916c-4bd3-952c-86064dc6c548"
	replace stand = 13 if key == "uuid:c356dbbe-17cd-4054-b631-fe9c87105e14"

	// 20-06-22
	replace date = td(20jun2022) if key == "uuid:b1aaa793-1b3f-43df-8ac1-48428149656a"
	replace stand = 14 if inlist(rid, 14101, 14301, 14302, 14501, 14502) & date == td(20jun2022)
	drop if key == "uuid:02164abb-d4f1-4478-99ef-baa267ba430e" // 15305, it was marked as partially complete because "4. Friends did not allow him to take the survey completely"
	
	// LC Drop surveys taken at Saidapet on 20/06/22: this is because we ended up dropping this stand and move to Velachery
	// we used the same stand id and also used the same RIDs that weren't used. 
	drop if stand == 15 & date == td(20jun2022) // LC 5/7: commenting this out because there doesn't seem to be a reason for this ??
	
	// 21-06-22 
	replace stand = 15 if stand == 998 & date == td(21jun2022)
	replace stand = 15 if stand == 11 & key == "uuid:41ca6401-a27e-433d-9ee8-df76d709ca4a"

	//22-06-22 
	replace ss_timetakenmins = ss_timetakenhrs if ss_timetakenhrs > 2 & ss_timetakenhrs != . & ss_timetakenmins == 0  // for those that mins != 0 I kept the number of hours taken
	replace ss_timetakenhrs  = 0  if ss_timetakenmins == ss_timetakenhrs & ss_timetakenhrs > 2 & ss_timetakenhrs != . // for those that mins != 0 I kept the number of hours taken
	replace rid = 15519 if key == "uuid:8deeb30b-1dd6-42af-8a76-ccba1cf2e212" // rid 15515 was duplicated
	
	//27-06-22
	replace rid = 15529    if key == "uuid:7ed95fa7-f438-4482-a4d8-7f649303cb52" // rid 15519 was duplicated
	replace launchset = 13 if key == "uuid:7ed95fa7-f438-4482-a4d8-7f649303cb52" // was entered as rid 15519 that was a launchset 12
	
	//28-06-22
	replace stand = 17 if key == "uuid:84bd00fc-4605-4784-b847-e7df237ca616" //  rid 17409 entered as stand 10
	replace stand = 15 if key == "uuid:6fcbd42c-c519-4a30-8944-6a6eb772f24f" //  rid 15131 entered as stand 998
	
	//04-07-22, replacing rid entry error
	replace rid=20404 if key=="uuid:a221bbf4-5eed-4fcf-9bee-b03fa8b4c0ed"
	
	*Correcting for 998 in stand value
	replace stand=18 if stand==998 & date==td(04jul2022) & rid>18000 & rid<18999
	replace stand=19 if stand==998 & date==td(04jul2022) & rid>19000 & rid<19999
	replace stand=20 if stand==998 & date==td(04jul2022) & rid>20000 & rid<20999
	replace launchset=14 if stand==18 & date==td(04jul2022)
	replace launchset=14 if stand==19 & date==td(04jul2022)
	replace launchset=14 if stand==20 & date==td(04jul2022)
	
	//05-07-22
	replace stand=16 if stand_others=="Padappai" & date==td(05jul2022)
	replace stand=18 if stand_others=="Pammal" & date==td(05jul2022)
	replace stand=20 if stand_others=="Sholinganallur" & date==td(05jul2022)
	
	//06-07-2022(NL)
	replace stand=16 if stand_others=="Padappai" & date==td(06jul2022)

	//07-07-2022
	replace batch =1 if key == "uuid:ed5b5189-7119-4dfd-9c43-74c8b11a9e45" // rid 19415
	
	//11-07-2022
	replace batch = 2      if date == td(11jul2022) & inlist(stand, 18, 19, 20)
	replace launchset = 15 if date == td(11jul2022) & inlist(stand, 18, 19, 20) & batch == 2
	
	//12-07-2022
	replace batch = 2 if inlist(rid, 20330, 18435, 19242) // were entered as batch 1

	
	replace batch = 2 if inlist(rid, 19426,19427,19428,19429,19430,19431) & interviewer == "44. Krishnan" & date == td(14jul2022)
	
	//18-07-2022
	replace batch = 3 if key == "uuid:5898bb1e-bab7-4737-a09d-90ba8b4d6fb3" // RID 17552
	
	//19-07-2022
	replace rid = 17467 if key == "uuid:29abe196-0622-476c-ac7f-508d2dad113d" // RID 17462 was duplicated
	
	//20-07-2022
	replace rid =  17479 if key == "uuid:9f7500f0-c60a-4cdd-9722-a17dc7242b65" // RID 17447 was duplicated

	* Drop dropped stands 
	drop if inlist(stand, ${droplist}) //DL 1/7/22, defined in master dofile
		
/*----------------------------------------------------*/
   /* [>   3.  Save data    <] */ 
/*----------------------------------------------------*/

	sort date interviewer rid
	order rid date interviewer 
	isid rid
	save "$temp/02_screening_cleaned.dta", replace
	tab check_completion, m
	/*

	  Z0. Has the survey been |
	               completed? |      Freq.     Percent        Cum.
	--------------------------+-----------------------------------
	                    0. No |         24        1.37        1.37
	                   1. Yes |      1,722       98.40       99.77
	999. Partially Incomplete |          4        0.23      100.00
	--------------------------+-----------------------------------
	                    Total |      1,750      100.00
	*/
	

	* Only keep completed surveys 
	keep if check_completion==1
	save "$temp/03_screening_completed_cleaned.dta", replace



	
	


	
	
