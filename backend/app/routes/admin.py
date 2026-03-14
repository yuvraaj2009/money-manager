from __future__ import annotations

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database.database import get_db
from app.schemas.admin_schema import AdminResetResponse
from utils.db_reset import reset_household_data

router = APIRouter(tags=["Admin"])


@router.post("/admin/reset", response_model=AdminResetResponse)
def admin_reset(session: Session = Depends(get_db)):
    return reset_household_data(session)
