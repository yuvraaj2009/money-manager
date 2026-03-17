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
    categories = session.scalars(select(Category).where(Category.user_id == user_id)).all()
    accounts = session.scalars(select(Account).where(Account.user_id == user_id)).all()
    budgets = session.scalars(select(Budget).where(Budget.user_id == user_id)).all()
    profile = session.scalar(select(Profile).where(Profile.user_id == user_id).limit(1))
    transactions = session.scalars(select(Transaction).where(Transaction.user_id == user_id)).all()

    result["step_4_user_has_data"] = len(categories) > 0
    result["data_counts"] = {
        "categories": len(categories),
        "accounts": len(accounts),
        "budgets": len(budgets),
        "transactions": len(transactions),
        "has_profile": profile is not None,
    }

    if len(categories) == 0:
        result["warning"] = "User has no categories — seed_user_defaults may have failed during signup."

    return result


@router.post("/reseed/{user_id}")
def debug_reseed(user_id: str, session: Session = Depends(get_db)):
    """Re-run seed_user_defaults for a user who is missing default data."""
    user = session.get(User, user_id)
    if user is None:
        return {"error": f"User {user_id} not found"}

    # Check if already has data
    categories = session.scalars(select(Category).where(Category.user_id == user_id)).all()
    if len(categories) > 0:
        return {"message": f"User already has {len(categories)} categories, skipping reseed"}

    from app.database.seed_data import seed_user_defaults
    try:
        seed_user_defaults(session, user_id)
        return {"message": f"Successfully reseeded defaults for user {user_id}"}
    except Exception as e:
        logger.exception("Reseed failed for user %s", user_id)
        return {"error": f"Reseed failed: {type(e).__name__}: {e}"}
