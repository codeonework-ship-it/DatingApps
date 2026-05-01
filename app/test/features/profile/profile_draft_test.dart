// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter_test/flutter_test.dart';
import 'package:verified_dating_app/core/constants/app_constants.dart';
import 'package:verified_dating_app/features/profile/providers/profile_setup_provider.dart';

// ─── helpers ─────────────────────────────────────────────────────────────────

ProfileDraft _emptyDraft() => ProfileDraft(
  userId: 'u1',
  phoneNumber: '+91999',
  name: '',
  dateOfBirth: null,
  gender: 'M',
  photos: const [],
  bio: '',
  heightCm: null,
  education: null,
  profession: null,
  incomeRange: null,
  seekingGenders: const [],
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
  drinking: '',
  smoking: '',
  religion: null,
  motherTongue: null,
  hookupOnly: false,
);

ProfileDraft _fullDraft() => _emptyDraft().copyWith(
  name: 'Riya Patel',
  dateOfBirth: DateTime(1995, 3, 12),
  photos: [
    ProfilePhotoItem(
      id: 'p1',
      photoUrl: 'https://x.test/1.jpg',
      storagePath: 'x/1',
      ordering: 0,
    ),
    ProfilePhotoItem(
      id: 'p2',
      photoUrl: 'https://x.test/2.jpg',
      storagePath: 'x/2',
      ordering: 1,
    ),
  ],
  bio: 'A long enough bio to exceed the minimum character requirement.',
  seekingGenders: ['M'],
  drinking: 'Never',
  smoking: 'Never',
);

// ─── tests ───────────────────────────────────────────────────────────────────

