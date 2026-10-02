import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/core/theme/theme_presets.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/graduation/providers/graduation_provider.dart';
import 'package:verified_dating_app/features/intentional_dating/dating_rhythm.dart';
import 'package:verified_dating_app/features/intentional_dating/profile_stories.dart';
import 'package:verified_dating_app/features/intentional_dating/today_introductions.dart';
import 'package:verified_dating_app/features/swipe/providers/curated_daily_set_provider.dart';

// AND-10: pull-to-refresh on Today reloaded the wall, cover and introductions
// but not the "Your story" card, so a story published elsewhere kept showing
// "Tell a little more of your story" until the editor was opened and closed.

class _Auth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(isAuthenticated: true, userId: 'me');
}

class _Daily extends CuratedDailySetNotifier {
  _Daily(super.ref);
  @override
  Future<void> load() async {
    if (mounted) state = const CuratedDailySetState();
  }
}

class _Pause extends DiscoveryPauseNotifier {
  _Pause(super.ref);
  @override
  Future<void> load() async {
    state = const DiscoveryPauseState(loaded: true, paused: false);
  }
}

/// Every other Today request (wall, cover, activities) answers empty.
Dio _emptyApi() => Dio()
  ..interceptors.add(
    InterceptorsWrapper(
      onRequest: (r, h) => h.resolve(
        Response<dynamic>(
          requestOptions: r,
          statusCode: 200,
          data: <String, dynamic>{},
        ),
      ),
    ),
  );

void main() {
  testWidgets('pull-to-refresh on Today reloads the Your story count', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    var published = 0;
    var loads = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith(_Auth.new),
          apiClientProvider.overrideWithValue(_emptyApi()),
          curatedDailySetProvider.overrideWith(_Daily.new),
          datingRhythmProvider.overrideWith((ref) async => {}),
          discoveryPauseProvider.overrideWith(_Pause.new),
          profileStoriesProvider.overrideWith((ref, user) async {
            loads++;
            return {
              'stories': [
                for (var i = 0; i < published; i++)
                  {'prompt_id': 'little_joy', 'text': 'Market coffee'},
              ],
            };
          }),
        ],
        child: MaterialApp(
          theme: ThemePresets.themeFor(ThemePresets.realLife),
          home: TodayIntroductions(onOpenProfile: (_) {}, onBrowse: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tell a little more of your story'), findsOneWidget);
    final before = loads;

    // A story is published from somewhere else, then the member pulls down.
    published = 1;
    // The same callback the pull gesture runs (RefreshIndicator.onRefresh).
    final refreshed = tester
        .state<RefreshIndicatorState>(find.byType(RefreshIndicator))
        .show();
    await tester.pumpAndSettle();
    await refreshed;
    await tester.pumpAndSettle();

    expect(loads, greaterThan(before));
    expect(find.text('1 of 3 stories shared'), findsOneWidget);
    expect(find.text('Write your first story'), findsNothing);
  });
}
