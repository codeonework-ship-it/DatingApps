# Connect website implementation — 27 September 2026

## Scope

The website exposes the existing member product through a browser build rather
than duplicating its business rules in a second client. Six responsive public
pages introduce the product and link to 31 feature entries. Desktop members get
persistent section navigation and a feature directory; narrow screens retain the
mobile app layout. The public design follows the current Ember palette, Figtree
interface typography and Bodoni display typography.

Source requirements: [consolidated FRD](CONSOLIDATED_FRD.md),
[traceability](REQUIREMENTS_TRACEABILITY.md), and
[product/architecture review](PRODUCT_ARCHITECTURE_REVIEW.md).

## Feature access and limits

| Requirement area | Website surface | Boundary |
|---|---|---|
| AUTH, terms and onboarding | Sign in, signup, agreement, resumable profile setup; validated reload recovery | Existing backend owns identity and completion gates |
| PROF | Profile editing, photos, preview, dating/lifestyle preferences | Browser picker sends bytes; local media uses same-origin URLs |
| DISC and trust | Discovery, saved preferences, trust filters, badges | Existing eligibility, mutual-match and safety rules retained |
| UNLK, CHAT, GIFT | Matches and eligible conversation flows, quests, gestures, activities, gifts/wallet | Existing match/unlock gates; no claim of production paid settlement |
| Realtime and NOTIF | Authenticated chat/notification streams, inbox and category settings | Browser upgrade auth added without weakening origin checks; push-provider activation remains separate |
| Engagement and XP | Daily prompts, levels/rewards, challenges, rooms, groups, polls, nudges, friends | Uses existing persisted APIs; empty/error states are retained |
| Safety/account | Reporting/blocking routes, appeals, contacts, privacy, export/deletion controls, help | No simulated emergency response; production policy/provider gates remain |
| Verification | Document/selfie upload and status view | Evidence is validated and privately stored; production identity-provider review remains separate |
| Voice and calls | Microphone recording, private voice upload, provider live rooms and call history | Production requires an approved private room host; voice playback remains pending |
| Billing | Public membership information and hosted browser checkout | Concurrent billing implementation is owned separately; settlement still requires provider verification |
| Admin | Existing Django operator console | Not exposed as an unauthenticated public/member page |

## Architecture changes

- Same-origin static/API/WebSocket Node server; local binding by default.
- Browser-specific session context, photo rendering and socket connectors preserve
  native platform behavior.
- Flutter Router owns shareable section URLs and browser history.
- Profile uploads use multipart bytes; JavaScript-safe BigInt replaces an integer
  constant that prevented the Dart web compiler from building.
- Verification replaces browser-local file paths with authenticated multipart
  document/selfie uploads in a private storage namespace.
- Voice icebreakers record 20–45 seconds from the browser or device microphone,
  validate the audio container, and persist integrity metadata without exposing
  storage keys. Active calls open the server-provided provider room URL.
- Browser session restore rotates the refresh credential before treating a member
  as authenticated. Passwords are not persisted.
- Public HTML remains readable without the Flutter runtime. Search/menu JavaScript
  enhances the feature directory and narrow-screen navigation.
- Account-saved theme presets now apply to both browser and native clients. The
  Star Wars preset adds an original deep-space palette and generated starfield
  atmosphere without external artwork or runtime image requests.

## Acceptance evidence

See `website/tests/`, `app/test/core/network/browser_media_urls_test.dart`,
`backend/internal/bff/mobile/browser_socket_auth_test.go`, and the local artifacts
under `qa/results/2026-09-27-website/`. Final test results are recorded below. Route/render checks are deliberately separate from business-workflow
acceptance. A local pass does not certify all 111 FRD requirements or production
capacity, compliance, external delivery or payment settlement.

### Final local results

| Check | Result |
|---|---|
| Release web build | PASS; independent output at `website/.build/app`, `/app/` base path, local CanvasKit assets |
| Chrome/Playwright | 21/21 PASS, including Star Wars selection and reload persistence |
| Member route coverage | All 26 checked destinations at 390px and 1440px, including browser Appearance controls |
| Public responsive coverage | Six pages at 360px and 1440px; images, content, overflow, navigation, search and links |
| Browser workflow acceptance | Valid login, authenticated live stream, preference save, filters, deep link, reload restoration, history, logout; gallery upload, durable media reload, hosted-checkout control, microphone capture entry, verification entry, paused QA profile completion and post-completion logout; signup-to-signin link |
| Flutter | 872/872 PASS, including 550 screen layouts across five sizes and two themes |
| Android | Debug APK built, installed and launched on `emulator-5556`; `MainActivity` remained foreground with no fatal exception |
| Analyzer | No errors or warnings; existing/informational style findings remain |
| Go | Browser socket authentication and chat/notification realtime tests PASS |
| Visual review | Public homepage, member profile and generated route screenshots reviewed; light-profile contrast fixed |

The responsive harness now includes the separately added native checkout host,
using a non-networking platform view to test app chrome. It exposed a small-phone
notice overflow, fixed by allowing the notice text to wrap. This does not validate
provider pages or settle a payment. Billing logic and provider integration remain
owned by the concurrent billing work.

The browser member app uses the hosted-checkout launcher supplied by the separate
billing implementation. It opens the provider page and waits for backend-confirmed
status before reflecting access. See the separate
[PEN-01 report](codex/completed/PEN01_CARD_SUBSCRIPTION_CHECKOUT_REPORT_2026-09-27.md)
for billing progress and provider acceptance still required.

The website build directory is isolated because another app build overwrote the
shared `app/build/web` output with a different base path during QA. The final run
uses the independent output, preventing that collision. No remote deployment was
performed. Safari/Firefox, real provider delivery and every possible business
mutation are not certified by these checks.
