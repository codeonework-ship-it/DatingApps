// Shared fixtures for the Photo Themes control tests: a fake BFF that holds
// the themes, gallery pages, photos, likes, reach and the member's own entry
// (every write changes what the next read returns), a gallery picker answered
// with a real file, and small gesture helpers.

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/photo_themes/photo_theme_widgets.dart';
import 'package:verified_dating_app/features/photo_themes/photo_themes_data.dart';

import '../../support/qa_api.dart';

final en = qaL10n(const Locale('en'));

Finder key(String k) => find.byKey(ValueKey(k));

/// A 1x1 transparent PNG, standing in for a member's photo bytes.
final png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA'
  '60e6kgAAAABJRU5ErkJggg==',
);

Map<String, dynamic> themeJson({
  String id = 't1',
  String title = 'My perfect Sunday',
  int count = 2,
  String myEntry = '',
}) => {
  'id': id,
  'slug': 'perfect-sunday',
  'title': title,
  'prompt': 'Show us the Sunday you would repeat forever.',
  'entry_count': count,
  'my_entry_id': myEntry,
};

Map<String, dynamic> entryJson({
  String id = 'e1',
  String author = 'priya',
  String name = 'Priya Sharma',
  String caption = 'Pancakes, then nowhere to be.',
  bool mine = false,
  int likes = 3,
  bool liked = false,
  bool allowFeaturing = false,
}) => {
  'id': id,
  'theme_id': 't1',
  'author_id': author,
  'author_name': name,
  'caption': caption,
  'alt_text': 'A stack of pancakes on a balcony table',
  'created_at': '2026-09-28T10:15:00Z',
  'mine': mine,
  'theme_title': 'My perfect Sunday',
  'like_count': likes,
  'liked_by_me': liked,
  'comment_count': 0,
  'pending_comment_count': 0,
  'allow_featuring': allowFeaturing,
  'featured': false,
  'wall_reach': 0,
};

/// The Photo Themes server. [pages] maps a `before` cursor ('' for the first
/// page) to its entries and next cursor.
class PhotoWorld {
  PhotoWorld({
    List<Map<String, dynamic>>? themes,
    Map<String, (List<Map<String, dynamic>>, String)>? pages,
    this.eligible = true,
    this.wall = const [],
  }) : themes = themes ?? [themeJson()],
       pages =
           pages ??
           {
             '': (
               [
                 entryJson(),
                 entryJson(
                   id: 'e2',
                   author: 'sam',
                   name: 'Sam Lee',
                   caption: 'Long walk.',
                 ),
               ],
               '',
             ),
           } {
    api
      ..on(
        'GET /themes',
        (_) => qaOk({
          'themes': this.themes,
          'eligible': eligible,
          'eligibility_message': '',
        }),
      )
      ..on('GET /themes/wall', (_) => qaOk({'entries': wall}))
      ..on('GET /themes/t1/entries', (c) {
        final before = c.query['before'] as String? ?? '';
        final page = this.pages[before]!;
        return qaOk({
          if (before.isEmpty) 'theme': this.themes.first,
          'entries': page.$1,
          'next_cursor': page.$2,
        });
      })
      ..on('GET /themes/t1/entries/*/photo', (_) => QaReply(200, png))
      ..on(
        'GET /themes/t1/entries/*/comments',
        (_) => qaOk({'comments': <dynamic>[]}),
      )
      ..on('PUT /themes/t1/entries/*', (c) {
        final id = c.path.split('/').last;
        final form = c.data! as FormData;
        final fields = {for (final f in form.fields) f.key: f.value};
        final saved = {
          ...entryJson(id: id, author: 'me', name: 'Me', mine: true),
          'caption': fields['caption'],
          'alt_text': fields['alt_text'],
        };
        final first = this.pages['']!;
        this.pages[''] = ([saved, ...first.$1], first.$2);
        this.themes[0] = {...this.themes[0], 'my_entry_id': id};
        return qaOk({'entry': saved});
      })
      ..on('DELETE /themes/t1/entries/*', (c) {
        final id = c.path.split('/').last;
        final first = this.pages['']!;
        this.pages[''] = (
          first.$1.where((e) => e['id'] != id).toList(),
          first.$2,
        );
        this.themes[0] = {...this.themes[0], 'my_entry_id': ''};
        return qaOk({'ok': true});
      })
      ..on('POST /themes/t1/entries/*/featuring', (c) {
        final id = c.path.split('/')[4];
        return qaOk({
          'entry': entryJson(
            id: id,
            author: 'me',
            mine: true,
            allowFeaturing: c.body['allow'] as bool,
          ),
        });
      })
      ..on('PUT /themes/t1/entries/*/like', (c) {
        final id = c.path.split('/')[4];
        return qaOk({'entry': entryJson(id: id, likes: 4, liked: true)});
      })
      ..on('DELETE /themes/t1/entries/*/like', (c) {
        final id = c.path.split('/')[4];
        return qaOk({'entry': entryJson(id: id)});
      })
      ..on('POST /safety/block', (_) => qaOk({'success': true}))
      ..on(
        'POST /blog/reports/theme_entry/*',
        (_) => qaOk({
          'report': {'id': 'r1'},
        }),
      )
      ..on('POST /walls/views', (_) => qaOk({'recorded': true}));
  }

