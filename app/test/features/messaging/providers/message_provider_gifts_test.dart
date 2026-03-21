import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/messaging/models/rose_gift.dart';
import 'package:verified_dating_app/features/messaging/providers/message_provider.dart';

class _TestAuthNotifier extends AuthNotifier {
  @override
  AuthState build() =>
      const AuthState(isAuthenticated: true, userId: 'gift-test-user');
}

enum _GiftSendMode { success, insufficientCoins, chatLocked }

class _GiftApiHarness {
  _GiftApiHarness({
    required this.matchId,
    this.sendMode = _GiftSendMode.success,
  });

  final String matchId;
  int walletCoins = 12;
  _GiftSendMode sendMode;
  Map<String, dynamic>? lastGiftSendHeaders;
  final List<String> telemetryEventNames = <String>[];

  Dio buildClient() {
    final dio = Dio(BaseOptions(baseUrl: 'https://test.invalid'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.method == 'GET' && options.path == '/chat/gifts') {
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: <String, dynamic>{
                  'gifts': <Map<String, dynamic>>[
                    <String, dynamic>{
                      'id': 'rose_blue_rare',
                      'name': 'Blue Rose',
                      'gif_url': 'https://example.test/blue.gif',
                      'icon_key': 'rose_blue',
                      'price_coins': 1,
                      'tier': 'premium_common',
                      'is_limited': false,
                    },
                  ],
                },
              ),
            );
            return;
          }

          if (options.method == 'GET' &&
              options.path == '/wallet/gift-test-user/coins') {
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: <String, dynamic>{
                  'wallet': <String, dynamic>{
                    'user_id': 'gift-test-user',
                    'coin_balance': walletCoins,
                  },
                },
              ),
            );
            return;
          }

          if (options.method == 'GET' &&
              options.path == '/chat/$matchId/messages') {
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: const <String, dynamic>{'messages': <dynamic>[]},
              ),
            );
            return;
          }

          if (options.method == 'POST' &&
              options.path == '/chat/$matchId/gifts/events') {
            final payload =
                (options.data as Map?)?.cast<String, dynamic>() ??
                <String, dynamic>{};
            final eventName = payload['event_name']?.toString() ?? '';
            if (eventName.isNotEmpty) {
              telemetryEventNames.add(eventName);
            }
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 202,
                data: const <String, dynamic>{'accepted': true},
              ),
            );
            return;
          }

          if (options.method == 'POST' &&
              options.path == '/chat/$matchId/gifts/send') {
            lastGiftSendHeaders = <String, dynamic>{
              'Idempotency-Key': options.headers['Idempotency-Key'],
              'X-User-ID': options.headers['X-User-ID'],
            };

            if (sendMode == _GiftSendMode.insufficientCoins) {
              handler.reject(
                DioException(
                  requestOptions: options,
                  response: Response<dynamic>(
                    requestOptions: options,
                    statusCode: 402,
                    data: const <String, dynamic>{
                      'success': false,
                      'error': 'insufficient wallet coins',
                      'error_code': 'INSUFFICIENT_COINS',
                    },
                  ),
                  type: DioExceptionType.badResponse,
                ),
              );
              return;
            }

            if (sendMode == _GiftSendMode.chatLocked) {
              handler.reject(
                DioException(
                  requestOptions: options,
                  response: Response<dynamic>(
                    requestOptions: options,
                    statusCode: 423,
                    data: const <String, dynamic>{
                      'success': false,
                      'error': 'chat is locked',
                      'error_code': 'CHAT_LOCKED_REQUIREMENT_PENDING',
                      'unlock_state': 'quest_pending',
                      'unlock_policy_variant': 'require_quest_template',
                    },
                  ),
                  type: DioExceptionType.badResponse,
                ),
              );
              return;
            }

            walletCoins = 11;
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: <String, dynamic>{
                  'gift_send': <String, dynamic>{
                    'id': 'gift-send-1',
                    'match_id': matchId,
                    'sender_user_id': 'gift-test-user',
                    'receiver_user_id': 'gift-receiver',
                    'gift_id': 'rose_blue_rare',
                    'gift_name': 'Blue Rose',
                    'gif_url': 'https://example.test/blue.gif',
                    'icon_key': 'rose_blue',
                    'price_coins': 1,
                    'created_at': DateTime.now().toIso8601String(),
                    'remaining_coins': 11,
                  },
                  'wallet': <String, dynamic>{
                    'user_id': 'gift-test-user',
                    'coin_balance': 11,
                  },
                },
              ),
            );
            return;
          }

          if (options.method == 'POST' &&
              options.path == '/chat/$matchId/messages') {
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: const <String, dynamic>{'success': true},
              ),
            );
            return;
          }

          handler.reject(
            DioException(
              requestOptions: options,
              error: 'unexpected request ${options.method} ${options.path}',
            ),
          );
        },
      ),
    );
    return dio;
  }
}

