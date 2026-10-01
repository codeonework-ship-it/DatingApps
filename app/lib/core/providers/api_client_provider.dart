import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_session_store.dart';
import '../config/app_runtime_config.dart';
import '../telemetry/client_error_reporter.dart';
import '../telemetry/pii_scrubber.dart';
import '../utils/logger.dart';
import '../network/browser_media_urls.dart';
import 'network_quality_provider.dart';

final authRefreshClientProvider = Provider<Dio>(
  (ref) => Dio(
    BaseOptions(
      baseUrl: AppRuntimeConfig.apiBaseUrl,
      connectTimeout: Duration(milliseconds: AppRuntimeConfig.apiTimeoutMs),
      receiveTimeout: Duration(milliseconds: AppRuntimeConfig.apiTimeoutMs),
      headers: const {'Content-Type': 'application/json'},
    ),
  ),
);

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
  Future<String?>? refreshInFlight;

  Future<String?> refreshAccessToken() {
    final existing = refreshInFlight;
    if (existing != null) {
      return existing;
    }
    final refreshToken = AuthSessionStore.instance.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      return Future<String?>.value();
    }
    final sessionRevision = AuthSessionStore.instance.revision;
    final refreshDio = ref.read(authRefreshClientProvider);
    Future<String?> runRefresh() async {
      try {
        final response = await refreshDio.post<dynamic>(
          '/auth/refresh',
          data: <String, dynamic>{'refresh_token': refreshToken},
        );
        final data = (response.data as Map?)?.cast<String, dynamic>() ?? {};
        final accessToken = data['access_token']?.toString().trim() ?? '';
        final rotatedRefresh = data['refresh_token']?.toString().trim() ?? '';
        if (data['success'] != true ||
            accessToken.isEmpty ||
            rotatedRefresh.isEmpty) {
          throw StateError('Session refresh was rejected.');
        }
        if (AuthSessionStore.instance.revision != sessionRevision) return null;
        AuthSessionStore.instance.update(
          accessToken: accessToken,
          refreshToken: rotatedRefresh,
        );
        return accessToken;
      } on DioException catch (error) {
        // A network outage is retryable; only a rejected credential ends this session.
        if ((error.response?.statusCode == 400 ||
                error.response?.statusCode == 401) &&
            AuthSessionStore.instance.revision == sessionRevision) {
          AuthSessionStore.instance.clear();
        }
        return null;
      } on Object {
        if (AuthSessionStore.instance.revision == sessionRevision) {
          AuthSessionStore.instance.clear();
        }
        return null;
      } finally {
        refreshInFlight = null;
      }
    }

    final future = runRefresh();
    refreshInFlight = future;
    return future;
  }

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final correlationId = CorrelationContext.generate();
        options.headers['X-Correlation-ID'] = correlationId;
        options.headers['X-Client-Platform'] = _clientPlatformTag;
        options.extra['correlation_id'] = correlationId;
        options.extra['session_revision'] = AuthSessionStore.instance.revision;
        options.extra['started_at'] = DateTime.now().microsecondsSinceEpoch;
        final accessToken = AuthSessionStore.instance.accessToken;
        if (accessToken != null && accessToken.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $accessToken';
          if (_shouldAttachIdempotencyKey(options) &&
              !_hasIdempotencyKey(options.headers)) {
            final idempotencyKey = options.extra['idempotency_key']
                ?.toString()
                .trim();
            final resolvedKey = idempotencyKey == null || idempotencyKey.isEmpty
                ? correlationId
                : idempotencyKey;
            options.extra['idempotency_key'] = resolvedKey;
            options.headers['Idempotency-Key'] = resolvedKey;
          }
        }

        // Never log query values, bodies or headers (Authorization).
        log.info('api_request', null, null, <String, dynamic>{
          'method': options.method,
          'path': _loggablePath(options.path),
          if (kDebugMode && options.queryParameters.isNotEmpty)
            'query_keys': options.queryParameters.keys.toList(),
        }, correlationId);
        handler.next(options);
      },
      onResponse: (response, handler) {
        if (kIsWeb)
          response.data = browserMediaUrls(
            response.data,
            Uri.parse(AppRuntimeConfig.apiBaseUrl),
          );
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
          'path': _loggablePath(request.path),
          'status': response.statusCode,
          'duration_ms': durationMs,
        }, correlationId);
        recordApiBreadcrumb(request.method, request.path, response.statusCode);
        ref.read(networkQualityProvider.notifier).reportSuccess(durationMs);
        handler.next(response);
      },
      onError: (error, handler) async {
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

        // DioException.toString() includes the full URI (query values); in
        // release builds only the failure type is logged. Failed requests are
        // not crash reports, so the exception itself is not forwarded there.
        log.error(
          'api_error',
          kDebugMode ? error : null,
          kDebugMode ? error.stackTrace : null,
          <String, dynamic>{
            'method': request.method,
            'path': _loggablePath(request.path),
            'status': error.response?.statusCode,
            'failure': error.type.name,
            'duration_ms': durationMs,
          },
          correlationId,
        );
        recordApiBreadcrumb(
          request.method,
          request.path,
          error.response?.statusCode,
        );
        ref.read(networkQualityProvider.notifier).reportFailure(error);

        // A response can be lost after the server has committed a write. Retry a
        // transport failure once only when the request carries a stable
        // idempotency key; the BFF will replay the original response instead of
        // applying the command twice.
        if (_shouldRetryIdempotentTransport(error)) {
          request.extra['idempotent_transport_retry'] = true;
          try {
            handler.resolve(await dio.fetch<dynamic>(request));
            return;
          } on DioException catch (retryError) {
            handler.next(retryError);
            return;
          }
        }

        // An expired processing lease is deliberately not taken over by the
        // server because the original aggregate may already be committed. Ask the
        // authenticated operation ledger for the durable outcome and resolve the
        // original call when its response is available.
        final recovery = _uncertainCommandRecovery(error.response?.data);
        if (recovery != null && request.extra['operation_recovery'] != true) {
          request.extra['operation_recovery'] = true;
          try {
            final baseUri = Uri.parse(request.baseUrl);
            final statusUri = baseUri
                .resolve(recovery.statusPath)
                .replace(
                  queryParameters: <String, String>{
                    'method': recovery.method,
                    'path': recovery.path,
                    'idempotency_key': recovery.idempotencyKey,
                  },
                );
            final statusResponse = await dio.getUri<Map<String, dynamic>>(
              statusUri,
              options: Options(
                extra: const <String, dynamic>{'operation_recovery': true},
              ),
            );
            final status = statusResponse.data ?? const <String, dynamic>{};
            if (status['state'] == 'completed') {
              handler.resolve(
                Response<dynamic>(
                  requestOptions: request,
                  statusCode: (status['http_status'] as num?)?.toInt() ?? 200,
                  data: status['result'],
                  extra: <String, dynamic>{
                    'operation_recovered': true,
                    'operation_id': status['operation_id'],
                  },
                ),
              );
              return;
            }
            if (error.response?.data is Map) {
              (error.response!.data as Map)['operation_state'] =
                  status['state'];
              (error.response!.data as Map)['operation_id'] =
                  status['operation_id'];
            }
          } on Object catch (recoveryError, recoveryStack) {
            log.error(
              'operation_recovery_failed',
              recoveryError,
              recoveryStack,
              <String, dynamic>{'path': _loggablePath(request.path)},
              correlationId,
            );
          }
        }
        final shouldRefresh =
            error.response?.statusCode == 401 &&
            request.extra['session_revision'] ==
                AuthSessionStore.instance.revision &&
            request.extra['auth_retry'] != true &&
            !request.path.startsWith('/auth/');
        if (shouldRefresh) {
          final accessToken = await refreshAccessToken();
          if (accessToken != null && accessToken.isNotEmpty) {
            request.extra['auth_retry'] = true;
            request.headers['Authorization'] = 'Bearer $accessToken';
            try {
              handler.resolve(await dio.fetch<dynamic>(request));
              return;
            } on DioException {
              // Return the original authorization failure below.
            }
          }
        }
        handler.next(error);
      },
    ),
  );

  return dio;
});

