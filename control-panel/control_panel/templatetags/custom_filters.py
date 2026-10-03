"""Custom Django template filters for the AegisConnect Control Panel."""

from __future__ import annotations

from django import template

register = template.Library()


@register.filter(name="replace")
def replace_filter(value: str, arg: str) -> str:
    """Replace occurrences of a substring in the given value.

    Usage: {{ value|replace:"old:new" }}
    The first character of *arg* is used as the separator between
    the search string and the replacement string.

    Examples:
        {{ "deep_dive"|replace:"_: " }}  →  "deep dive"
        {{ "hello_world"|replace:"_: " }}  →  "hello world"
    """
    if not arg or not isinstance(value, str):
        return value

    # Split on the first colon only – "old:new"
    parts = arg.split(":", 1) if ":" in arg else [arg, ""]
    old = parts[0]
    new = parts[1] if len(parts) > 1 else ""
    return value.replace(old, new)


@register.filter(name="isodate")
def isodate_filter(value):
    """Turn the BFF's ISO-8601 timestamp strings into datetimes for |date.

    Django's |date filter returns "" for a string, so every
    ``{{ x.created_at|date:"M d, Y" }}`` over JSON data rendered as "—".
    Usage: {{ item.created_at|isodate|date:"M d, Y"|default:"—" }}
    """
    from datetime import date, datetime, timezone

    if isinstance(value, (datetime, date)):
        return value
    raw = str(value or "").strip()
    if not raw:
        return ""
    try:
        parsed = datetime.fromisoformat(raw.replace("Z", "+00:00"))
    except ValueError:
        return ""
    return parsed if parsed.tzinfo else parsed.replace(tzinfo=timezone.utc)


@register.filter(name="thousands")
def thousands_filter(value):
    """4961582 -> "4,961,582"; anything that is not a whole number is returned as is."""
    try:
        return f"{int(value):,}"
    except (TypeError, ValueError):
        return value


@register.filter(name="bytes")
def bytes_filter(value):
    """5368709120 -> "5.0 GB"; non-numbers are returned as is."""
    try:
        size = float(value)
    except (TypeError, ValueError):
        return value
    for unit in ("B", "KB", "MB", "GB", "TB"):
        if abs(size) < 1024 or unit == "TB":
            return f"{size:.0f} {unit}" if unit == "B" else f"{size:.1f} {unit}"
        size /= 1024
    return value
