from datetime import datetime
from typing import Optional
from pydantic import BaseModel


# ── Users ─────────────────────────────────────────────────────────────────────

class RegisterRequest(BaseModel):
    device_token: str


class RegisterResponse(BaseModel):
    user_id: str
    device_token: str
    created_at: datetime


# ── Transactions ──────────────────────────────────────────────────────────────

class TransactionIn(BaseModel):
    receipt_no: str
    timestamp: datetime
    merchant_name: str = ""
    merchant_id: str = ""
    transaction_type: str = "other"
    amount: float
    balance_after: float = 0.0
    is_debit: bool = True
    details: str = ""


class TransactionOut(BaseModel):
    id: str
    receipt_no: str
    timestamp: datetime
    merchant_name: str
    merchant_id: str
    transaction_type: str
    amount: float
    balance_after: float
    category: str
    label_source: str
    confidence_score: float
    is_debit: bool

    class Config:
        from_attributes = True


class SyncRequest(BaseModel):
    device_token: str
    transactions: list[TransactionIn]


class SyncResponse(BaseModel):
    synced: int
    skipped: int
    transactions: list[TransactionOut]


class LabelRequest(BaseModel):
    device_token: str
    category: str


class TransactionListResponse(BaseModel):
    transactions: list[TransactionOut]
    total: int


# ── Dashboard ─────────────────────────────────────────────────────────────────

class CategoryTotal(BaseModel):
    category: str
    total: float
    count: int
    percentage: float


class AnomalySummary(BaseModel):
    id: str
    merchant_name: str
    amount: float
    category: str
    severity: str
    description: str
    detected_at: datetime


class DashboardResponse(BaseModel):
    runway_days: Optional[int]
    current_balance: float
    daily_avg: float
    monthly_forecast: float
    method: str
    category_totals: list[CategoryTotal]
    recent_anomalies: list[AnomalySummary]
    total_transactions: int
    total_spend_30d: float
    last_synced: Optional[datetime]


# ── Forecast ──────────────────────────────────────────────────────────────────

class ForecastPoint(BaseModel):
    date: str
    yhat: float
    yhat_lower: float
    yhat_upper: float


class WhatIfResult(BaseModel):
    category: str
    reduce_pct: float
    new_runway_days: int
    saved_ksh_per_month: float


class ForecastResponse(BaseModel):
    runway_days: Optional[int]
    daily_avg_ksh: float
    monthly_forecast_ksh: float
    large_monthly_ksh: float
    method: str
    forecast_series: list[ForecastPoint]
    what_if: Optional[WhatIfResult] = None


# ── Anomalies ─────────────────────────────────────────────────────────────────

class AnomalyOut(BaseModel):
    id: str
    alert_type: str
    receipt_no: str
    merchant_name: str
    category: str
    amount: float
    severity: str
    score: float
    description: str
    acknowledged: bool
    detected_at: datetime

    class Config:
        from_attributes = True


class ScanResponse(BaseModel):
    n_tx_flagged: int
    n_category_alerts: int
    message: str