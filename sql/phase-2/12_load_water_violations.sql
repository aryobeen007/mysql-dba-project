-- ============================================================
-- Project  : MySQL DBA
-- Author   : Naseer Aryobee
-- Script   : 12_load_water_violations.sql
-- Purpose  : Load EPA SDWIS drinking water violations and
--            enforcement data into fact_water_violations
-- ============================================================

USE cancer_environment_db;

-- Step 1: Create staging table matching raw CSV structure
CREATE TABLE staging_water_violations (
    SUBMISSIONYEARQUARTER VARCHAR(10),
    PWSID VARCHAR(20),
    VIOLATION_ID VARCHAR(20),
    FACILITY_ID VARCHAR(20),
    COMPL_PER_BEGIN_DATE VARCHAR(20),
    COMPL_PER_END_DATE VARCHAR(20),
    NON_COMPL_PER_BEGIN_DATE VARCHAR(20),
    NON_COMPL_PER_END_DATE VARCHAR(20),
    PWS_DEACTIVATION_DATE VARCHAR(20),
    VIOLATION_CODE VARCHAR(10),
    VIOLATION_CATEGORY_CODE VARCHAR(10),
    IS_HEALTH_BASED_IND VARCHAR(5),
    CONTAMINANT_CODE VARCHAR(10),
    VIOL_MEASURE VARCHAR(30),
    UNIT_OF_MEASURE VARCHAR(20),
    FEDERAL_MCL VARCHAR(50),
    STATE_MCL VARCHAR(50),
    IS_MAJOR_VIOL_IND VARCHAR(5),
    SEVERITY_IND_CNT VARCHAR(10),
    CALCULATED_RTC_DATE VARCHAR(20),
    VIOLATION_STATUS VARCHAR(20),
    PUBLIC_NOTIFICATION_TIER VARCHAR(10),
    CALCULATED_PUB_NOTIF_TIER VARCHAR(10),
    VIOL_ORIGINATOR_CODE VARCHAR(10),
    SAMPLE_RESULT_ID VARCHAR(20),
    CORRECTIVE_ACTION_ID VARCHAR(20),
    RULE_CODE VARCHAR(10),
    RULE_GROUP_CODE VARCHAR(10),
    RULE_FAMILY_CODE VARCHAR(10),
    VIOL_FIRST_REPORTED_DATE VARCHAR(20),
    VIOL_LAST_REPORTED_DATE VARCHAR(20),
    ENFORCEMENT_ID VARCHAR(20),
    ENFORCEMENT_DATE VARCHAR(20),
    ENFORCEMENT_ACTION_TYPE_CODE VARCHAR(10),
    ENF_ACTION_CATEGORY VARCHAR(20),
    ENF_ORIGINATOR_CODE VARCHAR(10),
    ENF_FIRST_REPORTED_DATE VARCHAR(20),
    ENF_LAST_REPORTED_DATE VARCHAR(20)
);

-- Step 2: Load raw CSV into staging table
LOAD DATA LOCAL INFILE 'C:/Users/User/Desktop/mysql-dba-project/data/raw/water-quality/SDWA_VIOLATIONS_ENFORCEMENT.csv'
INTO TABLE staging_water_violations
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Step 3: Verify staging load
SELECT COUNT(*) AS staging_row_count FROM staging_water_violations;




-- Step 4: Insert into fact table with transformations
-- Only include rows where PWSID exists in dim_water_system
INSERT INTO fact_water_violations (
    pwsid, violation_code, violation_category_code, is_health_based_ind,
    contaminant_code, viol_measure, unit_of_measure, federal_mcl,
    non_compl_per_begin_date, non_compl_per_end_date, violation_status, rule_code
)
SELECT
    sv.PWSID,
    sv.VIOLATION_CODE,
    sv.VIOLATION_CATEGORY_CODE,
    sv.IS_HEALTH_BASED_IND,
    sv.CONTAMINANT_CODE,
    CASE WHEN sv.VIOL_MEASURE REGEXP '^-?[0-9]+\\.?[0-9]*$' THEN CAST(sv.VIOL_MEASURE AS DECIMAL(15,5)) ELSE NULL END,
    sv.UNIT_OF_MEASURE,
    sv.FEDERAL_MCL,
    CASE WHEN sv.NON_COMPL_PER_BEGIN_DATE != '' THEN STR_TO_DATE(sv.NON_COMPL_PER_BEGIN_DATE, '%m/%d/%Y') ELSE NULL END,
    CASE WHEN sv.NON_COMPL_PER_END_DATE != '' THEN STR_TO_DATE(sv.NON_COMPL_PER_END_DATE, '%m/%d/%Y') ELSE NULL END,
    sv.VIOLATION_STATUS,
    sv.RULE_CODE
FROM staging_water_violations sv
INNER JOIN dim_water_system w ON w.pwsid = sv.PWSID;

-- Step 5: Verify
SELECT COUNT(*) AS fact_row_count FROM fact_water_violations;