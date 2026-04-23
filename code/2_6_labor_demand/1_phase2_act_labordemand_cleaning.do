**************************************************
*Project: LD Main Study
*Purpose: Phase 2 activity - labor demand test cleaning
*Author: Luisa
*Last modified: May_8_2025 (HW)
**************************************************

	cap program drop main
	program main
		use "$raw/01d_phase2act_labordemand_named.dta", clear
		cleaning
		save "$temp/01d_phase2act_labordemand_cleaned_v2.dta", replace
		finalizing
		sort pid date
		save "$temp/01d_phase2act_labordemand_cleaned_completed_v2.dta", replace
	end
	
*****************************************
*Codes Starts
*****************************************

	cap program drop cleaning
	program cleaning
		disp("No corrections so far")
		
		/*28-06, some pids have done labor demand twice, need to check the reason. For now dropping the first time it was taken (since they did not turn up) -NL
		drop if pid==163 & date==td(21june2022)
		drop if pid==201 & date==td(22june2022)
		drop if pid==217 & date==td(22june2022)
		drop if pid==238 & date==td(20june2022)
		drop if pid==242 & date==td(20june2022)
		drop if pid==254 & date==td(25june2022)
		drop if pid==264 & date==td(22june2022)
		drop if pid==357 & date==td(20june2022)
		drop if pid==130 & date==td(21june2022)
		drop if pid==215 & date==td(23june2022)
		drop if pid==240 & date==td(25june2022)
		*/
		
		//27-10-2022 (NL), replacing attendance date for PIDs for whom the attendance day is missing
		replace required_attendance_date ="01nov2022" if key=="uuid:07237ee3-a7d7-48c8-a317-583e52aa9314"
		replace required_attendance_date ="01nov2022" if key=="uuid:dbe9369a-0a65-4e4a-abb0-e3ab3a859a4d"
		replace required_attendance_date ="02nov2022" if key=="uuid:ac023efc-b0e7-4f63-b18c-57e8e95cb6f5"
		replace required_attendance_date ="02nov2022" if key=="uuid:f3e46334-e39d-4210-801e-38367cf46b6d"
		replace required_attendance_date ="02nov2022" if key=="uuid:53ced9a4-bd5e-4284-8716-23493463ab7b"
		replace required_attendance_date ="01nov2022" if key=="uuid:e85c5174-9a1e-422a-a3e2-9e35c70ef2f0"
		replace required_attendance_date ="28oct2022" if key=="uuid:c2763425-b803-4097-8a5e-ab42ba0dbaa6"
		replace required_attendance_date ="29oct2022" if key=="uuid:fb5d5a5b-3ba1-43ea-8797-8304e55f41e0"
		replace required_attendance_date ="31oct2022" if key=="uuid:9e4a66df-e2b3-472a-bb02-0c7c7f50b29b"
		replace required_attendance_date ="01nov2022" if key=="uuid:bdc2d69c-d6d0-4096-9222-9dc095bc9242"
		replace required_attendance_date ="29oct2022" if key=="uuid:252abbf2-c46d-4b81-8931-a6a27e7319d0"
		replace required_attendance_date ="28oct2022" if key=="uuid:ad75695e-be26-4004-8e08-c6755ad2c737"
		replace required_attendance_date ="26oct2022" if key=="uuid:226f4806-b970-4bfe-a6b7-2e5510b78618"
		replace required_attendance_date ="22oct2022" if key=="uuid:70fa619d-be7a-4f84-85b0-2d1ff8d036c7"
		replace required_attendance_date ="27oct2022" if key=="uuid:d40c224e-d635-441c-9260-cf3f417e4213"
		replace required_attendance_date ="28oct2022" if key=="uuid:581b54f6-4567-4dd3-b122-04cb37372fd3"
		replace required_attendance_date ="27oct2022" if key=="uuid:e56d2f0f-057a-481b-ac83-c068c2bf209d"
		replace required_attendance_date ="28oct2022" if key=="uuid:1a6d435b-3ad6-4b09-9ff5-0bee71031d34"
		replace required_attendance_date ="28oct2022" if key=="uuid:2b807b1a-a79c-4300-a798-a14ce535058b"
		replace required_attendance_date ="28oct2022" if key=="uuid:99d60a59-c387-4696-aedc-c0fe9bc92882"
		replace required_attendance_date ="26oct2022" if key=="uuid:8f4f7c14-6c0c-4a38-9178-c6802b50a5f9"
		replace required_attendance_date ="25oct2022" if key=="uuid:0c9ab055-5d24-42bd-85d3-0e63b7ad741b"	
		replace required_attendance_date ="25oct2022" if key=="uuid:59ddd85e-ab8f-4a57-808a-975f0f9bf67c"
		replace required_attendance_date ="28oct2022" if key=="uuid:abea0adc-2eac-4a5a-a9a0-2d7d801f6907"
		replace required_attendance_date ="29oct2022" if key=="uuid:6585bf4c-c12d-47b3-81a6-3b7f5f398571"
		replace required_attendance_date ="28oct2022" if key=="uuid:266ab288-84a7-48ac-a776-41d49b63ac30"
		replace required_attendance_date ="22oct2022" if key=="uuid:226f4806-b970-4bfe-a6b7-2e5510b78618"
		replace required_attendance_date ="04nov2022" if key=="uuid:0c46837e-f19b-459e-ab83-cc4a3e4a5c27"
		replace required_attendance_date ="07nov2022" if key=="uuid:c2dc3967-9b04-47f1-93f9-bdc0cb7d4b97"
		
		replace required_attendance_date ="05nov2022" if key=="uuid:e1e757b6-066b-436d-83cb-4341f9e452d1"
		replace required_attendance_date ="10nov2022" if key=="uuid:0244ae10-e762-4681-8765-bdada9e00ec0"
		replace required_attendance_date ="05nov2022" if key=="uuid:74445805-f715-49d2-b888-9a874b7ca2ed"
		
		
		
		replace required_attendance_date ="28nov2022" if key=="uuid:105238d7-ed5f-48d6-849f-7eb9d451accb"
		replace required_attendance_date ="01dec2022" if key=="uuid:3a6e7d31-79b5-4c8c-b80c-8c1c5c9abd28"
		
		//13-11, dropping duplicate observation (NL)
		drop if key=="uuid:b24ffd5f-cecb-4c18-842d-72888edeee15"
		
		
		//17-11 (NL), correcting for required day of attendance
		replace required_attendance_date ="19nov2022" if key=="uuid:c17341a1-2006-4b6d-99d8-c18d53ab366a"
		replace required_attendance_date ="19nov2022" if key=="uuid:a36f369f-190a-445a-8391-0428ef37b9f6"
		replace required_attendance_date ="19nov2022" if key=="uuid:2e056a3f-e6e5-4ce9-980c-0a92049524e1"
		
		//30-11
		replace required_attendance_date ="23nov2022" if key=="uuid:b64371de-3cb5-4f3c-b3fb-69ece7b38680"
		replace required_attendance_date ="23nov2022" if key=="uuid:d5bda5d2-39f1-4334-9ed6-873813ea5d51"
		
		replace required_attendance_date ="22nov2022" if key=="uuid:94d77243-0163-4f9f-97c9-69807e15fe2f"
		replace required_attendance_date ="23nov2022" if key=="uuid:d5bda5d2-39f1-4334-9ed6-873813ea5d51"
		replace required_attendance_date ="22nov2022" if key=="uuid:4391a3f8-1ef6-49ed-ac7e-6466ac0eb78a"
	
	
		replace required_attendance_date ="24nov2022" if key=="uuid:856d8836-2062-43c4-b5df-ddd4d266a610"
		replace required_attendance_date ="24nov2022" if key=="uuid:991c6c84-03ba-4e69-be0d-9cefd83c5a1b"
		replace required_attendance_date ="24nov2022" if key=="uuid:2b2e0ebd-b018-43eb-ae9e-a0d1e4f68d07"
		
		replace required_attendance_date ="25nov2022" if key=="uuid:6c0ad279-36ec-47f6-8e6b-3f2557ad6ca2"
		replace required_attendance_date ="26nov2022" if key=="uuid:f0e6eb37-ee34-405f-8dfe-f5fd8d6f3473"
	
		replace required_attendance_date ="28nov2022" if key=="uuid:68d64693-6aae-479e-9ac8-42d96b12a422"
		replace required_attendance_date ="19nov2022" if key=="uuid:989e6139-6b8f-4a20-8e18-752a4a3284fa"
		replace required_attendance_date ="05nov2022" if key=="uuid:05bebf79-e836-462b-bac2-fbc9be069cba"
		replace required_attendance_date ="22nov2022" if key=="uuid:7b1c7b24-e001-444d-9ffe-75b748a2d59d"
		replace required_attendance_date ="26nov2022" if key=="uuid:512bcafe-6a3b-4203-a193-3098d3e478a0"
		drop if key=="uuid:829bcec7-bad9-4d05-9b1f-f72d3db0bed6"
		drop if key=="uuid:856d8836-2062-43c4-b5df-ddd4d266a610"
		
		replace required_attendance_date ="10nov2022" if key=="uuid:989e6139-6b8f-4a20-8e18-752a4a3284fa"
		
		replace required_attendance_date ="02dec2022" if key=="uuid:3204514b-f3c3-4f6a-9483-55acc15cf72b"
		replace required_attendance_date ="24nov2022" if key=="uuid:ba1b7073-beed-494c-b1ad-41e1ae2a64fc"
		replace required_attendance_date ="28nov2022" if key=="uuid:78addedf-b523-45b3-86ed-50cda0cc19f7"
		replace required_attendance_date ="05dec2022" if key=="uuid:6e6738e6-0634-49cb-9807-30359c57db9d"
		replace required_attendance_date ="21oct2022" if key=="uuid:22580143-f213-4cdf-b0ee-707d716203f5"
		replace required_attendance_date ="03nov2022" if key=="uuid:c3a9a1bd-98b5-4536-aa33-8fae904f5a6a"
		replace required_attendance_date ="05nov2022" if key=="uuid:799fc30d-49b1-4c02-b754-7cfb6364b4b0"
		replace required_attendance_date ="04nov2022" if key=="uuid:b4c265de-0a59-4890-bf40-3c94ebf30eb6"
		replace required_attendance_date ="10nov2022" if key=="uuid:dc070b7c-e18a-4845-97cc-9ec7617df0a6"
		replace required_attendance_date ="29nov2022" if key=="uuid:8797bb31-d1cf-4e3f-999b-9ddfa1f63694"
		replace required_attendance_date ="05nov2022" if key=="uuid:fffce039-b197-4033-99c6-f367a36f748d"
		replace required_attendance_date ="17nov2022" if key=="uuid:43a98c59-d450-4ae0-ba53-d1dbd57f3902"
		replace required_attendance_date ="10nov2022" if key=="uuid:8e196411-f768-481a-a365-484b8f8ca3a0"
		
	
	
	
	
		
		
		
	end
	
	cap program drop finalizing
	program finalizing
		keep if check_completion == 1
	
		// NB: we re-randomized people that were announced but didn't show up, so there might be duplicate pids
		isid pid date
	end

	
main

	
