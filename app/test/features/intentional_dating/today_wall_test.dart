import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/core/providers/runtime_feature_flags_provider.dart';
import 'package:verified_dating_app/core/theme/theme_presets.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/blog/blog_data.dart';
import 'package:verified_dating_app/features/blog/blog_screen.dart';
import 'package:verified_dating_app/features/intentional_dating/today_introductions.dart';
import 'package:verified_dating_app/features/intentional_dating/today_wall.dart';
import 'package:verified_dating_app/features/photo_themes/photo_theme_widgets.dart';
import 'package:verified_dating_app/features/photo_themes/photo_themes_data.dart';
import 'package:verified_dating_app/features/walls/today_wall_data.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

class _Auth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(isAuthenticated: true, userId: 'me');
}

Map<String, dynamic> postJson(String id, {bool featured = true}) => {
  'id': id,
  'author_id': 'author-$id',
  'author_name': 'Writer $id',
  'title': 'Chapter $id',
  'body': 'A story members loved,\n\nabout a long walk home.',
  'audience': 'community',
  'invitation': '',
  'version': 1,
  'photos': <dynamic>[],
  'like_count': 12,
  'liked_by_me': false,
  'comment_count': 3,
  'pending_comment_count': 0,
  'allow_featuring': true,
  'featured': featured,
  'view_count': 40,
};

Map<String, dynamic> entryJson(String id) => {
  'id': id,
  'theme_id': 't1',
  'author_id': 'author-$id',
  'author_name': 'Priya Sharma',
  'caption': 'Pancakes, then nowhere to be.',
  'alt_text': 'A stack of pancakes on a balcony table',
  'created_at': '2026-09-28T10:15:00Z',
  'mine': false,
  'theme_title': 'My perfect Sunday',
  'like_count': 21,
  'liked_by_me': false,
  'comment_count': 4,
  'pending_comment_count': 0,
  'allow_featuring': true,
  'featured': true,
  'wall_reach': 50,
};

/// [count] items alternating chapter (odd positions) and photo (even).
Map<String, dynamic> wallJson(int count) => {
  'day': '2026-10-01',
  'items': [
    for (var i = 1; i <= count; i++)
      i.isOdd
          ? {'kind': 'chapter', 'position': i, 'post': postJson('c$i')}
          : {'kind': 'photo', 'position': i, 'entry': entryJson('p$i')},
  ],
};

typedef _Handler = FutureOr<Object?> Function(RequestOptions r);

/// Fake API built on [InterceptorsWrapper]: [handler] returns response data,
/// or throws an int to reject with that HTTP status.
class _Api {
  _Api({Object? wall, Object? cover, _Handler? other})
    : _wall = wall ?? wallJson(0),
      _cover = cover ?? {'cover': null},
      _other = other;
  final Object _wall;
  final Object _cover;
  final _Handler? _other;
  final requests = <RequestOptions>[];

  List<RequestOptions> get views =>
      requests.where((r) => r.path == '/walls/views').toList();

  FutureOr<Object?> _handle(RequestOptions r) {
    switch (r.path) {
      case '/walls/today':
        if (_wall is int) {
          throw _wall;
        }
        return _wall;
      case '/themes/cover':
        if (_cover is int) {
          throw _cover;
        }
        return _cover;
      case '/walls/views':
        return {'recorded': true};
    }
    if (r.path.endsWith('/comments')) {
      return {'comments': <dynamic>[]};
    }
    if (r.path.startsWith('/blog/posts/')) {
      return {'post': postJson(r.path.split('/').last)};
    }
    if (r.path.endsWith('/photo')) {
      throw 404;
    }
    return _other?.call(r) ?? <String, dynamic>{};
  }

  late final Dio dio = Dio()
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (r, h) async {
          requests.add(r);
          try {
            final data = await _handle(r);
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

Widget host(_Api api, {double scale = 1, Widget? home}) => ProviderScope(
  overrides: [
    authNotifierProvider.overrideWith(_Auth.new),
    apiClientProvider.overrideWithValue(api.dio),
    runtimeFeatureFlagsProvider.overrideWith(
      (ref) => Stream.value(
        RuntimeFeatureFlags({
          'intentional_dating_enabled': true,
          'photo_themes_enabled': true,
        }),
      ),
    ),
  ],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: ThemePresets.themeFor(ThemePresets.realLife),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home:
        home ??
        const Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: TodayCoverAndWall(),
          ),
        ),
  ),
);

