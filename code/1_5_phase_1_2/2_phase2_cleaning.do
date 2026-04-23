**************************************************
*Project: LD Main Study
*Purpose: Phase1 Cleaning  
*Author: Supraja
*Notes: 10-05-22 (AD) Changed the phase1_cleaning code to fit phase 2
*Last modified: 2024-04-02 (YS)
*************************************************

/*----------------------------------------------------------*/
/* [>   1.  Open data    <] */ 
/*----------------------------------------------------------*/

	use "$raw/01_phase2_named", clear
	format date %td

/*----------------------------------------------------*/
   /* [>   2.  Clean data    <] */ 
/*----------------------------------------------------*/	


* Clean up arrival time variable
	gen arrival_time_1 = Clock(arrival_time, "hms")
	format arrival_time_1 %tCHH:MM
	rename arrival_time arrival_time_string
	rename arrival_time_1 arrival_time
	format arrival_time %tCHH:MM

* Manual corrections 

	drop if inlist(stand, ${droplist}) //DL 1/7/22, defined in master dofile

	// 13-05-2022
	drop if key == "uuid:a48ffd7a-f915-4944-bca3-78d9ff56e45c" // (incomplete) phone survey but participant already surveyed on that day

	// 14-05-2022
	drop if key == "uuid:7e12f2c1-5190-486b-a655-c84fbc0ef862" // this was a Phase 1 PID still
	
	//16-05-2022, dropping because of duplicate entry to correct for prefill error
	drop if pid==544 & key=="uuid:a67ac575-038c-433d-bd2a-ca31bc020528"
	
	//changing the time for ananthan's tab, across multiple dates
	replace arrival_time= arrival_time- tC(09:30) if interviewer=="23. Ananthan" & date==td(09may2022) & arrival_time>tc(10:00) & mode==1
	replace arrival_time= arrival_time- tC(09:30) if interviewer=="23. Ananthan" & date==td(10may2022) & arrival_time>tc(10:00) & mode==1
	replace arrival_time= arrival_time- tC(09:30) if interviewer=="23. Ananthan" & date==td(11may2022) & arrival_time>tc(10:00) & mode==1
	replace arrival_time= arrival_time- tC(09:30) if interviewer=="23. Ananthan" & date==td(12may2022) & arrival_time>tc(10:00) & mode==1
	replace arrival_time= arrival_time- tC(09:30) if interviewer=="23. Ananthan" & date==td(13may2022) & arrival_time>tc(10:00) & mode==1
	replace arrival_time= arrival_time- tC(09:30) if interviewer=="23. Ananthan" & date==td(14may2022) & arrival_time>tc(10:00) & mode==1
	replace arrival_time= arrival_time- tC(09:30) if interviewer=="23. Ananthan" & date==td(16may2022) & arrival_time>tc(10:00) & mode==1
	
	//dropping repeat obs for 196 on 16 may 2022 - something may be wrong with this surveyor's tablet
	drop if pid == 196  & key == "uuid:cd1b2149-7eb3-4418-93ea-63720e1a64a2"
	
	//19-05-2022, entered wrong date
	replace date = td(19may2022) if key == "uuid:407ab0bf-5308-4f2f-896a-7fb8682f718e"
	
	//21-05-22 corrections for ananthan's tab
	replace arrival_time= arrival_time- tC(09:30) if interviewer=="23. Ananthan" & date==td(17may2022) & arrival_time>tc(10:00) & mode==1
	replace arrival_time= arrival_time- tC(09:30) if interviewer=="23. Ananthan" & date==td(18may2022) & arrival_time>tc(10:00) & mode==1
	replace arrival_time= arrival_time- tC(09:30) if interviewer=="23. Ananthan" & date==td(19may2022) & arrival_time>tc(10:00) & mode==1
	replace arrival_time= arrival_time- tC(09:30) if interviewer=="23. Ananthan" & date==td(20may2022) & arrival_time>tc(10:00) & mode==1
	replace arrival_time= arrival_time- tC(09:30) if interviewer=="23. Ananthan" & date==td(21may2022) & arrival_time>tc(10:00) & mode==1
	
	//23-05-22 ananthan's tab
	replace arrival_time= arrival_time- tC(09:30) if interviewer=="23. Ananthan" & date==td(23may2022) & arrival_time>tc(10:00) & mode==1
	
	//23-05-22 dropping repeat observations for 509 & 566 -- I checked with the surveyors (AD) 
	drop if pid == 509 & date == td(23may2022) & recall_days == 1
	drop if pid == 566 & date == td(23may2022) & recall_days == 1
	
	//24-05-22 ananthan's tab
	replace arrival_time= arrival_time- tC(09:30) if interviewer=="23. Ananthan" & date==td(24may2022) & arrival_time>tc(10:00) & mode==1
	replace arrival_time = tc(07:51) if interviewer == "8. Avinash" & date == td(24may2022) & pid == 328
	
	//24-05-22 ananthan's tab
	replace arrival_time= arrival_time- tC(09:30) if interviewer=="23. Ananthan" & date==td(25may2022) & arrival_time>tc(10:00) & mode==1
	
	//26-05-22 ananthan's tab
	replace arrival_time= arrival_time- tC(09:30) if interviewer=="23. Ananthan" & date==td(26may2022) & arrival_time>tc(10:00) & mode==1
	
	//27-05-22 ananthan's tab
	replace arrival_time= arrival_time- tC(09:30) if interviewer=="23. Ananthan" & date==td(27may2022) & arrival_time>tc(10:00) & mode==1
	
	//27-05-22 cleaning date for 2149
	replace date = td(27may2022) if pid == 2149 & date == td(31may2022)
	
	//28-05-22 ananthan's tab
	replace arrival_time= arrival_time- tC(09:30) if interviewer=="23. Ananthan" & date==td(28may2022) & arrival_time>tc(10:00) & mode==1
	replace arrival_time= tC(5:45) if pid == 511 & date == td(28may2022) & arrival_time>tc(10:00) & mode==1
	
	//30-05-22 ananthan's tab
	replace arrival_time= arrival_time- tC(09:30) if interviewer=="23. Ananthan" & date==td(30may2022) & arrival_time>tc(10:00) & mode==1
	
	//31-05-22 ananthan's tab
	replace arrival_time= arrival_time- tC(09:30) if interviewer=="23. Ananthan" & date==td(31may2022) & arrival_time>tc(10:00) & mode==1
	
	//01-06-22 ananthan's tab
	replace arrival_time= arrival_time- tC(09:30) if interviewer=="23. Ananthan" & date==td(01jun2022) & arrival_time>tc(10:00) & mode==1

	//30-05-22 (LC) monthly PID 
	drop if pid == 502 & date == td(19may2022)
	
	//06-06-22 ananthan's tab
	replace arrival_time= arrival_time- tC(09:30) if interviewer=="23. Ananthan" & date==td(06jun2022) & arrival_time>tc(10:00) & mode==1
	
	//07-06-22  ananthan's tab
	replace arrival_time= arrival_time- tC(09:30) if interviewer=="23. Ananthan" & date==td(07jun2022) & arrival_time>tc(10:00) & mode==1
	
	//23-06-22 Correcting for wrongly entered stand
	replace stand=5 if key=="uuid:fbc68485-8f91-4de4-bfb8-b22c7e71e226"
	
	//05-07-22 
	replace stand = 3 if key == "uuid:20969c49-da73-423e-a0c8-7abc1caee693" // PID 350, entered as stand 14
	//17/18-06-22 There was an issue in the survey because mode == 1 (in person) was dropped
	
	replace mode = 1 if inlist(key, "uuid:044afd55-5b7c-40f5-bfe2-54cd45e98542")
	replace mode = 1 if inlist(key, "uuid:04baec66-55fe-4b1e-b13e-f518a526be84" , "uuid:055fb027-be43-4ab4-99c1-137b3bf5256a")
	replace mode = 1 if inlist(key, "uuid:070be47f-0339-4b93-b9a4-334c1b26e0a0" , "uuid:0a83da0e-e33c-42b5-ae1c-5e0f45d6e1fd")
	replace mode = 1 if inlist(key, "uuid:0ba27619-fb9b-4e6f-b113-15d89677525d" , "uuid:0ba425f0-6e83-41f4-9ffc-9640338489a9")
	replace mode = 1 if inlist(key, "uuid:0eb32b36-ed30-4df9-9508-cffaf99aa81a" , "uuid:15ff75e2-49ec-4b11-8522-36933f8f77a5")
	replace mode = 1 if inlist(key, "uuid:1c019fae-e139-449d-820e-c8d38216c1d4" , "uuid:1dc95cd8-6b07-4132-9a41-4cae8f3324dd" )
	replace mode = 1 if inlist(key, "uuid:2a3ccda7-8c4b-4b74-a8c8-9cb7a47fa275" , "uuid:2d74dde0-e2bc-4eb2-9bd3-998d33dab539" )
	replace mode = 1 if inlist(key, "uuid:2fbe82a3-9457-4458-aa27-d5910541a916" , "uuid:3344a357-b0c8-45cb-851f-be42725ca3f7" )
	replace mode = 1 if inlist(key, "uuid:3410fc96-7e50-4531-bccd-00c1cb721b99" , "uuid:3c8c9188-3978-41e5-9ba4-0f4ecacb61b2" )
	replace mode = 1 if inlist(key, "uuid:3d6b1ef5-9a43-47b7-8845-76f05c4b6d33" , "uuid:40628dbf-139c-4182-bd54-f0d7ab4169d6" )
    replace mode = 1 if inlist(key, "uuid:408d2a55-f832-4cfe-9a83-3855e504097f" , "uuid:427b0ee5-b6a8-471c-ac83-5385e27916e3" )
	replace mode = 1 if inlist(key, "uuid:42cabb3b-1dfe-47a0-b66b-67b3e43b0820" , "uuid:4727943e-5a33-498c-b58b-99ef951a7d9d" )
	replace mode = 1 if inlist(key, "uuid:47fd10f6-2f99-4ed4-8392-aff6ac4c36e2" , "uuid:4c193fda-44ba-4d1c-9f6b-e21dfe6864fc" )
	replace mode = 1 if inlist(key, "uuid:568e63d6-8520-4783-997e-0cb72216ddc4" , "uuid:5d09271e-c3d1-411e-9782-a145804f87d4" )
	replace mode = 1 if inlist(key, "uuid:5d1763d8-434c-45ef-8314-aaa496e7e8de" , "uuid:625d0fea-aa20-44e1-9f16-96cb3aad13de" )
	replace mode = 1 if inlist(key, "uuid:6650b02f-1a16-40f2-a8f5-c289b17211cd" , "uuid:66b5a4ba-826d-424f-a075-c2afbdaa1184" )
	replace mode = 1 if inlist(key, "uuid:67fe4e2f-2576-49ec-b498-a25eaa75fc90" , "uuid:6f58cb26-7955-4df9-9d20-acd5fa1f3125" )
	replace mode = 1 if inlist(key, "uuid:6f5f4660-5e77-4f98-9bfd-31bd2ae2048f" , "uuid:70ea4962-93d7-47c4-9a9b-fb3f853abba9" )
	replace mode = 1 if inlist(key, "uuid:713edd15-19ef-413b-aa78-61f274f499ba" , "uuid:7727200f-9805-4a71-ab34-f248478ed46c" )
	replace mode = 1 if inlist(key,	"uuid:7787cfbc-7dd3-40a7-855b-f121b7b1cfad" )
	replace mode = 1 if inlist(key,	"uuid:77c2c3d5-3c9e-405b-8b47-240b3f0e6d7c" , "uuid:7a09c015-11bf-4b91-81ff-687c5fc505ad" )
	replace mode = 1 if inlist(key,	"uuid:7b2f7e7a-1a91-44fc-9c6b-263d59737eba" , "uuid:7e3df1a4-33bb-484c-9f68-f40bbc83df18" )
	replace mode = 1 if inlist(key,	"uuid:7e4f02b3-3c8c-4d96-98ed-4d858d7248db" , "uuid:7f5fa3cb-8fc9-4717-8877-d0931100bc71" )
	replace mode = 1 if inlist(key,	"uuid:81bff5d2-befd-40e3-b0bd-4155189a8ed9" , "uuid:835e5fd5-5ebd-4a1b-ba47-e725aec78e53" )
	replace mode = 1 if inlist(key,	"uuid:83d65472-5ef6-47e8-8a44-51e439718d68" , "uuid:873a1da8-c281-4301-a271-71b3de66b073" )
	replace mode = 1 if inlist(key,	"uuid:8818d4fd-339d-4ae1-b775-a0646dba68f5" , "uuid:8bb6c333-3266-46b8-84d6-2db192f72a2a" )
	replace mode = 1 if inlist(key,	"uuid:8be16b33-ff72-4322-a5d8-1dd0a87e6443" , "uuid:94b5567e-2eea-4a26-8d95-db050729700a" )
	replace mode = 1 if inlist(key,	"uuid:98c78ee2-7d34-4d3a-a05a-7ba6fe4ede26" , "uuid:9a8aa32e-4292-4349-8c70-0c6d749ce000" )
	replace mode = 1 if inlist(key,	"uuid:9bf069fb-b2db-4c8b-8aba-5f2d6d8d43c7" , "uuid:9c8e7eae-d2b6-4dc7-9d0e-8e7a960a8a57" )
	replace mode = 1 if inlist(key,	"uuid:9e9992ae-233e-469d-9dd5-a5dccbd29847" , "uuid:9f8f1714-e155-4502-965e-f22762bf7c37" )
	replace mode = 1 if inlist(key,	"uuid:a0f202a4-0b94-477f-a399-294a2cfab097" )
	replace mode = 1 if inlist(key,	"uuid:b517f7ce-9e54-422e-ad28-8de01afaf41d" , "uuid:b78a05b2-00af-4634-ae7b-6f40ab109760" )
	replace mode = 1 if inlist(key,	"uuid:b78c00dc-ebf2-4723-9b04-82fd47bcc71d" , "uuid:b81ce951-073e-4fe3-af23-787f73e2074c" )
	replace mode = 1 if inlist(key,	"uuid:bdc0c0ab-6d7e-4c20-8371-af2f3ec6bad8" , "uuid:c887d111-cf5a-48e0-bd4a-d67499fa4c65" )
	replace mode = 1 if inlist(key,	"uuid:cad83970-6acc-42b5-a9f0-be74b906ef0a" , "uuid:cf5cae3b-625b-4878-8ba0-78343f20c0ef" )
	replace mode = 1 if inlist(key,	"uuid:d847a1ff-13a0-41aa-bdb3-21267fcc677c" , "uuid:e151219c-077d-47a0-b333-97424864b930" )
	replace mode = 1 if inlist(key,	"uuid:e5c67ee6-286c-4ba7-aedb-4b24f2acd2b9" , "uuid:e6bbe6f2-7792-4de6-9a4e-2ff61a69c8df" )
	replace mode = 1 if inlist(key,	"uuid:e7a8ab00-d9a5-4ce8-8687-a018b6d72076" )
	replace mode = 1 if inlist(key,	"uuid:eb7fc98f-ac2c-444c-bb1d-94fa29c177ca" , "uuid:ec24885f-0600-4dfb-b8e6-a7b98f0cf573" )
	replace mode = 1 if inlist(key,	"uuid:f16fd294-59fb-4d2a-ad18-1f4eef5ec60f" , "uuid:f87892c2-4f72-4528-99c2-613dd59ec63c" )
	replace mode = 1 if inlist(key,	"uuid:f9b8d590-0133-4b52-b6f2-1496b6820047" , "uuid:fe7c8c13-4ebd-4b78-8bff-8dafae70853a" )
	
	replace mode = 1 if inlist(key, "uuid:067ae4de-cecd-4b8d-b5fc-5d2cbf2eade9")
	replace mode = 1 if inlist(key, "uuid:08789116-307e-4d1f-acd3-53517e36997c" , "uuid:08c6205f-1ff6-48a4-93d7-30d2973238fd" )
	replace mode = 1 if inlist(key, "uuid:092126a2-e224-4de1-85a1-ceff328afb4e" , "uuid:0a6adc4a-1cf2-46a9-94d3-499cad100a52" )
	replace mode = 1 if inlist(key, "uuid:0b5908c2-ddf0-4bf4-be44-2ab80bad91a4" , "uuid:0dbb683b-72c7-464c-b462-4dc86b6245d3" )
	replace mode = 1 if inlist(key, "uuid:0dd4aa3a-d426-40c8-8544-f812301749d0" , "uuid:15c71ea3-68f9-4684-a03d-f8c3cb1d4591" )
	replace mode = 1 if inlist(key, "uuid:16280b95-b9d7-4b56-9433-abbc2fd3c5cc" , "uuid:18175d54-8fed-4553-b8d3-0f545be2907a" )
	replace mode = 1 if inlist(key, "uuid:18f08067-6a3a-48e8-bfd0-360df719c203" , "uuid:1901d0df-d172-45a3-8355-4a4f866bf6d8" )
	replace mode = 1 if inlist(key, "uuid:1ec1ced0-1674-41ab-badd-458f5b381085" , "uuid:1ff90702-0d21-4536-a5ab-25c24e88469c" )
	replace mode = 1 if inlist(key, "uuid:249910ae-ec0b-4f94-9645-aa1226625320" , "uuid:2b190735-d292-4ed7-8f70-677cd6a74a1a" )
	replace mode = 1 if inlist(key, "uuid:30158c81-4d9f-4a84-9de1-1dade53f29b5" , "uuid:306e65fa-e60e-4b42-87fb-ea16a294b7b8" )
	replace mode = 1 if inlist(key, "uuid:30c08545-12fa-45b5-b408-6a5bf00855e1" , "uuid:311f5ab1-b2cf-4850-87f5-b3824f092fe4" )
	replace mode = 1 if inlist(key, "uuid:34f6844d-9abd-41a3-aa58-d85df64bb33f" , "uuid:359cf28a-d434-4532-868a-b8ca9332a5b6" )
	replace mode = 1 if inlist(key, "uuid:4073f311-0638-4357-8f2b-422a7334cf99" , "uuid:41d66fd2-2bca-44ea-9e62-3471bd116735" )
	replace mode = 1 if inlist(key, "uuid:4331ffa9-c279-4589-978b-180d397c3fa4" , "uuid:45bd7b13-e9fc-424b-afe1-edd6d971849c" )
	replace mode = 1 if inlist(key, "uuid:49b794f3-9800-4102-a2ca-9936642e95ff" , "uuid:4d1b97c2-1274-45e9-8470-46356bfa48df" )
	replace mode = 1 if inlist(key, "uuid:50957f97-7b1b-46ec-8b10-3eb67f3e7d7e" , "uuid:539ac202-a736-4e43-8e19-d2efb6a48a3c" )
	replace mode = 1 if inlist(key, "uuid:550a69bd-91d7-47ff-9638-78a4df21f78d" , "uuid:55a94ce4-91ef-4218-bc9d-6cbbfc5a8596" )
	replace mode = 1 if inlist(key, "uuid:57cb5987-00d9-4e4d-886a-73fab8e8134d" , "uuid:5b1c825e-8934-48e4-b7a7-a01b432b57ab" )
	replace mode = 1 if inlist(key, "uuid:5c470fef-ddc9-42d9-9f2a-065d26e4beac" , "uuid:635784c6-7b2c-4dfc-969e-ecfe37e21a8c" )
	replace mode = 1 if inlist(key, "uuid:669c02f5-c939-4331-8324-9b3934c22dd1" , "uuid:69709424-adb4-4cb6-a931-3af6d37f801a" )
	replace mode = 1 if inlist(key, "uuid:69979dca-b6a3-4405-89cd-9d23385b1fc5" , "uuid:6e9830fc-f4db-4796-b3ba-642b30780174" )
	replace mode = 1 if inlist(key, "uuid:6f47c1c8-c389-4459-9468-f77c075356d5" , "uuid:7114a944-df27-442d-9cc0-5530d428c445" )
	replace mode = 1 if inlist(key, "uuid:7131af8d-244d-4eaa-9e2b-3c5dc113d159" , "uuid:734b6d87-1243-46fd-b1b3-58c290aa72b8" )
	replace mode = 1 if inlist(key, "uuid:741a9ff7-2f3d-4d44-919f-fdf891195d55" , "uuid:745f6471-e94e-4f0d-b9b9-e175312eaf9b" )
	replace mode = 1 if inlist(key, "uuid:769e7a4b-3ce2-4a1e-87a7-251fa13f9a83" , "uuid:7d36ceea-37a6-4696-975b-cd96c55f32b2" )
	replace mode = 1 if inlist(key, "uuid:849f38bd-3e69-4b22-92ff-6eb9e2d0093b" , "uuid:8d276ce8-dc34-4712-b2a7-dd2d87fb37f3" )
	replace mode = 1 if inlist(key, "uuid:8eee652a-7685-4531-a6ab-1b0b7c769cbd" , "uuid:9388499a-8c32-4791-8dac-95038653921d" )
	replace mode = 1 if inlist(key, "uuid:9493d2ac-b6d9-4e0e-86a0-6d18608bdc15" )
	replace mode = 1 if inlist(key, "uuid:993f7c5c-7732-4f08-801d-cba7f7ab0910" , "uuid:9aed8c30-debe-4d37-a530-e2e7454ff754" )
	replace mode = 1 if inlist(key, "uuid:9fc441d6-3dae-4f3a-a295-b3d797eec184" , "uuid:a0c2f1b1-1efd-4cf3-83e1-14bb328b8358" )
	replace mode = 1 if inlist(key, "uuid:a43d90a2-0f59-498a-8bf3-dd3a6acf6e31" , "uuid:a5c817fb-5268-43b4-a3e2-ffcdbf9c2d2e" )
	replace mode = 1 if inlist(key, "uuid:a5f5821b-8e5f-4325-8dcd-e4ea554e4164" , "uuid:aa34e022-e1c2-457c-a18e-814fd2e9121a" )
	replace mode = 1 if inlist(key, "uuid:b524e769-0345-4977-9b33-8e66de80dca3" , "uuid:b962aefc-bdb3-4106-b1a9-16c010e4bacd" )
	replace mode = 1 if inlist(key, "uuid:c36f69b2-6cb8-4856-b092-7bb7585ee846" , "uuid:c43c4f3a-3b74-4e7e-ba45-8ddccb2dd9e0" )
	replace mode = 1 if inlist(key, "uuid:c64df5d5-a8f0-4d8c-9bad-310b003410c4" , "uuid:cc416357-449d-4786-8598-acce9d5e0e6e" )
	replace mode = 1 if inlist(key, "uuid:cd17e4d7-16ab-4578-8a34-a37d8a64ef19" , "uuid:cd36d00a-3406-4a0d-a5e0-63e3622028ad" )
	replace mode = 1 if inlist(key, "uuid:cd6584f8-ce34-4f9c-8801-950105a7c1e7" , "uuid:ce7ea7ac-d50a-474b-a5c3-e83501aa7385" )
	replace mode = 1 if inlist(key, "uuid:d7edfa8b-deb2-49cd-8c2b-810ad7506785" )
	replace mode = 1 if inlist(key, "uuid:db0318ba-9113-42f9-bafe-bb845aa55b0b" , "uuid:dd5a2f4e-36ad-44de-b654-2e9093b5aa42" )
	replace mode = 1 if inlist(key, "uuid:dedfabbb-cada-43d0-9cf2-5b12cdecf283" , "uuid:e0bf04e7-6524-4d62-99d2-9befa2112b94" )
	replace mode = 1 if inlist(key, "uuid:e14561a4-d520-44ff-9b00-bbbc64f21c02" , "uuid:e37308ea-7f15-404d-908a-60473fac1d18" )
	replace mode = 1 if inlist(key, "uuid:e563fcc9-4b5f-4843-a93b-d86d90bee967" , "uuid:e595653d-c141-4be8-a2f9-cfdafd86f893" )
	replace mode = 1 if inlist(key, "uuid:eacbb31c-e95e-4939-a4aa-1e8e6fc9ed34" , "uuid:ead612e4-910c-468e-b3f1-e6939d14a29c" )
	replace mode = 1 if inlist(key, "uuid:ebe69870-a44d-4f39-be47-18916ff191d6" , "uuid:ed854880-c52e-401c-96b0-20e9a4f857fb" )
	replace mode = 1 if inlist(key, "uuid:f194abca-3278-4441-a9a2-c2711b49e80f" , "uuid:f453e091-bd4b-43c7-b7da-3a11fa5d032a" )
	replace mode = 1 if inlist(key, "uuid:f4b76389-7cc6-476b-a8dc-0cf204cb517b" , "uuid:fd6e952a-0057-4f08-986e-da8665a6c89e" )
	// correct arrival time from attendance_tracker

	// 17-jun
	replace arrival_time = tc("6:34:00 AM") if pid == 118 & interviewer == "44. Krishnan"   & date == td(17jun2022)
	replace arrival_time = tc("9:27:00 AM") if pid == 125 & interviewer == "22. Karthik"    & date == td(17jun2022)
	replace arrival_time = tc("8:15:00 AM") if pid == 143 & interviewer == "44. Krishnan"   & date == td(17jun2022)
	replace arrival_time = tc("7:24:00 AM") if pid == 139 & interviewer == "22. Karthik"    & date == td(17jun2022)
	replace arrival_time = tc("6:25:00 AM") if pid == 144 & interviewer == "44. Krishnan"   & date == td(17jun2022)
	replace arrival_time = tc("7:36:00 AM") if pid == 180 & interviewer == "44. Krishnan"   & date == td(17jun2022)
    replace arrival_time = tc("7:12:00 AM") if pid == 182 & interviewer == "44. Krishnan"   & date == td(17jun2022)
	replace arrival_time = tc("8:33:00 AM") if pid == 216 & interviewer == "33. Mohan Raja" & date == td(17jun2022)
	replace arrival_time = tc("7:43:00 AM") if pid == 240 & interviewer == "33. Mohan Raja" & date == td(17jun2022)
	replace arrival_time = tc("8:30:00 AM") if pid == 2108 & interviewer == "22. Karthik"   & date == td(17jun2022)
	replace arrival_time = tc("7:24:00 AM") if pid == 2110 & interviewer == "6. Bavithra"   & date == td(17jun2022)
	replace arrival_time = tc("7:20:00 AM") if pid == 2124 & interviewer == "22. Karthik"   & date == td(17jun2022)
	replace arrival_time = tc("6:25:00 AM") if pid == 2140 & interviewer == "22. Karthik"   & date == td(17jun2022)
	replace arrival_time = tc("8:18:00 AM") if pid == 2143 & interviewer == "22. Karthik"   & date == td(17jun2022)
	replace arrival_time = tc("8:03:00 AM") if pid == 2144 & interviewer == "44. Krishnan"  & date == td(17jun2022)
	 
	// 20-jun
	drop if key == "uuid:ffd91b66-5881-4ea1-9b97-7aa8a7afe380" // entry had entry error
	
	//26-09 (NL), dropping duplicate observation
	drop if key=="uuid:97735495-7371-4484-b210-e72acadb36f5"
	drop if pid==1620 & date==td(24sep2022) & arrival_time==tc(01jan1960 07:26:58)
	
	//06-10-2022 
	drop if key=="uuid:a81e5b7a-71ae-4e7e-ac81-79c34ae9bb2b"
	
	//dropping wrongly entered survey
	drop if key=="uuid:affcb05b-d41a-428a-85b3-189bd2d2f9b8"
	drop if pid==1514 & date==td(08oct2022) & arrival_time==tc(01jan1960 15:45:16)
	
	//changing the time for ananthan's tab, across multiple dates (NL)
	replace arrival_time= arrival_time- tC(09:30) if interviewer=="23. Ananthan" & date==td(26sep2022) & arrival_time>tc(10:00) & mode==1
	replace arrival_time= arrival_time- tC(09:30) if interviewer=="23. Ananthan" & date==td(28sep2022) & arrival_time>tc(10:00) & mode==1
	replace arrival_time= arrival_time- tC(09:30) if interviewer=="23. Ananthan" & date==td(30sep2022) & arrival_time>tc(10:00) & mode==1
	replace arrival_time= arrival_time- tC(09:30) if interviewer=="23. Ananthan" & date==td(01oct2022) & arrival_time>tc(10:00) & mode==1
	replace arrival_time= arrival_time- tC(09:30) if interviewer=="23. Ananthan" & date==td(07oct2022) & arrival_time>tc(10:00) & mode==1
	replace arrival_time= arrival_time- tC(09:30) if interviewer=="23. Ananthan" & date==td(08oct2022) & arrival_time>tc(10:00) & mode==1
	replace arrival_time= arrival_time- tC(09:30) if interviewer=="23. Ananthan" & date==td(03oct2022) & arrival_time>tc(10:00) & mode==1
	
	replace arrival_time= arrival_time- tC(09:30) if interviewer=="48. Mohammad" & date==td(26sep2022) & arrival_time>tc(10:00) & mode==1
	replace arrival_time= arrival_time- tC(09:30) if interviewer=="48. Mohammad" & date==td(28sep2022) & arrival_time>tc(10:00) & mode==1
	
	//28-10 (NL), the in-person survey form was submitted late, so phone call was done as well
	drop if key=="uuid:ac06daad-a484-48c7-a49c-faa2eaf26154"
	drop if key =="uuid:a6bb330b-ba64-45e6-b6a3-5e18d56556fe"
	
	//14-11 (NL), correcting the stand entered
	replace stand=13 if pid==1304 & key=="uuid:7d9142c0-0adb-4e87-bbde-c7c6002e99b8"
	replace stand=13 if pid==1381 & key=="uuid:aee05562-f1b7-49a8-9dce-93c03c427eec"
	
	//17-12-2022 (LR), Correcting for wrongly entered stand
	replace stand=18 if pid== 1845| pid ==1823
	replace stand= 17 if pid == 1769
	


