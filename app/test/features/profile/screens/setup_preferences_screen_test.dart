import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/widgets/glass_widgets.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';
import 'package:verified_dating_app/features/common/screens/main_navigation_screen.dart';
import 'package:verified_dating_app/features/profile/providers/preference_master_data_provider.dart';
import 'package:verified_dating_app/features/profile/providers/profile_setup_provider.dart';
import 'package:verified_dating_app/features/profile/screens/setup/setup_preferences_screen.dart';

class _FakeProfileSetupNotifier extends ProfileSetupNotifier {
  _FakeProfileSetupNotifier(this.initialDraft);

  final ProfileDraft initialDraft;
  Map<String, dynamic> savedPreferences = {};
  Map<String, dynamic> savedLifestyle = {};
  bool failSave = false;
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
    if (failSave) {
      throw Exception('QA save failure');
    }
    savedPreferences = {
      'seekingGenders': seekingGenders,
      'minAgeYears': minAgeYears,
      'maxAgeYears': maxAgeYears,
      'maxDistanceKm': maxDistanceKm,
      'educationFilter': educationFilter,
      'seriousOnly': seriousOnly,
      'verifiedOnly': verifiedOnly,
      'country': country,
      'regionState': regionState,
      'city': city,
      'instagramHandle': instagramHandle,
      'hobbies': hobbies,
      'favoriteBooks': favoriteBooks,
      'favoriteNovels': favoriteNovels,
      'favoriteSongs': favoriteSongs,
      'extraCurriculars': extraCurriculars,
      'additionalInfo': additionalInfo,
      'intentTags': intentTags,
      'languageTags': languageTags,
      'petPreference': petPreference,
      'dietPreference': dietPreference,
      'workoutFrequency': workoutFrequency,
      'dietType': dietType,
      'sleepSchedule': sleepSchedule,
      'travelStyle': travelStyle,
      'politicalComfortRange': politicalComfortRange,
      'dealBreakerTags': dealBreakerTags,
      'motherTongue': motherTongue,
      'hookupOnly': hookupOnly,
    };
  }

  @override
  Future<void> saveLifestyle({
    required String drinking,
    required String smoking,
    required String? religion,
  }) async {
    saveLifestyleCalls += 1;
    savedLifestyle = {
      'drinking': drinking,
      'smoking': smoking,
      'religion': religion,
    };
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
  countries: <String>['India', 'Canada'],
  statesByCountry: <String, List<String>>{
    'India': <String>['Karnataka'],
    'Canada': <String>['Ontario'],
  },
  citiesByState: <String, List<String>>{
    'Karnataka': <String>['Bengaluru'],
    'Ontario': <String>['Toronto'],
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
  Locale? locale,
}) => ProviderScope(
  overrides: [
    profileSetupNotifierProvider.overrideWith(() => notifier),
    preferenceMasterDataProvider.overrideWith((ref) async => _masterData()),
    preferenceMasterDataOfflineProvider.overrideWith((ref) => false),
  ],
  child: MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
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

Future<void> _pumpUi(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 450));
}

