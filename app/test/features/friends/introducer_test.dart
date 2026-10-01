import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/auth/auth_session_store.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/auth/screens/signup_screen.dart';
import 'package:verified_dating_app/features/friends/screens/introducer_screen.dart';

class _Auth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(
    isAuthenticated: true,
    userId: 'friend',
    accountKind: 'introducer',
  );
}

class _Api {
  final requests = <RequestOptions>[];
  bool fail = false;
  String status = 'pending';
  bool pairReady = false;
  Dio client() {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (o, h) {
          requests.add(o);
          if (fail) {
            h.reject(DioException(requestOptions: o, error: 'offline'));
            return;
          }
          Object data = {'success': true};
          if (o.path == '/introducer/connections')
            data = {
              'connections': [
                {
                  'id': 'permission',
                  'user_id': 'alice',
                  'name': 'Alice',
                  'status': pairReady ? 'active' : status,
                  'share_photo': false,
                  'share_city': false,
                },
                if (pairReady)
                  {
                    'id': 'permission-bob',
                    'user_id': 'bob',
                    'name': 'Bob',
                    'status': 'active',
                    'share_photo': false,
                    'share_city': false,
                  },
              ],
            };
          if (o.path == '/friends/friend/intros')
            data = {'made': [], 'received': []};
          if (o.path == '/introducer/invites')
            data = {
              'code': 'private-one-use-invitation',
              'expires_at': '2026-10-01T00:00:00Z',
            };
          if (o.path.endsWith('/approve')) status = 'active';
          h.resolve(
            Response<dynamic>(requestOptions: o, statusCode: 200, data: data),
          );
        },
      ),
    );
    return dio;
  }
}

Future<void> _show(
  WidgetTester tester,
  _Api api, {
  bool member = false,
  double width = 390,
  double scale = 1,
}) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(_Auth.new),
        apiClientProvider.overrideWithValue(api.client()),
      ],
      child: MaterialApp(
        theme: ThemeData(useMaterial3: true),
        builder: (_, child) => MediaQuery(
          data: MediaQueryData(
            size: Size(width, 844),
            textScaler: TextScaler.linear(scale),
          ),
          child: child!,
        ),
        home: IntroducerScreen(memberControls: member),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(AuthSessionStore.instance.clear);
  tearDown(AuthSessionStore.instance.clear);
  test(
    'friend signup sends account purpose, skips profile bootstrap, restores server kind',
    () async {
      final requests = <RequestOptions>[];
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (o, h) {
              requests.add(o);
              h.resolve(
                Response<dynamic>(
                  requestOptions: o,
                  statusCode: 200,
                  data: {
                    'success': true,
                    'user_id': 'friend',
                    'account_kind': 'introducer',
                    'access_token': 'a',
                    'refresh_token': 'r',
                  },
                ),
              );
            },
          ),
        );
      final c = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(dio)],
      );
      addTearDown(c.dispose);
      await c
          .read(authNotifierProvider.notifier)
          .signUp(
            signup: const SignupDraft(
              username: 'sam_friend',
              name: 'Sam Friend',
              dateOfBirth: '1990-01-01',
              gender: '',
              accountKind: 'introducer',
            ),
            password: 'Password123!',
          );
      expect(requests.map((r) => r.path), ['/auth/signup']);
      expect((requests.single.data as Map)['account_kind'], 'introducer');
      expect((requests.single.data as Map).containsKey('gender'), isFalse);
      expect(c.read(authNotifierProvider).isIntroducer, isTrue);
      expect(
        c.read(authNotifierProvider).copyWith(error: 'retry').isIntroducer,
        isTrue,
      );
      expect(AuthSessionStore.instance.accountKind, 'introducer');
      AuthSessionStore.instance.restored = true;
      final restored = ProviderContainer();
      addTearDown(restored.dispose);
      expect(restored.read(authNotifierProvider).isIntroducer, isTrue);
    },
  );
  testWidgets('friend workspace only fetches consent and private receipts', (
    tester,
  ) async {
    final api = _Api();
    await _show(tester, api);
    expect(api.requests.map((r) => r.path).toSet(), {
      '/introducer/connections',
      '/friends/friend/intros',
    });
    await tester.scrollUntilVisible(
      find.text('Waiting for your friend’s approval.'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Suggest an introduction'), findsNothing);
    expect(find.text('Discover'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('member can approve a named request with explicit disclosure', (
    tester,
  ) async {
    final api = _Api();
    await _show(tester, api, member: true);
    await tester.scrollUntilVisible(
      find.text('Allow introductions'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Allow introductions'));
    await tester.pumpAndSettle();
    expect(
      api.requests.where((r) => r.method == 'POST').single.path,
      '/introducer/connections/permission/approve',
    );
    expect(api.status, 'active');
    expect(tester.takeException(), isNull);
  });
  testWidgets('invitation preview defaults to no photo and no city', (
    tester,
  ) async {
    final api = _Api();
    await _show(tester, api, member: true);
    await tester.scrollUntilVisible(
      find.text('Create invitation code'),
      350,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create invitation code'));
    await tester.pumpAndSettle();
    final request = api.requests.firstWhere(
      (r) => r.path == '/introducer/invites' && r.method == 'POST',
    );
    expect(request.data, {'share_photo': false, 'share_city': false});
    await tester.scrollUntilVisible(
      find.text('Copy code'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('private-one-use-invitation'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('offline consent load gives retry and no composer', (
    tester,
  ) async {
    final api = _Api()..fail = true;
    await _show(tester, api);
    await tester.scrollUntilVisible(
      find.text('Try again'),
      350,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Suggest an introduction'), findsNothing);
    expect(find.text('Try again'), findsOneWidget);
  });
  for (final width in [360.0, 1280.0]) {
    testWidgets('friend consent layout at $width with large text', (
      tester,
    ) async {
      await _show(tester, _Api(), member: true, width: width, scale: 1.7);
      await tester.scrollUntilVisible(
        find.text('Allow introductions'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'two consenting friends can be introduced with an optional note',
    (tester) async {
      final api = _Api()..pairReady = true;
      await _show(tester, api);
      await tester.scrollUntilVisible(
        find.text('First friend'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('First friend'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alice').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Second friend'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bob').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField).last,
        '  You both love books.  ',
      );
      await tester.scrollUntilVisible(
        find.text('Suggest an introduction'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Suggest an introduction'));
      await tester.pumpAndSettle();
      final sent = api.requests.singleWhere(
        (r) => r.method == 'POST' && r.path == '/friends/friend/intros',
      );
      expect(sent.data, {
        'first_user_id': 'alice',
        'second_user_id': 'bob',
        'message': 'You both love books.',
      });
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('removing permission requires the clear in-app choice', (
    tester,
  ) async {
    final api = _Api()..status = 'active';
    await _show(tester, api);
    await tester.scrollUntilVisible(
      find.text('Remove permission'),
      350,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove permission'));
    await tester.pumpAndSettle();
    expect(find.text('Remove permission for Alice?'), findsOneWidget);
    expect(api.requests.where((r) => r.method == 'DELETE'), isEmpty);
    await tester.tap(find.widgetWithText(FilledButton, 'Remove permission'));
    await tester.pumpAndSettle();
    expect(
      api.requests.singleWhere((r) => r.method == 'DELETE').path,
      '/introducer/connections/permission',
    );
  });

  testWidgets('introducer onboarding does not ask for gender', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: SignupScreen(introducer: true)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('I identify as'), findsNothing);
    expect(
      find.text('Be the friend who brings people together.'),
      findsOneWidget,
    );
  });
}
