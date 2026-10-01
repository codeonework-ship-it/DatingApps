import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/api_client_provider.dart';
import '../../../core/utils/logger.dart';
import '../../auth/providers/auth_provider.dart';

/// The member's account lifecycle state, as the server reports it.
///
/// `deactivated` is carried separately from `isActive` on purpose. `is_active`
/// means the platform has enabled the account and gates sign-in; a self-service
/// pause is recorded as `deactivated_at` so the member can still sign back in
/// to undo it. Collapsing the two here would make a paused account look
/// disabled.
class AccountLifecycle {
  const AccountLifecycle({
    required this.isActive,
    required this.deactivated,
    this.deletionRequestedAt,
    this.deletionEffectiveAt,
    this.deletionCancellable = false,
    this.exportReady = false,
    this.exportExpiresAt,
  });

  factory AccountLifecycle.fromApi(Map<String, dynamic>? payload) {
    final data = payload ?? const <String, dynamic>{};
    DateTime? parse(Object? raw) {
      final text = raw?.toString().trim() ?? '';
      if (text.isEmpty) {
        return null;
      }
      return DateTime.tryParse(text)?.toLocal();
    }

    return AccountLifecycle(
      isActive: data['is_active'] == true,
      deactivated: data['deactivated'] == true,
      deletionRequestedAt: parse(data['deletion_requested_at']),
      deletionEffectiveAt: parse(data['deletion_effective_at']),
      deletionCancellable: data['deletion_cancellable'] == true,
      exportReady: data['export_ready'] == true,
      exportExpiresAt: parse(data['export_expires_at']),
    );
  }

  final bool isActive;
  final bool deactivated;
  final DateTime? deletionRequestedAt;
  final DateTime? deletionEffectiveAt;
  final bool deletionCancellable;
  final bool exportReady;
  final DateTime? exportExpiresAt;

  bool get deletionScheduled => deletionEffectiveAt != null;

  /// Whole days left before erasure, floored at zero.
  int get daysUntilDeletion {
    final effective = deletionEffectiveAt;
    if (effective == null) {
      return 0;
    }
    final remaining = effective.difference(DateTime.now());
    return remaining.isNegative ? 0 : remaining.inDays;
  }
}

final accountLifecycleProvider =
    AsyncNotifierProvider<AccountLifecycleNotifier, AccountLifecycle>(
      AccountLifecycleNotifier.new,
    );

class AccountLifecycleNotifier extends AsyncNotifier<AccountLifecycle> {
  String get _userId {
    final id = ref.read(authNotifierProvider).userId?.trim();
    if (id == null || id.isEmpty) {
      throw StateError('Not authenticated');
    }
    return id;
  }

  @override
  Future<AccountLifecycle> build() async {
    final userId = ref.watch(authNotifierProvider).userId;
    if (userId == null) {
      throw StateError('Not authenticated');
    }
    return _fetch(userId);
  }

  Future<AccountLifecycle> _fetch(String userId) async {
    final response = await ref
        .read(apiClientProvider)
        .get<Map<String, dynamic>>('/account/$userId/lifecycle');
    final lifecycle = response.data?['lifecycle'];
    return AccountLifecycle.fromApi(
      lifecycle is Map ? lifecycle.cast<String, dynamic>() : null,
    );
  }

  /// Runs a lifecycle mutation and adopts the state the server returns.
  ///
  /// The response already carries the new lifecycle, so it is used directly
  /// rather than re-fetching: a second round trip would leave the screen
  /// showing the old state for as long as it took, on the one screen where
  /// stale state is alarming.
  Future<void> _mutate(
    Future<Response<Map<String, dynamic>>> Function(Dio dio, String userId)
    request,
  ) async {
    final userId = _userId;
    state = const AsyncValue<AccountLifecycle>.loading();
    try {
      final response = await request(ref.read(apiClientProvider), userId);
      final lifecycle = response.data?['lifecycle'];
      state = AsyncValue.data(
        AccountLifecycle.fromApi(
          lifecycle is Map ? lifecycle.cast<String, dynamic>() : null,
        ),
      );
    } on DioException catch (e, stackTrace) {
      log.error('Account lifecycle request failed', e, stackTrace);
      // Re-read rather than keep the error as the screen's state: the action
      // failed but the account still has a real state the member needs to see.
      state = await AsyncValue.guard(() => _fetch(userId));
      rethrow;
    }
  }

  Future<void> deactivate({String? reason}) => _mutate(
    (dio, userId) => dio.post<Map<String, dynamic>>(
      '/account/$userId/deactivate',
      data: {if (reason != null && reason.isNotEmpty) 'reason': reason},
    ),
  );

  Future<void> reactivate() => _mutate(
    (dio, userId) =>
        dio.post<Map<String, dynamic>>('/account/$userId/reactivate'),
  );

  Future<void> requestDeletion({String? reason}) => _mutate(
    (dio, userId) => dio.post<Map<String, dynamic>>(
      '/account/$userId/deletion',
      data: {if (reason != null && reason.isNotEmpty) 'reason': reason},
    ),
  );

  Future<void> cancelDeletion() => _mutate(
    (dio, userId) =>
        dio.delete<Map<String, dynamic>>('/account/$userId/deletion'),
  );

  /// Requests a fresh export and returns it.
  ///
  /// The payload is handed straight back to the caller instead of being held
  /// in provider state: it is a large one-off document the member saves or
  /// views, not something every rebuild should carry.
  Future<Map<String, dynamic>> createExport() async {
    final userId = _userId;
    final response = await ref
        .read(apiClientProvider)
        .post<Map<String, dynamic>>('/account/$userId/export');
    state = await AsyncValue.guard(() => _fetch(userId));
    final export = response.data?['export'];
    return export is Map ? export.cast<String, dynamic>() : {};
  }

  Future<Map<String, dynamic>?> fetchExport() async {
    final userId = _userId;
    try {
      final response = await ref
          .read(apiClientProvider)
          .get<Map<String, dynamic>>('/account/$userId/export');
      final export = response.data?['export'];
      return export is Map ? export.cast<String, dynamic>() : null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(() => _fetch(_userId));
  }
}
