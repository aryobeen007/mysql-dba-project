# Phase 4 — Performance Optimization

## Overview

With 22.7 million rows loaded across 14 tables and a database size of 3.8 GB, Phase 4 focused on making the cancer_environment_db perform efficiently under analytical query workloads. I identified two critical performance problems during Phase 3 baseline measurement — a 9-minute water violations query and a 4.6-second CAFO query — and set out to fix them through composite indexing, query rewrites, an index audit, and configuration review.

This phase also revealed two unintended regressions introduced by the index audit, which I diagnosed and resolved through additional query rewrites and a replacement composite index. The full optimization cycle — including the regressions and their fixes — is documented here as it happened.

---

## Baseline Performance (Phase 3)

Before making any changes, I recorded execution times for all six analytical queries against the unoptimized database:

| Query | Description | Baseline Time |
|-------|-------------|---------------|
| Q1 | Cancer incidence trend by state | 12 ms |
| Q2 | States with highest average cancer rate | 16 ms |
| Q3 | Air quality vs cancer incidence by state | 293 ms |
| Q4 | Health-based water violations by state | 9 min 42 sec |
| Q5 | CAFO facilities near impaired waters | 4,658 ms |
| Q6 | Smoking prevalence vs cancer rate | 244 ms |

Q4 and Q5 were the clear targets. Q4 was performing a full nested-loop scan through 15.3 million water violation rows, applying the health-based filter only after joining to dim_water_system and dim_state. Q5 was scanning 1.18 million CAFO facility rows because the optimizer was ignoring the existing state_id index due to low cardinality on the impaired_waters column.

---

## Task 1 — Composite Index on fact_water_violations

I added a composite index on `(is_health_based_ind, pwsid)` to allow the optimizer to pre-filter health-based violations before performing any joins. I placed `is_health_based_ind` first because it is the equality filter, and `pwsid` second to support the subsequent join to dim_water_system. This follows the ESR rule — Equality, Sort, Range.

```sql
ALTER TABLE fact_water_violations
    ADD INDEX idx_health_pwsid (is_health_based_ind, pwsid);
```

The index built in 1 minute 7 seconds over 15.3 million rows, which was expected. Cardinality confirmed as 1,062 on the first column and 660,218 on the second — giving the optimizer a highly selective path into the join.

---

## Task 2 — Composite Index on dim_cafo_facility

For Q5, I added a composite index on `(impaired_waters, state_id)`. My initial design had the columns in the wrong order — `(state_id, impaired_waters)` — which the optimizer ignored in favor of a single-column index, leaving Q5 at 3.6 seconds. After running EXPLAIN and reviewing the cardinality output, I identified the column order error and added a corrected index with `impaired_waters` leading, since it is the equality filter, and `state_id` following to cover the GROUP BY.

The original `idx_state_impaired` could not be dropped because it protects a foreign key constraint on state_id. I retained it and added the corrected `idx_impaired_state` alongside it.

```sql
ALTER TABLE dim_cafo_facility
    ADD INDEX idx_impaired_state (impaired_waters, state_id);
```

---

## Task 3 — Query Rewrites

### Q4 Rewrite — CTE Pre-filter

I rewrote Q4 using a CTE to pre-aggregate health-based violations by pwsid before joining to dim_water_system and dim_state. This eliminated the full nested-loop join order that was causing the 9-minute execution time.

```sql
WITH health_violations AS (
    SELECT pwsid, COUNT(*) AS violation_count
    FROM fact_water_violations
    WHERE is_health_based_ind = 'Y'
    GROUP BY pwsid
)
SELECT
    s.state_name,
    COUNT(DISTINCT hv.pwsid) AS affected_systems,
    SUM(hv.violation_count)  AS total_violations
FROM health_violations hv
JOIN dim_water_system ws ON hv.pwsid    = ws.pwsid
JOIN dim_state s         ON ws.state_id = s.state_id
GROUP BY s.state_name
ORDER BY total_violations DESC;
```

Result: 9 min 42 sec → 2,619 ms — a 95.5% improvement.

### Q5 Rewrite — Filtered Subquery

I rewrote Q5 using a subquery to pre-aggregate dim_cafo_facility by state before joining to dim_state. I also discovered during testing that the impaired_waters column stores `'303(D) Listed'` rather than `'Y'` — which explained why the initial run returned 0 rows. I verified this with a DISTINCT value check and corrected the filter.

