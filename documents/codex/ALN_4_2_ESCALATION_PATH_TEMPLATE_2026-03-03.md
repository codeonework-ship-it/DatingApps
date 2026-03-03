# ALN-4.2 Safety-Critical Escalation Path Template (3 Mar 2026)

## Trigger Conditions
Escalate immediately when any of the following occurs:
- Threat of self-harm, violence, or credible safety risk.
- Potential wrongful moderation action with high user harm impact.
- Appeals queue backlog exceeds SLA tolerance (older than 24h without owner response).

## Escalation Chain
1. Shift Moderator (first triage)
2. Appeals Queue Owner (decision owner)
3. Trust & Safety Manager (policy override authority)
4. Incident Commander (cross-functional coordination)
5. Product + Engineering leads (release impact decision)

## Contact Matrix

| Role | Primary Contact | Backup Contact | Channel | Paging Method |
|---|---|---|---|---|
| Shift Moderator | PENDING | PENDING | `#moderation-ops` | PENDING |
| Appeals Queue Owner | PENDING | PENDING | `#moderation-ops` | PENDING |
| Trust & Safety Manager | PENDING | PENDING | `#trust-safety` | PENDING |
| Incident Commander | PENDING | PENDING | `#incident-engagement-launch` | PENDING |
| Backend Lead | PENDING | PENDING | `#eng-backend` | PENDING |
| Flutter Lead | PENDING | PENDING | `#eng-mobile` | PENDING |

## Incident Handoff Fields (fill during dry-run)
- Incident ID / reference: __________
- Trigger detected at (UTC): __________
- Incident commander assigned at (UTC): __________
- Owning queue (moderation/platform/product): __________
- Current severity: [ ] SEV-1 [ ] SEV-2 [ ] SEV-3

## Time Targets
- Acknowledge page: <= 15 minutes
- Initial containment decision: <= 30 minutes
- Final owner assignment: <= 60 minutes

## Verification Check
- [ ] All primary + backup contacts are named.
- [ ] Paging method tested for incident commander and trust & safety manager.
- [ ] Escalation chain validated in rehearsal walkthrough.

## Signoff
- Trust & Safety Ops Lead: __________
- Incident Commander: __________
- Timestamp (UTC): __________
