import 'dart:async';

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../core/utils/logger.dart';
import '../../auth/providers/auth_provider.dart';

part 'profile_setup_provider.g.dart';

typedef JsonMap = Map<String, dynamic>;

class ProfilePhotoItem {
  const ProfilePhotoItem({
    required this.id,
    required this.photoUrl,
    required this.storagePath,
    required this.ordering,
    this.originalFilename = '',
    this.mimeType = '',
    this.widthPx = 0,
    this.heightPx = 0,
    this.sizeBytes = 0,
    this.moderationStatus = 'pending',
  });
  final String id;
  final String photoUrl;
  final String storagePath;
  final int ordering;
  final String originalFilename;
  final String mimeType;
  final int widthPx;
  final int heightPx;
  final int sizeBytes;
  final String moderationStatus;

  bool get isHeic =>
      mimeType == 'image/heic' ||
      originalFilename.toLowerCase().endsWith('.heic') ||
      photoUrl.toLowerCase().contains('.heic');

  ProfilePhotoItem withOrdering(int value) => ProfilePhotoItem(
    id: id,
    photoUrl: photoUrl,
    storagePath: storagePath,
    ordering: value,
    originalFilename: originalFilename,
    mimeType: mimeType,
    widthPx: widthPx,
    heightPx: heightPx,
    sizeBytes: sizeBytes,
    moderationStatus: moderationStatus,
  );
}

String profileMediaErrorMessage(Object error) {
  if (error is StateError) {
    return error.message.toString();
  }
  if (error is DioException) {
    final data = error.response?.data;
    final serverMessage = data is Map
        ? (data['error'] ?? data['message'])?.toString().trim()
        : data?.toString().trim();
    if (serverMessage != null && serverMessage.isNotEmpty) {
      return serverMessage;
    }
    switch (error.response?.statusCode) {
      case 413:
        return 'This photo is larger than the 10 MB limit.';
      case 415:
        return 'Use a JPEG, PNG, WebP, or HEIC photo.';
      case 422:
        return 'Photo dimensions must be between 300×300 and 4096×4096.';
      case 409:
        return 'Your profile photo quota has been reached.';
      case 507:
        return 'Photo storage is temporarily full. Please try again later.';
    }
  }
  return 'Photo update failed. Please try again.';
}

class ProfileDraft {
  const ProfileDraft({
    required this.userId,
    required this.phoneNumber,
    required this.name,
    required this.dateOfBirth,
    required this.gender,
    required this.photos,
    required this.bio,
    required this.heightCm,
    required this.education,
    required this.profession,
    required this.incomeRange,
    required this.seekingGenders,
    required this.minAgeYears,
    required this.maxAgeYears,
    required this.maxDistanceKm,
    required this.educationFilter,
    required this.seriousOnly,
    required this.verifiedOnly,
    required this.country,
    required this.regionState,
    required this.city,
    required this.instagramHandle,
    required this.hobbies,
    required this.favoriteBooks,
    required this.favoriteNovels,
    required this.favoriteSongs,
    required this.extraCurriculars,
    required this.additionalInfo,
    required this.intentTags,
    required this.languageTags,
    required this.petPreference,
    required this.dietPreference,
    required this.workoutFrequency,
    required this.dietType,
    required this.sleepSchedule,
    required this.travelStyle,
    required this.politicalComfortRange,
    required this.dealBreakerTags,
    required this.drinking,
    required this.smoking,
    required this.religion,
    required this.motherTongue,
    required this.hookupOnly,
  });
  final String userId;
  final String phoneNumber;

  final String name;
  final DateTime? dateOfBirth;
  final String gender; // 'M' | 'F' | 'Other'

  final List<ProfilePhotoItem> photos;

  final String bio;
  final int? heightCm;
  final String? education;
  final String? profession;
  final String? incomeRange;

