-- =============================================================================
-- Project:  MySQL DBA
-- Author:   Naseer Aryobee
-- Script:   04_configuration_tuning.sql
-- Phase:    4 — Performance Optimization
-- Purpose:  Review and tune MySQL configuration settings relative to the
--           cancer_environment_db database size of 3.8 GB. Focus on
--           innodb_buffer_pool_size, innodb_buffer_pool_instances, and
--           max_connections.
-- =============================================================================

USE cancer_environment_db;

-- -----------------------------------------------------------------------------
-- Step 1 — Current configuration baseline
-- -----------------------------------------------------------------------------
-- Capture current values before making any changes.
-- -----------------------------------------------------------------------------

SHOW VARIABLES LIKE 'innodb_buffer_pool_size';
SHOW VARIABLES LIKE 'innodb_buffer_pool_instances';
SHOW VARIABLES LIKE 'innodb_buffer_pool_chunk_size';
SHOW VARIABLES LIKE 'max_connections';
SHOW VARIABLES LIKE 'innodb_log_file_size';
SHOW VARIABLES LIKE 'innodb_flush_log_at_trx_commit';
SHOW VARIABLES LIKE 'innodb_io_capacity';


-- -----------------------------------------------------------------------------
-- Step 2 — Buffer pool utilization
-- -----------------------------------------------------------------------------
-- Measure how effectively the current buffer pool is being used.
-- A high read hit ratio (close to 100%) means data is being served from
-- memory rather than disk. A low ratio means the buffer pool is too small.
--
-- Formula: hit ratio = 1 - (physical_reads / logical_reads)
-- -----------------------------------------------------------------------------

SELECT
    FORMAT(
        (1 - (
            (SELECT variable_value FROM performance_schema.global_status WHERE variable_name = 'Innodb_buffer_pool_reads') /
            (SELECT variable_value FROM performance_schema.global_status WHERE variable_name = 'Innodb_buffer_pool_read_requests')
        )) * 100, 4
    ) AS buffer_pool_hit_ratio_pct,
    FORMAT(
        (SELECT variable_value FROM performance_schema.global_status WHERE variable_name = 'Innodb_buffer_pool_reads'),
        0
    ) AS physical_disk_reads,
    FORMAT(
        (SELECT variable_value FROM performance_schema.global_status WHERE variable_name = 'Innodb_buffer_pool_read_requests'),
        0
    ) AS logical_reads;


-- -----------------------------------------------------------------------------
-- Step 3 — Buffer pool size vs database size
-- -----------------------------------------------------------------------------
-- Compare current buffer pool allocation against total database size.
-- Ideal: buffer pool should be large enough to hold the working data set.
-- Our database is 3.8 GB total (1.8 GB data + 2.0 GB indexes after audit).
-- -----------------------------------------------------------------------------

SELECT
    ROUND(@@innodb_buffer_pool_size / 1024 / 1024, 0)        AS buffer_pool_mb,
    ROUND(@@innodb_buffer_pool_size / 1024 / 1024 / 1024, 2) AS buffer_pool_gb,
    (
        SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024, 0)
        FROM information_schema.tables
        WHERE table_schema = 'cancer_environment_db'
    )                                                          AS database_size_mb,
    ROUND(
        @@innodb_buffer_pool_size /
        (SELECT SUM(data_length + index_length)
         FROM information_schema.tables
         WHERE table_schema = 'cancer_environment_db') * 100
    , 1)                                                       AS buffer_pool_pct_of_db;


-- -----------------------------------------------------------------------------
-- Step 4 — Connection utilization
-- -----------------------------------------------------------------------------
-- Review current and peak connection usage vs max_connections setting.
-- Helps right-size max_connections for a single-user portfolio environment.
-- -----------------------------------------------------------------------------

SHOW STATUS LIKE 'Max_used_connections';
SHOW STATUS LIKE 'Threads_connected';
SHOW STATUS LIKE 'Connection_errors_max_connections';


-- -----------------------------------------------------------------------------
-- Step 5 — Configuration tuning findings and recommendations
-- -----------------------------------------------------------------------------
-- Based on the review above, the following changes are recommended:
--
-- innodb_buffer_pool_size:
--   Default is 128 MB — covers only 2.8% of our 3.8 GB database.
--   Recommended value: 1G. Applied dynamically via SET GLOBAL and confirmed
--   active during the session. Not persisted to my.ini on this environment
--   due to Windows file permission constraints on the MySQL config file.
--
-- innodb_io_capacity:
--   Default 200 is tuned for spinning disks. Recommended value: 500 for SSD.
--   Applied dynamically via SET GLOBAL during the session.
--
-- innodb_buffer_pool_instances:
--   Read-only at runtime — can only be set at startup via my.ini.
--   Recommended value: 2 when buffer pool >= 1G.
--
-- max_connections:
--   Default 151 is appropriate. Peak usage was 5 connections.
--   No change needed for a single-user portfolio environment.
--
-- Note: On a production server these values would be persisted in my.ini.
--   For this portfolio environment, SET GLOBAL was used to demonstrate
--   the tuning approach. Recommended my.ini entries:
--
--   innodb_buffer_pool_size = 1G
--   innodb_buffer_pool_instances = 2
--   innodb_io_capacity = 500
-- -----------------------------------------------------------------------------

SET GLOBAL innodb_buffer_pool_size = 1073741824;   -- 1 GB
SET GLOBAL innodb_io_capacity = 500;

-- -----------------------------------------------------------------------------
-- Step 6 — Verify active settings
-- -----------------------------------------------------------------------------

SHOW VARIABLES LIKE 'innodb_buffer_pool_size';
SHOW VARIABLES LIKE 'innodb_buffer_pool_instances';
SHOW VARIABLES LIKE 'innodb_io_capacity';


-- -----------------------------------------------------------------------------
-- Step 7 — Persisting settings to my.ini
-- -----------------------------------------------------------------------------
-- SET GLOBAL applies changes for the current session only and resets on
-- service restart. To make changes permanent, the following entries need
-- to be added to the [mysqld] section of:
-- C:\ProgramData\MySQL\MySQL Server 8.0\my.ini
--
-- Recommended entries:
--   innodb_buffer_pool_size = 1G
--   innodb_buffer_pool_instances = 2
--   innodb_io_capacity = 500
--
-- Note: On this Windows environment, my.ini is protected by OS-level
--   permissions. Direct edits require admin PowerShell and care must be
--   taken to preserve the original file encoding (ASCII) to avoid
--   corrupting the config file. The dynamic SET GLOBAL approach
--   demonstrates the tuning intent. In a production Linux environment
--   these values would be written to /etc/mysql/my.cnf and persisted
--   with a service restart.
-- -----------------------------------------------------------------------------