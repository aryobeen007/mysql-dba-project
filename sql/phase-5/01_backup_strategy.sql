-- =============================================================================
-- Project:  MySQL DBA
-- Author:   Naseer Aryobee
-- Script:   01_backup_strategy.sql
-- Phase:    5 — Backup and Recovery
-- Purpose:  Document and verify the backup environment before implementing
--           the mysqldump backup strategy for cancer_environment_db.
-- =============================================================================

USE cancer_environment_db;

-- -----------------------------------------------------------------------------
-- Step 1 — Verify MySQL version and backup tool availability
-- -----------------------------------------------------------------------------

SELECT VERSION() AS mysql_version;

-- -----------------------------------------------------------------------------
-- Step 2 — Database size snapshot before backup
-- -----------------------------------------------------------------------------
-- Establishes the size we need to account for in backup storage planning.
-- -----------------------------------------------------------------------------

SELECT
    table_schema                                                        AS database_name,
    COUNT(*)                                                            AS total_tables,
    ROUND(SUM(data_length) / 1024 / 1024, 2)                          AS data_mb,
    ROUND(SUM(index_length) / 1024 / 1024, 2)                         AS index_mb,
    ROUND(SUM(data_length + index_length) / 1024 / 1024, 2)           AS total_mb,
    ROUND(SUM(data_length + index_length) / 1024 / 1024 / 1024, 2)   AS total_gb
FROM information_schema.tables
WHERE table_schema = 'cancer_environment_db'
GROUP BY table_schema;

-- -----------------------------------------------------------------------------
-- Step 3 — Table row counts for backup verification reference
-- -----------------------------------------------------------------------------
-- After a restore, I will compare these counts to confirm data integrity.
-- -----------------------------------------------------------------------------

SELECT
    table_name,
    table_rows AS estimated_rows
FROM information_schema.tables
WHERE table_schema = 'cancer_environment_db'
ORDER BY table_rows DESC;

-- -----------------------------------------------------------------------------
-- Step 4 — Verify binary logging status
-- -----------------------------------------------------------------------------
-- Binary logging is required for point-in-time recovery.
-- Documents whether binlog is enabled on this instance.
-- -----------------------------------------------------------------------------

SHOW VARIABLES LIKE 'log_bin';
SHOW VARIABLES LIKE 'binlog_format';
SHOW VARIABLES LIKE 'expire_logs_days';
SHOW VARIABLES LIKE 'binlog_expire_logs_seconds';

-- -----------------------------------------------------------------------------
-- Step 5 — Verify InnoDB settings relevant to backup consistency
-- -----------------------------------------------------------------------------

SHOW VARIABLES LIKE 'innodb_flush_log_at_trx_commit';
SHOW VARIABLES LIKE 'transaction_isolation';