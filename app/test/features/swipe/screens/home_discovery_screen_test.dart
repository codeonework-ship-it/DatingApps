import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/engagement/providers/daily_prompt_provider.dart';
import 'package:verified_dating_app/features/swipe/models/discovery_profile.dart';
import 'package:verified_dating_app/features/swipe/providers/swipe_provider.dart';
import 'package:verified_dating_app/features/swipe/screens/home_discovery_screen.dart';

DiscoveryProfile _buildSpotlightProfile() => DiscoveryProfile(
  id: 'rail-user',
  name: 'Rail User',
  dateOfBirth: DateTime(1998, 3, 12),
  bio: 'Spotlight profile',
  additionalInfo: null,
  profession: 'Engineer',
  education: null,
  instagramHandle: null,
  hobbies: const <String>[],
  favoriteSongs: const <String>[],
  extraCurriculars: const <String>[],
  intentTags: const <String>[],
  languageTags: const <String>[],
  isVerified: true,
  photoUrls: const <String>[],
  isSpotlight: true,
  spotlightTier: 'gold',
  spotlightScore: 92,
  spotlightReason: 'paid_plus_activity',
);

class _FakeSwipeNotifier extends SwipeNotifier {
  @override
  SwipeState build() => SwipeState(
      isLoading: false,
      profiles: <DiscoveryProfile>[],
      spotlightProfiles: <DiscoveryProfile>[_buildSpotlightProfile()],
      discoveryMode: SwipeNotifier.discoveryModeAll,
    );

  @override
  Future<void> setDiscoveryMode(String mode) async {
    final normalized =
        mode.trim().toLowerCase() == SwipeNotifier.discoveryModeSpotlight
        ? SwipeNotifier.discoveryModeSpotlight
        : SwipeNotifier.discoveryModeAll;
    state = state.copyWith(discoveryMode: normalized, currentIndex: 0);
  }
}

class _FakeDailyPromptNotifier extends DailyPromptNotifier {
  _FakeDailyPromptNotifier(super.ref);

  @override
  Future<void> load() async {
    state = const DailyPromptState();
  }
}

void main() {
  testWidgets('renders spotlight rail safely with empty photo list', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          swipeNotifierProvider.overrideWith(_FakeSwipeNotifier.new),
          dailyPromptProvider.overrideWith(_FakeDailyPromptNotifier.new),
        ],
        child: const MaterialApp(home: HomeDiscoveryScreen()),
      ),
    );

    await tester.pump();

    expect(find.text('Find meaningful verified matches'), findsOneWidget);
    expect(find.text('No profiles'), findsOneWidget);
    expect(find.text('Spotlight'), findsOneWidget);
    expect(find.text('Rail User'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
