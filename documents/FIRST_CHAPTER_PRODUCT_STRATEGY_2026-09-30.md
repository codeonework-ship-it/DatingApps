# Connect: create your first chapter together

Product decision memo · 30 September 2026 · Proposed strategy, not a shipped feature announcement

## The recommendation

Make **First Chapter** the signature experience: two people make something small together, discover a reason to continue, and can turn it into a real date. The public promise is **“Create your first chapter together.”**

A person should be able to demonstrate the product to a friend in thirty seconds. The demo should show a delightful interaction, not a compatibility percentage or a list of filters. This is a hypothesis to validate; no feature can guarantee global virality.

The existing foundations—dating rhythm, chemistry prompts, shared date plans, private second yes, friend introductions, and the new city-pilot infrastructure—make this possible. Adding more disconnected screens would dilute the proposition. Connect needs one recognizable interaction connecting these foundations.

## What the market already covers

This is a focused competitive check, not an exhaustive novelty or patent assessment. Vendor descriptions establish the existence of features; they do not establish that those features work for our audience.

| Existing territory | Primary source | Product implication |
|---|---|---|
| Friends participating in dating and pair-to-pair discovery | [Tinder Double Date, June 2025](https://www.tinderpressroom.com/2025-06-17-Tinder-Launches-Double-Date-The-New-Way-to-Make-Connections-with-Your-Bestie) and [Matchmaker](https://ca.tinderpressroom.com/2023-10-23-TINDER-MATCHMAKER-TM-INTRODUCES-THE-ULTIMATE-WAY-FOR-POTENTIAL-MATCHES-TO-PASS-THE-FRIEND-TEST) | Friend involvement is useful, but insufficient as our central differentiation. |
| Easier conversation starters | [Bumble Opening Moves](https://bumble.com/en/features/opening-moves/) | A prompt library alone is not the proposition. |
| Private post-date feedback and focus on existing conversations | [Hinge We Met](https://help.hinge.co/hc/en-us/articles/360010692913-What-is-We-Met) and [Your Turn Limits](https://help.hinge.co/hc/en-us/articles/31662181659027-What-is-Your-Turn-Limits) | Private feedback supports product learning; it is not a new category by itself. |
| Arranged dates and local singles experiences | [Breeze](https://breeze.social/) and [Thursday](https://events.getthursday.com/) | “Get off the app” and events already have established competitors. |

Our opportunity, as an inference from this review, is a coherent **shared creation → comfortable next step → real-world follow-through → reusable story** experience. Do not advertise this as the world's first without a broader assessment.

## The flagship: First Chapter Studio

Example: “We have a rainy afternoon and a small budget. What do we make of it?”

1. A member selects a scene: a small adventure, a food discovery, a creative challenge, or a quiet afternoon. This is an expression of personality; no exact availability or location is public.
2. Two consenting members enter an optional shared scene. One chooses a starting point; the other adds a surprise. They can respond asynchronously, change their mind, or skip the activity and chat normally.
3. Each contributes something different: a sketch, a short caption, an activity choice, or an optional voice snippet with a text alternative. The second contribution changes the scene; this must be more than two people answering an identical questionnaire.
4. The app reveals a small co-authored card: “Bookshop → unexpected dessert → a question worth staying for.” No claim that the pair is psychologically compatible follows from these choices.
5. Either can suggest turning it into a date. Their existing broad time windows, budget and accessibility preferences help shape a private plan. Exact venue and time appear only in the mutually agreed plan.

**Why it matters:** it gives people shared context and a glimpse of how it feels to make a choice together. We should test whether this improves conversation quality; completing a playful task does not prove chemistry.

**The memorable demonstration:** “We made our first date together before we ran out of things to say.” This is proposed positioning, not an asserted customer testimonial.

**Minimum viable version:** three text-and-choice scenes, accessible without audio or animation, available between existing matches. Reuse the chemistry and date-plan foundations. Do not make games a gate to messaging, introduce speed scoring, or require simultaneous attendance.

## The supporting features worth building

### 1. Pass the Chapter: sharing with a reason

A member can publish a reusable version of their own scene: “What would you add to this afternoon?” A recipient can try a neutral browser preview, then make their own version. Sharing is a deliberate action with a preview of exactly what will be public.

The shared artifact contains an approved template and the sharer's permitted creative contribution. It does not contain a match's name, face, messages, response, dating status, exact location or availability. Publishing joint content requires approval from both authors. A friend playing with a template is not automatically enrolled in dating, discoverable, or added to a contact list.

**Growth hypothesis:** people share because making the next chapter is enjoyable. The invitation delivers value before requesting an install. Test this against a conventional invitation; do not attach coin rewards, pressure timers or automatic contact invitations.

### 2. A private green light: “I would be comfortable with…”

Each person can privately choose a next step: keep chatting, try a voice call, or suggest a date. Reveal a shared option only when both choose it. A non-match of preferences discloses nothing and never closes the conversation.

This extends the existing private second yes to the period before a first date. It addresses the uncertainty of whether an invitation is welcome. A green light is permission to propose, not consent to a specific call, venue, time or physical activity. Members can withdraw it at any point.

**Success measure:** mutually accepted plans per eligible pair, alongside pressure complaints and abandonment. Do not judge it by how many people click “ready.”

### 3. In my words: cross-cultural comfort cards

Offer optional, member-authored explanations such as “I take time before meeting,” “I prefer daytime dates,” or “I would like family involvement later.” Let each person state what relationship terms mean to them. Present the original language alongside any clearly labelled translation.

Localization should cover language, right-to-left layouts, local currencies, date and time formats, accessibility, alcohol-free choices and differing expectations around public sharing. Do not infer these preferences from nationality, religion, ethnicity or gender.

**Why this belongs:** the signature experience must travel across cultures without making everyone behave like one launch-city audience. These are enabling capabilities, not a claim of automatic international product-market fit.

### 4. Stories that give back: successful members become creators

After both members choose to celebrate their connection, they may co-author an anonymous “our first chapter” template for others: a conversation activity or a locally adaptable date idea. Each controls their contribution and approves joint publication. Declining has no effect on the relationship or account.

This gives members a voluntary role after dating success. The reusable idea can travel; the relationship stays private unless both explicitly choose otherwise. No automatic testimonials, public date histories, partner ratings or leaderboards.

**Growth hypothesis:** people invite friends to try an experience they enjoyed. Track qualified referrals and subsequent conversation/date outcomes, not vanity share counts.

## UI/UX: recognizable, warm, easy to understand

The screenshot's main issue is information architecture: the Matches icon delivered a screen labelled Conversations. This turn restores a Matches overview with people cards, explicit chat/date actions, and a separate Conversations choice. Desktop and mobile labels agree.

For the next design phase, make the signature scene card the visual identity: two contributions visibly forming one composition. Use warm neutral surfaces, deep ink, one coral or apricot action colour and a restrained secondary accent. Strong typography, generous spacing and real member-controlled content should carry the personality. Space-themed visuals can remain an optional theme; they should not obscure names, text or actions.

Suggested future navigation, to test before a larger change: **Today · Connections · Plans · You**. Within Connections: **New connections · Conversations**. This navigation proposal is not implemented in this turn; the current five destinations remain intact.

Every scene needs a text-only path, keyboard and screen-reader support, reduced motion, large-text layouts, persistent drafts and recovery after disconnection. Show genuine overlap only when member-supplied data supports it. Avoid animated connection lines that imply an actual relationship, fake presence, compatibility scores or urgency.

## Build order and acceptance

| Epic | Scope | Dependency / go-no-go condition |
|---|---|---|
| FC-01 — First Chapter Studio | Three co-created scenes between existing matches; save/reveal; optional conversion to a plan | Existing mutual match, safety controls and plan permissions. Compare with ordinary chat; reject if users find it burdensome. |
| FC-02 — Share and remix | Neutral browser preview, explicit export preview, revocable links, adult dating opt-in, attribution | FC-01 must demonstrate value. Publication permission enforced on the server; a public template never grants profile access. |
| FC-03 — Private green light | Separate private readiness records, mutual reveal, expiry and withdrawal | Existing private-consent architecture. Single-party choices must never appear in another person's events or analytics drilldowns. |
| FC-04 — Language and comfort | Localized scenes, accessibility, original/translated text, member-controlled comfort cards | Research and review with members in the specific next city. No culturally inferred defaults. |
| FC-05 — Alumni chapters and hosted adaptations | Jointly approved stories, moderated templates, small hosted tests | Voluntary mutual participation; city pilot's outcome review and staffed operations before hosted experiences. |

Implement FC-01 first. Test FC-02 as the growth mechanism once the shared interaction is worthwhile. FC-03 supports conversion to a comfortable next step. FC-04 is required before expanding to a substantially different language/cultural market. FC-05 follows evidence and operating readiness.

Architectural constraints: additive aggregate records for scenes, contributions, publication approvals and readiness; a single owner for each; versioned writes; transactionally recorded events; idempotent reveal/export; audience-scoped subscriptions. No private answer values in broad event streams. Share links expose separate approved public artifacts, never live private conversation records. The command center receives aggregate outcomes and operational reports, not a compatibility score for each person.

## Test the whole growth loop

**Value loop:** introduction → optional shared scene → two-way conversation → mutually shaped plan → voluntary date outcome.

**Growth loop:** enjoyable scene → deliberate share → recipient tries a neutral preview → explicit dating opt-in where eligible → a useful introduction → another enjoyable scene.

Measure every transition with consent, unique users and a declared time window. Define a qualified activation before testing. “Invited signup” is weaker than “new eligible member who subsequently has a two-way conversation.” A viral coefficient above one can indicate self-propagating growth for that measured cycle; it does not establish retention, safety, geographic density or profitability.

The city pilot currently measures three-message-per-person conversations within seven days, accepted plans within twenty-eight days, and voluntary mutually reported date outcomes. That conversation threshold is a behavioural proxy, not a claim that a conversation was worthwhile. A future quality study should ask a separate optional question and report its response coverage.

For a comparison experiment, assign a pair consistently to the same experience, account for overlapping members and network effects, set the primary outcome and stopping rules before launch, and report uncertainty. The existing pilot is observational and must not be described as causal proof. Its twenty-pair minimum is an operational review floor, not a statistical power calculation.

Stop or revise if the scene adds friction, increases unwanted contact, exposes private content, attracts low-quality referrals, or reduces mutually accepted plans despite increasing shares. Report response coverage and unknown date outcomes separately; treat withdrawal as withdrawal.

## International expansion and the business model

Grow city by city around enough mutually eligible, recently active members in compatible language, intent and availability groups. Global downloads without local introductions are not success. Establish a reviewed operating playbook for each expansion city, including member support and hosted-experience readiness, and localize the scene content with people who live there.

Keep consent, reporting, normal conversation and leaving available. Potential future revenue is optional planning convenience and clearly labelled hosted experiences, with transparent prices and cancellation terms. Paid access should not buy another person's response or safety status. Billing remains separately owned; no monetization change is included here.

The defensible asset is consistent execution: enjoyable shared interactions, evidence that they lead to dates people wanted, trusted local operations and member-approved creative content. A novel screen is easy to copy. A coherent product that reliably delivers that promise is harder to reproduce.
