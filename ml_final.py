"""
ml_final.py
-----------


MODELS TRAINED:
  1. Random Forest
  2. Gradient Boosting
  3. Extra Trees          ← Best: MAE 26.644 ms (40.3% better than PostgreSQL)
  4. Histogram Gradient Boosting (XGBoost-style)
  5. SVR (RBF Kernel)

USAGE:
  Put this file and benchmark_final_100.csv in the same folder, then:

  pip install pandas scikit-learn matplotlib numpy
  python ml_final.py

OUTPUT:
  - Full results table printed to console
  - Hypothesis test result (H0 vs H1)
  - Feature importance scores
  - Saves results_chart.png to ../results/
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

from sklearn.ensemble import (
    RandomForestRegressor,
    GradientBoostingRegressor,
    ExtraTreesRegressor,
    HistGradientBoostingRegressor,
)
from sklearn.svm import SVR
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import train_test_split, cross_val_score, KFold
from sklearn.metrics import mean_absolute_error, mean_squared_error

# ── Configuration ─────────────────────────────────────────────────
BASE_DIR    = os.path.dirname(os.path.abspath(__file__))
DATA_PATH   = os.path.join(BASE_DIR, '..', 'data', 'benchmark_final_100.csv')
RESULTS_DIR = os.path.join(BASE_DIR, '..', 'results')
SEED        = 42

FEATURE_COLS = [
    "est_cost",       # PostgreSQL's own cost estimate (dimensionless)
    "est_rows",       # Estimated rows to process
    "num_joins",      # Number of table joins in the plan
    "join_type",      # Hash=1, Nested Loop=2, Merge=3
    "scan_type",      # Sequential=1, Index=2, Bitmap=3
    "planning_time",  # Time PostgreSQL spent planning (ms)
]
TARGET = "execution_time"   # actual wall-clock ms from EXPLAIN ANALYZE


def load_data():
    print("=" * 62)
    print("  FINAL PRESENTATION — ML QUERY LATENCY PREDICTION")
    print("  100 Queries | 5 Models + PostgreSQL Baseline")
    print("=" * 62)

    if not os.path.exists(DATA_PATH):
        # Try same directory as script
        alt = os.path.join(BASE_DIR, 'benchmark_final_100.csv')
        if os.path.exists(alt):
            df = pd.read_csv(alt)
        else:
            raise FileNotFoundError(
                f"Cannot find benchmark_final_100.csv\n"
                f"Tried: {DATA_PATH}\n"
                f"And:   {alt}\n"
                f"Place the CSV in the same folder as this script."
            )
    else:
        df = pd.read_csv(DATA_PATH)

    print(f"\n  Queries loaded   : {len(df)}")
    print(f"  Latency range    : {df[TARGET].min():.3f} ms — {df[TARGET].max():.3f} ms")
    print(f"  Mean latency     : {df[TARGET].mean():.2f} ms")
    print(f"  Std deviation    : {df[TARGET].std():.2f} ms")

    fast  = len(df[df[TARGET] < 5])
    med   = len(df[(df[TARGET] >= 5) & (df[TARGET] < 100)])
    slow  = len(df[(df[TARGET] >= 100) & (df[TARGET] < 500)])
    vslow = len(df[df[TARGET] >= 500])
    print(f"\n  Fast  (<5ms)     : {fast}")
    print(f"  Medium (5-100ms) : {med}")
    print(f"  Slow (100-500ms) : {slow}")
    print(f"  V.Slow (500ms+)  : {vslow}")
    return df


def prepare(df):
    X = df[FEATURE_COLS]
    y = df[TARGET]
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.20, random_state=SEED
    )
    sc = StandardScaler()
    X_train_sc = sc.fit_transform(X_train)
    X_test_sc  = sc.transform(X_test)
    print(f"\n  Training queries : {len(X_train)}")
    print(f"  Test queries     : {len(X_test)}")
    return X, y, X_train, X_test, y_train, y_test, X_train_sc, X_test_sc


def train_all(X, y, X_train, X_test, y_train, y_test, X_train_sc, X_test_sc):
    print("\n" + "=" * 62)
    print("  TRAINING MODELS")
    print("=" * 62)

    kf = KFold(n_splits=5, shuffle=True, random_state=SEED)
    results = {}

    def fit(name, model, Xtr, Xte, X_cv=None, y_cv=None):
        model.fit(Xtr, y_train)
        p   = model.predict(Xte)
        mae  = mean_absolute_error(y_test, p)
        rmse = np.sqrt(mean_squared_error(y_test, p))
        cv   = (
            -cross_val_score(model, X_cv, y_cv, cv=kf,
                             scoring='neg_mean_absolute_error').mean()
            if X_cv is not None else None
        )
        cv_s = f"{cv:.3f}" if cv else "N/A"
        print(f"\n  {name}")
        print(f"    Test MAE  : {mae:.3f} ms")
        print(f"    Test RMSE : {rmse:.3f} ms")
        print(f"    CV-MAE    : {cv_s} ms")
        results[name] = {"preds": p, "mae": mae, "rmse": rmse, "cv": cv, "model": model}

    fit("Random Forest",
        RandomForestRegressor(n_estimators=200, max_depth=8,
                              min_samples_split=3, random_state=SEED),
        X_train, X_test, X, y)

    fit("Gradient Boosting",
        GradientBoostingRegressor(n_estimators=300, learning_rate=0.05,
                                  max_depth=4, subsample=0.8,
                                  min_samples_split=3, random_state=SEED),
        X_train, X_test, X, y)

    fit("Extra Trees",
        ExtraTreesRegressor(n_estimators=200, max_depth=8,
                            min_samples_split=3, random_state=SEED),
        X_train, X_test, X, y)

    fit("Hist GB (XGBoost-style)",
        HistGradientBoostingRegressor(max_iter=300, learning_rate=0.05,
                                      max_depth=4, min_samples_leaf=3,
                                      random_state=SEED),
        X_train, X_test, X, y)

    fit("SVR (RBF Kernel)",
        SVR(kernel='rbf', C=100, gamma=0.1, epsilon=5),
        X_train_sc, X_test_sc, X_train_sc, y_train)

    # PostgreSQL baseline: scale est_cost linearly to ms
    scale    = y.mean() / X["est_cost"].replace(0, 0.001).mean()
    pg_preds = X_test["est_cost"] * scale
    pg_mae   = mean_absolute_error(y_test, pg_preds)
    pg_rmse  = np.sqrt(mean_squared_error(y_test, pg_preds))
    print(f"\n  PostgreSQL Planner (baseline)")
    print(f"    Test MAE  : {pg_mae:.3f} ms")
    print(f"    Test RMSE : {pg_rmse:.3f} ms")
    results["PostgreSQL Planner"] = {
        "preds": pg_preds, "mae": pg_mae, "rmse": pg_rmse,
        "cv": None, "model": None
    }
    return results


def print_results(results, y_test, X, y):
    ORDER = ["PostgreSQL Planner", "Random Forest", "Gradient Boosting",
             "Extra Trees", "Hist GB (XGBoost-style)", "SVR (RBF Kernel)"]
    pg_mae = results["PostgreSQL Planner"]["mae"]

    print("\n" + "=" * 72)
    print("  FINAL RESULTS TABLE")
    print("=" * 72)
    print(f"\n  {'Model':<28} {'MAE (ms)':>10} {'RMSE (ms)':>10} "
          f"{'CV-MAE':>10} {'vs Baseline':>12}")
    print("  " + "-" * 70)

    for name in ORDER:
        r   = results[name]
        cv_s = f"{r['cv']:.3f}" if r['cv'] else "   N/A"
        if name == "PostgreSQL Planner":
            diff_s = "  baseline"
        else:
            diff = (pg_mae - r['mae']) / pg_mae * 100
            diff_s = f"  {diff:+.1f}%"
        print(f"  {name:<28} {r['mae']:>10.3f} {r['rmse']:>10.3f} "
              f"{cv_s:>10}{diff_s:>12}")

    # Hypothesis test
    ml_only = {k: v for k, v in results.items() if k != "PostgreSQL Planner"}
    best    = min(ml_only, key=lambda k: ml_only[k]['mae'])
    best_v  = ml_only[best]['mae']

    print("\n" + "=" * 72)
    print("  HYPOTHESIS TEST")
    print("=" * 72)
    print(f"\n  H0: EML >= EPG  (ML model is NOT better than PostgreSQL)")
    print(f"  H1: EML <  EPG  (ML model IS better than PostgreSQL)")
    print(f"\n  PostgreSQL Planner MAE : {pg_mae:.3f} ms")
    print(f"  Best ML model          : {best}")
    print(f"  Best ML MAE            : {best_v:.3f} ms")
    if best_v < pg_mae:
        pct = (pg_mae - best_v) / pg_mae * 100
        print(f"\n  RESULT: H1 SUPPORTED ✓")
        print(f"  {best} is {pct:.1f}% more accurate than PostgreSQL!")
    else:
        print(f"\n  RESULT: H0 holds — PostgreSQL still wins")

    # Feature importance
    gb = results["Gradient Boosting"]["model"]
    print("\n" + "=" * 72)
    print("  FEATURE IMPORTANCE  (Gradient Boosting)")
    print("=" * 72)
    for feat, imp in sorted(zip(FEATURE_COLS, gb.feature_importances_),
                            key=lambda x: x[1], reverse=True):
        bar = "█" * int(imp * 50)
        print(f"  {feat:<15} {imp:.4f}  {bar}")

    return best


def save_charts(results, y_test, best_name):
    os.makedirs(RESULTS_DIR, exist_ok=True)

    ORDER  = ["PostgreSQL Planner", "Random Forest", "Gradient Boosting",
              "Extra Trees", "Hist GB (XGBoost-style)", "SVR (RBF Kernel)"]
    LABELS = ["PostgreSQL\nPlanner", "Random\nForest", "Gradient\nBoosting",
              "Extra\nTrees", "Hist GB\n(XGBoost)", "SVR\n(RBF)"]
    COLORS = ["#666666", "#0F4A3A", "#1E3A5F", "#FF8C00", "#8B0000", "#3D1A6E"]
    maes   = [results[n]["mae"]  for n in ORDER]
    rmses  = [results[n]["rmse"] for n in ORDER]
    bi     = ORDER.index(best_name)

    gb  = results["Gradient Boosting"]["model"]
    et_p = results[best_name]["preds"]

    fig = plt.figure(figsize=(16, 10))
    fig.patch.set_facecolor("white")
    fig.suptitle(
        "Final Presentation — ML Query Latency Prediction\n"
        "100 Queries  |  5 Models  +  PostgreSQL Baseline",
        fontsize=13, fontweight="bold", y=0.98
    )
    bw = 0.50

    # MAE
    ax1 = fig.add_subplot(2, 2, 1)
    bars = ax1.bar(LABELS, maes, color=COLORS, edgecolor="white", width=bw)
    bars[bi].set_edgecolor("#F0C040"); bars[bi].set_linewidth(2.5)
    ax1.axhline(maes[0], color="#666666", linestyle="--", lw=1.2, alpha=0.7,
                label=f"PostgreSQL Baseline ({maes[0]:.1f} ms)")
    for j, (bar, v) in enumerate(zip(bars, maes)):
        ax1.text(bar.get_x()+bar.get_width()/2, v+0.5, f"{v:.1f}",
                 ha="center", va="bottom", fontsize=9, fontweight="bold", color=COLORS[j])
    ax1.set_title("MAE Comparison  (lower = better)", fontsize=12, fontweight="bold")
    ax1.set_ylabel("Mean Absolute Error (ms)"); ax1.set_ylim(0, max(maes)*1.25)
    ax1.spines["top"].set_visible(False); ax1.spines["right"].set_visible(False)
    ax1.yaxis.grid(True, alpha=0.3, linestyle="--"); ax1.set_axisbelow(True)
    ax1.tick_params(axis="x", labelsize=8.5); ax1.legend(fontsize=9)

    # RMSE
    ax2 = fig.add_subplot(2, 2, 2)
    bars2 = ax2.bar(LABELS, rmses, color=COLORS, edgecolor="white", width=bw)
    bars2[bi].set_edgecolor("#F0C040"); bars2[bi].set_linewidth(2.5)
    ax2.axhline(rmses[0], color="#666666", linestyle="--", lw=1.2, alpha=0.7,
                label=f"PostgreSQL Baseline ({rmses[0]:.1f} ms)")
    for j, (bar, v) in enumerate(zip(bars2, rmses)):
        ax2.text(bar.get_x()+bar.get_width()/2, v+1, f"{v:.1f}",
                 ha="center", va="bottom", fontsize=9, fontweight="bold", color=COLORS[j])
    ax2.set_title("RMSE Comparison  (lower = better)", fontsize=12, fontweight="bold")
    ax2.set_ylabel("RMSE (ms)"); ax2.set_ylim(0, max(rmses)*1.25)
    ax2.spines["top"].set_visible(False); ax2.spines["right"].set_visible(False)
    ax2.yaxis.grid(True, alpha=0.3, linestyle="--"); ax2.set_axisbelow(True)
    ax2.tick_params(axis="x", labelsize=8.5); ax2.legend(fontsize=9)

    # Feature importance
    ax3 = fig.add_subplot(2, 2, 3)
    fs = sorted(zip(FEATURE_COLS, gb.feature_importances_), key=lambda x: x[1])
    fc = ["#BBBBBB","#BBBBBB","#8B6914","#7A3A0A","#1E3A5F","#1E3A5F"]
    hb = ax3.barh([f[0] for f in fs], [f[1] for f in fs],
                  color=fc, edgecolor="white", height=0.55)
    for bar, v in zip(hb, [f[1] for f in fs]):
        ax3.text(v+0.004, bar.get_y()+bar.get_height()/2,
                 f"{v:.3f}", va="center", fontsize=10, fontweight="bold")
    ax3.set_title("Feature Importance — Gradient Boosting", fontsize=12, fontweight="bold")
    ax3.set_xlabel("Importance Score"); ax3.set_xlim(0, 0.82)
    ax3.spines["top"].set_visible(False); ax3.spines["right"].set_visible(False)
    ax3.xaxis.grid(True, alpha=0.3, linestyle="--"); ax3.set_axisbelow(True)

    # Actual vs Predicted
    ax4 = fig.add_subplot(2, 2, 4)
    ax4.scatter(y_test.values, et_p, color=COLORS[bi], alpha=0.8,
                edgecolors="white", s=65, zorder=3)
    mx = max(max(y_test.values), max(et_p)) * 1.08
    ax4.plot([0, mx], [0, mx], "k--", lw=1.2, label="Perfect prediction")
    ax4.set_xlabel("Actual Execution Time (ms)")
    ax4.set_ylabel("Predicted Execution Time (ms)")
    ax4.set_title(f"Actual vs Predicted — {best_name}", fontsize=12, fontweight="bold")
    ax4.legend(fontsize=10)
    ax4.spines["top"].set_visible(False); ax4.spines["right"].set_visible(False)
    ax4.yaxis.grid(True, alpha=0.3, linestyle="--")
    ax4.xaxis.grid(True, alpha=0.3, linestyle="--")
    ax4.set_axisbelow(True)

    leg = [mpatches.Patch(color=c, label=f"{n}   MAE={results[n]['mae']:.1f}ms")
           for c, n in zip(COLORS, ORDER)]
    fig.legend(handles=leg, loc="lower center", ncol=3, fontsize=9.5,
               framealpha=0.9, bbox_to_anchor=(0.5, 0.01))
    plt.tight_layout(rect=[0, 0.09, 1, 0.96])

    out = os.path.join(RESULTS_DIR, "results_chart.png")
    plt.savefig(out, dpi=180, bbox_inches="tight", facecolor="white")
    print(f"\n  Chart saved → {out}")


if __name__ == "__main__":
    df = load_data()
    X, y, X_train, X_test, y_train, y_test, Xsc_tr, Xsc_te = prepare(df)
    results = train_all(X, y, X_train, X_test, y_train, y_test, Xsc_tr, Xsc_te)
    best = print_results(results, y_test, X, y)
    save_charts(results, y_test, best)
    print("\n  ✅  Done!\n")
