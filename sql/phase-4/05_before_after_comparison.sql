-- =============================================================================
-- Project:  MySQL DBA
-- Author:   Naseer Aryobee
-- Script:   05_before_after_comparison.sql
-- Phase:    4 — Performance Optimization
-- Purpose:  Re-run all 6 Phase 3 baseline queries after Phase 4 optimization
--           to measure and document performance improvements.
-- =============================================================================

USE cancer_environment_db;

-- -----------------------------------------------------------------------------
-- Q1 — Cancer incidence trend by state
-- Baseline: 12 ms
-- -----------------------------------------------------------------------------

SELECT
    s.state_name,
    y.year_id,
    ci.age_adjusted_rate
FROM fact_cancer_incidence ci
JOIN dim_state s  ON ci.state_id = s.state_id
JOIN dim_year y   ON ci.year_id  = y.year_id
ORDER BY s.state_name, y.year_id;


-- -----------------------------------------------------------------------------
-- Q2 — States with highest average cancer rate
-- Baseline: 16 ms
-- -----------------------------------------------------------------------------

SELECT
    s.state_name,
    ROUND(AVG(ci.age_adjusted_rate), 2) AS avg_cancer_rate
FROM fact_cancer_incidence ci
JOIN dim_state s ON ci.state_id = s.state_id
GROUP BY s.state_name
ORDER BY avg_cancer_rate DESC;


-- -----------------------------------------------------------------------------
-- Q3 — Air quality vs cancer incidence by state
-- Baseline: 293 ms
-- -----------------------------------------------------------------------------

SELECT
    s.state_name,
    ROUND(AVG(aq.good_days), 1)         AS avg_good_air_days,
    ROUND(AVG(aq.unhealthy_days), 1)    AS avg_unhealthy_days,
    ROUND(AVG(ci.age_adjusted_rate), 2) AS avg_cancer_rate
FROM fact_air_quality aq
JOIN dim_county c  ON aq.county_id = c.county_id
JOIN dim_state s   ON c.state_id   = s.state_id
JOIN fact_cancer_incidence ci ON ci.state_id = s.state_id
GROUP BY s.state_name
ORDER BY avg_cancer_rate DESC;


-- -----------------------------------------------------------------------------
-- Q4 — Health-based water violations by state (OPTIMIZED)
-- Baseline: 9 min 42 sec
-- -----------------------------------------------------------------------------

WITH health_violations AS (
    SELECT
        pwsid,
        COUNT(*) AS violation_count
    FROM fact_water_violations
    WHERE is_health_based_ind = 'Y'
    GROUP BY pwsid
)
SELECT
    s.state_name,
    COUNT(DISTINCT hv.pwsid)   AS affected_systems,
    SUM(hv.violation_count)    AS total_violations
FROM health_violations hv
JOIN dim_water_system ws ON hv.pwsid    = ws.pwsid
JOIN dim_state s         ON ws.state_id = s.state_id
GROUP BY s.state_name
ORDER BY total_violations DESC;


-- -----------------------------------------------------------------------------
-- Q5 — CAFO facilities near impaired waters by state (OPTIMIZED)
-- Baseline: 4,658 ms
-- -----------------------------------------------------------------------------

SELECT
    s.state_name,
    cf.facility_count
FROM (
    SELECT
        state_id,
        COUNT(*) AS facility_count
    FROM dim_cafo_facility
    WHERE impaired_waters = '303(D) Listed'
    GROUP BY state_id
) cf
JOIN dim_state s ON cf.state_id = s.state_id
ORDER BY cf.facility_count DESC;


-- -----------------------------------------------------------------------------
-- Q6 — Smoking prevalence vs cancer rate by state
-- Baseline: 244 ms
-- -----------------------------------------------------------------------------

SELECT
    s.state_name,
    ROUND(AVG(CASE WHEN cd.question LIKE '%Smoking%' THEN cd.data_value END), 1) AS avg_smoking_pct,
    ROUND(AVG(ci.age_adjusted_rate), 2) AS avg_cancer_rate
FROM fact_chronic_disease_indicators cd
JOIN dim_state s ON cd.state_id = s.state_id
JOIN fact_cancer_incidence ci ON ci.state_id = s.state_id
GROUP BY s.state_name
ORDER BY avg_cancer_rate DESC;