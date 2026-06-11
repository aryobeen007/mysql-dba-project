# Phase 1: Data Sourcing and Documentation

**Project:** MySQL DBA  
**Author:** Naseer Aryobee  
**Portfolio:** [nasaryobee.com](https://nasaryobee.com)  
**GitHub:** [github.com/aryobeen007/mysql-dba-project](https://github.com/aryobeen007/mysql-dba-project)  
**Phase Status:** Complete  

---

## Overview

In this phase I identified, verified, and downloaded all datasets that form the foundation of this project. My research question centers on understanding the relationship between cancer rates across the United States and the environmental, lifestyle, food, and water quality factors that contribute to them.

I made a deliberate decision early in this phase to pivot away from a narrowly scoped CAFO water contamination dataset toward a broader public health research question. The broader scope — cancer incidence and mortality correlated with air quality, drinking water violations, food environment, and behavioral risk factors — produces a richer dataset, a more compelling analytical story, and a more reusable data foundation for the future Databricks and Tableau projects that will follow this MySQL work.

Every dataset I selected meets the following criteria:

- Publicly available at no cost
- Published by a federal agency or peer-reviewed source
- Directly relevant to the research question
- Downloadable without proprietary software or special access
- Documented with supporting scientific references

---

## Dataset Inventory

### Dataset 1 — EPA ECHO NPDES Facility and Permit Data

| Field | Detail |
|-------|--------|
| **Agency** | U.S. Environmental Protection Agency (EPA) |
| **Program** | National Pollutant Discharge Elimination System (NPDES) |
| **Source URL** | https://echo.epa.gov/tools/data-downloads |
| **Files** | `npdes_downloads.zip` (343 MB), `npdes_outfalls_layer.zip` (48 MB) |
| **Location** | `data/raw/cafo/` |
| **Coverage** | National — all NPDES permitted facilities |

**What it contains:** Facility names, permit types, permit status, inspection history, violation records, and discharge point coordinates for all facilities regulated under the Clean Water Act including Concentrated Animal Feeding Operations (CAFOs).

**Why I selected it:** This dataset is the authoritative federal source for water discharge compliance data. I included it to provide the regulatory and geographic context for agricultural pollution sources that may correlate with water quality violations and downstream public health outcomes.

**Supporting reference:** Burkholder, J. et al. (2007). Impacts of Waste from Concentrated Animal Feeding Operations on Water Quality. *Environmental Health Perspectives*, 115(2), 308–312. https://doi.org/10.1289/ehp.8839

---

### Dataset 2 — USDA 2022 Census of Agriculture

| Field | Detail |
|-------|--------|
| **Agency** | U.S. Department of Agriculture, National Agricultural Statistics Service (NASS) |
| **Program** | Census of Agriculture |
| **Source URL** | https://www.nass.usda.gov/datasets/qs.census2022.txt.gz |
| **Files** | `qs.census2022.txt` (2.3 GB) |
| **Location** | `data/raw/cafo/` |
| **Coverage** | National — all counties, all commodities, 2022 |

**What it contains:** Complete 2022 Census of Agriculture data including livestock operation counts, animal inventories, farm sizes, and sales data by county for all agricultural commodities including cattle, hogs, poultry, and dairy.

**Why I selected it:** The Census of Agriculture is the gold standard for understanding where and how densely livestock operations are concentrated across the U.S. I will use this to establish county-level agricultural intensity as a potential environmental risk factor.

**Supporting reference:** MacDonald, J.M. et al. (2009). *Manure Use for Fertilizer and for Energy.* USDA Economic Research Report No. 67.

---

### Dataset 3 — CDC WONDER Cancer Incidence 1999–2022

| Field | Detail |
|-------|--------|
| **Agency** | Centers for Disease Control and Prevention (CDC) and National Cancer Institute (NCI) |
| **Program** | United States Cancer Statistics (USCS) |
| **Source URL** | https://wonder.cdc.gov/cancer.html |
| **Files** | `cdc_wonder_cancer_incidence_by_state_1999_2022.csv` |
| **Location** | `data/raw/public-health/` |
| **Coverage** | All 50 states, 1999–2022, all cancer types combined |

**What it contains:** Annual cancer incidence counts, population denominators, and age-adjusted rates per 100,000 by state and year covering all invasive cancer sites combined from 1999 through 2022.

**Why I selected it:** This is the official federal cancer statistics dataset — the primary dependent variable in my analysis. I will use state-level incidence trends over 22 years to identify patterns and correlate them with environmental and lifestyle risk factors.

**Supporting reference:** U.S. Cancer Statistics Working Group. *United States Cancer Statistics: 1999–2022 Incidence and Mortality Web-based Report.* Atlanta: CDC and NCI; 2024.

---

### Dataset 4 — CDC WONDER Cancer Mortality 2018–2023

| Field | Detail |
|-------|--------|
| **Agency** | Centers for Disease Control and Prevention (CDC) |
| **Program** | National Vital Statistics System (NVSS) |
| **Source URL** | https://wonder.cdc.gov/cancer.html |
| **Files** | `cdc_wonder_cancer_mortality_by_state_2018_2023.csv` |
| **Location** | `data/raw/public-health/` |
| **Coverage** | All 50 states, 2018–2023, all cancer sites |

**What it contains:** Annual cancer mortality counts, population denominators, and age-adjusted death rates per 100,000 by state and year.

**Why I selected it:** Mortality data complements incidence data by capturing outcomes rather than diagnoses. States with high incidence but lower mortality may reflect better healthcare access, while states with both high incidence and high mortality indicate more severe public health challenges.

**Supporting reference:** U.S. Cancer Statistics Working Group. *United States Cancer Statistics: 1999–2022 Incidence and Mortality Web-based Report.* Atlanta: CDC and NCI; 2024.

---

### Dataset 5 — CDC Chronic Disease Indicators

| Field | Detail |
|-------|--------|
| **Agency** | Centers for Disease Control and Prevention (CDC) |
| **Program** | Chronic Disease Indicators (CDI) |
| **Source URL** | https://data.virginia.gov/dataset/u-s-chronic-disease-indicators |
| **Files** | `cdc_chronic_disease_indicators_all_states.csv` (111 MB) |
| **Location** | `data/raw/public-health/` |
| **Coverage** | All 50 states, multiple years, 115 indicators |

**What it contains:** State-level prevalence estimates for 115 chronic disease indicators including smoking rates, obesity prevalence, physical inactivity, alcohol consumption, diabetes prevalence, and cancer screening rates derived primarily from the Behavioral Risk Factor Surveillance System (BRFSS).

**Why I selected it:** This dataset provides the lifestyle and behavioral risk factor dimension of my analysis. Smoking, obesity, and physical inactivity are among the strongest known predictors of cancer incidence and I need state-level estimates to correlate with cancer rates over time.

**Supporting reference:** Watson, K.B. et al. (2024). Chronic Disease Indicators: 2022–2024 Refresh and Modernization of the Web Tool. *Preventing Chronic Disease*, 21, 240109. https://doi.org/10.5888/pcd21.240109

---

### Dataset 6 — EPA AQI by County 2000–2022

| Field | Detail |
|-------|--------|
| **Agency** | U.S. Environmental Protection Agency (EPA) |
| **Program** | Air Quality System (AQS) |
| **Source URL** | https://aqs.epa.gov/aqsweb/airdata/download_files.html |
| **Files** | 23 CSV files — `annual_aqi_by_county_2000.csv` through `annual_aqi_by_county_2022.csv` |
| **Location** | `data/raw/air-quality/` |
| **Coverage** | National — all monitored counties, 2000–2022 |

**What it contains:** Annual Air Quality Index (AQI) statistics by county including median AQI, maximum AQI, number of days with unhealthy air, and counts of days exceeding thresholds for ozone, PM2.5, PM10, carbon monoxide, nitrogen dioxide, and sulfur dioxide.

**Why I selected it:** Long-term exposure to fine particulate matter (PM2.5) and other air pollutants is a well-documented cause of lung cancer and other malignancies. I downloaded all 23 years to enable trend analysis matching the cancer incidence time range.

**Supporting reference:** Pope, C.A. et al. (2002). Lung Cancer, Cardiopulmonary Mortality, and Long-term Exposure to Fine Particulate Air Pollution. *JAMA*, 287(9), 1132–1141. https://doi.org/10.1001/jama.287.9.1132

---

### Dataset 7 — EPA SDWIS Drinking Water Violations

| Field | Detail |
|-------|--------|
| **Agency** | U.S. Environmental Protection Agency (EPA) |
| **Program** | Safe Drinking Water Information System (SDWIS) |
| **Source URL** | https://echo.epa.gov/tools/data-downloads#drinking-water |
| **Files** | 11 CSV files including `SDWA_VIOLATIONS_ENFORCEMENT.csv` (4 GB) |
| **Location** | `data/raw/water-quality/` |
| **Coverage** | National — all public water systems |

**What it contains:** Complete Safe Drinking Water Act compliance records including all violations by contaminant type, public water system details, facility locations, enforcement actions, and service area populations affected.

**Why I selected it:** Drinking water quality is a direct environmental exposure pathway for cancer-causing contaminants including nitrates, arsenic, and disinfection byproducts. I will use this dataset to identify counties with chronic drinking water violations and correlate them with cancer incidence patterns.

**Supporting reference:** Ward, M.H. et al. (2018). Drinking Water Nitrate and Human Health: An Updated Review. *International Journal of Environmental Research and Public Health*, 15(7), 1557. https://doi.org/10.3390/ijerph15071557

---

### Dataset 8 — USDA Food Environment Atlas

| Field | Detail |
|-------|--------|
| **Agency** | U.S. Department of Agriculture, Economic Research Service (ERS) |
| **Program** | Food Environment Atlas |
| **Source URL** | https://www.ers.usda.gov/data-products/food-environment-atlas/data-access-and-documentation-downloads/ |
| **Files** | `StateAndCountyData.csv` (39 MB), `VariableList.csv` |
| **Location** | `data/raw/food-environment/` |
| **Coverage** | All U.S. counties, current release |

**What it contains:** County-level food environment indicators including food desert classifications, grocery store and fast food restaurant access, farmers market availability, SNAP participation rates, obesity and diabetes prevalence, and food insecurity estimates.

**Why I selected it:** Diet and food access are significant contributors to cancer risk, particularly for colorectal, breast, and other diet-related cancers. County-level food environment data allows me to examine whether limited access to healthy food correlates with elevated cancer rates across the country.

**Supporting reference:** Larson, N.I. et al. (2009). Neighborhood Environments: Disparities in Access to Healthy Foods in the U.S. *American Journal of Preventive Medicine*, 36(1), 74–81. https://doi.org/10.1016/j.amepre.2008.09.025

---

## Data Acquisition Scripts

I wrote two Python scripts to automate data downloads where manual downloading was impractical:

- `sql/phase-1/download_epa_aqi.py` — Downloads all 23 years of EPA AQI by county data, extracts ZIP files, and saves CSVs to `data/raw/air-quality/`
- `sql/phase-1/download_water_quality.py` — Initial WQP water quality download script (superseded by SDWIS approach)
- `sql/phase-1/retry_water_quality.py` — Retry script for failed WQP state downloads (superseded by SDWIS approach)

---

## Key Decisions and Rationale

**Decision 1 — Pivoting from CAFO water contamination to broader cancer risk factors**
I originally scoped this project around CAFO water contamination data. After encountering significant data availability challenges with the EPA Water Quality Portal API and evaluating the analytical value of a broader approach, I pivoted to a multi-factor cancer risk analysis. This decision produces a richer research question, a more complete dataset, and a stronger portfolio piece that will also serve the future Databricks and Tableau projects.

**Decision 2 — Using pre-packaged bulk downloads instead of API calls**
Early attempts to download water quality data state-by-state via the WQP API resulted in timeouts, connection resets, and incomplete data after two days of download attempts. I switched to pre-packaged bulk downloads from EPA ECHO and USDA wherever available. This produced cleaner, more complete, and more reliably documented data.

**Decision 3 — Excluding raw data files from GitHub**
All raw data files are excluded from the GitHub repository via `.gitignore`. Raw datasets range from 39 MB to 4 GB and are not appropriate for version control. Only scripts, documentation, and schema files are committed to the repository.

**Decision 4 — State-level cancer data instead of county-level**
CDC WONDER limits cancer incidence queries to 75,000 rows. County-level data by cancer type and year exceeds this limit. I chose state-level data grouped by year to stay within the limit while preserving the time-series dimension needed for trend analysis.

---

## Phase 1 Summary

| Dataset | Source | Size | Location |
|---------|--------|------|----------|
| EPA ECHO NPDES Permits | EPA | 391 MB | `data/raw/cafo/` |
| USDA Census of Agriculture 2022 | USDA NASS | 2.3 GB | `data/raw/cafo/` |
| CDC Cancer Incidence 1999–2022 | CDC WONDER | ~1 MB | `data/raw/public-health/` |
| CDC Cancer Mortality 2018–2023 | CDC WONDER | ~1 MB | `data/raw/public-health/` |
| CDC Chronic Disease Indicators | CDC/BRFSS | 111 MB | `data/raw/public-health/` |
| EPA AQI by County 2000–2022 | EPA AQS | ~40 MB | `data/raw/air-quality/` |
| EPA SDWIS Drinking Water | EPA | 4.7 GB | `data/raw/water-quality/` |
| USDA Food Environment Atlas | USDA ERS | 39 MB | `data/raw/food-environment/` |