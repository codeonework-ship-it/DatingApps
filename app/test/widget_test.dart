import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:verified_dating_app/features/profile/providers/profile_setup_provider.dart';
import 'package:verified_dating_app/features/profile/screens/setup/setup_about_screen.dart';
import 'package:verified_dating_app/features/profile/screens/setup/setup_photos_screen.dart';
import 'package:verified_dating_app/features/profile/screens/setup/setup_preview_screen.dart';

class _FakeProfileSetupNotifier extends ProfileSetupNotifier {
  _FakeProfileSetupNotifier(this.initialDraft);

  final ProfileDraft initialDraft;

  @override
  Future<ProfileDraft> build() async => initialDraft;
}

ProfileDraft _draft() => ProfileDraft(
  userId: '1',
  phoneNumber: '+919999999999',
  name: 'Test User',
  bio: 'This is a profile bio that is long enough for validation.',
  gender: 'M',
  photos: const <ProfilePhotoItem>[],
  drinking: 'Never',
  smoking: 'Never',
  dateOfBirth: DateTime(2000, 1, 1),
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
  religion: null,
  motherTongue: null,
  hookupOnly: false,
);

Widget _app(Widget home) => ProviderScope(
  overrides: [
    profileSetupNotifierProvider.overrideWith(
      () => _FakeProfileSetupNotifier(_draft()),
    ),
  ],
  child: MaterialApp(home: home),
);

Future<void> _pumpUi(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('SetupPhotosScreen renders without overflow', (tester) async {
    await tester.pumpWidget(_app(const SetupPhotosScreen()));
    await _pumpUi(tester);

    expect(find.text('Add your photos'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('SetupAboutScreen renders without overflow', (tester) async {
    await tester.pumpWidget(_app(const SetupAboutScreen()));
    await _pumpUi(tester);

    expect(find.byType(SetupAboutScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('SetupPreviewScreen renders without overflow', (tester) async {
    await tester.pumpWidget(_app(const SetupPreviewScreen()));
    await _pumpUi(tester);

    expect(find.byType(SetupPreviewScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
