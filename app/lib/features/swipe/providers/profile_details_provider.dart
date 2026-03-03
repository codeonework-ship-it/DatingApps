import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_runtime_config.dart';
import '../../../core/config/feature_flags.dart';
import '../../../core/providers/api_client_provider.dart';

class ProfileDetails {
  const ProfileDetails({
    required this.userId,
    required this.name,
    required this.dateOfBirth,
    required this.gender,
    required this.bio,
    required this.additionalInfo,
    required this.heightCm,
    required this.education,
    required this.profession,
    required this.drinking,
    required this.smoking,
    required this.religion,
    required this.motherTongue,
    required this.relationshipStatus,
    required this.personalityType,
    required this.partyLover,
    required this.country,
    required this.regionState,
    required this.city,
    required this.instagramHandle,
    required this.hobbies,
    required this.favoriteBooks,
    required this.favoriteNovels,
    required this.favoriteSongs,
    required this.extraCurriculars,
    required this.intentTags,
    required this.languageTags,
    required this.isVerified,
    required this.photoUrls,
    this.petPreference,
    this.dietPreference,
    this.workoutFrequency,
    this.dietType,
    this.sleepSchedule,
    this.travelStyle,
    this.politicalComfortRange,
    this.hookupOnly,
    this.dealBreakerTags = const <String>[],
  });
  final String userId;
  final String name;
  final DateTime dateOfBirth;
  final String gender;
  final String? bio;
  final String? additionalInfo;
  final int? heightCm;
  final String? education;
  final String? profession;
  final String? drinking;
  final String? smoking;
  final String? religion;
  final String? motherTongue;
  final String? relationshipStatus;
  final String? personalityType;
  final bool partyLover;
  final String? country;
  final String? regionState;
  final String? city;
  final String? instagramHandle;
  final List<String> hobbies;
  final List<String> favoriteBooks;
  final List<String> favoriteNovels;
  final List<String> favoriteSongs;
  final List<String> extraCurriculars;
  final List<String> intentTags;
  final List<String> languageTags;
  final bool isVerified;
  final List<String> photoUrls;
  final String? petPreference;
  final String? dietPreference;
  final String? workoutFrequency;
  final String? dietType;
  final String? sleepSchedule;
  final String? travelStyle;
  final String? politicalComfortRange;
  final bool? hookupOnly;
  final List<String> dealBreakerTags;

  int get age {
    final now = DateTime.now();
    var a = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      a--;
    }
    return a;
  }
}

