import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/intentional_dating/profile_stories.dart';

class _Auth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(isAuthenticated: true, userId: 'me');
}

class _Api {
  final List<Map<String, dynamic>> saves = [];
  Map<String, dynamic> saved = {
    'stories': <dynamic>[],
    'published': false,
    'version': 0,
    'photos': <dynamic>[],
  };
  bool reject = false;
  Dio get dio => Dio()
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (r, h) {
          if (r.method == 'PUT') {
            saves.add(Map<String, dynamic>.from(r.data as Map));
            if (reject) {
              h.reject(
                DioException(
                  requestOptions: r,
                  response: Response<dynamic>(
                    requestOptions: r,
                    statusCode: 409,
                    data: {'error': 'Stories changed. Reload before saving.'},
                  ),
                ),
              );
              return;
            }
            saved = {
              ...saved,
              ...saves.last,
              'version': (saved['version'] as int) + 1,
            };
          }
          h.resolve(
            Response<dynamic>(requestOptions: r, statusCode: 200, data: saved),
          );
        },
      ),
    );
}

Widget host(
  _Api api, {
  Widget child = const ProfileStoriesScreen(),
  double scale = 1,
}) => ProviderScope(
  overrides: [
    authNotifierProvider.overrideWith(_Auth.new),
    apiClientProvider.overrideWithValue(api.dio),
  ],
  child: MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: child,
  ),
);
Future<void> tapVisible(WidgetTester t, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    t.state<ScrollableState>(find.byType(Scrollable).first).position.jumpTo(0);
    await t.pumpAndSettle();
    await t.scrollUntilVisible(
      finder,
      250,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await t.ensureVisible(finder);
  await t.pumpAndSettle();
  await t.tap(finder);
  await t.pumpAndSettle();
}

void main() {
  testWidgets(
    'private by default; preview is not publication; explicit publish then hide',
    (t) async {
      final api = _Api();
      await t.pumpWidget(host(api));
      await t.pumpAndSettle();
      expect(
        t
            .widget<SwitchListTile>(
              find.byKey(const ValueKey('qa.stories.publish')),
            )
            .value,
        isFalse,
      );
      await tapVisible(t, find.byKey(const ValueKey('qa.stories.add')));
      await t.enterText(
        find.byType(TextFormField).first,
        'My Sunday ritual is coffee and a novel.',
      );
      await tapVisible(t, find.text('Preview my stories'));
      expect(find.text('PREVIEW · THIS DOES NOT PUBLISH'), findsOneWidget);
      expect(api.saves, isEmpty);
      await tapVisible(t, find.byKey(const ValueKey('qa.stories.save')));
      expect(api.saves.single['published'], false);
      expect(api.saves.single['expected_version'], 0);
      await tapVisible(t, find.byKey(const ValueKey('qa.stories.publish')));
      await tapVisible(t, find.byKey(const ValueKey('qa.stories.save')));
      expect(api.saves.last['published'], true);
      expect(api.saves.last['expected_version'], 1);
      await tapVisible(t, find.byKey(const ValueKey('qa.stories.publish')));
      await tapVisible(t, find.byKey(const ValueKey('qa.stories.save')));
      expect(api.saves.last['published'], false);
      expect(api.saves.last['expected_version'], 2);
    },
  );
  testWidgets('unfinished preview cannot bypass validation', (t) async {
    final api = _Api();
    await t.pumpWidget(host(api));
    await t.pumpAndSettle();
    await tapVisible(t, find.byKey(const ValueKey('qa.stories.add')));
    await tapVisible(t, find.text('Preview my stories'));
    await tapVisible(t, find.byKey(const ValueKey('qa.stories.save')));
    expect(api.saves, isEmpty);
    expect(find.byType(TextFormField), findsOneWidget);
  });
  testWidgets('stale saves retain edits and offer explicit reload', (t) async {
    final api = _Api()..reject = true;
    await t.pumpWidget(host(api));
    await t.pumpAndSettle();
    await tapVisible(t, find.byKey(const ValueKey('qa.stories.add')));
    await t.enterText(
      find.byType(TextFormField).first,
      'Keep my unsaved words',
    );
    await tapVisible(t, find.byKey(const ValueKey('qa.stories.save')));
    expect(find.text('Keep my unsaved words'), findsOneWidget);
    expect(find.text('Reload saved stories · discard edits'), findsOneWidget);
  });
  testWidgets('selected photo requires an accessible description', (t) async {
    final api = _Api();
    api.saved = {
      'version': 0,
      'published': false,
      'stories': [
        {
          'prompt_id': 'little_joy',
          'text': 'Reading outside',
          'photo_id': 'photo',
          'photo_description': '',
        },
      ],
      'photos': [
        {'id': 'photo', 'url': 'https://example.test/photo.jpg'},
      ],
    };
    await t.pumpWidget(host(api));
    await t.pumpAndSettle();
    await tapVisible(t, find.byKey(const ValueKey('qa.stories.save')));
    expect(api.saves, isEmpty);
    await t.enterText(
      find.widgetWithText(TextFormField, 'Describe this photo'),
      'A novel on a picnic blanket',
    );
    await tapVisible(t, find.byKey(const ValueKey('qa.stories.save')));
    expect(
      api.saves.single['stories'][0]['photo_description'],
      'A novel on a picnic blanket',
    );
  });
  for (final width in [390.0, 768.0, 1440.0]) {
    testWidgets('story editor fits width $width with enlarged text', (t) async {
      t.view.physicalSize = Size(width, 1100);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final api = _Api();
      await t.pumpWidget(host(api, scale: 2));
      await t.pumpAndSettle();
      await tapVisible(t, find.byKey(const ValueKey('qa.stories.add')));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });
  }
  testWidgets('private stories render no public section', (t) async {
    await t.pumpWidget(
      host(
        _Api(),
        child: const Scaffold(body: ProfileStoriesSection(userId: 'them')),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('A little more me'), findsNothing);
  });
}
