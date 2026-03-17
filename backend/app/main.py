from __future__ import annotations

import logging
import sys
from contextlib import asynccontextmanager
from pathlib import Path

# Configure root logger so all app.* loggers output to stdout (visible in Render logs)
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s [%(name)s] %(message)s",
    stream=sys.stdout,
)

from alembic import command
from alembic.config import Config as AlembicConfig
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.config import get_settings
from app.database import models  # noqa: F401
from app.database.database import SessionLocal
from app.routes import admin, analytics, auth, budgets, debug, households, profile, transactions, version
from utils.db_reset import seed_default_data

logger = logging.getLogger(__name__)
settings = get_settings()


def _run_migrations() -> None:
    """Apply all pending Alembic migrations."""
    backend_dir = Path(__file__).resolve().parent.parent
    alembic_cfg = AlembicConfig(str(backend_dir / "alembic.ini"))
    alembic_cfg.set_main_option("script_location", str(backend_dir / "alembic"))
    alembic_cfg.set_main_option("sqlalchemy.url", settings.database_url)
    command.upgrade(alembic_cfg, "head")
    logger.info("Database migrations applied successfully.")


def _check_config() -> None:
    """Log warnings for missing or insecure configuration."""
    if settings.jwt_secret == "change-me-in-production":
        logger.warning("⚠️  JWT_SECRET is using the default value! Set JWT_SECRET env var in production.")
    if not settings.google_client_id:
        logger.warning("⚠️  GOOGLE_CLIENT_ID is not set! Google Sign-In will fail.")
    logger.info("Config: environment=%s, db=%s..., google_client_id_set=%s",
                settings.environment, settings.database_url[:30], bool(settings.google_client_id))


@asynccontextmanager
async def lifespan(_: FastAPI):
    _check_config()
    _run_migrations()
    with SessionLocal() as session:
        seed_default_data(
            session,
            include_budgets=True,
            include_profile=True,
            include_demo_transactions=settings.seed_demo_data,
        )
    logger.info("Startup complete — app ready to serve requests.")
    yield


app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    description="Personal finance tracking API for the Money Manager mobile application.",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(transactions.router)
app.include_router(analytics.router)
app.include_router(budgets.router)
app.include_router(profile.router)
app.include_router(households.router)
app.include_router(admin.router)
app.include_router(version.router)
app.include_router(debug.router)


@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Catch unhandled exceptions and return a JSON error with details for debugging."""
    logger.exception("Unhandled error on %s %s", request.method, request.url.path)
    error_type = type(exc).__name__
    error_msg = str(exc) or "No details available"
    return JSONResponse(
        status_code=500,
        content={
            "detail": f"Internal server error: {error_type}: {error_msg}",
            "path": request.url.path,
            "method": request.method,
        },
    )


@app.get("/", tags=["System"])
def root():
    return {
        "name": settings.app_name,
        "version": settings.app_version,
        "docs": "/docs",
        "status": "ok",
    }


@app.get("/health", tags=["System"])
def health_check():
    return {"status": "ok"}


