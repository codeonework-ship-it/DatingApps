// Control tests for Cover of the Week and Today's wall
// (lib/features/intentional_dating/today_wall.dart): paging, opening the
// cover, a chapter and the empty-wall actions, their failures and l10n.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/blog/blog_screen.dart';
import 'package:verified_dating_app/features/intentional_dating/today_wall.dart';
import 'package:verified_dating_app/features/photo_themes/photo_theme_widgets.dart';
import 'package:verified_dating_app/features/photo_themes/photo_themes_screen.dart';

import '../../support/qa_api.dart';
import 'intentional_dating_qa_support.dart';

Map<String, dynamic> _post(String id) => {
  'id': id,
  'author_id': 'author-$id',
  'author_name': 'Writer $id',
  'title': 'Chapter $id',
  'body': 'A story members loved, about a long walk home.',
  'audience': 'community',
  'invitation': '',
  'version': 1,
  'photos': <dynamic>[],
  'like_count': 12,
  'liked_by_me': false,
  'comment_count': 3,
  'pending_comment_count': 0,
  'allow_featuring': true,
  'featured': false,
  'view_count': 40,
};

Map<String, dynamic> _entry(String id) => {
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
  'featured': false,
  'wall_reach': 50,
};

/// [count] picks alternating chapter (odd positions) and photo (even).
Map<String, dynamic> _wall(int count) => {
  'day': '2026-10-03',
  'items': [
    for (var i = 1; i <= count; i++)
      i.isOdd
          ? {'kind': 'chapter', 'position': i, 'post': _post('c$i')}
          : {'kind': 'photo', 'position': i, 'entry': _entry('p$i')},
  ],
};

QaApi _api({int wall = 5, bool cover = false}) => QaApi()
  ..json('GET /walls/today', _wall(wall))
  ..json('GET /themes/cover', {
    'cover': cover ? {'week_start': '2026-09-28', 'entry': _entry('p9')} : null,
  })
  ..json('POST /walls/views', {'recorded': true})
  ..json('GET /themes/*/entries/*/comments', {'comments': <dynamic>[]})
  ..on(
    'GET /blog/posts/*',
    (c) => qaOk({'post': _post(c.path.split('/').last)}),
  )
  ..json('GET /blog/posts/*/comments', {'comments': <dynamic>[]})
  ..json('GET /blog/posts', {'posts': <dynamic>[]})
  ..json('GET /themes', {'themes': <dynamic>[]})
  ..json('GET /themes/wall', {'items': <dynamic>[]});

Future<void> _pump(WidgetTester t, QaApi api, {Locale? locale}) => pumpQa(
  t,
  api,
  const Scaffold(
    body: SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: TodayCoverAndWall(),
    ),
  ),
  locale: locale,
  size: const Size(430, 2000),
);

final _en = qaL10n(const Locale('en'));
Finder get _position => find.byKey(const ValueKey('qa.today.wall.position'));
String _positionText(WidgetTester t) => t.widget<Text>(_position).data!;
Finder _chapter(String id) => find.byKey(ValueKey('qa.today.wall.chapter.$id'));

