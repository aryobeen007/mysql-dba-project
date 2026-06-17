-- =============================================================================
-- Project:  MySQL DBA
-- Author:   Naseer Aryobee
-- Script:   06_additional_indexes.sql
-- Phase:    4 — Performance Optimization
-- Purpose:  Add indexes identified as necessary after the before/after
--           comparison in 05_before_after_comparison.sql revealed regressions
--           in Q6 caused by the removal of idx_question during the audit.
-- =============================================================================

USE cancer_environment_db;

-- -----------------------------------------------------------------------------
-- Background
-- -----------------------------------------------------------------------------
-- During the index audit in 03_index_audit.sql, idx_question on
-- fact_chronic_disease_indicators was identified as unused by
-- sys.schema_unused_indexes and dropped. However, the before/after
-- comparison revealed that Q6 regressed from 244 ms to 18,114 ms after
-- the drop.
--
-- Investigation showed the root cause was not the missing index alone —
-- the original Q6 query design caused a cross join between
-- fact_chronic_disease_indicators (375K rows) and fact_cancer_incidence
-- (1,218 rows) before aggregating. The query was rewritten using subqueries
-- to pre-aggregate each fact table separately before joining.
--
-- A composite index on (state_id, question) is added here to support the
-- rewritten Q6 subquery, which filters on question and groups by state_id.
-- This replaces the dropped single-column idx_question with a more useful
-- composite index that covers both the filter and the GROUP BY.
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- Index — fact_chronic_disease_indicators
-- -----------------------------------------------------------------------------
-- Supports the rewritten Q6 subquery:
--   WHERE question LIKE '%Smoking%' GROUP BY state_id
--
-- Note: The leading wildcard in LIKE '%Smoking%' prevents index use for
--   the filter itself, but state_id leading the index allows the optimizer
--   to use it for the GROUP BY aggregation, reducing the sort overhead.
-- -----------------------------------------------------------------------------

ALTER TABLE fact_chronic_disease_indicators
    ADD INDEX idx_state_question (state_id, question);

-- -----------------------------------------------------------------------------
-- Verification
-- -----------------------------------------------------------------------------

SHOW INDEX FROM fact_chronic_disease_indicators
WHERE Key_name = 'idx_state_question';