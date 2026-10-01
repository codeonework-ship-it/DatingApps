import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/core/providers/runtime_feature_flags_provider.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/matching/providers/match_provider.dart';
import 'package:verified_dating_app/features/matching/screens/matches_list_screen.dart';

class _Auth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(isAuthenticated: true, userId: 'me');
}

class _Matches extends MatchNotifier {
  @override
  MatchState build() => MatchState(
    matches: [
      Match(
        id: 'match-maya',
        userId: 'maya',
        userName: 'Maya',
        userPhoto: '',
        lastMessage: 'Hello there',
        lastMessageTime: DateTime(2026, 9, 30),
        unreadCount: 0,
        isOnline: false,
      ),
    ],
  );
}

/// Friends BFF for the match sheet: no friends yet, then Maya as an
/// outgoing request once one is sent.
class _Api {
  final posts = <({String path, Object? body})>[];
  bool requested = false;

  Dio build() {
    final dio = Dio(BaseOptions(baseUrl: 'http://bff.test/v1'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          Object data = <String, dynamic>{};
          if (options.method == 'POST') {
            posts.add((path: options.path, body: options.data));
            if (options.path == '/friends/me') {
              requested = true;
            }
          }
          if (options.method == 'GET' && options.path == '/friends/me') {
            data = {
              'friends': [
                if (requested)
                  {
                    'friend_user_id': 'maya',
                    'friend_name': 'Maya',
                    'status': 'pending',
                    'direction': 'outgoing',
                    'source': 'match',
                    'updated_at': '2026-09-30T00:00:00Z',
                  },
              ],
            };
          }
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: data,
            ),
          );
        },
      ),
    );
    return dio;
  }
}

void main() {
  testWidgets('the match options sheet sends a friend request from match', (
    tester,
  ) async {
    final api = _Api();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(_Auth.new),
          matchNotifierProvider.overrideWith(_Matches.new),
          matchesViewProvider.overrideWith((ref) => MatchesView.people),
          apiClientProvider.overrideWithValue(api.build()),
          runtimeFeatureFlagsProvider.overrideWith(
            (_) => Stream.value(
              const RuntimeFeatureFlags({
                'date_plans_enabled': false,
                'graduation_enabled': false,
              }),
            ),
          ),
        ],
        child: const MaterialApp(home: MatchesListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Match options for Maya'));
    await tester.pumpAndSettle();
    final tile = find.byKey(const ValueKey('qa.add_friend.maya'));
    expect(tile, findsOneWidget);
    expect(
      find.descendant(of: tile, matching: find.text('Add friend')),
      findsOneWidget,
    );

    await tester.tap(tile);
    await tester.pumpAndSettle();
    final sent = api.posts.singleWhere((p) => p.path == '/friends/me');
    expect(sent.body, {'friend_user_id': 'maya', 'source': 'match'});
    // The sheet stays open and the tile now reflects the request.
    expect(
      find.descendant(of: tile, matching: find.text('Requested')),
      findsOneWidget,
    );
  });
}
