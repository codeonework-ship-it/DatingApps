import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/core/providers/runtime_feature_flags_provider.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/common/screens/privacy_safety_screen.dart';
import 'package:verified_dating_app/features/friends/screens/friends_screen.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

class _Auth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(isAuthenticated: true, userId: 'me');
}

/// "Let people find me in friend search": GET/PUT
/// /friends/me/search-visibility, plus the privacy settings the screen loads.
class _Api {
  _Api({this.visible = true});
  bool visible;
  bool reject = false;
  final puts = <Object?>[];

  Dio build() {
    final dio = Dio(BaseOptions(baseUrl: 'https://test.invalid'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final path = options.path;
          if (path == '/friends/me/search-visibility') {
            if (options.method == 'PUT') {
              puts.add(options.data);
              if (reject) {
                handler.reject(
                  DioException(
                    requestOptions: options,
                    response: Response<dynamic>(
                      requestOptions: options,
                      statusCode: 503,
                      data: {'error': 'Friends are temporarily unavailable.'},
                    ),
                  ),
                );
                return;
              }
              visible = (options.data as Map)['visible'] as bool;
            }
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: {'visible': visible},
              ),
            );
            return;
          }
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: path.startsWith('/settings/')
                  ? {
                      'settings': {
                        'show_age': true,
                        'show_exact_distance': false,
                        'show_online_status': true,
                      },
                    }
                  : path == '/friends/me/search'
                  ? {'results': <Object>[]}
                  : <String, Object?>{},
            ),
          );
        },
      ),
    );
    return dio;
  }
}

Widget _app(_Api api, Widget home) => ProviderScope(
  overrides: [
    authNotifierProvider.overrideWith(_Auth.new),
    apiClientProvider.overrideWithValue(api.build()),
    runtimeFeatureFlagsProvider.overrideWith(
      (ref) => Stream.value(RuntimeFeatureFlags.defaults),
    ),
  ],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  ),
);

void main() {
  final tile = find.byKey(const ValueKey('qa.privacy.friend_search'));

  testWidgets('privacy switch turns friend search off and back on', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final api = _Api();
    await tester.pumpWidget(_app(api, const PrivacySafetyScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Let people find me in friend search'), findsOneWidget);
    expect(tester.widget<SwitchListTile>(tile).value, isTrue);
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(api.puts.last, {'visible': false});
    expect(tester.widget<SwitchListTile>(tile).value, isFalse);
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(api.puts.last, {'visible': true});
    expect(tester.widget<SwitchListTile>(tile).value, isTrue);
  });

  testWidgets('a failed save puts the switch back and explains', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final api = _Api()..reject = true;
    await tester.pumpWidget(_app(api, const PrivacySafetyScreen()));
    await tester.pumpAndSettle();
    await tester.tap(tile);
    await tester.pumpAndSettle();
    expect(tester.widget<SwitchListTile>(tile).value, isTrue);
    expect(find.text('Friends are temporarily unavailable.'), findsOneWidget);
  });

  testWidgets('the Add friend sheet tells a hidden member they are hidden', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final hidden in [true, false]) {
      final api = _Api(visible: !hidden);
      await tester.pumpWidget(
        _app(
          api,
          Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showAddFriendSheet(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('qa.friends.search_hidden_note')),
        hidden ? findsOneWidget : findsNothing,
      );
      // Searching still works for a hidden member.
      expect(
        find.byKey(const ValueKey('qa.friends.search_field')),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
    }
  });
}
