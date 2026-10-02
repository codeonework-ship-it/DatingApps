import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/core/providers/runtime_feature_flags_provider.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/friends/models/friend_social.dart';
import 'package:verified_dating_app/features/friends/screens/friends_screen.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

class _Auth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(isAuthenticated: true, userId: 'me');
}

/// In-memory BFF for the friends screen: friends list, one incoming intro
/// and one pending vouch; records every command.
class _FakeFriendsApi {
  final List<({String method, String path, Map<String, dynamic> body})>
  commands = [];
  String introDecision = 'pending';
  String vouchStatus = 'pending';

  Dio build() {
    final dio = Dio(BaseOptions(baseUrl: 'http://bff.test/v1'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          Map<String, dynamic>? data;
          if (options.method == 'GET') {
            if (options.path == '/friends/me') {
              data = {
                'friends': [
                  {
                    'friend_user_id': 'meera',
                    'friend_name': 'Meera',
                    'status': 'accepted',
                    'direction': '',
                    'updated_at': '2026-09-27T00:00:00Z',
                  },
                  {
                    'friend_user_id': 'dev',
                    'friend_name': 'Dev',
                    'status': 'accepted',
                    'direction': '',
                    'updated_at': '2026-09-27T00:00:00Z',
                  },
                ],
              };
            } else if (options.path == '/friends/me/activities') {
              data = {'activities': <dynamic>[]};
            } else if (options.path == '/friends/me/vouches') {
              data = {
                'about_me': [
                  {
                    'id': 'vouch-1',
                    'subject_user_id': 'me',
                    'subject_name': 'Me',
                    'voucher_user_id': 'meera',
                    'voucher_name': 'Meera',
                    'text': 'Warm, curious and always the first to show up.',
                    'status': vouchStatus,
                    'created_at': '2026-09-27T00:00:00Z',
                  },
                ],
                'written': <dynamic>[],
              };
            } else if (options.path == '/friends/me/intros') {
              data = {
                'received': [
                  {
                    'id': 'intro-1',
                    'introducer_user_id': 'meera',
                    'introducer_name': 'Meera',
                    'message': 'You two would get on.',
                    'status': introDecision == 'accepted' ? 'open' : 'open',
                    'my_decision': introDecision,
                    'other': {
                      'user_id': 'arjun',
                      'name': 'Arjun',
                      'age': 31,
                      'city': 'Pune',
                      'is_verified': true,
                      'photo_urls': <String>[],
                    },
                    'expires_at': '2026-10-11T00:00:00Z',
                    'created_at': '2026-09-27T00:00:00Z',
                  },
                ],
                'made': <dynamic>[],
              };
            }
          } else {
            final body = options.data is Map
                ? (options.data as Map).cast<String, dynamic>()
                : <String, dynamic>{};
            commands.add((
              method: options.method,
              path: options.path,
              body: body,
            ));
            if (options.path.endsWith('/intros/intro-1/decision')) {
              introDecision = body['decision'] == 'accept'
                  ? 'accepted'
                  : 'declined';
            }
            if (options.path.endsWith('/vouches/vouch-1/decision')) {
              vouchStatus = body['decision'] == 'approve'
                  ? 'approved'
                  : 'hidden';
            }
            data = {'success': true};
          }
          if (data == null) {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response<dynamic>(
                  requestOptions: options,
                  statusCode: 404,
                  data: {
                    'error': 'unexpected ${options.method} ${options.path}',
                  },
                ),
              ),
            );
            return;
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

Widget _host(_FakeFriendsApi api) => ProviderScope(
  overrides: [
    authNotifierProvider.overrideWith(_Auth.new),
    apiClientProvider.overrideWithValue(api.build()),
    runtimeFeatureFlagsProvider.overrideWith(
      (ref) => Stream.value(RuntimeFeatureFlags.defaults),
    ),
  ],
  child: const MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: FriendsScreen(),
  ),
);

void main() {
  testWidgets('an incoming intro shows the other person and can be accepted', (
    tester,
  ) async {
    final api = _FakeFriendsApi();
    await tester.pumpWidget(_host(api));
    await tester.pumpAndSettle();

    expect(find.text('Intros for you'), findsOneWidget);
    expect(
      find.textContaining('Meera thinks you should meet Arjun, 31'),
      findsOneWidget,
    );
    expect(find.text('“You two would get on.”'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('qa.friends.intro_accept.intro-1')),
      250,
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('qa.friends.intro_accept.intro-1')),
    );
    await tester.pumpAndSettle();

    final decision = api.commands.firstWhere(
      (c) => c.path.endsWith('/intros/intro-1/decision'),
    );
    expect(decision.body['decision'], 'accept');
    // Once answered, the intro leaves the "for you" list.
    expect(find.text('Intros for you'), findsNothing);
  });

  testWidgets('a pending vouch can be approved for the profile', (
    tester,
  ) async {
    final api = _FakeFriendsApi();
    await tester.pumpWidget(_host(api));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Vouches waiting for your approval'),
      250,
    );
    await tester.pumpAndSettle();
    expect(find.text('Vouches waiting for your approval'), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const ValueKey('qa.friends.vouch_approve.vouch-1')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('qa.friends.vouch_approve.vouch-1')),
    );
    await tester.pumpAndSettle();

    final decision = api.commands.firstWhere(
      (c) => c.path.endsWith('/vouches/vouch-1/decision'),
    );
    expect(decision.body['decision'], 'approve');
    await tester.scrollUntilVisible(
      find.text('Vouches on your profile'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Vouches on your profile'), findsOneWidget);
    expect(find.text('Meera vouched for you'), findsOneWidget);
  });

  testWidgets('the intro sheet needs two different friends', (tester) async {
    final api = _FakeFriendsApi();
    await tester.pumpWidget(_host(api));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('qa.friends.intro_action')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await Scrollable.ensureVisible(
      tester.element(find.byKey(const ValueKey('qa.friends.intro_action'))),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('qa.friends.intro_action')));
    await tester.pumpAndSettle();
    expect(find.text('Introduce two friends'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('qa.friends.intro_first.meera')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('qa.friends.intro_second.dev')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('qa.friends.intro_submit')));
    await tester.pumpAndSettle();

    final made = api.commands.firstWhere((c) => c.path == '/friends/me/intros');
    expect(made.body['first_user_id'], 'meera');
    expect(made.body['second_user_id'], 'dev');
  });

  test('models parse the BFF payloads', () {
    final intro = FriendIntro.fromJson({
      'id': 'i',
      'introducer_user_id': 'x',
      'introducer_name': 'Meera',
      'status': 'open',
      'my_decision': 'pending',
      'other': {'user_id': 'y', 'name': 'Arjun', 'age': 31},
      'expires_at': '2026-10-11T00:00:00Z',
      'created_at': '2026-09-27T00:00:00Z',
    });
    expect(intro.awaitingMe, isTrue);
    expect(intro.other?.age, 31);
    final vouch = FriendVouch.fromJson({
      'id': 'v',
      'subject_user_id': 'me',
      'voucher_user_id': 'x',
      'voucher_name': 'Meera',
      'text': 't',
      'status': 'approved',
      'created_at': '',
    });
    expect(vouch.isApproved, isTrue);
  });
}
