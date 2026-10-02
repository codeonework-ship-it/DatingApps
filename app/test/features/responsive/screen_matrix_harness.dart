import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/auth/screens/account_recovery_screen.dart';
import 'package:verified_dating_app/features/auth/screens/auth_screen.dart';
import 'package:verified_dating_app/features/auth/screens/signup_screen.dart';
import 'package:verified_dating_app/features/auth/screens/user_agreement_screen.dart';
import 'package:verified_dating_app/features/auth/screens/welcome_screen.dart';
import 'package:verified_dating_app/features/blog/blog_screen.dart';
import 'package:verified_dating_app/features/blog/blog_writers_screen.dart';
import 'package:verified_dating_app/features/calls/screens/call_history_screen.dart';
import 'package:verified_dating_app/features/calls/screens/call_session_screen.dart';
import 'package:verified_dating_app/features/clubs/club_detail_screen.dart';
import 'package:verified_dating_app/features/clubs/clubs_screen.dart';
import 'package:verified_dating_app/features/clubs/my_lists_screen.dart';
import 'package:verified_dating_app/features/clubs/title_detail_screen.dart';
import 'package:verified_dating_app/features/common/screens/about_app_screen.dart';
import 'package:verified_dating_app/features/common/screens/account_data_screen.dart';
import 'package:verified_dating_app/features/common/screens/blocked_users_screen.dart';
import 'package:verified_dating_app/features/common/screens/emergency_contacts_screen.dart';
import 'package:verified_dating_app/features/common/screens/help_support_screen.dart';
import 'package:verified_dating_app/features/common/screens/language_settings_screen.dart';
import 'package:verified_dating_app/features/common/screens/main_navigation_screen.dart';
import 'package:verified_dating_app/features/common/screens/moderation_appeals_screen.dart';
import 'package:verified_dating_app/features/common/screens/notification_settings_screen.dart';
import 'package:verified_dating_app/features/common/screens/privacy_safety_screen.dart';
import 'package:verified_dating_app/features/common/screens/settings_screen.dart';
import 'package:verified_dating_app/features/engagement/screens/circle_challenges_screen.dart';
import 'package:verified_dating_app/features/engagement/screens/conversation_rooms_screen.dart';
import 'package:verified_dating_app/features/engagement/screens/daily_prompt_screen.dart';
import 'package:verified_dating_app/features/engagement/screens/engagement_hub_screen.dart';
import 'package:verified_dating_app/features/engagement/screens/group_coffee_polls_screen.dart';
import 'package:verified_dating_app/features/engagement/screens/level_progression_screen.dart';
import 'package:verified_dating_app/features/engagement/screens/match_nudges_screen.dart';
import 'package:verified_dating_app/features/engagement/screens/trust_badges_screen.dart';
import 'package:verified_dating_app/features/engagement/screens/trust_filter_screen.dart';
import 'package:verified_dating_app/features/engagement/screens/voice_icebreakers_screen.dart';
import 'package:verified_dating_app/features/friends/screens/friends_screen.dart';
import 'package:verified_dating_app/features/graduation/screens/graduation_celebration_screen.dart';
import 'package:verified_dating_app/features/groups/create_group_screen.dart';
import 'package:verified_dating_app/features/groups/group_detail_screen.dart';
import 'package:verified_dating_app/features/groups/groups_screen.dart';
import 'package:verified_dating_app/features/matching/screens/activity_session_screen.dart';
import 'package:verified_dating_app/features/matching/screens/match_notification_screen.dart';
import 'package:verified_dating_app/features/matching/screens/matches_list_screen.dart';
import 'package:verified_dating_app/features/messaging/screens/chat_screen.dart';
import 'package:verified_dating_app/features/notifications/screens/notification_inbox_screen.dart';
import 'package:verified_dating_app/features/payment/providers/subscription_provider.dart';
import 'package:verified_dating_app/features/payment/screens/checkout_webview_screen.dart';
import 'package:verified_dating_app/features/payment/screens/subscription_screen.dart';
import 'package:verified_dating_app/features/payment/screens/wallet_payment_screen.dart';
import 'package:verified_dating_app/features/photo_themes/photo_theme_gallery_screen.dart';
import 'package:verified_dating_app/features/photo_themes/photo_themes_screen.dart';
import 'package:verified_dating_app/features/plans/screens/plans_screen.dart';
import 'package:verified_dating_app/features/profile/providers/preference_master_data_provider.dart';
import 'package:verified_dating_app/features/profile/providers/profile_setup_provider.dart';
import 'package:verified_dating_app/features/profile/screens/edit_profile_screen.dart';
import 'package:verified_dating_app/features/profile/screens/profile_view_screen.dart';
import 'package:verified_dating_app/features/profile/screens/profile_viewers_screen.dart';
import 'package:verified_dating_app/features/profile/screens/setup/profile_setup_entry_screen.dart';
import 'package:verified_dating_app/features/profile/screens/setup/setup_about_screen.dart';
import 'package:verified_dating_app/features/profile/screens/setup/setup_photos_screen.dart';
import 'package:verified_dating_app/features/profile/screens/setup/setup_preferences_screen.dart';
import 'package:verified_dating_app/features/profile/screens/setup/setup_preview_screen.dart';
import 'package:verified_dating_app/features/safety/screens/sos_screen.dart';
import 'package:verified_dating_app/features/support/screens/support_ticket_form_screen.dart';
import 'package:verified_dating_app/features/support/screens/support_ticket_thread_screen.dart';
import 'package:verified_dating_app/features/support/screens/support_tickets_screen.dart';
import 'package:verified_dating_app/features/swipe/models/discovery_profile.dart';
import 'package:verified_dating_app/features/swipe/screens/home_discovery_screen.dart';
import 'package:verified_dating_app/features/city_pilot/city_pilot_screen.dart';
import 'package:verified_dating_app/features/first_chapter/chapter_studio_screen.dart';
import 'package:verified_dating_app/features/first_chapter/comfort_cards_screen.dart';
import 'package:verified_dating_app/features/friends/screens/introducer_screen.dart';
import 'package:verified_dating_app/features/social_chat/social_chat_screen.dart';
import 'package:verified_dating_app/features/swipe/screens/liked_me_screen.dart';
import 'package:verified_dating_app/features/swipe/screens/liked_profiles_screen.dart';
import 'package:verified_dating_app/features/swipe/screens/passed_profiles_screen.dart';
import 'package:verified_dating_app/features/swipe/screens/profile_details_screen.dart';
import 'package:verified_dating_app/features/swipe/screens/spotlight_profiles_screen.dart';
import 'package:verified_dating_app/features/verification/screens/verification_landing_screen.dart';
import 'package:verified_dating_app/features/verification/screens/verification_selfie_screen.dart';
import 'package:verified_dating_app/features/verification/screens/verification_status_screen.dart';
import 'package:verified_dating_app/features/verification/screens/verification_upload_id_screen.dart';
import 'package:verified_dating_app/features/web/web_entry_screen.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

