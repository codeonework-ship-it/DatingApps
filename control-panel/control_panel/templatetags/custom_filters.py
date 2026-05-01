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
