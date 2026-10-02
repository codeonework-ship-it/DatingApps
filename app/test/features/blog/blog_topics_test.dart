import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/blog/blog_data.dart';
import 'package:verified_dating_app/features/blog/blog_editor.dart';
import 'package:verified_dating_app/features/blog/blog_screen.dart';
import 'package:verified_dating_app/features/blog/blog_writers_screen.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

class _Auth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(isAuthenticated: true, userId: 'me');
}

/// Fake API: [route] answers each request; throw to fail it, return a Future
/// to hold it open.
class _Api {
  _Api(this.route);
  final FutureOr<Object?> Function(RequestOptions r) route;
  final requests = <RequestOptions>[];

  List<RequestOptions> feedReads() => [
    for (final r in requests)
      if (r.path == '/blog/posts') r,
  ];

  Dio get dio => Dio()
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (r, h) async {
          requests.add(r);
          try {
            final data = await route(r);
            h.resolve(
              Response<dynamic>(requestOptions: r, statusCode: 200, data: data),
            );
          } on Object catch (e) {
            h.reject(
              DioException(
                requestOptions: r,
                error: e,
                response: Response<dynamic>(
                  requestOptions: r,
                  statusCode: 500,
                  data: {'error': 'Something went wrong.'},
                ),
              ),
            );
          }
        },
      ),
    );
}

const _topics = {
  'topics': [
    {
      'slug': 'feelings',
      'title': 'Feelings & healing',
      'description': '',
      'post_count': 4,
    },
    {
      'slug': 'love',
      'title': 'Love & relationships',
      'description': '',
      'post_count': 2,
    },
  ],
};

Map<String, dynamic> _post({
  String id = 'p1',
  String author = 'writer',
  Map<String, dynamic> extra = const {},
}) => {
  'id': id,
  'author_id': author,
  'author_name': 'Meera',
  'title': 'Chapter $id',
  'body': 'Words for $id',
  'audience': 'community',
  'invitation': '',
  'version': 1,
  'photos': <dynamic>[],
  ...extra,
};

Widget _host(_Api api, Widget child, {double scale = 1}) => ProviderScope(
  overrides: [
    authNotifierProvider.overrideWith(_Auth.new),
    apiClientProvider.overrideWithValue(api.dio),
  ],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: child,
  ),
);

