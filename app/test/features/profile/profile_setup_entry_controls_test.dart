// Test names carry literal catalog case ids, which can be long.
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/profile/screens/setup/profile_setup_entry_screen.dart';
import 'package:verified_dating_app/features/profile/screens/setup/setup_about_screen.dart';
import 'package:verified_dating_app/features/profile/screens/setup/setup_photos_screen.dart';
import 'package:verified_dating_app/features/profile/screens/setup/setup_preview_screen.dart';

import '../../support/qa_api.dart';
import '../../support/qa_screen_quality.dart';
import 'support/profile_bff.dart';

// Screen-level checks for the setup entry router (ProfileSetupEntryScreen):
// it reads the signup workflow and the draft from the recording fake BFF and
// resumes at the first missing step, so each check runs once per place a
// member can resume (photos, about, preview) with that step's real content.
// Its Retry and l10n cases live in setup_preview_entry_controls_test.dart.

/// Where the entry screen resumes for a draft, and what only that step shows
/// once the draft arrived.
final _resumes = <(String, Map<String, dynamic>, Finder Function())>[
  (
    'photos (one of two photos)',
    qaDraftJson(photoCount: 1, bio: ''),
    () => find.byKey(
      const ValueKey('qa.setup.photos.delete_p1'),
      skipOffstage: false,
    ),
  ),
  (
    'about (photos, no bio)',
    qaDraftJson(photoCount: 2, bio: ''),
    () => find.byKey(
      const ValueKey('qa.setup.about.bio_field'),
      skipOffstage: false,
    ),
  ),
  (
    'preview (complete)',
    qaDraftJson(photoCount: 3),
    () => find.byKey(
      const ValueKey('qa.setup.preview.complete_button'),
      skipOffstage: false,
    ),
  ),
];

QaApi _api(Map<String, dynamic> draft) {
  final api = QaApi();
  ProfileBff(api, draft: draft);
  api.json('GET /auth/signup/workflow/*', {
    'state': 'in_progress',
    'current_activity': 'profile',
  });
  return api;
}

void main() {
  group('screen quality', () {
    testWidgets(
      'setup entry lays out on phone and tablet in both themes at '
      'every step it resumes at [case:profile.profile_setup_entry.layout_matrix]',
      (tester) async {
        for (final (_, draft, loaded) in _resumes) {
          await qaExpectLaysOutOnPhoneAndTablet(
            tester,
            api: () => _api(draft),
            build: () => const ProfileSetupEntryScreen(),
            extra: qaMasterDataOverrides,
            loaded: loaded,
          );
        }
      },
    );

    testWidgets(
      'setup entry meets tap-target, label and contrast guidelines '
      'at every step it resumes at [case:profile.profile_setup_entry.a11y_guidelines]',
      (tester) async {
        for (final (_, draft, loaded) in _resumes) {
          await qaExpectMeetsA11yGuidelines(
            tester,
            api: () => _api(draft),
            build: () => const ProfileSetupEntryScreen(),
            extra: qaMasterDataOverrides,
            loaded: loaded,
          );
        }
      },
    );

    testWidgets('the three drafts above really resume at photos, about and '
        'preview', (tester) async {
      for (final (where, draft, _) in _resumes) {
        await qaQualityPump(
          tester,
          _api(draft),
          const ProfileSetupEntryScreen(),
          extra: qaMasterDataOverrides(),
        );
        final expected = where.startsWith('photos')
            ? SetupPhotosScreen
            : where.startsWith('about')
            ? SetupAboutScreen
            : SetupPreviewScreen;
        expect(find.byType(expected), findsOneWidget, reason: where);
        await qaQualityUnmount(tester);
      }
    });
  });
}
