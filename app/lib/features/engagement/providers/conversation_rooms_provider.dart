import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../core/utils/logger.dart';
import '../../auth/providers/auth_provider.dart';

class ConversationRoom {
  const ConversationRoom({
    required this.id,
    required this.theme,
    required this.description,
    required this.lifecycleState,
    required this.startsAt,
    required this.endsAt,
    required this.capacity,
    required this.participantCount,
    required this.participantUserIds,
    required this.isParticipant,
  });

  factory ConversationRoom.fromJson(Map<String, dynamic> json) => ConversationRoom(
      id: json['id']?.toString() ?? '',
      theme: json['theme']?.toString() ?? 'Room',
      description: json['description']?.toString() ?? '',
      lifecycleState: json['lifecycle_state']?.toString() ?? 'scheduled',
      startsAt: json['starts_at']?.toString() ?? '',
      endsAt: json['ends_at']?.toString() ?? '',
      capacity: (json['capacity'] as num?)?.toInt() ?? 0,
      participantCount: (json['participant_count'] as num?)?.toInt() ?? 0,
      participantUserIds: ((json['participant_user_ids'] as List?) ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
      isParticipant: json['is_participant'] == true,
    );
  final String id;
  final String theme;
  final String description;
  final String lifecycleState;
  final String startsAt;
  final String endsAt;
  final int capacity;
  final int participantCount;
  final List<String> participantUserIds;
  final bool isParticipant;
}

class ConversationRoomsState {
  const ConversationRoomsState({
    this.isLoading = false,
    this.isMutating = false,
    this.error,
    this.rooms = const <ConversationRoom>[],
    this.stateFilter = '',
    this.friendOnly = false,
  });
  final bool isLoading;
  final bool isMutating;
  final String? error;
  final List<ConversationRoom> rooms;
  final String stateFilter;
  final bool friendOnly;

  ConversationRoomsState copyWith({
    bool? isLoading,
    bool? isMutating,
    String? error,
    bool clearError = false,
    List<ConversationRoom>? rooms,
    String? stateFilter,
    bool? friendOnly,
  }) => ConversationRoomsState(
    isLoading: isLoading ?? this.isLoading,
    isMutating: isMutating ?? this.isMutating,
    error: clearError ? null : (error ?? this.error),
    rooms: rooms ?? this.rooms,
    stateFilter: stateFilter ?? this.stateFilter,
    friendOnly: friendOnly ?? this.friendOnly,
  );
}

class ConversationRoomsNotifier extends StateNotifier<ConversationRoomsState> {
  ConversationRoomsNotifier(this._ref) : super(const ConversationRoomsState()) {
    Future<void>.microtask(loadRooms);
  }

  final Ref _ref;

  Future<void> loadRooms({String stateFilter = '', bool? friendOnly}) async {
    final resolvedFriendOnly = friendOnly ?? state.friendOnly;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      stateFilter: stateFilter,
      friendOnly: resolvedFriendOnly,
    );

    if (kUseMockAuth) {
      state = state.copyWith(
        isLoading: false,
        rooms: const <ConversationRoom>[
          ConversationRoom(
            id: 'room-communication-reset',
            theme: 'Communication Reset',
            description: 'Share one communication pattern this week.',
            lifecycleState: 'active',
            startsAt: '2026-03-01T10:00:00Z',
            endsAt: '2026-03-01T11:00:00Z',
            capacity: 20,
            participantCount: 3,
            participantUserIds: <String>['mock-user-001', 'u2', 'u3'],
            isParticipant: true,
          ),
        ],
      );
      return;
    }

    try {
      final userId = _ref.read(authNotifierProvider).userId;
      final dio = _ref.read(apiClientProvider);
      final response = await dio.get<Map<String, dynamic>>(
        '/rooms',
        queryParameters: {
          'user_id': userId,
          if (stateFilter.trim().isNotEmpty) 'state': stateFilter.trim(),
          if (resolvedFriendOnly) 'friend_only': true,
          'limit': 50,
        },
      );
      final body =
          (response.data as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      final roomsRaw = (body['rooms'] as List?) ?? const [];
      final rooms = roomsRaw
          .whereType<Map<String, dynamic>>()
          .map(ConversationRoom.fromJson)
          .where((room) => room.id.isNotEmpty)
          .toList(growable: false);

      state = state.copyWith(isLoading: false, rooms: rooms);
    } on DioException catch (e, stackTrace) {
      log.error('Failed to load rooms', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: _extractApiError(
          e,
          fallback: 'Failed to load conversation rooms. Please try again.',
        ),
      );
    } catch (e, stackTrace) {
      log.error('Failed to load rooms', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load conversation rooms. Please try again.',
      );
    }
  }

