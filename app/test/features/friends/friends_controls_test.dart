import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/friends/screens/friends_screen.dart';
import 'package:verified_dating_app/features/friends/screens/introducer_screen.dart';
import 'package:verified_dating_app/features/intentional_dating/dating_rhythm.dart';
import 'package:verified_dating_app/features/plans/screens/plans_screen.dart';
import 'package:verified_dating_app/features/social_chat/social_chat_screen.dart';

import '../../support/qa_api.dart';

// Friends screen controls: each test performs the real gesture and asserts
// the request the server receives, where the member lands and what they
// see — and, for every command, what happens when the server refuses or the
// device is offline.

Map<String, dynamic> _friend(
  String id,
  String name, {
  String status = 'accepted',
  String direction = '',
  String source = '',
}) => {
  'friend_user_id': id,
  'friend_name': name,
  'friend_username': id,
  'friend_city': 'Pune',
  'friend_photo_url': '',
  'status': status,
  'direction': direction,
  'source': source,
  'created_at': '2026-09-30T00:00:00Z',
  'updated_at': '2026-09-30T00:00:00Z',
};

Map<String, dynamic> _vouch(String id, String status) => {
  'id': id,
  'subject_user_id': 'me',
  'subject_name': 'Me',
  'voucher_user_id': 'meera',
  'voucher_name': 'Meera',
  'text': 'Warm, curious and always the first to show up.',
  'status': status,
  'created_at': '2026-09-27T00:00:00Z',
};

Map<String, dynamic> _intro(String id, String decision) => {
  'id': id,
  'introducer_user_id': 'meera',
  'introducer_name': 'Meera',
  'message': 'You two would get on.',
  'status': 'open',
  'my_decision': decision,
  'other': {
    'user_id': 'arjun',
    'name': 'Arjun',
    'age': 31,
    'city': 'Pune',
    'is_verified': true,
    'photo_urls': <String>[],
  },
  'expires_at': '2026-10-11T00:00:00Z',
  'created_at': '2026-09-27T00:00:00Z',
};

/// A stateful friends BFF: two friends, an incoming and an outgoing
/// request, a friend chat, an intro and a vouch waiting on me, an approved
/// vouch on my profile. Commands change the state like the server does.
class _World {
  _World() {
    api
      ..on('GET /friends/me', (_) => qaOk({'friends': rows.values.toList()}))
      ..on(
        'GET /friends/me/activities',
        (_) => qaOk({'activities': activities}),
      )
      ..on(
        'GET /friends/me/vouches',
        (_) =>
            qaOk({'about_me': vouches.values.toList(), 'written': <dynamic>[]}),
      )
      ..on(
        'GET /friends/me/intros',
        (_) => qaOk({'received': intros.values.toList(), 'made': <dynamic>[]}),
      )
      ..on('GET /social/channels', (_) => qaOk({'channels': channels}))
      ..on('POST /friends/me/*/decision', (c) {
        final id = c.path.split('/')[3];
        if (c.body['decision'] == 'accept') {
          rows[id] = _friend(id, rows[id]!['friend_name'] as String);
        } else {
          rows.remove(id);
        }
        return qaOk({'success': true});
      })
      ..on('DELETE /friends/me/*', (c) {
        rows.remove(c.path.split('/').last);
        return qaOk({'success': true});
      })
      ..on('POST /friends/me/intros/*/decision', (c) {
        final id = c.path.split('/')[4];
        intros[id] = _intro(
          id,
          c.body['decision'] == 'accept' ? 'accepted' : 'declined',
        );
        return qaOk({'success': true});
      })
      ..on('POST /friends/me/vouches/*/decision', (c) {
        final id = c.path.split('/')[4];
        vouches[id] = _vouch(
          id,
          c.body['decision'] == 'approve' ? 'approved' : 'hidden',
        );
        return qaOk({'success': true});
      })
      ..on(
        'POST /social/friends/*/channel',
        (c) => qaOk({
          'channel': {
            'id': 'ch-${c.path.split('/')[3]}',
            'kind': 'friend',
            'title': 'Meera',
            'peer_id': c.path.split('/')[3],
          },
        }),
      )
      ..on('POST /safety/block', (c) {
        rows.remove(c.body['blocked_user_id']);
        return qaOk({'success': true});
      });
  }

