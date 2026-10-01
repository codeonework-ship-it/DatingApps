import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/runtime_feature_flags_provider.dart';
import 'package:verified_dating_app/features/engagement/providers/daily_prompt_provider.dart';
import 'package:verified_dating_app/features/swipe/models/discovery_profile.dart';
import 'package:verified_dating_app/features/swipe/providers/curated_daily_set_provider.dart';
import 'package:verified_dating_app/features/swipe/providers/swipe_provider.dart';
import 'package:verified_dating_app/features/swipe/screens/home_discovery_screen.dart';

DiscoveryProfile _pick(String id, String name, List<String> reasons) =>
    DiscoveryProfile(
      id: id,
      name: name,
      dateOfBirth: DateTime(1997, 6, 1),
      bio: 'Curated pick',
      additionalInfo: null,
      profession: 'Designer',
      education: null,
      instagramHandle: null,
      hobbies: const <String>[],
      favoriteSongs: const <String>[],
      extraCurriculars: const <String>[],
      intentTags: const <String>['long_term'],
      languageTags: const <String>['English'],
      isVerified: true,
      photoUrls: const <String>[],
      reasons: reasons,
      why: 'Picked for you today: ${reasons.join(' · ')}',
    );

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
  _FakeCuratedNotifier(super.ref, this.profiles);

  final List<DiscoveryProfile> profiles;

  @override
  Future<void> load() async {
    state = CuratedDailySetState(profiles: profiles, setDate: '2026-09-27');
  }
}

Widget _app({
  required List<DiscoveryProfile> picks,
  Map<String, bool> flags = const <String, bool>{},
}) => ProviderScope(
  overrides: [
    swipeNotifierProvider.overrideWith(_FakeSwipeNotifier.new),
    dailyPromptProvider.overrideWith(_FakeDailyPromptNotifier.new),
    curatedDailySetProvider.overrideWith(
      (ref) => _FakeCuratedNotifier(ref, picks),
    ),
    runtimeFeatureFlagsProvider.overrideWith(
      (ref) => Stream.value(
        RuntimeFeatureFlags(<String, bool>{
          ...RuntimeFeatureFlags.defaults.values,
          'intentional_dating_enabled': false,
          ...flags,
        }),
      ),
    ),
  ],
  child: const MaterialApp(home: HomeDiscoveryScreen()),
);

void main() {
  final picks = <DiscoveryProfile>[
    _pick('today-1', 'Asha', const <String>[
      'Shares your intent',
      'Verified & active',
      'Shows up',
    ]),
    _pick('today-2', 'Bina', const <String>['Both reply within a day']),
    _pick('today-3', 'Chitra', const <String>[]),
  ];

  testWidgets('renders the Today rail with reason chips', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(picks: picks));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.byKey(const ValueKey('qa.discover.today.rail')),
      findsOneWidget,
    );
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('3 picks'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('qa.discover.today.card.0')),
      findsOneWidget,
    );
    expect(find.text('Shares your intent'), findsOneWidget);
    expect(find.text('Verified & active'), findsOneWidget);
    // A card shows at most two reason chips.
    expect(find.text('Shows up'), findsNothing);
    expect(
      find.byKey(const ValueKey('qa.discover.today.reason.0.1')),
      findsOneWidget,
    );
    expect(find.text('Both reply within a day'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hides the rail when the runtime flag is off', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(
        picks: picks,
        flags: const <String, bool>{'curated_daily_set_enabled': false},
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const ValueKey('qa.discover.today.rail')), findsNothing);
    expect(find.text('Shares your intent'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hides the rail when there are no picks', (tester) async {
    await tester.pumpWidget(_app(picks: const <DiscoveryProfile>[]));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const ValueKey('qa.discover.today.rail')), findsNothing);
    expect(find.text('No profiles'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
