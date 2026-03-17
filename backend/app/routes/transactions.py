from __future__ import annotations

import logging

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.auth.dependencies import get_current_user
from app.crud.transaction_crud import (
    create_transaction,
    get_form_metadata,
    get_transaction,
    list_transactions,
)
from app.database.database import get_db
from app.database.models import User
from app.schemas.transaction_schema import (
    TransactionCreate,
    TransactionFormMetadata,
    TransactionResponse,
)

logger = logging.getLogger(__name__)
router = APIRouter(tags=["Transactions"])


@router.post("/transactions", response_model=TransactionResponse, status_code=status.HTTP_201_CREATED)
@router.post("/transaction", response_model=TransactionResponse, status_code=status.HTTP_201_CREATED)
def add_transaction(
    payload: TransactionCreate,
    session: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return create_transaction(session, payload, current_user.id)


@router.get("/transactions", response_model=list[TransactionResponse])
def get_transactions(
    session: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return list_transactions(session, current_user.id)


@router.get("/transactions/recent", response_model=list[TransactionResponse])
def get_recent_transactions(
    limit: int = Query(default=5, ge=1, le=20),
    session: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return list_transactions(session, current_user.id, limit=limit)


@router.get("/transactions/form-metadata", response_model=TransactionFormMetadata)
def get_transaction_form_metadata(
    session: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return get_form_metadata(session, current_user.id)


@router.get("/transactions/{transaction_id}", response_model=TransactionResponse)
@router.get("/transaction/{transaction_id}", response_model=TransactionResponse)
def get_transaction_detail(
    transaction_id: str,
    session: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return get_transaction(session, transaction_id, current_user.id)
