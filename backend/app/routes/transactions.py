from __future__ import annotations

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.crud.transaction_crud import (
    create_transaction,
    get_form_metadata,
    get_transaction,
    list_transactions,
)
from app.database.database import get_db
from app.schemas.transaction_schema import (
    TransactionCreate,
    TransactionFormMetadata,
    TransactionResponse,
)

router = APIRouter(tags=["Transactions"])


@router.post("/transactions", response_model=TransactionResponse, status_code=status.HTTP_201_CREATED)
@router.post("/transaction", response_model=TransactionResponse, status_code=status.HTTP_201_CREATED)
def add_transaction(payload: TransactionCreate, session: Session = Depends(get_db)):
    return create_transaction(session, payload)


@router.get("/transactions", response_model=list[TransactionResponse])
def get_transactions(session: Session = Depends(get_db)):
    return list_transactions(session)


@router.get("/transactions/recent", response_model=list[TransactionResponse])
def get_recent_transactions(
    limit: int = Query(default=5, ge=1, le=20),
    session: Session = Depends(get_db),
):
    return list_transactions(session, limit=limit)


@router.get("/transactions/form-metadata", response_model=TransactionFormMetadata)
def get_transaction_form_metadata(session: Session = Depends(get_db)):
    return get_form_metadata(session)


@router.get("/transactions/{transaction_id}", response_model=TransactionResponse)
@router.get("/transaction/{transaction_id}", response_model=TransactionResponse)
def get_transaction_detail(transaction_id: str, session: Session = Depends(get_db)):
    return get_transaction(session, transaction_id)
