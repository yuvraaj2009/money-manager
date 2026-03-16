from __future__ import annotations

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.auth.dependencies import get_current_user
from app.crud.budget_crud import list_budgets, upsert_budget
from app.database.database import get_db
from app.database.models import User
from app.schemas.budget_schema import BudgetCreate, BudgetResponse

router = APIRouter(tags=["Budgets"])


@router.get("/budgets", response_model=list[BudgetResponse])
def get_budgets(
    month: int | None = Query(default=None, ge=1, le=12),
    year: int | None = Query(default=None, ge=2000, le=2100),
    session: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return list_budgets(session, current_user.id, month=month, year=year)


@router.post("/budgets", response_model=BudgetResponse, status_code=status.HTTP_201_CREATED)
@router.post("/budget", response_model=BudgetResponse, status_code=status.HTTP_201_CREATED)
def save_budget(
    payload: BudgetCreate,
    session: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return upsert_budget(session, payload, current_user.id)
