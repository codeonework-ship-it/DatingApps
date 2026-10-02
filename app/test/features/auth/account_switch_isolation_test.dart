// Regression tests for Android QA findings (2026-10-01):
//  - AND-01: after signing out and signing in as another member in the same
//    app process, the notification inbox and badge showed the previous
//    member's notifications.
//  - AND-02: the previous member's theme stayed on screen instead of the new
//    member's stored theme.
//  - AND-03: the Friends screen never refetched on open, so a friend request
//    received after the first load (or a different member's list) was not
//    shown until pull-to-refresh.
//  - Audit 2026-10-02 (P0): support tickets, moderation appeals and the other
//    global member providers only `ref.read` the auth state, so the next
//    member on a shared device saw the previous member's data. Every member
//    provider now depends on the signed-in member id (watchSignedInUserId).
//  - Audit 2026-10-02 (P1): the app language was loaded once per process,
//    so the next member kept the previous member's language.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verified_dating_app/core/i18n/app_locale_provider.dart';
import 'package:verified_dating_app/core/notifications/push_notification_service.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/core/providers/runtime_feature_flags_provider.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/calls/providers/call_provider.dart';
import 'package:verified_dating_app/features/celebrations/reward_ledger.dart';
import 'package:verified_dating_app/features/common/screens/main_navigation_screen.dart';
import 'package:verified_dating_app/features/engagement/providers/circle_challenge_provider.dart';
import 'package:verified_dating_app/features/engagement/providers/daily_prompt_provider.dart';
import 'package:verified_dating_app/features/engagement/providers/group_coffee_poll_provider.dart';
import 'package:verified_dating_app/features/engagement/providers/level_progression_provider.dart';
import 'package:verified_dating_app/features/engagement/providers/match_nudge_provider.dart';
import 'package:verified_dating_app/features/engagement/providers/moderation_appeals_provider.dart';
import 'package:verified_dating_app/features/engagement/providers/trust_badges_provider.dart';
import 'package:verified_dating_app/features/graduation/providers/graduation_provider.dart';
import 'package:verified_dating_app/features/matching/providers/activity_session_provider.dart';
import 'package:verified_dating_app/features/matching/providers/gesture_timeline_provider.dart';
import 'package:verified_dating_app/features/matching/providers/trust_filter_provider.dart';
import 'package:verified_dating_app/features/plans/providers/plans_provider.dart';
import 'package:verified_dating_app/features/safety/providers/sos_provider.dart';
import 'package:verified_dating_app/features/support/support_api.dart';
import 'package:verified_dating_app/features/common/providers/app_theme_provider.dart';
import 'package:verified_dating_app/features/friends/providers/friends_provider.dart';
import 'package:verified_dating_app/features/friends/screens/friends_screen.dart';
import 'package:verified_dating_app/features/notifications/providers/notification_provider.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

/// The member whose credential the fake server sees (token-scoped routes
/// such as `/support/tickets` carry no member id in the path).
String? _sessionMember = 'me';

