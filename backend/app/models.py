import uuid
from datetime import datetime
from sqlalchemy import (
    String, Float, Boolean, DateTime, Text,
    ForeignKey, UniqueConstraint, Integer
)
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database import Base


def new_uuid() -> str:
    return str(uuid.uuid4())


class User(Base):
    __tablename__ = "users"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=new_uuid)
    device_token: Mapped[str] = mapped_column(String, unique=True, index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    transactions: Mapped[list["Transaction"]] = relationship(back_populates="user")
    merchants: Mapped[list["Merchant"]] = relationship(back_populates="user")
    forecasts: Mapped[list["Forecast"]] = relationship(back_populates="user")
    anomalies: Mapped[list["Anomaly"]] = relationship(back_populates="user")


class Transaction(Base):
    __tablename__ = "transactions"
    __table_args__ = (
        UniqueConstraint("user_id", "receipt_no", "transaction_type", name="uq_user_receipt"),
    )

    id: Mapped[str] = mapped_column(String, primary_key=True, default=new_uuid)
    user_id: Mapped[str] = mapped_column(String, ForeignKey("users.id"), index=True)
    receipt_no: Mapped[str] = mapped_column(String, index=True)
    timestamp: Mapped[datetime] = mapped_column(DateTime, index=True)
    merchant_name: Mapped[str] = mapped_column(String, default="")
    merchant_id: Mapped[str] = mapped_column(String, default="", index=True)
    transaction_type: Mapped[str] = mapped_column(String, default="other")
    amount: Mapped[float] = mapped_column(Float, default=0.0)
    balance_after: Mapped[float] = mapped_column(Float, default=0.0)
    category: Mapped[str] = mapped_column(String, default="review")
    label_source: Mapped[str] = mapped_column(String, default="model")
    confidence_score: Mapped[float] = mapped_column(Float, default=0.0)
    is_debit: Mapped[bool] = mapped_column(Boolean, default=True)
    details: Mapped[str] = mapped_column(Text, default="")
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    user: Mapped["User"] = relationship(back_populates="transactions")


class Merchant(Base):
    """Per-user merchant memory — the user's own labels take highest priority."""
    __tablename__ = "merchants"
    __table_args__ = (
        UniqueConstraint("user_id", "merchant_id", name="uq_user_merchant"),
    )

    id: Mapped[str] = mapped_column(String, primary_key=True, default=new_uuid)
    user_id: Mapped[str] = mapped_column(String, ForeignKey("users.id"), index=True)
    merchant_id: Mapped[str] = mapped_column(String)
    merchant_name: Mapped[str] = mapped_column(String, default="")
    category: Mapped[str] = mapped_column(String)
    tx_count: Mapped[int] = mapped_column(Integer, default=1)
    total_amount: Mapped[float] = mapped_column(Float, default=0.0)
    last_seen: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    user: Mapped["User"] = relationship(back_populates="merchants")


class Forecast(Base):
    __tablename__ = "forecasts"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=new_uuid)
    user_id: Mapped[str] = mapped_column(String, ForeignKey("users.id"), index=True)
    generated_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    runway_days: Mapped[int] = mapped_column(Integer, default=0)
    daily_avg: Mapped[float] = mapped_column(Float, default=0.0)
    monthly_forecast: Mapped[float] = mapped_column(Float, default=0.0)
    large_monthly_avg: Mapped[float] = mapped_column(Float, default=0.0)
    method: Mapped[str] = mapped_column(String, default="cold_start")
    forecast_json: Mapped[str] = mapped_column(Text, default="[]")

    user: Mapped["User"] = relationship(back_populates="forecasts")


class Anomaly(Base):
    __tablename__ = "anomalies"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=new_uuid)
    user_id: Mapped[str] = mapped_column(String, ForeignKey("users.id"), index=True)
    detected_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    alert_type: Mapped[str] = mapped_column(String, default="transaction")
    receipt_no: Mapped[str] = mapped_column(String, default="")
    merchant_name: Mapped[str] = mapped_column(String, default="")
    category: Mapped[str] = mapped_column(String, default="")
    amount: Mapped[float] = mapped_column(Float, default=0.0)
    severity: Mapped[str] = mapped_column(String, default="low")
    score: Mapped[float] = mapped_column(Float, default=0.0)
    description: Mapped[str] = mapped_column(Text, default="")
    acknowledged: Mapped[bool] = mapped_column(Boolean, default=False)

    user: Mapped["User"] = relationship(back_populates="anomalies")