  final List<String> seekingGenders;
  final int minAgeYears;
  final int maxAgeYears;
  final int maxDistanceKm;
  final List<String> educationFilter;
  final bool seriousOnly;
  final bool verifiedOnly;
  final String? country;
  final String? regionState;
  final String? city;
  final String? instagramHandle;
  final List<String> hobbies;
  final List<String> favoriteBooks;
  final List<String> favoriteNovels;
  final List<String> favoriteSongs;
  final List<String> extraCurriculars;
  final String? additionalInfo;
  final List<String> intentTags;
  final List<String> languageTags;
  final String? petPreference;
  final String? dietPreference;
  final String? workoutFrequency;
  final String? dietType;
  final String? sleepSchedule;
  final String? travelStyle;
  final String? politicalComfortRange;
  final List<String> dealBreakerTags;

  final String drinking;
  final String smoking;
  final String? religion;
  final String? motherTongue;
  final bool hookupOnly;

  // Optional edits must distinguish an omitted argument from an explicit clear.
  static const _unchanged = Object();

  ProfileDraft copyWith({
    String? phoneNumber,
    String? name,
    DateTime? dateOfBirth,
    String? gender,
    List<ProfilePhotoItem>? photos,
    String? bio,
    Object? heightCm = _unchanged,
    Object? education = _unchanged,
    Object? profession = _unchanged,
    Object? incomeRange = _unchanged,
    List<String>? seekingGenders,
    int? minAgeYears,
    int? maxAgeYears,
    int? maxDistanceKm,
    List<String>? educationFilter,
    bool? seriousOnly,
    bool? verifiedOnly,
    Object? country = _unchanged,
    Object? regionState = _unchanged,
    Object? city = _unchanged,
    Object? instagramHandle = _unchanged,
    List<String>? hobbies,
    List<String>? favoriteBooks,
    List<String>? favoriteNovels,
    List<String>? favoriteSongs,
    List<String>? extraCurriculars,
    Object? additionalInfo = _unchanged,
    List<String>? intentTags,
    List<String>? languageTags,
    Object? petPreference = _unchanged,
    Object? dietPreference = _unchanged,
    Object? workoutFrequency = _unchanged,
    Object? dietType = _unchanged,
    Object? sleepSchedule = _unchanged,
    Object? travelStyle = _unchanged,
    Object? politicalComfortRange = _unchanged,
    List<String>? dealBreakerTags,
    String? drinking,
    String? smoking,
    Object? religion = _unchanged,
    Object? motherTongue = _unchanged,
    bool? hookupOnly,
  }) => ProfileDraft(
    userId: userId,
    phoneNumber: phoneNumber ?? this.phoneNumber,
    name: name ?? this.name,
    dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    gender: gender ?? this.gender,
    photos: photos ?? this.photos,
    bio: bio ?? this.bio,
    heightCm: identical(heightCm, _unchanged)
        ? this.heightCm
        : heightCm as int?,
    education: identical(education, _unchanged)
        ? this.education
        : education as String?,
    profession: identical(profession, _unchanged)
        ? this.profession
        : profession as String?,
    incomeRange: identical(incomeRange, _unchanged)
        ? this.incomeRange
        : incomeRange as String?,
    seekingGenders: seekingGenders ?? this.seekingGenders,
    minAgeYears: minAgeYears ?? this.minAgeYears,
    maxAgeYears: maxAgeYears ?? this.maxAgeYears,
    maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
    educationFilter: educationFilter ?? this.educationFilter,
    seriousOnly: seriousOnly ?? this.seriousOnly,
    verifiedOnly: verifiedOnly ?? this.verifiedOnly,
    country: identical(country, _unchanged) ? this.country : country as String?,
    regionState: identical(regionState, _unchanged)
        ? this.regionState
        : regionState as String?,
    city: identical(city, _unchanged) ? this.city : city as String?,
    instagramHandle: identical(instagramHandle, _unchanged)
        ? this.instagramHandle
        : instagramHandle as String?,
    hobbies: hobbies ?? this.hobbies,
    favoriteBooks: favoriteBooks ?? this.favoriteBooks,
    favoriteNovels: favoriteNovels ?? this.favoriteNovels,
    favoriteSongs: favoriteSongs ?? this.favoriteSongs,
    extraCurriculars: extraCurriculars ?? this.extraCurriculars,
    additionalInfo: identical(additionalInfo, _unchanged)
        ? this.additionalInfo
        : additionalInfo as String?,
    intentTags: intentTags ?? this.intentTags,
    languageTags: languageTags ?? this.languageTags,
    petPreference: identical(petPreference, _unchanged)
        ? this.petPreference
        : petPreference as String?,
    dietPreference: identical(dietPreference, _unchanged)
        ? this.dietPreference
        : dietPreference as String?,
    workoutFrequency: identical(workoutFrequency, _unchanged)
        ? this.workoutFrequency
        : workoutFrequency as String?,
    dietType: identical(dietType, _unchanged)
        ? this.dietType
        : dietType as String?,
    sleepSchedule: identical(sleepSchedule, _unchanged)
        ? this.sleepSchedule
        : sleepSchedule as String?,
    travelStyle: identical(travelStyle, _unchanged)
        ? this.travelStyle
        : travelStyle as String?,
    politicalComfortRange: identical(politicalComfortRange, _unchanged)
        ? this.politicalComfortRange
        : politicalComfortRange as String?,
    dealBreakerTags: dealBreakerTags ?? this.dealBreakerTags,
    drinking: drinking ?? this.drinking,
    smoking: smoking ?? this.smoking,
    religion: identical(religion, _unchanged)
        ? this.religion
        : religion as String?,
    motherTongue: identical(motherTongue, _unchanged)
        ? this.motherTongue
        : motherTongue as String?,
    hookupOnly: hookupOnly ?? this.hookupOnly,
  );

