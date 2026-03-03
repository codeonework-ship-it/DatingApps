import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/config/app_runtime_config.dart';
import '../../../core/config/feature_flags.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../core/utils/logger.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/profile_setup_provider.dart';
import '../models/discovery_profile.dart';

part 'swipe_provider.g.dart';

/// Swipe State
class SwipeState {
  const SwipeState({
    this.profiles = const [],
    this.passedProfiles = const [],
    this.currentIndex = 0,
    this.isLoading = false,
    this.error,
    this.likeCount = 0,
    this.passCount = 0,
    this.trustFilterActive = false,
    this.trustFilteredOutCount = 0,
  });
  final List<DiscoveryProfile> profiles;
  final List<DiscoveryProfile> passedProfiles;
  final int currentIndex;
  final bool isLoading;
  final String? error;
  final int likeCount;
  final int passCount;
  final bool trustFilterActive;
  final int trustFilteredOutCount;

  SwipeState copyWith({
    List<DiscoveryProfile>? profiles,
    List<DiscoveryProfile>? passedProfiles,
    int? currentIndex,
    bool? isLoading,
    String? error,
    int? likeCount,
    int? passCount,
    bool? trustFilterActive,
    int? trustFilteredOutCount,
  }) => SwipeState(
    profiles: profiles ?? this.profiles,
    passedProfiles: passedProfiles ?? this.passedProfiles,
    currentIndex: currentIndex ?? this.currentIndex,
    isLoading: isLoading ?? this.isLoading,
    error: error ?? this.error,
    likeCount: likeCount ?? this.likeCount,
    passCount: passCount ?? this.passCount,
    trustFilterActive: trustFilterActive ?? this.trustFilterActive,
    trustFilteredOutCount: trustFilteredOutCount ?? this.trustFilteredOutCount,
  );
}

/// Swipe Provider
@riverpod
class SwipeNotifier extends _$SwipeNotifier {
  Set<String> get _mockMatchedProfileIds => AppRuntimeConfig.matchedProfileIds;
  Map<String, String> _manualFilters = const <String, String>{};

  @override
  SwipeState build() {
    Future<void>.microtask(_loadProfiles);
    return const SwipeState(isLoading: true);
  }

  /// Load profiles from gateway API
  Future<void> _loadProfiles() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      if (kUseMockAuth) {
        await Future<void>.delayed(const Duration(milliseconds: 220));
        state = state.copyWith(
          profiles: _mockProfiles,
          currentIndex: 0,
          isLoading: false,
          error: null,
          trustFilterActive: false,
          trustFilteredOutCount: 0,
        );
        return;
      }

      final authState = ref.read(authNotifierProvider);
      final currentUserId = authState.userId;
      if (currentUserId == null) {
        state = state.copyWith(
          profiles: const [],
          isLoading: false,
          error: 'Please login to discover profiles.',
        );
        return;
      }

