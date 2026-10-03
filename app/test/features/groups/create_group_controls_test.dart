import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:verified_dating_app/features/groups/create_group_screen.dart';
import 'package:verified_dating_app/features/groups/friend_picker.dart';
import 'package:verified_dating_app/features/groups/group_detail_screen.dart';
import 'package:verified_dating_app/features/groups/group_launch.dart';
import 'package:verified_dating_app/features/groups/group_widgets.dart';

import '../../support/qa_api.dart';
import '../../support/qa_screen_checks.dart';
import 'groups_world.dart';

// Start a group: each control is used the way a member would and the test
// asserts what the server receives on Create group (the exact body), what
// the screen shows and where the member lands — and, for the create
// request, what happens when the server refuses or the device is offline.

final _en = qaL10n(const Locale('en'));

/// Starting a group from scratch: every friend can be invited.
GroupsWorld _world() {
  final w = GroupsWorld();
  for (final f in w.friends) {
    f['status'] = 'available';
  }
  return w;
}

const _asha = (userId: 'asha', name: 'Asha', photoUrl: '');

Future<List<Object?>> _open(
  WidgetTester tester,
  GroupsWorld world, {
  List<GroupInvitee> invitees = const [],
  String? kind,
  String category = '',
  QaCoverPicker? picker,
  bool launcher = false,
}) => pumpQa(
  tester,
  world.api,
  CreateGroupScreen(
    invitees: invitees,
    initialKind: kind,
    initialCategory: category,
  ),
  size: const Size(430, 3000),
  launcher: launcher,
  extra: [if (picker != null) qaPickerOverride(picker)],
);

Finder _field(String label) => find.widgetWithText(TextField, label);
Finder get _name => _field(_en.groupsNameLabel);
Finder get _about => _field(_en.groupsAboutOptionalLabel);
Finder get _city => _field(_en.groupsCityLabel);
Finder get _createButton =>
    find.widgetWithText(FilledButton, _en.groupsCreateGroup);
Finder _chip(String label) => find.widgetWithText(ChoiceChip, label);

String _text(WidgetTester tester, Finder field) =>
    tester.widget<TextField>(field).controller!.text;

bool _selected(WidgetTester tester, String chip) =>
    tester.widget<ChoiceChip>(_chip(chip)).selected;

GroupCover _cover(WidgetTester tester) =>
    tester.widget<GroupCover>(find.byType(GroupCover));

List<QaCall> _creates(GroupsWorld w) =>
    w.api.sent('POST', '/engagement/groups');

Future<void> _create(WidgetTester tester) => qaTap(tester, _createButton);

/// Names the group and creates it; returns the body the server received.
Future<Map<String, dynamic>> _nameAndCreate(
  WidgetTester tester,
  GroupsWorld world, [
  String name = 'Brunch crew',
]) async {
  await tester.enterText(_name, name);
  await _create(tester);
  return _creates(world).last.body;
}

/// Picks a cover photo through the sheet (gallery or camera) and confirms
/// the preview.
Future<void> _pickCover(WidgetTester tester, {bool camera = false}) async {
  await qaTap(tester, qaKey('groups.create.cover'));
  await qaTap(
    tester,
    qaKey(camera ? 'groups.cover.camera' : 'groups.cover.gallery'),
  );
  await qaTap(tester, qaKey('groups.cover.confirm'));
}

