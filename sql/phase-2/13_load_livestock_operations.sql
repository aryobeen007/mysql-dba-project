-- ============================================================
-- Project  : MySQL DBA
-- Author   : Naseer Aryobee
-- Script   : 13_load_livestock_operations.sql
-- Purpose  : Load USDA Census of Agriculture 2022 data into
--            a staging table, then transform and insert into
--            fact_livestock_operations
-- ============================================================

USE cancer_environment_db;

-- Step 1: Create staging table matching raw tab-delimited structure
CREATE TABLE staging_livestock (
    SOURCE_DESC VARCHAR(50),
    SECTOR_DESC VARCHAR(50),
    GROUP_DESC VARCHAR(50),
    COMMODITY_DESC VARCHAR(50),
    CLASS_DESC VARCHAR(100),
    PRODN_PRACTICE_DESC VARCHAR(100),
    UTIL_PRACTICE_DESC VARCHAR(100),
    STATISTICCAT_DESC VARCHAR(50),
    UNIT_DESC VARCHAR(50),
    SHORT_DESC VARCHAR(255),
    DOMAIN_DESC VARCHAR(100),
    DOMAINCAT_DESC VARCHAR(255),
    AGG_LEVEL_DESC VARCHAR(20),
    STATE_ANSI VARCHAR(5),
    STATE_FIPS_CODE VARCHAR(5),
    STATE_ALPHA VARCHAR(5),
    STATE_NAME VARCHAR(50),
    ASD_CODE VARCHAR(10),
    ASD_DESC VARCHAR(100),
    COUNTY_ANSI VARCHAR(5),
    COUNTY_CODE VARCHAR(5),
    COUNTY_NAME VARCHAR(100),
    REGION_DESC VARCHAR(50),
    ZIP_5 VARCHAR(10),
    WATERSHED_CODE VARCHAR(20),
    WATERSHED_DESC VARCHAR(100),
    CONGR_DISTRICT_CODE VARCHAR(5),
    COUNTRY_CODE VARCHAR(5),
    COUNTRY_NAME VARCHAR(50),
    LOCATION_DESC VARCHAR(255),
    YEAR VARCHAR(5),
    FREQ_DESC VARCHAR(20),
    BEGIN_CODE VARCHAR(5),
    END_CODE VARCHAR(5),
    REFERENCE_PERIOD_DESC VARCHAR(50),
    WEEK_ENDING VARCHAR(20),
    LOAD_TIME VARCHAR(30),
    VALUE VARCHAR(30),
    CV_PCT VARCHAR(20)
);

-- Step 2: Load raw tab-delimited file into staging table
LOAD DATA LOCAL INFILE 'C:/Users/User/Desktop/mysql-dba-project/data/raw/cafo/qs.census2022.txt'
INTO TABLE staging_livestock
FIELDS TERMINATED BY '\t'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Step 3: Verify staging load
SELECT COUNT(*) AS staging_row_count FROM staging_livestock;
SELECT COMMODITY_DESC, COUNT(*) AS cnt 
FROM staging_livestock 
WHERE AGG_LEVEL_DESC = 'COUNTY'
GROUP BY COMMODITY_DESC 
ORDER BY cnt DESC 
LIMIT 10;


-- Step 4: Insert into fact table with transformations
-- Join on state FIPS and county FIPS codes to get county_id
INSERT INTO fact_livestock_operations (
    county_id, commodity_desc, class_desc, statisticcat_desc,
    unit_desc, domain_desc, domaincat_desc, year_id, value_text
)
SELECT
    c.county_id,
    sl.COMMODITY_DESC,
    sl.CLASS_DESC,
    sl.STATISTICCAT_DESC,
    sl.UNIT_DESC,
    sl.DOMAIN_DESC,
    sl.DOMAINCAT_DESC,
    CAST(sl.YEAR AS UNSIGNED),
    sl.VALUE
FROM staging_livestock sl
JOIN dim_state s ON s.state_fips = sl.STATE_FIPS_CODE
JOIN dim_county c ON c.state_id = s.state_id AND c.county_fips = sl.COUNTY_CODE
WHERE sl.AGG_LEVEL_DESC = 'COUNTY'
  AND sl.YEAR REGEXP '^[0-9]+$';

-- Step 5: Verify
SELECT COUNT(*) AS fact_row_count FROM fact_livestock_operations;

-- Step 6: Cleanup
DROP TABLE staging_livestock;