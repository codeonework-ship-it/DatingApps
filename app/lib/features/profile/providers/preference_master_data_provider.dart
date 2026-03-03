import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers/api_client_provider.dart';

class PreferenceMasterData {
  const PreferenceMasterData({
    required this.countries,
    required this.statesByCountry,
    required this.citiesByState,
    required this.religions,
    required this.motherTongues,
    required this.languages,
    required this.dietPreferences,
    required this.workoutFrequencies,
    required this.dietTypes,
    required this.sleepSchedules,
    required this.travelStyles,
    required this.politicalComfortRanges,
  });

  factory PreferenceMasterData.empty() => const PreferenceMasterData(
    countries: <String>[],
    statesByCountry: <String, List<String>>{},
    citiesByState: <String, List<String>>{},
    religions: <String>[],
    motherTongues: <String>[],
    languages: <String>[],
    dietPreferences: <String>[],
    workoutFrequencies: <String>[],
    dietTypes: <String>[],
    sleepSchedules: <String>[],
    travelStyles: <String>[],
    politicalComfortRanges: <String>[],
  );

  factory PreferenceMasterData.fromJson(Map<String, dynamic> json) {
    final countries = _toList(json['countries']);
    final statesByCountry = _toMapOfLists(json['states_by_country']);
    final citiesByState = _toMapOfLists(json['cities_by_state']);

    return PreferenceMasterData(
      countries: countries,
      statesByCountry: statesByCountry,
      citiesByState: citiesByState,
      religions: _toList(json['religions']),
      motherTongues: _toList(json['mother_tongues']),
      languages: _toList(json['languages']),
      dietPreferences: _toList(json['diet_preferences']),
      workoutFrequencies: _toList(json['workout_frequencies']),
      dietTypes: _toList(json['diet_types']),
      sleepSchedules: _toList(json['sleep_schedules']),
      travelStyles: _toList(json['travel_styles']),
      politicalComfortRanges: _toList(json['political_comfort_ranges']),
    );
  }
  final List<String> countries;
  final Map<String, List<String>> statesByCountry;
  final Map<String, List<String>> citiesByState;
  final List<String> religions;
  final List<String> motherTongues;
  final List<String> languages;
  final List<String> dietPreferences;
  final List<String> workoutFrequencies;
  final List<String> dietTypes;
  final List<String> sleepSchedules;
  final List<String> travelStyles;
  final List<String> politicalComfortRanges;

  Map<String, dynamic> toJson() => {
    'countries': countries,
    'states_by_country': statesByCountry,
    'cities_by_state': citiesByState,
    'religions': religions,
    'mother_tongues': motherTongues,
    'languages': languages,
    'diet_preferences': dietPreferences,
    'workout_frequencies': workoutFrequencies,
    'diet_types': dietTypes,
    'sleep_schedules': sleepSchedules,
    'travel_styles': travelStyles,
    'political_comfort_ranges': politicalComfortRanges,
  };

  bool get hasAnyData =>
      countries.isNotEmpty ||
      statesByCountry.isNotEmpty ||
      citiesByState.isNotEmpty ||
      religions.isNotEmpty ||
      motherTongues.isNotEmpty ||
      languages.isNotEmpty ||
      dietPreferences.isNotEmpty ||
      workoutFrequencies.isNotEmpty ||
      dietTypes.isNotEmpty ||
      sleepSchedules.isNotEmpty ||
      travelStyles.isNotEmpty ||
      politicalComfortRanges.isNotEmpty;

  static List<String> _toList(dynamic value) {
    final raw = (value as List?) ?? const [];
    final out = raw
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);
    return out;
  }

  static Map<String, List<String>> _toMapOfLists(dynamic value) {
    final raw = (value as Map?)?.cast<String, dynamic>() ?? const {};
    final out = <String, List<String>>{};
    raw.forEach((key, items) {
      final normalizedKey = key.trim();
      if (normalizedKey.isEmpty) {
        return;
      }
      out[normalizedKey] = _toList(items);
    });
    return out;
  }
}

const _masterDataCacheKey = 'preferences_master_data_cache_v1';
PreferenceMasterData? _memoryCache;

final preferenceMasterDataOfflineProvider = StateProvider<bool>((ref) => false);

bool _isOfflineError(DioException error) {
  if (error.type == DioExceptionType.connectionError ||
      error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.sendTimeout ||
      error.type == DioExceptionType.receiveTimeout) {
    return true;
  }
  final message = error.message?.toLowerCase() ?? '';
  return message.contains('socketexception') ||
      message.contains('failed host lookup') ||
      message.contains('network is unreachable');
}

Future<PreferenceMasterData?> _readCachedMasterData() async {
  if (_memoryCache != null) {
    return _memoryCache;
  }
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_masterDataCacheKey);
  if (raw == null || raw.isEmpty) {
    return null;
  }
  try {
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final cached = PreferenceMasterData.fromJson(decoded);
    if (!cached.hasAnyData) {
      return null;
    }
    _memoryCache = cached;
    return cached;
  } catch (_) {
    return null;
  }
}

Future<PreferenceMasterData> _fetchAndPersistMasterData(Ref ref) async {
  final dio = ref.read(apiClientProvider);
  final response = await dio.get<Map<String, dynamic>>(
    '/master-data/preferences',
  );
  final body =
      (response.data as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
  final master =
      (body['master_data'] as Map?)?.cast<String, dynamic>() ??
      <String, dynamic>{};
  final parsed = PreferenceMasterData.fromJson(master);
  if (!parsed.hasAnyData) {
    throw const FormatException('Master data response is empty');
  }
  ref.read(preferenceMasterDataOfflineProvider.notifier).state = false;
  _memoryCache = parsed;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_masterDataCacheKey, jsonEncode(parsed.toJson()));
  return parsed;
}

Future<void> _refreshMasterDataInBackground(Ref ref) async {
  try {
    await _fetchAndPersistMasterData(ref);
  } on DioException catch (error) {
    if (_isOfflineError(error)) {
      ref.read(preferenceMasterDataOfflineProvider.notifier).state = true;
    }
  } catch (_) {
    // Ignore background refresh errors; cached data remains available.
  }
}

final preferenceMasterDataProvider = FutureProvider<PreferenceMasterData>((
  ref,
) async {
  final cached = await _readCachedMasterData();
  if (cached != null) {
    unawaited(_refreshMasterDataInBackground(ref));
    return cached;
  }

  try {
    return await _fetchAndPersistMasterData(ref);
  } on DioException catch (error) {
    if (_isOfflineError(error)) {
      ref.read(preferenceMasterDataOfflineProvider.notifier).state = true;
    }
    final cachedAfterError = await _readCachedMasterData();
    if (cachedAfterError != null) {
      return cachedAfterError;
    }
    rethrow;
  }
});
