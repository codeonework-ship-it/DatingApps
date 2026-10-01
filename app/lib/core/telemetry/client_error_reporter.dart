import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_session_store.dart';
import '../config/app_runtime_config.dart';
import '../constants/app_constants.dart';
import '../utils/logger.dart';
import 'breadcrumbs.dart';
import 'pii_scrubber.dart';
import 'sha256.dart';
import 'telemetry_env_stub.dart'
    if (dart.library.io) 'telemetry_env_io.dart'
    as env;

/// Self-hosted crash and error reporting.
///
/// Errors are scrubbed of personal data, de-duplicated, queued on the device
/// and sent in small batches to `POST {apiBaseUrl}/client/errors`. Reports
/// are anonymous: they carry a random per-install id, never the account id,
/// email, phone number or device name. There is no third-party SDK.
///
/// Fatal policy: `FlutterError.onError` reports are `fatal: false` because
/// the framework has already caught them and keeps the app running (it shows
/// an error widget instead of crashing). Errors that reach
/// `PlatformDispatcher.instance.onError` or the root `runZonedGuarded`
/// handler were not caught by any code at all, so they are `fatal: true`.
/// Errors passed to `log.error(message, error, stack)` are `handled: true`,
/// `fatal: false`.
///
/// Gating: capture is compiled in only when
/// `FeatureFlags.enableClientErrorReporting` is true (off in debug builds by
/// default) and never runs under `flutter test` unless a test passes
/// `enabled: true`. The member can switch it off in Privacy & Safety; that
/// stops capture and deletes the queue from disk.
class ClientErrorReporter with WidgetsBindingObserver {
  ClientErrorReporter({
    ClientErrorStore? store,
    ClientErrorTransport? transport,
    DateTime Function()? clock,
    bool? enabled,
    ClientErrorContext Function()? context,
    String? Function()? bearerToken,
    this.flushDebounce = const Duration(seconds: 10),
    this.observeLifecycle = true,
  }) : _store = store ?? SharedPreferencesClientErrorStore(),
       _transport = transport ?? dioClientErrorTransport,
       _clock = clock ?? DateTime.now,
       buildEnabled =
           enabled ??
           (FeatureFlags.enableClientErrorReporting &&
               !env.isRunningUnderFlutterTest),
       _context = context ?? ClientErrorContext.current,
       _bearerToken =
           bearerToken ?? (() => AuthSessionStore.instance.accessToken);

  /// The app-wide reporter used by `main.dart`, the logger, the API client
  /// and the navigator observer. Tests may replace it.
  static ClientErrorReporter instance = ClientErrorReporter();

  static const int maxBatchEvents = 20;
  static const int maxQueuedEvents = 100;
  static const int maxBodyBytes = 60 * 1024;
  static const Duration dedupeWindow = Duration(seconds: 60);
  static const Duration maxEventAge = Duration(days: 7);
  static const Duration _baseBackoff = Duration(seconds: 30);
  static const Duration _maxBackoff = Duration(minutes: 30);
  static const Duration _defaultRetryAfter = Duration(seconds: 60);
  static const Duration _maxRetryAfter = Duration(hours: 1);
  static const int _maxBatchesPerFlush = 5;

  static const String queueKey = 'client_errors.queue.v1';
  static const String installIdKey = 'client_errors.install_id';
  static const String optInKey = 'client_errors.opt_in';

  final ClientErrorStore _store;
  final ClientErrorTransport _transport;
  final DateTime Function() _clock;
  final ClientErrorContext Function() _context;
  final String? Function() _bearerToken;
  final Duration flushDebounce;
  final bool observeLifecycle;

  /// Whether this build may capture at all (see class docs).
  final bool buildEnabled;

  /// The member's "Share crash reports" choice. Defaults to on.
  final ValueNotifier<bool> optIn = ValueNotifier<bool>(true);

  final BreadcrumbBuffer breadcrumbs = BreadcrumbBuffer();

  /// Template of the route on top of the app navigator, e.g. `/settings`.
  String? currentScreen;

  final List<ClientErrorEvent> _queue = <ClientErrorEvent>[];
  final Map<String, DateTime> _lastSeen = <String, DateTime>{};
  String? _installId;
  bool _started = false;
  bool _loaded = false;
  bool _flushing = false;
  bool _capturing = false;
  bool _attached = false;
  int _failures = 0;
  DateTime? _nextAttemptAt;
  Timer? _timer;

