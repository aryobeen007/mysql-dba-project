-- ============================================================
-- Project  : MySQL DBA
-- Author   : Naseer Aryobee
-- Script   : 10_load_food_environment.sql
-- Purpose  : Load USDA Food Environment Atlas data into a
--            staging table, then transform and insert into
--            fact_food_environment
-- ============================================================

USE cancer_environment_db;

-- Step 1: Create staging table matching raw CSV structure
CREATE TABLE staging_food_environment (
    fips VARCHAR(10),
    state_abbr VARCHAR(10),
    county_name VARCHAR(100),
    variable_code VARCHAR(50),
    value VARCHAR(30)
);

-- Step 2: Load raw CSV into staging table
LOAD DATA LOCAL INFILE 'C:/Users/User/Desktop/mysql-dba-project/data/raw/food-environment/StateAndCountyData.csv'
INTO TABLE staging_food_environment
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Step 3: Verify staging load
SELECT COUNT(*) AS staging_row_count FROM staging_food_environment;
SELECT * FROM staging_food_environment LIMIT 5;


-- Step 4: Insert into fact table with transformations
-- Split 5-digit FIPS into state (first 2) and county (last 3) codes
INSERT INTO fact_food_environment (county_id, variable_code, value)
SELECT
    c.county_id,
    sf.variable_code,
    CASE WHEN sf.value REGEXP '^-?[0-9]+\\.?[0-9]*$' THEN CAST(sf.value AS DECIMAL(15,5)) ELSE NULL END
FROM staging_food_environment sf
JOIN dim_state s ON s.state_fips = LEFT(sf.fips, 2)
JOIN dim_county c ON c.state_id = s.state_id AND c.county_fips = RIGHT(sf.fips, 3)
WHERE sf.value REGEXP '^-?[0-9]+\\.?[0-9]*$';

-- Step 5: Verify
SELECT COUNT(*) AS fact_row_count FROM fact_food_environment;

-- Step 6: Cleanup
DROP TABLE staging_food_environment;