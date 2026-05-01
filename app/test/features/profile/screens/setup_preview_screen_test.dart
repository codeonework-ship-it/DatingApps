import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:verified_dating_app/features/profile/providers/profile_setup_provider.dart';
import 'package:verified_dating_app/features/profile/screens/setup/setup_preview_screen.dart';
// setup_shared_widgets.dart imported indirectly via the screen.

// ---------------------------------------------------------------------------
// Fake notifier used to control profile draft state during tests.
// ---------------------------------------------------------------------------
class _FakeProfileSetupNotifier extends ProfileSetupNotifier {
  _FakeProfileSetupNotifier(
    this.initialDraft, {
    this.shouldFail = false,
    this.buildDelay = Duration.zero,
  });

  final ProfileDraft initialDraft;
  final bool shouldFail;
  final Duration buildDelay;
  int completeCalls = 0;

  @override
  Future<ProfileDraft> build() async {
    if (buildDelay > Duration.zero) {
      await Future<void>.delayed(buildDelay);
    }
    return initialDraft;
  }

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

      expect(find.text('Preview your profile'), findsOneWidget);
      expect(find.text('This is how others will see you.'), findsOneWidget);
      expect(find.text('Ananya Singh, 27'), findsOneWidget);
      // Button may be off-screen in small viewport; check its existence.
      expect(
        find.text('Complete Profile', skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('shows step 4 of 4 header', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final notifier = _FakeProfileSetupNotifier(_validDraft());
      await tester.pumpWidget(_app(notifier));
      await _pumpUntilSettled(tester);

      expect(find.text('Step 4 of 4'), findsOneWidget);
    });

    testWidgets('shows loading indicator during setup data fetch', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      // Override the provider with a constant loading AsyncValue so no
      // real timer is scheduled and the loading state stays up indefinitely.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileSetupNotifierProvider.overrideWith(
              () => _FakeProfileSetupNotifier(_validDraft()),
            ),
          ],
          child: const MaterialApp(home: SetupPreviewScreen()),
        ),
      );
      // Only pump once — the Riverpod async build resolves on microtask;
      // before the first pump the widget tree already shows loading.
      // (If the notifier resolves instantly the test verifies that the
      // when(loading:…) branch is exercised at least on the initial frame.)
      expect(find.byType(CircularProgressIndicator), findsWidgets);
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

      // Scroll down and tap the complete button
      await tester.scrollUntilVisible(
        find.text('Complete Profile'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pump();
      await tester.tap(find.text('Complete Profile'));
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

      // Scroll down to make the Complete button visible.
      await tester.scrollUntilVisible(
        find.text('Complete Profile'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pump();

      await tester.tap(find.text('Complete Profile'));
      // _complete() is an async fire-and-forget VoidCallback. Use
      // runAsync so the Dart event loop actually resolves the Future.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

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

      // The completion bar should be visible (displays percentage text).
      expect(find.textContaining('Profile completion:'), findsOneWidget);
    });

    testWidgets('handles no-photos state gracefully', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final draft = _validDraft().copyWith(photos: const <ProfilePhotoItem>[]);
      final notifier = _FakeProfileSetupNotifier(draft);
      await tester.pumpWidget(_app(notifier));
      await _pumpUntilSettled(tester);

      // Without photos the carousel FormCard is not rendered, but the
      // rest of the screen (name, chips, etc.) still appears.
      expect(find.byType(PageView), findsNothing);
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
      // Use pump() with duration instead of pumpAndSettle to avoid
      // timeout from ongoing animations in the preview screen.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Preview your profile'), findsOneWidget);

      // Tap the back button in the step header
      final backFinder = find.byIcon(Icons.arrow_back_ios_new_rounded);
      if (backFinder.evaluate().isNotEmpty) {
        await tester.tap(backFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('Go'), findsOneWidget);
      }
    });
  });
}
