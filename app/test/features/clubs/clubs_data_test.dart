import 'package:dio/dio.dart';
import 'package:flutter/material.dart' hide Title;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/clubs/club_detail_screen.dart';
import 'package:verified_dating_app/features/clubs/clubs_data.dart';
import 'package:verified_dating_app/features/clubs/clubs_screen.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

class _Auth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(isAuthenticated: true, userId: 'me');
}

const _title = {
  'id': 'title-1',
  'kind': 'book',
  'title': 'Piranesi',
  'creator': 'Susanna Clarke',
  'release_year': 2020,
  'average_rating': 4.5,
  'review_count': 2,
};

final _selection = {
  'id': 'sel-1',
  'week_start': mondayOf(DateTime.now()),
  'note': 'Start with the first notebook.',
  'title': _title,
  'post_count': 3,
};

Map<String, Object?> _club({
  String id = 'club-1',
  String role = 'owner',
  Object? selection,
}) => {
  'id': id,
  'kind': 'book',
  'name': 'Sunday Slow Reads',
  'description': 'One chapter at a time.',
  'owner_id': 'me',
  'member_count': 8,
  'my_role': role,
  'version': 2,
  'moderation_state': 'active',
  'current_selection': selection,
};

/// Answers requests from [routes] keyed by "METHOD path".
class _FakeApi {
  _FakeApi(this.routes);
  final Map<String, Object> routes;
  final requests = <RequestOptions>[];

  Dio get dio => Dio()
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          final body = routes['${options.method} ${options.path}'];
          if (body == null) {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response<dynamic>(
                  requestOptions: options,
                  statusCode: 404,
                  data: {'error': 'not found'},
                ),
              ),
            );
            return;
          }
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: body,
            ),
          );
        },
      ),
    );
}

Widget _host(_FakeApi api, Widget child) => ProviderScope(
  overrides: [
    authNotifierProvider.overrideWith(_Auth.new),
    apiClientProvider.overrideWithValue(api.dio),
  ],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  ),
);

