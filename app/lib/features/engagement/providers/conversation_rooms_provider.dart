import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/network/api_error_message.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../core/utils/logger.dart';
import '../../auth/providers/auth_provider.dart';

/// Conversation Rooms are live chat rooms (`/v1/rooms`, migration 117):
/// always-on public topic rooms plus short rooms members host. Joining a room
/// returns its chat channel in the shared chat engine; the member list lets
/// people add each other as friends.

int _int(Object? v) => v is num ? v.toInt() : 0;

DateTime? _time(Object? v) =>
    v is String && v.isNotEmpty ? DateTime.tryParse(v)?.toLocal() : null;

/// Room categories, in display order.
const roomCategories = <String, String>{
  'talk': 'Talk',
  'interests': 'Interests',
  'active': 'Out & about',
  'city': 'Your city',
};

class ConversationRoom {
  const ConversationRoom({
    required this.id,
    required this.theme,
    required this.description,
    required this.lifecycleState,
    this.slug = '',
    this.category = 'talk',
    this.iconKey = 'forum',
    this.emoji = '',
    this.roomType = 'topic',
    this.city = '',
    this.alwaysOn = false,
    this.startsAt,
    this.endsAt,
    this.capacity = 0,
    this.participantCount = 0,
    this.hereNow = 0,
    this.friendsHere = 0,
    this.isParticipant = false,
    this.myRole = '',
    this.canModerate = false,
    this.isHost = false,
    this.hostName = '',
    this.channelId = '',
  });

  factory ConversationRoom.fromJson(Map<dynamic, dynamic> json) =>
      ConversationRoom(
        id: json['id']?.toString() ?? '',
        theme:
            (json['title'] ?? json['theme'])?.toString().trim().isNotEmpty ==
                true
            ? (json['title'] ?? json['theme']).toString()
            : 'Room',
        description: json['description']?.toString() ?? '',
        lifecycleState: json['lifecycle_state']?.toString() ?? 'scheduled',
        slug: json['slug']?.toString() ?? '',
        category: json['category']?.toString() ?? 'talk',
        iconKey: json['icon_key']?.toString() ?? 'forum',
        emoji: json['emoji']?.toString() ?? '',
        roomType: json['room_type']?.toString() ?? 'topic',
        city: json['city']?.toString() ?? '',
        alwaysOn: json['always_on'] == true,
        startsAt: _time(json['starts_at']),
        endsAt: _time(json['ends_at']),
        capacity: _int(json['capacity']),
        participantCount: _int(json['participant_count']),
        hereNow: _int(json['here_now']),
        friendsHere: _int(json['friends_here']),
        isParticipant: json['is_participant'] == true,
        myRole: json['my_role']?.toString() ?? '',
        canModerate: json['can_moderate'] == true,
        isHost: json['is_host'] == true,
        hostName: json['host_name']?.toString() ?? '',
        channelId: json['channel_id']?.toString() ?? '',
      );

  final String id;

  /// The room's name (the API's `title`; `theme` for older servers).
  final String theme;
  final String description;

  /// `active`, `scheduled` or `closed`.
  final String lifecycleState;
  final String slug;
  final String category;
  final String iconKey;
  final String emoji;

  /// `topic` (always-on public rooms) or `member` (hosted by a member).
  final String roomType;
  final String city;
  final bool alwaysOn;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final int capacity;
  final int participantCount;

  /// Members whose presence heartbeat is under two minutes old.
  final int hereNow;

  /// Accepted friends currently in the room.
  final int friendsHere;
  final bool isParticipant;

  /// `host`, `moderator`, `participant`, or empty when not in the room.
  final String myRole;

  /// Hosts and moderators may warn and remove members.
  final bool canModerate;

  /// The signed-in member started this room.
  final bool isHost;
  final String hostName;

  /// The room's chat channel, set once the member has joined.
  final String channelId;

  String get title => theme;
  bool get isLive => lifecycleState == 'active';
  bool get isClosed => lifecycleState == 'closed';
  bool get isFull => capacity > 0 && participantCount >= capacity;

