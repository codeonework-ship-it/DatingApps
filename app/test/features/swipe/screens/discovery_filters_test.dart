import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verified_dating_app/core/providers/runtime_feature_flags_provider.dart';
import 'package:verified_dating_app/features/common/screens/main_navigation_screen.dart';
import 'package:verified_dating_app/features/engagement/providers/billing_coexistence_provider.dart';
import 'package:verified_dating_app/features/engagement/providers/daily_prompt_provider.dart';
import 'package:verified_dating_app/features/matching/providers/match_provider.dart';
import 'package:verified_dating_app/features/matching/providers/trust_filter_provider.dart';
import 'package:verified_dating_app/features/notifications/providers/notification_provider.dart';
import 'package:verified_dating_app/features/profile/providers/preference_master_data_provider.dart';
import 'package:verified_dating_app/features/profile/providers/profile_setup_provider.dart';
import 'package:verified_dating_app/features/swipe/providers/swipe_provider.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

class _Swipe extends SwipeNotifier {
  Map<String, String> filters = {};
  int refreshes = 0;
  @override
  SwipeState build() => const SwipeState();
  @override
  void setManualFilters(Map<String, String> value) {
    filters = Map.of(value);
  }

  @override
  Future<void> refreshProfiles() async {
    refreshes++;
  }
}

class _Matches extends MatchNotifier {
  @override
  MatchState build() => const MatchState();
  @override
  Future<void> refresh() async {}
}

class _Draft extends ProfileSetupNotifier {
  _Draft(this.initial);
  final ProfileDraft initial;
  @override
  Future<ProfileDraft> build() async => initial;
}

class _Prompt extends DailyPromptNotifier {
  _Prompt(super.ref);
  @override
  Future<void> load() async {}
}

class _Notifications extends NotificationNotifier {
  _Notifications(super.ref);
  @override
  Future<void> bootstrap() async {}
}

class _Trust extends TrustFilterNotifier {
  _Trust(super.ref);
  bool fail = false;
  @override
  Future<void> load() async {}
  @override
  Future<void> save({
    required bool enabled,
    required int minimumActiveBadges,
    required List<String> requiredBadgeCodes,
  }) async {
    state = state.copyWith(
      enabled: enabled,
      minimumActiveBadges: minimumActiveBadges,
      requiredBadgeCodes: requiredBadgeCodes,
      error: fail ? 'QA trust save failed' : null,
      clearError: !fail,
    );
  }

  void rebuild() {
    state = state.copyWith();
  }
}

ProfileDraft _draft() => ProfileDraft(
  userId: 'user-1',
  phoneNumber: '+919999999999',
  name: 'Ananya',
  dateOfBirth: DateTime(1998, 6, 20),
  gender: 'F',
  photos: const <ProfilePhotoItem>[
    ProfilePhotoItem(
      id: 'p1',
      photoUrl: 'https://example.com/p1.jpg',
      storagePath: '',
      ordering: 0,
    ),
    ProfilePhotoItem(
      id: 'p2',
      photoUrl: 'https://example.com/p2.jpg',
      storagePath: '',
      ordering: 1,
    ),
  ],
  bio: 'This is a sufficiently long bio for tests.',
  heightCm: null,
  education: null,
  profession: null,
  incomeRange: null,
  seekingGenders: const <String>['M', 'F'],
  minAgeYears: 21,
  maxAgeYears: 40,
  maxDistanceKm: 50,
  educationFilter: const <String>[],
  seriousOnly: true,
  verifiedOnly: false,
  country: 'India',
  regionState: 'Karnataka',
  city: 'Bengaluru',
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
  religion: 'Hindu',
  motherTongue: 'Kannada',
  hookupOnly: false,
);

final _master = PreferenceMasterData.fromJson({
  'countries': ['India', 'Canada'],
  'states_by_country': {
    'India': ['Karnataka', 'Maharashtra'],
    'Canada': ['Ontario'],
  },
  'cities_by_state': {
    'Karnataka': ['Bengaluru'],
    'Maharashtra': ['Mumbai'],
    'Ontario': ['Toronto'],
  },
  'religions': ['Hindu', 'Buddhist'],
  'mother_tongues': ['Kannada', 'Hindi'],
});

