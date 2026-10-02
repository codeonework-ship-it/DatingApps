// Control-level tests for following writers (BlogFollowButton on a chapter
// and in Writers you follow) and the Writers you follow screen. Every test
// asserts the request the app sent and what the member sees.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/blog/blog_follow.dart';
import 'package:verified_dating_app/features/blog/blog_screen.dart';
import 'package:verified_dating_app/features/blog/blog_writers_screen.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

import '../../support/qa_api.dart';

final AppLocalizations _en = qaL10n(const Locale('en'));

const _follow = ValueKey('blog.follow.writer');

Map<String, dynamic> _chapter({
  String id = 'p1',
  String title = 'Rain on the terrace',
  bool subscribed = false,
  int followers = 12,
}) => {
  'id': id,
  'author_id': 'writer',
  'author_name': 'Meera',
  'title': title,
  'body': 'We counted the drops on the railing.',
  'audience': 'community',
  'invitation': '',
  'version': 1,
  'photos': <dynamic>[],
  'author_subscribed': subscribed,
  'author_subscriber_count': followers,
};

Map<String, dynamic> _writer(
  String id,
  String name, {
  int followers = 3,
  String latestTitle = 'Rain on the terrace',
  String latestPostId = 'p1',
}) => {
  'author_id': id,
  'name': name,
  'subscriber_count': followers,
  'latest_title': latestTitle,
  'latest_post_id': latestPostId,
};

QaApi _api({Map<String, dynamic>? chapter}) {
  final api = QaApi()
    ..json('GET /blog/posts/*', {'post': chapter ?? _chapter()})
    ..json('GET /blog/posts/*/comments', {'comments': <dynamic>[]})
    ..json('POST /walls/views', {'recorded': true});
  return api;
}

String _label(WidgetTester tester) => tester
    .widget<Text>(
      find.descendant(of: find.byKey(_follow), matching: find.byType(Text)),
    )
    .data!;

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await qaSettle(tester);
}

