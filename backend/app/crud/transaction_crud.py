from __future__ import annotations

from datetime import date, datetime

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.database.models import Account, Category, Transaction
from app.schemas.transaction_schema import (
    AccountOption,
    CategoryOption,
    TransactionCreate,
    TransactionFormMetadata,
    TransactionResponse,
)
from app.utils.currency_utils import paise_to_rupees
from app.utils.id_generator import generate_id, generate_reference_id

PAYMENT_METHODS = ["Cash", "Card", "UPI", "Wallet", "Auto-Pay", "Bank Transfer"]


def _require_category(session: Session, category_id: str) -> Category:
    category = session.get(Category, category_id)
    if category is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Category '{category_id}' was not found.",
        )
    return category


def _require_account(session: Session, account_id: str) -> Account:
    account = session.get(Account, account_id)
    if account is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Account '{account_id}' was not found.",
        )
    return account


def _base_transaction_query():
    return (
        select(Transaction)
        .options(selectinload(Transaction.category), selectinload(Transaction.account))
        .order_by(Transaction.date.desc(), Transaction.created_at.desc())
    )


def serialize_transaction(transaction: Transaction) -> TransactionResponse:
    return TransactionResponse(
        id=transaction.id,
        amount=transaction.amount,
        amount_rupees=paise_to_rupees(transaction.amount),
        flow="income" if transaction.amount > 0 else "expense",
        category=transaction.category.name,
        category_id=transaction.category_id,
        category_name=transaction.category.name,
        category_color=transaction.category.color,
        category_icon=transaction.category.icon,
        description=transaction.description,
        merchant_name=transaction.description,
        payment_method=transaction.payment_method,
        account=transaction.account.name,
        account_id=transaction.account_id,
        account_name=transaction.account.name,
        account_masked_number=transaction.account.masked_number,
        date=transaction.date,
        transaction_date=transaction.date,
        reference_id=transaction.reference_id,
        receipt_url=transaction.receipt_url,
        created_at=transaction.created_at,
    )


def create_transaction(session: Session, payload: TransactionCreate) -> TransactionResponse:
    _require_category(session, payload.category_id)
    _require_account(session, payload.account_id)

    transaction_date = payload.resolved_date
    transaction = Transaction(
        id=generate_id("TRX"),
        amount=payload.amount,
        category_id=payload.category_id,
        description=payload.description.strip(),
        payment_method=payload.payment_method.strip(),
        account_id=payload.account_id,
        date=transaction_date,
        reference_id=payload.reference_id or generate_reference_id("TRX"),
        receipt_url=payload.receipt_url,
        created_at=datetime.utcnow(),
    )
    session.add(transaction)
    session.commit()
    session.refresh(transaction)

    from app.crud.budget_crud import refresh_budget_history

    refresh_budget_history(session, month=transaction_date.month, year=transaction_date.year)
    transaction = session.scalar(
        _base_transaction_query().where(Transaction.id == transaction.id)
    )
    return serialize_transaction(transaction)


def list_transactions(session: Session, limit: int | None = None) -> list[TransactionResponse]:
    query = _base_transaction_query()
    if limit is not None:
        query = query.limit(limit)
    transactions = session.scalars(query).all()
    return [serialize_transaction(transaction) for transaction in transactions]


def get_transaction(session: Session, transaction_id: str) -> TransactionResponse:
    transaction = session.scalar(
        _base_transaction_query().where(Transaction.id == transaction_id)
    )
    if transaction is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Transaction '{transaction_id}' was not found.",
        )
    return serialize_transaction(transaction)


def list_categories(session: Session) -> list[CategoryOption]:
    categories = session.scalars(select(Category).order_by(Category.name.asc())).all()
    return [CategoryOption.model_validate(category) for category in categories]


def list_accounts(session: Session) -> list[AccountOption]:
    accounts = session.scalars(select(Account).order_by(Account.name.asc())).all()
    return [AccountOption.model_validate(account) for account in accounts]


def get_form_metadata(session: Session) -> TransactionFormMetadata:
    return TransactionFormMetadata(
        categories=list_categories(session),
        accounts=list_accounts(session),
        payment_methods=PAYMENT_METHODS,
    )


def fetch_transactions_for_range(
    session: Session, start_date: date, end_date: date
) -> list[Transaction]:
    query = (
        _base_transaction_query()
        .where(Transaction.date >= start_date)
        .where(Transaction.date <= end_date)
    )
    return session.scalars(query).all()
