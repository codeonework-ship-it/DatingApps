# Calls, identity, voice and push provider delivery

Date: 2026-09-27  
Decision: **Production NO_GO pending external acceptance evidence**

## Delivered

- Calls use a configured private Jitsi origin and short-lived HS256 tokens scoped to the authenticated member and room. Production configuration rejects public Jitsi and incomplete signing credentials.
- Identity document and selfie evidence is signature/dimension validated, stored privately, and sent to a configured provider as multipart bytes. Only `approved`, `rejected`, and `manual_review` are accepted. Provider outages fail closed.
- Voice recording duration is enforced by the server. Audio is moderated before delivery; rejected or manual-review audio is deleted. Approved audio is available only to conversation participants through short-lived signed playback URLs.
- FCM HTTP v1 and APNs HTTP2 delivery, device-token lifecycle, invalid-token cleanup, retries, dead letters, and queue SLO reporting are implemented.
- `matching.voice_moderation_events` records provider/model/decision evidence and participates in the event-source registry.

## Release evidence still required

- Configure the selected Jitsi, identity, voice, FCM and APNs credentials in the target environment without checking secrets into the repository.
- Run paired physical-device calls across permission denial, backgrounding and network changes.
- Run an approved labelled identity/liveness corpus and voice-safety corpus through the selected providers.
- Complete Android and iPhone foreground/background/terminated delivery for incoming calls and match nudges, plus token rotation and invalid-token cases.

The machine-readable source of truth is [`contracts/provider_acceptance.v1.json`](contracts/provider_acceptance.v1.json). `qa/governance/run_release_governance_gate.sh launch` refuses a production GO until every required item has passed evidence.
