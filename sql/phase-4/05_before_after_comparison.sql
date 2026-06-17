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
-- Baseline: 12 ms | Optimized: 23 ms
-- Note: Small table, no optimization needed. Slight variance is normal.
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
-- Baseline: 16 ms | Optimized: 8 ms
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
-- Baseline: 293 ms | Initial rerun: 903 ms | Optimized: 58 ms
-- Fix: Rewrote using subqueries to pre-aggregate each fact table separately
--      before joining, eliminating the cross join between fact_air_quality
--      and fact_cancer_incidence that caused the regression.
-- -----------------------------------------------------------------------------

SELECT
    s.state_name,
    aq.avg_good_air_days,
    aq.avg_unhealthy_days,
    ci.avg_cancer_rate
FROM dim_state s
JOIN (
    SELECT
        c.state_id,
        ROUND(AVG(aq.good_days), 1)      AS avg_good_air_days,
        ROUND(AVG(aq.unhealthy_days), 1) AS avg_unhealthy_days
    FROM fact_air_quality aq
    JOIN dim_county c ON aq.county_id = c.county_id
    GROUP BY c.state_id
) aq ON aq.state_id = s.state_id
JOIN (
    SELECT
        state_id,
        ROUND(AVG(age_adjusted_rate), 2) AS avg_cancer_rate
    FROM fact_cancer_incidence
    GROUP BY state_id
) ci ON ci.state_id = s.state_id
ORDER BY ci.avg_cancer_rate DESC;


-- -----------------------------------------------------------------------------
-- Q4 — Health-based water violations by state
-- Baseline: 9 min 42 sec | Optimized: 2,619 ms
-- Fix: CTE pre-filter + composite index idx_health_pwsid
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
-- Q5 — CAFO facilities near impaired waters by state
-- Baseline: 4,658 ms | Optimized: 165 ms
-- Fix: Subquery pre-aggregation + composite index idx_impaired_state
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
-- Baseline: 244 ms | Initial rerun: 18,114 ms | Optimized: 1,640 ms
-- Fix: Rewrote using subqueries to pre-aggregate each fact table separately
--      before joining. Leading wildcard LIKE '%Smoking%' prevents index use
--      on question column, but subquery rewrite eliminates the cross join
--      that caused the 18-second regression.
-- -----------------------------------------------------------------------------

SELECT
    s.state_name,
    sm.avg_smoking_pct,
    ci.avg_cancer_rate
FROM dim_state s
JOIN (
    SELECT
        state_id,
        ROUND(AVG(data_value), 1) AS avg_smoking_pct
    FROM fact_chronic_disease_indicators
    WHERE question LIKE '%Smoking%'
    GROUP BY state_id
) sm ON sm.state_id = s.state_id
JOIN (
    SELECT
        state_id,
        ROUND(AVG(age_adjusted_rate), 2) AS avg_cancer_rate
    FROM fact_cancer_incidence
    GROUP BY state_id
) ci ON ci.state_id = s.state_id
ORDER BY ci.avg_cancer_rate DESC;