  bool get isCapturing => buildEnabled && optIn.value;

  /// Events waiting to be sent (oldest first).
  List<ClientErrorEvent> get pendingEvents =>
      List<ClientErrorEvent>.unmodifiable(_queue);

  String? get installId => _installId;

  /// Loads the opt-in choice, install id and any queue left by a previous
  /// run, then sends it. Safe to call without awaiting.
  Future<void> start() async {
    if (_started) {
      return;
    }
    _started = true;
    final stored = await _safeRead(optInKey);
    if (stored != null) {
      optIn.value = stored != '0';
    }
    if (!buildEnabled) {
      _loaded = true;
      return;
    }
    if (!optIn.value) {
      _queue.clear();
      await _safeRemove(queueKey);
      _loaded = true;
      return;
    }
    _installId = await _loadInstallId();
    final persisted = _decodeQueue(await _safeRead(queueKey));
    // Events captured before loading finished go after the persisted ones.
    _queue.insertAll(0, persisted);
    _trimQueue();
    _dropExpired(_clock());
    _loaded = true;
    _attach();
    await _persist();
    unawaited(flush());
  }

  /// Routes `log.error` into the reporter and follows app lifecycle.
  void _attach() {
    if (_attached) {
      return;
    }
    _attached = true;
    AppLogger.errorSink = _onLoggedError;
    if (observeLifecycle) {
      WidgetsBinding.instance.addObserver(this);
    }
  }

