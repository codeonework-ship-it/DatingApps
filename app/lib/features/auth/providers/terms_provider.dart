import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../core/utils/logger.dart';
import 'auth_provider.dart';

part 'terms_provider.g.dart';

@riverpod
class TermsAcceptance extends _$TermsAcceptance {
  static const _legacyKey = 'termsAccepted_v1';
  static const _scopedPrefix = 'termsAccepted_v1_';

  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    final authState = ref.watch(authNotifierProvider);
    final userId = authState.userId?.trim() ?? '';
    final localValue = await _readLocalValue(prefs, userId);

    if (kUseMockAuth) {
      return localValue;
    }

    if (userId.isEmpty) {
      return false;
    }

    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.get<Map<String, dynamic>>(
        '/users/$userId/agreements/terms',
      );
      final data =
          (response.data as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      final agreement =
          (data['agreement'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      final accepted = agreement['accepted'] == true;
      if (accepted != localValue) {
        await _persistLocalValue(prefs, userId: userId, accepted: accepted);
      }
      return accepted;
    } on DioException {
      return localValue;
    }
  }

  Future<void> accept() async {
    state = const AsyncLoading();
    final prefs = await SharedPreferences.getInstance();
    final authState = ref.read(authNotifierProvider);
    final userId = authState.userId?.trim() ?? '';

    try {
      if (kUseMockAuth) {
        await _persistLocalValue(prefs, userId: userId, accepted: true);
        state = const AsyncData(true);
        return;
      }

      if (userId.isEmpty) {
        log.warning('terms_acceptance_missing_user');
        state = const AsyncData(false);
        return;
      }

      final dio = ref.read(apiClientProvider);
      await dio.patch<Map<String, dynamic>>(
        '/users/$userId/agreements/terms',
        data: const <String, dynamic>{'accepted': true, 'terms_version': 'v1'},
      );
      await _persistLocalValue(prefs, userId: userId, accepted: true);
      state = const AsyncData(true);
    } on DioException catch (error, stackTrace) {
      log.warning('terms_acceptance_remote_failed', error, stackTrace);
      state = const AsyncData(false);
    } on Object catch (error, stackTrace) {
      log.warning('terms_acceptance_submit_failed', error, stackTrace);
      state = const AsyncData(false);
    }
  }

  Future<void> reset() async {
    state = const AsyncLoading();
    final prefs = await SharedPreferences.getInstance();
    final authState = ref.read(authNotifierProvider);
    final userId = authState.userId?.trim() ?? '';
    if (kUseMockAuth) {
      await prefs.remove(_legacyKey);
    } else if (userId.isNotEmpty) {
      await prefs.remove(_scopedKey(userId));
      await prefs.remove(_legacyKey);
    }
    state = const AsyncData(false);
  }

  Future<bool> _readLocalValue(SharedPreferences prefs, String userId) async {
    if (kUseMockAuth) {
      return prefs.getBool(_legacyKey) ?? false;
    }

    if (userId.isEmpty) {
      return false;
    }

    final scopedKey = _scopedKey(userId);
    final scopedValue = prefs.getBool(scopedKey);
    if (scopedValue != null) {
      return scopedValue;
    }

    // One-time migration from the legacy unscoped key.
    final legacyValue = prefs.getBool(_legacyKey);
    if (legacyValue != null) {
      await prefs.setBool(scopedKey, legacyValue);
      await prefs.remove(_legacyKey);
      return legacyValue;
    }
    return false;
  }

  Future<void> _persistLocalValue(
    SharedPreferences prefs, {
    required String userId,
    required bool accepted,
  }) async {
    if (kUseMockAuth) {
      await prefs.setBool(_legacyKey, accepted);
      return;
    }

    if (userId.isEmpty) {
      return;
    }

    await prefs.setBool(_scopedKey(userId), accepted);
    await prefs.remove(_legacyKey);
  }

  String _scopedKey(String userId) {
    final normalized = userId.trim();
    if (normalized.isEmpty) {
      return _legacyKey;
    }
    return '$_scopedPrefix${_sanitizeUserId(normalized)}';
  }

  String _sanitizeUserId(String value) =>
      value.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
}
