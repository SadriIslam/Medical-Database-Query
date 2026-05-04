"""
generate_dataset.py
-------------------
Regenerates the synthetic portion of benchmark_final_100.csv.

Queries 1-20 and 61-100 are real EXPLAIN ANALYZE results collected
from pgAdmin. Queries 21-60 are synthetic, modeled on the four
behavioral patterns observed in the real data:

  Pattern 1 — Fast indexed joins:     est_cost < 500,  scan=2 (index), exec < 5ms
  Pattern 2 — Medium bitmap scans:    est_cost 1k-5k,  scan=3 (bitmap), exec 5-100ms
  Pattern 3 — Slow hash joins:        est_cost 5k-15k, join=1 (hash),   exec 100-500ms
  Pattern 4 — Very slow seq scans:    est_cost > 20k,  scan=1 (seq),    exec > 500ms

Usage:
  python generate_dataset.py

Output:
  ../data/benchmark_dataset_60.csv  (Update 3 dataset, 60 queries)
"""

import os
import pandas as pd

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
OUT_PATH = os.path.join(BASE_DIR, '..', 'data', 'benchmark_dataset_60.csv')

COLS = ["query_id","description","est_cost","est_rows","num_joins",
        "join_type","scan_type","planning_time","execution_time"]

# ── Real queries Q1-Q20 ───────────────────────────────────────────
real = [
    (1,  "Simple Join",                    198.23,    53,      1, 2, 3, 3.315,  0.623),
    (2,  "Time Range Filter",              5159.23,   4630,    2, 1, 3, 1.265,  29.091),
    (3,  "Aggregation",                    4442.07,   1160,    0, 0, 1, 0.356,  46.911),
    (4,  "Four Table Join",                109.59,    3,       4, 2, 2, 4.598,  0.102),
    (5,  "Observation Lookup",             38932.75,  24068,   1, 1, 1, 1.469,  671.251),
    (6,  "Provider Encounter Count",       5001.66,   50,      1, 1, 1, 4.871,  190.674),
    (7,  "Patient Conditions List",        150.44,    200,     2, 2, 2, 16.971, 141.435),
    (8,  "Medication Lookup",              125.30,    300,     2, 2, 2, 5.287,  74.316),
    (9,  "Procedures By Date",             4145.35,   21664,   0, 0, 1, 5.193,  10.994),
    (10, "Count Conditions Per Patient",   9416.10,   100,     1, 1, 1, 1.042,  488.375),
    (11, "Immunizations By Date",          715.13,    4109,    0, 0, 1, 2.148,  1.140),
    (12, "Observations By Category",       19639.30,  163592,  0, 0, 1, 4.421,  3.462),
    (13, "Medications With Date Filter",   978.42,    300,     2, 2, 2, 1.062,  26.391),
    (14, "Encounter Class Count",          4386.04,   6,       0, 0, 1, 0.200,  52.425),
    (15, "Most Common Conditions",         1428.22,   50,      0, 0, 1, 0.167,  27.161),
    (16, "Imaging Studies By Date",        94.54,     500,     0, 0, 1, 0.211,  2.638),
    (17, "Five Table Join",                1002.97,   200,     4, 2, 2, 8.501,  5.440),
    (18, "Allergy Lookup",                 367.92,    200,     2, 2, 2, 1.494,  3.320),
    (19, "Supplies By Date",               12.51,     300,     0, 0, 1, 0.114,  0.350),
    (20, "Full Patient Profile",           16142.27,  50,      3, 1, 1, 3.903,  1073.446),
]

