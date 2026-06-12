# ============================================================
# Project  : MySQL DBA
# Author   : Naseer Aryobee
# Script   : 11_load_water_systems.py
# Purpose  : Load EPA SDWIS public water systems, joined with
#            geographic county data, into dim_water_system
# ============================================================

import mysql.connector
import csv
import getpass

PWS_FILE = r"C:\Users\User\Desktop\mysql-dba-project\data\raw\water-quality\SDWA_PUB_WATER_SYSTEMS.csv"
GEO_FILE = r"C:\Users\User\Desktop\mysql-dba-project\data\raw\water-quality\SDWA_GEOGRAPHIC_AREAS.csv"

password = getpass.getpass("Enter MySQL root password: ")

conn = mysql.connector.connect(
    host="localhost",
    user="root",
    password=password,
    database="cancer_environment_db"
)
cursor = conn.cursor()

# Pre-load state lookup
cursor.execute("SELECT state_id, state_abbr FROM dim_state")
state_lookup = {abbr: sid for sid, abbr in cursor.fetchall()}

# Pre-load county lookup (state_id, county_name_upper) -> county_id
cursor.execute("""
    SELECT c.county_id, s.state_abbr, c.county_name
    FROM dim_county c
    JOIN dim_state s ON s.state_id = c.state_id
""")
county_lookup = {(abbr, county.upper()): cid for cid, abbr, county in cursor.fetchall()}

# Step 1: Build PWSID -> county_id map from geographic areas file
print("Reading geographic areas file...")
pwsid_to_county = {}

with open(GEO_FILE, "r", encoding="utf-8-sig") as f:
    reader = csv.DictReader(f)
    for row in reader:
        pwsid = row["PWSID"]
        county_served = row["COUNTY_SERVED"].strip().upper()
        state_served = row["STATE_SERVED"].strip()

        if not county_served:
            continue

        # Try state from STATE_SERVED first, fallback to PWSID prefix
        state_abbr = state_served if state_served else pwsid[:2]

        key = (state_abbr, county_served)
        if key in county_lookup:
            pwsid_to_county[pwsid] = county_lookup[key]

print(f"Mapped {len(pwsid_to_county)} PWSIDs to counties")

# Step 2: Read public water systems file and insert
print("Reading public water systems file...")
insert_sql = """
INSERT INTO dim_water_system (
    pwsid, pws_name, state_id, county_id, population_served,
    owner_type_code, pws_type_code, primary_source_code
) VALUES (%s,%s,%s,%s,%s,%s,%s,%s)
ON DUPLICATE KEY UPDATE pws_name = pws_name
"""

batch = []
total_inserted = 0
batch_size = 5000

with open(PWS_FILE, "r", encoding="utf-8-sig") as f:
    reader = csv.DictReader(f)
    for row in reader:
        pwsid = row["PWSID"]
        state_code = row["STATE_CODE"]
        state_id = state_lookup.get(state_code)
        county_id = pwsid_to_county.get(pwsid)

        pop_served = row["POPULATION_SERVED_COUNT"]
        try:
            pop_served = int(float(pop_served)) if pop_served else None
        except ValueError:
            pop_served = None

        batch.append((
            pwsid,
            row["PWS_NAME"][:255] if row["PWS_NAME"] else None,
            state_id,
            county_id,
            pop_served,
            row["OWNER_TYPE_CODE"] if row["OWNER_TYPE_CODE"] else None,
            row["PWS_TYPE_CODE"] if row["PWS_TYPE_CODE"] else None,
            row["PRIMARY_SOURCE_CODE"] if row["PRIMARY_SOURCE_CODE"] else None,
        ))

        if len(batch) >= batch_size:
            cursor.executemany(insert_sql, batch)
            conn.commit()
            total_inserted += len(batch)
            print(f"  Inserted {total_inserted} rows...")
            batch = []

if batch:
    cursor.executemany(insert_sql, batch)
    conn.commit()
    total_inserted += len(batch)

print(f"\nTotal water systems inserted: {total_inserted}")

cursor.close()
conn.close()