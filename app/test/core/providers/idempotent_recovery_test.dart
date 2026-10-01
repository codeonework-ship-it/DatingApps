import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/auth/auth_session_store.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';

class _RecoveryAdapter implements HttpClientAdapter {
  _RecoveryAdapter({required this.mode});

  final String mode;
  int writeCalls = 0;
  final List<String> idempotencyKeys = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.uri.path.endsWith('/operations/status')) {
      return ResponseBody.fromString(
        jsonEncode(<String, dynamic>{
          'operation_id': 'operation-1',
          'state': 'completed',
          'http_status': 200,
          'result': <String, dynamic>{'saved': true},
        }),
        200,
        headers: <String, List<String>>{
          Headers.contentTypeHeader: <String>[Headers.jsonContentType],
        },
      );
    }
    writeCalls++;
    idempotencyKeys.add(options.headers['Idempotency-Key']?.toString() ?? '');
    if (mode == 'transport' && writeCalls == 1) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    if (mode == 'uncertain') {
      return ResponseBody.fromString(
        jsonEncode(<String, dynamic>{
          'success': false,
          'error_code': 'COMMAND_OUTCOME_UNCERTAIN',
          'recovery': <String, dynamic>{
            'status_url': '/v1/operations/status',
            'method': 'PATCH',
            'path': '/v1/settings/member-1',
            'idempotency_key': options.headers['Idempotency-Key'],
          },
        }),
        409,
        headers: <String, List<String>>{
          Headers.contentTypeHeader: <String>[Headers.jsonContentType],
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode(<String, dynamic>{'saved': true}),
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  setUp(
    () => AuthSessionStore.instance.update(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
    ),
  );
  tearDown(AuthSessionStore.instance.clear);

  test('transport retry reuses the original idempotency key', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final adapter = _RecoveryAdapter(mode: 'transport');
    final dio = container.read(apiClientProvider)..httpClientAdapter = adapter;

    final response = await dio.patch<Map<String, dynamic>>(
      '/settings/member-1',
      data: <String, dynamic>{'notifications_enabled': true},
    );

    expect(response.data?['saved'], true);
    expect(adapter.writeCalls, 2);
    expect(adapter.idempotencyKeys.first, isNotEmpty);
    expect(adapter.idempotencyKeys.toSet(), hasLength(1));
  });

  test('uncertain command resolves from durable operation status', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final adapter = _RecoveryAdapter(mode: 'uncertain');
    final dio = container.read(apiClientProvider)..httpClientAdapter = adapter;

    final response = await dio.patch<Map<String, dynamic>>(
      '/settings/member-1',
      data: <String, dynamic>{'notifications_enabled': true},
    );

    expect(response.data?['saved'], true);
    expect(response.extra['operation_recovered'], true);
    expect(response.extra['operation_id'], 'operation-1');
    expect(adapter.writeCalls, 1);
  });
}