  final api = QaApi();
  final List<Map<String, dynamic>> themes;
  final Map<String, (List<Map<String, dynamic>>, String)> pages;
  bool eligible;
  List<Map<String, dynamic>> wall;

  List<QaCall> get views => api.sent('POST', '/walls/views');
}

ThemeEntry entry({bool mine = false, int likes = 3}) => ThemeEntry.fromJson(
  entryJson(author: mine ? 'me' : 'priya', mine: mine, likes: likes),
);

/// A page with one button that opens [entry]'s sheet the way the gallery and
/// the wall do (which also counts a view).
class SheetLauncher extends StatelessWidget {
  const SheetLauncher({required this.entry, super.key});
  final ThemeEntry entry;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(
        key: const ValueKey('qa.test.open_sheet'),
        onPressed: () => showThemeEntrySheet(context, entry: entry),
        child: const Text('open sheet'),
      ),
    ),
  );
}

/// Pumps the launcher and opens the sheet for [e].
Future<void> openSheet(WidgetTester t, PhotoWorld w, ThemeEntry e) async {
  await pumpQa(t, w.api, SheetLauncher(entry: e), size: const Size(430, 1600));
  await t.tap(key('qa.test.open_sheet'));
  await qaSettle(t);
  expect(find.byType(ThemeEntrySheet), findsOneWidget);
}

/// [finder] inside the open entry sheet.
Finder inSheet(Finder finder) =>
    find.descendant(of: find.byType(ThemeEntrySheet), matching: finder);

/// [finder] inside the open dialog.
Finder inDialog(Finder finder) =>
    find.descendant(of: find.byType(AlertDialog), matching: finder);

Future<void> tapIn(WidgetTester t, Finder finder) async {
  await t.ensureVisible(finder);
  await t.pump();
  await t.tap(finder);
  await qaSettle(t);
}

const _pickerChannel = MethodChannel('plugins.flutter.io/image_picker');

/// Answers the gallery picker with [path] (null: the member cancelled).
List<MethodCall> mockPicker(WidgetTester t, String? path) {
  final calls = <MethodCall>[];
  t.binding.defaultBinaryMessenger.setMockMethodCallHandler(_pickerChannel, (
    call,
  ) async {
    calls.add(call);
    return path;
  });
  addTearDown(
    () => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      _pickerChannel,
      null,
    ),
  );
  return calls;
}

/// A real PNG on disk for the picker to return.
String photoFile() {
  final dir = Directory.systemTemp.createTempSync('photo_themes_qa');
  final path = '${dir.path}/sunday.png';
  File(path).writeAsBytesSync(png);
  return path;
}

/// Lets the picked file be read from disk, then settles. Reading takes
/// several real I/O round trips, each continued by a fake-async frame.
Future<void> settleIo(WidgetTester t) async {
  await qaSettle(t);
  for (var i = 0; i < 10; i++) {
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await t.pump();
  }
  await qaSettle(t);
}

/// The fields of the multipart upload the gallery sent.
Map<String, String> uploadFields(QaCall call) => {
  for (final f in (call.data! as FormData).fields) f.key: f.value,
};
