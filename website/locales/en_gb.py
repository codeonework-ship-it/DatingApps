"""en-GB: the en-US copy with British spelling. Wording is identical.

Derived from `en` at import time so the two can never drift apart in
substance; only the spellings listed below differ.
"""

from . import en

LANG = "en-GB"
HREFLANG = "en-GB"
NATIVE_NAME = "English (UK)"

# Whole-word, case-preserving spelling swaps (US → GB).
_SPELLING = {
    "favorite": "favourite",
    "center": "centre",
    "behavior": "behaviour",
    "catalog": "catalogue",
}


def _britishise(text):
    for us, gb in _SPELLING.items():
        text = text.replace(us, gb).replace(us.capitalize(), gb.capitalize())
    return text


STRINGS = {key: _britishise(value) for key, value in en.STRINGS.items()}

FEATURES = [
    (path, _britishise(name), _britishise(desc), icon, badge)
    for path, name, desc, icon, badge in en.FEATURES
]
