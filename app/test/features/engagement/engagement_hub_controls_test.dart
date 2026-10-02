// Engage hub: every tile opens its screen (and that screen starts loading
// from the BFF), runtime flags hide gated tiles, and the hub renders in every
// locale.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/blog/blog_screen.dart';
import 'package:verified_dating_app/features/city_pilot/city_pilot_screen.dart';
import 'package:verified_dating_app/features/clubs/clubs_screen.dart';
import 'package:verified_dating_app/features/engagement/screens/circle_challenges_screen.dart';
import 'package:verified_dating_app/features/engagement/screens/conversation_rooms_screen.dart';
import 'package:verified_dating_app/features/engagement/screens/daily_prompt_screen.dart';
import 'package:verified_dating_app/features/engagement/screens/engagement_hub_screen.dart';
import 'package:verified_dating_app/features/engagement/screens/group_coffee_polls_screen.dart';
import 'package:verified_dating_app/features/engagement/screens/level_progression_screen.dart';
import 'package:verified_dating_app/features/engagement/screens/trust_badges_screen.dart';
import 'package:verified_dating_app/features/engagement/screens/trust_filter_screen.dart';
import 'package:verified_dating_app/features/engagement/screens/voice_icebreakers_screen.dart';
import 'package:verified_dating_app/features/friends/screens/friends_screen.dart';
import 'package:verified_dating_app/features/groups/groups_screen.dart';
import 'package:verified_dating_app/features/photo_themes/photo_themes_screen.dart';

import '../../support/qa_api.dart';
import 'engagement_qa.dart';

/// Every flag the hub reads, on.
const _allOn = {
  'intentional_dating_enabled': true,
  'photo_themes_enabled': true,
  'clubs_enabled': true,
  'daily_prompts_enabled': true,
  'voice_icebreakers_enabled': true,
  'circles_enabled': true,
  'group_coffee_polls_enabled': true,
  'groups_enabled': true,
  'rooms_enabled': true,
  'level_progression_enabled': true,
  'billing_enabled': true,
};

QaApi _api() => QaApi()
  ..json('GET /engagement/daily-prompt/me', {
    'daily_prompt': {
      'prompt': {'id': 'dp-1', 'prompt_text': 'What makes you laugh?'},
      'streak': {'current_days': 0},
      'spark': {'participants_today': 7, 'similar_answer_count': 0},
    },
  })
  ..json('GET /billing/coexistence-matrix', {
    'core_progression_non_blocking': true,
    'features': <Object>[],
  });

Future<void> _openHub(
  WidgetTester tester,
  QaApi api, {
  Map<String, bool> flags = _allOn,
}) => pumpQa(tester, api, const EngagementHubScreen(), flags: flags);

