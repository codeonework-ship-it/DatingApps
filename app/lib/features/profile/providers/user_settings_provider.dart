import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../core/utils/logger.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/profile_models.dart';

final userSettingsProvider =
    AsyncNotifierProvider<UserSettingsNotifier, UserSettings>(
      UserSettingsNotifier.new,
    );

class UserSettingsNotifier extends AsyncNotifier<UserSettings> {
  @override
  Future<UserSettings> build() async {
    final userId = ref.watch(authNotifierProvider).userId;
    if (userId == null) {
      throw StateError('Not authenticated');
    }

    if (kUseMockAuth) {
      return _defaultSettings(userId);
    }

    final dio = ref.read(apiClientProvider);
    try {
      final response = await dio.get<Map<String, dynamic>>('/settings/$userId');
      return _fromApi(userId, response.data);
    } on DioException catch (e, stackTrace) {
      log.error('Failed to fetch user settings', e, stackTrace);
      rethrow;
    }
  }

  Future<void> patchSettings({
    bool? showAge,
    bool? showExactDistance,
    bool? showOnlineStatus,
    bool? notifyNewMatch,
    bool? notifyNewMessage,
    bool? notifyLikes,
    String? theme,
    String? locale,
  }) async {
    final current = await future;
    final next = current.copyWith(
      showAge: showAge ?? current.showAge,
      showExactDistance: showExactDistance ?? current.showExactDistance,
      showOnlineStatus: showOnlineStatus ?? current.showOnlineStatus,
      notifyNewMatch: notifyNewMatch ?? current.notifyNewMatch,
      notifyNewMessage: notifyNewMessage ?? current.notifyNewMessage,
      notifyLikes: notifyLikes ?? current.notifyLikes,
      theme: theme ?? current.theme,
      locale: locale ?? current.locale,
      updatedAt: DateTime.now(),
    );
    state = AsyncData(next);

    if (kUseMockAuth) {
      return;
    }

    final dio = ref.read(apiClientProvider);
    try {
      // Only what changed: the copy loaded earlier can be stale (the theme
      // and notification switches save through their own endpoints), and the
      // server applies every field it is sent.
      final response = await dio.patch<Map<String, dynamic>>(
        '/settings/${current.userId}',
        data: {
          'show_age': ?showAge,
          'show_exact_distance': ?showExactDistance,
          'show_online_status': ?showOnlineStatus,
          'notify_new_match': ?notifyNewMatch,
          'notify_new_message': ?notifyNewMessage,
          'notify_likes': ?notifyLikes,
          'theme': ?theme,
          // Empty returns the member to the device language (stored NULL).
          'locale': ?locale,
        },
      );
      state = AsyncData(_fromApi(current.userId, response.data));
    } on DioException catch (e, stackTrace) {
      log.error('Failed to patch user settings', e, stackTrace);
      state = AsyncError(e, stackTrace);
    }
  }

  UserSettings _fromApi(String userId, dynamic data) {
    final root = (data as Map?)?.cast<String, dynamic>() ?? const {};
    final payload =
        (root['settings'] as Map?)?.cast<String, dynamic>() ?? const {};

    return UserSettings(
      userId: userId,
      showAge: payload['show_age'] as bool? ?? true,
      showExactDistance: payload['show_exact_distance'] as bool? ?? false,
      showOnlineStatus: payload['show_online_status'] as bool? ?? true,
      notifyNewMatch: payload['notify_new_match'] as bool? ?? true,
      notifyNewMessage: payload['notify_new_message'] as bool? ?? true,
      notifyLikes: payload['notify_likes'] as bool? ?? true,
      theme: payload['theme']?.toString() ?? 'auto',
      locale: payload['locale']?.toString().trim() ?? '',
      updatedAt: DateTime.tryParse(payload['updated_at']?.toString() ?? ''),
    );
  }

  UserSettings _defaultSettings(String userId) => UserSettings(
    userId: userId,
    showAge: true,
    showExactDistance: false,
    showOnlineStatus: true,
    notifyNewMatch: true,
    notifyNewMessage: true,
    notifyLikes: true,
    theme: 'auto',
    locale: '',
  );
}
