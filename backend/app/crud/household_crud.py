"""CRUD operations for household management."""
from __future__ import annotations

import secrets

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.database.models import Household, HouseholdMember
from app.schemas.household_schema import HouseholdMemberResponse, HouseholdResponse
from app.utils.id_generator import generate_id


def _generate_invite_code() -> str:
    """Generate a short, unique invite code."""
    return secrets.token_urlsafe(8)[:8].upper()


def _serialize_household(household: Household) -> HouseholdResponse:
    members = [
        HouseholdMemberResponse(
            id=m.id,
            user_id=m.user_id,
            user_name=m.user.name,
            user_email=m.user.email,
            role=m.role,
            joined_at=m.joined_at,
        )
        for m in household.members
    ]
    return HouseholdResponse(
        id=household.id,
        name=household.name,
        invite_code=household.invite_code,
        created_by=household.created_by,
        created_at=household.created_at,
        members=members,
    )


def create_household(session: Session, name: str, user_id: str) -> HouseholdResponse:
    """Create a new household and add the creator as owner."""
    household = Household(
        id=generate_id("HH"),
        name=name,
        invite_code=_generate_invite_code(),
        created_by=user_id,
    )
    session.add(household)
    session.flush()

    member = HouseholdMember(
        id=generate_id("HHM"),
        household_id=household.id,
        user_id=user_id,
        role="owner",
    )
    session.add(member)
    session.commit()

    return _load_household(session, household.id)


def list_user_households(session: Session, user_id: str) -> list[HouseholdResponse]:
    """List all households the user belongs to."""
    memberships = session.scalars(
        select(HouseholdMember).where(HouseholdMember.user_id == user_id)
    ).all()
    household_ids = [m.household_id for m in memberships]
    if not household_ids:
        return []

    households = session.scalars(
        select(Household)
        .where(Household.id.in_(household_ids))
        .options(selectinload(Household.members).selectinload(HouseholdMember.user))
    ).all()
    return [_serialize_household(h) for h in households]


def join_household(session: Session, invite_code: str, user_id: str) -> HouseholdResponse:
    """Join a household by invite code."""
    household = session.scalar(
        select(Household).where(Household.invite_code == invite_code)
    )
    if household is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Invalid invite code.",
        )

    existing = session.scalar(
        select(HouseholdMember).where(
            HouseholdMember.household_id == household.id,
            HouseholdMember.user_id == user_id,
        )
    )
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="You are already a member of this household.",
        )

    member = HouseholdMember(
        id=generate_id("HHM"),
        household_id=household.id,
        user_id=user_id,
        role="member",
    )
    session.add(member)
    session.commit()

    return _load_household(session, household.id)


def leave_household(session: Session, household_id: str, user_id: str) -> None:
    """Remove the user from a household."""
    member = session.scalar(
        select(HouseholdMember).where(
            HouseholdMember.household_id == household_id,
            HouseholdMember.user_id == user_id,
        )
    )
    if member is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="You are not a member of this household.",
        )
    session.delete(member)
    session.commit()


def get_household_members(session: Session, household_id: str, user_id: str) -> list[HouseholdMemberResponse]:
    """Get members of a household (only if the requester is a member)."""
    membership = session.scalar(
        select(HouseholdMember).where(
            HouseholdMember.household_id == household_id,
            HouseholdMember.user_id == user_id,
        )
    )
    if membership is None:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="You are not a member of this household.",
        )

    household = _load_household(session, household_id)
    return household.members


def _load_household(session: Session, household_id: str) -> HouseholdResponse:
    household = session.scalar(
        select(Household)
        .where(Household.id == household_id)
        .options(selectinload(Household.members).selectinload(HouseholdMember.user))
    )
    return _serialize_household(household)
