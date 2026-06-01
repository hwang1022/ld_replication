************************************************************
************************************************************
* 	Project:			Labor Discipline
* 	Purpose:			Create Stand*Date level weather
* 	Author:				HW 
* 	Date created:		2025-Aug (HW)
* 	Last modified:		2025-Sep-16 (HW)
************************************************************
************************************************************

******************
**# 1. Read Data
******************

	use "$temp/stand_date_hour_weather.dta", clear


	* Understanding Rain Code
	sum rain if weather_code == 51 // 0.1-0.4
	sum rain if weather_code == 53 // 0.5-0.9
	sum rain if weather_code == 55 // 1-1.2
	sum rain if weather_code == 61 // 1.3-2.4
	sum rain if weather_code == 63 // 2.5-7.5
	sum rain if weather_code == 65 // 7.6+


******************************
**# 2. Create Day Level Data
******************************

	* Mean Temperature of the entire day
	* Max Temperature of the entire day
	* Mean Temperature During Recruitment Time (5:30-10:30)
	* Max Temperature During Recruitment Time (5:30-10:30)
	* Accumulative Precipitation of the entire day
	* Accumulative Precipitation During Recruitment Time (5:30-10:30)

	* Create data conditional on during recruitment time
	gen apparent_temp_recruit = apparent_temperature if hour >= 5.5 & hour <= 10.5
	gen precip_recruit = rain if hour >= 5.5 & hour <= 10.5
	gen weather_code_recruit = weather_code if hour >= 5.5 & hour <= 10.5

	collapse    (mean) mean_apparent_temp = apparent_temperature ///
				(mean) mean_apparent_temp_recruit = apparent_temp_recruit ///
				(max) max_apparent_temp = apparent_temperature ///
				(max) max_apparent_temp_recruit = apparent_temp_recruit ///
				(sum) accu_prec = rain ///
				(mean) mean_prec = rain ///
				(max) max_prec = rain ///
				(sum) accu_prec_recruit = precip_recruit ///
				(mean) mean_prec_recruit = precip_recruit ///
				(max) max_prec_recruit = precip_recruit ///
				(max) max_weather_code = weather_code ///
				(max) max_weather_code_recruit = weather_code_recruit ///
				(max) month year month_year , by(stand date)


	* Labeling
	label var mean_apparent_temp			"Mean Apparent Temperature of the day"
	label var mean_apparent_temp_recruit	"Mean Apparent Temperature During Recruitment Time"
	label var max_apparent_temp				"Max Apparent Temperature of the day"
	label var max_apparent_temp_recruit		"Max Apparent Temperature During Recruitment Time"
	label var accu_prec						"Accumulative Precipitation of the day"
	label var accu_prec_recruit				"Accumulative Precipitation During Recruitment Time"
	label var max_apparent_temp_recruit		"Max Apparent Temperature During Recruitment Time"
	label var mean_prec						"Mean Precipitation of the day"
	label var mean_prec_recruit				"Mean Precipitation During Recruitment Time"
	label var max_prec						"Max Precipitation of the day"
	label var max_prec_recruit				"Max Precipitation During Recruitment Time"
	label var max_weather_code				"Max Weather Code of the day"
	label var max_weather_code_recruit		"Max Weather Code During Recruitment Time"
	label var month							"Month"
	label var year							"Year"
	label var month_year					"Month Year"
	label var stand							"Stand"
	label var date							"Date"
	   

	order stand date month year month_year
	sort stand date
	drop if year == 2025

	lab val max_weather_code wmo_weather
	lab val max_weather_code_recruit wmo_weather
	replace max_weather_code = 999 if max_weather_code == -999
	replace max_weather_code_recruit = 999 if max_weather_code_recruit == -999

	save "$final/weather_day_stand_level.dta", replace