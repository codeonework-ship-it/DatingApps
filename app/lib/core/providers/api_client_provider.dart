import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_runtime_config.dart';
import '../utils/logger.dart';
import 'network_quality_provider.dart';

final apiClientProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppRuntimeConfig.apiBaseUrl,
      connectTimeout: Duration(milliseconds: AppRuntimeConfig.apiTimeoutMs),
      receiveTimeout: Duration(milliseconds: AppRuntimeConfig.apiTimeoutMs),
      sendTimeout: Duration(milliseconds: AppRuntimeConfig.apiTimeoutMs),
      headers: const {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final correlationId = CorrelationContext.generate();
        options.headers['X-Correlation-ID'] = correlationId;
        options.headers['X-Client-Platform'] = _clientPlatformTag;
        options.extra['correlation_id'] = correlationId;
        options.extra['started_at'] = DateTime.now().microsecondsSinceEpoch;

        log.info('api_request', null, null, <String, dynamic>{
          'method': options.method,
          'path': options.path,
          'base_url': options.baseUrl,
          'query': options.queryParameters,
        }, correlationId);
        handler.next(options);
      },
      onResponse: (response, handler) {
        final request = response.requestOptions;
        final correlationId =
            request.extra['correlation_id']?.toString() ??
            response.headers.value('X-Correlation-ID') ??
            '';
        final startedAt = request.extra['started_at'];
        var durationMs = 0;
        if (startedAt is int) {
          durationMs =
              (DateTime.now().microsecondsSinceEpoch - startedAt) ~/ 1000;
        }

        log.info('api_response', null, null, <String, dynamic>{
          'method': request.method,
          'path': request.path,
          'status': response.statusCode,
          'duration_ms': durationMs,
        }, correlationId);
        ref.read(networkQualityProvider.notifier).reportSuccess(durationMs);
        handler.next(response);
      },
      onError: (error, handler) {
        final request = error.requestOptions;
        final correlationId =
            request.extra['correlation_id']?.toString() ??
            error.response?.headers.value('X-Correlation-ID') ??
            '';
        final startedAt = request.extra['started_at'];
        var durationMs = 0;
        if (startedAt is int) {
          durationMs =
              (DateTime.now().microsecondsSinceEpoch - startedAt) ~/ 1000;
        }

        log.error('api_error', error, error.stackTrace, <String, dynamic>{
          'method': request.method,
          'path': request.path,
          'status': error.response?.statusCode,
          'duration_ms': durationMs,
        }, correlationId);
        ref.read(networkQualityProvider.notifier).reportFailure(error);
        handler.next(error);
      },
    ),
  );

  return dio;
});

String get _clientPlatformTag {
  if (kIsWeb) {
    return 'web';
  }
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return 'android';
    case TargetPlatform.iOS:
      return 'ios';
    case TargetPlatform.macOS:
      return 'macos';
    case TargetPlatform.linux:
      return 'linux';
    case TargetPlatform.windows:
      return 'windows';
    case TargetPlatform.fuchsia:
      return 'fuchsia';
  }
}
