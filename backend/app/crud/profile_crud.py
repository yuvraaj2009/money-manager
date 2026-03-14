from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database.models import Profile
from app.schemas.profile_schema import ProfileCreate, ProfileResponse, ProfileUpdate

DEFAULT_PROFILE_ID = "profile_primary"


def _build_profile_response(profile: Profile) -> ProfileResponse:
    return ProfileResponse(
        id=profile.id,
        name=profile.name,
        monthly_income=profile.monthly_income,
        monthly_income_rupees=profile.monthly_income / 100,
        currency=profile.currency,
        household_members=profile.household_members,
        created_at=profile.created_at,
        updated_at=profile.updated_at,
    )


def get_or_create_profile(session: Session) -> ProfileResponse:
    profile = session.scalar(select(Profile).limit(1))
    if profile is None:
        profile = Profile(
            id=DEFAULT_PROFILE_ID,
            name="My Household",
            monthly_income=0,
            currency="INR",
            household_members=2,
        )
        session.add(profile)
        session.commit()
        session.refresh(profile)
    return _build_profile_response(profile)


def create_profile(session: Session, payload: ProfileCreate) -> ProfileResponse:
    profile = session.scalar(select(Profile).limit(1))
    if profile is None:
        profile = Profile(id=DEFAULT_PROFILE_ID)
        session.add(profile)

    profile.name = payload.name.strip()
    profile.monthly_income = payload.monthly_income
    profile.currency = payload.currency.strip().upper() or "INR"
    profile.household_members = payload.household_members

    session.commit()
    session.refresh(profile)
    return _build_profile_response(profile)


def update_profile(session: Session, payload: ProfileUpdate) -> ProfileResponse:
    profile = session.scalar(select(Profile).limit(1))
    if profile is None:
        profile = Profile(id=DEFAULT_PROFILE_ID)
        session.add(profile)

    profile.name = payload.name.strip()
    profile.monthly_income = payload.monthly_income
    profile.currency = payload.currency.strip().upper() or "INR"
    profile.household_members = payload.household_members

    session.commit()
    session.refresh(profile)
    return _build_profile_response(profile)
