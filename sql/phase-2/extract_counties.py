# ============================================================
# Project  : MySQL DBA
# Author   : Naseer Aryobee
# Script   : extract_counties.py
# Purpose  : Extract unique state/county FIPS combinations
#            from the USDA Census of Agriculture file to
#            generate INSERT statements for dim_county
# ============================================================

import csv

INPUT_FILE = r"C:\Users\User\Desktop\mysql-dba-project\data\raw\cafo\qs.census2022.txt"
OUTPUT_FILE = r"C:\Users\User\Desktop\mysql-dba-project\sql\phase-2\05_load_dim_county.sql"

seen = set()
records = []

with open(INPUT_FILE, "r", encoding="utf-8", errors="ignore") as f:
    reader = csv.DictReader(f, delimiter="\t")

    for row in reader:
        agg_level = row.get("AGG_LEVEL_DESC", "")
        if agg_level != "COUNTY":
            continue

        state_fips = row.get("STATE_FIPS_CODE", "").strip()
        county_code = row.get("COUNTY_CODE", "").strip()
        county_name = row.get("COUNTY_NAME", "").strip()

        if not state_fips or not county_code or not county_name:
            continue

        key = (state_fips, county_code)
        if key in seen:
            continue

        seen.add(key)
        county_name_escaped = county_name.replace("'", "\\'")
        records.append((state_fips, county_code, county_name_escaped))

print(f"Found {len(records)} unique county records")

with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
    f.write("-- ============================================================\n")
    f.write("-- Project  : MySQL DBA\n")
    f.write("-- Author   : Naseer Aryobee\n")
    f.write("-- Script   : 05_load_dim_county.sql\n")
    f.write("-- Purpose  : Populate dim_county from unique state/county\n")
    f.write("--            FIPS combinations in USDA Census of Agriculture\n")
    f.write("-- ============================================================\n\n")
    f.write("USE cancer_environment_db;\n\n")
    f.write("INSERT INTO dim_county (state_id, county_fips, county_name)\n")
    f.write("SELECT s.state_id, c.county_fips, c.county_name\n")
    f.write("FROM (\n")

    values = []
    for state_fips, county_code, county_name in records:
        values.append(f"    SELECT '{state_fips}' AS state_fips, '{county_code}' AS county_fips, '{county_name}' AS county_name")

    f.write(" UNION ALL\n".join(values))
    f.write("\n) c\n")
    f.write("JOIN dim_state s ON s.state_fips = c.state_fips;\n")

print(f"SQL script written to: {OUTPUT_FILE}")