import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/blog/blog_data.dart';
import 'package:verified_dating_app/features/blog/blog_screen.dart';
import 'package:verified_dating_app/features/blog/blog_social.dart';

class _Auth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(isAuthenticated: true, userId: 'me');
}

Map<String, dynamic> postJson({
  String id = 'p1',
  String author = 'author',
  int likes = 3,
  bool liked = false,
  Map<String, dynamic> extra = const {},
}) => {
  'id': id,
  'author_id': author,
  'author_name': 'Priya',
  'title': 'The bookshop on the corner',
  'body': 'A small story.',
  'audience': 'community',
  'invitation': '',
  'version': 2,
  'photos': <dynamic>[],
  'like_count': likes,
  'liked_by_me': liked,
  'comment_count': 1,
  'pending_comment_count': 0,
  'allow_featuring': true,
  'featured': false,
  ...extra,
};

Map<String, dynamic> commentJson(
  String id, {
  String status = 'approved',
  bool mine = false,
  bool canModerate = false,
  String body = 'Lovely.',
}) => {
  'id': id,
  'post_id': 'p1',
  'author_id': mine ? 'me' : 'reader-$id',
  'author_name': 'Reader $id',
  'body': body,
  'status': status,
  'mine': mine,
  'can_moderate': canModerate,
  'created_at': '2026-10-01T09:00:00Z',
};

typedef _Handler = FutureOr<Object?> Function(RequestOptions r);

/// Fake API: [handler] returns response data, or throws a status code (int)
/// to reject with that HTTP status.
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

Widget host(_Api api, Widget child) => ProviderScope(
  overrides: [
    authNotifierProvider.overrideWith(_Auth.new),
    apiClientProvider.overrideWithValue(api.dio),
  ],
  child: MaterialApp(
    home: Scaffold(body: ListView(children: [child])),
  ),
);

