import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_error_message.dart';
import '../../core/widgets/connect_page.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    final kind = group.kindLabel(l10n);
    await openSocialChat(
      context,
      channelId: group.channelId,
      title: group.name,
      subtitle: '$kind · ${group.memberLabel(l10n)}',
      subtitleFor: (channel) =>
          '$kind · ${l10n.chatMemberCount(channel.memberCount)}',
      emptyText: l10n.groupsChatEmpty(group.name),
      header: group.description.isEmpty ? null : _ChatHeader(group: group),
      onSenderTap: (context, message) => showGroupSheet<void>(
        context,
        GroupSheetFrame(
          title: message.senderName.isEmpty
              ? AppLocalizations.of(context).chatMember
              : message.senderName,
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
    final l10n = AppLocalizations.of(context);
    final picked = await pickGroupFriends(
      context,
      groupId: group.id,
      title: l10n.groupsInviteFriendsTo(group.name),
      confirmLabel: l10n.groupsSendInvitations,
    );
    if (picked == null || picked.isEmpty || !mounted) {
      return;
    }
    await run(
      () => groupsApi(ref).invite(group.id, [for (final f in picked) f.userId]),
      failure: l10n.groupsInvitationsFailed,
      success: picked.length == 1
          ? l10n.groupsInvitationSentTo(picked.first.name)
          : l10n.groupsInvitationsSent(picked.length),
    );
  }

  Future<void> leave(Group shown) async {
    // People join and leave while this screen is open, and the warning
    // differs in kind ("the group will be deleted" vs "ownership passes"),
    // so decide it on the group as it is now, not as it was loaded.
    var group = shown;
    try {
      group = await ref.refresh(groupDetailProvider(id).future);
    } on Object {
      // Offline: fall back to what is on screen.
    }
    if (!mounted) {
      return;
    }
    final alone = group.myRole == 'owner' && group.memberCount <= 1;
    final l10n = AppLocalizations.of(context);
    final ok = await confirmCommunityAction(
      context,
      title: l10n.groupsLeaveTitle(group.name),
      message: alone
          ? l10n.groupsLeaveBodyAlone
          : group.myRole == 'owner'
          ? l10n.groupsLeaveBodyOwner
          : group.isCommunity
          ? l10n.groupsLeaveBodyCommunity
          : l10n.groupsLeaveBodyPrivate,
      action: l10n.groupsLeave,
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
          apiErrorMessage(e, fallback: l10n.groupsLeaveFailed),
        );
        setState(() => busy = false);
      }
    }
  }

  Future<void> changeCover(Group group) async {
    if (busy) {
      return;
    }
    final l10n = AppLocalizations.of(context);
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
        showCommunitySnack(context, groupCoverUploadedMessage(l10n, updated));
      }
    } on Object catch (e) {
      if (mounted) {
        showCommunitySnack(
          context,
          apiErrorMessage(e, fallback: l10n.groupsCoverUploadFailed),
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
    final l10n = AppLocalizations.of(context);
    final ok = await confirmCommunityAction(
      context,
      title: l10n.groupsRemoveCoverTitle,
      message: l10n.groupsRemoveCoverBody(group.name),
      action: l10n.groupsRemove,
    );
    if (!ok || !mounted) {
      return;
    }
    await run(
      () => groupsApi(ref).removeCover(group.id),
      failure: l10n.groupsRemoveCoverFailed,
      success: l10n.groupsCoverRemoved,
    );
  }

  Future<void> deleteGroup(Group group) async {
    final l10n = AppLocalizations.of(context);
    final ok = await confirmCommunityAction(
      context,
      title: l10n.groupsDeleteTitle(group.name),
      message: l10n.groupsDeleteBody,
      action: l10n.groupsDeleteGroup,
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
          apiErrorMessage(e, fallback: l10n.groupsDeleteFailed),
        );
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                  try {
                    await ref.read(groupDetailProvider(id).future);
                  } on Object {
                    // The page shows what went wrong, with Try again.
                  }
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
                              ? l10n.groupsDetailEyebrow
                              : group.kindLabel(l10n).toUpperCase(),
                          title: group?.name ?? l10n.groupsDetailTitleFallback,
                          actions: [
                            if (group != null && group.canManage)
                              PopupMenuButton<String>(
                                tooltip: l10n.groupsOwnerTools,
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
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text(l10n.groupsEditGroup),
                                    ),
                                  if (group.canChangeCover)
                                    PopupMenuItem(
                                      value: 'cover',
                                      child: Text(
                                        group.coverPhotoStatus.isEmpty ||
                                                group.coverRejected
                                            ? l10n.groupsAddCoverPhoto
                                            : l10n.groupsChangeCoverPhoto,
                                      ),
                                    ),
                                  if (group.canChangeCover &&
                                      group.hasCoverPhoto)
                                    PopupMenuItem(
                                      value: 'remove_cover',
                                      child: Text(l10n.groupsRemoveCoverPhoto),
                                    ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text(l10n.groupsDeleteGroup),
                                  ),
                                ],
                              )
                            else if (group != null)
                              PopupMenuButton<String>(
                                key: const ValueKey('groups.detail.more'),
                                tooltip: l10n.groupsMoreOptions,
                                enabled: !busy,
                                onSelected: (_) => reportCommunityItem(
                                  context,
                                  ref,
                                  kind: 'group',
                                  id: group.id,
                                ),
                                itemBuilder: (_) => [
                                  PopupMenuItem(
                                    value: 'report',
                                    child: Text(l10n.groupsReportGroup),
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
                            title: l10n.groupsUnavailableTitle,
                            message: apiErrorMessage(
                              e,
                              fallback: l10n.groupsUnavailableBody,
                            ),
                            actionLabel: l10n.chatTryAgain,
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
                              failure: l10n.groupsJoinFailed,
                              success: l10n.groupsWelcome(group.name),
                            ),
                            onRespond: ({required accept}) => run(
                              () => groupsApi(
                                ref,
                              ).respond(group.id, accept: accept),
                              failure: l10n.groupsAnswerFailed,
                              success: accept
                                  ? l10n.groupsWelcome(group.name)
                                  : l10n.groupsInvitationDeclined,
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
    final l10n = AppLocalizations.of(context);
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
        GroupPill(
          label: group.isCommunity ? l10n.groupsOpenToAll : l10n.groupsPrivate,
        ),
        GroupPill(label: group.memberLabel(l10n)),
        if (group.city.isNotEmpty) GroupPill(label: group.city),
        if (group.isMember && group.myRole != 'member')
          GroupPill(
            label: group.myRole == 'owner'
                ? l10n.groupsYouRunIt
                : l10n.groupsYouModerate,
          ),
      ],
    );
    final coverNote = group.coverUnderReview
        ? l10n.groupsCoverNotePending
        : group.coverRejected && !group.hasCoverPhoto
        ? l10n.groupsCoverNoteRejected
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
                  caption: '${group.emoji}  ${group.kindLabel(l10n)}',
                  badge: group.coverUnderReview
                      ? GroupCoverBadge(
                          key: const ValueKey('groups.cover.review'),
                          label: l10n.groupsCoverUnderReview,
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
                              ? l10n.groupsChangeCover
                              : l10n.groupsAddCoverPhoto,
                        ),
                      ),
                      if (group.hasCoverPhoto)
                        TextButton.icon(
                          key: const ValueKey('groups.cover.remove'),
                          onPressed: busy ? null : onRemoveCover,
                          style: TextButton.styleFrom(minimumSize: tall),
                          icon: const Icon(Icons.hide_image_outlined),
                          label: Text(l10n.groupsRemoveCover),
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
            title: l10n.groupsRemovedTitle,
            message: group.myRole == 'owner'
                ? l10n.groupsRemovedBodyOwner
                : l10n.groupsRemovedBodyMember,
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
                label: Text(l10n.groupsMembers),
              ),
              TextButton.icon(
                onPressed: busy ? null : onLeave,
                style: TextButton.styleFrom(minimumSize: tall),
                icon: const Icon(Icons.logout_rounded),
                label: Text(l10n.groupsLeave),
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
                  ? l10n.groupsChatButtonUnread(group.unreadCount)
                  : l10n.groupsChatButton,
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
                  label: Text(l10n.groupsInviteFriends),
                ),
              OutlinedButton.icon(
                onPressed: busy ? null : onMembers,
                style: OutlinedButton.styleFrom(minimumSize: tall),
                icon: const Icon(Icons.groups_2_outlined),
                label: Text(l10n.groupsMembers),
              ),
              TextButton.icon(
                onPressed: busy ? null : onLeave,
                style: TextButton.styleFrom(minimumSize: tall),
                icon: const Icon(Icons.logout_rounded),
                label: Text(l10n.groupsLeave),
              ),
            ],
          ),
          const SizedBox(height: ConnectMetrics.sectionGap),
          ConnectSectionHeader(
            label: l10n.groupsWhosHere,
            trailing: TextButton(
              onPressed: onMembers,
              style: TextButton.styleFrom(minimumSize: tall),
              child: Text(l10n.groupsSeeAll),
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
                final shownName = m.isMe ? l10n.groupsYou : m.name;
                final role =
                    groupRoleLabel(l10n, m.role) ?? l10n.groupsRoleMember;
                return Semantics(
                  label: '$shownName, $role',
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
                            shownName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colors.onSurface,
                            ),
                          ),
                          if (m.role != 'member')
                            Text(
                              groupRoleLabel(l10n, m.role) ?? '',
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
                  l10n.groupsInvitedToJoin(group.name),
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
                        child: Text(l10n.groupsDecline),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: busy ? null : () => onRespond(accept: true),
                        style: FilledButton.styleFrom(minimumSize: tall),
                        child: Text(l10n.groupsJoinGroup),
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
            label: Text(l10n.groupsJoinGroup),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.groupsJoinHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ] else
          GroupNotice(
            icon: Icons.lock_outline_rounded,
            title: group.isCommunity
                ? l10n.groupsCantJoinTitle
                : l10n.groupsInvitationOnly,
            message: group.isCommunity
                ? l10n.groupsCantJoinBody
                : l10n.groupsInvitationOnlyBody,
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

  List<(String, String)> actionsFor(AppLocalizations l10n, GroupMember member) {
    final mine = widget.group.myRole;
    if (member.isMe || member.role == 'owner') {
      return const [];
    }
    return [
      if (mine == 'owner' && member.role == 'member')
        ('make_moderator', l10n.groupsMakeModerator),
      if (mine == 'owner' && member.role == 'moderator')
        ('make_member', l10n.groupsMakeMember),
      if (mine == 'owner' || (mine == 'moderator' && member.role == 'member'))
        ('remove', l10n.groupsRemoveFromGroup),
    ];
  }

  Future<void> act(GroupMember member, String action) async {
    final l10n = AppLocalizations.of(context);
    if (action == 'remove' &&
        !await confirmCommunityAction(
          context,
          title: l10n.groupsRemoveMemberTitle(member.name),
          message: widget.group.isCommunity
              ? l10n.groupsRemoveMemberBodyCommunity
              : l10n.groupsRemoveMemberBodyPrivate,
          action: l10n.groupsRemove,
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
          apiErrorMessage(e, fallback: l10n.groupsChangeFailed),
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
    final l10n = AppLocalizations.of(context);
    return GroupSheetFrame(
      title: l10n.groupsMembers,
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
                title: l10n.groupsMembersFailed,
                message: apiErrorMessage(
                  e,
                  fallback: l10n.groupsPleaseTryAgain,
                ),
              ),
              data: (members) => Column(
                children: [
                  for (final member in members)
                    Builder(
                      builder: (context) {
                        final actions = actionsFor(l10n, member);
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          minTileHeight: 56,
                          leading: GroupAvatar(
                            name: member.name,
                            photoUrl: member.photoUrl,
                          ),
                          title: Text(
                            member.isMe
                                ? l10n.groupsMemberYou(member.name)
                                : member.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            groupRoleLabel(l10n, member.role) ??
                                l10n.groupsRoleMember,
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
                                  tooltip: l10n.groupsMemberOptions(
                                    member.name,
                                  ),
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
    final l10n = AppLocalizations.of(context);
    final trimmed = name.text.trim();
    // The same rule as creating a group; the server refuses shorter names.
    if (trimmed.length < 3) {
      setState(() => error = l10n.groupsCreateNameTooShort);
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await groupsApi(ref).update(widget.group.id, {
        'name': trimmed,
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
          () => error = apiErrorMessage(e, fallback: l10n.groupsEditFailed),
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
    final l10n = AppLocalizations.of(context);
    final categories = ref.watch(groupCategoriesProvider).valueOrNull ?? [];
    return GroupSheetFrame(
      title: l10n.groupsEditGroup,
      footer: FilledButton(
        onPressed: busy ? null : save,
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        child: Text(busy ? l10n.groupsSaving : l10n.groupsSaveChanges),
      ),
      children: [
        TextField(
          controller: name,
          maxLength: 60,
          decoration: InputDecoration(labelText: l10n.groupsNameLabel),
        ),
        TextField(
          controller: description,
          maxLength: 500,
          minLines: 2,
          maxLines: 5,
          decoration: InputDecoration(labelText: l10n.groupsAboutLabel),
        ),
        TextField(
          controller: city,
          maxLength: 60,
          decoration: InputDecoration(labelText: l10n.groupsCityLabel),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in groupCoverColors(l10n).entries)
              ChoiceChip(
                label: Text(entry.value),
                selected: coverColor == entry.key,
                onSelected: (_) => setState(() => coverColor = entry.key),
              ),
          ],
        ),
        if (widget.group.isCommunity && categories.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            l10n.groupsLifestyleLabel,
            style: Theme.of(context).textTheme.titleSmall,
          ),
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