  final api = QaApi();
  final rows = <String, Map<String, dynamic>>{
    'meera': _friend('meera', 'Meera'),
    'dev': _friend('dev', 'Dev'),
    'ravi': _friend(
      'ravi',
      'Ravi',
      status: 'pending',
      direction: 'incoming',
      source: 'room',
    ),
    'tara': _friend(
      'tara',
      'Tara',
      status: 'pending',
      direction: 'outgoing',
      source: 'match',
    ),
  };
  final activities = <Map<String, dynamic>>[];
  final vouches = <String, Map<String, dynamic>>{
    'v-pending': _vouch('v-pending', 'pending'),
    'v-shown': _vouch('v-shown', 'approved'),
  };
  final intros = <String, Map<String, dynamic>>{
    'intro-1': _intro('intro-1', 'pending'),
  };
  final channels = <Map<String, dynamic>>[
    {
      'id': 'ch-meera',
      'kind': 'friend',
      'title': 'Meera',
      'peer_id': 'meera',
      'member_count': 2,
      'last_message': 'See you Sunday?',
      'unread_count': 2,
    },
  ];
}

Future<List<Object?>> _open(
  WidgetTester tester,
  _World world, {
  bool launcher = false,
  Locale? locale,
}) => pumpQa(
  tester,
  world.api,
  const FriendsScreen(),
  size: const Size(500, 3200),
  launcher: launcher,
  locale: locale,
);

Finder _key(String key) => find.byKey(ValueKey(key));

Future<void> _tap(WidgetTester tester, String key) async {
  await tester.ensureVisible(_key(key));
  await tester.pumpAndSettle();
  await tester.tap(_key(key));
  await tester.pumpAndSettle();
}

/// Disposes screens with chat polling/reconnect timers.
Future<void> _teardown(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 2));
}

