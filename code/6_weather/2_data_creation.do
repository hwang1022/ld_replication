************************************************************
************************************************************
* 	Project:			Labor Discipline
* 	Purpose:			Create weather dataset
* 	Author:				HW 
* 	Date created:		2025-Aug (HW)
* 	Last modified:		2025-Sep-12 (HW)
************************************************************
************************************************************


******************
**# 1. Read Data
******************

local combine_raw = 1

if `combine_raw' == 1 {
	* Get list of all files matching the pattern
	local files : dir "$external/weather" files "stand_*_*_hourly.csv"

	* Initialize counter for tempfiles
	local n = 0

	* Loop through each file
	foreach file of local files {
		// Extract stand number and year from filename using regex
		if regexm("`file'", "stand_([0-9]+\.?[0-9]*)_([0-9]+)_hourly\.csv") {
			local stand_num = regexs(1)
			local year_num = regexs(2)
			
			// Load the dataset
			import delimited "$external/weather/`file'", clear
			
			// Add stand and year variables
			gen stand = real("`stand_num'")
			// Save as tempfile
			tempfile file`n'
			save `file`n'', replace
			
			local n = `n' + 1
		}
	}

	* Combine all datasets
	if `n' > 0 {
		use `file0', clear
		local number_of_files = `n' - 1
		forvalues i = 1/`number_of_files' {
			append using `file`i''
		}
	}

	save "$temp/raw_weather_combined.dta", replace
}


