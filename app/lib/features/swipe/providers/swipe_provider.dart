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
    this.spotlightProfiles = const [],
    this.passedProfiles = const [],
    this.likedProfiles = const [],
    this.currentIndex = 0,
    this.isLoading = false,
    this.error,
    this.likeCount = 0,
    this.passCount = 0,
    this.discoveryMode = 'all',
    this.trustFilterActive = false,
    this.trustFilteredOutCount = 0,
  });
  final List<DiscoveryProfile> profiles;
  final List<DiscoveryProfile> spotlightProfiles;
  final List<DiscoveryProfile> passedProfiles;
  final List<DiscoveryProfile> likedProfiles;
  final int currentIndex;
  final bool isLoading;
  final String? error;
  final int likeCount;
  final int passCount;
  final String discoveryMode;
  final bool trustFilterActive;
  final int trustFilteredOutCount;

  SwipeState copyWith({
    List<DiscoveryProfile>? profiles,
    List<DiscoveryProfile>? spotlightProfiles,
    List<DiscoveryProfile>? passedProfiles,
    List<DiscoveryProfile>? likedProfiles,
    int? currentIndex,
    bool? isLoading,
    String? error,
    int? likeCount,
    int? passCount,
    String? discoveryMode,
    bool? trustFilterActive,
    int? trustFilteredOutCount,
  }) => SwipeState(
    profiles: profiles ?? this.profiles,
    spotlightProfiles: spotlightProfiles ?? this.spotlightProfiles,
    passedProfiles: passedProfiles ?? this.passedProfiles,
    likedProfiles: likedProfiles ?? this.likedProfiles,
    currentIndex: currentIndex ?? this.currentIndex,
    isLoading: isLoading ?? this.isLoading,
    error: error ?? this.error,
    likeCount: likeCount ?? this.likeCount,
    passCount: passCount ?? this.passCount,
    discoveryMode: discoveryMode ?? this.discoveryMode,
    trustFilterActive: trustFilterActive ?? this.trustFilterActive,
    trustFilteredOutCount: trustFilteredOutCount ?? this.trustFilteredOutCount,
  );
}

/// Swipe Provider
@riverpod
class SwipeNotifier extends _$SwipeNotifier {
  static const String discoveryModeAll = 'all';
  static const String discoveryModeSpotlight = 'spotlight';

  Set<String> get _mockMatchedProfileIds => AppRuntimeConfig.matchedProfileIds;
  Map<String, String> _manualFilters = const <String, String>{};

  bool _isRetriableSwipeError(DioException error) {
    final status = error.response?.statusCode ?? 0;
    if (status >= 500) return true;
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.unknown;
  }

  Future<Map<String, dynamic>> _postSwipeDecision({
    required String currentUserId,
    required String targetUserId,
    required bool isLike,
  }) async {
    final dio = ref.read(apiClientProvider);
    DioException? lastError;

    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await dio.post<Map<String, dynamic>>(
          '/swipe',
          data: {
            'user_id': currentUserId,
            'target_user_id': targetUserId,
            'is_like': isLike,
          },
        );
        return (response.data as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};
      } on DioException catch (e) {
        lastError = e;
        final shouldRetry = attempt == 0 && _isRetriableSwipeError(e);
        if (!shouldRetry) {
          rethrow;
        }
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
    }

