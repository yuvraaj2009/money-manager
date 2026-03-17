from __future__ import annotations

from pathlib import Path

from fastapi import APIRouter, HTTPException, status
from fastapi.responses import FileResponse

from app.config import get_settings
from app.schemas.version_schema import VersionResponse

router = APIRouter(tags=["Version"])

settings = get_settings()
_STATIC_APK_DIR = Path.cwd() / "static" / "apk"


@router.get("/version", response_model=VersionResponse)
def get_version():
    """Return current API version, minimum required version, and APK download info."""
    return VersionResponse(
        version=settings.app_version,
        min_app_version=settings.min_app_version,
        latest_app_version=settings.latest_app_version,
        apk_url="/download/apk",
        update_url=settings.update_url,
        message=settings.update_message,
    )


@router.get("/download/apk")
def download_apk():
    """Serve the latest APK file for direct download."""
    apk_path = _STATIC_APK_DIR / settings.apk_filename
    if not apk_path.is_file():
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="APK file not available. Please try again later.",
        )
    return FileResponse(
        path=str(apk_path),
        media_type="application/vnd.android.package-archive",
        filename=settings.apk_filename,
    )