void main() {
  group('BlogPost parsing', () {
    test('reads likes, comments and featuring fields', () {
      final post = BlogPost.fromJson(
        postJson(
          likes: 12,
          liked: true,
          extra: {
            'comment_count': 3,
            'pending_comment_count': 1,
            'featured': true,
          },
        ),
      );
      expect(post.likeCount, 12);
      expect(post.likedByMe, isTrue);
      expect(post.commentCount, 3);
      expect(post.pendingCommentCount, 1);
      expect(post.allowFeaturing, isTrue);
      expect(post.featured, isTrue);
    });

    test('older payloads without the new fields still parse safely', () {
      final json = postJson()
        ..remove('like_count')
        ..remove('liked_by_me')
        ..remove('comment_count')
        ..remove('pending_comment_count')
        ..remove('allow_featuring')
        ..remove('featured');
      final post = BlogPost.fromJson(json);
      expect(post.likeCount, 0);
      expect(post.likedByMe, isFalse);
      expect(post.commentCount, 0);
      expect(post.pendingCommentCount, 0);
      expect(post.allowFeaturing, isFalse);
      expect(post.featured, isFalse);
    });

    test('reads tiered reach and the next tier', () {
      final post = BlogPost.fromJson(
        postJson(
          extra: {
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
      expect(post.wallReach, 50);
      final tier = post.nextTier!;
      expect(tier.reach, 100);
      expect(tier.likesNeeded, 38);
      expect(tier.commentsNeeded, 4);
      expect(tier.progress, closeTo((62 + 6) / 110, 1e-9));
    });

    test('reach fields are optional and null next_tier is fine', () {
      final absent = BlogPost.fromJson(postJson());
      expect(absent.wallReach, 0);
      expect(absent.nextTier, isNull);
      final explicit = BlogPost.fromJson(
        postJson(extra: {'wall_reach': 0, 'next_tier': null}),
      );
      expect(explicit.nextTier, isNull);
    });

    test('tier copy names only what is still needed', () {
      BlogNextTier tier(int likes, int comments) => BlogNextTier(
        likes: 50,
        comments: 5,
        reach: 50,
        likesNeeded: likes,
        commentsNeeded: comments,
      );
      expect(
        blogTierNeeds(tier(38, 4)),
        '38 more likes and 4 more comments to reach 50 walls',
      );
      expect(blogTierNeeds(tier(1, 0)), '1 more like to reach 50 walls');
      expect(blogTierNeeds(tier(0, 1)), '1 more comment to reach 50 walls');
    });

    test('comment JSON parses every contract field', () {
      final c = BlogComment.fromJson(
        commentJson('c1', status: 'pending', mine: true, body: 'Hello'),
      );
      expect(c.id, 'c1');
      expect(c.postId, 'p1');
      expect(c.authorId, 'me');
      expect(c.body, 'Hello');
      expect(c.isPending, isTrue);
      expect(c.mine, isTrue);
      expect(c.canModerate, isFalse);
      expect(c.createdAt, DateTime.utc(2026, 10, 1, 9));
    });
  });

  group('comment grouping', () {
    final comments = [
      BlogComment.fromJson(commentJson('a1')),
      BlogComment.fromJson(commentJson('p-other', status: 'pending')),
      BlogComment.fromJson(
        commentJson('p-mine', status: 'pending', mine: true),
      ),
      BlogComment.fromJson(
        commentJson('d-mine', status: 'declined', mine: true),
      ),
      BlogComment.fromJson(commentJson('d-other', status: 'declined')),
    ];
    List<String> ids(List<BlogComment> list) => [for (final c in list) c.id];

    test('the chapter author sees pending comments to approve', () {
      final g = groupBlogComments(comments, viewerIsAuthor: true);
      expect(ids(g.awaitingMyApproval), ['p-other']);
      expect(ids(g.approved), ['a1']);
    });

    test('other readers never see someone else’s pending comment', () {
      final g = groupBlogComments(comments, viewerIsAuthor: false);
      expect(g.awaitingMyApproval, isEmpty);
      expect(ids(g.approved), ['a1']);
      expect(ids(g.mineSent), ['p-mine']);
      expect(ids(g.mineDeclined), ['d-mine']);
    });
  });

  group('likes', () {
    test('a failed like rolls back to the server state and rethrows', () async {
      final api = _Api((r) => throw 500);
      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(_Auth.new),
          apiClientProvider.overrideWithValue(api.dio),
        ],
      );
      addTearDown(container.dispose);
      final post = BlogPost.fromJson(postJson());
      final likes = container.read(blogLikesProvider.notifier);
      final pending = likes.toggle(post);
      expect(
        container.read(blogLikesProvider)['p1'],
        const BlogLikeState(
          liked: true,
          count: 4,
          reaction: 'love',
          reactions: {'love': 1},
        ),
      );
      await expectLater(pending, throwsA(isA<DioException>()));
      expect(container.read(blogLikesProvider), isEmpty);
      expect(likes.of(post), const BlogLikeState(liked: false, count: 3));
      expect(api.requests.single.method, 'PUT');
      expect(api.requests.single.path, '/blog/posts/p1/like');
    });

    test(
      'a confirmed like adopts the server count; a failed unlike restores it',
      () async {
        var fail = false;
        final api = _Api((r) {
          if (fail) throw 429;
          return {'post': postJson(likes: 8, liked: true)};
        });
        final container = ProviderContainer(
          overrides: [
            authNotifierProvider.overrideWith(_Auth.new),
            apiClientProvider.overrideWithValue(api.dio),
          ],
        );
        addTearDown(container.dispose);
        final post = BlogPost.fromJson(postJson());
        final likes = container.read(blogLikesProvider.notifier);
        await likes.toggle(post);
        expect(likes.of(post), const BlogLikeState(liked: true, count: 8));
        fail = true;
        await expectLater(likes.toggle(post), throwsA(isA<DioException>()));
        expect(api.requests.last.method, 'DELETE');
        expect(likes.of(post), const BlogLikeState(liked: true, count: 8));
      },
    );

    testWidgets('the heart flips at once and rolls back with a message', (
      t,
    ) async {
      final gate = Completer<void>();
      final api = _Api((r) async {
        await gate.future;
        throw 500;
      });
      final post = BlogPost.fromJson(postJson());
      await t.pumpWidget(host(api, BlogLikeButton(post: post)));
      await t.tap(find.byKey(const ValueKey('blog.like.p1')));
      await t.pump();
      expect(find.text('4'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      gate.complete();
      await t.pumpAndSettle();
      expect(find.text('3'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    test('reactions parse; unknown ones are ignored', () {
      final post = BlogPost.fromJson(
        postJson(
          likes: 4,
          liked: true,
          extra: {
            'my_reaction': 'hear_you',
            'reactions': {'hear_you': 3, 'love': 1, 'meh': 9},
          },
        ),
      );
      expect(post.myReaction, 'hear_you');
      expect(post.reactions, {'hear_you': 3, 'love': 1});
    });

    test('switching a reaction keeps one like and moves the tally', () {
      const state = BlogLikeState(
        liked: true,
        count: 5,
        reaction: 'love',
        reactions: {'love': 5},
      );
      final hug = state.next(like: true, reaction: 'hug');
      expect(hug.count, 5);
      expect(hug.reaction, 'hug');
      expect(hug.reactions, {'love': 4, 'hug': 1});
      final gone = hug.next(like: false);
      expect(gone.count, 4);
      expect(gone.liked, isFalse);
      expect(gone.reactions, {'love': 4});
      expect(state.next(like: true), same(state));
    });

    test('react sends the reaction and adopts the server tally', () async {
      final api = _Api(
        (r) => {
          'post': postJson(
            likes: 4,
            liked: true,
            extra: {
              'my_reaction': 'hear_you',
              'reactions': {'hear_you': 1, 'love': 3},
            },
          ),
        },
      );
      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(_Auth.new),
          apiClientProvider.overrideWithValue(api.dio),
        ],
      );
      addTearDown(container.dispose);
      final post = BlogPost.fromJson(postJson());
      final likes = container.read(blogLikesProvider.notifier);
      await likes.react(post, 'hear_you');
      expect(api.requests.single.method, 'PUT');
      expect(api.requests.single.data, {'reaction': 'hear_you'});
      expect(likes.of(post).reaction, 'hear_you');
      expect(likes.of(post).reactions, {'hear_you': 1, 'love': 3});
    });

    testWidgets('the react button opens the picker and shows the choice', (
      t,
    ) async {
      final api = _Api(
        (r) => {
          'post': postJson(
            likes: 4,
            liked: true,
            extra: {
              'my_reaction': 'hear_you',
              'reactions': {'hear_you': 1, 'love': 3},
            },
          ),
        },
      );
      final post = BlogPost.fromJson(postJson());
      await t.pumpWidget(host(api, BlogEngagementRow(post: post)));
      await t.tap(find.byKey(const ValueKey('blog.like.p1.react')));
      await t.pumpAndSettle();
      expect(find.text('How does this chapter make you feel?'), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('reaction.option.hear_you')));
      await t.pumpAndSettle();
      expect(api.requests.single.data, {'reaction': 'hear_you'});
      expect(find.text('🫶'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('🫶 1'), findsOneWidget);
      expect(find.text('❤️ 3'), findsOneWidget);
    });

    testWidgets('authors cannot like their own chapter', (t) async {
      final api = _Api((r) => {'post': postJson()});
      final post = BlogPost.fromJson(postJson(author: 'me'));
      await t.pumpWidget(host(api, BlogLikeButton(post: post)));
      final button = t.widget<TextButton>(
        find.byKey(const ValueKey('blog.like.p1')),
      );
      expect(button.onPressed, isNull);
      expect(
        find.byWidgetPredicate(
          (w) => w is Tooltip && w.message == 'You can’t like your own chapter',
        ),
        findsOneWidget,
      );
      await t.tap(find.byKey(const ValueKey('blog.like.p1')));
      await t.pump();
      expect(api.requests, isEmpty);
    });
  });

  group('comments section', () {
    testWidgets('the author sees pending comments and can approve them', (
      t,
    ) async {
      final api = _Api((r) {
        if (r.method == 'GET') {
          return {
            'comments': [
              commentJson('c1', body: 'Shared already.'),
              commentJson(
                'c2',
                status: 'pending',
                canModerate: true,
                body: 'Waiting on you.',
              ),
            ],
          };
        }
        return {'comment': commentJson('c2')};
      });
      final post = BlogPost.fromJson(postJson(author: 'me'));
      await t.pumpWidget(host(api, BlogCommentsSection(post: post)));
      await t.pumpAndSettle();
      expect(find.text('Waiting for your approval'), findsOneWidget);
      expect(find.text('Waiting on you.'), findsOneWidget);
      expect(find.text('Shared already.'), findsOneWidget);
      expect(find.byKey(const ValueKey('blog.comment.field')), findsNothing);
      await t.tap(find.byKey(const ValueKey('blog.comment.approve.c2')));
      await t.pumpAndSettle();
      final decision = api.requests.firstWhere((r) => r.method == 'POST');
      expect(decision.path, '/blog/posts/p1/comments/c2/decision');
      expect(decision.data, {'decision': 'approve'});
    });

    testWidgets('readers see approved and their own pending comments only', (
      t,
    ) async {
      final api = _Api((r) {
        if (r.method == 'GET') {
          return {
            'comments': [
              commentJson('c1', body: 'Shared already.'),
              commentJson('c2', status: 'pending', body: 'Someone else.'),
              commentJson('c3', status: 'pending', mine: true, body: 'Mine.'),
            ],
          };
        }
        return {'comment': commentJson('new', status: 'pending', mine: true)};
      });
      final post = BlogPost.fromJson(postJson());
      await t.pumpWidget(host(api, BlogCommentsSection(post: post)));
      await t.pumpAndSettle();
      expect(find.text('Waiting for your approval'), findsNothing);
      expect(find.text('Someone else.'), findsNothing);
      expect(find.text('Shared already.'), findsOneWidget);
      expect(find.text('Mine.'), findsOneWidget);
      expect(find.text('Sent to the author for approval'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('blog.comment.approve.c2')),
        findsNothing,
      );

      await t.enterText(
        find.byKey(const ValueKey('blog.comment.field')),
        '  This made me want to visit.  ',
      );
      await t.pump();
      await t.tap(find.byKey(const ValueKey('blog.comment.send')));
      await t.pumpAndSettle();
      final put = api.requests.firstWhere((r) => r.method == 'PUT');
      expect(
        put.path,
        matches(
          RegExp(
            r'^/blog/posts/p1/comments/[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
      expect(put.data, {'body': 'This made me want to visit.'});
      // The composer notice plus the pending comment's own label.
      expect(find.text('Sent to the author for approval'), findsNWidgets(2));
    });

    testWidgets('a failed send keeps the words and retries with the same id', (
      t,
    ) async {
      var fail = true;
      final api = _Api((r) {
        if (r.method == 'GET') return {'comments': <dynamic>[]};
        if (fail) throw 500;
        return {'comment': commentJson('x', status: 'pending', mine: true)};
      });
      final post = BlogPost.fromJson(postJson());
      await t.pumpWidget(host(api, BlogCommentsSection(post: post)));
      await t.pumpAndSettle();
      await t.enterText(
        find.byKey(const ValueKey('blog.comment.field')),
        'Hello there',
      );
      await t.pump();
      await t.tap(find.byKey(const ValueKey('blog.comment.send')));
      await t.pumpAndSettle();
      expect(find.text('Hello there'), findsOneWidget);
      fail = false;
      await t.tap(find.byKey(const ValueKey('blog.comment.send')));
      await t.pumpAndSettle();
      final puts = api.requests.where((r) => r.method == 'PUT').toList();
      expect(puts, hasLength(2));
      expect(puts[0].path, puts[1].path);
      expect(find.text('Hello there'), findsNothing);
    });
  });

  testWidgets('community feed leads with Featured Stories and engagement', (
    t,
  ) async {
    final api = _Api((r) {
      if (r.path == '/blog/featured') {
        return {
          'posts': [
            postJson(
              id: 'f1',
              extra: {'title': 'Loved by many', 'featured': true},
            ),
          ],
        };
      }
      if (r.path == '/blog/posts') {
        return {
          'posts': [
            postJson(extra: {'featured': true}),
          ],
          'next_cursor': '',
        };
      }
      if (r.path.endsWith('/comments')) return {'comments': <dynamic>[]};
      return {
        'post': postJson(extra: {'featured': true}),
      };
    });
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(_Auth.new),
          apiClientProvider.overrideWithValue(api.dio),
        ],
        child: const MaterialApp(home: BlogScreen()),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('Featured Stories'), findsOneWidget);
    await t.tap(find.widgetWithText(ChoiceChip, 'Mine'));
    await t.pumpAndSettle();
    expect(find.text('Featured Stories'), findsNothing);
    await t.tap(find.widgetWithText(ChoiceChip, 'For you'));
    await t.pumpAndSettle();
    expect(find.text('Featured Stories'), findsOneWidget);
    expect(find.byKey(const ValueKey('blog.featured.f1')), findsOneWidget);
    await t.scrollUntilVisible(
      find.text('Read chapter →'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const ValueKey('blog.like.p1')), findsOneWidget);
    expect(find.text('1 comment'), findsOneWidget);
    await t.ensureVisible(find.text('Read chapter →'));
    await t.pumpAndSettle();
    await t.tap(find.text('Read chapter →'));
    await t.pumpAndSettle();
    expect(find.byType(BlogDetailScreen), findsOneWidget);
    expect(find.text('Featured'), findsOneWidget);
    expect(find.byKey(const ValueKey('blog.like.p1')), findsOneWidget);
    await t.scrollUntilVisible(
      find.byKey(const ValueKey('blog.comment.field')),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Comments'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('authors see their reach and progress; readers do not', (
    t,
  ) async {
    final api = _Api((r) => <String, dynamic>{});
    Map<String, dynamic> reach(String author) => postJson(
      author: author,
      extra: {
        'wall_reach': 50,
        'next_tier': {
          'likes': 100,
          'comments': 10,
          'reach': 100,
          'likes_needed': 38,
          'comments_needed': 4,
        },
      },
    );
    await t.pumpWidget(
      host(api, BlogReachCard(post: BlogPost.fromJson(reach('me')))),
    );
    expect(find.text('On 50 walls'), findsOneWidget);
    expect(
      find.text('38 more likes and 4 more comments to reach 100 walls'),
      findsOneWidget,
    );
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    await t.pumpWidget(
      host(api, BlogReachCard(post: BlogPost.fromJson(reach('author')))),
    );
    expect(find.text('On 50 walls'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });
}
