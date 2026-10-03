// Shared QA harness for control-level widget tests: a recording fake BFF
// (every request is kept so tests assert the exact method, path, query and
// body the app sent) plus a host that pumps a screen the way the app does
// (signed-in member, runtime flags, theme, all 10 locales).
//
// Tag every test name with the catalog case ids it proves: the text
// `[case:` + the case id + `]`, once per case (several per test allowed).
// The QA Lab runner reads these tags from test names.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/core/providers/runtime_feature_flags_provider.dart';
import 'package:verified_dating_app/core/theme/app_theme.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/notifications/providers/notification_provider.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

/// One request the app sent.
class QaCall {
  QaCall(this.options);
  final RequestOptions options;
  String get method => options.method;
  String get path => options.path;
  Map<String, dynamic> get query => options.queryParameters;
  Object? get data => options.data;

  /// The JSON body as a map (empty when the body is not a map).
  Map<String, dynamic> get body =>
      data is Map ? (data! as Map).cast<String, dynamic>() : const {};

  @override
  String toString() =>
      '$method $path${query.isEmpty ? '' : ' $query'}${data == null ? '' : ' $data'}';
}

/// What the fake server answers.
class QaReply {
  const QaReply(this.status, this.body, {this.offline = false, this.delay});
  final int status;
  final Object? body;
  final bool offline;
  final Duration? delay;
}

typedef QaHandler = QaReply Function(QaCall call);

QaReply qaOk([Object? body = const <String, dynamic>{}]) => QaReply(200, body);

/// A server error with the BFF's error envelope.
QaReply qaError(
  int status, {
  String message = 'Something broke on our side.',
  String? code,
  Map<String, dynamic>? extra,
}) => QaReply(status, {
  'success': false,
  'error': message,
  'message': message,
  'error_code': ?code,
  ...?extra,
});

/// The device is offline: Dio raises a connection error with no response.
const qaOffline = QaReply(0, null, offline: true);

/// Recording fake BFF. Routes are keyed `'METHOD /path'`; a `*` segment
/// matches any one path segment (`'POST /groups/*/join'`). Later [on] calls
/// replace earlier ones, so a test can start from a happy fixture and then
/// fail one route. Unknown routes answer 404 and are listed in [unhandled].
class QaApi {
  QaApi([Map<String, QaHandler>? routes]) {
    routes?.forEach(on);
  }

  final _routes = <String, QaHandler>{};
  final calls = <QaCall>[];
  final unhandled = <QaCall>[];

  /// Registers (or replaces) a route handler.
  void on(String route, QaHandler handler) => _routes[route] = handler;

  /// Forgets every route handler (recorded [calls] are kept). An exact
  /// route wins over a `*` route, so a fixture that wants its wildcard
  /// routes back after a test failed one exact path clears first.
  void clearRoutes() => _routes.clear();

  /// Registers a fixed JSON answer.
  void json(String route, Object? body) => on(route, (_) => qaOk(body));

  /// Makes [route] fail with [status] (default 500).
  void fail(String route, {int status = 500, String? message, String? code}) =>
      on(
        route,
        (_) => qaError(
          status,
          message: message ?? 'Something broke on our side.',
          code: code,
        ),
      );

  /// Makes [route] fail as if the device were offline.
  void offline(String route) => on(route, (_) => qaOffline);

  /// Non-GET requests (the commands the app sent).
  List<QaCall> get writes => calls.where((c) => c.method != 'GET').toList();

  /// Requests matching [method] and [path] (a `*` segment matches any one).
  List<QaCall> sent(String method, String path) =>
      calls.where((c) => c.method == method && _match(path, c.path)).toList();

  /// Short `METHOD /path` lines of the commands, handy in `expect`.
  List<String> get writeLines =>
      writes.map((c) => '${c.method} ${c.path}').toList();

  static bool _match(String pattern, String path) {
    if (pattern == path) {
      return true;
    }
    final p = pattern.split('/');
    final a = path.split('/');
    if (p.length != a.length) {
      return false;
    }
    for (var i = 0; i < p.length; i++) {
      if (p[i] != '*' && p[i] != a[i]) {
        return false;
      }
    }
    return true;
  }

  QaHandler? _find(String method, String path) {
    final exact = _routes['$method $path'];
    if (exact != null) {
      return exact;
    }
    for (final entry in _routes.entries) {
      final space = entry.key.indexOf(' ');
      if (entry.key.substring(0, space) == method &&
          _match(entry.key.substring(space + 1), path)) {
        return entry.value;
      }
    }
    return null;
  }

