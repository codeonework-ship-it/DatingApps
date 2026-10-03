import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/config/feature_flags.dart';
import 'package:verified_dating_app/features/blog/blog_screen.dart';
import 'package:verified_dating_app/features/calls/screens/call_history_screen.dart';
import 'package:verified_dating_app/features/common/screens/about_app_screen.dart';
import 'package:verified_dating_app/features/common/screens/account_data_screen.dart';
import 'package:verified_dating_app/features/common/screens/help_support_screen.dart';
import 'package:verified_dating_app/features/common/screens/language_settings_screen.dart';
import 'package:verified_dating_app/features/common/screens/notification_settings_screen.dart';
import 'package:verified_dating_app/features/common/screens/privacy_safety_screen.dart';
import 'package:verified_dating_app/features/common/screens/settings_screen.dart';
import 'package:verified_dating_app/features/engagement/screens/conversation_rooms_screen.dart';
import 'package:verified_dating_app/features/engagement/screens/match_nudges_screen.dart';
import 'package:verified_dating_app/features/engagement/screens/trust_badges_screen.dart';
import 'package:verified_dating_app/features/engagement/screens/trust_filter_screen.dart';
import 'package:verified_dating_app/features/friends/screens/friends_screen.dart';
import 'package:verified_dating_app/features/intentional_dating/dating_rhythm.dart';
import 'package:verified_dating_app/features/intentional_dating/profile_stories.dart';
import 'package:verified_dating_app/features/notifications/screens/notification_inbox_screen.dart';
import 'package:verified_dating_app/features/payment/screens/subscription_screen.dart';
import 'package:verified_dating_app/features/profile/screens/edit_profile_screen.dart';
import 'package:verified_dating_app/features/profile/screens/setup/setup_photos_screen.dart';
import 'package:verified_dating_app/features/profile/screens/setup/setup_preferences_screen.dart';
import 'package:verified_dating_app/features/verification/screens/verification_landing_screen.dart';
import 'package:verified_dating_app/features/verification/screens/verification_upload_id_screen.dart';

import '../../support/qa_api.dart';

// Every Settings row opens its own screen. The target screens load their own
// data; the fake server answers any read with an empty object so each one can
// build (their internals are covered by their own suites).

