import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/groups/friend_picker.dart';
import 'package:verified_dating_app/features/groups/group_launch.dart';

import '../../support/qa_api.dart';
import '../../support/qa_screen_checks.dart';
import 'groups_world.dart';

// The friend picker sheet (Start a group's "Choose friends" and a group's
// "Invite friends"): search, picking and un-picking friends, the confirm
// button and what it hands back to the opener, and the retry when friends
// fail to load. Each test drives the real sheet against the fake BFF.

final _en = qaL10n(const Locale('en'));

/// Opens the picker the way the app does and records what it returns.
class _Host extends StatelessWidget {
  const _Host({
    required this.results,
    this.groupId = '',
    this.selected = const [],
    this.confirmLabel,
  });
  final List<List<GroupInvitee>?> results;
  final String groupId;
  final List<GroupInvitee> selected;
  final String? confirmLabel;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: IconButton(
        key: const ValueKey('qa.test.picker'),
        icon: const Icon(Icons.group_add_outlined),
        onPressed: () async => results.add(
          await pickGroupFriends(
            context,
            groupId: groupId,
            selected: selected,
            confirmLabel: confirmLabel,
          ),
        ),
      ),
    ),
  );
}

Future<List<List<GroupInvitee>?>> _openPicker(
  WidgetTester tester,
  GroupsWorld world, {
  String groupId = '',
  List<GroupInvitee> selected = const [],
  String? confirmLabel,
  Locale? locale,
}) async {
  final results = <List<GroupInvitee>?>[];
  await pumpQa(
    tester,
    world.api,
    _Host(
      results: results,
      groupId: groupId,
      selected: selected,
      confirmLabel: confirmLabel,
    ),
    size: const Size(430, 1200),
    locale: locale,
  );
  await qaTap(tester, qaKey('qa.test.picker'));
  expect(find.byType(GroupFriendPicker), findsOneWidget);
  return results;
}

Finder _tile(String name) => find.widgetWithText(CheckboxListTile, name);
Finder get _search => find.widgetWithText(TextField, _en.groupsSearchFriends);

bool? _checked(WidgetTester tester, String name) =>
    tester.widget<CheckboxListTile>(_tile(name)).value;

List<String> _shown(WidgetTester tester) => [
  for (final e in find.byType(CheckboxListTile).evaluate())
    ((e.widget as CheckboxListTile).title! as Text).data!,
];

List<String> _ids(List<GroupInvitee>? picked) => [
  for (final f in picked ?? const <GroupInvitee>[]) f.userId,
];

