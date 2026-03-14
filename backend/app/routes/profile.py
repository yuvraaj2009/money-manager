from __future__ import annotations

from datetime import datetime

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.crud.profile_crud import create_profile, get_or_create_profile, update_profile
from app.database.database import get_db
from app.schemas.profile_schema import ProfileCreate, ProfileResponse, ProfileUpdate

router = APIRouter(tags=["Profile"])


@router.get("/profile", response_model=ProfileResponse)
def get_profile(session: Session = Depends(get_db)):
    return get_or_create_profile(session)


@router.post("/profile", response_model=ProfileResponse, status_code=status.HTTP_201_CREATED)
def create_profile_route(payload: ProfileCreate, session: Session = Depends(get_db)):
    return create_profile(session, payload)


@router.put("/profile", response_model=ProfileResponse)
def update_profile_route(payload: ProfileUpdate, session: Session = Depends(get_db)):
    return update_profile(session, payload)
