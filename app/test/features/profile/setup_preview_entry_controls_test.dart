// Test names carry literal catalog case ids, which can be long.
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/i18n/app_l10n.dart';
import 'package:verified_dating_app/core/widgets/glass_widgets.dart';
import 'package:verified_dating_app/features/common/screens/main_navigation_screen.dart';
import 'package:verified_dating_app/features/profile/screens/setup/profile_setup_entry_screen.dart';
import 'package:verified_dating_app/features/profile/screens/setup/setup_about_screen.dart';
import 'package:verified_dating_app/features/profile/screens/setup/setup_photos_screen.dart';
import 'package:verified_dating_app/features/profile/screens/setup/setup_preview_screen.dart';

import '../../support/qa_api.dart';
import 'support/profile_bff.dart';

// Control-level tests for the last setup step (SetupPreviewScreen) and the
// setup entry router (ProfileSetupEntryScreen), on the real draft notifier
// and the recording fake BFF.

const _complete = ValueKey('qa.setup.preview.complete_button');

final _en = qaL10n(const Locale('en'));

Future<List<Object?>> _openPreview(
  WidgetTester tester,
  QaApi api, {
  Locale? locale,
}) => pumpQa(
  tester,
  api,
  const SetupPreviewScreen(),
  launcher: true,
  locale: locale,
  extra: qaMasterDataOverrides(),
);

Future<void> _tapComplete(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(_complete));
  await qaSettle(tester, frames: 2);
  await tester.tap(find.byKey(_complete));
  await qaSettle(tester);
}

/// Index of the wide (active) dot under the photo carousel.
int _activeDot(WidgetTester tester) {
  final dots = tester
      .widgetList<AnimatedContainer>(
        find.byWidgetPredicate(
          (w) =>
              w is AnimatedContainer &&
              (w.constraints ==
                      const BoxConstraints.tightFor(width: 8, height: 8) ||
                  w.constraints ==
                      const BoxConstraints.tightFor(width: 20, height: 8)),
        ),
      )
      .toList();
  return dots.indexWhere(
    (d) => d.constraints == const BoxConstraints.tightFor(width: 20, height: 8),
  );
}