  Future<void> joinRoom(String roomId) async {
    await _roomMutation(roomId: roomId, endpointSuffix: 'join');
  }

  Future<void> leaveRoom(String roomId) async {
    await _roomMutation(roomId: roomId, endpointSuffix: 'leave');
  }

  Future<void> moderateRoom({
    required String roomId,
    required String targetUserId,
    required String action,
    String reason = '',
  }) async {
    final moderatorUserId = _ref.read(authNotifierProvider).userId;
    if (moderatorUserId == null || moderatorUserId.trim().isEmpty) {
      state = state.copyWith(error: 'User session not available.');
      return;
    }

    state = state.copyWith(isMutating: true, clearError: true);

    if (kUseMockAuth) {
      state = state.copyWith(isMutating: false);
      await loadRooms(
        stateFilter: state.stateFilter,
        friendOnly: state.friendOnly,
      );
      return;
    }

    try {
      final dio = _ref.read(apiClientProvider);
      final response = await dio.post<Map<String, dynamic>>(
        '/rooms/$roomId/moderate',
        data: {
          'moderator_user_id': moderatorUserId,
          'target_user_id': targetUserId,
          'action': action,
          'reason': reason,
        },
      );
      final body =
          (response.data as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      final roomRaw =
          (body['room'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};

      state = state.copyWith(
        isMutating: false,
        rooms: _replaceRoom(ConversationRoom.fromJson(roomRaw)),
      );
    } on DioException catch (e, stackTrace) {
      log.error('Failed to moderate room', e, stackTrace);
      state = state.copyWith(
        isMutating: false,
        error: _extractApiError(
          e,
          fallback: 'Failed to apply moderation action. Please try again.',
        ),
      );
    } catch (e, stackTrace) {
      log.error('Failed to moderate room', e, stackTrace);
      state = state.copyWith(
        isMutating: false,
        error: 'Failed to apply moderation action. Please try again.',
      );
    }
  }

  Future<void> _roomMutation({
    required String roomId,
    required String endpointSuffix,
  }) async {
    final userId = _ref.read(authNotifierProvider).userId;
    if (userId == null || userId.trim().isEmpty) {
      state = state.copyWith(error: 'User session not available.');
      return;
    }

    state = state.copyWith(isMutating: true, clearError: true);

    if (kUseMockAuth) {
      state = state.copyWith(isMutating: false);
      await loadRooms(
        stateFilter: state.stateFilter,
        friendOnly: state.friendOnly,
      );
      return;
    }

    try {
      final dio = _ref.read(apiClientProvider);
      final response = await dio.post<Map<String, dynamic>>(
        '/rooms/$roomId/$endpointSuffix',
        data: {'user_id': userId},
      );
      final body =
          (response.data as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      final roomRaw =
          (body['room'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};

      state = state.copyWith(
        isMutating: false,
        rooms: _replaceRoom(ConversationRoom.fromJson(roomRaw)),
      );
    } on DioException catch (e, stackTrace) {
      log.error('Room mutation failed', e, stackTrace);
      state = state.copyWith(
        isMutating: false,
        error: _extractApiError(
          e,
          fallback: 'Failed to update room. Please try again.',
        ),
      );
    } catch (e, stackTrace) {
      log.error('Room mutation failed', e, stackTrace);
      state = state.copyWith(
        isMutating: false,
        error: 'Failed to update room. Please try again.',
      );
    }
  }

  List<ConversationRoom> _replaceRoom(ConversationRoom updated) {
    final index = state.rooms.indexWhere((room) => room.id == updated.id);
    if (index < 0) {
      return <ConversationRoom>[updated, ...state.rooms];
    }
    final out = List<ConversationRoom>.from(state.rooms);
    out[index] = updated;
    return out;
  }
}

final conversationRoomsProvider =
    StateNotifierProvider<ConversationRoomsNotifier, ConversationRoomsState>(
      ConversationRoomsNotifier.new,
    );

String _extractApiError(DioException e, {required String fallback}) {
  final data = e.response?.data;
  if (data is Map && data['error'] != null) {
    return data['error'].toString();
  }
  return fallback;
}
