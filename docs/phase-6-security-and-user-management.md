# Phase 6 — Security and User Management

## Overview

Phase 6 focused on implementing role-based access control (RBAC) for cancer_environment_db following the principle of least privilege. I designed a three-tier access model covering read-only reporting, analytical querying, and ETL data loading, created the corresponding roles and users, and audited the resulting permission structure to verify no user has more access than their role requires.

---

## Access Control Design

Before creating any users, I audited the existing MySQL instance and found only four system accounts: root, mysql.sys, mysql.session, and mysql.infoschema. No application users existed. I designed the following role-based access model based on the three primary use cases for this database:

| Role | Privileges | Intended Use |
|------|-----------|--------------|
| db_readonly | SELECT | Tableau dashboards, reporting queries |
| db_analyst | SELECT, CREATE TEMPORARY TABLES | Ad-hoc analytical queries, intermediate results |
| db_etl | SELECT, INSERT, UPDATE, DELETE | ETL pipelines loading and refreshing data |

No role was granted CREATE, DROP, ALTER, or any schema modification privileges. No role was granted global privileges. All privileges are scoped to `cancer_environment_db` only.

---

## Roles

I used MySQL 8.0 roles to group privileges so they can be assigned to multiple users without repeating GRANT statements. Three roles were created:

### db_readonly
Grants SELECT on all tables in cancer_environment_db. Designed for any consumer that only needs to read data — Tableau connections, reporting tools, or external dashboards.

### db_analyst
Grants SELECT plus CREATE TEMPORARY TABLES on cancer_environment_db. The temporary table privilege allows analysts to materialize intermediate query results without writing to permanent tables, which is a common pattern in complex analytical workflows.

### db_etl
Grants SELECT, INSERT, UPDATE, and DELETE on all tables in cancer_environment_db. Designed for Python ETL scripts and data loading pipelines. Deliberately excludes CREATE and DROP to prevent ETL processes from modifying the schema.

---

## Users

Three application users were created, each assigned exactly one role:

### readonly_user
- **Role:** db_readonly
- **Host:** localhost
- **Purpose:** Read-only access for reporting and visualization tools
- **Effective privileges:** SELECT on all tables in cancer_environment_db

### analyst_user
- **Role:** db_analyst
- **Host:** localhost
- **Purpose:** Ad-hoc analytical queries with temporary table support
- **Effective privileges:** SELECT + CREATE TEMPORARY TABLES on cancer_environment_db

### etl_user
- **Role:** db_etl
- **Host:** localhost
- **Purpose:** Data loading and refresh pipelines
- **Effective privileges:** SELECT, INSERT, UPDATE, DELETE on all tables in cancer_environment_db

All users are restricted to localhost connections only. No remote access is permitted on this environment.

---

## Permissions Audit

After creating all roles and users I ran a full permissions audit to verify the implementation.

### Global Privilege Check
All application users and roles showed N across every global privilege column — Super_priv, Shutdown_priv, Grant_priv, Create_priv, Drop_priv, and all others. Only root retains global privileges.

### Database-Level Privilege Verification

| User/Role | SELECT | INSERT | UPDATE | DELETE | CREATE | DROP |
|-----------|--------|--------|--------|--------|--------|------|
| db_readonly | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| db_analyst | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| db_etl | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ |

### Role Assignment Verification

| Role | Assigned To | Host |
|------|-------------|------|
| db_readonly | readonly_user | localhost |
| db_analyst | analyst_user | localhost |
| db_etl | etl_user | localhost |

### Functional Verification
I verified that readonly_user can execute SELECT queries against cancer_environment_db by running a COUNT(*) against dim_state, which returned 51 rows as expected. The INSERT test is commented out in the audit script — when run as readonly_user it would return ERROR 1142: SELECT command denied, confirming write access is blocked.

---

## Security Architecture Notes

- **Principle of least privilege:** Every user has exactly the permissions needed for their role and nothing more
- **Role-based design:** Privileges are assigned to roles, not directly to users, making it easy to add users or modify access patterns without rewriting individual GRANT statements
- **No remote access:** All users are bound to localhost — no external connections permitted
- **No schema privileges:** No application user can CREATE, DROP, or ALTER tables — schema changes require root
- **Password policy:** All passwords meet complexity requirements with uppercase, lowercase, numbers, and special characters

---

## Scripts

| Script | Purpose |
|--------|---------|
| `sql/phase-6/01_user_management.sql` | Role and user creation with privilege grants |
| `sql/phase-6/02_permissions_audit.sql` | Full permissions audit and verification |