import '../../support/qa_profile_fixtures.dart';

/// Shared harness for the screen matrix (`screen_matrix_test.dart`) and the
/// accessibility guideline checks (`screen_accessibility_test.dart`).
///
/// Both suites must walk the *same* screen map: a screen added here is
/// automatically layout-checked at every size and accessibility-checked at the
/// reference phone size.
class _LayoutAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(
    isAuthenticated: true,
    userId: 'layout-member',
    username: 'layout_member',
  );
}

class _LayoutDraft extends ProfileSetupNotifier {
  @override
  Future<ProfileDraft> build() async => qaProfileDraft();
}

Dio _layoutApi() {
  final dio = Dio(BaseOptions(baseUrl: 'https://layout.invalid'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (o, h) => h.resolve(
        Response<dynamic>(
          requestOptions: o,
          statusCode: 200,
          data: <String, dynamic>{},
        ),
      ),
    ),
  );
  return dio;
}

/// Every device size the app ships to.
const screenMatrixDevices = <String, Size>{
  'small phone 320x568': Size(320, 568),
  'phone 360x780': Size(360, 780),
  'large phone 430x932': Size(430, 932),
  'tablet portrait 768x1024': Size(768, 1024),
  'tablet landscape 1024x1366': Size(1024, 1366),
};

/// The mainstream phone the accessibility guidelines are checked on.
const screenMatrixReferencePhone = 'phone 360x780';