    throw lastError ??
        DioException(
          requestOptions: RequestOptions(path: '/swipe'),
          message: 'Swipe request failed',
        );
  }

  @override
  SwipeState build() {
    Future<void>.microtask(_loadProfiles);
    return const SwipeState(isLoading: true);
  }

  /// Load profiles from gateway API
  Future<void> _loadProfiles() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      if (kUseMockAuth || kUseMockDiscoveryData) {
        await Future<void>.delayed(const Duration(milliseconds: 220));
        final mode = state.discoveryMode;
        final fallbackSpotlight = _mockProfiles.take(4).toList(growable: false);
        final visibleProfiles = mode == discoveryModeSpotlight
            ? fallbackSpotlight
            : _mockProfiles;
        state = state.copyWith(
          profiles: visibleProfiles,
          spotlightProfiles: fallbackSpotlight,
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
      final queryParameters = <String, dynamic>{
        'limit': 50,
        'mode': state.discoveryMode,
      };
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
          .map(_toDiscoveryProfile)
          .where((profile) => profile.id.isNotEmpty)
          .toList();

      final spotlightRaw = (body['spotlight_profiles'] as List?) ?? const [];
      var spotlightProfiles = spotlightRaw
          .whereType<Map<String, dynamic>>()
          .map(_toDiscoveryProfile)
          .where((profile) => profile.id.isNotEmpty)
          .toList();
      if (spotlightProfiles.isEmpty) {
        spotlightProfiles = profiles
            .where((profile) => profile.isSpotlight)
            .take(6)
            .toList(growable: false);
      }

      state = state.copyWith(
        profiles: profiles,
        spotlightProfiles: spotlightProfiles,
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

    final targetProfile = state.profiles[state.currentIndex];
    final targetUserId = targetProfile.id;
    final previousIndex = state.currentIndex;
    final previousLikeCount = state.likeCount;
    final previousLikedProfiles = List<DiscoveryProfile>.from(
      state.likedProfiles,
    );
    final previousError = state.error;

    final updatedLikedProfiles = <DiscoveryProfile>[
      targetProfile,
      ...state.likedProfiles.where((item) => item.id != targetProfile.id),
    ];

    state = state.copyWith(
      currentIndex: previousIndex + 1,
      likeCount: previousLikeCount + 1,
      likedProfiles: updatedLikedProfiles,
      error: null,
    );

    try {
      final currentUserId = ref.read(authNotifierProvider).userId;
      if (currentUserId == null || currentUserId.isEmpty) {
        state = state.copyWith(
          currentIndex: previousIndex,
          likeCount: previousLikeCount,
          likedProfiles: previousLikedProfiles,
          error: 'User session not available. Please login again.',
        );
        return null;
      }

      if (kUseMockAuth || kUseMockDiscoveryData) {
        if (_mockMatchedProfileIds.contains(targetUserId)) {
          return 'mock-match-$targetUserId';
        }
        return null;
      }

      final body = await _postSwipeDecision(
        currentUserId: currentUserId,
        targetUserId: targetUserId,
        isLike: true,
      );
      final matchID = body['match_id']?.toString();
      return (matchID == null || matchID.isEmpty) ? null : matchID;
    } on DioException catch (e, stackTrace) {
      log.error('Failed to like profile', e, stackTrace);
      if (state.currentIndex == previousIndex + 1 &&
          state.profiles.length > previousIndex &&
          state.profiles[previousIndex].id == targetProfile.id) {
        state = state.copyWith(
          currentIndex: previousIndex,
          likeCount: previousLikeCount,
          likedProfiles: previousLikedProfiles,
          error: 'Unable to like right now. Please try again.',
        );
      } else {
        state = state.copyWith(error: 'Unable to like right now.');
      }
      return null;
    } catch (e, stackTrace) {
      log.error('Failed to like profile', e, stackTrace);
      if (state.currentIndex == previousIndex + 1 &&
          state.profiles.length > previousIndex &&
          state.profiles[previousIndex].id == targetProfile.id) {
        state = state.copyWith(
          currentIndex: previousIndex,
          likeCount: previousLikeCount,
          likedProfiles: previousLikedProfiles,
          error: 'Unable to like right now. Please try again.',
        );
      } else {
        state = state.copyWith(error: 'Unable to like right now.');
      }
      return null;
    } finally {
      if (state.error == null && previousError != null) {
        state = state.copyWith(error: null);
      }
    }
  }

  /// Pass current profile
  Future<void> passProfile() async {
    if (state.currentIndex >= state.profiles.length) return;

    final previousIndex = state.currentIndex;
    final previousPassCount = state.passCount;
    final previousPassedProfiles = List<DiscoveryProfile>.from(
      state.passedProfiles,
    );

    try {
      final targetProfile = state.profiles[state.currentIndex];
      final targetUserId = targetProfile.id;
      final currentUserId = ref.read(authNotifierProvider).userId;

      final updatedPassedProfiles = <DiscoveryProfile>[
        targetProfile,
        ...state.passedProfiles.where((item) => item.id != targetProfile.id),
      ];

      state = state.copyWith(
        currentIndex: previousIndex + 1,
        passCount: previousPassCount + 1,
        passedProfiles: updatedPassedProfiles,
        error: null,
      );

      if (!kUseMockAuth) {
        if (currentUserId == null || currentUserId.isEmpty) {
          state = state.copyWith(
            currentIndex: previousIndex,
            passCount: previousPassCount,
            passedProfiles: previousPassedProfiles,
            error: 'User session not available. Please login again.',
          );
          return;
        }

        await _postSwipeDecision(
          currentUserId: currentUserId,
          targetUserId: targetUserId,
          isLike: false,
        );
      }
    } on DioException catch (e, stackTrace) {
      log.error('Failed to pass profile', e, stackTrace);
      state = state.copyWith(
        currentIndex: previousIndex,
        passCount: previousPassCount,
        passedProfiles: previousPassedProfiles,
        error: 'Unable to pass right now. Please try again.',
      );
    } catch (e, stackTrace) {
      log.error('Failed to pass profile', e, stackTrace);
      state = state.copyWith(
        currentIndex: previousIndex,
        passCount: previousPassCount,
        passedProfiles: previousPassedProfiles,
        error: 'Unable to pass right now. Please try again.',
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

  Future<void> setDiscoveryMode(String mode) async {
    final normalized = mode.trim().toLowerCase() == discoveryModeSpotlight
        ? discoveryModeSpotlight
        : discoveryModeAll;
    if (state.discoveryMode == normalized) {
      return;
    }
    state = state.copyWith(discoveryMode: normalized, currentIndex: 0);
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

  List<String> _extractAndNormalizePhotoUrls(Map<String, dynamic> map) {
    final urls = <String>[];

    void addRaw(dynamic value) {
      final normalized = _normalizePhotoUrl(value?.toString() ?? '');
      if (normalized.isEmpty || urls.contains(normalized)) {
        return;
      }
      urls.add(normalized);
    }

    for (final key in <String>['photoUrls', 'photo_urls']) {
      final raw = (map[key] as List?) ?? const [];
      for (final item in raw) {
        addRaw(item);
      }
    }

    final photosRaw = (map['photos'] as List?) ?? const [];
    for (final item in photosRaw) {
      final photo = (item as Map?)?.cast<String, dynamic>();
      if (photo == null) {
        continue;
      }
      addRaw(photo['photo_url']);
      addRaw(photo['photoUrl']);
      addRaw(photo['url']);
    }

    if (urls.isEmpty) {
      return <String>[AppRuntimeConfig.placeholderProfileImageUrl];
    }
    return urls;
  }

  DiscoveryProfile _toDiscoveryProfile(Map<String, dynamic> map) {
    final photoList = _extractAndNormalizePhotoUrls(map);
    final dob =
        DateTime.tryParse(map['dateOfBirth']?.toString() ?? '') ??
        DateTime(1998, 1, 1);
    final spotlightTierRaw =
        (map['spotlight_tier'] ?? map['spotlightTier'])?.toString().trim() ??
        '';
    final spotlightReasonRaw =
        (map['spotlight_reason'] ?? map['spotlightReason'])
            ?.toString()
            .trim() ??
        '';

    return DiscoveryProfile(
      id: map['id']?.toString() ?? map['user_id']?.toString() ?? '',
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
      extraCurriculars: ((map['extra_curriculars'] as List?) ?? const [])
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
      photoUrls: photoList,
      isSpotlight: map['is_spotlight'] == true || map['isSpotlight'] == true,
      spotlightTier: spotlightTierRaw.isEmpty ? null : spotlightTierRaw,
      spotlightScore: _toDouble(
        map['spotlight_score'] ?? map['spotlightScore'],
      ),
      spotlightReason: spotlightReasonRaw.isEmpty ? null : spotlightReasonRaw,
    );
  }

  double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString().trim());
  }

  String _normalizePhotoUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    final apiBase = Uri.tryParse(AppRuntimeConfig.apiBaseUrl);
    final apiOrigin = apiBase == null
        ? null
        : Uri(
            scheme: apiBase.scheme,
            host: apiBase.host,
            port: apiBase.hasPort ? apiBase.port : null,
          );

    final candidate = trimmed.startsWith('//') ? 'https:$trimmed' : trimmed;
    final parsed = Uri.tryParse(candidate);
    if (parsed == null) {
      return '';
    }

    if (!parsed.hasScheme) {
      if (apiOrigin == null) {
        return '';
      }
      final path = candidate.startsWith('/') ? candidate : '/$candidate';
      return apiOrigin.resolve(path).toString();
    }

    final localhostAliases = <String>{'localhost', '127.0.0.1', '0.0.0.0'};
    if (apiBase != null &&
        localhostAliases.contains(parsed.host.toLowerCase())) {
      return parsed
          .replace(
            scheme: apiBase.scheme,
            host: apiBase.host,
            port: apiBase.hasPort
                ? apiBase.port
                : (parsed.hasPort ? parsed.port : null),
          )
          .toString();
    }

    return parsed.toString();
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
