import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/engagement/screens/room_chat.dart';
import 'package:verified_dating_app/features/social_chat/social_chat_screen.dart';

import '../../support/qa_api.dart';
import 'rooms_qa_fixture.dart';

// A room's chat: the presence band and heartbeat, sending, the People and
// Room options buttons (People here, Moderate, Leave, Close), the member
// list and a member's card (Add friend, Report, Block, and for hosts Warn,
// Mute for how long, Unmute and Remove). Each test performs the gesture and
// asserts the request the server got, what closed or opened, and what the
// member sees; every API call also has its failure path.

final en = qaL10n(const Locale('en'));

const _people = ValueKey('room.chat.people');
const _menu = ValueKey('room.chat.menu');
const _asha = ValueKey('room.member.asha');
const _report = ValueKey('room.member.report');
const _block = ValueKey('room.member.block');
const _warn = ValueKey('room.member.warn');
const _mute = ValueKey('room.member.mute');
const _unmute = ValueKey('room.member.unmute');
const _remove = ValueKey('room.member.remove');

/// A host's view of an always-on topic room.
RoomsServer _hostServer({String? ashaMutedUntil}) =>
    RoomsServer(myRole: 'host', ashaMutedUntil: ashaMutedUntil);

/// A host's view of a room they started (it ends; it can be closed).
RoomsServer _hostedRoomServer() => RoomsServer(
  myRole: 'host',
  joinedExtra: const {
    'is_host': true,
    'always_on': false,
    'room_type': 'member',
    'host_name': 'Me',
  },
);

Finder get _chat => find.byType(SocialChatScreen);
Finder get _dialog => find.byType(AlertDialog);
Finder _inDialog(String text) =>
    find.descendant(of: _dialog, matching: find.text(text));

List<QaCall> _moderations(RoomsServer s) => s.sent('POST', '/rooms/*/moderate');
int _memberLoads(RoomsServer s) => s.sent('GET', '/rooms/r1/members').length;

/// Opens the Rooms list and joins Late-night talks (its chat opens).
Future<void> _enterChat(
  WidgetTester tester,
  RoomsServer s, {
  Locale? locale,
}) async {
  await openRooms(tester, s, locale: locale);
  await tapRoom(tester, 'r1');
  expect(_chat, findsOneWidget);
}

Future<void> _openMenuItem(WidgetTester tester, String item) async {
  await tester.tap(find.byKey(_menu));
  await tester.pumpAndSettle();
  await tester.tap(find.text(item).last);
  await tester.pumpAndSettle();
}

/// Opens Asha's card from the People list (or, for hosts, Moderate).
Future<void> _openAshaCard(WidgetTester tester, {bool moderate = false}) async {
  if (moderate) {
    await _openMenuItem(tester, en.roomsMenuModerate);
  } else {
    await tester.tap(find.byKey(_people));
    await tester.pumpAndSettle();
  }
  await tester.tap(find.byKey(_asha));
  await tester.pumpAndSettle();
  expect(find.byKey(_report), findsOneWidget, reason: 'the card is open');
}

/// Dismisses the top sheet by tapping its barrier.
Future<void> _dismissSheet(WidgetTester tester) async {
  await tester.tapAt(const Offset(215, 20));
  await tester.pumpAndSettle();
}

/// Lets the visible SnackBar time out, so the next one can show.
Future<void> _snackGone(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
  expect(find.byType(SnackBar), findsNothing);
}

/// The words of a one-placeholder message before its placeholder.
String _before(String Function(String) message) =>
    message('§').split('§').first;

bool _enabled(WidgetTester tester, ValueKey<String> key) =>
    tester.widget<ButtonStyleButton>(find.byKey(key)).onPressed != null;

