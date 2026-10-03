// Test names carry literal catalog case ids, which can be long.
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/profile/screens/profile_viewers_screen.dart';

import '../../support/qa_api.dart';
import '../../support/qa_screen_quality.dart';
import '../swipe/discover_qa_fixtures.dart' show qaSilenceNetworkImages;

// Screen-level checks for "Who viewed my profile" (ProfileViewersScreen),
// fed by the recording fake BFF's GET /profile/{id}/viewers. The list's
// controls (open, retry, empty) are proven from My Profile in
// profile_view_controls_test.dart.

/// Recent visitors as the BFF lists them: some with a photo, one without a
/// name (shown by id), one with no visit time ("viewed recently").
const _viewers = [
  {
    'user_id': 'rhea',
    'name': 'Rhea',
    'photo_url': '',
    'viewed_at': '2026-09-30T18:45:00Z',
  },
  {
    'user_id': 'arjun',
    'name': 'Arjun Venkataraman-Iyer',
    'photo_url': 'https://example.com/arjun.jpg',
    'viewed_at': '2026-09-29T08:10:00Z',
  },
  {'user_id': 'noname-7', 'name': '', 'photo_url': '', 'viewed_at': ''},
  {
    'user_id': 'leela',
    'name': 'Leela',
    'photo_url': '',
    'viewed_at': '2026-09-20T21:05:00Z',
  },
];

QaApi _api() {
  final api = QaApi()..json('GET /profile/me/viewers', {'viewers': _viewers});
  return api;
}

void main() {
  // Visitor photos never load in widget tests; keep them loading instead of
  // failing with the test client's HTTP 400.
  qaSilenceNetworkImages();

  group('screen quality', () {
    // A visitor's name only renders once the list arrived.
    Finder loaded() => find.text('Rhea', skipOffstage: false);

    testWidgets('Who viewed my profile with visitors lays out on phone and '
        'tablet in both themes [case:profile.profile_viewers.layout_matrix]', (
      tester,
    ) async {
      await qaExpectLaysOutOnPhoneAndTablet(
        tester,
        api: _api,
        build: () => const ProfileViewersScreen(),
        loaded: loaded,
      );
    });

    testWidgets('Who viewed my profile meets tap-target, label and contrast '
        'guidelines [case:profile.profile_viewers.a11y_guidelines]', (
      tester,
    ) async {
      await qaExpectMeetsA11yGuidelines(
        tester,
        api: _api,
        build: () => const ProfileViewersScreen(),
        loaded: loaded,
      );
    });

    testWidgets('Back on Who viewed my profile returns to the screen that '
        'opened it [case:profile.profile_viewers.back_affordance]', (
      tester,
    ) async {
      final api = _api();
      await qaExpectBackReturnsToOpener(
        tester,
        api: api,
        build: () => const ProfileViewersScreen(),
        screen: find.byType(ProfileViewersScreen),
        loaded: loaded(),
      );
      expect(api.sent('GET', '/profile/me/viewers'), hasLength(1));
      expect(api.writes, isEmpty);
    });
  });
}