/// Every screen in the app, keyed by its class name.
Map<String, Widget Function()> buildScreenMatrix() {
  final sampleProfile = DiscoveryProfile(
    id: 'p-1',
    name: 'Ananya',
    dateOfBirth: DateTime(1998, 4, 12),
    bio: 'Architect. Filter coffee maximalist.',
    additionalInfo: null,
    profession: 'Architect',
    education: 'CEPT',
    instagramHandle: null,
    hobbies: const ['reading', 'pottery'],
    favoriteSongs: const ['Raga Yaman'],
    extraCurriculars: const ['choir'],
    intentTags: const ['serious'],
    languageTags: const ['en', 'ta'],
    isVerified: true,
    photoUrls: const [],
  );

  return <String, Widget Function()>{
    // auth
    'WelcomeScreen': WelcomeScreen.new,
    'WebEntryScreen': WebEntryScreen.new,
    'AuthScreen': AuthScreen.new,
    'AccountRecoveryScreen': AccountRecoveryScreen.new,
    'SignupScreen': SignupScreen.new,
    'UserAgreementScreen': UserAgreementScreen.new,
    // blog
    'BlogScreen': BlogScreen.new,
    'BlogDetailScreen': () => const BlogDetailScreen(id: 'chapter-1'),
    'BlogWritersScreen': BlogWritersScreen.new,
    // calls
    'CallHistoryScreen': CallHistoryScreen.new,
    'CallSessionScreen': () => const CallSessionScreen(
      matchId: 'm-1',
      recipientUserId: 'u-2',
      recipientName: 'Meera',
    ),
    // clubs
    'ClubsScreen': ClubsScreen.new,
    'ClubDetailScreen': () => const ClubDetailScreen(clubId: 'club-1'),
    'MyListsScreen': MyListsScreen.new,
    'TitleDetailScreen': () => const TitleDetailScreen(titleId: 'title-1'),
    // common
    'AboutAppScreen': AboutAppScreen.new,
    'BlockedUsersScreen': BlockedUsersScreen.new,
    'EmergencyContactsScreen': EmergencyContactsScreen.new,
    'HelpSupportScreen': HelpSupportScreen.new,
    // support
    'SupportTicketFormScreen': SupportTicketFormScreen.new,
    'SupportTicketsScreen': SupportTicketsScreen.new,
    'SupportTicketThreadScreen': () =>
        const SupportTicketThreadScreen(ticketId: 'ticket-1'),
    'LanguageSettingsScreen': LanguageSettingsScreen.new,
    'MainNavigationScreen': MainNavigationScreen.new,
    'ModerationAppealsScreen': ModerationAppealsScreen.new,
    'NotificationSettingsScreen': NotificationSettingsScreen.new,
    'AccountDataScreen': AccountDataScreen.new,
    'PrivacySafetyScreen': PrivacySafetyScreen.new,
    'SettingsScreen': SettingsScreen.new,
    // engagement
    'CircleChallengesScreen': CircleChallengesScreen.new,
    'GroupsScreen': GroupsScreen.new,
    'GroupDetailScreen': () => const GroupDetailScreen(groupId: 'group-1'),
    'CreateGroupScreen': CreateGroupScreen.new,
    'ConversationRoomsScreen': ConversationRoomsScreen.new,
    'DailyPromptScreen': DailyPromptScreen.new,
    'EngagementHubScreen': EngagementHubScreen.new,
    'GroupCoffeePollsScreen': GroupCoffeePollsScreen.new,
    'LevelProgressionScreen': LevelProgressionScreen.new,
    'MatchNudgesScreen': MatchNudgesScreen.new,
    'TrustBadgesScreen': TrustBadgesScreen.new,
    'TrustFilterScreen': TrustFilterScreen.new,
    'VoiceIcebreakersScreen': VoiceIcebreakersScreen.new,
    // friends
    'FriendsScreen': FriendsScreen.new,
    'PlansScreen': PlansScreen.new,
    // graduation
    'GraduationCelebrationScreen': () =>
        const GraduationCelebrationScreen(matchId: 'm-1', partnerName: 'Meera'),
    // matching
    'ActivitySessionScreen': () => const ActivitySessionScreen(
      matchId: 'm-1',
      otherUserId: 'u-2',
      otherUserName: 'Meera',
    ),
    'MatchNotificationScreen': () => const MatchNotificationScreen(
      matchId: 'm-1',
      otherUserId: 'u-2',
      otherUserName: 'Meera',
      otherUserPhotoUrl: '',
    ),
    'MatchesListScreen': MatchesListScreen.new,
    // messaging
    'ChatScreen': () => const ChatScreen(
      matchId: 'm-1',
      otherUserId: 'u-2',
      userName: 'Meera',
      userPhotoUrl: '',
    ),
    // notifications
    'NotificationInboxScreen': NotificationInboxScreen.new,
    // photo themes
    'PhotoThemesScreen': PhotoThemesScreen.new,
    'PhotoThemeGalleryScreen': () =>
        const PhotoThemeGalleryScreen(themeId: 'theme-1'),
    // payment: layout chrome only, never a live provider page.
    'CheckoutWebViewScreen': () => const CheckoutWebViewScreen(
      planName: 'Plus',
      checkout: BillingCheckout(
        id: 'layout-checkout',
        status: 'open',
        checkoutUrl: 'https://example.invalid/checkout',
        planCode: 'plus',
        billingCycle: 'monthly',
        amountMinor: 99900,
        currency: 'INR',
      ),
    ),
    'SubscriptionScreen': SubscriptionScreen.new,
    'WalletPaymentScreen': () => const WalletPaymentScreen(walletCoins: 120),
    // profile
    'EditProfileScreen': EditProfileScreen.new,
    'ProfileViewScreen': ProfileViewScreen.new,
    'ProfileViewersScreen': ProfileViewersScreen.new,
    'ProfileSetupEntryScreen': ProfileSetupEntryScreen.new,
    'SetupAboutScreen': SetupAboutScreen.new,
    'SetupPhotosScreen': SetupPhotosScreen.new,
    'SetupPreferencesScreen': SetupPreferencesScreen.new,
    'SetupPreviewScreen': SetupPreviewScreen.new,
    // safety
    'SosScreen': SosScreen.new,
    // swipe
    'HomeDiscoveryScreen': HomeDiscoveryScreen.new,
    'LikedProfilesScreen': LikedProfilesScreen.new,
    'PassedProfilesScreen': PassedProfilesScreen.new,
    'ProfileDetailsScreen': () => ProfileDetailsScreen(profile: sampleProfile),
    'SpotlightProfilesScreen': () =>
        SpotlightProfilesScreen(profiles: [sampleProfile]),
    // verification
    'VerificationLandingScreen': VerificationLandingScreen.new,
    'VerificationSelfieScreen': () =>
        VerificationSelfieScreen(idPhoto: XFile('test/fixtures/id.jpg')),
    'VerificationStatusScreen': VerificationStatusScreen.new,
    'VerificationUploadIdScreen': VerificationUploadIdScreen.new,
    'ChapterStudioScreen': () =>
        const ChapterStudioScreen(matchId: 'm-1', partnerName: 'Meera'),
    'CityPilotScreen': CityPilotScreen.new,
    'ComfortCardsScreen': ComfortCardsScreen.new,
    'IntroducerScreen': IntroducerScreen.new,
    'LikedMeScreen': LikedMeScreen.new,
    'SocialChatScreen': () =>
        const SocialChatScreen(channelId: 'c-1', title: 'Weekend hikers'),
  };
}