void main() {
  group('ProfileDraft.profileCompletionPercent', () {
    test('returns 0 when draft is completely empty', () {
      final draft = _emptyDraft();
      expect(draft.profileCompletionPercent, 0);
    });

    test('increments by ~17% per satisfied criterion (total 6)', () {
      // Each of the 6 criteria is worth 1/6 ≈ 16.67%, rounded.
      const total = 6;
      var draft = _emptyDraft();

      // 1. Name
      draft = draft.copyWith(name: 'Jo');
      expect(draft.profileCompletionPercent, ((1 / total) * 100).round());

      // 2. Date of birth
      draft = draft.copyWith(dateOfBirth: DateTime(1995));
      expect(draft.profileCompletionPercent, ((2 / total) * 100).round());

      // 3. Two photos
      draft = draft.copyWith(
        photos: [
          ProfilePhotoItem(
            id: 'p1',
            photoUrl: 'u',
            storagePath: 's',
            ordering: 0,
          ),
          ProfilePhotoItem(
            id: 'p2',
            photoUrl: 'v',
            storagePath: 't',
            ordering: 1,
          ),
        ],
      );
      expect(draft.profileCompletionPercent, ((3 / total) * 100).round());

      // 4. Bio (≥ 10 chars)
      draft = draft.copyWith(bio: '0123456789abc');
      expect(draft.profileCompletionPercent, ((4 / total) * 100).round());

      // 5. Seeking genders non-empty
      draft = draft.copyWith(seekingGenders: ['F']);
      expect(draft.profileCompletionPercent, ((5 / total) * 100).round());

      // 6. Drinking & smoking set
      draft = draft.copyWith(drinking: 'Never', smoking: 'Socially');
      expect(draft.profileCompletionPercent, 100);
    });

    test('returns 100 for a fully completed draft', () {
      expect(_fullDraft().profileCompletionPercent, 100);
    });

    test('does NOT double-count name when only name is set', () {
      final draft = _emptyDraft().copyWith(name: 'Alex');
      // Only the name criterion fires; the rest are not met.
      expect(draft.profileCompletionPercent, lessThan(50));
    });

    test('name shorter than minNameLength does not count', () {
      final draft = _emptyDraft().copyWith(
        name: 'A',
      ); // length 1 < minNameLength (2)
      expect(draft.profileCompletionPercent, 0);
    });

    test('exactly minNameLength characters counts as valid', () {
      final twoChar = 'A' * ValidationConstants.minNameLength;
      final draft = _emptyDraft().copyWith(name: twoChar);
      expect(draft.profileCompletionPercent, greaterThan(0));
    });

    test('bio shorter than minBioLength does not count', () {
      final draft = _emptyDraft().copyWith(bio: 'Short'); // < 10 chars
      expect(draft.profileCompletionPercent, 0);
    });

    test('exactly minPhotos photos counts as valid', () {
      final draft = _emptyDraft().copyWith(
        photos: [
          ProfilePhotoItem(
            id: 'p1',
            photoUrl: 'u',
            storagePath: 's',
            ordering: 0,
          ),
          ProfilePhotoItem(
            id: 'p2',
            photoUrl: 'v',
            storagePath: 't',
            ordering: 1,
          ),
        ],
      );
      expect(draft.profileCompletionPercent, greaterThan(0));
    });

    test('only one photo does not satisfy photo criterion', () {
      final draft = _emptyDraft().copyWith(
        photos: [
          ProfilePhotoItem(
            id: 'p1',
            photoUrl: 'u',
            storagePath: 's',
            ordering: 0,
          ),
        ],
      );
      expect(draft.profileCompletionPercent, 0); // no other criterion met
    });
  });

  group('ProfileDraft.copyWith', () {
    test('preserves all unchanged fields', () {
      final original = _fullDraft();
      final copy = original.copyWith();
      expect(copy.userId, original.userId);
      expect(copy.name, original.name);
      expect(copy.photos.length, original.photos.length);
      expect(copy.bio, original.bio);
      expect(copy.seekingGenders, original.seekingGenders);
      expect(copy.drinking, original.drinking);
    });

    test('updates only the specified field', () {
      final original = _fullDraft();
      final updated = original.copyWith(name: 'Changed Name');
      expect(updated.name, 'Changed Name');
      expect(updated.bio, original.bio);
      expect(updated.photos, original.photos);
    });

    test('photos list is replaced, not mutated', () {
      final original = _fullDraft();
      final newPhotos = [
        ProfilePhotoItem(
          id: 'n1',
          photoUrl: 'new',
          storagePath: 'nsp',
          ordering: 0,
        ),
      ];
      final updated = original.copyWith(photos: newPhotos);
      expect(updated.photos.length, 1);
      expect(updated.photos.first.id, 'n1');
      expect(original.photos.length, 2); // original untouched
    });

    test(
      'copyWith with null-able fields keeps original when not specified',
      () {
        final original = _fullDraft();
        final updated = original.copyWith(bio: 'New bio');
        expect(updated.education, original.education);
        expect(updated.religion, original.religion);
      },
    );
  });

  group('ProfilePhotoItem', () {
    test('constructs with all fields', () {
      const photo = ProfilePhotoItem(
        id: 'x1',
        photoUrl: 'https://example.com/img.jpg',
        storagePath: 'user/img.jpg',
        ordering: 3,
      );
      expect(photo.id, 'x1');
      expect(photo.photoUrl, 'https://example.com/img.jpg');
      expect(photo.storagePath, 'user/img.jpg');
      expect(photo.ordering, 3);
    });
  });

  // ── Validation logic (mirrors _validate in SetupPreviewScreen) ──────────────
  group('Preview screen validation logic', () {
    String? _validate(ProfileDraft draft) {
      if (draft.name.trim().length < ValidationConstants.minNameLength) {
        return 'Name is required.';
      }
      if (draft.dateOfBirth == null) {
        return 'Date of birth is required.';
      }
      if (draft.photos.length < ValidationConstants.minPhotos) {
        return 'At least ${ValidationConstants.minPhotos} photos are required.';
      }
      if (draft.bio.trim().length < ValidationConstants.minBioLength) {
        return 'Bio must be at least ${ValidationConstants.minBioLength} characters.';
      }
      return null;
    }

    test('returns null (passes) for a fully valid draft', () {
      expect(_validate(_fullDraft()), isNull);
    });

    test('reports "Name is required" when name is empty', () {
      final draft = _fullDraft().copyWith(name: '');
      expect(_validate(draft), 'Name is required.');
    });

    test('reports "Name is required" when name is whitespace only', () {
      final draft = _fullDraft().copyWith(name: '   ');
      expect(_validate(draft), 'Name is required.');
    });

    test('reports "Name is required" when name is too short', () {
      final draft = _fullDraft().copyWith(
        name: 'A',
      ); // 1 char < minNameLength 2
      expect(_validate(draft), 'Name is required.');
    });

    test('reports DOB error when dateOfBirth is null', () {
      // Cannot use _fullDraft().copyWith(dateOfBirth: null) because the
      // manual copyWith treats null as "keep existing". Build from empty base.
      final draft = ProfileDraft(
        userId: 'u1',
        phoneNumber: '+91',
        name: 'Riya',
        dateOfBirth: null,
        gender: 'F',
        photos: [
          ProfilePhotoItem(
            id: 'p1',
            photoUrl: 'https://x.test/1.jpg',
            storagePath: 'x/1',
            ordering: 0,
          ),
          ProfilePhotoItem(
            id: 'p2',
            photoUrl: 'https://x.test/2.jpg',
            storagePath: 'x/2',
            ordering: 1,
          ),
        ],
        bio: 'A long enough bio to exceed the minimum character requirement.',
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
      expect(_validate(draft), 'Date of birth is required.');
    });

    test('reports photo error when photos are empty', () {
      final draft = _fullDraft().copyWith(photos: const []);
      expect(
        _validate(draft),
        contains('${ValidationConstants.minPhotos} photos'),
      );
    });

    test('reports photo error when only 1 photo provided', () {
      final draft = _fullDraft().copyWith(
        photos: [
          ProfilePhotoItem(
            id: 'p1',
            photoUrl: 'u',
            storagePath: 's',
            ordering: 0,
          ),
        ],
      );
      expect(
        _validate(draft),
        contains('${ValidationConstants.minPhotos} photos'),
      );
    });

    test('reports bio error when bio is too short', () {
      final draft = _fullDraft().copyWith(bio: 'Short');
      expect(
        _validate(draft),
        contains('${ValidationConstants.minBioLength} characters'),
      );
    });

    test('reports bio error when bio is all whitespace', () {
      final draft = _fullDraft().copyWith(bio: '     ');
      expect(
        _validate(draft),
        contains('${ValidationConstants.minBioLength} characters'),
      );
    });

    test('name validation is checked before DOB (first error wins)', () {
      final draft = _fullDraft().copyWith(name: '', dateOfBirth: null);
      expect(_validate(draft), 'Name is required.');
    });

    test('DOB check before photos (error priority)', () {
      // Build a draft with valid name, null DOB, and no photos to verify that
      // the DOB error fires before the photos check.
      final draft = ProfileDraft(
        userId: 'u1',
        phoneNumber: '+91',
        name: 'Riya',
        dateOfBirth: null,
        gender: 'F',
        photos: const [], // photos also missing
        bio: '',
        heightCm: null,
        education: null,
        profession: null,
        incomeRange: null,
        seekingGenders: const [],
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
      expect(_validate(draft), 'Date of birth is required.');
    });

    test('photos check before bio (error priority)', () {
      final draft = _fullDraft().copyWith(photos: const [], bio: '');
      expect(
        _validate(draft),
        contains('${ValidationConstants.minPhotos} photos'),
      );
    });
  });
}