  /// Wraps the currently installed `FlutterError.onError` and
  /// `PlatformDispatcher.instance.onError` so both still run after the error
  /// is recorded. Call after `main.dart` has installed its own handlers.
  void installErrorHooks() {
    final previousFlutter = FlutterError.onError;
    FlutterError.onError = (details) {
      recordFlutterError(details);
      previousFlutter?.call(details);
    };
    final previousPlatform = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stack) {
      recordError(
        error,
        stack,
        source: ClientErrorSource.platform,
        fatal: true,
      );
      return previousPlatform?.call(error, stack) ?? true;
    };
  }

  /// Records an error the framework caught (build, layout, paint, gestures).
  void recordFlutterError(FlutterErrorDetails details) {
    // Silent errors are expected noise (for example an image that failed to
    // download on a poor connection); the framework itself does not surface
    // them in release builds.
    if (details.silent) {
      return;
    }
    recordError(
      details.exception,
      details.stack,
      source: ClientErrorSource.flutter,
    );
  }

  /// Records an error. Never throws.
  void recordError(
    Object error,
    StackTrace? stack, {
    required ClientErrorSource source,
    bool fatal = false,
    bool handled = false,
    String? context,
  }) {
    if (!buildEnabled || (_loaded && !optIn.value) || _capturing) {
      return;
    }
    _capturing = true;
    try {
      _capture(error, stack, source, fatal, handled, context);
    } on Object {
      // The reporter must never become the source of a new error.
    } finally {
      _capturing = false;
    }
  }

  void _capture(
    Object error,
    StackTrace? stack,
    ClientErrorSource source,
    bool fatal,
    bool handled,
    String? context,
  ) {
    final now = _clock();
    final errorType = _truncate(_errorType(error), 120);
    final description = _describe(error);
    final message = PiiScrubber.message(
      context == null ? description : '$context: $description',
    );
    final stackText = PiiScrubber.stack(stack?.toString() ?? '');
    final fingerprint = computeFingerprint(errorType, message, stackText);

    final last = _lastSeen[fingerprint];
    if (last != null && now.difference(last) < dedupeWindow) {
      return;
    }
    _lastSeen[fingerprint] = now;
    if (_lastSeen.length > 200) {
      _lastSeen.removeWhere((_, seen) => now.difference(seen) >= dedupeWindow);
    }

    final info = _context();
    _queue.add(
      ClientErrorEvent(
        fingerprint: fingerprint,
        errorType: errorType,
        message: message,
        stack: stackText,
        fatal: fatal,
        handled: handled,
        source: source,
        appVersion: info.appVersion,
        buildNumber: info.buildNumber,
        platform: info.platform,
        osVersion: info.osVersion,
        deviceClass: info.deviceClass,
        locale: info.locale,
        screen: currentScreen,
        breadcrumbs: breadcrumbs.snapshot(),
        occurredAt: now.toUtc(),
      ),
    );
    _trimQueue();
    if (!_loaded) {
      return;
    }
    unawaited(_persist());
    if (_queue.length >= maxBatchEvents) {
      unawaited(flush());
    } else {
      _schedule(flushDebounce);
    }
  }

  /// Adds a breadcrumb while capture is active.
  void addBreadcrumb(BreadcrumbCategory category, String message) {
    if (!isCapturing) {
      return;
    }
    breadcrumbs.add(
      Breadcrumb(
        at: _clock().toUtc(),
        category: category,
        message: clampBreadcrumb(message),
      ),
    );
  }

  /// Records `METHOD /path/template -> status` (no ids, query or body).
  void recordApi(String method, String path, int? status) => addBreadcrumb(
    BreadcrumbCategory.api,
    apiBreadcrumbMessage(method, path, status),
  );

  /// Turns crash reporting on or off for this device. Turning it off stops
  /// capture and deletes every queued report and the install id.
  Future<void> setOptIn({required bool enabled}) async {
    optIn.value = enabled;
    await _safeWrite(optInKey, enabled ? '1' : '0');
    if (enabled) {
      if (buildEnabled && _loaded) {
        _installId ??= await _loadInstallId();
        _attach();
      }
      return;
    }
    _timer?.cancel();
    _timer = null;
    _queue.clear();
    _lastSeen.clear();
    breadcrumbs.clear();
    _installId = null;
    await _safeRemove(queueKey);
    await _safeRemove(installIdKey);
  }

  /// Sends queued events. Respects back-off after a failure.
  Future<void> flush() async {
    if (!isCapturing || !_loaded || _flushing || _queue.isEmpty) {
      return;
    }
    final now = _clock();
    final nextAttempt = _nextAttemptAt;
    if (nextAttempt != null && now.isBefore(nextAttempt)) {
      _schedule(nextAttempt.difference(now));
      return;
    }
    _flushing = true;
    _timer?.cancel();
    _timer = null;
    try {
      _installId ??= await _loadInstallId();
      _dropExpired(now);
      var batches = 0;
      while (_queue.isNotEmpty &&
          isCapturing &&
          batches < _maxBatchesPerFlush) {
        batches++;
        final batch = _takeBatch();
        if (batch.isEmpty) {
          break;
        }
        final body = jsonEncode(<String, Object?>{
          'install_id': _installId,
          'events': batch.map((e) => e.toJson()).toList(),
        });
        final response = await _send(body);
        final status = response.statusCode;
        final sent = Set<ClientErrorEvent>.identity()..addAll(batch);
        if (status != null && status >= 200 && status < 300) {
          _queue.removeWhere(sent.contains);
          _failures = 0;
          _nextAttemptAt = null;
        } else if (status == 429) {
          var wait = response.retryAfter ?? _defaultRetryAfter;
          if (wait > _maxRetryAfter) {
            wait = _maxRetryAfter;
          }
          _nextAttemptAt = _clock().add(wait);
          _schedule(wait);
          break;
        } else if (status == null ||
            status >= 500 ||
            status == 408 ||
            status == 401 ||
            status == 403) {
          _failures++;
          final wait = _backoff();
          _nextAttemptAt = _clock().add(wait);
          _schedule(wait);
          break;
        } else {
          // 400, 413 and other client errors: the batch can never succeed,
          // so drop it rather than retry forever.
          _queue.removeWhere(sent.contains);
        }
      }
      if (_queue.isNotEmpty && _timer == null && _nextAttemptAt == null) {
        _schedule(flushDebounce);
      }
      await _persist();
    } on Object {
      // Never let reporting failures escape.
    } finally {
      _flushing = false;
    }
  }

  /// Cancels timers and lifecycle observation. Used by tests.
  void dispose() {
    _timer?.cancel();
    _timer = null;
    if (observeLifecycle && _attached) {
      WidgetsBinding.instance.removeObserver(this);
    }
    _attached = false;
    if (AppLogger.errorSink == _onLoggedError) {
      AppLogger.errorSink = null;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      addBreadcrumb(BreadcrumbCategory.lifecycle, 'resumed');
      unawaited(flush());
    } else if (state == AppLifecycleState.paused) {
      addBreadcrumb(BreadcrumbCategory.lifecycle, 'paused');
    }
  }

  void _onLoggedError(String message, Object error, StackTrace? stack) {
    // Failed HTTP calls are expected (offline, 4xx) and already measured on
    // the server, so they are not reported as client errors.
    if (error is DioException) {
      return;
    }
    recordError(
      error,
      stack,
      source: ClientErrorSource.logger,
      handled: true,
      context: message,
    );
  }

  Future<ClientErrorTransportResponse> _send(String body) async {
    final token = _bearerToken();
    final hasToken = token != null && token.isNotEmpty;
    var response = await _transport(body, bearerToken: hasToken ? token : null);
    if (hasToken && response.statusCode == 401) {
      // An expired session must not block anonymous reports.
      response = await _transport(body);
    }
    return response;
  }

  List<ClientErrorEvent> _takeBatch() {
    final batch = <ClientErrorEvent>[];
    var bytes = 0;
    final oversized = <ClientErrorEvent>[];
    for (final event in _queue) {
      if (batch.length >= maxBatchEvents) {
        break;
      }
      final size = utf8.encode(jsonEncode(event.toJson())).length + 1;
      if (size > maxBodyBytes - 256) {
        oversized.add(event);
        continue;
      }
      if (bytes + size > maxBodyBytes - 256) {
        break;
      }
      bytes += size;
      batch.add(event);
    }
    if (oversized.isNotEmpty) {
      final drop = Set<ClientErrorEvent>.identity()..addAll(oversized);
      _queue.removeWhere(drop.contains);
    }
    return batch;
  }

  Duration _backoff() {
    final exponent = min(_failures - 1, 10);
    final wait = _baseBackoff * pow(2, exponent).toInt();
    return wait > _maxBackoff ? _maxBackoff : wait;
  }

  void _schedule(Duration delay) {
    if (!isCapturing) {
      return;
    }
    _timer?.cancel();
    _timer = Timer(delay, () {
      _timer = null;
      unawaited(flush());
    });
  }

  void _trimQueue() {
    if (_queue.length > maxQueuedEvents) {
      _queue.removeRange(0, _queue.length - maxQueuedEvents);
    }
  }

  void _dropExpired(DateTime now) {
    _queue.removeWhere((e) => now.difference(e.occurredAt) > maxEventAge);
  }

  Future<void> _persist() async {
    if (!isCapturing) {
      return;
    }
    if (_queue.isEmpty) {
      await _safeRemove(queueKey);
      return;
    }
    await _safeWrite(
      queueKey,
      jsonEncode(_queue.map((e) => e.toJson()).toList()),
    );
  }

  List<ClientErrorEvent> _decodeQueue(String? raw) {
    if (raw == null || raw.isEmpty) {
      return <ClientErrorEvent>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <ClientErrorEvent>[];
      }
      return decoded
          .map(ClientErrorEvent.tryParse)
          .whereType<ClientErrorEvent>()
          .toList();
    } on FormatException {
      return <ClientErrorEvent>[];
    }
  }

  Future<String> _loadInstallId() async {
    final stored = await _safeRead(installIdKey);
    if (stored != null && _installIdPattern.hasMatch(stored)) {
      return stored;
    }
    final id = generateInstallId();
    await _safeWrite(installIdKey, id);
    return id;
  }

  Future<String?> _safeRead(String key) async {
    try {
      return await _store.read(key);
    } on Object {
      return null;
    }
  }

  Future<void> _safeWrite(String key, String value) async {
    try {
      await _store.write(key, value);
    } on Object {
      // Storage unavailable: keep working from memory.
    }
  }

  Future<void> _safeRemove(String key) async {
    try {
      await _store.remove(key);
    } on Object {
      // Storage unavailable: nothing to delete.
    }
  }

  static final RegExp _installIdPattern = RegExp(r'^[A-Za-z0-9_-]{16,64}$');
  static const String _installIdAlphabet =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';

  /// A random 32-character url-safe id, generated once per install.
  static String generateInstallId() {
    final random = Random.secure();
    return List<String>.generate(
      32,
      (_) => _installIdAlphabet[random.nextInt(_installIdAlphabet.length)],
    ).join();
  }

  static String _errorType(Object error) {
    final name = error.runtimeType.toString();
    final generic = name.indexOf('<');
    return generic > 0 ? name.substring(0, generic) : name;
  }

  static String _describe(Object error) {
    // FormatException.toString() echoes the input it failed to parse, which
    // may be a member's message or profile text. Keep only the reason.
    if (error is FormatException) {
      return 'FormatException: ${error.message}';
    }
    try {
      return error.toString();
    } on Object {
      return _errorType(error);
    }
  }

  static String _truncate(String value, int max) =>
      value.length > max ? value.substring(0, max) : value;
}

