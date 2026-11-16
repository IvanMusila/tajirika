import sys
import logging
from pathlib import Path
from datetime import datetime, timedelta

import pandas as pd
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Transaction, Anomaly
from app.schemas import DashboardResponse, CategoryTotal, AnomalySummary
from app.ml.loader import get_forecast_model
from app.config import settings
from app.routers.users import get_user_or_404

sys.path.insert(0, str(Path(__file__).parent.parent / "ml"))
import forecast_utils as fu

router = APIRouter()
logger = logging.getLogger(__name__)


@router.get("", response_model=DashboardResponse)
def get_dashboard(
    device_token: str,
    db: Session = Depends(get_db),
):
    user = get_user_or_404(device_token, db)

    # ── All transactions ──────────────────────────────────────────────────
    all_tx = db.query(Transaction).filter_by(user_id=user.id).all()
    if not all_tx:
        return DashboardResponse(
            runway_days=None,
            current_balance=0.0,
            daily_avg=0.0,
            monthly_forecast=0.0,
            method="no_data",
            category_totals=[],
            recent_anomalies=[],
            total_transactions=0,
            total_spend_30d=0.0,
            last_synced=None,
        )

    df = pd.DataFrame([{
        "timestamp":        t.timestamp,
        "amount":           t.amount,
        "balance_after":    t.balance_after,
        "category":         t.category,
        "transaction_type": t.transaction_type,
        "is_debit":         t.is_debit,
        "merchant_name":    t.merchant_name,
        "merchant_id":      t.merchant_id,
        "details":          t.details,
    } for t in all_tx])
    df["timestamp"] = pd.to_datetime(df["timestamp"])

    # Current balance = most recent transaction's balance_after
    current_balance = float(df.sort_values("timestamp")["balance_after"].iloc[-1])

    # ── Forecast / runway ─────────────────────────────────────────────────
    model = get_forecast_model(user.id, settings.model_dir)
    if model:
        forecast = fu.make_forecast(model, periods=30)
        _, large_df = fu.split_large_payments(df)
        large_avg = fu.monthly_large_avg(large_df)
        runway = fu.compute_runway(current_balance, forecast.tail(30), large_avg)
        daily_avg = float(forecast.tail(30)["yhat"].clip(lower=0).mean())
        monthly   = round(daily_avg * 30 + large_avg, 2)
        method    = "prophet"
    else:
        result    = fu.cold_start_summary(df, current_balance)
        runway    = result["runway_days"]
        daily_avg = result["daily_avg"]
        monthly   = result["monthly_forecast"]
        method    = "cold_start"

    # ── 30-day category totals ─────────────────────────────────────────────
    cutoff_30 = df["timestamp"].max() - timedelta(days=30)
    recent = df[df["timestamp"] >= cutoff_30 & df["is_debit"]]
    total_30d = float(recent["amount"].sum())

    cat_totals: list[CategoryTotal] = []
    for cat, grp in recent.groupby("category"):
        cat_total = float(grp["amount"].sum())
        cat_totals.append(CategoryTotal(
            category=str(cat),
            total=round(cat_total, 2),
            count=len(grp),
            percentage=round(cat_total / total_30d * 100, 1) if total_30d > 0 else 0.0,
        ))
    cat_totals.sort(key=lambda x: x.total, reverse=True)

    # ── Recent anomalies ──────────────────────────────────────────────────
    recent_anomalies_db = (
        db.query(Anomaly)
          .filter_by(user_id=user.id, acknowledged=False)
          .order_by(Anomaly.detected_at.desc())
          .limit(5)
          .all()
    )
    recent_anomalies = [
        AnomalySummary(
            id=a.id,
            merchant_name=a.merchant_name,
            amount=a.amount,
            category=a.category,
            severity=a.severity,
            description=a.description,
            detected_at=a.detected_at,
        )
        for a in recent_anomalies_db
    ]

    last_synced = df["timestamp"].max().to_pydatetime() if not df.empty else None

    return DashboardResponse(
        runway_days=runway,
        current_balance=round(current_balance, 2),
        daily_avg=round(daily_avg, 2),
        monthly_forecast=round(monthly, 2),
        method=method,
        category_totals=cat_totals,
        recent_anomalies=recent_anomalies,
        total_transactions=len(all_tx),
        total_spend_30d=round(total_30d, 2),
        last_synced=last_synced,
    )