import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/network/browser_media_urls.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/photo_themes/photo_themes_data.dart';
import 'package:verified_dating_app/features/photo_themes/photo_wall.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

/// Regression for theme photos (Cover of the Week) never rendering in the
/// browser. The web API client rewrites media links in every response; it used
/// to walk the photo's `Uint8List` as a JSON list, producing a `List<dynamic>`
/// that Dio could not cast to the `List<int>` the photo request asked for, so
/// the request failed and the cover fell back to its gradient placeholder.
///
/// These tests send the photo through Dio's real response pipeline (an HTTP
/// adapter, not an interceptor that short-circuits with a ready-made value),
/// with the web client's response rewrite installed.

class _Auth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(isAuthenticated: true, userId: 'me');
}

/// A 1x1 transparent PNG, standing in for a member's photo bytes.
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA'
  '60e6kgAAAABJRU5ErkJggg==',
);

const _photoPath = '/themes/t1/entries/e1/photo';

class _PhotoAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path == _photoPath) {
      return ResponseBody.fromBytes(
        _png,
        200,
        headers: {
          Headers.contentTypeHeader: ['image/png'],
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode({
        'photo_url': 'http://127.0.0.1:18080/v1/media/approved/me/a.jpg',
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

final _apiBase = Uri.parse('http://127.0.0.1:4190/v1');

/// The browser build's API client response handling.
Dio _webApi({void Function(Response<dynamic> response)? rewrite}) =>
    Dio(BaseOptions(baseUrl: 'http://127.0.0.1:4190/v1'))
      ..httpClientAdapter = _PhotoAdapter()
      ..interceptors.add(
        InterceptorsWrapper(
          onResponse: (response, handler) {
            (rewrite ?? (r) => rewriteBrowserMediaResponse(r, _apiBase))(
              response,
            );
            handler.next(response);
          },
        ),
      );

ProviderContainer _container(Dio api) {
  final container = ProviderContainer(
    overrides: [
      authNotifierProvider.overrideWith(_Auth.new),
      apiClientProvider.overrideWithValue(api),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

const _key = (user: 'me', theme: 't1', entry: 'e1');

const _entry = ThemeEntry(
  id: 'e1',
  themeId: 't1',
  authorId: 'author',
  authorName: 'Priya',
  caption: 'Pancakes, then nowhere to be.',
  altText: 'A stack of pancakes on a balcony table',
  mine: false,
);

void main() {
  test(
    'a theme photo survives the web response rewrite byte for byte',
    () async {
      final container = _container(_webApi());
      final sub = container.listen(themeEntryPhotoProvider(_key), (_, _) {});
      addTearDown(sub.close);
      final bytes = await container.read(themeEntryPhotoProvider(_key).future);
      expect(bytes, _png);
    },
  );

  test('JSON media links are still routed through the same origin', () async {
    final response = await _webApi().get<dynamic>('/profile/me');
    expect(
      (response.data as Map)['photo_url'],
      'http://127.0.0.1:4190/v1/media/approved/me/a.jpg',
    );
  });

  test('the old rewrite of byte bodies broke the photo request', () async {
    // What the web client used to do to every response body.
    final container = _container(
      _webApi(
        rewrite: (r) => r.data = r.data is List
            ? (r.data as List).map((item) => item).toList()
            : r.data,
      ),
    );
    final sub = container.listen(themeEntryPhotoProvider(_key), (_, _) {});
    addTearDown(sub.close);
    await expectLater(
      container.read(themeEntryPhotoProvider(_key).future),
      throwsA(isA<DioException>()),
    );
  });

  testWidgets('the cover shows the member photo, not the placeholder', (
    t,
  ) async {
    await t.runAsync(() async {
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(_Auth.new),
            apiClientProvider.overrideWithValue(_webApi()),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SizedBox(
              width: 300,
              height: 400,
              child: PhotoCoverImage(entry: _entry),
            ),
          ),
        ),
      );
      // The adapter answers on real I/O timers.
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await t.pump();
    final image = t.widget<Image>(find.byType(Image));
    expect(image.image, isA<MemoryImage>());
    expect((image.image as MemoryImage).bytes, _png);
    expect(
      find.byKey(const ValueKey('photo.cover.placeholder.e1')),
      findsNothing,
    );
  });
}
