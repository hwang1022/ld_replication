**************************************************
*Project: LD 
*Purpose: JFP recall survey cleaning
*Author: Vasanthi
* Last modified: 2024-04-23 (YS)
* HW Modified direcotries in Oct 2024
**************************************************

/*----------------------------------------------------*/
   /* [>   1.  Open data    <] */ 
/*----------------------------------------------------*/

	use "$raw/01_jfp_named.dta", clear
	isid pid date 
	display("no corrections so far")

/*----------------------------------------------------*/
   /* [>   2.  Save data    <] */ 
/*----------------------------------------------------*/

	keep if check_completion == 1
	drop interviewer_others deviceid subscriberid devicephonenum username duration caseid text_audit formdef_version key submissiondate starttime endtime		
	saveold "$temp/02_jfp_cleaned_complete.dta", replace
	

