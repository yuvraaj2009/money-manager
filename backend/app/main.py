from __future__ import annotations

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import get_settings
from app.database import models  # noqa: F401
from app.database.database import Base, SessionLocal, engine
from app.routes import admin, analytics, budgets, profile, transactions
from utils.db_reset import seed_default_data

settings = get_settings()


@asynccontextmanager
async def lifespan(_: FastAPI):
    Base.metadata.create_all(bind=engine)
    with SessionLocal() as session:
        seed_default_data(
            session,
            include_budgets=True,
            include_profile=True,
            include_demo_transactions=settings.seed_demo_data,
        )
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

app.include_router(transactions.router)
app.include_router(analytics.router)
app.include_router(budgets.router)
app.include_router(profile.router)
app.include_router(admin.router)


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
