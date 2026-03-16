from __future__ import annotations

import os
from functools import lru_cache
from pathlib import Path

from dotenv import load_dotenv
from pydantic import BaseModel, Field


def _project_root() -> Path:
    return Path(__file__).resolve().parent.parent


load_dotenv(_project_root() / ".env")


def _parse_bool(value: str | None, default: bool = False) -> bool:
    if value is None:
        return default
    return value.strip().lower() in {"1", "true", "yes", "on"}


def _parse_cors_origins(value: str | None) -> list[str]:
    if not value:
        return ["*"]
    origins = [item.strip() for item in value.split(",") if item.strip()]
    return origins or ["*"]


def _default_database_url() -> str:
    database_url = os.getenv("DATABASE_URL")
    if database_url:
        if database_url.startswith("postgres://"):
            return database_url.replace("postgres://", "postgresql+psycopg2://", 1)
        if database_url.startswith("postgresql://"):
            return database_url.replace(
                "postgresql://",
                "postgresql+psycopg2://",
                1,
            )
        return database_url

    sqlite_override = os.getenv("MONEY_MANAGER_DB_PATH")
    if sqlite_override:
        return f"sqlite:///{Path(sqlite_override).resolve().as_posix()}"

    db_path = _project_root() / "database.db"
    return f"sqlite:///{db_path.resolve().as_posix()}"


class Settings(BaseModel):
    app_name: str = "Money Manager System API"
    environment: str = Field(
        default_factory=lambda: os.getenv("ENVIRONMENT", "development")
    )
    api_version: str = Field(default_factory=lambda: os.getenv("API_VERSION", "1.0.0"))
    api_prefix: str = ""
    project_root: Path = Field(
        default_factory=_project_root
    )
    database_path: Path = Field(
        default_factory=lambda: _project_root() / "database.db"
    )
    database_url: str = Field(
        default_factory=_default_database_url
    )
    cors_origins: list[str] = Field(
        default_factory=lambda: _parse_cors_origins(os.getenv("CORS_ORIGINS"))
    )
    seed_demo_data: bool = Field(
        default_factory=lambda: _parse_bool(os.getenv("SEED_DEMO_DATA"), False)
    )

    # Auth
    google_client_id: str = Field(
        default_factory=lambda: os.getenv("GOOGLE_CLIENT_ID", "")
    )
    jwt_secret: str = Field(
        default_factory=lambda: os.getenv("JWT_SECRET", "change-me-in-production")
    )

    # App update
    min_app_version: str = Field(
        default_factory=lambda: os.getenv("MIN_APP_VERSION", "1.0.0")
    )
    latest_app_version: str = Field(
        default_factory=lambda: os.getenv("LATEST_APP_VERSION", "1.0.1")
    )
    update_url: str = Field(
        default_factory=lambda: os.getenv("UPDATE_URL", "")
    )
    apk_filename: str = Field(
        default_factory=lambda: os.getenv("APK_FILENAME", "money-manager.apk")
    )
    update_message: str = Field(
        default_factory=lambda: os.getenv("UPDATE_MESSAGE", "")
    )

    @property
    def app_version(self) -> str:
        return self.api_version


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings()
