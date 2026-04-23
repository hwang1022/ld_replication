**************************************************
**************************************************
*	Project: LD 
*	Purpose: JFP recall survey make variables 
*	Author: HW
* 	Last modified by HW Nov 22 2024
**************************************************
**************************************************


***************	
**# Open data
***************
			
	use "$temp/02_jfp_cleaned_complete.dta", clear

	
	
	
	
*********************
**# Clean Variables
*********************

	keep pid date jfp1_1 exp1 exp2 exp3 exp4 exp5 exp6 exp7 exp8
	

/*----------------------------------------------------*/
   /* [>   3.  Save data    <] */ 
/*----------------------------------------------------*/		
	save "$temp/02_jfp_makevar_v2.dta", replace


