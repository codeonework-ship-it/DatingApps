# Login, discovery and preference logic improvements

Implemented and verified locally on 26 September 2026. This is a focused hardening pass across the three connected features, not certification of every completed feature or production release readiness.

## Changed behavior

### Login and session handling

- Duplicate login/signup submissions are ignored while authentication is pending.
- Cancelling/resetting authentication or logging out invalidates pending responses. A delayed login cannot restore a cancelled session.
- Failed profile bootstrap clears temporary signup credentials. The created server account may still need bootstrap recovery; full signup recovery remains separate work.
- Logout clears local authentication even if push deregistration or server logout fails, while preventing an older logout from clearing a subsequent session.
- Refresh responses carry a session revision check. A late refresh cannot restore a logged-out session or overwrite a new login.
- Transient refresh network errors retain credentials for retry. An explicit credential rejection clears the current session.

### Discovery

- Initial discovery enforces saved seeking genders, age bounds, education, verification and serious-relationship preference. Opening the filter sheet is no longer required.
- Explicit query values override saved defaults; false and an explicitly present empty list are respected. Manual discovery filters do not rewrite saved partner preferences. Resetting the sheet affects its exposed controls; saved gender/education/serious criteria continue to apply unless explicitly overridden or edited in Preferences.
- Candidate eligibility reads current published identity attributes and the published profile snapshot, not an incomplete or mutable private draft. Gender aliases and serious-intent tags are normalized.
- Trust filtering runs before response trimming so rejected candidates do not consume the requested result count.
- Older asynchronous discovery responses cannot replace newer filter results. Successful loads clear prior errors, and changing accounts resets the provider's deck and manual filters.
- The private date of birth is removed from public profile, discovery and spotlight projections. When age visibility is enabled, the public response supplies an integer age. When disabled, age is absent. Client models and profile/card headings support that absence without fabricating a birthday.

### Preferences

- Draft-loading failures display the existing retry/error screen instead of substituting an editable empty/default profile that could overwrite saved values.
- Preference and discovery editors share age bounds 18–80 and distance bounds 1–500 km. The age maximum follows the existing supported signup contract; distance preserves the broader existing discovery range. Existing valid saved values are no longer silently truncated to 60 years/200 km by the preference editor.
- Successful preference saves invalidate discovery so the next deck uses the new saved criteria.

## Validation

| Check | Result | Evidence under `qa/results/2026-09-26-logic/` |
|---|---|---|
| Full Flutter unit/widget/golden suite | 838 passed | `flutter-final.jsonl` |
| Signed-in layout matrix | 531 passed: 53 screens × 5 sizes × 2 themes, plus inventory guard | `layout-final.jsonl` |
| Go backend suite, including local PostgreSQL integration | 484 tests/subtests passed | `backend-final.jsonl` |
| Targeted live API contracts | 12 passed | `api-final.xml` |
| Android device journeys | Login, preference save, saved-filter reopen: 3 passed | `android.xml` |
| Flutter analysis | No errors or warnings; 407 informational findings | `analyze-final.log` |
| ARM64 QA debug build | Passed; installed on isolated emulator-5556 | `apk-build.log` |

The Android checks used the new APK and initial updated BFF. The final published-candidate filtering correction was subsequently covered by PostgreSQL integration and live API checks. The previous full 43-scenario device run was not repeated in this pass. Layout fixtures do not prove real provider or end-to-end behavior.

Regression coverage includes delayed/cancelled login, duplicate submissions, failed signup bootstrap, refresh during logout/new login, transient versus rejected refresh, out-of-order discovery loads, error recovery, failed draft loading, hidden-age rendering, positive/negative saved eligibility, explicit overrides, serious-intent aliases, and filtering published profiles whose private drafts are incomplete.

Two existing API assumptions were corrected: saved restrictive preferences may legitimately produce an empty deck, while the public-profile contract explicitly requests a broad eligible pool. A separate positive broad-discovery fixture still requires candidates; the tests do not accept an always-empty endpoint.

The original live age-privacy regression now passes. Historical failed runs remain in the evidence directory; final JSON/XML files identify the passing revision. `summary.json` records counts and the APK checksum.

## Remaining architecture work, in priority order

1. **Geographical eligibility:** distance controls still require consented location storage and server distance enforcement, with known near/far fixtures. The shared slider limit is not evidence of distance enforcement.
2. **Eligibility at scale:** move candidate constraints and pagination into database/repository queries. Current overfetch remains capped at 300, and persisted preference read failures need an explicit fail-closed service contract instead of existing store fallbacks.
3. **Durable edits:** finish save-on-navigation/process-death behavior, serialize overlapping profile writes and validate preference bounds/types consistently on the server. About/Preferences Back behavior is not fully certified.
4. **Session lifecycle:** persistent session restoration, synchronization of terminal refresh rejection with the app gate, and account-created/bootstrap-failed recovery need dedicated end-to-end work.
5. **Filter contract:** extend the shared bounds to remaining secondary surfaces, define Spotlight filtering for hidden ages, and refresh open filter-sheet state after a separate preference edit. Manual/default/Reset semantics should be made visible consistently in the UI.
6. **Release acceptance:** real identity/payment/push providers, physical devices, accessibility, other Android versions, iOS and release builds remain outside this pass.

The public age response is a contract change: deploy the updated mobile client and backend together. Existing clients that depend on public birth dates need migration. No production deployment or release sign-off was performed.
