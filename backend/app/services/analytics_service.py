from __future__ import annotations

from collections import defaultdict
from datetime import date, datetime, timedelta

from sqlalchemy.orm import Session

from app.crud.budget_crud import list_budgets
from app.crud.transaction_crud import fetch_transactions_for_range
from app.schemas.analytics_schema import (
    AnalyticsSummaryResponse,
    CategoryTotalResponse,
    EfficiencyScoreResponse,
    MerchantSpendingResponse,
    MonthlySummaryResponse,
    TrendPointResponse,
    YearSummaryResponse,
)
from app.schemas.budget_schema import BudgetAlert, BudgetUtilizationResponse, DailySpendBar

HOUSEHOLD_AVERAGES = {
    "Housing": 180000,
    "Food": 45000,
    "Food & Dining": 40000,
    "Groceries": 80000,
    "Transport": 25000,
    "Utilities": 35000,
    "Entertainment": 20000,
    "Shopping": 60000,
    "Healthcare": 15000,
    "Health": 15000,
    "Lifestyle": 30000,
}


def _utc_today() -> date:
    return datetime.utcnow().date()


def _month_range(target: date) -> tuple[date, date]:
    start = date(target.year, target.month, 1)
    if target.month == 12:
        end = date(target.year, 12, 31)
    else:
        end = date(target.year, target.month + 1, 1) - timedelta(days=1)
    return start, end


def _sum_spending(transactions) -> int:
    return sum(abs(t.amount) for t in transactions if t.amount < 0)


def _sum_income(transactions) -> int:
    return sum(t.amount for t in transactions if t.amount > 0)


def get_budget_exceeded_alerts(
    session: Session, user_id: str, target: date | None = None
) -> list[BudgetAlert]:
    """Return budget alerts for categories at caution or exceeded status."""
    focus_date = target or _utc_today()
    budgets = list_budgets(session, user_id, month=focus_date.month, year=focus_date.year)
    alerts: list[BudgetAlert] = []
    for budget in budgets:
        if budget.status == "safe":
            continue
        alerts.append(
            BudgetAlert(
                category_id=budget.category_id,
                category_name=budget.category_name,
                spent_amount=budget.spent_amount,
                monthly_limit=budget.monthly_limit,
                over_amount=max(budget.spent_amount - budget.monthly_limit, 0),
                utilization_percentage=budget.utilization_percentage,
                severity="high" if budget.status == "exceeded" else "medium",
            )
        )
    return alerts


def get_weekly_burn_rate(session: Session, user_id: str, target: date | None = None) -> int:
    """Calculate average daily spending over the past 7 days, in paise."""
    focus_date = target or _utc_today()
    start = focus_date - timedelta(days=6)
    transactions = fetch_transactions_for_range(session, start, focus_date, user_id)
    total_spending = _sum_spending(transactions)
    return round(total_spending / 7) if total_spending else 0


def get_monthly_summary(
    session: Session, user_id: str, month: int | None = None, year: int | None = None
) -> MonthlySummaryResponse:
    """Aggregate income, spending, alerts, and insight for a single month."""
    today = _utc_today()
    focus_date = date(year or today.year, month or today.month, 1)
    start, end = _month_range(focus_date)
    transactions = fetch_transactions_for_range(session, start, end, user_id)
    total_spending = _sum_spending(transactions)
    total_income = _sum_income(transactions)
    budget_alerts = get_budget_exceeded_alerts(session, user_id, focus_date)
    category_totals = get_category_totals(session, user_id, month=focus_date.month, year=focus_date.year)
    top_category = category_totals[0].name if category_totals else "discretionary"
    insight = (
        f"{top_category} is your highest spend area this month. "
        f"You have {len(budget_alerts)} budget alert(s) to watch."
    )
    return MonthlySummaryResponse(
        month=focus_date.month,
        year=focus_date.year,
        total_spending=total_spending,
        total_income=total_income,
        net_cash_flow=total_income - total_spending,
        transaction_count=len(transactions),
        weekly_burn_rate=get_weekly_burn_rate(session, user_id, today),
        budget_alert_count=len(budget_alerts),
        insight=insight,
    )