final profileDetailsProvider = FutureProvider.family<ProfileDetails, String>((
  ref,
  userId,
) async {
  if (kUseMockAuth) {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return _mockProfileDetailsFor(userId);
  }

  try {
    final dio = ref.read(apiClientProvider);
    final response = await dio.get<Map<String, dynamic>>('/profile/$userId');
    final body =
        (response.data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final profile =
        (body['profile'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};

    var draft = <String, dynamic>{};
    try {
      final draftResponse = await dio.get<Map<String, dynamic>>(
        '/profile/$userId/draft',
      );
      final draftBody =
          (draftResponse.data as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      draft =
          (draftBody['draft'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
    } on DioException {
      draft = <String, dynamic>{};
    }

    final photoUrls = _resolvePhotoUrls(profile, draft);

    return ProfileDetails(
      userId: profile['id']?.toString() ?? userId,
      name: profile['name']?.toString() ?? 'User',
      dateOfBirth:
          DateTime.tryParse(profile['dateOfBirth']?.toString() ?? '') ??
          DateTime(1998, 1, 1),
      gender: profile['gender']?.toString() ?? 'Other',
      bio: _firstString(profile, draft, const ['bio']),
      additionalInfo: _firstString(profile, draft, const [
        'additional_info',
        'additionalInfo',
      ]),
      heightCm: (profile['heightCm'] as num?)?.toInt(),
      education: profile['education']?.toString(),
      profession: profile['profession']?.toString(),
      drinking: profile['drinking']?.toString(),
      smoking: profile['smoking']?.toString(),
      religion: _firstString(profile, draft, const ['religion']),
      motherTongue: _firstString(profile, draft, const [
        'mother_tongue',
        'motherTongue',
      ]),
      relationshipStatus: _firstString(profile, draft, const [
        'relationship_status',
        'relationshipStatus',
      ]),
      personalityType: _firstString(profile, draft, const [
        'personality_type',
        'personalityType',
      ]),
      partyLover: _firstBool(profile, draft, const [
        'party_lover',
        'partyLover',
      ]),
      country: _firstString(profile, draft, const ['country']),
      regionState: _firstString(profile, draft, const ['state', 'regionState']),
      city: _firstString(profile, draft, const ['city']),
      instagramHandle: _firstString(profile, draft, const [
        'instagram_handle',
        'instagramHandle',
      ]),
      hobbies: _firstStringList(profile, draft, const ['hobbies']),
      favoriteBooks: _firstStringList(profile, draft, const [
        'favorite_books',
        'favoriteBooks',
      ]),
      favoriteNovels: _firstStringList(profile, draft, const [
        'favorite_novels',
        'favoriteNovels',
      ]),
      favoriteSongs: _firstStringList(profile, draft, const [
        'favorite_songs',
        'favoriteSongs',
      ]),
      extraCurriculars: _firstStringList(profile, draft, const [
        'extra_curriculars',
        'extraCurriculars',
      ]),
      intentTags: _firstStringList(profile, draft, const [
        'intent_tags',
        'intentTags',
      ]),
      languageTags: _firstStringList(profile, draft, const [
        'language_tags',
        'languageTags',
      ]),
      isVerified: profile['isVerified'] == true,
      photoUrls: photoUrls.isEmpty
          ? <String>[AppRuntimeConfig.placeholderProfileImageUrl]
          : photoUrls,
      petPreference: _firstString(profile, draft, const [
        'pet_preference',
        'petPreference',
      ]),
      dietPreference: _firstString(profile, draft, const [
        'diet_preference',
        'dietPreference',
      ]),
      workoutFrequency: _firstString(profile, draft, const [
        'workout_frequency',
        'workoutFrequency',
      ]),
      dietType: _firstString(profile, draft, const ['diet_type', 'dietType']),
      sleepSchedule: _firstString(profile, draft, const [
        'sleep_schedule',
        'sleepSchedule',
      ]),
      travelStyle: _firstString(profile, draft, const [
        'travel_style',
        'travelStyle',
      ]),
      politicalComfortRange: _firstString(profile, draft, const [
        'political_comfort_range',
        'politicalComfortRange',
      ]),
      hookupOnly: _firstNullableBool(profile, draft, const [
        'hookup_only',
        'hookupOnly',
      ]),
      dealBreakerTags: _firstStringList(profile, draft, const [
        'deal_breaker_tags',
        'dealBreakerTags',
      ]),
    );
  } on DioException {
    return _mockProfileDetailsFor(userId);
  }
});

ProfileDetails _mockProfileDetailsFor(String userId) {
  final mock = <String, ProfileDetails>{
    'mock-user-002': ProfileDetails(
      userId: 'mock-user-002',
      name: 'Anya',
      dateOfBirth: DateTime(1997, 4, 12),
      gender: 'F',
      bio: 'Product designer who loves hiking and filter coffee.',
      additionalInfo: 'I enjoy sunrise walks, indie cinema, and journaling.',
      heightCm: 165,
      education: 'B.Des',
      profession: 'Product Designer',
      drinking: 'Occasionally',
      smoking: 'No',
      religion: 'Spiritual',
      motherTongue: 'Hindi',
      relationshipStatus: 'Single',
      personalityType: 'Ambivert',
      partyLover: false,
      country: 'India',
      regionState: 'Karnataka',
      city: 'Bengaluru',
      instagramHandle: '@anya.designs',
      hobbies: const <String>['Hiking', 'Sketching', 'Coffee tasting'],
      favoriteBooks: const <String>['Atomic Habits'],
      favoriteNovels: const <String>['The Night Circus'],
      favoriteSongs: const <String>['Golden Hour', 'Kesariya'],
      extraCurriculars: const <String>['Volunteer teaching', 'Community runs'],
      intentTags: const <String>['long_term'],
      languageTags: const <String>['English', 'Hindi'],
      isVerified: true,
      photoUrls: const <String>[
        'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=900&q=80',
        'https://images.unsplash.com/photo-1521119989659-a83eee488004?auto=format&fit=crop&w=900&q=80',
      ],
    ),
    'mock-user-003': ProfileDetails(
      userId: 'mock-user-003',
      name: 'Rhea',
      dateOfBirth: DateTime(1999, 9, 3),
      gender: 'F',
      bio: 'Runner, reader, and weekend road-tripper.',
      additionalInfo:
          'Looking for meaningful conversations and consistent effort.',
      heightCm: 170,
      education: 'MBA',
      profession: 'Marketing Lead',
      drinking: 'No',
      smoking: 'No',
      religion: 'Hindu',
      motherTongue: 'Marathi',
      relationshipStatus: 'Single',
      personalityType: 'Introvert',
      partyLover: false,
      country: 'India',
      regionState: 'Maharashtra',
      city: 'Pune',
      instagramHandle: '@rhea.moves',
      hobbies: const <String>['Running', 'Reading'],
      favoriteBooks: const <String>['Deep Work'],
      favoriteNovels: const <String>['The Alchemist'],
      favoriteSongs: const <String>['Ilahi'],
      extraCurriculars: const <String>['Marathon volunteering'],
      intentTags: const <String>['marriage'],
      languageTags: const <String>['English', 'Marathi'],
      isVerified: false,
      photoUrls: const <String>[
        'https://images.unsplash.com/photo-1521572267360-ee0c2909d518?auto=format&fit=crop&w=900&q=80',
        'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?auto=format&fit=crop&w=900&q=80',
      ],
    ),
    'mock-user-004': ProfileDetails(
      userId: 'mock-user-004',
      name: 'Mira',
      dateOfBirth: DateTime(1995, 1, 18),
      gender: 'F',
      bio: 'Travel filmmaker and dog person.',
      additionalInfo: 'Big on shared values, kindness, and curiosity.',
      heightCm: 168,
      education: 'BA Visual Media',
      profession: 'Content Creator',
      drinking: 'Socially',
      smoking: 'No',
      religion: 'Christian',
      motherTongue: 'Konkani',
      relationshipStatus: 'Single',
      personalityType: 'Extrovert',
      partyLover: true,
      country: 'India',
      regionState: 'Goa',
      city: 'Panaji',
      instagramHandle: '@mira.frames',
      hobbies: const <String>['Filmmaking', 'Pet care'],
      favoriteBooks: const <String>['Show Your Work'],
      favoriteNovels: const <String>['Normal People'],
      favoriteSongs: const <String>['A Sky Full of Stars'],
      extraCurriculars: const <String>['Animal shelter volunteer'],
      intentTags: const <String>['long_term'],
      languageTags: const <String>['English'],
      isVerified: true,
      photoUrls: const <String>[
        'https://images.unsplash.com/photo-1544723795-3fb6469f5b39?auto=format&fit=crop&w=900&q=80',
        'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?auto=format&fit=crop&w=900&q=80',
      ],
    ),
  };

  if (userId.startsWith('mock-female-') || userId.startsWith('mock-male-')) {
    return _generatedMockProfileDetails(userId);
  }

  return mock[userId] ??
      ProfileDetails(
        userId: userId,
        name: 'User',
        dateOfBirth: DateTime(1998, 1, 1),
        gender: 'Other',
        bio: 'Mock profile details.',
        additionalInfo: null,
        heightCm: null,
        education: null,
        profession: null,
        drinking: null,
        smoking: null,
        religion: null,
        motherTongue: null,
        relationshipStatus: null,
        personalityType: null,
        partyLover: false,
        country: null,
        regionState: null,
        city: null,
        instagramHandle: null,
        hobbies: const <String>[],
        favoriteBooks: const <String>[],
        favoriteNovels: const <String>[],
        favoriteSongs: const <String>[],
        extraCurriculars: const <String>[],
        intentTags: const <String>[],
        languageTags: const <String>[],
        isVerified: false,
        photoUrls: const <String>[
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=900&q=80',
        ],
      );
}

bool? _firstNullableBool(
  Map<String, dynamic> profile,
  Map<String, dynamic> draft,
  List<String> keys,
) {
  for (final key in keys) {
    final pValue = profile[key];
    if (pValue is bool) {
      return pValue;
    }
    final dValue = draft[key];
    if (dValue is bool) {
      return dValue;
    }
  }
  return null;
}

ProfileDetails _generatedMockProfileDetails(String userId) {
  final female = userId.startsWith('mock-female-');
  final seed = userId
      .replaceAll('mock-female-', '')
      .replaceAll('mock-male-', '')
      .padLeft(3, '0');
  final ordinal = int.tryParse(seed) ?? 1;

  final namesF = <String>['Anya', 'Rhea', 'Mira', 'Ira', 'Tara', 'Naina'];
  final namesM = <String>['Arjun', 'Karan', 'Neil', 'Rohan', 'Aman', 'Dev'];
  final cities = <String>['Bengaluru', 'Pune', 'Mumbai', 'Hyderabad'];
  final states = <String>[
    'Karnataka',
    'Maharashtra',
    'Maharashtra',
    'Telangana',
  ];
  final books = <String>[
    'Atomic Habits',
    'Deep Work',
    'Ikigai',
    'The Almanack of Naval',
  ];
  final novels = <String>[
    'The Alchemist',
    'Normal People',
    'The Kite Runner',
    'Norwegian Wood',
  ];
  final songs = <String>[
    'Golden Hour',
    'Ilahi',
    'Kesariya',
    'A Sky Full of Stars',
  ];
  final activities = <String>[
    'Community volunteering',
    'Weekend cycling',
    'Book club',
    'Fitness group',
  ];
  final hobbies = <String>['Travel', 'Reading', 'Photography', 'Cooking'];

  final idx = ordinal % cities.length;
  final name = female
      ? namesF[ordinal % namesF.length]
      : namesM[ordinal % namesM.length];

  return ProfileDetails(
    userId: userId,
    name: name,
    dateOfBirth: DateTime(
      1994 + (ordinal % 8),
      (ordinal % 12) + 1,
      (ordinal % 27) + 1,
    ),
    gender: female ? 'F' : 'M',
    bio:
        '${female ? 'Creative' : 'Ambitious'} professional who values consistency, kindness, and meaningful conversations.',
    additionalInfo:
        'Looking for someone genuine. Big fan of balanced routines and shared growth.',
    heightCm: female ? 160 + (ordinal % 10) : 170 + (ordinal % 12),
    education: female ? 'MBA' : 'B.Tech',
    profession: female ? 'Product Designer' : 'Software Engineer',
    drinking: ordinal % 2 == 0 ? 'Occasionally' : 'No',
    smoking: 'No',
    religion: ordinal % 2 == 0 ? 'Hindu' : 'Spiritual',
    motherTongue: idx.isEven ? 'Hindi' : 'English',
    relationshipStatus: 'Single',
    personalityType: idx == 0
        ? 'Introvert'
        : idx == 1
        ? 'Ambivert'
        : 'Extrovert',
    partyLover: idx == 2,
    country: 'India',
    regionState: states[idx],
    city: cities[idx],
    instagramHandle: '@${name.toLowerCase()}.$seed',
    hobbies: <String>[hobbies[idx], hobbies[(idx + 1) % hobbies.length]],
    favoriteBooks: <String>[books[idx]],
    favoriteNovels: <String>[novels[idx]],
    favoriteSongs: <String>[songs[idx]],
    extraCurriculars: <String>[activities[idx]],
    intentTags: const <String>['long_term'],
    languageTags: const <String>['English', 'Hindi'],
    isVerified: ordinal % 3 != 0,
    photoUrls: List<String>.generate(
      6,
      (index) => 'https://picsum.photos/seed/${userId}_$index/900/1200',
    ),
  );
}

bool _firstBool(
  Map<String, dynamic> profile,
  Map<String, dynamic> draft,
  List<String> keys,
) {
  for (final key in keys) {
    final rawProfile = profile[key];
    if (rawProfile is bool) {
      return rawProfile;
    }
    final rawDraft = draft[key];
    if (rawDraft is bool) {
      return rawDraft;
    }
  }
  return false;
}

String? _firstString(
  Map<String, dynamic> profile,
  Map<String, dynamic> draft,
  List<String> keys,
) {
  for (final key in keys) {
    final rawProfile = profile[key];
    if (rawProfile is String && rawProfile.trim().isNotEmpty) {
      return rawProfile.trim();
    }
    final rawDraft = draft[key];
    if (rawDraft is String && rawDraft.trim().isNotEmpty) {
      return rawDraft.trim();
    }
  }
  return null;
}

List<String> _firstStringList(
  Map<String, dynamic> profile,
  Map<String, dynamic> draft,
  List<String> keys,
) {
  for (final key in keys) {
    final fromProfile = _toStringList(profile[key]);
    if (fromProfile.isNotEmpty) {
      return fromProfile;
    }
    final fromDraft = _toStringList(draft[key]);
    if (fromDraft.isNotEmpty) {
      return fromDraft;
    }
  }
  return const <String>[];
}

List<String> _toStringList(dynamic value) {
  final raw = (value as List?) ?? const [];
  return raw
      .map((item) => item?.toString().trim() ?? '')
      .where((item) => item.isNotEmpty)
      .toList();
}

List<String> _resolvePhotoUrls(
  Map<String, dynamic> profile,
  Map<String, dynamic> draft,
) {
  final fromProfile = _extractPhotoUrlsFromProfile(profile);
  final fromDraft = _extractPhotoUrlsFromDraft(draft);
  final merged = <String>[];

  for (final url in <String>[...fromProfile, ...fromDraft]) {
    if (url.isEmpty || merged.contains(url)) {
      continue;
    }
    merged.add(url);
  }

  return merged;
}

List<String> _extractPhotoUrlsFromProfile(Map<String, dynamic> profile) {
  final direct = _toStringList(profile['photoUrls']);
  if (direct.isNotEmpty) {
    return direct;
  }

  final snake = _toStringList(profile['photo_urls']);
  if (snake.isNotEmpty) {
    return snake;
  }

  return const <String>[];
}

List<String> _extractPhotoUrlsFromDraft(Map<String, dynamic> draft) {
  final photosRaw = (draft['photos'] as List?)?.cast<dynamic>() ?? const [];
  if (photosRaw.isEmpty) {
    return const <String>[];
  }

  final parsed = <({String url, int order})>[];
  for (final item in photosRaw) {
    final map = (item as Map?)?.cast<String, dynamic>();
    if (map == null) {
      continue;
    }
    final url =
        map['photo_url']?.toString().trim() ??
        map['photoUrl']?.toString().trim() ??
        '';
    if (url.isEmpty) {
      continue;
    }
    final order = (map['ordering'] as num?)?.toInt() ?? 0;
    parsed.add((url: url, order: order));
  }

  parsed.sort((a, b) => a.order.compareTo(b.order));
  return parsed.map((item) => item.url).toList();
}