Future<void> _tap(WidgetTester t, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await t.scrollUntilVisible(
      finder,
      250,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await t.ensureVisible(finder);
  await t.pumpAndSettle();
  await t.tap(finder);
  await t.pumpAndSettle();
}

void main() {
  test('chapters parse topic and follow fields with safe defaults', () {
    final full = BlogPost.fromJson(
      _post(
        extra: {
          'topic': 'feelings',
          'topic_title': 'Feelings & healing',
          'author_subscribed': true,
          'author_subscriber_count': 12,
        },
      ),
    );
    expect(full.topic, 'feelings');
    expect(full.topicTitle, 'Feelings & healing');
    expect(full.authorSubscribed, isTrue);
    expect(full.authorSubscriberCount, 12);

    final bare = BlogPost.fromJson(_post());
    expect(bare.topic, '');
    expect(bare.topicTitle, '');
    expect(bare.authorSubscribed, isFalse);
    expect(bare.authorSubscriberCount, 0);

    final topic = BlogTopic.fromJson((_topics['topics']! as List).first as Map);
    expect(topic.slug, 'feelings');
    expect(topic.postCount, 4);
  });

  testWidgets('topic chips filter the current scope', (t) async {
    final api = _Api(
      (r) => switch (r.path) {
        '/blog/topics' => _topics,
        '/blog/posts' => {'posts': <dynamic>[], 'next_cursor': ''},
        _ => <String, dynamic>{},
      },
    );
    await t.pumpWidget(_host(api, const BlogScreen()));
    await t.pumpAndSettle();
    expect(api.feedReads().last.queryParameters.containsKey('topic'), isFalse);

    await _tap(t, find.widgetWithText(ChoiceChip, 'Feelings & healing'));
    expect(api.feedReads().last.queryParameters['scope'], 'community');
    expect(api.feedReads().last.queryParameters['topic'], 'feelings');

    await _tap(t, find.widgetWithText(ChoiceChip, 'Friends'));
    expect(api.feedReads().last.queryParameters['scope'], 'friends');
    expect(api.feedReads().last.queryParameters['topic'], 'feelings');

    await _tap(t, find.byKey(const ValueKey('blog.topic.all')));
    expect(api.feedReads().last.queryParameters.containsKey('topic'), isFalse);
  });

  testWidgets('Top rated ranks chapters and explains the ranking', (t) async {
    final api = _Api(
      (r) => switch (r.path) {
        '/blog/topics' => _topics,
        '/blog/posts' when r.queryParameters['scope'] == 'top' => {
          'posts': [
            _post(
              id: 'a',
              extra: {'topic': 'feelings', 'topic_title': 'Feelings & healing'},
            ),
            _post(id: 'b'),
            _post(id: 'c'),
          ],
          'next_cursor': '',
        },
        '/blog/posts' => {'posts': <dynamic>[], 'next_cursor': ''},
        _ => <String, dynamic>{},
      },
    );
    await t.pumpWidget(_host(api, const BlogScreen()));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('blog.rank.a')), findsNothing);

    await _tap(t, find.widgetWithText(ChoiceChip, 'Top rated'));
    expect(api.feedReads().last.queryParameters['scope'], 'top');
    expect(
      find.textContaining('Ranked by likes, approved comments and readers'),
      findsOneWidget,
    );
    for (final (id, rank) in [('a', '1'), ('b', '2'), ('c', '3')]) {
      final badge = find.byKey(ValueKey('blog.rank.$id'));
      await t.ensureVisible(badge);
      expect(
        find.descendant(of: badge, matching: find.text(rank)),
        findsOneWidget,
      );
    }
    expect(find.byKey(const ValueKey('blog.post_topic.a')), findsOneWidget);
  });

  testWidgets('empty Top rated and Following explain what to do', (t) async {
    final api = _Api(
      (r) => switch (r.path) {
        '/blog/posts' => {'posts': <dynamic>[], 'next_cursor': ''},
        _ => <String, dynamic>{},
      },
    );
    await t.pumpWidget(_host(api, const BlogScreen()));
    await t.pumpAndSettle();
    await _tap(t, find.widgetWithText(ChoiceChip, 'Following'));
    expect(api.feedReads().last.queryParameters['scope'], 'subscriptions');
    expect(find.textContaining('tap Follow their chapters'), findsOneWidget);

    await _tap(t, find.byKey(const ValueKey('blog.following.see_top')));
    expect(api.feedReads().last.queryParameters['scope'], 'top');
    expect(
      find.text('When chapters move people, they rise here.'),
      findsOneWidget,
    );
  });

  group('follow on a chapter', () {
    Widget detail(_Api api) => _host(api, const BlogDetailScreen(id: 'p1'));
    Map<String, dynamic> chapter({String author = 'writer'}) => {
      'post': _post(
        author: author,
        extra: {'author_subscribed': false, 'author_subscriber_count': 12},
      ),
    };

    testWidgets('flips at once, then confirms with the server', (t) async {
      final pending = Completer<Object?>();
      final api = _Api((r) {
        if (r.path == '/blog/authors/writer/subscription') {
          return pending.future;
        }
        if (r.path.endsWith('/comments')) return {'comments': <dynamic>[]};
        return chapter();
      });
      await t.pumpWidget(detail(api));
      await t.pumpAndSettle();
      expect(find.text('12 followers'), findsOneWidget);

      await t.tap(find.text('Follow their chapters'));
      await t.pump();
      expect(find.text('Following'), findsOneWidget);
      expect(find.text('13 followers'), findsOneWidget);
      await t.pump(const Duration(milliseconds: 50));
      expect(
        api.requests.where((r) => r.method == 'PUT').single.path,
        '/blog/authors/writer/subscription',
      );

      pending.complete({'subscribed': true, 'subscriber_count': 14});
      await t.pumpAndSettle();
      expect(find.text('Following'), findsOneWidget);
      expect(find.text('14 followers'), findsOneWidget);
    });

    testWidgets('rolls back and explains when the server fails', (t) async {
      final pending = Completer<Object?>();
      final api = _Api((r) {
        if (r.path == '/blog/authors/writer/subscription') {
          return pending.future;
        }
        if (r.path.endsWith('/comments')) return {'comments': <dynamic>[]};
        return chapter();
      });
      await t.pumpWidget(detail(api));
      await t.pumpAndSettle();
      await t.tap(find.text('Follow their chapters'));
      await t.pump();
      expect(find.text('Following'), findsOneWidget);
      await t.pump(const Duration(milliseconds: 50));
      expect(api.requests.where((r) => r.method == 'PUT'), hasLength(1));

      pending.completeError(StateError('offline'));
      await t.pumpAndSettle();
      expect(find.text('Follow their chapters'), findsOneWidget);
      expect(find.text('12 followers'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('is hidden on your own chapters', (t) async {
      final api = _Api((r) {
        if (r.path.endsWith('/comments')) return {'comments': <dynamic>[]};
        return chapter(author: 'me');
      });
      await t.pumpWidget(detail(api));
      await t.pumpAndSettle();
      expect(find.text('12 followers'), findsOneWidget);
      expect(find.text('Follow their chapters'), findsNothing);
      expect(find.text('Following'), findsNothing);
    });
  });

  testWidgets('writers you follow lists writers and can unfollow', (t) async {
    var followed = true;
    final api = _Api((r) {
      if (r.path == '/blog/subscriptions') {
        return {
          'writers': [
            if (followed)
              {
                'author_id': 'writer',
                'name': 'Meera',
                'subscriber_count': 3,
                'latest_title': 'Rain on the terrace',
                'latest_post_id': 'p1',
              },
          ],
        };
      }
      if (r.method == 'DELETE') {
        followed = false;
        return {'subscribed': false, 'subscriber_count': 2};
      }
      return <String, dynamic>{};
    });
    await t.pumpWidget(_host(api, const BlogWritersScreen()));
    await t.pumpAndSettle();
    expect(find.text('Meera'), findsOneWidget);
    expect(find.text('3 followers'), findsOneWidget);
    expect(find.textContaining('Rain on the terrace'), findsOneWidget);

    await t.tap(find.text('Following'));
    await t.pumpAndSettle();
    expect(
      api.requests.where((r) => r.method == 'DELETE').single.path,
      '/blog/authors/writer/subscription',
    );
    expect(find.byKey(const ValueKey('blog.writers.empty')), findsOneWidget);
  });

  group('editor', () {
    _Api editorApi() {
      var saved = <String, dynamic>{..._post(author: 'me'), 'version': 0};
      return _Api((r) {
        if (r.path == '/blog/topics') return _topics;
        if (r.method == 'PUT') {
          saved = {
            ...saved,
            ...Map<String, dynamic>.from(r.data as Map),
            'id': r.path.split('/').last,
            'author_id': 'me',
            'version': (r.data['expected_version'] as int) + 1,
          };
        }
        return {'post': saved};
      });
    }

    Future<void> write(WidgetTester t) async {
      await t.enterText(
        find.widgetWithText(TextField, 'Chapter title'),
        'A small mercy',
      );
      await t.enterText(
        find.widgetWithText(TextField, 'Your story'),
        'Someone held the door.',
      );
    }

    testWidgets('sends the chosen topic and clears it on a second tap', (
      t,
    ) async {
      final api = editorApi();
      await t.pumpWidget(_host(api, const BlogEditor()));
      await t.pumpAndSettle();
      await write(t);
      await _tap(t, find.widgetWithText(ChoiceChip, 'Feelings & healing'));
      await _tap(t, find.byKey(const ValueKey('blog.save')));
      final puts = api.requests.where((r) => r.method == 'PUT').toList();
      expect(puts.last.data['topic'], 'feelings');
      expect(puts.last.data['audience'], 'private');
      expect(puts.last.data.containsKey('allow_featuring'), isTrue);

      await _tap(t, find.widgetWithText(ChoiceChip, 'Feelings & healing'));
      await _tap(t, find.byKey(const ValueKey('blog.save')));
      expect(
        api.requests.where((r) => r.method == 'PUT').last.data['topic'],
        '',
      );
    });

    testWidgets('first share beyond Only me points to XP and level', (t) async {
      final api = editorApi();
      await t.pumpWidget(_host(api, const BlogEditor()));
      await t.pumpAndSettle();
      await write(t);
      await _tap(t, find.byKey(const ValueKey('blog.save')));
      expect(find.byKey(const ValueKey('blog.shared_snack')), findsNothing);

      await _tap(t, find.widgetWithText(ChoiceChip, 'Connect community'));
      await _tap(t, find.byKey(const ValueKey('blog.save')));
      await t.tap(find.widgetWithText(FilledButton, 'Publish chapter'));
      await t.pumpAndSettle();
      expect(
        find.text('Shared. Readers’ likes and comments earn you XP.'),
        findsOneWidget,
      );
      expect(find.widgetWithText(SnackBarAction, 'See my level'), findsOne);
    });
  });

  testWidgets('rewards sheet lists the contract values', (t) async {
    // From documents/BLOG_TOPICS_SUBSCRIPTIONS_REWARDS_2026-10-01.md.
    const contract = <String, (int, int)>{
      'story_published': (25, 50),
      'photo_shared': (20, 40),
      'like_received': (2, 40),
      'comment_received': (5, 50),
      'comment_approved': (5, 30),
      'subscriber_gained': (10, 100),
      'wall_tier_reached': (50, 150),
      'cover_of_week': (150, 150),
    };
    expect({
      for (final r in blogRewards) r.source: (r.xp, r.dailyCap),
    }, contract);

    final api = _Api(
      (r) => switch (r.path) {
        '/blog/posts' => {'posts': <dynamic>[], 'next_cursor': ''},
        _ => <String, dynamic>{},
      },
    );
    await t.pumpWidget(_host(api, const BlogScreen()));
    await t.pumpAndSettle();
    await t.tap(find.byTooltip('How rewards work'));
    await t.pumpAndSettle();
    expect(find.text('How rewards work'), findsWidgets);
    for (final MapEntry(key: source, value: (xp, cap)) in contract.entries) {
      final row = find.byKey(ValueKey('blog.reward.$source'));
      await t.scrollUntilVisible(
        row,
        120,
        scrollable: find
            .descendant(
              of: find.byKey(const ValueKey('blog.rewards_sheet')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(
        find.descendant(of: row, matching: find.text('+$xp XP')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: row, matching: find.text('Up to $cap XP a day')),
        findsOneWidget,
      );
    }
  });

  testWidgets('narrow phone at 1.3x text holds tabs, ranks and author row', (
    t,
  ) async {
    t.view.physicalSize = const Size(320, 640);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final post = _post(
      id: 'a',
      extra: {
        'topic': 'culture',
        'topic_title': 'Books, films & music',
        'author_subscribed': false,
        'author_subscriber_count': 1200,
      },
    );
    final api = _Api((r) {
      if (r.path == '/blog/topics') return _topics;
      if (r.path == '/blog/posts') {
        return {
          'posts': [post],
          'next_cursor': '',
        };
      }
      if (r.path.endsWith('/comments')) return {'comments': <dynamic>[]};
      return {'post': post};
    });
    await t.pumpWidget(_host(api, const BlogScreen(), scale: 1.3));
    await t.pumpAndSettle();
    await _tap(t, find.widgetWithText(ChoiceChip, 'Top rated'));
    expect(find.byKey(const ValueKey('blog.rank.a')), findsOneWidget);
    expect(t.takeException(), isNull);

    await t.pumpWidget(_host(api, const BlogDetailScreen(id: 'a'), scale: 1.3));
    await t.pumpAndSettle();
    expect(find.text('1200 followers'), findsOneWidget);
    expect(find.text('Follow their chapters'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
