from __future__ import annotations

import re
from dataclasses import dataclass
from datetime import date, datetime

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.crud.transaction_crud import create_transaction
from app.database.models import Account, Category
from app.schemas.transaction_schema import TransactionCreate
from app.utils.currency_utils import rupees_to_paise
from app.utils.id_generator import generate_reference_id

SMS_AMOUNT_PATTERN = re.compile(r"(?:Rs\.?|INR|₹)\s*([\d,]+(?:\.\d{1,2})?)", re.IGNORECASE)
SMS_ACCOUNT_PATTERN = re.compile(r"spent on\s+(.+?)\s+at\s+", re.IGNORECASE)
SMS_MERCHANT_PATTERN = re.compile(r"\bat\s+(.+?)\s+on\s+\d{1,2}\s+[A-Za-z]{3}", re.IGNORECASE)
SMS_DATE_PATTERN = re.compile(r"\bon\s+(\d{1,2}\s+[A-Za-z]{3}(?:\s+\d{4})?)", re.IGNORECASE)


@dataclass
class ParsedSmsTransaction:
    amount: int
    merchant: str
    transaction_date: date
    account_hint: str | None = None


def parse_sms_message(message: str) -> ParsedSmsTransaction | None:
    amount_match = SMS_AMOUNT_PATTERN.search(message)
    merchant_match = SMS_MERCHANT_PATTERN.search(message)
    date_match = SMS_DATE_PATTERN.search(message)
    account_match = SMS_ACCOUNT_PATTERN.search(message)

    if amount_match is None or merchant_match is None or date_match is None:
        return None

    amount = rupees_to_paise(amount_match.group(1))
    merchant = merchant_match.group(1).strip()
    raw_date = date_match.group(1).strip()
    parsed_date = None
    for pattern in ("%d %b %Y", "%d %b"):
        try:
            candidate = datetime.strptime(raw_date, pattern)
            if pattern == "%d %b":
                parsed_date = candidate.replace(year=date.today().year).date()
            else:
                parsed_date = candidate.date()
            break
        except ValueError:
            continue

    if parsed_date is None:
        return None

    return ParsedSmsTransaction(
        amount=-abs(amount),
        merchant=merchant,
        transaction_date=parsed_date,
        account_hint=account_match.group(1).strip() if account_match else None,
    )


def _infer_category_id(session: Session, merchant_name: str) -> str:
    name = merchant_name.lower()
    category_name = "Shopping"
    if any(keyword in name for keyword in ("bistro", "restaurant", "eats", "cafe")):
        category_name = "Food & Dining"
    elif any(keyword in name for keyword in ("utility", "electric", "water", "gas")):
        category_name = "Utilities"
    elif any(keyword in name for keyword in ("movie", "netflix", "cinema")):
        category_name = "Entertainment"
    elif any(keyword in name for keyword in ("uber", "metro", "fuel")):
        category_name = "Transport"

    category = session.scalar(select(Category).where(Category.name == category_name))
    if category is None:
        category = session.scalar(select(Category).order_by(Category.name.asc()))
    return category.id


def _match_account_id(session: Session, account_hint: str | None) -> str:
    if account_hint:
        accounts = session.scalars(select(Account).order_by(Account.name.asc())).all()
        normalized_hint = account_hint.lower()
        for account in accounts:
            if normalized_hint in account.name.lower() or normalized_hint in account.masked_number.lower():
                return account.id

    fallback_account = session.scalar(select(Account).order_by(Account.created_at.asc()))
    return fallback_account.id


def create_transaction_from_sms(
    session: Session, message: str, fallback_account_id: str | None = None
):
    parsed = parse_sms_message(message)
    if parsed is None:
        return None

    account_id = fallback_account_id or _match_account_id(session, parsed.account_hint)
    category_id = _infer_category_id(session, parsed.merchant)
    payload = TransactionCreate(
        amount=parsed.amount,
        category_id=category_id,
        description=parsed.merchant,
        payment_method="SMS Capture",
        account_id=account_id,
        date=parsed.transaction_date,
        reference_id=generate_reference_id("SMS"),
        receipt_url=None,
    )
    return create_transaction(session, payload)
