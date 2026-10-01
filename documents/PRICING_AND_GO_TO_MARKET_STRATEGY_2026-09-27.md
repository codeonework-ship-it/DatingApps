# Connect — Pricing and Go-to-Market Strategy

Status: **proposal for founder decision, 2026-09-27.** Numbers marked *assumption* are starting points to be replaced by measured data in the first 90 days. Competitor prices are approximate list prices and must be re-checked in each store and country before launch.

## 1. What we are selling

Tinder and Bumble sell *swipes and visibility*. Connect sells *dates that actually happen, with your friends in on it*. Everything below follows from three product facts that now exist in the code:

1. **Date plans your friends know about.** A matched pair turns a conversation into a plan (time window, venue, area). Every status the member sets reaches their friends list and the friend groups they chose: proposed, accepted, cancelled, "I'm safe", "I need help", and a missed check-in. Friends get told automatically; the member does not have to remember to share.
2. **Verified humans and a "Shows up" badge.** Both members' identity state is shown in the conversation. Dates confirmed by both sides feed a trust badge nobody else can offer because nobody else knows whether the date happened.
3. **Friends as the growth engine.** Vouches on profiles, friend-made intros, and graduation (leaving as a couple, celebrated and shared) each pull one or more non-members into the product.

Positioning line for the market: **"The dating app your friends are in on."** Sub-line for safety-minded buyers: "Every plan, every check-in, shared with the people who care about you."

## 2. Pricing principles

- **Never sell trust or exposure.** No paid badges, no paid ranking, no "see who liked you" gates on the core loop. The FRD already forbids purchasing trust; keep it. This is the single clearest contrast with the incumbents and the reason the free tier must be complete.
- **Free tier is the whole product.** Plans, friend notifications, check-ins, debriefs, vouches, intros, graduation, the Today set and ten copilot drafts a day are free. Paid is convenience and expression, never safety.
- **Price by market, not by exchange rate.** Purchasing-power pricing per country, with the same feature set everywhere.
- **Align the business with the outcome.** A member who graduates should feel we were on their side, not sorry to lose them.

## 3. Price architecture

Two paid layers plus cosmetics. Nothing else in the first year.

| Layer | What it contains | Why it is fair to sell |
|---|---|---|
| **Free** | Complete core loop: discovery, Today set, matching, chat, date plans + friend fan-out, check-ins, debrief, badges, vouches, intros, graduation, 10 copilot drafts/day, one gift/day | Safety and trust must never be behind a paywall |
| **Connect Plus** (subscription) | Unlimited copilot drafts; plan concierge (venue and time suggestions near both members); travel mode (browse another city before a trip); undo last pass; read receipts; advanced filters beyond the free set; priority support; **Graduation Refund** (unused subscription months credited back when both members confirm graduation) | All convenience. None of it changes who sees whom |
| **Theme packs and gifts** (coins) | Cinematic looks (Forge, Neon Grid, Crimson Alloy, Circuit, Deep Field, Love); Calm is always free (accessibility); paid gifts in chat | Expression, already built on the coin ledger with fraud controls |

**Deliberately not sold:** boosts, spotlight beyond the existing fairness-capped tier, "see who liked you", verification fast-track, extra Today candidates. Selling any of these would convert the fairness story into a pay-to-win story overnight.

### Suggested list prices (assumption; validate with a 2×2 price test per market)

| Market | Plus monthly | Plus quarterly | Plus yearly | Anchor (approx. incumbent monthly, verify) |
|---|---|---|---|---|
| India | ₹399 | ₹999 | ₹2,999 | Tinder Gold and Bumble Premium roughly ₹500–1,500 |
| UK | £8.99 | £22.99 | £59.99 | Tinder Gold roughly £20–25, Hinge+ roughly £25 |
| Eurozone (DE, FR, NL, ES, IT, PT, AT) | €9.99 | €24.99 | €69.99 | Bumble Premium roughly €25–35 |
| Poland | 34.99 zł | 89.99 zł | 249.99 zł | Local PPP of the euro price |
| Russian-speaking diaspora (EU, priced in local currency) | Same as host market | | | |

The yearly price is set at seven months of monthly. Quarterly is the default highlighted plan because dating intent runs in seasons; a quarter is long enough to see a Graduation Refund actually pay out for someone, which is the story we want members telling.

