@Tags(<String>['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/providers/runtime_feature_flags_provider.dart';
import 'package:verified_dating_app/core/theme/app_theme.dart';
import 'package:verified_dating_app/features/engagement/providers/daily_prompt_provider.dart';
import 'package:verified_dating_app/features/profile/providers/profile_setup_provider.dart';
import 'package:verified_dating_app/features/profile/screens/setup/setup_about_screen.dart';
import 'package:verified_dating_app/features/swipe/models/discovery_profile.dart';
import 'package:verified_dating_app/features/swipe/providers/swipe_provider.dart';
import 'package:verified_dating_app/features/auth/screens/welcome_screen.dart';
import 'package:verified_dating_app/features/swipe/screens/home_discovery_screen.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

class _FakeProfileSetupNotifier extends ProfileSetupNotifier {
  _FakeProfileSetupNotifier(this.initialDraft);

  final ProfileDraft initialDraft;

  @override
  Future<ProfileDraft> build() async => initialDraft;
}

class _FakeSwipeNotifier extends SwipeNotifier {
  _FakeSwipeNotifier(this._state);

  final SwipeState _state;

  @override
  SwipeState build() => _state;
}

class _FakeDailyPromptNotifier extends DailyPromptNotifier {
  _FakeDailyPromptNotifier(super.ref) : super();

  @override
  Future<void> load() async {
    state = const DailyPromptState(isLoading: false);
  }
}

ProfileDraft _draft({String name = 'Asha', DateTime? dob}) => ProfileDraft(
  userId: 'user-1',
  phoneNumber: '+919999999999',
  name: name,
  dateOfBirth: dob,
  gender: 'M',
  photos: const <ProfilePhotoItem>[],
  bio: '',
  heightCm: null,
  education: null,
  profession: null,
  incomeRange: null,
  seekingGenders: const <String>['F'],
  minAgeYears: 21,
  maxAgeYears: 40,
  maxDistanceKm: 50,
  educationFilter: const <String>[],
  seriousOnly: true,
  verifiedOnly: false,
  country: null,
  regionState: null,
  city: null,
  instagramHandle: null,
  hobbies: const <String>[],
  favoriteBooks: const <String>[],
  favoriteNovels: const <String>[],
  favoriteSongs: const <String>[],
  extraCurriculars: const <String>[],
  additionalInfo: null,
  intentTags: const <String>[],
  languageTags: const <String>[],
  petPreference: null,
  dietPreference: null,
  workoutFrequency: null,
  dietType: null,
  sleepSchedule: null,
  travelStyle: null,
  politicalComfortRange: null,
  dealBreakerTags: const <String>[],
  drinking: 'Never',
  smoking: 'Never',
  religion: null,
  motherTongue: null,
  hookupOnly: false,
);

Widget _setupApp(ProfileDraft draft) => ProviderScope(
  overrides: [
    profileSetupNotifierProvider.overrideWith(
      () => _FakeProfileSetupNotifier(draft),
    ),
  ],
  child: MaterialApp(
    theme: AppTheme.lightTheme,
    home: const SetupAboutScreen(isSetupFlow: true),
  ),
);

Widget _welcomeApp() => MaterialApp(
  theme: AppTheme.lightTheme,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: const WelcomeScreen(),
);

Widget _discoverApp() => ProviderScope(
  overrides: [
    swipeNotifierProvider.overrideWith(
      () => _FakeSwipeNotifier(
        const SwipeState(profiles: <DiscoveryProfile>[], isLoading: false),
      ),
    ),
    dailyPromptProvider.overrideWith(_FakeDailyPromptNotifier.new),
    // The screen reads runtime flags for the curated rail; keep the golden
    // fixture offline.
    runtimeFeatureFlagsProvider.overrideWith(
      (ref) => Stream.value(RuntimeFeatureFlags.defaults),
    ),
  ],
  child: MaterialApp(
    theme: AppTheme.lightTheme,
    home: const HomeDiscoveryScreen(),
  ),
);

void main() {
  Future<void> pumpUi(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
  }

  Future<void> setViewport(WidgetTester tester, Size logicalSize) async {
    tester.view.physicalSize = logicalSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  testWidgets('discover phone golden has no overflow', (tester) async {
    await setViewport(tester, const Size(360, 780));
    await tester.pumpWidget(_discoverApp());
    await pumpUi(tester);

    expect(find.text('Messages'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(HomeDiscoveryScreen),
      matchesGoldenFile('goldens/discover_phone.png'),
    );
  });

  testWidgets('discover tablet golden has no overflow', (tester) async {
    await setViewport(tester, const Size(1024, 1366));
    await tester.pumpWidget(_discoverApp());
    await pumpUi(tester);

    expect(find.text('Messages'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byType(HomeDiscoveryScreen),
      matchesGoldenFile('goldens/discover_tablet.png'),
    );
  });

  // ==========================================================================
  // Device matrix
  // ==========================================================================
  //
  // Golden files pin one phone and one tablet. They say nothing about the
  // sizes where layouts actually break: the smallest phone still in support,
  // the tallest phone, and a tablet in portrait. Overflow is asserted rather
  // than compared to a reference image, so these stay valid across restyles.

  const devices = <String, Size>{
    'small phone (320x568)': Size(320, 568),
    'phone (360x780)': Size(360, 780),
    'large phone (430x932)': Size(430, 932),
    'tablet portrait (768x1024)': Size(768, 1024),
    'tablet landscape (1024x1366)': Size(1024, 1366),
  };

  devices.forEach((label, size) {
    testWidgets('cover lays out without overflow on $label', (tester) async {
      await setViewport(tester, size);
      await tester.pumpWidget(_welcomeApp());
      await pumpUi(tester);
      expect(tester.takeException(), isNull, reason: 'overflow on $label');
    });

    testWidgets('setup about lays out without overflow on \$label', (
      tester,
    ) async {
      await setViewport(tester, size);
      await tester.pumpWidget(_setupApp(_draft(name: 'Asha')));
      await pumpUi(tester);
      expect(tester.takeException(), isNull, reason: 'overflow on $label');
    });

    testWidgets('discover lays out without overflow on $label', (tester) async {
      await setViewport(tester, size);
      await tester.pumpWidget(_discoverApp());
      await pumpUi(tester);
      expect(tester.takeException(), isNull, reason: 'overflow on $label');
    });
  });

  // The smallest supported phone with accessibility text turned up is where
  // fixed-height rows clip first.
  testWidgets('cover survives large text on the smallest phone', (
    tester,
  ) async {
    await setViewport(tester, const Size(320, 568));
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: _welcomeApp(),
      ),
    );
    await pumpUi(tester);
    expect(tester.takeException(), isNull);
  });
}