void main() {
  group('what kind', () {
    testWidgets(
      'Community group switches a friends-first group to a community: the '
      'lifestyle choice appears and the create carries kind and lifestyle '
      '[case:groups.create_group.community_group.action]',
      (tester) async {
        final world = _world();
        await _open(tester, world, invitees: [_asha]);
        // Friends preselected: it starts private, with no lifestyle step.
        expect(find.text(_en.groupsCreateLifestyleHeader), findsNothing);
        String? hint() => tester.widget<TextField>(_name).decoration!.hintText;
        expect(hint(), _en.groupsCreateNameHintPrivate);

        await qaTap(tester, find.text(_en.groupsKindCommunity));
        expect(find.text(_en.groupsCreateLifestyleHeader), findsOneWidget);
        expect(hint(), _en.groupsCreateNameHintCommunity);
        expect(_chip('📚  Books'), findsOneWidget);

        // A community needs a lifestyle: without one nothing is sent.
        await tester.enterText(_name, 'Readers club');
        await _create(tester);
        expect(find.text(_en.groupsCreatePickLifestyle), findsOneWidget);
        expect(_creates(world), isEmpty);

        await qaTap(tester, _chip('📚  Books'));
        await _create(tester);
        final body = _creates(world).single.body;
        expect(body['kind'], 'community');
        expect(body['category_slug'], 'books');
        expect(body['invitee_user_ids'], ['asha']);
        expect(find.byType(GroupDetailScreen), findsOneWidget);
      },
    );

    testWidgets(
      'Private group hides the lifestyle step and creates a private group '
      'with no lifestyle even when one had been picked '
      '[case:groups.create_group.private_group.action]',
      (tester) async {
        final world = _world();
        await _open(tester, world, category: 'music');
        expect(find.text(_en.groupsCreateLifestyleHeader), findsOneWidget);
        expect(_selected(tester, '🎶  Music'), isTrue);

        await qaTap(tester, find.text(_en.groupsKindPrivate));
        expect(find.text(_en.groupsCreateLifestyleHeader), findsNothing);
        expect(_chip('🎶  Music'), findsNothing);
        // The private group's emoji and name hint.
        expect(_cover(tester).emoji, '🫶');
        final hint = tester.widget<TextField>(_name).decoration!.hintText;
        expect(hint, _en.groupsCreateNameHintPrivate);

        final body = await _nameAndCreate(tester, world);
        expect(body['kind'], 'private');
        expect(body.containsKey('category_slug'), isFalse);
        expect(world.groups['new']!['kind'], 'private');
      },
    );
  });

  group('lifestyle', () {
    testWidgets(
      'a lifestyle chip selects that lifestyle, takes over the cover emoji '
      'and is what the group is created in '
      '[case:groups.create_group.c_emoji_c_title.action]',
      (tester) async {
        final world = _world();
        await _open(tester, world);
        expect(_selected(tester, '📚  Books'), isFalse);
        expect(_cover(tester).emoji, '✨');

        await qaTap(tester, _chip('📚  Books'));
        expect(_selected(tester, '📚  Books'), isTrue);
        expect(_cover(tester).emoji, '📚');

        // Picking another moves the selection (one lifestyle per group).
        await qaTap(tester, _chip('🎶  Music'));
        expect(_selected(tester, '🎶  Music'), isTrue);
        expect(_selected(tester, '📚  Books'), isFalse);
        expect(_cover(tester).emoji, '🎶');
        expect(
          find.bySemanticsLabel(_en.groupsCoverEmojiSemantics('🎶')),
          findsOneWidget,
        );

        final body = await _nameAndCreate(tester, world, 'Vinyl Sundays');
        expect(body['category_slug'], 'music');
        expect(body['kind'], 'community');
      },
    );

    testWidgets(
      'lifestyles that fail to load say so and Try again loads the chips '
      '[case:groups.create_group.lifestyles_could_not_load_onaction.action]',
      (tester) async {
        final world = _world();
        world.api.fail(
          'GET /engagement/group-categories',
          message: 'Lifestyles are resting.',
        );
        await _open(tester, world);
        expect(find.text(_en.groupsLifestylesFailed), findsOneWidget);
        expect(find.text('Lifestyles are resting.'), findsOneWidget);
        expect(_chip('📚  Books'), findsNothing);
        final before = world.api
            .sent('GET', '/engagement/group-categories')
            .length;

        world.api.on(
          'GET /engagement/group-categories',
          (_) => qaOk({'categories': world.categories}),
        );
        await qaTap(
          tester,
          find.widgetWithText(OutlinedButton, _en.chatTryAgain),
        );
        expect(
          world.api.sent('GET', '/engagement/group-categories').length,
          before + 1,
        );
        expect(find.text(_en.groupsLifestylesFailed), findsNothing);
        expect(_chip('📚  Books'), findsOneWidget);
        expect(_chip('🎶  Music'), findsOneWidget);
      },
    );
  });

  group('details', () {
    testWidgets(
      'the group name typed is sent trimmed and the new group opens under it '
      '[case:groups.create_group.the_sunday_brunch_crew_input.action]',
      (tester) async {
        final world = _world();
        await _open(tester, world, kind: 'private');
        final hint = tester.widget<TextField>(_name).decoration!.hintText;
        expect(hint, _en.groupsCreateNameHintPrivate);
        final body = await _nameAndCreate(tester, world, '  Brunch crew  ');
        expect(body['name'], 'Brunch crew');
        final detail = tester.widget<GroupDetailScreen>(
          find.byType(GroupDetailScreen),
        );
        expect(detail.groupId, 'new');
        expect(find.text('Brunch crew'), findsOneWidget);
      },
    );

    testWidgets(
      'the group name must have 3 letters after trimming, stops at 60 '
      'characters and keeps emoji and right-to-left text intact '
      '[case:groups.create_group.the_sunday_brunch_crew_input.validation]',
      (tester) async {
        final world = _world();
        await _open(tester, world, kind: 'private');
        for (final bad in ['', '     ', '  ab  ']) {
          await tester.enterText(_name, bad);
          await _create(tester);
          expect(
            find.text(_en.groupsCreateNameTooShort),
            findsOneWidget,
            reason: '"$bad"',
          );
          expect(_creates(world), isEmpty, reason: '"$bad" is not sent');
        }
        // The counter and the limit.
        expect(tester.widget<TextField>(_name).maxLength, 60);
        await tester.enterText(_name, 'x' * 75);
        await tester.pump();
        expect(_text(tester, _name), hasLength(60));
        expect(find.text('60/60'), findsOneWidget);

        const rtl = 'نادي القراءة 📚 كل أحد';
        final body = await _nameAndCreate(tester, world, rtl);
        expect(body['name'], rtl);
        expect(find.text(_en.groupsCreateNameTooShort), findsNothing);
      },
    );

    testWidgets('what the group is about is sent trimmed with the create '
        '[case:groups.create_group.what_is_it_about_optional_input.action]', (
      tester,
    ) async {
      final world = _world();
      await _open(tester, world, kind: 'private');
      await tester.enterText(_about, '  Pancakes, then a long walk.  ');
      final body = await _nameAndCreate(tester, world);
      expect(body['description'], 'Pancakes, then a long walk.');
      expect(world.groups['new']!['description'], body['description']);
      expect(find.text('Pancakes, then a long walk.'), findsOneWidget);
    });

    testWidgets(
      'what it is about is optional (empty and whitespace send ""), stops at '
      '500 characters and keeps emoji and right-to-left text intact '
      '[case:groups.create_group.what_is_it_about_optional_input.validation]',
      (tester) async {
        final world = _world();
        await _open(tester, world, kind: 'private');
        await tester.enterText(_about, '    ');
        var body = await _nameAndCreate(tester, world);
        expect(body['description'], '');

        await tester.pumpWidget(const SizedBox());
        final again = _world();
        await _open(tester, again, kind: 'private');
        expect(tester.widget<TextField>(_about).maxLength, 500);
        await tester.enterText(_about, 'y' * 520);
        await tester.pump();
        expect(_text(tester, _about), hasLength(500));
        expect(find.text('500/500'), findsOneWidget);
        const rtl = 'نلتقي كل أحد ☕️🥞 שלום';
        await tester.enterText(_about, rtl);
        body = await _nameAndCreate(tester, again);
        expect(body['description'], rtl);
      },
    );

    testWidgets('the city typed is sent trimmed with the create '
        '[case:groups.create_group.city_optional_input.action]', (
      tester,
    ) async {
      final world = _world();
      await _open(tester, world, kind: 'private');
      await tester.enterText(_city, '  Bengaluru ');
      final body = await _nameAndCreate(tester, world);
      expect(body['city'], 'Bengaluru');
      expect(world.groups['new']!['city'], 'Bengaluru');
      // The new group shows it.
      expect(find.text('Bengaluru'), findsOneWidget);
    });

    testWidgets(
      'the city is optional (whitespace sends ""), stops at 60 characters '
      'and keeps emoji and right-to-left text intact '
      '[case:groups.create_group.city_optional_input.validation]',
      (tester) async {
        final world = _world();
        await _open(tester, world, kind: 'private');
        await tester.enterText(_city, '   ');
        var body = await _nameAndCreate(tester, world);
        expect(body['city'], '');

        await tester.pumpWidget(const SizedBox());
        final again = _world();
        await _open(tester, again, kind: 'private');
        expect(tester.widget<TextField>(_city).maxLength, 60);
        await tester.enterText(_city, 'z' * 80);
        expect(_text(tester, _city), hasLength(60));
        const rtl = 'القاهرة 🌆';
        await tester.enterText(_city, rtl);
        body = await _nameAndCreate(tester, again);
        expect(body['city'], rtl);
      },
    );
  });

  group('cover', () {
    testWidgets(
      'a cover colour chip selects that colour, tints the preview and is sent '
      '[case:groups.create_group.choicechip_onselected.action]',
      (tester) async {
        final world = _world();
        await _open(tester, world, kind: 'private');
        expect(_selected(tester, _en.groupsCoverColorTheme), isTrue);
        expect(_cover(tester).color, 'primary');

        await qaTap(tester, _chip(_en.groupsCoverColorWarm));
        expect(_selected(tester, _en.groupsCoverColorWarm), isTrue);
        expect(_selected(tester, _en.groupsCoverColorTheme), isFalse);
        expect(_cover(tester).color, 'tertiary');

        await qaTap(tester, _chip(_en.groupsCoverColorAccent));
        expect(_cover(tester).color, 'secondary');
        final body = await _nameAndCreate(tester, world);
        expect(body['cover_color'], 'secondary');
      },
    );

    testWidgets(
      'a cover emoji tile chooses that emoji for the cover and it is sent '
      '[case:groups.create_group.cover_emoji_emoji.action]',
      (tester) async {
        final world = _world();
        await _open(tester, world, kind: 'private');
        expect(_cover(tester).emoji, '🫶');
        final tile = find.bySemanticsLabel(_en.groupsCoverEmojiSemantics('🌿'));
        expect(tile, findsOneWidget);
        expect(tester.getSemantics(tile), isSemantics(isSelected: false));

        await qaTap(tester, tile);
        expect(_cover(tester).emoji, '🌿');
        expect(tester.getSemantics(tile), isSemantics(isSelected: true));
        final body = await _nameAndCreate(tester, world);
        expect(body['cover_emoji'], '🌿');
        expect(world.groups['new']!['cover_emoji'], '🌿');
      },
    );

    testWidgets(
      'Change photo replaces the chosen cover with a new pick, and the new '
      'one is what gets uploaded to the created group '
      '[case:groups.create_group.groups_create_cover.action]',
      (tester) async {
        final world = _world();
        final picker = QaCoverPicker(qaCoverFile('first.png'));
        await _open(tester, world, kind: 'private', picker: picker);
        expect(find.text(_en.groupsCreateAddCoverPhoto), findsOneWidget);

        await _pickCover(tester);
        expect(qaKey('groups.create.coverPreview'), findsOneWidget);
        expect(find.text(_en.groupsCreateChangePhoto), findsOneWidget);
        expect(find.text(_en.groupsCreateAddCoverPhoto), findsNothing);

        picker.file = qaCoverFile('second.png');
        await _pickCover(tester, camera: true);
        expect(picker.sources, [ImageSource.gallery, ImageSource.camera]);
        expect(qaKey('groups.create.coverPreview'), findsOneWidget);
        // Nothing is uploaded before the group exists.
        expect(world.api.sent('PUT', '/engagement/groups/*/cover'), isEmpty);

        await _nameAndCreate(tester, world);
        final put = world.api.sent('PUT', '/engagement/groups/new/cover');
        expect(put, hasLength(1));
        expect(qaCoverForm(put.single).filename, 'second.png');
        expect(qaSnackText(tester), _en.groupsCoverUploadedReview);
        expect(find.byType(GroupDetailScreen), findsOneWidget);
      },
    );

    testWidgets(
      'Remove photo drops the chosen cover: the preview goes and the group '
      'is created without an upload '
      '[case:groups.create_group.remove_photo.action]',
      (tester) async {
        final world = _world();
        final picker = QaCoverPicker(qaCoverFile());
        await _open(tester, world, kind: 'private', picker: picker);
        await _pickCover(tester);
        expect(qaKey('groups.create.coverPreview'), findsOneWidget);

        await qaTap(
          tester,
          find.widgetWithText(TextButton, _en.groupsCreateRemovePhoto),
        );
        expect(qaKey('groups.create.coverPreview'), findsNothing);
        expect(find.text(_en.groupsCreateRemovePhoto), findsNothing);
        expect(find.text(_en.groupsCreateAddCoverPhoto), findsOneWidget);

        await _nameAndCreate(tester, world);
        expect(_creates(world), hasLength(1));
        expect(world.api.sent('PUT', '/engagement/groups/*/cover'), isEmpty);
        expect(find.byType(GroupDetailScreen), findsOneWidget);
      },
    );
  });

  group('friends', () {
    testWidgets(
      'Change friends opens the picker with the current friends chosen; the '
      'picked set replaces the chips and is invited on create '
      '[case:groups.create_group.change_friends.action]',
      (tester) async {
        final world = _world();
        await _open(tester, world, invitees: [_asha]);
        await qaTap(
          tester,
          find.widgetWithText(OutlinedButton, _en.groupsChangeFriends),
        );
        expect(find.byType(GroupFriendPicker), findsOneWidget);
        expect(find.text(_en.groupsInviteFriends), findsOneWidget);
        // Asked without a group: every friend, not a group's standing.
        expect(
          world.api.sent('GET', '/engagement/group-friends').last.query,
          isEmpty,
        );
        final ashaTile = find.widgetWithText(CheckboxListTile, 'Asha');
        expect(tester.widget<CheckboxListTile>(ashaTile).value, isTrue);

        await qaTap(tester, find.widgetWithText(CheckboxListTile, 'Dev'));
        await qaTap(tester, find.text('${_en.groupsDone} (2)'));
        expect(find.byType(GroupFriendPicker), findsNothing);
        expect(find.widgetWithText(InputChip, 'Asha'), findsOneWidget);
        expect(find.widgetWithText(InputChip, 'Dev'), findsOneWidget);

        final body = await _nameAndCreate(tester, world);
        expect(body['invitee_user_ids'], ['asha', 'dev']);
      },
    );

    testWidgets('removing a friend chip drops that invitation from the create '
        '[case:groups.create_group.friend_ondeleted.action]', (tester) async {
      final world = _world();
      await _open(
        tester,
        world,
        invitees: [_asha, (userId: 'dev', name: 'Dev', photoUrl: '')],
      );
      expect(find.text(_en.groupsCreateSubtitleFriends), findsOneWidget);
      await qaTap(tester, find.byTooltip(_en.groupsRemoveInvitee('Dev')));
      expect(find.widgetWithText(InputChip, 'Dev'), findsNothing);
      expect(find.widgetWithText(InputChip, 'Asha'), findsOneWidget);

      await qaTap(tester, find.byTooltip(_en.groupsRemoveInvitee('Asha')));
      expect(find.byType(InputChip), findsNothing);
      // No friends left: the button and caption say so.
      expect(find.text(_en.groupsChooseFriends), findsOneWidget);
      expect(find.text(_en.groupsCreateFriendsCaptionEmpty), findsOneWidget);
      expect(find.text(_en.groupsCreateSubtitle), findsOneWidget);

      final body = await _nameAndCreate(tester, world);
      expect(body['invitee_user_ids'], isEmpty);
    });
  });

  group('Create group', () {
    testWidgets(
      'sends the whole group in one request and replaces the form with the '
      'new group, so Back returns to where the member started '
      '[case:groups.create_group.create_group.action]',
      (tester) async {
        final world = _world();
        final results = await _open(
          tester,
          world,
          invitees: [_asha],
          kind: 'community',
          category: 'books',
          launcher: true,
        );
        await tester.enterText(_name, 'Koramangala readers');
        await tester.enterText(_about, 'One book a month.');
        await tester.enterText(_city, 'Bengaluru');
        await _create(tester);

        final create = _creates(world).single;
        final body = Map<String, dynamic>.of(create.body);
        final groupId = body.remove('group_id');
        expect(groupId, isA<String>());
        expect((groupId! as String).length, 36, reason: 'a uuid');
        expect(body, {
          'kind': 'community',
          'name': 'Koramangala readers',
          'category_slug': 'books',
          'description': 'One book a month.',
          'city': 'Bengaluru',
          'cover_color': 'primary',
          'invitee_user_ids': ['asha'],
        });
        expect(world.api.writeLines, ['POST /engagement/groups']);
        expect(find.byType(CreateGroupScreen), findsNothing);
        expect(find.byType(GroupDetailScreen), findsOneWidget);
        expect(world.api.sent('GET', '/engagement/groups/new'), isNotEmpty);

        await tester.tap(find.byTooltip('Back'));
        await tester.pumpAndSettle();
        expect(find.byType(GroupDetailScreen), findsNothing);
        expect(find.byType(CreateGroupScreen), findsNothing);
        expect(qaKey('qa.test.launcher'), findsOneWidget);
        expect(results, [null]);
      },
    );

    testWidgets(
      'a refused or offline create shows why, keeps everything typed, and '
      'the retry reuses the same group id so only one group is made '
      '[case:groups.create_group.create_group.api_failure]',
      (tester) async {
        final world = _world();
        await _open(tester, world, invitees: [_asha], kind: 'private');
        world.api.fail(
          'POST /engagement/groups',
          status: 422,
          message: 'You already run a group with that name.',
        );
        await tester.enterText(_name, 'Brunch crew');
        await tester.enterText(_city, 'Pune');
        await _create(tester);
        expect(
          find.text('You already run a group with that name.'),
          findsOneWidget,
        );
        expect(find.byType(CreateGroupScreen), findsOneWidget);
        expect(_text(tester, _name), 'Brunch crew');
        expect(_text(tester, _city), 'Pune');
        expect(find.widgetWithText(InputChip, 'Asha'), findsOneWidget);
        expect(tester.widget<FilledButton>(_createButton).onPressed, isNotNull);

        world.api.offline('POST /engagement/groups');
        await _create(tester);
        expect(find.text(_en.networkOfflineTryAgain), findsOneWidget);
        expect(_text(tester, _name), 'Brunch crew');

        // A 500 without a message: the screen's own words.
        world.api.on(
          'POST /engagement/groups',
          (_) => const QaReply(500, null),
        );
        await _create(tester);
        expect(find.text(_en.groupsCreateFailed), findsOneWidget);

        // Back online: the retry goes through, with the same id.
        world.heal('POST /engagement/groups');
        await _create(tester);
        final creates = _creates(world);
        expect(creates, hasLength(4));
        expect(
          creates.map((c) => c.body['group_id']).toSet(),
          hasLength(1),
          reason: 'every attempt carries the same idempotency id',
        );
        expect(find.byType(GroupDetailScreen), findsOneWidget);
      },
    );
  });

  testWidgets(
    'Start a group renders translated in every locale with nothing left in '
    'English [case:groups.create_group.l10n]',
    (tester) async {
      await qaExpectRendersInAllLocales(
        tester,
        _world().api,
        () => const CreateGroupScreen(
          invitees: [_asha],
          initialKind: 'community',
        ),
        size: const Size(430, 3000),
        expected: [
          (l) => l.groupsStartGroup,
          (l) => l.groupsCreateSubtitleFriends,
          (l) => l.groupsKindCommunity,
          (l) => l.groupsCreateCommunitySubtitle,
          (l) => l.groupsKindPrivate,
          (l) => l.groupsCreateLifestyleCaption,
          (l) => l.groupsNameLabel,
          (l) => l.groupsAboutOptionalLabel,
          (l) => l.groupsCityLabel,
          (l) => l.groupsCoverColorTheme,
          (l) => l.groupsCoverColorWarm,
          (l) => l.groupsCreateCoverPhotoOptional,
          (l) => l.groupsCreateAddCoverPhoto,
          (l) => l.groupsCreateFriendsCaption,
          (l) => l.groupsChangeFriends,
          (l) => l.groupsCreateGroup,
        ],
        // Fixture data: a friend's name and the server's lifestyle titles.
        // "DETAILS", "LIFESTYLE" and "Warm" are the German and Dutch words
        // too, and "Accent" the French and Dutch one (the arb files carry
        // them as the translations).
        allow: {
          'Accent',
          'Asha',
          '📚  Books',
          '🎶  Music',
          'DETAILS',
          'LIFESTYLE',
          'Warm',
        },
      );
    },
  );
}
