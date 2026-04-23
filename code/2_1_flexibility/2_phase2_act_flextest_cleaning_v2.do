**************************************************
*Project: LD Main Study
*Purpose: Phase 2 activity - flexibility test cleaning
*Author: Luisa
*Last modified: 12-06-2022 (LC)
*HW modified directories in late 2024
**************************************************

	cap program drop main
	program main
		use "$raw/01c_phase2act_flextest_named_v2.dta", clear
		cleaning
		save "$temp/03c_phase2act_flextest_cleaned_v2.dta", replace
		finalizing
		sort pid date
		order pid date stand contract_choice* first_day second_day
		save "$temp/03c_phase2act_flextest_cleaned_completed_v2.dta", replace
	end


	
*****************************************
*Codes Starts
*****************************************
	cap program drop cleaning
	program cleaning
		
		
		//missing question choice follow up
		replace q_choice=2 if pid==1831
		replace q_choice=1 if pid==1819
		replace q_choice=1 if pid==1704
		replace q_choice=2 if pid==1705
		
		//dropping duplicate entry (NL)
		drop if key == "uuid:59791370-9f04-498f-a045-54117e75af02" //6860
		drop if key == "uuid:98b3b015-e71c-4a2c-adf0-801795357f26" //1779
		drop if key == "uuid:4749d3e1-abc1-479c-a829-4fdc8d997a02" //6863
		drop if key == "uuid:8b6e8e2e-e5d1-42e1-b94a-45c6d9408635" //6867
		
		
		//coding reasons for choice (NL)
		gen reason_choice_1=.
		replace reason_choice_1 =1 if note_choice1 =="Amount excess" | note_choice1 =="Amount" | note_choice1 =="90 rupees is a bigger amount than another amount, so I will try to come before eight o'clock on labour market" | note_choice1 =="I am currently working in the catering and try to come before 8 as possible, that reason, 90 rupee will help towards transportation cost." | note_choice1 =="I have no work and this option getting excess amount" | note_choice1 =="10rs extra available I think I can come as I am already coming before 8" | note_choice1 =="10 RS extra amount"
		replace reason_choice_1 =2 if note_choice1 =="I am usually at the labor market before 8 o'clock" | note_choice1 =="Regularly early coming to the stand" | note_choice1 =="I can reach the stand before 8 am everyday so l am choose this 1st option" | note_choice1 =="Regularly coming to the stand" | note_choice1 =="8:00 before time flexible" | note_choice1 =="I chose option 1 as the labour market comes daily before 8 am" | note_choice1 =="8:00 flexible time" | note_choice1 =="I can reach the stand before 8 am everyday so l am choose this 1st option" | note_choice1 =="Regularly came to the stand @ 6 am" | note_choice1 =="Because I come at 8 am every day" | note_choice1 =="Early coming" | note_choice1 =="I can reach the stand before 8 am everyday so l am choose this 1st option"
		replace reason_choice =3 if note_choice1 =="Time" | note_choice1 =="Not time" | note_choice1 =="It is a bit difficult to reach the labor station before 8 am but i will try" | note_choice1 =="Time" | note_choice1 =="I will come to labor station as I have finished some work in my house. It will be more than 8:30am when I arrive and it is a bit difficult for me to arrive at 8am" | note_choice1 =="It is a bit difficult to come market before 8am. It is difficult to come labor stand by bus from our area" | note_choice1 =="It is late to prepare breakfast so I can reach the stand only at 8:30am" | note_choice1 =="It is a bit difficult to reach the labor station before 8 am but i will try" | note_choice1 =="It is a bit difficult to come market before 8am. It is difficult to come labor stand by bus from our area" | note_choice1 =="Time" | note_choice1 =="Timing is not constant" | note_choice1 =="Participant said long distance from home so he choose 2nd option.." | note_choice1 =="Coming to the stand every day from a distance of 20 km would be a bit difficult for me to come exactly at 8 am."
	
	
		//21-10-22 (NL) 
		replace first_day ="Tuesday" if pid==1845 & key=="uuid:af1d646e-d43a-4c3f-a6bf-4b03381dd64a"
		replace first_day ="Monday" if pid==6801 & key=="uuid:0cbe602a-27fb-4ebc-a1ab-ba9e397da987"
		replace second_day ="Thursday" if pid==6801& key=="uuid:0cbe602a-27fb-4ebc-a1ab-ba9e397da987"
		replace first_day ="Monday" if pid==1705 & key=="uuid:cdc04cf9-b40f-44c0-a289-78142f8f1fb8"
		replace second_day ="Thursday" if pid==1705 & key=="uuid:cdc04cf9-b40f-44c0-a289-78142f8f1fb8"
		
	
		//09-11-2022
		drop if key =="uuid:0cbe602a-27fb-4ebc-a1ab-ba9e397da987"
		replace stand = 16 if pid == 7738 & stand == 998 & key == "uuid:4c49c461-4bee-4035-a7e1-c16cb62be14b"
	
	
	
	
	end
	
	cap program drop finalizing
	program finalizing
		gen new_elicitation = !mi(comp_question_1)
		keep if check_completion == 1
	
		isid pid 
	end

	
main
	