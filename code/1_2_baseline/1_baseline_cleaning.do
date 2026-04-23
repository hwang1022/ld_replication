**************************************************
*Project: LD 
*Purpose: Baseline Cleaning  
*Author: Supraja
*Last modified: 2024-03-27 (YS)
**************************************************
		
/*----------------------------------------------------*/
   /* [>   1.  Open data    <] */ 
/*----------------------------------------------------*/


	use "$raw/01_baseline_named.dta", clear
	
/*----------------------------------------------------*/
   /* [>   2.  Clean data    <] */ 
/*----------------------------------------------------*/

	format date %td

	* Convert time to numeric 
	foreach x in bs_time_found bs_time_left_stand {
		forval i=1/7{
		cap confirm string variable `x'_`i'
			if !_rc{
				ren `x'_`i' `x'_`i'_str 
				gen double `x'_`i' = clock(`x'_`i'_str, "hms")
				format `x'_`i'  %tcHH:MM:SS
				drop `x'_`i'_str
				}
		}
	}

	*Entry errors
	//Correcting for errors on 03-03-2022
	*Correcting for completion status
	replace check_completion=0 if pid==102 & key=="uuid:f3505687-ad89-495f-8dad-c217a6245774"
	replace check_completion=0 if pid==317 & key=="uuid:6170da7a-8deb-49e3-b085-9a2b1189f36f"
	
	//Correcting for errors on 04-03-2022
	*Coding for work type others
	replace bs_work_type_1 = 15 if bs_work_type_others_1=="Metro water work"
	replace bs_work_type_1 = 15 if bs_work_type_others_1=="Metro water connection work"
	replace bs_work_type_2 = 15 if bs_work_type_others_2=="Metro water connection work"
	
	replace launchset = 1 if date==td(03mar2022)
	
	*Dropping for wrongly entered observation
	drop if pid==518 & key=="uuid:d2cc8ce4-dc1b-41ee-be7e-df80323944b1" 
	drop if pid==518 & key=="uuid:ef083577-5b25-4be7-8599-66a45ec1e141"
	
	//Correcting for errors on 05-03-2022

	//Error on 07-03-2022
	
	*Correcting for prefill issues
	replace bs_section_complete_1=1 if key=="uuid:5baf3524-7154-4208-b1fd-72086f318f1b" & pid==317
	forvalues i=3/5{
	replace bs_work_`i'=. if pid==317 & date==td(07mar2022) &key=="uuid:45a537e6-e38b-4c8d-84dc-c7085ae34954"
	replace bs_attend_sr_`i' =. if pid==317 & date==td(07mar2022) &key=="uuid:45a537e6-e38b-4c8d-84dc-c7085ae34954"
	replace bs_section_complete_`i' =. if pid==317 & date==td(07mar2022) &key=="uuid:45a537e6-e38b-4c8d-84dc-c7085ae34954"
	}
	
	//Error on 08-03-2022
	drop if pid==341 & date==td(08mar2022) & key=="uuid:6af84d0a-d1c8-4910-bcc8-3fe3921c1906" //wrongly taken survey
	
	//Error on 10-03-2022
		replace pid=137 if pid==124 & key=="uuid:66508368-c3f4-4c7e-8818-5cedb1c33c83" & date==td(10mar2022)
		replace pid =313 if date ==td(04mar2022) & key=="uuid:ee0e55ac-7e5b-4a37-900c-770e0f13c639"
		
		drop if key == "uuid:66508368-c3f4-4c7e-8818-5cedb1c33c83" | key=="uuid:1b75df9a-6a0b-46e6-b251-daeb37d4793e" | key=="uuid:d58d06e2-dada-4643-afb9-12427a00f900" |key=="uuid:1353fd21-e905-408c-974e-172dcd21b624" | key=="uuid:9cf695b8-c540-4f0d-8bcf-444192e0722d" |  key=="uuid:516c7506-785b-48a4-9545-0b076c8765c9" | key=="uuid:f98287a1-77ac-4e31-acc6-76c5adafb5e5"
	
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
	
	//23-03-2022
	*Correcting for wrongly entered date
	replace date=td(23mar2022) if date==td(24mar2022) & key=="uuid:21fb4d85-90b3-491d-baab-2e83a5daca6a" & pid==2144
	
	//for the 10th march duplicatesit mostly looks like a recall error corrected
	
	//Dropping duplicate pid
	drop if pid==2129 & key=="uuid:7e80758c-319c-4d6a-9d54-be1938968a70"

	//Dropping duplicate pid, 31-03-2022
	replace pid=808 if date==td(31mar2022) & key=="uuid:757216e7-3947-4279-a089-e5aafc551d3d"
	
	//Cleaning for stand 998 values, 31-03-2022
	replace stand=7 if p0_998 =="701" | p0_998 =="702" | p0_998 =="709" | p0_998 =="MMDA" | p0_998 =="Mmda"
	replace p0_998="" if p0_998 =="701" | p0_998 =="702" | p0_998 =="709" | p0_998 =="MMDA" | p0_998 =="Mmda"
	replace stand=6 if p0_998 =="Korattur"
	replace p0_998="" if p0_998 =="Korattur"
	replace stand=8 if p0_998 =="Porur"
	replace p0_998="" if p0_998 =="Porur"
	replace stand=9 if p0_998 =="T v k" | p0_998 =="T vk" | p0_998 =="Thiruvika Nagar" | p0_998 =="Thiruvika nagar" | p0_998 =="Tv k" | p0_998 =="Tvk" | p0_998 =="Tvk nagar"
	replace p0_998 ="" if p0_998 =="T v k" | p0_998 =="T vk" | p0_998 =="Thiruvika Nagar" | p0_998 =="Thiruvika nagar" | p0_998 =="Tv k" | p0_998 =="Tvk" | p0_998 =="Tvk nagar"
	
	//Launchset cleaning 02-04-2022
	replace launchset=4 if launchset==. & date>=td(31mar2022) & pid>=600 & pid<1000
	
	//Duplicate pid and wrongly entered pid correction, 02-04-2022
	drop if pid==846 & date==td(02apr2022) & key=="uuid:7a311cbf-fb21-4cad-b177-a0a6eb4a6d07"
	drop if pid==853 & date==td(02apr2022) & key=="uuid:8ca8f999-13b9-4de1-afec-3e1b46a0a85f"
	drop if pid==855 & date==td(02apr2022) & key=="uuid:7ba9a23c-aa6a-4b87-88f3-06dfcf794996"
	drop if pid==857 & date==td(01apr2022) & key=="uuid:071c7c8c-f60c-49d9-9ecc-bc170320158f"
	
	//Wrongly entered date, 04-04-2022
	replace date=td(04apr2022) if date==td(05apr2022) & interviewer=="40. Anupriya" & key=="uuid:df3ee4f3-a309-418d-a403-9ab5a06147c0"

	//Wrongly entered stand
	//replace stand=6 if stand==8 & interviewer=="36. Diwakar"
	
	//Wrongly entered completion
	replace check_completion=0 if check_completion==1 & date==td(06apr2022) & key=="uuid:b36f6119-16b0-44f6-a5a5-be4d2b6de0ca"
	replace check_completion=0 if check_completion==1 & date==td(06apr2022) & pid==913
	
	//Duplicate pid correction, 07-04-2022
	drop if pid==669 & bs_sttime=="8:20:47 AM" & date==td(07apr2022) & key=="uuid:08e1f14e-498f-4ff5-8171-345b60168c93"
	
	//Wrong stand correction
	replace stand=6 if pid>600 & pid<700 & stand==8
	
	//Wrong PID entry
	replace pid=813 if pid==865 & date==td(11apr2022) & & interviewer=="40. Anupriya" & key=="uuid:6b73181a-a886-4832-98c7-cb889f21aac1"
	
	// Option other is already in main list
	replace check_reason_inc_onspot = 1 if key == "uuid:de830119-268f-459b-a539-0e916fe40878"
	
	//12-05-22 cleaning stand name for 1005 & 1023
	replace stand = 10 if pid == 1005 & date == td(12may2022)
	replace stand = 10 if pid == 1023 & date == td(12may2022)
	
	// 16-05-22 (LC) wrong earnings
	replace bs_earn_1 = 850 if key == "uuid:d9588873-563c-4595-be09-37c1a4d4ca55"
	
	//19-05-22 cleaning stand name for 1060 & 1020
	replace stand = 10 if pid == 1060 & date == td(19may2022)
	replace stand = 10 if pid == 1020 & date == td(19may2022)
	
	//21-05-22 cleaning batch for 1049 - launchset 6 - CHECK IF THIS IS CORRECT
	//replace batch = 1 if pid == 1049 & launchset == 6
	
	//26-05-22 cleaning stand name for 1114
	replace stand = 11 if pid == 1114 & date == td(26may2022)
	
	//10-06-22 cleaning stand name for all PIDs today & yesterday
	replace stand = 12 if pid >= 1202 & pid <= 1289
	replace stand = 13 if pid >= 1301 & pid <= 1362
	
	//11-06-22 - LC: 1344 was entered twice : spotted in person in the AM, and then phone call in the PM
	// Temporarily replace 1344 as attended and mode == 1 in the phone call, and dropping in person survey
	replace mode = 1 if key == "uuid:cd61f1d0-985c-4fe8-bb21-9aaf672ec959"
	replace spot_time = "7:40:50 AM" if key == "uuid:cd61f1d0-985c-4fe8-bb21-9aaf672ec959"
	drop if key == "uuid:a2f2e8bd-ad1d-451a-9976-53def80193c4"
	
	//13-06-22
	drop if key == "uuid:dc75918e-242b-461c-82d0-83ec1c02a2e6" // 1337 spotted twice
	drop if key == "uuid:dcbae4f9-c6e2-4938-ada6-2b9f6c3046bc" // 1252 was called twice, the second time all recalls were already 
	
	// 15-06-22
	replace stand = 12 if pid == 1201
	
	//01-07-22 (temporarily dropping the duplicate obs) -NL
	drop if key =="uuid:3a500340-328a-4123-9419-2335af21fb1f"
	drop if key =="uuid:c361b4a0-e5c4-4f9c-9d7a-fcf750aa8218" // 1751
	drop if key =="uuid:c649da4a-578b-4ce8-bf9f-f2c59110a290" // 1559
	**** TEMP DROP!
	drop if key == "uuid:f47798c9-7c09-48a5-800c-c61363fc48ee" // 1357 entered twice, but probably two different PIDs?
	drop if key == "uuid:cd61f1d0-985c-4fe8-bb21-9aaf672ec959" // 1344 entered twice, one in person one on the phone --> think how to deal with it?
	
	// 16-06-22
	replace stand = 12 if inlist(key, "uuid:dfb23bbb-8d9a-4b65-bc55-ef213fa745e2", ///
									  "uuid:ddcf57cb-d0f8-485a-94f7-c6a1493cc498", ///
									  "uuid:5308973c-8709-4055-a614-55501c883075", ///
									  "uuid:818bc323-dee9-48d7-9a1c-479f0d16d523", ///
									  "uuid:6b889cf6-1570-444d-9b75-ef302a19cf3e", ///
									  "uuid:8b8da41c-f71d-460d-8056-3c05f7f8fd5a", ///
									  "uuid:d5ec1c00-730f-4ef8-aa50-9dbf2794765c", ///
									  "uuid:ab1bf1a8-9d30-49db-a00a-adb3d28425d6")
									  
	replace stand = 13 if inlist(key, "uuid:d715b7dc-f3f3-4b2e-b94f-c124d335e594", ///
									  "uuid:0d4e4337-e3fa-4c1d-b31d-43c6a84aceaf", ///
									  "uuid:eabe3d92-cf75-46ca-879a-085d5dd8c752", ///
									  "uuid:87a56195-3a87-4c30-b42b-c23819e9cc61", ///
									  "uuid:71f0857c-4f10-4bbd-a062-233882042655", ///
									  "uuid:9082de10-18da-4564-a187-226852443037", ///
									  "uuid:98d93ae7-c970-4d4b-b798-9b4f680318b9", ///
									  "uuid:aac97f1a-f9f9-41ce-8309-155dc6a8746e", ///
									  "uuid:10d539e4-8243-4762-b3bf-8c453c1d4fdb")
									  
									  
	// 	replace launchset = 11 if inlist( pid, 1294, 1296, 4300, 4306, 4312, 1293, 1299, 4302)  & date == td(16jun2022) 
    drop if key == "uuid:10d539e4-8243-4762-b3bf-8c453c1d4fdb" // survey entered by mistake
	
	replace pid=1355 if key =="uuid:d4fbdf68-30e3-495e-bd41-fe410acae03d" // replacing wrongly entered pid 
	
	//replace pid=1356 if key=="uuid:f47798c9-7c09-48a5-800c-c61363fc48ee"
	// 28-06-22 - PID screened in as batch 1 and launchset 10, however they went to native for a week-long holiday, so they took IC once they were back and we pushed them 1 week
	// 	replace batch = 2      if inlist(pid, 1283, 1286, 1276, 1265, 1264, 1270, 1263, 1249, 1248, 1261, 1219)
	// 	replace launchset = 11 if inlist(pid, 1283, 1286, 1276, 1265, 1264, 1270, 1263, 1249, 1248, 1261, 1219)

	// 04-07-22 (DL) missing launchsets
	replace launchset = 10 if key == "uuid:71f0857c-4f10-4bbd-a062-233882042655" & launchset == . // pid == 1365
	replace launchset = 11 if key == "uuid:eabe3d92-cf75-46ca-879a-085d5dd8c752" & launchset == . // pid == 1366
	replace launchset = 11 if key == "uuid:98d93ae7-c970-4d4b-b798-9b4f680318b9" & launchset == . // pid == 1372 
	replace launchset = 11 if key == "uuid:0d4e4337-e3fa-4c1d-b31d-43c6a84aceaf" & launchset == . // pid == 1373
	replace launchset = 11 if key == "uuid:d715b7dc-f3f3-4b2e-b94f-c124d335e594" & launchset == . // pid == 1380
	replace launchset = 11 if key == "uuid:aac97f1a-f9f9-41ce-8309-155dc6a8746e" & launchset == . // pid == 1371
	replace launchset = 11 if key == "uuid:9082de10-18da-4564-a187-226852443037" & launchset == . // pid == 1370
	replace launchset = 11 if key == "uuid:87a56195-3a87-4c30-b42b-c23819e9cc61" & launchset == . // pid == 1374
	replace launchset = 13 if key == "uuid:b8a13cca-2650-4579-80d6-de8afd604ca9" & launchset == . // pid == 17319 
	replace launchset = 13 if key == "uuid:93b3f84f-6fc1-468b-b195-a6ea102c1b7d" & launchset == . // pid == 17321
	
	//05-07-2022, (NL) correcting for wrongly entered pid
	replace pid=1414 if key=="uuid:eeb98f39-707d-486a-8b48-8c126209762f"
	replace pid=1660 if key=="uuid:b53e30b8-c29b-43de-a6f0-4dedacfc5b04"
	
	replace check_completion = 0 if key == "uuid:13152af5-0822-493a-b643-6ca16d814584" // 1469, call not picked up
	

	
	gen original_spot_time = spot_time
	generate double spot_time_1 = clock(spot_time, "hms")
	format %tcHH:MM:SS spot_time_1
	drop spot_time 
	rename spot_time_1 spot_time
	replace spot_time = spot_time - tc(09:30) if deviceid == "359981062041882"
	replace spot_time = spot_time - tc(09:30) if deviceid == "359981062055205"
	
	replace bs_notpaid_amt_due_2 = 800 if key == "uuid:282f8e2c-682c-4e41-a782-34f62d47c6e0" // pid 1531, was entered as 0
	
	//06-07-22 (DL) Missing Launchsets
	replace launchset = 10 if key == "uuid:ddcf57cb-d0f8-485a-94f7-c6a1493cc498" & launchset == . // pid == 1296
	replace launchset = 10 if key == "uuid:818bc323-dee9-48d7-9a1c-479f0d16d523" & launchset == . // pid == 4306
	replace launchset = 10 if key == "uuid:6b889cf6-1570-444d-9b75-ef302a19cf3e" & launchset == . // pid == 1294
	replace launchset = 11 if key == "uuid:5308973c-8709-4055-a614-55501c883075" & launchset == . // pid == 4300
	replace launchset = 11 if key == "uuid:dfb23bbb-8d9a-4b65-bc55-ef213fa745e2" & launchset == . // pid == 4312
	replace launchset = 11 if key == "uuid:d5ec1c00-730f-4ef8-aa50-9dbf2794765c" & launchset == . // pid == 1299
	replace launchset = 11 if key == "uuid:ab1bf1a8-9d30-49db-a00a-adb3d28425d6" & launchset == . // pid == 4302
	replace launchset = 11 if key == "uuid:8b8da41c-f71d-460d-8056-3c05f7f8fd5a" & launchset == . // pid == 1293
	replace launchset = 13 if key == "uuid:5fb85048-f088-4e9e-9005-e41389f94632" & launchset == . // pid == 17318
	
	//07-07-22 (DL) 
	//Missing Launchsets
	replace launchset = 13 if key == "uuid:44c6c6c9-3bd0-4e4b-b30b-87177297bace" & launchset == . // pid == 17321
	//stand recorded as 998 but should be 16
	replace stand = 16 if key == "uuid:a184845f-c9d0-4036-8baa-c0f6f519b27f" & stand == 998 // pid == 1605
	replace stand = 16 if key == "uuid:f841ee6a-3092-4ca7-9cc9-3c851fd2e878" & stand == 998 // pid == 1639
	replace stand = 16 if key == "uuid:a34719a7-fb86-48cf-af64-f222a589cc46" & stand == 998 // pid == 1659
	
	//08-07-22 (DL)
	//missing launchsets; there are 115 missing, so I thought it was better to change by groups
	replace launchset = 14 if stand == 14 & batch == 3 & launchset == . 
	replace launchset = 14 if stand == 16 & batch == 2 & launchset == . 
	replace launchset = 13 if stand == 17 & batch == 1 & launchset == .
	replace launchset = 14 if stand == 17 & batch == 2 & launchset == . 
	replace launchset = 14 if stand == 18 & batch == 1 & launchset == .
	replace launchset = 14 if stand == 19 & batch == 1 & launchset == .
	replace launchset = 14 if stand == 20 & batch == 1 & launchset == .
	//missing stands 
	replace stand = 16 if key == "uuid:d69efe14-d96c-4220-ba10-f0175f08c98b" & stand == 998 // pid == 1608
	replace date = td(08jul2022) if key == "uuid:c76fa6af-4d77-4da7-a74f-53db88e4e2de" // (LC) pid 1719
	
	//duplicates (TEMP DROP) LC
	drop if key == "uuid:4e3c6dbc-cf2a-4be8-947b-d54c5feb4436" // 1940 on 08/07
	drop if key == "uuid:dd4548f4-0114-4beb-a992-d9a83286724c" // 7704 on 08/07
	
	//11-07-22
	drop if key == "uuid:4e6a5fb6-cd10-4930-b899-29dc5bc8805f"  // pid 1934 called by mistake
	replace stand = 16 if key == "uuid:5cf3fc77-31a6-4eaa-a4cd-afde1148fe9a" // pid 1603, was entered as 18
	
	//12-07-22
	replace stand 	  = 17 if key == "uuid:8d1e9c55-b02c-477c-bf4b-63abd143ac47" //pid 1784, was entered  as 15
	replace launchset = 14 if key == "uuid:8d1e9c55-b02c-477c-bf4b-63abd143ac47" & launchset == . //pid 1784
	replace pid = 6848 if pid == 17321
	replace bs_earn_1 = 800 if key == "uuid:ad72bd64-788a-468e-afd8-be27ebc0df55" | key == "uuid:08fb06c9-310b-47db-8f38-2cc9f2ff529a" // pid  1757 on 4 and 5 /07
	replace bs_earn_2 = 800 if key == "uuid:ad72bd64-788a-468e-afd8-be27ebc0df55" // pid  1757 on 4/07

	// 15-07-22 (DL)
	//missing launchsets
	//replace launchset = 15 if key == "uuid:ff70a56b-94b2-4c1e-a882-dcd7edbd02bc" // pid 1962
	//replace launchset = 15 if key == "uuid:35fbd66a-2c82-4948-9db9-8f374928b2b9" // pid 1835
	//replace launchset = 15 if key == "uuid:c7a20d65-0403-47f6-870c-042027d6e7cb" // pid 1947
	
	//dropping these observations since baseline was started one day late
	drop if key=="uuid:ff70a56b-94b2-4c1e-a882-dcd7edbd02bc"
	drop if key=="uuid:35fbd66a-2c82-4948-9db9-8f374928b2b9"
	drop if key=="uuid:c7a20d65-0403-47f6-870c-042027d6e7cb"
	// 15-07-2022 (NL)
	replace pid=6802 if key=="uuid:a7913a40-579e-4628-853f-07e7b861c9b9" //wrongly entered PID
	replace check_completion = 1 if key == "uuid:f664d214-c2cf-4701-99f2-247afb34c395" // PID 6828 recall mistake
	replace stand = 17 if key == "uuid:48c1e543-6a3f-41b4-bd44-9f3263faf12f" // PID 1783 entered as stand 15
	//21-07-2022 (LC)
	drop if key == "uuid:61596666-2f7a-410b-a407-34ca72472d2b" // PID 7723 , entered same answers twice on 21/7
	
	//22-07-2022 (Dl)
	// Wrong stand number
	replace stand = 17 if pid == 6851 & stand == 15 & batch == 3
	// missing launchsets
	replace launchset = 16 if stand == 16 & batch == 3 & launchset == .
	replace launchset = 16 if stand == 17 & batch == 3 & launchset == .
	
	//22-07-2022 (NL)
	replace batch =1 if pid==515
	replace batch =1 if pid==531
	replace batch =2 if pid==164
	replace batch =1 if pid==127
	replace batch =2 if pid==174
	replace batch =1 if pid==1303
	replace batch =1 if pid==1536
	replace batch =1 if pid==1441
	replace batch =2 if pid==6837
	replace batch =1 if pid==1934
	replace batch = 2 if pid == 1683 
	replace batch = 2 if pid == 1940 
	
	//02-08-22, dropping duplicate observation (NL)
	drop if key=="uuid:63509f59-e6da-45bc-80c7-f34dcb882efa"
	replace batch = 3 if key == "uuid:00831de7-5e8d-43e1-904d-a1288f5f08a9"
	replace batch = 3 if key == "uuid:00831de7-5e8d-43e1-904d-a1288f5f08a9"
	
	drop if inlist(stand, ${droplist}) // defined in master.do
	label var launchset "Launch Set"

/*----------------------------------------------------*/
   /* [>   4.  Save data    <] */ 
/*----------------------------------------------------*/
	
	// drop irrelevant variables (2024-03-26)
	drop subscriberid devicephonenum username caseid text_audit duration note* starttime endtime stand_name_prefill

	order stand pid date interviewer 
	sort stand pid date 
	* isid pid date 
		* will not be the case as incomplete surveys are re-attempted on the phone, so there can be multiple entries for a pid-day
	save "$temp/02_baseline_cleaned.dta", replace

	tab check_completion, m 

	* Keep completed surveys and incomplete surveys conducted at the stand 
	drop if check_completion!=1 & mode==2 // still want to know that a person came to the stand even if they were not able to complete the survey
	isid pid date 
	order stand pid date interviewer batch 
	sort stand pid date 
	save "$temp/03_baseline_completed_cleaned.dta", replace
