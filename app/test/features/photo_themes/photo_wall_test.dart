import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/core/providers/runtime_feature_flags_provider.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/blog/blog_data.dart';
import 'package:verified_dating_app/features/photo_themes/photo_theme_widgets.dart';
import 'package:verified_dating_app/features/photo_themes/photo_themes_data.dart';
import 'package:verified_dating_app/features/photo_themes/photo_wall.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

class _Auth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(isAuthenticated: true, userId: 'me');
}

/// A 1x1 transparent PNG, standing in for a member's photo bytes.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA'
  '60e6kgAAAABJRU5ErkJggg==',
);

Map<String, dynamic> entryJson({
  String id = 'e1',
  String author = 'author',
  bool mine = false,
  int likes = 3,
  bool liked = false,
  Map<String, dynamic> extra = const {},
}) => {
  'id': id,
  'theme_id': 't1',
  'author_id': author,
  'author_name': 'Priya Sharma',
  'caption': 'Pancakes, then nowhere to be.',
  'alt_text': 'A stack of pancakes on a balcony table',
  'created_at': '2026-09-28T10:15:00Z',
  'mine': mine,
  'theme_title': 'My perfect Sunday',
  'like_count': likes,
  'liked_by_me': liked,
  'comment_count': 1,
  'pending_comment_count': 0,
  'allow_featuring': false,
  'featured': false,
  'wall_reach': 0,
  ...extra,
};

Map<String, dynamic> commentJson(
  String id, {
  String status = 'approved',
  bool mine = false,
  String body = 'Lovely light.',
}) => {
  'id': id,
  'entry_id': 'e1',
  'author_id': mine ? 'me' : 'reader-$id',
  'author_name': 'Reader $id',
  'body': body,
  'status': status,
  'mine': mine,
  'can_moderate': false,
  'created_at': '2026-10-01T09:00:00Z',
};

typedef _Handler = FutureOr<Object?> Function(RequestOptions r);

/// Fake API: [handler] returns response data, or throws an int to reject
/// with that HTTP status.
class _Api {
  _Api(this.handler);
  final _Handler handler;
  final requests = <RequestOptions>[];
  Dio get dio => Dio()
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (r, h) async {
          requests.add(r);
          try {
            final data = await handler(r);
            h.resolve(
              Response<dynamic>(requestOptions: r, statusCode: 200, data: data),
            );
          } on int catch (status) {
            h.reject(
              DioException(
                requestOptions: r,
                response: Response<dynamic>(
                  requestOptions: r,
                  statusCode: status,
                  data: {'error': 'Try again later.'},
                ),
              ),
            );
          }
        },
      ),
    );
}

List<Override> _overrides(_Api api, {bool photoThemes = true}) => [
  authNotifierProvider.overrideWith(_Auth.new),
  apiClientProvider.overrideWithValue(api.dio),
  runtimeFeatureFlagsProvider.overrideWith(
    (ref) => Stream.value(
      RuntimeFeatureFlags({
        'intentional_dating_enabled': true,
        'photo_themes_enabled': photoThemes,
      }),
    ),
  ),
];

Widget _sheet(_Api api, ThemeEntry entry) => ProviderScope(
  overrides: _overrides(api),
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: ThemeEntrySheet(entry: entry)),
  ),
);

/// The rail on its own. Today itself now shows wall photos in its mixed
/// carousel (see today_wall_test.dart).
Widget _today(_Api api) => ProviderScope(
  overrides: _overrides(api),
  child: const MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: PhotoWallRail(),
      ),
    ),
  ),
);

