from __future__ import annotations

from pydantic import BaseModel


class VersionResponse(BaseModel):
    """Schema for the GET /version endpoint."""

    version: str
    min_app_version: str
    latest_app_version: str
    apk_url: str
    update_url: str
    message: str
