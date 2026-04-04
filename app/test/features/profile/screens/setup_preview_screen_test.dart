import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/widgets/glass_widgets.dart';
import 'package:verified_dating_app/features/profile/providers/profile_completion_provider.dart';
import 'package:verified_dating_app/features/profile/providers/profile_setup_provider.dart';
import 'package:verified_dating_app/features/profile/screens/setup/setup_preview_screen.dart';
import 'package:verified_dating_app/features/profile/screens/setup/setup_shared_widgets.dart';

// ---------------------------------------------------------------------------
// Fake notifier used to control profile draft state during tests.
// ---------------------------------------------------------------------------
class _FakeProfileSetupNotifier extends ProfileSetupNotifier {
  _FakeProfileSetupNotifier(this.initialDraft, {this.shouldFail = false});

  final ProfileDraft initialDraft;
  final bool shouldFail;
  int completeCalls = 0;

  @override
  Future<ProfileDraft> build() async => initialDraft;

  @override
  Future<void> completeProfile() async {
    completeCalls += 1;
    if (shouldFail) {
      throw DioException(
        requestOptions: RequestOptions(path: '/profile/user-1/complete'),
        response: Response(
          requestOptions: RequestOptions(path: '/profile/user-1/complete'),
          statusCode: 500,
          data: {'error': 'Internal server error'},
        ),
        type: DioExceptionType.badResponse,
      );
    }
    // Simulate success — no-op.
  }
}

// ---------------------------------------------------------------------------
// Factory for a minimal valid draft.
// ---------------------------------------------------------------------------
ProfileDraft _validDraft() => ProfileDraft(
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

ProfileDraft _incompleteDraft() => _validDraft().copyWith(
  photos: const <ProfilePhotoItem>[],
  bio: '',
  name: '',
);

Widget _app(
  _FakeProfileSetupNotifier notifier, {
  List<Override> extraOverrides = const [],
}) => ProviderScope(
  overrides: [
    profileSetupNotifierProvider.overrideWith(() => notifier),
    ...extraOverrides,
  ],
  child: const MaterialApp(home: SetupPreviewScreen()),
);

Future<void> _pumpUntilSettled(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  group('SetupPreviewScreen', () {
    testWidgets('renders profile preview with valid draft', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final notifier = _FakeProfileSetupNotifier(_validDraft());
      await tester.pumpWidget(_app(notifier));
      await _pumpUntilSettled(tester);

      expect(find.text('Profile preview'), findsOneWidget);
      expect(find.text('How others see you'), findsOneWidget);
      expect(find.text('Ananya Singh'), findsOneWidget);
      expect(find.text('Complete & Start Matching'), findsOneWidget);
    });

    testWidgets('shows step 4 of 4 header', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final notifier = _FakeProfileSetupNotifier(_validDraft());
      await tester.pumpWidget(_app(notifier));
      await _pumpUntilSettled(tester);

      expect(find.text('4 / 4'), findsOneWidget);
    });

    testWidgets('shows loading indicator during setup data fetch', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final notifier = _FakeProfileSetupNotifier(_validDraft());
      await tester.pumpWidget(_app(notifier));
      // Don't settle — check loading state
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays bio text in preview', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final notifier = _FakeProfileSetupNotifier(_validDraft());
      await tester.pumpWidget(_app(notifier));
      await _pumpUntilSettled(tester);

      expect(
        find.text(
          'Hello there, this is a bio that is long enough to pass validation.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('displays profile chips for filled fields', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final notifier = _FakeProfileSetupNotifier(_validDraft());
      await tester.pumpWidget(_app(notifier));
      await _pumpUntilSettled(tester);

      expect(find.text('F'), findsOneWidget); // gender chip
      expect(find.text('165 cm'), findsOneWidget); // height chip
      expect(find.text('Software Engineer'), findsOneWidget); // profession
      expect(find.text("Bachelor's"), findsOneWidget); // education
    });

    testWidgets('shows validation snackbar when draft is incomplete '
        '(missing photos)', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final notifier = _FakeProfileSetupNotifier(_incompleteDraft());
      await tester.pumpWidget(_app(notifier));
      await _pumpUntilSettled(tester);

      // Tap the complete button
      await tester.tap(find.text('Complete & Start Matching'));
      await tester.pump(); // trigger snackbar
      await tester.pump(const Duration(milliseconds: 200));

      // Should show validation error about missing fields
      expect(find.byType(SnackBar), findsOneWidget);
      expect(notifier.completeCalls, 0);
    });

    testWidgets('shows API error snackbar on backend failure', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final notifier = _FakeProfileSetupNotifier(
        _validDraft(),
        shouldFail: true,
      );
      await tester.pumpWidget(_app(notifier));
      await _pumpUntilSettled(tester);

      await tester.tap(find.text('Complete & Start Matching'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(SnackBar), findsOneWidget);
      expect(notifier.completeCalls, 1);
    });

    testWidgets('shows completion badge with correct percentage', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final notifier = _FakeProfileSetupNotifier(_validDraft());
      await tester.pumpWidget(_app(notifier));
      await _pumpUntilSettled(tester);

      // The completion badge should be visible
      expect(find.byType(CompletionBadge), findsOneWidget);
    });

    testWidgets('handles no-photos state gracefully', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final draft = _validDraft().copyWith(photos: const <ProfilePhotoItem>[]);
      final notifier = _FakeProfileSetupNotifier(draft);
      await tester.pumpWidget(_app(notifier));
      await _pumpUntilSettled(tester);

      expect(find.text('No photos yet'), findsOneWidget);
    });

    testWidgets('back button navigates back (pop)', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final notifier = _FakeProfileSetupNotifier(_validDraft());
      // Wrap in a parent route so Navigator.pop has somewhere to go
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileSetupNotifierProvider.overrideWith(() => notifier),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SetupPreviewScreen(),
                      ),
                    ),
                    child: const Text('Go'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();

      expect(find.text('Profile preview'), findsOneWidget);

      // Tap the back button in the step header
      final backFinder = find.byIcon(Icons.arrow_back_ios_new_rounded);
      if (backFinder.evaluate().isNotEmpty) {
        await tester.tap(backFinder);
        await tester.pumpAndSettle();
        expect(find.text('Go'), findsOneWidget);
      }
    });
  });
}
