// Control-level tests for the Chapters feed (BlogScreen) and the chapter page
// (BlogDetailScreen). Every test performs the real gesture and asserts the
// request the app sent, where it navigated and what the member sees.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/blog/blog_connections.dart';
import 'package:verified_dating_app/features/blog/blog_editor.dart';
import 'package:verified_dating_app/features/blog/blog_screen.dart';
import 'package:verified_dating_app/features/blog/blog_sharing.dart';
import 'package:verified_dating_app/features/blog/blog_writers_screen.dart';
import 'package:verified_dating_app/features/engagement/screens/level_progression_screen.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

import '../../support/qa_api.dart';

final AppLocalizations _en = qaL10n(const Locale('en'));

Map<String, dynamic> _post(
  String id, {
  String author = 'writer',
  String name = 'Meera',
  String? title,
  String body = 'We counted the drops on the railing.',
  String audience = 'community',
  String invitation = '',
  int version = 3,
  List<Map<String, dynamic>> photos = const [],
  Map<String, dynamic> extra = const {},
}) => {
  'id': id,
  'author_id': author,
  'author_name': name,
  'title': title ?? 'Chapter $id',
  'body': body,
  'audience': audience,
  'invitation': invitation,
  'version': version,
  'photos': photos,
  ...extra,
};

/// A fake BFF with an empty Featured rail, two topics, an empty comment list
/// and a feed of [feed]; the chapter page answers with [detail] (or the
/// first feed chapter).
QaApi _api({
  List<Map<String, dynamic>> feed = const [],
  Map<String, dynamic>? detail,
}) {
  final api = QaApi()
    ..json('GET /blog/topics', {
      'topics': [
        {'slug': 'feelings', 'title': 'Feelings & healing', 'post_count': 4},
        {'slug': 'love', 'title': 'Love & relationships', 'post_count': 2},
      ],
    })
    ..json('GET /blog/featured', {'posts': <dynamic>[]})
    ..json('GET /blog/posts', {'posts': feed, 'next_cursor': ''})
    ..json('GET /blog/posts/*', {
      'post': detail ?? (feed.isEmpty ? _post('p1') : feed.first),
    })
    ..json('GET /blog/posts/*/comments', {'comments': <dynamic>[]})
    ..json('POST /walls/views', {'recorded': true});
  return api;
}

/// Commands the member's taps sent (a chapter view count is not one).
List<String> _commands(QaApi api) =>
    api.writeLines.where((l) => l != 'POST /walls/views').toList();

/// Scrolls the top route's list back to the start.
Future<void> _scrollToTop(WidgetTester tester) async {
  // A lazily built list corrects its offset after a long jump; jump until
  // the start really is at the top.
  for (var i = 0; i < 5; i++) {
    final position = tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position;
    if (position.pixels == 0) {
      break;
    }
    position.jumpTo(0);
    await tester.pump();
  }
}

List<Map<String, dynamic>> _feedQueries(QaApi api) => [
  for (final c in api.sent('GET', '/blog/posts')) c.query,
];

/// Scrolls [finder] into view in the top route's list, then taps it.
Future<void> _tap(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      250,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await qaSettle(tester);
}

/// Opens the feed, then the chapter [id] from its card, like a member does.
Future<void> _openFromFeed(WidgetTester tester, QaApi api, String id) async {
  await pumpQa(tester, api, const BlogScreen());
  await _tap(tester, find.byKey(ValueKey('qa.blog.post.$id')));
  expect(find.byType(BlogDetailScreen), findsOneWidget);
}

/// A 1x1 transparent PNG.
final _png = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