void main() {
  group('chat', () {
    testWidgets("Tapping a sender's name opens their card with Add friend, "
        'Report and Block (no moderation for a participant) '
        '[case:engagement.room_chat.social_message_x_sendertap.action] '
        '[case:engagement.room_chat.showmodalbottomsheet_open_2.action]', (
      tester,
    ) async {
      final s = RoomsServer();
      await _enterChat(tester, s);
      expect(find.text('Anyone else up?'), findsOneWidget);

      await tester.tap(find.text('Asha'));
      await tester.pumpAndSettle();
      final card = find.byType(BottomSheet);
      expect(card, findsOneWidget);
      expect(
        find.descendant(of: card, matching: find.text('Asha')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.text(en.roomsStatusHereNow)),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('qa.add_friend.asha')), findsOneWidget);
      expect(find.byKey(_report), findsOneWidget);
      expect(find.byKey(_block), findsOneWidget);
      expect(find.byKey(_warn), findsNothing);
      expect(find.byKey(_remove), findsNothing);
      expect(s.sent('GET', '/rooms/r1/members'), hasLength(1));
      expect(s.sent('POST', '/rooms/*/moderate'), isEmpty);
      await unmountRooms(tester);
    });

    testWidgets('The presence band shows who is here; the heartbeat updates '
        'it every 45 s and says away on leaving the chat '
        '[case:engagement.room_chat.presence_heartbeat.action]', (
      tester,
    ) async {
      final s = RoomsServer();
      await _enterChat(tester, s);
      List<Object?> beats() => [
        for (final c in s.sent('POST', '/rooms/r1/presence')) c.body['state'],
      ];
      expect(beats(), ['here']);
      expect(
        find.text('${en.roomsHereNow(3)} · ${en.roomsInTheRoom(5)}'),
        findsOneWidget,
      );

      s.hereNow = 7;
      await tester.pump(roomHeartbeatInterval);
      await tester.pumpAndSettle();
      expect(beats(), ['here', 'here']);
      expect(
        find.text('${en.roomsHereNow(7)} · ${en.roomsInTheRoom(5)}'),
        findsOneWidget,
      );

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(beats(), ['here', 'here', 'away']);
      await tester.pump(roomHeartbeatInterval * 2);
      expect(beats(), hasLength(3), reason: 'no heartbeat after leaving');
      await unmountRooms(tester);
    });

    testWidgets('A heartbeat that says the member was removed closes the chat '
        'with the reason; a failed heartbeat keeps the chat '
        '[case:engagement.room_chat.presence_heartbeat.api_failure]', (
      tester,
    ) async {
      final s = RoomsServer();
      await _enterChat(tester, s);

      s.api.fail('POST /rooms/*/presence');
      await tester.pump(roomHeartbeatInterval);
      await tester.pumpAndSettle();
      expect(_chat, findsOneWidget);
      expect(qaSnackText(tester), isNull);
      expect(
        find.text('${en.roomsHereNow(3)} · ${en.roomsInTheRoom(5)}'),
        findsOneWidget,
      );

      final loads = s.sent('GET', '/rooms').length;
      s.api.fail(
        'POST /rooms/*/presence',
        status: 403,
        message: 'You were removed from this room.',
        code: 'ROOM_BLOCKED_ACTIVE_SESSION',
      );
      await tester.pump(roomHeartbeatInterval);
      await tester.pumpAndSettle();
      expect(_chat, findsNothing);
      expect(qaSnackText(tester), 'You were removed from this room.');
      expect(s.sent('GET', '/rooms').length, greaterThan(loads));

      final beats = s.sent('POST', '/rooms/r1/presence');
      expect(beats.where((c) => c.body['state'] == 'away'), isEmpty);
      await tester.pump(roomHeartbeatInterval * 2);
      expect(s.sent('POST', '/rooms/r1/presence'), hasLength(beats.length));
      await unmountRooms(tester);
    });

    testWidgets('Send posts the message to the room channel and shows it '
        '[case:engagement.room_chat.send.action]', (tester) async {
      final s = RoomsServer();
      await _enterChat(tester, s);
      const text = 'Hello night owls 🌙 مرحبا';
      await tester.enterText(
        find.byKey(const ValueKey('social.chat.input')),
        text,
      );
      await tester.tap(find.byKey(const ValueKey('social.chat.send')));
      await tester.pumpAndSettle();

      final post = s.sent('POST', '/social/channels/chan-r1/messages').single;
      expect(post.body['body'], text);
      expect(post.body['client_message_id'], isA<String>());
      expect(post.body['client_message_id'], isNotEmpty);
      expect(find.text(text), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('social.chat.input')))
            .controller!
            .text,
        isEmpty,
      );
      await unmountRooms(tester);
    });

    testWidgets('A send that fails says why and marks the message not sent '
        '[case:engagement.room_chat.send.api_failure]', (tester) async {
      final s = RoomsServer();
      await _enterChat(tester, s);
      s.api.fail('POST /social/channels/*/messages', message: 'Chat is down.');
      await tester.enterText(
        find.byKey(const ValueKey('social.chat.input')),
        'Still up?',
      );
      await tester.tap(find.byKey(const ValueKey('social.chat.send')));
      await tester.pumpAndSettle();

      expect(s.sent('POST', '/social/channels/chan-r1/messages'), hasLength(1));
      expect(qaSnackText(tester), 'Chat is down.');
      expect(find.text('Still up?'), findsOneWidget);
      expect(find.text(en.chatStatusNotSent), findsOneWidget);
      await unmountRooms(tester);
    });

    testWidgets('A member muted in the room reads along: the composer is '
        'closed and says until when '
        '[case:engagement.room_chat.muted_composer.action]', (tester) async {
      final s = RoomsServer()
        ..readOnlyUntil = DateTime.now()
            .add(const Duration(minutes: 30))
            .toUtc()
            .toIso8601String();
      await _enterChat(tester, s);
      expect(
        find.byKey(const ValueKey('social.chat.read_only')),
        findsOneWidget,
      );
      expect(
        find.textContaining(_before(en.chatRoomMutedUntil)),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('social.chat.input')))
            .enabled,
        isFalse,
      );
      expect(
        tester
            .widget<IconButton>(find.byKey(const ValueKey('social.chat.send')))
            .onPressed,
        isNull,
      );
      expect(find.text('Anyone else up?'), findsOneWidget);
      await unmountRooms(tester);
    });
  });

  group('people', () {
    testWidgets('People lists who is here: hosts first, roles, here now, you '
        '[case:engagement.room_chat.room_chat_people.action] '
        '[case:engagement.room_chat.showmodalbottomsheet_open.action]', (
      tester,
    ) async {
      final s = RoomsServer();
      await _enterChat(tester, s);
      await tester.tap(find.byKey(_people));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text(en.roomsMenuPeople), findsOneWidget);
      expect(find.text(en.roomsPeopleIntro), findsOneWidget);
      expect(s.sent('GET', '/rooms/r1/members'), hasLength(1));
      final rows = tester
          .widgetList<ListTile>(
            find.descendant(
              of: find.byKey(const ValueKey('room.members.list')),
              matching: find.byType(ListTile),
            ),
          )
          .map((t) => t.key)
          .toList();
      expect(rows, const [
        ValueKey('room.member.ravi'),
        ValueKey('room.member.asha'),
        ValueKey('room.member.me'),
      ]);
      expect(find.text('Host · ${en.roomsStatusHereNow}'), findsOneWidget);
      expect(find.text(en.roomsYouSuffix('Me')), findsOneWidget);
      expect(find.byKey(const ValueKey('qa.add_friend.asha')), findsOneWidget);
      expect(find.byKey(const ValueKey('qa.add_friend.me')), findsNothing);
      await unmountRooms(tester);
    });

    testWidgets('Tapping someone in the list opens their card; your own row '
        'opens nothing [case:engagement.room_chat.room_member_x.action]', (
      tester,
    ) async {
      final s = RoomsServer();
      await _enterChat(tester, s);
      await tester.tap(find.byKey(_people));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('room.member.me')));
      await tester.pumpAndSettle();
      expect(find.byKey(_report), findsNothing);
      expect(find.byType(BottomSheet), findsOneWidget);

      await tester.tap(find.byKey(_asha));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNWidgets(2));
      expect(find.byKey(_report), findsOneWidget);
      expect(find.byKey(_block), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(BottomSheet).last,
          matching: find.text('Asha'),
        ),
        findsOneWidget,
      );
      await unmountRooms(tester);
    });

    testWidgets('regression: who is here that fails to load shows the '
        "server's reason; Try again reloads the list "
        '[case:engagement.room_chat.try_again.action]', (tester) async {
      final s = RoomsServer();
      s.api.fail('GET /rooms/*/members', message: 'The list is resting.');
      await _enterChat(tester, s);
      await tester.tap(find.byKey(_people));
      await tester.pumpAndSettle();
      expect(find.text('The list is resting.'), findsOneWidget);
      expect(find.byKey(_asha), findsNothing);

      s.api.offline('GET /rooms/*/members');
      // The list refetches on the next frames while the error stays up, so
      // pump frames rather than settle.
      await tester.tap(find.byKey(const ValueKey('qa.room.members.retry')));
      await qaSettle(tester);
      expect(find.text(en.networkCannotReachService), findsOneWidget);
      expect(_memberLoads(s), 2);

      s.api.on('GET /rooms/*/members', (_) => qaOk({'members': s.members}));
      await tester.tap(find.byKey(const ValueKey('qa.room.members.retry')));
      await qaSettle(tester);
      expect(_memberLoads(s), 3);
      expect(find.byKey(_asha), findsOneWidget);
      expect(find.byKey(const ValueKey('qa.room.members.retry')), findsNothing);
      await unmountRooms(tester);
    });

    testWidgets('Add friend in the list sends a request that started in a '
        'room and the button turns to Requested '
        '[case:engagement.room_chat.add_friend.action]', (tester) async {
      final s = RoomsServer();
      await _enterChat(tester, s);
      await tester.tap(find.byKey(_people));
      await tester.pumpAndSettle();
      const add = ValueKey('qa.add_friend.asha');
      expect(
        tester.widget<IconButton>(find.byKey(add)).tooltip,
        en.friendsAddFriend,
      );

      await tester.tap(find.byKey(add));
      await tester.pumpAndSettle();
      expect(s.sent('POST', '/friends/me').single.body, {
        'friend_user_id': 'asha',
        'source': 'room',
      });
      expect(qaSnackText(tester), en.friendsRequestSentTo('Asha'));
      expect(
        tester.widget<IconButton>(find.byKey(add)).tooltip,
        en.friendsRequested,
      );
      await unmountRooms(tester);
    });

    testWidgets('Add friend that fails says why and stays available '
        '[case:engagement.room_chat.add_friend.api_failure]', (tester) async {
      final s = RoomsServer();
      s.api.fail('POST /friends/me', message: 'Friend requests are paused.');
      await _enterChat(tester, s);
      await tester.tap(find.byKey(_people));
      await tester.pumpAndSettle();
      const add = ValueKey('qa.add_friend.asha');
      await tester.tap(find.byKey(add));
      await tester.pumpAndSettle();

      expect(s.sent('POST', '/friends/me'), hasLength(1));
      expect(qaSnackText(tester), 'Friend requests are paused.');
      final button = tester.widget<IconButton>(find.byKey(add));
      expect(button.tooltip, en.friendsAddFriend);
      expect(button.onPressed, isNotNull);
      await unmountRooms(tester);
    });
  });

  group('room options', () {
    testWidgets('A participant: People here opens the list; Leave asks '
        'first (Cancel keeps you in), then leaves, closes the chat and the '
        'list shows the room to join again '
        '[case:engagement.room_chat.room_chat_menu.action]', (tester) async {
      final s = RoomsServer();
      await _enterChat(tester, s);
      await tester.tap(find.byKey(_menu));
      await tester.pumpAndSettle();
      expect(find.text(en.roomsMenuPeople), findsOneWidget);
      expect(find.text(en.roomsLeaveAction), findsOneWidget);
      expect(find.text(en.roomsMenuModerate), findsNothing);
      expect(find.text(en.roomsCloseAction), findsNothing);
      await tester.tap(find.text(en.roomsMenuPeople));
      await tester.pumpAndSettle();
      expect(find.text(en.roomsPeopleIntro), findsOneWidget);
      expect(find.byKey(_asha), findsOneWidget);
      await _dismissSheet(tester);

      await _openMenuItem(tester, en.roomsLeaveAction);
      expect(_inDialog(en.roomsLeaveTitle('Late-night talks')), findsOneWidget);
      expect(_inDialog(en.roomsLeaveBody), findsOneWidget);
      await tester.tap(_inDialog(en.commonCancel));
      await tester.pumpAndSettle();
      expect(s.sent('POST', '/rooms/*/leave'), isEmpty);
      expect(_chat, findsOneWidget);

      final loads = s.sent('GET', '/rooms').length;
      await _openMenuItem(tester, en.roomsLeaveAction);
      await tester.tap(_inDialog(en.roomsLeaveAction));
      await tester.pumpAndSettle();
      final leave = s.sent('POST', '/rooms/*/leave').single;
      expect(leave.path, '/rooms/r1/leave');
      expect(leave.data, isNull);
      expect(_chat, findsNothing);
      expect(s.sent('GET', '/rooms').length, loads + 1);
      expect(s.sent('POST', '/rooms/r1/presence').last.body, {'state': 'away'});
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('rooms.tile.r1')).first,
          matching: find.text(en.roomsActionJoin),
        ),
        findsOneWidget,
      );
      await unmountRooms(tester);
    });

    testWidgets('A host of their own room: Moderate opens the moderation '
        'list; Close room asks, closes the room and the chat '
        '[case:engagement.room_chat.room_chat_menu.action]', (tester) async {
      final s = _hostedRoomServer();
      await _enterChat(tester, s);
      await tester.tap(find.byKey(_menu));
      await tester.pumpAndSettle();
      for (final item in [
        en.roomsMenuPeople,
        en.roomsMenuModerate,
        en.roomsLeaveAction,
        en.roomsCloseAction,
      ]) {
        expect(find.text(item), findsOneWidget, reason: item);
      }
      await tester.tap(find.text(en.roomsMenuModerate));
      await tester.pumpAndSettle();
      expect(
        find.text(en.roomsModerateTitle('Late-night talks')),
        findsOneWidget,
      );
      expect(find.text(en.roomsModerateIntro), findsOneWidget);
      await _dismissSheet(tester);

      await _openMenuItem(tester, en.roomsCloseAction);
      expect(_inDialog(en.roomsCloseTitle('Late-night talks')), findsOneWidget);
      expect(_inDialog(en.roomsCloseBody), findsOneWidget);
      await tester.tap(_inDialog(en.commonCancel));
      await tester.pumpAndSettle();
      expect(_moderations(s), isEmpty);

      final loads = s.sent('GET', '/rooms').length;
      await _openMenuItem(tester, en.roomsCloseAction);
      await tester.tap(_inDialog(en.roomsCloseAction));
      await tester.pumpAndSettle();
      expect(_moderations(s).single.path, '/rooms/r1/moderate');
      expect(_moderations(s).single.body, {'action': 'close_room'});
      expect(_chat, findsNothing);
      expect(s.sent('GET', '/rooms').length, greaterThan(loads));
      await unmountRooms(tester);
    });

    testWidgets("regression: Leave that fails shows the server's reason, "
        'keeps the chat open, sends once per tap, and the retry leaves '
        '[case:engagement.room_chat.room_chat_menu.api_failure]', (
      tester,
    ) async {
      final s = RoomsServer();
      s.api.fail(
        'POST /rooms/*/leave',
        status: 409,
        message: 'Hand the room to someone before you leave.',
      );
      await _enterChat(tester, s);
      await _openMenuItem(tester, en.roomsLeaveAction);
      await tester.tap(_inDialog(en.roomsLeaveAction));
      await tester.pumpAndSettle();
      expect(qaSnackText(tester), 'Hand the room to someone before you leave.');
      expect(_chat, findsOneWidget);
      expect(s.sent('POST', '/rooms/*/leave'), hasLength(1));
      await _snackGone(tester);

      s.api.on('POST /rooms/*/leave', (_) => const QaReply(500, null));
      await _openMenuItem(tester, en.roomsLeaveAction);
      await tester.tap(_inDialog(en.roomsLeaveAction));
      await tester.pumpAndSettle();
      expect(qaSnackText(tester), en.engagementRoomsLeaveFailed);
      expect(_chat, findsOneWidget);
      await _snackGone(tester);

      s.api.json('POST /rooms/*/leave', {
        'room': roomJson('r1', 'Late-night talks', here: 2, members: 4),
      });
      await _openMenuItem(tester, en.roomsLeaveAction);
      await tester.tap(_inDialog(en.roomsLeaveAction));
      await tester.pumpAndSettle();
      expect(s.sent('POST', '/rooms/*/leave'), hasLength(3));
      expect(_chat, findsNothing);
      await unmountRooms(tester);
    });

    testWidgets("regression: Close room that fails shows the server's "
        'reason and keeps the chat open '
        '[case:engagement.room_chat.room_chat_menu.api_failure]', (
      tester,
    ) async {
      final s = _hostedRoomServer();
      s.api.fail(
        'POST /rooms/*/moderate',
        status: 403,
        message: 'Only the host can close this room.',
      );
      await _enterChat(tester, s);
      await _openMenuItem(tester, en.roomsCloseAction);
      await tester.tap(_inDialog(en.roomsCloseAction));
      await tester.pumpAndSettle();
      expect(qaSnackText(tester), 'Only the host can close this room.');
      expect(_chat, findsOneWidget);
      expect(_moderations(s), hasLength(1));
      await unmountRooms(tester);
    });
  });

  group('member card', () {
    testWidgets('Report opens the report form; Submit report sends the '
        'reason and where it happened, closes the form and confirms '
        '(regression: it used to close silently) '
        '[case:engagement.room_chat.room_member_report.action] '
        '[case:engagement.room_chat.submit_report_onsubmit.action]', (
      tester,
    ) async {
      final s = RoomsServer();
      await _enterChat(tester, s);
      await _openAshaCard(tester);
      await tester.tap(find.byKey(_report));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(BottomSheet).last,
          matching: find.text(en.reportSheetTitle),
        ),
        findsOneWidget,
      );
      expect(find.text(en.reportSubmit), findsOneWidget);

      await tester.tap(find.text(en.reportReasonInappropriate));
      await tester.pumpAndSettle();
      await tester.tap(find.text(en.reportReasonHarassment).last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(BottomSheet).last,
          matching: find.byType(TextField),
        ),
        '  Spamming links 🔗  ',
      );
      await tester.tap(find.text(en.reportSubmit));
      await tester.pumpAndSettle();

      expect(s.sent('POST', '/safety/report').single.body, {
        'reporter_user_id': 'me',
        'reported_user_id': 'asha',
        'reason': 'harassment',
        'description':
            'Reported from the room "Late-night talks". '
            'Spamming links 🔗',
        'message_id': null,
      });
      expect(find.text(en.reportSubmit), findsNothing, reason: 'form closed');
      expect(qaSnackText(tester), en.communityReportSubmitted);
      expect(find.byKey(_report), findsOneWidget, reason: 'card stays');
      await unmountRooms(tester);
    });

    testWidgets('Submit report that fails says so, keeps the form and what '
        'was typed, sends once per tap, and the retry goes through '
        '[case:engagement.room_chat.room_member_report.api_failure] '
        '[case:engagement.room_chat.submit_report_onsubmit.api_failure]', (
      tester,
    ) async {
      final s = RoomsServer();
      s.api.fail('POST /safety/report', message: 'Reports are paused.');
      await _enterChat(tester, s);
      await _openAshaCard(tester);
      await tester.tap(find.byKey(_report));
      await tester.pumpAndSettle();
      final field = find.descendant(
        of: find.byType(BottomSheet).last,
        matching: find.byType(TextField),
      );
      await tester.enterText(field, 'Spamming links');
      await tester.tap(find.text(en.reportSubmit));
      await tester.pumpAndSettle();

      expect(s.sent('POST', '/safety/report'), hasLength(1));
      expect(qaSnackText(tester), en.reportSubmitFailed);
      expect(find.text(en.reportSubmit), findsOneWidget, reason: 'form open');
      expect(find.text('Spamming links'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.ancestor(
                of: find.text(en.reportSubmit),
                matching: find.byType(FilledButton),
              ),
            )
            .onPressed,
        isNotNull,
      );
      await _snackGone(tester);

      s.api.json('POST /safety/report', {
        'report': {'id': 'rep-2'},
      });
      await tester.tap(find.text(en.reportSubmit));
      await tester.pumpAndSettle();
      expect(s.sent('POST', '/safety/report'), hasLength(2));
      expect(find.text(en.reportSubmit), findsNothing, reason: 'form closed');
      expect(qaSnackText(tester), en.communityReportSubmitted);
      await unmountRooms(tester);
    });

    testWidgets('Block asks first (Cancel sends nothing), then blocks, '
        'closes the card, confirms and reloads who is here '
        '[case:engagement.room_chat.room_member_block.action]', (tester) async {
      final s = RoomsServer();
      await _enterChat(tester, s);
      await _openAshaCard(tester);
      await tester.tap(find.byKey(_block));
      await tester.pumpAndSettle();
      expect(_inDialog(en.communityBlockTitle('Asha')), findsOneWidget);
      expect(_inDialog(en.communityBlockBody), findsOneWidget);
      await tester.tap(_inDialog(en.commonCancel));
      await tester.pumpAndSettle();
      expect(s.sent('POST', '/safety/block'), isEmpty);
      expect(find.byKey(_block), findsOneWidget);

      final loads = _memberLoads(s);
      s.members = [
        for (final m in s.members)
          if (m['user_id'] != 'asha') m,
      ];
      await tester.tap(find.byKey(_block));
      await tester.pumpAndSettle();
      await tester.tap(_inDialog(en.communityBlockAction));
      await tester.pumpAndSettle();

      expect(s.sent('POST', '/safety/block').single.body, {
        'user_id': 'me',
        'blocked_user_id': 'asha',
      });
      expect(find.byKey(_block), findsNothing, reason: 'card closed');
      expect(qaSnackText(tester), en.roomsBlockedDone('Asha'));
      expect(_memberLoads(s), greaterThan(loads));
      expect(find.byKey(_asha), findsNothing, reason: 'list reloaded');
      await unmountRooms(tester);
    });

    testWidgets('Block that fails says so, keeps the card, sends once per '
        'tap, and the retry blocks '
        '[case:engagement.room_chat.room_member_block.api_failure]', (
      tester,
    ) async {
      final s = RoomsServer();
      s.api.fail('POST /safety/block', message: 'Blocking is paused.');
      await _enterChat(tester, s);
      await _openAshaCard(tester);
      await tester.tap(find.byKey(_block));
      await tester.pumpAndSettle();
      await tester.tap(_inDialog(en.communityBlockAction));
      await tester.pumpAndSettle();

      expect(s.sent('POST', '/safety/block'), hasLength(1));
      expect(qaSnackText(tester), en.communityBlockFailed);
      expect(find.byKey(_block), findsOneWidget);
      expect(_enabled(tester, _block), isTrue);
      await _snackGone(tester);

      s.api.json('POST /safety/block', const <String, dynamic>{});
      await tester.tap(find.byKey(_block));
      await tester.pumpAndSettle();
      await tester.tap(_inDialog(en.communityBlockAction));
      await tester.pumpAndSettle();
      expect(s.sent('POST', '/safety/block'), hasLength(2));
      expect(find.byKey(_block), findsNothing);
      expect(qaSnackText(tester), en.roomsBlockedDone('Asha'));
      await unmountRooms(tester);
    });
  });

  group('host moderation', () {
    testWidgets('Warn asks first (Cancel sends nothing), then sends '
        'warn_user for that member, closes the card and confirms '
        '[case:engagement.room_chat.room_member_warn.action]', (tester) async {
      final s = _hostServer();
      await _enterChat(tester, s);
      await _openAshaCard(tester, moderate: true);
      expect(find.text(en.roomsModerateEyebrow), findsOneWidget);
      await tester.tap(find.byKey(_warn));
      await tester.pumpAndSettle();
      expect(_inDialog(en.roomsWarnTitle('Asha')), findsOneWidget);
      expect(_inDialog(en.roomsWarnBody('Asha')), findsOneWidget);
      await tester.tap(_inDialog(en.commonCancel));
      await tester.pumpAndSettle();
      expect(_moderations(s), isEmpty);

      final loads = _memberLoads(s);
      await tester.tap(find.byKey(_warn));
      await tester.pumpAndSettle();
      await tester.tap(_inDialog(en.roomsWarnAction));
      await tester.pumpAndSettle();
      expect(_moderations(s).single.path, '/rooms/r1/moderate');
      expect(_moderations(s).single.body, {
        'target_user_id': 'asha',
        'action': 'warn_user',
      });
      expect(find.byKey(_warn), findsNothing, reason: 'card closed');
      expect(qaSnackText(tester), en.roomsWarnedDone('Asha'));
      expect(_memberLoads(s), greaterThan(loads));
      await unmountRooms(tester);
    });

    testWidgets("regression: Warn that fails shows the server's reason, "
        'keeps the card and its buttons, sends once per tap; retry works '
        '[case:engagement.room_chat.room_member_warn.api_failure]', (
      tester,
    ) async {
      final s = _hostServer();
      s.api.fail('POST /rooms/*/moderate', message: 'Moderation is offline.');
      await _enterChat(tester, s);
      await _openAshaCard(tester, moderate: true);
      Future<void> warn() async {
        await tester.tap(find.byKey(_warn));
        await tester.pumpAndSettle();
        await tester.tap(_inDialog(en.roomsWarnAction));
        await tester.pumpAndSettle();
      }

      await warn();
      expect(qaSnackText(tester), 'Moderation is offline.');
      expect(find.byKey(_warn), findsOneWidget);
      expect(_enabled(tester, _warn), isTrue);
      expect(_moderations(s), hasLength(1));
      await _snackGone(tester);

      s.api.on('POST /rooms/*/moderate', (_) => const QaReply(500, null));
      await warn();
      expect(qaSnackText(tester), en.engagementRoomsModerationFailed);
      await _snackGone(tester);

      s.api.on('POST /rooms/*/moderate', (c) => qaOk({'room': s.joined('r1')}));
      await warn();
      expect(_moderations(s), hasLength(3));
      expect(find.byKey(_warn), findsNothing);
      expect(qaSnackText(tester), en.roomsWarnedDone('Asha'));
      await unmountRooms(tester);
    });

    testWidgets('Mute in an always-on room offers 10 minutes, 1 hour or 24 '
        'hours; closing the choice sends nothing; 10 minutes sends '
        'mute_user 10m and confirms '
        '[case:engagement.room_chat.room_member_mute.action] '
        '[case:engagement.room_chat.room_mute_x.action]', (tester) async {
      final s = _hostServer();
      await _enterChat(tester, s);
      await _openAshaCard(tester, moderate: true);
      await tester.tap(find.byKey(_mute));
      await tester.pumpAndSettle();
      expect(find.text(en.roomsMuteSheetTitle('Asha')), findsOneWidget);
      expect(find.text(en.roomsMuteSheetBody('Asha')), findsOneWidget);
      expect(find.text(en.roomsMuteTenMinutes), findsOneWidget);
      expect(find.text(en.roomsMuteOneHour), findsOneWidget);
      expect(find.text(en.roomsMuteOneDay), findsOneWidget);
      expect(find.text(en.roomsMuteUntilEnd), findsNothing);

      await _dismissSheet(tester);
      expect(find.text(en.roomsMuteSheetTitle('Asha')), findsNothing);
      expect(_moderations(s), isEmpty);
      expect(find.byKey(_mute), findsOneWidget, reason: 'card stays');

      final loads = _memberLoads(s);
      await tester.tap(find.byKey(_mute));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('room.mute.10m')));
      await tester.pumpAndSettle();
      expect(_moderations(s).single.body, {
        'target_user_id': 'asha',
        'action': 'mute_user',
        'duration': '10m',
      });
      expect(find.text(en.roomsMuteSheetTitle('Asha')), findsNothing);
      expect(find.byKey(_mute), findsNothing, reason: 'card closed');
      expect(qaSnackText(tester), en.roomsMutedDone('Asha'));
      expect(_memberLoads(s), greaterThan(loads));
      await unmountRooms(tester);
    });

    testWidgets('Mute in a room the host started offers "Until the room '
        'ends", which sends duration session; the list then shows the mute '
        '[case:engagement.room_chat.until_the_room_ends.action] '
        '[case:engagement.room_chat.room_mute_x.action] '
        '[case:engagement.room_chat.room_member_mute.action]', (tester) async {
      final s = _hostedRoomServer();
      await _enterChat(tester, s);
      await _openAshaCard(tester, moderate: true);
      await tester.tap(find.byKey(_mute));
      await tester.pumpAndSettle();
      expect(find.text(en.roomsMuteUntilEnd), findsOneWidget);
      expect(find.text(en.roomsMuteOneDay), findsNothing);

      final until = DateTime.now().add(const Duration(hours: 1));
      s.members = [
        for (final m in s.members)
          m['user_id'] == 'asha'
              ? {...m, 'muted_until': until.toUtc().toIso8601String()}
              : m,
      ];
      await tester.tap(find.byKey(const ValueKey('room.mute.session')));
      await tester.pumpAndSettle();
      expect(_moderations(s).single.body, {
        'target_user_id': 'asha',
        'action': 'mute_user',
        'duration': 'session',
      });
      expect(find.byKey(_mute), findsNothing);
      expect(qaSnackText(tester), en.roomsMutedDone('Asha'));
      // Back on the moderation list, Asha now shows as muted.
      expect(
        find.textContaining(_before(en.roomsStatusMutedUntil)),
        findsOneWidget,
      );
      await unmountRooms(tester);
    });

    testWidgets("regression: Mute that fails shows the server's reason and "
        'keeps the card with Mute available; the retry mutes '
        '[case:engagement.room_chat.room_member_mute.api_failure]', (
      tester,
    ) async {
      final s = _hostServer();
      s.api.fail(
        'POST /rooms/*/moderate',
        status: 404,
        message: 'Asha already left the room.',
      );
      await _enterChat(tester, s);
      await _openAshaCard(tester, moderate: true);
      await tester.tap(find.byKey(_mute));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('room.mute.1h')));
      await tester.pumpAndSettle();

      expect(qaSnackText(tester), 'Asha already left the room.');
      expect(find.byKey(_mute), findsOneWidget);
      expect(_enabled(tester, _mute), isTrue);
      expect(_moderations(s), hasLength(1));
      await _snackGone(tester);

      s.api.on('POST /rooms/*/moderate', (c) => qaOk({'room': s.joined('r1')}));
      await tester.tap(find.byKey(_mute));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('room.mute.1h')));
      await tester.pumpAndSettle();
      expect(_moderations(s), hasLength(2));
      expect(_moderations(s).last.body['duration'], '1h');
      expect(qaSnackText(tester), en.roomsMutedDone('Asha'));
      await unmountRooms(tester);
    });

    testWidgets('A muted member shows Unmute: it sends unmute_user (no '
        'duration), closes the card and confirms '
        '[case:engagement.room_chat.room_member_unmute.action]', (
      tester,
    ) async {
      final until = DateTime.now().add(const Duration(minutes: 30));
      final s = _hostServer(ashaMutedUntil: until.toUtc().toIso8601String());
      await _enterChat(tester, s);
      await _openAshaCard(tester, moderate: true);
      expect(find.byKey(_mute), findsNothing);
      expect(
        find.textContaining(_before(en.roomsStatusMutedUntil)),
        findsWidgets,
      );

      final loads = _memberLoads(s);
      await tester.tap(find.byKey(_unmute));
      await tester.pumpAndSettle();
      expect(_moderations(s).single.body, {
        'target_user_id': 'asha',
        'action': 'unmute_user',
      });
      expect(find.byKey(_unmute), findsNothing, reason: 'card closed');
      expect(qaSnackText(tester), en.roomsUnmutedDone('Asha'));
      expect(_memberLoads(s), greaterThan(loads));
      await unmountRooms(tester);
    });

    testWidgets("regression: Unmute that fails shows the server's reason "
        'and keeps Unmute available '
        '[case:engagement.room_chat.room_member_unmute.api_failure]', (
      tester,
    ) async {
      final until = DateTime.now().add(const Duration(minutes: 30));
      final s = _hostServer(ashaMutedUntil: until.toUtc().toIso8601String());
      s.api.fail(
        'POST /rooms/*/moderate',
        status: 409,
        message: 'Asha is not muted any more.',
      );
      await _enterChat(tester, s);
      await _openAshaCard(tester, moderate: true);
      await tester.tap(find.byKey(_unmute));
      await tester.pumpAndSettle();

      expect(qaSnackText(tester), 'Asha is not muted any more.');
      expect(find.byKey(_unmute), findsOneWidget);
      expect(_enabled(tester, _unmute), isTrue);
      expect(_moderations(s), hasLength(1));
      await unmountRooms(tester);
    });

    testWidgets(
      'Remove asks first with what it means (Cancel sends '
      'nothing), then sends remove_user, closes the card and the list '
      'drops the member [case:engagement.room_chat.room_member_remove.action]',
      (tester) async {
        final s = _hostServer();
        await _enterChat(tester, s);
        await _openAshaCard(tester, moderate: true);
        await tester.tap(find.byKey(_remove));
        await tester.pumpAndSettle();
        expect(_inDialog(en.roomsRemoveTitle('Asha')), findsOneWidget);
        expect(_inDialog(en.roomsRemoveBodyAlwaysOn('Asha')), findsOneWidget);
        await tester.tap(_inDialog(en.commonCancel));
        await tester.pumpAndSettle();
        expect(_moderations(s), isEmpty);

        s.members = [
          for (final m in s.members)
            if (m['user_id'] != 'asha') m,
        ];
        await tester.tap(find.byKey(_remove));
        await tester.pumpAndSettle();
        await tester.tap(_inDialog(en.roomsRemoveAction));
        await tester.pumpAndSettle();
        expect(_moderations(s).single.body, {
          'target_user_id': 'asha',
          'action': 'remove_user',
        });
        expect(find.byKey(_remove), findsNothing, reason: 'card closed');
        expect(qaSnackText(tester), en.roomsRemovedDone('Asha'));
        expect(find.byKey(_asha), findsNothing, reason: 'list reloaded');
        await unmountRooms(tester);
      },
    );

    testWidgets("regression: Remove that fails shows the server's reason and "
        'keeps the card (hosted room: the warning says until it ends) '
        '[case:engagement.room_chat.room_member_remove.api_failure]', (
      tester,
    ) async {
      final s = _hostedRoomServer();
      s.api.fail(
        'POST /rooms/*/moderate',
        status: 403,
        message: 'Moderators cannot be removed.',
      );
      await _enterChat(tester, s);
      await _openAshaCard(tester, moderate: true);
      await tester.tap(find.byKey(_remove));
      await tester.pumpAndSettle();
      expect(_inDialog(en.roomsRemoveBodyHosted('Asha')), findsOneWidget);
      await tester.tap(_inDialog(en.roomsRemoveAction));
      await tester.pumpAndSettle();

      expect(qaSnackText(tester), 'Moderators cannot be removed.');
      expect(find.byKey(_remove), findsOneWidget);
      expect(_enabled(tester, _remove), isTrue);
      expect(_moderations(s), hasLength(1));
      await unmountRooms(tester);
    });
  });

  testWidgets('The room chat, its people and a member card render translated '
      'in every locale without overflow [case:engagement.room_chat.l10n]', (
    tester,
  ) async {
    for (final locale in qaLocales) {
      final l = qaL10n(locale);
      final s = RoomsServer();
      await _enterChat(tester, s, locale: locale);
      expect(tester.takeException(), isNull, reason: '$locale');
      expect(
        find.text('${l.roomsHereNow(3)} · ${l.roomsInTheRoom(5)}'),
        findsOneWidget,
        reason: '$locale',
      );
      expect(
        tester.widget<PopupMenuButton<String>>(find.byKey(_menu)).tooltip,
        l.roomsMenuTooltip,
      );

      await tester.tap(find.byKey(_people));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$locale');
      expect(find.text(l.roomsMenuPeople), findsOneWidget, reason: '$locale');
      expect(find.text(l.roomsPeopleIntro), findsOneWidget, reason: '$locale');

      await tester.tap(find.byKey(_asha));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$locale');
      expect(find.text(l.roomsReport), findsOneWidget, reason: '$locale');
      expect(find.text(l.roomsBlock), findsOneWidget, reason: '$locale');
      expect(find.text(l.friendsAddFriend), findsOneWidget, reason: '$locale');
      await unmountRooms(tester);
    }
  });
}
