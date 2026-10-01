import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/blog/blog_data.dart';
import 'package:verified_dating_app/features/blog/blog_editor.dart';
import 'package:verified_dating_app/features/blog/blog_screen.dart';

class _Auth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(isAuthenticated: true, userId: 'me');
  void switchUser() {
    state = const AuthState(isAuthenticated: true, userId: 'someone-else');
  }
}

class _Api {
  final writes = <RequestOptions>[];
  final reads = <RequestOptions>[];
  bool conflict = false;
  Map<String, dynamic> saved = {
    'id': 'chapter',
    'author_id': 'me',
    'author_name': 'Alex',
    'title': 'Remote title',
    'body': 'Remote text',
    'audience': 'private',
    'invitation': '',
    'version': 1,
    'photos': <dynamic>[],
  };
  Dio get dio => Dio()
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (r, h) {
          if (r.method == 'PUT') {
            writes.add(r);
            if (conflict) {
              h.reject(
                DioException(
                  requestOptions: r,
                  response: Response<dynamic>(
                    requestOptions: r,
                    statusCode: 409,
                    data: {'error': 'This chapter changed.'},
                  ),
                ),
              );
              return;
            }
            saved = {
              ...saved,
              ...Map<String, dynamic>.from(r.data as Map),
              'id': r.path.split('/').last,
              'version': (r.data['expected_version'] as int) + 1,
            };
          } else {
            reads.add(r);
          }
          h.resolve(
            Response<dynamic>(
              requestOptions: r,
              statusCode: 200,
              data: r.path == '/blog/posts'
                  ? {'posts': <dynamic>[], 'next_cursor': ''}
                  : {'post': saved},
            ),
          );
        },
      ),
    );
}

Widget host(_Api api, {Widget child = const BlogEditor(), double scale = 1}) =>
    ProviderScope(
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

Future<void> write(WidgetTester t) async {
  await t.enterText(
    find.widgetWithText(TextField, 'Chapter title'),
    'The smallest adventure',
  );
  await t.enterText(
    find.widgetWithText(TextField, 'Your story'),
    'A quiet coffee and a book.',
  );
}

void main() {
  testWidgets('draft defaults private and preview does not write', (t) async {
    final api = _Api();
    await t.pumpWidget(host(api));
    await t.pumpAndSettle();
    await write(t);
    await tapVisible(t, find.text('Preview'));
    expect(api.writes, isEmpty);
    expect(find.text('Preview · Only me · Not yet saved'), findsOneWidget);
    await tapVisible(t, find.byKey(const ValueKey('blog.save')));
    expect(api.writes.single.data['audience'], 'private');
    expect(api.writes.single.data['expected_version'], 0);
  });
  testWidgets('community publication requires explicit confirmation', (
    t,
  ) async {
    final api = _Api();
    await t.pumpWidget(host(api));
    await t.pumpAndSettle();
    await write(t);
    await tapVisible(t, find.widgetWithText(ChoiceChip, 'Connect community'));
    await tapVisible(t, find.byKey(const ValueKey('blog.save')));
    expect(api.writes, isEmpty);
    await t.tap(find.text('Cancel'));
    await t.pumpAndSettle();
    expect(api.writes, isEmpty);
    await tapVisible(t, find.byKey(const ValueKey('blog.save')));
    await t.tap(find.widgetWithText(FilledButton, 'Publish chapter'));
    await t.pumpAndSettle();
    expect(api.writes.single.data['audience'], 'community');
  });
  testWidgets('allow featuring is offered for community only and is sent', (
    t,
  ) async {
    final api = _Api();
    await t.pumpWidget(host(api));
    await t.pumpAndSettle();
    await write(t);
    expect(find.byKey(const ValueKey('blog.allow_featuring')), findsNothing);
    await tapVisible(t, find.byKey(const ValueKey('blog.save')));
    expect(api.writes.last.data['allow_featuring'], false);
    await tapVisible(t, find.widgetWithText(ChoiceChip, 'Connect community'));
    expect(
      find.textContaining('100 likes and 10 comments reach 100.'),
      findsOneWidget,
    );
    await tapVisible(t, find.byKey(const ValueKey('blog.allow_featuring')));
    await tapVisible(t, find.byKey(const ValueKey('blog.save')));
    await t.tap(find.widgetWithText(FilledButton, 'Publish chapter'));
    await t.pumpAndSettle();
    expect(api.writes.last.data['audience'], 'community');
    expect(api.writes.last.data['allow_featuring'], true);
    await tapVisible(t, find.widgetWithText(ChoiceChip, 'Friends'));
    await tapVisible(t, find.byKey(const ValueKey('blog.save')));
    await t.tap(find.widgetWithText(FilledButton, 'Publish chapter'));
    await t.pumpAndSettle();
    expect(api.writes.last.data['audience'], 'friends');
    expect(api.writes.last.data['allow_featuring'], false);
  });
  testWidgets('stale save retains edits and reload is deliberate', (t) async {
    final api = _Api()..conflict = true;
    await t.pumpWidget(
      host(api, child: BlogEditor(initial: BlogPost.fromJson(api.saved))),
    );
    await t.pumpAndSettle();
    await write(t);
    await tapVisible(t, find.byKey(const ValueKey('blog.save')));
    await tapVisible(t, find.text('Check saved version'));
    expect(find.text('Remote text'), findsOneWidget);
    expect(
      t
          .widget<TextField>(find.widgetWithText(TextField, 'Your story'))
          .controller!
          .text,
      'A quiet coffee and a book.',
    );
    await tapVisible(t, find.text('Use saved version'));
    expect(
      t
          .widget<TextField>(find.widgetWithText(TextField, 'Your story'))
          .controller!
          .text,
      'Remote text',
    );
  });
  testWidgets('editor hides private text on account change', (t) async {
    final api = _Api();
    await t.pumpWidget(
      host(api, child: BlogEditor(initial: BlogPost.fromJson(api.saved))),
    );
    await t.pumpAndSettle();
    final container = ProviderScope.containerOf(
      t.element(find.byType(BlogEditor)),
    );
    (container.read(authNotifierProvider.notifier) as _Auth).switchUser();
    await t.pumpAndSettle();
    expect(find.text('Remote text'), findsNothing);
    expect(
      find.text('Sign in as the author to edit this chapter.'),
      findsOneWidget,
    );
  });
  testWidgets(
    'feed starts with For you and scope tabs send the correct scope',
    (t) async {
      final api = _Api();
      await t.pumpWidget(host(api, child: const BlogScreen()));
      await t.pumpAndSettle();
      List<String?> scopes() => [
        for (final r in api.reads)
          if (r.path == '/blog/posts') r.queryParameters['scope'] as String?,
      ];
      expect(scopes().last, 'community');
      await tapVisible(t, find.widgetWithText(ChoiceChip, 'Mine'));
      expect(scopes().last, 'mine');
      await tapVisible(t, find.widgetWithText(ChoiceChip, 'Friends'));
      expect(scopes().last, 'friends');
      expect(find.text('A little quiet here, for now.'), findsOneWidget);
    },
  );
  testWidgets('narrow editor supports large text without overflow', (t) async {
    t.view.physicalSize = const Size(320, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(host(_Api(), scale: 1.6));
    await t.pumpAndSettle();
    await tapVisible(t, find.widgetWithText(ChoiceChip, 'Friends'));
    expect(t.takeException(), isNull);
    await tapVisible(t, find.byKey(const ValueKey('blog.save')));
    expect(t.takeException(), isNull);
  });
}
