import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/core/theme/app_theme.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/celebrations/celebrations_data.dart';
import 'package:verified_dating_app/features/celebrations/rose_rain.dart';

class _Auth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(
    userId: 'author-1',
    isAuthenticated: true,
    username: 'author_one',
  );
}

const _celebration = WallCelebration(
  id: 'c-1',
  kind: 'chapter',
  contentId: 'post-1',
  tier: 1,
  reach: 50,
  title: 'The bookshop that smelled like rain',
);

Finder _petalPainters() => find.byWidgetPredicate(
  (w) =>
      w is CustomPaint &&
      w.painter != null &&
      w.painter.runtimeType.toString() == '_RoseRainPainter',
);

Widget _host(Widget child, {bool reduceMotion = false}) => MaterialApp(
  theme: AppTheme.lightTheme,
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: child,
  ),
);

void main() {
  test('parses a celebration and builds its headline', () {
    final c = WallCelebration.fromJson(const {
      'id': 'c-2',
      'kind': 'photo',
      'content_id': 'entry-1',
      'theme_id': 'theme-1',
      'tier': 2,
      'reach': 100,
      'title': 'Golden hour',
    });
    expect(c.isPhoto, isTrue);
    expect(c.themeId, 'theme-1');
    expect(c.headline, 'Your photo reached 100 walls');
    expect(
      WallCelebration.fromJson(const {'id': 'x', 'content_id': 'y'}).kind,
      'chapter',
    );
  });

  testWidgets('plays the petal shower with the tier card', (tester) async {
    await tester.pumpWidget(
      _host(const RoseRainOverlay(celebration: _celebration)),
    );
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.text('Your chapter reached 50 walls'), findsOneWidget);
    expect(find.text('“The bookshop that smelled like rain”'), findsOneWidget);
    expect(_petalPainters(), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('reduced motion shows the card without petals', (tester) async {
    await tester.pumpWidget(
      _host(
        const RoseRainOverlay(celebration: _celebration),
        reduceMotion: true,
      ),
    );
    await tester.pump();
    expect(find.text('Your chapter reached 50 walls'), findsOneWidget);
    expect(_petalPainters(), findsNothing);
  });

  testWidgets('the host plays each celebration once and marks it seen', (
    tester,
  ) async {
    final seen = <String>[];
    var listed = 0;
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.method == 'POST') {
              seen.add(options.path);
              return handler.resolve(
                Response<dynamic>(
                  requestOptions: options,
                  statusCode: 200,
                  data: <String, dynamic>{'seen': true},
                ),
              );
            }
            listed++;
            return handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: <String, dynamic>{
                  'celebrations': listed == 1
                      ? [
                          {
                            'id': 'c-1',
                            'kind': 'chapter',
                            'content_id': 'post-1',
                            'tier': 1,
                            'reach': 50,
                            'title': 'A story',
                          },
                        ]
                      : <Object>[],
                },
              ),
            );
          },
        ),
      );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(dio),
          authNotifierProvider.overrideWith(_Auth.new),
        ],
        child: _host(
          const Scaffold(body: Stack(children: [RoseRainHost()])),
          reduceMotion: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Your chapter reached 50 walls'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('qa.rose_rain.close')));
    await tester.pumpAndSettle();
    expect(find.text('Your chapter reached 50 walls'), findsNothing);
    expect(seen, ['/walls/celebrations/c-1/seen']);
  });
}
