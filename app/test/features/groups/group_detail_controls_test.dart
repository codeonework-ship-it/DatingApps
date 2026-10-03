import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:verified_dating_app/features/groups/friend_picker.dart';
import 'package:verified_dating_app/features/groups/group_detail_screen.dart';
import 'package:verified_dating_app/features/groups/group_widgets.dart';
import 'package:verified_dating_app/features/social_chat/social_chat_screen.dart';

import '../../support/qa_api.dart';
import '../../support/qa_screen_checks.dart';
import 'groups_world.dart';

// One group: owner tools (edit, cover, delete), the edit sheet's fields and
// chips, members and their options, join / answer an invitation / leave,
// the group chat and a sender's card, pull to refresh and the unavailable
// notice. Each test performs the gesture against the stateful fake BFF and
// asserts the exact request, the state change and what the member sees —
// and, for commands, what happens when the server refuses.

final _en = qaL10n(const Locale('en'));

/// "Koramangala readers" (Books), 3 members: Priya (me), Asha (moderator)
/// and Dev. [role] is mine ('' = not a member).
GroupsWorld _world({String role = 'member', String coverStatus = ''}) {
  final w = GroupsWorld();
  w.groups['g1'] = qaGroup(
    role: role,
    channel: role.isEmpty ? '' : 'ch-g1',
    canInvite: role.isNotEmpty,
    canManage: role == 'owner',
    canJoin: role.isEmpty,
    city: 'Bengaluru',
    coverId: coverStatus.isEmpty ? '' : 'cv1',
    coverStatus: coverStatus,
  );
  w.members['g1'] = [
    qaMember('me', 'Priya', role: role.isEmpty ? 'member' : role, me: true),
    qaMember('asha', 'Asha', role: 'moderator'),
    qaMember('dev', 'Dev'),
  ];
  return w;
}

Future<List<Object?>> _open(
  WidgetTester tester,
  GroupsWorld world, {
  String id = 'g1',
  QaCoverPicker? picker,
}) async {
  final results = await pumpQa(
    tester,
    world.api,
    GroupDetailScreen(groupId: id),
    size: const Size(430, 1400),
    launcher: true,
    extra: [if (picker != null) qaPickerOverride(picker)],
  );
  await qaSettleRequests(tester);
  return results;
}

Map<String, dynamic> _g(GroupsWorld w, [String id = 'g1']) => w.groups[id]!;

Finder get _detail => find.byType(GroupDetailScreen);
Finder get _dialog => find.byType(AlertDialog);
Finder get _sheet => find.byType(BottomSheet);
Finder _confirm(String action) => find.descendant(
  of: _dialog,
  matching: find.widgetWithText(FilledButton, action),
);
Finder _button<T extends Widget>(String text) => find.widgetWithText(T, text);

Future<void> _ownerTool(WidgetTester tester, String item) async {
  await qaTap(tester, find.byTooltip(_en.groupsOwnerTools));
  await qaTap(tester, find.text(item).last);
}

// ---------------------------------------------------------------- edit sheet

Finder _field(String label) => find.descendant(
  of: _sheet,
  matching: find.widgetWithText(TextField, label),
);
Finder get _nameField => _field(_en.groupsNameLabel);
Finder get _aboutField => _field(_en.groupsAboutLabel);
Finder get _cityField => _field(_en.groupsCityLabel);
Finder get _save => _button<FilledButton>(_en.groupsSaveChanges);
Finder _sheetChip(String label) => find.descendant(
  of: _sheet,
  matching: find.widgetWithText(ChoiceChip, label),
);

String _text(WidgetTester tester, Finder field) =>
    tester.widget<TextField>(field).controller!.text;

Future<void> _openEdit(WidgetTester tester) async {
  await _ownerTool(tester, _en.groupsEditGroup);
  expect(
    find.descendant(of: _sheet, matching: find.text(_en.groupsEditGroup)),
    findsOneWidget,
  );
}

List<QaCall> _patches(GroupsWorld w) =>
    w.api.sent('PATCH', '/engagement/groups/g1');

Future<Map<String, dynamic>> _saveBody(
  WidgetTester tester,
  GroupsWorld w,
) async {
  await qaTap(tester, _save);
  return _patches(w).last.body;
}

// ------------------------------------------------------------------- members

Future<void> _openMembers(WidgetTester tester, String label) async {
  await qaTap(
    tester,
    label == _en.groupsSeeAll
        ? _button<TextButton>(label)
        : _button<OutlinedButton>(label),
  );
  expect(find.byType(GroupMembersSheet), findsOneWidget);
}

Finder _memberTile(String name) =>
    find.descendant(of: _sheet, matching: find.widgetWithText(ListTile, name));

String _roleOf(WidgetTester tester, String name) =>
    (tester.widget<ListTile>(_memberTile(name)).subtitle! as Text).data!;

