// Control tests for Today's "Something to talk about" activities
// (lib/features/intentional_dating/today_activities.dart): every tile opens
// its screen with the right arguments, through the real Navigator.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/blog/blog_screen.dart';
import 'package:verified_dating_app/features/clubs/clubs_screen.dart';
import 'package:verified_dating_app/features/first_chapter/chapter_studio_screen.dart';
import 'package:verified_dating_app/features/intentional_dating/today_activities.dart';
import 'package:verified_dating_app/features/photo_themes/photo_themes_screen.dart';

import '../../support/qa_api.dart';
import 'intentional_dating_qa_support.dart';

/// The reads the opened screens make, answered empty.
QaApi _api() => QaApi()
  ..json('GET /clubs', {'clubs': <dynamic>[]})
  ..json('GET /themes', {'themes': <dynamic>[]})
  ..json('GET /themes/wall', {'items': <dynamic>[]})
  ..json('GET /blog/posts', {'posts': <dynamic>[]})
  ..json('GET /chapters/catalogue', <String, dynamic>{})
  ..json('GET /chapters/publications', {'publications': <dynamic>[]})
  ..json('GET /matches/me', {'matches': <dynamic>[]});

Future<void> _pump(
  WidgetTester t,
  QaApi api, {
  Locale? locale,
  Map<String, bool> flags = const {},
}) => pumpQa(
  t,
  api,
  const Scaffold(
    body: SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: TodayActivities(),
    ),
  ),
  locale: locale,
  flags: flags,
  size: const Size(430, 1400),
);

final _en = qaL10n(const Locale('en'));

Future<void> _open(WidgetTester t, Finder tile) async {
  await t.ensureVisible(tile);
  await t.tap(tile);
  await qaSettle(t);
}

void main() {
  testWidgets(
    'the blog feature under "Something to talk about" opens the '
    'whole blog '
    '[case:intentional_dating.today_activities.something_to_talk_about.action]',
    (t) async {
      final api = _api();
      await _pump(t, api);
      expect(find.text(_en.todaySectionTalk), findsOneWidget);
      await _open(t, find.byKey(const ValueKey('qa.today.blog')));

      final blog = t.widget<BlogScreen>(find.byType(BlogScreen));
      expect(blog.authorId, isNull);
      expect(api.sent('GET', '/blog/posts'), isNotEmpty);
      await idTeardown(t);
    },
  );

  testWidgets('"Book clubs" opens clubs filtered to books '
      '[case:intentional_dating.today_activities.today_book_clubs.action]', (
    t,
  ) async {
    final api = _api();
    await _pump(t, api);
    await _open(t, find.byKey(const ValueKey('qa.today.book_clubs')));

    expect(t.widget<ClubsScreen>(find.byType(ClubsScreen)).initialKind, 'book');
    expect(api.sent('GET', '/clubs').last.query['kind'], 'book');
    await idTeardown(t);
  });

  testWidgets('"Film clubs" opens clubs filtered to films '
      '[case:intentional_dating.today_activities.today_film_clubs.action]', (
    t,
  ) async {
    final api = _api();
    await _pump(t, api);
    await _open(t, find.byKey(const ValueKey('qa.today.film_clubs')));

    expect(t.widget<ClubsScreen>(find.byType(ClubsScreen)).initialKind, 'film');
    expect(api.sent('GET', '/clubs').last.query['kind'], 'film');
    await idTeardown(t);
  });

  testWidgets('"Photo Themes" opens the photo prompts '
      '[case:intentional_dating.today_activities.today_photo_themes.action]', (
    t,
  ) async {
    final api = _api();
    await _pump(t, api);
    await _open(t, find.byKey(const ValueKey('qa.today.photo_themes')));

    expect(find.byType(PhotoThemesScreen), findsOneWidget);
    expect(api.sent('GET', '/themes'), isNotEmpty);
    await idTeardown(t);
  });

  testWidgets(
    '"First Chapter Studio" opens the studio without a match '
    '[case:intentional_dating.today_activities.today_chapter_studio.action]',
    (t) async {
      final api = _api();
      await _pump(t, api);
      await _open(t, find.byKey(const ValueKey('qa.today.chapter_studio')));

      final studio = t.widget<ChapterStudioScreen>(
        find.byType(ChapterStudioScreen),
      );
      expect(studio.matchId, isNull);
      expect(studio.partnerName, isNull);
      expect(api.sent('GET', '/chapters/catalogue'), isNotEmpty);
      await idTeardown(t);
    },
  );

  testWidgets('club and photo tiles follow their runtime flags', (t) async {
    await _pump(
      t,
      _api(),
      flags: {'clubs_enabled': false, 'photo_themes_enabled': false},
    );
    expect(find.byKey(const ValueKey('qa.today.book_clubs')), findsNothing);
    expect(find.byKey(const ValueKey('qa.today.film_clubs')), findsNothing);
    expect(find.byKey(const ValueKey('qa.today.photo_themes')), findsNothing);
    expect(find.byKey(const ValueKey('qa.today.chapter_studio')), findsOne);
    await idTeardown(t);
  });

  testWidgets('the activities render translated in every locale '
      '[case:intentional_dating.today_activities.l10n]', (t) async {
    await idSweepLocales(
      t,
      pump: (locale) => _pump(t, _api(), locale: locale),
      labels: (l10n) => [
        l10n.todaySectionTalk,
        l10n.todayTalkCaption,
        l10n.todayBlogTitle,
        l10n.todayBlogSubtitle,
        l10n.todayBookClubsTitle,
        l10n.todayBookClubsSubtitle,
        l10n.todayFilmClubsTitle,
        l10n.todayFilmClubsSubtitle,
        l10n.todayPhotoThemesTitle,
        l10n.todayPhotoThemesSubtitle,
        l10n.todayChapterStudioTitle,
        l10n.todayChapterStudioSubtitle,
      ],
    );
  });
}
