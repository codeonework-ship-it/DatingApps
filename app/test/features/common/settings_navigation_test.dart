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
  // One test per row, each naming its catalog case literally (the QA Lab
  // reads the ids from the test names as written).
  group('Settings rows', () {
    testWidgets(
      'Notification inbox opens NotificationInboxScreen '
      '[case:common.settings.settings_notification_inbox.action]',
      (tester) => _expectOpens(
        tester,
        const ValueKey('qa.settings.notification_inbox'),
        NotificationInboxScreen,
      ),
    );

    testWidgets(
      'Your dating rhythm opens DatingRhythmScreen '
      '[case:common.settings.settings_dating_rhythm.action]',
      (tester) => _expectOpens(
        tester,
        const ValueKey('qa.settings.dating_rhythm'),
        DatingRhythmScreen,
      ),
    );

    testWidgets(
      'Your profile stories opens ProfileStoriesScreen '
      '[case:common.settings.settings_profile_stories.action]',
      (tester) => _expectOpens(
        tester,
        const ValueKey('qa.settings.profile_stories'),
        ProfileStoriesScreen,
      ),
    );

    testWidgets(
      'Blog · Open Chapters opens BlogScreen '
      '[case:common.settings.settings_blog.action]',
      (tester) =>
          _expectOpens(tester, const ValueKey('qa.settings.blog'), BlogScreen),
    );

    testWidgets(
      'Edit Profile opens EditProfileScreen '
      '[case:common.settings.settings_edit_profile.action]',
      (tester) => _expectOpens(
        tester,
        const ValueKey('qa.settings.edit_profile'),
        EditProfileScreen,
      ),
    );

    testWidgets(
      'Photos opens SetupPhotosScreen '
      '[case:common.settings.settings_photos.action]',
      (tester) => _expectOpens(
        tester,
        const ValueKey('qa.settings.photos'),
        SetupPhotosScreen,
      ),
    );

    testWidgets(
      'Language opens LanguageSettingsScreen '
      '[case:common.settings.settings_language.action]',
      (tester) => _expectOpens(
        tester,
        const ValueKey('qa.settings.language'),
        LanguageSettingsScreen,
      ),
    );

    testWidgets(
      'Dating Preferences opens SetupPreferencesScreen '
      '[case:common.settings.settings_dating_preferences.action]',
      (tester) => _expectOpens(
        tester,
        const ValueKey('qa.settings.dating_preferences'),
        SetupPreferencesScreen,
      ),
    );

    testWidgets(
      'Account & Data opens AccountDataScreen '
      '[case:common.settings.settings_account_data.action]',
      (tester) => _expectOpens(
        tester,
        const ValueKey('qa.settings.account_data'),
        AccountDataScreen,
      ),
    );

    testWidgets(
      'Notifications opens NotificationSettingsScreen '
      '[case:common.settings.settings_notifications.action]',
      (tester) => _expectOpens(
        tester,
        const ValueKey('qa.settings.notifications'),
        NotificationSettingsScreen,
      ),
    );

    testWidgets(
      'Trust Badges opens TrustBadgesScreen '
      '[case:common.settings.settings_trust_badges.action]',
      (tester) => _expectOpens(
        tester,
        const ValueKey('qa.settings.trust_badges'),
        TrustBadgesScreen,
      ),
    );

    testWidgets(
      'Trust Filters opens TrustFilterScreen '
      '[case:common.settings.settings_trust_filters.action]',
      (tester) => _expectOpens(
        tester,
        const ValueKey('qa.settings.trust_filters'),
        TrustFilterScreen,
      ),
    );

    testWidgets(
      'Conversation Rooms opens ConversationRoomsScreen '
      '[case:common.settings.settings_conversation_rooms.action]',
      (tester) => _expectOpens(
        tester,
        const ValueKey('qa.settings.conversation_rooms'),
        ConversationRoomsScreen,
      ),
    );

    testWidgets(
      'Friends & Connections opens FriendsScreen '
      '[case:common.settings.settings_friends.action]',
      (tester) => _expectOpens(
        tester,
        const ValueKey('qa.settings.friends'),
        FriendsScreen,
      ),
    );

    testWidgets(
      'Call History opens CallHistoryScreen '
      '[case:common.settings.settings_call_history.action]',
      (tester) => _expectOpens(
        tester,
        const ValueKey('qa.settings.call_history'),
        CallHistoryScreen,
      ),
    );

    testWidgets(
      'Match Nudges opens MatchNudgesScreen '
      '[case:common.settings.settings_match_nudges.action]',
      (tester) => _expectOpens(
        tester,
        const ValueKey('qa.settings.match_nudges'),
        MatchNudgesScreen,
      ),
    );

    testWidgets(
      'Subscriptions opens SubscriptionScreen '
      '[case:common.settings.settings_subscriptions.action]',
      (tester) => _expectOpens(
        tester,
        const ValueKey('qa.settings.subscriptions'),
        SubscriptionScreen,
      ),
    );

    testWidgets(
      'Privacy & Safety opens PrivacySafetyScreen '
      '[case:common.settings.settings_privacy_safety.action]',
      (tester) => _expectOpens(
        tester,
        const ValueKey('qa.settings.privacy_safety'),
        PrivacySafetyScreen,
      ),
    );

    testWidgets(
      'Government verification opens VerificationLandingScreen '
      '[case:common.settings.settings_government_verification.action]',
      (tester) => _expectOpens(
        tester,
        const ValueKey('qa.settings.government_verification'),
        VerificationLandingScreen,
      ),
    );

    testWidgets(
      'About opens AboutAppScreen '
      '[case:common.settings.settings_about.action]',
      (tester) => _expectOpens(
        tester,
        const ValueKey('qa.settings.about'),
        AboutAppScreen,
      ),
    );

    // The support row has no catalog case of its own (the support centre
    // is covered by the support suites); kept as a navigation check.
    testWidgets(
      'Help & Support opens HelpSupportScreen',
      (tester) => _expectOpens(
        tester,
        const ValueKey('qa.settings.help_support'),
        HelpSupportScreen,
      ),
    );

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

  testWidgets('the inbox row is first and says when nothing is unread '
      '[case:common.settings.settings_notification_inbox.caught_up]', (
    tester,
  ) async {
    await pumpQa(tester, _permissive(), const SettingsScreen());
    final row = find.byKey(const ValueKey('qa.settings.notification_inbox'));
    expect(row, findsOneWidget);
    expect(
      find.descendant(of: row, matching: find.text('You are all caught up')),
      findsOneWidget,
    );
  });
}
