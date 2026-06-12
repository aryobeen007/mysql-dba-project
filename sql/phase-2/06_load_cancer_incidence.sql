-- ============================================================
-- Project  : MySQL DBA
-- Author   : Naseer Aryobee
-- Script   : 06_load_cancer_incidence.sql
-- Purpose  : Load CDC cancer incidence data into a staging
--            table, then transform and insert into
--            fact_cancer_incidence
-- ============================================================

USE cancer_environment_db;

-- Step 1: Create staging table matching raw CSV structure
CREATE TABLE staging_cancer_incidence (
    notes VARCHAR(255),
    state_name VARCHAR(50),
    state_code VARCHAR(10),
    year_val VARCHAR(10),
    year_code VARCHAR(10),
    case_count VARCHAR(20),
    population VARCHAR(20),
    age_adjusted_rate VARCHAR(20)
);

-- Step 2: Load raw CSV into staging table
LOAD DATA LOCAL INFILE 'C:/Users/User/Desktop/mysql-dba-project/data/raw/public-health/cdc_wonder_cancer_incidence_by_state_1999_2022.csv'
INTO TABLE staging_cancer_incidence
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(notes, state_name, state_code, year_val, year_code, case_count, population, age_adjusted_rate);

-- Step 3: Verify staging load
SELECT COUNT(*) AS staging_row_count FROM staging_cancer_incidence;
SELECT * FROM staging_cancer_incidence LIMIT 5;


-- Step 4: Insert into fact table with transformations
INSERT INTO fact_cancer_incidence (state_id, year_id, case_count, population, age_adjusted_rate)
SELECT
    s.state_id,
    CAST(st.year_val AS UNSIGNED),
    CAST(st.case_count AS UNSIGNED),
    CAST(st.population AS UNSIGNED),
    CAST(st.age_adjusted_rate AS DECIMAL(6,1))
FROM staging_cancer_incidence st
JOIN dim_state s ON s.state_name = st.state_name
WHERE st.year_val REGEXP '^[0-9]+$'
  AND st.case_count REGEXP '^[0-9]+$';

-- Step 5: Verify
SELECT COUNT(*) AS fact_row_count FROM fact_cancer_incidence;