Future<void> _pullToRefresh(WidgetTester tester) async {
  // The pull must pass a quarter of the (tall) viewport to arm.
  await tester.fling(find.text('Your people'), const Offset(0, 1400), 1500);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Back closes Friends and returns to the opener '
      '[case:friends.friends.back.action]', (tester) async {
    final world = _World();
    final results = await _open(tester, world, launcher: true);
    expect(find.byType(FriendsScreen), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(FriendsScreen), findsNothing);
    expect(results, [null]);
  });

  group('pull to refresh', () {
    testWidgets(
      'fetches friends, activity, vouches, intros and chats again and shows '
      'what changed [case:friends.friends.activity_onrefresh.action]',
      (tester) async {
        final world = _World();
        await _open(tester, world);
        int count(String path) => world.api.sent('GET', path).length;
        final paths = [
          '/friends/me',
          '/friends/me/activities',
          '/friends/me/vouches',
          '/friends/me/intros',
          '/social/channels',
        ];
        final before = {for (final p in paths) p: count(p)};

        world.rows['asha'] = _friend('asha', 'Asha');
        world.activities.add({
          'id': 'a-1',
          'type': 'friend_plan',
          'title': 'Asha planned a picnic',
          'description': 'Sunday at the lake',
          'created_at': '2026-10-01T00:00:00Z',
        });
        await _pullToRefresh(tester);

        for (final path in paths) {
          expect(count(path), before[path]! + 1, reason: path);
        }
        expect(world.api.sent('GET', '/friends/me/activities').last.query, {
          'limit': 30,
        });
        expect(find.text('3 friends'), findsOneWidget);
        expect(find.text('With your friends'), findsOneWidget);
        expect(find.text('Asha planned a picnic'), findsOneWidget);
        expect(world.api.writes, isEmpty);
      },
    );

    testWidgets('a failed refresh keeps the list and shows the server message '
        '[case:friends.friends.activity_onrefresh.api_failure]', (
      tester,
    ) async {
      final world = _World();
      await _open(tester, world);
      world.api.fail('GET /friends/me', message: 'Friends are napping.');
      await _pullToRefresh(tester);
      expect(find.text('Friends are napping.'), findsOneWidget);
      expect(find.text('Ravi'), findsOneWidget);

      world.api.offline('GET /friends/me');
      await _pullToRefresh(tester);
      expect(
        find.text(qaL10n(const Locale('en')).friendsLoadFailed),
        findsOneWidget,
      );
    });
  });

  group('requests', () {
    testWidgets(
      'a refused Accept explains, keeps the request and retry works once '
      '[case:friends.friends.friends_accept_x_accept.api_failure]',
      (tester) async {
        final world = _World();
        await _open(tester, world);
        world.api.fail(
          'POST /friends/me/*/decision',
          status: 409,
          message: 'Ravi withdrew the request.',
        );
        await _tap(tester, 'qa.friends.accept.ravi');
        expect(find.text('Ravi withdrew the request.'), findsOneWidget);
        expect(_key('qa.friends.request.ravi'), findsOneWidget);
        final accept = tester.widget<FilledButton>(
          _key('qa.friends.accept.ravi'),
        );
        expect(accept.onPressed, isNotNull, reason: 're-enabled');

        world.api.on('POST /friends/me/*/decision', (c) {
          world.rows['ravi'] = _friend('ravi', 'Ravi');
          return qaOk({'success': true});
        });
        await _tap(tester, 'qa.friends.accept.ravi');
        expect(world.api.sent('POST', '/friends/me/ravi/decision'), [
          isA<QaCall>().having((c) => c.body, 'body', {'decision': 'accept'}),
          isA<QaCall>().having((c) => c.body, 'body', {'decision': 'accept'}),
        ]);
        expect(_key('qa.friends.request.ravi'), findsNothing);
        expect(_key('qa.friends.friend.ravi'), findsOneWidget);
        expect(find.text('Ravi withdrew the request.'), findsNothing);
      },
    );

    testWidgets('a failed Decline (offline) explains and keeps the request '
        '[case:friends.friends.friends_decline_x_decline.api_failure]', (
      tester,
    ) async {
      final world = _World();
      await _open(tester, world);
      world.api.offline('POST /friends/me/*/decision');
      await _tap(tester, 'qa.friends.decline.ravi');
      expect(
        find.text(qaL10n(const Locale('en')).friendsRespondFailed),
        findsOneWidget,
      );
      expect(_key('qa.friends.request.ravi'), findsOneWidget);
      expect(world.api.sent('POST', '/friends/me/ravi/decision'), hasLength(1));
      expect(world.api.sent('POST', '/friends/me/ravi/decision').single.body, {
        'decision': 'decline',
      });
    });

    testWidgets('a failed Cancel keeps the outgoing request and explains '
        '[case:friends.friends.friends_cancel_x_cancel.api_failure]', (
      tester,
    ) async {
      final world = _World();
      await _open(tester, world);
      world.api.fail('DELETE /friends/me/*', message: 'Try again soon.');
      await _tap(tester, 'qa.friends.cancel.tara');
      expect(find.text('Try again soon.'), findsOneWidget);
      expect(_key('qa.friends.request.tara'), findsOneWidget);
      expect(world.api.writeLines, ['DELETE /friends/me/tara']);
      expect(
        tester.widget<OutlinedButton>(_key('qa.friends.cancel.tara')).onPressed,
        isNotNull,
      );
    });
  });

  group('friend chats', () {
    testWidgets(
      'tapping a friend conversation opens that chat and refreshes the list '
      'on return [case:friends.friends.friends_chat_x.action]',
      (tester) async {
        final world = _World();
        await _open(tester, world);
        expect(world.api.sent('GET', '/social/channels'), hasLength(1));
        await _tap(tester, 'qa.friends.chat.ch-meera');

        final chat = tester.widget<SocialChatScreen>(
          find.byType(SocialChatScreen),
        );
        expect(chat.channelId, 'ch-meera');
        expect(chat.title, 'Meera');
        expect(
          world.api.writes.where((c) => c.path.startsWith('/friends')),
          isEmpty,
        );

        world.channels.first['unread_count'] = 0;
        Navigator.of(tester.element(find.byType(SocialChatScreen))).pop();
        await tester.pumpAndSettle();
        expect(world.api.sent('GET', '/social/channels'), hasLength(2));
        expect(_key('qa.friends.unread.ch-meera'), findsNothing);
        await _teardown(tester);
      },
    );

    testWidgets(
      'Message on a friend row says why when the chat cannot open and stays '
      'on Friends [case:friends.friends.friends_message_x_message.api_failure]',
      (tester) async {
        final world = _World();
        world.api.fail(
          'POST /social/friends/*/channel',
          status: 403,
          message: 'You are no longer friends.',
        );
        await _open(tester, world);
        await _tap(tester, 'qa.friends.message.meera');
        expect(find.text('You are no longer friends.'), findsOneWidget);
        expect(find.byType(SocialChatScreen), findsNothing);
        expect(find.byType(FriendsScreen), findsOneWidget);
        expect(
          world.api.sent('POST', '/social/friends/meera/channel'),
          hasLength(1),
        );

        world.api.on(
          'POST /social/friends/*/channel',
          (_) => const QaReply(500, null),
        );
        // Let the first message time out so the next one shows.
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        await _tap(tester, 'qa.friends.message.meera');
        expect(
          find.text(qaL10n(const Locale('en')).friendsChatOpenFailed),
          findsOneWidget,
        );
      },
    );
  });

  group('intros and vouches waiting on me', () {
    testWidgets('No thanks declines the intro and removes the card '
        '[case:friends.friends.friends_intro_decline_x_decide.action]', (
      tester,
    ) async {
      final world = _World();
      await _open(tester, world);
      expect(find.text('Intros for you'), findsOneWidget);
      await _tap(tester, 'qa.friends.intro_decline.intro-1');

      expect(world.api.writeLines, [
        'POST /friends/me/intros/intro-1/decision',
      ]);
      expect(world.api.writes.single.body, {'decision': 'decline'});
      // Reloaded after the answer.
      expect(world.api.calls.last.path, '/friends/me/intros');
      expect(find.text('Intros for you'), findsNothing);
    });

    testWidgets('a failed No thanks keeps the intro and explains '
        '[case:friends.friends.friends_intro_decline_x_decide.api_failure]', (
      tester,
    ) async {
      final world = _World();
      await _open(tester, world);
      world.api.fail(
        'POST /friends/me/intros/*/decision',
        message: 'This intro expired.',
      );
      await _tap(tester, 'qa.friends.intro_decline.intro-1');
      expect(find.text('This intro expired.'), findsOneWidget);
      expect(_key('qa.friends.intro.intro-1'), findsOneWidget);
      expect(
        tester
            .widget<OutlinedButton>(_key('qa.friends.intro_decline.intro-1'))
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('Keep private hides a pending vouch from the profile '
        '[case:friends.friends.friends_vouch_hide_x_decide.action]', (
      tester,
    ) async {
      final world = _World();
      await _open(tester, world);
      expect(find.text('Vouches waiting for your approval'), findsOneWidget);
      await _tap(tester, 'qa.friends.vouch_hide.v-pending');

      expect(world.api.writeLines, [
        'POST /friends/me/vouches/v-pending/decision',
      ]);
      expect(world.api.writes.single.body, {'decision': 'hide'});
      expect(find.text('Vouches waiting for your approval'), findsNothing);
    });

    testWidgets('a failed Keep private keeps the vouch pending and explains '
        '[case:friends.friends.friends_vouch_hide_x_decide.api_failure]', (
      tester,
    ) async {
      final world = _World();
      await _open(tester, world);
      world.api.on(
        'POST /friends/me/vouches/*/decision',
        (_) => const QaReply(500, null),
      );
      await _tap(tester, 'qa.friends.vouch_hide.v-pending');
      expect(
        find.text(qaL10n(const Locale('en')).friendsVouchUpdateFailed),
        findsOneWidget,
      );
      expect(_key('qa.friends.vouch.v-pending'), findsOneWidget);
    });

    testWidgets('Hide from profile takes an approved vouch off my profile '
        '[case:friends.friends.hide_from_profile.action]', (tester) async {
      final world = _World()..vouches.remove('v-pending');
      await _open(tester, world);
      expect(find.text('Vouches on your profile'), findsOneWidget);
      await tester.ensureVisible(find.byTooltip('Hide from profile'));
      await tester.tap(find.byTooltip('Hide from profile'));
      await tester.pumpAndSettle();

      expect(world.api.writeLines, [
        'POST /friends/me/vouches/v-shown/decision',
      ]);
      expect(world.api.writes.single.body, {'decision': 'hide'});
      expect(find.text('Vouches on your profile'), findsNothing);
    });

    testWidgets('a failed Hide from profile keeps the vouch shown and explains '
        '[case:friends.friends.hide_from_profile.api_failure]', (tester) async {
      final world = _World()..vouches.remove('v-pending');
      await _open(tester, world);
      world.api.fail(
        'POST /friends/me/vouches/*/decision',
        message: 'Could not update that vouch.',
      );
      await tester.ensureVisible(find.byTooltip('Hide from profile'));
      await tester.tap(find.byTooltip('Hide from profile'));
      await tester.pumpAndSettle();
      expect(find.text('Could not update that vouch.'), findsOneWidget);
      expect(find.text('Vouches on your profile'), findsOneWidget);
    });
  });

  group('friend menu', () {
    Future<void> openMenu(WidgetTester tester, String id) async {
      await _tap(tester, 'qa.friends.menu.$id');
    }

    testWidgets(
      'Remove friend asks first, then deletes the friendship and the row '
      '[case:friends.friends.friends_menu_x_action.action]',
      (tester) async {
        final world = _World();
        await _open(tester, world);
        await openMenu(tester, 'dev');
        expect(find.text('Vouch for them'), findsOneWidget);
        expect(find.text('Introduce to a friend'), findsOneWidget);
        expect(find.text('Block'), findsOneWidget);

        await tester.tap(find.text('Remove friend'));
        await tester.pumpAndSettle();
        expect(find.text('Remove Dev?'), findsOneWidget);
        // Cancel keeps the friend and sends nothing.
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Cancel'),
          ),
        );
        await tester.pumpAndSettle();
        expect(world.api.writes, isEmpty);

        await openMenu(tester, 'dev');
        await tester.tap(find.text('Remove friend'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Remove friend'),
          ),
        );
        await tester.pumpAndSettle();
        expect(world.api.writeLines, ['DELETE /friends/me/dev']);
        expect(_key('qa.friends.friend.dev'), findsNothing);
        expect(find.text('1 friend'), findsOneWidget);
      },
    );

    testWidgets('Block asks first, blocks on the server and drops the friend '
        '[case:friends.friends.friends_menu_x_action.block]', (tester) async {
      final world = _World();
      await _open(tester, world);
      await openMenu(tester, 'dev');
      await tester.tap(find.text('Block'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(FilledButton),
        ),
      );
      await tester.pumpAndSettle();
      expect(world.api.writeLines, ['POST /safety/block']);
      expect(world.api.writes.single.body, {
        'user_id': 'me',
        'blocked_user_id': 'dev',
      });
      expect(_key('qa.friends.friend.dev'), findsNothing);
    });

    testWidgets(
      'Vouch and Introduce from the menu open their sheets for that friend '
      '[case:friends.friends.friends_menu_x_action.sheets]',
      (tester) async {
        final world = _World();
        await _open(tester, world);
        await openMenu(tester, 'dev');
        await tester.tap(find.text('Vouch for them'));
        await tester.pumpAndSettle();
        expect(find.text('Vouch for Dev'), findsOneWidget);
        Navigator.of(tester.element(find.text('Vouch for Dev'))).pop();
        await tester.pumpAndSettle();

        await openMenu(tester, 'dev');
        await tester.tap(find.text('Introduce to a friend'));
        await tester.pumpAndSettle();
        expect(find.text('Introduce two friends'), findsOneWidget);
        final first = tester.widget<ChoiceChip>(
          _key('qa.friends.intro_first.dev'),
        );
        expect(first.selected, isTrue, reason: 'preselected');
        expect(world.api.writes, isEmpty);
      },
    );

    testWidgets(
      'a failed Remove keeps the friend and explains; a failed Block says so '
      '[case:friends.friends.friends_menu_x_action.api_failure]',
      (tester) async {
        final world = _World();
        await _open(tester, world);
        world.api.fail('DELETE /friends/me/*', message: 'Remove failed here.');
        await openMenu(tester, 'dev');
        await tester.tap(find.text('Remove friend'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Remove friend'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Remove failed here.'), findsOneWidget);
        expect(_key('qa.friends.friend.dev'), findsOneWidget);

        world.api.fail('POST /safety/block');
        await openMenu(tester, 'dev');
        await tester.tap(find.text('Block'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(FilledButton),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(qaL10n(const Locale('en')).communityBlockFailed),
          findsOneWidget,
        );
        expect(_key('qa.friends.friend.dev'), findsOneWidget);
      },
    );
  });

  group('more links', () {
    testWidgets('Date plans shared with you opens Plans on the friends tab '
        '[case:friends.friends.friends_plans_link.action]', (tester) async {
      final world = _World();
      await _open(tester, world);
      await _tap(tester, 'qa.friends.plans_link');
      final plans = tester.widget<PlansScreen>(find.byType(PlansScreen));
      expect(plans.initialTab, 1);
    });

    testWidgets(
      'Invite a friend who isn’t dating opens the introducer controls '
      '[case:friends.friends.invite_a_friend_who_isn_t_dating.action]',
      (tester) async {
        final world = _World();
        await _open(tester, world);
        await tester.ensureVisible(
          find.text('Invite a friend who isn’t dating'),
        );
        await tester.tap(find.text('Invite a friend who isn’t dating'));
        await tester.pumpAndSettle();
        final screen = tester.widget<IntroducerScreen>(
          find.byType(IntroducerScreen),
        );
        expect(screen.memberControls, isTrue);
      },
    );

    testWidgets('Introductions, on your terms opens the dating rhythm settings '
        '[case:friends.friends.introductions_on_your_terms.action]', (
      tester,
    ) async {
      final world = _World();
      await _open(tester, world);
      await tester.ensureVisible(find.text('Introductions, on your terms'));
      await tester.tap(find.text('Introductions, on your terms'));
      await tester.pumpAndSettle();
      expect(find.byType(DatingRhythmScreen), findsOneWidget);
    });

    testWidgets('with intros switched off the intro surfaces are hidden '
        '[case:friends.friends.intros_flag_off.gated]', (tester) async {
      final world = _World();
      await pumpQa(
        tester,
        world.api,
        const FriendsScreen(),
        size: const Size(500, 3200),
        flags: const {'friend_intros_enabled': false},
      );
      expect(find.text('Intros for you'), findsNothing);
      expect(find.text('Vouches waiting for your approval'), findsNothing);
      expect(_key('qa.friends.intro_action'), findsNothing);
      expect(find.text('Invite a friend who isn’t dating'), findsNothing);
      expect(_key('qa.friends.plans_link'), findsOneWidget);
    });
  });

  group('Add friend search', () {
    testWidgets('the Add friend sheet opens with its search and caption '
        '[case:friends.friends.showmodalbottomsheet_open.action]', (
      tester,
    ) async {
      final world = _World()
        ..api.json('GET /friends/me/search-visibility', {'visible': true});
      await _open(tester, world);
      await _tap(tester, 'qa.friends.add');
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(_key('qa.friends.search_field'), findsOneWidget);
      expect(find.text('Type at least 3 letters'), findsOneWidget);
      expect(_key('qa.friends.search_hidden_note'), findsNothing);
    });

    testWidgets('submitting from the keyboard searches at once (no debounce) '
        '[case:friends.friends.friends_search_field_submitted.action]', (
      tester,
    ) async {
      final world = _World()
        ..api.json('GET /friends/me/search', {
          'results': [
            {
              'user_id': 'asha',
              'name': 'Asha',
              'username': 'asha.k',
              'city': 'Goa',
              'photo_url': '',
              'relationship': 'none',
            },
          ],
        });
      await _open(tester, world);
      await _tap(tester, 'qa.friends.add');
      await tester.enterText(_key('qa.friends.search_field'), '  asha  ');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      // Well before the 300 ms typing debounce would fire.
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      expect(world.api.sent('GET', '/friends/me/search').single.query, {
        'q': 'asha',
      });
      await tester.pumpAndSettle();
      expect(find.text('Asha'), findsOneWidget);
      expect(find.text('@asha.k · Goa'), findsOneWidget);
    });

    testWidgets(
      'short, blank and @-only queries never reach the server; unicode is '
      'sent as typed; an empty answer says so '
      '[case:friends.friends.friends_search_field_submitted.validation]',
      (tester) async {
        final world = _World()
          ..api.json('GET /friends/me/search', {'results': <dynamic>[]});
        await _open(tester, world);
        await _tap(tester, 'qa.friends.add');
        final field = _key('qa.friends.search_field');
        for (final text in ['as', '   ', '@ab', '😊']) {
          await tester.enterText(field, text);
          await tester.testTextInput.receiveAction(TextInputAction.search);
          await tester.pump(const Duration(milliseconds: 400));
        }
        expect(world.api.sent('GET', '/friends/me/search'), isEmpty);

        await tester.enterText(field, 'Zoë 😊');
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.pumpAndSettle();
        expect(world.api.sent('GET', '/friends/me/search').single.query, {
          'q': 'Zoë 😊',
        });
        expect(
          find.text(
            qaL10n(const Locale('en')).friendsSearchNoResults('Zoë 😊'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('a failed search says so in the sheet '
        '[case:friends.friends.friends_search_field_submitted.api_failure]', (
      tester,
    ) async {
      final world = _World()..api.offline('GET /friends/me/search');
      await _open(tester, world);
      await _tap(tester, 'qa.friends.add');
      await tester.enterText(_key('qa.friends.search_field'), 'asha');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(
        find.text(qaL10n(const Locale('en')).friendsSearchFailed),
        findsOneWidget,
      );
    });
  });

  testWidgets(
    'Friends renders translated in every locale [case:friends.friends.l10n]',
    (tester) async {
      for (final locale in qaLocales) {
        final world = _World();
        await _open(tester, world, locale: locale);
        final l10n = qaL10n(locale);
        expect(tester.takeException(), isNull, reason: '$locale');
        expect(find.text(l10n.friendsTitle), findsOneWidget, reason: '$locale');
        expect(find.text(l10n.friendsAddFriend), findsOneWidget);
        expect(find.text(l10n.friendsCountTitle(2)), findsOneWidget);
        expect(find.text(l10n.friendsAccept), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
      }
    },
  );
}