Finder _tile(String name) => find.byKey(ValueKey('qa.engagement_hub.$name'));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    // The voice screen creates a recorder; the plugin is not loaded in tests.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.llfbandit.record/messages'),
          (call) async => null,
        );
  });

  for (final (tile, title, screen, firstRequest, tag) in [
    (
      'blog',
      'Blog · Open Chapters',
      BlogScreen,
      null,
      '[case:engagement.engagement_hub.blog_open_chapters.action]',
    ),
    (
      'photo_themes',
      'Photo Themes',
      PhotoThemesScreen,
      null,
      '[case:engagement.engagement_hub.photo_themes.action]',
    ),
    (
      'clubs',
      'Book & Film Clubs',
      ClubsScreen,
      null,
      '[case:engagement.engagement_hub.book_film_clubs.action]',
    ),
    (
      'city_pilot',
      'The City Pilot',
      CityPilotScreen,
      null,
      '[case:engagement.engagement_hub.the_city_pilot.action]',
    ),
    (
      'daily_prompt',
      'Daily Prompt Streak',
      DailyPromptScreen,
      null,
      '[case:engagement.engagement_hub.daily_prompt_streak.action]',
    ),
    (
      'voice_icebreakers',
      'Guided Voice Icebreakers',
      VoiceIcebreakersScreen,
      '/engagement/voice-icebreakers/prompts',
      '[case:engagement.engagement_hub.guided_voice_icebreakers.action]',
    ),
    (
      'circles',
      'Local Circle Challenges',
      CircleChallengesScreen,
      '/engagement/circles/circle-blr-books/challenge',
      '[case:engagement.engagement_hub.local_circle_challenges.action]',
    ),
    (
      'coffee_polls',
      'Group Coffee Poll',
      GroupCoffeePollsScreen,
      '/engagement/group-coffee-polls',
      '[case:engagement.engagement_hub.group_coffee_poll.action]',
    ),
    (
      'groups',
      'Groups',
      GroupsScreen,
      null,
      '[case:engagement.engagement_hub.groups.action]',
    ),
    (
      'conversation_rooms',
      'Conversation Rooms',
      ConversationRoomsScreen,
      null,
      '[case:engagement.engagement_hub.conversation_rooms.action]',
    ),
    (
      'friends',
      'Friends & Introductions',
      FriendsScreen,
      null,
      '[case:engagement.engagement_hub.friends_introductions.action]',
    ),
    (
      'level_xp',
      'Level & XP',
      LevelProgressionScreen,
      '/progression/me',
      '[case:engagement.engagement_hub.level_xp.action]',
    ),
    (
      'trust_badges',
      'Trust Badges',
      TrustBadgesScreen,
      '/users/me/trust-badges',
      '[case:engagement.engagement_hub.trust_badges.action]',
    ),
    (
      'trust_filters',
      'Trust Filters',
      TrustFilterScreen,
      '/discovery/me/filters/trust',
      '[case:engagement.engagement_hub.trust_filters.action]',
    ),
  ]) {
    testWidgets('$title tile opens $screen and Back returns to the hub $tag', (
      tester,
    ) async {
      final api = _api();
      await _openHub(tester, api);
      await qaScrollTo(tester, _tile(tile));
      expect(
        find.descendant(of: _tile(tile), matching: find.text(title)),
        findsOneWidget,
      );
      expect(find.byType(screen), findsNothing);
      if (firstRequest != null) {
        expect(api.sent('GET', firstRequest), isEmpty);
      }

      await tester.tap(_tile(tile));
      await qaSettle(tester, frames: 15);
      // Screens owned by other areas meet a bare fake BFF (404s): they must
      // still open without throwing.
      expect(tester.takeException(), isNull);

      expect(find.byType(screen), findsOneWidget);
      expect(find.byType(EngagementHubScreen).hitTestable(), findsNothing);
      if (firstRequest != null) {
        expect(api.sent('GET', firstRequest), isNotEmpty);
      }
      expect(api.writes, isEmpty, reason: 'opening a screen changes nothing');

      await tester.pageBack();
      await qaSettle(tester, frames: 15);
      expect(tester.takeException(), isNull);
      expect(find.byType(screen), findsNothing);
      expect(_tile(tile).hitTestable(), findsOneWidget);
      await qaUnmount(tester);
    });
  }

  testWidgets(
    'Daily Prompt tile previews how many people replied today and opens that prompt [case:engagement.engagement_hub.daily_prompt_streak.action]',
    (tester) async {
      final api = _api();
      await _openHub(tester, api);
      await qaScrollTo(tester, _tile('daily_prompt'));
      expect(
        find.descendant(
          of: _tile('daily_prompt'),
          matching: find.text(en.engagementHubPromptRepliedToday(7)),
        ),
        findsOneWidget,
      );
      expect(api.sent('GET', '/engagement/daily-prompt/me'), hasLength(1));

      await tester.tap(_tile('daily_prompt'));
      await qaSettle(tester);
      expect(find.byType(DailyPromptScreen), findsOneWidget);
      expect(find.text('What makes you laugh?').hitTestable(), findsOneWidget);
      expect(
        api.sent('GET', '/engagement/daily-prompt/me'),
        hasLength(1),
        reason: 'the screen shares the prompt the hub already loaded',
      );
    },
  );

  testWidgets(
    'with the release-excluded flags off, Level & XP and Voice Icebreakers are hidden and the rest stay [case:engagement.engagement_hub.release_gates]',
    (tester) async {
      await _openHub(
        tester,
        _api(),
        flags: {
          ..._allOn,
          'level_progression_enabled': false,
          'voice_icebreakers_enabled': false,
        },
      );
      for (final name in ['trust_filters', 'daily_prompt']) {
        await qaScrollTo(tester, _tile(name));
        expect(_tile(name), findsOneWidget);
      }
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
      await tester.pump();
      expect(_tile('level_xp'), findsNothing);
      expect(find.text(en.engagementLevelTitle), findsNothing);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 3000));
      await tester.pump();
      for (var i = 0; i < 12; i++) {
        expect(_tile('voice_icebreakers'), findsNothing);
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -250));
        await tester.pump();
      }
      expect(find.text(en.engagementHubVoiceTitle), findsNothing);
    },
  );

  testWidgets(
    'with every optional surface off only the core tiles remain and the Create section is gone [case:engagement.engagement_hub.release_gates]',
    (tester) async {
      await _openHub(
        tester,
        _api(),
        flags: {for (final key in _allOn.keys) key: false},
      );
      final seen = <String>{};
      for (var i = 0; i < 12; i++) {
        for (final element
            in find
                .byWidgetPredicate(
                  (w) =>
                      w.key is ValueKey<String> &&
                      (w.key! as ValueKey<String>).value.startsWith(
                        'qa.engagement_hub.',
                      ),
                )
                .evaluate()) {
          seen.add((element.widget.key! as ValueKey<String>).value);
        }
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -250));
        await tester.pump();
      }
      expect(seen, {
        'qa.engagement_hub.city_pilot',
        'qa.engagement_hub.friends',
        'qa.engagement_hub.trust_badges',
        'qa.engagement_hub.trust_filters',
      });
      expect(find.text(en.engagementHubSectionCreate), findsNothing);
    },
  );

  testWidgets(
    'Engage hub renders translated in every locale without overflow [case:engagement.engagement_hub.l10n]',
    (tester) async {
      for (final locale in qaLocales) {
        await pumpQa(
          tester,
          _api(),
          const EngagementHubScreen(),
          locale: locale,
          flags: _allOn,
        );
        final l = qaL10n(locale);
        expect(tester.takeException(), isNull, reason: '$locale');
        expect(find.text(l.engagementHubTitle), findsOneWidget);
        expect(find.text(l.engagementHubSectionCreate), findsOneWidget);
        await qaScrollTo(tester, find.text(l.settingsTrustFiltersTitle));
        expect(tester.takeException(), isNull, reason: '$locale');
        expect(find.text(l.settingsTrustBadgesTitle), findsOneWidget);
        expect(find.text(l.engagementLevelTitle), findsOneWidget);
        await qaUnmount(tester);
      }
    },
  );
}
