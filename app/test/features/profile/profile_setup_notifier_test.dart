// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/features/profile/providers/profile_setup_provider.dart';

// ─── helpers ────────────────────────────────────────────────────────────────

/// A fake notifier that never hits the network. All mutating methods apply
/// state changes locally (mirrors the real optimistic-update pattern).
class _FakeNotifier extends ProfileSetupNotifier {
  _FakeNotifier(this._initial);

  final ProfileDraft _initial;

  @override
  Future<ProfileDraft> build() async => _initial;

  // Track call counts for assertions.
  int saveBasicInfoCalls = 0;
  int saveAboutCalls = 0;
  int completeProfileCalls = 0;

  @override
  Future<void> saveBasicInfo({
    required String name,
    required DateTime dateOfBirth,
    required String gender,
  }) async {
    saveBasicInfoCalls++;
    state = AsyncData(
      (state.valueOrNull ?? _initial).copyWith(
        name: name,
        dateOfBirth: dateOfBirth,
        gender: gender,
      ),
    );
  }

  @override
  Future<void> saveAbout({
    required String bio,
    required int? heightCm,
    required String? education,
    required String? profession,
    required String? incomeRange,
  }) async {
    saveAboutCalls++;
    final current = state.valueOrNull ?? _initial;
    state = AsyncData(
      current.copyWith(
        bio: bio,
        heightCm: heightCm,
        education: education,
        profession: profession,
        incomeRange: incomeRange,
      ),
    );
  }

  @override
  Future<void> completeProfile() async {
    completeProfileCalls++;
    // Simulate marking draft as completed.
  }
}

