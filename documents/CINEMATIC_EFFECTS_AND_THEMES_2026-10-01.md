# Cinematic effects and themes (2026-10-01)

The owner asked for "cinematic style effects and themes". This pass turns the
opt-in looks into moving film sets, gives the whole app one motion language
(page cuts, tab cuts, title cards, reward bursts) and keeps the everyday Today
look calm. Everything honours reduced motion.

## Three levels of cinema

`CinematicLevel.of(context)` (`lib/core/theme/cinematic_motion.dart`) decides
how much any effect does:

| Level    | When                                                                 | What you get |
|----------|----------------------------------------------------------------------|--------------|
| `still`  | Platform reduce-motion, or the Calm look (`AppTheme.reduceMotionOf`) | No motion, no flashes, scenes hold a still frame (Calm paints no scene at all), pages simply appear |
| `subtle` | Everyday looks: Today, Today evening, Daylight, Ember                | The quiet fade-and-rise page transition and a short tab fade. No atmosphere, grain, glow or sheen |
| `full`   | Cinematic looks: Forge, Neon Grid, Crimson Alloy, Circuit, Deep Field, Love, Rose, Petal, Snow, Gothic | Animated scenes, film layer, depth cuts, sheen, glow, parallax, blooms |

The web app is locked to the Today palette, so it only ever sees `subtle`.

## Scenes per look (`lib/core/theme/theme_atmosphere.dart`)

Each scene is three layers: a **back plate** (cached `ui.Picture`), a **motion
layer** painted from the shared clock, and a **front plate** (cached), plus
film grain on the dark looks.

| Look | Back plate (still) | Motion | Front / film |
|------|--------------------|--------|--------------|
| Forge | Brushed chrome streaks, furnace red and steel blue blooms, hex plate | Furnace bloom breathing (6 s), 26 embers rising and swaying, a chrome light sweep every 9 s, a faint arc across the hex plate for 0.2 s every 11 s (a thin line, never a frame flash) | Vignette, grain |
| Neon Grid | Amber sun, converging floor lines | Floor lines roll toward the camera, horizon glow with a neon stutter (two dips in 0.34 s every 5.3 s), the sun breathes, a CRT scan band rolls down every 7 s | Scanlines (one repeated-gradient draw), vignette, grain |
| Crimson Alloy | Crimson vignette blooms, core rings | Core spokes turn (48 s/rev), three ripples expand from the core, the core breathes, 14 gold sparks orbit, a lacquer sweep every 11 s | Vignette, grain |
| Circuit | Traces and solder nodes, violet bloom | Signals race along 12 traces with short trails; the end node blooms as a signal lands; slow scan band | Scanlines, vignette, grain |
| Deep Field | Plasma blooms, radial streaks, orbit glow | 96 stars at three depths drifting out from the centre (a slow dolly; near stars faster and larger), bright stars twinkle, a shooting star every 9.5 s | Vignette, grain |
| Love | Blush and rose blooms | 16 bokeh discs rise slowly and breathe, gold sparkle twinkles | Soft vignette in the look's own accent |
| Rose | Velvet blooms, two rose blooms in the corners | 14 petals tumble down, turning over in depth; gold glints twinkle | Vignette, grain |
| Petal | Blush and sage blooms | 24 petals and sage leaves fall on a gentle diagonal, turning over | Soft vignette in the look's own accent |
| Snow | Moon behind cloud, frost ferns | Aurora sways with light running along it, snow at three depths (fine dust, turning crystals, big soft near flakes) | Snow drifts, glints on the crests catch the light, soft vignette |
| Gothic | Moon, rose-window tracery, spired skyline, candle sticks | Bats circle the moon beating their wings, lit windows waver, fog rolls along the ground (seamless loop), candle flames flicker (three slow sines, fastest 2.2 Hz), sparks rise from the candles | Vignette, grain |

The film layer only sits on the **backdrop**, never over content: grain and
vignette are painted behind cards and text, so text contrast is unchanged.

## One shared clock (`lib/core/theme/cinematic_clock.dart`)

* **One `Ticker`** drives every ambient effect (scenes, button sheen, glow
  pulses). Ten things moving on screen cost one frame callback.
* **30 fps budget**: after each tick the ticker is muted (a muted ticker
  schedules no frames) and a short timer unmutes it for the next vsync, so a
  screen whose only motion is ambient renders 30 frames a second, not 60/120.
* It runs only while something **visible** is subscribed:
  * routes covered by an opaque route are offstage, and `Overlay` turns their
    `TickerMode` off; effects unsubscribe through `TickerMode`;
  * hidden bottom-navigation tabs are wrapped in `TickerMode(enabled: false)`
    by `CinematicTabStack`;
  * reduced motion (`AppTheme.reduceMotionOf`) never subscribes;
  * the theme picker's eleven chip previews pass `ambient: false` (still
    frames).
