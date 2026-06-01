"""
Download hourly historical weather data from the Open-Meteo Archive API for
labour stand locations listed in `data/external/Labour Stand Locations.csv`
(rows with main_study == "Yes"). Output is written to
`data/external/weather/` as both .csv and .dta files, one per stand per year.

Usage:
    Run from this script's directory (code/6_weather/) so the relative paths
    resolve correctly:

        cd code/6_weather
        python 1_open_meteo_api_history.py [options]

Options:
    --start_year YEAR   First year to scrape (default: 1990)
    --end_year   YEAR   Last year to scrape  (default: 2024)
    --replace           Overwrite existing output files (default: skip them)
    --sleep      SECS   Seconds to sleep between API calls (default: 60)

Examples:
    # Default run: 1990-2024, skip files that already exist
    python 1_open_meteo_api_history.py

    # Single year, overwriting any existing files
    python 1_open_meteo_api_history.py --start_year 2020 --end_year 2020 --replace

    # Backfill a range with a shorter delay between calls
    python 1_open_meteo_api_history.py --start_year 2010 --end_year 2015 --sleep 30
"""

import openmeteo_requests
import time
import pandas as pd
import requests_cache
from retry_requests import retry
import argparse
import os

# Setup the Open-Meteo API client with cache and retry on error
cache_session = requests_cache.CachedSession('.cache', expire_after = -1)
retry_session = retry(cache_session, retries = 5, backoff_factor = 0.2)
openmeteo = openmeteo_requests.Client(session = retry_session)


def should_skip_file(stand_id, year, replace):
	"""Check if file should be skipped based on replace option"""
	csv_file = f"../../data/external/weather/stand{stand_id}_{year}_hourly.csv"
	dta_file = f"../../data/external/weather/stand{stand_id}_{year}_hourly.dta"
	
	if not replace and (os.path.exists(csv_file) or os.path.exists(dta_file)):
		return True
	return False


def get_stand_mapping(i):
	global stand_ids
	"""Map iteration index to stand ID"""
	'''
	if i == 1 or i == 2 or i == 3:
		return i
	if i == 4 or i == 5:
		return i + 1
	if i == 6:
		return 13
	if i == 7 or i == 8 or i == 9 or i == 10:
		return i + 8
	if i == 11:
		return 20
	return i
	'''
	return stand_ids[i-1]



def fetch_weather_data(year, sleep_time, replace, latitudes, longitudes):
	
	"""Fetch weather data for a specific year"""
	# Check if all files for this year already exist and replace=False
	if not replace:
		all_files_exist = True
		for i in range(1, 12):  # 11 stands total
			stand_id = get_stand_mapping(i)
			if not should_skip_file(stand_id, year, replace):
				all_files_exist = False
				break
		
		if all_files_exist:
			print(f"Skipping year {year} - all files exist and replace=False")
			return
	
	# Make sure all required weather variables are listed here
	# The order of variables in hourly or daily is important to assign them correctly below
	url = "https://archive-api.open-meteo.com/v1/archive"
	params = {
		"latitude": latitudes,
		"longitude": longitudes,
		"start_date": f"{year}-01-01",
		"end_date": f"{year+1}-01-01",
		"hourly": ["temperature_2m", "relative_humidity_2m", "weather_code", "rain", "apparent_temperature"],
		"temperature_unit": "fahrenheit",
	}
	
	
	responses = openmeteo.weather_api(url, params=params)
	print(f"Finished Downloading Year {year}!!!")

	i = 1
	for response in responses:
		stand_id = get_stand_mapping(i)
		
		# Check if we should skip this individual file
		if should_skip_file(stand_id, year, replace):
			print(f"Skipping stand{stand_id}_{year} (file exists and replace=False)")
			i += 1
			continue
			
		print(f"\nCoordinates: {response.Latitude()}°N {response.Longitude()}°E")
		print(f"Elevation: {response.Elevation()} m asl")
		print(f"Timezone: {response.Timezone()}{response.TimezoneAbbreviation()}")
		print(f"Timezone difference to GMT+0: {response.UtcOffsetSeconds()}s")
		
		# Process hourly data. The order of variables needs to be the same as requested.
		hourly = response.Hourly()
		hourly_temperature_2m = hourly.Variables(0).ValuesAsNumpy()
		hourly_relative_humidity_2m = hourly.Variables(1).ValuesAsNumpy()
		hourly_weather_code = hourly.Variables(2).ValuesAsNumpy()
		hourly_rain = hourly.Variables(3).ValuesAsNumpy()
		hourly_apparent_temperature = hourly.Variables(4).ValuesAsNumpy()

		hourly_data = {"date": pd.date_range(
			start = pd.to_datetime(hourly.Time(), unit = "s", utc = True),
			end = pd.to_datetime(hourly.TimeEnd(), unit = "s", utc = True),
			freq = pd.Timedelta(seconds = hourly.Interval()),
			inclusive = "left"
		)}

		hourly_data["temperature_2m"] = hourly_temperature_2m
		hourly_data["relative_humidity_2m"] = hourly_relative_humidity_2m
		hourly_data["weather_code"] = hourly_weather_code
		hourly_data["rain"] = hourly_rain
		hourly_data["apparent_temperature"] = hourly_apparent_temperature
		
		hourly_dataframe = pd.DataFrame(data = hourly_data)
		print("\nHourly data\n", hourly_dataframe)
		
		# Save Datasets
		hourly_dataframe.to_csv(f"../../data/external/weather/stand_{stand_id}_{year}_hourly.csv", index = False)

		# Convert date columns to Stata datetime format
		stata_epoch = pd.Timestamp('1960-01-01', tz='UTC')
		hourly_dataframe['date'] = (hourly_dataframe['date'] - stata_epoch).dt.total_seconds() * 1000
		hourly_dataframe.to_stata(f"../../data/external/weather/stand_{stand_id}_{year}_hourly.dta", write_index = False)

		i = i + 1

		print(f"Finished Processing Stand {stand_id} for Year {year}!!!")
	time.sleep(sleep_time)


def main():
	"""Main function with command-line argument parsing"""
	parser = argparse.ArgumentParser(description='Download weather data from Open-Meteo API')
	parser.add_argument('--start_year', type=int, default=1990, 
						help='First year to scrape (default: 1990)')
	parser.add_argument('--end_year', type=int, default=2024, 
						help='Last year to scrape (default: 2024)')
	parser.add_argument('--replace', action='store_true', 
						help='Replace existing weather data files')
	parser.add_argument('--sleep', type=int, default=60, 
						help='Seconds to sleep between API calls (default: 60)')
	
	args = parser.parse_args()
	
	# Validate year range
	if args.start_year > args.end_year:
		print("Error: start_year must be less than or equal to end_year")
		return
	
	print(f"Downloading weather data for years {args.start_year}-{args.end_year}")
	print(f"Replace existing files: {args.replace}")
	print(f"Sleep time between calls: {args.sleep} seconds")

	# Read coordinates from csv
	df = pd.read_csv("../../data/external/Labour Stand Locations.csv")
	df = df[df["main_study"]== "Yes"]
	df= df.sort_values("stand_no")
	latitudes = df["latitude"].to_list()
	longitudes = df["longitude"].to_list()
	global stand_ids
	stand_ids = df["stand_no"].to_list()
	
	# Process years in reverse order (as in original code)
	for year in range(args.end_year, args.start_year - 1, -1):
		print(f"\n{'='*50}")
		print(f"Processing Year {year}")
		print(f"{'='*50}")
		fetch_weather_data(year, args.sleep, args.replace, latitudes, longitudes)


if __name__ == "__main__":
	main()