**Graduation Refund mechanics.** When both members confirm graduation, any unused whole months on a quarterly or yearly plan are credited as coins or refunded to the original payment method (member's choice, one per account, only after the plan has run at least one month). Cost is bounded because graduation is two-sided and rare; the marketing value is not.

**Store fees.** Apple and Google take up to 30%. Ship web checkout (already built on Stripe with a sandbox provider) as the default on the website for all markets where it is permitted, and steer app users to it where the rules allow. In the EU, the Digital Markets Act permits linking out; India permits web billing. Assume a blended 18% fee in the model.

## 4. Unit economics (assumptions to replace with data)

| Metric | Assumption | Note |
|---|---|---|
| Free → Plus conversion | 4–6% of monthly actives | Incumbents run roughly 3–8% depending on market |
| Blended ARPPU per month | India ₹350, Europe €8.50 (after quarterly/yearly mix) | Net of store fees is ~82% of this |
| Coin ARPU (all actives) | India ₹12/month, Europe €0.40/month | Theme packs and gifts |
| Paid retention | 55% month 3, 35% month 6 | Graduation is a healthy churn reason and should be reported separately |
| Blended CAC | India ₹180, Europe €6 | Friend loops are the lever that gets there (below) |
| Payback | Under 3 months in both regions at these numbers | If CAC doubles, quarterly plan mix must rise to hold payback under 5 months |

Run the model per city, not per country. A city that has not reached density will show terrible numbers regardless of pricing.

## 5. Go-to-market: density first, friends second, ads last

### 5.1 The playbook is city by city

A two-sided market with no one nearby is worthless at any price. Every launch city follows the same gates:

1. **Waitlist by city.** Members can sign up anywhere, but discovery opens per city only when the waitlist clears a density threshold (*assumption:* 3,000 verified members with a gender balance no worse than 60/40). Until then the app offers verification, profile, friends, vouches and intros, so early members arrive with a friend graph already built.
2. **Seed the first thousand through friend groups, not ads.** Community groups already exist in the product. Recruit 30–50 group hosts per city (running clubs, climbing gyms, language exchanges, alumni circles, co-working spaces) and give each host a friend-group invite link.
3. **Open discovery with the Today set and the fairness cap on.** The first week's experience decides word of mouth; a curated five with reasons feels nothing like an empty swipe deck.
4. **Measure plans kept, not signups.** A city graduates from "launch" to "live" when weekly plans kept per active member crosses the target (*assumption:* 0.08).

Launch order: Bengaluru (already the densest test cohort), then one more Indian metro; London and Dublin for English; Berlin, Vienna and Zurich for German; Paris; Amsterdam; Warsaw; Madrid, Milan and Lisbon; Russian-language support serves the diaspora in those cities rather than a separate market.

### 5.2 The friend loops are the acquisition engine

Every social feature ships with an invite path for non-members, because each one has a natural reason to bring someone in:

| Loop | Trigger | Who joins | Instrumentation |
|---|---|---|---|
| Plan notifications | "Add a friend who is not on Connect yet" when choosing who gets told | Close friends, safety contacts | Invites sent per plan, accept rate |
| Vouches | A member asks a friend to vouch | Friends who know them well | Vouch requests to non-members |
| Intros | An introducer wants to introduce a non-member friend | Single friends of members | Intro invitations |
| Graduation | "Tell my friends" on confirmation with a referral link | The couple's wider circle | Referral redemptions per graduation |

The single number to manage is the **friend K-factor**: invites accepted per new member in their first 30 days. At 0.5 the paid channels only need to fill the gap to density; at 0.2 the model does not work and the loops need redesign before spending on ads.

### 5.3 Channels by stage

| Stage | Channel | Message |
|---|---|---|
| Pre-launch | City waitlist pages (localised), group hosts, campus and co-working partnerships | "Your city opens when your friends are in" |
| Launch | Earned media on the safety angle, women's safety organisations, local creators who talk about dating fatigue | "It tells your friends when you're on a date" |
| Live | Performance ads only against measured CAC, referral credits, venue partners offering first-date perks to confirmed plans | "Less swiping. More actual dates." |

Venue partners are also a revenue line later (a first-date package booked through a confirmed plan), but do not sell it before plans kept is a stable number.

### 5.4 Localisation is a launch requirement, not a feature

The app and website now ship in en-US, en-GB, de, fr, ru, es, it, pt, nl and pl. Each language launch needs three more things: local venue categories and copy in the plan card, local payment methods (SEPA and iDEAL for NL, BLIK for PL, UPI for India), and a local safety partner named on the safety page. Do not open a language market without all three.

## 6. Metrics and guardrails

North star: **weekly plans kept per active member.** Supporting: match-to-plan within 7 days, plan-to-kept rate, debrief completion, check-in rate, friend K-factor, free-to-Plus conversion, graduation rate.

Guardrails that block growth spend if breached: report and block rate above the FRD tolerance (+2 percentage points), fairness cap bypass rate above zero, "need help" check-ins without a friend acknowledgement within 30 minutes, complaint rate about friend notifications.

## 7. Risks and how the product already answers them

| Risk | Answer |
|---|---|
| Members find friend notifications intrusive | The rule is deliberate and disclosed at proposal time; recipients have their own "friends' plans" toggle; groups are opt-in per plan. Watch the complaint rate and add a per-friend mute before a global off switch. |
| Vouch rings and fake intros | Vouches only from accepted friends, approved by the subject, three shown; intros only between the introducer's accepted friends with preference compatibility; both leave audit events. |
| Copilot makes conversations feel fake | Drafts are marked honestly to the recipient, capped at ten a day for free, and the copilot never sends. |
| Regulation | EU: GDPR and the Digital Services Act; UK: Online Safety Act age assurance; India: DPDP Act. Verification and erasure already exist; age assurance vendor selection is a launch blocker for the UK. |
| Store fees and price tests | Web checkout first; run price tests only on the website where changes are cheap. |

## 8. First 90 days

| Weeks | Milestone |
|---|---|
| 1–2 | Price test page on the website in India and UK; host recruitment kit; safety-partner outreach |
| 3–6 | Bengaluru density push through groups; measure friend K-factor and plans kept weekly |
| 7–10 | Open London and Berlin waitlists; German and UK pricing live; venue partner pilot in Bengaluru |
| 11–13 | Decide on Plus price points from test data; decide whether performance ads start, based on K-factor |

Decision needed from the founder now: approve the "never sell trust or exposure" rule as a company policy, and approve the Graduation Refund as the signature pricing promise.
