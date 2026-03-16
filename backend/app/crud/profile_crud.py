from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database.models import Profile
from app.schemas.profile_schema import ProfileCreate, ProfileResponse, ProfileUpdate
from app.utils.id_generator import generate_id


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


def get_or_create_profile(session: Session, user_id: str) -> ProfileResponse:
    """Get the user's profile, creating a default one if needed."""
    profile = session.scalar(
        select(Profile).where(Profile.user_id == user_id).limit(1)
    )
    if profile is None:
        profile = Profile(
            id=generate_id("PRF"),
            user_id=user_id,
            name="My Household",
            monthly_income=0,
            currency="INR",
            household_members=1,
        )
        session.add(profile)
        session.commit()
        session.refresh(profile)
    return _build_profile_response(profile)


def create_profile(session: Session, payload: ProfileCreate, user_id: str) -> ProfileResponse:
    """Create or update the user's profile."""
    profile = session.scalar(
        select(Profile).where(Profile.user_id == user_id).limit(1)
    )
    if profile is None:
        profile = Profile(id=generate_id("PRF"), user_id=user_id)
        session.add(profile)

    profile.name = payload.name.strip()
    profile.monthly_income = payload.monthly_income
    profile.currency = payload.currency.strip().upper() or "INR"
    profile.household_members = payload.household_members

    session.commit()
    session.refresh(profile)
    return _build_profile_response(profile)


def update_profile(session: Session, payload: ProfileUpdate, user_id: str) -> ProfileResponse:
    """Update the user's profile."""
    profile = session.scalar(
        select(Profile).where(Profile.user_id == user_id).limit(1)
    )
    if profile is None:
        profile = Profile(id=generate_id("PRF"), user_id=user_id)
        session.add(profile)

    profile.name = payload.name.strip()
    profile.monthly_income = payload.monthly_income
    profile.currency = payload.currency.strip().upper() or "INR"
    profile.household_members = payload.household_members

    session.commit()
    session.refresh(profile)
    return _build_profile_response(profile)