* It **pauses in the background** (paused, hidden, detached) and keeps
  running while `inactive` (a system sheet over the app is still on screen).
  Time freezes while stopped and resumes from the same value: no jump.
* It is **off under `flutter test`** (`FLUTTER_TEST` is set), so existing
  `pumpAndSettle` tests still settle. Clock tests switch it on.

## Performance measures

* Static layers are recorded once per look and size into a `ui.Picture` (LRU
  of 40) and replayed with one draw call. Only the motion layer is drawn per
  frame.
* Particle caps: at most 96 stars (Deep Field), 95 snow particles across three
  depths, 26 embers, 24 petals, 16 bokeh discs, 12 circuit pulses.
* No per-frame blur: blurred elements (aurora, fog) are cached pictures that
  are translated; near snowflakes use a wide low-alpha halo stroke instead of
  a mask blur. Snowflake and petal paths are cached; petal shading uses one
  unit-space shader per colour with the paint alpha.
* Grain is one cached field of specks (density scales with area, capped at
  3,200 per tone) re-seated at 12 Hz by offsetting it, drawn with two
  `drawRawPoints` calls when recorded.
* Scenes sit in a `RepaintBoundary` (`isComplex`, `willChange` while live),
  so a moving scene never repaints the page above it.
* Button sheen repaints only during the 1.1 s of each 7 s cycle when the band
  is on the button (the clock is gated per button).
* Parallax repaints only the photo's `Flow`, driven by the scroll position.

## Transitions

### Page cut (`CinematicPageTransitionsBuilder`)

Installed for every platform via `ThemeData.pageTransitionsTheme` (replacing
the old fade-and-rise builder).

* **Cinematic looks: depth cut** (420 ms). The incoming page fades up while
  the camera settles from 104% to 100% (`CinematicMotion.settle`, a
  fast-out, long-landing cubic). The page underneath sinks to 94% and dims to
  42% black. Popping plays it in reverse.
* **Everyday looks:** the existing quiet fade and 3.5% rise; nothing happens
  to the page underneath.
* **Reduced motion:** no animation.
* **Back still works.** Android back (button, gesture, `PopScope`, including
  the Matches/Engage/Profile/Settings → Today rule in
  `main_navigation_screen.dart`) goes through the navigator as before; the
  builder only decides how the pop looks. On **iOS/macOS** the page is wrapped
  in Cupertino's own transition (driven at rest, so it adds no motion) purely
  for its edge swipe-back detector, which the previous builder had lost;
  while a swipe is in progress both pages follow the finger linearly.
* The transition widget tree is **identical in every mode** (only the
  animations change), so switching looks, toggling reduce motion or starting
  a swipe never remounts a page or loses screen state.
* Android predictive back is not enabled in the manifest; if it is turned on
  later, back still pops (without the predictive peek).

### Tab cut (`CinematicTabStack`)

Replaces the `IndexedStack` in `MainNavigationScreen`. All tabs stay alive.
Hidden tabs get `TickerMode` off (their scenes and animations pause) and
`HeroMode` off (so future heroes can only fly from the visible tab). Switching
fades the new tab up from the ground; cinematic looks add a 4% slide in the
direction of travel and a 98.5% → 100% settle (360 ms); everyday looks fade
only (200 ms); reduced motion switches instantly.

### Theme switch as a scene change

`showThemeTitleCard` now plays a short scene change (1.7 s, then a 420 ms
dissolve):

1. Letterbox bars (11% of the height each) slide in.
2. "NOW SHOWING" and the look's name track in from wide letter-spacing out of
   a soft focus (blur 8 → 0), over the look's own moving atmosphere.
3. A light effect tuned to the look crosses the frame, fading in and out once:
   * Forge, Neon Grid, Crimson Alloy, Circuit, Deep Field: an **anamorphic
     streak** with a gliding hot spot and two lens ghosts;
   * Love, Rose, Petal: a **warm light leak** washing in from a corner;
   * Snow: a **frost glint** and a cool sheen;
   * Gothic: **candle glow** from below and a **moonbeam**.
4. The accent rule and tagline arrive; the card dissolves into the app.

Underneath, `MaterialApp.themeAnimationStyle` is now 450 ms ease-in-out, so
the palette **morphs** (ThemeData colours lerp) instead of cutting. Calm skips
the card; with platform reduce motion the card appears and leaves with no
motion, flare or fade. Sound-free.

## Micro-effects (`lib/core/theme/cinematic_effects.dart`)

* **Sheen on primary buttons** (`CinematicSheen`): cinematic looks only, via
  `ButtonStyle.backgroundBuilder` on Filled/Elevated buttons (a static
  tear-off, so theme data stays stable) and inside `GlassButton`. A soft white
  band glides over the fill, under the label, every 7 s. Off when disabled.
