from __future__ import annotations

from pydantic import BaseModel


class CategoryTotalResponse(BaseModel):
    category_id: str
    name: str
    color: str
    icon: str
    total_amount: int
    percentage: float


class TrendPointResponse(BaseModel):
    month: int
    label: str
    total_spending: int
    total_income: int
    net_flow: int


class MonthlySummaryResponse(BaseModel):
    month: int
    year: int
    total_spending: int
    total_income: int
    net_cash_flow: int
    transaction_count: int
    weekly_burn_rate: int
    budget_alert_count: int
    insight: str


class AnalyticsSummaryResponse(BaseModel):
    month: int
    year: int
    monthly_total: int
    income_total: int
    expense_total: int
    top_category: str
    net_cash_flow: int
    transaction_count: int
    weekly_burn_rate: int
    budget_alert_count: int
    insight: str


class YearSummaryResponse(BaseModel):
    year: int
    total_spending: int
    total_income: int
    net_cash_flow: int
    average_monthly_spending: int
    monthly_breakdown: list[TrendPointResponse]


class MerchantSpendingResponse(BaseModel):
    merchant_name: str
    total_amount: int
    transaction_count: int
    trend_label: str


class EfficiencyScoreResponse(BaseModel):
    score: int
    household_average: int
    actual_spending: int
    delta_percentage: float
    insight: str
