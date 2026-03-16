"""Authentication routes — Google Sign-In."""
from __future__ import annotations

import logging

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.auth.google_verify import verify_google_token
from app.auth.jwt_handler import create_access_token
from app.database.database import get_db
from app.database.models import User
from app.database.seed_data import seed_user_defaults
from app.schemas.auth_schema import AuthResponse, GoogleLoginRequest, UserResponse
from app.utils.id_generator import generate_id

logger = logging.getLogger(__name__)

router = APIRouter(tags=["Auth"])


@router.post("/auth/google", response_model=AuthResponse)
def google_login(payload: GoogleLoginRequest, session: Session = Depends(get_db)):
    """Authenticate with a Google ID token.

    Verifies the token, creates a new user if necessary, and returns a JWT.
    """
    try:
        google_info = verify_google_token(payload.id_token)
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid Google token: {exc}",
        )

    user = session.scalar(
        select(User).where(User.google_id == google_info["sub"])
    )

    if user is None:
        user = User(
            id=generate_id("USR"),
            google_id=google_info["sub"],
            email=google_info["email"],
            name=google_info["name"],
            picture_url=google_info.get("picture"),
        )
        session.add(user)
        session.commit()
        session.refresh(user)
        # Seed default categories, accounts, budgets, and profile for the new user
        seed_user_defaults(session, user.id)
        logger.info("Created new user %s (%s)", user.id, user.email)
    else:
        # Update name / picture if changed on the Google side
        user.name = google_info["name"]
        user.picture_url = google_info.get("picture")
        session.commit()

    access_token = create_access_token(user.id)
    return AuthResponse(
        access_token=access_token,
        user=UserResponse(
            id=user.id,
            email=user.email,
            name=user.name,
            picture_url=user.picture_url,
            created_at=user.created_at,
        ),
    )
