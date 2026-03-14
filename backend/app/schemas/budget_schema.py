from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, ConfigDict


class BudgetCreate(BaseModel):
    category_id: str
    monthly_limit: int


class BudgetResponse(BaseModel):
    id: str
    category: str
    category_id: str
    category_name: str
    category_color: str
    category_icon: str
    monthly_limit: int
    spent_amount: int
    remaining_amount: int
    utilization_percentage: float
    status: str
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class BudgetAlert(BaseModel):
    category_id: str
    category_name: str
    spent_amount: int
    monthly_limit: int
    over_amount: int
    utilization_percentage: float
    severity: str


class DailySpendBar(BaseModel):
    label: str
    amount: int
    is_today: bool = False


class BudgetUtilizationResponse(BaseModel):
    month: int
    year: int
    total_budget: int
    total_spent: int
    utilization_percentage: float
    alerts: list[BudgetAlert]
    budgets: list[BudgetResponse]
    daily_spend: list[DailySpendBar]
