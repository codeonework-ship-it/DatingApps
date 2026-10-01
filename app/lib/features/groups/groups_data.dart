import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../core/providers/api_client_provider.dart';
import '../auth/providers/auth_provider.dart';

/// Lifestyle community groups and private friend groups
/// (`/v1/engagement/groups...`, migration 118). Every action is taken as the
/// signed-in member; the server decides who may see, join, invite and manage.

int _int(Object? v) => v is num ? v.toInt() : 0;

String _str(Object? v) => v is String ? v : '';

DateTime? _time(Object? v) =>
    v is String && v.isNotEmpty ? DateTime.tryParse(v)?.toLocal() : null;

List<Map<dynamic, dynamic>> _maps(Object? v) => [
  for (final item in (v is List ? v : const []))
    if (item is Map) item,
];

/// A lifestyle category, e.g. "🏃 Fitness & running".
class GroupCategory {
  const GroupCategory({
    required this.slug,
    required this.title,
    required this.emoji,
    this.description = '',
    this.groupCount = 0,
  });

  factory GroupCategory.fromJson(Map<dynamic, dynamic> json) => GroupCategory(
    slug: _str(json['slug']),
    title: _str(json['title']),
    emoji: _str(json['emoji']),
    description: _str(json['description']),
    groupCount: _int(json['group_count']),
  );

  final String slug, title, emoji, description;
  final int groupCount;
}

/// One member as shown in a group.
class GroupMember {
  const GroupMember({
    required this.userId,
    required this.name,
    this.photoUrl = '',
    this.role = 'member',
    this.isMe = false,
    this.isFriend = false,
  });

  factory GroupMember.fromJson(Map<dynamic, dynamic> json) => GroupMember(
    userId: _str(json['user_id']),
    name: _str(json['name']),
    photoUrl: _str(json['photo_url']),
    role: _str(json['role']).isEmpty ? 'member' : _str(json['role']),
    isMe: json['is_me'] == true,
    isFriend: json['is_friend'] == true,
  );

  final String userId, name, photoUrl;

  /// owner, moderator or member.
  final String role;
  final bool isMe, isFriend;
}

const groupRoleLabels = <String, String>{
  'owner': 'Owner',
  'moderator': 'Moderator',
  'member': 'Member',
};

class Group {
  const Group({
    required this.id,
    required this.kind,
    required this.name,
    this.categorySlug = '',
    this.categoryTitle = '',
    this.categoryEmoji = '',
    this.description = '',
    this.city = '',
    this.coverEmoji = '',
    this.coverColor = '',
    this.memberCount = 0,
    this.memberCap = 0,
    this.myRole = '',
    this.inviteId = '',
    this.channelId = '',
    this.unreadCount = 0,
    this.canInvite = false,
    this.canManage = false,
    this.canJoin = false,
    this.removed = false,
    this.coverPhotoUrl = '',
    this.coverPhotoId = '',
    this.coverPhotoStatus = '',
    this.members = const [],
    this.updatedAt,
  });

  factory Group.fromJson(Map<dynamic, dynamic> json) => Group(
    id: _str(json['id']),
    kind: _str(json['kind']).isEmpty ? 'private' : _str(json['kind']),
    name: _str(json['name']),
    categorySlug: _str(json['category_slug']),
    categoryTitle: _str(json['category_title']),
    categoryEmoji: _str(json['category_emoji']),
    description: _str(json['description']),
    city: _str(json['city']),
    coverEmoji: _str(json['cover_emoji']),
    coverColor: _str(json['cover_color']),
    memberCount: _int(json['member_count']),
    memberCap: _int(json['member_cap']),
    myRole: _str(json['my_role']),
    inviteId: _str(json['invite_id']),
    channelId: _str(json['channel_id']),
    unreadCount: _int(json['unread_count']),
    canInvite: json['can_invite'] == true,
    canManage: json['can_manage'] == true,
    canJoin: json['can_join'] == true,
    removed:
        json['removed'] == true || _str(json['moderation_state']) == 'removed',
    coverPhotoUrl: _str(json['cover_photo_url']),
    coverPhotoId: _str(json['cover_photo_id']),
    coverPhotoStatus: _str(json['cover_photo_status']),
    members: [
      for (final m in _maps(json['members_preview'])) GroupMember.fromJson(m),
    ],
    updatedAt: _time(json['updated_at']),
  );