/// Offline fixtures (signed-in member, draft, master data, canned API) so a
/// screen renders its real content without a backend.
List<Override> screenMatrixOverrides() => [
  authNotifierProvider.overrideWith(_LayoutAuth.new),
  profileSetupNotifierProvider.overrideWith(_LayoutDraft.new),
  preferenceMasterDataProvider.overrideWith(
    (ref) async => PreferenceMasterData.localFallback(),
  ),
  preferenceMasterDataOfflineProvider.overrideWith((ref) => false),
  apiClientProvider.overrideWithValue(_layoutApi()),
];

/// True for the errors this harness exists to catch.
bool isLayoutError(Object error) {
  final text = error.toString();
  return text.contains('overflowed') ||
      text.contains('RenderFlex') ||
      text.contains('RenderBox was not laid out') ||
      text.contains('hasSize') ||
      text.contains('Vertical viewport was given unbounded height') ||
      text.contains('Horizontal viewport was given unbounded width');
}

/// Pumps [child] at [size] and returns the layout errors it produced.
///
/// [whileMounted] runs after the screen has settled, while semantics are still
/// enabled, so callers can inspect the mounted tree (for example, evaluate
/// accessibility guidelines). Its own exceptions propagate to the caller rather
/// than being filtered as runtime noise.
Future<List<Object>> pumpAndCollectLayoutErrors(
  WidgetTester tester,
  Widget child,
  Size size,
  ThemeData theme, {
  TextScaler textScaler = TextScaler.noScaling,
  List<Override> overrides = const [],
  FutureOr<void> Function()? whileMounted,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final layoutErrors = <Object>[];
  final semantics = tester.ensureSemantics();
  final previousOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    if (!isLayoutError(details.exception)) {
      return;
    }
    if (const bool.fromEnvironment('QA_VERBOSE_LAYOUT')) {
      debugPrint(details.toString());
    }
    // Keep the widget location: "overflowed by 167 pixels" is not actionable
    // on its own; the creator line is what points at the offending Row.
    final where = details.context?.toDescription() ?? '';
    layoutErrors.add('${details.exception}${where.isEmpty ? '' : ' [$where]'}');
  };

  try {
    try {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            if (const bool.fromEnvironment('QA_SCREEN_FIXTURES'))
              ...screenMatrixOverrides(),
            ...overrides,
          ],
          child: MaterialApp(
            theme: theme,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, appChild) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: textScaler),
              child: appChild!,
            ),
            home: child,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
    } on Object catch (error) {
      if (isLayoutError(error)) {
        layoutErrors.add(error);
      }
    }
    if (whileMounted != null) {
      await whileMounted();
    }
  } finally {
    FlutterError.onError = previousOnError;
    semantics.dispose();
  }

  // Drain anything the framework captured so it cannot leak into the next
  // test as a spurious failure.
  for (var i = 0; i < 24; i++) {
    final captured = tester.takeException();
    if (captured == null) {
      break;
    }
    if (isLayoutError(captured)) {
      layoutErrors.add(captured);
    }
  }
  return layoutErrors;
}
