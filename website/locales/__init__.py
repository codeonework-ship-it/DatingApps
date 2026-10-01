"""Website copy, one module per locale.

`en` (en-US) is the source; every other module must define the same
STRINGS keys and a FEATURES list of the same length and order. The
generator (`generate_pages.py`) checks both and refuses to build a locale
that drifts.

URL prefix → module. The default locale lives at the site root; the others
under `/<prefix>/`.
"""

LOCALES = [
    ("", "en"),
    ("en-gb", "en_gb"),
    ("de", "de"),
    ("fr", "fr"),
    ("ru", "ru"),
    ("es", "es"),
    ("it", "it"),
    ("pt", "pt"),
    ("nl", "nl"),
    ("pl", "pl"),
]