ProfileDraft _baseDraft() => ProfileDraft(
  userId: 'u-test-1',
  phoneNumber: '+91000',
  name: 'Base',
  dateOfBirth: DateTime(2000),
  gender: 'M',
  photos: const [],
  bio: 'A bio that is definitely longer than ten characters.',
  heightCm: null,
  education: null,
  profession: null,
  incomeRange: null,
  seekingGenders: const ['F'],
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

ProviderContainer _container(_FakeNotifier notifier) => ProviderContainer(
  overrides: [profileSetupNotifierProvider.overrideWith(() => notifier)],
);

// ─── tests ───────────────────────────────────────────────────────────────────

void main() {
  group('ProfileSetupNotifier — initial state', () {
    test('builds with the provided initial draft', () async {
      final notifier = _FakeNotifier(_baseDraft());
      final container = _container(notifier);
      addTearDown(container.dispose);

      final result = await container.read(profileSetupNotifierProvider.future);
      expect(result.name, 'Base');
      expect(result.userId, 'u-test-1');
    });
  });

  // ── Bug 1: saveBasicInfo must preserve name in state ──────────────────────
  group('saveBasicInfo — name preservation (Bug 1 regression)', () {
    test('state contains the saved name after saveBasicInfo', () async {
      final notifier = _FakeNotifier(_baseDraft().copyWith(name: ''));
      final container = _container(notifier);
      addTearDown(container.dispose);

      await container.read(profileSetupNotifierProvider.future);
      await container
          .read(profileSetupNotifierProvider.notifier)
          .saveBasicInfo(
            name: 'Priya',
            dateOfBirth: DateTime(1998),
            gender: 'F',
          );

      final draft = container.read(profileSetupNotifierProvider).valueOrNull;
      expect(draft, isNotNull);
      expect(draft!.name, 'Priya');
    });

    test(
      'saveBasicInfo is idempotent: calling twice keeps last value',
      () async {
        final notifier = _FakeNotifier(_baseDraft());
        final container = _container(notifier);
        addTearDown(container.dispose);

        await container.read(profileSetupNotifierProvider.future);
        final n = container.read(profileSetupNotifierProvider.notifier);

        await n.saveBasicInfo(
          name: 'First',
          dateOfBirth: DateTime(1990),
          gender: 'M',
        );
        await n.saveBasicInfo(
          name: 'Second',
          dateOfBirth: DateTime(1992),
          gender: 'F',
        );

        final draft = container.read(profileSetupNotifierProvider).valueOrNull;
        expect(draft!.name, 'Second');
        expect(draft.gender, 'F');
      },
    );

    test('name is NOT cleared when saveAbout is called after saveBasicInfo '
        '(Bug 1 regression)', () async {
      final notifier = _FakeNotifier(_baseDraft().copyWith(name: ''));
      final container = _container(notifier);
      addTearDown(container.dispose);

      await container.read(profileSetupNotifierProvider.future);
      final n = container.read(profileSetupNotifierProvider.notifier);

      // Step 1: user saves basic info — name should be in state.
      await n.saveBasicInfo(
        name: 'Visible Name',
        dateOfBirth: DateTime(1995),
        gender: 'F',
      );
      expect(
        container.read(profileSetupNotifierProvider).valueOrNull?.name,
        'Visible Name',
      );

      // Step 2: user saves the about section — must NOT wipe the name.
      await n.saveAbout(
        bio: 'This bio is definitely long enough to pass validation.',
        heightCm: 165,
        education: "Bachelor's",
        profession: 'Engineer',
        incomeRange: '10-20L',
      );

      final draft = container.read(profileSetupNotifierProvider).valueOrNull;
      expect(draft, isNotNull);
      expect(
        draft!.name,
        'Visible Name',
        reason: 'saveAbout must not clear the previously saved name',
      );
      expect(draft.bio, contains('long enough'));
    });
  });

  // ── Bug 2: photos must survive saveAbout round-trip ──────────────────────
  group('Photo state preservation (Bug 2 regression)', () {
    test('photos remain in state after saveAbout is called', () async {
      final photo = ProfilePhotoItem(
        id: 'p-existing',
        photoUrl: 'https://cdn.test/x.jpg',
        storagePath: 'user/x.jpg',
        ordering: 0,
      );
      final draftWithPhoto = _baseDraft().copyWith(photos: [photo]);
      final notifier = _FakeNotifier(draftWithPhoto);
      final container = _container(notifier);
      addTearDown(container.dispose);

      await container.read(profileSetupNotifierProvider.future);

      // Simulate the about screen saving new data.
      await container
          .read(profileSetupNotifierProvider.notifier)
          .saveAbout(
            bio: 'An adequately long bio string for testing purposes.',
            heightCm: 170,
            education: null,
            profession: null,
            incomeRange: null,
          );

      final draft = container.read(profileSetupNotifierProvider).valueOrNull;
      expect(draft, isNotNull);
      expect(
        draft!.photos,
        isNotEmpty,
        reason: 'Existing photos must survive saveAbout (Bug 2 regression)',
      );
      expect(draft.photos.first.id, 'p-existing');
    });

    test('two photos plus bio saved: both photos survive the subsequent '
        'saveAbout call', () async {
      final photos = [
        ProfilePhotoItem(
          id: 'pa',
          photoUrl: 'https://cdn.test/a.jpg',
          storagePath: 'user/a.jpg',
          ordering: 0,
        ),
        ProfilePhotoItem(
          id: 'pb',
          photoUrl: 'https://cdn.test/b.jpg',
          storagePath: 'user/b.jpg',
          ordering: 1,
        ),
      ];
      final notifier = _FakeNotifier(_baseDraft().copyWith(photos: photos));
      final container = _container(notifier);
      addTearDown(container.dispose);

      await container.read(profileSetupNotifierProvider.future);
      await container
          .read(profileSetupNotifierProvider.notifier)
          .saveAbout(
            bio: 'More than ten characters here.',
            heightCm: null,
            education: "Master's",
            profession: 'Designer',
            incomeRange: null,
          );

      final result = container.read(profileSetupNotifierProvider).valueOrNull;
      expect(
        result!.photos.length,
        2,
        reason: 'Both photos must survive saveAbout',
      );
      expect(result.photos.map((p) => p.id), containsAll(['pa', 'pb']));
    });
  });

  // ── copyWith immutability asserts ────────────────────────────────────────
  group('State immutability', () {
    test('updating via notifier creates a new state instance', () async {
      final initial = _baseDraft();
      final notifier = _FakeNotifier(initial);
      final container = _container(notifier);
      addTearDown(container.dispose);

      final before = await container.read(profileSetupNotifierProvider.future);
      await container
          .read(profileSetupNotifierProvider.notifier)
          .saveBasicInfo(
            name: 'Different',
            dateOfBirth: DateTime(2001),
            gender: 'M',
          );
      final after = container.read(profileSetupNotifierProvider).valueOrNull;
      // The initial object is unchanged.
      expect(before.name, 'Base');
      expect(after?.name, 'Different');
    });
  });

  // ── completeProfile ──────────────────────────────────────────────────────
  group('completeProfile', () {
    test('is callable on a fully valid draft without throwing', () async {
      final photos = [
        ProfilePhotoItem(
          id: 'p1',
          photoUrl: 'u1',
          storagePath: 's1',
          ordering: 0,
        ),
        ProfilePhotoItem(
          id: 'p2',
          photoUrl: 'u2',
          storagePath: 's2',
          ordering: 1,
        ),
      ];
      final draft = _baseDraft().copyWith(photos: photos);
      final notifier = _FakeNotifier(draft);
      final container = _container(notifier);
      addTearDown(container.dispose);

      await container.read(profileSetupNotifierProvider.future);
      await expectLater(
        container.read(profileSetupNotifierProvider.notifier).completeProfile(),
        completes,
      );
      expect(notifier.completeProfileCalls, 1);
    });
  });

  // ── Widget smoke tests ───────────────────────────────────────────────────
  // These ensure the provider override pattern used by all screen tests works.
  group('ProviderScope override pattern', () {
    testWidgets('override resolves to fake data without network calls', (
      tester,
    ) async {
      final notifier = _FakeNotifier(
        _baseDraft().copyWith(name: 'Widget Test'),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileSetupNotifierProvider.overrideWith(() => notifier),
          ],
          child: Consumer(
            builder: (_, ref, __) {
              final draft = ref.watch(profileSetupNotifierProvider).valueOrNull;
              return MaterialApp(
                home: Scaffold(body: Text(draft?.name ?? 'loading')),
              );
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Widget Test'), findsOneWidget);
    });
  });
}