* If there is an in-person survey and one on the phone in the same day
	* keep attendance variable but merge in info from phone
	bys pid date: gen count = _N
	preserve
	   keep if count > 1 & mode == 2
	   isid pid date
		tempfile phone_data
		save `phone_data'
	restore

	drop if count > 1 & mode == 2
	duplicates list pid date
	merge 1:1 pid date using `phone_data', update
	drop _merge count

	isid pid date

	
	//12-09 (NL), dropping pids which were in phase2 since the launchset was wrong
	local date 05sep2022 06sep2022 07sep2022 08sep2022 09sep2022 10sep2022
	foreach date in `date'{
	cap drop if pid==1411 & date==td(`date')
	cap drop if pid==9505 & date==td(`date')
	}
	
	//12-10 (DL), replace launchset for 3 overlapping ones
	replace launchset = 2 if pid == 311 & launchset == 1
	replace launchset = 14 if pid == 1645 & launchset == 13
	replace launchset = 15 if pid == 1818 & launchset == 14
	
	//19-10 (DL) Wrong stand
	replace stand = 16 if pid == 7707 & key == "uuid:693fcdaa-02e7-49a4-a967-cb57bd858ce5"
	
	//25-10 (NL) ineligible pid
	drop if pid==7704
	
	//26-10 (NL)  correcting for wrongly entered date
	replace date =td(25oct2022) if key =="uuid:bacbe215-d53b-4ff4-874f-9aea4a62a2a3"

	// 28-04-24 (LC) wrong stand
	replace stand = 17 if key == "uuid:d82c9a93-2fe4-4790-8151-d8b148164c22"
	replace stand = 17 if key == "uuid:135594d3-6bee-4e27-b663-9ad4567e0012"

	// 4/21/26 (LC) wrong survey mode
	replace mode = 2 if key == "uuid:c177df8d-4045-436a-836a-edf53e7097d3"

/*----------------------------------------------------*/
   /* [>   3.  Save data    <] */ 
/*----------------------------------------------------*/

	//added 2024-04-22
	drop subscriberid devicephonenum username duration caseid text_audit p0_alatitude p0_alongitude p0_aaltitude p0_aaccuracy note* response1*

	drop if pid==1612 & interviewer==""
	
	isid pid date 
	order pid date interviewer 
	sort pid date

	
	drop if check_completion!=1 & mode == 2
	save "$temp/03_phase2_completed_cleaned.dta", replace
	
