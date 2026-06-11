# ============================================================
# Project  : MySQL DBA
# Author   : Naseer Aryobee
# Script   : retry_water_quality.py
# Purpose  : Retry failed state downloads one year at a time
#            to avoid WQP API server timeouts
# ============================================================

import requests
import os
import time

OUTPUT_DIR = r"data\raw\water-quality"
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Only the failed states
FAILED_STATES = [
    "US:12", "US:27", "US:31", "US:38",
    "US:39", "US:40", "US:42", "US:46",
    "US:48", "US:55"
]

YEARS = [
    ("01-01-2015", "12-31-2015"),
    ("01-01-2016", "12-31-2016"),
    ("01-01-2017", "12-31-2017"),
    ("01-01-2018", "12-31-2018"),
    ("01-01-2019", "12-31-2019"),
    ("01-01-2020", "12-31-2020"),
    ("01-01-2021", "12-31-2021"),
    ("01-01-2022", "12-31-2022"),
]

BASE_URL = "https://www.waterqualitydata.us/data/Result/search"

for state in FAILED_STATES:
    state_code = state.split(":")[1]

    for start_date, end_date in YEARS:
        year = start_date.split("-")[2]
        output_file = os.path.join(OUTPUT_DIR, f"wqp_nutrients_{state_code}_{year}.csv")

        if os.path.exists(output_file):
            print(f"Already exists, skipping: {output_file}")
            continue

        print(f"Downloading state {state_code} year {year}...")

        params = {
            "characteristicType": "Nutrient",
            "sampleMedia": "Water",
            "startDateLo": start_date,
            "startDateHi": end_date,
            "dataProfile": "narrowResult",
            "mimeType": "csv",
            "zip": "no",
            "statecode": state
        }

        try:
            response = requests.get(BASE_URL, params=params, timeout=300, stream=True)
            response.raise_for_status()

            with open(output_file, "wb") as f:
                for chunk in response.iter_content(chunk_size=8192):
                    f.write(chunk)

            print(f"Saved: {output_file}")
            time.sleep(3)

        except Exception as e:
            print(f"Failed for state {state_code} year {year}: {e}")

print("Retry complete.")