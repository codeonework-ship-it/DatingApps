import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/permissions/device_permission_service.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/calls/providers/call_provider.dart';
import 'package:verified_dating_app/features/engagement/providers/match_nudge_provider.dart';
import 'package:verified_dating_app/features/payment/providers/subscription_provider.dart';
import 'package:verified_dating_app/features/safety/providers/sos_provider.dart';

class _AuthenticatedUser extends AuthNotifier {
  @override
  AuthState build() => const AuthState(
    isAuthenticated: true,
    userId: 'user-a',
    username: 'user_a',
  );
}

class _GrantedPermissions extends DevicePermissionService {
  const _GrantedPermissions();

  @override
  Future<bool> requestCallPermissions() async => true;

  @override
  Future<SosCoordinates?> currentSosCoordinates() async =>
      const SosCoordinates(latitude: 12.97, longitude: 77.59);
}

class _DeniedPermissions extends DevicePermissionService {
  const _DeniedPermissions();

  @override
  Future<bool> requestCallPermissions() async => false;

  @override
  Future<SosCoordinates?> currentSosCoordinates() async => null;
}

class _JourneyApiHarness {
  _JourneyApiHarness({this.rejectNudge = false});

  final bool rejectNudge;
  Map<String, dynamic>? lastCallStart;
  Map<String, dynamic>? lastSos;
  Map<String, dynamic>? lastNudge;
  Map<String, dynamic>? lastCheckout;
  String? checkoutIdempotencyKey;
  int checkoutPolls = 0;

  Dio build() {
    final dio = Dio(BaseOptions(baseUrl: 'https://test.invalid'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final body =
              (options.data as Map?)?.cast<String, dynamic>() ?? const {};
          Object response;
          switch ('${options.method} ${options.path}') {
            case 'POST /calls/start':
              lastCallStart = body;
              response = {
                'session': {
                  'id': 'call-1',
                  'match_id': 'match-1',
                  'initiator_id': 'user-a',
                  'recipient_id': 'user-b',
                  'status': 'active',
                  'room_id': 'room-1',
                  'started_at': '2026-08-09T10:00:00Z',
                },
              };
            case 'POST /calls/call-1/end':
              response = {
                'session': {
                  'id': 'call-1',
                  'match_id': 'match-1',
                  'initiator_id': 'user-a',
                  'recipient_id': 'user-b',
                  'status': 'ended',
                  'room_id': 'room-1',
                  'started_at': '2026-08-09T10:00:00Z',
                  'ended_at': '2026-08-09T10:01:00Z',
                  'duration_sec': 60,
                },
              };
            case 'POST /safety/sos':
              lastSos = body;
              response = {
                'alert': {
                  'id': 'sos-1',
                  'user_id': 'user-a',
                  'emergency_level': body['emergency_level'],
                  'message': 'Help',
                  'latitude': body['latitude'],
                  'longitude': body['longitude'],
                  'status': 'active',
                  'triggered_at': '2026-08-09T10:00:00Z',
                },
              };
            case 'POST /engagement/match-nudges/send':
              lastNudge = body;
              if (rejectNudge) {
                handler.reject(
                  DioException(
                    requestOptions: options,
                    response: Response<dynamic>(
                      requestOptions: options,
                      statusCode: 429,
                      data: const {'error': 'daily nudge cap reached'},
                    ),
                  ),
                );
                return;
              }
              response = {
                'nudge': {
                  'id': 'nudge-1',
                  ...body,
                  'created_at': '2026-08-09T10:00:00Z',
                },
              };
            case 'GET /billing/plans':
              response = {
                'plans': [
                  {
                    'id': 'plan-1',
                    'name': 'Plus',
                    'monthly_price': 499,
                    'yearly_price': 4999,
                    'likes_per_day': 50,
                    'messages_per_day': 100,
                    'features': ['Priority likes'],
                    'is_active': true,
                  },
                ],
              };
            case 'GET /billing/account':
              response = {
                'account': {
                  'user_id': 'user-a',
                  'name': 'Member A',
                  'email': 'a@example.test',
                  'mode': 'sandbox',
                  'payment_methods': ['card'],
                },
              };
            case 'GET /billing/subscription/user-a':
              response = {'subscription': null};
            case 'GET /billing/payments/user-a':
              response = {'payments': <Object>[]};
            case 'POST /billing/checkout':
              lastCheckout = body;
              checkoutIdempotencyKey = options.headers['Idempotency-Key']
                  ?.toString();
              response = {
                'success': true,
                'checkout': {
                  'id': 'checkout-1',
                  'user_id': 'user-a',
                  'plan_code': 'plan-1',
                  'billing_cycle': body['billing_cycle'],
                  'provider': 'sandbox',
                  'status': 'open',
                  'amount_minor': 49900,
                  'currency': 'INR',
                  'checkout_url':
                      'https://pay.test/v1/billing/sandbox/checkout/cs_1',
                  'created_at': '2026-08-09T10:00:00Z',
                },
                'return_url': 'https://pay.test/v1/billing/checkout/return',
              };
            case 'GET /billing/checkout/checkout-1':
              checkoutPolls++;
              response = {
                'checkout': {
                  'id': 'checkout-1',
                  'status': checkoutPolls >= 2 ? 'completed' : 'open',
                },
                if (checkoutPolls >= 2)
                  'subscription': {
                    'id': 'subscription-1',
                    'user_id': 'user-a',
                    'plan_id': 'plan-1',
                    'plan_name': 'Plus',
                    'status': 'active',
                    'billing_cycle': 'monthly',
                    'start_date': '2026-08-09T10:00:00Z',
                    'provider': 'sandbox',
                    'is_paid': true,
                    'entitled': true,
                    'auto_renew': true,
                    'card_brand': 'visa',
                    'card_last4': '4242',
                  },
              };
            case 'POST /billing/subscription/user-a/cancel':
              response = {
                'success': true,
                'subscription': {
                  'id': 'subscription-1',
                  'user_id': 'user-a',
                  'plan_id': 'plan-1',
                  'plan_name': 'Plus',
                  'status': 'active',
                  'billing_cycle': 'monthly',
                  'start_date': '2026-08-09T10:00:00Z',
                  'is_paid': true,
                  'auto_renew': false,
                  'cancel_at_period_end': true,
                },
              };
            default:
              handler.reject(
                DioException(
                  requestOptions: options,
                  error: 'Unexpected request ${options.method} ${options.path}',
                ),
              );
              return;
          }
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: response,
            ),
          );
        },
      ),
    );
    return dio;
  }
}

