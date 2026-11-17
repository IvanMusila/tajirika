"""
Loads and caches all ML models. Called once at FastAPI startup.
Per-user forecast and anomaly models are loaded lazily on first request.
"""
import sys
import joblib
import logging
from pathlib import Path

logger = logging.getLogger(__name__)

# Global model store
_store: dict = {
    "categorizer": None,
    "forecasts": {},    # user_id -> Prophet model
    "anomalies": {},    # user_id -> {"model": ..., "merchant_stats": ...}
}


def init_models(model_dir: str) -> None:
    """Load the shared categorizer at startup. Call from FastAPI lifespan."""
    base = Path(model_dir)

    cat_path = base / "categorizer" / "categorizer.pkl"
    if cat_path.exists():
        _store["categorizer"] = joblib.load(cat_path)
        logger.info(f"Categorizer loaded from {cat_path}")
    else:
        logger.warning(f"Categorizer not found at {cat_path} — categorization will use rules only")

    # Add utils to path so imports work
    ml_dir = Path(__file__).parent
    if str(ml_dir) not in sys.path:
        sys.path.insert(0, str(ml_dir))


def get_categorizer():
    return _store["categorizer"]


def get_forecast_model(user_id: str, model_dir: str):
    """Load a user's Prophet model lazily. Returns None if not found."""
    if user_id not in _store["forecasts"]:
        path = Path(model_dir) / "forecast" / f"forecast_{user_id}.pkl"
        if path.exists():
            _store["forecasts"][user_id] = joblib.load(path)
            logger.info(f"Forecast model loaded for user {user_id}")
        else:
            _store["forecasts"][user_id] = None
    return _store["forecasts"][user_id]


def get_anomaly_model(user_id: str, model_dir: str) -> dict | None:
    """Load a user's anomaly model lazily. Returns None if not found."""
    if user_id not in _store["anomalies"]:
        path = Path(model_dir) / "anomaly" / f"anomaly_{user_id}.pkl"
        if path.exists():
            _store["anomalies"][user_id] = joblib.load(path)
            logger.info(f"Anomaly model loaded for user {user_id}")
        else:
            _store["anomalies"][user_id] = None
    return _store["anomalies"][user_id]


def save_forecast_model(user_id: str, model, model_dir: str) -> None:
    """Save and cache a newly fitted Prophet model."""
    path = Path(model_dir) / "forecast" / f"forecast_{user_id}.pkl"
    path.parent.mkdir(parents=True, exist_ok=True)
    joblib.dump(model, path)
    _store["forecasts"][user_id] = model


def save_anomaly_model(user_id: str, payload: dict, model_dir: str) -> None:
    """Save and cache a newly fitted anomaly model."""
    path = Path(model_dir) / "anomaly" / f"anomaly_{user_id}.pkl"
    path.parent.mkdir(parents=True, exist_ok=True)
    joblib.dump(payload, path)
    _store["anomalies"][user_id] = payload