  final String id;

  /// `community` (public, by lifestyle) or `private` (a friends group).
  final String kind;
  final String name, categorySlug, categoryTitle, categoryEmoji;
  final String description, city, coverEmoji;

  /// A theme role: primary, secondary or tertiary ('' for the default).
  final String coverColor;
  final int memberCount, memberCap;

  /// owner, moderator, member, or '' when not a member.
  final String myRole;

  /// The signed-in member's pending invitation, if any.
  final String inviteId;

  /// The group chat (members only).
  final String channelId;
  final int unreadCount;
  final bool canInvite, canManage, canJoin;

  /// Removed after a review (a report upheld by the trust team). Members
  /// still see it, but nobody can join, invite or chat until it is restored.
  final bool removed;

  /// The cover photo's API path and id, set only when this member may see
  /// it (approved, or pending for the owner). Empty: show the emoji cover.
  final String coverPhotoUrl, coverPhotoId;

  /// Owner only: `pending` (under review), `approved`, or `rejected` (the
  /// last photo was not approved); '' without a photo.
  final String coverPhotoStatus;

  /// Up to eight members (members only).
  final List<GroupMember> members;
  final DateTime? updatedAt;

  bool get isCommunity => kind == 'community';
  bool get isMember => myRole.isNotEmpty;
  bool get canModerate => myRole == 'owner' || myRole == 'moderator';

  /// A cover photo this member may see.
  bool get hasCoverPhoto => coverPhotoId.isNotEmpty;

  /// The owner's photo is waiting for a review (only they can see it).
  bool get coverUnderReview => coverPhotoStatus == 'pending';

  /// The owner's last photo was not approved.
  bool get coverRejected => coverPhotoStatus == 'rejected';

  /// The owner may add, change or remove the cover photo.
  bool get canChangeCover => myRole == 'owner' && !removed;

  /// The emoji on the cover: the member's choice, else the category's.
  String get emoji => coverEmoji.isNotEmpty
      ? coverEmoji
      : categoryEmoji.isNotEmpty
      ? categoryEmoji
      : (isCommunity ? '✨' : '🫶');

  String get kindLabel => isCommunity ? 'Community group' : 'Private group';

  String get memberLabel => '$memberCount member${memberCount == 1 ? '' : 's'}';
}

class GroupInvite {
  const GroupInvite({
    required this.id,
    required this.group,
    this.inviterId = '',
    this.inviterName = '',
    this.inviterPhotoUrl = '',
  });

  factory GroupInvite.fromJson(Map<dynamic, dynamic> json) => GroupInvite(
    id: _str(json['id']),
    group: Group.fromJson(json['group'] is Map ? json['group'] as Map : {}),
    inviterId: _str(json['inviter_user_id']),
    inviterName: _str(json['inviter_name']),
    inviterPhotoUrl: _str(json['inviter_photo_url']),
  );

  final String id;
  final Group group;
  final String inviterId, inviterName, inviterPhotoUrl;
}

/// A friend in the invite picker.
class GroupFriend {
  const GroupFriend({
    required this.userId,
    required this.name,
    this.photoUrl = '',
    this.status = 'available',
  });

  factory GroupFriend.fromJson(Map<dynamic, dynamic> json) => GroupFriend(
    userId: _str(json['user_id']),
    name: _str(json['name']),
    photoUrl: _str(json['photo_url']),
    status: _str(json['status']).isEmpty ? 'available' : _str(json['status']),
  );

  final String userId, name, photoUrl;

  /// available, member or invited.
  final String status;

