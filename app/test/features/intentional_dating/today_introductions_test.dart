import 'package:dio/dio.dart';
import 'package:verified_dating_app/core/providers/api_client_provider.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:verified_dating_app/core/theme/theme_presets.dart';
import 'package:verified_dating_app/features/graduation/providers/graduation_provider.dart';
import 'package:verified_dating_app/features/intentional_dating/dating_rhythm.dart';
import 'package:verified_dating_app/features/intentional_dating/today_introductions.dart';
import 'package:verified_dating_app/features/swipe/models/discovery_profile.dart';
import 'package:verified_dating_app/features/swipe/providers/curated_daily_set_provider.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

class _Daily extends CuratedDailySetNotifier {
  _Daily(super.ref, this.initial);
  final CuratedDailySetState initial;
  @override
  Future<void> load() async {
    if (mounted) state = initial;
  }
}

class _Pause extends DiscoveryPauseNotifier {
  _Pause(super.ref, this.isPaused);
  final bool isPaused;
  @override
  Future<void> load() async {
    state = DiscoveryPauseState(loaded: true, paused: isPaused);
  }
}

DiscoveryProfile pick(String id, String activity) => DiscoveryProfile(
  id: id,
  name: id,
  dateOfBirth: null,
  publicAge: 29,
  bio: 'A real introduction with a human story.',
  additionalInfo: null,
  profession: 'Designer',
  education: null,
  instagramHandle: null,
  hobbies: const [],
  favoriteSongs: const [],
  extraCurriculars: const [],
  intentTags: const [],
  languageTags: const [],
  isVerified: true,
  photoUrls: const [],
  sharedActivities: [activity],
  reasons: const ['A similar communication pace'],
);

Widget host({
  CuratedDailySetState? daily,
  bool paused = false,
  double scale = 1,
  ValueChanged<DiscoveryProfile>? open,
  VoidCallback? browse,
  Locale? locale,
}) => ProviderScope(
  overrides: [
    curatedDailySetProvider.overrideWith(
      (ref) => _Daily(
        ref,
        daily ??
            CuratedDailySetState(
              profiles: [pick('Maya', 'coffee'), pick('Sam', 'walk')],
            ),
      ),
    ),
    datingRhythmProvider.overrideWith((ref) async => {}),
    discoveryPauseProvider.overrideWith((ref) => _Pause(ref, paused)),
  ],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: locale,
    theme: ThemePresets.themeFor(ThemePresets.realLife),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: TodayIntroductions(
      onOpenProfile: open ?? (_) {},
      onBrowse: browse ?? () {},
    ),
  ),
);

class _Auth extends AuthNotifier {
  @override
  AuthState build() => const AuthState(isAuthenticated: true, userId: 'me');
}

void main() {
  test(
    'Changing discovery filters reloads the curated request with those filters',
    () async {
      final queries = <Map<String, dynamic>>[];
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (r, h) {
              queries.add(Map.of(r.queryParameters));
              h.resolve(
                Response<dynamic>(
                  requestOptions: r,
                  statusCode: 200,
                  data: {'candidates': <dynamic>[]},
                ),
              );
            },
          ),
        );
      final container = ProviderContainer(
        overrides: [
          authNotifierProvider.overrideWith(_Auth.new),
          apiClientProvider.overrideWithValue(dio),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        curatedDailySetProvider,
        (_, __) {},
      );
      addTearDown(subscription.close);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      container.read(curatedDiscoveryFiltersProvider.notifier).state = {
        'age_min': '28',
        'age_max': '36',
      };
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(queries.last, {'age_min': '28', 'age_max': '36'});
    },
  );
  for (final width in [390.0, 768.0, 1440.0]) {
    testWidgets(
      'Today fits $width with large text and operable introductions',
      (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        String? opened;
        await tester.pumpWidget(host(scale: 2, open: (p) => opened = p.id));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final button = find.byKey(const ValueKey('qa.today.profile.Maya'));
        await tester.ensureVisible(button);
        await tester.pumpAndSettle();
        await tester.tap(button);
        expect(opened, 'Maya');
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'Activity filters use real shared preferences and can be cleared',
    (tester) async {
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      final filter = find.byKey(const ValueKey('qa.today.activity.coffee'));
      await tester.ensureVisible(filter);
      await tester.tap(filter);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('qa.today.profile.Maya')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('qa.today.profile.Sam')), findsNothing);
      await tester.tap(find.text('All introductions'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('qa.today.profile.Sam')),
        findsOneWidget,
      );
    },
  );
  testWidgets('Pause hides cached introductions', (tester) async {
    await tester.pumpWidget(host(paused: true));
    await tester.pumpAndSettle();
    expect(find.text('Take the time you need.'), findsOneWidget);
    expect(find.byKey(const ValueKey('qa.today.profile.Maya')), findsNothing);
  });
  testWidgets('Failed refresh hides cached profiles and offers retry', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        daily: CuratedDailySetState(
          profiles: [pick('Maya', 'coffee')],
          error: 'unavailable',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Try again'), findsOneWidget);
    expect(find.byKey(const ValueKey('qa.today.profile.Maya')), findsNothing);
  });
  testWidgets('Today speaks German for a German member', (tester) async {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(host(locale: const Locale('de')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('HEUTE'), findsOneWidget);
    expect(
      find.text(DateFormat.MMMMEEEEd('de').format(DateTime.now())),
      findsOneWidget,
    );
    expect(
      find.text('Ein kleines Hallo.\nRaum für etwas Echtes.'),
      findsOneWidget,
    );
    expect(find.text('DEIN TEMPO'), findsOneWidget);
    expect(find.text('Deinen Rhythmus festlegen'), findsOneWidget);
    expect(find.text('HEUTIGE VORSTELLUNGEN'), findsOneWidget);
    expect(find.text('Alle Vorstellungen'), findsOneWidget);
    expect(find.text('Kaffee'), findsOneWidget);
    expect(find.text('Maya kennenlernen'), findsOneWidget);
    expect(
      find.text('Ein erstes Hallo könnte ein gemeinsamer Kaffee sein.'),
      findsOneWidget,
    );
    expect(find.text('TODAY'), findsNothing);
    expect(find.text('Meet Maya'), findsNothing);
  });
  testWidgets('Empty pool gives a useful next step', (tester) async {
    bool browsed = false;
    await tester.pumpWidget(
      host(daily: const CuratedDailySetState(), browse: () => browsed = true),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Explore profiles'));
    await tester.tap(find.text('Explore profiles'));
    expect(browsed, isTrue);
  });
}