  int get profileCompletionPercent {
    var score = 0;
    const total = 6;

    if (name.trim().length >= ValidationConstants.minNameLength) {
      score++;
    }
    if (dateOfBirth != null) {
      score++;
    }
    if (photos.length >= ValidationConstants.minPhotos) {
      score++;
    }
    if (bio.trim().length >= ValidationConstants.minBioLength) {
      score++;
    }
    if (seekingGenders.isNotEmpty) {
      score++;
    }
    if (drinking.isNotEmpty && smoking.isNotEmpty) {
      score++;
    }

    return ((score / total) * 100).round();
  }
}

@riverpod
class ProfileSetupNotifier extends _$ProfileSetupNotifier {
  final _picker = ImagePicker();

  @override
  Future<ProfileDraft> build() async {
    final auth = ref.watch(authNotifierProvider);
    final userId = auth.userId;
    if (userId == null) {
      throw StateError('Not authenticated');
    }

    // Keep the provider alive across all setup screens so that navigating
    // forward/back never triggers a re-fetch that could wipe in-progress data.
    ref.keepAlive();

    const fallbackPhone = '';

    try {
      final draft = await _fetchDraft(
        userId,
        fallbackPhone: fallbackPhone,
      ).timeout(const Duration(seconds: 10));
      return _applySignupFallback(draft, auth.pendingSignup);
    } on Object catch (e, stackTrace) {
      log.error('Failed to load profile draft', e, stackTrace);
      rethrow;
    }
  }

  Future<void> saveBasicInfo({
    required String name,
    required DateTime dateOfBirth,
    required String gender,
  }) async {
    final current = await future;
    final next = current.copyWith(
      name: name.trim(),
      dateOfBirth: dateOfBirth,
      gender: gender,
    );
    state = AsyncData(next);

    await _patchRemoteDraft(next.userId, next.phoneNumber, {
      'name': next.name,
      'date_of_birth': _toIsoDate(next.dateOfBirth),
      'gender': next.gender,
    }, optimistic: next);
  }

  Future<void> saveAbout({
    required String bio,
    required int? heightCm,
    required String? education,
    required String? profession,
    required String? incomeRange,
  }) async {
    final current = await future;
    final next = current.copyWith(
      bio: bio,
      heightCm: heightCm,
      education: education,
      profession: profession,
      incomeRange: incomeRange,
    );
    state = AsyncData(next);

    await _patchRemoteDraft(next.userId, next.phoneNumber, {
      'bio': next.bio.trim().isEmpty ? null : next.bio.trim(),
      'height_cm': next.heightCm,
      'education': next.education,
      'profession': next.profession,
      'income_range': next.incomeRange,
    }, optimistic: next);
  }