  ConversationRoom copyWith({int? hereNow, int? participantCount}) =>
      ConversationRoom(
        id: id,
        theme: theme,
        description: description,
        lifecycleState: lifecycleState,
        slug: slug,
        category: category,
        iconKey: iconKey,
        emoji: emoji,
        roomType: roomType,
        city: city,
        alwaysOn: alwaysOn,
        startsAt: startsAt,
        endsAt: endsAt,
        capacity: capacity,
        participantCount: participantCount ?? this.participantCount,
        hereNow: hereNow ?? this.hereNow,
        friendsHere: friendsHere,
        isParticipant: isParticipant,
        myRole: myRole,
        canModerate: canModerate,
        isHost: isHost,
        hostName: hostName,
        channelId: channelId,
      );
}

/// Someone in a room, as `GET /rooms/{id}/members` lists them.
class RoomMember {
  const RoomMember({
    required this.userId,
    required this.name,
    this.photoUrl = '',
    this.role = 'participant',
    this.hereNow = false,
    this.isMe = false,
    this.friendStatus = 'none',
    this.mutedUntil,
  });

  factory RoomMember.fromJson(Map<dynamic, dynamic> json) => RoomMember(
    userId: json['user_id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    photoUrl: json['photo_url']?.toString() ?? '',
    role: json['role']?.toString() ?? 'participant',
    hereNow: json['here_now'] == true,
    isMe: json['is_me'] == true,
    friendStatus: json['friend_status']?.toString() ?? 'none',
    mutedUntil: _time(json['muted_until']),
  );

  final String userId, name, photoUrl;

  /// `host`, `moderator` or `participant`.
  final String role;
  final bool hereNow, isMe;

  /// `me`, `friends`, `requested`, `incoming` or `none`.
  final String friendStatus;

  /// When this member's mute ends. Only hosts, moderators and the muted
  /// member themselves are told.
  final DateTime? mutedUntil;

  bool get isMuted => mutedUntil != null && mutedUntil!.isAfter(DateTime.now());

  String get displayName => name.trim().isEmpty ? 'Member' : name.trim();
}

/// Why a room action failed, with the server's stable code when it sent one
/// (`ROOM_CLOSED`, `ROOM_CAPACITY_REACHED`, `ROOM_BLOCKED_ACTIVE_SESSION`,
/// `ROOM_NOT_JOINED`).
class RoomActionException implements Exception {
  const RoomActionException(this.message, {this.code = ''});
  final String message;
  final String code;

  /// The member is no longer in the room and the chat should close.
  bool get endsVisit =>
      code == 'ROOM_BLOCKED_ACTIVE_SESSION' ||
      code == 'ROOM_NOT_JOINED' ||
      code == 'ROOM_CLOSED';

  @override
  String toString() => message;
}

RoomActionException _roomError(Object e, String fallback) {
  if (e is DioException) {
    final data = e.response?.data;
    final code = data is Map ? data['error_code']?.toString() ?? '' : '';
    return RoomActionException(
      apiErrorMessage(e, fallback: fallback),
      code: code,
    );
  }
  return RoomActionException(fallback);
}

ConversationRoom _roomFrom(Response<dynamic> response) {
  final data = response.data;
  final room = data is Map ? data['room'] : null;
  return ConversationRoom.fromJson(room is Map ? room : const {});
}

/// The room endpoints the screens use.
class RoomsApi {
  const RoomsApi(this._dio);
  final Dio _dio;

  Future<ConversationRoom> join(String roomId) async {
    try {
      return _roomFrom(await _dio.post<dynamic>('/rooms/$roomId/join'));
    } on Object catch (e) {
      throw _roomError(e, 'Could not join this room. Please retry.');
    }
  }

  Future<ConversationRoom> leave(String roomId) async {
    try {
      return _roomFrom(await _dio.post<dynamic>('/rooms/$roomId/leave'));
    } on Object catch (e) {
      throw _roomError(e, 'Could not leave this room. Please retry.');
    }
  }

  /// Presence heartbeat; [away] when the member leaves the chat screen.
  Future<ConversationRoom> presence(String roomId, {bool away = false}) async {
    try {
      return _roomFrom(
        await _dio.post<dynamic>(
          '/rooms/$roomId/presence',
          data: {'state': away ? 'away' : 'here'},
        ),
      );
    } on Object catch (e) {
      throw _roomError(e, 'Lost touch with the room.');
    }
  }

