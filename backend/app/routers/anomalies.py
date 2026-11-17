import sys
import logging
from pathlib import Path
from datetime import datetime

import pandas as pd
from fastapi import APIRouter, Depends, Query, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Transaction, Anomaly
from app.schemas import AnomalyOut, ScanResponse
from app.ml.loader import get_anomaly_model, save_anomaly_model
from app.config import settings
from app.routers.users import get_user_or_404

sys.path.insert(0, str(Path(__file__).parent.parent / "ml"))
import anomaly_utils as au

router = APIRouter()
logger = logging.getLogger(__name__)


class AckRequest(BaseModel):
    device_token: str


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
        "receipt_no":       t.receipt_no,
        "details":          t.details,
    } for t in rows])
    df["timestamp"] = pd.to_datetime(df["timestamp"])
    return df


@router.post("/scan", response_model=ScanResponse)
def scan_anomalies(
    device_token: str,
    db: Session = Depends(get_db),
):
    """
    Run the full anomaly scan for this user.
    Saves new anomalies to the database.
    """
    user = get_user_or_404(device_token, db)
    df = _build_df(user.id, db)

    if df.empty:
        return ScanResponse(n_tx_flagged=0, n_category_alerts=0,
                            message="No transactions to scan.")

    # Load or fit anomaly model
    payload = get_anomaly_model(user.id, settings.model_dir)
    if payload is None:
        logger.info(f"No anomaly model for {user.id} — fitting on the fly")
        model, merchant_stats = au.fit_user_anomaly(df)
        payload = {"model": model, "merchant_stats": merchant_stats}
        save_anomaly_model(user.id, payload, settings.model_dir)

    result = au.full_scan(df, payload["model"], payload["merchant_stats"])

    if not result["ready"]:
        return ScanResponse(n_tx_flagged=0, n_category_alerts=0,
                            message=result["message"])

    # Existing receipt numbers already in the anomalies table
    existing_receipts = {
        a.receipt_no
        for a in db.query(Anomaly.receipt_no).filter_by(user_id=user.id).all()
    }

    new_count = 0
    for a in result["transaction_anomalies"]:
        if a["receipt_no"] in existing_receipts:
            continue
        db.add(Anomaly(
            user_id=user.id,
            alert_type="transaction",
            receipt_no=a["receipt_no"],
            merchant_name=a["merchant_name"],
            category=a["category"],
            amount=a["amount"],
            severity=a["severity"],
            score=a["score"],
            description=" | ".join(a["reasons"]),
        ))
        new_count += 1

    for a in result["category_alerts"]:
        # Use week string as a pseudo receipt_no to deduplicate
        key = f"weekly_{a['category']}_{a['week']}"
        if key in existing_receipts:
            continue
        db.add(Anomaly(
            user_id=user.id,
            alert_type="weekly_category",
            receipt_no=key,
            merchant_name="",
            category=a["category"],
            amount=a["week_total"],
            severity=a["severity"],
            score=float(a["zscore"]),
            description=a["message"],
        ))
        new_count += 1

    db.commit()
    logger.info(f"Scan: user={user.id} new_anomalies={new_count}")

    return ScanResponse(
        n_tx_flagged=result["n_tx_flagged"],
        n_category_alerts=result["n_category_alerts"],
        message=f"Scan complete. {new_count} new alerts saved.",
    )


@router.get("", response_model=list[AnomalyOut])
def list_anomalies(
    device_token: str,
    acknowledged: bool | None = None,
    limit: int = Query(50, le=200),
    db: Session = Depends(get_db),
):
    user = get_user_or_404(device_token, db)
    q = db.query(Anomaly).filter_by(user_id=user.id)
    if acknowledged is not None:
        q = q.filter(Anomaly.acknowledged == acknowledged)
    rows = q.order_by(Anomaly.detected_at.desc()).limit(limit).all()
    return [AnomalyOut.model_validate(r) for r in rows]


@router.patch("/{anomaly_id}", response_model=AnomalyOut)
def acknowledge_anomaly(
    anomaly_id: str,
    req: AckRequest,
    db: Session = Depends(get_db),
):
    user = get_user_or_404(req.device_token, db)
    anomaly = db.query(Anomaly).filter_by(id=anomaly_id, user_id=user.id).first()
    if not anomaly:
        raise HTTPException(status_code=404, detail="Anomaly not found")
    anomaly.acknowledged = True
    db.commit()
    db.refresh(anomaly)
    return AnomalyOut.model_validate(anomaly)