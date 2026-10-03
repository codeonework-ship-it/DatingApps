import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/theme/app_theme.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../support/layout_webview_platform.dart';
import 'screen_matrix_harness.dart';

/// Layout coverage for **every** screen in the app, at each device size it
/// ships to.
///
/// Golden files pin a couple of screens at a couple of sizes. They say nothing
/// about the widths where layouts actually break — the smallest phone still in
/// support, the tallest phone, a tablet in portrait — and nothing at all about
/// the screens they do not cover.
///
/// These assert the absence of *layout* errors rather than comparing pixels, so
/// they survive restyling and cost nothing to extend. Runtime noise a screen
/// produces without a backend (failed requests, absent plugins, missing files)
/// is deliberately tolerated: this is a layout harness, not an integration one.
///
/// Every screen must appear here. A screen absent from this map is a screen
/// nobody is checking at 320pt. The map itself lives in
/// `screen_matrix_harness.dart` so the accessibility guideline suite
/// (`screen_accessibility_test.dart`) walks exactly the same screens.
void main() {
  WebViewPlatform.instance = LayoutWebViewPlatform();
  const devices = screenMatrixDevices;
  final screens = buildScreenMatrix();

  // Every screen is exercised under both themes.
  //
  // The matrix used to pump the light theme only, which is why a dark-mode
  // regression — near-white labels drawn on a hardcoded light ground — passed
  // 281 green tests while the app was unreadable on device. A theme the
  // product ships and lets members select has to be covered like any other
  // configuration.
  final themes = <String, ThemeData>{
    'light': AppTheme.lightTheme,
    'dark': AppTheme.darkTheme,
  };

  for (final MapEntry(key: themeLabel, value: theme) in themes.entries) {
    devices.forEach((deviceLabel, size) {
      screens.forEach((screenLabel, build) {
        final feature = _caseFeatures[screenLabel];
        testWidgets('$screenLabel lays out on $deviceLabel [$themeLabel] '
            '[case:$feature.layout_matrix]', (tester) async {
          final errors = await pumpAndCollectLayoutErrors(
            tester,
            build(),
            size,
            theme,
          );
          expect(
            errors,
            isEmpty,
            reason:
                '$screenLabel has ${errors.length} layout error(s) on '
                '$deviceLabel ($themeLabel):\n${errors.join('\n')}',
          );
        });
      });
    });
  }

  // Every shipped screen also runs with Android's large accessibility font
  // scale on the smallest supported phone, in both themes. This catches
  // clipped actions and unreadable fixed-height rows that ordinary responsive
  // coverage misses; the dark theme swaps surfaces and paddings on several
  // screens, so it gets its own large-text pass rather than inheriting light's.
  for (final MapEntry(key: themeLabel, value: theme) in themes.entries) {
    screens.forEach((screenLabel, build) {
      testWidgets(
        '$screenLabel supports large accessibility text [$themeLabel]',
        (tester) async {
          final errors = await pumpAndCollectLayoutErrors(
            tester,
            build(),
            devices['small phone 320x568']!,
            theme,
            textScaler: const TextScaler.linear(1.3),
          );
          expect(
            errors,
            isEmpty,
            reason:
                '$screenLabel has ${errors.length} accessibility layout '
                'error(s) ($themeLabel):\n${errors.join('\n')}',
          );
        },
      );
    });
  }

  test('every screen in the matrix names its catalog feature', () {
    // The layout cases are tagged `[case:<feature>.layout_matrix]`; a screen
    // without an entry here would run untagged and prove nothing in QA Lab.
    expect(
      _caseFeatures.keys.toSet(),
      screens.keys.toSet(),
      reason: 'Add the catalog feature id of each new screen to _caseFeatures',
    );
  });

  test('every screen in the app is covered by this matrix', () {
    final declared = Directory('lib/features')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('_screen.dart'))
        .expand(
          (file) => RegExp(
            r'class (\w+Screen) extends',
          ).allMatches(file.readAsStringSync()).map((m) => m.group(1)!),
        )
        .toSet();

    final missing = declared.difference(screens.keys.toSet()).toList()..sort();

    expect(
      missing,
      isEmpty,
      reason:
          'These screens are not layout-tested at any device size:\n'
          '${missing.join('\n')}',
    );
  });
}