  Future<List<RoomMember>> members(String roomId) async {
    try {
      final response = await _dio.get<dynamic>('/rooms/$roomId/members');
      final data = response.data;
      final rows = data is Map ? data['members'] as List? : null;
      return [
        for (final row in rows ?? const [])
          if (row is Map) RoomMember.fromJson(row),
      ];
    } on Object catch (e) {
      throw _roomError(e, 'Could not load who is here. Please retry.');
    }
  }

  /// `action` is `warn_user`, `mute_user`, `unmute_user`, `remove_user` or
  /// `close_room`. [duration] applies to `mute_user`: `10m`, `1h` or
  /// `session` (until the room ends; 24 hours for always-on rooms).
  Future<ConversationRoom> moderate(
    String roomId, {
    required String action,
    String targetUserId = '',
    String reason = '',
    String duration = '',
  }) async {
    try {
      return _roomFrom(
        await _dio.post<dynamic>(
          '/rooms/$roomId/moderate',
          data: {
            if (targetUserId.isNotEmpty) 'target_user_id': targetUserId,
            'action': action,
            if (reason.trim().isNotEmpty) 'reason': reason.trim(),
            if (duration.isNotEmpty) 'duration': duration,
          },
        ),
      );
    } on Object catch (e) {
      throw _roomError(e, 'That did not go through. Please retry.');
    }
  }

  Future<ConversationRoom> create({
    required String title,
    required String category,
    String description = '',
    DateTime? startsAt,
    int durationMinutes = 60,
    int capacity = 30,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/rooms',
        data: {
          'title': title.trim(),
          'description': description.trim(),
          'category': category,
          if (startsAt != null) 'starts_at': startsAt.toUtc().toIso8601String(),
          'duration_minutes': durationMinutes,
          'capacity': capacity,
        },
      );
      return _roomFrom(response);
    } on Object catch (e) {
      throw _roomError(e, 'Could not start the room. Please retry.');
    }
  }
}

final roomsApiProvider = Provider<RoomsApi>(
  (ref) => RoomsApi(ref.watch(apiClientProvider)),
);

/// The people in a room (members only).
final roomMembersProvider = FutureProvider.autoDispose
    .family<List<RoomMember>, String>(
      (ref, roomId) => ref.watch(roomsApiProvider).members(roomId),
    );

class ConversationRoomsState {
  const ConversationRoomsState({
    this.isLoading = false,
    this.isMutating = false,
    this.error,
    this.rooms = const <ConversationRoom>[],
    this.category = '',
    this.friendOnly = false,
  });
  final bool isLoading;
  final bool isMutating;
  final String? error;
  final List<ConversationRoom> rooms;

  /// Category filter for the "All rooms" section; empty for all.
  final String category;
  final bool friendOnly;

  List<ConversationRoom> get joined =>
      rooms.where((r) => r.isParticipant && !r.isClosed).toList();

  /// Rooms with someone here now, busiest first.
  List<ConversationRoom> get liveNow =>
      (rooms.where((r) => r.isLive && r.hereNow > 0).toList()
        ..sort((a, b) => b.hereNow.compareTo(a.hereNow)));

  List<ConversationRoom> get upcoming =>
      rooms.where((r) => r.lifecycleState == 'scheduled').toList();

  List<ConversationRoom> get browsable => rooms
      .where(
        (r) =>
            r.isLive &&
            (category.isEmpty || r.category == category) &&
            (!friendOnly || r.friendsHere > 0 || r.isParticipant),
      )
      .toList();

  ConversationRoomsState copyWith({
    bool? isLoading,
    bool? isMutating,
    String? error,
    bool clearError = false,
    List<ConversationRoom>? rooms,
    String? category,
    bool? friendOnly,
  }) => ConversationRoomsState(
    isLoading: isLoading ?? this.isLoading,
    isMutating: isMutating ?? this.isMutating,
    error: clearError ? null : (error ?? this.error),
    rooms: rooms ?? this.rooms,
    category: category ?? this.category,
    friendOnly: friendOnly ?? this.friendOnly,
  );
}

