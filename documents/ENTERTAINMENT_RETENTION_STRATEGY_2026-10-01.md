# Entertainment that makes women stay

Status: **proposal for founder decision, 2026-10-01.** Retention and revenue figures marked *assumption* are
starting points to replace with measured data. Partner names are examples of the kind of partner to approach,
not existing relationships.

## 1. The problem in one paragraph

Women rarely leave a dating app because they are bored of it. They leave because the app gives them three bad
experiences and no good reason to come back: too much low-effort inbound attention, constant safety vigilance,
and long stretches of nothing to do between good conversations. Entertainment fixes the third problem, and done
well it eases the other two. It gives a woman something enjoyable to do on a day with no matches. It lets men show
effort and personality instead of sending "hey". It also happens in spaces she controls. The goal is not more
time in the app. The goal is **a reason to open it that does not depend on who messaged her.**

## 2. Principles (first principles, then platform)

Two lenses shaped this list.

- **First principles (the SpaceX lens).** Start from the job, not from competitors. The job is "an enjoyable,
  low-pressure way to see who someone really is." Every idea below must either create that signal or make waiting
  pleasant. Reuse what already flies: the blog case queue, the moderated photo pipeline, clubs, the coin ledger,
  friend fan-out and the City Pilot are reusable boosters. New ideas should mostly be new payloads on them.
- **Platform and measurement (the Google lens).** Ship small, instrument everything, and decide with
  experiments. Each idea has a single north-star metric and a kill threshold before it gets a second sprint.

Product rules that do not bend:

1. **Healthy, not compulsive.** No infinite feeds, no streak shaming, no variable-reward loot boxes. Daily
   content is finite. Notifications are capped and respect the dating-rhythm pause.
2. **She controls the room.** Every social surface has audience controls, block/report, and a women-only option
   where it makes sense. Women-only spaces require verified identity.
3. **Never sell trust or exposure.** Entertainment can sell expression (themes, stickers, premium stories) and
   convenience, never visibility, ranking or "see who liked you". This matches the pricing strategy of 2026-09-27.
4. **18+ only.** The audience is adults. Appeal to the youngest adult members comes from tone and design, never
   from anything that targets minors.
5. **Friends welcome.** Women already ask friends about dates. Features that let a friend join, react or vouch
   beat features that isolate.

## 3. The idea portfolio

Effort: S = under two weeks for one squad, M = two to six weeks, L = more than six weeks.
"Reuses" names what already exists in the codebase.

### A. Stories and play (solo, any day, no match needed)

| # | Idea | What she does | Why it keeps her | Reuses | Effort | Money |
|---|---|---|---|---|---|---|
| A1 | **Interactive romance stories** | Reads short, choose-your-path romance and comedy episodes, a new chapter each week | Serialized fiction is one of the strongest retention formats for women 18–34 in mobile entertainment (assumption to validate in market tests). It is pure enjoyment on zero-match days | Blog reader, coin ledger, First Chapter story engine | L | Free first chapter, later chapters by coins or Plus |
| A2 | **Vibe forecast** | A playful daily card ("Today favours a slow coffee and an honest question") with an opt-in astrology flavour | A tiny daily ritual with no pressure. Shareable to stories outside the app | Daily prompt infrastructure | S | Free; premium themed card packs |
| A3 | **Personality quizzes** | Ten-question quizzes such as "Your date archetype" and "Your comfort language", with results as optional profile badges | Self-discovery is fun and shareable, and the results become conversation starters | Profile stories, badges | S | Free; drives sharing |
| A4 | **Daily word and picture puzzles** | One short puzzle a day, finite like a newspaper puzzle | Proven daily-habit mechanic without endless scrolling | Daily prompt scheduler | M | Free; Plus gets the archive |

### B. Play together (with a match, low pressure)

| # | Idea | What happens | Why it works for women | Reuses | Effort | Money |
|---|---|---|---|---|---|---|
| B1 | **Two-minute games in chat** | This-or-that, two truths and a lie, "finish my sentence", desert-island picks | Replaces interview-style small talk with play. Low-effort openers become visible effort | Chat, copilot prompts | M | Free; cosmetic game skins |
| B2 | **Quiz match** | Both answer the same five questions, then see where they agree | Creates a reason to message that is about something | Daily prompt answers | S | Free |
| B3 | **Watch-along** | Two matches (or a film club) press play on the same trailer, short film or playlist and react live | A "date" with no logistics and no safety risk | Film clubs, realtime outbox | M | Partner content |
| B4 | **Playlist swap** | Each shares five songs for a theme ("songs for a long drive"); each rates the other's | Music taste is a strong, low-stakes signal | Photo Themes model (one entry per prompt) | S | Free |

