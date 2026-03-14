import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/profile/providers/profile_setup_provider.dart';
import 'package:verified_dating_app/features/profile/screens/setup/setup_basic_info_screen.dart';

class _FakeProfileSetupNotifier extends ProfileSetupNotifier {
  _FakeProfileSetupNotifier(this.initialDraft);

  final ProfileDraft initialDraft;
  int saveCalls = 0;

  @override
  Future<ProfileDraft> build() async => initialDraft;

  @override
  Future<void> saveBasicInfo({
    required String name,
    required DateTime dateOfBirth,
    required String gender,
  }) async {
    saveCalls += 1;
    state = AsyncData(
      initialDraft.copyWith(
        name: name,
        dateOfBirth: dateOfBirth,
        gender: gender,
      ),
    );
  }
}

ProfileDraft _draft({String name = '', DateTime? dob}) => ProfileDraft(
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

Widget _appWithOverride(_FakeProfileSetupNotifier notifier) => ProviderScope(
  overrides: [profileSetupNotifierProvider.overrideWith(() => notifier)],
  child: const MaterialApp(home: SetupBasicInfoScreen()),
);

void main() {
  testWidgets('renders without overflow on compact phone viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final notifier = _FakeProfileSetupNotifier(_draft(name: 'Asha'));
    await tester.pumpWidget(_appWithOverride(notifier));
    await tester.pumpAndSettle();

    expect(find.text('Basic Info'), findsAtLeastNWidgets(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders cleanly on tablet viewport', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final notifier = _FakeProfileSetupNotifier(
      _draft(name: 'Priya', dob: DateTime(1997, 10, 12)),
    );
    await tester.pumpWidget(_appWithOverride(notifier));
    await tester.pumpAndSettle();

    expect(
      find.text('Tell matches who you are. You can edit this later.'),
      findsOneWidget,
    );
    expect(find.text('Next'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows validation when name is too short', (tester) async {
    final notifier = _FakeProfileSetupNotifier(_draft(name: '', dob: null));
    await tester.pumpWidget(_appWithOverride(notifier));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'A');
    await tester.tap(find.text('Next'));
    await tester.pump();

    expect(find.text('Name must be at least 2 characters.'), findsOneWidget);
    expect(notifier.saveCalls, 0);
  });

  testWidgets('shows validation when date of birth is missing', (tester) async {
    final notifier = _FakeProfileSetupNotifier(_draft(name: '', dob: null));
    await tester.pumpWidget(_appWithOverride(notifier));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Ananya');
    await tester.tap(find.text('Next'));
    await tester.pump();

    expect(find.text('Please select your date of birth.'), findsOneWidget);
    expect(notifier.saveCalls, 0);
  });

  testWidgets('submits and navigates to photos when basic info is valid', (
    tester,
  ) async {
    final notifier = _FakeProfileSetupNotifier(
      _draft(name: 'Ananya', dob: DateTime(1998, 6, 20)),
    );
    await tester.pumpWidget(_appWithOverride(notifier));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Ananya Singh');
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(notifier.saveCalls, 1);
    expect(find.text('Photos'), findsOneWidget);
  });
}
