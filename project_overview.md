# Project Documentation — Full Phase Overview

## Phase 1 — Database Setup (Week 1)

### Environment
- PostgreSQL 18 on Windows (DELL laptop)
- Database: `medical_analytics`
- Data source: Synthea synthetic EHR generator

### Issues Encountered and Fixes

| Error | Cause | Fix |
|-------|-------|-----|
| Column type mismatch | Python preprocessing stored numbers as timestamps | `ALTER TABLE ... ALTER COLUMN TYPE TEXT` |
| Missing columns | Some schema columns absent from CSVs | `ALTER TABLE ... DROP COLUMN` |
| PK violations | Event tables had no unique ID | Removed PK constraints |
| COPY permission error | Windows filesystem restriction | Switched to `\copy` in psql |

---

## Phase 2 — Loading, Indexing, Benchmarking (Week 2)

### Tables Loaded

| Table | Rows |
|-------|------|
| observations | 531,144 |
| imaging_studies | 151,637 |
| procedures | 83,823 |
| encounters | 61,459 |
| medications | 56,430 |
| conditions | 38,094 |
| payer_transitions | 53,101 |
| immunizations | 17,009 |
| providers | 5,056 |
| patients | 1,163 |
| careplans | 3,931 |
| supplies | 1,573 |
| organizations | 1,127 |
| allergies | 794 |
| payers | 10 |
| devices | 89 |
| claims_transactions | 0 |
| **Total** | **900,000+** |

### Data Loading Command
```sql
\copy table_name FROM 'path/to/file.csv' CSV HEADER;
```

### Key Benchmark Results (5 real queries)

| Query | Description | Execution Time |
|-------|-------------|----------------|
| Q1 | Simple join | 0.623 ms |
| Q2 | Time range filter | 29.091 ms |
| Q3 | Aggregation | 46.911 ms |
| Q4 | 4-table join (all indexed) | **0.102 ms — fastest** |
| Q5 | Vital signs (no index on filter) | **671 ms — slowest** |

**Key insight:** Q4 joined 4 tables but ran in 0.1ms because all indexes fired.
Q5 joined 2 tables but took 671ms — no index on observations.category.
Indexes matter more than join count.

---

## Phase 3 — ML Baseline (Project Update 3)

### Dataset: 60 queries (20 real + 40 synthetic)
### Models: Random Forest, Gradient Boosting, SVR

| Model | MAE (ms) | vs PostgreSQL |
|-------|----------|---------------|
| PostgreSQL Planner | 66.4 | Baseline |
| Gradient Boosting | 54.4 | −18% |
| Random Forest | 59.9 | −10% |
| SVR (RBF) | 68.7 | Worse |

---

## Final Presentation — 100 Queries, 5 Models

### Dataset: 100 queries (60 real + 40 synthetic)
### Train/Test: 80/20 split, seed=42

| Model | MAE (ms) | RMSE (ms) | CV-MAE (ms) | vs Baseline |
|-------|----------|-----------|-------------|-------------|
| PostgreSQL Planner | 44.639 | 91.056 | N/A | — |
| **Extra Trees ★** | **26.644** | **64.011** | **89.241** | **−40.3%** |
| SVR (RBF) | 31.779 | 61.374 | 119.632 | −28.8% |
| Random Forest | 32.265 | 66.102 | 96.455 | −27.7% |
| Gradient Boosting | 49.806 | 121.912 | 103.032 | −11.6% |
| Hist GB (XGBoost) | 66.239 | 159.268 | 108.456 | +48.4% |

**H₁ SUPPORTED: EML (26.644) < EPG (44.639)**

### Feature Importance (Gradient Boosting)

| Feature | Importance |
|---------|-----------|
| est_cost | 69.8% |
| planning_time | 11.2% |
| est_rows | 9.7% |
| num_joins | 7.5% |
| join_type | 1.3% |
| scan_type | 0.6% |

**Key finding:** est_cost at 69.8% confirms the ML model is a calibration
layer on PostgreSQL's estimate — not an independent predictor.

---

## How to Run

### Step 1 — Database setup
```bash
psql -U postgres
CREATE DATABASE medical_analytics;
\c medical_analytics
\i sql/schema.sql
```

### Step 2 — Load Synthea data
Download from https://synthea.mitre.org/ then:
```sql
\copy patients FROM 'path/patients.csv' CSV HEADER;
-- Repeat for all 17 tables
```

### Step 3 — Create indexes
```sql
\i sql/indexes.sql
```

### Step 4 — Run ML models
```bash
pip install -r requirements.txt
cd ml
python ml_final.py
```

---

## Future Directions

1. **300+ real queries** — replace all synthetic data with real EXPLAIN ANALYZE
2. **Richer features** — buffer hit rates, actual/estimated row ratio, temp file creation
3. **True XGBoost** — L1/L2 regularization and gain-threshold pruning
4. **Query scheduler** — middleware that intercepts queries, predicts latency,
   and routes expensive queries to off-peak windows
