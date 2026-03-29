# ALN-4.2 Rollback Communication Template (3 Mar 2026)

## Audience Channels
- Engineering: `#eng-backend`, `#eng-mobile`
- Product: `#product-engagement`
- Moderation Ops: `#moderation-ops`
- Incident Room: `#incident-engagement-launch`

## Message Template (Initial Rollback Notice)
```
[ALN-4.2] Rollback initiated
Time (UTC): <timestamp>
Decision owner: <name>
Reason: <brief summary>
Scope: <features/flags impacted>
Actions in progress:
1) Disable feature flags
2) Restart services with known-good config
3) Re-run health and critical API smoke checks
Next update ETA: <minutes>
```

## Message Template (Rollback Complete)
```
[ALN-4.2] Rollback complete
Time (UTC): <timestamp>
Final state: <stable/degraded>
Health checks: <pass/fail summary>
API smoke: <pass/fail summary>
User impact window: <duration>
Follow-up owner: <name>
Postmortem ETA: <date/time>
```

## Checklist Before Sending
- [ ] Incident commander has approved message text.
- [ ] Product manager has reviewed user-impact wording.
- [ ] Moderation owner has acknowledged operational impact.
- [ ] Latest health and smoke outputs are attached.

## Signoff
- Incident Commander: __________
- Product Manager: __________
- Backend Lead: __________
- Trust & Safety Ops Lead: __________
- Timestamp (UTC): __________