  bool get available => status == 'available';
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

void _watchSession(Ref ref) =>
    ref.watch(authNotifierProvider.select((s) => s.userId));

final groupCategoriesProvider = FutureProvider.autoDispose<List<GroupCategory>>(
  (ref) async {
    _watchSession(ref);
    final response = await ref
        .watch(apiClientProvider)
        .get<dynamic>('/engagement/group-categories');
    return [
      for (final c in _maps((response.data as Map)['categories']))
        GroupCategory.fromJson(c),
    ];
  },
);

Future<List<Group>> _groups(Dio api, Map<String, String> query) async {
  final response = await api.get<dynamic>(
    '/engagement/groups',
    queryParameters: query,
  );
  return [
    for (final g in _maps((response.data as Map)['groups'])) Group.fromJson(g),
  ];
}

/// The member's groups, most recently active first.
final myGroupsProvider = FutureProvider.autoDispose<List<Group>>((ref) async {
  _watchSession(ref);
  return _groups(ref.watch(apiClientProvider), const {'scope': 'mine'});
});

/// Community groups to discover; '' for every category.
final discoverGroupsProvider = FutureProvider.autoDispose
    .family<List<Group>, String>((ref, category) async {
      _watchSession(ref);
      return _groups(ref.watch(apiClientProvider), {
        'scope': 'discover',
        if (category.isNotEmpty) 'category': category,
      });
    });

final groupInvitesProvider = FutureProvider.autoDispose<List<GroupInvite>>((
  ref,
) async {
  _watchSession(ref);
  final response = await ref
      .watch(apiClientProvider)
      .get<dynamic>('/engagement/group-invites');
  return [
    for (final i in _maps((response.data as Map)['invites']))
      GroupInvite.fromJson(i),
  ];
});

final groupDetailProvider = FutureProvider.autoDispose.family<Group, String>((
  ref,
  id,
) async {
  _watchSession(ref);
  final response = await ref
      .watch(apiClientProvider)
      .get<dynamic>('/engagement/groups/$id');
  return Group.fromJson((response.data as Map)['group'] as Map);
});

final groupMembersProvider = FutureProvider.autoDispose
    .family<List<GroupMember>, String>((ref, id) async {
      _watchSession(ref);
      final response = await ref
          .watch(apiClientProvider)
          .get<dynamic>('/engagement/groups/$id/members');
      return [
        for (final m in _maps((response.data as Map)['members']))
          GroupMember.fromJson(m),
      ];
    });

/// Accepted, unblocked friends; with a group id, each friend's standing in it.
final groupFriendsProvider = FutureProvider.autoDispose
    .family<List<GroupFriend>, String>((ref, groupId) async {
      _watchSession(ref);
      final response = await ref
          .watch(apiClientProvider)
          .get<dynamic>(
            '/engagement/group-friends',
            queryParameters: {if (groupId.isNotEmpty) 'group_id': groupId},
          );
      return [
        for (final f in _maps((response.data as Map)['friends']))
          GroupFriend.fromJson(f),
      ];
    });

/// Identifies one cover photo: a new photo has a new id, so its bytes can
/// be cached by key.
typedef GroupCoverKey = ({String user, String group, String cover});

/// A group's cover photo bytes, loaded through the authenticated API (like
/// theme photos). Kept for a few minutes so lists don't refetch on scroll.
final groupCoverPhotoProvider = FutureProvider.autoDispose
    .family<Uint8List, GroupCoverKey>((ref, key) async {
      final user = ref.watch(authNotifierProvider.select((s) => s.userId));
      if (user == null || user != key.user) {
        throw StateError('Sign in to view this photo.');
      }
      final response = await ref
          .watch(apiClientProvider)
          .get<List<int>>(
            '/engagement/groups/${key.group}/cover',
            queryParameters: {'v': key.cover},
            options: Options(responseType: ResponseType.bytes),
          );
      final link = ref.keepAlive();
      final timer = Timer(const Duration(minutes: 5), link.close);
      ref.onDispose(timer.cancel);
      return Uint8List.fromList(response.data!);
    });

/// Picks a cover photo from the gallery or camera. Overridden in tests.
final groupCoverPickerProvider =
    Provider<Future<XFile?> Function(ImageSource source)>(
      (ref) =>
          (source) => ImagePicker().pickImage(
            source: source,
            maxWidth: 2048,
            maxHeight: 2048,
            imageQuality: 88,
          ),
    );

/// The largest cover photo the server accepts.
const groupCoverMaxBytes = 10 * 1024 * 1024;

// ---------------------------------------------------------------------------
// Actions
// ---------------------------------------------------------------------------

/// Refreshes every list a membership change can affect.
void invalidateGroups(WidgetRef ref, [String groupId = '']) {
  ref
    ..invalidate(myGroupsProvider)
    ..invalidate(discoverGroupsProvider)
    ..invalidate(groupInvitesProvider)
    ..invalidate(groupCategoriesProvider);
  if (groupId.isNotEmpty) {
    ref
      ..invalidate(groupDetailProvider(groupId))
      ..invalidate(groupMembersProvider(groupId))
      ..invalidate(groupFriendsProvider(groupId));
  }
}

class GroupsApi {
  GroupsApi(this.api);
  final Dio api;

  Group _group(Response<dynamic> r) =>
      Group.fromJson((r.data as Map)['group'] as Map);

  Future<Group> create({
    required String kind,
    required String name,
    String categorySlug = '',
    String description = '',
    String city = '',
    String coverEmoji = '',
    String coverColor = '',
    List<String> inviteeIds = const [],
    String? groupId,
  }) async => _group(
    await api.post<dynamic>(
      '/engagement/groups',
      data: {
        'group_id': groupId ?? const Uuid().v4(),
        'kind': kind,
        'name': name,
        if (categorySlug.isNotEmpty) 'category_slug': categorySlug,
        'description': description,
        'city': city,
        if (coverEmoji.isNotEmpty) 'cover_emoji': coverEmoji,
        if (coverColor.isNotEmpty) 'cover_color': coverColor,
        'invitee_user_ids': inviteeIds,
      },
    ),
  );

  Future<Group> update(String id, Map<String, Object?> changes) async =>
      _group(await api.patch<dynamic>('/engagement/groups/$id', data: changes));

  Future<void> delete(String id) =>
      api.delete<dynamic>('/engagement/groups/$id');

  Future<Group> join(String id) async =>
      _group(await api.post<dynamic>('/engagement/groups/$id/join'));

  /// Returns true when the group was deleted (the owner was alone).
  Future<bool> leave(String id) async {
    final r = await api.post<dynamic>('/engagement/groups/$id/leave');
    return (r.data as Map)['deleted'] == true;
  }

  Future<Group> respond(String id, {required bool accept}) async => _group(
    await api.post<dynamic>(
      '/engagement/groups/$id/invites/respond',
      data: {'decision': accept ? 'accept' : 'decline'},
    ),
  );

  Future<int> invite(String id, List<String> userIds) async {
    final r = await api.post<dynamic>(
      '/engagement/groups/$id/invites',
      data: {'invitee_user_ids': userIds},
    );
    final invited = (r.data as Map)['invited_user_ids'];
    return invited is List ? invited.length : 0;
  }

  /// Uploads (or replaces) the cover photo. [coverId] makes a retry return
  /// the saved result; [onProgress] reports 0–1 while the bytes are sent.
  Future<Group> uploadCover(
    String id, {
    required List<int> bytes,
    required String filename,
    String? coverId,
    void Function(double progress)? onProgress,
  }) async => _group(
    await api.put<dynamic>(
      '/engagement/groups/$id/cover',
      data: FormData.fromMap({
        'cover_id': coverId ?? const Uuid().v4(),
        'image': MultipartFile.fromBytes(bytes, filename: filename),
      }),
      onSendProgress: onProgress == null
          ? null
          : (sent, total) {
              if (total > 0) {
                onProgress((sent / total).clamp(0, 1).toDouble());
              }
            },
    ),
  );

  /// Removes the cover photo; the group falls back to its emoji.
  Future<Group> removeCover(String id) async =>
      _group(await api.delete<dynamic>('/engagement/groups/$id/cover'));

  Future<void> manage(String id, String userId, String action) =>
      api.post<dynamic>(
        '/engagement/groups/$id/members/$userId',
        data: {'action': action},
      );
}

GroupsApi groupsApi(WidgetRef ref) => GroupsApi(ref.read(apiClientProvider));
