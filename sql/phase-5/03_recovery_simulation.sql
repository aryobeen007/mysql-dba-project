-- =============================================================================
-- Project:  MySQL DBA
-- Author:   Naseer Aryobee
-- Script:   03_recovery_simulation.sql
-- Phase:    5 — Backup and Recovery
-- Purpose:  Simulate a recovery scenario by dropping and restoring
--           cancer_environment_db from the full mysqldump backup.
--           Documents row counts before and after to verify data integrity.
-- =============================================================================

-- =============================================================================
-- PRE-RECOVERY — Record row counts before drop
-- Run this block FIRST and save the output before proceeding.
-- =============================================================================

USE cancer_environment_db;

SELECT
    table_name,
    table_rows AS estimated_rows
FROM information_schema.tables
WHERE table_schema = 'cancer_environment_db'
ORDER BY table_rows DESC;

-- =============================================================================
-- RECOVERY SIMULATION — Run from PowerShell, not DataGrip
-- =============================================================================
--
-- Step 1 — Drop the database (simulates data loss event):
--
--   & "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" `
--       --user=root --password `
--       --execute="DROP DATABASE cancer_environment_db;"
--
-- Step 2 — Restore from backup (replace filename with your actual backup file):
--
--   & "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" `
--       --user=root --password `
--       < "C:\Users\User\Desktop\mysql-dba-project\backups\cancer_environment_db_full_20260624_133040.sql"
--
-- Note: The restore of a 2.18 GB dump file will take several minutes.
--       MySQL will recreate the database, all tables, indexes, and data.
--
-- =============================================================================

-- =============================================================================
-- POST-RECOVERY — Verify row counts match pre-recovery baseline
-- Run this block AFTER the restore completes.
-- =============================================================================

USE cancer_environment_db;

SELECT
    table_name,
    table_rows AS estimated_rows
FROM information_schema.tables
WHERE table_schema = 'cancer_environment_db'
ORDER BY table_rows DESC;

-- -----------------------------------------------------------------------------
-- Final integrity check — verify key table counts exactly
-- -----------------------------------------------------------------------------

SELECT 'fact_water_violations'           AS table_name, COUNT(*) AS exact_rows FROM fact_water_violations
UNION ALL
SELECT 'fact_livestock_operations',                     COUNT(*) FROM fact_livestock_operations
UNION ALL
SELECT 'dim_cafo_facility',                             COUNT(*) FROM dim_cafo_facility
UNION ALL
SELECT 'fact_food_environment',                         COUNT(*) FROM fact_food_environment
UNION ALL
SELECT 'fact_cafo_sic_codes',                           COUNT(*) FROM fact_cafo_sic_codes
UNION ALL
SELECT 'fact_cafo_violations',                          COUNT(*) FROM fact_cafo_violations
UNION ALL
SELECT 'dim_water_system',                              COUNT(*) FROM dim_water_system
UNION ALL
SELECT 'fact_chronic_disease_indicators',               COUNT(*) FROM fact_chronic_disease_indicators
UNION ALL
SELECT 'fact_air_quality',                              COUNT(*) FROM fact_air_quality
UNION ALL
SELECT 'dim_county',                                    COUNT(*) FROM dim_county
UNION ALL
SELECT 'fact_cancer_incidence',                         COUNT(*) FROM fact_cancer_incidence
UNION ALL
SELECT 'fact_cancer_mortality',                         COUNT(*) FROM fact_cancer_mortality
UNION ALL
SELECT 'dim_state',                                     COUNT(*) FROM dim_state
UNION ALL
SELECT 'dim_year',                                      COUNT(*) FROM dim_year;