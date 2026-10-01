# Snow and Gothic looks, and theme-aware reward bursts (2026-10-01)

Two new looks join Settings → Theme, and every reward or achievement now plays a short burst drawn in the
member's look: snowflakes for Snow, roses for Rose and Petal, bats and embers for Gothic, and confetti in the
look's own colours for everything else.

## The looks

Both are in `ThemePresets.themed` (`app/lib/core/theme/theme_presets.dart`), so they appear in the Settings
strip with a preview card (each themed preview card now paints its look's atmosphere behind the miniature
page) and get the "Now showing" title card when chosen. They are stored as `mode:snow` / `mode:gothic`.

| Look | id | Brightness | Palette | Display face |
|---|---|---|---|---|
| Snow | `snow` | light | frosted ice-white ground `#EEF4FA`, snow-white paper, deep winter-navy ink `#0F2138`, glacier-blue primary `#1F5F99`, frost-blue secondary, aurora-green tertiary | Bodoni Moda (bundled) |
| Gothic | `gothic` | dark | near-black velvet ground `#0B0810`, bone ink `#F2EBE3`, garnet crimson primary `#EC5577`, amethyst secondary, antique-gold tertiary | Bodoni Moda (bundled) |

Contrast: ink on ground, paper and sunk paper is at least 13.9:1 (AAA). Muted and faint ink, and all three
accents used as text, are at least 4.5:1 (AA) on every surface; button labels on the primary fill and
accents on their tints are at least 4.5:1. Snow's body contrast stays below Calm's, which remains the
highest-contrast light look. `test/features/theme/snow_gothic_presets_test.dart` checks all of this.

### Atmosphere scenes (`app/lib/core/theme/theme_atmosphere.dart`)

Static, seeded, low-alpha and pointer-transparent like the other scenes.

- **Snow**: a moon behind thin cloud, two soft aurora ribbons with uneven curtain rays, frost ferns creeping
  in from the top corners, three depths of snow (fine dust, crisp small crystals, large out-of-focus
  crystals with a white core over a glacier-blue halo), and three drifts along the bottom with glints on
  their crests.
- **Gothic**: a full moon with bats crossing it, a cathedral rose window's tracery in antique gold (twelve
  lancet petals with trefoil eyes, roundels, a sexfoil heart, garnet and amethyst stained-glass tints), a
  spired skyline against a garnet horizon with a few lit windows, low fog, and three candles.

Shared vector motifs (snow crystal, bat with a wing-flap parameter, petal, rose bloom with a furled heart)
live in `app/lib/core/theme/theme_motifs.dart`.

## Reward bursts

`app/lib/features/celebrations/reward_burst.dart`

| Look | Burst |
|---|---|
| Snow | a frost ring blooms out, snow crystals and glints radiate, twinkle and drift down |
| Rose, Petal | whole roses spin out with loose petals and a few leaves, then tumble and fall |
| Gothic | a pale moon swells, bats spiral outward beating their wings, crimson embers and gold candle sparks rise |
| Every other look | confetti in the look's primary, secondary, tertiary and swatch colours |

A small card at the top names the reward ("Chapter published", "3 new rewards", "Level 4 reached",
"Badge earned", "Reward claimed"), shows a "+N XP" pill and up to four detail lines. It does not block the
screen, closes itself after 6 seconds (12 with a screen reader), can be swiped up, and has a 48pt Close
button. Bursts queue, so two never overlap.

Public API for other features: `showRewardBurst(context, RewardBurst(...))`, drawn in the root overlay above
every route.

### What triggers a burst

`RewardBurstHost` (`reward_burst_host.dart`) is mounted once in the signed-in shell next to `RoseRainHost`.

1. **New XP ledger entries**: checked when the shell mounts, whenever the app returns to the foreground, every
   60 seconds while the app is in the foreground, and whenever the Level & XP provider loads (opening the
   Level & XP screen, pull to refresh, the reload after a claim). One entry plays as its own reward; several
   are grouped into one summary.
2. **Level-ups**: the current level rose since the last look. The level-up leads the card and carries the
   XP and badges that arrived with it.
3. **Claiming a level reward**: `claimReward` success on the Level & XP screen (replaces the old
   "Reward claimed." snackbar).
4. **Newly earned trust badges**: an active badge code never celebrated before.
5. **Wall tiers and Cover of the Week**: the existing rose rain card now follows the look: Snow gets snow,
   Gothic gets bats and embers, Rose and Petal get the rose burst on top of the petal rain, and every other
   look keeps the classic petal rain. The XP these two award (`wall_tier_reached`, `cover_of_week`) is not
   announced again as an XP burst.

### Rules

- What was celebrated is remembered per signed-in member in shared preferences
  (`reward_burst.seen.v1.<userId>`: highest ledger sequence, level, every badge code celebrated). It is saved
  before the burst plays, so nothing replays, even if the app closes mid-burst.
- First look on a device (fresh install, new member): the current ledger, level and badges become the
  baseline. At most one summary plays ("Your rewards today") for XP earned in the last 24 hours; older
  history is never celebrated.
- Clawbacks (negative XP) and a lower level after a review update the baseline silently. A badge that lapses
  and returns does not play again.
- A part that fails to load (progression, ledger or badges) is left untouched: no reset, no replay.
- Reduced motion (the platform setting or the Calm look) shows the card with no particles and no haptic.
  Particles ignore pointers and are excluded from semantics; the card is a live region.

## Tests

- `test/features/theme/snow_gothic_presets_test.dart`: presets selectable, AA contrast on every surface,
  bundled display face, atmosphere and title card paint.
- `test/features/celebrations/reward_ledger_test.dart`: diffing (baseline, 24-hour summary, once only,
  grouping, clawbacks and wall-tier XP skipped, level-up, badges, failed parts) and per-member storage.
- `test/features/celebrations/reward_burst_test.dart`: style per look, every style paints, reduced motion and
  Calm show no particles, accessible card, queueing, wall celebration per look, and the host celebrating new
  XP once without replaying across polls or relaunches.
