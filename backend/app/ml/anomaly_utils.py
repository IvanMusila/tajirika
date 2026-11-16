
# anomaly_utils.py
# Shared between Google Colab (training) and FastAPI (serving).

import warnings, json, joblib
import numpy as np
import pandas as pd
from sklearn.ensemble import IsolationForest
from sklearn.preprocessing import LabelEncoder

warnings.filterwarnings("ignore")

MIN_WEEKS_FOR_ANOMALY = 6
CONTAMINATION         = 0.015
SEVERITY_HIGH         = -0.15
SEVERITY_MED          = -0.05
ALERT_ZSCORE          = 2.0
SKIP_CATEGORIES       = {"invisible"}
SKIP_TYPES            = {"fee", "loan_repayment", "savings_deposit"}

CATEGORIES = ["necessity", "convenience", "social", "aspirational", "invisible"]

def build_features(df, merchant_stats=None):
    df = df.copy()
    df["timestamp"] = pd.to_datetime(df["timestamp"])

    enc = LabelEncoder()
    enc.fit(CATEGORIES)
    cat_codes = enc.transform(
        df["category"].where(df["category"].isin(CATEGORIES), "convenience")
    )

    df["log_amount"]   = np.log1p(df["amount"].astype(float))
    df["hour"]         = df["timestamp"].dt.hour
    df["dow"]          = df["timestamp"].dt.dayofweek
    df["cat_code"]     = cat_codes

    df = df.sort_values("timestamp").reset_index(drop=True)
    df["rolling_7d"]   = (df.groupby("category")["amount"]
                            .transform(lambda x: x.rolling(7, min_periods=1).mean()))
    df["log_roll7"]    = np.log1p(df["rolling_7d"])

    if merchant_stats is not None:
        med = df["merchant_id"].astype(str).map(merchant_stats.get("median", {}))
        med = med.fillna(df["amount"].median())
        df["amt_vs_med"] = df["amount"].astype(float) / med.clip(lower=1)
    else:
        df["amt_vs_med"] = 1.0

    return df[["log_amount", "hour", "dow", "cat_code", "log_roll7", "amt_vs_med"]].values

def compute_merchant_stats(df):
    debit = df[df['is_debit'] & ~df['transaction_type'].isin(SKIP_TYPES)].copy()
    stats = {'median': {}, 'freq': {}}
    for mid, grp in debit.groupby('merchant_id'):
        stats['freq'][str(mid)] = int(len(grp))
        if len(grp) >= 3:
            stats['median'][str(mid)] = float(grp['amount'].median())
    return stats

def fit_user_anomaly(df, contamination=CONTAMINATION):
    debit = df[
        df["is_debit"] &
        ~df["transaction_type"].isin(SKIP_TYPES) &
        ~df["category"].isin(SKIP_CATEGORIES)
    ].copy()
    merchant_stats = compute_merchant_stats(debit)
    X = build_features(debit, merchant_stats)
    model = IsolationForest(
        n_estimators=200,
        contamination=contamination,
        random_state=42,
        n_jobs=-1,
    )
    model.fit(X)
    return model, merchant_stats

def detect_anomalies(df, model, merchant_stats):
    debit = df[
        df["is_debit"] &
        ~df["transaction_type"].isin(SKIP_TYPES) &
        ~df["category"].isin(SKIP_CATEGORIES)
    ].copy()
    if debit.empty:
        return pd.DataFrame()
    X        = build_features(debit, merchant_stats)
    scores   = model.decision_function(X)
    preds    = model.predict(X)
    debit    = debit.reset_index(drop=True)
    debit["anomaly_score"]  = scores
    debit["is_anomaly"]     = preds == -1
    debit["severity"]       = "normal"
    debit.loc[debit["anomaly_score"] <= SEVERITY_HIGH, "severity"] = "high"
    debit.loc[(debit["anomaly_score"] > SEVERITY_HIGH) &
              (debit["anomaly_score"] <= SEVERITY_MED),  "severity"] = "medium"
    debit.loc[(debit["anomaly_score"] > SEVERITY_MED) &
              (debit["anomaly_score"] <= 0),              "severity"] = "low"
    
    # After computing is_anomaly, suppress whitelisted recurring transactions
    debit['_recurring'] = debit.apply(
        lambda r: is_recurring_normal(r, merchant_stats), axis=1)
    debit.loc[debit['_recurring'], 'is_anomaly'] = False
    debit.loc[debit['_recurring'], 'severity']   = 'normal'
    debit = debit.drop(columns=['_recurring'])
    return debit

