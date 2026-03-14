from __future__ import annotations

from decimal import Decimal, InvalidOperation, ROUND_HALF_UP


def rupees_to_paise(amount: str | int | float | Decimal) -> int:
    try:
        decimal_amount = Decimal(str(amount).replace(",", ""))
    except InvalidOperation as exc:
        raise ValueError("Invalid currency amount.") from exc

    return int((decimal_amount * Decimal("100")).quantize(Decimal("1"), rounding=ROUND_HALF_UP))


def paise_to_rupees(amount: int) -> float:
    return round(amount / 100, 2)


def format_inr(amount: int) -> str:
    sign = "-" if amount < 0 else ""
    absolute = abs(amount)
    return f"{sign}₹{absolute / 100:,.2f}"
