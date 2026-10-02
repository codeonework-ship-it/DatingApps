import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';

import 'qa_api.dart';

// The shared QA harness must report what the app really sent and fail the
// way a real server or a dropped connection does, or every test built on it
// would pass on scaffolding.
void main() {
  test('records requests and matches wildcard routes', () async {
    final api = QaApi({
      'GET /groups/*': (c) => qaOk({'id': c.path}),
    });
    final dio = api.dio;
    final res = await dio.get<dynamic>('/groups/g-1');
    expect(res.data, {'id': '/groups/g-1'});
    // Unknown routes answer 404 (and are listed), like a missing endpoint.
    await expectLater(
      dio.post<dynamic>('/groups/g-1/join', data: {'a': 1}),
      throwsA(isA<DioException>()),
    );
    expect(api.writeLines, ['POST /groups/g-1/join']);
    expect(api.sent('POST', '/groups/*/join').single.body, {'a': 1});
    expect(api.unhandled.single.path, '/groups/g-1/join');
  });

  test('fail and offline reject like the real client', () async {
    final api = QaApi()
      ..fail('POST /x', status: 422, message: 'Too long')
      ..offline('GET /y');
    final dio = api.dio;
    final bad = await dio
        .post<dynamic>('/x')
        .then<Object?>((_) => null, onError: (Object e) => e);
    expect((bad! as DioException).response?.statusCode, 422);
    expect((bad as DioException).response?.data['error'], 'Too long');
    final off = await dio
        .get<dynamic>('/y')
        .then<Object?>((_) => null, onError: (Object e) => e);
    expect((off! as DioException).type, DioExceptionType.connectionError);
  });

  testWidgets('pumpQa hosts a screen with the fake API and pops results', (
    tester,
  ) async {
    final api = QaApi()..json('GET /ping', {'ok': true});
    final results = await pumpQa(
      tester,
      api,
      Consumer(
        builder: (context, ref, _) => TextButton(
          onPressed: () async {
            await ref.read(apiClientProvider).get<dynamic>('/ping');
            if (context.mounted) Navigator.of(context).pop('done');
          },
          child: const Text('go'),
        ),
      ),
      launcher: true,
    );
    await tester.tap(find.text('go'));
    await qaSettle(tester);
    expect(api.sent('GET', '/ping'), hasLength(1));
    expect(results, ['done']);
  });
}
