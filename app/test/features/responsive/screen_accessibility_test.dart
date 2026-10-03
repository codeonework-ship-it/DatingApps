import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/runtime_feature_flags_provider.dart';
import 'package:verified_dating_app/core/theme/app_theme.dart';
import 'package:verified_dating_app/features/web/web_member_workspace.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../support/layout_webview_platform.dart';
import 'screen_matrix_harness.dart';

/// Accessibility guideline checks for every screen in the matrix.
///
/// The layout matrix only switches semantics on; it never asks whether what it
/// builds is usable with TalkBack or VoiceOver, or with a thumb. These run
/// Flutter's own guideline checks over the settled semantics tree of every
/// screen in `screen_matrix_harness.dart` (plus the authenticated web shell),
/// on the reference phone, in both shipped themes:
///
///  * [labeledTapTargetGuideline] — anything tappable announces a label or
///    tooltip, so a screen reader never says just "button".
///  * [androidTapTargetGuideline] — anything tappable is at least 48x48.
///  * [textContrastGuideline] — text meets WCAG AA contrast against what is
///    actually painted behind it.
///
/// Screens are pumped exactly as the layout matrix pumps them — no backend —
/// so most show their signed-out, empty or error state. That is the state
/// being checked.
///
/// Known failures live in [_knownFailures]. It is a ratchet, not a skip list:
/// a screen may not fail any *other* guideline, may not fail an allowlisted one
/// on more nodes than recorded, and an entry that has improved or been fixed
/// must be lowered or deleted in the same change. The list only shrinks.
void main() {
  WebViewPlatform.instance = LayoutWebViewPlatform();

  // VoiceIcebreakersScreen constructs an AudioRecorder, which fires an
  // unawaited `create` on the record plugin's channel. The layout matrix never
  // lets real async work complete, so the MissingPluginException never lands;
  // the contrast check has to (it renders the frame for real), and the
  // exception would then surface as an uncaught test error. Answer the channel
  // instead: this is plugin plumbing, not something the guidelines judge.
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.llfbandit.record/messages'),
          (call) async => null,
        );
  });

  final guidelines = <String, AccessibilityGuideline>{
    _labels: labeledTapTargetGuideline,
    _tapTargets: androidTapTargetGuideline,
    _contrast: textContrastGuideline,
  };

  final themes = <String, ThemeData>{
    'light': AppTheme.lightTheme,
    'dark': AppTheme.darkTheme,
  };

  final reference = screenMatrixDevices[screenMatrixReferencePhone]!;
  final flags = <Override>[
    runtimeFeatureFlagsProvider.overrideWith(
      (ref) => Stream.value(RuntimeFeatureFlags.defaults),
    ),
  ];

  final targets = <String, _Target>{
    for (final entry in buildScreenMatrix().entries)
      entry.key: (build: entry.value, size: reference, overrides: const []),
    // The browser shell is not a *Screen, so the matrix does not list it.
    _webDesktop: (
      build: WebMemberWorkspace.new,
      size: const Size(1440, 900),
      overrides: flags,
    ),
    _webPhone: (
      build: WebMemberWorkspace.new,
      size: reference,
      overrides: flags,
    ),
  };

  Future<void> checkGuidelines(
    WidgetTester tester,
    String label,
    _Target target,
    String themeLabel,
    ThemeData theme,
  ) async {
    final failing = <String, String>{};
    await pumpAndCollectLayoutErrors(
      tester,
      target.build(),
      target.size,
      theme,
      overrides: target.overrides,
      whileMounted: () async {
        for (final entry in guidelines.entries) {
          final evaluation = await entry.value.evaluate(tester);
          if (!evaluation.passed) {
            failing[entry.key] = evaluation.reason ?? '';
          }
        }
      },
    );

    final known = _knownFailures['$label [$themeLabel]'] ?? const {};
    final problems = <String>[];
    for (final guideline in guidelines.keys) {
      final reason = failing[guideline];
      final nodes = reason == null
          ? 0
          : 'SemanticsNode#'.allMatches(reason).length;
      final ceiling = known[guideline]?.nodes ?? 0;
      if (nodes > ceiling) {
        problems.add(
          '$guideline: $nodes failing node(s), allowlist permits $ceiling'
          '\n$reason',
        );
      } else if (nodes < ceiling) {
        problems.add(
          '$guideline improved: $nodes failing node(s), allowlist still '
          'says $ceiling. '
          '${nodes == 0 ? 'Delete' : 'Lower'} the "$label [$themeLabel]" '
          '$guideline entry in _knownFailures.',
        );
      }
    }
    expect(
      problems,
      isEmpty,
      reason: '$label [$themeLabel] accessibility:\n${problems.join('\n\n')}',
    );
  }

  themes.forEach((themeLabel, theme) {
    targets.forEach((label, target) {
      final feature = _caseFeatures[label];
      if (feature == null) {
        // The browser shell is not a catalog screen.
        testWidgets(
          '$label meets accessibility guidelines [$themeLabel]',
          (tester) => checkGuidelines(tester, label, target, themeLabel, theme),
        );
        return;
      }
      // Every matrix screen proves `<feature>.a11y_guidelines`: labelled tap
      // targets, 48x48 tap targets and AA contrast, with the ratchet below.
      testWidgets(
        '$label meets accessibility guidelines [$themeLabel] '
        '[case:$feature.a11y_guidelines]',
        (tester) => checkGuidelines(tester, label, target, themeLabel, theme),
      );
    });
  });

  test('every matrix screen names its catalog feature', () {
    expect(
      _caseFeatures.keys.toSet(),
      buildScreenMatrix().keys.toSet(),
      reason: 'Add the catalog feature id of each new screen to _caseFeatures',
    );
  });

  test('every allowlisted accessibility failure names a real check', () {
    for (final MapEntry(key: target, value: entries)
        in _knownFailures.entries) {
      final match = RegExp(r'^(.*) \[(light|dark)\]$').firstMatch(target);
      expect(match, isNotNull, reason: '"$target" must end in [light|dark]');
      expect(
        targets.containsKey(match!.group(1)),
        isTrue,
        reason: '"$target" is not a screen this suite checks',
      );
      for (final MapEntry(key: guideline, value: known) in entries.entries) {
        expect(guidelines.containsKey(guideline), isTrue, reason: guideline);
        expect(known.nodes, greaterThan(0), reason: '$target $guideline');
        expect(known.why, isNotEmpty, reason: '$target $guideline');
      }
    }
  });
}

typedef _Target = ({
  Widget Function() build,
  Size size,
  List<Override> overrides,
});

typedef _Known = ({int nodes, String why});

const _labels = 'labeled tap targets';
const _tapTargets = 'android tap targets';
const _contrast = 'text contrast';
const _webDesktop = 'WebMemberWorkspace desktop 1440x900';
const _webPhone = 'WebMemberWorkspace phone';

/// Per-screen, per-theme, per-guideline accessibility debt.
///
/// `nodes` is the exact number of failing semantics nodes today. The suite
/// fails if it grows, and also fails if it shrinks until the entry is lowered
/// or deleted, so this map can only get smaller. Do not add entries: fix the
/// screen.
const _knownFailures = <String, Map<String, _Known>>{};

/// Catalog feature id of each matrix screen (qa/catalog/feature_catalog.json).
/// The guideline test of a screen proves `<feature>.a11y_guidelines`.
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
