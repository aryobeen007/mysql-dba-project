-- ============================================================
-- Project  : MySQL DBA
-- Author   : Naseer Aryobee
-- Script   : 02_create_tables.sql
-- Purpose  : Create all dimension and fact tables for the
--            cancer environment database
-- ============================================================

USE cancer_environment_db;

-- ============================================================
-- DIMENSION TABLES
-- ============================================================

CREATE TABLE dim_state (
    state_id INT AUTO_INCREMENT PRIMARY KEY,
    state_fips CHAR(2) NOT NULL UNIQUE,
    state_abbr CHAR(2) NOT NULL,
    state_name VARCHAR(50) NOT NULL
);

CREATE TABLE dim_county (
    county_id INT AUTO_INCREMENT PRIMARY KEY,
    state_id INT NOT NULL,
    county_fips CHAR(3) NOT NULL,
    county_name VARCHAR(100) NOT NULL,
    FOREIGN KEY (state_id) REFERENCES dim_state(state_id),
    UNIQUE KEY uq_state_county (state_id, county_fips)
);

CREATE TABLE dim_year (
    year_id INT PRIMARY KEY,
    decade VARCHAR(10) NOT NULL
);

-- ============================================================
-- PUBLIC HEALTH FACT TABLES
-- ============================================================

CREATE TABLE fact_cancer_incidence (
    incidence_id INT AUTO_INCREMENT PRIMARY KEY,
    state_id INT NOT NULL,
    year_id INT NOT NULL,
    case_count INT,
    population INT,
    age_adjusted_rate DECIMAL(6,1),
    FOREIGN KEY (state_id) REFERENCES dim_state(state_id),
    FOREIGN KEY (year_id) REFERENCES dim_year(year_id),
    UNIQUE KEY uq_state_year (state_id, year_id)
);

CREATE TABLE fact_cancer_mortality (
    mortality_id INT AUTO_INCREMENT PRIMARY KEY,
    state_id INT NOT NULL,
    year_id INT NOT NULL,
    death_count INT,
    population INT,
    age_adjusted_rate DECIMAL(6,1),
    FOREIGN KEY (state_id) REFERENCES dim_state(state_id),
    FOREIGN KEY (year_id) REFERENCES dim_year(year_id),
    UNIQUE KEY uq_state_year_mortality (state_id, year_id)
);

CREATE TABLE fact_chronic_disease_indicators (
    indicator_id INT AUTO_INCREMENT PRIMARY KEY,
    state_id INT NOT NULL,
    year_start INT NOT NULL,
    year_end INT NOT NULL,
    topic VARCHAR(100),
    question VARCHAR(255),
    data_value_type VARCHAR(50),
    data_value DECIMAL(10,2),
    low_confidence_limit DECIMAL(10,2),
    high_confidence_limit DECIMAL(10,2),
    stratification_category VARCHAR(50),
    stratification VARCHAR(50),
    FOREIGN KEY (state_id) REFERENCES dim_state(state_id),
    INDEX idx_topic (topic),
    INDEX idx_question (question(100))
);

-- ============================================================
-- ENVIRONMENTAL FACT TABLES
-- ============================================================

CREATE TABLE fact_air_quality (
    air_quality_id INT AUTO_INCREMENT PRIMARY KEY,
    county_id INT NOT NULL,
    year_id INT NOT NULL,
    days_with_aqi INT,
    good_days INT,
    moderate_days INT,
    unhealthy_sensitive_days INT,
    unhealthy_days INT,
    very_unhealthy_days INT,
    hazardous_days INT,
    max_aqi INT,
    percentile_90_aqi INT,
    median_aqi INT,
    days_co INT,
    days_no2 INT,
    days_ozone INT,
    days_pm25 INT,
    days_pm10 INT,
    FOREIGN KEY (county_id) REFERENCES dim_county(county_id),
    FOREIGN KEY (year_id) REFERENCES dim_year(year_id),
    UNIQUE KEY uq_county_year_aqi (county_id, year_id)
);

CREATE TABLE fact_food_environment (
    food_env_id INT AUTO_INCREMENT PRIMARY KEY,
    county_id INT NOT NULL,
    variable_code VARCHAR(50) NOT NULL,
    value DECIMAL(15,5),
    FOREIGN KEY (county_id) REFERENCES dim_county(county_id),
    UNIQUE KEY uq_county_variable (county_id, variable_code),
    INDEX idx_variable_code (variable_code)
);

