-- ============================================================
-- Project  : MySQL DBA
-- Author   : Naseer Aryobee
-- Script   : 02_baseline_queries.sql
-- Purpose  : Run baseline diagnostic queries to establish
--            performance benchmarks before optimization
-- ============================================================

USE cancer_environment_db;

-- ============================================================
-- Q1: Cancer incidence trend by state (simple aggregation)
-- ============================================================
SELECT 
    s.state_name,
    f.year_id,
    f.case_count,
    f.age_adjusted_rate
FROM fact_cancer_incidence f
JOIN dim_state s ON s.state_id = f.state_id
WHERE f.year_id BETWEEN 2000 AND 2022
ORDER BY s.state_name, f.year_id;

-- ============================================================
-- Q2: States with highest average cancer incidence rate
-- ============================================================
SELECT 
    s.state_name,
    ROUND(AVG(f.age_adjusted_rate), 1) AS avg_age_adjusted_rate,
    SUM(f.case_count) AS total_cases
FROM fact_cancer_incidence f
JOIN dim_state s ON s.state_id = f.state_id
GROUP BY s.state_name
ORDER BY avg_age_adjusted_rate DESC
LIMIT 10;

-- ============================================================
-- Q3: Air quality vs cancer incidence by state
-- (multi-table join across environmental and health data)
-- ============================================================
SELECT
    s.state_name,
    ROUND(AVG(aq.median_aqi), 1) AS avg_median_aqi,
    ROUND(AVG(aq.days_pm25), 1) AS avg_pm25_days,
    ROUND(AVG(ci.age_adjusted_rate), 1) AS avg_cancer_rate
FROM fact_air_quality aq
JOIN dim_county c ON c.county_id = aq.county_id
JOIN dim_state s ON s.state_id = c.state_id
JOIN fact_cancer_incidence ci ON ci.state_id = s.state_id
    AND ci.year_id = aq.year_id
GROUP BY s.state_name
ORDER BY avg_cancer_rate DESC
LIMIT 10;

-- ============================================================
-- Q4: Health-based drinking water violations by state
-- (large table scan on fact_water_violations)
-- ============================================================
SELECT
    s.state_name,
    COUNT(*) AS total_violations,
    SUM(CASE WHEN wv.is_health_based_ind = 'Y' THEN 1 ELSE 0 END) AS health_based_violations
FROM fact_water_violations wv
JOIN dim_water_system ws ON ws.pwsid = wv.pwsid
JOIN dim_state s ON s.state_id = ws.state_id
GROUP BY s.state_name
ORDER BY health_based_violations DESC
LIMIT 10;

-- ============================================================
-- Q5: CAFO facilities near impaired water bodies by state
-- ============================================================
SELECT
    s.state_name,
    COUNT(*) AS cafo_facilities,
    SUM(CASE WHEN f.impaired_waters = '303(D) Listed' THEN 1 ELSE 0 END) AS near_impaired_waters
FROM dim_cafo_facility f
JOIN dim_state s ON s.state_id = f.state_id
GROUP BY s.state_name
ORDER BY near_impaired_waters DESC
LIMIT 10;

-- ============================================================
-- Q6: Smoking prevalence vs cancer incidence by state
-- (cross-domain lifestyle + health join)
-- ============================================================
SELECT
    s.state_name,
    ROUND(AVG(CASE WHEN cd.question LIKE '%cigarette smoking%' 
              THEN cd.data_value END), 1) AS avg_smoking_rate,
    ROUND(AVG(ci.age_adjusted_rate), 1) AS avg_cancer_rate
FROM fact_chronic_disease_indicators cd
JOIN dim_state s ON s.state_id = cd.state_id
JOIN fact_cancer_incidence ci ON ci.state_id = cd.state_id
    AND ci.year_id BETWEEN cd.year_start AND cd.year_end
WHERE cd.topic = 'Tobacco'
GROUP BY s.state_name
ORDER BY avg_cancer_rate DESC
LIMIT 10;