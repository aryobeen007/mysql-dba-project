# ============================================================
# Project  : MySQL DBA
# Author   : Naseer Aryobee
# Script   : download_water_quality.py
# Purpose  : Download USGS/EPA water quality nutrient data
#            from the Water Quality Portal API by state
# ============================================================

import requests
import os
import time

OUTPUT_DIR = r"data\raw\water-quality"
os.makedirs(OUTPUT_DIR, exist_ok=True)

STATES = [
    "US:01","US:05","US:06","US:08","US:12","US:13",
    "US:17","US:18","US:19","US:20","US:21","US:22",
    "US:26","US:27","US:29","US:31","US:37","US:38",
    "US:39","US:40","US:42","US:45","US:46","US:48",
    "US:55"
]

BASE_URL = "https://www.waterqualitydata.us/data/Result/search"

PARAMS = {
    "characteristicType": "Nutrient",
    "sampleMedia": "Water",
    "startDateLo": "01-01-2015",
    "startDateHi": "12-31-2022",
    "dataProfile": "narrowResult",
    "mimeType": "csv",
    "zip": "no"
}

for state in STATES:
    state_code = state.split(":")[1]
    output_file = os.path.join(OUTPUT_DIR, f"wqp_nutrients_{state_code}.csv")

    if os.path.exists(output_file):
        print(f"Already exists, skipping: {output_file}")
        continue

    print(f"Downloading state {state_code}...")
    params = PARAMS.copy()
    params["statecode"] = state

    try:
        response = requests.get(BASE_URL, params=params, timeout=300, stream=True)
        response.raise_for_status()

        with open(output_file, "wb") as f:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)

        print(f"Saved: {output_file}")
        time.sleep(2)

    except Exception as e:
        print(f"Failed for state {state_code}: {e}")

print("Download complete.")