const _mockRooms = <ConversationRoom>[
  ConversationRoom(
    id: 'room-late-night',
    theme: 'Late-night talks',
    description:
        "Can't sleep? Neither can we. Slow, honest conversation for "
        'night owls.',
    lifecycleState: 'active',
    category: 'talk',
    iconKey: 'night',
    alwaysOn: true,
    capacity: 200,
    participantCount: 14,
    hereNow: 6,
    friendsHere: 1,
  ),
  ConversationRoom(
    id: 'room-bookworms',
    theme: "Bookworms' corner",
    description: "What you're reading, and the one you press on everyone.",
    lifecycleState: 'active',
    category: 'interests',
    iconKey: 'book',
    alwaysOn: true,
    capacity: 200,
    participantCount: 5,
  ),
];

class ConversationRoomsNotifier extends StateNotifier<ConversationRoomsState> {
  ConversationRoomsNotifier(this._ref) : super(const ConversationRoomsState()) {
    Future<void>.microtask(loadRooms);
  }

  final Ref _ref;

  Future<void> loadRooms() async {
    state = state.copyWith(isLoading: true, clearError: true);
    if (kUseMockAuth) {
      state = state.copyWith(isLoading: false, rooms: _mockRooms);
      return;
    }
    try {
      final response = await _ref
          .read(apiClientProvider)
          .get<dynamic>('/rooms', queryParameters: {'limit': 100});
      final data = response.data;
      final rows = data is Map ? data['rooms'] as List? : null;
      final rooms = [
        for (final row in rows ?? const [])
          if (row is Map) ConversationRoom.fromJson(row),
      ].where((room) => room.id.isNotEmpty).toList(growable: false);
      if (!mounted) {
        return;
      }
      state = state.copyWith(isLoading: false, rooms: rooms);
    } on Object catch (e, stackTrace) {
      log.error('Failed to load rooms', e, stackTrace);
      if (!mounted) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        error: apiErrorMessage(
          e,
          fallback: 'Rooms are unavailable right now. Pull to retry.',
        ),
      );
    }
  }

  void setCategory(String category) =>
      state = state.copyWith(category: category);

  void setFriendOnly({required bool value}) =>
      state = state.copyWith(friendOnly: value);

  /// Joins [roomId] and returns the room with its chat channel.
  Future<ConversationRoom> joinRoom(String roomId) async {
    state = state.copyWith(isMutating: true, clearError: true);
    try {
      final room = await _ref.read(roomsApiProvider).join(roomId);
      _replace(room);
      return room;
    } finally {
      if (mounted) {
        state = state.copyWith(isMutating: false);
      }
    }
  }

  Future<void> leaveRoom(String roomId) async {
    state = state.copyWith(isMutating: true, clearError: true);
    try {
      _replace(await _ref.read(roomsApiProvider).leave(roomId));
    } finally {
      if (mounted) {
        state = state.copyWith(isMutating: false);
      }
    }
  }

  Future<ConversationRoom> createRoom({
    required String title,
    required String category,
    String description = '',
    int durationMinutes = 60,
    int capacity = 30,
  }) async {
    final room = await _ref
        .read(roomsApiProvider)
        .create(
          title: title,
          category: category,
          description: description,
          durationMinutes: durationMinutes,
          capacity: capacity,
        );
    _replace(room);
    return room;
  }

  /// Applies a fresher copy of a room (from join, leave or a heartbeat).
  void updateRoom(ConversationRoom room) => _replace(room);

  void _replace(ConversationRoom updated) {
    if (!mounted || updated.id.isEmpty) {
      return;
    }
    final index = state.rooms.indexWhere((room) => room.id == updated.id);
    final out = List<ConversationRoom>.from(state.rooms);
    if (index < 0) {
      out.insert(0, updated);
    } else {
      out[index] = updated;
    }
    state = state.copyWith(rooms: out);
  }
}

final conversationRoomsProvider =
    StateNotifierProvider<ConversationRoomsNotifier, ConversationRoomsState>((
      ref,
    ) {
      // Per member: signing in as someone else on this device must never
      // show the previous member's rooms and roles.
      ref.watch(authNotifierProvider.select((s) => s.userId));
      return ConversationRoomsNotifier(ref);
    });

/// The signed-in member's id, for comparing against room members.
String currentRoomUserId(Ref ref) =>
    ref.read(authNotifierProvider).userId ?? '';
