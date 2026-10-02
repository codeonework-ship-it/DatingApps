// Regression tests for Android QA findings (2026-10-01):
//  - AND-01: after signing out and signing in as another member in the same
//    app process, the notification inbox and badge showed the previous
//    member's notifications.
//  - AND-02: the previous member's theme stayed on screen instead of the new
//    member's stored theme.
//  - AND-03: the Friends screen never refetched on open, so a friend request
//    received after the first load (or a different member's list) was not
//    shown until pull-to-refresh.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/notifications/push_notification_service.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/core/providers/runtime_feature_flags_provider.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/common/providers/app_theme_provider.dart';
import 'package:verified_dating_app/features/friends/providers/friends_provider.dart';
import 'package:verified_dating_app/features/friends/screens/friends_screen.dart';
import 'package:verified_dating_app/features/notifications/providers/notification_provider.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

class _SwitchableAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(isAuthenticated: true, userId: 'me');

  void signInAs(String? userId) => state = userId == null
      ? const AuthState()
      : AuthState(isAuthenticated: true, userId: userId);
}

class _NoPush extends PushNotificationService {
  _NoPush() : super(Dio());

  @override
  Future<void> start({
    required String userId,
    required PushOpenHandler onOpened,
  }) async {}

  @override
  Future<void> unregister(String userId) async {}
}

Map<String, dynamic> _friend(String id, String name, String direction) => {
  'friend_user_id': id,
  'friend_name': name,
  'friend_username': id,
  'friend_city': '',
  'friend_photo_url': '',
  'status': direction.isEmpty ? 'accepted' : 'pending',
  'direction': direction,
  'source': 'search',
  'created_at': '2026-10-01T00:00:00Z',
  'updated_at': '2026-10-01T00:00:00Z',
};

/// Per-member BFF: every response depends on the member in the path.
class _Api {
  final friends = <String, List<Map<String, dynamic>>>{
    'me': [_friend('meera', 'Meera', '')],
    'other': [],
  };
  final themes = {'me': 'dark:rose', 'other': 'auto'};
  final notifications = {
    'me': [
      {
        'id': 'n1',
        'sequence': 1,
        'event_type': 'social.message.new',
        'title': 'New message from Meera',
        'body': 'Private words for me only',
      },
    ],
    'other': <Map<String, dynamic>>[],
  };

  Dio build() {
    final dio = Dio(BaseOptions(baseUrl: 'http://bff.test/v1'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final parts = options.path.split('/');
          final user = parts.length > 2 ? parts[2] : '';
          final Object data = switch (options.path) {
            final p when p == '/notifications/$user' => {
              'notifications': notifications[user] ?? const [],
            },
            final p when p == '/notifications/$user/unread-count' => {
              'unread_count': (notifications[user] ?? const []).length,
            },
            final p when p == '/notifications/$user/preferences' => {
              'preferences': <String, dynamic>{},
            },
            final p when p == '/settings/$user' => {
              'settings': {'theme': themes[user]},
            },
            final p when p == '/friends/$user' => {
              'friends': friends[user] ?? const [],
            },
            final p when p == '/friends/$user/activities' => {
              'activities': <dynamic>[],
            },
            final p when p == '/friends/$user/vouches' => {
              'about_me': <dynamic>[],
              'written': <dynamic>[],
            },
            final p when p == '/friends/$user/intros' => {
              'received': <dynamic>[],
              'made': <dynamic>[],
            },
            '/social/channels' => {'channels': <dynamic>[]},
            _ => <String, dynamic>{},
          };
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

ProviderContainer _container(_Api api) {
  final container = ProviderContainer(
    overrides: [
      authNotifierProvider.overrideWith(_SwitchableAuth.new),
      apiClientProvider.overrideWithValue(api.build()),
      pushNotificationServiceProvider.overrideWithValue(_NoPush()),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('notifications never carry over to the next member (AND-01)', () async {
    final container = _container(_Api())
      ..listen(notificationProvider, (_, _) {});
    await pumpEventQueue();
    expect(container.read(notificationProvider).unreadCount, 1);
    expect(
      container.read(notificationProvider).items.single.body,
      'Private words for me only',
    );

    final auth =
        container.read(authNotifierProvider.notifier) as _SwitchableAuth
          ..signInAs(null);
    await pumpEventQueue();
    expect(container.read(notificationProvider).items, isEmpty);

    auth.signInAs('other');
    await pumpEventQueue();
    expect(container.read(notificationProvider).items, isEmpty);
    expect(container.read(notificationProvider).unreadCount, 0);
  });

  test('the next member gets their own stored theme (AND-02)', () async {
    final container = _container(_Api());
    final theme = container.read(appThemeProvider.notifier);
    await theme.ensureLoaded();
    expect(container.read(appThemeProvider).presetId, 'rose');

    (container.read(authNotifierProvider.notifier) as _SwitchableAuth).signInAs(
      'other',
    );
    await container.read(appThemeProvider.notifier).ensureLoaded();
    expect(container.read(appThemeProvider).presetId, 'classic');
    expect(container.read(appThemeProvider).wireValue, 'auto');
  });

  test('friends never carry over to the next member', () async {
    final container = _container(_Api())..listen(friendsProvider, (_, _) {});
    await pumpEventQueue();
    expect(container.read(friendsProvider).accepted, hasLength(1));

    (container.read(authNotifierProvider.notifier) as _SwitchableAuth).signInAs(
      'other',
    );
    await pumpEventQueue();
    expect(container.read(friendsProvider).friends, isEmpty);
  });

  testWidgets('opening Friends fetches requests received since the last '
      'load (AND-03)', (tester) async {
    final api = _Api();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(_SwitchableAuth.new),
          apiClientProvider.overrideWithValue(api.build()),
          pushNotificationServiceProvider.overrideWithValue(_NoPush()),
          runtimeFeatureFlagsProvider.overrideWith(
            (ref) => Stream.value(RuntimeFeatureFlags.defaults),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Consumer(
            builder: (context, ref, _) {
              // Something else (an Add friend button) loaded the list first.
              ref.watch(friendsProvider);
              return Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const FriendsScreen(),
                    ),
                  ),
                  child: const Text('Open friends'),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // A request arrives on the server after that first load.
    api.friends['me']!.add(_friend('ravi', 'Ravi', 'incoming'));

    await tester.tap(find.text('Open friends'));
    await tester.pumpAndSettle();

    expect(find.text('Waiting on you'), findsOneWidget);
    expect(find.text('Ravi'), findsOneWidget);
  });
}
