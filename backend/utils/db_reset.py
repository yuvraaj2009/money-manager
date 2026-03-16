from __future__ import annotations

from sqlalchemy import delete
from sqlalchemy.orm import Session

from app.database import models  # noqa: F401
from app.database.database import SessionLocal
from app.database.models import Budget, BudgetHistory, Category, Account, Transaction
from app.database.seed_data import seed_user_defaults


def seed_default_data(
    session: Session,
    *,
    include_budgets: bool = True,
    include_profile: bool = True,
    include_demo_transactions: bool = False,
) -> None:
    """Legacy startup seed — no-op with auth enabled."""
    pass


def reset_household_data(session: Session, user_id: str) -> dict[str, int | bool | str]:
    """Reset a user's data: delete transactions, budgets, categories, accounts; re-seed defaults."""
    deleted_transactions = session.execute(
        delete(Transaction).where(Transaction.user_id == user_id)
    ).rowcount or 0
    deleted_budget_history = session.execute(
        delete(BudgetHistory).where(BudgetHistory.user_id == user_id)
    ).rowcount or 0
    deleted_budgets = session.execute(
        delete(Budget).where(Budget.user_id == user_id)
    ).rowcount or 0
    session.execute(delete(Category).where(Category.user_id == user_id))
    session.execute(delete(Account).where(Account.user_id == user_id))
    session.commit()

    seed_user_defaults(session, user_id)

    recreated_categories = session.query(Category).filter_by(user_id=user_id).count()
    recreated_accounts = session.query(Account).filter_by(user_id=user_id).count()

    return {
        "status": "reset",
        "deleted_transactions": deleted_transactions,
        "deleted_budgets": deleted_budgets,
        "deleted_budget_history": deleted_budget_history,
        "recreated_categories": recreated_categories,
        "recreated_accounts": recreated_accounts,
        "preserved_profile": True,
    }