void main() {
  testWidgets(
    'picking a friend ticks them and counts them on the confirm button; '
    'picking again un-ticks them; members and invitees cannot be picked '
    '[case:groups.friend_picker.friend.action]',
    (tester) async {
      final world = GroupsWorld();
      final results = await _openPicker(tester, world, groupId: 'g1');
      expect(_checked(tester, 'Dev'), isFalse);
      expect(find.text(_en.groupsDone), findsOneWidget);

      await qaTap(tester, _tile('Dev'));
      expect(_checked(tester, 'Dev'), isTrue);
      expect(find.text('${_en.groupsDone} (1)'), findsOneWidget);

      await qaTap(tester, _tile('Kabir'));
      expect(find.text('${_en.groupsDone} (2)'), findsOneWidget);

      await qaTap(tester, _tile('Dev'));
      expect(_checked(tester, 'Dev'), isFalse);
      expect(find.text('${_en.groupsDone} (1)'), findsOneWidget);

      // Asha is already in the group and Meera already invited: shown as
      // ticked with why, but tapping them changes nothing.
      expect(find.text(_en.groupsAlreadyMember), findsOneWidget);
      expect(find.text(_en.groupsInvitationSent), findsOneWidget);
      expect(tester.widget<CheckboxListTile>(_tile('Asha')).onChanged, isNull);
      await qaTap(tester, _tile('Asha'));
      await qaTap(tester, _tile('Meera'));
      expect(find.text('${_en.groupsDone} (1)'), findsOneWidget);

      await qaTap(tester, find.text('${_en.groupsDone} (1)'));
      expect(results, hasLength(1));
      expect(_ids(results.single), ['kabir']);
      expect(results.single!.single.name, 'Kabir');
      expect(world.api.writes, isEmpty, reason: 'picking sends nothing');
    },
  );

  testWidgets(
    'the confirm button closes the sheet and hands back exactly the chosen '
    'friends, with a custom label and the count '
    '[case:groups.friend_picker.confirmlabel_chosen_length.action]',
    (tester) async {
      final world = GroupsWorld();
      final results = await _openPicker(
        tester,
        world,
        groupId: 'g1',
        confirmLabel: _en.groupsSendInvitations,
      );
      expect(world.api.sent('GET', '/engagement/group-friends').single.query, {
        'group_id': 'g1',
      });
      expect(find.text(_en.groupsSendInvitations), findsOneWidget);
      await qaTap(tester, _tile('Dev'));
      await qaTap(tester, _tile('Zoë'));
      final confirm = find.text('${_en.groupsSendInvitations} (2)');
      expect(confirm, findsOneWidget);

      await qaTap(tester, confirm);
      expect(find.byType(GroupFriendPicker), findsNothing);
      expect(results, hasLength(1));
      expect(_ids(results.single), ['dev', 'zoe']);

      // With nothing chosen it hands back an empty list (not a dismissal).
      await qaTap(tester, qaKey('qa.test.picker'));
      await qaTap(tester, find.text(_en.groupsSendInvitations));
      expect(results, hasLength(2));
      expect(results.last, isEmpty);
    },
  );

  testWidgets(
    'search narrows the list by name (any case) and keeps the friends '
    'already chosen while filtered '
    '[case:groups.friend_picker.search_friends.action]',
    (tester) async {
      final world = GroupsWorld();
      final results = await _openPicker(tester, world);
      expect(_shown(tester), ['Asha', 'Dev', 'Meera', 'Kabir', 'Zoë']);
      await qaTap(tester, _tile('Dev'));

      await tester.enterText(_search, 'KAB');
      await tester.pump();
      expect(_shown(tester), ['Kabir']);
      await qaTap(tester, _tile('Kabir'));
      expect(find.text('${_en.groupsDone} (2)'), findsOneWidget);

      await tester.enterText(_search, '');
      await tester.pump();
      expect(_shown(tester), hasLength(5));
      expect(_checked(tester, 'Dev'), isTrue);

      await qaTap(tester, find.text('${_en.groupsDone} (2)'));
      expect(_ids(results.single), ['dev', 'kabir']);
      // Searching is local: no request per keystroke.
      expect(world.api.sent('GET', '/engagement/group-friends'), hasLength(1));
    },
  );

  testWidgets(
    'search ignores surrounding spaces, treats whitespace as no filter, '
    'matches accents and right-to-left names, and a long query just shows '
    'no one [case:groups.friend_picker.search_friends.validation]',
    (tester) async {
      final world = GroupsWorld()
        ..friends.add({
          'user_id': 'maryam',
          'name': 'مريم',
          'status': 'available',
        });
      await _openPicker(tester, world);
      Future<void> search(String q) async {
        await tester.enterText(_search, q);
        await tester.pump();
      }

      await search('    ');
      expect(_shown(tester), hasLength(6));
      await search('  kabir  ');
      expect(_shown(tester), ['Kabir']);
      await search('zoë');
      expect(_shown(tester), ['Zoë']);
      await search('مر');
      expect(_shown(tester), ['مريم']);
      // The typed query stays as typed (right-to-left, unaltered).
      final field = find.descendant(
        of: _search,
        matching: find.byType(EditableText),
      );
      expect(tester.widget<EditableText>(field).controller.text, 'مر');
      await search('x' * 300);
      expect(_shown(tester), isEmpty);
      expect(tester.takeException(), isNull);
      await search('');
      expect(_shown(tester), hasLength(6));
      expect(world.api.sent('GET', '/engagement/group-friends'), hasLength(1));
    },
  );

  testWidgets('friends that fail to load say why; Try again loads them and the '
      'friends chosen before are still chosen '
      '[case:groups.friend_picker.friends_could_not_load_onaction.action]', (
    tester,
  ) async {
    final world = GroupsWorld();
    world.api.fail(
      'GET /engagement/group-friends',
      message: 'Friends are taking a nap.',
    );
    final results = await _openPicker(
      tester,
      world,
      selected: [(userId: 'dev', name: 'Dev', photoUrl: '')],
    );
    expect(find.text(_en.groupsFriendsFailed), findsOneWidget);
    expect(find.text('Friends are taking a nap.'), findsOneWidget);
    expect(find.byType(CheckboxListTile), findsNothing);
    expect(find.text('${_en.groupsDone} (1)'), findsOneWidget);

    world.heal('GET /engagement/group-friends');
    await qaTap(tester, find.widgetWithText(OutlinedButton, _en.chatTryAgain));
    expect(world.api.sent('GET', '/engagement/group-friends'), hasLength(2));
    expect(find.text(_en.groupsFriendsFailed), findsNothing);
    expect(find.byType(CheckboxListTile), findsNWidgets(5));
    expect(_checked(tester, 'Dev'), isTrue);

    await qaTap(tester, find.text('${_en.groupsDone} (1)'));
    expect(_ids(results.single), ['dev']);
  });

  testWidgets(
    'the friend picker renders translated in every locale with nothing left '
    'in English [case:groups.friend_picker.l10n]',
    (tester) async {
      await qaExpectRendersInAllLocales(
        tester,
        GroupsWorld().api,
        () => const _Host(results: [], groupId: 'g1'),
        prepare: (tester, l) async {
          await qaTap(tester, qaKey('qa.test.picker'));
          await qaTap(tester, _tile('Dev'));
        },
        expected: [
          (l) => l.groupsChooseFriends,
          (l) => l.groupsPickerSubtitle,
          (l) => l.groupsSearchFriends,
          (l) => '${l.groupsDone} (1)',
          (l) => l.groupsAlreadyMember,
          (l) => l.groupsInvitationSent,
        ],
        // Fixture data: the friends' names.
        allow: {'Asha', 'Dev', 'Meera', 'Kabir', 'Zoë'},
      );
    },
  );
}
