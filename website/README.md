# Connect website

Public website plus the existing authenticated Connect app, compiled for browsers.
The app shares its Go API, PostgreSQL state, feature rules and Flutter screens with
Android. The Django operator console remains a separate authenticated service.

## Run locally

1. Start the repository's local PostgreSQL, API gateway and mobile BFF stack. The
   default gateway for this website is `http://127.0.0.1:18080`.
2. Run `bash website/build.sh` from the repository root. Set `FLUTTER_BIN` if the
   Flutter installation differs from this workstation's configured path.
3. Run `node website/server.mjs` and open `http://127.0.0.1:4190/`.

The member build lives in `website/.build/app/`, separate from other app builds.
Public pages are in `public/`. Edit their content in `generate_pages.py`, then run
`python3 website/generate_pages.py`. Styles and browser interactions are separate.
`npm ci --prefix website` installs the browser test runner; serving needs only Node.

## Routes and integration

- `/`, `/features`, `/safety`, `/privacy`, `/guidelines`, `/membership`: public HTML.
- `/app/#/signup`, `/app/#/signin`: account entry.
- `/app/#/discover`, `/matches`, `/engagement`, `/profile`, `/settings`: primary app
  sections (each path follows `/app/#`).
- `/app/#/features`: member feature directory. Individual routes are registered in
  `app/lib/features/web/web_member_workspace.dart`.
- `/v1/*`: same-origin API proxy; authenticated chat and notification WebSocket
  upgrades use the same origin. The gateway receives the original Host so its
  origin check and media URLs match the browser.

`CONNECT_API_UPSTREAM`, `PORT` and `HOST` configure the server. It binds to loopback
by default. `WEB_ALLOWED_HOSTS` is a comma-separated allowlist and must include the
public host when the server is placed behind a reverse proxy. `WEB_MAX_PROXY_BODY_BYTES`
defaults to 25 MiB so the proxy can accept identity evidence while bounding streamed
request bodies. `WEB_API_BASE_URL` is an optional Flutter compile-time override; the
normal web build derives `/v1` from the page origin. Mobile configuration files are
removed from web build assets. Never put server credentials in Flutter defines.

Browser photo uploads send picked bytes, without `dart:io`. Local media URLs are
normalized to the browser's same-origin media proxy. Browser sockets carry opaque
access credentials in an upgrade subprotocol header, never the URL; the BFF accepts
this only for its two same-origin authenticated stream paths and echoes only the
version protocol.

A rotating refresh credential is held in this tab's `sessionStorage`. Reload first
validates it against the backend; access tokens stay in memory. Logout clears the
local session and requests server revocation. This is not an HttpOnly-cookie auth
architecture: any future third-party scripts require a fresh security review.

## Checks

Run `npm test --prefix website` with the local stack running. Chrome's default
macOS path can be overridden by `CHROME_BIN`. Use a completed, isolated test member
via `QA_EXISTING_USERNAME` and `QA_EXISTING_PASSWORD`; defaults identify the existing
local QA fixture. The upload test creates a paused synthetic account and removes
its uploaded media afterward. Tests never need a real customer account. Browser artifacts go
to ignored `qa/results/2026-09-27-website/` and may contain test account information.

The suite covers public pages, responsive widths, search, keyboard navigation,
links, authentication, live stream connection, preferences save, browser history,
refresh recovery, logout, photo upload, onboarding completion and member-route rendering. Route coverage is
not a claim that every business mutation or external integration was exercised.
Flutter widget/provider tests and Go stream security tests complement it.

## Release boundaries

This is a local development website, not a published production deployment.
Production hosting needs HTTPS/WSS termination, restricted upstream access,
provider configuration, approved privacy/terms content and operational acceptance.
Keep the public proxy as the sole browser API entry; do not blindly trust forwarded
headers from arbitrary clients. A production proxy must preserve the actual
external host and protocol through the gateway. Keep BFF profiling, metrics and
documentation listeners on an authenticated operations network; the public gateway
does not expose the Go profiler.

Billing is being updated separately; do not reintroduce the old local activation
flow or treat a hosted checkout redirect as settled payment. Hosted browser checkout
uses the provider URL returned by the billing API and waits for server confirmation.
Live call rooms use the configured `CALL_ROOM_BASE_URL`; development defaults to
Jitsi Meet, while production requires an approved private deployment. Browser and
native voice capture upload validated private audio, and identity verification
uploads private document/selfie evidence. Voice playback and automated identity
provider decisions still require their production integrations.
The consolidated FRD and its decision register remain authoritative for unresolved
requirements; website navigation does not mark those requirements complete.