def explain_anomaly(row, df, merchant_stats):
    reasons = []
    merchant_median = merchant_stats.get("median", {}).get(str(row["merchant_id"]))
    if merchant_median and row["amount"] > merchant_median * 2.5:
        reasons.append(
            f"Amount (Ksh {row['amount']:,.0f}) is "
            f"{row['amount']/merchant_median:.1f}x your usual spend "
            f"at {row['merchant_name']} (median Ksh {merchant_median:,.0f})."
        )
    ts = pd.to_datetime(row["timestamp"])
    if ts.hour < 5 or ts.hour >= 23:
        reasons.append(
            f"Unusual time — transaction at {ts.strftime('%I:%M %p')}."
        )
    df_tmp = df[df["merchant_id"] == row["merchant_id"]].copy()
    df_tmp["hour"] = pd.to_datetime(df_tmp["timestamp"]).dt.hour
    typical_hours = df_tmp["hour"].mode()
    if not typical_hours.empty and abs(ts.hour - typical_hours.iloc[0]) > 6:
        reasons.append(
            f"You usually pay {row['merchant_name']} "
            f"around {typical_hours.iloc[0]:02d}:00."
        )
    cutoff = ts - pd.Timedelta(days=30)
    recent_cat = df[
        (df["category"] == row["category"]) &
        (pd.to_datetime(df["timestamp"]) >= cutoff) &
        (pd.to_datetime(df["timestamp"]) < ts) &
        df["is_debit"]
    ]["amount"].sum()
    baseline_cat = df[
        (df["category"] == row["category"]) &
        (pd.to_datetime(df["timestamp"]) < cutoff) &
        df["is_debit"]
    ]["amount"].mean() * 30 if len(df) > 60 else None
    if baseline_cat and recent_cat > baseline_cat * 1.5:
        reasons.append(
            f"Your {row['category']} spend in the last 30 days "
            f"(Ksh {recent_cat:,.0f}) is "
            f"{recent_cat/baseline_cat:.1f}x your usual monthly amount "
            f"(Ksh {baseline_cat:,.0f})."
        )
    if not reasons:
        reasons.append(
            f"This transaction is unusual based on your spending patterns "
            f"(anomaly score: {row['anomaly_score']:.3f})."
        )
    return reasons

def weekly_category_check(df, min_weeks=MIN_WEEKS_FOR_ANOMALY, zscore_threshold=ALERT_ZSCORE):
    debit = df[
        df["is_debit"] &
        ~df["transaction_type"].isin(SKIP_TYPES) &
        ~df["category"].isin(SKIP_CATEGORIES)
    ].copy()
    if debit.empty:
        return pd.DataFrame()
    debit["timestamp"] = pd.to_datetime(debit["timestamp"])
    debit["week"]      = debit["timestamp"].dt.to_period("W")
    weekly = (debit.groupby(["week", "category"])["amount"]
                   .sum()
                   .reset_index()
                   .rename(columns={"amount": "week_total"}))
    weekly["week_dt"] = weekly["week"].dt.start_time
    alerts = []
    for cat in weekly["category"].unique():
        cat_w = weekly[weekly["category"] == cat].sort_values("week_dt").reset_index(drop=True)
        if len(cat_w) < min_weeks:
            continue
        for i in range(min_weeks, len(cat_w)):
            history  = cat_w.iloc[i - min_weeks: i]["week_total"]
            current  = cat_w.iloc[i]["week_total"]
            mean_h   = history.mean()
            std_h    = history.std()
            if std_h < 1:
                continue
            z = (current - mean_h) / std_h
            if z >= zscore_threshold:
                alerts.append({
                    "week":        str(cat_w.iloc[i]["week"]),
                    "category":    cat,
                    "week_total":  round(current, 2),
                    "baseline_avg": round(mean_h, 2),
                    "zscore":      round(z, 2),
                    "severity":    "high" if z >= 3.0 else "medium",
                    "message":     (
                        f"{cat.title()} spend this week "
                        f"(Ksh {current:,.0f}) is {z:.1f} standard deviations "
                        f"above your {min_weeks}-week average "
                        f"(Ksh {mean_h:,.0f})."
                    ),
                })
    return pd.DataFrame(alerts)

def full_scan(df, model, merchant_stats):
    tx_anomalies  = detect_anomalies(df, model, merchant_stats)
    cat_alerts    = weekly_category_check(df)
    n_weeks = (pd.to_datetime(df["timestamp"]).max() -
               pd.to_datetime(df["timestamp"]).min()).days / 7
    if n_weeks < MIN_WEEKS_FOR_ANOMALY:
        return {
            "ready": False,
            "message": f"Need {MIN_WEEKS_FOR_ANOMALY} weeks of history. "
                       f"Currently have {n_weeks:.1f} weeks.",
            "transaction_anomalies": [],
            "category_alerts": [],
        }
    flagged = tx_anomalies[tx_anomalies["is_anomaly"]].copy()
    flagged_out = []
    for _, row in flagged.iterrows():
        flagged_out.append({
            "receipt_no":    row.get("receipt_no", ""),
            "timestamp":     str(row["timestamp"]),
            "merchant_name": row.get("merchant_name", ""),
            "category":      row["category"],
            "amount":        float(row["amount"]),
            "severity":      row["severity"],
            "score":         round(float(row["anomaly_score"]), 4),
            "reasons":       explain_anomaly(row, df, merchant_stats),
        })
    flagged_out.sort(key=lambda x: x["score"])
    cat_out = cat_alerts.to_dict("records") if not cat_alerts.empty else []
    return {
        "ready":                  True,
        "transaction_anomalies":  flagged_out,
        "category_alerts":        cat_out,
        "n_tx_scanned":           len(tx_anomalies),
        "n_tx_flagged":           len(flagged_out),
        "n_category_alerts":      len(cat_out),
    }

def is_recurring_normal(row, merchant_stats):
    mid = str(row.get('merchant_id', ''))
    median = merchant_stats.get('median', {}).get(mid)
    freq   = merchant_stats.get('freq', {}).get(mid, 0)
    if freq < 3 or median is None:
        return False
    # Amount within 60% of the merchant median = expected spend
    return 0.4 <= (float(row['amount']) / median) <= 2.5