  Future<void> savePreferences({
    required List<String> seekingGenders,
    required int minAgeYears,
    required int maxAgeYears,
    required int maxDistanceKm,
    required List<String> educationFilter,
    required bool seriousOnly,
    required bool verifiedOnly,
    required String? country,
    required String? regionState,
    required String? city,
    required String? instagramHandle,
    required List<String> hobbies,
    required List<String> favoriteBooks,
    required List<String> favoriteNovels,
    required List<String> favoriteSongs,
    required List<String> extraCurriculars,
    required String? additionalInfo,
    required List<String> intentTags,
    required List<String> languageTags,
    required String? petPreference,
    required String? dietPreference,
    required String? workoutFrequency,
    required String? dietType,
    required String? sleepSchedule,
    required String? travelStyle,
    required String? politicalComfortRange,
    required List<String> dealBreakerTags,
    required String? motherTongue,
    required bool hookupOnly,
  }) async {
    final current = await future;
    final next = current.copyWith(
      seekingGenders: seekingGenders,
      minAgeYears: minAgeYears,
      maxAgeYears: maxAgeYears,
      maxDistanceKm: maxDistanceKm,
      educationFilter: educationFilter,
      seriousOnly: seriousOnly,
      verifiedOnly: verifiedOnly,
      country: _asNullableString(country),
      regionState: _asNullableString(regionState),
      city: _asNullableString(city),
      instagramHandle: _asNullableString(instagramHandle),
      hobbies: hobbies,
      favoriteBooks: favoriteBooks,
      favoriteNovels: favoriteNovels,
      favoriteSongs: favoriteSongs,
      extraCurriculars: extraCurriculars,
      additionalInfo: _asNullableString(additionalInfo),
      intentTags: intentTags,
      languageTags: languageTags,
      petPreference: _asNullableString(petPreference),
      dietPreference: _asNullableString(dietPreference),
      workoutFrequency: _asNullableString(workoutFrequency),
      dietType: _asNullableString(dietType),
      sleepSchedule: _asNullableString(sleepSchedule),
      travelStyle: _asNullableString(travelStyle),
      politicalComfortRange: _asNullableString(politicalComfortRange),
      dealBreakerTags: dealBreakerTags,
      motherTongue: _asNullableString(motherTongue),
      hookupOnly: hookupOnly,
    );
    state = AsyncData(next);

    await _patchRemoteDraft(next.userId, next.phoneNumber, {
      'seeking_genders': next.seekingGenders,
      'min_age_years': next.minAgeYears,
      'max_age_years': next.maxAgeYears,
      'max_distance_km': next.maxDistanceKm,
      'education_filter': next.educationFilter,
      'serious_only': next.seriousOnly,
      'verified_only': next.verifiedOnly,
      'country': next.country,
      'state': next.regionState,
      'city': next.city,
      'instagram_handle': next.instagramHandle,
      'hobbies': next.hobbies,
      'favorite_books': next.favoriteBooks,
      'favorite_novels': next.favoriteNovels,
      'favorite_songs': next.favoriteSongs,
      'extra_curriculars': next.extraCurriculars,
      'additional_info': next.additionalInfo,
      'intent_tags': next.intentTags,
      'language_tags': next.languageTags,
      'pet_preference': next.petPreference,
      'diet_preference': next.dietPreference,
      'workout_frequency': next.workoutFrequency,
      'diet_type': next.dietType,
      'sleep_schedule': next.sleepSchedule,
      'travel_style': next.travelStyle,
      'political_comfort_range': next.politicalComfortRange,
      'deal_breaker_tags': next.dealBreakerTags,
      'mother_tongue': next.motherTongue,
      'hookup_only': next.hookupOnly,
    }, optimistic: next);
  }

  Future<void> saveLifestyle({
    required String drinking,
    required String smoking,
    required String? religion,
  }) async {
    final current = await future;
    final next = current.copyWith(
      drinking: drinking,
      smoking: smoking,
      religion: religion,
    );
    state = AsyncData(next);

    await _patchRemoteDraft(next.userId, next.phoneNumber, {
      'drinking': next.drinking,
      'smoking': next.smoking,
      'religion': next.religion,
    }, optimistic: next);
  }

