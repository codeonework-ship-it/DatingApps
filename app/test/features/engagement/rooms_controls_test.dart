// Case tags stay whole on one line for the static coverage scanner.
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/engagement/screens/conversation_rooms_screen.dart';
import 'package:verified_dating_app/features/social_chat/social_chat_screen.dart';

import '../../support/qa_api.dart';
import 'rooms_qa_fixture.dart';

// Rooms list controls: join a room from its tile, start a room (the sheet's
// fields, topic, length and Start now), pull to refresh, Try again, the
// topic and "Friends here" filters, and Back. Each test performs the gesture
// and asserts the request the server got, where the member ended up and what
// they see; every API call also has its failure path.

final en = qaL10n(const Locale('en'));

const _start = ValueKey('rooms.start');
const _title = ValueKey('rooms.start.title');
const _about = ValueKey('rooms.start.about');
const _submit = ValueKey('rooms.start.submit');
const _retry = ValueKey('qa.rooms.retry');
const _list = ValueKey('rooms.list');

Finder _tile(String id) => find.byKey(ValueKey('rooms.tile.$id'));
Finder get _sheet => find.byType(BottomSheet);
Finder _inSheet(String text) =>
    find.descendant(of: _sheet, matching: find.text(text));

String _summary(int people, int rooms) =>
    en.roomsChattingIn(en.roomsPeopleCount(people), en.roomsRoomCount(rooms));

Future<void> _openStartSheet(WidgetTester tester) async {
  await tester.tap(find.byKey(_start));
  await tester.pumpAndSettle();
}

Future<void> _tapSubmit(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(_submit));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(_submit));
}

Future<void> _pullToRefresh(WidgetTester tester) async {
  await tester.fling(find.byKey(_list), const Offset(0, 900), 1200);
  await tester.pumpAndSettle();
}

/// Lets the visible SnackBar time out, so the next one can show.
Future<void> _snackGone(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
  expect(find.byType(SnackBar), findsNothing);
}

bool _chipSelected(WidgetTester tester, String key) {
  final chip = tester.widget(find.byKey(ValueKey(key)));
  return switch (chip) {
    ChoiceChip(:final selected) => selected,
    FilterChip(:final selected) => selected,
    _ => throw StateError('not a chip: $key'),
  };
}

Future<void> _tapChip(WidgetTester tester, String key) async {
  await tester.ensureVisible(find.byKey(ValueKey(key)));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ValueKey(key)));
  await tester.pumpAndSettle();
}

