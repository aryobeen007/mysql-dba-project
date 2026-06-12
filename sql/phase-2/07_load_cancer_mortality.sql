-- ============================================================
-- Project  : MySQL DBA
-- Author   : Naseer Aryobee
-- Script   : 07_load_cancer_mortality.sql
-- Purpose  : Load CDC cancer mortality data into a staging
--            table, then transform and insert into
--            fact_cancer_mortality
-- ============================================================

USE cancer_environment_db;

-- Step 1: Create staging table matching raw CSV structure
CREATE TABLE staging_cancer_mortality (
    notes VARCHAR(255),
    state_name VARCHAR(50),
    state_code VARCHAR(10),
    year_val VARCHAR(10),
    year_code VARCHAR(10),
    death_count VARCHAR(20),
    population VARCHAR(20),
    age_adjusted_rate VARCHAR(20)
);

-- Step 2: Load raw CSV into staging table
LOAD DATA LOCAL INFILE 'C:/Users/User/Desktop/mysql-dba-project/data/raw/public-health/cdc_wonder_cancer_mortality_by_state_2018_2023.csv'
INTO TABLE staging_cancer_mortality
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(notes, state_name, state_code, year_val, year_code, death_count, population, age_adjusted_rate);

-- Step 3: Verify staging load
SELECT COUNT(*) AS staging_row_count FROM staging_cancer_mortality;
SELECT * FROM staging_cancer_mortality LIMIT 5;

-- Step 4: Insert into fact table with transformations
INSERT INTO fact_cancer_mortality (state_id, year_id, death_count, population, age_adjusted_rate)
SELECT
    s.state_id,
    CAST(st.year_val AS UNSIGNED),
    CAST(st.death_count AS UNSIGNED),
    CAST(st.population AS UNSIGNED),
    CAST(st.age_adjusted_rate AS DECIMAL(6,1))
FROM staging_cancer_mortality st
JOIN dim_state s ON s.state_name = st.state_name
WHERE st.year_val REGEXP '^[0-9]+$'
  AND st.death_count REGEXP '^[0-9]+$';

-- Step 5: Verify
SELECT COUNT(*) AS fact_row_count FROM fact_cancer_mortality;

-- Step 6: Cleanup
DROP TABLE staging_cancer_mortality;