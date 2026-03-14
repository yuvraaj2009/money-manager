from __future__ import annotations

from datetime import date as calendar_date, datetime

from pydantic import BaseModel, ConfigDict, Field, model_validator


class CategoryOption(BaseModel):
    id: str
    name: str
    color: str
    icon: str

    model_config = ConfigDict(from_attributes=True)


class AccountOption(BaseModel):
    id: str
    name: str
    type: str
    masked_number: str

    model_config = ConfigDict(from_attributes=True)


class TransactionCreate(BaseModel):
    amount: int = Field(
        ...,
        description="Signed amount in paise. Use negative values for expenses and positive values for income.",
    )
    category_id: str
    description: str = Field(..., min_length=1, max_length=255)
    payment_method: str = Field(..., min_length=1, max_length=48)
    account_id: str
    date: calendar_date | None = None
    transaction_date: calendar_date | None = None
    reference_id: str | None = None
    receipt_url: str | None = None

    @model_validator(mode="after")
    def ensure_transaction_date(self) -> "TransactionCreate":
        if self.date is None and self.transaction_date is None:
            self.date = datetime.utcnow().date()
        elif self.date is None:
            self.date = self.transaction_date
        elif self.transaction_date is None:
            self.transaction_date = self.date
        return self

    @property
    def resolved_date(self) -> calendar_date:
        return self.transaction_date or self.date or datetime.utcnow().date()


class TransactionResponse(BaseModel):
    id: str
    amount: int
    amount_rupees: float
    flow: str
    category: str
    category_id: str
    category_name: str
    category_color: str
    category_icon: str
    description: str
    merchant_name: str
    payment_method: str
    account: str
    account_id: str
    account_name: str
    account_masked_number: str
    date: calendar_date
    transaction_date: calendar_date
    reference_id: str | None
    receipt_url: str | None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class TransactionFormMetadata(BaseModel):
    categories: list[CategoryOption]
    accounts: list[AccountOption]
    payment_methods: list[str]
