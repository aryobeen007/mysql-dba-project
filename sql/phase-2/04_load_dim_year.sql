-- ============================================================
-- Project  : MySQL DBA
-- Author   : Naseer Aryobee
-- Script   : 04_load_dim_year.sql
-- Purpose  : Populate dim_year for years 1980-2026 to cover
--            the full range across all datasets
-- ============================================================

USE cancer_environment_db;

INSERT INTO dim_year (year_id, decade)
SELECT
    yr AS year_id,
    CONCAT(FLOOR(yr / 10) * 10, 's') AS decade
FROM (
    SELECT 1980 + n AS yr
    FROM (
        SELECT a.N + b.N * 10 + c.N * 100 AS n
        FROM
            (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) a,
            (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) b,
            (SELECT 0 AS N) c
    ) numbers
    WHERE 1980 + n <= 2026
) years;