def get_analytics_summary(
    session: Session, user_id: str, month: int | None = None, year: int | None = None
) -> AnalyticsSummaryResponse:
    """Return the full analytics summary including top category and insight."""
    summary = get_monthly_summary(session, user_id, month=month, year=year)
    categories = get_category_totals(session, user_id, month=summary.month, year=summary.year)
    top_category = categories[0].name if categories else "Other"
    return AnalyticsSummaryResponse(
        month=summary.month,
        year=summary.year,
        monthly_total=summary.total_income + summary.total_spending,
        income_total=summary.total_income,
        expense_total=summary.total_spending,
        top_category=top_category,
        net_cash_flow=summary.net_cash_flow,
        transaction_count=summary.transaction_count,
        weekly_burn_rate=summary.weekly_burn_rate,
        budget_alert_count=summary.budget_alert_count,
        insight=summary.insight,
    )


def get_yearly_summary(
    session: Session, user_id: str, year: int | None = None
) -> YearSummaryResponse:
    """Aggregate spending/income across all 12 months for the given year."""
    target_year = year or _utc_today().year
    monthly_breakdown: list[TrendPointResponse] = []
    for month_index in range(1, 13):
        start = date(target_year, month_index, 1)
        _, end = _month_range(start)
        transactions = fetch_transactions_for_range(session, start, end, user_id)
        spending = _sum_spending(transactions)
        income = _sum_income(transactions)
        monthly_breakdown.append(
            TrendPointResponse(
                month=month_index,
                label=start.strftime("%b"),
                total_spending=spending,
                total_income=income,
                net_flow=income - spending,
            )
        )

    total_spending = sum(p.total_spending for p in monthly_breakdown)
    total_income = sum(p.total_income for p in monthly_breakdown)
    return YearSummaryResponse(
        year=target_year,
        total_spending=total_spending,
        total_income=total_income,
        net_cash_flow=total_income - total_spending,
        average_monthly_spending=round(total_spending / 12) if total_spending else 0,
        monthly_breakdown=monthly_breakdown,
    )


def get_category_totals(
    session: Session, user_id: str, month: int | None = None, year: int | None = None
) -> list[CategoryTotalResponse]:
    """Return per-category spending totals sorted by amount descending."""
    today = _utc_today()
    focus_date = date(year or today.year, month or today.month, 1)
    start, end = _month_range(focus_date)
    transactions = fetch_transactions_for_range(session, start, end, user_id)
    totals: dict[str, dict[str, object]] = {}
    total_spending = _sum_spending(transactions)

    for transaction in transactions:
        if transaction.amount >= 0:
            continue
        bucket = totals.setdefault(
            transaction.category_id,
            {
                "name": transaction.category.name,
                "color": transaction.category.color,
                "icon": transaction.category.icon,
                "total": 0,
            },
        )
        bucket["total"] = int(bucket["total"]) + abs(transaction.amount)

    sorted_items = sorted(totals.items(), key=lambda item: int(item[1]["total"]), reverse=True)
    response: list[CategoryTotalResponse] = []
    for category_id, bucket in sorted_items:
        category_total = int(bucket["total"])
        percentage = round((category_total / total_spending) * 100, 1) if total_spending else 0.0
        response.append(
            CategoryTotalResponse(
                category_id=category_id,
                name=str(bucket["name"]),
                color=str(bucket["color"]),
                icon=str(bucket["icon"]),
                total_amount=category_total,
                percentage=percentage,
            )
        )
    return response


def get_trends(
    session: Session, user_id: str, year: int | None = None
) -> list[TrendPointResponse]:
    """Return monthly trend data points for the given year."""
    return get_yearly_summary(session, user_id, year=year).monthly_breakdown


