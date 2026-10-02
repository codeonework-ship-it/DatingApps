import 'package:flutter/material.dart' hide Title;
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/clubs/my_lists_screen.dart';
import 'package:verified_dating_app/features/clubs/title_detail_screen.dart';

import '../../support/qa_api.dart';
import 'clubs_qa_fixtures.dart';

// My lists (cards, list and item menus, the list editor and note dialog)
// and the review / add-to-list sheets opened from a title page.

Future<ClubsWorld> _lists(
  WidgetTester t, {
  void Function(ClubsWorld w)? setup,
}) async {
  final w = ClubsWorld();
  setup?.call(w);
  await pumpQa(t, w.api, const MyListsScreen());
  return w;
}

Future<ClubsWorld> _title(
  WidgetTester t, {
  void Function(ClubsWorld w)? setup,
}) async {
  final w = ClubsWorld();
  setup?.call(w);
  await pumpQa(t, w.api, const TitleDetailScreen(titleId: 'title-1'));
  return w;
}

int _listLoads(ClubsWorld w) => w.api.sent('GET', '/clubs/lists').length;

Finder get _listName => inSheet(find.widgetWithText(TextField, 'List name'));

Finder _menuOfList(String name) => find.descendant(
  of: find.ancestor(of: find.text(name), matching: find.byType(MemberListCard)),
  matching: find.byTooltip('List options'),
);

Future<void> _listMenu(WidgetTester t, String name, String item) async {
  await scrollTo(t, _menuOfList(name));
  await t.tap(_menuOfList(name));
  await qaSettle(t);
  await t.tap(find.text(item).last);
  await qaSettle(t);
}

Future<void> _itemMenu(WidgetTester t, String title, String item) async {
  await scrollTo(t, find.byTooltip('Options for $title'));
  await t.tap(find.byTooltip('Options for $title'));
  await qaSettle(t);
  await t.tap(find.text(item).last);
  await qaSettle(t);
}

Finder get _noteField =>
    inDialog(find.widgetWithText(TextField, 'Why it is on this list'));

Map<String, dynamic> _item(ClubsWorld w, String list, String title) =>
    (w.listById(list)!['items'] as List)
        .cast<Map<String, dynamic>>()
        .firstWhere((i) => (i['title'] as Map)['id'] == title);

Future<void> _waitOutSnack(WidgetTester t) => qaSettle(t, frames: 50);

