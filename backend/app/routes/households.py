"""Household management routes."""
from __future__ import annotations

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.auth.dependencies import get_current_user
from app.crud.household_crud import (
    create_household,
    get_household_members,
    join_household,
    leave_household,
    list_user_households,
)
from app.database.database import get_db
from app.database.models import User
from app.schemas.household_schema import (
    HouseholdCreate,
    HouseholdJoinRequest,
    HouseholdMemberResponse,
    HouseholdResponse,
)

router = APIRouter(tags=["Households"])


@router.post("/households", response_model=HouseholdResponse, status_code=status.HTTP_201_CREATED)
def create_household_route(
    payload: HouseholdCreate,
    session: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return create_household(session, payload.name, current_user.id)


@router.get("/households", response_model=list[HouseholdResponse])
def list_households(
    session: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return list_user_households(session, current_user.id)


@router.post("/households/join", response_model=HouseholdResponse)
def join_household_route(
    payload: HouseholdJoinRequest,
    session: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return join_household(session, payload.invite_code, current_user.id)


@router.get("/households/{household_id}/members", response_model=list[HouseholdMemberResponse])
def get_members(
    household_id: str,
    session: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return get_household_members(session, household_id, current_user.id)


@router.delete("/households/{household_id}/leave", status_code=status.HTTP_204_NO_CONTENT)
def leave_household_route(
    household_id: str,
    session: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    leave_household(session, household_id, current_user.id)
