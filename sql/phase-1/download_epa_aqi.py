# ============================================================
# Project  : MySQL DBA
# Author   : Naseer Aryobee
# Script   : download_epa_aqi.py
# Purpose  : Download EPA annual AQI by county data 2000-2022
# ============================================================

import requests
import os
import zipfile
import time

OUTPUT_DIR = r"C:\Users\User\Desktop\mysql-dba-project\data\raw\air-quality"
os.makedirs(OUTPUT_DIR, exist_ok=True)

BASE_URL = "https://aqs.epa.gov/aqsweb/airdata"

for year in range(2000, 2023):
    filename = f"annual_aqi_by_county_{year}.zip"
    url = f"{BASE_URL}/{filename}"
    zip_path = os.path.join(OUTPUT_DIR, filename)
    csv_name = f"annual_aqi_by_county_{year}.csv"
    csv_path = os.path.join(OUTPUT_DIR, csv_name)

    if os.path.exists(csv_path):
        print(f"Already exists, skipping: {csv_name}")
        continue

    print(f"Downloading {filename}...")

    try:
        response = requests.get(url, timeout=60)
        response.raise_for_status()

        with open(zip_path, "wb") as f:
            f.write(response.content)

        with zipfile.ZipFile(zip_path, "r") as z:
            z.extractall(OUTPUT_DIR)

        os.remove(zip_path)
        print(f"Saved: {csv_name}")
        time.sleep(1)

    except Exception as e:
        print(f"Failed for {year}: {e}")

print("Download complete.")