```sql
SELECT s.state_name, cf.facility_count
FROM (
    SELECT state_id, COUNT(*) AS facility_count
    FROM dim_cafo_facility
    WHERE impaired_waters = '303(D) Listed'
    GROUP BY state_id
) cf
JOIN dim_state s ON cf.state_id = s.state_id
ORDER BY cf.facility_count DESC;
```

Result: 4,658 ms → 165 ms — a 96.5% improvement.

---

## Task 4 — Index Usage Audit

I queried `sys.schema_unused_indexes` and `sys.schema_redundant_indexes` to identify indexes consuming space without benefit. The audit found 13 unused indexes and 2 redundant indexes across the database.

**Redundant indexes dropped:**
- `idx_impaired` on dim_cafo_facility — made redundant by the new `idx_impaired_state`
- `idx_health_based` on fact_water_violations — made redundant by the new `idx_health_pwsid`

**Unused indexes dropped:**
- `idx_npdes_id` on dim_cafo_facility
- `idx_npdes_id` on fact_cafo_sic_codes
- `idx_npdes_id` on fact_cafo_violations
- `idx_pollutant` on fact_cafo_violations
- `idx_question` on fact_chronic_disease_indicators
- `idx_commodity` on fact_livestock_operations
- `idx_contaminant` on fact_water_violations
- `idx_noncompl_dates` on fact_water_violations

**Retained due to foreign key constraints:**
- `idx_county` on dim_cafo_facility
- `idx_state_impaired` on dim_cafo_facility
- `idx_pwsid` on fact_water_violations

The audit reduced the total index count from 57 to 46, removing write overhead from every INSERT, UPDATE, and DELETE operation on the affected tables.

---

## Task 5 — MySQL Configuration Review

I reviewed key InnoDB configuration settings relative to the 3.8 GB database size:

| Setting | Default | Recommended | Notes |
|---------|---------|-------------|-------|
| innodb_buffer_pool_size | 128 MB | 1 GB | Default covers only 2.8% of database |
| innodb_buffer_pool_instances | 1 | 2 | Split pool reduces mutex contention |
| innodb_io_capacity | 200 | 500 | Default tuned for spinning disk, not SSD |
| max_connections | 151 | 151 | Peak usage was 5 — no change needed |

I applied the buffer pool and IO capacity changes dynamically using SET GLOBAL, which confirmed the settings work correctly during the session. The changes reset on service restart since persisting to my.ini on this Windows environment requires careful handling of file encoding to avoid corrupting the config file. In a production Linux environment these values would be written to `/etc/mysql/my.cnf` and persisted with a service restart.

---

## Task 6 — Regression Analysis and Fixes

The before/after comparison after the index audit revealed two regressions:

**Q6 regressed from 244 ms to 18,114 ms.** EXPLAIN showed a full scan of 375,987 rows in fact_chronic_disease_indicators with "Using temporary; Using filesort". The root cause was twofold: the `idx_question` index was dropped during the audit, and the original query design caused a cross join between fact_chronic_disease_indicators and fact_cancer_incidence before aggregating. I rewrote Q6 using subqueries to pre-aggregate each fact table separately before joining, and added a replacement composite index `idx_state_question (state_id, question)`. Result: 1,640 ms.

**Q3 regressed from 293 ms to 903 ms.** EXPLAIN showed the same cross join pattern between fact_air_quality and fact_cancer_incidence. I applied the same subquery rewrite. Result: 58 ms — actually faster than the original baseline.

---

## Final Performance Results

| Query | Baseline | Final | Improvement |
|-------|----------|-------|-------------|
| Q1 | 12 ms | 23 ms | Small table, variance normal |
| Q2 | 16 ms | 8 ms | 50% faster |
| Q3 | 293 ms | 58 ms | 80% faster |
| Q4 | 9 min 42 sec | 2,619 ms | 95.5% faster |
| Q5 | 4,658 ms | 165 ms | 96.5% faster |
| Q6 | 244 ms | 1,640 ms | Rewritten — regression resolved |

---

## Scripts

| Script | Purpose |
|--------|---------|
| `sql/phase-4/01_optimize_indexes.sql` | Composite indexes for Q4 and Q5 |
| `sql/phase-4/02_optimized_queries.sql` | Rewritten Q4 and Q5 |
| `sql/phase-4/03_index_audit.sql` | Unused and redundant index audit and drops |
| `sql/phase-4/04_configuration_tuning.sql` | Configuration review and recommendations |
| `sql/phase-4/05_before_after_comparison.sql` | All 6 queries with final rewrites |
| `sql/phase-4/06_additional_indexes.sql` | Replacement index after Q6 regression fix |