def get_top_merchants(
    session: Session, user_id: str, month: int | None = None, year: int | None = None, limit: int = 5
) -> list[MerchantSpendingResponse]:
    """Return top merchants by spending with month-over-month trend labels."""
    today = _utc_today()
    focus_date = date(year or today.year, month or today.month, 1)
    previous_month = date(
        focus_date.year - 1 if focus_date.month == 1 else focus_date.year,
        12 if focus_date.month == 1 else focus_date.month - 1,
        1,
    )
    current_start, current_end = _month_range(focus_date)
    prev_start, prev_end = _month_range(previous_month)
    current_transactions = fetch_transactions_for_range(session, current_start, current_end, user_id)
    previous_transactions = fetch_transactions_for_range(session, prev_start, prev_end, user_id)

    current_totals: dict[str, dict[str, int]] = defaultdict(lambda: {"total": 0, "count": 0})
    previous_totals: dict[str, int] = defaultdict(int)

    for transaction in current_transactions:
        if transaction.amount < 0:
            current_totals[transaction.description]["total"] += abs(transaction.amount)
            current_totals[transaction.description]["count"] += 1

    for transaction in previous_transactions:
        if transaction.amount < 0:
            previous_totals[transaction.description] += abs(transaction.amount)

    merchants = sorted(
        current_totals.items(),
        key=lambda item: item[1]["total"],
        reverse=True,
    )[:limit]

    response: list[MerchantSpendingResponse] = []
    for merchant_name, data in merchants:
        previous_total = previous_totals.get(merchant_name, 0)
        if previous_total == 0:
            trend_label = "New"
        else:
            delta = ((data["total"] - previous_total) / previous_total) * 100
            if abs(delta) < 1:
                trend_label = "Flat"
            elif delta > 0:
                trend_label = f"Up {round(delta)}%"
            else:
                trend_label = f"Down {abs(round(delta))}%"

        response.append(
            MerchantSpendingResponse(
                merchant_name=merchant_name,
                total_amount=data["total"],
                transaction_count=data["count"],
                trend_label=trend_label,
            )
        )
    return response


def get_efficiency_score(
    session: Session, user_id: str, month: int | None = None, year: int | None = None
) -> EfficiencyScoreResponse:
    """Compute an efficiency score (18-99) comparing actual spending to household baselines."""
    today = _utc_today()
    focus_date = date(year or today.year, month or today.month, 1)
    start, end = _month_range(focus_date)
    transactions = fetch_transactions_for_range(session, start, end, user_id)
    actual_spending = _sum_spending(transactions)
    household_average = sum(HOUSEHOLD_AVERAGES.values())
    alerts = get_budget_exceeded_alerts(session, user_id, focus_date)

    if household_average == 0:
        delta_percentage = 0.0
    else:
        delta_percentage = round(
            ((household_average - actual_spending) / household_average) * 100, 1
        )

    score = round(78 + (delta_percentage * 0.7) - (len(alerts) * 6))
    score = max(18, min(score, 99))

    if delta_percentage >= 0:
        insight = (
            f"Your household spending is {delta_percentage}% more efficient than the "
            "local baseline this month."
        )
    else:
        insight = (
            f"Spending is {abs(delta_percentage)}% above the modeled baseline. "
            "Focus on the categories with active alerts."
        )

    return EfficiencyScoreResponse(
        score=score,
        household_average=household_average,
        actual_spending=actual_spending,
        delta_percentage=delta_percentage,
        insight=insight,
    )


def get_budget_utilization(
    session: Session, user_id: str, month: int | None = None, year: int | None = None
) -> BudgetUtilizationResponse:
    """Return overall budget utilization with daily spend bars and alerts."""
    today = _utc_today()
    focus_date = date(year or today.year, month or today.month, 1)
    budgets = list_budgets(session, user_id, month=focus_date.month, year=focus_date.year)
    total_budget = sum(budget.monthly_limit for budget in budgets)
    total_spent = sum(budget.spent_amount for budget in budgets)
    utilization = round((total_spent / total_budget) * 100, 1) if total_budget else 0.0

    bars: list[DailySpendBar] = []
    for offset in range(6, -1, -1):
        current_day = today - timedelta(days=offset)
        transactions = fetch_transactions_for_range(session, current_day, current_day, user_id)
        bars.append(
            DailySpendBar(
                label=current_day.strftime("%a"),
                amount=_sum_spending(transactions),
                is_today=offset == 0,
            )
        )

    return BudgetUtilizationResponse(
        month=focus_date.month,
        year=focus_date.year,
        total_budget=total_budget,
        total_spent=total_spent,
        utilization_percentage=utilization,
        alerts=get_budget_exceeded_alerts(session, user_id, focus_date),
        budgets=budgets,
        daily_spend=bars,
    )
