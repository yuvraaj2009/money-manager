"""Initial schema — captures existing tables.

Revision ID: 0001
Revises: None
Create Date: 2026-03-16
"""
from __future__ import annotations

from alembic import op
import sqlalchemy as sa

revision: str = "0001"
down_revision: str | None = None
branch_labels: str | None = None
depends_on: str | None = None


def upgrade() -> None:
    op.create_table(
        "categories",
        sa.Column("id", sa.String(64), primary_key=True),
        sa.Column("name", sa.String(80), unique=True, index=True, nullable=False),
        sa.Column("color", sa.String(16), nullable=False, server_default="#0049E6"),
        sa.Column("icon", sa.String(48), nullable=False, server_default="wallet"),
        sa.Column("created_at", sa.DateTime, nullable=False),
    )

    op.create_table(
        "accounts",
        sa.Column("id", sa.String(64), primary_key=True),
        sa.Column("name", sa.String(80), index=True, nullable=False),
        sa.Column("type", sa.String(40), nullable=False),
        sa.Column("masked_number", sa.String(32), nullable=False),
        sa.Column("created_at", sa.DateTime, nullable=False),
    )

    op.create_table(
        "transactions",
        sa.Column("id", sa.String(64), primary_key=True),
        sa.Column("amount", sa.Integer, nullable=False),
        sa.Column(
            "category_id",
            sa.String(64),
            sa.ForeignKey("categories.id"),
            index=True,
            nullable=False,
        ),
        sa.Column("description", sa.String(255), nullable=False),
        sa.Column("payment_method", sa.String(48), nullable=False),
        sa.Column(
            "account_id",
            sa.String(64),
            sa.ForeignKey("accounts.id"),
            index=True,
            nullable=False,
        ),
        sa.Column("date", sa.Date, index=True, nullable=False),
        sa.Column("reference_id", sa.String(80), unique=True, nullable=True),
        sa.Column("receipt_url", sa.String(512), nullable=True),
        sa.Column("created_at", sa.DateTime, nullable=False),
    )

    op.create_table(
        "budgets",
        sa.Column("id", sa.String(64), primary_key=True),
        sa.Column(
            "category_id",
            sa.String(64),
            sa.ForeignKey("categories.id"),
            unique=True,
            index=True,
            nullable=False,
        ),
        sa.Column("monthly_limit", sa.Integer, nullable=False),
        sa.Column("created_at", sa.DateTime, nullable=False),
    )

    op.create_table(
        "budget_history",
        sa.Column("id", sa.String(64), primary_key=True),
        sa.Column(
            "category_id",
            sa.String(64),
            sa.ForeignKey("categories.id"),
            index=True,
            nullable=False,
        ),
        sa.Column("spent_amount", sa.Integer, nullable=False, server_default="0"),
        sa.Column("month", sa.Integer, index=True, nullable=False),
        sa.Column("year", sa.Integer, index=True, nullable=False),
        sa.Column("created_at", sa.DateTime, nullable=False),
        sa.UniqueConstraint("category_id", "month", "year", name="uq_budget_month_year"),
    )

    op.create_table(
        "profiles",
        sa.Column("id", sa.String(64), primary_key=True),
        sa.Column("name", sa.String(120), nullable=False, server_default="My Household"),
        sa.Column("monthly_income", sa.Integer, nullable=False, server_default="0"),
        sa.Column("currency", sa.String(8), nullable=False, server_default="INR"),
        sa.Column("household_members", sa.Integer, nullable=False, server_default="1"),
        sa.Column("created_at", sa.DateTime, nullable=False),
        sa.Column("updated_at", sa.DateTime, nullable=False),
    )


def downgrade() -> None:
    op.drop_table("budget_history")
    op.drop_table("budgets")
    op.drop_table("transactions")
    op.drop_table("accounts")
    op.drop_table("categories")
    op.drop_table("profiles")