* **Glow pulse** (`CinematicGlowPulse`): a slow 2.4 s breathing glow for live
  indicators. Cinematic looks only; reduce motion gets a steady glow;
  everyday looks and Calm get none. The "here now" indicators live in
  `conversation_rooms_screen.dart`, which the chat stream owns; wrapping its
  live dot in `CinematicGlowPulse` is a one-line follow-up for that stream.
* **Parallax** (`CinematicParallax`): the Cover of the Week photo on Today sits
  deeper than its card and drifts against the scroll (8% travel in cinematic
  looks, a third of that in everyday looks, none under reduce motion). The
  photo is pre-scaled so no edge ever shows.
* **Staggered entrance** (`CinematicStaggerScope` + `CinematicEntrance`): the
  Engage hub's tiles fade in and rise 12 pt in a 70 ms stagger the first time
  the tab is seen (the controller is held by the hidden tab's `TickerMode`
  until then). Reduced motion shows everything at once.
* **Hero transitions:** not added in this pass. The Cover of the Week opens a
  bottom sheet, and heroes only fly between page routes; converting it to a
  page would change behaviour. `CinematicTabStack` already disables heroes in
  hidden tabs, which removes the main risk (duplicate tags across tabs) for a
  later member-photo hero.

## Reward bursts in the same language

* The burst card now enters with `CinematicMotion.settle` (the page-cut
  curve) instead of a bouncy overshoot.
* **Level-ups** open with a single bloom of light from the card
  (`CinematicBloomPainter`: one swell peaking at 8% of the burst, gone by
  50%, at most 22% white) and a medium haptic (small rewards keep the light
  haptic).
* **Cover of the Week** (the rose-rain celebration) opens with the same
  single bloom, like a flashbulb across the room. Its reduce-motion check now
  goes through `AppTheme.reduceMotionOf` like every other effect.

## Accessibility and safety

* Everything honours `AppTheme.reduceMotionOf` (platform setting or Calm): no
  ambient motion, no page or tab animation, no bloom, flare, sheen pulse or
  title-card motion.
* **Photosensitivity:** nothing flashes more than three times a second. The
  neon stutter changes at most 4 times in any second (tested at 5 ms
  resolution over 2 minutes; the WCAG limit is 6 changes = 3 flashes). The
  forge arc and shooting star are thin lines once every ~10 s. Blooms are a
  single swell. Candle flicker stays within ±20% (tested) on a tiny area.
* Scenes, sheen, glow, flares and blooms ignore pointers and are excluded from
  semantics.
* Contrast: the film layer and scenes paint behind content only; palette
  colours are unchanged (`screen_accessibility_test` and
  `dark_ground_contrast_test` pass).
* Spacing: new `EdgeInsets` are multiples of 4.

## Tests

New:

* `test/features/theme/cinematic_clock_test.dart`: off under flutter test by
  default; one ticker for a scene; pause on background and resume without a
  jump; reduced motion, Calm, the Today look and still previews never
  subscribe; a covered route unsubscribes; scene, two sheens and a glow share
  one ticker.
* `test/features/theme/cinematic_transitions_test.dart`: every platform uses
  the builder; depth cut in cinematic looks; quiet rise in the everyday look;
  no animation under reduce motion and Calm; system back pops (cinematic and
  Today); `PopScope` still intercepts; iOS edge swipe pops; the sheen builder
  is a stable tear-off and absent for everyday/Calm; tab stack keeps tabs
  alive, pauses hidden ones, cuts in cinematic looks, only fades in everyday,
  switches instantly under reduce motion.
* `test/features/theme/cinematic_scenes_test.dart`: every preset's scene paints
  at seven sizes (including zero and 2560×1440), with and without film, at
  nine moments (including inside each timed event and after a day); every
  cinematic look has a moving scene; repaint rules; neon flicker rate; candle
  range; bloom is a single swell; title flares paint; the title card slides
  bars in, reveals the title and leaves, dismisses on tap, is still under
  reduce motion and skipped for Calm.

Existing theme, celebrations, navigation, settings and accessibility suites
pass. `spacing_grid_test` still fails only on the pre-existing chat,
introducer, city pilot and match card literals.

## Files

* New: `lib/core/theme/cinematic_clock.dart`, `cinematic_motion.dart`,
  `cinematic_effects.dart`, `cinematic/env_io.dart`, `cinematic/env_stub.dart`.
* Rewritten: `lib/core/theme/theme_atmosphere.dart` (layered animated scenes,
  title card).
* Edited: `app_theme.dart` (page transitions), `theme_presets.dart` (button
  sheen, `ConnectPalette` equality), `glass_widgets.dart` (GlassButton sheen),
  `main.dart` (theme morph only), `main_navigation_screen.dart`
  (`CinematicTabStack`), `settings_screen.dart` (still chip previews),
  `today_wall.dart` (cover parallax), `engagement_hub_screen.dart` (tile
  stagger), `reward_burst.dart` and `rose_rain.dart` (bloom, haptics, curve).
