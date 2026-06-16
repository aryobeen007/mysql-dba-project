-- =============================================================================
-- Project:  MySQL DBA
-- Author:   Naseer Aryobee
-- Script:   03_index_audit.sql
-- Phase:    4 — Performance Optimization
-- Purpose:  Audit all indexes in cancer_environment_db for usage and
--           redundancy. Drop unused and redundant indexes to reclaim space
--           and reduce write overhead on INSERT/UPDATE/DELETE operations.
-- =============================================================================

USE cancer_environment_db;

-- -----------------------------------------------------------------------------
-- Step 1 — Full index inventory
-- -----------------------------------------------------------------------------
-- Run before any drops to establish baseline index count and size.
-- Result: 57 indexes across 14 tables.
-- -----------------------------------------------------------------------------

SELECT
    s.table_name,
    s.index_name,
    s.column_name,
    s.seq_in_index,
    s.cardinality,
    s.nullable,
    s.index_type,
    ROUND(t.index_length / 1024 / 1024, 2) AS index_size_mb
FROM information_schema.statistics s
JOIN information_schema.tables t
    ON s.table_schema = t.table_schema
    AND s.table_name = t.table_name
WHERE s.table_schema = 'cancer_environment_db'
ORDER BY s.table_name, s.index_name, s.seq_in_index;


-- -----------------------------------------------------------------------------
-- Step 2 — Unused index check via sys.schema_unused_indexes
-- -----------------------------------------------------------------------------
-- Identifies indexes not selected by the optimizer since last service restart.
-- Result: 13 unused indexes identified.
-- -----------------------------------------------------------------------------

SELECT *
FROM sys.schema_unused_indexes
WHERE object_schema = 'cancer_environment_db';


-- -----------------------------------------------------------------------------
-- Step 3 — Redundant index check via sys.schema_redundant_indexes
-- -----------------------------------------------------------------------------
-- Identifies indexes where one is a left-prefix of another on the same table.
-- Result: 2 redundant indexes identified:
--   idx_impaired on dim_cafo_facility — made redundant by idx_impaired_state
--   idx_health_based on fact_water_violations — made redundant by idx_health_pwsid
-- -----------------------------------------------------------------------------

SELECT
    table_schema,
    table_name,
    redundant_index_name,
    redundant_index_columns,
    dominant_index_name,
    dominant_index_columns,
    subpart_exists
FROM sys.schema_redundant_indexes
WHERE table_schema = 'cancer_environment_db';


-- -----------------------------------------------------------------------------
-- Step 4 — Drop redundant indexes
-- -----------------------------------------------------------------------------

ALTER TABLE dim_cafo_facility
    DROP INDEX idx_impaired;

ALTER TABLE fact_water_violations
    DROP INDEX idx_health_based;


-- -----------------------------------------------------------------------------
-- Step 5 — Drop unused indexes
-- -----------------------------------------------------------------------------
-- Three indexes could not be dropped due to foreign key constraints:
--   idx_county on dim_cafo_facility    — FK on county_id
--   idx_state_impaired on dim_cafo_facility — FK on state_id
--   idx_pwsid on fact_water_violations — FK on pwsid
-- These are retained and documented as FK-protected indexes.
-- -----------------------------------------------------------------------------

ALTER TABLE dim_cafo_facility
    DROP INDEX idx_npdes_id;

ALTER TABLE fact_cafo_sic_codes
    DROP INDEX idx_npdes_id;

ALTER TABLE fact_cafo_violations
    DROP INDEX idx_npdes_id;

ALTER TABLE fact_cafo_violations
    DROP INDEX idx_pollutant;

ALTER TABLE fact_chronic_disease_indicators
    DROP INDEX idx_question;

ALTER TABLE fact_livestock_operations
    DROP INDEX idx_commodity;

ALTER TABLE fact_water_violations
    DROP INDEX idx_contaminant;

ALTER TABLE fact_water_violations
    DROP INDEX idx_noncompl_dates;


-- -----------------------------------------------------------------------------
-- Step 6 — Verification
-- -----------------------------------------------------------------------------
-- Confirm final index state. Result: 46 indexes remaining across 14 tables.
-- Dropped: 11 indexes (2 redundant + 9 unused)
-- Retained due to FK constraints: idx_county, idx_state_impaired,
--   idx_pwsid (3 indexes)
-- -----------------------------------------------------------------------------

SELECT
    s.table_name,
    s.index_name,
    s.column_name,
    s.seq_in_index,
    s.cardinality,
    s.index_type
FROM information_schema.statistics s
WHERE s.table_schema = 'cancer_environment_db'
ORDER BY s.table_name, s.index_name, s.seq_in_index;