-- ============================================================
-- WATER QUALITY TABLES
-- ============================================================

CREATE TABLE dim_water_system (
    pwsid VARCHAR(20) PRIMARY KEY,
    pws_name VARCHAR(255),
    state_id INT,
    county_id INT,
    population_served INT,
    owner_type_code CHAR(1),
    pws_type_code VARCHAR(10),
    primary_source_code VARCHAR(10),
    FOREIGN KEY (state_id) REFERENCES dim_state(state_id),
    FOREIGN KEY (county_id) REFERENCES dim_county(county_id),
    INDEX idx_county (county_id)
);

CREATE TABLE fact_water_violations (
    violation_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    pwsid VARCHAR(20) NOT NULL,
    violation_code VARCHAR(10),
    violation_category_code VARCHAR(10),
    is_health_based_ind CHAR(1),
    contaminant_code VARCHAR(10),
    viol_measure DECIMAL(15,5),
    unit_of_measure VARCHAR(20),
    federal_mcl VARCHAR(50),
    non_compl_per_begin_date DATE,
    non_compl_per_end_date DATE,
    violation_status VARCHAR(20),
    rule_code VARCHAR(10),
    FOREIGN KEY (pwsid) REFERENCES dim_water_system(pwsid),
    INDEX idx_pwsid (pwsid),
    INDEX idx_contaminant (contaminant_code),
    INDEX idx_health_based (is_health_based_ind),
    INDEX idx_noncompl_dates (non_compl_per_begin_date, non_compl_per_end_date)
);

-- ============================================================
-- CAFO / AGRICULTURE TABLES
-- ============================================================

CREATE TABLE fact_livestock_operations (
    operation_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    county_id INT NOT NULL,
    commodity_desc VARCHAR(50) NOT NULL,
    class_desc VARCHAR(50),
    statisticcat_desc VARCHAR(50),
    unit_desc VARCHAR(50),
    domain_desc VARCHAR(100),
    domaincat_desc VARCHAR(255),
    year_id INT NOT NULL,
    value_text VARCHAR(50),
    FOREIGN KEY (county_id) REFERENCES dim_county(county_id),
    FOREIGN KEY (year_id) REFERENCES dim_year(year_id),
    INDEX idx_commodity (commodity_desc),
    INDEX idx_county_year (county_id, year_id)
);

CREATE TABLE dim_cafo_facility (
    facility_id BIGINT PRIMARY KEY,
    npdes_id VARCHAR(20) NOT NULL,
    facility_name VARCHAR(255),
    location_address VARCHAR(255),
    city VARCHAR(100),
    county_id INT,
    state_id INT,
    zip VARCHAR(10),
    latitude DECIMAL(10,6),
    longitude DECIMAL(10,6),
    impaired_waters VARCHAR(50),
    FOREIGN KEY (county_id) REFERENCES dim_county(county_id),
    FOREIGN KEY (state_id) REFERENCES dim_state(state_id),
    INDEX idx_npdes_id (npdes_id),
    INDEX idx_county (county_id),
    INDEX idx_impaired (impaired_waters)
);

CREATE TABLE fact_cafo_sic_codes (
    sic_record_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    npdes_id VARCHAR(20) NOT NULL,
    sic_code VARCHAR(10) NOT NULL,
    sic_desc VARCHAR(255),
    primary_indicator_flag CHAR(1),
    INDEX idx_npdes_id (npdes_id),
    INDEX idx_sic_code (sic_code)
);

CREATE TABLE fact_cafo_violations (
    violation_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    npdes_id VARCHAR(20) NOT NULL,
    violation_type VARCHAR(50),
    violation_short_desc VARCHAR(255),
    pollutant_code VARCHAR(20),
    pollutant_desc VARCHAR(255),
    exceedance_pct DECIMAL(10,2),
    monitoring_period_end_date DATE,
    rnc_detection_date DATE,
    INDEX idx_npdes_id (npdes_id),
    INDEX idx_pollutant (pollutant_code),
    INDEX idx_monitoring_date (monitoring_period_end_date)
);