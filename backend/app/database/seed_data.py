from __future__ import annotations

from datetime import datetime

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database.models import Account, Budget, Category, Profile, Transaction
from app.utils.id_generator import generate_id, generate_reference_id

DEFAULT_CATEGORIES = [
    {"name": "Housing", "color": "#0F52FF", "icon": "home"},
    {"name": "Food", "color": "#0E8C3A", "icon": "restaurant"},
    {"name": "Entertainment", "color": "#C53A16", "icon": "movie"},
    {"name": "Groceries", "color": "#4CEB74", "icon": "shopping_cart"},
    {"name": "Transport", "color": "#FF9479", "icon": "commute"},
    {"name": "Utilities", "color": "#6E8CFF", "icon": "bolt"},
    {"name": "Shopping", "color": "#0049E6", "icon": "shopping_bag"},
    {"name": "Healthcare", "color": "#F74B6D", "icon": "health_and_safety"},
    {"name": "Income", "color": "#0B7D2A", "icon": "payments"},
]

DEFAULT_ACCOUNTS = [
    {"name": "Bank account", "type": "Bank", "masked_number": "HDFC **** 8291"},
    {"name": "Visa Black", "type": "Card", "masked_number": "Visa Black **** 9012"},
    {"name": "Wallet", "type": "Wallet", "masked_number": "Digital Credits"},
    {"name": "Joint Savings Account", "type": "Savings", "masked_number": "Joint **** 4401"},
]

DEFAULT_BUDGET_LIMITS = {
    "Housing": 180000,
    "Food": 45000,
    "Entertainment": 20000,
    "Groceries": 80000,
    "Transport": 25000,
    "Utilities": 35000,
    "Shopping": 40000,
    "Healthcare": 15000,
}


def seed_user_defaults(session: Session, user_id: str) -> None:
    """Seed default categories, accounts, budgets, and profile for a new user."""
    cat_map: dict[str, str] = {}
    for cat_data in DEFAULT_CATEGORIES:
        cat_id = generate_id("CAT")
        cat_map[cat_data["name"]] = cat_id
        session.add(Category(id=cat_id, user_id=user_id, **cat_data))

    for acc_data in DEFAULT_ACCOUNTS:
        session.add(Account(id=generate_id("ACC"), user_id=user_id, **acc_data))

    for cat_name, limit in DEFAULT_BUDGET_LIMITS.items():
        cat_id = cat_map.get(cat_name)
        if cat_id:
            session.add(
                Budget(
                    id=generate_id("BGT"),
                    user_id=user_id,
                    category_id=cat_id,
                    monthly_limit=limit,
                )
            )

    session.add(
        Profile(
            id=generate_id("PRF"),
            user_id=user_id,
            name="My Household",
            monthly_income=0,
            currency="INR",
            household_members=1,
        )
    )

    session.commit()


def seed_database(
    session: Session,
    *,
    include_budgets: bool = True,
    include_profile: bool = True,
    include_demo_transactions: bool = False,
) -> None:
    """Legacy seed — no-op when auth is enabled.

    Data is now seeded per-user via seed_user_defaults on first login.
    """
    pass
