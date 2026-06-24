-- =============================================================================
-- Project:  MySQL DBA
-- Author:   Naseer Aryobee
-- Script:   01_user_management.sql
-- Phase:    6 — Security and User Management
-- Purpose:  Design and implement role-based access control for
--           cancer_environment_db. Create least-privilege users for
--           analyst, readonly, and etl_user roles.
-- =============================================================================

-- =============================================================================
-- Step 1 — Audit existing users before making any changes
-- =============================================================================

SELECT
    user,
    host,
    account_locked,
    password_expired
FROM mysql.user
ORDER BY user;


-- =============================================================================
-- Step 2 — Create roles
-- =============================================================================
-- Roles group privileges together so they can be assigned to multiple users
-- without repeating GRANT statements. Three roles cover the access patterns
-- for this database:
--
-- db_readonly:  SELECT only — for dashboards, reporting tools, Tableau
-- db_analyst:   SELECT + limited write — for data analysts running queries
--               and updating derived tables
-- db_etl:       INSERT, UPDATE, DELETE, SELECT — for ETL pipelines loading
--               and refreshing data
-- =============================================================================

CREATE ROLE IF NOT EXISTS 'db_readonly';
CREATE ROLE IF NOT EXISTS 'db_analyst';
CREATE ROLE IF NOT EXISTS 'db_etl';


-- =============================================================================
-- Step 3 — Grant privileges to roles
-- =============================================================================

-- db_readonly — SELECT only on all tables
GRANT SELECT ON cancer_environment_db.* TO 'db_readonly';

-- db_analyst — SELECT on all tables + ability to create temporary tables
--              for intermediate query results
GRANT SELECT ON cancer_environment_db.* TO 'db_analyst';
GRANT CREATE TEMPORARY TABLES ON cancer_environment_db.* TO 'db_analyst';

-- db_etl — Full data manipulation on all tables, no schema changes
GRANT SELECT, INSERT, UPDATE, DELETE ON cancer_environment_db.* TO 'db_etl';


-- =============================================================================
-- Step 4 — Create users and assign roles
-- =============================================================================
-- Each user is created with a strong password and assigned the appropriate
-- role. Users connect from localhost only — no remote access on this
-- portfolio environment.
-- =============================================================================

-- readonly_user — Tableau dashboards, reporting queries
CREATE USER IF NOT EXISTS 'readonly_user'@'localhost'
    IDENTIFIED BY 'R3ad0nly!Secure#2026';
GRANT 'db_readonly' TO 'readonly_user'@'localhost';
ALTER USER 'readonly_user'@'localhost'
    DEFAULT ROLE 'db_readonly';

-- analyst_user — Data analyst running ad-hoc queries
CREATE USER IF NOT EXISTS 'analyst_user'@'localhost'
    IDENTIFIED BY 'An4lyst!Secure#2026';
GRANT 'db_analyst' TO 'analyst_user'@'localhost';
ALTER USER 'analyst_user'@'localhost'
    DEFAULT ROLE 'db_analyst';

-- etl_user — ETL pipelines loading and refreshing data
CREATE USER IF NOT EXISTS 'etl_user'@'localhost'
    IDENTIFIED BY 'Etl!Secure#2026Pass';
GRANT 'db_etl' TO 'etl_user'@'localhost';
ALTER USER 'etl_user'@'localhost'
    DEFAULT ROLE 'db_etl';


-- =============================================================================
-- Step 5 — Verify users and roles were created
-- =============================================================================

SELECT
    user,
    host,
    account_locked,
    password_expired
FROM mysql.user
WHERE user IN ('readonly_user', 'analyst_user', 'etl_user',
               'db_readonly', 'db_analyst', 'db_etl')
ORDER BY user;


-- =============================================================================
-- Step 6 — Verify role assignments
-- =============================================================================

SELECT
    FROM_USER   AS role_name,
    TO_USER     AS assigned_to,
    TO_HOST     AS host
FROM mysql.role_edges
ORDER BY role_name;


-- =============================================================================
-- Step 7 — Verify effective privileges per user
-- =============================================================================

SHOW GRANTS FOR 'readonly_user'@'localhost';
SHOW GRANTS FOR 'analyst_user'@'localhost';
SHOW GRANTS FOR 'etl_user'@'localhost';