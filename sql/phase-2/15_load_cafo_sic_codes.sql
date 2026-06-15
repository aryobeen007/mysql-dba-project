-- ============================================================
-- Project  : MySQL DBA
-- Author   : Naseer Aryobee
-- Script   : 15_load_cafo_sic_codes.sql
-- Purpose  : Load EPA NPDES SIC codes into fact_cafo_sic_codes
-- ============================================================

USE cancer_environment_db;

-- Step 1: Create staging table
CREATE TABLE staging_cafo_sic (
    NPDES_ID VARCHAR(20),
    SIC_CODE VARCHAR(10),
    SIC_DESC VARCHAR(255),
    PRIMARY_INDICATOR_FLAG CHAR(1)
);

-- Step 2: Load raw CSV into staging table
LOAD DATA LOCAL INFILE 'C:/Users/User/Desktop/mysql-dba-project/data/raw/cafo/npdes_extracted/NPDES_SICS.csv'
INTO TABLE staging_cafo_sic
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Step 3: Verify staging load
SELECT COUNT(*) AS staging_row_count FROM staging_cafo_sic;

-- Step 4: Insert into fact table
INSERT INTO fact_cafo_sic_codes (
    npdes_id, sic_code, sic_desc, primary_indicator_flag
)
SELECT
    NPDES_ID,
    SIC_CODE,
    SIC_DESC,
    PRIMARY_INDICATOR_FLAG
FROM staging_cafo_sic;

-- Step 5: Verify
SELECT COUNT(*) AS fact_row_count FROM fact_cafo_sic_codes;

-- Step 6: Quick check on agricultural SIC codes
SELECT sic_code, sic_desc, COUNT(*) AS facility_count
FROM fact_cafo_sic_codes
WHERE sic_code IN ('0211','0212','0213','0214','0241','0251','0252','0259','0272')
GROUP BY sic_code, sic_desc
ORDER BY facility_count DESC;

-- Step 7: Cleanup
DROP TABLE staging_cafo_sic;