void main() {
  group('onboarding errors in German never show raw server or exception '
      'text [case:l10n.setup.raw_errors]', () {
    setUp(() => setCurrentAppLocale(const Locale('de')));
    tearDown(() => setCurrentAppLocale(null));
    final de = qaL10n(const Locale('de'));

    testWidgets('a refused completion reads the translated fallback', (
      tester,
    ) async {
      final api = QaApi();
      ProfileBff(api);
      api.fail(
        'POST /profile/*/complete',
        status: 422,
        message: 'Add one more approved photo',
      );
      await _openPreview(tester, api, locale: const Locale('de'));
      await _tapComplete(tester);
      expect(qaSnackText(tester), de.profileSetupServerError);
      expect(find.textContaining('approved photo'), findsNothing);
      expect(api.writes, hasLength(1));
    });

    for (final (name, screen) in <(String, Widget)>[
      ('about', const SetupAboutScreen()),
      ('photos', const SetupPhotosScreen()),
      ('preview', const SetupPreviewScreen()),
    ]) {
      testWidgets('a draft that fails to load on $name', (tester) async {
        final api = QaApi();
        ProfileBff(api);
        api.fail(
          'GET /profile/*/draft',
          status: 500,
          message: 'pq: relation "profiles" does not exist',
        );
        await pumpQa(
          tester,
          api,
          screen,
          locale: const Locale('de'),
          extra: qaMasterDataOverrides(),
        );
        expect(find.text(de.profileSetupLoadErrorTitle), findsOneWidget);
        expect(find.text(de.commonSomethingWentWrongTryAgain), findsOneWidget);
        expect(find.textContaining('relation'), findsNothing);
        expect(find.textContaining('DioException'), findsNothing);
      });
    }
  });

  group('SetupPreviewScreen', () {
    testWidgets(
      'Complete Profile completes on the server and opens the app '
      'on Discover '
      '[case:profile.setup_preview.setup_preview_complete_button_complete.action]',
      (tester) async {
        final api = QaApi();
        ProfileBff(api);
        await _openPreview(tester, api);
        final container = ProviderScope.containerOf(
          tester.element(find.byType(SetupPreviewScreen)),
        );
        container.read(mainNavigationIndexProvider.notifier).state = 4;
        await _tapComplete(tester);
        expect(api.writeLines, ['POST /profile/me/complete']);
        expect(container.read(mainNavigationIndexProvider), 0);
        expect(find.byType(MainNavigationScreen), findsOneWidget);
        expect(find.byType(SetupPreviewScreen), findsNothing);
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      'an incomplete profile is explained before anything is sent '
      '[case:profile.setup_preview.setup_preview_complete_button_complete.validation]',
      (tester) async {
        final api = QaApi();
        ProfileBff(api, draft: qaDraftJson(bio: 'Too short'));
        await _openPreview(tester, api);
        await _tapComplete(tester);
        expect(qaSnackText(tester), _en.profileSetupBioTooShort(10));
        expect(api.writes, isEmpty);
        expect(find.byType(SetupPreviewScreen), findsOneWidget);
      },
    );

    testWidgets(
      'a refused completion shows the server reason, stays and '
      're-enables the button '
      '[case:profile.setup_preview.setup_preview_complete_button_complete.api_failure]',
      (tester) async {
        final api = QaApi();
        ProfileBff(api);
        api.fail(
          'POST /profile/*/complete',
          status: 422,
          message: 'Add one more approved photo',
        );
        final results = await _openPreview(tester, api);
        await _tapComplete(tester);
        expect(qaSnackText(tester), 'Add one more approved photo');
        expect(api.writes, hasLength(1));
        expect(results, isEmpty);
        expect(find.byType(SetupPreviewScreen), findsOneWidget);
        final button = tester.widget<GlassButton>(find.byKey(_complete));
        expect(button.onPressed, isNotNull);
        expect(button.isLoading, isFalse);
      },
    );

    testWidgets(
      'offline completion says so '
      '[case:profile.setup_preview.setup_preview_complete_button_complete.api_failure]',
      (tester) async {
        final api = QaApi();
        ProfileBff(api);
        api.offline('POST /profile/*/complete');
        await _openPreview(tester, api);
        await _tapComplete(tester);
        expect(qaSnackText(tester), _en.networkOfflineTryAgain);
        expect(api.writes, hasLength(1));
      },
    );

    // Regression (2026-10-02): two taps before the button rebuilt completed
    // the profile twice.
    testWidgets(
      'a double tap completes once '
      '[case:profile.setup_preview.setup_preview_complete_button_complete.action]',
      (tester) async {
        final api = QaApi();
        final bff = ProfileBff(api);
        api.on(
          'POST /profile/*/complete',
          (_) => QaReply(200, {
            'draft': bff.draft,
          }, delay: const Duration(milliseconds: 300)),
        );
        await _openPreview(tester, api);
        await tester.ensureVisible(find.byKey(_complete));
        await qaSettle(tester, frames: 2);
        await tester.tap(find.byKey(_complete));
        await tester.tap(find.byKey(_complete), warnIfMissed: false);
        await qaSettle(tester);
        expect(api.sent('POST', '/profile/*/complete'), hasLength(1));
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      'swiping the photos moves the active dot '
      '[case:profile.setup_preview.previewbody_onpagechanged_onpagechanged.action]',
      (tester) async {
        final api = QaApi();
        ProfileBff(api, draft: qaDraftJson(photoCount: 3));
        await _openPreview(tester, api);
        expect(_activeDot(tester), 0);
        await tester.fling(find.byType(PageView), const Offset(-300, 0), 1200);
        await qaSettle(tester);
        expect(_activeDot(tester), 1);
        await tester.fling(find.byType(PageView), const Offset(-300, 0), 1200);
        await qaSettle(tester);
        expect(_activeDot(tester), 2);
        await tester.fling(find.byType(PageView), const Offset(300, 0), 1200);
        await qaSettle(tester);
        expect(_activeDot(tester), 1);
      },
    );

    testWidgets('Back returns to the previous step '
        '[case:profile.setup_preview.back_onback.action]', (tester) async {
      final api = QaApi();
      ProfileBff(api);
      final results = await _openPreview(tester, api);
      await tester.tap(find.byTooltip(_en.profileSetupBackTooltip));
      await qaSettle(tester);
      expect(find.byType(SetupPreviewScreen), findsNothing);
      expect(results, [null]);
      expect(api.writes, isEmpty);
    });

    testWidgets('Retry reloads a preview that failed to load '
        '[case:profile.setup_preview.retry_onretry.action]', (tester) async {
      final api = QaApi();
      final bff = ProfileBff(api);
      api.fail('GET /profile/*/draft');
      await _openPreview(tester, api);
      expect(find.text(_en.profileSetupLoadErrorTitle), findsOneWidget);
      expect(find.byKey(_complete), findsNothing);
      bff.install();
      await tester.tap(find.text(_en.profileSetupRetry));
      await qaSettle(tester);
      expect(api.sent('GET', '/profile/me/draft'), hasLength(2));
      expect(find.byKey(_complete), findsOneWidget);
    });

    testWidgets('renders translated in every locale '
        '[case:profile.setup_preview.l10n]', (tester) async {
      for (final locale in qaLocales) {
        await tester.pumpWidget(const SizedBox());
        final api = QaApi();
        ProfileBff(api);
        await _openPreview(tester, api, locale: locale);
        final l10n = qaL10n(locale);
        expect(find.text(l10n.profileSetupPreviewTitle), findsOneWidget);
        expect(find.text(l10n.profileSetupStepCounter(4, 4)), findsOneWidget);
        await tester.ensureVisible(find.byKey(_complete));
        await qaSettle(tester, frames: 2);
        expect(find.text(l10n.profileSetupCompleteProfile), findsOneWidget);
        expect(tester.takeException(), isNull, reason: '$locale');
      }
    });
  });

  group('ProfileSetupEntryScreen', () {
    void workflow(QaApi api, {bool fail = false}) => fail
        ? api.fail('GET /auth/signup/workflow/*')
        : api.json('GET /auth/signup/workflow/*', {
            'state': 'in_progress',
            'current_activity': 'profile',
          });

    testWidgets('Retry reloads the setup status and resumes at the first '
        'missing step [case:profile.profile_setup_entry.retry.action]', (
      tester,
    ) async {
      final api = QaApi();
      ProfileBff(api, draft: qaDraftJson(photoCount: 2, bio: ''));
      workflow(api, fail: true);
      await pumpQa(
        tester,
        api,
        const ProfileSetupEntryScreen(),
        extra: qaMasterDataOverrides(),
      );
      expect(find.text(_en.profileSetupRetry), findsOneWidget);
      expect(find.byType(SetupAboutScreen), findsNothing);

      workflow(api);
      await tester.tap(find.text(_en.profileSetupRetry));
      await qaSettle(tester);
      expect(api.sent('GET', '/auth/signup/workflow/me'), hasLength(2));
      expect(find.byType(SetupAboutScreen), findsOneWidget);
    });

    testWidgets('a member without photos starts at the photo step '
        '[case:profile.profile_setup_entry.retry.action]', (tester) async {
      final api = QaApi();
      ProfileBff(api, draft: qaDraftJson(photoCount: 0, bio: ''));
      workflow(api);
      await pumpQa(
        tester,
        api,
        const ProfileSetupEntryScreen(),
        extra: qaMasterDataOverrides(),
      );
      expect(find.byType(SetupPhotosScreen), findsOneWidget);
    });

    testWidgets('renders translated in every locale '
        '[case:profile.profile_setup_entry.l10n]', (tester) async {
      for (final locale in qaLocales) {
        await tester.pumpWidget(const SizedBox());
        final api = QaApi();
        ProfileBff(api, draft: qaDraftJson(photoCount: 2, bio: ''));
        workflow(api, fail: true);
        await pumpQa(
          tester,
          api,
          const ProfileSetupEntryScreen(),
          locale: locale,
          extra: qaMasterDataOverrides(),
        );
        final l10n = qaL10n(locale);
        expect(find.text(l10n.profileSetupRetry), findsOneWidget);
        workflow(api);
        await tester.tap(find.text(l10n.profileSetupRetry));
        await qaSettle(tester);
        expect(find.text(l10n.profileSetupAboutTitle), findsOneWidget);
        expect(tester.takeException(), isNull, reason: '$locale');
      }
    });
  });
}
