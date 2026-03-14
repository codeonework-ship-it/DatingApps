import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../core/utils/logger.dart';
import '../../auth/providers/auth_provider.dart';

class CommunityGroup {
  const CommunityGroup({
    required this.id,
    required this.name,
    required this.city,
    required this.topic,
    required this.description,
    required this.visibility,
    required this.memberCount,
    required this.isMember,
    required this.memberRole,
  });

  factory CommunityGroup.fromJson(Map<String, dynamic> json) => CommunityGroup(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    city: json['city']?.toString() ?? '',
    topic: json['topic']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
    visibility: json['visibility']?.toString() ?? 'private',
    memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
    isMember: json['is_member'] == true,
    memberRole: json['member_role']?.toString() ?? '',
  );

  final String id;
  final String name;
  final String city;
  final String topic;
  final String description;
  final String visibility;
  final int memberCount;
  final bool isMember;
  final String memberRole;
}

class CommunityGroupInvite {
  const CommunityGroupInvite({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.groupCity,
    required this.groupTopic,
    required this.inviterUserId,
    required this.status,
  });

  factory CommunityGroupInvite.fromJson(Map<String, dynamic> json) =>
      CommunityGroupInvite(
        id: json['id']?.toString() ?? '',
        groupId: json['group_id']?.toString() ?? '',
        groupName: json['group_name']?.toString() ?? '',
        groupCity: json['group_city']?.toString() ?? '',
        groupTopic: json['group_topic']?.toString() ?? '',
        inviterUserId: json['inviter_user_id']?.toString() ?? '',
        status: json['status']?.toString() ?? 'pending',
      );

  final String id;
  final String groupId;
  final String groupName;
  final String groupCity;
  final String groupTopic;
  final String inviterUserId;
  final String status;
}

class CommunityGroupsState {
  const CommunityGroupsState({
    this.isLoading = false,
    this.isMutating = false,
    this.error,
    this.groups = const <CommunityGroup>[],
    this.invites = const <CommunityGroupInvite>[],
  });

  final bool isLoading;
  final bool isMutating;
  final String? error;
  final List<CommunityGroup> groups;
  final List<CommunityGroupInvite> invites;

  CommunityGroupsState copyWith({
    bool? isLoading,
    bool? isMutating,
    String? error,
    bool clearError = false,
    List<CommunityGroup>? groups,
    List<CommunityGroupInvite>? invites,
  }) => CommunityGroupsState(
    isLoading: isLoading ?? this.isLoading,
    isMutating: isMutating ?? this.isMutating,
    error: clearError ? null : (error ?? this.error),
    groups: groups ?? this.groups,
    invites: invites ?? this.invites,
  );
}

class CommunityGroupsNotifier extends StateNotifier<CommunityGroupsState> {
  CommunityGroupsNotifier(this._ref) : super(const CommunityGroupsState()) {
    Future<void>.microtask(load);
  }

  final Ref _ref;

