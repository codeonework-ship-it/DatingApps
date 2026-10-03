import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/theme/app_theme.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

import 'screen_matrix_harness.dart';

/// Screens that are never pushed on top of another one: entry points and
/// the main tabs. Everything else is opened from somewhere and must show a
/// way back.
const _roots = {
  'WelcomeScreen',
  'WebEntryScreen',
  'AuthScreen',
  'MainNavigationScreen',
  'HomeDiscoveryScreen',
  'MatchesListScreen',
  'EngagementHubScreen',
  'ProfileViewScreen',
  'SettingsScreen',
  'ProfileSetupEntryScreen',
};

/// Screens without a back/close control, and why that is fine.
const _exempt = {
  // A gate shown in place of the app until the terms are accepted; its way
  // out is "Sign out" (qa.terms.sign_out), checked below.
  'UserAgreementScreen',
  // Has a close button in its AppBar, but the platform WebView cannot
  // render in widget tests, so the screen never finishes building here.
  'CheckoutWebViewScreen',
};

/// The visible back or close control of the pushed screen, or null.
Finder? _backControl(WidgetTester tester, BuildContext context) {
  final strings = MaterialLocalizations.of(context);
  final labels = {
    strings.backButtonTooltip,
    strings.closeButtonTooltip,
    'Back',
    'Close',
  };
  final icons = <IconData>{
    Icons.arrow_back,
    Icons.arrow_back_rounded,
    Icons.arrow_back_ios,
    Icons.arrow_back_ios_new,
    Icons.arrow_back_ios_new_rounded,
    Icons.close,
    Icons.close_rounded,
    Icons.chevron_left,
    Icons.chevron_left_rounded,
  };
  for (final type in [BackButton, CloseButton, BackButtonIcon]) {
    final found = find.byType(type).hitTestable();
    if (found.evaluate().isNotEmpty) {
      return found.first;
    }
  }
  final buttons = find.byWidgetPredicate((w) {
    if (w is! IconButton) {
      return false;
    }
    final icon = w.icon;
    return labels.contains(w.tooltip) ||
        (icon is Icon && icons.contains(icon.icon));
  }).hitTestable();
  if (buttons.evaluate().isNotEmpty) {
    return buttons.first;
  }
  final tooltips = find
      .byWidgetPredicate((w) => w is Tooltip && labels.contains(w.message))
      .hitTestable();
  if (tooltips.evaluate().isNotEmpty) {
    return tooltips.first;
  }
  final semantics = find
      .byWidgetPredicate(
        (w) =>
            w is Semantics &&
            (w.properties.label == 'Back' ||
                w.properties.label == strings.backButtonTooltip),
      )
      .hitTestable();
  return semantics.evaluate().isEmpty ? null : semantics.first;
}

void main() {
  final screens = buildScreenMatrix();

  test('every pushed screen names its catalog feature', () {
    final pushed = screens.keys.where(
      (k) => !_roots.contains(k) && !_exempt.contains(k),
    );
    expect(
      _caseFeatures.keys.toSet(),
      pushed.toSet(),
      reason: 'Add the catalog feature id of each new screen to _caseFeatures',
    );
  });

  for (final entry in screens.entries) {
    if (_roots.contains(entry.key)) {
      continue;
    }
    final feature = _caseFeatures[entry.key];
    testWidgets('${entry.key} shows a way back when pushed '
        '[case:$feature.back_affordance]', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: screenMatrixOverrides(),
          child: MaterialApp(
            navigatorKey: navigator,
            theme: AppTheme.lightTheme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: Text('launcher')),
          ),
        ),
      );
      navigator.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => entry.value()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      final context = navigator.currentState!.context;
      // Ignore unrelated runtime noise from fixture data; this audit is
      // only about navigation.
      tester.takeException();
      if (entry.key == 'UserAgreementScreen') {
        expect(
          find.byKey(const ValueKey('qa.terms.sign_out')),
          findsOneWidget,
          reason: 'the terms gate needs a way out',
        );
      } else if (!_exempt.contains(entry.key)) {
        final back = _backControl(tester, context);
        expect(
          back,
          isNotNull,
          reason: '${entry.key} has no back or close button when pushed',
        );
        // Using it must return to the opener, not just exist.
        await tester.tap(back!, warnIfMissed: false);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        tester.takeException();
        expect(
          find.text('launcher'),
          findsOneWidget,
          reason:
              '${entry.key}: its back/close control did not return to the '
              'screen that opened it',
        );
        expect(navigator.currentState!.canPop(), isFalse);
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });
  }
}

/// Catalog feature id of each pushed screen (qa/catalog/feature_catalog.json).
/// Its test proves `<feature>.back_affordance`: a visible back or close
/// control that returns to the opener.
const _caseFeatures = <String, String>{
  'AccountRecoveryScreen': 'auth.account_recovery',
  'SignupScreen': 'auth.signup',
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
  'ModerationAppealsScreen': 'common.moderation_appeals',
  'NotificationSettingsScreen': 'common.notification_settings',
  'AccountDataScreen': 'common.account_data',
  'PrivacySafetyScreen': 'common.privacy_safety',
  'CircleChallengesScreen': 'engagement.circle_challenges',
  'GroupsScreen': 'groups.groups',
  'GroupDetailScreen': 'groups.group_detail',
  'CreateGroupScreen': 'groups.create_group',
  'ConversationRoomsScreen': 'engagement.conversation_rooms',
  'DailyPromptScreen': 'engagement.daily_prompt',
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
  'ChatScreen': 'messaging.chat',
  'NotificationInboxScreen': 'notifications.notification_inbox',
  'PhotoThemesScreen': 'photo_themes.photo_themes',
  'PhotoThemeGalleryScreen': 'photo_themes.photo_theme_gallery',
  'SubscriptionScreen': 'payment.subscription',
  'WalletPaymentScreen': 'payment.wallet_payment',
  'EditProfileScreen': 'profile.edit_profile',
  'ProfileViewersScreen': 'profile.profile_viewers',
  'SetupAboutScreen': 'profile.setup_about',
  'SetupPhotosScreen': 'profile.setup_photos',
  'SetupPreferencesScreen': 'profile.setup_preferences',
  'SetupPreviewScreen': 'profile.setup_preview',
  'SosScreen': 'safety.sos',
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