void _tall(WidgetTester t) {
  t.view.physicalSize = const Size(800, 2400);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

void main() {
  group('ThemeEntry parsing', () {
    test('reads the wall fields', () {
      final entry = ThemeEntry.fromJson(
        entryJson(
          likes: 12,
          liked: true,
          extra: {
            'comment_count': 3,
            'pending_comment_count': 1,
            'allow_featuring': true,
            'featured': true,
            'wall_reach': 50,
            'next_tier': {
              'likes': 100,
              'comments': 10,
              'reach': 100,
              'likes_needed': 38,
              'comments_needed': 4,
            },
          },
        ),
      );
      expect(entry.themeTitle, 'My perfect Sunday');
      expect(entry.likeCount, 12);
      expect(entry.likedByMe, isTrue);
      expect(entry.commentCount, 3);
      expect(entry.pendingCommentCount, 1);
      expect(entry.allowFeaturing, isTrue);
      expect(entry.featured, isTrue);
      expect(entry.wallReach, 50);
      expect(entry.nextTier?.reach, 100);
      expect(entry.nextTier?.likesNeeded, 38);
      expect(entry.firstName, 'Priya');
    });

    test('older payloads without the wall fields parse safely', () {
      final entry = ThemeEntry.fromJson({
        'id': 'e1',
        'theme_id': 't1',
        'author_id': 'a',
        'author_name': 'Priya',
        'caption': 'Hi',
        'alt_text': 'Alt',
        'created_at': '2026-09-28T10:15:00Z',
        'mine': false,
      });
      expect(entry.themeTitle, isEmpty);
      expect(entry.likeCount, 0);
      expect(entry.likedByMe, isFalse);
      expect(entry.commentCount, 0);
      expect(entry.pendingCommentCount, 0);
      expect(entry.allowFeaturing, isFalse);
      expect(entry.featured, isFalse);
      expect(entry.wallReach, 0);
      expect(entry.nextTier, isNull);
    });

    test('photo comments carry entry_id', () {
      final comment = BlogComment.fromJson(commentJson('c1'));
      expect(comment.postId, 'e1');
      expect(comment.isApproved, isTrue);
    });
  });

  Map<String, String> fieldMap(FormData form) => {
    for (final f in form.fields) f.key: f.value,
  };

  group('upload', () {
    Map<String, String> fields(FormData form) => fieldMap(form);

    test('sends allow_featuring only when the member opts in', () {
      final off = themeEntryForm(
        bytes: _png,
        filename: 'p.png',
        caption: 'Hi',
        altText: 'Alt',
      );
      expect(fields(off), {'caption': 'Hi', 'alt_text': 'Alt'});
      final on = themeEntryForm(
        bytes: _png,
        filename: 'p.png',
        caption: 'Hi',
        altText: 'Alt',
        allowFeaturing: true,
      );
      expect(fields(on)['allow_featuring'], 'true');
      expect(on.files.single.key, 'image');
    });

    testWidgets('the dialog switch is off by default and reports its value', (
      t,
    ) async {
      ThemeEntryDetails? result;
      Future<void> run({required bool flip}) async {
        await t.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () async => result = await askEntryDetails(context),
                child: const Text('open'),
              ),
            ),
          ),
        );
        await t.tap(find.text('open'));
        await t.pumpAndSettle();
        expect(find.textContaining('50 likes and 5 comments'), findsOneWidget);
        final key = find.byKey(const ValueKey('photo.upload.allow_featuring'));
        expect(t.widget<SwitchListTile>(key).value, isFalse);
        await t.enterText(find.byType(TextField).at(0), 'Hi');
        await t.pump();
        await t.enterText(find.byType(TextField).at(1), 'Alt');
        await t.pump();
        if (flip) {
          await t.tap(key);
          await t.pump();
          expect(t.widget<SwitchListTile>(key).value, isTrue);
        }
        final share = find.widgetWithText(FilledButton, 'Share');
        await t.tap(share);
        await t.pumpAndSettle();
      }

      await run(flip: false);
      expect(result?.allowFeaturing, isFalse);
      await run(flip: true);
      expect(result?.allowFeaturing, isTrue);
      expect(result?.caption, 'Hi');
    });

    test('uploadThemeEntry puts the form to the entry path', () async {
      final api = _Api((r) => {'entry': entryJson(mine: true)});
      final saved = await uploadThemeEntry(
        api.dio,
        themeId: 't1',
        entryId: 'e1',
        bytes: _png,
        filename: 'p.png',
        caption: 'Hi',
        altText: 'Alt',
        allowFeaturing: true,
      );
      final put = api.requests.single;
      expect(put.method, 'PUT');
      expect(put.path, '/themes/t1/entries/e1');
      final form = put.data as FormData;
      expect(fieldMap(form)['allow_featuring'], 'true');
      expect(saved?.id, 'e1');
    });
  });

  group('likes', () {
    test('a failed like rolls back and rethrows', () async {
      final api = _Api((r) => throw 500);
      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(_Auth.new),
          apiClientProvider.overrideWithValue(api.dio),
        ],
      );
      addTearDown(container.dispose);
      final entry = ThemeEntry.fromJson(entryJson());
      final likes = container.read(photoLikesProvider.notifier);
      final pending = likes.toggle(entry);
      expect(
        container.read(photoLikesProvider)['e1'],
        const BlogLikeState(
          liked: true,
          count: 4,
          reaction: 'love',
          reactions: {'love': 1},
        ),
      );
      await expectLater(pending, throwsA(isA<DioException>()));
      expect(container.read(photoLikesProvider), isEmpty);
      expect(likes.of(entry), const BlogLikeState(liked: false, count: 3));
      expect(api.requests.single.method, 'PUT');
      expect(api.requests.single.path, '/themes/t1/entries/e1/like');
    });

    test('a confirmed unlike adopts the server count', () async {
      final api = _Api((r) => {'entry': entryJson(likes: 7, liked: false)});
      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(_Auth.new),
          apiClientProvider.overrideWithValue(api.dio),
        ],
      );
      addTearDown(container.dispose);
      final entry = ThemeEntry.fromJson(entryJson(likes: 9, liked: true));
      await container.read(photoLikesProvider.notifier).toggle(entry);
      expect(
        container.read(photoLikesProvider)['e1'],
        const BlogLikeState(liked: false, count: 7),
      );
      expect(api.requests.single.method, 'DELETE');
    });
  });

  group('entry sheet', () {
    testWidgets('the author approves pending comments and controls reach', (
      t,
    ) async {
      _tall(t);
      final api = _Api((r) {
        if (r.path.endsWith('/photo')) throw 404;
        if (r.path.endsWith('/comments')) {
          return {
            'comments': [
              commentJson('c1', body: 'Shared already.'),
              commentJson('c2', status: 'pending', body: 'Waiting on you.'),
            ],
          };
        }
        if (r.path.endsWith('/featuring')) {
          return {
            'entry': entryJson(
              author: 'me',
              mine: true,
              extra: {
                'allow_featuring': true,
                'wall_reach': 50,
                'next_tier': {
                  'likes': 100,
                  'comments': 10,
                  'reach': 100,
                  'likes_needed': 38,
                  'comments_needed': 4,
                },
              },
            ),
          };
        }
        return {'comment': commentJson('c2')};
      });
      final entry = ThemeEntry.fromJson(entryJson(author: 'me', mine: true));
      await t.pumpWidget(_sheet(api, entry));
      await t.pumpAndSettle();

      // Own photo: the heart is visible but cannot be pressed.
      final like = t.widget<TextButton>(
        find.byKey(const ValueKey('photo.like.e1')),
      );
      expect(like.onPressed, isNull);
      expect(
        find.byWidgetPredicate(
          (w) => w is Tooltip && w.message == 'You can’t like your own photo',
        ),
        findsOneWidget,
      );

      expect(find.text('Waiting for your approval'), findsOneWidget);
      expect(find.text('Waiting on you.'), findsOneWidget);
      expect(find.byKey(const ValueKey('photo.comment.field')), findsNothing);
      await t.tap(find.byKey(const ValueKey('photo.comment.approve.c2')));
      await t.pumpAndSettle();
      final decision = api.requests.firstWhere(
        (r) => r.path.endsWith('/decision'),
      );
      expect(decision.path, '/themes/t1/entries/e1/comments/c2/decision');
      expect(decision.data, {'decision': 'approve'});

      final reach = find.byKey(const ValueKey('photo.featuring.e1'));
      expect(t.widget<SwitchListTile>(reach).value, isFalse);
      expect(find.text('On 50 walls'), findsNothing);
      await t.tap(reach);
      await t.pumpAndSettle();
      final featuring = api.requests.firstWhere(
        (r) => r.path.endsWith('/featuring'),
      );
      expect(featuring.method, 'POST');
      expect(featuring.data, {'allow': true});
      expect(t.widget<SwitchListTile>(reach).value, isTrue);
      expect(find.text('On 50 walls'), findsOneWidget);
      expect(
        find.text('38 more likes and 4 more comments to reach 100 walls'),
        findsOneWidget,
      );
    });

    testWidgets('other members never see pending comments and can report', (
      t,
    ) async {
      _tall(t);
      final api = _Api((r) {
        if (r.path.endsWith('/photo')) throw 404;
        if (r.path.endsWith('/comments')) {
          return {
            'comments': [
              commentJson('c1', body: 'Shared already.'),
              commentJson('c2', status: 'pending', body: 'Someone else.'),
              commentJson('c3', status: 'pending', mine: true, body: 'Mine.'),
            ],
          };
        }
        return {
          'report': {'id': 'r1'},
        };
      });
      final entry = ThemeEntry.fromJson(entryJson());
      await t.pumpWidget(_sheet(api, entry));
      await t.pumpAndSettle();

      expect(find.text('Waiting for your approval'), findsNothing);
      expect(find.text('Someone else.'), findsNothing);
      expect(find.text('Shared already.'), findsOneWidget);
      expect(find.text('Mine.'), findsOneWidget);
      expect(find.byKey(const ValueKey('photo.comment.field')), findsOneWidget);
      expect(find.byKey(const ValueKey('photo.featuring.e1')), findsNothing);
      final like = t.widget<TextButton>(
        find.byKey(const ValueKey('photo.like.e1')),
      );
      expect(like.onPressed, isNotNull);

      await t.tap(
        find.descendant(
          of: find.byKey(const ValueKey('photo.comment.c1')),
          matching: find.byTooltip('Comment options'),
        ),
      );
      await t.pumpAndSettle();
      await t.tap(find.text('Report comment'));
      await t.pumpAndSettle();
      await t.tap(find.text('Submit report'));
      await t.pumpAndSettle();
      final report = api.requests.firstWhere((r) => r.method == 'POST');
      expect(report.path, '/blog/reports/photo_comment/c1');
    });
  });

  group('Photo wall rail', () {
    Finder covers() => find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          RegExp(
            r'^photo\.cover\.e\d+$',
          ).hasMatch((w.key! as ValueKey<String>).value),
    );

    testWidgets('renders magazine covers for wall photos', (t) async {
      final api = _Api((r) {
        if (r.path == '/themes/wall') {
          return {
            'entries': [
              entryJson(id: 'e1'),
              entryJson(id: 'e2', extra: {'caption': 'Long walk.'}),
            ],
          };
        }
        if (r.path.endsWith('/photo')) {
          return _png;
        }
        if (r.path.endsWith('/comments')) return {'comments': <dynamic>[]};
        return <String, dynamic>{};
      });
      await t.pumpWidget(_today(api));
      await t.pumpAndSettle();
      expect(find.text('Covers on your wall'), findsOneWidget);
      expect(covers(), findsNWidgets(2));
      // Masthead, cover line and byline.
      expect(find.text('MY PERFECT SUNDAY'), findsNWidgets(2));
      expect(find.text('Pancakes, then nowhere to be.'), findsOneWidget);
      expect(find.text('BY PRIYA'), findsNWidgets(2));
      expect(t.takeException(), isNull);

      await t.tap(find.text('Pancakes, then nowhere to be.'));
      await t.pumpAndSettle();
      expect(find.byType(ThemeEntrySheet), findsOneWidget);

      // The full-height sheet has a visible way back, not just a handle.
      await t.tap(find.byKey(const ValueKey('qa.photo_entry.close')));
      await t.pumpAndSettle();
      expect(find.byType(ThemeEntrySheet), findsNothing);
    });

    testWidgets('renders nothing for an empty wall', (t) async {
      final api = _Api(
        (r) => r.path == '/themes/wall'
            ? {'entries': <dynamic>[]}
            : <String, dynamic>{},
      );
      await t.pumpWidget(_today(api));
      await t.pumpAndSettle();
      expect(api.requests.map((r) => r.path), contains('/themes/wall'));
      expect(find.byType(PhotoWallRail), findsOneWidget);
      expect(find.byKey(const ValueKey('photo.wall_rail')), findsNothing);
      expect(find.text('Covers on your wall'), findsNothing);
    });

    testWidgets('a failing wall request is silent', (t) async {
      final api = _Api((r) {
        if (r.path == '/themes/wall') throw 500;
        return <String, dynamic>{};
      });
      await t.pumpWidget(_today(api));
      await t.pumpAndSettle();
      expect(api.requests.map((r) => r.path), contains('/themes/wall'));
      expect(find.byKey(const ValueKey('photo.wall_rail')), findsNothing);
      expect(find.text('Covers on your wall'), findsNothing);
      expect(find.text('Try again'), findsNothing);
      expect(t.takeException(), isNull);
    });
  });
}
