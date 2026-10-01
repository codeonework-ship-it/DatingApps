import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../core/utils/logger.dart';
import '../../auth/providers/auth_provider.dart';
import '../friend_actions.dart';

class FriendConnection {
  const FriendConnection({
    required this.friendUserId,
    required this.friendName,
    required this.status,
    required this.direction,
    required this.updatedAt,
    this.username = '',
    this.photoUrl = '',
    this.city = '',
    this.source = '',
    this.createdAt = '',
  });

  factory FriendConnection.fromJson(Map<String, dynamic> json) =>
      FriendConnection(
        friendUserId: json['friend_user_id']?.toString() ?? '',
        friendName: json['friend_name']?.toString() ?? 'Friend',
        status: json['status']?.toString() ?? 'accepted',
        direction: json['direction']?.toString() ?? '',
        updatedAt: json['updated_at']?.toString() ?? '',
        username: json['friend_username']?.toString() ?? '',
        photoUrl: json['friend_photo_url']?.toString() ?? '',
        city: json['friend_city']?.toString() ?? '',
        source: json['source']?.toString() ?? '',
        createdAt: json['created_at']?.toString() ?? '',
      );
  final String friendUserId;
  final String friendName;

  /// `accepted` or `pending`.
  final String status;

  /// `incoming`, `outgoing`, or empty for an accepted friend.
  final String direction;
  final String updatedAt;
  final String username;
  final String photoUrl;
  final String city;

  /// Where the request started: search, match, profile, room or group.
  final String source;
  final String createdAt;

  bool get isAccepted => status == 'accepted';
  bool get isIncoming => status == 'pending' && direction == 'incoming';
  bool get isOutgoing => status == 'pending' && direction != 'incoming';
}

/// A member offered by the Add friend search
/// (`GET /friends/{me}/search?q=`): only what a member card shows.
class FriendCandidate {
  const FriendCandidate({
    required this.userId,
    required this.name,
    this.username = '',
    this.city = '',
    this.photoUrl = '',
    this.relationship = 'none',
  });

  factory FriendCandidate.fromJson(Map<dynamic, dynamic> json) =>
      FriendCandidate(
        userId: json['user_id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        username: json['username']?.toString() ?? '',
        city: json['city']?.toString() ?? '',
        photoUrl: json['photo_url']?.toString() ?? '',
        relationship: json['relationship']?.toString() ?? 'none',
      );

  final String userId;
  final String name;
  final String username;
  final String city;
  final String photoUrl;

  /// none, friends, outgoing or incoming.
  final String relationship;
}

class FriendActivityItem {
  const FriendActivityItem({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.createdAt,
  });

  factory FriendActivityItem.fromJson(Map<String, dynamic> json) =>
      FriendActivityItem(
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

  List<FriendConnection> get accepted =>
      friends.where((f) => f.isAccepted).toList(growable: false);
  List<FriendConnection> get incoming =>
      friends.where((f) => f.isIncoming).toList(growable: false);
  List<FriendConnection> get outgoing =>
      friends.where((f) => f.isOutgoing).toList(growable: false);

  /// My connection with [userId], if any.
  FriendConnection? connectionWith(String userId) {
    for (final f in friends) {
      if (f.friendUserId == userId) {
        return f;
      }
    }
    return null;
  }

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
            direction: '',
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
    } on Object catch (e, stackTrace) {
      log.error('Failed to load friends', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load friends. Please try again.',
      );
    }
  }

  /// Sends a friend request from [source] and reloads. Throws on failure
  /// (the shared `sendFriendRequest` helper surfaces the error). Returns the
  /// resulting connection: pending, or accepted when they had already asked.
  Future<FriendConnection?> request(
    String friendUserId, {
    required FriendRequestSource source,
  }) async {
    final userId = _ref.read(authNotifierProvider).userId;
    if (userId == null || userId.trim().isEmpty) {
      throw StateError('Sign in to add friends.');
    }
    if (kUseMockAuth) {
      await load();
      return null;
    }
    final response = await _ref
        .read(apiClientProvider)
        .post<dynamic>(
          '/friends/$userId',
          data: {'friend_user_id': friendUserId, 'source': source.name},
        );
    await load();
    final data = response.data;
    final friend = data is Map ? data['friend'] : null;
    return friend is Map
        ? FriendConnection.fromJson(friend.cast<String, dynamic>())
        : null;
  }