# ── Synthetic queries Q21-Q60 ─────────────────────────────────────
synthetic = [
    (21,"Patient Name Lookup",85.20,10,1,2,2,1.200,0.312),
    (22,"Encounter By Provider",220.50,80,1,2,2,2.100,0.891),
    (23,"Conditions By Encounter",95.30,5,1,2,2,0.980,0.445),
    (24,"Procedures By Patient",110.40,12,1,2,2,1.340,0.520),
    (25,"Medications By Encounter",130.60,20,1,2,2,1.560,0.710),
    (26,"Imaging By Patient",88.20,8,1,2,2,0.890,0.390),
    (27,"Allergies By Patient",70.10,4,1,2,2,0.760,0.280),
    (28,"Supplies By Patient",60.50,6,1,2,2,0.650,0.190),
    (29,"Encounters In 2021",3200.50,5100,0,0,3,1.100,18.500),
    (30,"Conditions In 2020",2100.30,3800,0,0,3,0.900,12.300),
    (31,"Procedures 2019-2021",4800.70,18000,0,0,3,1.400,22.700),
    (32,"Medications In 2022",1800.20,2900,0,0,3,0.800,9.800),
    (33,"Imaging Studies 2020-2022",3600.40,6200,0,0,3,1.200,15.600),
    (34,"Immunizations In 2021",950.60,1500,0,0,3,0.700,4.200),
    (35,"Count Procedures Per Patient",7200.30,83823,0,0,1,0.450,88.500),
    (36,"Sum Medications Per Encounter",5400.20,56430,0,0,1,0.380,62.300),
    (37,"Count Imaging Per Patient",12000.50,151637,0,0,1,0.520,145.200),
    (38,"Average Encounter Duration",4100.80,61459,0,0,1,0.310,51.700),
    (39,"Count Allergies Per Patient",400.20,794,0,0,1,0.180,5.100),
    (40,"Count Supplies Per Encounter",600.40,1573,0,0,1,0.220,7.800),
    (41,"Patient Medication History",180.30,150,2,2,2,4.200,2.100),
    (42,"Patient Procedure History",210.50,180,2,2,2,5.100,2.800),
    (43,"Provider Patient List",320.70,250,2,2,2,6.300,3.900),
    (44,"Encounter Imaging List",155.40,120,2,2,2,3.800,1.750),
    (45,"Patient Allergy Profile",140.20,80,2,2,2,3.200,1.420),
    (46,"Encounter Supply List",170.60,140,2,2,2,4.500,1.980),
    (47,"All Vital Signs Lookup",35000.40,200000,0,0,1,1.800,580.300),
    (48,"Lab Results Full Scan",28000.60,170000,0,0,1,1.600,490.200),
    (49,"Imaging Full Category Scan",22000.30,130000,0,0,1,1.400,380.500),
    (50,"All Observations No Filter",42000.80,531144,0,0,1,2.100,820.600),
    (51,"Encounter Condition Aggregate",8900.50,38094,1,1,1,1.200,350.400),
    (52,"Patient Encounter Summary",6700.30,61459,1,1,1,0.980,260.700),
    (53,"Provider Procedure Summary",11200.70,83823,1,1,1,1.450,430.200),
    (54,"Payer Medication Summary",7800.40,56430,1,1,1,1.100,310.500),
    (55,"Organization Encounter Count",5500.20,61459,1,1,1,0.850,210.300),
    (56,"Full Clinical Profile",420.30,25,4,2,2,7.800,1.200),
    (57,"Patient Visit Complete",380.50,18,4,2,2,6.900,0.980),
    (58,"Encounter Full Detail",350.20,15,4,2,2,6.200,0.870),
    (59,"Provider Full Summary",510.40,30,3,2,2,5.600,1.450),
    (60,"Patient All Records",480.60,22,3,2,2,5.100,1.180),
]

df = pd.DataFrame(real + synthetic, columns=COLS)
os.makedirs(os.path.dirname(OUT_PATH), exist_ok=True)
df.to_csv(OUT_PATH, index=False)
print(f"Generated {len(df)} queries → {OUT_PATH}")
print(f"Range: {df['execution_time'].min():.3f}ms — {df['execution_time'].max():.3f}ms")
