import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/runtime_feature_flags_provider.dart';
import 'package:verified_dating_app/features/engagement/providers/daily_prompt_provider.dart';
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
  _FakeLikedMeNotifier(super.ref, this.initial, {this.matchIds = const {}});

  final List<LikedMeEntry> initial;

  /// Member id -> match id returned when liking that member back.
  final Map<String, String> matchIds;
  final List<(String, bool)> answers = <(String, bool)>[];

  @override
  Future<void> load() async {
    state = LikedMeState(entries: initial, count: initial.length);
  }

  @override
  Future<LikedMeAnswer> answer(
    DiscoveryProfile profile, {
    required bool like,
  }) async {
    answers.add((profile.id, like));
    state = state.copyWith(
      entries: state.entries.where((e) => e.profile.id != profile.id).toList(),
      count: state.count - 1,
    );
    return LikedMeAnswer(matchId: like ? matchIds[profile.id] : null);
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
  final asha = LikedMeEntry(
    profile: _profile('liker-1', 'Asha'),
    likedAt: DateTime.now().subtract(const Duration(hours: 2)),
  );
  final bina = LikedMeEntry(
    profile: _profile('liker-2', 'Bina'),
    likedAt: DateTime.now().subtract(const Duration(minutes: 5)),
  );

  late _FakeLikedMeNotifier fake;

  Widget screen(List<LikedMeEntry> entries, {Map<String, String>? matches}) =>
      ProviderScope(
        overrides: [
          swipeNotifierProvider.overrideWith(_FakeSwipeNotifier.new),
          likedMeProvider.overrideWith(
            (ref) => fake = _FakeLikedMeNotifier(
              ref,
              entries,
              matchIds: matches ?? const {},
            ),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: LikedMeScreen(),
        ),
      );

  testWidgets('lists everyone waiting on an answer', (tester) async {
    await tester.pumpWidget(screen([bina, asha]));
    await tester.pump();

    expect(find.text('Liked you · 2'), findsOneWidget);
    expect(find.text('Bina, 27'), findsOneWidget);
    expect(find.text('Asha, 27'), findsOneWidget);
    expect(find.text('Liked you 5 minutes ago'), findsOneWidget);
    expect(find.text('Liked you 2 hours ago'), findsOneWidget);
    expect(find.text('Architect'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('liking back a match opens the match screen', (tester) async {
    await tester.pumpWidget(screen([asha], matches: {'liker-1': 'match-1'}));
    await tester.pump();

    await tester.tap(
      find.byKey(const ValueKey('qa.liked_me.like_back.liker-1')),
    );
    await tester.pumpAndSettle();

    expect(fake.answers, [('liker-1', true)]);
    expect(find.text("It's a match!"), findsOneWidget);
    expect(find.text('You and Asha liked each other'), findsOneWidget);
    // The avatars load over the network, which widget tests refuse.
    tester.takeException();
  });

  testWidgets('passing removes the member without a match', (tester) async {
    await tester.pumpWidget(screen([bina, asha]));
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('qa.liked_me.pass.liker-2')));
    await tester.pump();

    expect(fake.answers, [('liker-2', false)]);
    expect(find.text('Bina, 27'), findsNothing);
    expect(find.text('Asha, 27'), findsOneWidget);
    expect(find.text('Liked you · 1'), findsOneWidget);
    expect(find.text('Passed on Bina'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows an empty state when nobody is waiting', (tester) async {
    await tester.pumpWidget(screen(const []));
    await tester.pump();

    expect(find.text('Liked you'), findsOneWidget);
    expect(find.text('No new likes yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the Discover notification opens who liked me', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          swipeNotifierProvider.overrideWith(_FakeSwipeNotifier.new),
          dailyPromptProvider.overrideWith(_FakeDailyPromptNotifier.new),
          curatedDailySetProvider.overrideWith(_FakeCuratedNotifier.new),
          likedMeProvider.overrideWith(
            (ref) => fake = _FakeLikedMeNotifier(ref, [bina, asha]),
          ),
          runtimeFeatureFlagsProvider.overrideWith(
            (ref) => Stream.value(RuntimeFeatureFlags.defaults),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HomeDiscoveryScreen(browseOnly: true),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byIcon(Icons.notifications_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Who has liked me'), findsOneWidget);
    expect(find.text('2 new likes'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('qa.discovery.notification.who_liked_me')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LikedMeScreen), findsOneWidget);
    expect(find.text('Liked you · 2'), findsOneWidget);
    expect(find.text('Latest unread notifications'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
