import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_error_message.dart';
import '../../core/widgets/connect_page.dart';
import '../../core/widgets/glass_widgets.dart';
import '../common/widgets/community_actions.dart';
import '../friends/friend_actions.dart';
import '../social_chat/social_chat_data.dart';
import '../social_chat/social_chat_screen.dart';
import 'friend_picker.dart';
import 'group_cover_picker.dart';
import 'group_widgets.dart';
import 'groups_data.dart';

/// One group: cover, what it is about, who is in it, its chat, and the
/// member's options (join, invite friends, leave; edit and moderate for the
/// owner).
class GroupDetailScreen extends ConsumerStatefulWidget {
  const GroupDetailScreen({required this.groupId, super.key});
  final String groupId;

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  bool busy = false;

  /// Cover upload progress (0–1); null when no upload is running.
  double? coverProgress;
  bool uploadingCover = false;

  String get id => widget.groupId;

  Future<void> run(
    Future<void> Function() action, {
    required String failure,
    String? success,
  }) async {
    if (busy) {
      return;
    }
    setState(() => busy = true);
    try {
      await action();
      invalidateGroups(ref, id);
      if (success != null && mounted) {
        showCommunitySnack(context, success);
      }
    } on Object catch (e) {
      if (mounted) {
        showCommunitySnack(context, apiErrorMessage(e, fallback: failure));
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  Future<void> openChat(Group group) async {
    await openSocialChat(
      context,
      channelId: group.channelId,
      title: group.name,
      subtitle: '${group.kindLabel} · ${group.memberLabel}',
      subtitleFor: (channel) =>
          '${group.kindLabel} · ${channel.memberCount} '
          '${channel.memberCount == 1 ? 'member' : 'members'}',
      emptyText:
          'Say hello to the group. Everyone in ${group.name} can see '
          'messages here.',
      header: group.description.isEmpty ? null : _ChatHeader(group: group),
      onSenderTap: (context, message) => showGroupSheet<void>(
        context,
        GroupSheetFrame(
          title: message.senderName.isEmpty ? 'Member' : message.senderName,
          children: [
            AddFriendButton(
              userId: message.senderId,
              name: message.senderName,
              source: FriendRequestSource.group,
              style: AddFriendStyle.tile,
            ),
          ],
        ),
      ),
    );
    ref
      ..invalidate(socialChannelsProvider)
      ..invalidate(myGroupsProvider);
  }

  Future<void> inviteFriends(Group group) async {
    final picked = await pickGroupFriends(
      context,
      groupId: group.id,
      title: 'Invite friends to ${group.name}',
      confirmLabel: 'Send invitations',
    );
    if (picked == null || picked.isEmpty || !mounted) {
      return;
    }
    await run(
      () => groupsApi(ref).invite(group.id, [for (final f in picked) f.userId]),
      failure: 'Invitations could not be sent.',
      success: picked.length == 1
          ? 'Invitation sent to ${picked.first.name}.'
          : '${picked.length} invitations sent.',
    );
  }

  Future<void> leave(Group group) async {
    final alone = group.myRole == 'owner' && group.memberCount <= 1;
    final ok = await confirmCommunityAction(
      context,
      title: 'Leave ${group.name}?',
      message: alone
          ? 'You are the only member, so the group and its chat will be '
                'deleted.'
          : group.myRole == 'owner'
          ? 'Ownership passes to your longest-standing moderator, or else '
                'member. You will lose access to the chat.'
          : group.isCommunity
          ? 'You will lose access to the group chat. You can join again '
                'later.'
          : 'You will lose access to the group chat. You will need a new '
                'invitation to come back.',
      action: 'Leave',
    );
    if (!ok || !mounted) {
      return;
    }
    setState(() => busy = true);
    try {
      await groupsApi(ref).leave(group.id);
      invalidateGroups(ref, id);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on Object catch (e) {
      if (mounted) {
        showCommunitySnack(
          context,
          apiErrorMessage(e, fallback: 'You could not leave just now.'),
        );
        setState(() => busy = false);
      }
    }
  }

  Future<void> changeCover(Group group) async {
    if (busy) {
      return;
    }
    final picked = await pickGroupCover(context, ref);
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      busy = true;
      uploadingCover = true;
      coverProgress = null;
    });
    try {
      final updated = await groupsApi(ref).uploadCover(
        group.id,
        bytes: picked.bytes,
        filename: picked.filename,
        onProgress: (p) {
          if (mounted) {
            setState(() => coverProgress = p);
          }
        },
      );
      invalidateGroups(ref, id);
      if (mounted) {
        showCommunitySnack(context, groupCoverUploadedMessage(updated));
      }
    } on Object catch (e) {
      if (mounted) {
        showCommunitySnack(
          context,
          apiErrorMessage(
            e,
            fallback:
                'Your cover photo could not be uploaded. Use a JPEG or PNG '
                'up to 10 MB.',
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
          uploadingCover = false;
          coverProgress = null;
        });
      }
    }
  }

  Future<void> removeCover(Group group) async {
    final ok = await confirmCommunityAction(
      context,
      title: 'Remove the cover photo?',
      message: '${group.name} will show its emoji cover again.',
      action: 'Remove',
    );
    if (!ok || !mounted) {
      return;
    }
    await run(
      () => groupsApi(ref).removeCover(group.id),
      failure: 'The cover photo could not be removed.',
      success: 'Cover photo removed.',
    );
  }

  Future<void> deleteGroup(Group group) async {
    final ok = await confirmCommunityAction(
      context,
      title: 'Delete ${group.name}?',
      message:
          'The group, its invitations and its chat are removed for everyone. '
          'This cannot be undone.',
      action: 'Delete group',
    );
    if (!ok || !mounted) {
      return;
    }
    setState(() => busy = true);
    try {
      await groupsApi(ref).delete(group.id);
      invalidateGroups(ref);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on Object catch (e) {
      if (mounted) {
        showCommunitySnack(
          context,
          apiErrorMessage(e, fallback: 'The group could not be deleted.'),
        );
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(groupDetailProvider(id));
    final group = detail.valueOrNull;
    return Scaffold(
      body: PostLoginBackdrop(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, box) {
              final gutter = ConnectMetrics.gutterFor(box.maxWidth);
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(groupDetailProvider(id));
                  await ref.read(groupDetailProvider(id).future);
                },
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(gutter, 12, gutter, 96),
                      children: [
                        ConnectPageHeader(
                          leading: const BackButton(),
                          eyebrow: group == null
                              ? 'GROUP'
                              : group.kindLabel.toUpperCase(),
                          title: group?.name ?? 'Group',
                          actions: [
                            if (group != null && group.canManage)
                              PopupMenuButton<String>(
                                tooltip: 'Owner tools',
                                enabled: !busy,
                                onSelected: (value) => switch (value) {
                                  'edit' => showGroupSheet<void>(
                                    context,
                                    _EditGroupSheet(group: group),
                                  ),
                                  'cover' => changeCover(group),
                                  'remove_cover' => removeCover(group),
                                  _ => deleteGroup(group),
                                },
                                itemBuilder: (_) => [
                                  // A removed group stays as reviewed until
                                  // the trust team restores it.
                                  if (!group.removed)
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Edit group'),
                                    ),
                                  if (group.canChangeCover)
                                    PopupMenuItem(
                                      value: 'cover',
                                      child: Text(
                                        group.coverPhotoStatus.isEmpty ||
                                                group.coverRejected
                                            ? 'Add cover photo'
                                            : 'Change cover photo',
                                      ),
                                    ),
                                  if (group.canChangeCover &&
                                      group.hasCoverPhoto)
                                    const PopupMenuItem(
                                      value: 'remove_cover',
                                      child: Text('Remove cover photo'),
                                    ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete group'),
                                  ),
                                ],
                              )
                            else if (group != null)
                              PopupMenuButton<String>(
                                key: const ValueKey('groups.detail.more'),
                                tooltip: 'More options',
                                enabled: !busy,
                                onSelected: (_) => reportCommunityItem(
                                  context,
                                  ref,
                                  kind: 'group',
                                  id: group.id,
                                ),
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'report',
                                    child: Text('Report group'),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (busy) const LinearProgressIndicator(),
                        detail.when(
                          skipLoadingOnRefresh: false,
                          loading: () => const Padding(
                            padding: EdgeInsets.all(48),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (e, _) => GroupNotice(
                            icon: Icons.cloud_off_outlined,
                            title: 'This group is unavailable',
                            message: apiErrorMessage(
                              e,
                              fallback:
                                  'It may have been deleted, or you may no '
                                  'longer have access.',
                            ),
                            actionLabel: 'Try again',
                            onAction: () =>
                                ref.invalidate(groupDetailProvider(id)),
                          ),
                          data: (group) => _GroupBody(
                            group: group,
                            busy: busy,
                            uploadingCover: uploadingCover,
                            coverProgress: coverProgress,
                            onChangeCover: () => changeCover(group),
                            onRemoveCover: () => removeCover(group),
                            onChat: () => openChat(group),
                            onInvite: () => inviteFriends(group),
                            onMembers: () => showGroupSheet<void>(
                              context,
                              GroupMembersSheet(group: group),
                            ),
                            onJoin: () => run(
                              () => groupsApi(ref).join(group.id),
                              failure: 'You could not join just now.',
                              success: 'Welcome to ${group.name}!',
                            ),
                            onRespond: ({required accept}) => run(
                              () => groupsApi(
                                ref,
                              ).respond(group.id, accept: accept),
                              failure: 'Your answer could not be saved.',
                              success: accept
                                  ? 'Welcome to ${group.name}!'
                                  : 'Invitation declined.',
                            ),
                            onLeave: () => leave(group),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.group});
  final Group group;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(12),
    child: ConnectPanel(
      padding: const EdgeInsets.all(ConnectMetrics.padding),
      child: Row(
        children: [
          GroupCoverThumb(group: group, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              group.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _GroupBody extends StatelessWidget {
  const _GroupBody({
    required this.group,
    required this.busy,
    required this.uploadingCover,
    required this.coverProgress,
    required this.onChangeCover,
    required this.onRemoveCover,
    required this.onChat,
    required this.onInvite,
    required this.onMembers,
    required this.onJoin,
    required this.onRespond,
    required this.onLeave,
  });
  final Group group;
  final bool busy, uploadingCover;
  final double? coverProgress;
  final VoidCallback onChangeCover, onRemoveCover;
  final VoidCallback onChat, onInvite, onMembers, onJoin, onLeave;
  final void Function({required bool accept}) onRespond;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    const tall = Size(48, 48);
    final pills = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (group.isCommunity && group.categoryTitle.isNotEmpty)
          GroupPill(
            label: '${group.categoryEmoji} ${group.categoryTitle}',
            emphasis: true,
          ),
        GroupPill(label: group.isCommunity ? 'Open to all' : 'Private'),
        GroupPill(label: group.memberLabel),
        if (group.city.isNotEmpty) GroupPill(label: group.city),
        if (group.isMember && group.myRole != 'member')
          GroupPill(
            label: group.myRole == 'owner' ? 'You run it' : 'You moderate',
          ),
      ],
    );
    final coverNote = group.coverUnderReview
        ? 'Only you can see this photo until it’s approved. Members see the '
              'emoji cover meanwhile.'
        : group.coverRejected && !group.hasCoverPhoto
        ? 'Your last cover photo wasn’t approved. Choose a different one.'
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConnectPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (group.hasCoverPhoto) ...[
                GroupCoverBanner(
                  key: const ValueKey('groups.detail.cover'),
                  group: group,
                  caption: '${group.emoji}  ${group.kindLabel}',
                  badge: group.coverUnderReview
                      ? const GroupCoverBadge(
                          key: ValueKey('groups.cover.review'),
                          label: 'Under review',
                          icon: Icons.hourglass_top_rounded,
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                pills,
              ] else
                Row(
                  children: [
                    GroupCover(
                      emoji: group.emoji,
                      color: group.coverColor,
                      size: 72,
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: pills),
                  ],
                ),
              if (group.canChangeCover) ...[
                if (coverNote != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    coverNote,
                    key: const ValueKey('groups.cover.note'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                if (uploadingCover)
                  GroupCoverProgress(progress: coverProgress)
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        key: const ValueKey('groups.cover.change'),
                        onPressed: busy ? null : onChangeCover,
                        style: OutlinedButton.styleFrom(minimumSize: tall),
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: Text(
                          group.hasCoverPhoto
                              ? 'Change cover'
                              : 'Add cover photo',
                        ),
                      ),
                      if (group.hasCoverPhoto)
                        TextButton.icon(
                          key: const ValueKey('groups.cover.remove'),
                          onPressed: busy ? null : onRemoveCover,
                          style: TextButton.styleFrom(minimumSize: tall),
                          icon: const Icon(Icons.hide_image_outlined),
                          label: const Text('Remove cover'),
                        ),
                    ],
                  ),
              ],
              if (group.description.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  group.description,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colors.onSurface,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: ConnectMetrics.cardGap),
        if (group.isMember && group.removed) ...[
          GroupNotice(
            key: const ValueKey('groups.detail.removed'),
            icon: Icons.gpp_maybe_outlined,
            title: 'This group was removed after a review',
            message: group.myRole == 'owner'
                ? 'Members can’t chat, join or invite while it is removed. '
                      'Your review notices explain the decision and let you '
                      'appeal.'
                : 'Members can’t chat, join or invite while it is removed. '
                      'You can leave the group at any time.',
          ),
          const SizedBox(height: ConnectMetrics.cardGap),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: busy ? null : onMembers,
                style: OutlinedButton.styleFrom(minimumSize: tall),
                icon: const Icon(Icons.groups_2_outlined),
                label: const Text('Members'),
              ),
              TextButton.icon(
                onPressed: busy ? null : onLeave,
                style: TextButton.styleFrom(minimumSize: tall),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Leave'),
              ),
            ],
          ),
        ] else if (group.isMember) ...[
          FilledButton.icon(
            onPressed: busy || group.channelId.isEmpty ? null : onChat,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            icon: const Icon(Icons.forum_outlined),
            label: Text(
              group.unreadCount > 0
                  ? 'Group chat · ${group.unreadCount} new'
                  : 'Group chat',
            ),
          ),
          const SizedBox(height: ConnectMetrics.cardGap),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (group.canInvite)
                OutlinedButton.icon(
                  onPressed: busy ? null : onInvite,
                  style: OutlinedButton.styleFrom(minimumSize: tall),
                  icon: const Icon(Icons.person_add_alt_rounded),
                  label: const Text('Invite friends'),
                ),
              OutlinedButton.icon(
                onPressed: busy ? null : onMembers,
                style: OutlinedButton.styleFrom(minimumSize: tall),
                icon: const Icon(Icons.groups_2_outlined),
                label: const Text('Members'),
              ),
              TextButton.icon(
                onPressed: busy ? null : onLeave,
                style: TextButton.styleFrom(minimumSize: tall),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Leave'),
              ),
            ],
          ),
          const SizedBox(height: ConnectMetrics.sectionGap),
          ConnectSectionHeader(
            label: 'WHO’S HERE',
            trailing: TextButton(
              onPressed: onMembers,
              style: TextButton.styleFrom(minimumSize: tall),
              child: const Text('See all'),
            ),
          ),
          const SizedBox(height: ConnectMetrics.cardGap),
          SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: group.members.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final m = group.members[i];
                return Semantics(
                  label:
                      '${m.isMe ? 'You' : m.name}, '
                      '${groupRoleLabels[m.role] ?? 'Member'}',
                  child: ExcludeSemantics(
                    child: SizedBox(
                      width: 64,
                      child: Column(
                        children: [
                          GroupAvatar(
                            name: m.name,
                            photoUrl: m.photoUrl,
                            radius: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            m.isMe ? 'You' : m.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colors.onSurface,
                            ),
                          ),
                          if (m.role != 'member')
                            Text(
                              groupRoleLabels[m.role] ?? '',
                              maxLines: 1,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colors.primary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ] else if (group.inviteId.isNotEmpty) ...[
          ConnectPanel(
            padding: const EdgeInsets.all(ConnectMetrics.padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'You’re invited to join ${group.name}.',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: busy ? null : () => onRespond(accept: false),
                        style: OutlinedButton.styleFrom(minimumSize: tall),
                        child: const Text('Decline'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: busy ? null : () => onRespond(accept: true),
                        style: FilledButton.styleFrom(minimumSize: tall),
                        child: const Text('Join group'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ] else if (group.canJoin) ...[
          FilledButton.icon(
            onPressed: busy ? null : onJoin,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            icon: const Icon(Icons.group_add_outlined),
            label: const Text('Join group'),
          ),
          const SizedBox(height: 8),
          Text(
            'Members see who’s here and chat together.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ] else
          GroupNotice(
            icon: Icons.lock_outline_rounded,
            title: group.isCommunity
                ? 'You can’t join this group'
                : 'Invitation only',
            message: group.isCommunity
                ? 'It may be full, or a moderator removed you.'
                : 'A member can invite you to this private group.',
          ),
      ],
    );
  }
}

/// Every member with their role. Anyone can add a member as a friend; the
/// owner promotes and demotes moderators and removes anyone; moderators
/// remove plain members.
class GroupMembersSheet extends ConsumerStatefulWidget {
  const GroupMembersSheet({required this.group, super.key});
  final Group group;

  @override
  ConsumerState<GroupMembersSheet> createState() => _GroupMembersSheetState();
}

class _GroupMembersSheetState extends ConsumerState<GroupMembersSheet> {
  bool busy = false;

  List<(String, String)> actionsFor(GroupMember member) {
    final mine = widget.group.myRole;
    if (member.isMe || member.role == 'owner') {
      return const [];
    }
    return [
      if (mine == 'owner' && member.role == 'member')
        ('make_moderator', 'Make moderator'),
      if (mine == 'owner' && member.role == 'moderator')
        ('make_member', 'Make member'),
      if (mine == 'owner' || (mine == 'moderator' && member.role == 'member'))
        ('remove', 'Remove from group'),
    ];
  }

  Future<void> act(GroupMember member, String action) async {
    if (action == 'remove' &&
        !await confirmCommunityAction(
          context,
          title: 'Remove ${member.name}?',
          message: widget.group.isCommunity
              ? 'They leave the group and its chat, and cannot rejoin by '
                    'themselves.'
              : 'They leave the group and its chat.',
          action: 'Remove',
        )) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() => busy = true);
    try {
      await groupsApi(ref).manage(widget.group.id, member.userId, action);
      invalidateGroups(ref, widget.group.id);
    } on Object catch (e) {
      if (mounted) {
        showCommunitySnack(
          context,
          apiErrorMessage(e, fallback: 'That change could not be saved.'),
        );
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GroupSheetFrame(
      title: 'Members',
      subtitle: widget.group.name,
      children: [
        if (busy) const LinearProgressIndicator(),
        ref
            .watch(groupMembersProvider(widget.group.id))
            .when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => GroupNotice(
                icon: Icons.cloud_off_outlined,
                title: 'Members could not load',
                message: apiErrorMessage(e, fallback: 'Please try again.'),
              ),
              data: (members) => Column(
                children: [
                  for (final member in members)
                    Builder(
                      builder: (context) {
                        final actions = actionsFor(member);
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          minTileHeight: 56,
                          leading: GroupAvatar(
                            name: member.name,
                            photoUrl: member.photoUrl,
                          ),
                          title: Text(
                            member.isMe ? '${member.name} (you)' : member.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            groupRoleLabels[member.role] ?? 'Member',
                            style: theme.textTheme.bodySmall,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!member.isMe)
                                AddFriendButton(
                                  userId: member.userId,
                                  name: member.name,
                                  source: FriendRequestSource.group,
                                  style: AddFriendStyle.icon,
                                ),
                              if (actions.isNotEmpty)
                                PopupMenuButton<String>(
                                  tooltip: 'Options for ${member.name}',
                                  enabled: !busy,
                                  onSelected: (action) => act(member, action),
                                  itemBuilder: (_) => [
                                    for (final (value, label) in actions)
                                      PopupMenuItem(
                                        value: value,
                                        child: Text(label),
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
      ],
    );
  }
}

/// The owner edits name, description, city, cover and (community groups)
/// the lifestyle category.
class _EditGroupSheet extends ConsumerStatefulWidget {
  const _EditGroupSheet({required this.group});
  final Group group;

  @override
  ConsumerState<_EditGroupSheet> createState() => _EditGroupSheetState();
}

class _EditGroupSheetState extends ConsumerState<_EditGroupSheet> {
  late final name = TextEditingController(text: widget.group.name);
  late final description = TextEditingController(
    text: widget.group.description,
  );
  late final city = TextEditingController(text: widget.group.city);
  late String category = widget.group.categorySlug;
  late String coverColor = widget.group.coverColor.isEmpty
      ? 'primary'
      : widget.group.coverColor;
  bool busy = false;
  String? error;

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    city.dispose();
    super.dispose();
  }

  Future<void> save() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await groupsApi(ref).update(widget.group.id, {
        'name': name.text.trim(),
        'description': description.text.trim(),
        'city': city.text.trim(),
        'cover_color': coverColor,
        if (widget.group.isCommunity) 'category_slug': category,
      });
      invalidateGroups(ref, widget.group.id);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on Object catch (e) {
      if (mounted) {
        setState(
          () => error = apiErrorMessage(
            e,
            fallback: 'Your changes could not be saved.',
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(groupCategoriesProvider).valueOrNull ?? [];
    return GroupSheetFrame(
      title: 'Edit group',
      footer: FilledButton(
        onPressed: busy ? null : save,
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        child: Text(busy ? 'Saving…' : 'Save changes'),
      ),
      children: [
        TextField(
          controller: name,
          maxLength: 60,
          decoration: const InputDecoration(labelText: 'Group name'),
        ),
        TextField(
          controller: description,
          maxLength: 500,
          minLines: 2,
          maxLines: 5,
          decoration: const InputDecoration(labelText: 'What is it about?'),
        ),
        TextField(
          controller: city,
          maxLength: 60,
          decoration: const InputDecoration(labelText: 'City (optional)'),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in groupCoverColors.entries)
              ChoiceChip(
                label: Text(entry.value),
                selected: coverColor == entry.key,
                onSelected: (_) => setState(() => coverColor = entry.key),
              ),
          ],
        ),
        if (widget.group.isCommunity && categories.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Lifestyle', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in categories)
                ChoiceChip(
                  label: Text('${c.emoji}  ${c.title}'),
                  selected: category == c.slug,
                  onSelected: (_) => setState(() => category = c.slug),
                ),
            ],
          ),
        ],
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    );
  }
}
