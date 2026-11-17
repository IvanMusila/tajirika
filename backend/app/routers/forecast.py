import sys
import logging
from pathlib import Path

import pandas as pd
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Transaction
from app.schemas import ForecastResponse, ForecastPoint, WhatIfResult
from app.ml.loader import get_forecast_model, save_forecast_model
from app.config import settings
from app.routers.users import get_user_or_404

sys.path.insert(0, str(Path(__file__).parent.parent / "ml"))
import forecast_utils as fu

router = APIRouter()
logger = logging.getLogger(__name__)


def _build_df(user_id: str, db: Session) -> pd.DataFrame:
    rows = db.query(Transaction).filter_by(user_id=user_id).all()
    if not rows:
        return pd.DataFrame()
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
    } for t in rows])
    df["timestamp"] = pd.to_datetime(df["timestamp"])
    return df


@router.get("", response_model=ForecastResponse)
def get_forecast(
    device_token: str,
    what_if_category: str | None = Query(None),
    what_if_reduce_pct: float | None = Query(None, ge=1, le=50),
    db: Session = Depends(get_db),
):
    user = get_user_or_404(device_token, db)
    df = _build_df(user.id, db)

    if df.empty:
        return ForecastResponse(
            runway_days=None,
            daily_avg_ksh=0.0,
            monthly_forecast_ksh=0.0,
            large_monthly_ksh=0.0,
            method="no_data",
            forecast_series=[],
        )

    # Current balance from latest transaction
    balance = float(df.sort_values("timestamp")["balance_after"].iloc[-1])

    # Try pre-fitted model first; fit on the fly if missing
    model = get_forecast_model(user.id, settings.model_dir)
    if model is None:
        logger.info(f"No forecast model for {user.id} — fitting on the fly")
        result = fu.fit_user_forecast(df, balance, user_id=user.id)
        if result["model"]:
            save_forecast_model(user.id, result["model"], settings.model_dir)
        model = result.get("model")

    if model is None:
        # Cold start fallback
        result = fu.cold_start_summary(df, balance)
        return ForecastResponse(
            runway_days=result["runway_days"],
            daily_avg_ksh=result["daily_avg"],
            monthly_forecast_ksh=result["monthly_forecast"],
            large_monthly_ksh=0.0,
            method="cold_start",
            forecast_series=[],
        )

    forecast = fu.make_forecast(model, periods=30)
    _, large_df = fu.split_large_payments(df)
    large_avg = fu.monthly_large_avg(large_df)
    fc30 = forecast.tail(30)

    runway = fu.compute_runway(balance, fc30, large_avg)
    daily_avg = float(fc30["yhat"].clip(lower=0).mean())
    monthly = round(daily_avg * 30 + large_avg, 2)

    series = [
        ForecastPoint(
            date=str(r.ds.date()),
            yhat=round(max(float(r.yhat), 0), 2),
            yhat_lower=round(max(float(r.yhat_lower), 0), 2),
            yhat_upper=round(max(float(r.yhat_upper), 0), 2),
        )
        for r in fc30.itertuples()
    ]

    what_if_result = None
    if what_if_category and what_if_reduce_pct:
        new_rw, saved = fu.what_if(
            balance, fc30, df,
            what_if_category, what_if_reduce_pct, large_avg,
        )
        what_if_result = WhatIfResult(
            category=what_if_category,
            reduce_pct=what_if_reduce_pct,
            new_runway_days=new_rw,
            saved_ksh_per_month=saved,
        )

    return ForecastResponse(
        runway_days=runway,
        daily_avg_ksh=round(daily_avg, 2),
        monthly_forecast_ksh=monthly,
        large_monthly_ksh=round(large_avg, 2),
        method="prophet",
        forecast_series=series,
        what_if=what_if_result,
    )