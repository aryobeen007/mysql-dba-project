# Phase 5 — Backup and Recovery

## Overview

With 22.7 million rows and 4.57 GB of data loaded across 14 tables, Phase 5 focused on implementing a reliable backup strategy for cancer_environment_db and proving that the database can be fully restored from that backup. I designed a mysqldump-based logical backup approach, executed a full backup, simulated a data loss event by dropping the database entirely, and restored it from the backup file while verifying row counts before and after.

---

## Backup Environment

Before implementing the backup strategy, I verified the environment:

- **MySQL version:** 8.0.45
- **Database size:** 4.57 GB total (2.22 GB data + 2.34 GB indexes)
- **Total rows:** 22,774,105 across 14 tables
- **Binary logging:** Enabled — current log file `DESKTOP-UK614UQ-bin.000007`
- **Transaction isolation:** REPEATABLE-READ — consistent with InnoDB snapshot reads
- **Binlog expiry:** 30 days (2,592,000 seconds)

Binary logging being enabled means point-in-time recovery is available in addition to full restore from dump.

---

## Backup Strategy

I chose mysqldump as the backup tool for the following reasons:

- It produces a portable, human-readable SQL file that can be restored on any MySQL instance
- It supports `--single-transaction` which takes a consistent InnoDB snapshot without locking tables during the backup
- It captures the binary log position at backup time via `--source-data=2`, enabling point-in-time recovery from any point after the backup
- It is available out of the box with MySQL Community Server — no additional tools required

The backup script is saved at `sql/phase-5/02_full_backup.ps1` and uses the following mysqldump flags:

| Flag | Purpose |
|------|---------|
| `--single-transaction` | Consistent InnoDB snapshot without table locks |
| `--routines` | Includes stored procedures and functions |
| `--triggers` | Includes triggers |
| `--events` | Includes scheduled events |
| `--flush-logs` | Flushes binary logs before backup for clean binlog position |
| `--source-data=2` | Records binary log position as a comment in the dump file |
| `--databases` | Includes the CREATE DATABASE statement in the dump |

---

## Full Backup Execution

I ran the full backup on June 24, 2026 using the backup script from PowerShell:

- **Backup file:** `cancer_environment_db_full_20260624_133040.sql`
- **File size:** 2.18 GB
- **Compression ratio:** The dump is approximately 48% of the live database size. This is expected — mysqldump exports logical INSERT statements rather than raw data pages, and InnoDB indexes do not need to be exported since they are rebuilt during restore.

---

## Recovery Simulation

To prove the backup is valid and the restore procedure works, I simulated a complete data loss event.

### Pre-Recovery Row Counts

Before dropping the database, I recorded exact row counts from all 14 tables as a verification baseline:

| Table | Rows |
|-------|------|
| fact_water_violations | 15,298,031 |
| fact_livestock_operations | 3,339,228 |
| dim_cafo_facility | 1,188,507 |
| fact_food_environment | 930,317 |
| fact_cafo_sic_codes | 784,937 |
| fact_cafo_violations | 395,599 |
| dim_water_system | 433,698 |
| fact_chronic_disease_indicators | 375,987 |
| fact_air_quality | 23,100 |
| dim_county | 3,079 |
| fact_cancer_incidence | 1,218 |
| fact_cancer_mortality | 306 |
| dim_state | 51 |
| dim_year | 47 |

### Data Loss Event

I dropped the entire database to simulate a catastrophic data loss:

```sql
DROP DATABASE cancer_environment_db;
```

### Restore Procedure

I restored from the full backup dump file using the MySQL client:

```bash
mysql --user=root --password < cancer_environment_db_full_20260624_133040.sql
```

MySQL replayed all CREATE DATABASE, CREATE TABLE, and INSERT statements from the 2.18 GB dump file, rebuilding the database and all indexes from scratch.

### Post-Recovery Verification

After the restore completed, I ran exact COUNT(*) queries against all 14 tables and confirmed all row counts matched the pre-recovery baseline exactly:

| Table | Pre-Recovery | Post-Recovery | Match |
|-------|-------------|---------------|-------|
| fact_water_violations | 15,298,031 | 15,298,031 | ✅ |
| fact_livestock_operations | 3,339,228 | 3,339,228 | ✅ |
| dim_cafo_facility | 1,188,507 | 1,188,507 | ✅ |
| fact_food_environment | 930,317 | 930,317 | ✅ |
| fact_cafo_sic_codes | 784,937 | 784,937 | ✅ |
| fact_cafo_violations | 395,599 | 395,599 | ✅ |
| dim_water_system | 433,698 | 433,698 | ✅ |
| fact_chronic_disease_indicators | 375,987 | 375,987 | ✅ |
| fact_air_quality | 23,100 | 23,100 | ✅ |
| dim_county | 3,079 | 3,079 | ✅ |
| fact_cancer_incidence | 1,218 | 1,218 | ✅ |
| fact_cancer_mortality | 306 | 306 | ✅ |
| dim_state | 51 | 51 | ✅ |
| dim_year | 47 | 47 | ✅ |

All 22,774,105 rows restored successfully across all 14 tables.

---

## Backup Retention and Rotation

For a production implementation of this backup strategy, I would implement the following rotation policy:

- **Daily full backups** retained for 7 days
- **Weekly backups** retained for 4 weeks
- **Monthly backups** retained for 12 months
- **Binary logs** retained for 30 days to support point-in-time recovery

On this portfolio environment, backups are stored locally in the `backups/` directory which is excluded from GitHub via `.gitignore` to prevent large binary files from being committed to the repository.

---

## Scripts

| Script | Purpose |
|--------|---------|
| `sql/phase-5/01_backup_strategy.sql` | Environment verification and size baseline |
| `sql/phase-5/02_full_backup.ps1` | Full mysqldump backup script |
| `sql/phase-5/03_recovery_simulation.sql` | Pre and post recovery row count verification |