/// Client-side grouping hint: sha256 of the error type, the message with
/// digits normalised, and the top five stack frames without line/column
/// numbers. The server computes its own grouping; this is advisory.
String computeFingerprint(String errorType, String message, String stack) {
  final normalisedMessage = message.replaceAll(RegExp(r'\d+'), '0');
  final frames = stack
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .take(5)
      .map(
        (line) => line
            .replaceAll(RegExp(r'^#\d+\s+'), '')
            .replaceAll(RegExp(r':\d+(:\d+)?'), ''),
      )
      .join('\n');
  return sha256Hex('$errorType\n$normalisedMessage\n$frames');
}

/// Records an API breadcrumb on the app-wide reporter.
void recordApiBreadcrumb(String method, String path, int? status) =>
    ClientErrorReporter.instance.recordApi(method, path, status);

/// Exposes the app-wide reporter to widgets (overridable in tests).
final clientErrorReporterProvider = Provider<ClientErrorReporter>(
  (ref) => ClientErrorReporter.instance,
);

enum ClientErrorSource { flutter, platform, zone, logger }

/// One report in the `events` array of `POST /v1/client/errors`.
class ClientErrorEvent {
  const ClientErrorEvent({
    required this.fingerprint,
    required this.errorType,
    required this.message,
    required this.stack,
    required this.fatal,
    required this.handled,
    required this.source,
    required this.appVersion,
    required this.buildNumber,
    required this.platform,
    required this.osVersion,
    required this.deviceClass,
    required this.locale,
    required this.breadcrumbs,
    required this.occurredAt,
    this.screen,
  });

