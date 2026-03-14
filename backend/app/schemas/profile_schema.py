from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, ConfigDict


class ProfileBase(BaseModel):
    name: str
    monthly_income: int
    currency: str = "INR"
    household_members: int


class ProfileCreate(ProfileBase):
    pass


class ProfileUpdate(ProfileBase):
    pass


class ProfileResponse(ProfileBase):
    id: str
    monthly_income_rupees: float
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
