# Couture finish, Blue Rose and Blue Lotus (2026-10-02)

A finishing pass over every look, plus two new looks. All of it lives in the
Flutter app; nothing changed on the server (the look is still stored in
`settings.theme` as `mode:preset`).

## The finish (`app/lib/core/theme/couture.dart`)

Each `ThemePreset` now carries two more colours:

| Field   | What it is | Example (Rose) |
|---------|------------|----------------|
| `jewel` | The second hue a primary action rolls into | champagne gold |
| `trim`  | The metal of the look's hairlines | pale gold |

What that changes, in every look:

- **Primary buttons** (`FilledButton`, `ElevatedButton`, `GlassButton`) are a
  gradient from `primary` to `jewel`, with a trim hairline and a coloured
  glow underneath. A Rose button is rose-gold, not flat pink.
- **Floating action button, tab indicator, slider thumb** wear the `jewel`.
- **Chosen chips** wear the look's *second* accent (`secondaryTint`).
- **Outlined buttons** are edged in the trim.
- **Cards, panels, dialogs, nav tiles** get a bevelled hairline (trim at the
  top-left, fading to the quiet rule) and a soft lift; dark looks also get a
  satin fill.
- **Eyebrows** are preceded by a short gradient rule.
- **Tab bar**: the selected destination sits in a small jewel pill.

Rules the finish keeps:

- A button whose call site chose its own fill (a destructive red) or that is
  disabled is never repainted.
- Depth never costs contrast: light looks keep flat white paper, white-label
  buttons are shaded toward the foot rather than glossed, and translucent
  panels cast no shadow.
- Calm keeps the sharp hairlines but stays one accent, flat and still.
- With no look on the theme (bare `ThemeData` in tests) every shared widget
  draws exactly as before.

## New looks

| Id          | Label      | Palette | Backdrop | Reward burst |
|-------------|------------|---------|----------|--------------|
| `bluerose`  | Blue Rose  | Midnight navy, sapphire, frost pink, platinum trim | Blue roses in the corners, ice-edged petals falling | Sapphire roses |
| `bluelotus` | Blue Lotus | Indigo water, periwinkle, lilac, gold trim | A moonlit pond from above: lily pads, two blooms, slow ripples, gold pollen | Lotus blooms |

Both are dark, meet WCAG AA on every surface, and sit after Rose in the
Settings strip.

## Adding a look from here

`jewel` and `trim` are required. `test/features/theme/couture_test.dart`
fails a look whose button label does not read across the whole gradient, or
whose `jewel` is the same hue as its `primary` (unless it is a
reduced-motion look).

## Open items

- The translated taglines for the two new looks (`themeTaglineBluerose`,
  `themeTaglineBluelotus`) ship with the localization pass, not this change.
- The Discover golden images were already stale before this change and still
  need regenerating.