void main() {
  testWidgets('"Next pick" moves the wall one card on until the last '
      '[case:intentional_dating.today_wall.next_pick.action]', (t) async {
    await _pump(t, _api(wall: 3));
    expect(_positionText(t), '1 / 3');
    final next = find.byTooltip(_en.todayWallNext);

    await t.tap(next);
    await qaSettle(t);
    expect(_positionText(t), '2 / 3');
    await t.tap(next);
    await qaSettle(t);
    expect(_positionText(t), '3 / 3');
    expect(_chapter('c3'), findsOneWidget);
    // On the last pick the button is disabled.
    expect(
      t
          .widget<IconButton>(
            find.widgetWithIcon(IconButton, Icons.chevron_right_rounded),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('"Previous pick" moves the wall back to the first card '
      '[case:intentional_dating.today_wall.previous_pick.action]', (t) async {
    await _pump(t, _api(wall: 3));
    final previous = find.widgetWithIcon(
      IconButton,
      Icons.chevron_left_rounded,
    );
    expect(t.widget<IconButton>(previous).onPressed, isNull);
    await t.tap(find.byTooltip(_en.todayWallNext));
    await qaSettle(t);
    await t.tap(find.byTooltip(_en.todayWallNext));
    await qaSettle(t);
    expect(_positionText(t), '3 / 3');

    await t.tap(find.byTooltip(_en.todayWallPrevious));
    await qaSettle(t);
    expect(_positionText(t), '2 / 3');
    await t.tap(find.byTooltip(_en.todayWallPrevious));
    await qaSettle(t);
    expect(_positionText(t), '1 / 3');
    expect(t.widget<IconButton>(previous).onPressed, isNull);
  });

  testWidgets(
    'swiping the wall pages through the picks and updates the '
    'position '
    '[case:intentional_dating.today_wall.today_wall_pages_pagechanged.action]',
    (t) async {
      final api = _api(wall: 4);
      await _pump(t, api);
      final pages = find.byKey(const ValueKey('qa.today.wall.pages'));
      expect(_positionText(t), '1 / 4');

      await t.fling(pages, const Offset(-300, 0), 1200);
      await qaSettle(t);
      expect(_positionText(t), '2 / 4');
      expect(t.widget<PageView>(pages).controller!.page!.round(), 1);
      await t.fling(pages, const Offset(-300, 0), 1200);
      await qaSettle(t);
      expect(_positionText(t), '3 / 4');

      await t.fling(pages, const Offset(300, 0), 1200);
      await qaSettle(t);
      expect(_positionText(t), '2 / 4');
      // Swiping records nothing: only opening a pick counts a view.
      expect(api.writes, isEmpty);
    },
  );

  testWidgets('tapping the cover opens the photo with its comments and '
      'records a view '
      '[case:intentional_dating.today_wall.inkwell_ontap.action]', (t) async {
    final api = _api(cover: true);
    await _pump(t, api);
    expect(find.byType(ThemeEntrySheet), findsNothing);

    await t.tap(find.byKey(const ValueKey('qa.today.cover')));
    await qaSettle(t);

    final sheet = t.widget<ThemeEntrySheet>(find.byType(ThemeEntrySheet));
    expect(sheet.entry.id, 'p9');
    expect(api.sent('POST', '/walls/views').single.body, {
      'kind': 'photo',
      'id': 'p9',
    });
    expect(api.sent('GET', '/themes/t1/entries/p9/comments'), hasLength(1));
    expect(find.text(_en.photoThemesSharedBy('Priya Sharma')), findsOneWidget);
    await idTeardown(t);
  });

  testWidgets('when the cover photo\'s comments fail to load, the sheet shows '
      'the error, keeps the photo, and retry loads them '
      '[case:intentional_dating.today_wall.inkwell_ontap.api_failure]', (
    t,
  ) async {
    final api = _api(
      cover: true,
    )..fail('GET /themes/t1/entries/p9/comments', message: 'Comments resting.');
    await _pump(t, api);
    await t.tap(find.byKey(const ValueKey('qa.today.cover')));
    await qaSettle(t);

    expect(find.byType(ThemeEntrySheet), findsOneWidget);
    expect(find.text('Comments resting.'), findsOneWidget);
    expect(find.text('Pancakes, then nowhere to be.'), findsWidgets);
    final retry = find.byKey(const ValueKey('qa.blog.retry'));
    expect(retry, findsOneWidget);

    api.json('GET /themes/t1/entries/p9/comments', {'comments': <dynamic>[]});
    await t.ensureVisible(retry);
    await t.tap(retry);
    await qaSettle(t);
    expect(api.sent('GET', '/themes/t1/entries/p9/comments'), hasLength(2));
    expect(find.text('Comments resting.'), findsNothing);
    expect(find.byKey(const ValueKey('qa.blog.retry')), findsNothing);
    await idTeardown(t);
  });

  testWidgets('tapping a chapter on the wall opens that chapter and records '
      'a view '
      '[case:intentional_dating.today_wall.today_wall_chapter_x.action]', (
    t,
  ) async {
    final api = _api(wall: 3);
    await _pump(t, api);
    await t.tap(find.byTooltip(_en.todayWallNext));
    await qaSettle(t);
    await t.tap(find.byTooltip(_en.todayWallNext));
    await qaSettle(t);

    await t.tap(_chapter('c3'));
    await qaSettle(t);
    expect(t.widget<BlogDetailScreen>(find.byType(BlogDetailScreen)).id, 'c3');
    expect(api.sent('POST', '/walls/views').single.body, {
      'kind': 'chapter',
      'id': 'c3',
    });
    expect(api.sent('GET', '/blog/posts/c3'), hasLength(1));
    expect(find.text('Chapter c3'), findsOneWidget);
    await idTeardown(t);
  });

  testWidgets('a chapter that fails to load shows the error with retry, and '
      'going back keeps the wall where it was '
      '[case:intentional_dating.today_wall.today_wall_chapter_x.api_failure]', (
    t,
  ) async {
    final api = _api(wall: 3)
      ..fail('GET /blog/posts/c3', message: 'Chapter resting.');
    await _pump(t, api);
    await t.tap(find.byTooltip(_en.todayWallNext));
    await qaSettle(t);
    await t.tap(find.byTooltip(_en.todayWallNext));
    await qaSettle(t);
    await t.tap(_chapter('c3'));
    await qaSettle(t);

    expect(find.byType(BlogDetailScreen), findsOneWidget);
    expect(find.text('Chapter resting.'), findsOneWidget);
    final retry = find.byKey(const ValueKey('qa.blog.retry'));
    expect(retry, findsOneWidget);

    await t.pageBack();
    await qaSettle(t);
    expect(_positionText(t), '3 / 3');
    expect(_chapter('c3'), findsOneWidget);

    await t.tap(_chapter('c3'));
    await qaSettle(t);
    api.json('GET /blog/posts/c3', {'post': _post('c3')});
    await t.tap(find.byKey(const ValueKey('qa.blog.retry')));
    await qaSettle(t);
    expect(api.sent('GET', '/blog/posts/c3').length, greaterThanOrEqualTo(3));
    expect(find.text('Chapter resting.'), findsNothing);
    expect(find.text('Chapter c3'), findsOneWidget);
    await idTeardown(t);
  });

  testWidgets('"Write a chapter" on an empty wall opens the blog '
      '[case:intentional_dating.today_wall.today_wall_write.action]', (
    t,
  ) async {
    final api = _api(wall: 0);
    await _pump(t, api);
    expect(find.byKey(const ValueKey('qa.today.wall.empty')), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('qa.today.wall.write')));
    await qaSettle(t);
    expect(t.widget<BlogScreen>(find.byType(BlogScreen)).authorId, isNull);
    expect(api.sent('GET', '/blog/posts'), isNotEmpty);
    await idTeardown(t);
  });

  testWidgets('"Share a photo" on an empty wall opens Photo Themes '
      '[case:intentional_dating.today_wall.today_wall_share.action]', (
    t,
  ) async {
    final api = _api(wall: 0);
    await _pump(t, api);
    await t.tap(find.byKey(const ValueKey('qa.today.wall.share')));
    await qaSettle(t);
    expect(find.byType(PhotoThemesScreen), findsOneWidget);
    expect(api.sent('GET', '/themes'), isNotEmpty);
    await idTeardown(t);
  });

  testWidgets('the cover and the wall render translated in every locale '
      '[case:intentional_dating.today_wall.l10n]', (t) async {
    const fixture = {
      'Chapter c1',
      'A story members loved, about a long walk home.',
      'Pancakes, then nowhere to be.',
      'MY PERFECT SUNDAY',
      'PRIYA',
      'Writer c1',
    };
    await idSweepLocales(
      t,
      pump: (locale) => _pump(t, _api(wall: 3, cover: true), locale: locale),
      labels: (l10n) => [
        l10n.todayCoverTitle,
        l10n.todayThisWeek,
        l10n.todayCoverBy('PRIYA'),
        l10n.todayWallLabel,
        l10n.todayWallTitle,
        l10n.todayWallCaption,
        l10n.todayWallChapter,
        l10n.todayWallBy('Writer c1'),
      ],
      fixture: fixture,
    );
    await idSweepLocales(
      t,
      pump: (locale) => _pump(t, _api(wall: 0), locale: locale),
      labels: (l10n) => [
        l10n.todayWallTitle,
        l10n.todayWallEmpty,
        l10n.todayWallWrite,
        l10n.todayWallShare,
      ],
    );
  });
}