void phone(WidgetTester t, {double height = 2000}) {
  t.view.physicalSize = Size(390, height);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

Finder wallCards() => find.byWidgetPredicate((w) {
  final key = w.key;
  return key is ValueKey<String> &&
      RegExp(r'^qa\.today\.wall\.(chapter|photo)\.').hasMatch(key.value);
});

void main() {
  group('parsing', () {
    test('view_count is optional and defaults to 0', () {
      final post = BlogPost.fromJson(postJson('c1')..remove('view_count'));
      expect(post.viewCount, 0);
      expect(BlogPost.fromJson(postJson('c1')).viewCount, 40);
      final entry = ThemeEntry.fromJson(entryJson('p1'));
      expect(entry.viewCount, 0);
      expect(
        ThemeEntry.fromJson(entryJson('p1')..['view_count'] = 7).viewCount,
        7,
      );
    });

    test('the wall keeps both kinds, caps at ten and skips bad items', () {
      final json = wallJson(12);
      (json['items'] as List)
        ..insert(0, {'kind': 'poll', 'position': 0})
        ..insert(1, {'kind': 'chapter', 'position': 0, 'post': 'oops'});
      final wall = TodayWall.fromJson(json);
      expect(wall.day, '2026-10-01');
      expect(wall.items, hasLength(10));
      expect(wall.items.first.kind, WallKind.chapter);
      expect(wall.items.first.id, 'c1');
      expect(wall.items[1].kind, WallKind.photo);
      expect(wall.items[1].entry!.firstName, 'Priya');
    });

    test('a null cover parses as no cover', () {
      expect(CoverOfTheWeek.tryParse({'cover': null}), isNull);
      final cover = CoverOfTheWeek.tryParse({
        'cover': {'week_start': '2026-09-28', 'entry': entryJson('p9')},
      });
      expect(cover!.entry.id, 'p9');
      expect(cover.weekStart, DateTime(2026, 9, 28));
    });

    test('recordWallView posts kind and id and never throws', () async {
      final api = _Api();
      expect(
        await recordWallView(api.dio, kind: WallKind.photo, id: 'p1'),
        isTrue,
      );
      expect(api.views.single.data, {'kind': 'photo', 'id': 'p1'});
      final failing = _Api(other: (_) => throw 500);
      expect(
        await recordWallView(failing.dio, kind: WallKind.chapter, id: ''),
        isFalse,
      );
    });
  });

  group('Today wall carousel', () {
    testWidgets('shows up to ten mixed picks with a position indicator', (
      t,
    ) async {
      phone(t);
      final api = _Api(wall: wallJson(12));
      await t.pumpWidget(host(api));
      await t.pumpAndSettle();

      expect(find.text('Today’s wall'), findsOneWidget);
      expect(
        find.text('Stories and photos members loved — new picks every day'),
        findsOneWidget,
      );
      expect(find.text('1 / 10'), findsOneWidget);
      // A chapter first, with the next card (a photo) peeking beside it.
      expect(
        find.byKey(const ValueKey('qa.today.wall.chapter.c1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('qa.today.wall.photo.p2')),
        findsOneWidget,
      );
      expect(find.text('Chapter c1'), findsOneWidget);
      expect(find.text('Featured'), findsWidgets);
      expect(find.text('by Writer c1'), findsOneWidget);
      expect(find.text('MY PERFECT SUNDAY'), findsWidgets);
      expect(t.takeException(), isNull);

      // Every card on the wall shares one height and the full card width.
      final chapter = t.getSize(
        find.byKey(const ValueKey('qa.today.wall.chapter.c1')),
      );
      final photo = t.getSize(
        find.byKey(const ValueKey('qa.today.wall.photo.p2')),
      );
      expect(chapter.height, photo.height);
      expect(chapter.width, photo.width);
      expect(chapter.width, greaterThan(350 * 0.85));

      // Paging through to the end never shows an eleventh item.
      for (var i = 0; i < 12; i++) {
        await t.tap(find.byTooltip('Next pick'));
        await t.pumpAndSettle();
      }
      expect(find.text('10 / 10'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('qa.today.wall.photo.p10')),
        findsOneWidget,
      );
      expect(find.text('Chapter c11'), findsNothing);
      await t.tap(find.byTooltip('Previous pick'));
      await t.pumpAndSettle();
      expect(find.text('9 / 10'), findsOneWidget);
    });

    testWidgets('fits large text without overflow', (t) async {
      phone(t, height: 2400);
      final api = _Api(
        wall: wallJson(3),
        cover: {
          'cover': {'week_start': '2026-09-28', 'entry': entryJson('p9')},
        },
      );
      await t.pumpWidget(host(api, scale: 1.3));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('qa.today.cover')), findsOneWidget);
      expect(find.text('1 / 3'), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.pumpWidget(host(api, scale: 2));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });

    testWidgets('opening a chapter records a view and opens it', (t) async {
      phone(t);
      final api = _Api(wall: wallJson(2));
      await t.pumpWidget(host(api));
      await t.pumpAndSettle();
      expect(api.views, isEmpty);

      await t.tap(find.text('Chapter c1'));
      await t.pumpAndSettle();
      expect(find.byType(BlogDetailScreen), findsOneWidget);
      expect(api.views.single.method, 'POST');
      expect(api.views.single.data, {'kind': 'chapter', 'id': 'c1'});
    });

    testWidgets('opening a photo records a view and opens its sheet', (
      t,
    ) async {
      phone(t);
      final api = _Api(
        wall: {
          'day': '2026-10-01',
          'items': [
            {'kind': 'photo', 'position': 1, 'entry': entryJson('p1')},
          ],
        },
      );
      await t.pumpWidget(host(api));
      await t.pumpAndSettle();
      expect(find.text('1 / 1'), findsOneWidget);

      await t.tap(find.byKey(const ValueKey('qa.today.wall.photo.p1')));
      await t.pumpAndSettle();
      expect(find.byType(ThemeEntrySheet), findsOneWidget);
      expect(api.views.single.data, {'kind': 'photo', 'id': 'p1'});
    });

    testWidgets('an empty wall invites the member to write or share', (
      t,
    ) async {
      phone(t);
      final api = _Api();
      await t.pumpWidget(host(api));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('qa.today.wall.empty')), findsOneWidget);
      expect(
        find.text(
          'Your wall fills up as members share stories and photos they love',
        ),
        findsOneWidget,
      );
      expect(find.text('Share a photo'), findsOneWidget);
      expect(find.textContaining(' / '), findsNothing);

      await t.tap(find.text('Write a chapter'));
      await t.pumpAndSettle();
      expect(find.byType(BlogScreen), findsOneWidget);
    });

    testWidgets('a failing wall request hides the section', (t) async {
      phone(t);
      final api = _Api(wall: 500);
      await t.pumpWidget(host(api));
      await t.pumpAndSettle();
      expect(api.requests.map((r) => r.path), contains('/walls/today'));
      expect(find.byKey(const ValueKey('qa.today.wall')), findsNothing);
      expect(find.text('Try again'), findsNothing);
      expect(t.takeException(), isNull);
    });
  });

  group('Cover of the Week', () {
    testWidgets('renders the cover and opens it with a recorded view', (
      t,
    ) async {
      phone(t);
      final api = _Api(
        wall: 500,
        cover: {
          'cover': {'week_start': '2026-09-28', 'entry': entryJson('p9')},
        },
      );
      await t.pumpWidget(host(api));
      await t.pumpAndSettle();

      expect(find.byKey(const ValueKey('qa.today.cover')), findsOneWidget);
      expect(find.text('COVER OF THE WEEK'), findsOneWidget);
      expect(find.text('This week'), findsOneWidget);
      expect(find.text('MY PERFECT SUNDAY'), findsOneWidget);
      expect(find.text('Pancakes, then nowhere to be.'), findsOneWidget);
      expect(find.text('BY PRIYA'), findsOneWidget);
      expect(find.text('21'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      // Edge to edge within the gutters, portrait 4:5.
      final size = t.getSize(find.byKey(const ValueKey('qa.today.cover')));
      expect(size.width, 350);
      expect(size.height, closeTo(350 * 5 / 4, 0.5));
      expect(t.takeException(), isNull);

      await t.tap(find.byKey(const ValueKey('qa.today.cover')));
      await t.pumpAndSettle();
      expect(find.byType(ThemeEntrySheet), findsOneWidget);
      expect(api.views.single.data, {'kind': 'photo', 'id': 'p9'});
    });

    testWidgets('renders nothing for a null cover', (t) async {
      phone(t);
      final api = _Api(wall: 500);
      await t.pumpWidget(host(api));
      await t.pumpAndSettle();
      expect(api.requests.map((r) => r.path), contains('/themes/cover'));
      expect(find.byKey(const ValueKey('qa.today.cover')), findsNothing);
      expect(
        find.byKey(const ValueKey('qa.today.cover.loading')),
        findsNothing,
      );
      expect(find.text('COVER OF THE WEEK'), findsNothing);
    });

    testWidgets('a failing cover request is silent', (t) async {
      phone(t);
      final api = _Api(wall: wallJson(1), cover: 500);
      await t.pumpWidget(host(api));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('qa.today.cover')), findsNothing);
      expect(find.byKey(const ValueKey('qa.today.wall')), findsOneWidget);
    });

    testWidgets('sits beside the wall on wide screens', (t) async {
      t.view.physicalSize = const Size(1200, 1600);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final api = _Api(
        wall: wallJson(4),
        cover: {
          'cover': {'week_start': '2026-09-28', 'entry': entryJson('p9')},
        },
      );
      await t.pumpWidget(host(api));
      await t.pumpAndSettle();
      final cover = t.getRect(find.byKey(const ValueKey('qa.today.cover')));
      final wall = t.getRect(find.byKey(const ValueKey('qa.today.wall')));
      expect(cover.top, wall.top);
      expect(wall.left, greaterThan(cover.right));
      expect(t.takeException(), isNull);
    });
  });

  group('the whole Today screen', () {
    for (final (width, scale) in [(390.0, 1.3), (768.0, 1.3), (1440.0, 1.0)]) {
      testWidgets('lays out at $width with text x$scale', (t) async {
        t.view.physicalSize = Size(width, 4000);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        final api = _Api(
          wall: wallJson(10),
          cover: {
            'cover': {'week_start': '2026-09-28', 'entry': entryJson('p9')},
          },
        );
        await t.pumpWidget(
          host(
            api,
            scale: scale,
            home: TodayIntroductions(onOpenProfile: (_) {}, onBrowse: () {}),
          ),
        );
        await t.pumpAndSettle();
        expect(find.text('TODAY'), findsOneWidget);
        expect(find.byKey(const ValueKey('qa.today.date')), findsOneWidget);
        expect(find.byKey(const ValueKey('qa.today.cover')), findsOneWidget);
        expect(find.byKey(const ValueKey('qa.today.wall')), findsOneWidget);
        expect(find.byKey(const ValueKey('qa.today.blog')), findsOneWidget);
        expect(find.byKey(const ValueKey('qa.today.rhythm')), findsOneWidget);
        // Sections run in the brief's order.
        double top(String key) => t.getTopLeft(find.byKey(ValueKey(key))).dy;
        expect(top('qa.today.cover'), lessThan(top('qa.today.blog')));
        expect(top('qa.today.wall'), lessThan(top('qa.today.blog')));
        expect(top('qa.today.blog'), lessThan(top('qa.today.rhythm')));
        // Grid tiles in a row share one height.
        expect(
          t.getSize(find.byKey(const ValueKey('qa.today.photo_themes'))).height,
          t
              .getSize(find.byKey(const ValueKey('qa.today.chapter_studio')))
              .height,
        );
        expect(t.takeException(), isNull);
      });
    }
  });
}