void main() {
  group('room tile', () {
    testWidgets('Tapping a room joins it once, shows it is busy, opens its '
        'chat, and back on the list it is one of your rooms '
        '[case:engagement.conversation_rooms.rooms_tile_x.action]', (
      tester,
    ) async {
      final s = RoomsServer();
      s.api.on('POST /rooms/*/join', slow(s.join));
      await openRooms(tester, s);
      expect(find.text(en.roomsSectionYours.toUpperCase()), findsNothing);

      await tester.ensureVisible(_tile('r2'));
      await tester.pumpAndSettle();
      await tester.tap(_tile('r2'));
      await tester.pump(const Duration(milliseconds: 50));
      // Busy: a spinner in place of "Join", and a second tap does nothing.
      expect(
        find.descendant(
          of: _tile('r2'),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      await tester.tap(_tile('r2'), warnIfMissed: false);
      await tester.pumpAndSettle();

      final joins = s.sent('POST', '/rooms/*/join');
      expect(joins.map((c) => c.path), ['/rooms/r2/join']);
      expect(joins.single.data, isNull);
      expect(find.byType(SocialChatScreen), findsOneWidget);
      expect(
        tester.widget<SocialChatScreen>(find.byType(SocialChatScreen)).title,
        "Bookworms' corner",
      );
      expect(find.text(en.roomsChatEmpty("Bookworms' corner")), findsOneWidget);

      final listLoads = s.sent('GET', '/rooms').length;
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(SocialChatScreen), findsNothing);
      expect(s.sent('GET', '/rooms'), hasLength(listLoads + 1));
      // The room now sits under "Your rooms" with Open.
      expect(find.text(en.roomsSectionYours.toUpperCase()), findsOneWidget);
      expect(
        find.descendant(of: _tile('r2').first, matching: find.text('Open')),
        findsOneWidget,
      );
      await unmountRooms(tester);
    });

    testWidgets('A room whose chat is not open yet says so and opens nothing '
        '[case:engagement.conversation_rooms.rooms_tile_x.action]', (
      tester,
    ) async {
      final s = RoomsServer();
      s.api.on(
        'POST /rooms/*/join',
        (c) => qaOk({
          'room': {...s.joined('r2'), 'channel_id': ''},
        }),
      );
      await openRooms(tester, s);
      await tapRoom(tester, 'r2');

      expect(s.sent('POST', '/rooms/r2/join'), hasLength(1));
      expect(find.byType(SocialChatScreen), findsNothing);
      expect(qaSnackText(tester), en.roomsChatNotOpen);
    });

    testWidgets('A join that fails says why, leaves the tile tappable, sends '
        'once per tap, and the retry opens the chat '
        '[case:engagement.conversation_rooms.rooms_tile_x.api_failure]', (
      tester,
    ) async {
      final s = RoomsServer();
      s.api.fail(
        'POST /rooms/*/join',
        status: 409,
        message: 'This room is full.',
        code: 'ROOM_CAPACITY_REACHED',
      );
      await openRooms(tester, s);

      await tapRoom(tester, 'r2');
      expect(qaSnackText(tester), 'This room is full.');
      expect(find.byType(SocialChatScreen), findsNothing);
      expect(
        find.descendant(of: _tile('r2'), matching: find.text('Join')),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(s.sent('POST', '/rooms/*/join'), hasLength(1));
      await _snackGone(tester);

      // Offline, then a server error with no reason: readable fallbacks.
      s.api.offline('POST /rooms/*/join');
      await tapRoom(tester, 'r2');
      expect(qaSnackText(tester), en.networkCannotReachService);
      await _snackGone(tester);
      s.api.on('POST /rooms/*/join', (_) => const QaReply(500, null));
      await tapRoom(tester, 'r2');
      expect(qaSnackText(tester), en.roomsJoinFailed);
      await _snackGone(tester);
      expect(s.sent('POST', '/rooms/*/join'), hasLength(3));

      s.api.on('POST /rooms/*/join', s.join);
      await tapRoom(tester, 'r2');
      expect(s.sent('POST', '/rooms/*/join'), hasLength(4));
      expect(find.byType(SocialChatScreen), findsOneWidget);
      await unmountRooms(tester);
    });
  });

  group('start a room', () {
    testWidgets(
      'Start a room opens the start sheet; dismissing it sends '
      'nothing [case:engagement.conversation_rooms.showmodalbottomsheet_open.action]',
      (tester) async {
        final s = RoomsServer();
        await openRooms(tester, s);
        await _openStartSheet(tester);

        expect(_sheet, findsOneWidget);
        expect(_inSheet(en.roomsStartRoom), findsOneWidget);
        expect(_inSheet(en.roomsStartIntro), findsOneWidget);
        expect(_inSheet(en.roomsStartNameLabel), findsOneWidget);
        expect(_inSheet(en.roomsStartAboutLabel), findsOneWidget);
        expect(_inSheet(en.roomsStartTopic), findsOneWidget);
        expect(_inSheet(en.roomsLength1Hour), findsOneWidget);
        expect(_inSheet(en.roomsStartNow), findsOneWidget);
        // Talk and an hour are picked to start with.
        expect(_chipSelected(tester, 'qa.rooms.start.category.talk'), isTrue);
        expect(
          tester
              .widget<SegmentedButton<int>>(
                find.byKey(const ValueKey('qa.rooms.start.length')),
              )
              .selected,
          {60},
        );

        final top = tester.getTopLeft(_sheet).dy;
        expect(top, greaterThan(60));
        await tester.tapAt(const Offset(200, 30));
        await tester.pumpAndSettle();
        expect(_sheet, findsNothing);
        expect(s.api.writes, isEmpty);
        expect(find.byType(SocialChatScreen), findsNothing);
      },
    );

    testWidgets(
      'Start now sends the name, line, topic and length once, '
      'closes the sheet, opens the new room, and the list then shows it '
      'hosted by you '
      '[case:engagement.conversation_rooms.rooms_start.action] '
      '[case:engagement.conversation_rooms.rooms_start_submit.action] '
      '[case:engagement.conversation_rooms.rooms_start_title_input.action] '
      '[case:engagement.conversation_rooms.rooms_start_about_input.action] '
      '[case:engagement.conversation_rooms.choicechip_onselected.action] '
      '[case:engagement.conversation_rooms.30_min_onselectionchanged.action]',
      (tester) async {
        final s = RoomsServer();
        s.api.on('POST /rooms', slow(s.create));
        await openRooms(tester, s);
        final loads = s.sent('GET', '/rooms').length;
        await _openStartSheet(tester);

        await tester.enterText(find.byKey(_title), 'Sunday picnic');
        await tester.enterText(find.byKey(_about), 'Bring one dish, take two.');
        await tester.pump();
        expect(find.text('Sunday picnic'), findsOneWidget);
        expect(find.text('Bring one dish, take two.'), findsOneWidget);

        await tester.tap(
          find.byKey(const ValueKey('qa.rooms.start.category.interests')),
        );
        await tester.pump();
        expect(
          _chipSelected(tester, 'qa.rooms.start.category.interests'),
          isTrue,
        );
        expect(_chipSelected(tester, 'qa.rooms.start.category.talk'), isFalse);

        await tester.tap(_inSheet(en.roomsLength30Min));
        await tester.pump();
        expect(
          tester
              .widget<SegmentedButton<int>>(
                find.byKey(const ValueKey('qa.rooms.start.length')),
              )
              .selected,
          {30},
        );

        await _tapSubmit(tester);
        await tester.pump(const Duration(milliseconds: 50));
        // Busy: the button is disabled, so a second tap sends nothing.
        expect(
          tester.widget<FilledButton>(find.byKey(_submit)).onPressed,
          isNull,
        );
        await tester.tap(find.byKey(_submit), warnIfMissed: false);
        await tester.pumpAndSettle();

        expect(s.sent('POST', '/rooms'), hasLength(1));
        expect(s.sent('POST', '/rooms').single.body, {
          'title': 'Sunday picnic',
          'description': 'Bring one dish, take two.',
          'category': 'interests',
          'duration_minutes': 30,
          'capacity': 30,
        });
        expect(_sheet, findsNothing);
        expect(find.byType(SocialChatScreen), findsOneWidget);
        expect(
          tester
              .widget<SocialChatScreen>(find.byType(SocialChatScreen))
              .channelId,
          channelOf('r9'),
        );
        expect(find.text(en.roomsChatEmpty('Sunday picnic')), findsOneWidget);

        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(s.sent('GET', '/rooms'), hasLength(loads + 1));
        expect(_tile('r9'), findsWidgets);
        expect(
          find.descendant(
            of: _tile('r9').first,
            matching: find.textContaining(en.roomsHostedByYou),
          ),
          findsOneWidget,
        );
        await unmountRooms(tester);
      },
    );

    testWidgets(
      'Topic chips and lengths switch the pick: City and 2 hours '
      'are what the server gets '
      '[case:engagement.conversation_rooms.choicechip_onselected.action] '
      '[case:engagement.conversation_rooms.30_min_onselectionchanged.action]',
      (tester) async {
        final s = RoomsServer();
        await openRooms(tester, s);
        await _openStartSheet(tester);
        await tester.enterText(find.byKey(_title), 'Night walk');
        for (final key in ['active', 'city']) {
          await tester.tap(
            find.byKey(ValueKey('qa.rooms.start.category.$key')),
          );
          await tester.pump();
          expect(_chipSelected(tester, 'qa.rooms.start.category.$key'), isTrue);
        }
        expect(
          _chipSelected(tester, 'qa.rooms.start.category.active'),
          isFalse,
        );
        await tester.tap(_inSheet(en.roomsLength2Hours));
        await tester.pump();
        await _tapSubmit(tester);
        await tester.pumpAndSettle();

        final body = s.sent('POST', '/rooms').single.body;
        expect(body['category'], 'city');
        expect(body['duration_minutes'], 120);
        expect(body['description'], '');
        await unmountRooms(tester);
      },
    );

    testWidgets(
      'A room name that is empty, blank or under 3 letters is '
      'refused in words and nothing is sent; past 60 characters typing '
      'stops [case:engagement.conversation_rooms.rooms_start_title_input.validation]',
      (tester) async {
        final s = RoomsServer();
        await openRooms(tester, s);
        await _openStartSheet(tester);

        for (final name in ['', '      ', ' ab ']) {
          await tester.enterText(find.byKey(_title), name);
          await _tapSubmit(tester);
          await tester.pumpAndSettle();
          expect(_inSheet(en.roomsStartNameTooShort), findsOneWidget);
          expect(s.sent('POST', '/rooms'), isEmpty);
          expect(_sheet, findsOneWidget);
        }

        final long = 'L' * 61;
        await tester.enterText(find.byKey(_title), long);
        await tester.pump();
        expect(
          tester.widget<TextField>(find.byKey(_title)).controller!.text,
          'L' * 60,
        );
        await _tapSubmit(tester);
        await tester.pumpAndSettle();
        expect(s.sent('POST', '/rooms').single.body['title'], 'L' * 60);
        await unmountRooms(tester);
      },
    );

    testWidgets(
      'Emoji and right-to-left names and lines reach the server '
      'byte for byte (only outer spaces trimmed) '
      '[case:engagement.conversation_rooms.rooms_start_title_input.validation] '
      '[case:engagement.conversation_rooms.rooms_start_about_input.validation]',
      (tester) async {
        final s = RoomsServer();
        await openRooms(tester, s);
        await _openStartSheet(tester);
        const name = 'سهرة 🌙 ليلية';
        const line = 'נדבר על ספרים 📚 — כולם מוזמנים 👩🏽‍💻';
        await tester.enterText(find.byKey(_title), '  $name  ');
        await tester.enterText(find.byKey(_about), '$line   ');
        await _tapSubmit(tester);
        await tester.pumpAndSettle();

        final body = s.sent('POST', '/rooms').single.body;
        expect(body['title'], name);
        expect(body['description'], line);
        expect(find.text(name), findsWidgets, reason: 'the new room opens');
        await unmountRooms(tester);
      },
    );

    testWidgets(
      'The optional line may be blank (sent empty) and stops at '
      '280 characters '
      '[case:engagement.conversation_rooms.rooms_start_about_input.validation]',
      (tester) async {
        final s = RoomsServer();
        await openRooms(tester, s);
        await _openStartSheet(tester);
        await tester.enterText(find.byKey(_title), 'Quiet hour');
        await tester.enterText(find.byKey(_about), '     ');
        await _tapSubmit(tester);
        await tester.pumpAndSettle();
        expect(s.sent('POST', '/rooms').single.body['description'], '');
        await unmountRooms(tester);

        final s2 = RoomsServer();
        await openRooms(tester, s2);
        await _openStartSheet(tester);
        await tester.enterText(find.byKey(_title), 'Long line');
        await tester.enterText(find.byKey(_about), 'a' * 281);
        await tester.pump();
        expect(
          tester.widget<TextField>(find.byKey(_about)).controller!.text,
          hasLength(280),
        );
        await _tapSubmit(tester);
        await tester.pumpAndSettle();
        expect(s2.sent('POST', '/rooms').single.body['description'], 'a' * 280);
        await unmountRooms(tester);
      },
    );

    testWidgets('Start now that fails shows the reason in the sheet, keeps '
        'what was typed and the button, sends once per tap, and the retry '
        'starts the room '
        '[case:engagement.conversation_rooms.rooms_start_submit.api_failure]', (
      tester,
    ) async {
      final s = RoomsServer();
      s.api.fail(
        'POST /rooms',
        status: 409,
        message: 'You already host an open room.',
        code: 'ROOM_HOST_LIMIT',
      );
      await openRooms(tester, s);
      await _openStartSheet(tester);
      await tester.enterText(find.byKey(_title), 'Sunday picnic');
      await tester.enterText(find.byKey(_about), 'Bring a dish.');
      await _tapSubmit(tester);
      await tester.pumpAndSettle();

      expect(_inSheet('You already host an open room.'), findsOneWidget);
      expect(_sheet, findsOneWidget);
      expect(find.text('Sunday picnic'), findsOneWidget);
      expect(find.text('Bring a dish.'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byKey(_submit)).onPressed,
        isNotNull,
      );
      expect(s.sent('POST', '/rooms'), hasLength(1));

      s.api.on('POST /rooms', (_) => const QaReply(500, null));
      await _tapSubmit(tester);
      await tester.pumpAndSettle();
      expect(_inSheet(en.engagementRoomsCreateFailed), findsOneWidget);
      expect(_inSheet('You already host an open room.'), findsNothing);

      s.api.offline('POST /rooms');
      await _tapSubmit(tester);
      await tester.pumpAndSettle();
      expect(_inSheet(en.networkCannotReachService), findsOneWidget);
      expect(s.sent('POST', '/rooms'), hasLength(3));
      expect(find.byType(SocialChatScreen), findsNothing);

      s.api.on('POST /rooms', s.create);
      await _tapSubmit(tester);
      await tester.pumpAndSettle();
      expect(s.sent('POST', '/rooms'), hasLength(4));
      expect(_sheet, findsNothing);
      expect(find.byType(SocialChatScreen), findsOneWidget);
      await unmountRooms(tester);
    });

    testWidgets('regression: a list refresh that fails after starting a room '
        'says why and keeps the rooms on screen '
        '[case:engagement.conversation_rooms.rooms_start.api_failure]', (
      tester,
    ) async {
      final s = RoomsServer();
      await openRooms(tester, s);
      await _openStartSheet(tester);
      await tester.enterText(find.byKey(_title), 'Sunday picnic');
      await _tapSubmit(tester);
      await tester.pumpAndSettle();
      expect(find.byType(SocialChatScreen), findsOneWidget);

      final loads = s.sent('GET', '/rooms').length;
      s.api.fail(
        'GET /rooms',
        status: 503,
        message: 'Rooms are taking a break.',
      );
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(s.sent('GET', '/rooms'), hasLength(loads + 1));
      expect(qaSnackText(tester), 'Rooms are taking a break.');
      // What was on screen stays: the new room and the others.
      expect(_tile('r9'), findsWidgets);
      expect(_tile('r1'), findsWidgets);
      expect(find.text('Rooms are taking a break.'), findsOneWidget);
      await unmountRooms(tester);
    });
  });

  group('list', () {
    testWidgets(
      'Pull to refresh reloads the rooms and shows the new counts '
      '[case:engagement.conversation_rooms.rooms_members_are_hosting_join_e_onrefresh.action]',
      (tester) async {
        final s = RoomsServer();
        await openRooms(tester, s);
        expect(find.text(_summary(3, 1)), findsOneWidget);
        expect(find.text(en.roomsComingUpCaption), findsOneWidget);
        expect(s.sent('GET', '/rooms'), hasLength(1));
        expect(s.sent('GET', '/rooms').single.query, {'limit': 100});

        s.rooms = [
          for (final r in s.rooms) r['id'] == 'r2' ? {...r, 'here_now': 4} : r,
        ];
        await _pullToRefresh(tester);

        expect(s.sent('GET', '/rooms'), hasLength(2));
        expect(find.text(_summary(7, 2)), findsOneWidget);
        expect(find.textContaining(en.roomsHereNow(4)), findsWidgets);
        expect(qaSnackText(tester), isNull);
      },
    );

    testWidgets(
      'regression: a pull to refresh that fails says why, keeps '
      'the rooms, sends once, and the next pull recovers '
      '[case:engagement.conversation_rooms.rooms_members_are_hosting_join_e_onrefresh.api_failure]',
      (tester) async {
        final s = RoomsServer();
        await openRooms(tester, s);
        s.api.fail(
          'GET /rooms',
          status: 503,
          message: 'Rooms are taking a break.',
        );
        await _pullToRefresh(tester);

        expect(s.sent('GET', '/rooms'), hasLength(2));
        expect(qaSnackText(tester), 'Rooms are taking a break.');
        expect(find.text(_summary(3, 1)), findsOneWidget);
        expect(_tile('r1'), findsWidgets);
        expect(_tile('r2'), findsOneWidget);
        // The full-page error is only for an empty list.
        expect(find.byKey(_retry), findsNothing);
        await _snackGone(tester);

        s.api.json('GET /rooms', {
          'rooms': [
            for (final r in s.rooms)
              r['id'] == 'r2' ? {...r, 'here_now': 4} : r,
          ],
        });
        await _pullToRefresh(tester);
        expect(s.sent('GET', '/rooms'), hasLength(3));
        expect(find.text(_summary(7, 2)), findsOneWidget);
        expect(qaSnackText(tester), isNull);
      },
    );

    testWidgets('Try again after a failed first load fetches the rooms and '
        'shows them [case:engagement.conversation_rooms.try_again.action]', (
      tester,
    ) async {
      final s = RoomsServer();
      s.api.fail('GET /rooms', message: 'Rooms are napping.');
      await openRooms(tester, s);
      expect(find.text('Rooms are napping.'), findsOneWidget);
      expect(find.byKey(_retry), findsOneWidget);
      expect(_tile('r1'), findsNothing);
      expect(qaSnackText(tester), isNull, reason: 'the error is in place');

      s.api.on('GET /rooms', (_) => qaOk({'rooms': s.rooms}));
      await tester.tap(find.byKey(_retry));
      await tester.pumpAndSettle();
      expect(s.sent('GET', '/rooms'), hasLength(2));
      expect(find.text('Rooms are napping.'), findsNothing);
      expect(find.byKey(_retry), findsNothing);
      expect(_tile('r1'), findsWidgets);
      expect(find.text(_summary(3, 1)), findsOneWidget);
    });

    testWidgets(
      'Try again that fails again says why, stays available, '
      'sends once per tap [case:engagement.conversation_rooms.try_again.api_failure]',
      (tester) async {
        final s = RoomsServer();
        s.api.fail('GET /rooms', message: 'Rooms are napping.');
        await openRooms(tester, s);

        s.api.offline('GET /rooms');
        await tester.tap(find.byKey(_retry));
        await tester.pumpAndSettle();
        expect(find.text(en.networkCannotReachService), findsOneWidget);
        expect(s.sent('GET', '/rooms'), hasLength(2));

        s.api.on('GET /rooms', (_) => const QaReply(500, null));
        await tester.tap(find.byKey(_retry));
        await tester.pumpAndSettle();
        expect(find.text(en.engagementRoomsLoadFailed), findsOneWidget);
        expect(
          tester.widget<FilledButton>(find.byKey(_retry)).onPressed,
          isNotNull,
        );
        expect(s.sent('GET', '/rooms'), hasLength(3));

        s.api.on('GET /rooms', (_) => qaOk({'rooms': s.rooms}));
        await tester.tap(find.byKey(_retry));
        await tester.pumpAndSettle();
        expect(_tile('r1'), findsWidgets);
      },
    );

    testWidgets(
      'Topic chips filter the browse list; All brings every room '
      'back; an empty topic says so; nothing is sent '
      '[case:engagement.conversation_rooms.rooms_category_all_category.action]',
      (tester) async {
        final s = RoomsServer();
        await openRooms(tester, s);
        // Late-night talks is live (top) and in the browse list.
        expect(_tile('r1'), findsNWidgets(2));
        expect(_tile('r2'), findsOneWidget);
        expect(_chipSelected(tester, 'rooms.category.all'), isTrue);

        await _tapChip(tester, 'rooms.category.interests');
        expect(_chipSelected(tester, 'rooms.category.interests'), isTrue);
        expect(_chipSelected(tester, 'rooms.category.all'), isFalse);
        expect(_tile('r1'), findsOneWidget, reason: 'live only');
        expect(_tile('r2'), findsOneWidget);

        await _tapChip(tester, 'rooms.category.city');
        expect(find.text(en.roomsNoRoomsInTopic), findsOneWidget);
        expect(_tile('r2'), findsNothing);

        await _tapChip(tester, 'rooms.category.all');
        expect(_chipSelected(tester, 'rooms.category.all'), isTrue);
        expect(find.text(en.roomsNoRoomsInTopic), findsNothing);
        expect(_tile('r1'), findsNWidgets(2));
        expect(_tile('r2'), findsOneWidget);
        expect(s.api.writes, isEmpty);
        expect(s.sent('GET', '/rooms'), hasLength(1));
      },
    );

    testWidgets(
      'Friends here keeps only rooms with a friend inside; with no '
      'match it says so; off again shows all '
      '[case:engagement.conversation_rooms.rooms_friends_here_friendonly.action]',
      (tester) async {
        final s = RoomsServer();
        await openRooms(tester, s);
        await _tapChip(tester, 'rooms.friends_here');
        expect(_chipSelected(tester, 'rooms.friends_here'), isTrue);
        expect(_tile('r1'), findsOneWidget, reason: 'live only, no friend');
        expect(_tile('r2'), findsOneWidget);

        await _tapChip(tester, 'rooms.category.talk');
        expect(find.text(en.roomsNoFriendsHere), findsOneWidget);
        expect(_tile('r2'), findsNothing);

        await _tapChip(tester, 'rooms.friends_here');
        expect(_chipSelected(tester, 'rooms.friends_here'), isFalse);
        expect(find.text(en.roomsNoFriendsHere), findsNothing);
        expect(_tile('r1'), findsNWidgets(2));
        expect(s.api.writes, isEmpty);
      },
    );

    testWidgets(
      'Back closes Rooms and returns to where it was opened '
      '[case:engagement.conversation_rooms.back_icon_arrow_back_rounded.action]',
      (tester) async {
        final s = RoomsServer();
        final results = await openRooms(tester, s, launcher: true);
        expect(find.byType(ConversationRoomsScreen), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('qa.rooms.back')));
        await tester.pumpAndSettle();
        expect(find.byType(ConversationRoomsScreen), findsNothing);
        expect(find.byKey(const ValueKey('qa.test.launcher')), findsOneWidget);
        expect(results, [null]);
        expect(s.api.writes, isEmpty);
      },
    );
  });

  testWidgets('Rooms and the start sheet render translated in every locale '
      'without overflow [case:engagement.conversation_rooms.l10n]', (
    tester,
  ) async {
    for (final locale in qaLocales) {
      final l = qaL10n(locale);
      await openRooms(tester, RoomsServer(), locale: locale);
      expect(tester.takeException(), isNull, reason: '$locale');
      expect(find.text(l.roomsTitle), findsWidgets, reason: '$locale');
      expect(find.text(l.roomsStartRoom), findsOneWidget, reason: '$locale');
      expect(find.text(l.roomsCategoryAll), findsOneWidget, reason: '$locale');

      await _openStartSheet(tester);
      expect(tester.takeException(), isNull, reason: '$locale');
      expect(_inSheet(l.roomsStartNow), findsOneWidget, reason: '$locale');
      expect(
        _inSheet(l.roomsStartNameLabel),
        findsOneWidget,
        reason: '$locale',
      );
      expect(_inSheet(l.roomsLength30Min), findsOneWidget, reason: '$locale');
      await unmountRooms(tester);
    }
  });
}
