import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/engagement/providers/daily_prompt_provider.dart';
import 'package:verified_dating_app/features/swipe/models/discovery_profile.dart';
import 'package:verified_dating_app/features/swipe/providers/swipe_provider.dart';
import 'package:verified_dating_app/features/swipe/screens/home_discovery_screen.dart';
import 'package:verified_dating_app/features/swipe/widgets/swipe_card.dart';

// ---------------------------------------------------------------------------
// Fake notifiers
// ---------------------------------------------------------------------------
class _FakeSwipeNotifierError extends SwipeNotifier {
  @override
  SwipeState build() => const SwipeState(
    isLoading: false,
    profiles: <DiscoveryProfile>[],
    spotlightProfiles: <DiscoveryProfile>[],
    error: 'Failed to load profiles. Please try again.',
  );

  @override
  Future<void> refreshProfiles() async {
    state = state.copyWith(error: null, isLoading: true);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    state = state.copyWith(isLoading: false, profiles: [_mockProfile()]);
  }
}

class _FakeSwipeNotifierLoading extends SwipeNotifier {
  @override
  SwipeState build() => const SwipeState(isLoading: true);
}

class _FakeSwipeNotifierEmpty extends SwipeNotifier {
  @override
  SwipeState build() => const SwipeState(
    isLoading: false,
    profiles: <DiscoveryProfile>[],
    spotlightProfiles: <DiscoveryProfile>[],
  );

  @override
  Future<void> refreshProfiles() async {}
}

class _FakeSwipeNotifierWithProfiles extends SwipeNotifier {
  @override
  SwipeState build() => SwipeState(
    isLoading: false,
    profiles: <DiscoveryProfile>[_mockProfile()],
    spotlightProfiles: <DiscoveryProfile>[],
  );
}

class _FakeSwipeNotifierAllReviewed extends SwipeNotifier {
  @override
  SwipeState build() => SwipeState(
    isLoading: false,
    profiles: <DiscoveryProfile>[_mockProfile()],
    spotlightProfiles: <DiscoveryProfile>[],
    currentIndex: 1,
  );
}

class _FakeSwipeNotifierTrustFiltered extends SwipeNotifier {
  @override
  SwipeState build() => const SwipeState(
    isLoading: false,
    profiles: <DiscoveryProfile>[],
    spotlightProfiles: <DiscoveryProfile>[],
    trustFilterActive: true,
    trustFilteredOutCount: 5,
  );

  @override
  Future<void> refreshProfiles() async {}
}

class _FakeDailyPromptNotifier extends DailyPromptNotifier {
  _FakeDailyPromptNotifier(super.ref);

  @override
  Future<void> load() async {
    state = const DailyPromptState();
  }
}

DiscoveryProfile _mockProfile() => DiscoveryProfile(
  id: 'user-1',
  name: 'Test User',
  dateOfBirth: DateTime(1997, 5, 15),
  bio: 'A valid bio for testing',
  additionalInfo: null,
  profession: 'Designer',
  education: "Bachelor's",
  instagramHandle: null,
  hobbies: const <String>['Reading'],
  favoriteSongs: const <String>[],
  extraCurriculars: const <String>[],
  intentTags: const <String>['serious'],
  languageTags: const <String>['English'],
  isVerified: true,
  photoUrls: const <String>[],
);

Widget _buildApp<T extends SwipeNotifier>(T Function() createNotifier) =>
    ProviderScope(
      overrides: [
        swipeNotifierProvider.overrideWith(createNotifier),
        dailyPromptProvider.overrideWith(_FakeDailyPromptNotifier.new),
      ],
      child: const MaterialApp(home: HomeDiscoveryScreen()),
    );

void main() {
  group('HomeDiscoveryScreen error states', () {
    testWidgets('shows error state when profiles fail to load', (tester) async {
      await tester.pumpWidget(_buildApp(_FakeSwipeNotifierError.new));
      await tester.pump();

      expect(find.text('Unable to load profiles'), findsOneWidget);
      expect(
        find.text('Failed to load profiles. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('shows loading indicator during profile fetch', (tester) async {
      await tester.pumpWidget(_buildApp(_FakeSwipeNotifierLoading.new));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state with refresh button when no profiles', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(_FakeSwipeNotifierEmpty.new));
      await tester.pump();

      expect(find.text('No profiles'), findsOneWidget);
      expect(find.text('Refresh'), findsOneWidget);
    });

    testWidgets(
      'shows all-reviewed state when currentIndex >= profiles.length',
      (tester) async {
        await tester.pumpWidget(_buildApp(_FakeSwipeNotifierAllReviewed.new));
        await tester.pump();

        expect(find.text('All reviewed!'), findsOneWidget);
      },
    );

    testWidgets('shows trust filter info when filters hide profiles', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(_FakeSwipeNotifierTrustFiltered.new));
      await tester.pump();

      expect(
        find.textContaining('Trust filters hid 5 profile(s)'),
        findsOneWidget,
      );
    });

    testWidgets('renders profile card when profiles are available', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_buildApp(_FakeSwipeNotifierWithProfiles.new));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // The screen should NOT show an error or empty state
      expect(find.text('Unable to load profiles'), findsNothing);
      expect(find.text('No profiles nearby'), findsNothing);
      // A SwipeCard should be present in the tree
      expect(find.byType(SwipeCard), findsOneWidget);
    });

    testWidgets('renders header with Discover Matches title', (tester) async {
      await tester.pumpWidget(_buildApp(_FakeSwipeNotifierEmpty.new));
      await tester.pump();

      expect(find.text('Discover Matches'), findsOneWidget);
      expect(find.text('Find meaningful verified matches'), findsOneWidget);
    });

    testWidgets('no overflow errors on compact viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_buildApp(_FakeSwipeNotifierEmpty.new));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('no overflow errors on tablet viewport', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_buildApp(_FakeSwipeNotifierEmpty.new));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
