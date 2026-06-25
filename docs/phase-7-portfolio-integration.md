# Phase 7 — Portfolio Integration

## Overview

Phase 7 focused on presenting the MySQL DBA project as a professional portfolio piece on nasaryobee.com. I captured screenshots from DataGrip, PowerShell, and VS Code across all six phases, built a full multi-page HTML portfolio site matching the design system of my existing PostgreSQL DBA project, and integrated the MySQL DBA project card into the main projects page.

---

## Screenshots Captured

I captured 16 screenshots across all phases to document the work visually. Screenshots were saved to the `screenshots/` directory in the project repository and committed to GitHub before being referenced in the portfolio HTML pages.

| Screenshot | Phase | What It Shows |
|-----------|-------|---------------|
| `phase-2-database-size.png` | Phase 2 | Database size summary — 4.57 GB across 14 tables |
| `phase-2-schema-overview.png` | Phase 2 | DataGrip explorer showing all 14 tables |
| `phase-2-table-inventory.png` | Phase 2 | Table inventory with row counts and sizes |
| `phase-3-q4-baseline-explain.png` | Phase 3 | Q4 EXPLAIN showing full 15.3M row scan |
| `phase-4-q4-optimized-result.png` | Phase 4 | Q4 result — 9m 42s down to 2,619 ms |
| `phase-4-q5-optimized-result.png` | Phase 4 | Q5 result — 4,658 ms down to 165 ms |
| `phase-4-index-audit-unused.png` | Phase 4 | sys.schema_unused_indexes — 13 unused indexes |
| `phase-4-before-after-comparison.png` | Phase 4 | Full before/after table for all 6 queries |
| `phase-5-recovery-verification.png` | Phase 5 | Post-recovery row count verification |
| `phase-6-role-assignments.png` | Phase 6 | mysql.role_edges — 3 role assignments |
| `phase-6-user-inventory.png` | Phase 6 | User inventory — 3 application users |
| `vscode-folder-structure.png` | Phase 1 | Full project folder structure in VS Code |
| `vscode-python-script.png` | Phase 1 | Python download script open in VS Code |
| `vscode-phase-2-scripts.png` | Phase 2 | All 16 Phase 2 load scripts in VS Code |
| `vscode-phase-4-scripts.png` | Phase 4 | All 6 Phase 4 optimization scripts in VS Code |
| `vscode-docs-folder.png` | All | docs/ folder showing all 6 phase markdown files |

---

## Portfolio Pages Built

I built 7 HTML pages for the MySQL DBA project following the exact design system of the PostgreSQL DBA project on nasaryobee.com. MySQL brand orange (`#e48c00`) was used as the accent color throughout, replacing the PostgreSQL blue, to visually distinguish the two projects while maintaining consistency with the overall portfolio aesthetic.

| File | Purpose |
|------|---------|
| `index.html` | Project landing page — overview, stats, phase cards, performance results, key findings, tools |
| `phase-1.html` | Data Sourcing — datasets, acquisition strategy, Python scripts, project structure |
| `phase-2.html` | Schema Design & Data Loading — star schema, design decisions, load results, verification |
| `phase-3.html` | Baseline Measurement — 6 query baselines, EXPLAIN analysis, root cause identification |
| `phase-4.html` | Performance Optimization — indexes, query rewrites, index audit, regression fixes, final results |
| `phase-5.html` | Backup & Recovery — mysqldump strategy, backup flags, drop/restore simulation, row verification |
| `phase-6.html` | Security & User Management — 3 roles, 3 users, privilege grants, permissions audit |

All pages share the same navigation structure — sticky header, phase navigation tabs, prev/next buttons — and all screenshot references use relative paths within the `projects/mysql-dba/` directory.

---

## Projects Page Integration

I added the MySQL DBA project card to `projects.html` on nasaryobee.com, positioned directly after the PostgreSQL DBA card. The card links to `projects/mysql-dba/index.html` and uses `mysql-dba-icon.png` as the project logo.

---

## Repository Structure at Completion

- data/raw/ — Raw data files (gitignored)
- docs/ — Phase documentation markdown files
  - phase-1-data-sourcing-and-documentation.md
  - phase-2-installation-schema-and-data-loading.md
  - phase-3-baseline-measurement-and-diagnostics.md
  - phase-4-performance-optimization.md
  - phase-5-backup-and-recovery.md
  - phase-6-security-and-user-management.md
  - phase-7-portfolio-integration.md
- exports/ — Export files
- screenshots/ — 16 portfolio screenshots
- sql/
  - phase-1/ — Download scripts
  - phase-2/ — 16 schema and load scripts
  - phase-3/ — Baseline measurement scripts
  - phase-4/ — 6 optimization scripts
  - phase-5/ — Backup and recovery scripts
  - phase-6/ — User management scripts
  - phase-7/ — Portfolio documentation
- backups/ — Backup files (gitignored)
- .gitignore
- README.md

---

## Live URLs

- **Project landing page:** nasaryobee.com/projects/mysql-dba/index.html
- **Projects page:** nasaryobee.com/projects.html
- **GitHub repository:** github.com/aryobeen007/mysql-dba-project