void main() {
  group('mondayOf', () {
    test('returns the same day for a Monday', () {
      expect(mondayOf(DateTime(2026, 9, 28)), '2026-09-28');
    });
    test('walks back from mid-week and Sunday', () {
      expect(mondayOf(DateTime(2026, 10, 1, 23, 59)), '2026-09-28');
      expect(mondayOf(DateTime(2026, 10, 4)), '2026-09-28');
    });
    test('crosses month and year boundaries', () {
      expect(mondayOf(DateTime(2026, 3, 1)), '2026-02-23');
      expect(mondayOf(DateTime(2027, 1, 2)), '2026-12-28');
    });
  });

  group('Title.fromJson', () {
    test('parses every contract field', () {
      final title = Title.fromJson(_title);
      expect(title.id, 'title-1');
      expect(title.kind, 'book');
      expect(title.title, 'Piranesi');
      expect(title.creator, 'Susanna Clarke');
      expect(title.releaseYear, 2020);
      expect(title.averageRating, 4.5);
      expect(title.reviewCount, 2);
      expect(title.byline, 'Susanna Clarke · 2020');
    });
    test('keeps a null release year and a null average rating', () {
      final title = Title.fromJson({
        ..._title,
        'release_year': null,
        'average_rating': null,
        'review_count': 0,
      });
      expect(title.releaseYear, isNull);
      expect(title.averageRating, isNull);
      expect(title.byline, 'Susanna Clarke');
    });
    test('reads an integer average rating as a double', () {
      expect(Title.fromJson({..._title, 'average_rating': 4}).averageRating, 4);
    });
  });

  group('Club.fromJson', () {
    test('parses the current selection and roles', () {
      final club = Club.fromJson(_club(selection: _selection));
      expect(club.name, 'Sunday Slow Reads');
      expect(club.memberCount, 8);
      expect(club.version, 2);
      expect(club.isOwner, isTrue);
      expect(club.canModerate, isTrue);
      expect(club.currentSelection?.title.title, 'Piranesi');
      expect(club.currentSelection?.postCount, 3);
    });
    test('allows a null current selection and an empty role', () {
      final club = Club.fromJson(_club(role: ''));
      expect(club.currentSelection, isNull);
      expect(club.isMember, isFalse);
      expect(club.canModerate, isFalse);
    });
  });

  test('ClubMember, ClubPost, TitleReview and MemberList parse', () {
    final member = ClubMember.fromJson({
      'user_id': 'u-2',
      'name': 'Sam',
      'role': 'moderator',
      'joined_at': '2026-09-01T08:00:00Z',
    });
    expect(member.role, 'moderator');
    expect(member.joinedAt, DateTime.utc(2026, 9, 1, 8));

    final post = ClubPost.fromJson({
      'id': 'p-1',
      'club_id': 'club-1',
      'selection_id': 'sel-1',
      'author_id': 'u-2',
      'author_name': 'Sam',
      'body': 'The statues!',
      'has_spoilers': true,
      'created_at': '2026-09-29T09:00:00Z',
      'mine': false,
      'hidden': true,
    });
    expect(post.hasSpoilers, isTrue);
    expect(post.hidden, isTrue);
    expect(post.mine, isFalse);

    final review = TitleReview.fromJson({
      'id': 'r-1',
      'title_id': 'title-1',
      'author_id': 'me',
      'author_name': 'Alex',
      'rating': 5,
      'body': 'Loved it.',
      'has_spoilers': false,
      'audience': 'friends',
      'version': 3,
      'created_at': '2026-09-20T09:00:00Z',
      'updated_at': '2026-09-21T09:00:00Z',
      'mine': true,
    });
    expect(review.rating, 5);
    expect(review.audience, 'friends');
    expect(review.version, 3);
    expect(review.updatedAt, DateTime.utc(2026, 9, 21, 9));

    final list = MemberList.fromJson({
      'id': 'l-1',
      'owner_id': 'me',
      'owner_name': 'Alex',
      'name': 'Read next',
      'kind': 'book',
      'audience': 'private',
      'version': 1,
      'mine': true,
      'items': [
        {'title': _title, 'note': 'Second', 'position': 2},
        {
          'title': {..._title, 'id': 'title-2', 'release_year': null},
          'note': 'First',
          'position': 1,
        },
      ],
    });
    expect(list.items.map((i) => i.note), ['First', 'Second']);
    expect(list.items.first.title.releaseYear, isNull);
  });

  test('TitleDetail.fromJson allows a null my_review', () {
    final detail = TitleDetail.fromJson({
      'title': _title,
      'my_review': null,
      'reviews': const <Object>[],
    });
    expect(detail.myReview, isNull);
    expect(detail.reviews, isEmpty);
  });

  testWidgets('ClubsScreen renders clubs and filters by kind', (t) async {
    final api = _FakeApi({
      'GET /clubs': {
        'clubs': [
          _club(selection: _selection),
          {
            ..._club(id: 'club-2', role: '', selection: null),
            'kind': 'film',
            'name': 'Midnight Movies',
            'member_count': 1,
          },
        ],
        'eligible': true,
      },
    });
    await t.pumpWidget(_host(api, const ClubsScreen()));
    await t.pumpAndSettle();

    expect(api.requests.first.queryParameters, {'scope': 'mine'});
    expect(find.text('Start a club'), findsOneWidget);
    await t.scrollUntilVisible(find.text('Sunday Slow Reads'), 200);
    expect(find.text('8 members'), findsOneWidget);
    expect(find.text('Book club'), findsOneWidget);
    expect(find.text('This week'), findsOneWidget);
    expect(find.text('Piranesi'), findsOneWidget);
    await t.scrollUntilVisible(find.text('Midnight Movies'), 200);
    expect(find.text('Film club'), findsOneWidget);
    expect(find.text('1 member'), findsOneWidget);
    expect(find.text('No pick yet this week'), findsOneWidget);

    await t.drag(find.byType(Scrollable).first, const Offset(0, 3000));
    await t.pumpAndSettle();
    await t.tap(find.widgetWithText(ChoiceChip, 'Films'));
    await t.pumpAndSettle();
    expect(api.requests.last.queryParameters, {
      'scope': 'mine',
      'kind': 'film',
    });
  });

  testWidgets('ClubDetailScreen shows the pick and collapses spoilers', (
    t,
  ) async {
    final api = _FakeApi({
      'GET /clubs/club-1': {
        'club': _club(role: 'member', selection: _selection),
        'selections': [_selection],
      },
      'GET /clubs/club-1/posts': {
        'posts': [
          {
            'id': 'p-1',
            'club_id': 'club-1',
            'selection_id': 'sel-1',
            'author_id': 'u-2',
            'author_name': 'Sam',
            'body': 'The ending is a twist.',
            'has_spoilers': true,
            'created_at': '2026-09-29T09:00:00Z',
            'mine': false,
            'hidden': false,
          },
        ],
        'next_cursor': '',
      },
    });
    await t.pumpWidget(_host(api, const ClubDetailScreen(clubId: 'club-1')));
    await t.pumpAndSettle();

    expect(find.text('Sunday Slow Reads'), findsWidgets);
    expect(find.text('Leave club'), findsOneWidget);
    expect(find.text('Set this week’s pick'), findsNothing);
    await t.scrollUntilVisible(find.text('Spoiler — tap to reveal'), 200);
    final posts = api.requests.where((r) => r.path == '/clubs/club-1/posts');
    expect(posts.first.queryParameters, {'selection_id': 'sel-1'});

    await t.ensureVisible(find.text('Spoiler — tap to reveal'));
    await t.pumpAndSettle();
    await t.tap(find.text('Spoiler — tap to reveal'));
    await t.pumpAndSettle();
    expect(find.text('Spoiler — tap to reveal'), findsNothing);
    expect(find.text('The ending is a twist.'), findsOneWidget);
  });
}