class _SwitchableAuth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(isAuthenticated: true, userId: 'me');

  void signInAs(String? userId) {
    _sessionMember = userId;
    state = userId == null
        ? const AuthState()
        : AuthState(isAuthenticated: true, userId: userId);
  }
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
  final locales = {'me': 'de', 'other': 'fr'};
  final tickets = {
    'me': [
      {
        'id': 't1',
        'reference': 'SUP-1001',
        'category': 'account',
        'subject': 'My private billing question',
        'status': 'open',
      },
    ],
    'other': <Map<String, dynamic>>[],
  };
  final appeals = {
    'me': [
      {
        'id': 'apl-1',
        'user_id': 'me',
        'reason': 'My private appeal',
        'status': 'submitted',
      },
    ],
    'other': <Map<String, dynamic>>[],
  };
  final requests = <String>[];
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
          requests.add('${options.method} ${options.uri}');
          final parts = options.path.split('/');
          final user = parts.length > 2 ? parts[2] : '';
          final Object data = switch (options.path) {
            '/support/tickets' => {
              'tickets': tickets[_sessionMember] ?? const [],
            },
            '/moderation/appeals' => {
              'appeals':
                  appeals[options.queryParameters['user_id']] ?? const [],
            },
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
              'settings': {'theme': themes[user], 'locale': locales[user]},
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
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    _sessionMember = 'me';
    SharedPreferences.setMockInitialValues({});
  });

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

  test('support tickets never carry over to the next member '
      '[case:support.support_tickets.account_switch_isolation]', () async {
    final api = _Api();
    final container = _container(api)
      ..listen(supportTicketsProvider, (_, _) {});
    final mine = await container.read(supportTicketsProvider.future);
    expect(mine.tickets.single.subject, 'My private billing question');

    final auth =
        container.read(authNotifierProvider.notifier) as _SwitchableAuth
          ..signInAs(null);
    await pumpEventQueue();
    // Signed out: nothing is shown and nothing is fetched without a member.
    expect(
      container.read(supportTicketsProvider).valueOrNull?.tickets,
      isEmpty,
    );
    final supportFetches = api.requests
        .where((r) => r.contains('/support/tickets'))
        .length;
    expect(supportFetches, 1);

    auth.signInAs('other');
    final theirs = await container.read(supportTicketsProvider.future);
    expect(theirs.tickets, isEmpty);
  });

  test('moderation appeals never carry over to the next member '
      '[case:common.moderation_appeals.account_switch_isolation]', () async {
    final api = _Api();
    final container = _container(api)
      ..listen(moderationAppealsProvider, (_, _) {});
    final mine = await container.read(moderationAppealsProvider.future);
    expect(mine.single.reason, 'My private appeal');

    final auth =
        container.read(authNotifierProvider.notifier) as _SwitchableAuth
          ..signInAs(null);
    await pumpEventQueue();
    // Signed out: an empty list, not an error and not the old appeals.
    expect(container.read(moderationAppealsProvider).valueOrNull, isEmpty);

    auth.signInAs('other');
    final theirs = await container.read(moderationAppealsProvider.future);
    expect(theirs, isEmpty);
    expect(api.requests.last, contains('/moderation/appeals?user_id=other'));
  });

  test('every member-scoped provider starts afresh for the next member '
      '[case:auth.session.account_switch_isolation]', () async {
    final container = _container(_Api());
    const match = 'match-1';
    const session = (matchId: match, otherUserId: 'meera');
    final providers = <String, Object Function()>{
      'callProvider': () => container.read(callProvider.notifier),
      'sosProvider': () => container.read(sosProvider.notifier),
      'trustFilterNotifierProvider': () =>
          container.read(trustFilterNotifierProvider.notifier),
      'plansFeedProvider': () => container.read(plansFeedProvider.notifier),
      'matchPlansProvider': () =>
          container.read(matchPlansProvider(match).notifier),
      'trustBadgesProvider': () => container.read(trustBadgesProvider.notifier),
      'levelProgressionProvider': () =>
          container.read(levelProgressionProvider.notifier),
      'dailyPromptProvider': () => container.read(dailyPromptProvider.notifier),
      'circleChallengeProvider': () =>
          container.read(circleChallengeProvider.notifier),
      'groupCoffeePollProvider': () =>
          container.read(groupCoffeePollProvider.notifier),
      'matchNudgeProvider': () => container.read(matchNudgeProvider.notifier),
      'discoveryPauseProvider': () =>
          container.read(discoveryPauseProvider.notifier),
      'matchGraduationProvider': () =>
          container.read(matchGraduationProvider(match).notifier),
      'gestureTimelineProvider': () =>
          container.read(gestureTimelineProvider(match).notifier),
      'activitySessionProvider': () =>
          container.read(activitySessionProvider(session).notifier),
    };
    final before = {
      for (final entry in providers.entries) entry.key: entry.value(),
    };
    container.read(rewardSnapshotReportsProvider.notifier).state =
        const RewardSnapshot(level: 3);
    container.read(mainNavigationIndexProvider.notifier).state = 4;
    await pumpEventQueue();

    (container.read(authNotifierProvider.notifier) as _SwitchableAuth).signInAs(
      'other',
    );
    await pumpEventQueue();

    for (final entry in providers.entries) {
      expect(
        identical(entry.value(), before[entry.key]),
        isFalse,
        reason: '${entry.key} kept the previous member\'s state',
      );
    }
    expect(container.read(rewardSnapshotReportsProvider), isNull);
    // The next member's session starts on Today.
    expect(container.read(mainNavigationIndexProvider), 0);
    await pumpEventQueue();
  });

  test('the next member gets their own stored language '
      '[case:common.language_settings.account_switch_reload]', () async {
    final container = _container(_Api());
    await container.read(appLocaleProvider.notifier).ensureLoaded();
    expect(container.read(appLocaleProvider), const Locale('de'));

    final auth =
        container.read(authNotifierProvider.notifier) as _SwitchableAuth
          ..signInAs(null)
          ..signInAs('other');
    await container.read(appLocaleProvider.notifier).ensureLoaded();
    expect(container.read(appLocaleProvider), const Locale('fr'));

    // The first member signs back in: their language comes back too.
    auth.signInAs('me');
    await container.read(appLocaleProvider.notifier).ensureLoaded();
    expect(container.read(appLocaleProvider), const Locale('de'));
  });
}
