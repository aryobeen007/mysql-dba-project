-- =============================================================================
-- Project:  MySQL DBA
-- Author:   Naseer Aryobee
-- Script:   01_optimize_indexes.sql
-- Phase:    4 — Performance Optimization
-- Purpose:  Add composite indexes to fix Q4 (9m 42s) and Q5 (4,658ms)
--           identified during Phase 3 baseline diagnostics.
-- =============================================================================

USE cancer_environment_db;

-- -----------------------------------------------------------------------------
-- Index 1: fact_water_violations — fix Q4
-- -----------------------------------------------------------------------------
-- Problem:  Q4 performed a full nested-loop scan through 15.3M rows.
--           The optimizer applied the is_health_based_ind filter only after
--           joining to dim_water_system and dim_state, making the join
--           extremely expensive.
--
-- Fix:      A composite index on (is_health_based_ind, pwsid) lets the
--           optimizer pre-filter to health-based violations first, then
--           use pwsid to join directly to dim_water_system — eliminating
--           the full table scan entirely.
--
-- Note:     is_health_based_ind is placed first because it is the equality
--           filter (WHERE is_health_based_ind = 'Y'). pwsid is placed second
--           to support the subsequent join. This follows the ESR rule:
--           Equality → Sort → Range.
-- -----------------------------------------------------------------------------

ALTER TABLE fact_water_violations
    ADD INDEX idx_health_pwsid (is_health_based_ind, pwsid);

-- -----------------------------------------------------------------------------
-- Index 2: dim_cafo_facility — fix Q5
-- -----------------------------------------------------------------------------
-- Problem:  Q5 aggregated CAFO facilities by state, counting rows where
--           impaired_waters = 'Y'. The optimizer ignored the existing
--           state_id index due to low cardinality on impaired_waters,
--           resulting in a 1.1M row full table scan.
--
-- Fix:      A composite index on (state_id, impaired_waters) gives the
--           optimizer a single index to handle both the GROUP BY state_id
--           aggregation and the impaired_waters filter together, avoiding
--           the full scan.
--
-- Note:     state_id leads because it drives the GROUP BY. impaired_waters
--           follows so the optimizer can apply the equality filter without
--           touching the base table.
-- -----------------------------------------------------------------------------

ALTER TABLE dim_cafo_facility
    ADD INDEX idx_state_impaired (state_id, impaired_waters);

-- -----------------------------------------------------------------------------
-- Verification — confirm both indexes are present
-- -----------------------------------------------------------------------------

SHOW INDEX FROM fact_water_violations
WHERE Key_name = 'idx_health_pwsid';

SHOW INDEX FROM dim_cafo_facility
WHERE Key_name = 'idx_state_impaired';