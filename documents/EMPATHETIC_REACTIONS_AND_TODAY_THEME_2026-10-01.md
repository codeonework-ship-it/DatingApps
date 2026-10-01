# Empathetic reactions, the Today look everywhere, and the Open Chapters back fix

Delivered 2026-10-01.

## Empathetic reactions

Readers can tell a writer how a chapter or photo made them feel, not just "like" it.
Migration: `backend/scripts/114_empathetic_reactions.sql`.

| id | Shown as | Meaning |
|---|---|---|
| `love` | ❤️ Love this | The plain like (default) |
| `hear_you` | 🫶 I hear you | Your feelings were heard |
| `me_too` | 🙋 Me too | I have felt this too |
| `with_you` | 🤝 I’m with you | Support |
| `hug` | 🫂 Sending a hug | Comfort |
| `proud` | 🌟 Proud of you | Encouragement |

Rules:

- A member has at most one reaction per chapter or photo. Every reaction counts as one like for
  wall tiers, Top rated, Today's wall ranking and the `like_received` reward.
- Changing a reaction is still one like: it skips the daily like limit and never re-awards XP.
- A plain like (no reaction sent) keeps a reaction the member already chose.
- Reaction counts only include active members, like the like count.
- Reactions are included in the member data export (`blog_likes`, `photo_likes`) and erased with
  the account, as likes were.

### API

`PUT /v1/blog/posts/{postID}/like` and `PUT /v1/themes/{themeID}/entries/{entryID}/like` accept an
optional body:

```json
{"reaction": "hear_you"}
```

No body means a plain like. An unknown reaction returns `400`. The chapter (`post`) and photo
(`entry`) JSON gain:

```json
{"my_reaction": "hear_you", "reactions": {"hear_you": 3, "love": 12}}
```

`my_reaction` is empty when the member has not liked the item. `DELETE` on the same paths removes
the reaction (and the like) as before.

### App

- The heart still likes and unlikes with one tap. The React button beside it (or a long press on
  the heart) opens "How does this chapter make you feel?" with the six reactions and "Take my
  reaction back".
- After reacting, the button shows the chosen emoji, and a summary shows the top reactions with
  counts (for example ❤️ 3 🫶 1). Everything is optimistic and rolls back on failure.
- Code: `app/lib/features/walls/reactions.dart` (catalogue and like state) and
  `app/lib/features/walls/reaction_widgets.dart` (picker and summary).

## The Today look on every screen

Every screen now uses the look the Today screen is designed in: one flat ground colour, an
uppercase eyebrow over a serif headline, paper cards with a hairline border and 20pt radius, and
colours taken only from the member's chosen theme.

- Shared building blocks: `app/lib/core/widgets/connect_page.dart` (`ConnectPageHeader`,
  `ConnectSectionHeader`, `ConnectPanel`, `ConnectNavTile`, `ConnectMetrics`). Today's own
  `TodaySectionHeader` and `TodayPanel` are now these.
- `GlassContainer` draws a Today card, `GlassButton` uses the theme's primary colour, and the
  post-login backdrop is flat for the everyday looks. Cinematic looks (Rose, Petal, Love, Neon
  Grid and others) still paint their atmosphere, now on Today too.
- Engage, Profile, Settings and the Matches header use the Today header and sections. About 45
  other screens, including the signed-out screens and the loading gates, no longer use the fixed
  crimson, pink and purple colours.
- Kept on purpose: the rose gift artwork, the rose-rain and like-burst petals, the in-call screen's
  dark video background, gold coins and XP, and success or warning colours.

### Theme in Settings

Settings now opens with a Theme section ("Make it yours"): Light / Dark / Match device, and a strip
of looks, each previewed as a small Today page in its own colours. The default look is now named
**Today** (it was "Real life"). The browser app stays on the Today look.

## Open Chapters back button

On Android the in-app back arrow, the back key and the back gesture all return correctly from Open
Chapters and from a chapter. In the browser app, a chapter or other screen opened on top of the
page had no URL of its own, so the browser's back button changed the page underneath and left the
chapter open. Browser back now closes the top screen first (asking before discarding unsaved
writing) and keeps the member where they were.
