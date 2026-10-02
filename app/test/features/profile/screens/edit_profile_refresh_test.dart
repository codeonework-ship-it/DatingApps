import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/profile/providers/profile_setup_provider.dart';
import 'package:verified_dating_app/features/profile/screens/edit_profile_screen.dart';
import 'package:verified_dating_app/l10n/app_localizations.dart';

/// What the server holds; tests change it between visits.
var _server = _draft();
var _fetches = 0;

class _ServerBackedNotifier extends ProfileSetupNotifier {
  @override
  Future<ProfileDraft> build() async {
    // Like the real provider: kept alive across the setup screens.
    ref.keepAlive();
    _fetches++;
    return _server;
  }
}

ProfileDraft _draft() => ProfileDraft(
  userId: 'user-1',
  phoneNumber: '+919999999999',
  name: 'Ananya Singh',
  dateOfBirth: DateTime(1998, 6, 20),
  gender: 'F',
  photos: const <ProfilePhotoItem>[
    ProfilePhotoItem(
      id: 'p1',
      photoUrl: 'https://example.com/1.jpg',
      storagePath: 'photos/1.jpg',
      ordering: 0,
    ),
    ProfilePhotoItem(
      id: 'p2',
      photoUrl: 'https://example.com/2.jpg',
      storagePath: 'photos/2.jpg',
      ordering: 1,
    ),
  ],
  bio: 'Hello there, this is a bio that is long enough to pass validation.',
  heightCm: 165,
  education: "Bachelor's",
  profession: 'Software Engineer',
  incomeRange: '10-20L',
  seekingGenders: const <String>['M'],
  minAgeYears: 24,
  maxAgeYears: 35,
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

void main() {
  // AND-13: Edit Profile showed the draft cached earlier in the session;
  // changes made elsewhere only appeared after "Refresh profile".
  testWidgets('reopening Edit Profile shows changes made elsewhere', (
    tester,
  ) async {
    _server = _draft();
    _fetches = 0;
    tester.view.physicalSize = const Size(430, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileSetupNotifierProvider.overrideWith(_ServerBackedNotifier.new),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const EditProfileScreen(),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Ananya Singh'), findsWidgets);
    expect(_fetches, 1, reason: 'a first open fetches once');

    // Changed on another device while Edit Profile was closed.
    _server = _server.copyWith(name: 'Ananya Rao');
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(_fetches, 2);
    expect(find.textContaining('Ananya Rao'), findsWidgets);
    expect(find.textContaining('Ananya Singh'), findsNothing);
  });
}
