import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../core/providers/safety_actions_provider.dart';
import '../../../core/utils/logger.dart';
import '../../auth/providers/auth_provider.dart';

class BlockedUserItem {
  const BlockedUserItem({required this.id, required this.name, this.photoUrl});
  final String id;
  final String name;
  final String? photoUrl;
}

final blockedUsersProvider =
    AsyncNotifierProvider<BlockedUsersNotifier, List<BlockedUserItem>>(
      BlockedUsersNotifier.new,
    );

class BlockedUsersNotifier extends AsyncNotifier<List<BlockedUserItem>> {
  @override
  Future<List<BlockedUserItem>> build() async {
    final userId = ref.watch(authNotifierProvider).userId;
    if (userId == null) {
      throw StateError('Not authenticated');
    }
    return _fetchBlockedUsers(userId);
  }

  Future<void> refresh() async {
    final userId = _requireUserId();
    state = AsyncData(await _fetchBlockedUsers(userId));
  }

  Future<void> unblockUser(String blockedUserId) async {
    final userId = _requireUserId();
    final previous = state.valueOrNull ?? await future;

    try {
      if (kUseMockAuth) {
        state = AsyncData(
          previous.where((user) => user.id != blockedUserId).toList(),
        );
        return;
      }

      await ref
          .read(safetyActionsProvider)
          .unblockUser(blockedUserId: blockedUserId);
      state = AsyncData(await _fetchBlockedUsers(userId));
    } catch (e, stackTrace) {
      log.error('Failed to unblock user', e, stackTrace);
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<List<BlockedUserItem>> _fetchBlockedUsers(String currentUserId) async {
    if (kUseMockAuth) {
      return state.valueOrNull ?? const <BlockedUserItem>[];
    }

    final dio = ref.read(apiClientProvider);
    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/blocked-users/$currentUserId',
      );
      final data = (response.data as Map?)?.cast<String, dynamic>() ?? const {};
      final rows =
          (data['blocked_users'] as List?)?.cast<dynamic>() ?? const [];
      return rows
          .whereType<Map<dynamic, dynamic>>()
          .map((row) => row.cast<String, dynamic>())
          .map(
            (row) => BlockedUserItem(
              id: row['id']?.toString() ?? '',
              name: row['name']?.toString() ?? 'Unknown User',
              photoUrl: row['photo_url']?.toString(),
            ),
          )
          .where((item) => item.id.isNotEmpty)
          .toList();
    } on DioException catch (e, stackTrace) {
      log.error('Failed to fetch blocked users', e, stackTrace);
      return state.valueOrNull ?? const <BlockedUserItem>[];
    }
  }

  String _requireUserId() {
    final userId = ref.read(authNotifierProvider).userId;
    if (userId == null) {
      throw StateError('Not authenticated');
    }
    return userId;
  }
}