  Future<void> addFriend(
    String friendUserId, {
    FriendRequestSource source = FriendRequestSource.search,
  }) async {
    state = state.copyWith(isMutating: true, clearError: true);
    try {
      await request(friendUserId, source: source);
      state = state.copyWith(isMutating: false);
    } on DioException catch (e, stackTrace) {
      log.error('Failed to add friend', e, stackTrace);
      state = state.copyWith(
        isMutating: false,
        error: _extractApiError(e, fallback: 'Failed to add friend.'),
      );
    } on Object catch (e, stackTrace) {
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
    } on Object catch (e, stackTrace) {
      log.error('Failed to remove friend', e, stackTrace);
      state = state.copyWith(
        isMutating: false,
        error: 'Failed to remove friend.',
      );
    }
  }

  Future<void> decideFriendRequest(
    String requesterUserId, {
    required bool accept,
  }) async {
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
        '/friends/$userId/$requesterUserId/decision',
        data: {'decision': accept ? 'accept' : 'decline'},
      );
      await load();
      state = state.copyWith(isMutating: false);
    } on DioException catch (e, stackTrace) {
      log.error('Failed to respond to friend request', e, stackTrace);
      state = state.copyWith(
        isMutating: false,
        error: _extractApiError(
          e,
          fallback: 'Failed to respond to friend request.',
        ),
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

/// `GET /friends/{me}/search?q=`: members to add as friends. Queries under
/// three letters return nothing without calling the server.
final friendSearchProvider = FutureProvider.autoDispose
    .family<List<FriendCandidate>, String>((ref, query) async {
      final q = query.trim();
      final me = ref.watch(authNotifierProvider.select((s) => s.userId));
      if (me == null || q.replaceFirst('@', '').length < 3) {
        return const <FriendCandidate>[];
      }
      final response = await ref
          .watch(apiClientProvider)
          .get<dynamic>('/friends/$me/search', queryParameters: {'q': q});
      final data = response.data;
      final results = data is Map ? data['results'] : null;
      return [
        for (final r in (results is List ? results : const []))
          if (r is Map) FriendCandidate.fromJson(r),
      ].where((c) => c.userId.isNotEmpty).toList(growable: false);
    });

/// `GET|PUT /friends/{me}/search-visibility`: the member's "Let people find
/// me in friend search" setting (default on). When it is off nobody finds
/// them in Add friend search; people who already see them (matches, rooms,
/// groups, profile) can still send a request.
class FriendSearchVisibilityNotifier extends AutoDisposeAsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final me = ref.watch(authNotifierProvider.select((s) => s.userId));
    if (me == null) {
      return true;
    }
    final response = await ref
        .watch(apiClientProvider)
        .get<dynamic>('/friends/$me/search-visibility');
    return _visible(response.data);
  }

  static bool _visible(Object? data) =>
      !(data is Map && data['visible'] == false);

  /// Saves the setting; the switch moves at once and returns if saving fails.
  Future<void> setVisible({required bool visible}) async {
    final me = ref.read(authNotifierProvider).userId;
    if (me == null) {
      return;
    }
    final previous = state;
    state = AsyncData(visible);
    try {
      final response = await ref
          .read(apiClientProvider)
          .put<dynamic>(
            '/friends/$me/search-visibility',
            data: {'visible': visible},
          );
      state = AsyncData(_visible(response.data));
    } on Object {
      state = previous;
      rethrow;
    }
  }
}

final friendSearchVisibilityProvider =
    AsyncNotifierProvider.autoDispose<FriendSearchVisibilityNotifier, bool>(
      FriendSearchVisibilityNotifier.new,
    );