******************
**# 2. Clean Data
******************

	use "$temp/raw_weather_combined.dta", clear

	sort stand date

	

	* Label stands
	* Purpose: Unknown
	* Author: Luisa
	* Last modified: Unknown	
	cap program drop	standLabeling		
	program define 		standLabeling
	cap label drop stand_lab
    label define stand_lab   	1 "1. Adambakam" 2 "2. Avadi" 3 "3. Aynavaram" 4 "4. Mandaveli"	5 "5. MKB" 6 "6. Korattur" 7 "7. MMDA" ///
								8 "8. Porur" 9 "9. TVK Nagar" 10 "10. Poonamallee"	11 "11. Keelkattalai" 12 "12. Krishna Nagar" ///
								13 "13. Thiruvanmiyur" 15 "15. Velachery" 16 "16. Padappai" 17 "17. Guduvanchery" 18 "18. Pammal" 20 "20. Iyapandagal" , replace
    qui label list stand_lab
	forv i = 1/`r(max)' {
	   global stand_lab_`i': label stand_lab `i'
	}
	
	end
	standLabeling
	lab val stand stand_lab

	* Format date and create hour variable
	* Convert string UTC timestamp in `date' to Stata datetime in IST (UTC+05:30)
	gen double datetime = clock(substr(date, 1, 19), "YMD hms") + 19800000
	format datetime %tc
	label var datetime "Datetime (IST, UTC+05:30)"

	* Free up name 'date' for daily date by renaming original string
	rename date date_str

	gen date = dofc(datetime)
	format date %td
	gen hour = hh(datetime) + mm(datetime)/60
	order date hour, after(datetime)
	order stand

	gen year = year(date)
	gen month = month(date)
	gen month_year = ym(year, month)
	format month_year %tm

	// keep if year >= 1992
	

	* Label weather code
	label define wmo_weather ///
	0 "Cloud development not observed or not observable" ///
	1 "Cloud generally dissolving or becoming less developed" ///
	2 "State of sky on the whole unchanged" ///
	3 "Clouds generally forming or developing" ///
	4 "Visibility reduced by smoke" ///
	5 "Haze" ///
	6 "Widespread dust in suspension in the air" ///
	7 "Dust or sand raised by wind at station" ///
	8 "Well-developed dust or sand whirls seen" ///
	9 "Duststorm or sandstorm within sight" ///
	10 "Mist" ///
	11 "Patches of shallow fog or ice fog" ///
	12 "Continuous shallow fog or ice fog" ///
	13 "Lightning visible, or thunder heard" ///
	14 "Precipitation within sight, not reaching ground" ///
	15 "Precipitation within sight, reaching ground, distant" ///
	16 "Precipitation within sight, reaching ground, near station" ///
	17 "Thunderstorm, but no precipitation at time of observation" ///
	18 "Squalls at or within sight of station" ///
	19 "Funnel clouds at or within sight of station" ///
	20 "Drizzle or snow grains, preceding hour, not current" ///
	21 "Rain, preceding hour, not current" ///
	22 "Snow, preceding hour, not current" ///
	23 "Rain and snow or ice pellets, preceding hour, not current" ///
	24 "Freezing drizzle or rain, preceding hour, not current" ///
	25 "Rain showers, preceding hour, not current" ///
	26 "Snow showers or rain and snow, preceding hour, not current" ///
	27 "Hail showers or rain and hail, preceding hour, not current" ///
	28 "Fog or ice fog, preceding hour, not current" ///
	29 "Thunderstorm, preceding hour, not current" ///
	30 "Slight/moderate duststorm - decreased" ///
	31 "Slight/moderate duststorm - no change" ///
	32 "Slight/moderate duststorm - begun or increased" ///
	33 "Severe duststorm - decreased" ///
	34 "Severe duststorm - no change" ///
	35 "Severe duststorm - begun or increased" ///
	36 "Slight/moderate drifting snow - low" ///
	37 "Heavy drifting snow - low" ///
	38 "Slight/moderate blowing snow - high" ///
	39 "Heavy blowing snow - high" ///
	40 "Fog or ice fog at distance, extending above observer" ///
	41 "Fog or ice fog in patches" ///
	42 "Fog/ice fog, sky visible, becoming thinner" ///
	43 "Fog/ice fog, sky invisible, becoming thinner" ///
	44 "Fog or ice fog, sky visible, no change" ///
	45 "Fog or ice fog, sky invisible, no change" ///
	46 "Fog or ice fog, sky visible, begun or thicker" ///
	47 "Fog or ice fog, sky invisible, begun or thicker" ///
	48 "Fog, depositing rime, sky visible" ///
	49 "Fog, depositing rime, sky invisible" ///
	50 "Drizzle, not freezing, intermittent, slight" ///
	51 "Drizzle, not freezing, continuous, slight" ///
	52 "Drizzle, not freezing, intermittent, moderate" ///
	53 "Drizzle, not freezing, continuous, moderate" ///
	54 "Drizzle, not freezing, intermittent, heavy" ///
	55 "Drizzle, not freezing, continuous, heavy" ///
	56 "Drizzle, freezing, slight" ///
	57 "Drizzle, freezing, moderate or heavy" ///
	58 "Rain and drizzle, slight" ///
	59 "Rain and drizzle, moderate or heavy" ///
	60 "Rain, not freezing, intermittent, slight" ///
	61 "Rain, not freezing, continuous, slight" ///
	62 "Rain, not freezing, intermittent, moderate" ///
	63 "Rain, not freezing, continuous, moderate" ///
	64 "Rain, not freezing, intermittent, heavy" ///
	65 "Rain, not freezing, continuous, heavy" ///
	66 "Rain, freezing, slight" ///
	67 "Rain, freezing, moderate or heavy" ///
	68 "Rain or drizzle and snow, slight" ///
	69 "Rain or drizzle and snow, moderate or heavy" ///
	70 "Intermittent fall of snowflakes, slight" ///
	71 "Continuous fall of snowflakes, slight" ///
	72 "Intermittent fall of snowflakes, moderate" ///
	73 "Continuous fall of snowflakes, moderate" ///
	74 "Intermittent fall of snowflakes, heavy" ///
	75 "Continuous fall of snowflakes, heavy" ///
	76 "Diamond dust (with or without fog)" ///
	77 "Snow grains (with or without fog)" ///
	78 "Isolated star-like snow crystals (with or without fog)" ///
	79 "Ice pellets" ///
	80 "Rain showers, slight" ///
	81 "Rain showers, moderate or heavy" ///
	82 "Rain showers, violent" ///
	83 "Showers of rain and snow, slight" ///
	84 "Showers of rain and snow, moderate or heavy" ///
	85 "Snow showers, slight" ///
	86 "Snow showers, moderate or heavy" ///
	87 "Snow pellets or small hail showers, slight" ///
	88 "Snow pellets or small hail showers, moderate or heavy" ///
	89 "Hail showers, not with thunder, slight" ///
	90 "Hail showers, not with thunder, moderate or heavy" ///
	91 "Slight rain - thunderstorm in preceding hour" ///
	92 "Moderate/heavy rain - thunderstorm in preceding hour" ///
	93 "Slight snow/rain and snow/hail - thunderstorm in preceding hour" ///
	94 "Moderate/heavy snow/rain and snow/hail - thunderstorm in preceding hour" ///
	95 "Thunderstorm, slight/moderate, without hail, with rain/snow" ///
	96 "Thunderstorm, slight/moderate, with hail" ///
	97 "Thunderstorm, heavy, without hail, with rain/snow" ///
	98 "Thunderstorm combined with duststorm/sandstorm" ///
	99 "Thunderstorm, heavy with hail" ///
	-999 "No Rain" ///
	999 "No Rain" , replace
	lab val weather_code wmo_weather
	replace weather_code = -999 if weather_code < 50 | weather_code > 69

	* Reorder weather variables
	keep stand datetime date hour month year month_year relative_humidity_2m temperature_2m apparent_temperature weather_code rain

	gen __COVER_____ = .
	gen __HEAT_____ = .
	gen __RAIN_____ = .



	order   __COVER_____ stand datetime date hour month year month_year ///
			__HEAT_____ relative_humidity_2m temperature_2m apparent_temperature ///
			__RAIN_____ weather_code rain
	




******************
**# 3. Save Data
******************

	save "$temp/stand_date_hour_weather.dta", replace
