// Shared fixtures for the clubs control tests: an in-memory clubs backend on
// top of the recording QaApi (writes change what the next GET returns, so a
// test can assert the request AND what the member sees afterwards), plus a
// few gesture helpers. Not a test file itself (no `_test` suffix).

import 'package:flutter/material.dart' hide Title;
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/clubs/clubs_data.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

import '../../support/qa_api.dart';

/// English strings, for asserting what the member reads.
final en = lookupAppLocalizations(const Locale('en'));

/// This week's and next week's Mondays, computed the way the app does.
String get thisMonday => mondayOf(DateTime.now());
String get nextMonday => mondayOf(DateTime.now().add(const Duration(days: 7)));

/// A client-generated v4 UUID as the last path segment.
final uuidSegment = RegExp(
  r'[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

Map<String, dynamic> titleJson(
  String id,
  String kind,
  String title,
  String creator, {
  int? year,
  double? average,
  int reviews = 0,
}) => {
  'id': id,
  'kind': kind,
  'title': title,
  'creator': creator,
  'release_year': year,
  'average_rating': average,
  'review_count': reviews,
};

/// An in-memory clubs backend. Club `club-1` ("Sunday Slow Reads", a book
/// club) is the one most tests open; [role] is the signed-in member's role
/// in it ('' when not a member).
class ClubsWorld {
  ClubsWorld({this.role = 'member'}) {
    _routes();
  }

  final api = QaApi();

  // ---- club-1 ---------------------------------------------------------
  String role;
  int memberCount = 8;
  bool eligible = true;
  String nextCursor = '';
  var _clock = 0;

  final catalogue = <String, Map<String, dynamic>>{
    'title-1': titleJson(
      'title-1',
      'book',
      'Piranesi',
      'Susanna Clarke',
      year: 2020,
      average: 4.5,
      reviews: 2,
    ),
    'title-2': titleJson(
      'title-2',
      'book',
      'Klara and the Sun',
      'Kazuo Ishiguro',
      year: 2021,
    ),
    'title-3': titleJson(
      'title-3',
      'film',
      'Portrait of a Lady on Fire',
      'Céline Sciamma',
      year: 2019,
      average: 4,
      reviews: 1,
    ),
  };

  late Map<String, dynamic>? current = {
    'id': 'sel-1',
    'week_start': thisMonday,
    'note': 'Start with the first notebook.',
    'title': catalogue['title-1'],
    'post_count': 2,
  };

  late final earlier = <Map<String, dynamic>>[
    {
      'id': 'sel-0',
      'week_start': '2026-01-05',
      'note': '',
      'title': catalogue['title-2'],
      'post_count': 1,
    },
  ];

  /// Picks saved for a later week (not shown on the club page yet).
  final upcoming = <Map<String, dynamic>>[];

  final posts = <String, List<Map<String, dynamic>>>{
    'sel-1': [
      _post('p-sam', 'sel-1', 'u-sam', 'Sam', 'The statues in the halls!', 1),
      _post('p-me', 'sel-1', 'me', 'Alex', 'I loved the tides.', 2, mine: true),
    ],
    'sel-0': [_post('p-rin', 'sel-0', 'u-rin', 'Rin', 'Klara made me cry.', 1)],
  };

  /// Posts older than the first page, served for `before=<nextCursor>`.
  final older = <Map<String, dynamic>>[];

  late List<Map<String, dynamic>> members = [
    {'user_id': 'me', 'name': 'Alex', 'role': role.isEmpty ? 'member' : role},
    {'user_id': 'u-sam', 'name': 'Sam', 'role': 'member'},
    {'user_id': 'u-rin', 'name': 'Rin', 'role': 'moderator'},
    if (role != 'owner')
      {'user_id': 'u-olive', 'name': 'Olive', 'role': 'owner'},
  ];

  // ---- other clubs ----------------------------------------------------
  final midnight = <String, dynamic>{
    'id': 'club-4',
    'kind': 'film',
    'name': 'Midnight Movies',
    'description': '',
    'owner_id': 'u-olive',
    'member_count': 1,
    'my_role': 'member',
    'version': 1,
    'moderation_state': 'active',
    'current_selection': null,
  };
  final nightOwls = <String, dynamic>{
    'id': 'club-3',
    'kind': 'book',
    'name': 'Night Owls Read',
    'description': 'Short books, late nights.',
    'owner_id': 'u-rin',
    'member_count': 5,
    'my_role': '',
    'version': 1,
    'moderation_state': 'active',
    'current_selection': null,
  };
  final created = <Map<String, dynamic>>[];

  // ---- lists ----------------------------------------------------------
  late final lists = <Map<String, dynamic>>[
    {
      'id': 'l-1',
      'owner_id': 'me',
      'owner_name': 'Alex',
      'name': 'Read next',
      'kind': 'book',
      'audience': 'private',
      'version': 1,
      'mine': true,
      'items': [
        {
          'title': catalogue['title-1'],
          'note': 'For a rainy weekend',
          'position': 1,
        },
        {'title': catalogue['title-2'], 'note': '', 'position': 2},
      ],
    },
    {
      'id': 'l-2',
      'owner_id': 'me',
      'owner_name': 'Alex',
      'name': 'Films that stayed',
      'kind': 'film',
      'audience': 'friends',
      'version': 3,
      'mine': true,
      'items': [
        {'title': catalogue['title-3'], 'note': '', 'position': 1},
      ],
    },
  ];

  // ---- reviews of title-1 --------------------------------------------
  Map<String, dynamic>? myReview;
  final reviews = <Map<String, dynamic>>[
    {
      'id': 'r-sam',
      'title_id': 'title-1',
      'author_id': 'u-sam',
      'author_name': 'Sam',
      'rating': 4,
      'body': 'A labyrinth of kindness.',
      'has_spoilers': false,
      'audience': 'community',
      'version': 1,
      'mine': false,
    },
  ];

  static Map<String, dynamic> _post(
    String id,
    String selection,
    String author,
    String name,
    String body,
    int minute, {
    bool mine = false,
    bool hidden = false,
    bool spoilers = false,
  }) => {
    'id': id,
    'club_id': 'club-1',
    'selection_id': selection,
    'author_id': author,
    'author_name': name,
    'body': body,
    'has_spoilers': spoilers,
    'created_at': '2026-09-29T09:${minute.toString().padLeft(2, '0')}:00Z',
    'mine': mine,
    'hidden': hidden,
  };

  /// A post by another member, for tests that add their own.
  Map<String, dynamic> post(
    String id,
    String body, {
    String selection = 'sel-1',
    String author = 'u-sam',
    String name = 'Sam',
    bool mine = false,
    bool hidden = false,
    bool spoilers = false,
    int minute = 5,
  }) => _post(
    id,
    selection,
    author,
    name,
    body,
    minute,
    mine: mine,
    hidden: hidden,
    spoilers: spoilers,
  );

  Map<String, dynamic> get club1 => {
    'id': 'club-1',
    'kind': 'book',
    'name': 'Sunday Slow Reads',
    'description': 'One chapter at a time.',
    'owner_id': role == 'owner' ? 'me' : 'u-olive',
    'member_count': memberCount,
    'my_role': role,
    'version': 2,
    'moderation_state': 'active',
    'current_selection': current,
  };

  List<Map<String, dynamic>> clubsFor(String scope, String? kind) {
    final all = scope == 'mine'
        ? [if (role.isNotEmpty) club1, midnight, ...created]
        : [nightOwls, if (role.isEmpty) club1];
    return [
      for (final c in all)
        if (kind == null || c['kind'] == kind) c,
    ];
  }

  Map<String, dynamic>? clubById(String id) {
    if (id == 'club-1') {
      return club1;
    }
    for (final c in [midnight, nightOwls, ...created]) {
      if (c['id'] == id) {
        return c;
      }
    }
    return null;
  }

  Map<String, dynamic>? listById(String id) =>
      lists.where((l) => l['id'] == id).firstOrNull;

  static String _seg(QaCall call, int index) => call.path.split('/')[index];

  final _handlers = <String, QaHandler>{};

  /// Registers the world's own handler for [route].
  void handle(String route, QaHandler handler) {
    _handlers[route] = handler;
    api.on(route, handler);
  }

  /// Re-installs the world's own handler for [route] after a test made it
  /// fail (the retry then succeeds).
  void heal(String route) => api.on(route, _handlers[route]!);

  /// Makes [route] answer after [delay], to observe the busy state.
  void slow(
    String route, {
    Duration delay = const Duration(milliseconds: 800),
  }) {
    final handler = _handlers[route]!;
    api.on(route, (call) {
      final reply = handler(call);
      return QaReply(reply.status, reply.body, delay: delay);
    });
  }

  void _routes() {
    this
      ..handle('GET /clubs', (call) {
        final scope = call.query['scope'] as String? ?? 'mine';
        return qaOk({
          'clubs': clubsFor(scope, call.query['kind'] as String?),
          'eligible': eligible,
        });
      })
      ..handle('GET /clubs/titles', (call) {
        final q = (call.query['q'] as String).toLowerCase();
        final kind = call.query['kind'] as String?;
        return qaOk({
          'titles': [
            for (final t in catalogue.values)
              if ((kind == null || t['kind'] == kind) &&
                  (t['title'] as String).toLowerCase().contains(q))
                t,
          ],
        });
      })
      ..handle('GET /clubs/lists', (_) => qaOk({'lists': lists}))
      ..handle('GET /clubs/titles/*', (call) {
        final id = _seg(call, 3);
        final title = catalogue[id];
        if (title == null) {
          return qaError(404, message: 'This title is gone.');
        }
        final mine = id == 'title-1' ? myReview : null;
        return qaOk({
          'title': title,
          'my_review': mine,
          'reviews': id == 'title-1' ? [...reviews, ?mine] : const <Object>[],
        });
      })
      ..handle('GET /clubs/*', (call) {
        final id = _seg(call, 2);
        final club = clubById(id);
        if (club == null) {
          return qaError(404, message: 'This club is closed.');
        }
        return qaOk({
          'club': club,
          'selections': id == 'club-1'
              ? [?current, ...earlier]
              : const <Object>[],
        });
      })
      ..handle('GET /clubs/*/members', (_) => qaOk({'members': members}))
      ..handle('GET /clubs/*/posts', (call) {
        final selection = call.query['selection_id'] as String;
        final before = call.query['before'] as String?;
        if (before != null) {
          return qaOk({'posts': older, 'next_cursor': ''});
        }
        return qaOk({
          'posts': posts[selection] ?? const <Object>[],
          'next_cursor': nextCursor,
        });
      })
      // ---- writes ----
      ..handle('PUT /clubs/*', (call) {
        final club = {
          'id': _seg(call, 2),
          'kind': call.body['kind'],
          'name': call.body['name'],
          'description': call.body['description'],
          'owner_id': 'me',
          'member_count': 1,
          'my_role': 'owner',
          'version': 1,
          'moderation_state': 'active',
          'current_selection': null,
        };
        created
          ..removeWhere((c) => c['id'] == club['id'])
          ..add(club);
        return qaOk({'club': club});
      })
      ..handle('POST /clubs/*/membership', (call) {
        if (call.body['action'] == 'join') {
          role = 'member';
          memberCount++;
        } else {
          role = '';
          memberCount--;
        }
        return qaOk({'club': club1});
      })
      ..handle('PUT /clubs/*/posts/*', (call) {
        final selection = call.body['selection_id'] as String;
        final post = _post(
          _seg(call, 4),
          selection,
          'me',
          'Alex',
          call.body['body'] as String,
          30 + _clock++,
          mine: true,
          spoilers: call.body['has_spoilers'] == true,
        );
        final thread = posts[selection] ??= [];
        final isNew = thread.every((p) => p['id'] != post['id']);
        thread
          ..removeWhere((p) => p['id'] == post['id'])
          ..add(post);
        final pick = current;
        if (isNew && pick != null && pick['id'] == selection) {
          pick['post_count'] = (pick['post_count'] as int) + 1;
        }
        return qaOk({'post': post});
      })
      ..handle('DELETE /clubs/*/posts/*', (call) {
        for (final list in posts.values) {
          list.removeWhere((p) => p['id'] == _seg(call, 4));
        }
        return qaOk();
      })
      ..handle('POST /clubs/*/posts/*/visibility', (call) {
        for (final list in posts.values) {
          for (final p in list) {
            if (p['id'] == _seg(call, 4)) {
              p['hidden'] = call.body['hidden'];
            }
          }
        }
        return qaOk();
      })
      ..handle('POST /clubs/*/members/*', (call) {
        final user = _seg(call, 4);
        switch (call.body['action']) {
          case 'make_moderator':
            members.firstWhere((m) => m['user_id'] == user)['role'] =
                'moderator';
          case 'make_member':
            members.firstWhere((m) => m['user_id'] == user)['role'] = 'member';
          case 'remove':
            members.removeWhere((m) => m['user_id'] == user);
            memberCount--;
        }
        return qaOk({'members': members});
      })
      ..handle('PUT /clubs/*/selections/*', (call) {
        final week = _seg(call, 4);
        final selection = {
          'id': 'sel-$week',
          'week_start': week,
          'note': call.body['note'],
          'title': catalogue[call.body['title_id']],
          'post_count': 0,
        };
        if (week == thisMonday) {
          current = selection;
        } else {
          upcoming.add(selection);
        }
        return qaOk({'selection': selection});
      })
      ..handle('PUT /clubs/titles/*', (call) {
        final name = call.body['title'] as String;
        final existing = catalogue.values
            .where(
              (t) => (t['title'] as String).toLowerCase() == name.toLowerCase(),
            )
            .firstOrNull;
        final title =
            existing ??
            titleJson(
              _seg(call, 3),
              call.body['kind'] as String,
              name,
              call.body['creator'] as String,
              year: call.body['release_year'] as int?,
            );
        catalogue[title['id'] as String] = title;
        return qaOk({'title': title});
      })
      ..handle('PUT /clubs/lists/*', (call) {
        final id = _seg(call, 3);
        final list = listById(id);
        if (list == null) {
          final fresh = {
            'id': id,
            'owner_id': 'me',
            'owner_name': 'Alex',
            'name': call.body['name'],
            'kind': call.body['kind'],
            'audience': call.body['audience'],
            'version': 1,
            'mine': true,
            'items': <Object>[],
          };
          lists.add(fresh);
          return qaOk({'list': fresh});
        }
        list
          ..['name'] = call.body['name']
          ..['kind'] = call.body['kind']
          ..['audience'] = call.body['audience']
          ..['version'] = (list['version'] as int) + 1;
        return qaOk({'list': list});
      })
      ..handle('DELETE /clubs/lists/*', (call) {
        lists.removeWhere((l) => l['id'] == _seg(call, 3));
        return qaOk();
      })
      ..handle('PUT /clubs/lists/*/items/*', (call) {
        final list = listById(_seg(call, 3))!;
        list['version'] = (list['version'] as int) + 1;
        final items = (list['items'] as List).cast<Map<String, dynamic>>();
        final titleId = _seg(call, 5);
        final item = items
            .where((i) => (i['title'] as Map)['id'] == titleId)
            .firstOrNull;
        if (item != null) {
          item['note'] = call.body['note'];
        } else {
          list['items'] = [
            ...items,
            {
              'title': catalogue[titleId],
              'note': call.body['note'],
              'position': items.length + 1,
            },
          ];
        }
        return qaOk({'list': list});
      })
      ..handle('DELETE /clubs/lists/*/items/*', (call) {
        final list = listById(_seg(call, 3))!;
        list['version'] = (list['version'] as int) + 1;
        list['items'] = [
          for (final i in (list['items'] as List).cast<Map<String, dynamic>>())
            if ((i['title'] as Map)['id'] != _seg(call, 5)) i,
        ];
        return qaOk();
      })
      ..handle('PUT /clubs/titles/*/reviews/*', (call) {
        myReview = {
          'id': _seg(call, 5),
          'title_id': _seg(call, 3),
          'author_id': 'me',
          'author_name': 'Alex',
          'rating': call.body['rating'],
          'body': call.body['body'],
          'has_spoilers': call.body['has_spoilers'],
          'audience': call.body['audience'],
          'version': (call.body['expected_version'] as int) + 1,
          'mine': true,
        };
        return qaOk({'review': myReview});
      })
      ..handle('DELETE /clubs/reviews/*', (_) {
        myReview = null;
        return qaOk();
      })
      ..handle(
        'POST /blog/reports/*/*',
        (_) => qaOk({
          'report': {'id': 'rep-1'},
        }),
      );
  }

  /// My review of title-1 (rating 3, friends only, version 2).
  void giveMyReview() => myReview = {
    'id': 'r-mine',
    'title_id': 'title-1',
    'author_id': 'me',
    'author_name': 'Alex',
    'rating': 3,
    'body': 'Slow start, then wonderful.',
    'has_spoilers': false,
    'audience': 'friends',
    'version': 2,
    'mine': true,
  };
}

/// Scrolls the screen's main list until [finder] is built and on screen.
Future<void> scrollTo(WidgetTester t, Finder finder) async {
  await t.scrollUntilVisible(
    finder,
    250,
    scrollable: find.byType(Scrollable).first,
  );
  await t.pump();
}

/// The Material button (Filled/Outlined/Text, with or without icon) that
/// shows [label].
Finder buttonWith(Finder label) => find.ancestor(
  of: label,
  matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
);

bool isEnabled(WidgetTester t, Finder label) =>
    t.widget<ButtonStyleButton>(buttonWith(label).first).enabled;

/// Opens the popup menu behind [tooltip] and picks [item].
Future<void> chooseFromMenu(WidgetTester t, String tooltip, String item) async {
  await t.tap(find.byTooltip(tooltip).first);
  await qaSettle(t);
  await t.tap(find.text(item).last);
  await qaSettle(t);
}

/// The text currently in the TextField labelled [label].
String fieldText(WidgetTester t, String label) =>
    t.widget<TextField>(find.widgetWithText(TextField, label)).controller!.text;

/// Picks [reason] (optional) in the shared report sheet, types
/// [description] and submits.
Future<void> submitReport(
  WidgetTester t, {
  String? reason,
  String description = '',
}) async {
  expect(find.text('Report'), findsWidgets, reason: 'report sheet is open');
  if (reason != null) {
    await t.tap(find.text('Inappropriate content'));
    await qaSettle(t);
    await t.tap(find.text(reason).last);
    await qaSettle(t);
  }
  if (description.isNotEmpty) {
    await t.enterText(
      find.widgetWithText(TextField, 'Description (optional)'),
      description,
    );
  }
  await t.tap(find.text('Submit report'));
  await qaSettle(t);
}

/// Pulls the screen's main list down to trigger its RefreshIndicator.
Future<void> pullToRefresh(WidgetTester t) async {
  await t.fling(find.byType(Scrollable).first, const Offset(0, 400), 1200);
  await t.pump();
  await qaSettle(t, frames: 20);
}

/// Every shipped locale, re-pumping [screen] for each: no layout exception
/// and every label from [labels] (that locale's strings) is on screen.
Future<void> sweepLocales(
  WidgetTester t, {
  required Widget Function() screen,
  required List<String> Function(AppLocalizations l10n) labels,
  ClubsWorld Function()? world,
  Future<void> Function(WidgetTester t, AppLocalizations l10n)? open,
}) async {
  for (final locale in qaLocales) {
    await t.pumpWidget(const SizedBox());
    final w = (world ?? ClubsWorld.new)();
    final l10n = qaL10n(locale);
    await pumpQa(t, w.api, screen(), locale: locale);
    if (open != null) {
      await open(t, l10n);
    }
    expect(t.takeException(), isNull, reason: 'layout error in $locale');
    for (final label in labels(l10n)) {
      expect(
        find.text(label),
        findsWidgets,
        reason: '"$label" is not shown in $locale',
      );
    }
    expect(w.api.unhandled, isEmpty, reason: '$locale');
  }
}

/// [finder] inside the open modal bottom sheet (the topmost one).
Finder inSheet(Finder finder) =>
    find.descendant(of: find.byType(BottomSheet).last, matching: finder);

/// [finder] inside the open dialog.
Finder inDialog(Finder finder) =>
    find.descendant(of: find.byType(AlertDialog), matching: finder);