void main() {
  group('owner tools', () {
    testWidgets(
      'Owner tools lists edit, cover and delete; Edit group opens the edit '
      'sheet and Add cover photo opens the photo choice '
      '[case:groups.group_detail.owner_tools.action]',
      (tester) async {
        final world = _world(role: 'owner');
        await _open(tester, world, picker: QaCoverPicker());
        expect(find.byTooltip(_en.groupsMoreOptions), findsNothing);
        await qaTap(tester, find.byTooltip(_en.groupsOwnerTools));
        expect(find.text(_en.groupsEditGroup), findsOneWidget);
        expect(find.text(_en.groupsDeleteGroup), findsOneWidget);
        expect(find.text(_en.groupsRemoveCoverPhoto), findsNothing);
        await qaTap(tester, find.text(_en.groupsEditGroup));
        expect(_nameField, findsOneWidget);
        expect(_text(tester, _nameField), 'Koramangala readers');
        await qaTap(tester, qaKey('qa.sheet.close'));
        expect(_sheet, findsNothing);

        await _ownerTool(tester, _en.groupsAddCoverPhoto);
        expect(find.text(_en.groupsCoverSheetTitle), findsOneWidget);
        expect(world.api.writes, isEmpty);
      },
    );

    testWidgets(
      'Owner tools > Delete group asks first, deletes the group and closes it '
      '[case:groups.group_detail.owner_tools.action]',
      (tester) async {
        final world = _world(role: 'owner');
        final results = await _open(tester, world);
        await _ownerTool(tester, _en.groupsDeleteGroup);
        expect(
          find.text(_en.groupsDeleteTitle('Koramangala readers')),
          findsOneWidget,
        );
        expect(find.text(_en.groupsDeleteBody), findsOneWidget);

        // Cancel keeps it.
        await qaTap(
          tester,
          find.descendant(of: _dialog, matching: find.text(_en.commonCancel)),
        );
        expect(world.api.writes, isEmpty);

        await _ownerTool(tester, _en.groupsDeleteGroup);
        await qaTap(tester, _confirm(_en.groupsDeleteGroup));
        expect(world.api.writeLines, ['DELETE /engagement/groups/g1']);
        expect(world.groups.containsKey('g1'), isFalse);
        expect(_detail, findsNothing);
        expect(results, [null]);
      },
    );

    testWidgets(
      'Owner tools > Remove cover photo asks first and removes the photo '
      '[case:groups.group_detail.owner_tools.action]',
      (tester) async {
        final world = _world(role: 'owner', coverStatus: 'approved');
        await _open(tester, world);
        await _ownerTool(tester, _en.groupsRemoveCoverPhoto);
        await qaTap(tester, _confirm(_en.groupsRemove));
        expect(world.api.writeLines, ['DELETE /engagement/groups/g1/cover']);
        expect(qaSnackText(tester), _en.groupsCoverRemoved);
        expect(qaKey('groups.detail.cover'), findsNothing);
      },
    );

    testWidgets(
      'a refused or offline delete says why, keeps the group open with the '
      'menu usable, and a retry deletes once '
      '[case:groups.group_detail.owner_tools.api_failure]',
      (tester) async {
        final world = _world(role: 'owner');
        final results = await _open(tester, world);
        world.api.fail(
          'DELETE /engagement/groups/*',
          status: 409,
          message: 'Hand the group over before deleting it.',
        );
        await _ownerTool(tester, _en.groupsDeleteGroup);
        await qaTap(tester, _confirm(_en.groupsDeleteGroup));
        expect(qaSnackText(tester), 'Hand the group over before deleting it.');
        expect(_detail, findsOneWidget);
        expect(find.text(_en.groupsWhosHere), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsNothing);
        expect(
          tester
              .widget<PopupMenuButton<String>>(
                find.byType(PopupMenuButton<String>),
              )
              .enabled,
          isTrue,
        );

        world.api.offline('DELETE /engagement/groups/*');
        await qaSnackGone(tester);
        await _ownerTool(tester, _en.groupsDeleteGroup);
        await qaTap(tester, _confirm(_en.groupsDeleteGroup));
        expect(qaSnackText(tester), _en.networkOfflineTryAgain);
        expect(_detail, findsOneWidget);

        world.heal('DELETE /engagement/groups/*');
        await qaSnackGone(tester);
        await _ownerTool(tester, _en.groupsDeleteGroup);
        await qaTap(tester, _confirm(_en.groupsDeleteGroup));
        expect(world.api.sent('DELETE', '/engagement/groups/g1'), hasLength(3));
        expect(_detail, findsNothing);
        expect(results, [null]);
      },
    );
  });

  group('edit sheet', () {
    testWidgets(
      'Save changes sends every field, closes the sheet and the page shows '
      'the saved group [case:groups.group_detail.save_changes.action]',
      (tester) async {
        final world = _world(role: 'owner');
        await _open(tester, world);
        await _openEdit(tester);
        final loads = world.api.sent('GET', '/engagement/groups/g1').length;
        await tester.enterText(_nameField, 'Indiranagar readers');
        await tester.enterText(_cityField, 'Mysuru');
        final body = await _saveBody(tester, world);
        expect(body, {
          'name': 'Indiranagar readers',
          'description': 'One book a month, long talks after.',
          'city': 'Mysuru',
          'cover_color': 'primary',
          'category_slug': 'books',
        });
        expect(_sheet, findsNothing);
        expect(
          world.api.sent('GET', '/engagement/groups/g1').length,
          greaterThan(loads),
          reason: 'the page reloads the saved group',
        );
        expect(find.text('Indiranagar readers'), findsOneWidget);
        expect(find.text('Mysuru'), findsOneWidget);
      },
    );

    testWidgets(
      'the group name typed is saved trimmed and becomes the page title '
      '[case:groups.group_detail.group_name_input.action]',
      (tester) async {
        final world = _world(role: 'owner');
        await _open(tester, world);
        await _openEdit(tester);
        await tester.enterText(_nameField, '  Night owls book club ');
        final body = await _saveBody(tester, world);
        expect(body['name'], 'Night owls book club');
        expect(_g(world)['name'], 'Night owls book club');
        expect(find.text('Night owls book club'), findsOneWidget);
        expect(find.text('Koramangala readers'), findsNothing);
      },
    );

    testWidgets(
      'the group name needs 3 letters after trimming (nothing is sent until '
      'then), stops at 60 characters and keeps emoji and right-to-left text '
      '[case:groups.group_detail.group_name_input.validation]',
      (tester) async {
        final world = _world(role: 'owner');
        await _open(tester, world);
        await _openEdit(tester);
        for (final bad in ['', '    ', ' ab ']) {
          await tester.enterText(_nameField, bad);
          await qaTap(tester, _save);
          expect(
            find.text(_en.groupsCreateNameTooShort),
            findsOneWidget,
            reason: '"$bad"',
          );
          expect(_patches(world), isEmpty, reason: '"$bad" is not sent');
          expect(_sheet, findsOneWidget, reason: 'the sheet stays open');
        }
        expect(tester.widget<TextField>(_nameField).maxLength, 60);
        await tester.enterText(_nameField, 'n' * 90);
        await tester.pump();
        expect(_text(tester, _nameField), hasLength(60));

        const rtl = 'نادي الكتاب 📚 ليلاً';
        await tester.enterText(_nameField, rtl);
        final body = await _saveBody(tester, world);
        expect(body['name'], rtl);
        expect(find.text(rtl), findsOneWidget);
      },
    );

    testWidgets(
      'what the group is about is saved trimmed and shown on the page '
      '[case:groups.group_detail.what_is_it_about_input.action]',
      (tester) async {
        final world = _world(role: 'owner');
        await _open(tester, world);
        await _openEdit(tester);
        expect(
          _text(tester, _aboutField),
          'One book a month, long talks after.',
        );
        await tester.enterText(_aboutField, '  Two books a month now.  ');
        final body = await _saveBody(tester, world);
        expect(body['description'], 'Two books a month now.');
        expect(find.text('Two books a month now.'), findsOneWidget);
      },
    );

    testWidgets(
      'what it is about may be cleared (whitespace saves ""), stops at 500 '
      'characters and keeps emoji and right-to-left text '
      '[case:groups.group_detail.what_is_it_about_input.validation]',
      (tester) async {
        final world = _world(role: 'owner');
        await _open(tester, world);
        await _openEdit(tester);
        expect(tester.widget<TextField>(_aboutField).maxLength, 500);
        await tester.enterText(_aboutField, 'w' * 600);
        await tester.pump();
        expect(_text(tester, _aboutField), hasLength(500));
        await tester.enterText(_aboutField, '   ');
        var body = await _saveBody(tester, world);
        expect(body['description'], '');
        expect(find.text('One book a month, long talks after.'), findsNothing);

        await _openEdit(tester);
        const rtl = 'نقرأ معاً 📖 كل شهر';
        await tester.enterText(_aboutField, rtl);
        body = await _saveBody(tester, world);
        expect(body['description'], rtl);
        expect(find.text(rtl), findsOneWidget);
      },
    );

    testWidgets('the city typed is saved trimmed and shown as a pill '
        '[case:groups.group_detail.city_optional_input.action]', (
      tester,
    ) async {
      final world = _world(role: 'owner');
      await _open(tester, world);
      await _openEdit(tester);
      expect(_text(tester, _cityField), 'Bengaluru');
      await tester.enterText(_cityField, ' Chennai  ');
      final body = await _saveBody(tester, world);
      expect(body['city'], 'Chennai');
      expect(find.widgetWithText(GroupPill, 'Chennai'), findsOneWidget);
      expect(find.text('Bengaluru'), findsNothing);
    });

    testWidgets(
      'the city may be cleared (whitespace saves "" and the pill goes), stops '
      'at 60 characters and keeps emoji and right-to-left text '
      '[case:groups.group_detail.city_optional_input.validation]',
      (tester) async {
        final world = _world(role: 'owner');
        await _open(tester, world);
        await _openEdit(tester);
        expect(tester.widget<TextField>(_cityField).maxLength, 60);
        await tester.enterText(_cityField, 'c' * 70);
        await tester.pump();
        expect(_text(tester, _cityField), hasLength(60));
        await tester.enterText(_cityField, '   ');
        var body = await _saveBody(tester, world);
        expect(body['city'], '');
        expect(find.text('Bengaluru'), findsNothing);

        await _openEdit(tester);
        const rtl = 'الرياض 🌴';
        await tester.enterText(_cityField, rtl);
        body = await _saveBody(tester, world);
        expect(body['city'], rtl);
        expect(find.widgetWithText(GroupPill, rtl), findsOneWidget);
      },
    );

    testWidgets(
      'a cover colour chip selects that colour and the save carries it '
      '[case:groups.group_detail.choicechip_onselected.action]',
      (tester) async {
        final world = _world(role: 'owner');
        await _open(tester, world);
        await _openEdit(tester);
        bool selected(String l) =>
            tester.widget<ChoiceChip>(_sheetChip(l)).selected;
        expect(selected(_en.groupsCoverColorTheme), isTrue);
        await qaTap(tester, _sheetChip(_en.groupsCoverColorAccent));
        expect(selected(_en.groupsCoverColorAccent), isTrue);
        expect(selected(_en.groupsCoverColorTheme), isFalse);
        final body = await _saveBody(tester, world);
        expect(body['cover_color'], 'secondary');
        expect(
          tester.widget<GroupCover>(find.byType(GroupCover)).color,
          'secondary',
        );
      },
    );

    testWidgets(
      'a lifestyle chip moves the community to that lifestyle on save '
      '[case:groups.group_detail.c_emoji_c_title.action]',
      (tester) async {
        final world = _world(role: 'owner');
        await _open(tester, world);
        expect(find.text('📚 Books'), findsOneWidget);
        await _openEdit(tester);
        expect(
          find.descendant(
            of: _sheet,
            matching: find.text(_en.groupsLifestyleLabel),
          ),
          findsOneWidget,
        );
        bool selected(String l) =>
            tester.widget<ChoiceChip>(_sheetChip(l)).selected;
        expect(selected('📚  Books'), isTrue);
        await qaTap(tester, _sheetChip('🎶  Music'));
        expect(selected('🎶  Music'), isTrue);
        expect(selected('📚  Books'), isFalse);
        final body = await _saveBody(tester, world);
        expect(body['category_slug'], 'music');
        expect(find.text('🎶 Music'), findsOneWidget);
        expect(find.text('📚 Books'), findsNothing);
      },
    );
  });

  group('cover', () {
    testWidgets(
      'Add cover photo picks, previews and uploads the photo, then shows it '
      'under review [case:groups.group_detail.groups_cover_change.action]',
      (tester) async {
        final world = _world(role: 'owner');
        final picker = QaCoverPicker(qaCoverFile('reading-nook.png'));
        await _open(tester, world, picker: picker);
        expect(find.text(_en.groupsAddCoverPhoto), findsOneWidget);
        await qaTap(tester, qaKey('groups.cover.change'));
        await qaTap(tester, qaKey('groups.cover.gallery'));
        await qaTap(tester, qaKey('groups.cover.confirm'));
        expect(picker.sources, [ImageSource.gallery]);

        final put = world.api.sent('PUT', '/engagement/groups/g1/cover');
        expect(put, hasLength(1));
        final form = qaCoverForm(put.single);
        expect(form.filename, 'reading-nook.png');
        expect(form.bytes, qaPng.length);
        expect(form.coverId, isNotEmpty);
        expect(qaSnackText(tester), _en.groupsCoverUploadedReview);
        expect(qaKey('groups.cover.review'), findsOneWidget);
        expect(find.text(_en.groupsChangeCover), findsOneWidget);
      },
    );

    testWidgets(
      'Remove cover asks first, removes the photo and the emoji cover is back '
      '[case:groups.group_detail.groups_cover_remove_removecover.action]',
      (tester) async {
        final world = _world(role: 'owner', coverStatus: 'approved');
        await _open(tester, world);
        expect(qaKey('groups.detail.cover'), findsOneWidget);
        await qaTap(tester, qaKey('groups.cover.remove'));
        expect(find.text(_en.groupsRemoveCoverTitle), findsOneWidget);
        expect(
          find.text(_en.groupsRemoveCoverBody('Koramangala readers')),
          findsOneWidget,
        );
        await qaTap(tester, _confirm(_en.groupsRemove));
        expect(world.api.writeLines, ['DELETE /engagement/groups/g1/cover']);
        expect(qaSnackText(tester), _en.groupsCoverRemoved);
        expect(qaKey('groups.detail.cover'), findsNothing);
        expect(qaKey('groups.cover.remove'), findsNothing);
        expect(find.byType(GroupCover), findsOneWidget);
      },
    );
  });

  group('members', () {
    testWidgets('Members opens the member list with everyone and their role '
        '[case:groups.group_detail.members_2.action]', (tester) async {
      final world = _world();
      await _open(tester, world);
      await _openMembers(tester, _en.groupsMembers);
      expect(
        world.api.sent('GET', '/engagement/groups/g1/members'),
        hasLength(1),
      );
      expect(_memberTile(_en.groupsMemberYou('Priya')), findsOneWidget);
      expect(_roleOf(tester, 'Asha'), _en.groupsRoleModerator);
      expect(_roleOf(tester, 'Dev'), _en.groupsRoleMember);
      // A plain member manages nobody; Add friend is offered.
      expect(find.byTooltip(_en.groupsMemberOptions('Dev')), findsNothing);
      expect(qaKey('qa.add_friend.dev'), findsOneWidget);
    });

    testWidgets('See all opens the same member list '
        '[case:groups.group_detail.see_all.action]', (tester) async {
      final world = _world();
      await _open(tester, world);
      expect(find.text(_en.groupsWhosHere), findsOneWidget);
      await _openMembers(tester, _en.groupsSeeAll);
      expect(
        world.api.sent('GET', '/engagement/groups/g1/members'),
        hasLength(1),
      );
      expect(
        find.descendant(of: _sheet, matching: find.text('Koramangala readers')),
        findsOneWidget,
      );
      expect(_memberTile('Asha'), findsOneWidget);
      expect(_memberTile('Dev'), findsOneWidget);
    });

    testWidgets('in a removed group Members still opens the member list '
        '[case:groups.group_detail.members.action]', (tester) async {
      final world = _world();
      _g(world)['removed'] = true;
      await _open(tester, world);
      expect(qaKey('groups.detail.removed'), findsOneWidget);
      expect(find.text(_en.groupsChatButton), findsNothing);
      await _openMembers(tester, _en.groupsMembers);
      expect(
        world.api.sent('GET', '/engagement/groups/g1/members'),
        hasLength(1),
      );
      expect(_roleOf(tester, 'Asha'), _en.groupsRoleModerator);
      expect(_memberTile('Dev'), findsOneWidget);
    });

    testWidgets(
      "a member's options let the owner promote, demote and remove them, "
      'and the list follows [case:groups.group_detail.options_for_name.action]',
      (tester) async {
        final world = _world(role: 'owner');
        await _open(tester, world);
        await _openMembers(tester, _en.groupsMembers);

        await qaTap(tester, find.byTooltip(_en.groupsMemberOptions('Dev')));
        expect(find.text(_en.groupsMakeModerator), findsOneWidget);
        expect(find.text(_en.groupsRemoveFromGroup), findsOneWidget);
        await qaTap(tester, find.text(_en.groupsMakeModerator));
        var write = world.api.sent('POST', '/engagement/groups/g1/members/dev');
        expect(write.single.body, {'action': 'make_moderator'});
        expect(_roleOf(tester, 'Dev'), _en.groupsRoleModerator);

        await qaTap(tester, find.byTooltip(_en.groupsMemberOptions('Asha')));
        await qaTap(tester, find.text(_en.groupsMakeMember));
        write = world.api.sent('POST', '/engagement/groups/g1/members/asha');
        expect(write.single.body, {'action': 'make_member'});
        expect(_roleOf(tester, 'Asha'), _en.groupsRoleMember);

        await qaTap(tester, find.byTooltip(_en.groupsMemberOptions('Dev')));
        await qaTap(tester, find.text(_en.groupsRemoveFromGroup));
        expect(find.text(_en.groupsRemoveMemberTitle('Dev')), findsOneWidget);
        expect(find.text(_en.groupsRemoveMemberBodyCommunity), findsOneWidget);
        await qaTap(tester, _confirm(_en.groupsRemove));
        write = world.api.sent('POST', '/engagement/groups/g1/members/dev');
        expect(write.last.body, {'action': 'remove'});
        expect(_memberTile('Dev'), findsNothing);
        expect(_memberTile('Asha'), findsOneWidget);
      },
    );

    testWidgets(
      'a refused member change says why, leaves the member as they were and '
      'the options work again '
      '[case:groups.group_detail.options_for_name.api_failure]',
      (tester) async {
        final world = _world(role: 'owner');
        await _open(tester, world);
        await _openMembers(tester, _en.groupsMembers);
        world.api.fail(
          'POST /engagement/groups/*/members/*',
          status: 403,
          message: 'Only the owner can do that.',
        );
        await qaTap(tester, find.byTooltip(_en.groupsMemberOptions('Dev')));
        await qaTap(tester, find.text(_en.groupsMakeModerator));
        expect(qaSnackText(tester), 'Only the owner can do that.');
        expect(_roleOf(tester, 'Dev'), _en.groupsRoleMember);
        final menu = find.byWidgetPredicate(
          (w) =>
              w is PopupMenuButton<String> &&
              w.tooltip == _en.groupsMemberOptions('Dev'),
        );
        expect(tester.widget<PopupMenuButton<String>>(menu).enabled, isTrue);

        // A 500 without a message: the sheet's own words.
        world.api.on(
          'POST /engagement/groups/*/members/*',
          (_) => const QaReply(500, null),
        );
        await qaSnackGone(tester);
        await qaTap(tester, find.byTooltip(_en.groupsMemberOptions('Dev')));
        await qaTap(tester, find.text(_en.groupsMakeModerator));
        expect(qaSnackText(tester), _en.groupsChangeFailed);

        world.heal('POST /engagement/groups/*/members/*');
        await qaSnackGone(tester);
        await qaTap(tester, find.byTooltip(_en.groupsMemberOptions('Dev')));
        await qaTap(tester, find.text(_en.groupsMakeModerator));
        expect(
          world.api.sent('POST', '/engagement/groups/g1/members/dev'),
          hasLength(3),
        );
        expect(_roleOf(tester, 'Dev'), _en.groupsRoleModerator);
      },
    );
  });

  group('invitation', () {
    GroupsWorld invited() {
      final w = GroupsWorld();
      w.groups['p1'] = qaGroup(
        id: 'p1',
        kind: 'private',
        name: 'Trek planners',
        inviteId: 'inv-1',
        memberCount: 4,
      );
      return w;
    }

    testWidgets(
      'Decline answers the invitation, says so, and the group is invitation '
      'only again [case:groups.group_detail.decline_onrespond.action]',
      (tester) async {
        final world = invited();
        await _open(tester, world, id: 'p1');
        expect(
          find.text(_en.groupsInvitedToJoin('Trek planners')),
          findsOneWidget,
        );
        await qaTap(tester, _button<OutlinedButton>(_en.groupsDecline));
        expect(world.api.writeLines, [
          'POST /engagement/groups/p1/invites/respond',
        ]);
        expect(world.api.writes.single.body, {'decision': 'decline'});
        expect(qaSnackText(tester), _en.groupsInvitationDeclined);
        expect(
          find.text(_en.groupsInvitedToJoin('Trek planners')),
          findsNothing,
        );
        expect(find.text(_en.groupsInvitationOnly), findsOneWidget);
      },
    );

    testWidgets(
      'a refused Decline says why, keeps the invitation with both answers '
      'usable, and the retry goes through once '
      '[case:groups.group_detail.decline_onrespond.api_failure]',
      (tester) async {
        final world = invited();
        await _open(tester, world, id: 'p1');
        world.api.fail(
          'POST /engagement/groups/*/invites/respond',
          status: 409,
          message: 'This invitation was withdrawn.',
        );
        await qaTap(tester, _button<OutlinedButton>(_en.groupsDecline));
        expect(qaSnackText(tester), 'This invitation was withdrawn.');
        expect(
          find.text(_en.groupsInvitedToJoin('Trek planners')),
          findsOneWidget,
        );
        expect(
          tester
              .widget<OutlinedButton>(
                _button<OutlinedButton>(_en.groupsDecline),
              )
              .onPressed,
          isNotNull,
        );
        expect(
          tester
              .widget<FilledButton>(_button<FilledButton>(_en.groupsJoinGroup))
              .onPressed,
          isNotNull,
        );

        world.api.offline('POST /engagement/groups/*/invites/respond');
        await qaSnackGone(tester);
        await qaTap(tester, _button<OutlinedButton>(_en.groupsDecline));
        expect(qaSnackText(tester), _en.networkOfflineTryAgain);

        world.heal('POST /engagement/groups/*/invites/respond');
        await qaSnackGone(tester);
        await qaTap(tester, _button<OutlinedButton>(_en.groupsDecline));
        expect(
          world.api.sent('POST', '/engagement/groups/p1/invites/respond'),
          hasLength(3),
        );
        expect(find.text(_en.groupsInvitationOnly), findsOneWidget);
      },
    );
  });

  testWidgets(
    'Join group joins the community, welcomes me and opens the member view '
    '[case:groups.group_detail.join_group.action]',
    (tester) async {
      final world = _world(role: '');
      await _open(tester, world);
      expect(find.text(_en.groupsJoinHint), findsOneWidget);
      await qaTap(tester, _button<FilledButton>(_en.groupsJoinGroup));
      expect(world.api.writeLines, ['POST /engagement/groups/g1/join']);
      expect(world.api.writes.single.data, isNull);
      expect(qaSnackText(tester), _en.groupsWelcome('Koramangala readers'));
      expect(find.text(_en.groupsJoinGroup), findsNothing);
      expect(find.text(_en.groupsChatButton), findsOneWidget);
      expect(find.text('4 members'), findsOneWidget);
    },
  );

  testWidgets(
    'Leave asks first with the community wording, leaves and closes the group '
    '[case:groups.group_detail.leave_onleave.action]',
    (tester) async {
      final world = _world();
      final results = await _open(tester, world);
      await qaTap(tester, _button<TextButton>(_en.groupsLeave));
      expect(
        find.text(_en.groupsLeaveTitle('Koramangala readers')),
        findsOneWidget,
      );
      expect(find.text(_en.groupsLeaveBodyCommunity), findsOneWidget);
      // It re-read the group before warning.
      expect(
        world.api.sent('GET', '/engagement/groups/g1').length,
        greaterThanOrEqualTo(2),
      );
      await qaTap(tester, _confirm(_en.groupsLeave));
      expect(world.api.writeLines, ['POST /engagement/groups/g1/leave']);
      expect(_g(world)['my_role'], '');
      expect(_detail, findsNothing);
      expect(results, [null]);
    },
  );

  group('chat', () {
    testWidgets('Group chat opens the group conversation titled with the group '
        '[case:groups.group_detail.group_chat.action]', (tester) async {
      final world = _world();
      await _open(tester, world);
      await qaTap(tester, _button<FilledButton>(_en.groupsChatButton));
      final chat = tester.widget<SocialChatScreen>(
        find.byType(SocialChatScreen),
      );
      expect(chat.channelId, 'ch-g1');
      expect(chat.title, 'Koramangala readers');
      expect(chat.subtitle, 'Community group · 3 members');
      expect(
        world.api.sent('GET', '/social/channels/ch-g1/messages'),
        isNotEmpty,
      );
      expect(find.text('Who is bringing snacks?'), findsOneWidget);
      await qaTeardown(tester);
    });

    testWidgets(
      'tapping a sender in the group chat opens their card, and Add friend '
      'sends a request that started in a group '
      '[case:groups.group_detail.social_message_x_sendertap.action]',
      (tester) async {
        final world = _world();
        await _open(tester, world);
        await qaTap(tester, _button<FilledButton>(_en.groupsChatButton));
        expect(find.text('Who is bringing snacks?'), findsOneWidget);

        await qaTap(tester, find.text('Asha').last);
        expect(_sheet, findsOneWidget);
        expect(
          find.descendant(of: _sheet, matching: find.text('Asha')),
          findsOneWidget,
        );
        final add = qaKey('qa.add_friend.asha');
        expect(add, findsOneWidget);
        expect(world.api.sent('POST', '/friends/me'), isEmpty);

        await qaTap(tester, add);
        expect(world.api.sent('POST', '/friends/me').single.body, {
          'friend_user_id': 'asha',
          'source': 'group',
        });
        expect(qaSnackText(tester), _en.friendsRequestSentTo('Asha'));
        await qaTeardown(tester);
      },
    );
  });

  testWidgets(
    'Invite friends opens the picker for this group and sends invitations to '
    'the friends chosen [case:groups.group_detail.invite_friends.action]',
    (tester) async {
      final world = _world();
      await _open(tester, world);
      await qaTap(tester, _button<OutlinedButton>(_en.groupsInviteFriends));
      expect(find.byType(GroupFriendPicker), findsOneWidget);
      expect(
        find.text(_en.groupsInviteFriendsTo('Koramangala readers')),
        findsOneWidget,
      );
      expect(world.api.sent('GET', '/engagement/group-friends').single.query, {
        'group_id': 'g1',
      });
      await qaTap(tester, find.widgetWithText(CheckboxListTile, 'Dev'));
      await qaTap(tester, find.widgetWithText(CheckboxListTile, 'Kabir'));
      await qaTap(tester, find.text('${_en.groupsSendInvitations} (2)'));

      final invite = world.api.sent('POST', '/engagement/groups/g1/invites');
      expect(invite.single.body, {
        'invitee_user_ids': ['dev', 'kabir'],
      });
      expect(qaSnackText(tester), _en.groupsInvitationsSent(2));
      expect(find.byType(GroupFriendPicker), findsNothing);
    },
  );

  group('More options', () {
    testWidgets(
      'More options > Report group files a report on this group and thanks '
      'the member [case:groups.group_detail.groups_detail_more.action]',
      (tester) async {
        final world = _world(role: '');
        await _open(tester, world);
        expect(find.byTooltip(_en.groupsOwnerTools), findsNothing);
        await qaTap(tester, qaKey('groups.detail.more'));
        await qaTap(tester, find.text(_en.groupsReportGroup));
        await tester.enterText(
          find.widgetWithText(TextField, _en.reportDescriptionLabel),
          'Spam links in the description.',
        );
        await qaTap(tester, find.text(_en.reportSubmit));
        expect(world.api.sent('POST', '/blog/reports/group/g1').single.body, {
          'reason': 'inappropriate',
          'description': 'Spam links in the description.',
        });
        expect(qaSnackText(tester), _en.communityReportSubmitted);
        expect(find.text(_en.reportSubmit), findsNothing);
      },
    );

    testWidgets(
      'a report that fails says so, keeps the sheet with what was typed, and '
      'a retry files it '
      '[case:groups.group_detail.groups_detail_more.api_failure]',
      (tester) async {
        final world = _world(role: '');
        await _open(tester, world);
        world.api.fail(
          'POST /blog/reports/group/*',
          message: 'Reports paused.',
        );
        await qaTap(tester, qaKey('groups.detail.more'));
        await qaTap(tester, find.text(_en.groupsReportGroup));
        final description = find.widgetWithText(
          TextField,
          _en.reportDescriptionLabel,
        );
        await tester.enterText(description, 'Spam links.');
        await qaTap(tester, find.text(_en.reportSubmit));
        expect(qaSnackText(tester), _en.reportSubmitFailed);
        expect(find.text(_en.reportSubmit), findsOneWidget);
        expect(
          tester.widget<TextField>(description).controller!.text,
          'Spam links.',
        );

        world.heal('POST /blog/reports/group/*');
        await qaSnackGone(tester);
        await qaTap(tester, find.text(_en.reportSubmit));
        expect(world.api.sent('POST', '/blog/reports/group/g1'), hasLength(2));
        expect(world.api.sent('POST', '/blog/reports/group/g1').last.body, {
          'reason': 'inappropriate',
          'description': 'Spam links.',
        });
        expect(qaSnackText(tester), _en.communityReportSubmitted);
        expect(_detail, findsOneWidget);
      },
    );
  });

  testWidgets('pull to refresh reloads the group and shows what changed '
      '[case:groups.group_detail.invitation_declined_onrefresh.action]', (
    tester,
  ) async {
    final world = _world();
    await _open(tester, world);
    final loads = world.api.sent('GET', '/engagement/groups/g1').length;
    _g(world)
      ..['description'] = 'Now meeting on Sundays.'
      ..['member_count'] = 5;
    await tester.fling(
      find.text('Koramangala readers').first,
      const Offset(0, 700),
      1500,
    );
    await tester.pumpAndSettle();
    await qaSettleRequests(tester);
    expect(
      world.api.sent('GET', '/engagement/groups/g1').length,
      greaterThan(loads),
    );
    expect(find.text('Now meeting on Sundays.'), findsOneWidget);
    expect(find.text('5 members'), findsOneWidget);
    expect(world.api.writes, isEmpty);
  });

  testWidgets(
    'a group that cannot load says it is unavailable with the reason, and '
    'Try again loads it '
    '[case:groups.group_detail.this_group_is_unavailable_onaction.action]',
    (tester) async {
      final world = _world();
      world.api.fail(
        'GET /engagement/groups/*',
        status: 404,
        message: 'Group not found.',
      );
      await _open(tester, world);
      expect(find.text(_en.groupsUnavailableTitle), findsOneWidget);
      expect(find.text('Group not found.'), findsOneWidget);
      expect(find.text(_en.groupsChatButton), findsNothing);
      final loads = world.api.sent('GET', '/engagement/groups/g1').length;

      world.heal('GET /engagement/groups/*');
      await qaTap(tester, _button<OutlinedButton>(_en.chatTryAgain));
      expect(world.api.sent('GET', '/engagement/groups/g1').length, loads + 1);
      expect(find.text(_en.groupsUnavailableTitle), findsNothing);
      expect(find.text('Koramangala readers'), findsOneWidget);
      expect(find.text(_en.groupsChatButton), findsOneWidget);
    },
  );

  testWidgets(
    'a group renders translated in every locale with nothing left in English '
    '[case:groups.group_detail.l10n]',
    (tester) async {
      final world = _world(role: 'owner', coverStatus: 'pending');
      _g(world)['unread_count'] = 2;
      await qaExpectRendersInAllLocales(
        tester,
        world.api,
        () => const GroupDetailScreen(groupId: 'g1'),
        expected: [
          (l) => l.groupsKindCommunity.toUpperCase(),
          (l) => l.groupsOpenToAll,
          (l) => l.groupsYouRunIt,
          (l) => l.groupsCoverUnderReview,
          (l) => l.groupsCoverNotePending,
          (l) => l.groupsChangeCover,
          (l) => l.groupsRemoveCover,
          (l) => l.groupsChatButtonUnread(2),
          (l) => l.groupsInviteFriends,
          (l) => l.groupsMembers,
          (l) => l.groupsLeave,
          (l) => l.groupsWhosHere,
          (l) => l.groupsSeeAll,
          (l) => l.groupsYou,
        ],
        // Fixture data: the group's name, description, city, the server's
        // lifestyle title and a member's name.
        allow: {
          'Koramangala readers',
          'One book a month, long talks after.',
          'Bengaluru',
          '📚 Books',
          'Asha',
        },
      );
    },
  );
}