ProviderContainer _buildContainer(Dio dio) => ProviderContainer(
  overrides: [
    authNotifierProvider.overrideWith(_TestAuthNotifier.new),
    apiClientProvider.overrideWithValue(dio),
  ],
);

void main() {
  group('MessageNotifier rose gifts', () {
    test('adds idempotency and actor headers for send endpoint', () async {
      const matchId = 'match-gift-headers';
      final harness = _GiftApiHarness(matchId: matchId);
      final container = _buildContainer(harness.buildClient());
      addTearDown(container.dispose);

      final provider = messageNotifierProvider(matchId);
      final sub = container.listen(
        provider,
        (previous, next) {},
        fireImmediately: true,
      );
      addTearDown(sub.close);

      final notifier = container.read(provider.notifier);
      await notifier.sendRoseGift(
        gift: const RoseGift(
          id: 'rose_blue_rare',
          name: 'Blue Rose',
          gifUrl: 'https://example.test/blue.gif',
          priceCoins: 1,
          tier: 'premium_common',
          isLimited: false,
          iconKey: 'rose_blue',
        ),
        receiverUserId: 'gift-receiver',
      );

      final headers = harness.lastGiftSendHeaders;
      expect(headers, isNotNull);
      expect(headers!['X-User-ID'], 'gift-test-user');
      expect(
        (headers['Idempotency-Key'] as String?)?.startsWith('gift-'),
        isTrue,
      );
      expect(container.read(provider).walletCoins, 11);
    });

    test(
      'handles insufficient coins response with user-facing error',
      () async {
        const matchId = 'match-gift-insufficient';
        final harness = _GiftApiHarness(
          matchId: matchId,
          sendMode: _GiftSendMode.insufficientCoins,
        );
        final container = _buildContainer(harness.buildClient());
        addTearDown(container.dispose);

        final provider = messageNotifierProvider(matchId);
        final sub = container.listen(
          provider,
          (previous, next) {},
          fireImmediately: true,
        );
        addTearDown(sub.close);

        final notifier = container.read(provider.notifier);
        await notifier.sendRoseGift(
          gift: const RoseGift(
            id: 'rose_blue_rare',
            name: 'Blue Rose',
            gifUrl: 'https://example.test/blue.gif',
            priceCoins: 1,
            tier: 'premium_common',
            isLimited: false,
            iconKey: 'rose_blue',
          ),
          receiverUserId: 'gift-receiver',
        );

        final state = container.read(provider);
        expect(state.error, 'Not enough coins to send Blue Rose.');
        expect(state.isChatLocked, isFalse);
        expect(state.isSendingGift, isFalse);
      },
    );

    test('handles chat locked response and sets lock metadata', () async {
      const matchId = 'match-gift-locked';
      final harness = _GiftApiHarness(
        matchId: matchId,
        sendMode: _GiftSendMode.chatLocked,
      );
      final container = _buildContainer(harness.buildClient());
      addTearDown(container.dispose);

      final provider = messageNotifierProvider(matchId);
      final sub = container.listen(
        provider,
        (previous, next) {},
        fireImmediately: true,
      );
      addTearDown(sub.close);

      final notifier = container.read(provider.notifier);
      await notifier.sendRoseGift(
        gift: const RoseGift(
          id: 'rose_blue_rare',
          name: 'Blue Rose',
          gifUrl: 'https://example.test/blue.gif',
          priceCoins: 1,
          tier: 'premium_common',
          isLimited: false,
          iconKey: 'rose_blue',
        ),
        receiverUserId: 'gift-receiver',
      );

      final state = container.read(provider);
      expect(state.error, 'Chat is locked until the quest is approved.');
      expect(state.isChatLocked, isTrue);
      expect(state.unlockState, 'quest_pending');
      expect(state.unlockPolicyVariant, 'require_quest_template');
      expect(state.isSendingGift, isFalse);
    });

    test('posts telemetry for panel and preview interactions', () async {
      const matchId = 'match-gift-ui-telemetry';
      final harness = _GiftApiHarness(matchId: matchId);
      final container = _buildContainer(harness.buildClient());
      addTearDown(container.dispose);

      final provider = messageNotifierProvider(matchId);
      final sub = container.listen(
        provider,
        (previous, next) {},
        fireImmediately: true,
      );
      addTearDown(sub.close);

      container.read(provider.notifier)
        ..trackGiftPanelOpened()
        ..trackGiftPreviewOpened(
          const RoseGift(
            id: 'rose_blue_rare',
            name: 'Blue Rose',
            gifUrl: 'https://example.test/blue.gif',
            priceCoins: 1,
            tier: 'premium_common',
            isLimited: false,
            iconKey: 'rose_blue',
          ),
        );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(harness.telemetryEventNames, contains('gift_panel_opened'));
      expect(harness.telemetryEventNames, contains('gift_preview_opened'));
    });
  });
}
