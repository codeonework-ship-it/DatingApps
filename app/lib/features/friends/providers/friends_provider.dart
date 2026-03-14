import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../core/utils/logger.dart';
import '../../auth/providers/auth_provider.dart';

class FriendConnection {
  const FriendConnection({
    required this.friendUserId,
    required this.friendName,
    required this.status,
    required this.updatedAt,
  });

  factory FriendConnection.fromJson(Map<String, dynamic> json) => FriendConnection(
      friendUserId: json['friend_user_id']?.toString() ?? '',
      friendName: json['friend_name']?.toString() ?? 'Friend',
      status: json['status']?.toString() ?? 'accepted',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  final String friendUserId;
  final String friendName;
  final String status;
  final String updatedAt;
}

class FriendActivityItem {
  const FriendActivityItem({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.createdAt,
  });

  factory FriendActivityItem.fromJson(Map<String, dynamic> json) => FriendActivityItem(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Activity',
      description: json['description']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
    );
  final String id;
  final String type;
  final String title;
  final String description;
  final String createdAt;
}

class FriendsState {
  const FriendsState({
    this.isLoading = false,
    this.isMutating = false,
    this.error,
    this.friends = const <FriendConnection>[],
    this.activities = const <FriendActivityItem>[],
  });
  final bool isLoading;
  final bool isMutating;
  final String? error;
  final List<FriendConnection> friends;
  final List<FriendActivityItem> activities;

  FriendsState copyWith({
    bool? isLoading,
    bool? isMutating,
    String? error,
    bool clearError = false,
    List<FriendConnection>? friends,
    List<FriendActivityItem>? activities,
  }) => FriendsState(
    isLoading: isLoading ?? this.isLoading,
    isMutating: isMutating ?? this.isMutating,
    error: clearError ? null : (error ?? this.error),
    friends: friends ?? this.friends,
    activities: activities ?? this.activities,
  );
}

class FriendsNotifier extends StateNotifier<FriendsState> {
  FriendsNotifier(this._ref) : super(const FriendsState()) {
    Future<void>.microtask(load);
  }

  final Ref _ref;

  Future<void> load() async {
    final userId = _ref.read(authNotifierProvider).userId;
    if (userId == null || userId.trim().isEmpty) {
      state = state.copyWith(isLoading: false, clearError: true);
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    if (kUseMockAuth) {
      state = state.copyWith(
        isLoading: false,
        friends: const <FriendConnection>[
          FriendConnection(
            friendUserId: 'mock-user-002',
            friendName: 'Ava',
            status: 'accepted',
            updatedAt: '2026-03-01T10:00:00Z',
          ),
        ],
        activities: const <FriendActivityItem>[
          FriendActivityItem(
            id: 'friend-default-1',
            type: 'suggested_activity',
            title: 'Plan a Friend Catch-up',
            description:
                'Share one weekly highlight and one goal for next week.',
            createdAt: '2026-03-01T10:00:00Z',
          ),
        ],
      );
      return;
    }

    try {
      final dio = _ref.read(apiClientProvider);
      final friendsResp = await dio.get<Map<String, dynamic>>(
        '/friends/$userId',
      );
      final activitiesResp = await dio.get<Map<String, dynamic>>(
        '/friends/$userId/activities',
        queryParameters: const {'limit': 30},
      );

      final friendsBody =
          (friendsResp.data as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      final activitiesBody =
          (activitiesResp.data as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};

      final friendsRaw = (friendsBody['friends'] as List?) ?? const [];
      final activitiesRaw = (activitiesBody['activities'] as List?) ?? const [];

      state = state.copyWith(
        isLoading: false,
        friends: friendsRaw
            .whereType<Map<String, dynamic>>()
            .map(FriendConnection.fromJson)
            .where((item) => item.friendUserId.isNotEmpty)
            .toList(growable: false),
        activities: activitiesRaw
            .whereType<Map<String, dynamic>>()
            .map(FriendActivityItem.fromJson)
            .where((item) => item.id.isNotEmpty)
            .toList(growable: false),
      );
    } on DioException catch (e, stackTrace) {
      log.error('Failed to load friends', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: _extractApiError(
          e,
          fallback: 'Failed to load friends. Please try again.',
        ),
      );
    } catch (e, stackTrace) {
      log.error('Failed to load friends', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load friends. Please try again.',
      );
    }
  }

  Future<void> addFriend(String friendUserId) async {
    final userId = _ref.read(authNotifierProvider).userId;
    if (userId == null || userId.trim().isEmpty) {
      return;
    }
    state = state.copyWith(isMutating: true, clearError: true);

    if (kUseMockAuth) {
      await load();
      state = state.copyWith(isMutating: false);
      return;
    }

    try {
      final dio = _ref.read(apiClientProvider);
      await dio.post<Map<String, dynamic>>(
        '/friends/$userId',
        data: {'friend_user_id': friendUserId},
      );
      await load();
      state = state.copyWith(isMutating: false);
    } on DioException catch (e, stackTrace) {
      log.error('Failed to add friend', e, stackTrace);
      state = state.copyWith(
        isMutating: false,
        error: _extractApiError(e, fallback: 'Failed to add friend.'),
      );
    } catch (e, stackTrace) {
      log.error('Failed to add friend', e, stackTrace);
      state = state.copyWith(isMutating: false, error: 'Failed to add friend.');
    }
  }

  Future<void> removeFriend(String friendUserId) async {
    final userId = _ref.read(authNotifierProvider).userId;
    if (userId == null || userId.trim().isEmpty) {
      return;
    }

    state = state.copyWith(isMutating: true, clearError: true);

    if (kUseMockAuth) {
      await load();
      state = state.copyWith(isMutating: false);
      return;
    }

    try {
      final dio = _ref.read(apiClientProvider);
      await dio.delete<void>('/friends/$userId/$friendUserId');
      await load();
      state = state.copyWith(isMutating: false);
    } on DioException catch (e, stackTrace) {
      log.error('Failed to remove friend', e, stackTrace);
      state = state.copyWith(
        isMutating: false,
        error: _extractApiError(e, fallback: 'Failed to remove friend.'),
      );
    } catch (e, stackTrace) {
      log.error('Failed to remove friend', e, stackTrace);
      state = state.copyWith(
        isMutating: false,
        error: 'Failed to remove friend.',
      );
    }
  }
}

final friendsProvider = StateNotifierProvider<FriendsNotifier, FriendsState>(
  FriendsNotifier.new,
);

String _extractApiError(DioException e, {required String fallback}) {
  final data = e.response?.data;
  if (data is Map && data['error'] != null) {
    return data['error'].toString();
  }
  return fallback;
}