  final String fingerprint;
  final String errorType;
  final String message;
  final String stack;
  final bool fatal;
  final bool handled;
  final ClientErrorSource source;
  final String appVersion;
  final String buildNumber;
  final String platform;
  final String osVersion;
  final String deviceClass;
  final String locale;
  final String? screen;
  final List<Breadcrumb> breadcrumbs;
  final DateTime occurredAt;

  Map<String, Object?> toJson() => <String, Object?>{
    'fingerprint': fingerprint,
    'error_type': errorType,
    'message': message,
    'stack': stack,
    'fatal': fatal,
    'handled': handled,
    'source': source.name,
    'app_version': appVersion,
    'build_number': buildNumber,
    'platform': platform,
    'os_version': osVersion,
    'device_class': deviceClass,
    'locale': locale,
    if (screen != null && screen!.isNotEmpty) 'screen': screen,
    'breadcrumbs': breadcrumbs.map((b) => b.toJson()).toList(),
    'occurred_at': occurredAt.toUtc().toIso8601String(),
  };

  static ClientErrorEvent? tryParse(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final occurredAt = DateTime.tryParse(raw['occurred_at']?.toString() ?? '');
    final errorType = raw['error_type']?.toString() ?? '';
    final sources = ClientErrorSource.values.where(
      (s) => s.name == raw['source'],
    );
    if (occurredAt == null || errorType.isEmpty || sources.isEmpty) {
      return null;
    }
    final crumbs = raw['breadcrumbs'];
    String text(String key) => raw[key]?.toString() ?? '';
    return ClientErrorEvent(
      fingerprint: text('fingerprint'),
      errorType: errorType,
      message: text('message'),
      stack: text('stack'),
      fatal: raw['fatal'] == true,
      handled: raw['handled'] == true,
      source: sources.first,
      appVersion: text('app_version'),
      buildNumber: text('build_number'),
      platform: text('platform'),
      osVersion: text('os_version'),
      deviceClass: text('device_class'),
      locale: text('locale'),
      screen: raw['screen']?.toString(),
      breadcrumbs: crumbs is List
          ? crumbs.map(Breadcrumb.tryParse).whereType<Breadcrumb>().toList()
          : const <Breadcrumb>[],
      occurredAt: occurredAt.toUtc(),
    );
  }
}

