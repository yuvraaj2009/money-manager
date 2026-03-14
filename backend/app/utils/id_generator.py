from __future__ import annotations

from datetime import datetime
from uuid import uuid4


def generate_id(prefix: str) -> str:
    return f"{prefix}-{uuid4().hex[:10].upper()}"


def generate_reference_id(prefix: str = "TRX") -> str:
    timestamp = datetime.utcnow().strftime("%y%m%d%H%M%S")
    return f"{prefix}-{timestamp}-{uuid4().hex[:4].upper()}"
