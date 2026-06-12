-- ============================================================
-- Project  : MySQL DBA
-- Author   : Naseer Aryobee
-- Script   : 09_load_chronic_disease.sql
-- Purpose  : Load CDC Chronic Disease Indicators (115 metrics)
--            into a staging table, then transform and insert
--            into fact_chronic_disease_indicators
-- ============================================================

USE cancer_environment_db;

-- Step 1: Create staging table matching raw CSV structure
CREATE TABLE staging_chronic_disease (
    YearStart VARCHAR(10),
    YearEnd VARCHAR(10),
    LocationAbbr VARCHAR(10),
    LocationDesc VARCHAR(100),
    DataSource VARCHAR(50),
    Topic VARCHAR(100),
    Question VARCHAR(255),
    Response VARCHAR(100),
    DataValueUnit VARCHAR(50),
    DataValueType VARCHAR(50),
    DataValue VARCHAR(20),
    DataValueAlt VARCHAR(20),
    DataValueFootnoteSymbol VARCHAR(10),
    DataValueFootnote VARCHAR(255),
    LowConfidenceLimit VARCHAR(20),
    HighConfidenceLimit VARCHAR(20),
    StratificationCategory1 VARCHAR(50),
    Stratification1 VARCHAR(50),
    StratificationCategory2 VARCHAR(50),
    Stratification2 VARCHAR(50),
    StratificationCategory3 VARCHAR(50),
    Stratification3 VARCHAR(50),
    Geolocation VARCHAR(100),
    LocationID VARCHAR(10),
    TopicID VARCHAR(20),
    QuestionID VARCHAR(20),
    ResponseID VARCHAR(20),
    DataValueTypeID VARCHAR(20),
    StratificationCategoryID1 VARCHAR(20),
    StratificationID1 VARCHAR(20),
    StratificationCategoryID2 VARCHAR(20),
    StratificationID2 VARCHAR(20),
    StratificationCategoryID3 VARCHAR(20),
    StratificationID3 VARCHAR(20)
);

-- Step 2: Load raw CSV into staging table
LOAD DATA LOCAL INFILE 'C:/Users/User/Desktop/mysql-dba-project/data/raw/public-health/cdc_chronic_disease_indicators_all_states.csv'
INTO TABLE staging_chronic_disease
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- Step 3: Verify staging load
SELECT COUNT(*) AS staging_row_count FROM staging_chronic_disease;




-- Step 4: Insert into fact table with transformations
-- Only include rows where state matches our dim_state (excludes US, territories not in our list)
INSERT INTO fact_chronic_disease_indicators (
    state_id, year_start, year_end, topic, question,
    data_value_type, data_value, low_confidence_limit,
    high_confidence_limit, stratification_category, stratification
)
SELECT
    s.state_id,
    CAST(sc.YearStart AS UNSIGNED),
    CAST(sc.YearEnd AS UNSIGNED),
    sc.Topic,
    sc.Question,
    sc.DataValueType,
    CASE WHEN sc.DataValue REGEXP '^-?[0-9]+\\.?[0-9]*$' THEN CAST(sc.DataValue AS DECIMAL(10,2)) ELSE NULL END,
    CASE WHEN sc.LowConfidenceLimit REGEXP '^-?[0-9]+\\.?[0-9]*$' THEN CAST(sc.LowConfidenceLimit AS DECIMAL(10,2)) ELSE NULL END,
    CASE WHEN sc.HighConfidenceLimit REGEXP '^-?[0-9]+\\.?[0-9]*$' THEN CAST(sc.HighConfidenceLimit AS DECIMAL(10,2)) ELSE NULL END,
    sc.StratificationCategory1,
    sc.Stratification1
FROM staging_chronic_disease sc
JOIN dim_state s ON s.state_abbr = sc.LocationAbbr;

-- Step 5: Verify
SELECT COUNT(*) AS fact_row_count FROM fact_chronic_disease_indicators;

-- Step 6: Cleanup
DROP TABLE staging_chronic_disease;