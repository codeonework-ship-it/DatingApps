import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

/// A canned server answer: a status code and a JSON body.
typedef FakeReply = ({int status, Object body});

typedef FakeHandler = FakeReply Function(RequestOptions request);

/// Answers support API calls from [routes], keyed `METHOD /path`, and
/// records every request so tests can assert the exact payloads sent.
class FakeSupportApi {
  FakeSupportApi(this.routes);

  final Map<String, FakeHandler> routes;
  final requests = <RequestOptions>[];

  List<RequestOptions> sent(String method, String path) => requests
      .where((r) => r.method == method && r.path == path)
      .toList(growable: false);

  Dio get dio {
    final dio = Dio(BaseOptions(baseUrl: 'https://support.invalid/v1'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          final handlerFn = routes['${options.method} ${options.path}'];
          final reply = handlerFn == null
              ? (status: 404, body: {'success': false, 'error': 'not found'})
              : handlerFn(options);
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

FakeReply ok(Object body, {int status = 200}) => (status: status, body: body);

FakeReply serverError(int status, String code, {Map<String, dynamic>? extra}) =>
    (
      status: status,
      body: {
        'success': false,
        'error': 'server says $code',
        'error_code': code,
        ...?extra,
      },
    );

Map<String, dynamic> ticketJson({
  String id = 'ticket-1',
  String reference = 'CN-2026-000123',
  String status = 'open',
  String category = 'technical',
  String subject = 'App crashes on chat',
  int unread = 0,
  bool canReply = true,
  bool canClose = true,
  bool canReopen = false,
  bool canRate = false,
  String? reopenUntil,
  Map<String, dynamic>? satisfaction,
}) => {
  'id': id,
  'reference': reference,
  'category': category,
  'subject': subject,
  'status': status,
  'channel': 'app',
  'created_at': '2026-09-30T10:00:00Z',
  'updated_at': '2026-09-30T11:00:00Z',
  'last_activity_at': '2026-09-30T11:00:00Z',
  'resolved_at': null,
  'closed_at': null,
  'reopen_until': reopenUntil,
  'message_count': 2,
  'unread_count': unread,
  'last_message_preview': 'Thanks, could you send a screenshot?',
  'last_message_author': 'agent',
  'can_reply': canReply,
  'can_close': canClose,
  'can_reopen': canReopen,
  'can_rate': canRate,
  'satisfaction': satisfaction,
  'merged_into_reference': null,
};

Map<String, dynamic> messageJson({
  String id = 'm-1',
  String author = 'member',
  String body = 'When I open a chat the app closes.',
  List<Map<String, dynamic>> attachments = const [],
}) => {
  'id': id,
  'author': author,
  'author_name': author == 'agent' ? 'Connect Support' : null,
  'body': body,
  'created_at': '2026-09-30T10:00:00Z',
  'attachments': attachments,
};

/// Hosts [child] with the fake API and the app's localisations.
Widget supportHost(FakeSupportApi api, Widget child, {List<Override>? extra}) =>
    ProviderScope(
      overrides: [apiClientProvider.overrideWithValue(api.dio), ...?extra],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );

/// Pumps [child] on a tall view (so whole forms fit) and lets it settle.
Future<void> pumpSupport(
  WidgetTester tester,
  FakeSupportApi api,
  Widget child, {
  List<Override>? extra,
}) async {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(supportHost(api, child, extra: extra));
  await tester.pumpAndSettle();
}
