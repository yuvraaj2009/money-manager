"""Pydantic models for authentication endpoints."""
from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel


class GoogleLoginRequest(BaseModel):
    id_token: str


class UserResponse(BaseModel):
    id: str
    email: str
    name: str
    picture_url: str | None = None
    created_at: datetime


class AuthResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse
