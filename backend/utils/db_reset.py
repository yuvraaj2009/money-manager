from __future__ import annotations

from datetime import datetime

from sqlalchemy import delete
from sqlalchemy.orm import Session

from app.database import models  # noqa: F401
from app.database.database import Base, SessionLocal, engine
from app.database.models import Account, Budget, BudgetHistory, Category, Transaction
from app.database.seed_data import seed_database


def seed_default_data(
    session: Session,
    *,
    include_budgets: bool = True,
    include_profile: bool = True,
    include_demo_transactions: bool = False,
) -> None:
    seed_database(
        session,
        include_budgets=include_budgets,
        include_profile=include_profile,
        include_demo_transactions=include_demo_transactions,
    )


def reset_database() -> None:
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    with SessionLocal() as session:
        seed_default_data(session)


def reset_household_data(session: Session) -> dict[str, int | bool | str]:
    deleted_transactions = session.execute(delete(Transaction)).rowcount or 0
    deleted_budget_history = session.execute(delete(BudgetHistory)).rowcount or 0
    deleted_budgets = session.execute(delete(Budget)).rowcount or 0
    session.execute(delete(Category))
    session.execute(delete(Account))
    session.commit()

    seed_default_data(
        session,
        include_budgets=False,
        include_profile=False,
        include_demo_transactions=False,
    )

    recreated_categories = session.query(Category).count()
    recreated_accounts = session.query(Account).count()

    return {
        "status": "reset",
        "deleted_transactions": deleted_transactions,
        "deleted_budgets": deleted_budgets,
        "deleted_budget_history": deleted_budget_history,
        "recreated_categories": recreated_categories,
        "recreated_accounts": recreated_accounts,
        "preserved_profile": True,
    }