void main() {
  preferencesQAMatrix();
  testWidgets(
    'onboarding dropdowns read in German; the stored values stay the master '
    'data words [case:l10n.setup.preferences_dropdown_labels]',
    (tester) async {
      final de = lookupAppLocalizations(const Locale('de'));
      final notifier = _FakeProfileSetupNotifier(
        _draft().copyWith(
          country: 'India',
          regionState: 'Karnataka',
          sleepSchedule: 'Early bird',
        ),
      );
      await tester.pumpWidget(
        _hostApp(
          isSetupFlow: false,
          notifier: notifier,
          locale: const Locale('de'),
        ),
      );
      await tester.tap(find.text('Open Preferences'));
      await _pumpUi(tester);
      await tester.tap(find.text(de.profileSetupTabAdvanced));
      await _pumpUi(tester);

      // Selected values are shown translated, never as the English word.
      expect(find.text('Indien'), findsOneWidget);
      expect(find.text('India'), findsNothing);
      expect(find.text(de.profileMasterSleepEarlyBird), findsOneWidget);
      // State and city names are proper names and stay as they are.
      expect(find.text('Karnataka'), findsOneWidget);

      Future<void> pick(String label, String shown) async {
        final control = find.widgetWithText(
          DropdownButtonFormField<String>,
          label,
        );
        await tester.ensureVisible(control);
        await tester.tap(control);
        await _pumpUi(tester);
        await tester.tap(find.text(shown).last);
        await _pumpUi(tester);
      }

      await pick(de.profileSetupMotherTongue, 'Kannada');
      await pick(de.profileSetupLanguage, 'Englisch');
      expect(find.text('English'), findsNothing);
      await tester.ensureVisible(find.text(de.profileSetupSavePreferences));
      await tester.tap(find.text(de.profileSetupSavePreferences));
      await _pumpUi(tester);

      expect(notifier.savedPreferences['country'], 'India');
      expect(notifier.savedPreferences['motherTongue'], 'Kannada');
      expect(notifier.savedPreferences['languageTags'], ['English']);
      expect(notifier.savedPreferences['sleepSchedule'], 'Early bird');
    },
  );
  testWidgets('shows Save when opened from non-setup flows', (tester) async {
    final notifier = _FakeProfileSetupNotifier(_draft());
    await tester.pumpWidget(_hostApp(isSetupFlow: false, notifier: notifier));

    await tester.tap(find.text('Open Preferences'));
    await _pumpUi(tester);

    expect(find.text('Save Preferences'), findsOneWidget);
    expect(find.text('Finish & Find Matches'), findsNothing);
  });

  testWidgets('treats null setup flag as non-setup flow safely', (
    tester,
  ) async {
    final notifier = _FakeProfileSetupNotifier(_draft());
    await tester.pumpWidget(_hostApp(isSetupFlow: null, notifier: notifier));

    await tester.tap(find.text('Open Preferences'));
    await _pumpUi(tester);

    expect(find.text('Save Preferences'), findsOneWidget);
    expect(find.text('Finish & Find Matches'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows Finish when opened from setup flow', (tester) async {
    final notifier = _FakeProfileSetupNotifier(_draft());
    await tester.pumpWidget(_hostApp(isSetupFlow: true, notifier: notifier));

    await tester.tap(find.text('Open Preferences'));
    await _pumpUi(tester);

    expect(find.text('Finish & Find Matches'), findsOneWidget);
    expect(find.text('Save Preferences'), findsNothing);
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
    await _pumpUi(tester);

    await tester.ensureVisible(find.byType(GlassButton));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byType(GlassButton));
    await _pumpUi(tester);

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
    await _pumpUi(tester);

    await tester.ensureVisible(find.byType(GlassButton));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byType(GlassButton));
    await _pumpUi(tester);

    expect(notifier.savePreferencesCalls, 1);
    expect(notifier.saveLifestyleCalls, 1);
    expect(notifier.completeProfileCalls, 0);
    expect(container.read(mainNavigationIndexProvider), 0);
  });
}

