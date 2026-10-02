import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/core/theme/theme_presets.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/profile/widgets/profile_showcase.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

class _Auth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(isAuthenticated: true, userId: 'me');
}

class _Api {
  _Api({required this.enabled, this.chapters = const []});
  bool enabled;
  final List<Map<String, Object?>> chapters;
  final puts = <Object?>[];

  Dio get dio => Dio()
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (r, h) {
          Object? data;
          if (r.path.endsWith('/showcase/consent')) {
            if (r.method == 'PUT') {
              puts.add(r.data);
              enabled = (r.data as Map)['visible'] == true;
            }
            data = {'visible': enabled};
          } else if (r.path.endsWith('/showcase')) {
            data = {'enabled': enabled, 'chapters': chapters, 'photos': []};
          }
          h.resolve(Response(requestOptions: r, statusCode: 200, data: data));
        },
      ),
    );
}

const chapter = {
  'id': 'c1',
  'title': 'Slow Sundays',
  'excerpt': 'Coffee, a long walk and a market.',
  'published_at': '2026-09-30T10:00:00Z',
  'like_count': 4,
  'comment_count': 1,
};

Widget host(_Api api, Widget child) => ProviderScope(
  overrides: [
    authNotifierProvider.overrideWith(_Auth.new),
    apiClientProvider.overrideWithValue(api.dio),
  ],
  child: MaterialApp(
    theme: ThemePresets.themeFor(ThemePresets.realLife),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  ),
);

void main() {
  testWidgets('another member without consent shows nothing', (tester) async {
    final api = _Api(enabled: false, chapters: [chapter]);
    await tester.pumpWidget(
      host(api, const ProfileShowcaseScene(userId: 'them')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('qa.profile.showcase')), findsNothing);
    expect(find.text('Slow Sundays'), findsNothing);
  });

  testWidgets('another member with consent shows public chapters and a '
      'link to all of them', (tester) async {
    final api = _Api(enabled: true, chapters: [chapter]);
    await tester.pumpWidget(
      host(api, const ProfileShowcaseScene(userId: 'them')),
    );
    await tester.pumpAndSettle();
    expect(find.text('In their own words'), findsOneWidget);
    expect(find.text('Slow Sundays'), findsOneWidget);
    expect(find.text('Coffee, a long walk and a market.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('qa.profile.showcase.read_all')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('qa.profile.showcase.consent')),
      findsNothing,
    );
  });

  testWidgets('consent on but nothing public shows nothing', (tester) async {
    await tester.pumpWidget(
      host(_Api(enabled: true), const ProfileShowcaseScene(userId: 'them')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('qa.profile.showcase')), findsNothing);
  });

  testWidgets('the owner previews it privately and can turn it on', (
    tester,
  ) async {
    final api = _Api(enabled: false, chapters: [chapter]);
    await tester.pumpWidget(
      host(api, const ProfileShowcaseScene(userId: 'me', isOwner: true)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Only you can see this'), findsOneWidget);
    expect(find.text('Slow Sundays'), findsOneWidget);
    final toggle = find.byKey(const ValueKey('qa.profile.showcase.consent'));
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);

    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(api.puts, [
      {'visible': true},
    ]);
    expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
    expect(find.text('Show on my profile'), findsOneWidget);
    // The owner's own preview never links to "all their chapters".
    expect(
      find.byKey(const ValueKey('qa.profile.showcase.read_all')),
      findsNothing,
    );
  });
}
