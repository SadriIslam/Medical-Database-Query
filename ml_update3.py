"""
ml_update3.py
-------------
CS 8260 — Advanced Database Systems | KSU Spring 2026
Project Update 3 — 3 models on 60-query dataset

USAGE:
  python ml_update3.py

Loads benchmark_dataset_60.csv and trains:
  1. Random Forest
  2. Gradient Boosting
  3. SVR (RBF Kernel)
"""

import os
import pandas as pd
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import warnings
warnings.filterwarnings('ignore')

from sklearn.ensemble import RandomForestRegressor, GradientBoostingRegressor
from sklearn.svm import SVR
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.metrics import mean_absolute_error, mean_squared_error

BASE_DIR  = os.path.dirname(os.path.abspath(__file__))
DATA_PATH = os.path.join(BASE_DIR, '..', 'data', 'benchmark_dataset_60.csv')
SEED = 42
FEATURE_COLS = ["est_cost","est_rows","num_joins","join_type","scan_type","planning_time"]
TARGET = "execution_time"

df = pd.read_csv(DATA_PATH)
X = df[FEATURE_COLS]; y = df[TARGET]
X_train,X_test,y_train,y_test = train_test_split(X,y,test_size=0.2,random_state=SEED)
sc = StandardScaler()
Xsc_tr = sc.fit_transform(X_train); Xsc_te = sc.transform(X_test)

print(f"Update 3 — 60 queries | Train={len(X_train)} Test={len(X_test)}")

def run(name, m, Xtr, Xte):
    m.fit(Xtr,y_train); p=m.predict(Xte)
    mae=mean_absolute_error(y_test,p); rmse=np.sqrt(mean_squared_error(y_test,p))
    cv=-cross_val_score(m,Xtr,y_train,cv=5,scoring='neg_mean_absolute_error').mean()
    print(f"  {name:<25} MAE={mae:.3f}  RMSE={rmse:.3f}  CV={cv:.3f}")
    return {"preds":p,"mae":mae,"rmse":rmse,"cv":cv,"model":m}

R={}
R["Random Forest"]     = run("Random Forest",     RandomForestRegressor(n_estimators=200,max_depth=8,random_state=SEED),X_train,X_test)
R["Gradient Boosting"] = run("Gradient Boosting", GradientBoostingRegressor(n_estimators=300,learning_rate=0.05,max_depth=4,subsample=0.8,random_state=SEED),X_train,X_test)
R["SVR (RBF)"]         = run("SVR (RBF)",         SVR(kernel='rbf',C=100,gamma=0.1,epsilon=5),Xsc_tr,Xsc_te)

scale=y.mean()/X["est_cost"].replace(0,0.001).mean()
pg_p=X_test["est_cost"]*scale
pg_mae=mean_absolute_error(y_test,pg_p)
print(f"  {'PostgreSQL Planner':<25} MAE={pg_mae:.3f}")

best=min(R,key=lambda k:R[k]['mae'])
print(f"\nBest: {best} — MAE {R[best]['mae']:.3f} vs PostgreSQL {pg_mae:.3f}")
if R[best]['mae'] < pg_mae:
    pct=(pg_mae-R[best]['mae'])/pg_mae*100
    print(f"H1 SUPPORTED ✓  —  {pct:.1f}% better than PostgreSQL!")

print("\nFeature Importance (Gradient Boosting):")
gb=R["Gradient Boosting"]["model"]
for feat,imp in sorted(zip(FEATURE_COLS,gb.feature_importances_),key=lambda x:x[1],reverse=True):
    print(f"  {feat:<15} {imp:.4f}  {'█'*int(imp*45)}")
