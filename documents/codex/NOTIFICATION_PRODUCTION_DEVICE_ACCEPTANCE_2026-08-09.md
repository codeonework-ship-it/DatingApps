# Notification Production Device Acceptance

Date: 2026-08-09

This is a physical-device release gate. Emulator notification UI does not prove
APNs delivery, an Android vendor's background policy, or a terminated iOS app.

## Credential and build prerequisites

1. Select `NOTIFICATION_PUSH_PROVIDER=direct` on the BFF.
2. Configure FCM HTTP v1 using `NOTIFICATION_FCM_PROJECT_ID` and a service
   account file mounted outside the repository. For direct APNs, mount the `.p8`
   key and configure team ID, key ID, bundle ID, and sandbox/production mode.
3. Put only Firebase client identifiers in Flutter configuration. Use
   `PUSH_TOKEN_PROVIDER=fcm` for Android and FCM-routed iOS, or `apns` for direct
   iOS APNs delivery.
4. Sign iOS with the Push Notifications capability and a provisioning profile
   whose application identifier is `com.verifieddating.verifiedDatingApp`.
5. Run `backend/scripts/notification_push_preflight.sh`. It never prints keys or
   raw device tokens.

## Required evidence matrix

Record the provider message ID, outbox ID, device/OS/app version, enqueue time,
visible time, tap route, and final delivery row for every case.

| Platform | App state | Incoming call | Match nudge | Expected |
| --- | --- | --- | --- | --- |
| Android physical device | Foreground | Required | Required | Existing in-app call sheet/banner; no duplicate OS alert. |
| Android physical device | Background | Required | Required | High-priority OS notification; tap opens call details or nudge journey. |
| Android physical device | Terminated | Required | Required | Process starts and routes exactly once after tap. |
| iPhone physical device | Foreground | Required | Required | Existing in-app UX; token remains registered. |
| iPhone physical device | Background | Required | Required | APNs/FCM alert appears; tap routes correctly. |
| iPhone physical device | Terminated | Required | Required | App starts and `getInitialMessage` routes exactly once. |

Also rotate one FCM token, uninstall one app, and send to one invalid APNs token.
Only invalid registrations may be disabled; provider authentication failures must
not disable healthy devices.

## Queue SLO gate

- Queue depth: at most 1,000.
- Oldest pending event: at most 30 seconds.
- Provider success over 15 minutes: at least 99%.
- Outbox-to-provider p95 over 15 minutes: at most 10 seconds when traffic exists.
- Dead-letter count: zero for the acceptance cohort.

Run the check in acceptance mode after the matrix and after the
production-shaped burst:

```
NOTIFICATION_SLO_REQUIRE_TRAFFIC=true backend/scripts/notification_queue_slo_check.sh
```

The flag is required for release evidence. Without it the script is a CI gate
that tolerates an empty window, and an empty window is exactly what a run that
never happened looks like: with zero delivery attempts the metrics view reports
100% success, so the push SLOs would otherwise be reported as met without a
single notification having been sent. In acceptance mode a no-traffic window
fails instead; in CI mode the push SLOs are printed as NOT PROVEN rather than
passed.

Attach its output and the matching Prometheus dashboard window to the release
record.

## Current status

The adapters, token lifecycle, OS capabilities, tap routing, telemetry, and
repeatable gates are implemented. This matrix is not signed off in this
workspace because no FCM/APNs credentials or signed physical devices are
available. Do not mark production delivery complete until all twelve required
device-state cases pass.
