-- =============================================================================
-- Project:  MySQL DBA
-- Author:   Naseer Aryobee
-- Script:   02_permissions_audit.sql
-- Phase:    6 — Security and User Management
-- Purpose:  Audit all user privileges and role assignments in
--           cancer_environment_db to verify least-privilege access control
--           is correctly implemented.
-- =============================================================================

-- =============================================================================
-- Step 1 — Full user inventory
-- =============================================================================

SELECT
    user,
    host,
    account_locked,
    password_expired,
    password_last_changed
FROM mysql.user
ORDER BY user;


-- =============================================================================
-- Step 2 — Role assignments
-- =============================================================================

SELECT
    FROM_USER   AS role_name,
    TO_USER     AS assigned_to,
    TO_HOST     AS host
FROM mysql.role_edges
ORDER BY role_name;


-- =============================================================================
-- Step 3 — Effective privileges per role
-- =============================================================================

SHOW GRANTS FOR 'db_readonly';
SHOW GRANTS FOR 'db_analyst';
SHOW GRANTS FOR 'db_etl';


-- =============================================================================
-- Step 4 — Effective privileges per user
-- =============================================================================

SHOW GRANTS FOR 'readonly_user'@'localhost';
SHOW GRANTS FOR 'analyst_user'@'localhost';
SHOW GRANTS FOR 'etl_user'@'localhost';


-- =============================================================================
-- Step 5 — Verify no users have excessive global privileges
-- =============================================================================
-- Only root should have global privileges. All other users should have
-- database-scoped privileges only via their assigned roles.
-- -----------------------------------------------------------------------------

SELECT
    user,
    host,
    Select_priv,
    Insert_priv,
    Update_priv,
    Delete_priv,
    Create_priv,
    Drop_priv,
    Grant_priv,
    Super_priv,
    Shutdown_priv
FROM mysql.user
WHERE user NOT IN ('root', 'mysql.sys', 'mysql.session', 'mysql.infoschema')
ORDER BY user;


-- =============================================================================
-- Step 6 — Verify database-level privileges
-- =============================================================================

SELECT
    user,
    host,
    db,
    Select_priv,
    Insert_priv,
    Update_priv,
    Delete_priv,
    Create_priv,
    Drop_priv
FROM mysql.db
WHERE db = 'cancer_environment_db'
ORDER BY user;


-- =============================================================================
-- Step 7 — Test readonly_user access (run as readonly_user to verify)
-- =============================================================================
-- The following confirms readonly_user can SELECT but not write.
-- Expected: SELECT succeeds, INSERT fails with access denied.
-- -----------------------------------------------------------------------------

-- Verify SELECT works
SELECT COUNT(*) AS row_count FROM cancer_environment_db.dim_state;

-- Verify INSERT is blocked (uncomment to test — expect ERROR 1142)
-- INSERT INTO cancer_environment_db.dim_state (state_fips, state_abbr, state_name)
-- VALUES ('99', 'XX', 'Test State');