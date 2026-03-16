"""Google ID-token verification."""
from __future__ import annotations

from google.auth.transport import requests as google_requests
from google.oauth2 import id_token

from app.config import get_settings


def verify_google_token(token: str) -> dict:
    """Verify a Google ID token and return the decoded payload.

    Returns a dict with keys: sub, email, name, picture (all strings).
    Raises ``ValueError`` if the token is invalid or the audience mismatches.
    """
    settings = get_settings()
    payload = id_token.verify_oauth2_token(
        token,
        google_requests.Request(),
        audience=settings.google_client_id,
    )
    return {
        "sub": payload["sub"],
        "email": payload.get("email", ""),
        "name": payload.get("name", ""),
        "picture": payload.get("picture", ""),
    }
