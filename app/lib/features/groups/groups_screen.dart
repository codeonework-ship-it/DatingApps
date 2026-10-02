import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_error_message.dart';
import '../../core/widgets/connect_page.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../l10n/app_localizations.dart';
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
    try {
      await ref.read(myGroupsProvider.future);
    } on Object {
      // The section shows what went wrong, with Try again.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
      message: apiErrorMessage(e, fallback: l10n.groupsErrorCheckConnection),
      actionLabel: l10n.chatTryAgain,
      onAction: retry,
    );

    final pending = invites.valueOrNull ?? const <GroupInvite>[];
    final categoryList = categories.valueOrNull ?? const <GroupCategory>[];
    final categoryTitle = categoryList
        .where((c) => c.slug == category)
        .map((c) => '${c.emoji} ${c.title}')
        .firstOrNull;
    final discoverEmptyTitle = categoryTitle == null
        ? l10n.groupsDiscoverEmptyTitle
        : l10n.groupsDiscoverEmptyCategoryTitle(categoryTitle);

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
                          eyebrow: l10n.groupsEyebrow,
                          title: l10n.groupsTitle,
                          subtitle: l10n.groupsSubtitle,
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          key: const ValueKey('groups.start'),
                          onPressed: () => openCreateGroup(context),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                          ),
                          icon: const Icon(Icons.add_rounded),
                          label: Text(l10n.groupsStartGroup),
                        ),
                        if (pending.isNotEmpty)
                          ...section(
                            l10n.groupsInvitationsHeader,
                            l10n.groupsInvitationsCaption,
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
                                    failure: l10n.groupsAnswerFailed,
                                    success: accept
                                        ? l10n.groupsWelcome(invite.group.name)
                                        : l10n.groupsInvitationDeclined,
                                  ),
                                ),
                            ],
                          ),
                        ...section(
                          l10n.groupsYourGroupsHeader,
                          null,
                          mine.when(
                            loading: () => [loading()],
                            error: (e, _) => [
                              failed(
                                e,
                                l10n.groupsYourGroupsFailed,
                                () => ref.invalidate(myGroupsProvider),
                              ),
                            ],
                            data: (groups) => groups.isEmpty
                                ? [
                                    GroupNotice(
                                      title: l10n.groupsEmptyTitle,
                                      message: l10n.groupsEmptyBody,
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
                          l10n.groupsDiscoverHeader,
                          l10n.groupsDiscoverCaption,
                          [
                            categories.when(
                              loading: loading,
                              error: (e, _) => failed(
                                e,
                                l10n.groupsLifestylesFailed,
                                () => ref.invalidate(groupCategoriesProvider),
                              ),
                              data: (list) => Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ChoiceChip(
                                    label: Text(l10n.groupsCategoryAll),
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
                                  l10n.groupsDiscoverFailed,
                                  () => ref.invalidate(
                                    discoverGroupsProvider(category),
                                  ),
                                ),
                              ],
                              data: (groups) => groups.isEmpty
                                  ? [
                                      GroupNotice(
                                        icon: Icons.explore_outlined,
                                        title: discoverEmptyTitle,
                                        message: l10n.groupsDiscoverEmptyBody,
                                        actionLabel: l10n.groupsStartOne,
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
                                                          failure: l10n
                                                              .groupsJoinFailed,
                                                          success: l10n
                                                              .groupsWelcome(
                                                                g.name,
                                                              ),
                                                        ),
                                                  style: FilledButton.styleFrom(
                                                    minimumSize: const Size(
                                                      64,
                                                      48,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    l10n.groupsJoin,
                                                    semanticsLabel: l10n
                                                        .groupsJoinNamed(
                                                          g.name,
                                                        ),
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
    final l10n = AppLocalizations.of(context);
    final group = invite.group;
    final kind = group.kindLabel(l10n);
    final members = group.memberLabel(l10n);
    final line = invite.inviterName.isEmpty
        ? l10n.groupsInvitedByFriend(kind, members)
        : l10n.groupsInvitedBy(invite.inviterName, kind, members);
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
                        line,
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
                    l10n.groupsDecline,
                    semanticsLabel: l10n.groupsDeclineNamed(group.name),
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
                  child: Text(
                    l10n.groupsJoin,
                    semanticsLabel: l10n.groupsJoinNamed(group.name),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
