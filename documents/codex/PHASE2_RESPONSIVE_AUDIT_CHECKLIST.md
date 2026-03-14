# Phase 2 Responsive Audit Checklist (Phone + Tablet)

Date: 2026-03-14

## Scope audited in this pass

- Discover home: `app/lib/features/swipe/screens/home_discovery_screen.dart`
- Profile setup basic info: `app/lib/features/profile/screens/setup/setup_basic_info_screen.dart`
- Profile setup photos: `app/lib/features/profile/screens/setup/setup_photos_screen.dart`
- Verification upload/selfie: already scroll-safety patched in previous phase
- Navigation shell and bottom nav spacing: `app/lib/features/common/screens/main_navigation_screen.dart`

## Checklist

- [x] Compact-width discover header actions reflow without clipping (`Wrap` in compact mode)
- [x] Discover message icon/button restored and wired (`onOpenMessages`)
- [x] Discover compact-height action spacing tuned to reduce bottom overflow risk
- [x] Profile setup basic info converted to scroll-safe body for small heights
- [x] Basic info visual hierarchy cleaned (clear title/subtitle/spacing)
- [x] Mock flag isolation improved (`USE_MOCK_DISCOVERY_DATA`)
- [x] OTP bypass default made safe (`BYPASS_OTP_VALIDATION=false` default)
- [x] Release guard blocks mock modes in release
- [x] Android baseline aligned for 2020-2026 support window (`minSdk 29`, `target/compileSdk 36`)

## Automated coverage added

- New widget tests: `app/test/features/profile/screens/setup_basic_info_screen_test.dart`
  - compact phone render without exceptions
  - tablet render without exceptions
  - validation: short name
  - validation: missing DOB
  - valid flow navigates to Photos

## Notes

- This pass validates core high-risk flows and responsiveness for key setup/discover surfaces.
- A true "all screens" guarantee requires running visual+interaction checks for each screen/device profile in CI (e.g., screenshot golden + integration tests).
