// Matches: tabs, search, filters, rows and cards, and every action in the
// match options sheet (call, activity, plan, graduation, add friend, nudge,
// close, report) against the recording fake BFF — the exact request, the
// screen or sheet that follows, and what the member reads on failure.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/permissions/device_permission_service.dart';
import 'package:verified_dating_app/features/calls/screens/call_history_screen.dart';
import 'package:verified_dating_app/features/calls/screens/call_session_screen.dart';
import 'package:verified_dating_app/features/common/screens/moderation_appeals_screen.dart';
import 'package:verified_dating_app/features/first_chapter/chapter_studio_screen.dart';
import 'package:verified_dating_app/features/intentional_dating/connection_card.dart';
import 'package:verified_dating_app/features/matching/screens/activity_session_screen.dart';
import 'package:verified_dating_app/features/matching/screens/matches_list_screen.dart';
import 'package:verified_dating_app/features/messaging/screens/chat_screen.dart';
import 'package:verified_dating_app/features/swipe/screens/home_discovery_screen.dart';

import '../../support/qa_api.dart';
import '../swipe/discover_qa_fixtures.dart';
import '../swipe/qa_screen_checks.dart';

class _GrantedPermissions extends DevicePermissionService {
  const _GrantedPermissions();
  @override
  Future<bool> requestCallPermissions() async => true;
}

final _maya = qaMatchRow(
  'm1',
  'maya',
  'Maya',
  lastMessage: 'See you Sunday?',
  unread: 2,
);
final _arjun = qaMatchRow('m2', 'arjun', 'Arjun', lastMessage: 'Coffee?');

final _start = DateTime.now().toUtc().add(const Duration(days: 2));
final _slotStart = DateTime.utc(_start.year, _start.month, _start.day, 8, 15);
final _slotEnd = _slotStart.add(const Duration(minutes: 90));

QaApi _api({List<Map<String, dynamic>>? matches}) =>
    qaDiscoverApi(matches: matches ?? [_maya, _arjun])
      ..json('POST /matches/*/read', <String, dynamic>{})
      ..json('POST /calls/start', {
        'session': {
          'id': 'call-1',
          'match_id': 'm1',
          'status': 'active',
          'room_id': 'room-1',
          'started_at': '2026-10-02T10:00:00Z',
        },
      })
      ..json('POST /activities/sessions/start', {
        'session': {
          'id': 'act-1',
          'status': 'active',
          'activity_type': 'this_or_that',
          'started_at': DateTime.now().toUtc().toIso8601String(),
          'expires_at': DateTime.now()
              .toUtc()
              .add(const Duration(minutes: 3))
              .toIso8601String(),
        },
      })
      ..json('POST /engagement/match-nudges/send', {
        'nudge': {'id': 'n1', 'match_id': 'm1'},
      })
      ..json('DELETE /matches/*', <String, dynamic>{})
      ..json('POST /safety/report', {
        'report': {'id': 'report-9'},
      })
      ..json('POST /matches/m1/plans', {
        'plan': {
          'id': 'p1',
          'match_id': 'm1',
          'proposer_user_id': 'me',
          'invitee_user_id': 'maya',
          'status': 'proposed',
          'window_start': _slotStart.toIso8601String(),
          'window_end': _slotEnd.toIso8601String(),
          'venue_category': 'coffee',
          'viewer_role': 'proposer',
          'partner_user_id': 'maya',
          'partner_name': 'Maya',
          'next_action': 'wait',
          'lock_version': 1,
        },
      })
      ..json('POST /matches/m1/graduation', {
        'graduation': {
          'id': 'g1',
          'match_id': 'm1',
          'proposer_user_id': 'me',
          'partner_user_id': 'maya',
          'status': 'proposed',
          'viewer_role': 'proposer',
        },
      })
      ..json('POST /friends/me', {
        'friend': {'status': 'pending'},
      });

Future<void> _open(
  WidgetTester tester,
  QaApi api, {
  MatchesView? view,
  Map<String, bool> flags = const {},
}) async {
  await pumpQa(
    tester,
    api,
    const MatchesListScreen(),
    flags: {'curated_daily_set_enabled': false, ...flags},
    extra: [
      ...qaDiscoverExtras(),
      devicePermissionServiceProvider.overrideWithValue(
        const _GrantedPermissions(),
      ),
      datingConnectionProvider('m1').overrideWith(
        (_) => Stream.value({
          'overlap': [
            {
              'start': _slotStart.toIso8601String(),
              'end': _slotEnd.toIso8601String(),
            },
          ],
        }),
      ),
      if (view != null) matchesViewProvider.overrideWith((ref) => view),
    ],
  );
}

