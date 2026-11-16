from contextlib import asynccontextmanager
import logging

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.database import engine, Base
from app.ml.loader import init_models
from app.routers import transactions, dashboard, forecast, anomalies, users

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Create all tables if they don't exist
    Base.metadata.create_all(bind=engine)
    logger.info("Database tables ready")

    # Load ML models
    init_models(settings.model_dir)
    logger.info("ML models initialised")

    yield

    logger.info("Shutting down")


app = FastAPI(
    title="Tajirika API",
    description="Spend smarter. Grow wealthier.",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(users.router, prefix="/users", tags=["users"])
app.include_router(transactions.router, prefix="/transactions", tags=["transactions"])
app.include_router(dashboard.router, prefix="/dashboard", tags=["dashboard"])
app.include_router(forecast.router, prefix="/forecast", tags=["forecast"])
app.include_router(anomalies.router, prefix="/anomalies", tags=["anomalies"])


@app.get("/health", tags=["health"])
def health_check():
    return {"status": "ok", "version": "1.0.0"}