  Future<void> load() async {
    final userId = _currentUserId();
    if (userId == null) {
      state = state.copyWith(error: 'User session not available.');
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    if (kUseMockAuth) {
      state = state.copyWith(
        isLoading: false,
        groups: const <CommunityGroup>[
          CommunityGroup(
            id: 'community-group-1',
            name: 'Bengaluru Weekend Explorers',
            city: 'Bengaluru',
            topic: 'City Hangouts',
            description: 'Plan low-key weekend city meetups.',
            visibility: 'public',
            memberCount: 6,
            isMember: true,
            memberRole: 'owner',
          ),
        ],
        invites: const <CommunityGroupInvite>[
          CommunityGroupInvite(
            id: 'community-group-invite-1',
            groupId: 'community-group-2',
            groupName: 'Anime Fanclub',
            groupCity: 'Bengaluru',
            groupTopic: 'Fanclub',
            inviterUserId: 'mock-user-002',
            status: 'pending',
          ),
        ],
      );
      return;
    }

    try {
      final dio = _ref.read(apiClientProvider);
      final groupsResponse = await dio.get<Map<String, dynamic>>(
        '/engagement/groups',
        queryParameters: <String, dynamic>{'user_id': userId, 'limit': 50},
      );
      final invitesResponse = await dio.get<Map<String, dynamic>>(
        '/engagement/group-invites',
        queryParameters: <String, dynamic>{
          'user_id': userId,
          'status': 'pending',
          'limit': 50,
        },
      );

      final groupsBody =
          (groupsResponse.data as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      final invitesBody =
          (invitesResponse.data as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      final groupsRaw = (groupsBody['groups'] as List?) ?? const [];
      final invitesRaw = (invitesBody['invites'] as List?) ?? const [];

      final groups = groupsRaw
          .whereType<Map<String, dynamic>>()
          .map(CommunityGroup.fromJson)
          .where((item) => item.id.isNotEmpty)
          .toList(growable: false);
      final invites = invitesRaw
          .whereType<Map<String, dynamic>>()
          .map(CommunityGroupInvite.fromJson)
          .where((item) => item.id.isNotEmpty)
          .toList(growable: false);

      state = state.copyWith(
        isLoading: false,
        groups: groups,
        invites: invites,
      );
    } on DioException catch (e, stackTrace) {
      log.error('Failed to load community groups', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: _extractApiError(
          e,
          fallback: 'Failed to load community groups. Please try again.',
        ),
      );
    } catch (e, stackTrace) {
      log.error('Failed to load community groups', e, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load community groups. Please try again.',
      );
    }
  }

  Future<void> createGroup({
    required String name,
    required String city,
    required String topic,
    required String description,
    required String visibility,
    required List<String> inviteeUserIds,
  }) async {
    final userId = _currentUserId();
    if (userId == null) {
      state = state.copyWith(error: 'User session not available.');
      return;
    }

    state = state.copyWith(isMutating: true, clearError: true);

    try {
      final dio = _ref.read(apiClientProvider);
      await dio.post<Map<String, dynamic>>(
        '/engagement/groups',
        data: <String, dynamic>{
          'owner_user_id': userId,
          'name': name.trim(),
          'city': city.trim(),
          'topic': topic.trim(),
          'description': description.trim(),
          'visibility': visibility.trim().isEmpty ? 'private' : visibility,
          'invitee_user_ids': inviteeUserIds,
        },
      );
      state = state.copyWith(isMutating: false);
      await load();
    } on DioException catch (e, stackTrace) {
      log.error('Failed to create community group', e, stackTrace);
      state = state.copyWith(
        isMutating: false,
        error: _extractApiError(
          e,
          fallback: 'Failed to create group. Please try again.',
        ),
      );
    } catch (e, stackTrace) {
      log.error('Failed to create community group', e, stackTrace);
      state = state.copyWith(
        isMutating: false,
        error: 'Failed to create group. Please try again.',
      );
    }
  }

  Future<void> respondInvite({
    required String groupId,
    required bool accept,
  }) async {
    final userId = _currentUserId();
    if (userId == null) {
      state = state.copyWith(error: 'User session not available.');
      return;
    }

    state = state.copyWith(isMutating: true, clearError: true);

    try {
      final dio = _ref.read(apiClientProvider);
      await dio.post<Map<String, dynamic>>(
        '/engagement/groups/$groupId/invites/respond',
        data: <String, dynamic>{
          'user_id': userId,
          'decision': accept ? 'accept' : 'decline',
        },
      );
      state = state.copyWith(isMutating: false);
      await load();
    } on DioException catch (e, stackTrace) {
      log.error('Failed to respond to group invite', e, stackTrace);
      state = state.copyWith(
        isMutating: false,
        error: _extractApiError(
          e,
          fallback: 'Failed to respond to invite. Please try again.',
        ),
      );
    } catch (e, stackTrace) {
      log.error('Failed to respond to group invite', e, stackTrace);
      state = state.copyWith(
        isMutating: false,
        error: 'Failed to respond to invite. Please try again.',
      );
    }
  }

  String? _currentUserId() {
    final userId = _ref.read(authNotifierProvider).userId?.trim() ?? '';
    if (userId.isEmpty) {
      return null;
    }
    return userId;
  }
}

final communityGroupsProvider =
    StateNotifierProvider<CommunityGroupsNotifier, CommunityGroupsState>(
      CommunityGroupsNotifier.new,
    );

String _extractApiError(DioException e, {required String fallback}) {
  final data = e.response?.data;
  if (data is Map && data['error'] != null) {
    return data['error'].toString();
  }
  return fallback;
}
