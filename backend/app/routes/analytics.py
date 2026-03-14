from __future__ import annotations

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.database.database import get_db
from app.schemas.analytics_schema import (
    AnalyticsSummaryResponse,
    CategoryTotalResponse,
    EfficiencyScoreResponse,
    MerchantSpendingResponse,
    MonthlySummaryResponse,
    TrendPointResponse,
    YearSummaryResponse,
)
from app.schemas.budget_schema import BudgetUtilizationResponse
from app.services.analytics_service import (
    get_analytics_summary,
    get_budget_utilization,
    get_category_totals,
    get_efficiency_score,
    get_monthly_summary,
    get_top_merchants,
    get_trends,
    get_yearly_summary,
)

router = APIRouter(tags=["Analytics"])


@router.get("/analytics/summary", response_model=AnalyticsSummaryResponse)
def analytics_summary(
    month: int | None = Query(default=None, ge=1, le=12),
    year: int | None = Query(default=None, ge=2000, le=2100),
    session: Session = Depends(get_db),
):
    return get_analytics_summary(session, month=month, year=year)


@router.get("/summary/month", response_model=MonthlySummaryResponse)
def summary_month(
    month: int | None = Query(default=None, ge=1, le=12),
    year: int | None = Query(default=None, ge=2000, le=2100),
    session: Session = Depends(get_db),
):
    return get_monthly_summary(session, month=month, year=year)


@router.get("/summary/year", response_model=YearSummaryResponse)
def summary_year(
    year: int | None = Query(default=None, ge=2000, le=2100),
    session: Session = Depends(get_db),
):
    return get_yearly_summary(session, year=year)


@router.get("/analytics/categories", response_model=list[CategoryTotalResponse])
def analytics_categories(
    month: int | None = Query(default=None, ge=1, le=12),
    year: int | None = Query(default=None, ge=2000, le=2100),
    session: Session = Depends(get_db),
):
    return get_category_totals(session, month=month, year=year)


@router.get("/analytics/trends", response_model=list[TrendPointResponse])
def analytics_trends(
    year: int | None = Query(default=None, ge=2000, le=2100),
    session: Session = Depends(get_db),
):
    return get_trends(session, year=year)


@router.get("/analytics/top-merchants", response_model=list[MerchantSpendingResponse])
def analytics_top_merchants(
    month: int | None = Query(default=None, ge=1, le=12),
    year: int | None = Query(default=None, ge=2000, le=2100),
    limit: int = Query(default=5, ge=1, le=20),
    session: Session = Depends(get_db),
):
    return get_top_merchants(session, month=month, year=year, limit=limit)


@router.get("/analytics/efficiency", response_model=EfficiencyScoreResponse)
def analytics_efficiency(
    month: int | None = Query(default=None, ge=1, le=12),
    year: int | None = Query(default=None, ge=2000, le=2100),
    session: Session = Depends(get_db),
):
    return get_efficiency_score(session, month=month, year=year)


@router.get("/analytics/budget-utilization", response_model=BudgetUtilizationResponse)
def analytics_budget_utilization(
    month: int | None = Query(default=None, ge=1, le=12),
    year: int | None = Query(default=None, ge=2000, le=2100),
    session: Session = Depends(get_db),
):
    return get_budget_utilization(session, month=month, year=year)
