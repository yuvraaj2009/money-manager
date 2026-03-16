"""JWT creation and validation."""
from __future__ import annotations

from datetime import datetime, timedelta

from jose import JWTError, jwt

from app.config import get_settings

ALGORITHM = "HS256"
TOKEN_TTL_DAYS = 30


def create_access_token(user_id: str) -> str:
    """Create a signed JWT containing the user id."""
    settings = get_settings()
    expire = datetime.utcnow() + timedelta(days=TOKEN_TTL_DAYS)
    payload = {"sub": user_id, "exp": expire}
    return jwt.encode(payload, settings.jwt_secret, algorithm=ALGORITHM)


def decode_access_token(token: str) -> str | None:
    """Return the user_id from a JWT, or *None* if invalid / expired."""
    settings = get_settings()
    try:
        payload = jwt.decode(token, settings.jwt_secret, algorithms=[ALGORITHM])
        return payload.get("sub")
    except JWTError:
        return None
