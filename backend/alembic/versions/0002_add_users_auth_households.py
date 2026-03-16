"""Add users, auth, and household tables; add user_id to all existing models.

Revision ID: 0002
Revises: 0001
Create Date: 2026-03-16
"""
from __future__ import annotations

from alembic import op
import sqlalchemy as sa

revision: str = "0002"
down_revision: str | None = "0001"
branch_labels: str | None = None
depends_on: str | None = None


def upgrade() -> None:
    # ── Users table ──────────────────────────────────────────────────
    op.create_table(
        "users",
        sa.Column("id", sa.String(64), primary_key=True),
        sa.Column("google_id", sa.String(128), unique=True, index=True, nullable=False),
        sa.Column("email", sa.String(255), unique=True, index=True, nullable=False),
        sa.Column("name", sa.String(255), nullable=False),
        sa.Column("picture_url", sa.String(512), nullable=True),
        sa.Column("created_at", sa.DateTime, nullable=False),
        sa.Column("updated_at", sa.DateTime, nullable=False),
    )

    # ── Households table ─────────────────────────────────────────────
    op.create_table(
        "households",
        sa.Column("id", sa.String(64), primary_key=True),
        sa.Column("name", sa.String(120), nullable=False),
        sa.Column("invite_code", sa.String(16), unique=True, index=True, nullable=False),
        sa.Column("created_by", sa.String(64), sa.ForeignKey("users.id"), nullable=False),
        sa.Column("created_at", sa.DateTime, nullable=False),
    )

    op.create_table(
        "household_members",
        sa.Column("id", sa.String(64), primary_key=True),
        sa.Column("household_id", sa.String(64), sa.ForeignKey("households.id"), index=True, nullable=False),
        sa.Column("user_id", sa.String(64), sa.ForeignKey("users.id"), index=True, nullable=False),
        sa.Column("role", sa.String(20), nullable=False, server_default="member"),
        sa.Column("joined_at", sa.DateTime, nullable=False),
        sa.UniqueConstraint("household_id", "user_id", name="uq_household_user"),
    )

    # ── Create a system user for backfilling existing data ───────────
    op.execute(
        "INSERT INTO users (id, google_id, email, name, created_at, updated_at) "
        "VALUES ('USR-SYSTEM0000', 'system', 'system@localhost', 'System User', "
        "CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)"
    )

    # ── Add user_id to categories (nullable first, then backfill) ────
    # Drop the old unique constraint on name so it can be per-user
    with op.batch_alter_table("categories") as batch_op:
        batch_op.drop_constraint("uq_user_category_name", type_="unique")  # may not exist, handled below
    op.add_column("categories", sa.Column("user_id", sa.String(64), nullable=True))
    op.execute("UPDATE categories SET user_id = 'USR-SYSTEM0000'")
    with op.batch_alter_table("categories") as batch_op:
        batch_op.alter_column("user_id", nullable=False)
        batch_op.create_index("ix_categories_user_id", ["user_id"])
        batch_op.create_foreign_key("fk_categories_user", "users", ["user_id"], ["id"])
        batch_op.create_unique_constraint("uq_user_category_name", ["user_id", "name"])

    # ── Add user_id to accounts ──────────────────────────────────────
    op.add_column("accounts", sa.Column("user_id", sa.String(64), nullable=True))
    op.execute("UPDATE accounts SET user_id = 'USR-SYSTEM0000'")
    with op.batch_alter_table("accounts") as batch_op:
        batch_op.alter_column("user_id", nullable=False)
        batch_op.create_index("ix_accounts_user_id", ["user_id"])
        batch_op.create_foreign_key("fk_accounts_user", "users", ["user_id"], ["id"])

    # ── Add user_id + household_id to transactions ───────────────────
    op.add_column("transactions", sa.Column("user_id", sa.String(64), nullable=True))
    op.add_column("transactions", sa.Column("household_id", sa.String(64), nullable=True))
    op.execute("UPDATE transactions SET user_id = 'USR-SYSTEM0000'")
    with op.batch_alter_table("transactions") as batch_op:
        batch_op.alter_column("user_id", nullable=False)
        batch_op.create_index("ix_transactions_user_id", ["user_id"])
        batch_op.create_index("ix_transactions_household_id", ["household_id"])
        batch_op.create_foreign_key("fk_transactions_user", "users", ["user_id"], ["id"])
        batch_op.create_foreign_key("fk_transactions_household", "households", ["household_id"], ["id"])

    # ── Add user_id + household_id to budgets ────────────────────────
    # Drop old unique on category_id (now per-user)
    op.add_column("budgets", sa.Column("user_id", sa.String(64), nullable=True))
    op.add_column("budgets", sa.Column("household_id", sa.String(64), nullable=True))
    op.execute("UPDATE budgets SET user_id = 'USR-SYSTEM0000'")
    with op.batch_alter_table("budgets") as batch_op:
        batch_op.alter_column("user_id", nullable=False)
        batch_op.create_index("ix_budgets_user_id", ["user_id"])
        batch_op.create_index("ix_budgets_household_id", ["household_id"])
        batch_op.create_foreign_key("fk_budgets_user", "users", ["user_id"], ["id"])
        batch_op.create_foreign_key("fk_budgets_household", "households", ["household_id"], ["id"])
        batch_op.create_unique_constraint("uq_user_budget_category", ["user_id", "category_id"])

    # ── Add user_id to budget_history ────────────────────────────────
    op.add_column("budget_history", sa.Column("user_id", sa.String(64), nullable=True))
    op.execute("UPDATE budget_history SET user_id = 'USR-SYSTEM0000'")
    with op.batch_alter_table("budget_history") as batch_op:
        batch_op.alter_column("user_id", nullable=False)
        batch_op.create_index("ix_budget_history_user_id", ["user_id"])
        batch_op.create_foreign_key("fk_budget_history_user", "users", ["user_id"], ["id"])
        batch_op.drop_constraint("uq_budget_month_year", type_="unique")
        batch_op.create_unique_constraint(
            "uq_user_budget_month_year",
            ["user_id", "category_id", "month", "year"],
        )

    # ── Add user_id to profiles ──────────────────────────────────────
    op.add_column("profiles", sa.Column("user_id", sa.String(64), nullable=True))
    op.execute("UPDATE profiles SET user_id = 'USR-SYSTEM0000'")
    with op.batch_alter_table("profiles") as batch_op:
        batch_op.alter_column("user_id", nullable=False)
        batch_op.create_index("ix_profiles_user_id", ["user_id"])
        batch_op.create_foreign_key("fk_profiles_user", "users", ["user_id"], ["id"])


def downgrade() -> None:
    # Remove user_id from all tables
    for table in ("profiles", "budget_history", "budgets", "transactions", "accounts", "categories"):
        with op.batch_alter_table(table) as batch_op:
            batch_op.drop_column("user_id")

    # Remove household_id from transactions and budgets
    with op.batch_alter_table("transactions") as batch_op:
        batch_op.drop_column("household_id")
    with op.batch_alter_table("budgets") as batch_op:
        batch_op.drop_column("household_id")

    op.drop_table("household_members")
    op.drop_table("households")

    # Remove system user
    op.execute("DELETE FROM users WHERE id = 'USR-SYSTEM0000'")
    op.drop_table("users")
