from __future__ import annotations

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.auth.dependencies import get_current_user
from app.crud.profile_crud import create_profile, get_or_create_profile, update_profile
from app.database.database import get_db
from app.database.models import User
from app.schemas.profile_schema import ProfileCreate, ProfileResponse, ProfileUpdate

router = APIRouter(tags=["Profile"])


@router.get("/profile", response_model=ProfileResponse)
def get_profile(
    session: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return get_or_create_profile(session, current_user.id)


@router.post("/profile", response_model=ProfileResponse, status_code=status.HTTP_201_CREATED)
def create_profile_route(
    payload: ProfileCreate,
    session: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return create_profile(session, payload, current_user.id)


@router.put("/profile", response_model=ProfileResponse)
def update_profile_route(
    payload: ProfileUpdate,
    session: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return update_profile(session, payload, current_user.id)