### C. Community and friends (women-first spaces)

| # | Idea | What happens | Why it keeps women | Reuses | Effort | Money |
|---|---|---|---|---|---|---|
| C1 | **Women-only lounge** | Verified-women rooms for dating advice, red-flag checks and "is this normal?" questions | Peer support is the antidote to safety fatigue, and it gives her a community even when dating is slow | Clubs (roles, moderation), verification, case queue | M | Free; never monetized |
| C2 | **Girls' night mode** | A friend group reviews a date plan, votes on outfits or venues, and gets the "I'm safe" check-in | Turns the app into something she uses with friends | Date plans + friend fan-out, group coffee polls | M | Free |
| C3 | **Live salons** | Weekly hosted text or audio sessions such as books, travel, careers or "first-date stories", with women hosts first | Appointment content brings people back on a schedule | Clubs, conversation rooms (need database backing) | M | Sponsored salons |
| C4 | **Seasons** | Six-week themed seasons such as monsoon, festive and summer, with themed photo prompts, club picks, badges and a finale event | Gives the whole app a sense of "something new is happening" | Photo Themes, clubs, XP, theme presets | S per season | Season cosmetic pass |

### D. Creative self-expression (already scoped)

| # | Idea | Status |
|---|---|---|
| D1 | Photo Themes | **Shipped 2026-10-01** |
| D2 | Book & Film Clubs | **Shipped 2026-10-01** |
| D3 | Mood boards | Scoped; needs a board model and saves |
| D4 | Recipe journals | Scoped; needs recipe fields and saves |
| D5 | Creative challenges | Scoped; reuse circle challenges with moderated media |

### E. Real-world experiences (the payoff)

| # | Idea | What happens | Reuses | Effort | Money |
|---|---|---|---|---|---|
| E1 | **Women-led small experiences** | Pottery, book cafés, supper clubs and walks in groups of 6–12, women hosts, day-time first | City Pilot, date plans, check-ins | M | Ticket share with venues |
| E2 | **Club meetups** | A book or film club can turn a weekly pick into a meetup at a partner café or screening | Clubs, City Pilot | S after E1 | Venue partnership |
| E3 | **Date-night kits** | Curated plan templates with a venue offer, such as "rainy-day museum and chai" | Date plans, plan concierge (Plus) | S | Venue offers, Plus |

### F. Self-care and confidence

| # | Idea | What happens | Effort | Money |
|---|---|---|---|---|
| F1 | **Dating reset** | A gentle mode during a pause: short reflection prompts, a confidence mini-course, and no discovery pressure | S | Free |
| F2 | **Expert mini-courses** | Five-minute lessons from therapists and dating coaches on boundaries, red flags and first dates | M | Premium courses or sponsor |

## 4. Prioritization

Scored 1–10 on Impact on women's weekly retention, Confidence, and Ease (ICE). Scores are judgement,
to be replaced with experiment data.

| Rank | Idea | Impact | Confidence | Ease | ICE | Why it ranks here |
|---|---|---|---|---|---|---|
| 1 | C4 Seasons | 8 | 8 | 9 | 576 | Packages what already shipped into a reason to return; almost no new infrastructure |
| 2 | A3 Personality quizzes | 7 | 8 | 8 | 448 | Cheap, shareable and feeds conversation starters |
| 3 | B1 Two-minute games in chat | 9 | 7 | 7 | 441 | Directly fixes low-effort openers, which is a top reason women disengage |
| 4 | C1 Women-only lounge | 9 | 7 | 6 | 378 | Strongest answer to safety fatigue; needs verification and moderation staffing |
| 5 | B4 Playlist swap | 6 | 7 | 9 | 378 | Almost a copy of Photo Themes with links instead of photos |
| 6 | A1 Interactive romance stories | 9 | 6 | 4 | 216 | Highest ceiling and the best revenue line, but needs a content pipeline |
| 7 | E1 Women-led experiences | 9 | 6 | 4 | 216 | The real payoff, gated by City Pilot operations |
| 8 | B3 Watch-along | 7 | 5 | 5 | 175 | Content licensing limits it to trailers, shorts and partner content at first |