/// A server that answers every read with `{}` and records everything.
QaApi _permissive() {
  final api = QaApi();
  for (var depth = 1; depth <= 7; depth++) {
    api.json('GET ${List.filled(depth, '/*').join()}', <String, dynamic>{});
  }
  return api;
}

Future<void> _openRow(WidgetTester tester, ValueKey<String> key) async {
  final row = find.byKey(key);
  await tester.scrollUntilVisible(
    row,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pump();
  await tester.tap(row);
  await qaSettle(tester, frames: 8);
}

/// Pumps Settings, opens [key] and checks [screen] is now on top.
Future<void> _expectOpens(
  WidgetTester tester,
  ValueKey<String> key,
  Type screen,
) async {
  final api = _permissive();
  await pumpQa(tester, api, const SettingsScreen());
  expect(find.byType(screen), findsNothing);
  await _openRow(tester, key);
  expect(find.byType(screen), findsOneWidget);
  // The new screen covers Settings: its rows are no longer hit-testable.
  expect(find.byKey(key).hitTestable(), findsNothing);
  expect(tester.takeException(), isNull);
}

void main() {
  final rows = <(String, String, Type)>[
    (
      'common.settings.notification_inbox.action',
      'qa.settings.notification_inbox',
      NotificationInboxScreen,
    ),
    (
      'common.settings.your_dating_rhythm.action',
      'qa.settings.dating_rhythm',
      DatingRhythmScreen,
    ),
    (
      'common.settings.your_profile_stories.action',
      'qa.settings.profile_stories',
      ProfileStoriesScreen,
    ),
    (
      'common.settings.blog_open_chapters.action',
      'qa.settings.blog',
      BlogScreen,
    ),
    (
      'common.settings.edit_profile.action',
      'qa.settings.edit_profile',
      EditProfileScreen,
    ),
    ('common.settings.photos.action', 'qa.settings.photos', SetupPhotosScreen),
    (
      'common.settings.settings_language.action',
      'qa.settings.language',
      LanguageSettingsScreen,
    ),
    (
      'common.settings.dating_preferences.action',
      'qa.settings.dating_preferences',
      SetupPreferencesScreen,
    ),
    (
      'common.settings.account_data.action',
      'qa.settings.account_data',
      AccountDataScreen,
    ),
    (
      'common.settings.notifications.action',
      'qa.settings.notifications',
      NotificationSettingsScreen,
    ),
    (
      'common.settings.trust_badges.action',
      'qa.settings.trust_badges',
      TrustBadgesScreen,
    ),
    (
      'common.settings.trust_filters.action',
      'qa.settings.trust_filters',
      TrustFilterScreen,
    ),
    (
      'common.settings.conversation_rooms.action',
      'qa.settings.conversation_rooms',
      ConversationRoomsScreen,
    ),
    (
      'common.settings.friends_connections.action',
      'qa.settings.friends',
      FriendsScreen,
    ),
    (
      'common.settings.call_history.action',
      'qa.settings.call_history',
      CallHistoryScreen,
    ),
    (
      'common.settings.match_nudges.action',
      'qa.settings.match_nudges',
      MatchNudgesScreen,
    ),
    (
      'common.settings.subscriptions.action',
      'qa.settings.subscriptions',
      SubscriptionScreen,
    ),
    (
      'common.settings.privacy_safety.action',
      'qa.settings.privacy_safety',
      PrivacySafetyScreen,
    ),
    (
      'common.settings.settings_government_verification.action',
      'qa.settings.government_verification',
      VerificationLandingScreen,
    ),
    (
      'common.settings.help_support.action',
      'qa.settings.help_support',
      HelpSupportScreen,
    ),
    ('common.settings.about.action', 'qa.settings.about', AboutAppScreen),
  ];

  group('Settings rows', () {
    for (final (caseId, key, screen) in rows) {
      testWidgets('$key opens $screen [case:$caseId]', (tester) async {
        await _expectOpens(tester, ValueKey(key), screen);
      });
    }

    // Automation-only entry: present only in builds made with
    // --dart-define=ENABLE_QA_AUTOMATION=true (the Appium runner). A shipped
    // build must not show it at all.
    testWidgets(
      'QA Verification Upload opens the ID upload only in an automation build '
      '[case:common.settings.settings_verification_upload.action]',
      (tester) async {
        const key = ValueKey('qa.settings.verification_upload');
        if (kEnableQaAutomation) {
          await _expectOpens(tester, key, VerificationUploadIdScreen);
          return;
        }
        await pumpQa(tester, _permissive(), const SettingsScreen());
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('qa.settings.logout')),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.byKey(key), findsNothing);
        expect(find.byType(VerificationUploadIdScreen), findsNothing);
      },
    );

    testWidgets(
      'story rows are hidden while intentional dating is off and rooms row '
      'while rooms are off [case:common.settings.runtime_flag_rows]',
      (tester) async {
        await pumpQa(
          tester,
          _permissive(),
          const SettingsScreen(),
          flags: const {
            'intentional_dating_enabled': false,
            'rooms_enabled': false,
          },
        );
        // Scroll to the last row so every row has been built.
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('qa.settings.about')),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        for (final hidden in const [
          'qa.settings.dating_rhythm',
          'qa.settings.profile_stories',
          'qa.settings.blog',
          'qa.settings.conversation_rooms',
        ]) {
          expect(find.byKey(ValueKey(hidden)), findsNothing, reason: hidden);
        }
        // Rows that do not depend on a flag are still there.
        expect(
          find.byKey(const ValueKey('qa.settings.friends')),
          findsOneWidget,
        );
      },
    );
  });

  testWidgets('Settings renders in every shipped language '
      '[case:common.settings.l10n]', (tester) async {
    for (final locale in qaLocales) {
      final l10n = qaL10n(locale);
      // A fresh tree per language (no scroll position carried over).
      await tester.pumpWidget(const SizedBox());
      await pumpQa(
        tester,
        _permissive(),
        const SettingsScreen(),
        locale: locale,
      );
      expect(tester.takeException(), isNull, reason: '$locale');
      // The Account section opens Settings: sign-out is easy to find.
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('qa.settings.logout')),
          matching: find.text(l10n.settingsSignOut),
        ),
        findsOneWidget,
        reason: '$locale',
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('qa.settings.logout_all')),
          matching: find.text(l10n.settingsSignOutAllTitle),
        ),
        findsOneWidget,
        reason: '$locale',
      );
      expect(find.text(l10n.settingsSignedInAs('me')), findsOneWidget);
      expect(find.text(l10n.settingsAppearanceTitle), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text(l10n.settingsEditProfileTitle),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.scrollUntilVisible(
        find.text(l10n.settingsAboutTitle),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(l10n.settingsAboutTitle), findsOneWidget);
    }
  });

  testWidgets(
    'the inbox row is first and says when nothing is unread '
    '[case:common.settings.notification_inbox.caught_up]',
    (tester) async {
      await pumpQa(tester, _permissive(), const SettingsScreen());
      final row = find.byKey(const ValueKey('qa.settings.notification_inbox'));
      expect(row, findsOneWidget);
      expect(
        find.descendant(of: row, matching: find.text('You are all caught up')),
        findsOneWidget,
      );
    },
  );
}