/// A request path safe for logs: never the query string; in profile and
/// release builds id-like segments are also replaced by `<id>`.
String _loggablePath(String path) {
  var value = path;
  if (value.contains('://')) {
    value = Uri.tryParse(value)?.path ?? '';
  }
  final cut = value.indexOf(RegExp('[?#]'));
  if (cut >= 0) {
    value = value.substring(0, cut);
  }
  return kDebugMode ? value : PiiScrubber.routeTemplate(value);
}

bool _hasIdempotencyKey(Map<String, dynamic> headers) => headers.entries.any(
  (entry) =>
      entry.key.toLowerCase() == 'idempotency-key' &&
      entry.value?.toString().trim().isNotEmpty == true,
);

bool _shouldAttachIdempotencyKey(RequestOptions options) {
  const writes = <String>{'POST', 'PUT', 'PATCH', 'DELETE'};
  final method = options.method.toUpperCase();
  if (!writes.contains(method)) {
    return false;
  }
  final path = options.path.startsWith('/') ? options.path : '/${options.path}';
  if (path.startsWith('/auth/')) {
    return const <String>{
      '/auth/logout',
      '/auth/sessions/revoke',
      '/auth/password/change',
      '/auth/recovery-code/rotate',
      '/auth/signup/bootstrap',
    }.contains(path);
  }
  if (method == 'POST' &&
      path.startsWith('/profile/') &&
      path.endsWith('/photos')) {
    return false;
  }
  return true;
}

bool _shouldRetryIdempotentTransport(DioException error) {
  if (error.response != null ||
      error.requestOptions.extra['idempotent_transport_retry'] == true ||
      !_hasIdempotencyKey(error.requestOptions.headers)) {
    return false;
  }
  return const <DioExceptionType>{
    DioExceptionType.connectionTimeout,
    DioExceptionType.sendTimeout,
    DioExceptionType.receiveTimeout,
    DioExceptionType.connectionError,
    DioExceptionType.unknown,
  }.contains(error.type);
}

class _CommandRecovery {
  const _CommandRecovery({
    required this.statusPath,
    required this.method,
    required this.path,
    required this.idempotencyKey,
  });

  final String statusPath;
  final String method;
  final String path;
  final String idempotencyKey;
}

_CommandRecovery? _uncertainCommandRecovery(Object? raw) {
  if (raw is! Map || raw['error_code'] != 'COMMAND_OUTCOME_UNCERTAIN') {
    return null;
  }
  final recovery = raw['recovery'];
  if (recovery is! Map) return null;
  final statusPath = recovery['status_url']?.toString().trim() ?? '';
  final method = recovery['method']?.toString().trim().toUpperCase() ?? '';
  final path = recovery['path']?.toString().trim() ?? '';
  final idempotencyKey = recovery['idempotency_key']?.toString().trim() ?? '';
  if (statusPath.isEmpty ||
      method.isEmpty ||
      path.isEmpty ||
      idempotencyKey.isEmpty) {
    return null;
  }
  return _CommandRecovery(
    statusPath: statusPath,
    method: method,
    path: path,
    idempotencyKey: idempotencyKey,
  );
}

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