/// Non-identifying device facts attached to every report.
@immutable
class ClientErrorContext {
  const ClientErrorContext({
    required this.platform,
    required this.osVersion,
    required this.deviceClass,
    required this.locale,
    required this.appVersion,
    required this.buildNumber,
  });

  /// Reads the running device. No device name or model is collected.
  factory ClientErrorContext.current() => ClientErrorContext(
    platform: _platform(),
    osVersion: _clean(PiiScrubber.scrub(env.operatingSystemVersion), 64),
    deviceClass: _deviceClass(),
    locale: _clean(PlatformDispatcher.instance.locale.toString(), 16),
    appVersion: _versionClean(AppVersion.name, 32),
    buildNumber: _versionClean(AppVersion.buildNumber, 16),
  );

  final String platform;
  final String osVersion;
  final String deviceClass;
  final String locale;
  final String appVersion;
  final String buildNumber;

  static String _platform() {
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
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return 'linux';
    }
  }

  static String _deviceClass() {
    if (kIsWeb) {
      return 'web';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return 'desktop';
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
        break;
    }
    final dispatcher = PlatformDispatcher.instance;
    final view =
        dispatcher.implicitView ??
        (dispatcher.views.isEmpty ? null : dispatcher.views.first);
    if (view == null || view.devicePixelRatio <= 0) {
      return 'unknown';
    }
    final size = view.physicalSize / view.devicePixelRatio;
    final shortest = size.shortestSide;
    if (shortest <= 0) {
      return 'unknown';
    }
    return shortest >= 600 ? 'tablet' : 'phone';
  }

  static String _clean(String value, int max) {
    final trimmed = value.trim();
    return trimmed.length > max ? trimmed.substring(0, max) : trimmed;
  }

  static String _versionClean(String value, int max) =>
      _clean(value.replaceAll(RegExp(r'[^0-9A-Za-z.+\-]'), ''), max);
}

/// Response of one upload attempt. [statusCode] is null on network failure.
@immutable
class ClientErrorTransportResponse {
  const ClientErrorTransportResponse({this.statusCode, this.retryAfter});

  final int? statusCode;
  final Duration? retryAfter;
}

/// Sends one JSON body to the error endpoint.
typedef ClientErrorTransport =
    Future<ClientErrorTransportResponse> Function(
      String jsonBody, {
      String? bearerToken,
    });

Dio? _transportDio;

/// Default transport: a dedicated Dio with no interceptors, so a reporting
/// failure can never recurse into the reporter, create API breadcrumbs or log
/// request bodies.
Future<ClientErrorTransportResponse> dioClientErrorTransport(
  String jsonBody, {
  String? bearerToken,
}) async {
  final dio = _transportDio ??= Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      responseType: ResponseType.plain,
      validateStatus: (_) => true,
    ),
  );
  var base = AppRuntimeConfig.apiBaseUrl;
  while (base.endsWith('/')) {
    base = base.substring(0, base.length - 1);
  }
  try {
    final response = await dio.post<String>(
      '$base/client/errors',
      data: jsonBody,
      options: Options(
        headers: <String, Object>{
          'Content-Type': 'application/json',
          if (bearerToken != null) 'Authorization': 'Bearer $bearerToken',
        },
      ),
    );
    final retryAfter = int.tryParse(
      response.headers.value('retry-after')?.trim() ?? '',
    );
    return ClientErrorTransportResponse(
      statusCode: response.statusCode,
      retryAfter: retryAfter == null || retryAfter < 0
          ? null
          : Duration(seconds: retryAfter),
    );
  } on Object {
    return const ClientErrorTransportResponse();
  }
}

/// Key-value persistence for the queue, install id and opt-in choice.
abstract class ClientErrorStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> remove(String key);
}

/// Device storage (SharedPreferences; localStorage on the web).
class SharedPreferencesClientErrorStore implements ClientErrorStore {
  @override
  Future<String?> read(String key) async =>
      (await SharedPreferences.getInstance()).getString(key);

  @override
  Future<void> write(String key, String value) async {
    await (await SharedPreferences.getInstance()).setString(key, value);
  }

  @override
  Future<void> remove(String key) async {
    await (await SharedPreferences.getInstance()).remove(key);
  }
}

/// In-memory store for tests.
class MemoryClientErrorStore implements ClientErrorStore {
  final Map<String, String> values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async => values.remove(key);
}
