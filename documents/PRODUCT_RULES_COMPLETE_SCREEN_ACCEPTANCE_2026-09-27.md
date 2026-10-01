# Product rules and complete-screen acceptance — 27 September 2026

## Decision

The P1 product rules are approved in
`documents/contracts/product_screen_acceptance.v1.json` and enforced by the
release-governance gate. Local automated acceptance is complete. Production
remains `NO_GO` until the signed release build passes the physical-device,
supported-OS, permission and network matrix in that contract.

## Approved semantics

| Surface | Approved rule |
|---|---|
| Activities | `co_op_prompt`, `this_or_that` and `value_match_round` are the only accepted types. A session lasts 120 seconds. The replay window is seven days and `this_or_that` is capped at two starts per match per window. Active responses may be replaced; terminal sessions are immutable. |
| Discovery | Server preferences and safety rules select eligible candidates before presentation. Spotlight cannot bypass either and retains a non-premium fairness allocation. A filtered match stays a match. Undo revisits the prior current-session card. Super Like is an uncharged Like presentation alias in this release and makes no priority claim. |
| Chat | The local destructive-action cancellation window is four seconds; delete-for-everyone is available for 24 hours. Delivered means authenticated socket handoff, not human receipt. Read means the recipient opened the conversation and advanced the durable cursor. Reconnect replaces stale local deletion/read state from authoritative history. |
| Prompts and nudges | One daily answer may be edited for ten minutes. Streak milestones are three and seven days. Nudges are capped at two per UTC day, respect delivery preferences, and are suppressed by relevant safety state for 14 days. Resumption links back to one trigger nudge. |
| Groups and friends | A coffee poll contains the creator plus one to three invitees. Only participants vote; their latest pre-finalization vote wins. Only the creator finalizes. Friend adds are pending requests; only the recipient accepts or declines. Blocking removes the relationship/request. |
| KPIs | DAU is trailing-24-hour unique authenticated members; MAU is trailing-30-day unique authenticated members. Every rate names numerator, denominator, source, scope and window. An unsatisfied source is unavailable rather than zero. Safety rollout tolerances use absolute percentage points. |

## Local acceptance delivered

- Every discovered Flutter `*Screen` is kept in one self-auditing matrix. The
  current 55 screens run at five viewport sizes in both light and dark themes,
  plus a smallest-phone pass at Android font scale 1.3. Semantics are enabled
  for every pump. The matrix therefore contains 550 standard layout cases, 55
  large-text cases and the coverage invariant.
- The large-text sweep found and fixed nine overflows across brand, discovery,
  settings, chat, profile, setup and identity-verification surfaces.
- Android automation covers background/foreground, authenticated process death
  and restart at font scale 1.3. Existing suites cover permission denial,
  offline/error presentation, filters/preferences, negative auth, discovery,
  matches and chat.
- The first live process-death run exposed that native sessions were memory-only.
  Native refresh credentials now persist in the operating-system secure store;
  access credentials remain memory-only; cold startup rotates the refresh
  credential before rendering an authenticated route; logout removes it. The
  three-case Android resilience rerun passed and is recorded at
  `qa/reports/appium/product-screen-2026-09-27-rerun/android-smoke.html`.
- Unknown activity types now fail at both runtime and repository boundaries.
- Friendship now requires recipient consent instead of creating a two-way
  relationship immediately. Incoming/outgoing pending state is visible in the
  app; accept, decline, cancel/remove and blocking are explicit transitions.
- Contract mode checks both the policy shape and implementation anchors. Launch
  mode fails closed while representative-device evidence is incomplete.

## Remaining production evidence

Repository automation cannot certify real OEM behavior, thermal/memory
pressure, OS permission surfaces, real network transitions or iOS behavior.
Attach results for the six representative-device rows in the contract, switch
their status only after the signed current build passes, then record an approved
`GO`. Until then, local completion does not imply production acceptance.

## Verification on the current workspace build

| Check | Result |
|---|---|
| Flutter complete suite | 933 passed |
| Complete-screen responsive/accessibility matrix | 606 passed |
| Android Appium resilience rerun | 3 passed: background, process death and 1.3 font restart |
| Appium/API non-device matrix | 31 passed, 3 intentionally skipped because they require opt-in mutation or a second synthetic member |
| Backend Go suite | `go test ./...` passed |
| Release governance contract mode | All six contract groups passed; production decision remains `NO_GO` |
| Android build | Debug split APKs built and the arm64 build was installed on the API 36 emulator |
| Web build | Release build completed and is served from the current local `/app/` path |
| Static analysis | No compile errors under the repository gate; existing lint/info debt remains and is not treated as product acceptance evidence |

## Backlog disposition

PEN-28–32 are approved and implemented locally. PEN-33 is complete for local
member-screen layout and negative automation. PEN-34 has approved semantics,
while DAU/MAU must remain unavailable until a durable aggregate exists. PEN-44
is locally automated and remains open for representative physical-device
evidence.
