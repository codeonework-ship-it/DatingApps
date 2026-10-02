import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/runtime_feature_flags_provider.dart';
import 'package:verified_dating_app/features/engagement/providers/daily_prompt_provider.dart';
import 'package:verified_dating_app/features/swipe/discover_l10n.dart';
import 'package:verified_dating_app/features/swipe/models/discovery_profile.dart';
import 'package:verified_dating_app/features/swipe/providers/curated_daily_set_provider.dart';
import 'package:verified_dating_app/features/swipe/providers/liked_me_provider.dart';
import 'package:verified_dating_app/features/swipe/providers/swipe_provider.dart';
import 'package:verified_dating_app/features/swipe/screens/home_discovery_screen.dart';
import 'package:verified_dating_app/features/swipe/screens/liked_me_screen.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

DiscoveryProfile _profile(String id, String name) => DiscoveryProfile(
  id: id,
  name: name,
  dateOfBirth: null,
  publicAge: 27,
  bio: 'Likes long walks',
  additionalInfo: null,
  profession: 'Architect',
  education: null,
  instagramHandle: null,
  hobbies: const <String>[],
  favoriteSongs: const <String>[],
  extraCurriculars: const <String>[],
  intentTags: const <String>[],
  languageTags: const <String>[],
  isVerified: true,
  photoUrls: const <String>[],
);

class _FakeLikedMeNotifier extends LikedMeNotifier {
  _FakeLikedMeNotifier(super.ref, this.initial);

  final List<LikedMeEntry> initial;

  @override
  Future<void> load() async {
    state = LikedMeState(entries: initial, count: initial.length);
  }
}

class _FakeSwipeNotifier extends SwipeNotifier {
  @override
  SwipeState build() => const SwipeState(
    isLoading: false,
    profiles: <DiscoveryProfile>[],
    spotlightProfiles: <DiscoveryProfile>[],
    discoveryMode: SwipeNotifier.discoveryModeAll,
  );
}

class _FakeDailyPromptNotifier extends DailyPromptNotifier {
  _FakeDailyPromptNotifier(super.ref);

  @override
  Future<void> load() async {
    state = const DailyPromptState();
  }
}

class _FakeCuratedNotifier extends CuratedDailySetNotifier {
  _FakeCuratedNotifier(super.ref);

  @override
  Future<void> load() async {
    state = const CuratedDailySetState();
  }
}

void main() {
  final entries = [
    LikedMeEntry(
      profile: _profile('liker-1', 'Asha'),
      likedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    LikedMeEntry(
      profile: _profile('liker-2', 'Bina'),
      likedAt: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
  ];

  Widget app(Widget home, {Locale locale = const Locale('de')}) =>
      ProviderScope(
        overrides: [
          swipeNotifierProvider.overrideWith(_FakeSwipeNotifier.new),
          dailyPromptProvider.overrideWith(_FakeDailyPromptNotifier.new),
          curatedDailySetProvider.overrideWith(_FakeCuratedNotifier.new),
          likedMeProvider.overrideWith(
            (ref) => _FakeLikedMeNotifier(ref, entries),
          ),
          runtimeFeatureFlagsProvider.overrideWith(
            (ref) => Stream.value(RuntimeFeatureFlags.defaults),
          ),
        ],
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      );

  testWidgets('who liked me renders in German', (tester) async {
    await tester.pumpWidget(app(const LikedMeScreen()));
    await tester.pump();

    expect(find.text('Haben dich geliked · 2'), findsOneWidget);
    expect(find.text('Hat dich vor 5 Minuten geliked'), findsOneWidget);
    expect(find.text('Hat dich vor 2 Stunden geliked'), findsOneWidget);
    expect(find.text('Zurückliken'), findsNWidgets(2));
    expect(find.text('Überspringen'), findsNWidgets(2));
    expect(find.text('Like back'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('who liked me uses Russian plural forms', (tester) async {
    await tester.pumpWidget(
      app(const LikedMeScreen(), locale: const Locale('ru')),
    );
    await tester.pump();

    expect(find.text('Лайкнул(а) тебя 5 минут назад'), findsOneWidget);
    expect(find.text('Лайкнул(а) тебя 2 часа назад'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('discover deck, empty state and notifications render in German', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(app(const HomeDiscoveryScreen(browseOnly: true)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Matches entdecken'), findsOneWidget);
    expect(find.text('FÜR DICH AUSGEWÄHLT'), findsOneWidget);
    expect(find.text('Keine Profile'), findsOneWidget);
    expect(find.text('Aktualisieren'), findsOneWidget);
    expect(find.text('Filter'), findsOneWidget);
    expect(find.text('Nachrichten'), findsOneWidget);
    expect(find.text('Discover Matches'), findsNothing);

    await tester.tap(find.byIcon(Icons.notifications_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Neueste ungelesene Benachrichtigungen'), findsOneWidget);
    expect(find.text('Wer mich geliked hat'), findsOneWidget);
    expect(find.text('2 neue Likes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('known provider fallbacks are localised, server text is kept', (
    tester,
  ) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(
      localizeDiscoverMessage(l10n, DiscoverMessages.loadProfiles),
      'Profile konnten nicht geladen werden. Bitte versuch es noch einmal.',
    );
    expect(localizeDiscoverMessage(l10n, 'Server said no'), 'Server said no');
  });
}
