// Control-level tests for chapter likes, reactions and comments
// (blog_social.dart): every control is driven by a real gesture and the test
// asserts the request that reached the fake BFF and what the member sees.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/blog/blog_data.dart';
import 'package:verified_dating_app/features/blog/blog_screen.dart';
import 'package:verified_dating_app/features/blog/blog_social.dart';

import '../../support/qa_api.dart';

final en = qaL10n(const Locale('en'));

Map<String, dynamic> postJson({
  String id = 'p1',
  String author = 'author',
  String title = 'The bookshop on the corner',
  int likes = 3,
  bool liked = false,
  String reaction = '',
  Map<String, int> reactions = const {},
  int comments = 1,
}) => {
  'id': id,
  'author_id': author,
  'author_name': 'Priya',
  'title': title,
  'body': 'A small story.',
  'audience': 'community',
  'invitation': '',
  'version': 2,
  'photos': <dynamic>[],
  'like_count': likes,
  'liked_by_me': liked,
  'my_reaction': reaction,
  'reactions': reactions,
  'comment_count': comments,
  'pending_comment_count': 0,
  'allow_featuring': true,
  'featured': true,
};

Map<String, dynamic> commentJson(
  String id, {
  String status = 'approved',
  bool mine = false,
  String body = 'Lovely.',
}) => {
  'id': id,
  'post_id': 'p1',
  'author_id': mine ? 'me' : 'reader-$id',
  'author_name': 'Reader $id',
  'body': body,
  'status': status,
  'mine': mine,
  'can_moderate': false,
  'created_at': '2026-10-01T09:00:00Z',
};

/// The chapter page's engagement row plus its comments, as the detail page
/// lays them out.
Widget chapter(BlogPost post) => Scaffold(
  body: ListView(
    padding: const EdgeInsets.all(16),
    children: [
      BlogEngagementRow(post: post, live: true),
      const SizedBox(height: 24),
      BlogCommentsSection(post: post),
    ],
  ),
);

/// Records what the app writes to the clipboard. [failWrites] makes the next
/// writes fail the way a denied clipboard does.
class FakeClipboard {
  String? text;
  int failWrites = 0;

  void install(WidgetTester t) {
    final messenger = t.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      switch (call.method) {
        case 'Clipboard.setData':
          if (failWrites > 0) {
            failWrites--;
            throw PlatformException(code: 'denied');
          }
          text = (call.arguments as Map)['text'] as String?;
          return null;
        case 'Clipboard.getData':
          return text == null ? null : {'text': text};
        case 'Clipboard.hasStrings':
          return {'value': text != null};
      }
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
  }
}

/// Selects all of a SelectableText with the real long-press toolbar and
/// copies it, the way a member copies words they want to keep.
Future<void> copyAllOf(WidgetTester t, Finder selectable) async {
  await t.longPress(selectable);
  await qaSettle(t, frames: 5);
  final selectAll = find.text('Select all');
  if (selectAll.evaluate().isNotEmpty) {
    await t.tap(selectAll);
    await qaSettle(t, frames: 5);
  }
  await t.tap(find.text('Copy'));
  await qaSettle(t, frames: 5);
}

const heart = ValueKey('blog.like.p1');
const react = ValueKey('blog.like.p1.react');
const field = ValueKey('blog.comment.field');
const send = ValueKey('blog.comment.send');

QaApi commentsApi(List<Map<String, dynamic>> Function() comments) => QaApi()
  ..on('GET /blog/posts/p1/comments', (_) => qaOk({'comments': comments()}));