void preferencesQAMatrix() {
  Future<void> open(
    WidgetTester tester,
    _FakeProfileSetupNotifier notifier, {
    bool advanced = false,
  }) async {
    await tester.pumpWidget(_hostApp(isSetupFlow: false, notifier: notifier));
    await tester.tap(find.text('Open Preferences'));
    await _pumpUi(tester);
    if (advanced) {
      await tester.tap(find.text('Advanced'));
      await _pumpUi(tester);
    }
  }

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.text('Save Preferences'));
    await _pumpUi(tester);
  }

  testWidgets(
    'QA saving preferences preserves existing education and languages',
    (tester) async {
      final notifier = _FakeProfileSetupNotifier(
        _draft().copyWith(
          educationFilter: ['Masters'],
          languageTags: ['English', 'Kannada'],
        ),
      );
      await open(tester, notifier);
      await save(tester);
      expect(notifier.savedPreferences['educationFilter'], ['Masters']);
      expect(notifier.savedPreferences['languageTags'], ['English', 'Kannada']);
    },
  );

  testWidgets(
    'QA basic preferences serialize age distance genders and all toggles',
    (tester) async {
      final notifier = _FakeProfileSetupNotifier(_draft());
      await open(tester, notifier);
      tester.widget<RangeSlider>(find.byType(RangeSlider)).onChanged!(
        const RangeValues(27, 39),
      );
      await tester.pump();
      tester.widget<Slider>(find.byType(Slider)).onChanged!(123);
      await tester.pump();
      for (final toggle in ['serious_only', 'verified_only', 'hookup_only']) {
        // The automation id is the switch's key (and a semantics
        // identifier); its spoken label is the translated toggle name.
        final control = find.byKey(
          ValueKey<String>('qa.setup.preferences.${toggle}_toggle'),
        );
        await tester.ensureVisible(control);
        await tester.tap(control);
        await tester.pump();
      }
      final other = find.text('Other');
      await tester.ensureVisible(other);
      await tester.tap(other);
      await tester.pump();
      await save(tester);
      expect(notifier.savedPreferences['minAgeYears'], 27);
      expect(notifier.savedPreferences['maxAgeYears'], 39);
      expect(notifier.savedPreferences['maxDistanceKm'], 123);
      expect(
        notifier.savedPreferences['seekingGenders'],
        containsAll(['M', 'F', 'Other']),
      );
      expect(notifier.savedPreferences['seriousOnly'], false);
      expect(notifier.savedPreferences['verifiedOnly'], true);
      expect(notifier.savedPreferences['hookupOnly'], true);
    },
  );

  testWidgets('QA empty seeking selection prevents save', (tester) async {
    final notifier = _FakeProfileSetupNotifier(_draft());
    await open(tester, notifier);
    await tester.tap(find.text('Men'));
    await tester.tap(find.text('Women'));
    await save(tester);
    expect(notifier.savePreferencesCalls, 0);
    expect(find.text('Select at least one gender preference.'), findsOneWidget);
  });

  testWidgets(
    'QA failed preferences save stays on the form and supports retry',
    (tester) async {
      final notifier = _FakeProfileSetupNotifier(_draft())..failSave = true;
      await open(tester, notifier);
      await save(tester);
      expect(find.text('Edit Preferences'), findsOneWidget);
      expect(
        find.text('Some preferences could not be saved right now.'),
        findsOneWidget,
      );
      notifier.failSave = false;
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 300));
      await save(tester);
      expect(notifier.savePreferencesCalls, 2);
      expect(notifier.saveLifestyleCalls, 1);
    },
  );

  testWidgets('QA out-of-range saved sliders are bounded safely', (
    tester,
  ) async {
    final notifier = _FakeProfileSetupNotifier(
      _draft().copyWith(minAgeYears: 10, maxAgeYears: 90, maxDistanceKm: 900),
    );
    await open(tester, notifier);
    expect(tester.takeException(), isNull);
    expect(
      tester.widget<RangeSlider>(find.byType(RangeSlider)).values,
      const RangeValues(18, 80),
    );
    expect(tester.widget<Slider>(find.byType(Slider)).value, 500);
  });
  testWidgets('QA changing country visibly clears saved state and city', (
    tester,
  ) async {
    final notifier = _FakeProfileSetupNotifier(
      _draft().copyWith(
        country: 'India',
        regionState: 'Karnataka',
        city: 'Bengaluru',
      ),
    );
    await open(tester, notifier, advanced: true);
    Finder field(String name) => find.byWidgetPredicate(
      (w) =>
          w is DropdownButtonFormField<String> &&
          w.decoration.labelText == name,
    );
    await tester.ensureVisible(field('Country'));
    await tester.tap(field('Country'));
    await _pumpUi(tester);
    await tester.tap(find.text('Canada').last);
    await _pumpUi(tester);
    expect(
      tester.state<FormFieldState<String>>(field('State / Region')).value,
      isNull,
    );
    expect(tester.state<FormFieldState<String>>(field('City')).value, isNull);
    await save(tester);
    expect(notifier.savedPreferences['country'], 'Canada');
    expect(notifier.savedPreferences['regionState'], isNull);
    expect(notifier.savedPreferences['city'], isNull);
  });

  testWidgets('QA setup Back keeps edits on screen when save fails', (
    tester,
  ) async {
    final notifier = _FakeProfileSetupNotifier(_draft())..failSave = true;
    await tester.pumpWidget(_hostApp(isSetupFlow: true, notifier: notifier));
    await _pumpUi(tester);
    await tester.tap(find.text('Open Preferences'));
    await _pumpUi(tester);
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await _pumpUi(tester);
    expect(find.text('Your Preferences'), findsOneWidget);
    expect(
      find.text('Could not save your changes. Please try again.'),
      findsOneWidget,
    );
    expect(notifier.savePreferencesCalls, 1);
  });

  final dropdowns = <(String, String, String)>[
    ('Country', 'country', 'India'),
    ('State / Region', 'regionState', 'Karnataka'),
    ('City', 'city', 'Bengaluru'),
    ('Religion preference', 'religion', 'Hindu'),
    ('Mother tongue', 'motherTongue', 'Kannada'),
    ('Language', 'languageTags', 'English'),
    ('Diet preference', 'dietPreference', 'Veg'),
    ('Workout frequency', 'workoutFrequency', 'Often'),
    ('Diet type', 'dietType', 'Balanced'),
    ('Sleep schedule', 'sleepSchedule', 'Early bird'),
    ('Travel style', 'travelStyle', 'Adventurous'),
    ('Political comfort range', 'politicalComfortRange', 'Moderate'),
  ];
  for (final (label, field, value) in dropdowns) {
    testWidgets('QA preference dropdown $field reaches the save payload', (
      tester,
    ) async {
      final notifier = _FakeProfileSetupNotifier(
        _draft().copyWith(country: 'India', regionState: 'Karnataka'),
      );
      await open(tester, notifier, advanced: true);
      final control = find.widgetWithText(
        DropdownButtonFormField<String>,
        label,
      );
      await tester.ensureVisible(control);
      await tester.tap(control);
      await _pumpUi(tester);
      await tester.tap(find.text(value).last);
      await _pumpUi(tester);
      await save(tester);
      final actual = field == 'religion'
          ? notifier.savedLifestyle[field]
          : notifier.savedPreferences[field];
      expect(actual, field == 'languageTags' ? [value] : value);
    });
  }

  final textFields = <(String, String, bool)>[
    ('Instagram handle (without @)', 'instagramHandle', false),
    ('Intent tags (long-term, marriage, casual…)', 'intentTags', true),
    ('Hobbies (comma-separated)', 'hobbies', true),
    ('Favourite books (comma-separated)', 'favoriteBooks', true),
    ('Favourite novels (comma-separated)', 'favoriteNovels', true),
    ('Favourite songs (comma-separated)', 'favoriteSongs', true),
    ('Extra-curricular activities (comma-separated)', 'extraCurriculars', true),
    ('Additional information', 'additionalInfo', false),
    ('Pet preference', 'petPreference', false),
    ('Tags (comma-separated)', 'dealBreakerTags', true),
  ];
  for (final (label, field, isList) in textFields) {
    testWidgets('QA preference text $field is editable and saved', (
      tester,
    ) async {
      final notifier = _FakeProfileSetupNotifier(_draft());
      await open(tester, notifier, advanced: true);
      final input = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == label,
      );
      expect(input, findsOneWidget);
      await tester.ensureVisible(input);
      await tester.enterText(input, isList ? ' alpha, beta, ' : '  sample  ');
      await save(tester);
      expect(
        notifier.savedPreferences[field],
        isList ? ['alpha', 'beta'] : 'sample',
      );
    });
  }
}
