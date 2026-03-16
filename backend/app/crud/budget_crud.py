from __future__ import annotations

from datetime import date, datetime, timedelta

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.database.models import Budget, BudgetHistory, Category
from app.schemas.budget_schema import BudgetCreate, BudgetResponse
from app.utils.id_generator import generate_id


def _utc_today() -> date:
    return datetime.utcnow().date()


def _month_window(month: int, year: int) -> tuple[date, date]:
    start = date(year, month, 1)
    if month == 12:
        end = date(year, 12, 31)
    else:
        end = date(year, month + 1, 1) - timedelta(days=1)
    return start, end


def _build_budget_response(budget: Budget, spent_amount: int) -> BudgetResponse:
    """Build a BudgetResponse with calculated utilization and status."""
    remaining = max(budget.monthly_limit - spent_amount, 0)
    utilization = (
        round((spent_amount / budget.monthly_limit) * 100, 1)
        if budget.monthly_limit
        else 0.0
    )
    status_name = "safe"
    if spent_amount > budget.monthly_limit:
        status_name = "exceeded"
    elif spent_amount >= budget.monthly_limit * 0.8:
        status_name = "caution"

    return BudgetResponse(
        id=budget.id,
        category=budget.category.name,
        category_id=budget.category_id,
        category_name=budget.category.name,
        category_color=budget.category.color,
        category_icon=budget.category.icon,
        monthly_limit=budget.monthly_limit,
        spent_amount=spent_amount,
        remaining_amount=remaining,
        utilization_percentage=utilization,
        status=status_name,
        created_at=budget.created_at,
    )


def refresh_budget_history(
    session: Session,
    user_id: str,
    month: int | None = None,
    year: int | None = None,
) -> None:
    """Recalculate budget history for the user's budgets."""
    from app.crud.transaction_crud import fetch_transactions_for_range

    today = _utc_today()
    target_month = month or today.month
    target_year = year or today.year
    start, end = _month_window(target_month, target_year)

    budgets = session.scalars(
        select(Budget)
        .where(Budget.user_id == user_id)
        .options(selectinload(Budget.category))
        .order_by(Budget.created_at.asc())
    ).all()
    transactions = fetch_transactions_for_range(session, start, end, user_id)

    spent_by_category: dict[str, int] = {}
    for transaction in transactions:
        if transaction.amount < 0:
            spent_by_category[transaction.category_id] = (
                spent_by_category.get(transaction.category_id, 0) + abs(transaction.amount)
            )

    existing_history = session.scalars(
        select(BudgetHistory)
        .where(
            BudgetHistory.user_id == user_id,
            BudgetHistory.month == target_month,
            BudgetHistory.year == target_year,
        )
    ).all()
    history_map = {entry.category_id: entry for entry in existing_history}

    for budget in budgets:
        spent_amount = spent_by_category.get(budget.category_id, 0)
        history = history_map.get(budget.category_id)
        if history is None:
            session.add(
                BudgetHistory(
                    id=generate_id("BGH"),
                    user_id=user_id,
                    category_id=budget.category_id,
                    spent_amount=spent_amount,
                    month=target_month,
                    year=target_year,
                )
            )
        else:
            history.spent_amount = spent_amount

    session.commit()


def list_budgets(
    session: Session,
    user_id: str,
    month: int | None = None,
    year: int | None = None,
) -> list[BudgetResponse]:
    """List all budgets for the user with current spent amounts."""
    refresh_budget_history(session, user_id, month=month, year=year)

    today = _utc_today()
    target_month = month or today.month
    target_year = year or today.year
    history_entries = session.scalars(
        select(BudgetHistory)
        .where(
            BudgetHistory.user_id == user_id,
            BudgetHistory.month == target_month,
            BudgetHistory.year == target_year,
        )
    ).all()
    history_map = {entry.category_id: entry.spent_amount for entry in history_entries}

    budgets = session.scalars(
        select(Budget)
        .where(Budget.user_id == user_id)
        .options(selectinload(Budget.category))
        .order_by(Budget.created_at.asc())
    ).all()
    return [
        _build_budget_response(budget, history_map.get(budget.category_id, 0))
        for budget in budgets
    ]


def upsert_budget(
    session: Session, payload: BudgetCreate, user_id: str
) -> BudgetResponse:
    """Create or update a budget for the given user."""
    category = session.scalar(
        select(Category)
        .where(Category.id == payload.category_id, Category.user_id == user_id)
    )
    if category is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Category '{payload.category_id}' was not found.",
        )

    budget = session.scalar(
        select(Budget).where(
            Budget.user_id == user_id,
            Budget.category_id == payload.category_id,
        )
    )
    if budget is None:
        budget = Budget(
            id=generate_id("BGT"),
            user_id=user_id,
            category_id=payload.category_id,
            monthly_limit=payload.monthly_limit,
            created_at=datetime.utcnow(),
        )
        session.add(budget)
    else:
        budget.monthly_limit = payload.monthly_limit

    session.commit()
    session.refresh(budget)
    refresh_budget_history(session, user_id)

    budget = session.scalar(
        select(Budget)
        .options(selectinload(Budget.category))
        .where(Budget.id == budget.id)
    )
    today = _utc_today()
    spent_amount = session.scalar(
        select(BudgetHistory.spent_amount)
        .where(
            BudgetHistory.user_id == user_id,
            BudgetHistory.category_id == budget.category_id,
            BudgetHistory.month == today.month,
            BudgetHistory.year == today.year,
        )
    ) or 0
    return _build_budget_response(budget, spent_amount)
