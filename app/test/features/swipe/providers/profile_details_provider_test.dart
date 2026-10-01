import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/features/swipe/providers/profile_details_provider.dart';

void main() {
  test(
    'renders published rich attributes without requesting a private draft',
    () async {
      final requests = <String>[];
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            requests.add(options.path);
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'found': true,
                  'profile': {
                    'id': 'member',
                    'name': 'Published member',
                    'date_of_birth': '1998-03-01',
                    'gender': 'F',
                    'bio': 'Published biography',
                    'hobbies': ['Reading'],
                    'is_verified': false,
                    'photoUrls': ['approved-photo'],
                  },
                },
              ),
            );
          },
        ),
      );
      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(dio)],
      );
      addTearDown(container.dispose);
      final profile = await container.read(
        profileDetailsProvider('member').future,
      );
      expect(profile.name, 'Published member');
      expect(profile.hobbies, ['Reading']);
      expect(profile.photoUrls, ['approved-photo']);
      expect(profile.isVerified, isFalse);
      expect(requests, ['/profile/member']);
    },
  );

  for (final status in [401, 403, 404, 503]) {
    test('HTTP $status remains an error instead of a mock member', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.badResponse,
                response: Response(requestOptions: options, statusCode: status),
              ),
            );
          },
        ),
      );
      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(dio)],
      );
      addTearDown(container.dispose);
      await expectLater(
        container.read(profileDetailsProvider('member').future),
        throwsA(isA<DioException>()),
      );
    });
  }

  test(
    'an empty or not-found response cannot fabricate profile details',
    () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {'found': false, 'profile': <String, dynamic>{}},
              ),
            );
          },
        ),
      );
      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(dio)],
      );
      addTearDown(container.dispose);
      await expectLater(
        container.read(profileDetailsProvider('member').future),
        throwsStateError,
      );
    },
  );
}
