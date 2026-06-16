-- ============================================================
-- Project  : MySQL DBA
-- Author   : Naseer Aryobee
-- Script   : 01_baseline_database_size.sql
-- Purpose  : Capture baseline database and table size metrics
--            before any performance optimization
-- ============================================================

USE cancer_environment_db;

-- Total database size
SELECT 
    table_schema AS database_name,
    ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS total_size_mb,
    ROUND(SUM(data_length) / 1024 / 1024, 2) AS data_size_mb,
    ROUND(SUM(index_length) / 1024 / 1024, 2) AS index_size_mb
FROM information_schema.tables
WHERE table_schema = 'cancer_environment_db'
GROUP BY table_schema;

-- Per-table size breakdown
SELECT
    table_name,
    table_rows AS estimated_rows,
    ROUND(data_length / 1024 / 1024, 2) AS data_mb,
    ROUND(index_length / 1024 / 1024, 2) AS index_mb,
    ROUND((data_length + index_length) / 1024 / 1024, 2) AS total_mb
FROM information_schema.tables
WHERE table_schema = 'cancer_environment_db'
ORDER BY (data_length + index_length) DESC;

-- Index inventory -- what indexes exist before optimization
SELECT
    TABLE_NAME,
    INDEX_NAME,
    COLUMN_NAME,
    NON_UNIQUE,
    INDEX_TYPE
FROM information_schema.statistics
WHERE TABLE_SCHEMA = 'cancer_environment_db'
ORDER BY TABLE_NAME, INDEX_NAME;