void main() {
  group('my lists', () {
    testWidgets(
      'New list: name, Films, Friends → Create list adds it to the shelf '
      '[case:clubs.my_lists.create_a_new_list.action] '
      '[case:clubs.list_sheets.list_name_input.action] '
      '[case:clubs.list_sheets.segmentedbutton_onselectionchang_onselectionchanged.action] '
      '[case:clubs.list_sheets.choicechip_onselected.action] '
      '[case:clubs.list_sheets.create_list.action]',
      (t) async {
        final w = await _lists(t);
        final loads = _listLoads(w);
        await t.tap(find.byTooltip('Create a new list'));
        await qaSettle(t);
        expect(inSheet(find.text('New list')), findsOneWidget);
        expect(
          t
              .widget<SegmentedButton<String>>(
                inSheet(find.byType(SegmentedButton<String>)),
              )
              .selected,
          {'book'},
        );
        ChoiceChip chip(String label) => t.widget<ChoiceChip>(
          inSheet(find.widgetWithText(ChoiceChip, label)),
        );
        expect(chip('Only me').selected, isTrue);

        await t.enterText(_listName, '  Comfort rewatches  ');
        await t.tap(inSheet(find.text('Films')));
        await qaSettle(t);
        await t.tap(inSheet(find.text('Friends')));
        await qaSettle(t);
        expect(chip('Friends').selected, isTrue);
        expect(chip('Only me').selected, isFalse);

        w.slow('PUT /clubs/lists/*');
        await t.tap(inSheet(find.text('Create list')));
        await t.pump(const Duration(milliseconds: 100));
        expect(inSheet(find.text('Saving…')), findsOneWidget);
        expect(isEnabled(t, inSheet(find.text('Saving…'))), isFalse);
        await qaSettle(t, frames: 15);

        final put = w.api.sent('PUT', '/clubs/lists/*').single;
        expect(put.path, matches(uuidSegment));
        expect(put.body, {
          'name': 'Comfort rewatches',
          'kind': 'film',
          'audience': 'friends',
          'expected_version': 0,
        });
        expect(find.byType(BottomSheet), findsNothing);
        expect(_listLoads(w), greaterThan(loads));
        await scrollTo(t, find.text('Comfort rewatches'));
        final card = find.ancestor(
          of: find.text('Comfort rewatches'),
          matching: find.byType(MemberListCard),
        );
        expect(
          find.descendant(of: card, matching: find.text('Film list')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: card, matching: find.text('0 titles')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: card, matching: find.text('Friends')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Create list failure keeps the sheet and name; retry reuses the id '
      '[case:clubs.list_sheets.create_list.api_failure]',
      (t) async {
        final w = await _lists(t);
        await t.tap(find.byTooltip('Create a new list'));
        await qaSettle(t);
        await t.enterText(_listName, 'Comfort rewatches');
        w.api.fail('PUT /clubs/lists/*', message: 'Lists are paused.');
        await t.tap(inSheet(find.text('Create list')));
        await qaSettle(t);
        expect(inSheet(find.text('Lists are paused.')), findsOneWidget);
        expect(fieldText(t, 'List name'), 'Comfort rewatches');
        expect(isEnabled(t, inSheet(find.text('Create list'))), isTrue);
        expect(w.api.sent('PUT', '/clubs/lists/*'), hasLength(1));

        w.api.on('PUT /clubs/lists/*', (_) => const QaReply(500, null));
        await t.tap(inSheet(find.text('Create list')));
        await qaSettle(t);
        expect(inSheet(find.text(en.clubsListNotSaved)), findsOneWidget);

        w.heal('PUT /clubs/lists/*');
        await t.tap(inSheet(find.text('Create list')));
        await qaSettle(t);
        final puts = w.api.sent('PUT', '/clubs/lists/*');
        expect(puts, hasLength(3));
        expect(puts.map((c) => c.path).toSet(), hasLength(1));
        expect(find.byType(BottomSheet), findsNothing);
        await scrollTo(t, find.text('Comfort rewatches'));
      },
    );

    testWidgets(
      'List name: empty and blank are refused; over 60 is cut; emoji and RTL '
      'are kept [case:clubs.list_sheets.list_name_input.validation]',
      (t) async {
        final w = await _lists(t);
        await t.tap(find.byTooltip('Create a new list'));
        await qaSettle(t);
        for (final bad in ['', '    ']) {
          await t.enterText(_listName, bad);
          await t.tap(inSheet(find.text('Create list')));
          await qaSettle(t);
          expect(inSheet(find.text('Give your list a name.')), findsOneWidget);
        }
        expect(w.api.writes, isEmpty);

        await t.enterText(_listName, 'L' * 61);
        expect(fieldText(t, 'List name'), 'L' * 60);

        const name = 'كتب للصيف ☀️ 📚';
        await t.enterText(_listName, name);
        await t.tap(inSheet(find.text('Create list')));
        await qaSettle(t);
        expect(w.api.sent('PUT', '/clubs/lists/*').single.body['name'], name);
        await scrollTo(t, find.text(name));
      },
    );

    testWidgets('Pull to refresh reloads the lists '
        '[case:clubs.my_lists.new_list_onrefresh.action]', (t) async {
      final w = await _lists(t);
      final loads = _listLoads(w);
      w.lists.first['name'] = 'Read next (winter)';
      await pullToRefresh(t);
      expect(_listLoads(w), loads + 1);
      expect(find.text('Read next (winter)'), findsOneWidget);
      expect(find.text('Read next'), findsNothing);
    });

    testWidgets('Your lists could not load: Try again reloads them '
        '[case:clubs.my_lists.your_lists_could_not_load_onaction.action]', (
      t,
    ) async {
      final w = await _lists(
        t,
        setup: (w) => w.api.fail('GET /clubs/lists', message: 'Shelf closed.'),
      );
      expect(find.text('Your lists could not load'), findsOneWidget);
      expect(find.text('Shelf closed.'), findsOneWidget);

      w.heal('GET /clubs/lists');
      await t.tap(find.text('Try again'));
      await qaSettle(t);
      expect(_listLoads(w), 2);
      expect(find.text('Read next'), findsOneWidget);
      expect(find.text('Your lists could not load'), findsNothing);
    });

    testWidgets('No lists yet: the notice\'s New list opens the editor '
        '[case:clubs.my_lists.start_your_first_list_onaction.action]', (
      t,
    ) async {
      final w = await _lists(t, setup: (w) => w.lists.clear());
      expect(find.text('Start your first list'), findsOneWidget);
      expect(find.text(en.clubsFirstListMessage), findsOneWidget);
      await t.tap(find.widgetWithText(OutlinedButton, 'New list'));
      await qaSettle(t);
      expect(inSheet(find.text('New list')), findsOneWidget);

      await t.enterText(_listName, 'Books to lend');
      await t.tap(inSheet(find.text('Create list')));
      await qaSettle(t);
      expect(
        w.api.sent('PUT', '/clubs/lists/*').single.body['name'],
        'Books to lend',
      );
      expect(find.text('Start your first list'), findsNothing);
      expect(find.text('Books to lend'), findsOneWidget);
    });

    testWidgets(
      'List options: Add a title, Edit list and (after confirming) Delete '
      'list [case:clubs.my_lists.list_options.action]',
      (t) async {
        final w = await _lists(
          t,
          setup: (w) => w.catalogue['title-4'] = titleJson(
            'title-4',
            'book',
            'The Remains of the Day',
            'Kazuo Ishiguro',
            year: 1989,
          ),
        );

        // Add a title: the picker is headed with the list's name.
        await _listMenu(t, 'Read next', 'Add a title');
        expect(inSheet(find.text('Add to Read next')), findsOneWidget);
        await t.enterText(
          inSheet(find.widgetWithText(TextField, 'Search books')),
          'rem',
        );
        await qaSettle(t, frames: 6);
        await t.tap(inSheet(find.text('The Remains of the Day')));
        await qaSettle(t);
        final add = w.api.sent('PUT', '/clubs/lists/*/items/*').single;
        expect(add.path, '/clubs/lists/l-1/items/title-4');
        expect(add.body, {'note': ''});
        expect(find.byType(BottomSheet), findsNothing);
        await scrollTo(t, find.text('The Remains of the Day'));
        expect(find.text('3 titles'), findsOneWidget);

        // Edit list: kind is fixed once it has titles.
        await _listMenu(t, 'Read next', 'Edit list');
        expect(inSheet(find.text('Edit list')), findsOneWidget);
        expect(fieldText(t, 'List name'), 'Read next');
        expect(inSheet(find.byType(SegmentedButton<String>)), findsNothing);
        await t.enterText(_listName, 'Read next, soon');
        await t.tap(inSheet(find.text('Connect community')));
        await qaSettle(t);
        await t.tap(inSheet(find.text('Save')));
        await qaSettle(t);
        final edit = w.api.sent('PUT', '/clubs/lists/*').single;
        expect(edit.path, '/clubs/lists/l-1');
        expect(edit.body, {
          'name': 'Read next, soon',
          'kind': 'book',
          'audience': 'community',
          'expected_version': 2,
        });
        await scrollTo(t, find.text('Read next, soon'));
        expect(find.text('Connect community'), findsOneWidget);

        // Delete list asks first.
        await _listMenu(t, 'Read next, soon', 'Delete list');
        expect(inDialog(find.text('Delete Read next, soon?')), findsOneWidget);
        await t.tap(inDialog(find.text('Cancel')));
        await qaSettle(t);
        expect(w.api.sent('DELETE', '/clubs/lists/*'), isEmpty);

        await _listMenu(t, 'Read next, soon', 'Delete list');
        await t.tap(inDialog(find.text('Delete list')));
        await qaSettle(t);
        final delete = w.api.sent('DELETE', '/clubs/lists/*').single;
        expect(delete.path, '/clubs/lists/l-1');
        expect(delete.data, {'expected_version': 3});
        expect(find.text('Read next, soon'), findsNothing);
        expect(find.text('Films that stayed'), findsOneWidget);
      },
    );

    testWidgets(
      'regression: Add a title that is already on the list keeps its note',
      (t) async {
        final w = await _lists(t);
        await _listMenu(t, 'Read next', 'Add a title');
        await t.enterText(
          inSheet(find.widgetWithText(TextField, 'Search books')),
          'pir',
        );
        await qaSettle(t, frames: 6);
        await t.tap(inSheet(find.text('Piranesi')));
        await qaSettle(t);
        expect(
          w.api.sent('PUT', '/clubs/lists/l-1/items/title-1').single.body,
          {'note': 'For a rainy weekend'},
        );
        expect(_item(w, 'l-1', 'title-1')['note'], 'For a rainy weekend');
        expect(find.textContaining('“For a rainy weekend”'), findsOneWidget);
      },
    );

    testWidgets('List option failures say why and keep the list '
        '[case:clubs.my_lists.list_options.api_failure]', (t) async {
      final w = await _lists(t);
      w.api.fail(
        'DELETE /clubs/lists/*',
        status: 409,
        message: 'This list changed. Reload and retry.',
      );
      await _listMenu(t, 'Read next', 'Delete list');
      await t.tap(inDialog(find.text('Delete list')));
      await qaSettle(t);
      expect(qaSnackText(t), 'This list changed. Reload and retry.');
      expect(w.api.sent('DELETE', '/clubs/lists/*'), hasLength(1));
      expect(find.text('Read next'), findsOneWidget);
      final menu = t.widget<PopupMenuButton<String>>(
        find.ancestor(
          of: _menuOfList('Read next'),
          matching: find.byType(PopupMenuButton<String>),
        ),
      );
      expect(menu.enabled, isTrue);

      await _waitOutSnack(t);
      w.api.on('PUT /clubs/lists/*/items/*', (_) => const QaReply(500, null));
      await _listMenu(t, 'Films that stayed', 'Add a title');
      await t.enterText(
        inSheet(find.widgetWithText(TextField, 'Search films')),
        'por',
      );
      await qaSettle(t, frames: 6);
      await t.tap(inSheet(find.text('Portrait of a Lady on Fire')));
      await qaSettle(t);
      expect(qaSnackText(t), en.clubsAddToThisListFailed);
      expect(w.api.sent('PUT', '/clubs/lists/*/items/*'), hasLength(1));

      await _waitOutSnack(t);
      w.heal('DELETE /clubs/lists/*');
      await _listMenu(t, 'Read next', 'Delete list');
      await t.tap(inDialog(find.text('Delete list')));
      await qaSettle(t);
      expect(find.text('Read next'), findsNothing);
    });

    testWidgets('Tapping a listed title opens its page '
        '[case:clubs.my_lists.note.action]', (t) async {
      final w = await _lists(t);
      expect(
        find.text('Susanna Clarke · 2020\n“For a rainy weekend”'),
        findsOneWidget,
      );
      await t.tap(find.text('Piranesi'));
      await qaSettle(t);
      expect(
        t.widget<TitleDetailScreen>(find.byType(TitleDetailScreen)).titleId,
        'title-1',
      );
      expect(w.api.sent('GET', '/clubs/titles/title-1'), hasLength(1));
      expect(find.text('A labyrinth of kindness.'), findsOneWidget);
    });

    testWidgets(
      'Item options: Edit note (Cancel keeps it, Save note saves it) and '
      'Remove from list '
      '[case:clubs.my_lists.options_for_title.action] '
      '[case:clubs.list_sheets.showdialog_open.action] '
      '[case:clubs.list_sheets.why_it_is_on_this_list_input.action] '
      '[case:clubs.list_sheets.cancel.action] '
      '[case:clubs.list_sheets.save_note.action]',
      (t) async {
        final w = await _lists(t);
        await t.tap(find.byTooltip('Options for Klara and the Sun'));
        await qaSettle(t);
        expect(find.text('Add a note'), findsOneWidget);
        await t.tapAt(const Offset(10, 10));
        await qaSettle(t);

        await _itemMenu(t, 'Piranesi', 'Edit note');
        expect(inDialog(find.text('Your note')), findsOneWidget);
        expect(fieldText(t, 'Why it is on this list'), 'For a rainy weekend');
        await t.enterText(_noteField, 'Changed my mind');
        await t.tap(inDialog(find.text('Cancel')));
        await qaSettle(t);
        expect(find.byType(AlertDialog), findsNothing);
        expect(w.api.writes, isEmpty);
        expect(find.textContaining('“For a rainy weekend”'), findsOneWidget);

        await _itemMenu(t, 'Piranesi', 'Edit note');
        await t.enterText(_noteField, '  Start on a Sunday  ');
        await t.tap(inDialog(find.text('Save note')));
        await qaSettle(t);
        final put = w.api.sent('PUT', '/clubs/lists/*/items/*').single;
        expect(put.path, '/clubs/lists/l-1/items/title-1');
        expect(put.body, {'note': 'Start on a Sunday'});
        expect(find.textContaining('“Start on a Sunday”'), findsOneWidget);
        expect(find.textContaining('rainy'), findsNothing);

        await _itemMenu(t, 'Klara and the Sun', 'Remove from list');
        final delete = w.api.sent('DELETE', '/clubs/lists/*/items/*').single;
        expect(delete.path, '/clubs/lists/l-1/items/title-2');
        expect(find.text('Klara and the Sun'), findsNothing);
        expect(find.text('1 title'), findsWidgets);
      },
    );

    testWidgets(
      'regression: changing a list further down keeps the shelf in place '
      'instead of reloading it back to the top',
      (t) async {
        final w = await _lists(
          t,
          setup: (w) {
            for (var i = 3; i <= 5; i++) {
              w.lists.insert(0, {
                ...w.lists.first,
                'id': 'l-$i',
                'name': 'Shelf $i',
              });
            }
          },
        );
        await scrollTo(
          t,
          find.byTooltip('Options for Portrait of a Lady on Fire'),
        );
        final scroll = t.state<ScrollableState>(find.byType(Scrollable).first);
        expect(scroll.position.pixels, greaterThan(0));

        await _itemMenu(t, 'Portrait of a Lady on Fire', 'Remove from list');
        expect(
          w.api.sent('DELETE', '/clubs/lists/*/items/*').single.path,
          '/clubs/lists/l-2/items/title-3',
        );
        expect(
          t.state<ScrollableState>(find.byType(Scrollable).first),
          same(scroll),
          reason: 'the shelf was not rebuilt from scratch',
        );
        expect(scroll.position.pixels, greaterThan(0));
        expect(find.text('Portrait of a Lady on Fire'), findsNothing);
        expect(find.text('Films that stayed'), findsOneWidget);
      },
    );

    testWidgets('Item option failures say why and keep the item '
        '[case:clubs.my_lists.options_for_title.api_failure]', (t) async {
      final w = await _lists(t);
      w.api.on('PUT /clubs/lists/*/items/*', (_) => const QaReply(500, null));
      await _itemMenu(t, 'Piranesi', 'Edit note');
      await t.enterText(_noteField, 'New note');
      await t.tap(inDialog(find.text('Save note')));
      await qaSettle(t);
      expect(qaSnackText(t), en.clubsNoteNotSaved);
      expect(find.textContaining('“For a rainy weekend”'), findsOneWidget);
      expect(w.api.sent('PUT', '/clubs/lists/*/items/*'), hasLength(1));

      await _waitOutSnack(t);
      w.api.fail(
        'DELETE /clubs/lists/*/items/*',
        message: 'Removing is paused.',
      );
      await _itemMenu(t, 'Klara and the Sun', 'Remove from list');
      expect(qaSnackText(t), 'Removing is paused.');
      expect(find.text('Klara and the Sun'), findsOneWidget);
      expect(w.api.sent('DELETE', '/clubs/lists/*/items/*'), hasLength(1));

      await _waitOutSnack(t);
      w.heal('DELETE /clubs/lists/*/items/*');
      await _itemMenu(t, 'Klara and the Sun', 'Remove from list');
      expect(find.text('Klara and the Sun'), findsNothing);
    });

    testWidgets(
      'Note: over 280 is cut, a blank note clears it, emoji and RTL are kept '
      '[case:clubs.list_sheets.why_it_is_on_this_list_input.validation]',
      (t) async {
        final w = await _lists(t);
        await _itemMenu(t, 'Piranesi', 'Edit note');
        await t.enterText(_noteField, 'q' * 281);
        expect(fieldText(t, 'Why it is on this list'), 'q' * 280);

        await t.enterText(_noteField, '   ');
        await t.tap(inDialog(find.text('Save note')));
        await qaSettle(t);
        expect(w.api.sent('PUT', '/clubs/lists/*/items/*').last.body, {
          'note': '',
        });
        expect(find.textContaining('“'), findsNothing);
        expect(find.text('Susanna Clarke · 2020'), findsOneWidget);

        const note = 'לקרוא בגשם ☔ — اقرأها ببطء';
        await _itemMenu(t, 'Piranesi', 'Add a note');
        await t.enterText(_noteField, note);
        await t.tap(inDialog(find.text('Save note')));
        await qaSettle(t);
        expect(w.api.sent('PUT', '/clubs/lists/*/items/*').last.body, {
          'note': note,
        });
        expect(find.textContaining('“$note”'), findsOneWidget);
      },
    );
  });

  group('review sheet', () {
    testWidgets('Write a review: stars, words, spoilers and audience are saved '
        '[case:clubs.title_detail.write_a_review.action] '
        '[case:clubs.review_sheets.count_plural_1_1_star_other_coun.action] '
        '[case:clubs.review_sheets.what_did_you_think_optional_input.action] '
        '[case:clubs.review_sheets.contains_spoilers.action] '
        '[case:clubs.review_sheets.choicechip_onselected.action] '
        '[case:clubs.review_sheets.save_review.action]', (t) async {
      final w = await _title(t);
      expect(find.text('What did you think?'), findsOneWidget);
      await t.tap(find.text('Write a review'));
      await qaSettle(t);
      expect(inSheet(find.text('Write a review')), findsOneWidget);
      expect(inSheet(find.text('Piranesi')), findsOneWidget);
      expect(inSheet(find.text('Tap a star to rate')), findsOneWidget);

      await t.tap(find.byTooltip('4 stars'));
      await qaSettle(t);
      expect(inSheet(find.text('4 out of 5')), findsOneWidget);
      final selected = [
        for (var star = 1; star <= 5; star++)
          t
              .widget<IconButton>(
                find.ancestor(
                  of: find.byTooltip(star == 1 ? '1 star' : '$star stars'),
                  matching: find.byType(IconButton),
                ),
              )
              .isSelected,
      ];
      expect(selected, [true, true, true, true, false]);

      await t.enterText(
        inSheet(
          find.widgetWithText(TextField, 'What did you think? (optional)'),
        ),
        '  A house of endless halls.  ',
      );
      await t.tap(inSheet(find.text('Contains spoilers')));
      await t.tap(inSheet(find.text('Connect community')));
      await qaSettle(t);
      expect(
        t
            .widget<SwitchListTile>(
              inSheet(find.widgetWithText(SwitchListTile, 'Contains spoilers')),
            )
            .value,
        isTrue,
      );
      expect(
        t
            .widget<ChoiceChip>(
              inSheet(find.widgetWithText(ChoiceChip, 'Connect community')),
            )
            .selected,
        isTrue,
      );

      final loads = w.api.sent('GET', '/clubs/titles/title-1').length;
      w.slow('PUT /clubs/titles/*/reviews/*');
      await t.tap(inSheet(find.text('Save review')));
      await t.pump(const Duration(milliseconds: 100));
      expect(inSheet(find.text('Saving…')), findsOneWidget);
      expect(isEnabled(t, inSheet(find.text('Saving…'))), isFalse);
      await qaSettle(t, frames: 15);

      final put = w.api.sent('PUT', '/clubs/titles/*/reviews/*').single;
      expect(put.path, startsWith('/clubs/titles/title-1/reviews/'));
      expect(put.path, matches(uuidSegment));
      expect(put.body, {
        'rating': 4,
        'body': 'A house of endless halls.',
        'has_spoilers': true,
        'audience': 'community',
        'expected_version': 0,
      });
      expect(find.byType(BottomSheet), findsNothing);
      expect(
        w.api.sent('GET', '/clubs/titles/title-1').length,
        greaterThan(loads),
      );
      expect(find.text('Your review'), findsOneWidget);
      expect(find.text('A house of endless halls.'), findsOneWidget);
      expect(find.text('Connect community'), findsOneWidget);
      expect(find.text('Spoilers'), findsOneWidget);
    });

    testWidgets(
      'Save review needs a star; the words are optional, cut at 4000, blank '
      'is sent empty, emoji and RTL are kept '
      '[case:clubs.review_sheets.what_did_you_think_optional_input.validation]',
      (t) async {
        final w = await _title(t);
        await t.tap(find.text('Write a review'));
        await qaSettle(t);
        final body = inSheet(
          find.widgetWithText(TextField, 'What did you think? (optional)'),
        );
        await t.enterText(body, 'Loved it');
        await t.tap(inSheet(find.text('Save review')));
        await qaSettle(t);
        expect(inSheet(find.text('Tap a star to rate it.')), findsOneWidget);
        expect(w.api.writes, isEmpty);

        await t.enterText(body, 'w' * 4001);
        expect(fieldText(t, 'What did you think? (optional)'), 'w' * 4000);

        await t.tap(find.byTooltip('1 star'));
        await t.enterText(body, '  \n  ');
        await t.tap(inSheet(find.text('Save review')));
        await qaSettle(t);
        expect(
          w.api.sent('PUT', '/clubs/titles/*/reviews/*').last.body['body'],
          '',
        );

        const words = 'رائعة 🌊✨ — מופלא';
        await t.tap(find.text('Edit'));
        await qaSettle(t);
        await t.enterText(body, words);
        await t.tap(inSheet(find.text('Save review')));
        await qaSettle(t);
        expect(
          w.api.sent('PUT', '/clubs/titles/*/reviews/*').last.body['body'],
          words,
        );
        expect(find.text(words), findsOneWidget);
      },
    );

    testWidgets(
      'Save review failure keeps the sheet, stars and words; retry saves '
      '[case:clubs.review_sheets.save_review.api_failure]',
      (t) async {
        final w = await _title(t);
        await t.tap(find.text('Write a review'));
        await qaSettle(t);
        await t.tap(find.byTooltip('5 stars'));
        await t.enterText(
          inSheet(
            find.widgetWithText(TextField, 'What did you think? (optional)'),
          ),
          'Perfect.',
        );
        w.api.fail(
          'PUT /clubs/titles/*/reviews/*',
          status: 409,
          message: 'Your review changed elsewhere. Reload and retry.',
        );
        await t.tap(inSheet(find.text('Save review')));
        await qaSettle(t);
        expect(
          inSheet(
            find.text('Your review changed elsewhere. Reload and retry.'),
          ),
          findsOneWidget,
        );
        expect(inSheet(find.text('5 out of 5')), findsOneWidget);
        expect(fieldText(t, 'What did you think? (optional)'), 'Perfect.');
        expect(isEnabled(t, inSheet(find.text('Save review'))), isTrue);
        expect(w.api.sent('PUT', '/clubs/titles/*/reviews/*'), hasLength(1));

        w.api.on(
          'PUT /clubs/titles/*/reviews/*',
          (_) => const QaReply(500, null),
        );
        await t.tap(inSheet(find.text('Save review')));
        await qaSettle(t);
        expect(inSheet(find.text(en.clubsReviewNotSaved)), findsOneWidget);

        w.heal('PUT /clubs/titles/*/reviews/*');
        await t.tap(inSheet(find.text('Save review')));
        await qaSettle(t);
        final puts = w.api.sent('PUT', '/clubs/titles/*/reviews/*');
        expect(puts, hasLength(3));
        expect(puts.map((c) => c.path).toSet(), hasLength(1));
        expect(find.byType(BottomSheet), findsNothing);
        expect(find.text('Perfect.'), findsOneWidget);
      },
    );

    testWidgets('Edit opens my review prefilled and saves the new version '
        '[case:clubs.title_detail.edit.action]', (t) async {
      final w = await _title(t, setup: (w) => w.giveMyReview());
      expect(find.text('Your review'), findsOneWidget);
      expect(find.text('Slow start, then wonderful.'), findsOneWidget);
      await t.tap(find.text('Edit'));
      await qaSettle(t);
      expect(inSheet(find.text('Edit your review')), findsOneWidget);
      expect(inSheet(find.text('3 out of 5')), findsOneWidget);
      expect(
        fieldText(t, 'What did you think? (optional)'),
        'Slow start, then wonderful.',
      );
      expect(
        t
            .widget<ChoiceChip>(
              inSheet(find.widgetWithText(ChoiceChip, 'Friends')),
            )
            .selected,
        isTrue,
      );

      await t.tap(find.byTooltip('5 stars'));
      await t.enterText(
        inSheet(
          find.widgetWithText(TextField, 'What did you think? (optional)'),
        ),
        'Wonderful from start to end.',
      );
      await t.tap(inSheet(find.text('Save review')));
      await qaSettle(t);
      final put = w.api.sent('PUT', '/clubs/titles/*/reviews/*').single;
      expect(put.path, '/clubs/titles/title-1/reviews/r-mine');
      expect(put.body, {
        'rating': 5,
        'body': 'Wonderful from start to end.',
        'has_spoilers': false,
        'audience': 'friends',
        'expected_version': 2,
      });
      expect(find.text('Wonderful from start to end.'), findsOneWidget);
      expect(find.text('Slow start, then wonderful.'), findsNothing);
    });
  });

  group('add to a list sheet', () {
    testWidgets(
      'Add to a list shows my lists of this kind; tapping one adds the title '
      '[case:clubs.title_detail.add_to_a_list.action] '
      '[case:clubs.review_sheets.count_plural_1_1_title_other_cou.action]',
      (t) async {
        final w = await _title(
          t,
          setup: (w) => w.lists.add({
            ...w.lists.first,
            'id': 'l-3',
            'name': 'Gifts',
            'version': 1,
            'items': <Object>[],
          }),
        );
        await t.tap(find.text('Add to a list'));
        await qaSettle(t);
        expect(inSheet(find.text('Add to a list')), findsOneWidget);
        expect(w.api.sent('GET', '/clubs/lists'), hasLength(1));
        expect(inSheet(find.text('Read next')), findsOneWidget);
        expect(inSheet(find.text('2 titles')), findsOneWidget);
        expect(inSheet(find.text('0 titles')), findsOneWidget);
        expect(inSheet(find.text('Films that stayed')), findsNothing);

        w.slow('PUT /clubs/lists/*/items/*');
        await t.tap(inSheet(find.text('Gifts')));
        await t.pump(const Duration(milliseconds: 100));
        expect(inSheet(find.byType(LinearProgressIndicator)), findsOneWidget);
        expect(
          t
              .widget<ListTile>(
                inSheet(find.widgetWithText(ListTile, 'Read next')),
              )
              .enabled,
          isFalse,
        );
        await qaSettle(t, frames: 15);

        final put = w.api.sent('PUT', '/clubs/lists/*/items/*').single;
        expect(put.path, '/clubs/lists/l-3/items/title-1');
        expect(put.body, {'note': ''});
        expect(find.byType(BottomSheet), findsNothing);
        expect(qaSnackText(t), 'Added to Gifts.');
        expect((w.listById('l-3')!['items'] as List), hasLength(1));
      },
    );

    testWidgets(
      'regression: Add to a list keeps the note when the title is already '
      'on that list',
      (t) async {
        final w = await _title(t);
        await t.tap(find.text('Add to a list'));
        await qaSettle(t);
        await t.tap(inSheet(find.text('Read next')));
        await qaSettle(t);
        expect(
          w.api.sent('PUT', '/clubs/lists/l-1/items/title-1').single.body,
          {'note': 'For a rainy weekend'},
        );
        expect(_item(w, 'l-1', 'title-1')['note'], 'For a rainy weekend');
        expect(qaSnackText(t), 'Added to Read next.');
      },
    );

    testWidgets(
      'Add to a list failure says why and keeps the sheet '
      '[case:clubs.review_sheets.count_plural_1_1_title_other_cou.api_failure]',
      (t) async {
        final w = await _title(t);
        await t.tap(find.text('Add to a list'));
        await qaSettle(t);
        w.api.fail(
          'PUT /clubs/lists/*/items/*',
          status: 409,
          message: 'A list holds up to 100 titles.',
        );
        await t.tap(inSheet(find.text('Read next')));
        await qaSettle(t);
        expect(qaSnackText(t), 'A list holds up to 100 titles.');
        expect(inSheet(find.text('Add to a list')), findsOneWidget);
        expect(
          t
              .widget<ListTile>(
                inSheet(find.widgetWithText(ListTile, 'Read next')),
              )
              .enabled,
          isTrue,
        );
        expect(w.api.sent('PUT', '/clubs/lists/*/items/*'), hasLength(1));

        await _waitOutSnack(t);
        w.heal('PUT /clubs/lists/*/items/*');
        await t.tap(inSheet(find.text('Read next')));
        await qaSettle(t);
        expect(find.byType(BottomSheet), findsNothing);
        expect(qaSnackText(t), 'Added to Read next.');
      },
    );

    testWidgets(
      'New list from Add to a list creates a list of this kind and adds the '
      'title to it [case:clubs.review_sheets.new_list.action]',
      (t) async {
        final w = await _title(
          t,
          setup: (w) => w.lists.removeWhere((l) => l['kind'] == 'book'),
        );
        await t.tap(find.text('Add to a list'));
        await qaSettle(t);
        expect(inSheet(find.text(en.clubsNoBookLists)), findsOneWidget);
        await t.tap(inSheet(find.text('New list')));
        await qaSettle(t);
        expect(inSheet(find.text('Create list')), findsOneWidget);
        expect(
          t
              .widget<SegmentedButton<String>>(
                inSheet(find.byType(SegmentedButton<String>)),
              )
              .selected,
          {'book'},
        );
        await t.enterText(_listName, 'Strange houses');
        await t.tap(inSheet(find.text('Create list')));
        await qaSettle(t);

        final created = w.api.sent('PUT', '/clubs/lists/*').single;
        expect(created.body['kind'], 'book');
        expect(created.body['name'], 'Strange houses');
        final id = created.path.split('/').last;
        final added = w.api.sent('PUT', '/clubs/lists/*/items/*').single;
        expect(added.path, '/clubs/lists/$id/items/title-1');
        expect(added.body, {'note': ''});
        expect(find.byType(BottomSheet), findsNothing);
        expect(qaSnackText(t), 'Added to Strange houses.');
      },
    );
  });

  group('l10n', () {
    testWidgets('My lists renders in every locale '
        '[case:clubs.my_lists.l10n]', (t) async {
      await sweepLocales(
        t,
        screen: () => const MyListsScreen(),
        open: (t, l10n) async {
          expect(find.byTooltip(l10n.clubsListOptions), findsNWidgets(2));
          expect(
            find.byTooltip(l10n.clubsItemOptions('Piranesi')),
            findsOneWidget,
          );
        },
        labels: (l10n) => [
          l10n.clubsMyLists,
          l10n.clubsShelfTitle,
          l10n.clubsNewList,
          l10n.clubsBadgeBookList,
          l10n.clubsAudiencePrivate,
          l10n.clubsTitleCount(2),
        ],
      );
    });

    testWidgets('List editor and note dialog render in every locale '
        '[case:clubs.list_sheets.l10n]', (t) async {
      await sweepLocales(
        t,
        screen: () => const MyListsScreen(),
        open: (t, l10n) async {
          await t.tap(find.byType(FloatingActionButton));
          await qaSettle(t);
          await t.tap(find.text(l10n.clubsCreateList));
          await qaSettle(t);
          expect(t.takeException(), isNull);
          for (final label in [
            l10n.clubsListNameLabel,
            l10n.clubsWhoCanSee,
            l10n.clubsAudienceCommunity,
            l10n.clubsListNameRequired,
          ]) {
            expect(find.text(label), findsWidgets, reason: label);
          }
          await t.tap(find.byKey(const ValueKey('qa.sheet.close')));
          await qaSettle(t);
          await t.tap(find.byTooltip(l10n.clubsItemOptions('Piranesi')));
          await qaSettle(t);
          await t.tap(find.text(l10n.clubsEditNote));
          await qaSettle(t);
        },
        labels: (l10n) => [
          l10n.clubsYourNote,
          l10n.clubsNoteLabel,
          l10n.clubsSaveNote,
        ],
      );
    });

    testWidgets('Review and add-to-list sheets render in every locale '
        '[case:clubs.review_sheets.l10n]', (t) async {
      await sweepLocales(
        t,
        screen: () => const TitleDetailScreen(titleId: 'title-1'),
        open: (t, l10n) async {
          await t.tap(find.text(l10n.clubsWriteReview));
          await qaSettle(t);
          await t.tap(find.text(l10n.clubsSaveReview));
          await qaSettle(t);
          expect(t.takeException(), isNull);
          for (final label in [
            l10n.clubsTapStarToRate,
            l10n.clubsReviewBodyLabel,
            l10n.clubsContainsSpoilers,
            l10n.clubsWhoCanSee,
            l10n.clubsTapStarError,
          ]) {
            expect(find.text(label), findsWidgets, reason: label);
          }
          await t.tap(find.byKey(const ValueKey('qa.sheet.close')));
          await qaSettle(t);
          await t.tap(find.text(l10n.clubsAddToAList));
          await qaSettle(t);
        },
        labels: (l10n) => [
          l10n.clubsAddToAList,
          l10n.clubsTitleCount(2),
          l10n.clubsNewList,
        ],
      );
    });
  });
}