Future<void> _tap(WidgetTester tester, Key key, {int frames = 12}) async {
  await tester.ensureVisible(find.byKey(key).first);
  await tester.tap(find.byKey(key).first);
  await qaSettle(tester, frames: frames);
}

/// Opens the options sheet of Maya's conversation row.
Future<void> _openOptions(WidgetTester tester, QaApi api) async {
  await _open(tester, api, view: MatchesView.conversations);
  await _tap(tester, const ValueKey('qa.matches.match_row.m1.options'));
  expect(find.byKey(const ValueKey('qa.matches.unmatch_action')), findsOne);
}

Finder _row(String id) => find.byKey(ValueKey('qa.matches.match_row.$id'));

void main() {
  qaSilenceNetworkImages();

  group('views, search and filters', () {
    testWidgets('the tabs switch between Discover, people and conversations '
        '[case:matching.matches_list.matches_x_tab.action]', (tester) async {
      final api = _api();
      await _open(tester, api);
      expect(find.byType(HomeDiscoveryScreen), findsOneWidget);

      await _tap(tester, const ValueKey('qa.matches.people_tab'));
      expect(find.byKey(const ValueKey('qa.matches.person.m1')), findsOne);
      expect(
        find.text('People you chose. Possibilities you shape together.'),
        findsOneWidget,
      );

      await _tap(tester, const ValueKey('qa.matches.conversations_tab'));
      expect(_row('m1'), findsOneWidget);
      expect(
        find.text('A little closer, one message at a time.'),
        findsOneWidget,
      );

      await _tap(tester, const ValueKey('qa.matches.discover_tab'));
      expect(find.byType(HomeDiscoveryScreen), findsOneWidget);
    });

    testWidgets("Discover's Messages opens the conversations "
        '[case:matching.matches_list.messages_onopenmessages.action]', (
      tester,
    ) async {
      final api = _api();
      await _open(tester, api);
      await _tap(tester, const ValueKey('qa.discovery.messages_button'));

      expect(_row('m1'), findsOneWidget);
      expect(_row('m2'), findsOneWidget);
    });

    testWidgets('search narrows conversations by name or last message '
        '[case:matching.matches_list.chat_search_conversations.action] '
        '[case:matching.matches_list.chat_search_conversations.validation]', (
      tester,
    ) async {
      final api = _api();
      await _open(tester, api, view: MatchesView.conversations);
      final search = find.byKey(const ValueKey('qa.chat.search_conversations'));

      await tester.enterText(search, 'ARJ');
      await qaSettle(tester, frames: 2);
      expect(_row('m2'), findsOneWidget);
      expect(_row('m1'), findsNothing);

      await tester.enterText(search, 'sunday');
      await qaSettle(tester, frames: 2);
      expect(_row('m1'), findsOneWidget);
      expect(_row('m2'), findsNothing);

      await tester.enterText(search, 'zzz 🙂');
      await qaSettle(tester, frames: 2);
      expect(
        find.text('No conversations here yet. Try another search or filter.'),
        findsOneWidget,
      );
      expect(api.writes, isEmpty, reason: 'search is local');
    });

    testWidgets('Unread shows only unread conversations; All shows all '
        '[case:matching.matches_list.matches_filter_unread.action] '
        '[case:matching.matches_list.matches_filter_all.action]', (
      tester,
    ) async {
      final api = _api();
      await _open(tester, api, view: MatchesView.conversations);
      expect(find.text('Unread · 1'), findsOneWidget);

      await _tap(tester, const ValueKey('qa.matches.filter_unread'));
      expect(_row('m1'), findsOneWidget);
      expect(_row('m2'), findsNothing);

      await _tap(tester, const ValueKey('qa.matches.filter_all'));
      expect(_row('m2'), findsOneWidget);
    });

    testWidgets('Call history opens the call history '
        '[case:matching.matches_list.calls_history.action]', (tester) async {
      final api = _api()..json('GET /calls/history/me', {'history': <dynamic>[]});
      await _open(tester, api, view: MatchesView.people);
      await _tap(tester, const ValueKey('qa.calls.history'));

      expect(find.byType(CallHistoryScreen), findsOneWidget);
      expect(api.sent('GET', '/calls/history/me'), hasLength(1));
    });
  });

  group('load and retry', () {
    testWidgets('a failed load offers Retry, which shows the matches '
        '[case:matching.matches_list.matches_retry.action] '
        '', (tester) async {
      final api = _api()..fail('GET /matches/me', message: 'Matches resting');
      await _open(tester, api, view: MatchesView.people);
      expect(find.text('Unable to load matches'), findsOneWidget);
      expect(find.text('Matches resting'), findsOneWidget);

      api.json('GET /matches/me', {
        'matches': [_maya],
      });
      await _tap(tester, const ValueKey('qa.matches.retry'));

      expect(api.sent('GET', '/matches/me'), hasLength(2));
      expect(find.byKey(const ValueKey('qa.matches.person.m1')), findsOne);
    });

    // Regression (2026-10-02): the load error stuck after a successful
    // retry, so a member with no matches yet stayed on "Unable to load".
    testWidgets('Retry that succeeds with no matches shows the empty state '
        '[case:matching.matches_list.matches_retry.api_failure] '
        '[case:matching.matches_list.matches_retry.clears_error]', (
      tester,
    ) async {
      final api = _api()..offline('GET /matches/me');
      await _open(tester, api, view: MatchesView.people);
      expect(
        find.text('Failed to load matches. Please try again.'),
        findsOneWidget,
      );

      api.json('GET /matches/me', {'matches': <dynamic>[]});
      await _tap(tester, const ValueKey('qa.matches.retry'));

      expect(find.text('Unable to load matches'), findsNothing);
      expect(find.text('No matches yet'), findsOneWidget);
    });
  });

  group('rows and cards', () {
    testWidgets('a conversation row marks it read and opens the chat '
        '[case:matching.matches_list.matches_match_row_x.action] '
        '', (tester) async {
      final api = _api();
      await _open(tester, api, view: MatchesView.conversations);
      await _tap(tester, const ValueKey('qa.matches.match_row.m1'));

      expect(api.sent('POST', '/matches/m1/read').single.body, {
        'user_id': 'me',
      });
      final chat = tester.widget<ChatScreen>(find.byType(ChatScreen));
      expect(chat.matchId, 'm1');
      expect(chat.userName, 'Maya');
    });

    testWidgets('a failed read receipt still opens the chat '
        '[case:matching.matches_list.matches_match_row_x.api_failure]', (
      tester,
    ) async {
      final api = _api()..fail('POST /matches/m1/read');
      await _open(tester, api, view: MatchesView.conversations);
      await _tap(tester, const ValueKey('qa.matches.match_row.m1'));

      expect(api.sent('POST', '/matches/m1/read'), hasLength(1));
      expect(find.byType(ChatScreen), findsOneWidget);
    });

    testWidgets('Open chat on a match card opens the chat '
        '[case:matching.match_overview_card.matches_person_x_chat.action]', (
      tester,
    ) async {
      final api = _api();
      await _open(tester, api, view: MatchesView.people);
      await _tap(tester, const ValueKey('qa.matches.person.m2.chat'));

      expect(tester.widget<ChatScreen>(find.byType(ChatScreen)).matchId, 'm2');
      expect(api.sent('POST', '/matches/m2/read'), hasLength(1));
    });

    testWidgets("a match card's options open the match options "
        '[case:matching.matches_list.matches_person_x_options_options.action] '
        '[case:matching.matches_list.showmodalbottomsheet_open.action]', (
      tester,
    ) async {
      final api = _api();
      await _open(tester, api, view: MatchesView.people);
      await _tap(tester, const ValueKey('qa.matches.person.m1.options'));

      for (final key in [
        'call_action',
        'activity_action',
        'plan_action',
        'graduation_action',
        'nudge_action',
        'unmatch_action',
        'report_action',
      ]) {
        expect(find.byKey(ValueKey('qa.matches.$key')), findsOneWidget);
      }
    });

    testWidgets('long-pressing a conversation opens its options '
        '[case:matching.matches_list.matches_match_row_x_options.action]', (
      tester,
    ) async {
      final api = _api();
      await _open(tester, api, view: MatchesView.conversations);
      await tester.longPress(_row('m2'));
      await qaSettle(tester);

      expect(find.byKey(const ValueKey('qa.matches.nudge_action')), findsOne);
    });

    testWidgets(
      'First Chapter on a match card opens the chapter studio '
      '[case:matching.matches_list.matches_person_x_chapter_chapter.action]',
      (tester) async {
        final api = _api();
        await _open(tester, api, view: MatchesView.people);
        await _tap(tester, const ValueKey('qa.matches.person.m1.chapter'));

        final studio = tester.widget<ChapterStudioScreen>(
          find.byType(ChapterStudioScreen),
        );
        expect(studio.matchId, 'm1');
        expect(studio.partnerName, 'Maya');
      },
    );

    testWidgets('Plan a date on a match card proposes a plan '
        '[case:matching.matches_list.matches_person_x_plan_plan.action]', (
      tester,
    ) async {
      final api = _api();
      await _open(tester, api, view: MatchesView.people);
      await _tap(tester, const ValueKey('qa.matches.person.m1.plan'));
      await _tap(tester, const ValueKey('qa.plan.submit'));

      final plan = api.sent('POST', '/matches/m1/plans').single.body;
      expect(plan['venue_category'], isNotEmpty);
      expect(plan['window_start'], isNotEmpty);
    });
  });

  group('match options', () {
    testWidgets('Start call session opens the call for this match '
        '[case:matching.matches_list.matches_call_action.action]', (
      tester,
    ) async {
      final api = _api();
      await _openOptions(tester, api);
      await _tap(tester, const ValueKey('qa.matches.call_action'));

      final call = tester.widget<CallSessionScreen>(
        find.byType(CallSessionScreen),
      );
      expect(call.matchId, 'm1');
      expect(call.recipientUserId, 'maya');
      expect(api.sent('POST', '/calls/start').single.body, {
        'match_id': 'm1',
        'initiator_user_id': 'me',
        'recipient_user_id': 'maya',
      });
      expect(find.text('Session active'), findsOneWidget);
    });

    testWidgets('Start an activity opens the activity for this match '
        '[case:matching.matches_list.matches_activity_action.action] '
        '[case:matching.activity_session.openers_handle_result]', (
      tester,
    ) async {
      final api = _api();
      await _openOptions(tester, api);
      await _tap(tester, const ValueKey('qa.matches.activity_action'));

      final activity = tester.widget<ActivitySessionScreen>(
        find.byType(ActivitySessionScreen),
      );
      expect(activity.matchId, 'm1');
      expect(activity.otherUserId, 'maya');
      expect(
        api.sent('POST', '/activities/sessions/start').single.body['match_id'],
        'm1',
      );
      await tester.pumpWidget(const SizedBox()); // stop the countdown
    });

    testWidgets('Plan a date sends the plan and confirms it '
        '[case:matching.matches_list.matches_plan_action.action]', (
      tester,
    ) async {
      final api = _api();
      await _openOptions(tester, api);
      await _tap(tester, const ValueKey('qa.matches.plan_action'));
      await _tap(tester, const ValueKey('qa.plan.submit'));

      expect(api.sent('POST', '/matches/m1/plans'), hasLength(1));
      expect(qaSnackText(tester), 'Plan sent to Maya.');
    });

    testWidgets('We found each other asks to graduate and confirms it '
        '[case:matching.matches_list.matches_graduation_action.action]', (
      tester,
    ) async {
      final api = _api();
      await _openOptions(tester, api);
      await _tap(tester, const ValueKey('qa.matches.graduation_action'));
      await _tap(tester, const ValueKey('qa.graduation.submit'));

      expect(api.sent('POST', '/matches/m1/graduation').single.body, {
        'share_with_friends': false,
      });
      expect(
        qaSnackText(tester),
        'Asked Maya to leave together. They can confirm from your chat.',
      );
    });

    testWidgets('Add friend in the options sends a friend request '
        '[case:matching.matches_list.add_friend.action]', (tester) async {
      final api = _api();
      await _openOptions(tester, api);
      await _tap(tester, const ValueKey('qa.add_friend.maya'));

      expect(api.sent('POST', '/friends/me').single.body, {
        'friend_user_id': 'maya',
        'source': 'match',
      });
      expect(qaSnackText(tester), 'Friend request sent to Maya.');
    });

    testWidgets('Send a nudge sends it and confirms '
        '[case:matching.matches_list.matches_nudge_action.action] '
        '', (tester) async {
      final api = _api();
      await _openOptions(tester, api);
      await _tap(tester, const ValueKey('qa.matches.nudge_action'));

      final nudge = api.sent('POST', '/engagement/match-nudges/send').single;
      expect(nudge.body['match_id'], 'm1');
      expect(nudge.body.values, contains('maya'));
      expect(qaSnackText(tester), 'Nudge sent to Maya.');
      expect(
        find.byKey(const ValueKey('qa.matches.nudge_action')),
        findsNothing,
        reason: 'the sheet closed',
      );
    });

    testWidgets(
      'a refused nudge shows the reason '
      '[case:matching.matches_list.matches_nudge_action.api_failure] '
      '[case:matching.matches_list.matches_match_row_x_options.api_failure] '
      '[case:matching.matches_list.matches_person_x_options_options.api_failure]',
      (tester) async {
        final api = _api()
          ..fail(
            'POST /engagement/match-nudges/send',
            status: 429,
            message: 'You already nudged Maya today.',
          );
        await _openOptions(tester, api);
        await _tap(tester, const ValueKey('qa.matches.nudge_action'));

        expect(qaSnackText(tester), 'You already nudged Maya today.');
      },
    );

    testWidgets('Close conversation asks first; Keep talking keeps it '
        '[case:matching.matches_list.matches_unmatch_action_2.action] '
        '[case:matching.matches_list.matches_close_dialog_keep.action]', (
      tester,
    ) async {
      final api = _api();
      await _openOptions(tester, api);
      await _tap(tester, const ValueKey('qa.matches.unmatch_action'));
      expect(find.text('Close this conversation?'), findsOneWidget);

      await _tap(tester, const ValueKey('qa.matches.close_dialog.keep'));

      expect(find.text('Close this conversation?'), findsNothing);
      expect(api.sent('DELETE', '/matches/m1'), isEmpty);
      expect(_row('m1'), findsOneWidget);
    });

    testWidgets('Close conversation ends the match and removes the row '
        '[case:matching.matches_list.matches_unmatch_action.action] '
        '[case:matching.matches_list.matches_close_dialog_confirm.action]', (
      tester,
    ) async {
      final api = _api();
      await _openOptions(tester, api);
      await _tap(tester, const ValueKey('qa.matches.unmatch_action'));
      await _tap(tester, const ValueKey('qa.matches.close_dialog.confirm'));

      expect(api.sent('DELETE', '/matches/m1').single.query, {'user_id': 'me'});
      expect(_row('m1'), findsNothing);
      expect(_row('m2'), findsOneWidget);
    });

    // Regression (2026-10-02): a refused close failed silently; the row
    // stayed and nothing said why.
    testWidgets('a refused close keeps the row and says so '
        '[case:matching.matches_list.matches_unmatch_action.api_failure]', (
      tester,
    ) async {
      final api = _api()..fail('DELETE /matches/m1');
      await _openOptions(tester, api);
      await _tap(tester, const ValueKey('qa.matches.unmatch_action'));
      await _tap(tester, const ValueKey('qa.matches.close_dialog.confirm'));

      expect(api.sent('DELETE', '/matches/m1'), hasLength(1));
      expect(_row('m1'), findsOneWidget);
      expect(qaSnackText(tester), 'Failed to unmatch.');
    });

    testWidgets('Report sends the report; Appeal opens the appeal '
        '[case:matching.matches_list.matches_report_action.action] '
        '[case:matching.matches_list.submit_report_onsubmit.action] '
        '[case:matching.matches_list.appeal.action]', (tester) async {
      final api = _api();
      await _openOptions(tester, api);
      await _tap(tester, const ValueKey('qa.matches.report_action'));
      await tester.tap(find.text('Submit report'));
      await qaSettle(tester);

      expect(api.sent('POST', '/safety/report').single.body, {
        'reporter_user_id': 'me',
        'reported_user_id': 'maya',
        'reason': 'inappropriate',
        'description': '',
        'message_id': null,
      });
      expect(qaSnackText(tester), contains('Report submitted. Thank you.'));

      await tester.tap(find.text('Appeal'));
      await qaSettle(tester);
      final appeal = tester.widget<ModerationAppealsScreen>(
        find.byType(ModerationAppealsScreen),
      );
      expect(appeal.initialReportId, 'report-9');
    });

    testWidgets('a failed report says so and nothing is confirmed '
        '[case:matching.matches_list.matches_report_action.api_failure] '
        '[case:matching.matches_list.submit_report_onsubmit.api_failure]', (
      tester,
    ) async {
      final api = _api()..offline('POST /safety/report');
      await _openOptions(tester, api);
      await _tap(tester, const ValueKey('qa.matches.report_action'));
      await tester.tap(find.text('Submit report'));
      await qaSettle(tester);

      expect(api.sent('POST', '/safety/report'), hasLength(1));
      expect(qaSnackText(tester), 'Failed to submit report. Please try again.');
      expect(find.textContaining('Report submitted'), findsNothing);
    });
  });

  group('screen checks', () {
    Future<void> pumpMatches(
      WidgetTester tester,
      MatchesView view, {
      Size size = const Size(430, 932),
      ThemeData? theme,
      Locale? locale,
    }) async {
      const screen = MatchesListScreen();
      await pumpQa(
        tester,
        _api(),
        theme == null ? screen : qaThemed(theme, screen),
        size: size,
        locale: locale,
        flags: {
          'curated_daily_set_enabled': false,
          'intentional_dating_enabled': true,
        },
        extra: [
          ...qaDiscoverExtras(),
          matchesViewProvider.overrideWith((ref) => view),
        ],
      );
      qaDropImageErrors(tester);
    }

    Finder person(String id) => find.byKey(ValueKey('qa.matches.person.$id'));

    for (final view in [MatchesView.people, MatchesView.conversations]) {
      testWidgets('the ${view.name} view meets the tap-target, label and '
          'contrast guidelines [case:matching.matches_list.a11y_guidelines]', (
        tester,
      ) async {
        await pumpMatches(tester, view);
        expect(
          view == MatchesView.people ? person('m1') : _row('m1'),
          findsOneWidget,
        );
        await qaExpectA11y(tester);
      });

      testWidgets('the ${view.name} view lays out on phones and tablets in '
          'both themes [case:matching.matches_list.layout_matrix]', (
        tester,
      ) async {
        await qaExpectLayout(
          tester,
          pump: (size, theme) =>
              pumpMatches(tester, view, size: size, theme: theme),
          check: (where) {
            final first = view == MatchesView.people
                ? person('m1')
                : _row('m1');
            expect(first, findsOneWidget, reason: where);
          },
        );
      });
    }

    testWidgets('both views render translated in every language '
        '[case:matching.matches_list.l10n]', (tester) async {
      for (final view in [MatchesView.people, MatchesView.conversations]) {
        await qaExpectTranslated(
          tester,
          pump: (locale) => pumpMatches(tester, view, locale: locale),
          fixture: {'Maya', 'Arjun', 'See you Sunday?', 'Coffee?'},
          check: (l10n, where) {
            expect(
              find.text(
                view == MatchesView.people
                    ? l10n.matchesSubtitlePeople
                    : l10n.matchesSubtitleConversations,
              ),
              findsOneWidget,
              reason: '$where ${view.name}',
            );
            expect(
              find.text(l10n.matchesTabPeople),
              findsOneWidget,
              reason: '$where ${view.name}',
            );
            expect(
              find.text(l10n.matchesTabConversations),
              findsOneWidget,
              reason: '$where ${view.name}',
            );
          },
        );
      }
    });

    testWidgets('a match card renders translated in every language '
        '[case:matching.match_overview_card.l10n]', (tester) async {
      await qaExpectTranslated(
        tester,
        pump: (locale) =>
            pumpMatches(tester, MatchesView.people, locale: locale),
        fixture: {'Maya', 'Arjun', 'See you Sunday?', 'Coffee?'},
        check: (l10n, where) {
          final card = person('m1');
          expect(card, findsOneWidget, reason: where);
          Finder inCard(String text) =>
              find.descendant(of: card, matching: find.text(text));
          // Maya has 2 unread messages; Arjun none.
          expect(
            inCard(l10n.matchesChatUnread(2)),
            findsOneWidget,
            reason: where,
          );
          expect(
            find.descendant(
              of: person('m2'),
              matching: find.text(l10n.matchesOpenChat),
            ),
            findsOneWidget,
            reason: where,
          );
          expect(
            inCard(l10n.matchesActionPlanDate),
            findsOneWidget,
            reason: where,
          );
          expect(
            inCard(l10n.matchesFirstChapter),
            findsOneWidget,
            reason: where,
          );
          expect(
            find.descendant(
              of: card,
              matching: find.byTooltip(l10n.matchesOptionsTooltip('Maya')),
            ),
            findsOneWidget,
            reason: where,
          );
        },
      );
    });
  });
}
