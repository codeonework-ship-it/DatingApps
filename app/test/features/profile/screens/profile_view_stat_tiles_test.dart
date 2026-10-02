import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/core/theme/app_theme.dart';
import 'package:verified_dating_app/features/common/screens/main_navigation_screen.dart';
import 'package:verified_dating_app/features/matching/screens/matches_list_screen.dart';
import 'package:verified_dating_app/features/profile/screens/profile_view_screen.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

/// Regression: the Matches and Messages tiles on My Profile had no tap
/// handler, so tapping them did nothing. They must open the Matches tab on
/// the matching sub-view.
void main() {
  Future<ProviderContainer> pumpProfile(WidgetTester tester) async {
    tester.view.physicalSize = const Size(600, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) => handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: <String, dynamic>{},
            ),
          ),
        ),
      );
    final container = ProviderContainer(
      overrides: [apiClientProvider.overrideWithValue(dio)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ProfileViewScreen(),
        ),
      ),
    );
    await tester.pump();
    return container;
  }

  testWidgets('Matches tile opens the Matches tab on Your matches '
      '[case:profile.profile_view.matches.action]', (tester) async {
    final container = await pumpProfile(tester);
    container.read(mainNavigationIndexProvider.notifier).state = 3;

    // The tiles sit behind the scenes, under the cinematic hero.
    await tester.ensureVisible(find.text('Matches'));
    await tester.pump();
    await tester.tap(find.text('Matches'));
    await tester.pump();

    expect(container.read(mainNavigationIndexProvider), 1);
    expect(container.read(matchesViewProvider), MatchesView.people);
  });

  testWidgets('Messages tile opens the Matches tab on Conversations '
      '[case:profile.profile_view.messages.action]', (tester) async {
    final container = await pumpProfile(tester);
    container.read(mainNavigationIndexProvider.notifier).state = 3;

    await tester.ensureVisible(find.text('Messages'));
    await tester.pump();
    await tester.tap(find.text('Messages'));
    await tester.pump();

    expect(container.read(mainNavigationIndexProvider), 1);
    expect(container.read(matchesViewProvider), MatchesView.conversations);
  });
}
