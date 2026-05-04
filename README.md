# Predicting PostgreSQL Query Execution Latency


> Can a supervised Machine Learning model predict how long a PostgreSQL query will take — more accurately than PostgreSQL's own built-in cost estimator?

---



---

## Project Summary

This project builds a hospital database using synthetic EHR data from [Synthea](https://synthea.mitre.org/), runs 100 benchmark queries using PostgreSQL's `EXPLAIN ANALYZE`, and trains five supervised ML regression models to predict query execution latency in milliseconds.

### Research Hypotheses

- **H₀:** EML ≥ EPG — ML model error is equal or worse than PostgreSQL's estimator
- **H₁:** EML < EPG — ML model error is lower than PostgreSQL's estimator

### Final Result

**H₁ is supported.** Extra Trees Regressor achieved MAE of **26.644 ms** — a **40.3% improvement** over the PostgreSQL planner baseline of **44.639 ms**. Three of five models outperformed the baseline.

---

## Repository Structure

```
📁 project-root/
│
├── 📁 data/
│   ├── benchmark_final_100.csv     ← Final 100-query ML dataset (used for final presentation)
│   └── benchmark_dataset_60.csv    ← 60-query dataset (used for Project Update 3)
│
├── 📁 ml/
│   ├── ml_final.py                 ← Final ML script: 5 models, 100 queries
│   ├── ml_update3.py               ← Update 3 ML script: 3 models, 60 queries
│   └── generate_dataset.py         ← Script that generates the synthetic portion of the dataset
│
├── 📁 sql/
│   ├── schema.sql                  ← Full 17-table PostgreSQL schema
│   ├── indexes.sql                 ← All 16 B-tree index definitions + ANALYZE
│   └── benchmark_queries.sql       ← All 20 real benchmark queries with EXPLAIN ANALYZE
│
├── 📁 results/
│   ├── fig_model_comparison.png    ← MAE and RMSE bar charts (all models)
│   ├── fig_feature_importance.png  ← Gradient Boosting feature importance
│   ├── fig_actual_vs_predicted.png ← Extra Trees actual vs. predicted scatter plot
│   ├── fig_distribution.png        ← Query execution time distribution histogram
│   └── fig_methodology.png         ← System methodology flow diagram
│
├── 📁 docs/
│   └── project_overview.md         ← Detailed documentation of all project phases
│
├── requirements.txt                ← Python dependencies
├── .gitignore
└── README.md
```

---

## Quick Start

### 1. Clone the repository
```bash
git clone https://github.com/YOUR_USERNAME/query-latency-prediction.git
cd query-latency-prediction
```

### 2. Install Python dependencies
```bash
pip install -r requirements.txt
```

### 3. Run the final ML evaluation
```bash
cd ml
python ml_final.py
```

This will:
- Load `../data/benchmark_final_100.csv`
- Train 5 ML models (Random Forest, Gradient Boosting, Extra Trees, Hist GB, SVR)
- Compare against the PostgreSQL planner baseline
- Print the full results table and hypothesis test outcome
- Save result charts to `../results/`

---

## Dataset

### benchmark_final_100.csv (Final Presentation)

100 queries — 60 real EXPLAIN ANALYZE results + 40 synthetic queries modeled on real patterns.

| Split | Queries |
|-------|---------|
| Training | 80 (80%) |
| Test | 20 (20%) |

**Execution time range:** 0.041 ms — 1,747.285 ms  
**Mean:** 152.59 ms | **Std Dev:** 288.95 ms

### Features (inputs to ML models)

| Feature | Source | Description |
|---------|--------|-------------|
| `est_cost` | Total Cost in plan | PostgreSQL's own cost estimate — 69.8% feature importance |
| `planning_time` | Planning Time field | Time spent generating the plan — 11.2% importance |
| `est_rows` | Plan Rows field | Estimated rows to process — 9.7% importance |
| `num_joins` | Count of Join nodes | Number of table joins — 7.5% importance |
| `join_type` | Node type encoding | Hash=1, Nested Loop=2, Merge=3 |
| `scan_type` | Node type encoding | Sequential=1, Index=2, Bitmap=3 |

**Target variable:** `execution_time` — actual wall-clock milliseconds from EXPLAIN ANALYZE

### Query Category Breakdown

| Category | Count | Latency Range | Characteristics |
|----------|-------|---------------|-----------------|
| Fast Indexed Joins | 33 | < 5 ms | Index Nested Loop, low est_cost |
| Medium Queries | 38 | 5–100 ms | Bitmap Heap Scan, date range filters |
| Slow Hash Joins | 19 | 100–500 ms | Hash Join, large table scans |
| Very Slow Scans | 10 | > 500 ms | Sequential scan, external merge sort |

---

## Model Results

| Model | MAE (ms) | RMSE (ms) | CV-MAE (ms) | vs. Baseline |
|-------|----------|-----------|-------------|--------------|
| PostgreSQL Planner | 44.639 | 91.056 | N/A | — |
| **Extra Trees ★** | **26.644** | **64.011** | **89.241** | **−40.3%** |
| SVR (RBF) | 31.779 | 61.374 | 119.632 | −28.8% |
| Random Forest | 32.265 | 66.102 | 96.455 | −27.7% |
| Gradient Boosting | 49.806 | 121.912 | 103.032 | −11.6% |
| Hist GB (XGBoost) | 66.239 | 159.268 | 108.456 | +48.4% |

★ Best model — H₁ supported: EML (26.644) < EPG (44.639)

---

## Database Setup

### Environment
- PostgreSQL 18 on Windows
- Database name: `medical_analytics`
- Data: Synthea synthetic EHR CSVs

### Key Tables

| Table | Rows |
|-------|------|
| observations | 531,144 |
| imaging_studies | 151,637 |
| procedures | 83,823 |
| encounters | 61,459 |
| medications | 56,430 |
| conditions | 38,094 |
| **Total** | **900,000+** |

### Setup Steps
```sql
-- 1. Create database
CREATE DATABASE medical_analytics;
\c medical_analytics

-- 2. Create schema
\i sql/schema.sql

-- 3. Load Synthea CSVs (example for one table)
\copy patients FROM 'path/to/patients.csv' CSV HEADER;
-- Repeat for all 17 tables

-- 4. Create indexes
\i sql/indexes.sql
```

---

## Key Findings

1. **Extra Trees achieves 40.3% better MAE than PostgreSQL** — three independent model families confirm H₁
2. **est_cost dominates at 69.8%** — the ML model is a calibration layer on PostgreSQL's estimate, not an independent predictor
3. **Indexes matter more than join count** — Q4 (4 tables, all indexed) = 0.1 ms vs Q5 (2 tables, no index on filter) = 671 ms
4. **Boosting methods need more data** — Gradient Boosting and XGBoost require 240+ training examples to outperform ensembles

---

## Requirements

- Python 3.8+
- PostgreSQL 18 (for database setup)
- See `requirements.txt` for Python packages

---

