# Release contract and governance — 27 September 2026

## Outcome

The Release contracts and governance epic now has one versioned source of
truth: [`contracts/release_contract.v1.json`](contracts/release_contract.v1.json).
It resolves the product and architecture baseline for PEN-14–17, PEN-25–27 and
PEN-46 and makes contract drift a release-regression failure.

This completes the governance *definition*. It does not claim that production
is ready. The current production decision is deliberately `NO_GO` because
named human owners, target-environment evidence and server/client enforcement
of every excluded capability have not been recorded. The strict launch gate
will fail until those facts are supplied.

## Approved rules

### Authentication and eligibility

- Usernames are immutable after creation, normalized with trim + lowercase,
  and contain 3–30 ASCII letters, numbers, dots or underscores with an
  alphanumeric first and last character.
- Passwords contain 8–72 UTF-8 bytes, at least one ASCII letter and one digit.
  Seventy-two bytes matches the bcrypt implementation boundary. Signup,
  recovery, password change and Flutter validation now share it.
- Connect supports adults aged 18–80. Eligibility uses calendar age at request
  time in UTC. The UI requires an explicit gender selection from `M`, `F`, or
  `Other`; it no longer silently defaults a new member to `F`.
- Identity verification is a separate state. It is not required to create an
  account or enter discovery in the first-release baseline.

### Public profiles

- Publication requires 100% profile completion and at least two current,
  active, approved photos.
- Public detail, discovery and spotlight share the same publication predicate.
- Current enforcement and media state override retained completion snapshots.
- The public response uses an explicit allowlist. Another member's mutable
  private draft is never a fallback.

### Economy and quests

- The first production release excludes checkout, coin purchase and all gifts.
  The canonical currency remains INR/paise for the separately owned billing
  work. Enabling money requires provider acceptance, approved prices,
  settlement reconciliation, disputes/refunds and concurrent-spend proof.
- Quest unlock is excluded from the first release. Its future role model is
  gender-neutral: a template owner, either participant as submitter, and the
  other participant as reviewer. Self-review and assisted review are off.
  Activation requires server-enforced roles, pending-review template freeze,
  cooldown/attempt acceptance, appeals ownership and negative authorization
  tests.

These exclusions are product decisions, not assertions that route hiding is
already complete. `GOV-002` blocks production GO until shipped clients hide the
capabilities and their server commands reject direct or stale-client requests.

## First release scope

The `Connect Core closed beta` includes username/password access, profile
creation/editing, preferences, filters, public discovery, matching, text chat,
block/report/unmatch and account settings.

Real-money billing, coin purchase, gifts, quests, calls, voice icebreakers,
the verified identity badge, production push notifications and XP progression
remain outside the first release. This lets the core relationship journey move
through staging without weakening provider, financial, privacy or operations
gates.

## Ownership and GO/NO-GO

The contract assigns accountable roles for Product, Architecture/Backend,
Client Engineering, Trust & Safety, QA/Release, Production Operations and the
separate Billing stream. Named people are intentionally blank because the
repository cannot truthfully invent human approvals.

Production becomes `GO` only when:

1. every P0 gate is `passed` with evidence;
2. every required area has a named owner;
3. the decision is `GO` with a UTC timestamp; and
4. the versioned contract and implementation anchors still validate.

Run the contract check used by local release regression:

```bash
./qa/governance/run_release_governance_gate.sh contract
```

Run the fail-closed production decision check:

```bash
./qa/governance/run_release_governance_gate.sh launch
```

The second command is expected to fail while the recorded decision is
`NO_GO`. Its JSON evidence is written to `qa/reports/release/`.

## Backlog disposition

| Item | Governance disposition |
|---|---|
| PEN-14 | Public profile contract approved and locally implemented. |
| PEN-15 | Publication baseline approved and locally implemented; verification remains independent. |
| PEN-16 | Username and password boundaries approved and aligned across current backend/Flutter paths. |
| PEN-17 | Calendar age 18–80 and explicit gender selection approved. |
| PEN-25 | Money excluded from first release; billing owner retains activation approval. |
| PEN-26 | Gifts excluded until the economy activation gate passes. |
| PEN-27 | Quests excluded; future gender-neutral role contract approved. |
| PEN-46 | Scope, accountable roles, P0 rule and fail-closed decision mechanism defined; production remains `NO_GO`. |

## Verification boundary

The governance gate checks the JSON structure, non-overlapping release scope,
P0 gate integrity, complete PEN mapping and core source anchors for username,
password, age, gender, publication and assisted-review defaults. It is a fast
drift check; focused backend and Flutter tests still prove behavior.
