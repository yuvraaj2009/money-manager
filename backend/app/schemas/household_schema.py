"""Pydantic models for household endpoints."""
from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, Field


class HouseholdCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=120)


class HouseholdJoinRequest(BaseModel):
    invite_code: str = Field(..., min_length=1, max_length=16)


class HouseholdMemberResponse(BaseModel):
    id: str
    user_id: str
    user_name: str
    user_email: str
    role: str
    joined_at: datetime


class HouseholdResponse(BaseModel):
    id: str
    name: str
    invite_code: str
    created_by: str
    created_at: datetime
    members: list[HouseholdMemberResponse] = []
