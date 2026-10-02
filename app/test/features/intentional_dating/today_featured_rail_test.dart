import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/blog/blog_screen.dart';
import 'package:verified_dating_app/features/blog/blog_social.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

class _Auth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(isAuthenticated: true, userId: 'me');
}

Map<String, dynamic> featured(int i) => {
  'id': 'f$i',
  'author_id': 'author$i',
  'author_name': 'Writer $i',
  'title': 'Featured chapter $i',
  'body': 'A story people loved.',
  'audience': 'community',
  'invitation': '',
  'version': 1,
  'photos': <dynamic>[],
  'like_count': 10 + i,
  'liked_by_me': false,
  'comment_count': 2,
  'pending_comment_count': 0,
  'allow_featuring': true,
  'featured': true,
};

/// [featuredStatus] other than 200 makes `/blog/featured` fail.
({Dio dio, List<String> paths}) fakeApi({
  List<Map<String, dynamic>> posts = const [],
  int featuredStatus = 200,
}) {
  final paths = <String>[];
  final dio = Dio()
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (r, h) {
          paths.add(r.path);
          if (r.path == '/blog/featured' && featuredStatus != 200) {
            h.reject(
              DioException(
                requestOptions: r,
                response: Response<dynamic>(
                  requestOptions: r,
                  statusCode: featuredStatus,
                  data: {'error': 'Featured Stories are unavailable.'},
                ),
              ),
            );
            return;
          }
          final Object data;
          if (r.path == '/blog/featured') {
            data = {'posts': posts};
          } else if (r.path.endsWith('/comments')) {
            data = {'comments': <dynamic>[]};
          } else if (r.path.startsWith('/blog/posts/')) {
            data = {'post': featured(0)..['id'] = r.path.split('/').last};
          } else {
            data = <String, dynamic>{};
          }
          h.resolve(
            Response<dynamic>(requestOptions: r, statusCode: 200, data: data),
          );
        },
      ),
    );
  return (dio: dio, paths: paths);
}

/// The compact rail as it used to sit on Today. Today now shows these
/// chapters in its mixed wall carousel (see today_wall_test.dart); the rail
/// itself still serves the Blog screen.
Widget host(Dio dio) => ProviderScope(
  overrides: [
    authNotifierProvider.overrideWith(_Auth.new),
    apiClientProvider.overrideWithValue(dio),
  ],
  child: const MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: BlogFeaturedRail(
          title: 'On your wall',
          caption: 'Stories other members loved',
          limit: 5,
          compact: true,
        ),
      ),
    ),
  ),
);

Finder cards() => find.byWidgetPredicate(
  (w) =>
      w.key is ValueKey<String> &&
      (w.key! as ValueKey<String>).value.startsWith('blog.featured.'),
);

void main() {
  testWidgets('shows up to five featured cards', (t) async {
    final api = fakeApi(posts: [for (var i = 1; i <= 7; i++) featured(i)]);
    await t.pumpWidget(host(api.dio));
    await t.pumpAndSettle();
    expect(find.text('On your wall'), findsOneWidget);
    expect(find.text('Stories other members loved'), findsOneWidget);
    expect(cards(), findsNWidgets(5));
    expect(find.text('Featured chapter 1'), findsOneWidget);
    expect(find.text('by Writer 1'), findsOneWidget);
    expect(find.text('11'), findsOneWidget);
    expect(find.text('Featured'), findsNWidgets(5));
    expect(find.text('Featured chapter 6'), findsNothing);
    expect(t.takeException(), isNull);

    await t.tap(find.text('Featured chapter 1'));
    await t.pumpAndSettle();
    expect(find.byType(BlogDetailScreen), findsOneWidget);
    expect(api.paths, contains('/blog/posts/f1'));
  });

  testWidgets('renders nothing for an empty wall', (t) async {
    final api = fakeApi();
    await t.pumpWidget(host(api.dio));
    await t.pumpAndSettle();
    expect(api.paths, contains('/blog/featured'));
    expect(find.byKey(const ValueKey('blog.featured_rail')), findsNothing);
    expect(find.text('On your wall'), findsNothing);
    expect(cards(), findsNothing);
  });

  testWidgets('a failing request is silent', (t) async {
    final api = fakeApi(posts: [featured(1)], featuredStatus: 500);
    await t.pumpWidget(host(api.dio));
    await t.pumpAndSettle();
    expect(api.paths, contains('/blog/featured'));
    expect(find.byKey(const ValueKey('blog.featured_rail')), findsNothing);
    expect(find.text('On your wall'), findsNothing);
    expect(find.textContaining('unavailable'), findsNothing);
    expect(find.text('Try again'), findsNothing);
    expect(t.takeException(), isNull);
  });
}
