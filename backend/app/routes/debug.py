"""Temporary debug endpoints for diagnosing production issues.

Remove this file once the issues are resolved.
"""
from __future__ import annotations

import logging

from fastapi import APIRouter, Depends
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy import select, text
from sqlalchemy.orm import Session

from app.auth.jwt_handler import decode_access_token
from app.config import get_settings
from app.database.database import get_db
from app.database.models import (
    Account,
    Budget,
    Category,
    Profile,
    Transaction,
    User,
)

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/debug", tags=["Debug"])

_bearer_scheme = HTTPBearer(auto_error=False)


@router.get("/config")
def debug_config():
    """Return non-sensitive configuration values to verify env vars are loaded."""
    settings = get_settings()
    return {
        "environment": settings.environment,
        "database_url_prefix": settings.database_url[:30] + "...",
        "google_client_id_set": bool(settings.google_client_id),
        "google_client_id_preview": settings.google_client_id[:20] + "..." if settings.google_client_id else "(empty)",
        "jwt_secret_is_default": settings.jwt_secret == "change-me-in-production",
        "cors_origins": settings.cors_origins,
        "min_app_version": settings.min_app_version,
        "latest_app_version": settings.latest_app_version,
    }


@router.get("/db")
def debug_db(session: Session = Depends(get_db)):
    """Check database connectivity and list table row counts."""
    try:
        tables = ["users", "categories", "accounts", "transactions", "budgets", "profiles", "budget_history"]
        counts = {}
        for table in tables:
            try:
                result = session.execute(text(f"SELECT COUNT(*) FROM {table}"))
                counts[table] = result.scalar()
            except Exception as e:
                counts[table] = f"ERROR: {e}"
        return {"status": "connected", "table_counts": counts}
    except Exception as e:
        return {"status": "error", "error": str(e)}


@router.get("/user")
def debug_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(_bearer_scheme),
    session: Session = Depends(get_db),
):
    """Debug the auth flow step by step — returns diagnostic info at each stage."""
    result: dict = {
        "step_1_token_present": False,
        "step_2_token_decoded": False,
        "step_3_user_exists": False,
        "step_4_user_has_data": False,
    }

    # Step 1: Is there a token?
    if credentials is None:
        result["error"] = "No Authorization header provided"
        return result
    result["step_1_token_present"] = True
    result["token_preview"] = credentials.credentials[:20] + "..."

    # Step 2: Can we decode it?
    user_id = decode_access_token(credentials.credentials)
    if user_id is None:
        result["error"] = "Token decode failed (invalid or expired JWT)"
        return result
    result["step_2_token_decoded"] = True
    result["user_id"] = user_id

    # Step 3: Does the user exist in DB?
    user = session.get(User, user_id)
    if user is None:
        result["error"] = f"User {user_id} not found in database"
        all_users = session.scalars(select(User)).all()
        result["existing_user_ids"] = [u.id for u in all_users]
        return result
    result["step_3_user_exists"] = True
    result["user"] = {
        "id": user.id,
        "email": user.email,
        "name": user.name,
        "created_at": str(user.created_at),
    }

    # Step 4: Does the user have seeded data?
    counts = _get_user_data_counts(session, user_id)
    result["step_4_user_has_data"] = counts["categories"] > 0
    result["data_counts"] = counts

    if counts["categories"] == 0:
        result["warning"] = "User has no categories — use POST /debug/fix-user/{user_id} to fix."

    return result


def _get_user_data_counts(session: Session, user_id: str) -> dict:
    """Return counts of all user data."""
    return {
        "categories": len(session.scalars(select(Category).where(Category.user_id == user_id)).all()),
        "accounts": len(session.scalars(select(Account).where(Account.user_id == user_id)).all()),
        "budgets": len(session.scalars(select(Budget).where(Budget.user_id == user_id)).all()),
        "has_profile": session.scalar(select(Profile).where(Profile.user_id == user_id).limit(1)) is not None,
        "transactions": len(session.scalars(select(Transaction).where(Transaction.user_id == user_id)).all()),
    }


@router.post("/fix-user/{user_id}")
def debug_fix_user(user_id: str, session: Session = Depends(get_db)):
    """Emergency fix: seed default data for a user who is missing it."""
    user = session.get(User, user_id)
    if user is None:
        all_users = session.scalars(select(User)).all()
        return {
            "error": f"User '{user_id}' not found in database",
            "existing_users": [{"id": u.id, "email": u.email, "name": u.name} for u in all_users],
        }

    before_counts = _get_user_data_counts(session, user_id)

    if before_counts["categories"] > 0:
        return {
            "message": f"User {user_id} already has data — no fix needed",
            "user": {"id": user.id, "email": user.email, "name": user.name},
            "data_counts": before_counts,
        }

    from app.database.seed_data import seed_user_defaults
    try:
        seed_user_defaults(session, user_id)
    except Exception as e:
        logger.exception("fix-user failed for %s", user_id)
        return {
            "error": f"Seeding failed: {type(e).__name__}: {e}",
            "user": {"id": user.id, "email": user.email},
        }

    after_counts = _get_user_data_counts(session, user_id)
    return {
        "message": f"Successfully seeded defaults for user {user_id}",
        "user": {"id": user.id, "email": user.email, "name": user.name},
        "before": before_counts,
        "after": after_counts,
    }


@router.post("/fix-all-users")
def debug_fix_all_users(session: Session = Depends(get_db)):
    """Emergency fix: seed default data for ALL users who are missing it."""
    all_users = session.scalars(select(User)).all()
    results = []
    from app.database.seed_data import ensure_user_defaults
    for user in all_users:
        try:
            seeded = ensure_user_defaults(session, user.id)
            results.append({
                "user_id": user.id,
                "email": user.email,
                "seeded": seeded,
            })
        except Exception as e:
            results.append({
                "user_id": user.id,
                "email": user.email,
                "error": f"{type(e).__name__}: {e}",
            })
    return {"users_processed": len(results), "results": results}