void main() {
  group('likes and reactions', () {
    testWidgets(
      'Heart likes then unlikes: PUT then DELETE, the count follows the server '
      '[case:blog.blog_social.love_icon_favorite_rounded_ontoggle.action]',
      (t) async {
        final api = commentsApi(() => [])
          ..json('PUT /blog/posts/p1/like', {
            'post': postJson(
              likes: 4,
              liked: true,
              reaction: 'love',
              reactions: {'love': 1},
            ),
          })
          ..json('DELETE /blog/posts/p1/like', {'post': postJson()});
        await pumpQa(t, api, chapter(BlogPost.fromJson(postJson())));
        expect(find.text('3'), findsOneWidget);
        expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);

        await t.tap(find.byKey(heart));
        await qaSettle(t);
        expect(api.writeLines, ['PUT /blog/posts/p1/like']);
        expect(api.writes.single.data, isNull, reason: 'a plain like');
        expect(find.text('4'), findsOneWidget);
        expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
        expect(find.text('❤️ 1'), findsOneWidget);

        await t.tap(find.byKey(heart));
        await qaSettle(t);
        expect(api.writeLines, [
          'PUT /blog/posts/p1/like',
          'DELETE /blog/posts/p1/like',
        ]);
        expect(find.text('3'), findsOneWidget);
        expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
        expect(find.text('❤️ 1'), findsNothing);
        expect(t.takeException(), isNull);
      },
    );

    testWidgets(
      'A failed like rolls back, explains itself, ignores taps in flight and '
      'retries cleanly [case:blog.blog_social.love_icon_favorite_rounded_ontoggle.api_failure]',
      (t) async {
        final api = commentsApi(() => [])
          ..on(
            'PUT /blog/posts/p1/like',
            (_) => const QaReply(
              500,
              <String, dynamic>{},
              delay: Duration(milliseconds: 300),
            ),
          );
        await pumpQa(t, api, chapter(BlogPost.fromJson(postJson())));
        await t.tap(find.byKey(heart));
        await t.pump();
        expect(find.text('4'), findsOneWidget, reason: 'optimistic');
        await t.tap(find.byKey(heart)); // in flight: ignored
        await qaSettle(t);
        expect(api.writeLines, ['PUT /blog/posts/p1/like']);
        expect(find.text('3'), findsOneWidget);
        expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
        expect(qaSnackText(t), en.blogReactionFailed);

        // The server's own words win over the fallback.
        api.fail('PUT /blog/posts/p1/like', message: 'Likes are paused.');
        await t.tap(find.byKey(heart));
        await qaSettle(t);
        expect(qaSnackText(t), 'Likes are paused.');
        expect(find.text('3'), findsOneWidget);

        api.json('PUT /blog/posts/p1/like', {
          'post': postJson(likes: 4, liked: true),
        });
        await t.tap(find.byKey(heart));
        await qaSettle(t);
        expect(api.sent('PUT', '/blog/posts/p1/like'), hasLength(3));
        expect(api.sent('DELETE', '/blog/posts/p1/like'), isEmpty);
        expect(find.text('4'), findsOneWidget);
        expect(t.takeException(), isNull);
      },
    );

    testWidgets(
      'React opens the picker; a choice is sent and shown, taking it back '
      'unlikes, and a long press on the heart opens the same picker '
      '[case:blog.blog_social.x_react.action]',
      (t) async {
        final api = commentsApi(() => [])
          ..json('PUT /blog/posts/p1/like', {
            'post': postJson(
              likes: 4,
              liked: true,
              reaction: 'hear_you',
              reactions: {'hear_you': 1, 'love': 3},
            ),
          })
          ..json('DELETE /blog/posts/p1/like', {
            'post': postJson(reactions: {'love': 3}),
          });
        await pumpQa(t, api, chapter(BlogPost.fromJson(postJson())));
        final button = t.widget<IconButton>(find.byKey(react));
        expect(button.tooltip, en.blogReactTooltip);

        await t.tap(find.byKey(react));
        await qaSettle(t);
        expect(find.text(en.wallsReactQuestion('chapter')), findsOneWidget);
        expect(find.byKey(const ValueKey('reaction.remove')), findsNothing);
        await t.tap(find.byKey(const ValueKey('reaction.option.hear_you')));
        await qaSettle(t);
        expect(api.writeLines, ['PUT /blog/posts/p1/like']);
        expect(api.writes.single.body, {'reaction': 'hear_you'});
        expect(find.text(en.wallsReactQuestion('chapter')), findsNothing);
        expect(find.text('🫶'), findsOneWidget);
        expect(find.text('4'), findsOneWidget);
        expect(find.text('🫶 1'), findsOneWidget);

        // Long press on the heart: the same picker, with a way back.
        await t.longPress(find.byKey(heart));
        await qaSettle(t);
        expect(find.text(en.wallsReactQuestion('chapter')), findsOneWidget);
        await t.tap(find.byKey(const ValueKey('reaction.remove')));
        await qaSettle(t);
        expect(api.writeLines, [
          'PUT /blog/posts/p1/like',
          'DELETE /blog/posts/p1/like',
        ]);
        expect(find.text('🫶'), findsNothing);
        expect(find.text('3'), findsOneWidget);
        expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
      },
    );

    testWidgets(
      'Authors cannot react to their own chapter: both controls are disabled '
      'with a reason and nothing is sent [case:blog.blog_social.x_react.action]',
      (t) async {
        final api = commentsApi(() => []);
        await pumpQa(
          t,
          api,
          chapter(BlogPost.fromJson(postJson(author: 'me'))),
        );
        expect(t.widget<IconButton>(find.byKey(react)).onPressed, isNull);
        expect(t.widget<TextButton>(find.byKey(heart)).onPressed, isNull);
        expect(
          t.widget<IconButton>(find.byKey(react)).tooltip,
          'You can’t react to your own chapter',
        );
        await t.tap(find.byKey(react), warnIfMissed: false);
        await qaSettle(t);
        expect(find.text(en.wallsReactQuestion('chapter')), findsNothing);
        expect(api.writes, isEmpty);
      },
    );

    testWidgets(
      'A failed reaction rolls back with the server message and no '
      'duplicate; picking again succeeds [case:blog.blog_social.x_react.api_failure]',
      (t) async {
        final api = commentsApi(() => [])
          ..fail('PUT /blog/posts/p1/like', message: 'Reactions are paused.');
        await pumpQa(t, api, chapter(BlogPost.fromJson(postJson())));
        await t.tap(find.byKey(react));
        await qaSettle(t);
        await t.tap(find.byKey(const ValueKey('reaction.option.hug')));
        await qaSettle(t);
        expect(api.writeLines, ['PUT /blog/posts/p1/like']);
        expect(qaSnackText(t), 'Reactions are paused.');
        expect(find.text('🫂'), findsNothing);
        expect(find.text('3'), findsOneWidget);
        expect(t.widget<IconButton>(find.byKey(react)).onPressed, isNotNull);

        api.json('PUT /blog/posts/p1/like', {
          'post': postJson(
            likes: 4,
            liked: true,
            reaction: 'hug',
            reactions: {'hug': 1},
          ),
        });
        await t.tap(find.byKey(react));
        await qaSettle(t);
        await t.tap(find.byKey(const ValueKey('reaction.option.hug')));
        await qaSettle(t);
        expect(api.sent('PUT', '/blog/posts/p1/like'), hasLength(2));
        expect(api.writes.last.body, {'reaction': 'hug'});
        expect(find.text('🫂'), findsOneWidget);
        expect(find.text('4'), findsOneWidget);
      },
    );
  });

  group('Featured Stories card', () {
    QaApi featuredApi() => QaApi()
      ..json('GET /blog/featured', {
        'posts': [postJson(id: 'f1', title: 'Loved by many', likes: 12)],
      })
      ..json('GET /blog/posts/f1', {
        'post': postJson(id: 'f1', title: 'Loved by many', likes: 12),
      })
      ..json('GET /blog/posts/f1/comments', {'comments': <dynamic>[]});

    testWidgets('Tapping a featured chapter counts one wall view and opens it '
        '[case:blog.blog_social.comments.action]', (t) async {
      final api = featuredApi()..json('POST /walls/views', {'recorded': true});
      await pumpQa(t, api, const Scaffold(body: BlogFeaturedRail()));
      final card = find.byKey(const ValueKey('blog.featured.f1'));
      expect(
        find.descendant(of: card, matching: find.text('12')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.text('1')),
        findsOneWidget,
        reason: 'comment count',
      );
      await t.tap(card);
      await qaSettle(t);
      expect(api.sent('POST', '/walls/views').single.body, {
        'kind': 'chapter',
        'id': 'f1',
      });
      expect(find.byType(BlogDetailScreen), findsOneWidget);
      expect(api.sent('GET', '/blog/posts/f1'), hasLength(1));
      expect(find.text(en.blogDetailTitle), findsOneWidget);
      expect(find.text('Loved by many'), findsOneWidget);
    });

    testWidgets(
      'A failed view count never stops the member reading: the chapter opens '
      'with no error [case:blog.blog_social.comments.api_failure]',
      (t) async {
        final api = featuredApi()..fail('POST /walls/views');
        await pumpQa(t, api, const Scaffold(body: BlogFeaturedRail()));
        await t.tap(find.byKey(const ValueKey('blog.featured.f1')));
        await qaSettle(t);
        expect(api.sent('POST', '/walls/views'), hasLength(1));
        expect(find.byType(BlogDetailScreen), findsOneWidget);
        expect(find.text('Loved by many'), findsOneWidget);
        expect(qaSnackText(t), isNull);
        expect(t.takeException(), isNull);
      },
    );
  });

  group('comment composer', () {
    testWidgets('Typing fills the composer, shows the count and enables Send '
        '[case:blog.blog_social.x_comment_field.action]', (t) async {
      final api = commentsApi(() => []);
      await pumpQa(t, api, chapter(BlogPost.fromJson(postJson())));
      expect(t.widget<FilledButton>(find.byKey(send)).onPressed, isNull);
      expect(find.text(en.blogNoCommentsInvite), findsOneWidget);
      await t.enterText(find.byKey(field), 'Made me smile');
      await t.pump();
      expect(find.text('Made me smile'), findsOneWidget);
      expect(find.text('13/500'), findsOneWidget);
      expect(t.widget<FilledButton>(find.byKey(send)).onPressed, isNotNull);
      expect(api.writes, isEmpty, reason: 'typing alone sends nothing');
    });

    testWidgets(
      'Blank comments cannot be sent, the 500-character limit holds, and '
      'unicode reaches the server byte-for-byte '
      '[case:blog.blog_social.x_comment_field.validation]',
      (t) async {
        final api = commentsApi(() => [])
          ..on(
            'PUT /blog/posts/p1/comments/*',
            (c) => qaOk({
              'comment': commentJson(
                'x',
                status: 'pending',
                mine: true,
                body: c.body['body'] as String,
              ),
            }),
          );
        await pumpQa(t, api, chapter(BlogPost.fromJson(postJson())));

        await t.enterText(find.byKey(field), '   \n  ');
        await t.pump();
        expect(t.widget<FilledButton>(find.byKey(send)).onPressed, isNull);
        await t.tap(find.byKey(send), warnIfMissed: false);
        await t.pump();
        expect(api.writes, isEmpty);

        await t.enterText(find.byKey(field), 'a' * 501);
        await t.pump();
        expect(
          t.widget<TextField>(find.byKey(field)).controller!.text,
          'a' * 500,
        );

        const unicode = '¡Qué bonito! 😀 שלום عالم 👩🏽‍💻';
        await t.enterText(find.byKey(field), '  $unicode  ');
        await t.pump();
        await t.tap(find.byKey(send));
        await qaSettle(t);
        expect(api.writes.single.body, {'body': unicode});
      },
    );

    testWidgets(
      'regression: an emoji-rich comment within 500 characters can be sent '
      '(the limit counts characters, not UTF-16 units) '
      '[case:blog.blog_social.x_comment_field.validation]',
      (t) async {
        final api = commentsApi(() => [])
          ..json('PUT /blog/posts/p1/comments/*', {
            'comment': commentJson('x', status: 'pending', mine: true),
          });
        await pumpQa(t, api, chapter(BlogPost.fromJson(postJson())));
        final emoji = '😀' * 300; // 300 characters, 600 UTF-16 units
        await t.enterText(find.byKey(field), emoji);
        await t.pump();
        expect(find.text('300/500'), findsOneWidget);
        expect(t.widget<FilledButton>(find.byKey(send)).onPressed, isNotNull);
        await t.tap(find.byKey(send));
        await qaSettle(t);
        expect(api.writes.single.body, {'body': emoji});
      },
    );

    testWidgets(
      'Send puts the trimmed comment under a fresh id, clears the composer, '
      'says it went to the author and shows it pending '
      '[case:blog.blog_social.x_comment_send.action]',
      (t) async {
        var sent = false;
        final api =
            commentsApi(
              () => [
                commentJson('c1', body: 'Shared already.'),
                if (sent)
                  commentJson(
                    'c9',
                    status: 'pending',
                    mine: true,
                    body: 'This made me want to visit.',
                  ),
              ],
            )..on('PUT /blog/posts/p1/comments/*', (c) {
              sent = true;
              return qaOk({
                'comment': commentJson('c9', status: 'pending', mine: true),
              });
            });
        await pumpQa(t, api, chapter(BlogPost.fromJson(postJson())));
        await t.enterText(find.byKey(field), '  This made me want to visit.  ');
        await t.pump();
        await t.tap(find.byKey(send));
        await t.tap(find.byKey(send), warnIfMissed: false);
        await qaSettle(t);

        final put = api.writes.single;
        expect(put.method, 'PUT');
        expect(
          put.path,
          matches(
            RegExp(
              r'^/blog/posts/p1/comments/[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
            ),
          ),
        );
        expect(put.body, {'body': 'This made me want to visit.'});
        expect(t.widget<TextField>(find.byKey(field)).controller!.text, '');
        expect(api.sent('GET', '/blog/posts/p1/comments'), hasLength(2));
        expect(find.text('This made me want to visit.'), findsOneWidget);
        // The composer notice plus the pending comment's own label.
        expect(find.text(en.blogCommentSent), findsNWidgets(2));
      },
    );

    testWidgets(
      'A failed send keeps the words, explains, re-enables Send and retries '
      'under the same id [case:blog.blog_social.x_comment_send.api_failure]',
      (t) async {
        final api = commentsApi(() => [])
          ..on(
            'PUT /blog/posts/p1/comments/*',
            (_) => const QaReply(500, <String, dynamic>{}),
          );
        await pumpQa(t, api, chapter(BlogPost.fromJson(postJson())));
        await t.enterText(find.byKey(field), 'Hello there');
        await t.pump();
        await t.tap(find.byKey(send));
        await qaSettle(t);
        expect(find.text(en.blogCommentSendFailed), findsOneWidget);
        expect(
          t.widget<TextField>(find.byKey(field)).controller!.text,
          'Hello there',
        );
        expect(t.widget<FilledButton>(find.byKey(send)).onPressed, isNotNull);

        api.fail(
          'PUT /blog/posts/p1/comments/*',
          status: 429,
          message: 'You have commented a lot today. Come back tomorrow.',
        );
        await t.tap(find.byKey(send));
        await qaSettle(t);
        expect(
          find.text('You have commented a lot today. Come back tomorrow.'),
          findsOneWidget,
        );

        api.json('PUT /blog/posts/p1/comments/*', {
          'comment': commentJson('x', status: 'pending', mine: true),
        });
        await t.tap(find.byKey(send));
        await qaSettle(t);
        final puts = api.sent('PUT', '/blog/posts/p1/comments/*');
        expect(puts, hasLength(3));
        expect(puts.map((c) => c.path).toSet(), hasLength(1));
        expect(t.widget<TextField>(find.byKey(field)).controller!.text, '');
        expect(find.text(en.blogCommentSendFailed), findsNothing);
      },
    );

    testWidgets('Comments that fail to load offer Try again, which loads them '
        '[case:blog.blog_social.blog_retry_retry.action]', (t) async {
      var fail = true;
      final api = QaApi()
        ..on(
          'GET /blog/posts/p1/comments',
          (_) => fail
              ? const QaReply(500, <String, dynamic>{})
              : qaOk({
                  'comments': [commentJson('c1', body: 'Back again.')],
                }),
        );
      await pumpQa(t, api, chapter(BlogPost.fromJson(postJson())));
      expect(find.text(en.blogCommentsLoadFailed), findsOneWidget);
      expect(find.text('Back again.'), findsNothing);
      fail = false;
      await t.tap(find.widgetWithText(OutlinedButton, en.blogTryAgain));
      await qaSettle(t);
      expect(api.sent('GET', '/blog/posts/p1/comments'), hasLength(2));
      expect(find.text(en.blogCommentsLoadFailed), findsNothing);
      expect(find.text('Back again.'), findsOneWidget);
    });
  });

  group('author decisions', () {
    late String status;
    QaApi authorApi() {
      status = 'pending';
      return commentsApi(
        () => [
          commentJson('c1', body: 'Shared already.'),
          commentJson('c2', status: status, body: 'Waiting on you.'),
        ],
      );
    }

    final approve = find.byKey(const ValueKey('blog.comment.approve.c2'));
    final decline = find.byKey(const ValueKey('blog.comment.decline.c2'));
    BlogPost mine() => BlogPost.fromJson(postJson(author: 'me'));

    testWidgets(
      'Approve shares the comment: one decision request, a confirmation, and '
      'it moves out of the waiting group [case:blog.blog_social.x_comment_approve_x.action]',
      (t) async {
        final api = authorApi()
          ..on('POST /blog/posts/p1/comments/c2/decision', (c) {
            status = 'approved';
            return QaReply(200, {
              'comment': commentJson('c2'),
            }, delay: const Duration(milliseconds: 200));
          });
        await pumpQa(t, api, chapter(mine()));
        expect(find.text(en.blogWaitingApproval), findsOneWidget);
        expect(find.byKey(field), findsNothing, reason: 'authors approve');
        await t.tap(approve);
        await t.pump();
        expect(t.widget<FilledButton>(approve).onPressed, isNull);
        await t.tap(approve, warnIfMissed: false);
        await qaSettle(t);
        expect(api.writes.single.path, '/blog/posts/p1/comments/c2/decision');
        expect(api.writes.single.body, {'decision': 'approve'});
        expect(qaSnackText(t), en.blogCommentApproved);
        expect(find.text(en.blogWaitingApproval), findsNothing);
        expect(approve, findsNothing);
        expect(find.text('Waiting on you.'), findsOneWidget);
        expect(find.text('2 comments'), findsOneWidget);
      },
    );

    testWidgets('Decline keeps the comment off the chapter with a confirmation '
        '[case:blog.blog_social.x_comment_decline_x_decline.action]', (
      t,
    ) async {
      final api = authorApi()
        ..on('POST /blog/posts/p1/comments/c2/decision', (c) {
          status = 'declined';
          return qaOk({'comment': commentJson('c2', status: 'declined')});
        });
      await pumpQa(t, api, chapter(mine()));
      await t.tap(decline);
      await qaSettle(t);
      expect(api.writes.single.path, '/blog/posts/p1/comments/c2/decision');
      expect(api.writes.single.body, {'decision': 'decline'});
      expect(qaSnackText(t), en.blogCommentDeclined('chapter'));
      expect(qaSnackText(t), 'Declined. It won’t appear on your chapter.');
      expect(find.text('Waiting on you.'), findsNothing);
      expect(find.text(en.blogWaitingApproval), findsNothing);
      expect(find.text('Shared already.'), findsOneWidget);
    });

    for (final row in [
      (
        'approve',
        '[case:blog.blog_social.x_comment_approve_x.api_failure]',
        'approve',
      ),
      (
        'decline',
        '[case:blog.blog_social.x_comment_decline_x_decline.api_failure]',
        'decline',
      ),
    ]) {
      testWidgets(
        'A failed ${row.$1} explains itself and leaves the comment waiting '
        'with both buttons usable ${row.$2}',
        (t) async {
          final api = authorApi()
            ..fail(
              'POST /blog/posts/p1/comments/c2/decision',
              status: 409,
              message: 'This comment changed. Refresh and try again.',
            );
          await pumpQa(t, api, chapter(mine()));
          await t.tap(row.$1 == 'approve' ? approve : decline);
          await qaSettle(t);
          expect(api.writes.single.body, {'decision': row.$3});
          expect(
            qaSnackText(t),
            'This comment changed. Refresh and try again.',
          );
          expect(find.text(en.blogWaitingApproval), findsOneWidget);
          expect(t.widget<FilledButton>(approve).onPressed, isNotNull);
          expect(t.widget<OutlinedButton>(decline).onPressed, isNotNull);

          api.json('POST /blog/posts/p1/comments/c2/decision', {
            'comment': commentJson('c2'),
          });
          await t.tap(row.$1 == 'approve' ? approve : decline);
          await qaSettle(t);
          expect(api.writes, hasLength(2));
        },
      );
    }
  });

  group('comment options', () {
    const options = ValueKey('qa.blog.comment.options.c1');

    Future<void> openReport(WidgetTester t) async {
      await t.tap(find.byKey(options));
      await qaSettle(t);
      await t.tap(find.text(en.blogReportComment));
      await qaSettle(t);
    }

    Future<void> fillReport(WidgetTester t) async {
      await t.tap(find.text(en.reportReasonInappropriate));
      await qaSettle(t);
      await t.tap(find.text(en.reportReasonHarassment).last);
      await qaSettle(t);
      await t.enterText(
        find.widgetWithText(TextField, en.reportDescriptionLabel),
        'Rude about my friend',
      );
      await t.pump();
    }

    testWidgets(
      'regression: Report comment sends the reason and details, closes the '
      'sheet and confirms it was sent '
      '[case:blog.blog_social.x_comment_options_x_report.action] '
      '[case:blog.blog_social.report_could_not_be_submitted_onsubmit.action]',
      (t) async {
        final api = commentsApi(() => [commentJson('c1', body: 'Ugh.')])
          ..json('POST /blog/reports/comment/c1', {
            'report': {'id': 'r1'},
          });
        await pumpQa(t, api, chapter(BlogPost.fromJson(postJson())));
        await openReport(t);
        expect(find.text(en.reportSheetTitle), findsOneWidget);
        await fillReport(t);
        await t.tap(find.text(en.reportSubmit));
        await qaSettle(t);
        expect(api.writeLines, ['POST /blog/reports/comment/c1']);
        expect(api.writes.single.body, {
          'reason': 'harassment',
          'description': 'Rude about my friend',
        });
        expect(find.text(en.reportSheetTitle), findsNothing);
        expect(qaSnackText(t), en.communityReportSubmitted);
      },
    );

    testWidgets(
      'A failed comment report keeps the sheet and the words, explains, and '
      'the retry is the only other request '
      '[case:blog.blog_social.x_comment_options_x_report.api_failure] '
      '[case:blog.blog_social.report_could_not_be_submitted_onsubmit.api_failure]',
      (t) async {
        final api = commentsApi(() => [commentJson('c1', body: 'Ugh.')])
          ..fail('POST /blog/reports/comment/c1');
        await pumpQa(t, api, chapter(BlogPost.fromJson(postJson())));
        await openReport(t);
        await fillReport(t);
        await t.tap(find.text(en.reportSubmit));
        await qaSettle(t);
        expect(api.writes, hasLength(1));
        expect(find.text(en.reportSheetTitle), findsOneWidget);
        expect(qaSnackText(t), en.reportSubmitFailed);
        expect(find.text('Rude about my friend'), findsOneWidget);
        expect(
          t
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, en.reportSubmit),
              )
              .onPressed,
          isNotNull,
        );

        api.json('POST /blog/reports/comment/c1', {
          'report': {'id': 'r1'},
        });
        await t.tap(find.text(en.reportSubmit));
        await qaSettle(t);
        expect(api.writes, hasLength(2));
        expect(api.writes.last.body, {
          'reason': 'harassment',
          'description': 'Rude about my friend',
        });
        expect(find.text(en.reportSheetTitle), findsNothing);
        expect(qaSnackText(t), en.communityReportSubmitted);
      },
    );

    testWidgets(
      'Delete comment asks first; Cancel keeps it, Delete removes it and '
      'confirms [case:blog.blog_social.comment_options_ondelete.action]',
      (t) async {
        var deleted = false;
        final api =
            commentsApi(
              () => [
                if (!deleted)
                  commentJson(
                    'c1',
                    status: 'pending',
                    mine: true,
                    body: 'Second thoughts.',
                  ),
              ],
            )..on('DELETE /blog/posts/p1/comments/c1', (_) {
              deleted = true;
              return qaOk();
            });
        await pumpQa(t, api, chapter(BlogPost.fromJson(postJson())));
        await t.tap(find.byKey(options));
        await qaSettle(t);
        expect(find.text(en.blogReportComment), findsNothing, reason: 'mine');
        await t.tap(find.text(en.blogDeleteComment));
        await qaSettle(t);
        expect(find.text(en.blogDeleteCommentTitle), findsOneWidget);
        await t.tap(find.text(en.blogCancel));
        await qaSettle(t);
        expect(api.writes, isEmpty);
        expect(find.text('Second thoughts.'), findsOneWidget);

        await t.tap(find.byKey(options));
        await qaSettle(t);
        await t.tap(find.text(en.blogDeleteComment));
        await qaSettle(t);
        await t.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text(en.blogDeleteComment),
          ),
        );
        await qaSettle(t);
        expect(api.writeLines, ['DELETE /blog/posts/p1/comments/c1']);
        expect(qaSnackText(t), en.blogCommentDeleted);
        expect(find.text('Second thoughts.'), findsNothing);
      },
    );

    testWidgets('A failed delete explains and keeps the comment '
        '[case:blog.blog_social.comment_options_ondelete.api_failure]', (
      t,
    ) async {
      final api =
          commentsApi(
            () => [
              commentJson(
                'c1',
                status: 'pending',
                mine: true,
                body: 'Keep me.',
              ),
            ],
          )..on(
            'DELETE /blog/posts/p1/comments/c1',
            (_) => const QaReply(500, <String, dynamic>{}),
          );
      await pumpQa(t, api, chapter(BlogPost.fromJson(postJson())));
      await t.tap(find.byKey(options));
      await qaSettle(t);
      await t.tap(find.text(en.blogDeleteComment));
      await qaSettle(t);
      await t.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(en.blogDeleteComment),
        ),
      );
      await qaSettle(t);
      expect(api.writes, hasLength(1));
      expect(qaSnackText(t), en.blogCommentDeleteFailed);
      expect(find.text('Keep me.'), findsOneWidget);
    });
  });

  group('comment text', () {
    const body = 'Line one 🌙\nשלום — مرحبا\n  spaced  ';

    testWidgets(
      'A comment is selectable: select all and copy puts its exact words on '
      'the clipboard [case:blog.blog_social.selectabletext_input_input.action]',
      (t) async {
        final clipboard = FakeClipboard()..install(t);
        final api = commentsApi(
          () => [commentJson('c1', body: 'Keep this line.')],
        );
        await pumpQa(t, api, chapter(BlogPost.fromJson(postJson())));
        final text = find.widgetWithText(SelectableText, 'Keep this line.');
        expect(text, findsOneWidget);
        await copyAllOf(t, text);
        expect(clipboard.text, 'Keep this line.');
        expect(api.writes, isEmpty);
      },
    );

    testWidgets(
      'Emoji, RTL and line breaks in a comment render and copy byte-for-byte '
      '[case:blog.blog_social.selectabletext_input_input.validation]',
      (t) async {
        final clipboard = FakeClipboard()..install(t);
        final api = commentsApi(() => [commentJson('c1', body: body)]);
        await pumpQa(t, api, chapter(BlogPost.fromJson(postJson())));
        final text = find.byWidgetPredicate(
          (w) => w is SelectableText && w.data == body,
        );
        expect(text, findsOneWidget);
        await copyAllOf(t, text);
        expect(clipboard.text, body);
      },
    );
  });

  testWidgets('Likes and comments render translated in every language without '
      'overflow [case:blog.blog_social.l10n]', (t) async {
    for (final locale in qaLocales) {
      final l10n = qaL10n(locale);
      final api = commentsApi(() => [commentJson('c1', body: 'Lovely.')]);
      await pumpQa(
        t,
        api,
        chapter(BlogPost.fromJson(postJson())),
        locale: locale,
        size: const Size(360, 800),
      );
      expect(t.takeException(), isNull, reason: '$locale');
      expect(find.text(l10n.blogComments), findsOneWidget, reason: '$locale');
      expect(find.text(l10n.blogSendToAuthor), findsOneWidget);
      expect(find.text(l10n.blogCommentCount(1)), findsOneWidget);
      expect(find.text(l10n.blogCommentsReaderNote), findsOneWidget);
      await t.pumpWidget(const SizedBox());

      // The reaction picker (a shared walls sheet) on the default phone.
      // It overflows on 360–390 px phones; reported to the walls owner.
      await pumpQa(
        t,
        commentsApi(() => []),
        chapter(BlogPost.fromJson(postJson())),
        locale: locale,
      );
      await t.tap(find.byKey(react));
      await qaSettle(t);
      expect(find.text(l10n.wallsReactQuestion('chapter')), findsOneWidget);
      expect(t.takeException(), isNull, reason: '$locale picker');
      await t.pumpWidget(const SizedBox());
    }
  });
}