ProviderContainer _container(_JourneyApiHarness harness) => ProviderContainer(
  overrides: [
    authNotifierProvider.overrideWith(_AuthenticatedUser.new),
    apiClientProvider.overrideWithValue(harness.build()),
    devicePermissionServiceProvider.overrideWithValue(
      const _GrantedPermissions(),
    ),
  ],
);

ProviderContainer _containerWithDeniedPermissions(_JourneyApiHarness harness) =>
    ProviderContainer(
      overrides: [
        authNotifierProvider.overrideWith(_AuthenticatedUser.new),
        apiClientProvider.overrideWithValue(harness.build()),
        devicePermissionServiceProvider.overrideWithValue(
          const _DeniedPermissions(),
        ),
      ],
    );

void main() {
  test(
    'call start/end uses authenticated actor and persists returned state',
    () async {
      final harness = _JourneyApiHarness();
      final container = _container(harness);
      addTearDown(container.dispose);

      final session = await container
          .read(callProvider.notifier)
          .startCall(matchId: 'match-1', recipientUserId: 'user-b');
      expect(session?.id, 'call-1');
      expect(harness.lastCallStart?['initiator_user_id'], 'user-a');
      expect(await container.read(callProvider.notifier).endCall(), isTrue);
      expect(container.read(callProvider).activeSession, isNull);
      expect(container.read(callProvider).history.single.durationSeconds, 60);
    },
  );

  test('SOS includes device location and adds the alert to history', () async {
    final harness = _JourneyApiHarness();
    final container = _container(harness);
    addTearDown(container.dispose);

    final alert = await container
        .read(sosProvider.notifier)
        .activate(emergencyLevel: 'high', message: 'Help');
    expect(alert?.id, 'sos-1');
    expect(harness.lastSos?['user_id'], 'user-a');
    expect(harness.lastSos?['latitude'], 12.97);
    expect(container.read(sosProvider).lastAlertIncludedLocation, isTrue);
  });

  test('call start stops before the API when permissions are denied', () async {
    final harness = _JourneyApiHarness();
    final container = _containerWithDeniedPermissions(harness);
    addTearDown(container.dispose);

    final session = await container
        .read(callProvider.notifier)
        .startCall(matchId: 'match-1', recipientUserId: 'user-b');
    expect(session, isNull);
    expect(harness.lastCallStart, isNull);
    expect(container.read(callProvider).permissionDenied, isTrue);
  });

  test('SOS continues without coordinates when location is denied', () async {
    final harness = _JourneyApiHarness();
    final container = _containerWithDeniedPermissions(harness);
    addTearDown(container.dispose);

    expect(
      await container
          .read(sosProvider.notifier)
          .activate(emergencyLevel: 'high', message: 'Help'),
      isNotNull,
    );
    expect(harness.lastSos?['latitude'], 0);
    expect(container.read(sosProvider).lastAlertIncludedLocation, isFalse);
  });

  test('match nudge sends server-supported payload', () async {
    final harness = _JourneyApiHarness();
    final container = _container(harness);
    addTearDown(container.dispose);

    final nudge = await container
        .read(matchNudgeProvider.notifier)
        .send(matchId: 'match-1', counterpartyUserId: 'user-b');
    expect(nudge?.id, 'nudge-1');
    expect(harness.lastNudge?['user_id'], 'user-a');
    expect(harness.lastNudge?['nudge_type'], 'stalled_24h');
  });

  test('match nudge exposes the server daily-cap failure', () async {
    final harness = _JourneyApiHarness(rejectNudge: true);
    final container = _container(harness);
    addTearDown(container.dispose);

    final nudge = await container
        .read(matchNudgeProvider.notifier)
        .send(matchId: 'match-1', counterpartyUserId: 'user-b');
    expect(nudge, isNull);
    expect(
      container.read(matchNudgeProvider).errorByMatchId['match-1'],
      'daily nudge cap reached',
    );
  });

  test(
    'subscription checkout is idempotent and settles through polling',
    () async {
      final harness = _JourneyApiHarness();
      final container = _container(harness);
      addTearDown(container.dispose);

      final notifier = container.read(subscriptionProvider.notifier);
      await notifier.load();
      final plan = container.read(subscriptionProvider).plans.single;
      expect(container.read(subscriptionProvider).subscription, isNull);

      final checkout = await notifier.startCheckout(
        plan: plan,
        billingCycle: 'monthly',
      );
      expect(checkout, isNotNull);
      expect(checkout!.checkoutUrl, contains('/billing/sandbox/checkout/'));
      expect(
        checkout.isReturnUrl(
          'https://pay.test/v1/billing/checkout/return?checkout_id=checkout-1&status=success',
        ),
        isTrue,
      );
      expect(
        checkout.isReturnUrl(
          'https://pay.test/v1/billing/sandbox/checkout/cs_1',
        ),
        isFalse,
      );
      expect(harness.lastCheckout?['plan_id'], 'plan-1');
      expect(harness.lastCheckout?.containsKey('user_id'), isFalse);
      expect(harness.checkoutIdempotencyKey, startsWith('checkout-'));
      // Starting a checkout never activates anything locally.
      expect(container.read(subscriptionProvider).subscription, isNull);
      expect(container.read(subscriptionProvider).checkoutPlanId, 'plan-1');

      final outcome = await notifier.awaitCheckout(
        checkout,
        interval: Duration.zero,
      );
      expect(outcome, CheckoutOutcome.completed);
      expect(harness.checkoutPolls, greaterThanOrEqualTo(2));
      expect(container.read(subscriptionProvider).checkoutPlanId, isNull);

      expect(await notifier.setAutoRenew(enabled: false), isTrue);
      final subscription = container.read(subscriptionProvider).subscription;
      expect(subscription?.autoRenew, isFalse);
      expect(subscription?.cancelAtPeriodEnd, isTrue);
    },
  );
}
