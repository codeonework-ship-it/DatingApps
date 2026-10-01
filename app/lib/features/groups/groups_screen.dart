import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_error_message.dart';
import '../../core/widgets/connect_page.dart';
import '../../core/widgets/glass_widgets.dart';
import '../common/widgets/community_actions.dart';
import '../social_chat/social_chat_data.dart';
import 'group_detail_screen.dart';
import 'group_launch.dart';
import 'group_widgets.dart';
import 'groups_data.dart';

/// The groups whose chat notifications the member muted (channels of kind
/// `group`, matched by their group id). A mute that has run out is ignored.
Set<String> mutedGroupIds(List<SocialChannel> channels, {DateTime? now}) {
  final at = now ?? DateTime.now();
  return {
    for (final c in channels)
      if (c.kind == 'group' &&
          c.refId.isNotEmpty &&
          c.muted &&
          (c.mutedUntil == null || c.mutedUntil!.isAfter(at)))
        c.refId,
  };
}

/// Groups: the member's groups, invitations, and community groups to
/// discover by lifestyle.
class GroupsScreen extends ConsumerStatefulWidget {
  const GroupsScreen({super.key, this.initialCategory = ''});

  /// A lifestyle slug to open Discover already filtered.
  final String initialCategory;

  @override
  ConsumerState<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends ConsumerState<GroupsScreen> {
  late String category = widget.initialCategory;
  final busy = <String>{};

  Future<void> act(
    String key,
    Future<void> Function() action, {
    required String failure,
    String? success,
  }) async {
    if (busy.contains(key)) {
      return;
    }
    setState(() => busy.add(key));
    try {
      await action();
      invalidateGroups(ref, key);
      if (success != null && mounted) {
        showCommunitySnack(context, success);
      }
    } on Object catch (e) {
      if (mounted) {
        showCommunitySnack(context, apiErrorMessage(e, fallback: failure));
      }
    } finally {
      if (mounted) {
        setState(() => busy.remove(key));
      }
    }
  }

  void open(Group group) => Navigator.of(context).push<void>(
    MaterialPageRoute(builder: (_) => GroupDetailScreen(groupId: group.id)),
  );

  Future<void> refresh() async {
    invalidateGroups(ref);
    ref.invalidate(socialChannelsProvider);
    await ref.read(myGroupsProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final mine = ref.watch(myGroupsProvider);
    final invites = ref.watch(groupInvitesProvider);
    final categories = ref.watch(groupCategoriesProvider);
    final discover = ref.watch(discoverGroupsProvider(category));
    final canPop = Navigator.of(context).canPop();
    final mutedGroups = mutedGroupIds(
      ref.watch(socialChannelsProvider).valueOrNull ?? const [],
    );

    List<Widget> section(
      String label,
      String? caption,
      List<Widget> children, {
      Widget? trailing,
    }) => [
      const SizedBox(height: ConnectMetrics.sectionGap),
      ConnectSectionHeader(label: label, caption: caption, trailing: trailing),
      const SizedBox(height: ConnectMetrics.cardGap),
      for (final child in children)
        Padding(
          padding: const EdgeInsets.only(bottom: ConnectMetrics.cardGap),
          child: child,
        ),
    ];

    Widget loading() => const Padding(
      padding: EdgeInsets.all(24),
      child: Center(child: CircularProgressIndicator()),
    );

    Widget failed(Object e, String title, VoidCallback retry) => GroupNotice(
      icon: Icons.cloud_off_outlined,
      title: title,
      message: apiErrorMessage(e, fallback: 'Please check your connection.'),
      actionLabel: 'Try again',
      onAction: retry,
    );

    final pending = invites.valueOrNull ?? const <GroupInvite>[];
    final categoryList = categories.valueOrNull ?? const <GroupCategory>[];
    final categoryTitle = categoryList
        .where((c) => c.slug == category)
        .map((c) => '${c.emoji} ${c.title}')
        .firstOrNull;

    return Scaffold(
      body: PostLoginBackdrop(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, box) {
              final gutter = ConnectMetrics.gutterFor(box.maxWidth);
              return RefreshIndicator(
                onRefresh: refresh,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 840),
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(gutter, 12, gutter, 120),
                      children: [
                        ConnectPageHeader(
                          leading: canPop ? const BackButton() : null,
                          eyebrow: 'GROUPS',
                          title: 'Find your people.',
                          subtitle:
                              'Lifestyle communities anyone can join, and '
                              'private groups just for your friends.',
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          key: const ValueKey('groups.start'),
                          onPressed: () => openCreateGroup(context),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                          ),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Start a group'),
                        ),
                        if (pending.isNotEmpty)
                          ...section(
                            'INVITATIONS',
                            'Friends asked you to join.',
                            [
                              for (final invite in pending)
                                _InviteCard(
                                  invite: invite,
                                  busy: busy.contains(invite.group.id),
                                  onOpen: () => open(invite.group),
                                  onRespond: ({required accept}) => act(
                                    invite.group.id,
                                    () => groupsApi(
                                      ref,
                                    ).respond(invite.group.id, accept: accept),
                                    failure: 'Your answer could not be saved.',
                                    success: accept
                                        ? 'Welcome to ${invite.group.name}!'
                                        : 'Invitation declined.',
                                  ),
                                ),
                            ],
                          ),
                        ...section(
                          'YOUR GROUPS',
                          null,
                          mine.when(
                            loading: () => [loading()],
                            error: (e, _) => [
                              failed(
                                e,
                                'Your groups could not load',
                                () => ref.invalidate(myGroupsProvider),
                              ),
                            ],
                            data: (groups) => groups.isEmpty
                                ? [
                                    const GroupNotice(
                                      title: 'No groups yet',
                                      message:
                                          'Join a community below, or start a '
                                          'private group with your friends.',
                                    ),
                                  ]
                                : [
                                    for (final g in groups)
                                      GroupCard(
                                        group: g,
                                        onTap: () => open(g),
                                        muted: mutedGroups.contains(g.id),
                                        trailing: g.unreadCount > 0
                                            ? GroupUnreadBadge(
                                                count: g.unreadCount,
                                              )
                                            : null,
                                      ),
                                  ],
                          ),
                        ),
                        ...section(
                          'DISCOVER BY LIFESTYLE',
                          'Community groups are open to everyone.',
                          [
                            categories.when(
                              loading: loading,
                              error: (e, _) => failed(
                                e,
                                'Lifestyles could not load',
                                () => ref.invalidate(groupCategoriesProvider),
                              ),
                              data: (list) => Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ChoiceChip(
                                    label: const Text('All'),
                                    selected: category.isEmpty,
                                    onSelected: (_) =>
                                        setState(() => category = ''),
                                  ),
                                  for (final c in list)
                                    ChoiceChip(
                                      key: ValueKey(
                                        'groups.category.${c.slug}',
                                      ),
                                      label: Text(
                                        c.groupCount > 0
                                            ? '${c.emoji}  ${c.title} · '
                                                  '${c.groupCount}'
                                            : '${c.emoji}  ${c.title}',
                                      ),
                                      selected: category == c.slug,
                                      onSelected: (_) => setState(
                                        () => category = category == c.slug
                                            ? ''
                                            : c.slug,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            ...discover.when(
                              loading: () => [loading()],
                              error: (e, _) => [
                                failed(
                                  e,
                                  'Groups could not load',
                                  () => ref.invalidate(
                                    discoverGroupsProvider(category),
                                  ),
                                ),
                              ],
                              data: (groups) => groups.isEmpty
                                  ? [
                                      GroupNotice(
                                        icon: Icons.explore_outlined,
                                        title: categoryTitle == null
                                            ? 'Nothing new to join'
                                            : 'No $categoryTitle groups yet',
                                        message:
                                            'Be the first: start a community '
                                            'group and invite your friends.',
                                        actionLabel: 'Start one',
                                        onAction: () => openCreateGroup(
                                          context,
                                          kind: 'community',
                                          category: category,
                                        ),
                                      ),
                                    ]
                                  : [
                                      for (final g in groups)
                                        GroupCard(
                                          group: g,
                                          onTap: () => open(g),
                                          trailing: g.canJoin
                                              ? FilledButton.tonal(
                                                  key: ValueKey(
                                                    'groups.join.${g.id}',
                                                  ),
                                                  onPressed: busy.contains(g.id)
                                                      ? null
                                                      : () => act(
                                                          g.id,
                                                          () => groupsApi(
                                                            ref,
                                                          ).join(g.id),
                                                          failure:
                                                              'You could not '
                                                              'join just now.',
                                                          success:
                                                              'Welcome to '
                                                              '${g.name}!',
                                                        ),
                                                  style: FilledButton.styleFrom(
                                                    minimumSize: const Size(
                                                      64,
                                                      48,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    'Join',
                                                    semanticsLabel:
                                                        'Join ${g.name}',
                                                  ),
                                                )
                                              : null,
                                        ),
                                    ],
                            ),
                          ],
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

class _InviteCard extends StatelessWidget {
  const _InviteCard({
    required this.invite,
    required this.busy,
    required this.onOpen,
    required this.onRespond,
  });
  final GroupInvite invite;
  final bool busy;
  final VoidCallback onOpen;
  final void Function({required bool accept}) onRespond;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final group = invite.group;
    final who = invite.inviterName.isEmpty ? 'A friend' : invite.inviterName;
    return ConnectPanel(
      padding: const EdgeInsets.all(ConnectMetrics.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onOpen,
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                GroupCoverThumb(group: group),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$who invited you · ${group.kindLabel} · '
                        '${group.memberLabel}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: busy ? null : () => onRespond(accept: false),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(48, 48),
                  ),
                  child: Text(
                    'Decline',
                    semanticsLabel: 'Decline ${group.name}',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: busy ? null : () => onRespond(accept: true),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(48, 48),
                  ),
                  child: Text('Join', semanticsLabel: 'Join ${group.name}'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
