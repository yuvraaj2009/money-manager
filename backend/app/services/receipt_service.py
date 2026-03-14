from __future__ import annotations

from pathlib import Path
from urllib.parse import urlparse


def build_receipt_filename(reference_id: str | None, receipt_url: str | None) -> str:
    suffix = "jpg"
    if receipt_url:
        parsed = urlparse(receipt_url)
        path_suffix = Path(parsed.path).suffix.lstrip(".")
        if path_suffix:
            suffix = path_suffix
    token = (reference_id or "receipt").lower().replace("#", "").replace(" ", "-")
    return f"{token}.{suffix}"


def get_receipt_metadata(reference_id: str | None, receipt_url: str | None) -> dict[str, str] | None:
    if not receipt_url:
        return None

    return {
        "url": receipt_url,
        "filename": build_receipt_filename(reference_id, receipt_url),
        "status": "ready",
    }


def extract_receipt_text(receipt_url: str) -> dict[str, str]:
    return {
        "status": "pending",
        "message": "OCR extraction has not been implemented yet.",
        "source": receipt_url,
    }
