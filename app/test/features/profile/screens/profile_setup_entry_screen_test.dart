import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/theme/app_theme.dart';
import 'package:verified_dating_app/features/auth/providers/auth_provider.dart';
import 'package:verified_dating_app/features/profile/providers/preference_master_data_provider.dart';
import 'package:verified_dating_app/features/profile/providers/profile_completion_provider.dart';
import 'package:verified_dating_app/features/profile/providers/profile_setup_provider.dart';
import 'package:verified_dating_app/features/profile/screens/setup/profile_setup_entry_screen.dart';
import 'package:verified_dating_app/features/profile/screens/setup/setup_about_screen.dart';
import 'package:verified_dating_app/features/profile/screens/setup/setup_photos_screen.dart';
import 'package:verified_dating_app/features/profile/screens/setup/setup_preview_screen.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

class _AuthenticatedUser extends AuthNotifier {
  @override
  AuthState build() => const AuthState(
    isAuthenticated: true,
    isNewAccount: true,
    userId: 'user-1',
    username: 'signup_user',
  );
}

class _DraftNotifier extends ProfileSetupNotifier {
  _DraftNotifier(this.draft);

  final ProfileDraft draft;

  @override
  Future<ProfileDraft> build() async => draft;
}

ProfileDraft _draft({required int photoCount, required String bio}) =>
    ProfileDraft(
      userId: 'user-1',
      phoneNumber: '',
      name: 'Signup User',
      dateOfBirth: DateTime(1998, 1, 1),
      gender: 'F',
      photos: List<ProfilePhotoItem>.generate(
        photoCount,
        (index) => ProfilePhotoItem(
          id: 'photo-$index',
          photoUrl: 'https://example.com/photo-$index.jpg',
          storagePath: 'profile_photos/user-1/photo-$index.jpg',
          ordering: index,
        ),
      ),
      bio: bio,
      heightCm: null,
      education: null,
      profession: null,
      incomeRange: null,
      seekingGenders: const ['M'],
      minAgeYears: 18,
      maxAgeYears: 60,
      maxDistanceKm: 50,
      educationFilter: const [],
      seriousOnly: true,
      verifiedOnly: false,
      country: null,
      regionState: null,
      city: null,
      instagramHandle: null,
      hobbies: const [],
      favoriteBooks: const [],
      favoriteNovels: const [],
      favoriteSongs: const [],
      extraCurriculars: const [],
      additionalInfo: null,
      intentTags: const [],
      languageTags: const [],
      petPreference: null,
      dietPreference: null,
      workoutFrequency: null,
      dietType: null,
      sleepSchedule: null,
      travelStyle: null,
      politicalComfortRange: null,
      dealBreakerTags: const [],
      drinking: 'Never',
      smoking: 'Never',
      religion: null,
      motherTongue: null,
      hookupOnly: false,
    );

Widget _app(ProfileDraft draft) => ProviderScope(
  overrides: [
    authNotifierProvider.overrideWith(_AuthenticatedUser.new),
    profileCompletionProvider.overrideWith(
      (ref) async => ProfileCompletion(
        hasUserRow: true,
        profileCompletion: 50,
        photoCount: draft.photos.length,
      ),
    ),
    profileSetupNotifierProvider.overrideWith(() => _DraftNotifier(draft)),
    preferenceMasterDataProvider.overrideWith(
      (ref) async => PreferenceMasterData.empty(),
    ),
    preferenceMasterDataOfflineProvider.overrideWith((ref) => false),
  ],
  child: MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: AppTheme.darkTheme,
    home: const ProfileSetupEntryScreen(),
  ),
);

Future<void> _pump(WidgetTester tester, ProfileDraft draft) async {
  await tester.pumpWidget(_app(draft));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('resumes at photos when fewer than two are durable', (
    tester,
  ) async {
    await _pump(tester, _draft(photoCount: 0, bio: ''));

    expect(find.byType(SetupPhotosScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('resumes at about when photos exist but bio is missing', (
    tester,
  ) async {
    await _pump(tester, _draft(photoCount: 2, bio: ''));

    expect(find.byType(SetupAboutScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('resumes at preview when completion requirements are present', (
    tester,
  ) async {
    await _pump(
      tester,
      _draft(photoCount: 2, bio: 'A complete and durable profile bio.'),
    );

    expect(find.byType(SetupPreviewScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
