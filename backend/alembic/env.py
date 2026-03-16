from __future__ import annotations

import sys
from pathlib import Path

from alembic import context
from sqlalchemy import engine_from_config, pool

# Ensure the backend package is importable
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from app.config import get_settings
from app.database.database import Base
from app.database import models  # noqa: F401 – register all models with Base

target_metadata = Base.metadata

settings = get_settings()


def run_migrations_offline() -> None:
    """Run migrations in 'offline' mode — emit SQL to stdout."""
    context.configure(
        url=settings.database_url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )
    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    """Run migrations against a live database connection."""
    cfg = context.config
    cfg.set_main_option("sqlalchemy.url", settings.database_url)

    connectable = engine_from_config(
        cfg.get_section(cfg.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:
        context.configure(connection=connection, target_metadata=target_metadata)
        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