/// Catalog feature id of each screen (qa/catalog/feature_catalog.json). The
/// layout test of a screen proves `<feature>.layout_matrix`.
const _caseFeatures = <String, String>{
  'WelcomeScreen': 'auth.welcome',
  'WebEntryScreen': 'web.web_entry',
  'AuthScreen': 'auth.auth',
  'AccountRecoveryScreen': 'auth.account_recovery',
  'SignupScreen': 'auth.signup',
  'UserAgreementScreen': 'auth.user_agreement',
  'BlogScreen': 'blog.blog',
  'BlogDetailScreen': 'blog.blog_detail',
  'BlogWritersScreen': 'blog.blog_writers',
  'CallHistoryScreen': 'calls.call_history',
  'CallSessionScreen': 'calls.call_session',
  'ClubsScreen': 'clubs.clubs',
  'ClubDetailScreen': 'clubs.club_detail',
  'MyListsScreen': 'clubs.my_lists',
  'TitleDetailScreen': 'clubs.title_detail',
  'AboutAppScreen': 'common.about_app',
  'BlockedUsersScreen': 'common.blocked_users',
  'EmergencyContactsScreen': 'common.emergency_contacts',
  'HelpSupportScreen': 'common.help_support',
  'SupportContactFormScreen': 'support.support_contact_form',
  'SupportTicketFormScreen': 'support.support_ticket_form',
  'SupportTicketsScreen': 'support.support_tickets',
  'SupportTicketThreadScreen': 'support.support_ticket_thread',
  'LanguageSettingsScreen': 'common.language_settings',
  'MainNavigationScreen': 'common.main_navigation',
  'ModerationAppealsScreen': 'common.moderation_appeals',
  'NotificationSettingsScreen': 'common.notification_settings',
  'AccountDataScreen': 'common.account_data',
  'PrivacySafetyScreen': 'common.privacy_safety',
  'SettingsScreen': 'common.settings',
  'CircleChallengesScreen': 'engagement.circle_challenges',
  'GroupsScreen': 'groups.groups',
  'GroupDetailScreen': 'groups.group_detail',
  'CreateGroupScreen': 'groups.create_group',
  'ConversationRoomsScreen': 'engagement.conversation_rooms',
  'DailyPromptScreen': 'engagement.daily_prompt',
  'EngagementHubScreen': 'engagement.engagement_hub',
  'GroupCoffeePollsScreen': 'engagement.group_coffee_polls',
  'LevelProgressionScreen': 'engagement.level_progression',
  'MatchNudgesScreen': 'engagement.match_nudges',
  'TrustBadgesScreen': 'engagement.trust_badges',
  'TrustFilterScreen': 'engagement.trust_filter',
  'VoiceIcebreakersScreen': 'engagement.voice_icebreakers',
  'FriendsScreen': 'friends.friends',
  'PlansScreen': 'plans.plans',
  'GraduationCelebrationScreen': 'graduation.graduation_celebration',
  'ActivitySessionScreen': 'matching.activity_session',
  'MatchNotificationScreen': 'matching.match_notification',
  'MatchesListScreen': 'matching.matches_list',
  'ChatScreen': 'messaging.chat',
  'NotificationInboxScreen': 'notifications.notification_inbox',
  'PhotoThemesScreen': 'photo_themes.photo_themes',
  'PhotoThemeGalleryScreen': 'photo_themes.photo_theme_gallery',
  'CheckoutWebViewScreen': 'payment.checkout_webview',
  'SubscriptionScreen': 'payment.subscription',
  'WalletPaymentScreen': 'payment.wallet_payment',
  'EditProfileScreen': 'profile.edit_profile',
  'ProfileViewScreen': 'profile.profile_view',
  'ProfileViewersScreen': 'profile.profile_viewers',
  'ProfileSetupEntryScreen': 'profile.profile_setup_entry',
  'SetupAboutScreen': 'profile.setup_about',
  'SetupPhotosScreen': 'profile.setup_photos',
  'SetupPreferencesScreen': 'profile.setup_preferences',
  'SetupPreviewScreen': 'profile.setup_preview',
  'SosScreen': 'safety.sos',
  'HomeDiscoveryScreen': 'swipe.home_discovery',
  'LikedProfilesScreen': 'swipe.liked_profiles',
  'PassedProfilesScreen': 'swipe.passed_profiles',
  'ProfileDetailsScreen': 'swipe.profile_details',
  'SpotlightProfilesScreen': 'swipe.spotlight_profiles',
  'VerificationLandingScreen': 'verification.verification_landing',
  'VerificationSelfieScreen': 'verification.verification_selfie',
  'VerificationStatusScreen': 'verification.verification_status',
  'VerificationUploadIdScreen': 'verification.verification_upload_id',
  'ChapterStudioScreen': 'first_chapter.chapter_studio',
  'CityPilotScreen': 'city_pilot.city_pilot',
  'ComfortCardsScreen': 'first_chapter.comfort_cards',
  'IntroducerScreen': 'friends.introducer',
  'LikedMeScreen': 'swipe.liked_me',
  'SocialChatScreen': 'social_chat.social_chat',
};
