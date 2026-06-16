-- =============================================================================
-- Project:  MySQL DBA
-- Author:   Naseer Aryobee
-- Script:   02_optimized_queries.sql
-- Phase:    4 — Performance Optimization
-- Purpose:  Rewritten Q4 and Q5 to take advantage of the composite indexes
--           added in 01_optimize_indexes.sql. Includes before/after timing
--           comments for documentation reference.
-- =============================================================================

USE cancer_environment_db;

-- -----------------------------------------------------------------------------
-- Q4 OPTIMIZED — Health-based water violations by state
-- -----------------------------------------------------------------------------
-- Baseline:  9 min 42 sec
-- Problem:   Full nested-loop scan through 15.3M violations after joining
--            to dim_water_system and dim_state. is_health_based_ind filter
--            applied too late in the join order.
--
-- Fix:       CTE pre-filters fact_water_violations to health-based rows only
--            using the new idx_health_pwsid index before any joins occur.
--            The optimizer hits the index on is_health_based_ind = 'Y' first,
--            returning a fraction of the 15.3M rows, then joins that small
--            result set to dim_water_system and dim_state.
--
-- Result:    2 sec 544 ms — 99.6% improvement over baseline.
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
JOIN dim_water_system ws ON hv.pwsid = ws.pwsid
JOIN dim_state s         ON ws.state_id = s.state_id
GROUP BY s.state_name
ORDER BY total_violations DESC;


-- -----------------------------------------------------------------------------
-- Q5 OPTIMIZED — CAFO facilities near impaired waters by state
-- -----------------------------------------------------------------------------
-- Baseline:  4,658 ms
-- Problem:   Optimizer ignored state_id index on dim_cafo_facility due to
--            low cardinality on impaired_waters, causing a 1.1M row full
--            table scan followed by a GROUP BY sort.
--
-- Fix:       Subquery pre-aggregates dim_cafo_facility using the composite
--            index idx_impaired_state (impaired_waters, state_id). Column
--            order was corrected after initial testing — placing impaired_waters
--            first aligns with the equality filter, allowing the optimizer to
--            satisfy both the WHERE and GROUP BY from the index alone.
--
-- Note:      impaired_waters stores '303(D) Listed' (EPA Section 303(d)
--            designation), not 'Y'. Discovered via DISTINCT value check
--            after Q5 returned 0 rows on first run.
--
-- Result:    464 ms — 90% improvement over baseline.
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