void main() {
  group('follow on a chapter', () {
    testWidgets(
      'Follow their chapters follows at once and shows the confirmed count '
      '[case:blog.blog_follow.follow_their_chapters.action]',
      (tester) async {
        final api = _api()
          ..on(
            'PUT /blog/authors/*/subscription',
            (_) => const QaReply(200, {
              'subscribed': true,
              'subscriber_count': 14,
            }, delay: Duration(milliseconds: 300)),
          );
        await pumpQa(tester, api, const BlogDetailScreen(id: 'p1'));
        expect(_label(tester), _en.blogFollowTheirChapters);
        expect(find.text(_en.blogFollowerCount(12)), findsOneWidget);

        await tester.tap(find.byKey(_follow));
        await tester.pump();
        // Optimistic: flipped before the server answers.
        expect(_label(tester), _en.blogFollowingButton);
        expect(find.text(_en.blogFollowerCount(13)), findsOneWidget);
        // A second tap while the first is in flight sends nothing more.
        await tester.tap(find.byKey(_follow));
        await qaSettle(tester);

        expect(api.writeLines, ['PUT /blog/authors/writer/subscription']);
        expect(api.writes.single.data, isNull);
        expect(_label(tester), _en.blogFollowingButton);
        expect(find.text(_en.blogFollowerCount(14)), findsOneWidget);
        expect(qaSnackText(tester), isNull);
      },
    );

    testWidgets('a failed follow rolls back, explains and can be retried '
        '[case:blog.blog_follow.follow_their_chapters.api_failure]', (
      tester,
    ) async {
      var attempts = 0;
      final api = _api()
        ..on('PUT /blog/authors/*/subscription', (_) {
          attempts++;
          return switch (attempts) {
            1 => qaError(503, message: 'Following is paused for a moment.'),
            2 => const QaReply(500, <String, dynamic>{}),
            _ => qaOk({'subscribed': true, 'subscriber_count': 13}),
          };
        });
      await pumpQa(tester, api, const BlogDetailScreen(id: 'p1'));
      await _tap(tester, find.byKey(_follow));
      expect(qaSnackText(tester), 'Following is paused for a moment.');
      expect(_label(tester), _en.blogFollowTheirChapters);
      expect(find.text(_en.blogFollowerCount(12)), findsOneWidget);
      expect(api.writes, hasLength(1));

      // Without a server message the localized fallback is shown.
      await _tap(tester, find.byKey(_follow));
      expect(qaSnackText(tester), _en.blogFollowFailed);
      expect(_label(tester), _en.blogFollowTheirChapters);

      await _tap(tester, find.byKey(_follow));
      expect(api.writes, hasLength(3));
      expect(_label(tester), _en.blogFollowingButton);
      expect(find.text(_en.blogFollowerCount(13)), findsOneWidget);
    });

    testWidgets('Following stops following and shows the confirmed count '
        '[case:blog.blog_follow.following.action]', (tester) async {
      final api = _api(chapter: _chapter(subscribed: true, followers: 5))
        ..json('DELETE /blog/authors/*/subscription', {
          'subscribed': false,
          'subscriber_count': 4,
        });
      await pumpQa(tester, api, const BlogDetailScreen(id: 'p1'));
      expect(_label(tester), _en.blogFollowingButton);
      expect(find.text(_en.blogFollowerCount(5)), findsOneWidget);

      await _tap(tester, find.byKey(_follow));
      expect(api.writeLines, ['DELETE /blog/authors/writer/subscription']);
      expect(_label(tester), _en.blogFollowTheirChapters);
      expect(find.text(_en.blogFollowerCount(4)), findsOneWidget);
    });

    testWidgets(
      'a failed unfollow keeps following, explains and can be retried '
      '[case:blog.blog_follow.following.api_failure]',
      (tester) async {
        var attempts = 0;
        final api = _api(chapter: _chapter(subscribed: true, followers: 5))
          ..on('DELETE /blog/authors/*/subscription', (_) {
            attempts++;
            return switch (attempts) {
              1 => qaOffline,
              2 => const QaReply(500, <String, dynamic>{}),
              _ => qaOk({'subscribed': false, 'subscriber_count': 4}),
            };
          });
        await pumpQa(tester, api, const BlogDetailScreen(id: 'p1'));
        await _tap(tester, find.byKey(_follow));
        expect(qaSnackText(tester), _en.networkCannotReachService);
        expect(_label(tester), _en.blogFollowingButton);
        expect(find.text(_en.blogFollowerCount(5)), findsOneWidget);

        await _tap(tester, find.byKey(_follow));
        expect(qaSnackText(tester), _en.blogUnfollowFailed);
        expect(_label(tester), _en.blogFollowingButton);

        await _tap(tester, find.byKey(_follow));
        expect(api.writes, hasLength(3));
        expect(_label(tester), _en.blogFollowTheirChapters);
        expect(find.text(_en.blogFollowerCount(4)), findsOneWidget);
      },
    );

    testWidgets(
      'the follow button and rewards sheet are translated in every locale '
      '[case:blog.blog_follow.l10n]',
      (tester) async {
        for (final locale in qaLocales) {
          final l10n = qaL10n(locale);
          await tester.pumpWidget(const SizedBox());
          await pumpQa(
            tester,
            _api(),
            const BlogDetailScreen(id: 'p1'),
            locale: locale,
          );
          expect(tester.takeException(), isNull, reason: '$locale chapter');
          expect(_label(tester), l10n.blogFollowTheirChapters);
          expect(find.text(l10n.blogFollowerCount(12)), findsOneWidget);

          await tester.pumpWidget(const SizedBox());
          await pumpQa(
            tester,
            _api(),
            Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => showBlogRewardsSheet(context),
                    child: const Text('rewards'),
                  ),
                ),
              ),
            ),
            locale: locale,
          );
          await tester.tap(find.text('rewards'));
          await qaSettle(tester);
          expect(tester.takeException(), isNull, reason: '$locale rewards');
          expect(find.text(l10n.blogRewardsTitle), findsOneWidget);
          expect(find.text(l10n.blogRewardsIntro), findsOneWidget);
          expect(
            find.text(l10n.blogRewardDailyCap(50)),
            findsWidgets,
            reason: '$locale caps',
          );
        }
      },
    );
  });

  group('Writers you follow', () {
    testWidgets(
      'a list that cannot load explains and Try again reloads '
      '[case:blog.blog_writers.writers_you_follow_could_not_loa_retry.action]',
      (tester) async {
        var loads = 0;
        final api = _api()
          ..on('GET /blog/subscriptions', (_) {
            loads++;
            return switch (loads) {
              1 => qaError(503, message: 'Writers are resting. Try soon.'),
              2 => const QaReply(500, <String, dynamic>{}),
              _ => qaOk({
                'writers': [_writer('writer', 'Meera')],
              }),
            };
          });
        await pumpQa(tester, api, const BlogWritersScreen());
        expect(find.text('Writers are resting. Try soon.'), findsOneWidget);

        await _tap(tester, find.byKey(const ValueKey('qa.blog.retry')));
        expect(find.text(_en.blogWritersLoadFailed), findsOneWidget);

        await _tap(tester, find.byKey(const ValueKey('qa.blog.retry')));
        expect(api.sent('GET', '/blog/subscriptions'), hasLength(3));
        expect(find.text('Meera'), findsOneWidget);
        expect(find.text(_en.blogFollowerCount(3)), findsOneWidget);
        expect(find.byKey(const ValueKey('qa.blog.retry')), findsNothing);
      },
    );

    testWidgets('pull to refresh reloads the writers '
        '[case:blog.blog_writers.an_untitled_chapter_onrefresh.action]', (
      tester,
    ) async {
      var loads = 0;
      final api = _api()
        ..on('GET /blog/subscriptions', (_) {
          loads++;
          return qaOk({
            'writers': [
              _writer('writer', 'Meera'),
              if (loads > 1) _writer('ravi', 'Ravi', latestPostId: 'p2'),
            ],
          });
        });
      await pumpQa(tester, api, const BlogWritersScreen());
      expect(find.text('Ravi'), findsNothing);

      await tester.fling(
        find.byType(RefreshIndicator),
        const Offset(0, 500),
        1000,
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await qaSettle(tester);

      expect(api.sent('GET', '/blog/subscriptions'), hasLength(2));
      expect(find.text('Ravi'), findsOneWidget);
      expect(find.text('Meera'), findsOneWidget);
    });

    testWidgets('an empty list explains how to follow writers '
        '[case:blog.blog_writers.an_untitled_chapter_onrefresh.action]', (
      tester,
    ) async {
      final api = _api()
        ..json('GET /blog/subscriptions', {'writers': <dynamic>[]});
      await pumpQa(tester, api, const BlogWritersScreen());
      expect(find.byKey(const ValueKey('blog.writers.empty')), findsOneWidget);
      expect(find.text(_en.blogNoWriters), findsOneWidget);
      expect(find.text(_en.blogNoWritersBody), findsOneWidget);
    });

    testWidgets(
      'Latest: An untitled chapter counts a view and opens that chapter '
      '[case:blog.blog_writers.an_untitled_chapter.action]',
      (tester) async {
        final api =
            _api(
              chapter: _chapter(id: 'p9', title: ''),
            )..json('GET /blog/subscriptions', {
              'writers': [
                _writer('writer', 'Meera', latestTitle: '', latestPostId: 'p9'),
              ],
            });
        await pumpQa(tester, api, const BlogWritersScreen());
        final latest = find.byKey(
          const ValueKey('qa.blog.writer.latest.writer'),
        );
        expect(
          find.descendant(
            of: latest,
            matching: find.text(_en.blogLatest(_en.blogUntitled)),
          ),
          findsOneWidget,
        );

        await _tap(tester, latest);
        expect(api.sent('POST', '/walls/views').map((c) => c.body), [
          {'kind': 'chapter', 'id': 'p9'},
        ]);
        expect(find.byType(BlogDetailScreen), findsOneWidget);
        expect(api.sent('GET', '/blog/posts/p9'), hasLength(1));
        // An untitled chapter reads as such on its page too.
        expect(find.text(_en.blogUntitled), findsOneWidget);
        expect(
          find.text('We counted the drops on the railing.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'a failed view count still opens the chapter; a chapter that cannot load '
      'explains [case:blog.blog_writers.an_untitled_chapter.api_failure]',
      (tester) async {
        var loads = 0;
        final api = _api()
          ..json('GET /blog/subscriptions', {
            'writers': [_writer('writer', 'Meera', latestPostId: 'p9')],
          })
          ..fail('POST /walls/views')
          ..on('GET /blog/posts/*', (_) {
            loads++;
            return loads == 1
                ? qaError(404, message: 'This chapter is no longer shared.')
                : qaOk({'post': _chapter(id: 'p9')});
          });
        await pumpQa(tester, api, const BlogWritersScreen());
        await _tap(
          tester,
          find.byKey(const ValueKey('qa.blog.writer.latest.writer')),
        );
        expect(find.byType(BlogDetailScreen), findsOneWidget);
        expect(find.text('This chapter is no longer shared.'), findsOneWidget);
        expect(api.sent('POST', '/walls/views'), hasLength(1));
        expect(qaSnackText(tester), isNull);

        await _tap(tester, find.byKey(const ValueKey('qa.blog.retry')));
        expect(find.text('Rain on the terrace'), findsOneWidget);
        expect(api.sent('POST', '/walls/views'), hasLength(1));
      },
    );

    testWidgets(
      'Following in the list unfollows and the writer leaves the list '
      '[case:blog.blog_follow.following.action]',
      (tester) async {
        var following = true;
        final api = _api()
          ..on(
            'GET /blog/subscriptions',
            (_) => qaOk({
              'writers': [if (following) _writer('writer', 'Meera')],
            }),
          )
          ..on('DELETE /blog/authors/*/subscription', (_) {
            following = false;
            return qaOk({'subscribed': false, 'subscriber_count': 2});
          });
        await pumpQa(tester, api, const BlogWritersScreen());
        expect(_label(tester), _en.blogFollowingButton);
        await _tap(tester, find.byKey(_follow));

        expect(api.writeLines, ['DELETE /blog/authors/writer/subscription']);
        expect(api.sent('GET', '/blog/subscriptions'), hasLength(2));
        expect(find.text('Meera'), findsNothing);
        expect(
          find.byKey(const ValueKey('blog.writers.empty')),
          findsOneWidget,
        );
      },
    );

    testWidgets('a failed unfollow in the list keeps the writer and explains '
        '[case:blog.blog_follow.following.api_failure]', (tester) async {
      final api = _api()
        ..json('GET /blog/subscriptions', {
          'writers': [_writer('writer', 'Meera')],
        })
        ..fail('DELETE /blog/authors/*/subscription');
      await pumpQa(tester, api, const BlogWritersScreen());
      await _tap(tester, find.byKey(_follow));
      expect(qaSnackText(tester), 'Something broke on our side.');
      expect(_label(tester), _en.blogFollowingButton);
      expect(find.text('Meera'), findsOneWidget);
      expect(find.text(_en.blogFollowerCount(3)), findsOneWidget);
      expect(api.sent('GET', '/blog/subscriptions'), hasLength(1));
    });

    testWidgets('Writers you follow is translated in every locale '
        '[case:blog.blog_writers.l10n]', (tester) async {
      for (final locale in qaLocales) {
        final l10n = qaL10n(locale);
        final api = _api()
          ..json('GET /blog/subscriptions', {
            'writers': [_writer('writer', 'Meera', latestTitle: '')],
          });
        await tester.pumpWidget(const SizedBox());
        await pumpQa(tester, api, const BlogWritersScreen(), locale: locale);
        expect(tester.takeException(), isNull, reason: '$locale');
        expect(find.text(l10n.blogWritersTitle), findsOneWidget);
        expect(find.text(l10n.blogFollowingButton), findsOneWidget);
        expect(find.text(l10n.blogLatest(l10n.blogUntitled)), findsOneWidget);

        api.json('GET /blog/subscriptions', {'writers': <dynamic>[]});
        await tester.pumpWidget(const SizedBox());
        await pumpQa(tester, api, const BlogWritersScreen(), locale: locale);
        expect(tester.takeException(), isNull, reason: '$locale empty');
        expect(find.text(l10n.blogNoWriters), findsOneWidget);
      }
    });
  });
}