void main() {
  group('feed', () {
    testWidgets('scope chips load each feed and explain it '
        '[case:blog.blog.blog_scope_x.action]', (tester) async {
      final api = _api()
        ..on(
          'GET /blog/posts',
          (call) => qaOk({
            'posts': [
              _post(
                'in-${call.query['scope']}',
                title: 'Chapter in ${call.query['scope']}',
              ),
            ],
            'next_cursor': '',
          }),
        );
      await pumpQa(tester, api, const BlogScreen());
      expect(_feedQueries(api), [
        {'scope': 'community'},
      ]);
      expect(find.text(_en.blogScopeCaptionCommunity), findsOneWidget);
      expect(find.text('Chapter in community'), findsOneWidget);

      for (final (scope, caption) in [
        ('top', _en.blogScopeCaptionTop),
        ('subscriptions', _en.blogScopeCaptionFollowing),
        ('friends', _en.blogScopeCaptionFriends),
        ('mine', _en.blogScopeCaptionMine),
        ('community', _en.blogScopeCaptionCommunity),
      ]) {
        await _tap(tester, find.byKey(ValueKey('blog.scope.$scope')));
        expect(_feedQueries(api).last, {'scope': scope}, reason: scope);
        expect(
          tester
              .widget<ChoiceChip>(find.byKey(ValueKey('blog.scope.$scope')))
              .selected,
          isTrue,
        );
        expect(find.text(caption), findsOneWidget, reason: scope);
        expect(find.text('Chapter in $scope'), findsOneWidget);
        // Only Top rated shows ranks.
        expect(
          find.byKey(ValueKey('blog.rank.in-$scope')),
          scope == 'top' ? findsOneWidget : findsNothing,
        );
      }
      expect(api.unhandled, isEmpty);
    });

    testWidgets('topic chips filter the feed and All clears the filter '
        '[case:blog.blog.blog_topic_t_slug_isempty.action]', (tester) async {
      final api = _api()
        ..on(
          'GET /blog/posts',
          (call) => qaOk({
            'posts': [
              if (call.query['topic'] == 'feelings')
                _post('f1', title: 'A feelings chapter')
              else
                _post('a1', title: 'Any chapter'),
            ],
            'next_cursor': '',
          }),
        );
      await pumpQa(tester, api, const BlogScreen());
      expect(find.text('Any chapter'), findsOneWidget);

      await _tap(tester, find.byKey(const ValueKey('blog.topic.feelings')));
      expect(_feedQueries(api).last, {
        'scope': 'community',
        'topic': 'feelings',
      });
      expect(find.text('A feelings chapter'), findsOneWidget);
      expect(find.text('Any chapter'), findsNothing);

      // The topic stays while switching scope.
      await _tap(tester, find.byKey(const ValueKey('blog.scope.friends')));
      expect(_feedQueries(api).last, {'scope': 'friends', 'topic': 'feelings'});

      await _tap(tester, find.byKey(const ValueKey('blog.topic.all')));
      expect(_feedQueries(api).last, {'scope': 'friends'});
      expect(find.text('Any chapter'), findsOneWidget);
    });

    testWidgets('More chapters loads the next page and Previous page returns '
        '[case:blog.blog.blog_more_chapters.action] '
        '[case:blog.blog.blog_previous_page.action]', (tester) async {
      final api = _api()
        ..on(
          'GET /blog/posts',
          (call) => qaOk(
            call.query['before'] == 'cursor-2'
                ? {
                    'posts': [_post('p2', title: 'Second page chapter')],
                    'next_cursor': '',
                  }
                : {
                    'posts': [_post('p1', title: 'First page chapter')],
                    'next_cursor': 'cursor-2',
                  },
          ),
        );
      await pumpQa(tester, api, const BlogScreen());
      expect(find.byKey(const ValueKey('qa.blog.previous_page')), findsNothing);

      await _tap(tester, find.byKey(const ValueKey('qa.blog.more_chapters')));
      expect(_feedQueries(api).last, {
        'scope': 'community',
        'before': 'cursor-2',
      });
      expect(find.text('Second page chapter'), findsOneWidget);
      expect(find.text('First page chapter'), findsNothing);
      expect(find.byKey(const ValueKey('qa.blog.more_chapters')), findsNothing);

      await _tap(tester, find.byKey(const ValueKey('qa.blog.previous_page')));
      expect(_feedQueries(api).last, {'scope': 'community'});
      expect(find.text('First page chapter'), findsOneWidget);
      expect(find.text('Second page chapter'), findsNothing);
      expect(find.byKey(const ValueKey('qa.blog.previous_page')), findsNothing);
    });

    testWidgets('pull to refresh reloads the same feed '
        '[case:blog.blog.more_chapters_onrefresh.action]', (tester) async {
      var loads = 0;
      final api = _api()
        ..on('GET /blog/posts', (call) {
          loads++;
          return qaOk({
            'posts': [
              _post('p$loads', title: loads == 1 ? 'Old chapter' : 'Fresh one'),
            ],
            'next_cursor': '',
          });
        });
      await pumpQa(tester, api, const BlogScreen());
      expect(find.text('Old chapter'), findsOneWidget);

      await tester.fling(
        find.byType(RefreshIndicator),
        const Offset(0, 500),
        1000,
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await qaSettle(tester);

      expect(_feedQueries(api), [
        {'scope': 'community'},
        {'scope': 'community'},
      ]);
      expect(find.text('Fresh one'), findsOneWidget);
      expect(find.text('Old chapter'), findsNothing);
    });

    testWidgets('a feed that cannot load explains and Try again reloads '
        '[case:blog.blog.blog_retry_retry.action]', (
      tester,
    ) async {
      var loads = 0;
      final api = _api()
        ..on('GET /blog/posts', (call) {
          loads++;
          if (loads == 1) {
            return qaError(503, message: 'Chapters are resting. Try soon.');
          }
          if (loads == 2) {
            return const QaReply(500, <String, dynamic>{});
          }
          return qaOk({
            'posts': [_post('p1', title: 'Back again')],
            'next_cursor': '',
          });
        });
      await pumpQa(tester, api, const BlogScreen());
      expect(find.text('Chapters are resting. Try soon.'), findsOneWidget);

      // Without a server message the localized fallback is shown.
      await _tap(tester, find.byKey(const ValueKey('qa.blog.retry')));
      expect(find.text(_en.blogFeedLoadFailed), findsOneWidget);

      await _tap(tester, find.byKey(const ValueKey('qa.blog.retry')));
      expect(find.text('Back again'), findsOneWidget);
      expect(find.byKey(const ValueKey('qa.blog.retry')), findsNothing);
      expect(_feedQueries(api), hasLength(3));
    });

    testWidgets('empty Following points to Top rated, which loads it '
        '[case:blog.blog.blog_following_see_top_seetoprated.action]', (
      tester,
    ) async {
      final api = _api()
        ..on(
          'GET /blog/posts',
          (call) => qaOk({
            'posts': [
              if (call.query['scope'] == 'top')
                _post('t1', title: 'Most loved'),
            ],
            'next_cursor': '',
          }),
        );
      await pumpQa(tester, api, const BlogScreen());
      await _tap(
        tester,
        find.byKey(const ValueKey('blog.scope.subscriptions')),
      );
      expect(find.text(_en.blogEmptyFollowingTitle), findsOneWidget);

      await _tap(tester, find.byKey(const ValueKey('blog.following.see_top')));
      expect(_feedQueries(api).last, {'scope': 'top'});
      expect(
        tester
            .widget<ChoiceChip>(find.byKey(const ValueKey('blog.scope.top')))
            .selected,
        isTrue,
      );
      expect(find.text(_en.blogScopeCaptionTop), findsOneWidget);
      expect(find.text('Most loved'), findsOneWidget);
      expect(find.byKey(const ValueKey('blog.rank.t1')), findsOneWidget);
    });

    testWidgets('Write a chapter opens an empty editor and back returns '
        '[case:blog.blog.blog_new.action]', (tester) async {
      final api = _api();
      await pumpQa(tester, api, const BlogScreen());
      await _tap(tester, find.byKey(const ValueKey('blog.new')));
      expect(find.byType(BlogEditor), findsOneWidget);
      expect(find.text(_en.blogEditorHeadline), findsOneWidget);
      expect(find.text(_en.blogNotSavedDefault), findsOneWidget);
      expect(api.writes, isEmpty);

      await tester.tap(find.byType(BackButton));
      await qaSettle(tester);
      expect(find.byType(BlogEditor), findsNothing);
      expect(find.byType(BlogScreen), findsOneWidget);
    });

    testWidgets(
      'How rewards work lists rewards and See my level opens the level screen '
      '[case:blog.blog.blog_rewards.action] '
      '[case:blog.blog_follow.see_my_level.action] '
      '[case:blog.blog_follow.blog_rewards_see_my_level.action]',
      (tester) async {
        final api = _api();
        await pumpQa(tester, api, const BlogScreen());
        await tester.tap(find.byKey(const ValueKey('blog.rewards')));
        await qaSettle(tester);
        final sheet = find.byKey(const ValueKey('blog.rewards_sheet'));
        expect(sheet, findsOneWidget);
        expect(find.text(_en.blogRewardsIntro), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('blog.reward.story_published')),
            matching: find.text(_en.blogRewardXp(25)),
          ),
          findsOneWidget,
        );

        final seeLevel = find.byKey(
          const ValueKey('qa.blog.rewards.see_my_level'),
        );
        await tester.scrollUntilVisible(
          seeLevel,
          200,
          scrollable: find
              .descendant(of: sheet, matching: find.byType(Scrollable))
              .first,
        );
        await tester.tap(seeLevel);
        await qaSettle(tester);
        expect(sheet, findsNothing);
        expect(find.byType(LevelProgressionScreen), findsOneWidget);
        expect(api.sent('GET', '/progression/me'), isNotEmpty);
      },
    );

    testWidgets('Writers you follow opens the list of writers '
        '[case:blog.blog.blog_writers.action]', (tester) async {
      final api = _api()
        ..json('GET /blog/subscriptions', {
          'writers': [
            {
              'author_id': 'writer',
              'name': 'Meera',
              'subscriber_count': 3,
              'latest_title': 'Rain on the terrace',
              'latest_post_id': 'p1',
            },
          ],
        });
      await pumpQa(tester, api, const BlogScreen());
      await tester.tap(find.byKey(const ValueKey('blog.writers')));
      await qaSettle(tester);
      expect(find.byType(BlogWritersScreen), findsOneWidget);
      expect(api.sent('GET', '/blog/subscriptions'), hasLength(1));
      expect(find.text('Meera'), findsOneWidget);
      expect(find.text(_en.blogLatest('Rain on the terrace')), findsOneWidget);
    });

    for (final (key, section, tag) in [
      (
        'qa.blog.connections',
        'responses',
        '[case:blog.blog.private_responses_sharing_and_no.action]',
      ),
      (
        'qa.blog.private_responses',
        'responses',
        '[case:blog.blog.private_responses.action]',
      ),
      (
        'qa.blog.shared_links',
        'publications',
        '[case:blog.blog.shared_links.action]',
      ),
      (
        'qa.blog.review_notices',
        'notices',
        '[case:blog.blog.review_notices.action]',
      ),
    ]) {
      testWidgets('$key opens the $section section $tag', (tester) async {
        final api = _api()..json('GET /blog/$section', {section: <dynamic>[]});
        await pumpQa(tester, api, const BlogScreen());
        await _tap(tester, find.byKey(ValueKey(key)));
        expect(find.byType(BlogConnectionsScreen), findsOneWidget);
        expect(api.sent('GET', '/blog/$section'), hasLength(1));
        final label = switch (section) {
          'responses' => _en.blogPrivateResponses,
          'publications' => _en.blogSharedLinks,
          _ => _en.blogReviewNotices,
        };
        expect(
          tester
              .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, label))
              .selected,
          isTrue,
        );
        expect(
          find.text(switch (section) {
            'responses' => _en.blogResponsesEmpty,
            'publications' => _en.blogPublicationsEmpty,
            _ => _en.blogNoticesEmpty,
          }),
          findsOneWidget,
        );
      });
    }

    testWidgets('Photo unavailable · Retry loads the photo again '
        '[case:blog.blog.blog_photo_retry_x.action]', (tester) async {
      var loads = 0;
      final api =
          _api(
            feed: [
              _post(
                'p1',
                photos: [
                  {'id': 'ph1', 'alt_text': 'A wet terrace'},
                ],
              ),
            ],
          )..on('GET /blog/posts/*/photos/*', (call) {
            loads++;
            return loads == 1 ? qaError(500) : qaOk(_png);
          });
      await pumpQa(tester, api, const BlogScreen());
      final retry = find.byKey(const ValueKey('qa.blog.photo_retry.ph1'));
      expect(retry, findsOneWidget);
      expect(find.text(_en.blogPhotoUnavailableRetry), findsOneWidget);

      await _tap(tester, retry);
      expect(api.sent('GET', '/blog/posts/p1/photos/ph1'), hasLength(2));
      expect(retry, findsNothing);
      expect(
        find.byWidgetPredicate(
          (w) => w is Image && w.semanticLabel == 'A wet terrace',
        ),
        findsOneWidget,
      );
      expect(find.text('A wet terrace'), findsOneWidget);
    });
  });

  group('reading a chapter', () {
    testWidgets('Read chapter counts one view and opens the chapter '
        '[case:blog.blog.blog_post_x.action]', (tester) async {
      final api = _api(
        feed: [
          _post('p1', title: 'Rain on the terrace'),
          _post('mine', author: 'me', name: 'Me', title: 'My own'),
        ],
      );
      await pumpQa(tester, api, const BlogScreen());
      // Other members' chapters read; the member's own read & edit.
      expect(find.text(_en.blogReadChapter), findsOneWidget);
      expect(find.text(_en.blogReadEdit), findsOneWidget);

      await _tap(tester, find.byKey(const ValueKey('qa.blog.post.p1')));
      expect(api.sent('POST', '/walls/views').map((c) => c.body), [
        {'kind': 'chapter', 'id': 'p1'},
      ]);
      expect(find.byType(BlogDetailScreen), findsOneWidget);
      expect(api.sent('GET', '/blog/posts/p1'), hasLength(1));
      expect(find.text('Rain on the terrace'), findsOneWidget);
      expect(find.text('We counted the drops on the railing.'), findsOneWidget);
      expect(find.text('Meera'), findsOneWidget);
    });

    testWidgets('a failed view count never stops reading and is not retried '
        '[case:blog.blog.blog_post_x.api_failure]', (tester) async {
      final api = _api(feed: [_post('p1', title: 'Rain on the terrace')])
        ..fail('POST /walls/views');
      await _openFromFeed(tester, api, 'p1');
      expect(find.text('Rain on the terrace'), findsOneWidget);
      expect(qaSnackText(tester), isNull);
      expect(tester.takeException(), isNull);
      expect(api.sent('POST', '/walls/views'), hasLength(1));

      // Going back and opening it again counts (at most) once more.
      await tester.tap(find.byType(BackButton));
      await qaSettle(tester);
      await _tap(tester, find.byKey(const ValueKey('qa.blog.post.p1')));
      expect(api.sent('POST', '/walls/views'), hasLength(2));
      expect(find.text('Rain on the terrace'), findsOneWidget);
    });

    testWidgets('an unavailable chapter explains and Try again loads it '
        '[case:blog.blog.blog_retry_retry_2.action]', (
      tester,
    ) async {
      var loads = 0;
      final api = _api(feed: [_post('p1', title: 'Rain on the terrace')])
        ..on('GET /blog/posts/*', (call) {
          loads++;
          if (loads == 1) {
            return qaError(404, message: 'This chapter is no longer shared.');
          }
          if (loads == 2) {
            return const QaReply(500, <String, dynamic>{});
          }
          return qaOk({'post': _post('p1', title: 'Rain on the terrace')});
        });
      await _openFromFeed(tester, api, 'p1');
      expect(find.text('This chapter is no longer shared.'), findsOneWidget);

      await _tap(tester, find.byKey(const ValueKey('qa.blog.retry')));
      expect(find.text(_en.blogDetailUnavailable), findsOneWidget);

      await _tap(tester, find.byKey(const ValueKey('qa.blog.retry')));
      expect(api.sent('GET', '/blog/posts/p1'), hasLength(3));
      expect(find.text('Rain on the terrace'), findsOneWidget);
      expect(find.byKey(const ValueKey('qa.blog.retry')), findsNothing);
    });

    testWidgets(
      'Respond privately sends a response and opens private responses '
      '[case:blog.blog.blog_detail_respond.action]',
      (tester) async {
        final post = _post('p1', invitation: 'teach_me');
        final api = _api(feed: [post])
          ..json('POST /blog/responses', {
            'response': {'id': 'r1'},
          })
          ..json('GET /blog/responses', {'responses': <dynamic>[]});
        await _openFromFeed(tester, api, 'p1');
        expect(find.text(_en.blogInvitationTeachMe), findsOneWidget);

        await _tap(
          tester,
          find.byKey(const ValueKey('qa.blog.detail.respond')),
        );
        expect(find.byType(BlogTextCommandScreen), findsOneWidget);
        expect(find.text(_en.blogPrivateResponseTitle), findsOneWidget);
        await tester.enterText(
          find.widgetWithText(TextField, _en.blogOwnWordsLabel),
          '  Teach me the railing trick.  ',
        );
        await tester.pump();
        await tester.tap(
          find.widgetWithText(FilledButton, _en.blogSendPrivateResponse),
        );
        await qaSettle(tester);

        final sent = api.sent('POST', '/blog/responses').single.body;
        expect(sent['post_id'], 'p1');
        expect(sent['text'], 'Teach me the railing trick.');
        expect(sent['id'], isA<String>());
        expect(find.byType(BlogTextCommandScreen), findsNothing);
        expect(find.byType(BlogConnectionsScreen), findsOneWidget);
        expect(api.sent('GET', '/blog/responses'), isNotEmpty);
      },
    );

    testWidgets('Create a public preview opens sharing with the chapter text '
        '[case:blog.blog.blog_detail_public_preview.action]', (tester) async {
      final mine = _post('p1', author: 'me', name: 'Me', body: 'My words.');
      final api = _api(feed: [mine]);
      await _openFromFeed(tester, api, 'p1');
      // Own chapters cannot be reported or blocked.
      expect(find.byKey(const ValueKey('qa.blog.detail.report')), findsNothing);
      await _tap(
        tester,
        find.byKey(const ValueKey('qa.blog.detail.public_preview')),
      );
      expect(find.byType(BlogShareScreen), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is TextField && w.controller?.text == 'My words.',
        ),
        findsOneWidget,
      );
      expect(_commands(api), isEmpty);
    });

    testWidgets(
      'Edit chapter opens this chapter in the editor and saves this version '
      '[case:blog.blog.blog_detail_edit.action]',
      (tester) async {
        final mine = _post(
          'p1',
          author: 'me',
          name: 'Me',
          title: 'My terrace',
          audience: 'private',
        );
        final api = _api(feed: [mine])
          ..on(
            'PUT /blog/posts/*',
            (call) => qaOk({
              'post': {...mine, ...call.body, 'version': 4},
            }),
          );
        await _openFromFeed(tester, api, 'p1');
        await _tap(tester, find.byKey(const ValueKey('qa.blog.detail.edit')));
        expect(find.byType(BlogEditor), findsOneWidget);
        expect(
          tester
              .widget<TextField>(
                find.widgetWithText(TextField, _en.blogChapterTitleLabel),
              )
              .controller!
              .text,
          'My terrace',
        );
        await _tap(tester, find.byKey(const ValueKey('blog.save')));
        final put = api.sent('PUT', '/blog/posts/p1').single.body;
        expect(put['expected_version'], 3);
        expect(put['title'], 'My terrace');
        expect(put['audience'], 'private');
        await _scrollToTop(tester);
        expect(find.text(_en.blogSavedOnlyMe), findsOneWidget);
      },
    );
  });

  group('delete, report and block', () {
    testWidgets('Delete asks first; Cancel keeps the chapter and sends nothing '
        '[case:blog.blog.cancel.action] [case:blog.blog.blog_confirm_cancel.action]', (
      tester,
    ) async {
      final api = _api(
        feed: [_post('p1', author: 'me', name: 'Me')],
      );
      await _openFromFeed(tester, api, 'p1');
      await _tap(tester, find.byKey(const ValueKey('qa.blog.detail.delete')));
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text(_en.blogDeleteChapterTitle), findsOneWidget);
      expect(find.text(_en.blogDeleteChapterMessage), findsOneWidget);
      expect(
        find.byKey(const ValueKey('qa.blog.confirm.cancel')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('qa.blog.confirm.ok')),
          matching: find.text(_en.blogDeleteChapter),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('qa.blog.confirm.cancel')));
      await qaSettle(tester);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(BlogDetailScreen), findsOneWidget);
      expect(_commands(api), isEmpty);
    });

    testWidgets(
      'Delete chapter deletes this version and returns to the refreshed feed '
      '[case:blog.blog.blog_detail_delete.action] '
      '[case:blog.blog.blog_confirm_ok.action]',
      (tester) async {
        var deleted = false;
        final mine = _post('p1', author: 'me', name: 'Me', title: 'Gone soon');
        final api = _api(feed: [mine])
          ..on(
            'GET /blog/posts',
            (call) => qaOk({
              'posts': [if (!deleted) mine],
              'next_cursor': '',
            }),
          )
          ..on('DELETE /blog/posts/*', (call) {
            deleted = true;
            return qaOk({'deleted': true});
          });
        await _openFromFeed(tester, api, 'p1');
        await _tap(tester, find.byKey(const ValueKey('qa.blog.detail.delete')));
        await tester.tap(find.byKey(const ValueKey('qa.blog.confirm.ok')));
        await qaSettle(tester);

        final delete = api.sent('DELETE', '/blog/posts/p1').single;
        expect(delete.body, {'expected_version': 3});
        expect(find.byType(BlogDetailScreen), findsNothing);
        expect(_feedQueries(api), hasLength(2), reason: 'feed refreshed');
        expect(find.text('Gone soon'), findsNothing);
        expect(
          find.byKey(const ValueKey('blog.empty.community')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'a failed delete explains, keeps the chapter and can be retried '
      '[case:blog.blog.blog_detail_delete.api_failure]',
      (tester) async {
        var attempts = 0;
        final api =
            _api(
              feed: [
                _post('p1', author: 'me', name: 'Me', title: 'Still here'),
              ],
            )..on('DELETE /blog/posts/*', (call) {
              attempts++;
              return attempts == 1
                  ? qaError(
                      409,
                      message: 'This chapter changed. Reload it first.',
                    )
                  : qaOk({'deleted': true});
            });
        await _openFromFeed(tester, api, 'p1');
        await _tap(tester, find.byKey(const ValueKey('qa.blog.detail.delete')));
        await tester.tap(find.byKey(const ValueKey('qa.blog.confirm.ok')));
        await qaSettle(tester);

        expect(qaSnackText(tester), 'This chapter changed. Reload it first.');
        expect(find.byType(BlogDetailScreen), findsOneWidget);
        expect(find.text('Still here'), findsOneWidget);
        expect(api.sent('DELETE', '/blog/posts/p1'), hasLength(1));
        final button = tester.widget<ButtonStyleButton>(
          find.byKey(const ValueKey('qa.blog.detail.delete')),
        );
        expect(button.onPressed, isNotNull);

        await _tap(tester, find.byKey(const ValueKey('qa.blog.detail.delete')));
        await tester.tap(find.byKey(const ValueKey('qa.blog.confirm.ok')));
        await qaSettle(tester);
        expect(api.sent('DELETE', '/blog/posts/p1'), hasLength(2));
        expect(find.byType(BlogDetailScreen), findsNothing);
      },
    );

    testWidgets('Report chapter sends the reason and details, then confirms '
        '[case:blog.blog.blog_detail_report.action] '
        '[case:blog.blog.blog_detail_report_submit.action]', (
      tester,
    ) async {
      final api = _api(feed: [_post('p1')])
        ..json('POST /blog/posts/*/report', {
          'report': {'id': 'r1'},
        });
      await _openFromFeed(tester, api, 'p1');
      await _tap(tester, find.byKey(const ValueKey('qa.blog.detail.report')));
      expect(find.text(_en.reportSheetTitle), findsOneWidget);

      await tester.tap(find.text(_en.reportReasonInappropriate));
      await qaSettle(tester);
      await tester.tap(find.text(_en.reportReasonHarassment).last);
      await qaSettle(tester);
      await tester.enterText(
        find.widgetWithText(TextField, _en.reportDescriptionLabel),
        'Mocks the writer 😞',
      );
      await tester.tap(find.widgetWithText(FilledButton, _en.reportSubmit));
      await qaSettle(tester);

      expect(api.sent('POST', '/blog/posts/p1/report').single.body, {
        'reason': 'harassment',
        'description': 'Mocks the writer 😞',
      });
      expect(find.text(_en.reportSheetTitle), findsNothing);
      expect(qaSnackText(tester), _en.blogReportSubmitted);
      expect(find.byType(BlogDetailScreen), findsOneWidget);
    });

    testWidgets(
      'Report chapter regression: a sent report is confirmed, a dismissed '
      'sheet is not',
      (tester) async {
        final api = _api(feed: [_post('p1')])
          ..json('POST /blog/posts/*/report', {'report': null});
        await _openFromFeed(tester, api, 'p1');
        await _tap(tester, find.byKey(const ValueKey('qa.blog.detail.report')));
        // Dismiss without sending.
        await tester.tapAt(const Offset(200, 40));
        await qaSettle(tester);
        expect(find.text(_en.reportSheetTitle), findsNothing);
        expect(_commands(api), isEmpty);
        expect(qaSnackText(tester), isNull);

        // A sent report is confirmed even when the server returns no id.
        await _tap(tester, find.byKey(const ValueKey('qa.blog.detail.report')));
        await tester.tap(find.widgetWithText(FilledButton, _en.reportSubmit));
        await qaSettle(tester);
        expect(api.sent('POST', '/blog/posts/p1/report').single.body, {
          'reason': 'inappropriate',
          'description': '',
        });
        expect(qaSnackText(tester), _en.blogReportSubmitted);
      },
    );

    testWidgets(
      'a failed report keeps the sheet and the text; retry sends once more '
      '[case:blog.blog.blog_detail_report.api_failure] '
      '[case:blog.blog.blog_detail_report_submit.api_failure]',
      (tester) async {
        var attempts = 0;
        final api = _api(feed: [_post('p1')])
          ..on('POST /blog/posts/*/report', (call) {
            attempts++;
            return attempts == 1
                ? qaError(500)
                : qaOk({
                    'report': {'id': 'r2'},
                  });
          });
        await _openFromFeed(tester, api, 'p1');
        await _tap(tester, find.byKey(const ValueKey('qa.blog.detail.report')));
        final details = find.widgetWithText(
          TextField,
          _en.reportDescriptionLabel,
        );
        await tester.enterText(details, 'Copied my chapter');
        final submit = find.widgetWithText(FilledButton, _en.reportSubmit);
        await tester.tap(submit);
        await qaSettle(tester);

        expect(qaSnackText(tester), _en.reportSubmitFailed);
        expect(find.text(_en.reportSheetTitle), findsOneWidget);
        expect(
          tester.widget<TextField>(details).controller!.text,
          'Copied my chapter',
        );
        expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);
        expect(api.sent('POST', '/blog/posts/p1/report'), hasLength(1));

        await tester.tap(submit);
        await qaSettle(tester);
        expect(api.sent('POST', '/blog/posts/p1/report'), hasLength(2));
        expect(
          api.sent('POST', '/blog/posts/p1/report').last.body['description'],
          'Copied my chapter',
        );
        expect(find.text(_en.reportSheetTitle), findsNothing);
        // The confirmation follows once the failure message times out.
        await tester.pump(const Duration(seconds: 4));
        await qaSettle(tester);
        expect(qaSnackText(tester), _en.blogReportSubmitted);
      },
    );

    testWidgets(
      'Block this member asks, blocks the writer and leaves their chapter '
      '[case:blog.blog.blog_detail_block.action]',
      (tester) async {
        var blocked = false;
        final theirs = _post('p1', title: 'Their chapter');
        final api = _api(feed: [theirs])
          ..on(
            'GET /blog/posts',
            (call) => qaOk({
              'posts': [if (!blocked) theirs],
              'next_cursor': '',
            }),
          )
          ..on('POST /safety/block', (call) {
            blocked = true;
            return qaOk({'success': true});
          });
        await _openFromFeed(tester, api, 'p1');
        await _tap(tester, find.byKey(const ValueKey('qa.blog.detail.block')));
        expect(find.text(_en.blogBlockTitle), findsOneWidget);
        expect(find.text(_en.blogBlockMessageChapter), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('qa.blog.confirm.ok')));
        await qaSettle(tester);

        expect(api.sent('POST', '/safety/block').single.body, {
          'user_id': 'me',
          'blocked_user_id': 'writer',
        });
        expect(find.byType(BlogDetailScreen), findsNothing);
        expect(find.text('Their chapter'), findsNothing);
        expect(
          find.byKey(const ValueKey('blog.empty.community')),
          findsOneWidget,
        );
      },
    );

    testWidgets('a failed block explains and keeps the chapter open '
        '[case:blog.blog.blog_detail_block.api_failure]', (tester) async {
      final api = _api(feed: [_post('p1', title: 'Their chapter')])
        ..fail('POST /safety/block');
      await _openFromFeed(tester, api, 'p1');
      await _tap(tester, find.byKey(const ValueKey('qa.blog.detail.block')));
      await tester.tap(find.byKey(const ValueKey('qa.blog.confirm.ok')));
      await qaSettle(tester);

      expect(qaSnackText(tester), _en.blogBlockRetryFailed);
      expect(find.byType(BlogDetailScreen), findsOneWidget);
      expect(find.text('Their chapter'), findsOneWidget);
      expect(api.sent('POST', '/safety/block'), hasLength(1));

      // Cancelling the next attempt sends nothing.
      await _tap(tester, find.byKey(const ValueKey('qa.blog.detail.block')));
      await tester.tap(find.byKey(const ValueKey('qa.blog.confirm.cancel')));
      await qaSettle(tester);
      expect(api.sent('POST', '/safety/block'), hasLength(1));
    });
  });

  testWidgets('feed and chapter page render translated in every locale '
      '[case:blog.blog.l10n]', (tester) async {
    for (final locale in qaLocales) {
      final l10n = qaL10n(locale);
      final api = _api(feed: [_post('p1', invitation: 'what_next')]);
      await pumpQa(tester, api, const BlogScreen(), locale: locale);
      expect(tester.takeException(), isNull, reason: '$locale feed');
      expect(find.text(l10n.blogWriteChapter), findsOneWidget);
      expect(find.text(l10n.blogScopeForYou), findsOneWidget);
      expect(find.text(l10n.blogScopeCaptionCommunity), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text(l10n.blogReadChapter),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull, reason: '$locale card');

      await pumpQa(
        tester,
        api,
        const BlogDetailScreen(id: 'p1'),
        locale: locale,
      );
      expect(tester.takeException(), isNull, reason: '$locale chapter');
      expect(find.text(l10n.blogDetailTitle), findsOneWidget);
      expect(find.text(l10n.blogInvitationWhatNext), findsOneWidget);
      expect(find.text(l10n.blogRespondPrivately), findsOneWidget);
    }
  });
}