Finder key(String suffix) => find.byKey(ValueKey('qa.filters.$suffix'));
Future<void> press(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> dropdown(WidgetTester tester, String label, String? value) async {
  await press(tester, key('${label}_dropdown'));
  await tester.tap(find.text(value ?? 'Any').last);
  await tester.pumpAndSettle();
}

Future<void> open(WidgetTester tester) async {
  await press(
    tester,
    find.byKey(const ValueKey('qa.discovery.filter_button')).first,
  );
}

void main() {
  late _Swipe swipe;
  late _Trust trust;
  Future<void> mount(WidgetTester tester, {ProfileDraft? draft}) async {
    SharedPreferences.setMockInitialValues({});
    swipe = _Swipe();
    tester.view.physicalSize = const Size(900, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          runtimeFeatureFlagsProvider.overrideWith(
            (ref) => Stream.value(
              RuntimeFeatureFlags(<String, bool>{
                ...RuntimeFeatureFlags.defaults.values,
                // Today replaces the deck when intentional dating is on; these
                // tests drive the deck's filter button.
                'intentional_dating_enabled': false,
              }),
            ),
          ),
          billingCoexistenceMatrixProvider.overrideWith(
            (ref) async => const BillingCoexistenceMatrix(
              matrixVersion: 'qa',
              coreProgressionNonBlocking: true,
              coreProgressionFeatures: [],
              monetizedFeatures: [],
            ),
          ),
          swipeNotifierProvider.overrideWith(() => swipe),
          matchNotifierProvider.overrideWith(_Matches.new),
          profileSetupNotifierProvider.overrideWith(
            () => _Draft(draft ?? _draft()),
          ),
          dailyPromptProvider.overrideWith(_Prompt.new),
          notificationProvider.overrideWith(_Notifications.new),
          trustFilterNotifierProvider.overrideWith(
            (ref) => trust = _Trust(ref),
          ),
          preferenceMasterDataProvider.overrideWith((ref) async => _master),
          preferenceMasterDataOfflineProvider.overrideWith((ref) => false),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MainNavigationScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await open(tester);
    expect(tester.takeException(), isNull);
  }

  testWidgets(
    'discovery safely opens inverted and out-of-range saved sliders',
    (tester) async {
      await mount(
        tester,
        draft: _draft().copyWith(
          minAgeYears: 90,
          maxAgeYears: 10,
          maxDistanceKm: 0,
        ),
      );
      expect(
        tester.widget<RangeSlider>(key('age_range_slider')).values,
        const RangeValues(18, 80),
      );
      expect(tester.widget<Slider>(key('distance_slider')).value, 1);
    },
  );

  for (final entry in {
    'country': 'Canada',
    'state': 'Maharashtra',
    'city': 'Bengaluru',
    'mother_tongue': 'Hindi',
    'religion': 'Buddhist',
    'relationship_status': 'Divorced',
    'smoking': 'Regularly',
    'drinking': 'Socially',
    'personality_type': 'Introvert',
  }.entries) {
    testWidgets('discovery ${entry.key} applies selected value', (
      tester,
    ) async {
      await mount(tester);
      await dropdown(tester, entry.key, entry.value);
      await press(tester, key('apply_button'));
      expect(swipe.filters[entry.key], entry.value);
      expect(swipe.refreshes, 1);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('all discovery sliders, switches and trust badges apply', (
    tester,
  ) async {
    await mount(tester);
    tester.widget<RangeSlider>(key('age_range_slider')).onChanged!(
      const RangeValues(18, 70),
    );
    tester.widget<Slider>(key('distance_slider')).onChanged!(500);
    await tester.pumpAndSettle();
    expect(tester.widget<Slider>(key('trust_badge_slider')).onChanged, isNull);
    for (final name in ['party_lover', 'hookup', 'verified_only', 'trust']) {
      await press(tester, key('${name}_switch'));
    }
    tester.widget<Slider>(key('trust_badge_slider')).onChanged!(4);
    await tester.pumpAndSettle();
    for (final name in [
      'Prompt Completer',
      'Respectful Communicator',
      'Consistent Profile',
      'Verified & Active',
    ]) {
      await press(tester, find.widgetWithText(FilterChip, name));
    }
    await press(tester, key('apply_button'));
    expect(swipe.filters, containsPair('min_age', '18'));
    expect(swipe.filters, containsPair('max_age', '70'));
    expect(swipe.filters, containsPair('max_distance_km', '500'));
    for (final name in ['party_lover', 'hookup_only', 'verified_only']) {
      expect(swipe.filters[name], 'true');
    }
    expect(trust.state.enabled, isTrue);
    expect(trust.state.minimumActiveBadges, 4);
    expect(
      trust.state.requiredBadgeCodes,
      unorderedEquals([
        'prompt_completer',
        'respectful_communicator',
        'consistent_profile',
        'verified_active',
      ]),
    );
  });
  testWidgets('Any survives provider rebuild and reopening', (tester) async {
    await mount(tester);
    await dropdown(tester, 'religion', null);
    trust.rebuild();
    await tester.pumpAndSettle();
    await press(tester, key('apply_button'));
    expect(swipe.filters.containsKey('religion'), isFalse);
    await tester.pump(const Duration(seconds: 5));
    await open(tester);
    expect(
      tester.widget<DropdownButton<String>>(key('religion_dropdown')).value,
      isNull,
    );
  });
  testWidgets('Reset clears saved preferences across provider rebuild', (
    tester,
  ) async {
    await mount(tester);
    await press(tester, key('reset_button'));
    trust.rebuild();
    await tester.pumpAndSettle();
    await press(tester, key('apply_button'));
    expect(swipe.filters, {
      'min_age': '20',
      'max_age': '50',
      'max_distance_km': '50',
      'verified_only': 'false',
    });
    expect(trust.state.enabled, isFalse);
    expect(trust.state.requiredBadgeCodes, isEmpty);
  });
  testWidgets('changing country clears dependent state and city', (
    tester,
  ) async {
    await mount(tester);
    await dropdown(tester, 'country', 'Canada');
    trust.rebuild();
    await tester.pumpAndSettle();
    await press(tester, key('apply_button'));
    expect(swipe.filters['country'], 'Canada');
    expect(swipe.filters.containsKey('state'), isFalse);
    expect(swipe.filters.containsKey('city'), isFalse);
  });
  testWidgets(
    'failed trust save keeps sheet open and does not apply partial filters',
    (tester) async {
      await mount(tester);
      trust.fail = true;
      await press(tester, key('apply_button'));
      expect(key('apply_button'), findsOneWidget);
      expect(swipe.refreshes, 0);
      expect(swipe.filters, isEmpty);
      expect(find.text('QA trust save failed'), findsOneWidget);
    },
  );
}