  Dio get dio {
    final dio = Dio(BaseOptions(baseUrl: 'http://bff.test/v1'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final call = QaCall(options);
          calls.add(call);
          final route = _find(options.method, options.path);
          if (route == null) {
            unhandled.add(call);
          }
          final reply =
              route?.call(call) ??
              const QaReply(404, {'success': false, 'error': 'not found'});
          if (reply.delay != null) {
            await Future<void>.delayed(reply.delay!);
          }
          if (reply.offline) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.connectionError,
                message: 'Connection refused',
              ),
            );
            return;
          }
          final response = Response<dynamic>(
            requestOptions: options,
            statusCode: reply.status,
            data: reply.body,
          );
          if (reply.status >= 400) {
            handler.reject(
              DioException(
                requestOptions: options,
                response: response,
                type: DioExceptionType.badResponse,
              ),
            );
            return;
          }
          handler.resolve(response);
        },
      ),
    );
    return dio;
  }
}

class _QaAuth extends AuthNotifier {
  _QaAuth(this.state0);
  final AuthState state0;
  @override
  AuthState build() => state0;
}

/// Signed-in member override (`me` by default).
Override qaAuth({String userId = 'me', String accountKind = 'dating'}) =>
    authNotifierProvider.overrideWith(
      () => _QaAuth(
        AuthState(
          isAuthenticated: true,
          userId: userId,
          username: userId,
          accountKind: accountKind,
        ),
      ),
    );

/// Runtime flags: the local all-on defaults with [flags] applied on top.
Override qaFlags([Map<String, bool> flags = const {}]) =>
    runtimeFeatureFlagsProvider.overrideWith(
      (ref) => Stream.value(
        RuntimeFeatureFlags({...RuntimeFeatureFlags.defaults.values, ...flags}),
      ),
    );

/// The standard overrides: signed-in member, fake API, runtime flags.
List<Override> qaOverrides(
  QaApi api, {
  String userId = 'me',
  String accountKind = 'dating',
  Map<String, bool> flags = const {},
  List<Override> extra = const [],
}) => [
  qaAuth(userId: userId, accountKind: accountKind),
  apiClientProvider.overrideWithValue(api.dio),
  qaFlags(flags),
  ...extra,
];

/// Pumps [child] as the home of a localized, themed app on a phone-sized
/// view. Pass [launcher] = true to push [child] from a launcher page
/// instead; the pop results are returned so tests can assert what a screen
/// handed back to its opener (and that it closed).
Future<List<Object?>> pumpQa(
  WidgetTester tester,
  QaApi api,
  Widget child, {
  String userId = 'me',
  String accountKind = 'dating',
  Map<String, bool> flags = const {},
  List<Override> extra = const [],
  Size size = const Size(430, 932),
  Locale? locale,
  bool launcher = false,
  bool settle = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final results = <Object?>[];
  await tester.pumpWidget(
    ProviderScope(
      overrides: qaOverrides(
        api,
        userId: userId,
        accountKind: accountKind,
        flags: flags,
        extra: extra,
      ),
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: launcher
            ? Builder(
                builder: (context) => Scaffold(
                  body: Center(
                    child: TextButton(
                      key: const ValueKey('qa.test.launcher'),
                      onPressed: () async => results.add(
                        await Navigator.of(context).push<Object?>(
                          MaterialPageRoute(builder: (_) => child),
                        ),
                      ),
                      child: const Text('open'),
                    ),
                  ),
                ),
              )
            : child,
      ),
    ),
  );
  if (launcher) {
    await tester.tap(find.byKey(const ValueKey('qa.test.launcher')));
  }
  if (settle) {
    await qaSettle(tester);
  }
  return results;
}

/// Pumps frames for [frames] x 100 ms. Use instead of pumpAndSettle where a
/// screen has a looping animation or a periodic timer.
Future<void> qaSettle(WidgetTester tester, {int frames = 10}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Every locale the app ships, for l10n render cases.
List<Locale> get qaLocales => AppLocalizations.supportedLocales;

/// The localizations for [locale] (to assert translated labels render).
AppLocalizations qaL10n(Locale locale) => lookupAppLocalizations(locale);

/// The visible SnackBar text, or null.
String? qaSnackText(WidgetTester tester) {
  final bars = find.byType(SnackBar);
  if (bars.evaluate().isEmpty) {
    return null;
  }
  final texts = find.descendant(of: bars.first, matching: find.byType(Text));
  return texts
      .evaluate()
      .map((e) => (e.widget as Text).data ?? '')
      .where((t) => t.isNotEmpty)
      .join(' ');
}

/// A notification provider that loads nothing and opens no realtime socket,
/// for screens tested on their own that only read the unread count (e.g.
/// Settings' "Notification inbox" row). In the app the main navigation keeps
/// the real connection open.
Override idleNotificationsOverride() => notificationProvider.overrideWith(_IdleNotifications.new);

class _IdleNotifications extends NotificationNotifier {
  _IdleNotifications(super.ref);

  @override
  Future<void> bootstrap() async {}
}
