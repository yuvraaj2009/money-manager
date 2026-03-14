from __future__ import annotations

from datetime import datetime

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database.models import Account, Budget, Category, Profile, Transaction
from app.utils.id_generator import generate_id, generate_reference_id

DEFAULT_CATEGORIES = [
    {"id": "cat_housing", "name": "Housing", "color": "#0F52FF", "icon": "home"},
    {"id": "cat_food", "name": "Food", "color": "#0E8C3A", "icon": "restaurant"},
    {
        "id": "cat_entertainment",
        "name": "Entertainment",
        "color": "#C53A16",
        "icon": "movie",
    },
    {
        "id": "cat_groceries",
        "name": "Groceries",
        "color": "#4CEB74",
        "icon": "shopping_cart",
    },
    {"id": "cat_transport", "name": "Transport", "color": "#FF9479", "icon": "commute"},
    {"id": "cat_utilities", "name": "Utilities", "color": "#6E8CFF", "icon": "bolt"},
    {"id": "cat_shopping", "name": "Shopping", "color": "#0049E6", "icon": "shopping_bag"},
    {
        "id": "cat_healthcare",
        "name": "Healthcare",
        "color": "#F74B6D",
        "icon": "health_and_safety",
    },
    {"id": "cat_income", "name": "Income", "color": "#0B7D2A", "icon": "payments"},
]

DEFAULT_ACCOUNTS = [
    {
        "id": "acc_hdfc_8291",
        "name": "Bank account",
        "type": "Bank",
        "masked_number": "HDFC **** 8291",
    },
    {
        "id": "acc_visa_9012",
        "name": "Visa Black",
        "type": "Card",
        "masked_number": "Visa Black **** 9012",
    },
    {
        "id": "acc_wallet_credits",
        "name": "Wallet",
        "type": "Wallet",
        "masked_number": "Digital Credits",
    },
    {
        "id": "acc_joint_savings",
        "name": "Joint Savings Account",
        "type": "Savings",
        "masked_number": "Joint **** 4401",
    },
]

DEFAULT_BUDGETS = [
    {"id": "bud_housing", "category_id": "cat_housing", "monthly_limit": 180000},
    {"id": "bud_food", "category_id": "cat_food", "monthly_limit": 45000},
    {"id": "bud_entertainment", "category_id": "cat_entertainment", "monthly_limit": 20000},
    {"id": "bud_groceries", "category_id": "cat_groceries", "monthly_limit": 80000},
    {"id": "bud_transport", "category_id": "cat_transport", "monthly_limit": 25000},
    {"id": "bud_utilities", "category_id": "cat_utilities", "monthly_limit": 35000},
    {"id": "bud_shopping", "category_id": "cat_shopping", "monthly_limit": 40000},
    {"id": "bud_healthcare", "category_id": "cat_healthcare", "monthly_limit": 15000},
]

DEFAULT_PROFILE = {
    "id": "profile_primary",
    "name": "My Household",
    "monthly_income": 0,
    "currency": "INR",
    "household_members": 2,
}


def _demo_transactions(now: datetime) -> list[dict[str, object]]:
    return [
        {
            "id": generate_id("TRX"),
            "amount": 850000,
            "category_id": "cat_income",
            "description": "Monthly Income",
            "payment_method": "ACH Transfer",
            "account_id": "acc_joint_savings",
            "date": now.date().replace(day=1),
            "reference_id": generate_reference_id("PAY"),
            "receipt_url": None,
            "created_at": now,
        },
        {
            "id": generate_id("TRX"),
            "amount": -129900,
            "category_id": "cat_shopping",
            "description": "Grocery and Essentials",
            "payment_method": "Debit Card",
            "account_id": "acc_hdfc_8291",
            "date": now.date(),
            "reference_id": generate_reference_id("SHOP"),
            "receipt_url": None,
            "created_at": now,
        },
    ]


def seed_database(
    session: Session,
    *,
    include_budgets: bool = True,
    include_profile: bool = True,
    include_demo_transactions: bool = False,
) -> None:
    if session.scalar(select(Category.id).limit(1)) is None:
        session.add_all(Category(**category) for category in DEFAULT_CATEGORIES)

    if session.scalar(select(Account.id).limit(1)) is None:
        session.add_all(Account(**account) for account in DEFAULT_ACCOUNTS)

    if include_profile and session.scalar(select(Profile.id).limit(1)) is None:
        session.add(Profile(**DEFAULT_PROFILE))

    if include_budgets and session.scalar(select(Budget.id).limit(1)) is None:
        session.add_all(Budget(**budget) for budget in DEFAULT_BUDGETS)

    if include_demo_transactions and session.scalar(select(Transaction.id).limit(1)) is None:
        now = datetime.utcnow()
        session.add_all(Transaction(**transaction) for transaction in _demo_transactions(now))

    session.commit()