## 5. The 90-day plan

**Days 0–30: package and play (no new platforms).**

- Launch Season 1, "Monsoon Season": three themed Photo Themes prompts, a featured book pick and a featured film
  pick, two seasonal badges and a finale photo wall.
- Ship personality quizzes (three quizzes) with optional profile badges.
- Ship playlist swap as a Photo Themes variant that holds links, not photos.
- Instrument the women's retention dashboard in section 7 before any of this goes live.

**Days 31–60: play together and a safe space.**

- Two-minute games in chat (four game types) with a per-match daily cap.
- Women-only lounge pilot in one city with verified women only, two trained moderators, and the existing case
  queue extended with a `lounge_post` type.
- Back conversation rooms with the database (they are in-memory today), which salons need.

**Days 61–90: stories and real life.**

- Interactive stories pilot: one six-episode romance-comedy series, the first two episodes free.
- First women-led experiences through City Pilot in the pilot city, plus club meetups at one partner café.
- Decide go, iterate or kill for every 0–60-day feature using the thresholds below.

## 6. Business development

| Partner type | What we offer them | What we get | Example targets (to approach) |
|---|---|---|---|
| Book publishers and bookstores | Featured weekly picks to engaged readers, author salons | Free advance copies, author events, co-marketing | Indian and UK publishers, independent bookstores |
| Streaming and film distributors | Film club picks, watch-along trailers | Trailers and shorts rights, premiere screenings, promo codes | Regional OTT platforms, indie film festivals |
| Cafés, studios and venues | Small, safe, pre-booked groups on quiet days | Ticket share, member offers, safe day-time venues | Book cafés, pottery and art studios, supper clubs |
| Wellness and beauty brands | Sponsored seasons and salons that fit the brand | Sponsorship revenue, gifts for season finales | Only brands that pass a women-first values review |
| Music platforms | Playlist swap integration | Deep links, artist salons | Streaming services with link sharing |

**Revenue lines this adds (all consistent with "never sell trust"):**

1. Premium story chapters and season cosmetic passes on the existing coin ledger.
2. Experience tickets (revenue share with venues).
3. Sponsored seasons and salons, capped at one sponsor per season and clearly labelled.
4. Plus perks: puzzle and story archives, plan concierge for date-night kits.

## 7. How we will know

**North star:** weekly active women who did something enjoyable on a day they had no new match
("good-day rate"). *Assumption:* raising this lifts 30-day retention of women.

| Metric | Target to keep investing (assumption) | Kill or rework if |
|---|---|---|
| Women's day-7 and day-30 retention versus a holdout | +3 and +2 points | No lift after two iterations |
| Share of women's sessions with no match activity that include an entertainment action | 35% | Under 15% |
| Openers containing a game or prompt versus a plain greeting | 40% of first messages | Under 10% |
| Reports per 1,000 interactions in new surfaces | At or below the chat baseline | 1.5 times the chat baseline |
| Women's satisfaction ("I enjoyed Connect today") | 4.2 of 5 | Under 3.6 |

Every feature ships behind its own flag with a 10% holdout so the lift is measured, not assumed.

## 8. Risks and guardrails

- **Moderation load.** Every new social surface multiplies reports. Budget moderator hours before launch and
  reuse the single case queue so operators see everything in one place.
- **Harassment through play.** Games and quizzes must not reveal anything she did not choose to share, and every
  game message is reportable like chat.
- **Content cost.** Interactive stories need writers and editing. Start with one series and a small freelance
  bench before building tooling.
- **Gender balance.** Men also need reasons to stay, or the women's experience suffers. Games and clubs give men a
  way to show effort, which is the behaviour women ask for.
- **Over-gamification.** Badges and seasons must celebrate taking part, never rank people.

## 9. Decisions needed from the founder

1. Approve Season 1 as the first launch and choose its theme.
2. Approve the women-only lounge pilot, including moderator staffing.
3. Approve a content budget for one interactive story series.
4. Choose the pilot city for women-led experiences and the first partner categories.

## 10. The engagement engine: designing for delight

