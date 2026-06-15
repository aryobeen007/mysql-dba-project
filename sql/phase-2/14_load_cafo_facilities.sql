-- ============================================================
-- Project  : MySQL DBA
-- Author   : Naseer Aryobee
-- Script   : 14_load_cafo_facilities.sql
-- Purpose  : Load EPA NPDES ICIS facility data into
--            dim_cafo_facility
-- ============================================================

USE cancer_environment_db;

-- Step 1: Create staging table matching raw CSV structure
CREATE TABLE staging_cafo_facilities (
    ICIS_FACILITY_INTEREST_ID VARCHAR(20),
    NPDES_ID VARCHAR(20),
    FACILITY_UIN VARCHAR(20),
    FACILITY_TYPE_CODE VARCHAR(10),
    FACILITY_NAME VARCHAR(255),
    LOCATION_ADDRESS VARCHAR(255),
    SUPPLEMENTAL_ADDRESS_TEXT VARCHAR(255),
    CITY VARCHAR(100),
    COUNTY_CODE VARCHAR(10),
    STATE_CODE VARCHAR(5),
    ZIP VARCHAR(10),
    GEOCODE_LATITUDE VARCHAR(20),
    GEOCODE_LONGITUDE VARCHAR(20),
    IMPAIRED_WATERS VARCHAR(50)
);

-- Step 2: Load raw CSV into staging table
LOAD DATA LOCAL INFILE 'C:/Users/User/Desktop/mysql-dba-project/data/raw/cafo/npdes_extracted/ICIS_FACILITIES.csv'
INTO TABLE staging_cafo_facilities
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Step 3: Verify staging load
SELECT COUNT(*) AS staging_row_count FROM staging_cafo_facilities;

-- Step 4: Insert into dim_cafo_facility with transformations
-- COUNTY_CODE format is "KY029" - state abbr + 3 digit county FIPS
INSERT INTO dim_cafo_facility (
    facility_id, npdes_id, facility_name, location_address,
    city, county_id, state_id, zip, latitude, longitude, impaired_waters
)
SELECT
    CAST(sf.ICIS_FACILITY_INTEREST_ID AS UNSIGNED),
    sf.NPDES_ID,
    sf.FACILITY_NAME,
    sf.LOCATION_ADDRESS,
    sf.CITY,
    c.county_id,
    s.state_id,
    sf.ZIP,
    CASE WHEN sf.GEOCODE_LATITUDE REGEXP '^-?[0-9]+\\.?[0-9]*$' THEN CAST(sf.GEOCODE_LATITUDE AS DECIMAL(10,6)) ELSE NULL END,
    CASE WHEN sf.GEOCODE_LONGITUDE REGEXP '^-?[0-9]+\\.?[0-9]*$' THEN CAST(sf.GEOCODE_LONGITUDE AS DECIMAL(10,6)) ELSE NULL END,
    sf.IMPAIRED_WATERS
FROM staging_cafo_facilities sf
JOIN dim_state s ON s.state_abbr = sf.STATE_CODE
LEFT JOIN dim_county c ON c.state_id = s.state_id 
    AND c.county_fips = RIGHT(sf.COUNTY_CODE, 3)
WHERE sf.ICIS_FACILITY_INTEREST_ID REGEXP '^[0-9]+$';

-- Step 5: Verify
SELECT COUNT(*) AS fact_row_count FROM dim_cafo_facility;

-- Step 6: Cleanup
DROP TABLE staging_cafo_facilities;