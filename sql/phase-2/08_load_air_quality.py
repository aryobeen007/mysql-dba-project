# ============================================================
# Project  : MySQL DBA
# Author   : Naseer Aryobee
# Script   : 08_load_air_quality.py
# Purpose  : Load all 23 years of EPA AQI by county data
#            into fact_air_quality
# ============================================================

import mysql.connector
import csv
import os
import getpass

DATA_DIR = r"C:\Users\User\Desktop\mysql-dba-project\data\raw\air-quality"

password = getpass.getpass("Enter MySQL root password: ")

conn = mysql.connector.connect(
    host="localhost",
    user="root",
    password=password,
    database="cancer_environment_db"
)
cursor = conn.cursor()

# Pre-load state and county lookups into memory for fast matching
cursor.execute("SELECT state_id, state_name FROM dim_state")
state_lookup = {name: sid for sid, name in cursor.fetchall()}

cursor.execute("""
    SELECT c.county_id, s.state_name, c.county_name
    FROM dim_county c
    JOIN dim_state s ON s.state_id = c.state_id
""")
county_lookup = {(state, county.upper()): cid for cid, state, county in cursor.fetchall()}

total_inserted = 0
total_skipped = 0

insert_sql = """
INSERT INTO fact_air_quality (
    county_id, year_id, days_with_aqi, good_days, moderate_days,
    unhealthy_sensitive_days, unhealthy_days, very_unhealthy_days,
    hazardous_days, max_aqi, percentile_90_aqi, median_aqi,
    days_co, days_no2, days_ozone, days_pm25, days_pm10
) VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
"""

for year in range(2000, 2023):
    filename = f"annual_aqi_by_county_{year}.csv"
    filepath = os.path.join(DATA_DIR, filename)

    if not os.path.exists(filepath):
        print(f"File not found, skipping: {filename}")
        continue

    print(f"Processing {filename}...")
    batch = []

    with open(filepath, "r", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)

        for row in reader:
            state = row["State"]
            county = row["County"]
            key = (state, county.upper())

            if key not in county_lookup:
                total_skipped += 1
                continue

            county_id = county_lookup[key]

            batch.append((
                county_id,
                int(row["Year"]),
                int(row["Days with AQI"]) if row["Days with AQI"] else None,
                int(row["Good Days"]) if row["Good Days"] else None,
                int(row["Moderate Days"]) if row["Moderate Days"] else None,
                int(row["Unhealthy for Sensitive Groups Days"]) if row["Unhealthy for Sensitive Groups Days"] else None,
                int(row["Unhealthy Days"]) if row["Unhealthy Days"] else None,
                int(row["Very Unhealthy Days"]) if row["Very Unhealthy Days"] else None,
                int(row["Hazardous Days"]) if row["Hazardous Days"] else None,
                int(row["Max AQI"]) if row["Max AQI"] else None,
                int(row["90th Percentile AQI"]) if row["90th Percentile AQI"] else None,
                int(row["Median AQI"]) if row["Median AQI"] else None,
                int(row["Days CO"]) if row["Days CO"] else None,
                int(row["Days NO2"]) if row["Days NO2"] else None,
                int(row["Days Ozone"]) if row["Days Ozone"] else None,
                int(row["Days PM2.5"]) if row["Days PM2.5"] else None,
                int(row["Days PM10"]) if row["Days PM10"] else None,
            ))

    if batch:
        cursor.executemany(insert_sql, batch)
        conn.commit()
        total_inserted += len(batch)
        print(f"  Inserted {len(batch)} rows")

print(f"\nTotal rows inserted: {total_inserted}")
print(f"Total rows skipped (county not found): {total_skipped}")

cursor.close()
conn.close()