Added 2026-10-01 at the founder's request: the app should win attention through the reward effect of
anticipation, recognition and surprise. Those are real levers. The question is which ones build a habit women
enjoy and which ones build resentment, store-policy risk and churn. Every idea below uses one of five reward
types, and each is tied to something that already exists in the product.

| Reward type | What the brain enjoys | Healthy version | Version we will not ship |
|---|---|---|---|
| Recognition | Being seen and appreciated | Likes, approved comments, wall tiers ("Your photo reached 50 walls") | Public popularity rankings of people |
| Progress | Visible movement toward a goal | Next-tier bar, profile strength, season track | Streaks that punish a missed day |
| Anticipation | Something good is coming | A fixed daily reveal time, "almost there" nudges | Countdown pressure on paid items |
| Surprise | Unexpected delight | Rose rain on a new tier, a rare petal in a season | Paid loot boxes or random paid rewards |
| Belonging | Being part of something | Clubs, seasons, "3 people loved the same Sunday" | Fear-of-missing-out notifications at night |

### Ideas, ready to build on what shipped today

1. **Rose rain on every tier.** When a story or photo reaches a new wall tier, the author's next app open plays a
   two-second shower of rose petals in their chosen theme, then the tier card. This is the purest dopamine
   moment in the product: earned, rare and celebratory. Reuses the theme atmosphere painters and the tier
   notification already sent.
2. **"Almost there" nudges.** When a creation is within 20% of the next tier ("4 likes and 1 comment to reach
   100 walls"), tell the author once. Progress close to completion is one of the strongest motivators.
   The next-tier data already exists in the API.
3. **The 8 pm reveal.** The Today wall refreshes once a day at a fixed local time with a short reveal animation
   ("Tonight's covers"). Anticipation of a known moment builds a daily habit without an endless feed.
4. **Petal collection (seasons).** Each like you give and receive drops a petal into a season jar shown on your
   profile. Ten petals bloom into a rose badge. Rare golden petals appear for approved comments, because
   effort deserves a rarer reward than a tap. Cosmetic only, never sold as a random draw.
5. **Rose Garden profile.** Roses received as gifts (the gift ledger already exists) bloom in a small garden on
   the profile, so generosity becomes visible and beautiful. A daily free rose is already part of the product.
6. **Cover of the week.** Each Photo Theme crowns one "cover" per week from photos with author opt-in, chosen by
   a mix of likes and approved comments and shown full-bleed on everyone's Today wall for a day. This is the
   magazine-cover moment, earned rather than bought.
7. **Reciprocity sparks.** "3 people shared a Sunday like yours" after a Photo Themes post, or "Someone in your
   club rated it 5 stars too". Similarity is a strong pull back into the app and a natural conversation starter.
8. **Haptics and sound for wins.** A light haptic on like, a soft chime on a new approved comment and a richer
   one on a tier. Small sensory rewards make taps feel good; all respect system silent mode and Calm theme.
9. **Weekly highlight reel.** Every Sunday, a private recap: walls reached, new comments, club picks finished,
   petals collected. A finite, reflective dose of recognition instead of constant pings.
10. **Theme drops.** New looks (Rose and Petal shipped today) arrive with seasons, revealed with their title card.
    Novelty in how the app looks keeps it feeling alive; looks are cosmetic purchases on the coin ledger.

### Guardrails that keep this healthy

- At most three engagement notifications a day, none during quiet hours (10 pm to 8 am local), and none while
  the dating-rhythm pause is on.
- No paid randomness. Anything earned at random is free; anything sold is shown before purchase.
- Never rank people. Rank creations (stories, photos, club picks) and only with the author's opt-in.
- Calm theme turns off animation, sound and celebratory motion everywhere.
- A weekly "time well spent" check: if a member's sessions grow but their satisfaction score drops, reduce
  nudges for them automatically.
- Women-first safety still wins: wall reach pauses on any open report, and comments wait for author approval.

### What to build first

| Order | Feature | Effort | Why first |
|---|---|---|---|
| 1 | Rose rain on new tier + "almost there" nudge | S | Uses data that already exists; the most emotional moment |
| 2 | Cover of the week | S | Turns Photo Themes into a weekly event with a magazine-cover payoff |
| 3 | Petal collection in Season 1 | M | Gives every like a visible, collectable result |
| 4 | 8 pm reveal for the Today wall | M | Creates a daily appointment without an infinite feed |
| 5 | Weekly highlight reel | S | Recognition in one satisfying dose |
