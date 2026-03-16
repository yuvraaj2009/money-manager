from __future__ import annotations

from datetime import date, datetime

from sqlalchemy import Date, DateTime, ForeignKey, Integer, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database.database import Base


def utcnow() -> datetime:
    return datetime.utcnow()


# ── User ──────────────────────────────────────────────────────────────────

class User(Base):
    __tablename__ = "users"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    google_id: Mapped[str] = mapped_column(String(128), unique=True, index=True)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    name: Mapped[str] = mapped_column(String(255))
    picture_url: Mapped[str | None] = mapped_column(String(512))
    created_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow, onupdate=utcnow)

    categories: Mapped[list["Category"]] = relationship(back_populates="user")
    accounts: Mapped[list["Account"]] = relationship(back_populates="user")
    transactions: Mapped[list["Transaction"]] = relationship(back_populates="user")
    budgets: Mapped[list["Budget"]] = relationship(back_populates="user")
    profiles: Mapped[list["Profile"]] = relationship(back_populates="user")

    def __repr__(self) -> str:
        return f"<User {self.id} {self.email}>"


# ── Household ─────────────────────────────────────────────────────────────

class Household(Base):
    __tablename__ = "households"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    name: Mapped[str] = mapped_column(String(120))
    invite_code: Mapped[str] = mapped_column(String(16), unique=True, index=True)
    created_by: Mapped[str] = mapped_column(ForeignKey("users.id"))
    created_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)

    members: Mapped[list["HouseholdMember"]] = relationship(back_populates="household")
    creator: Mapped[User] = relationship()

    def __repr__(self) -> str:
        return f"<Household {self.id} {self.name!r}>"


class HouseholdMember(Base):
    __tablename__ = "household_members"
    __table_args__ = (
        UniqueConstraint("household_id", "user_id", name="uq_household_user"),
    )

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    household_id: Mapped[str] = mapped_column(ForeignKey("households.id"), index=True)
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id"), index=True)
    role: Mapped[str] = mapped_column(String(20), default="member")
    joined_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)

    household: Mapped[Household] = relationship(back_populates="members")
    user: Mapped[User] = relationship()

    def __repr__(self) -> str:
        return f"<HouseholdMember {self.user_id} in {self.household_id}>"


# ── Category ──────────────────────────────────────────────────────────────

class Category(Base):
    __tablename__ = "categories"
    __table_args__ = (
        UniqueConstraint("user_id", "name", name="uq_user_category_name"),
    )

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id"), index=True)
    name: Mapped[str] = mapped_column(String(80), index=True)
    color: Mapped[str] = mapped_column(String(16), default="#0049E6")
    icon: Mapped[str] = mapped_column(String(48), default="wallet")
    created_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)

    user: Mapped[User] = relationship(back_populates="categories")
    transactions: Mapped[list["Transaction"]] = relationship(back_populates="category")
    budgets: Mapped[list["Budget"]] = relationship(back_populates="category")
    budget_history: Mapped[list["BudgetHistory"]] = relationship(
        back_populates="category"
    )

    def __repr__(self) -> str:
        return f"<Category {self.id} {self.name!r}>"


# ── Account ───────────────────────────────────────────────────────────────

class Account(Base):
    __tablename__ = "accounts"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id"), index=True)
    name: Mapped[str] = mapped_column(String(80), index=True)
    type: Mapped[str] = mapped_column(String(40))
    masked_number: Mapped[str] = mapped_column(String(32))
    created_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)

    user: Mapped[User] = relationship(back_populates="accounts")
    transactions: Mapped[list["Transaction"]] = relationship(back_populates="account")

    def __repr__(self) -> str:
        return f"<Account {self.id} {self.name!r}>"


# ── Transaction ───────────────────────────────────────────────────────────

class Transaction(Base):
    __tablename__ = "transactions"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id"), index=True)
    household_id: Mapped[str | None] = mapped_column(
        ForeignKey("households.id"), index=True, nullable=True
    )
    amount: Mapped[int] = mapped_column(Integer)
    category_id: Mapped[str] = mapped_column(ForeignKey("categories.id"), index=True)
    description: Mapped[str] = mapped_column(String(255))
    payment_method: Mapped[str] = mapped_column(String(48))
    account_id: Mapped[str] = mapped_column(ForeignKey("accounts.id"), index=True)
    date: Mapped[date] = mapped_column(Date, index=True, default=lambda: utcnow().date())
    reference_id: Mapped[str | None] = mapped_column(String(80), unique=True)
    receipt_url: Mapped[str | None] = mapped_column(String(512))
    created_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)

    user: Mapped[User] = relationship(back_populates="transactions")
    category: Mapped[Category] = relationship(back_populates="transactions")
    account: Mapped[Account] = relationship(back_populates="transactions")

    def __repr__(self) -> str:
        return f"<Transaction {self.id} {self.amount}>"


# ── Budget ────────────────────────────────────────────────────────────────

class Budget(Base):
    __tablename__ = "budgets"
    __table_args__ = (
        UniqueConstraint("user_id", "category_id", name="uq_user_budget_category"),
    )

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id"), index=True)
    household_id: Mapped[str | None] = mapped_column(
        ForeignKey("households.id"), index=True, nullable=True
    )
    category_id: Mapped[str] = mapped_column(ForeignKey("categories.id"), index=True)
    monthly_limit: Mapped[int] = mapped_column(Integer)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)

    user: Mapped[User] = relationship(back_populates="budgets")
    category: Mapped[Category] = relationship(back_populates="budgets")

    def __repr__(self) -> str:
        return f"<Budget {self.id} limit={self.monthly_limit}>"


# ── Budget History ────────────────────────────────────────────────────────

class BudgetHistory(Base):
    __tablename__ = "budget_history"
    __table_args__ = (
        UniqueConstraint(
            "user_id", "category_id", "month", "year",
            name="uq_user_budget_month_year",
        ),
    )

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id"), index=True)
    category_id: Mapped[str] = mapped_column(ForeignKey("categories.id"), index=True)
    spent_amount: Mapped[int] = mapped_column(Integer, default=0)
    month: Mapped[int] = mapped_column(Integer, index=True)
    year: Mapped[int] = mapped_column(Integer, index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)

    category: Mapped[Category] = relationship(back_populates="budget_history")

    def __repr__(self) -> str:
        return f"<BudgetHistory {self.category_id} {self.month}/{self.year}>"


# ── Profile ───────────────────────────────────────────────────────────────

class Profile(Base):
    __tablename__ = "profiles"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id"), index=True)
    name: Mapped[str] = mapped_column(String(120), default="My Household")
    monthly_income: Mapped[int] = mapped_column(Integer, default=0)
    currency: Mapped[str] = mapped_column(String(8), default="INR")
    household_members: Mapped[int] = mapped_column(Integer, default=1)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime,
        default=utcnow,
        onupdate=utcnow,
    )

    user: Mapped[User] = relationship(back_populates="profiles")

    def __repr__(self) -> str:
        return f"<Profile {self.id} {self.name!r}>"
