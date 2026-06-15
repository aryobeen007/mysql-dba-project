-- ============================================================
-- Project  : MySQL DBA
-- Author   : Naseer Aryobee
-- Script   : 16_load_cafo_violations.sql
-- Purpose  : Load EPA NPDES permit schedule violations into
--            fact_cafo_violations
-- ============================================================

USE cancer_environment_db;

-- Step 1: Create staging table matching raw CSV structure
CREATE TABLE staging_cafo_violations (
    NPDES_ID VARCHAR(20),
    NPDES_VIOLATION_ID VARCHAR(20),
    PERM_SCHEDULE_EVENT_ID VARCHAR(20),
    VIOLATION_TYPE_CODE VARCHAR(10),
    VIOLATION_CODE VARCHAR(10),
    VIOLATION_DESC VARCHAR(255),
    SCHEDULE_EVENT_CODE VARCHAR(20),
    SCHEDULE_EVENT_DESC VARCHAR(255),
    SCHEDULE_DATE VARCHAR(20),
    RNC_DETECTION_CODE VARCHAR(10),
    RNC_DETECTION_DESC VARCHAR(100),
    RNC_DETECTION_DATE VARCHAR(20),
    RNC_RESOLUTION_CODE VARCHAR(10),
    RNC_RESOLUTION_DESC VARCHAR(100),
    RNC_RESOLUTION_DATE VARCHAR(20),
    ACTUAL_DATE VARCHAR(20),
    REPORT_RECEIVED_DATE VARCHAR(20)
);

-- Step 2: Load raw CSV into staging table
LOAD DATA LOCAL INFILE 'C:/Users/User/Desktop/mysql-dba-project/data/raw/cafo/npdes_extracted/NPDES_PS_VIOLATIONS.csv'
INTO TABLE staging_cafo_violations
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Step 3: Verify staging load
SELECT COUNT(*) AS staging_row_count FROM staging_cafo_violations;

-- Step 4: Insert into fact table with transformations
INSERT INTO fact_cafo_violations (
    npdes_id, violation_type, violation_short_desc,
    pollutant_code, pollutant_desc,
    monitoring_period_end_date, rnc_detection_date
)
SELECT
    sv.NPDES_ID,
    sv.VIOLATION_TYPE_CODE,
    sv.VIOLATION_DESC,
    sv.SCHEDULE_EVENT_CODE,
    sv.SCHEDULE_EVENT_DESC,
    CASE WHEN sv.SCHEDULE_DATE REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' 
         THEN STR_TO_DATE(sv.SCHEDULE_DATE, '%m/%d/%Y') ELSE NULL END,
    CASE WHEN sv.RNC_DETECTION_DATE REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' 
         THEN STR_TO_DATE(sv.RNC_DETECTION_DATE, '%m/%d/%Y') ELSE NULL END
FROM staging_cafo_violations sv;

-- Step 5: Verify
SELECT COUNT(*) AS fact_row_count FROM fact_cafo_violations;

-- Step 6: Quick breakdown by violation type
SELECT violation_type, COUNT(*) AS cnt
FROM fact_cafo_violations
GROUP BY violation_type
ORDER BY cnt DESC;

-- Step 7: Cleanup
DROP TABLE staging_cafo_violations;