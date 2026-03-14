import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/common/screens/main_navigation_screen.dart';
import 'package:verified_dating_app/features/profile/providers/preference_master_data_provider.dart';
import 'package:verified_dating_app/features/profile/providers/profile_setup_provider.dart';
import 'package:verified_dating_app/features/profile/screens/setup/setup_preferences_screen.dart';

class _FakeProfileSetupNotifier extends ProfileSetupNotifier {
  _FakeProfileSetupNotifier(this.initialDraft);

  final ProfileDraft initialDraft;
  int savePreferencesCalls = 0;
  int saveLifestyleCalls = 0;
  int completeProfileCalls = 0;

  @override
  Future<ProfileDraft> build() async => initialDraft;

  @override
  Future<void> savePreferences({
    required List<String> seekingGenders,
    required int minAgeYears,
    required int maxAgeYears,
    required int maxDistanceKm,
    required List<String> educationFilter,
    required bool seriousOnly,
    required bool verifiedOnly,
    required String? country,
    required String? regionState,
    required String? city,
    required String? instagramHandle,
    required List<String> hobbies,
    required List<String> favoriteBooks,
    required List<String> favoriteNovels,
    required List<String> favoriteSongs,
    required List<String> extraCurriculars,
    required String? additionalInfo,
    required List<String> intentTags,
    required List<String> languageTags,
    required String? petPreference,
    required String? dietPreference,
    required String? workoutFrequency,
    required String? dietType,
    required String? sleepSchedule,
    required String? travelStyle,
    required String? politicalComfortRange,
    required List<String> dealBreakerTags,
    required String? motherTongue,
    required bool hookupOnly,
  }) async {
    savePreferencesCalls += 1;
  }

  @override
  Future<void> saveLifestyle({
    required String drinking,
    required String smoking,
    required String? religion,
  }) async {
    saveLifestyleCalls += 1;
  }

  @override
  Future<void> completeProfile() async {
    completeProfileCalls += 1;
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

PreferenceMasterData _masterData() => const PreferenceMasterData(
  countries: <String>['India'],
  statesByCountry: <String, List<String>>{
    'India': <String>['Karnataka'],
  },
  citiesByState: <String, List<String>>{
    'Karnataka': <String>['Bengaluru'],
  },
  religions: <String>['Hindu'],
  motherTongues: <String>['Kannada'],
  languages: <String>['English'],
  dietPreferences: <String>['Veg'],
  workoutFrequencies: <String>['Often'],
  dietTypes: <String>['Balanced'],
  sleepSchedules: <String>['Early bird'],
  travelStyles: <String>['Adventurous'],
  politicalComfortRanges: <String>['Moderate'],
);

Widget _hostApp({
  required bool? isSetupFlow,
  required _FakeProfileSetupNotifier notifier,
}) => ProviderScope(
  overrides: [
    profileSetupNotifierProvider.overrideWith(() => notifier),
    preferenceMasterDataProvider.overrideWith((ref) async => _masterData()),
    preferenceMasterDataOfflineProvider.overrideWith((ref) => false),
  ],
  child: MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      SetupPreferencesScreen(isSetupFlow: isSetupFlow),
                ),
              );
            },
            child: const Text('Open Preferences'),
          ),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('shows Save when opened from non-setup flows', (tester) async {
    final notifier = _FakeProfileSetupNotifier(_draft());
    await tester.pumpWidget(_hostApp(isSetupFlow: false, notifier: notifier));

    await tester.tap(find.text('Open Preferences'));
    await tester.pumpAndSettle();

    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Finish'), findsNothing);
  });

  testWidgets('treats null setup flag as non-setup flow safely', (
    tester,
  ) async {
    final notifier = _FakeProfileSetupNotifier(_draft());
    await tester.pumpWidget(_hostApp(isSetupFlow: null, notifier: notifier));

    await tester.tap(find.text('Open Preferences'));
    await tester.pumpAndSettle();

    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Finish'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows Finish when opened from setup flow', (tester) async {
    final notifier = _FakeProfileSetupNotifier(_draft());
    await tester.pumpWidget(_hostApp(isSetupFlow: true, notifier: notifier));

    await tester.tap(find.text('Open Preferences'));
    await tester.pumpAndSettle();

    expect(find.text('Finish'), findsOneWidget);
    expect(find.text('Save'), findsNothing);
  });

  testWidgets('setup flow Finish saves data and completes profile', (
    tester,
  ) async {
    final notifier = _FakeProfileSetupNotifier(_draft());
    await tester.pumpWidget(_hostApp(isSetupFlow: true, notifier: notifier));

    final container = ProviderScope.containerOf(
      tester.element(find.text('Open Preferences')),
    );
    container.read(mainNavigationIndexProvider.notifier).state = 4;

    await tester.tap(find.text('Open Preferences'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Finish'));
    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();

    expect(notifier.savePreferencesCalls, 1);
    expect(notifier.saveLifestyleCalls, 1);
    expect(notifier.completeProfileCalls, 1);
    expect(container.read(mainNavigationIndexProvider), 0);
  });

  testWidgets('edit flow Save updates preferences without complete profile', (
    tester,
  ) async {
    final notifier = _FakeProfileSetupNotifier(_draft());
    await tester.pumpWidget(_hostApp(isSetupFlow: false, notifier: notifier));

    final container = ProviderScope.containerOf(
      tester.element(find.text('Open Preferences')),
    );
    container.read(mainNavigationIndexProvider.notifier).state = 4;

    await tester.tap(find.text('Open Preferences'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(notifier.savePreferencesCalls, 1);
    expect(notifier.saveLifestyleCalls, 1);
    expect(notifier.completeProfileCalls, 0);
    expect(container.read(mainNavigationIndexProvider), 0);
  });
}