  Future<void> addPhotoFromGallery() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) {
      return;
    }
    await _uploadAndInsertPhoto(file);
  }

  Future<void> addPhotoFromCamera() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (file == null) {
      return;
    }
    await _uploadAndInsertPhoto(file);
  }

  Future<void> _uploadAndInsertPhoto(XFile file) async {
    final current = await future;
    if (current.photos.length >= ValidationConstants.maxPhotos) {
      throw StateError(
        'Maximum ${ValidationConstants.maxPhotos} photos are allowed.',
      );
    }
    if (await file.length() > 10 * 1024 * 1024) {
      throw StateError('This photo is larger than the 10 MB limit.');
    }

    final ts = DateTime.now().millisecondsSinceEpoch;
    final photoId = '${current.userId}-$ts';
    final ext = _imageExtension(file.name);

    // ── 1. Optimistic local entry (show a file:// thumbnail) ───────────────
    final optimisticPhoto = ProfilePhotoItem(
      id: 'local-$photoId',
      photoUrl: file.path, // local path used as placeholder
      storagePath: file.path,
      ordering: current.photos.length,
    );
    state = AsyncData(
      current.copyWith(photos: [...current.photos, optimisticPhoto]),
    );

    try {
      // ── 2. Upload to Go BFF via multipart/form-data ──────────────────────
      final dio = ref.read(apiClientProvider);
      final multipart = FormData.fromMap({
        'image': MultipartFile.fromBytes(
          await file.readAsBytes(),
          filename: '$photoId$ext',
        ),
      });
      final response = await dio.post<Map<String, dynamic>>(
        '/profile/${current.userId}/photos',
        data: multipart,
        options: Options(contentType: 'multipart/form-data'),
      );
      state = AsyncData(
        _draftFromApi(
          current.userId,
          response.data,
          fallbackPhone: current.phoneNumber,
        ),
      );
    } on DioException catch (e, stackTrace) {
      log.error('Failed to upload photo', e, stackTrace);
      // Remove the optimistic entry on failure so user can retry
      final rolled = current.photos
          .where((p) => p.id != optimisticPhoto.id)
          .toList();
      state = AsyncData(current.copyWith(photos: rolled));
      rethrow; // let the screen show an error snackbar
    } catch (e, stackTrace) {
      log.error('Unexpected error during photo upload', e, stackTrace);
      final rolled = current.photos
          .where((p) => p.id != optimisticPhoto.id)
          .toList();
      state = AsyncData(current.copyWith(photos: rolled));
      rethrow;
    }
  }

  /// Returns the lower-cased extension including the dot, defaulting to .jpg.
  static String _imageExtension(String filename) {
    final dot = filename.lastIndexOf('.');
    if (dot < 0) {
      return '.jpg';
    }
    final ext = filename.substring(dot).toLowerCase();
    return const {'.jpg', '.jpeg', '.png', '.webp', '.heic'}.contains(ext)
        ? ext
        : '.jpg';
  }

  Future<void> deletePhoto(ProfilePhotoItem photo) async {
    final current = await future;
    final remaining = [...current.photos]
      ..removeWhere((item) => item.id == photo.id);
    final normalized = <ProfilePhotoItem>[];
    for (var i = 0; i < remaining.length; i++) {
      normalized.add(remaining[i].withOrdering(i));
    }
    final optimistic = current.copyWith(photos: normalized);
    state = AsyncData(optimistic);

    final dio = ref.read(apiClientProvider);
    try {
      final response = await dio.delete<Map<String, dynamic>>(
        '/profile/${current.userId}/photos/${photo.id}',
      );
      state = AsyncData(
        _draftFromApi(
          current.userId,
          response.data,
          fallbackPhone: current.phoneNumber,
        ),
      );
    } on DioException catch (e, stackTrace) {
      log.error('Failed to delete photo', e, stackTrace);
      state = AsyncData(current);
      rethrow;
    } on Object catch (e, stackTrace) {
      log.error('Unexpected error deleting photo', e, stackTrace);
      state = AsyncData(current);
      rethrow;
    }
  }

  Future<void> reorderPhotos(int oldIndex, int newIndex) async {
    final current = await future;
    final photos = [...current.photos];
    final targetIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final item = photos.removeAt(oldIndex);
    photos.insert(targetIndex, item);

    final normalized = <ProfilePhotoItem>[];
    for (var i = 0; i < photos.length; i++) {
      normalized.add(photos[i].withOrdering(i));
    }
    final optimistic = current.copyWith(photos: normalized);
    state = AsyncData(optimistic);

    final dio = ref.read(apiClientProvider);
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/profile/${current.userId}/photos/reorder',
        data: {'photo_ids': normalized.map((photo) => photo.id).toList()},
      );
      state = AsyncData(
        _draftFromApi(
          current.userId,
          response.data,
          fallbackPhone: current.phoneNumber,
        ),
      );
    } on DioException catch (e, stackTrace) {
      log.error('Failed to reorder photos', e, stackTrace);
      state = AsyncData(current);
      rethrow;
    } on Object catch (e, stackTrace) {
      log.error('Unexpected error reordering photos', e, stackTrace);
      state = AsyncData(current);
      rethrow;
    }
  }

  Future<void> completeProfile() async {
    final current = await future;

    final isValid =
        current.name.trim().length >= ValidationConstants.minNameLength &&
        current.dateOfBirth != null &&
        current.gender.trim().isNotEmpty &&
        current.photos.length >= ValidationConstants.minPhotos &&
        current.bio.trim().length >= ValidationConstants.minBioLength &&
        current.seekingGenders.isNotEmpty;

    if (!isValid) {
      throw StateError('Profile is incomplete');
    }

    final dio = ref.read(apiClientProvider);
    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/profile/${current.userId}/complete',
      );
      state = AsyncData(
        _draftFromApi(
          current.userId,
          response.data,
          fallbackPhone: current.phoneNumber,
        ),
      );
    } on DioException catch (e, stackTrace) {
      log.error('Failed to complete profile', e, stackTrace);
      rethrow;
    }
  }

  Future<ProfileDraft> _fetchDraft(
    String userId, {
    required String fallbackPhone,
  }) async {
    final dio = ref.read(apiClientProvider);
    final response = await dio.get<Map<String, dynamic>>(
      '/profile/$userId/draft',
    );
    return _draftFromApi(userId, response.data, fallbackPhone: fallbackPhone);
  }

  Future<void> _patchRemoteDraft(
    String userId,
    String fallbackPhone,
    JsonMap payload, {
    required ProfileDraft optimistic,
  }) async {
    final dio = ref.read(apiClientProvider);
    try {
      final response = await dio.patch<Map<String, dynamic>>(
        '/profile/$userId/draft',
        data: payload,
      );
      state = AsyncData(
        _draftFromApi(userId, response.data, fallbackPhone: fallbackPhone),
      );
    } on DioException catch (e, stackTrace) {
      log.error('Failed to patch profile draft', e, stackTrace);
      state = AsyncData(optimistic);
      // Keep edits available for retry, but do not acknowledge a failed write.
      rethrow;
    }
  }

  ProfileDraft _draftFromApi(
    String userId,
    dynamic responseData, {
    required String fallbackPhone,
  }) {
    final root = (responseData as Map?)?.cast<String, dynamic>() ?? const {};
    final draft = (root['draft'] as Map?)?.cast<String, dynamic>() ?? const {};
    final photosRaw = (draft['photos'] as List?)?.cast<dynamic>() ?? const [];
    final photos = photosRaw
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => ProfilePhotoItem(
            id: _asString(
              item['id'],
              fallback: 'photo-${DateTime.now().millisecondsSinceEpoch}',
            ),
            photoUrl: _asString(item['photo_url'], fallback: ''),
            storagePath: _asString(item['storage_path'], fallback: ''),
            ordering: _asInt(item['ordering'], fallback: 0),
            originalFilename: _asString(
              item['original_filename'],
              fallback: '',
            ),
            mimeType: _asString(item['mime_type'], fallback: ''),
            widthPx: _asInt(item['width_px'], fallback: 0),
            heightPx: _asInt(item['height_px'], fallback: 0),
            sizeBytes: _asInt(item['size_bytes'], fallback: 0),
            moderationStatus: _asString(
              item['moderation_status'],
              fallback: 'pending',
            ),
          ),
        )
        .toList();

    return ProfileDraft(
      userId: userId,
      phoneNumber: _asString(draft['phone_number'], fallback: fallbackPhone),
      name: _asString(draft['name'], fallback: ''),
      dateOfBirth: _parseDate(_asString(draft['date_of_birth'], fallback: '')),
      gender: _asString(draft['gender'], fallback: 'M'),
      photos: photos,
      bio: _asString(draft['bio'], fallback: ''),
      heightCm: _asNullableInt(draft['height_cm']),
      education: _asNullableString(draft['education']),
      profession: _asNullableString(draft['profession']),
      incomeRange: _asNullableString(draft['income_range']),
      seekingGenders: _asStringList(
        draft['seeking_genders'],
        fallback: const ['M', 'F'],
      ),
      minAgeYears: _asInt(draft['min_age_years'], fallback: 18),
      maxAgeYears: _asInt(draft['max_age_years'], fallback: 60),
      maxDistanceKm: _asInt(draft['max_distance_km'], fallback: 50),
      educationFilter: _asStringList(draft['education_filter']),
      seriousOnly: _asBool(draft['serious_only'], fallback: true),
      verifiedOnly: _asBool(draft['verified_only'], fallback: false),
      country: _asNullableString(draft['country']),
      regionState: _asNullableString(draft['state']),
      city: _asNullableString(draft['city']),
      instagramHandle: _asNullableString(draft['instagram_handle']),
      hobbies: _asStringList(draft['hobbies']),
      favoriteBooks: _asStringList(draft['favorite_books']),
      favoriteNovels: _asStringList(draft['favorite_novels']),
      favoriteSongs: _asStringList(draft['favorite_songs']),
      extraCurriculars: _asStringList(draft['extra_curriculars']),
      additionalInfo: _asNullableString(draft['additional_info']),
      intentTags: _asStringList(draft['intent_tags']),
      languageTags: _asStringList(draft['language_tags']),
      petPreference: _asNullableString(draft['pet_preference']),
      dietPreference: _asNullableString(draft['diet_preference']),
      workoutFrequency: _asNullableString(draft['workout_frequency']),
      dietType: _asNullableString(draft['diet_type']),
      sleepSchedule: _asNullableString(draft['sleep_schedule']),
      travelStyle: _asNullableString(draft['travel_style']),
      politicalComfortRange: _asNullableString(
        draft['political_comfort_range'],
      ),
      dealBreakerTags: _asStringList(draft['deal_breaker_tags']),
      drinking: _asString(draft['drinking'], fallback: 'Never'),
      smoking: _asString(draft['smoking'], fallback: 'Never'),
      religion: _asNullableString(draft['religion']),
      motherTongue: _asNullableString(draft['mother_tongue']),
      hookupOnly: _asBool(draft['hookup_only'], fallback: false),
    );
  }

  ProfileDraft _applySignupFallback(ProfileDraft draft, SignupDraft? signup) {
    if (signup == null) {
      return draft;
    }
    final parsedDob = _parseDate(signup.dateOfBirth.trim());
    return draft.copyWith(
      name: draft.name.trim().isEmpty ? signup.name.trim() : draft.name,
      dateOfBirth: draft.dateOfBirth ?? parsedDob,
      gender: draft.gender.trim().isEmpty ? signup.gender.trim() : draft.gender,
    );
  }
}

String _toIsoDate(DateTime? value) {
  if (value == null) {
    return '';
  }
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}

DateTime? _parseDate(String raw) {
  if (raw.isEmpty) {
    return null;
  }
  return DateTime.tryParse(raw);
}

String _asString(dynamic value, {required String fallback}) {
  if (value == null) {
    return fallback;
  }
  final result = value.toString().trim();
  return result.isEmpty ? fallback : result;
}

String? _asNullableString(dynamic value) {
  if (value == null) {
    return null;
  }
  final result = value.toString().trim();
  return result.isEmpty ? null : result;
}

int _asInt(dynamic value, {required int fallback}) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return fallback;
}

int? _asNullableInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return null;
}

bool _asBool(dynamic value, {required bool fallback}) {
  if (value is bool) {
    return value;
  }
  return fallback;
}

List<String> _asStringList(dynamic value, {List<String> fallback = const []}) {
  if (value is! List) {
    return fallback;
  }
  final out = value.map((e) => e.toString().trim()).where((e) => e.isNotEmpty);
  return out.toList();
}
