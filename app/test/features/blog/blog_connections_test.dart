import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/blog/blog_connections.dart';
import 'package:verified_dating_app/features/blog/blog_data.dart';
import 'package:verified_dating_app/features/blog/blog_sharing.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

class Auth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(isAuthenticated: true, userId: 'me');
  void change() =>
      state = const AuthState(isAuthenticated: true, userId: 'someone-else');
}

class Api {
  final writes = <RequestOptions>[];
  bool fail = false;
  Map<String, dynamic> response = {
    'id': 'exchange',
    'post_id': 'post',
    'partner_name': 'Alex',
    'partner_id': 'alex',
    'text': 'A private hello',
    'status': 'accepted',
    'incoming': true,
    'my_story': 'My words',
    'partner_story': '',
    'revealed': false,
    'version': 3,
    'can_plan': false,
    'can_joint_share': false,
  };
  Dio get dio => Dio()
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (r, h) {
          if (r.method != 'GET') {
            writes.add(r);
            if (fail) {
              h.reject(
                DioException(
                  requestOptions: r,
                  response: Response<dynamic>(
                    requestOptions: r,
                    statusCode: 409,
                    data: {
                      'error': 'The source changed. Your words are still here.',
                    },
                  ),
                ),
              );
              return;
            }
          }
          h.resolve(
            Response<dynamic>(
              requestOptions: r,
              statusCode: 200,
              data: {
                'response': response,
                'publication': {'id': 'link'},
                'publications': <dynamic>[],
                'notices': <dynamic>[],
                'responses': <dynamic>[],
              },
            ),
          );
        },
      ),
    );
}

BlogPost post() => BlogPost.fromJson({
  'id': 'post',
  'author_id': 'me',
  'author_name': 'Me',
  'title': 'A little Sunday',
  'body': 'Coffee and a bookshop.',
  'audience': 'community',
  'invitation': 'your_version',
  'version': 1,
  'photos': <dynamic>[],
});
Widget host(Api api, Widget screen, {double scale = 1}) => ProviderScope(
  overrides: [
    authNotifierProvider.overrideWith(Auth.new),
    apiClientProvider.overrideWithValue(api.dio),
  ],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: screen,
  ),
);
Future<void> tap(WidgetTester t, Finder finder) async {
  await t.scrollUntilVisible(
    finder,
    220,
    scrollable: find.byType(Scrollable).first,
  );
  await t.ensureVisible(finder);
  await t.pumpAndSettle();
  await t.tap(finder);
  await t.pumpAndSettle();
}

void main() {
  test('public links use the public page contract', () {
    final url = Uri.parse(blogShareUrl('public-id'));
    expect(url.path, '/story.html');
    expect(url.queryParameters, {'id': 'public-id'});
  });
  testWidgets('public copy requires unchecked explicit consent', (t) async {
    final api = Api();
    await t.pumpWidget(host(api, BlogShareScreen(post: post())));
    await t.pumpAndSettle();
    await t.scrollUntilVisible(
      find.text('Create public link'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      t
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Create public link'),
          )
          .onPressed,
      isNull,
    );
    expect(api.writes, isEmpty);
    await tap(t, find.text('I approve this exact public copy'));
    await tap(t, find.text('Create public link'));
    expect(api.writes.single.data['approved'], true);
    expect(api.writes.single.data['photo_ids'], isEmpty);
    expect(api.writes.single.data['excerpt'], post().body);
    expect(find.text('Your public copy is ready.'), findsOneWidget);
  });
  testWidgets('editing a preview clears consent', (t) async {
    final api = Api();
    await t.pumpWidget(host(api, BlogShareScreen(post: post())));
    await t.pumpAndSettle();
    await tap(t, find.text('I approve this exact public copy'));
    await t.ensureVisible(find.byType(TextField));
    await t.enterText(find.byType(TextField), 'Coffee');
    await t.pumpAndSettle();
    expect(
      t.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
      false,
    );
    expect(api.writes, isEmpty);
  });
  testWidgets('failed share retains exact preview without a false success', (
    t,
  ) async {
    final api = Api()..fail = true;
    await t.pumpWidget(host(api, BlogShareScreen(post: post())));
    await t.pumpAndSettle();
    await tap(t, find.text('I approve this exact public copy'));
    await tap(t, find.text('Create public link'));
    expect(find.text('Your public copy is ready.'), findsNothing);
    expect(find.textContaining('source changed'), findsOneWidget);
    expect(
      t.widget<TextField>(find.byType(TextField)).controller!.text,
      post().body,
    );
  });
  testWidgets('joint preview shows both exact contributions but no live link', (
    t,
  ) async {
    final api = Api();
    await t.pumpWidget(
      host(
        api,
        BlogShareScreen(
          post: post(),
          exchange: {
            'id': 'exchange',
            'incoming': true,
            'my_story': 'One voice',
            'partner_story': 'Another voice',
          },
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('One voice\n\nAnother voice'), findsOneWidget);
    await tap(t, find.text('I approve this exact public copy'));
    await tap(t, find.text('Request the other author’s approval'));
    expect(api.writes.single.data['response_id'], 'exchange');
    expect(find.text('Copy public link'), findsNothing);
    expect(find.textContaining('stays unavailable'), findsOneWidget);
  });
  testWidgets('exchange waiting state hides partner text and planning', (
    t,
  ) async {
    final api = Api();
    await t.pumpWidget(host(api, const BlogExchangeScreen(id: 'exchange')));
    await t.pumpAndSettle();
    expect(find.text('My words'), findsOneWidget);
    expect(find.text('Shape a date together'), findsNothing);
    expect(api.writes, isEmpty);
    await t.pumpWidget(const SizedBox());
  });
  testWidgets(
    'response error preserves text and retries with the same command ID',
    (t) async {
      final api = Api()..fail = true;
      await t.pumpWidget(
        host(
          api,
          const BlogTextCommandScreen(
            title: 'Response',
            help: 'Only the author can read this.',
            label: 'Send private response',
            path: '/blog/responses',
            payload: {'post_id': 'post'},
            maxLength: 600,
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField), 'A thoughtful hello');
      await tap(t, find.text('Send private response'));
      await tap(t, find.text('Send private response'));
      expect(api.writes.length, 2);
      expect(api.writes[0].data['id'], api.writes[1].data['id']);
      expect(
        t.widget<TextField>(find.byType(TextField)).controller!.text,
        'A thoughtful hello',
      );
    },
  );
  testWidgets('account switch clears the sharing surface', (t) async {
    final api = Api();
    await t.pumpWidget(host(api, BlogShareScreen(post: post())));
    await t.pumpAndSettle();
    final container = ProviderScope.containerOf(
      t.element(find.byType(BlogShareScreen)),
    );
    (container.read(authNotifierProvider.notifier) as Auth).change();
    await t.pumpAndSettle();
    expect(find.text('A little Sunday'), findsNothing);
    expect(find.text('Sign in again to continue.'), findsOneWidget);
    expect(api.writes, isEmpty);
  });
  testWidgets('sharing and connections fit 320px at large text', (t) async {
    t.view.physicalSize = const Size(320, 740);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final api = Api();
    await t.pumpWidget(host(api, BlogShareScreen(post: post()), scale: 1.6));
    await t.pumpAndSettle();
    await tap(t, find.text('I approve this exact public copy'));
    expect(t.takeException(), isNull);
    await t.pumpWidget(host(api, const BlogConnectionsScreen(), scale: 1.6));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  });
}
