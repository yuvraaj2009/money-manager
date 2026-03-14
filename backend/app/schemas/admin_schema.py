from __future__ import annotations

from pydantic import BaseModel


class AdminResetResponse(BaseModel):
    status: str
    deleted_transactions: int
    deleted_budgets: int
    deleted_budget_history: int
    recreated_categories: int
    recreated_accounts: int
    preserved_profile: bool
