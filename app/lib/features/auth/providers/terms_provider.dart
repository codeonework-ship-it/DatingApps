import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/providers/api_client_provider.dart';
import 'auth_provider.dart';

part 'terms_provider.g.dart';

@riverpod
class TermsAcceptance extends _$TermsAcceptance {
  static const _key = 'termsAccepted_v1';

  @override
  Future<bool> build() async {
    final prefs = await SharedPreferences.getInstance();
    final localValue = prefs.getBool(_key) ?? false;

    if (kUseMockAuth) {
      return localValue;
    }

    final authState = ref.read(authNotifierProvider);
    final userId = authState.userId;
    if (userId == null || userId.trim().isEmpty) {
      return localValue;
    }

    try {
      final dio = ref.read(apiClientProvider);
      final response = await dio.get<Map<String, dynamic>>(
        '/users/${userId.trim()}/agreements/terms',
      );
      final data =
          (response.data as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      final agreement =
          (data['agreement'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      final accepted = agreement['accepted'] == true;
      if (accepted != localValue) {
        await prefs.setBool(_key, accepted);
      }
      return accepted;
    } on DioException {
      return localValue;
    }
  }

  Future<void> accept() async {
    state = const AsyncLoading();
    try {
      final prefs = await SharedPreferences.getInstance();

      if (!kUseMockAuth) {
        final authState = ref.read(authNotifierProvider);
        final userId = authState.userId?.trim() ?? '';
        if (userId.isEmpty) {
          throw StateError('Cannot accept terms without authenticated user.');
        }

        final dio = ref.read(apiClientProvider);
        await dio.patch<Map<String, dynamic>>(
          '/users/$userId/agreements/terms',
          data: const <String, dynamic>{
            'accepted': true,
            'terms_version': 'v1',
          },
        );
      }

      await prefs.setBool(_key, true);
      state = const AsyncData(true);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> reset() async {
    state = const AsyncLoading();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    state = const AsyncData(false);
  }
}
