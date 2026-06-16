# Phase 3: Baseline Measurement and Diagnostics

**Project:** MySQL DBA  
**Author:** Naseer Aryobee  
**Portfolio:** [nasaryobee.com](https://nasaryobee.com)  
**GitHub:** [github.com/aryobeen007/mysql-dba-project](https://github.com/aryobeen007/mysql-dba-project)  
**Phase Status:** Complete  

---

## Overview

In this phase I captured the database in its pre-optimized state. I measured database and table sizes, inventoried all existing indexes, ran six diagnostic queries representing real analytical workloads, recorded execution times, and analyzed query execution plans using EXPLAIN. The results of this phase establish the performance baseline that Phase 4 optimization will improve against.

---

## Database Size Baseline

| Metric | Value |
|--------|-------|
| Total Database Size | 3,836.84 MB |
| Data Size | 1,808.72 MB |
| Index Size | 2,028.13 MB |

The index size exceeds the data size at this stage, which is expected since indexes were created during table definition before data was loaded. Phase 4 will analyze whether all indexes are being used and eliminate any that are not.

---

## Table Size Breakdown

| Table | Estimated Rows | Data (MB) | Index (MB) | Total (MB) |
|-------|---------------|-----------|------------|------------|
| fact_water_violations | 14,896,195 | 1,253.00 | 1,627.86 | 2,880.86 |
| dim_cafo_facility | 1,109,291 | 256.91 | 149.36 | 406.27 |
| fact_food_environment | 929,766 | 49.58 | 85.22 | 134.80 |
| fact_chronic_disease_indicators | 375,430 | 67.59 | 51.80 | 119.39 |
| dim_water_system | 485,523 | 71.64 | 35.09 | 106.73 |
| fact_cafo_sic_codes | 776,431 | 58.59 | 38.11 | 96.70 |
| fact_cafo_violations | 393,156 | 48.59 | 39.58 | 88.17 |
| fact_air_quality | 23,146 | 2.52 | 0.84 | 3.36 |
| dim_county | 3,079 | 0.16 | 0.08 | 0.23 |
| fact_cancer_incidence | 1,218 | 0.08 | 0.09 | 0.17 |
| fact_livestock_operations | 3,339,228 | 0.02 | 0.05 | 0.06 |
| fact_cancer_mortality | 306 | 0.02 | 0.03 | 0.05 |
| dim_state | 51 | 0.02 | 0.02 | 0.03 |
| dim_year | 47 | 0.02 | 0.00 | 0.02 |

**Note:** fact_water_violations at 2.88 GB dominates the database and is the primary performance concern. fact_livestock_operations showed 0 estimated rows in the information schema despite containing 3.3 million rows — this was resolved by running ANALYZE TABLE.

---

## Index Inventory (Pre-Optimization)

| Table | Index Name | Column | Unique | Type |
|-------|------------|--------|--------|------|
| dim_cafo_facility | PRIMARY | facility_id | Yes | BTREE |
| dim_cafo_facility | idx_county | county_id | No | BTREE |
| dim_cafo_facility | idx_impaired | impaired_waters | No | BTREE |
| dim_cafo_facility | idx_npdes_id | npdes_id | No | BTREE |
| dim_cafo_facility | state_id | state_id | No | BTREE |
| dim_county | PRIMARY | county_id | Yes | BTREE |
| dim_county | uq_state_county | state_id, county_fips | Yes | BTREE |
| dim_state | PRIMARY | state_id | Yes | BTREE |
| dim_state | state_fips | state_fips | Yes | BTREE |
| dim_water_system | PRIMARY | pwsid | Yes | BTREE |
| dim_water_system | idx_county | county_id | No | BTREE |
| dim_water_system | state_id | state_id | No | BTREE |
| fact_air_quality | PRIMARY | air_quality_id | Yes | BTREE |
| fact_air_quality | uq_county_year_aqi | county_id, year_id | Yes | BTREE |
| fact_cafo_sic_codes | PRIMARY | sic_record_id | Yes | BTREE |
| fact_cafo_sic_codes | idx_npdes_id | npdes_id | No | BTREE |
| fact_cafo_sic_codes | idx_sic_code | sic_code | No | BTREE |
| fact_cafo_violations | PRIMARY | violation_id | Yes | BTREE |
| fact_cafo_violations | idx_monitoring_date | monitoring_period_end_date | No | BTREE |
| fact_cafo_violations | idx_npdes_id | npdes_id | No | BTREE |
| fact_cafo_violations | idx_pollutant | pollutant_code | No | BTREE |
| fact_cancer_incidence | PRIMARY | incidence_id | Yes | BTREE |
| fact_cancer_incidence | uq_state_year | state_id, year_id | Yes | BTREE |
| fact_chronic_disease_indicators | PRIMARY | indicator_id | Yes | BTREE |
| fact_chronic_disease_indicators | idx_question | question | No | BTREE |
| fact_chronic_disease_indicators | idx_topic | topic | No | BTREE |
| fact_chronic_disease_indicators | state_id | state_id | No | BTREE |
| fact_food_environment | PRIMARY | food_env_id | Yes | BTREE |
| fact_food_environment | uq_county_variable | county_id, variable_code | Yes | BTREE |
| fact_food_environment | idx_variable_code | variable_code | No | BTREE |
| fact_livestock_operations | PRIMARY | operation_id | Yes | BTREE |
| fact_livestock_operations | idx_commodity | commodity_desc | No | BTREE |
| fact_livestock_operations | idx_county_year | county_id, year_id | No | BTREE |
| fact_water_violations | PRIMARY | violation_id | Yes | BTREE |
| fact_water_violations | idx_contaminant | contaminant_code | No | BTREE |
| fact_water_violations | idx_health_based | is_health_based_ind | No | BTREE |
| fact_water_violations | idx_noncompl_dates | non_compl_per_begin_date, non_compl_per_end_date | No | BTREE |
| fact_water_violations | idx_pwsid | pwsid | No | BTREE |

---

## Baseline Query Performance

I ran six queries representing real analytical workloads against the database in its pre-optimized state. All execution times were recorded in DataGrip.

| Query | Description | Execution Time |
|-------|-------------|----------------|
| Q1 | Cancer incidence trend by state | 12 ms |
| Q2 | States with highest average cancer rate | 16 ms |
| Q3 | Air quality vs cancer incidence by state | 293 ms |
| Q4 | Health-based water violations by state | 9 min 42 sec |
| Q5 | CAFO facilities near impaired waters | 4,658 ms |
| Q6 | Smoking prevalence vs cancer rate | 244 ms |

---

## Execution Plan Analysis

### Q4 — Health-Based Water Violations by State (Critical)

EXPLAIN output:

- id=1, type=ALL, table=s, key=NULL, rows=51, Extra=Using temporary; Using filesort
- id=1, type=ref, table=ws, key=state_id, rows=7704, Extra=Using index
- id=1, type=ref, table=wv, key=idx_pwsid, rows=52, Extra=

**Problem:** MySQL starts with a full scan of dim_state (51 rows), then for each state loops through approximately 7,704 water systems, then for each water system processes approximately 52 violation rows. With 433,698 water systems and 15.3 million violation rows this creates an enormous nested loop resulting in a 9-minute execution time.

**Root cause:** The query optimizer chose a join order that forces processing all violation rows multiple times. The is_health_based_ind filter is applied after the join rather than before, eliminating no rows during the scan.

**Phase 4 fix:** Rewrite the query to filter violations first using a subquery or CTE, add a composite index on (is_health_based_ind, pwsid), and force a more efficient join order.

---

### Q5 — CAFO Facilities Near Impaired Waters (Slow)

EXPLAIN output:

- id=1, type=ALL, table=f, key=NULL, rows=1,112,830, Extra=Using where; Using temporary; Using filesort
- id=1, type=eq_ref, table=s, key=PRIMARY, rows=1, Extra=

**Problem:** MySQL ignores the state_id index on dim_cafo_facility and performs a full table scan of 1.1 million rows. The optimizer estimated that too many rows would match the filter, making a full scan appear cheaper than an index lookup.

**Root cause:** The impaired_waters column has low cardinality (only a few distinct values), causing the optimizer to skip the index. The GROUP BY state_name with Using temporary; Using filesort adds additional overhead.

**Phase 4 fix:** Add a composite index on (state_id, impaired_waters) and rewrite using a filtered subquery to reduce the working set before aggregation.

---

## Key Findings

1. **Q4 is the critical failure** — 9 minutes 42 seconds for a state-level aggregation query is unacceptable. This will be the primary target of Phase 4 optimization.

2. **Q5 needs attention** — 4.6 seconds for a 1.1 million row table scan with grouping is a significant performance issue.

3. **Q1, Q2, Q3, Q6 are acceptable** — sub-300ms queries on smaller tables perform well without additional optimization.

4. **Index size exceeds data size** — at 2.03 GB of indexes vs 1.81 GB of data, Phase 4 will audit index usage and remove any unused indexes to reclaim space and improve write performance.

5. **fact_water_violations dominates** — at 2.88 GB and 15.3 million rows, every query touching this table is a potential performance problem. Proper indexing and query design are critical for this table.

---

## Phase 3 Summary

I completed a thorough baseline measurement of the database before any optimization work. I identified two critical performance problems — a 9-minute query on drinking water violations and a 4.6-second query on CAFO facility data — and documented their root causes using EXPLAIN analysis. These findings directly inform the indexing strategy and query rewrites I will implement in Phase 4.