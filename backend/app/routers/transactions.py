import sys
import logging
from pathlib import Path
from datetime import datetime, timedelta

import pandas as pd
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy.dialects.postgresql import insert

from app.database import get_db
from app.models import Transaction, Merchant
from app.schemas import (
    SyncRequest, SyncResponse, TransactionOut,
    LabelRequest, TransactionListResponse,
)
from app.ml.loader import get_categorizer
from app.routers.users import get_user_or_404

# Add ml/ folder to path so categorizer_features imports correctly
sys.path.insert(0, str(Path(__file__).parent.parent / "ml"))
import categorizer_features as cf

router = APIRouter()
logger = logging.getLogger(__name__)


def _categorize(tx, user_id: str, db: Session, model) -> tuple[str, float, str]:
    # 1. User merchant memory
    mem = db.query(Merchant).filter_by(
        user_id=user_id, merchant_id=tx.merchant_id
    ).first()
    if mem:
        return mem.category, 1.0, "user_memory"

    # 2. Rules + model (guard against missing model)
    row_df = pd.DataFrame([{
        "merchant_name":    tx.merchant_name,
        "merchant_id":      tx.merchant_id,
        "transaction_type": tx.transaction_type,
        "details":          tx.details,
        "amount":           tx.amount,
        "is_debit":         tx.is_debit,
        "category":         "unknown",
    }])

    try:
        result = cf.categorize(row_df, model)
        return (
            result["category"].iloc[0],
            float(result["confidence"].iloc[0]),
            result["source"].iloc[0],
        )
    except Exception:
        # Model missing or failed — fall back to type-based defaults
        fallback = {
            "buy_goods":        ("convenience", 0.5, "default"),
            "paybill":          ("invisible",   0.5, "default"),
            "send_money":       ("social",      0.5, "default"),
            "fee":              ("invisible",   1.0, "rule"),
            "data_bundle":      ("convenience", 1.0, "rule"),
            "airtime":          ("convenience", 1.0, "rule"),
            "loan_repayment":   ("invisible",   1.0, "rule"),
            "savings_deposit":  ("invisible",   1.0, "rule"),
            "withdrawal":       ("necessity",   1.0, "rule"),
        }
        cat, conf, src = fallback.get(tx.transaction_type, ("review", 0.0, "default"))
        return cat, conf, src

def _update_merchant_memory(user_id: str, tx, category: str, db: Session) -> None:
    """Upsert the user's merchant memory after labeling."""
    mem = db.query(Merchant).filter_by(
        user_id=user_id, merchant_id=tx.merchant_id
    ).first()
    if mem:
        mem.category     = category
        mem.tx_count    += 1
        mem.total_amount += tx.amount
        mem.last_seen    = datetime.utcnow()
    else:
        db.add(Merchant(
            user_id=user_id,
            merchant_id=tx.merchant_id,
            merchant_name=tx.merchant_name,
            category=category,
            tx_count=1,
            total_amount=tx.amount,
        ))


@router.post("/sync", response_model=SyncResponse)
def sync_transactions(req: SyncRequest, db: Session = Depends(get_db)):
    """
    Batch upload parsed transactions from the Flutter app.
    Deduplicates by (user_id, receipt_no).
    Runs the categorization priority chain on each new transaction.
    """
    user = get_user_or_404(req.device_token, db)
    model = get_categorizer()

    existing = {
        r.receipt_no
        for r in db.query(Transaction.receipt_no)
                   .filter_by(user_id=user.id)
                   .all()
    }

    synced, skipped = 0, 0
    saved: list[Transaction] = []

    seen_in_batch: set[str] = set()

    for tx in req.transactions:
        # Deduplicate against DB and within the current batch
        dedup_key = f"{tx.receipt_no}|{tx.transaction_type}"
        if tx.receipt_no in existing or dedup_key in seen_in_batch:
            skipped += 1
            continue
        seen_in_batch.add(dedup_key)

        category, confidence, source = _categorize(tx, user.id, db, model)

        row = Transaction(
            user_id=user.id,
            receipt_no=tx.receipt_no,
            timestamp=tx.timestamp,
            merchant_name=tx.merchant_name,
            merchant_id=tx.merchant_id,
            transaction_type=tx.transaction_type,
            amount=tx.amount,
            balance_after=tx.balance_after,
            is_debit=tx.is_debit,
            details=tx.details,
            category=category,
            label_source=source,
            confidence_score=confidence,
        )
        db.add(row)
        saved.append(row)
        synced += 1

    db.commit()
    for row in saved:
        db.refresh(row)

    logger.info(f"Sync: user={user.id} synced={synced} skipped={skipped}")
    return SyncResponse(
        synced=synced,
        skipped=skipped,
        transactions=[TransactionOut.model_validate(r) for r in saved],
    )


@router.get("", response_model=TransactionListResponse)
def list_transactions(
    device_token: str,
    limit: int = Query(50, le=200),
    offset: int = 0,
    category: str | None = None,
    search: str | None = None,
    date_from: datetime | None = None,
    date_to: datetime | None = None,
    db: Session = Depends(get_db),
):
    user = get_user_or_404(device_token, db)
    q = db.query(Transaction).filter_by(user_id=user.id)

    if category:
        q = q.filter(Transaction.category == category)
    if search:
        q = q.filter(Transaction.merchant_name.ilike(f"%{search}%"))
    if date_from:
        q = q.filter(Transaction.timestamp >= date_from)
    if date_to:
        q = q.filter(Transaction.timestamp <= date_to)

    total = q.count()
    rows = q.order_by(Transaction.timestamp.desc()).offset(offset).limit(limit).all()
    return TransactionListResponse(
        transactions=[TransactionOut.model_validate(r) for r in rows],
        total=total,
    )


@router.patch("/{transaction_id}/label", response_model=TransactionOut)
def label_transaction(
    transaction_id: str,
    req: LabelRequest,
    db: Session = Depends(get_db),
):
    """
    User corrects a category. Updates the transaction and merchant memory
    so the same merchant is labeled correctly from now on.
    """
    user = get_user_or_404(req.device_token, db)
    tx = db.query(Transaction).filter_by(id=transaction_id, user_id=user.id).first()
    if not tx:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="Transaction not found")

    tx.category     = req.category
    tx.label_source = "user_label"
    tx.confidence_score = 1.0

    _update_merchant_memory(user.id, tx, req.category, db)
    db.commit()
    db.refresh(tx)
    return TransactionOut.model_validate(tx)