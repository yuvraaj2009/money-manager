"""FastAPI dependencies for authentication."""
from __future__ import annotations

import logging

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from app.auth.jwt_handler import decode_access_token
from app.database.database import get_db
from app.database.models import User

logger = logging.getLogger(__name__)

_bearer_scheme = HTTPBearer(auto_error=False)


def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(_bearer_scheme),
    session: Session = Depends(get_db),
) -> User:
    """Extract and validate a Bearer JWT, returning the corresponding User.

    Raises 401 if the token is missing, invalid, or the user no longer exists.
    """
    if credentials is None:
        logger.warning("Auth failed: no Authorization header provided")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication required.",
        )

    token_preview = credentials.credentials[:20] + "..." if len(credentials.credentials) > 20 else credentials.credentials
    logger.info("Auth: decoding token starting with %s", token_preview)

    user_id = decode_access_token(credentials.credentials)
    if user_id is None:
        logger.warning("Auth failed: token decode returned None (invalid/expired)")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token.",
        )

    logger.info("Auth: token decoded, user_id=%s", user_id)
    user = session.get(User, user_id)
    if user is None:
        logger.warning("Auth failed: user_id=%s not found in database", user_id)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User account not found.",
        )
    logger.info("Auth: authenticated user %s (%s)", user.id, user.email)
    return user