      final dio = ref.read(apiClientProvider);
      final queryParameters = <String, dynamic>{'limit': 50};
      final draftValue = ref.read(profileSetupNotifierProvider);
      final draft = draftValue.valueOrNull;
      if (draft != null) {
        if (draft.intentTags.isNotEmpty) {
          queryParameters['intent_tags'] = draft.intentTags.join(',');
        }
        if (draft.languageTags.isNotEmpty) {
          queryParameters['language_tags'] = draft.languageTags.join(',');
        }
        if ((draft.petPreference ?? '').trim().isNotEmpty) {
          queryParameters['pet_preference'] = draft.petPreference;
        }
        if ((draft.dietPreference ?? '').trim().isNotEmpty) {
          queryParameters['diet_preference'] = draft.dietPreference;
        }
        if ((draft.workoutFrequency ?? '').trim().isNotEmpty) {
          queryParameters['workout_frequency'] = draft.workoutFrequency;
        }
        if ((draft.dietType ?? '').trim().isNotEmpty) {
          queryParameters['diet_type'] = draft.dietType;
        }
        if ((draft.sleepSchedule ?? '').trim().isNotEmpty) {
          queryParameters['sleep_schedule'] = draft.sleepSchedule;
        }
        if ((draft.travelStyle ?? '').trim().isNotEmpty) {
          queryParameters['travel_style'] = draft.travelStyle;
        }
        if ((draft.politicalComfortRange ?? '').trim().isNotEmpty) {
          queryParameters['political_comfort_range'] =
              draft.politicalComfortRange;
        }
        if (draft.dealBreakerTags.isNotEmpty) {
          queryParameters['deal_breaker_tags'] = draft.dealBreakerTags.join(
            ',',
          );
        }
        if ((draft.country ?? '').trim().isNotEmpty) {
          queryParameters['country'] = draft.country;
        }
        if ((draft.regionState ?? '').trim().isNotEmpty) {
          queryParameters['state'] = draft.regionState;
        }
        if ((draft.city ?? '').trim().isNotEmpty) {
          queryParameters['city'] = draft.city;
        }
        if (draft.hookupOnly) {
          queryParameters['hookup_only'] = 'true';
        }
      }
      for (final entry in _manualFilters.entries) {
        queryParameters[entry.key] = entry.value;
      }
      final response = await dio.get<Map<String, dynamic>>(
        '/discovery/$currentUserId',
        queryParameters: queryParameters,
      );
      final body =
          (response.data as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      final raw = (body['candidates'] as List?) ?? const [];
      final trustFilter =
          (body['trust_filter'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{};

      final profiles = raw
          .whereType<Map<String, dynamic>>()
          .map((row) {
            final map = row;
            final photoList =
                (map['photoUrls'] as List?)
                    ?.map((e) => e.toString())
                    .toList() ??
                const <String>[];
            final dob =
                DateTime.tryParse(map['dateOfBirth']?.toString() ?? '') ??
                DateTime(1998, 1, 1);
            return DiscoveryProfile(
              id: map['id']?.toString() ?? '',
              name: map['name']?.toString() ?? 'Unknown',
              dateOfBirth: dob,
              bio: map['bio']?.toString(),
              additionalInfo: map['additional_info']?.toString(),
              profession: map['profession']?.toString(),
              education: map['education']?.toString(),
              instagramHandle: map['instagram_handle']?.toString(),
              hobbies: ((map['hobbies'] as List?) ?? const [])
                  .map((e) => e.toString())
                  .where((e) => e.trim().isNotEmpty)
                  .toList(),
              favoriteSongs: ((map['favorite_songs'] as List?) ?? const [])
                  .map((e) => e.toString())
                  .where((e) => e.trim().isNotEmpty)
                  .toList(),
              extraCurriculars:
                  ((map['extra_curriculars'] as List?) ?? const [])
                      .map((e) => e.toString())
                      .where((e) => e.trim().isNotEmpty)
                      .toList(),
              intentTags: ((map['intent_tags'] as List?) ?? const [])
                  .map((e) => e.toString())
                  .where((e) => e.trim().isNotEmpty)
                  .toList(),
              languageTags: ((map['language_tags'] as List?) ?? const [])
                  .map((e) => e.toString())
                  .where((e) => e.trim().isNotEmpty)
                  .toList(),
              isVerified: map['isVerified'] == true,
              photoUrls: photoList.isEmpty
                  ? <String>[AppRuntimeConfig.placeholderProfileImageUrl]
                  : photoList,
            );
          })
          .where((profile) => profile.id.isNotEmpty)
          .toList();

      state = state.copyWith(
        profiles: profiles,
        currentIndex: 0,
        isLoading: false,
        error: null,
        trustFilterActive: trustFilter['active'] == true,
        trustFilteredOutCount:
            (trustFilter['filtered_out_count'] as num?)?.toInt() ?? 0,
      );
    } on DioException catch (e, stackTrace) {
      log.error('Failed to load profiles', e, stackTrace);
      final data = e.response?.data;
      final message = data is Map && data['error'] != null
          ? data['error'].toString()
          : 'Failed to load profiles. Please try again.';
      state = state.copyWith(error: message, isLoading: false);
    } catch (e, stackTrace) {
      log.error('Failed to load profiles', e, stackTrace);
      state = state.copyWith(
        error: 'Failed to load profiles. Please try again.',
        isLoading: false,
      );
    }
  }

  /// Like current profile
  Future<String?> likeProfile() async {
    if (state.currentIndex >= state.profiles.length) return null;

    try {
      final targetUserId = state.profiles[state.currentIndex].id;
      final currentUserId = ref.read(authNotifierProvider).userId;
      if (currentUserId == null) return null;

      if (kUseMockAuth) {
        state = state.copyWith(
          currentIndex: state.currentIndex + 1,
          likeCount: state.likeCount + 1,
        );
        if (_mockMatchedProfileIds.contains(targetUserId)) {
          return 'mock-match-$targetUserId';
        }
        return null;
      }

      final dio = ref.read(apiClientProvider);
      final response = await dio.post<Map<String, dynamic>>(
        '/swipe',
        data: {
          'user_id': currentUserId,
          'target_user_id': targetUserId,
          'is_like': true,
        },
      );
      final body =
          (response.data as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      final matchID = body['match_id']?.toString();

      state = state.copyWith(
        currentIndex: state.currentIndex + 1,
        likeCount: state.likeCount + 1,
      );
      return (matchID == null || matchID.isEmpty) ? null : matchID;
    } on DioException catch (e, stackTrace) {
      log.error('Failed to like profile', e, stackTrace);
      state = state.copyWith(error: 'Failed to like profile.');
      return null;
    } catch (e, stackTrace) {
      log.error('Failed to like profile', e, stackTrace);
      state = state.copyWith(error: 'Failed to like profile.');
      return null;
    }
  }

  /// Pass current profile
  Future<void> passProfile() async {
    if (state.currentIndex >= state.profiles.length) return;

    try {
      final targetProfile = state.profiles[state.currentIndex];
      final targetUserId = targetProfile.id;
      final currentUserId = ref.read(authNotifierProvider).userId;
      if (currentUserId == null) return;

      final updatedPassedProfiles = <DiscoveryProfile>[
        targetProfile,
        ...state.passedProfiles.where((item) => item.id != targetProfile.id),
      ];

      state = state.copyWith(
        currentIndex: state.currentIndex + 1,
        passCount: state.passCount + 1,
        passedProfiles: updatedPassedProfiles,
      );

      if (!kUseMockAuth) {
        final dio = ref.read(apiClientProvider);
        await dio.post<void>(
          '/swipe',
          data: {
            'user_id': currentUserId,
            'target_user_id': targetUserId,
            'is_like': false,
          },
        );
      }
    } on DioException catch (e, stackTrace) {
      log.error('Failed to pass profile', e, stackTrace);
      state = state.copyWith(
        error: 'Saved for later. Sync failed, will retry.',
      );
    } catch (e, stackTrace) {
      log.error('Failed to pass profile', e, stackTrace);
      state = state.copyWith(
        error: 'Saved for later. Sync failed, will retry.',
      );
    }
  }

  /// Undo last swipe
  Future<void> undoSwipe() async {
    if (state.currentIndex > 0) {
      state = state.copyWith(currentIndex: state.currentIndex - 1);
    }
  }

  /// Refresh profiles
  Future<void> refreshProfiles() async {
    state = state.copyWith(currentIndex: 0);
    await _loadProfiles();
  }

  Future<void> recordProfileView(String viewedUserId) async {
    if (viewedUserId.trim().isEmpty) return;

    try {
      final viewerUserId = ref.read(authNotifierProvider).userId;
      if (viewerUserId == null || viewerUserId.isEmpty) return;
      if (viewerUserId == viewedUserId) return;

      if (kUseMockAuth) {
        return;
      }

      final dio = ref.read(apiClientProvider);
      await dio.post<void>(
        '/profile/views',
        data: {'viewer_user_id': viewerUserId, 'viewed_user_id': viewedUserId},
      );
    } catch (e, stackTrace) {
      log.error('Failed to record profile view', e, stackTrace);
    }
  }

  void setManualFilters(Map<String, String> filters) {
    _manualFilters = Map<String, String>.from(filters);
  }
}

final _mockProfiles = _generateMockProfiles();

List<DiscoveryProfile> _generateMockProfiles() {
  final femaleCount = AppRuntimeConfig.mockFemaleUsersCount;
  final maleCount = AppRuntimeConfig.mockMaleUsersCount;
  final minAge = AppRuntimeConfig.mockMinAgeYears;
  final maxAge = AppRuntimeConfig.mockMaxAgeYears;
  final lowerAge = minAge <= maxAge ? minAge : maxAge;
  final upperAge = maxAge >= minAge ? maxAge : minAge;
  final ageSpan = (upperAge - lowerAge) + 1;

  final femaleNames = <String>[
    'Anya',
    'Rhea',
    'Mira',
    'Nina',
    'Sara',
    'Ira',
    'Lia',
    'Tara',
    'Ava',
    'Zara',
  ];
  final maleNames = <String>[
    'Arjun',
    'Rohan',
    'Kian',
    'Noah',
    'Rey',
    'Vihaan',
    'Ishan',
    'Kabir',
    'Aarav',
    'Dev',
  ];
  final professions = <String>[
    'Product Designer',
    'Software Engineer',
    'Marketing Lead',
    'Doctor',
    'Architect',
    'Data Analyst',
    'Teacher',
    'Photographer',
  ];
  final educations = <String>['B.Tech', 'MBA', 'B.Des', 'B.Sc', 'M.Tech', 'BA'];
  final bios = <String>[
    'Loves weekend coffee walks and honest conversations.',
    'Into travel, books, and long evening drives.',
    'Fitness-focused, family-oriented, and career-driven.',
    'Enjoys music gigs, food trails, and meaningful connections.',
    'Prefers calm weekends, hiking, and quality time.',
  ];
  final hobbies = <String>[
    'Travel',
    'Music',
    'Cooking',
    'Hiking',
    'Photography',
  ];
  final songs = <String>['Golden Hour', 'Ilahi', 'Kesariya', 'Blinding Lights'];
  final activities = <String>[
    'Community volunteering',
    'Weekend sports',
    'Book club',
    'Yoga sessions',
  ];
  final intents = <String>['long_term', 'marriage', 'new_friends'];
  final languages = <String>['English', 'Hindi', 'Tamil'];

  DateTime dobForAge(int age, int offset) {
    final now = DateTime.now();
    return DateTime(now.year - age, 1, 1);
  }

  List<DiscoveryProfile> buildGroup({
    required String prefix,
    required int count,
    required List<String> names,
    required int groupOffset,
  }) {
    final profiles = <DiscoveryProfile>[];
    for (var i = 0; i < count; i++) {
      final id = '$prefix-${(i + 1).toString().padLeft(3, '0')}';
      final age = lowerAge + (i % ageSpan);
      profiles.add(
        DiscoveryProfile(
          id: id,
          name: names[i % names.length],
          dateOfBirth: dobForAge(age, i + groupOffset),
          bio: bios[i % bios.length],
          additionalInfo:
              'Enjoys meaningful conversations and steady connection-building.',
          profession: professions[i % professions.length],
          education: educations[i % educations.length],
          instagramHandle: '@${names[i % names.length].toLowerCase()}_${i + 1}',
          hobbies: <String>[hobbies[i % hobbies.length]],
          favoriteSongs: <String>[songs[i % songs.length]],
          extraCurriculars: <String>[activities[i % activities.length]],
          intentTags: <String>[intents[i % intents.length]],
          languageTags: <String>[languages[i % languages.length]],
          isVerified: i % 3 != 0,
          photoUrls: <String>[
            'https://picsum.photos/seed/$id-1/900/1200',
            'https://picsum.photos/seed/$id-2/900/1200',
          ],
        ),
      );
    }
    return profiles;
  }

  final females = buildGroup(
    prefix: 'mock-female',
    count: femaleCount,
    names: femaleNames,
    groupOffset: 0,
  );
  final males = buildGroup(
    prefix: 'mock-male',
    count: maleCount,
    names: maleNames,
    groupOffset: femaleCount,
  );

  return <DiscoveryProfile>[...females, ...males];
}
