import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/app_layout.dart';
import '../../../core/providers/runtime_feature_flags_provider.dart';
import '../../../core/widgets/connect_page.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../common/widgets/community_actions.dart';
import '../../groups/group_launch.dart';
import '../../intentional_dating/dating_rhythm.dart';
import '../../plans/screens/plans_screen.dart';
import '../../social_chat/social_chat_data.dart';
import '../../social_chat/social_chat_screen.dart';
import '../friend_actions.dart';
import '../models/friend_social.dart';
import '../providers/friend_social_provider.dart';
import '../providers/friends_provider.dart';
import '../widgets/friend_social_sheets.dart';
import 'introducer_screen.dart';

/// Friends in the Today look: requests to answer, conversations with
/// friends, the friends list with Message / Vouch / Introduce / Remove /
/// Block, an Add friend search (no raw ids) and "Create a group" from
/// selected friends.
class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key, this.createGroup = openCreateGroup});

  /// Starts a group with the chosen friends (the Groups feature's
  /// [openCreateGroup]; replaceable in tests).
  final Future<void> Function(
    BuildContext context, {
    List<GroupInvitee> invitees,
  })
  createGroup;

  // Requests and friendships change on the other member's side, so the lists
  // are fetched again every time the screen opens, not only on
  // pull-to-refresh: an incoming request must be there when the member
  // arrives from its notification.
  @override
  Widget build(BuildContext context, WidgetRef ref) => _LoadOnOpen(
    onOpen: () => Future.wait([
      ref.read(friendsProvider.notifier).load(),
      ref.read(friendSocialProvider.notifier).load(),
    ]),
    child: Consumer(builder: (context, ref, _) => _screen(context, ref)),
  );

  Widget _screen(BuildContext context, WidgetRef ref) {
    final state = ref.watch(friendsProvider);
    final notifier = ref.read(friendsProvider.notifier);
    final social = ref.watch(friendSocialProvider);
    final socialNotifier = ref.read(friendSocialProvider.notifier);
    final runtimeFlags = ref
        .watch(runtimeFeatureFlagsProvider)
        .maybeWhen(
          data: (flags) => flags,
          orElse: () => RuntimeFeatureFlags.defaults,
        );
    final introsEnabled = runtimeFlags.enabled(
      'friend_intros_enabled',
      fallback: true,
    );
    final accepted = state.accepted;
    final incoming = state.incoming;
    final outgoing = state.outgoing;
    final friendChats =
        ref
            .watch(socialChannelsProvider)
            .whenOrNull(
              data: (channels) =>
                  channels.where((c) => c.kind == 'friend').toList(),
            ) ??
        const <SocialChannel>[];
    final unreadByFriend = {
      for (final c in friendChats) c.peerId: c.unreadCount,
    };
    final byId = {for (final f in state.friends) f.friendUserId: f};
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    Future<void> refresh() async {
      ref.invalidate(socialChannelsProvider);
      await Future.wait([notifier.load(), socialNotifier.load()]);
    }

    List<Widget> section(
      String label, {
      required List<Widget> children,
      String? title,
      String? caption,
      Widget? trailing,
    }) => [
      const SizedBox(height: ConnectMetrics.sectionGap),
      ConnectSectionHeader(
        label: label,
        title: title,
        caption: caption,
        trailing: trailing,
      ),
      const SizedBox(height: ConnectMetrics.cardGap),
      for (final child in children)
        Padding(
          padding: const EdgeInsets.only(bottom: ConnectMetrics.cardGap),
          child: child,
        ),
    ];

    return Scaffold(
      body: PostLoginBackdrop(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, box) {
              final gutter = ConnectMetrics.gutterFor(box.maxWidth);
              return RefreshIndicator(
                onRefresh: refresh,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(gutter, 12, gutter, 120),
                  children: [
                    ConnectPageHeader(
                      eyebrow: l10n.friendsEyebrow,
                      title: l10n.friendsTitle,
                      subtitle: l10n.friendsSubtitle,
                      leading: Navigator.of(context).canPop()
                          ? IconButton(
                              tooltip: l10n.friendsBack,
                              icon: const Icon(Icons.arrow_back_rounded),
                              onPressed: () => Navigator.of(context).maybePop(),
                            )
                          : null,
                    ),
                    const SizedBox(height: AppLayout.space5),
                    Wrap(
                      spacing: AppLayout.space3,
                      runSpacing: AppLayout.space3,
                      children: [
                        FilledButton.icon(
                          key: const ValueKey('qa.friends.add'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, AppLayout.minTapTarget),
                          ),
                          onPressed: () => showAddFriendSheet(context),
                          icon: const Icon(Icons.person_add_alt_1_outlined),
                          label: Text(l10n.friendsAddFriend),
                        ),
                        OutlinedButton.icon(
                          key: const ValueKey('qa.friends.create_group'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, AppLayout.minTapTarget),
                          ),
                          onPressed: accepted.isEmpty
                              ? null
                              : () => _createGroup(context, accepted),
                          icon: const Icon(Icons.group_add_outlined),
                          label: Text(l10n.friendsCreateGroup),
                        ),
                      ],
                    ),
                    if (state.hasError || social.hasError) ...[
                      const SizedBox(height: AppLayout.space4),
                      Text(
                        state.errorText(l10n) ?? social.errorText(l10n)!,
                        style: TextStyle(color: colors.error),
                      ),
                    ],
                    if (incoming.isNotEmpty || outgoing.isNotEmpty)
                      ...section(
                        l10n.friendsSectionRequests,
                        title: incoming.isEmpty
                            ? l10n.friendsRequestsWaitingOnOthers
                            : l10n.friendsRequestsWaitingOnYou,
                        caption: l10n.friendsRequestsCaption,
                        children: [
                          for (final f in incoming)
                            _RequestRow(
                              friend: f,
                              busy: state.isMutating,
                              onAccept: () => notifier.decideFriendRequest(
                                f.friendUserId,
                                accept: true,
                              ),
                              onDecline: () => notifier.decideFriendRequest(
                                f.friendUserId,
                                accept: false,
                              ),
                            ),
                          for (final f in outgoing)
                            _RequestRow(
                              friend: f,
                              busy: state.isMutating,
                              onCancel: () =>
                                  notifier.removeFriend(f.friendUserId),
                            ),
                        ],
                      ),
                    if (friendChats.isNotEmpty)
                      ...section(
                        l10n.friendsSectionChats,
                        title: l10n.friendsChatsTitle,
                        children: [
                          for (final c in friendChats)
                            _ChatRow(
                              channel: c,
                              photoUrl: byId[c.peerId]?.photoUrl ?? '',
                              onTap: () async {
                                await openSocialChat(
                                  context,
                                  channelId: c.id,
                                  title: c.title,
                                  subtitle: l10n.roomsStatusFriend,
                                );
                                ref.invalidate(socialChannelsProvider);
                              },
                            ),
                        ],
                      ),
                    if (introsEnabled && social.introsAwaitingMe.isNotEmpty)
                      ...section(
                        l10n.friendsSectionIntros,
                        title: l10n.friendsIntrosTitle,
                        children: [
                          for (final intro in social.introsAwaitingMe)
                            _IntroCard(
                              intro: intro,
                              busy: social.isMutating,
                              onDecide: (accept) => socialNotifier.decideIntro(
                                introId: intro.id,
                                accept: accept,
                              ),
                            ),
                        ],
                      ),
                    if (introsEnabled && social.pendingVouches.isNotEmpty)
                      ...section(
                        l10n.friendsSectionVouches,
                        title: l10n.friendsVouchesPendingTitle,
                        children: [
                          for (final vouch in social.pendingVouches)
                            _VouchCard(
                              vouch: vouch,
                              busy: social.isMutating,
                              onDecide: (approve) => socialNotifier.decideVouch(
                                vouchId: vouch.id,
                                approve: approve,
                              ),
                            ),
                        ],
                      ),
                    ...section(
                      l10n.friendsEyebrow,
                      title: l10n.friendsCountTitle(accepted.length),
                      trailing: introsEnabled && accepted.length >= 2
                          ? TextButton.icon(
                              key: const ValueKey('qa.friends.intro_action'),
                              style: TextButton.styleFrom(
                                minimumSize: const Size(
                                  0,
                                  AppLayout.minTapTarget,
                                ),
                              ),
                              onPressed: social.isMutating
                                  ? null
                                  : () => _makeIntro(context, accepted),
                              icon: const Icon(
                                Icons.connect_without_contact_rounded,
                              ),
                              label: Text(l10n.friendsIntroduce),
                            )
                          : null,
                      children: [
                        if (state.isLoading && state.friends.isEmpty)
                          const Center(child: CircularProgressIndicator())
                        else if (accepted.isEmpty)
                          ConnectPanel(
                            child: Text(
                              l10n.friendsEmptyBody,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: colors.onSurfaceVariant),
                            ),
                          )
                        else
                          for (final f in accepted)
                            _FriendRow(
                              friend: f,
                              unread: unreadByFriend[f.friendUserId] ?? 0,
                              introsEnabled: introsEnabled,
                              onMessage: () => openFriendChat(
                                context,
                                ref,
                                friendId: f.friendUserId,
                                name: f.nameLabel(l10n),
                              ),
                              onAction: (action) => _onFriendAction(
                                context,
                                ref,
                                action,
                                f,
                                accepted,
                              ),
                            ),
                      ],
                    ),
                    if (introsEnabled &&
                        social.vouchesAboutMe.any((v) => v.isApproved))
                      ...section(
                        l10n.friendsSectionOnProfile,
                        title: l10n.friendsVouchesOnProfileTitle,
                        children: [
                          for (final vouch in social.vouchesAboutMe.where(
                            (v) => v.isApproved,
                          ))
                            ConnectPanel(
                              padding: const EdgeInsets.all(
                                ConnectMetrics.padding,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.verified_rounded,
                                    color: colors.primary,
                                  ),
                                  const SizedBox(width: AppLayout.space3),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(l10n.friendsQuoted(vouch.text)),
                                        const SizedBox(height: 4),
                                        Text(
                                          l10n.friendsVouchedForYou(
                                            vouch.voucherLabel(l10n),
                                          ),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: colors.onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: l10n.friendsHideFromProfile,
                                    icon: const Icon(
                                      Icons.visibility_off_outlined,
                                    ),
                                    onPressed: social.isMutating
                                        ? null
                                        : () => socialNotifier.decideVouch(
                                            vouchId: vouch.id,
                                            approve: false,
                                          ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ...section(
                      l10n.friendsSectionMore,
                      title: l10n.friendsMoreTitle,
                      children: [
                        ConnectNavTile(
                          key: const ValueKey('qa.friends.plans_link'),
                          icon: Icons.event_available_rounded,
                          title: l10n.friendsPlansLinkTitle,
                          subtitle: l10n.friendsPlansLinkSubtitle,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const PlansScreen(initialTab: 1),
                            ),
                          ),
                        ),
                        if (introsEnabled) ...[
                          ConnectNavTile(
                            icon: Icons.diversity_1_outlined,
                            title: l10n.friendsInviteIntroducerTitle,
                            subtitle: l10n.friendsInviteIntroducerSubtitle,
                            tint: colors.secondary,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const IntroducerScreen(
                                  memberControls: true,
                                ),
                              ),
                            ),
                          ),
                          ConnectNavTile(
                            icon: Icons.privacy_tip_outlined,
                            title: l10n.friendsIntroTermsTitle,
                            subtitle: l10n.friendsIntroTermsSubtitle,
                            tint: colors.tertiary,
                            onTap: () => openDatingRhythm(context),
                          ),
                        ],
                      ],
                    ),
                    if (state.activities.isNotEmpty)
                      ...section(
                        l10n.friendsSectionActivity,
                        title: l10n.friendsActivityTitle,
                        children: [
                          for (final activity in state.activities.take(5))
                            ConnectPanel(
                              padding: const EdgeInsets.all(
                                ConnectMetrics.padding,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.local_activity_outlined,
                                    color: colors.primary,
                                  ),
                                  const SizedBox(width: AppLayout.space3),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          activity.title.trim().isEmpty
                                              ? l10n.friendsActivityFallback
                                              : activity.title,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        if (activity.description.isNotEmpty)
                                          Text(
                                            activity.description,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color:
                                                      colors.onSurfaceVariant,
                                                ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _onFriendAction(
    BuildContext context,
    WidgetRef ref,
    String action,
    FriendConnection friend,
    List<FriendConnection> accepted,
  ) async {
    final notifier = ref.read(friendsProvider.notifier);
    final l10n = AppLocalizations.of(context);
    switch (action) {
      case 'vouch':
        final sent = await showVouchSheet(context: context, friend: friend);
        if (sent == true && context.mounted) {
          showCommunitySnack(
            context,
            l10n.friendsVouchSentSnack(friend.nameLabel(l10n)),
          );
        }
      case 'intro':
        await _makeIntro(context, accepted, preselected: friend);
      case 'remove':
        final confirmed = await confirmCommunityAction(
          context,
          title: l10n.friendsRemoveTitle(friend.nameLabel(l10n)),
          message: l10n.friendsRemoveBody,
          action: l10n.friendsRemoveFriend,
        );
        if (confirmed) {
          await notifier.removeFriend(friend.friendUserId);
          ref.invalidate(socialChannelsProvider);
        }
      case 'block':
        if (!context.mounted) {
          return;
        }
        final blocked = await blockCommunityMember(
          context,
          ref,
          userId: friend.friendUserId,
          name: friend.nameLabel(l10n),
        );
        if (blocked) {
          await notifier.load();
          ref.invalidate(socialChannelsProvider);
        }
    }
  }

  Future<void> _makeIntro(
    BuildContext context,
    List<FriendConnection> accepted, {
    FriendConnection? preselected,
  }) async {
    final made = await showIntroSheet(
      context: context,
      friends: accepted,
      preselected: preselected,
    );
    if (made == true && context.mounted) {
      showCommunitySnack(
        context,
        AppLocalizations.of(context).friendsIntroMadeSnack,
      );
    }
  }

  Future<void> _createGroup(
    BuildContext context,
    List<FriendConnection> accepted,
  ) async {
    final chosen = await showModalBottomSheet<List<FriendConnection>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => _CreateGroupSheet(friends: accepted),
    );
    if (chosen == null || chosen.isEmpty || !context.mounted) {
      return;
    }
    await createGroup(
      context,
      invitees: [
        for (final f in chosen)
          (
            userId: f.friendUserId,
            name: f.nameLabel(AppLocalizations.of(context)),
            photoUrl: f.photoUrl,
          ),
      ],
    );
  }
}

/// Opens the Add friend search: type a name or @username, see up to ten
/// members, and send a request from each row.
Future<void> showAddFriendSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => const _AddFriendSheet(),
    );

/// Runs [onOpen] once after the first frame, i.e. each time the screen is
/// pushed.
class _LoadOnOpen extends StatefulWidget {
  const _LoadOnOpen({required this.onOpen, required this.child});

  final Future<void> Function() onOpen;
  final Widget child;

  @override
  State<_LoadOnOpen> createState() => _LoadOnOpenState();
}

class _LoadOnOpenState extends State<_LoadOnOpen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(widget.onOpen());
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _AddFriendSheet extends ConsumerStatefulWidget {
  const _AddFriendSheet();

  @override
  ConsumerState<_AddFriendSheet> createState() => _AddFriendSheetState();
}

class _AddFriendSheetState extends ConsumerState<_AddFriendSheet> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _query = value.trim());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final ready = _query.replaceFirst('@', '').length >= 3;
    final results = ready ? ref.watch(friendSearchProvider(_query)) : null;
    // A member who turned off "Let people find me in friend search" can still
    // search, but is told they cannot be found the same way.
    final hidden =
        ref.watch(friendSearchVisibilityProvider).valueOrNull == false;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConnectSectionHeader(
            label: l10n.friendsAddSheetLabel,
            title: l10n.friendsAddSheetTitle,
            caption: l10n.friendsAddSheetCaption,
          ),
          if (hidden) ...[
            const SizedBox(height: AppLayout.space3),
            Text(
              l10n.friendsSearchHiddenNote,
              key: const ValueKey('qa.friends.search_hidden_note'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppLayout.space4),
          TextField(
            key: const ValueKey('qa.friends.search_field'),
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: _onChanged,
            onSubmitted: (v) => setState(() => _query = v.trim()),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              labelText: l10n.friendsSearchLabel,
              helperText: l10n.friendsSearchHelper,
            ),
          ),
          const SizedBox(height: AppLayout.space3),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.5,
            ),
            child: results == null
                ? const SizedBox.shrink()
                : results.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(AppLayout.space4),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.all(AppLayout.space4),
                      child: Text(
                        l10n.friendsSearchFailed,
                        style: TextStyle(color: colors.error),
                      ),
                    ),
                    data: (people) => people.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(AppLayout.space4),
                            child: Text(
                              l10n.friendsSearchNoResults(_query),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          )
                        : ListView(
                            shrinkWrap: true,
                            children: [
                              for (final p in people)
                                _MemberLine(
                                  key: ValueKey(
                                    'qa.friends.result.${p.userId}',
                                  ),
                                  name: p.name,
                                  photoUrl: p.photoUrl,
                                  detail: [
                                    if (p.username.isNotEmpty) '@${p.username}',
                                    if (p.city.isNotEmpty) p.city,
                                  ].join(' · '),
                                  trailing: AddFriendButton(
                                    userId: p.userId,
                                    name: p.name,
                                    source: FriendRequestSource.search,
                                  ),
                                ),
                            ],
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CreateGroupSheet extends StatefulWidget {
  const _CreateGroupSheet({required this.friends});

  final List<FriendConnection> friends;

  @override
  State<_CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends State<_CreateGroupSheet> {
  final _selected = <String>{};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConnectSectionHeader(
            label: l10n.friendsNewGroupLabel,
            title: l10n.friendsNewGroupTitle,
            caption: l10n.friendsNewGroupCaption,
          ),
          const SizedBox(height: AppLayout.space3),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final f in widget.friends)
                  CheckboxListTile(
                    key: ValueKey('qa.friends.group_pick.${f.friendUserId}'),
                    value: _selected.contains(f.friendUserId),
                    onChanged: (on) => setState(
                      () => on ?? false
                          ? _selected.add(f.friendUserId)
                          : _selected.remove(f.friendUserId),
                    ),
                    secondary: _Avatar(
                      name: f.nameLabel(l10n),
                      photoUrl: f.photoUrl,
                    ),
                    title: Text(f.nameLabel(l10n)),
                    subtitle: f.username.isEmpty
                        ? null
                        : Text('@${f.username}'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppLayout.space3),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const ValueKey('qa.friends.group_continue'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, AppLayout.minTapTarget),
              ),
              onPressed: _selected.isEmpty
                  ? null
                  : () => Navigator.of(context).pop([
                      for (final f in widget.friends)
                        if (_selected.contains(f.friendUserId)) f,
                    ]),
              icon: const Icon(Icons.group_add_outlined),
              label: Text(
                _selected.isEmpty
                    ? l10n.friendsChooseFriends
                    : l10n.friendsCreateGroupWith(_selected.length),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A round photo, or the first letter of the name.
class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.photoUrl});

  final String name;
  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return CircleAvatar(
      radius: 22,
      backgroundColor: colors.primaryContainer,
      foregroundImage: photoUrl.isEmpty ? null : NetworkImage(photoUrl),
      onForegroundImageError: photoUrl.isEmpty ? null : (_, _) {},
      child: Text(
        initial,
        style: TextStyle(
          color: colors.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Avatar, name and one detail line, with a trailing action.
class _MemberLine extends StatelessWidget {
  const _MemberLine({
    required this.name,
    required this.photoUrl,
    required this.detail,
    required this.trailing,
    super.key,
  });

  final String name;
  final String photoUrl;
  final String detail;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppLayout.space2),
      child: Row(
        children: [
          _Avatar(name: name, photoUrl: photoUrl),
          const SizedBox(width: AppLayout.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
                if (detail.isNotEmpty)
                  Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppLayout.space2),
          trailing,
        ],
      ),
    );
  }
}

String _sourceLabel(AppLocalizations l10n, String source) => switch (source) {
  'match' => l10n.friendsSourceMatch,
  'profile' => l10n.friendsSourceProfile,
  'room' => l10n.friendsSourceRoom,
  'group' => l10n.friendsSourceGroup,
  'search' => l10n.friendsSourceSearch,
  _ => '',
};

class _RequestRow extends StatelessWidget {
  const _RequestRow({
    required this.friend,
    required this.busy,
    this.onAccept,
    this.onDecline,
    this.onCancel,
  });

  final FriendConnection friend;
  final bool busy;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final id = friend.friendUserId;
    final incoming = friend.isIncoming;
    final l10n = AppLocalizations.of(context);
    final source = _sourceLabel(l10n, friend.source);
    final detail = [
      if (incoming) l10n.friendsWantsToBeFriends else l10n.friendsRequestSent,
      if (source.isNotEmpty) source,
    ].join(' · ');
    const tall = Size(0, AppLayout.minTapTarget);
    return ConnectPanel(
      key: ValueKey('qa.friends.request.$id'),
      padding: const EdgeInsets.all(ConnectMetrics.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MemberLine(
            name: friend.nameLabel(l10n),
            photoUrl: friend.photoUrl,
            detail: detail,
            trailing: incoming
                ? const SizedBox.shrink()
                : OutlinedButton(
                    key: ValueKey('qa.friends.cancel.$id'),
                    style: OutlinedButton.styleFrom(minimumSize: tall),
                    onPressed: busy ? null : onCancel,
                    child: Text(l10n.friendsCancel),
                  ),
          ),
          if (incoming) ...[
            const SizedBox(height: AppLayout.space2),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: ValueKey('qa.friends.decline.$id'),
                    style: OutlinedButton.styleFrom(minimumSize: tall),
                    onPressed: busy ? null : onDecline,
                    child: Text(l10n.friendsDecline),
                  ),
                ),
                const SizedBox(width: AppLayout.space2),
                Expanded(
                  child: FilledButton(
                    key: ValueKey('qa.friends.accept.$id'),
                    style: FilledButton.styleFrom(minimumSize: tall),
                    onPressed: busy ? null : onAccept,
                    child: Text(l10n.friendsAccept),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _FriendRow extends StatelessWidget {
  const _FriendRow({
    required this.friend,
    required this.unread,
    required this.introsEnabled,
    required this.onMessage,
    required this.onAction,
  });

  final FriendConnection friend;
  final int unread;
  final bool introsEnabled;
  final VoidCallback onMessage;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) {
    final id = friend.friendUserId;
    final l10n = AppLocalizations.of(context);
    final detail = [
      if (friend.username.isNotEmpty) '@${friend.username}',
      if (friend.city.isNotEmpty) friend.city,
    ].join(' · ');
    return ConnectPanel(
      key: ValueKey('qa.friends.friend.$id'),
      padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
      child: _MemberLine(
        name: friend.nameLabel(l10n),
        photoUrl: friend.photoUrl,
        detail: detail,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              key: ValueKey('qa.friends.message.$id'),
              tooltip: unread > 0
                  ? l10n.friendsMessageTooltipUnread(
                      friend.nameLabel(l10n),
                      unread,
                    )
                  : l10n.friendsMessageTooltip(friend.nameLabel(l10n)),
              onPressed: onMessage,
              icon: Badge(
                isLabelVisible: unread > 0,
                label: Text('$unread'),
                child: const Icon(Icons.chat_bubble_outline_rounded),
              ),
            ),
            PopupMenuButton<String>(
              key: ValueKey('qa.friends.menu.$id'),
              tooltip: l10n.friendsMoreFor(friend.nameLabel(l10n)),
              onSelected: onAction,
              itemBuilder: (_) => [
                if (introsEnabled) ...[
                  PopupMenuItem(
                    value: 'vouch',
                    child: ListTile(
                      leading: const Icon(Icons.verified_outlined),
                      title: Text(l10n.friendsMenuVouch),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'intro',
                    child: ListTile(
                      leading: const Icon(
                        Icons.connect_without_contact_rounded,
                      ),
                      title: Text(l10n.friendsMenuIntro),
                    ),
                  ),
                ],
                PopupMenuItem(
                  value: 'remove',
                  child: ListTile(
                    leading: const Icon(Icons.person_remove_outlined),
                    title: Text(l10n.friendsRemoveFriend),
                  ),
                ),
                PopupMenuItem(
                  value: 'block',
                  child: ListTile(
                    leading: const Icon(Icons.block_rounded),
                    title: Text(l10n.roomsBlock),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatRow extends StatelessWidget {
  const _ChatRow({
    required this.channel,
    required this.photoUrl,
    required this.onTap,
  });

  final SocialChannel channel;
  final String photoUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final unread = channel.unreadCount;
    final radius = BorderRadius.circular(ConnectMetrics.cardRadius);
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: channel.muted
          ? l10n.friendsChatSemanticsMuted(channel.title, unread)
          : l10n.friendsChatSemantics(channel.title, unread),
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: radius,
            border: Border.all(color: colors.outlineVariant),
          ),
          child: InkWell(
            key: ValueKey('qa.friends.chat.${channel.id}'),
            borderRadius: radius,
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 72),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ConnectMetrics.padding,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    _Avatar(name: channel.title, photoUrl: photoUrl),
                    const SizedBox(width: AppLayout.space3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            channel.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: unread > 0
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: colors.onSurface,
                            ),
                          ),
                          if (channel.lastMessage.isNotEmpty)
                            Text(
                              channel.lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Notifications muted for this chat (migration 119).
                    if (channel.muted) ...[
                      const SizedBox(width: AppLayout.space2),
                      Icon(
                        Icons.notifications_off_outlined,
                        key: ValueKey('qa.friends.muted.${channel.id}'),
                        size: 18,
                        color: colors.onSurfaceVariant,
                      ),
                    ],
                    if (unread > 0) ...[
                      const SizedBox(width: AppLayout.space2),
                      Badge(
                        key: ValueKey('qa.friends.unread.${channel.id}'),
                        label: Text('$unread'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({
    required this.intro,
    required this.busy,
    required this.onDecide,
  });

  final FriendIntro intro;
  final bool busy;
  final ValueChanged<bool> onDecide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final other = intro.other;
    final l10n = AppLocalizations.of(context);
    final headline = other == null
        ? l10n.friendsIntroHeadlineSomeone(intro.introducerLabel(l10n))
        : l10n.friendsIntroHeadline(
            intro.introducerLabel(l10n),
            other.age == null
                ? other.nameLabel(l10n)
                : l10n.friendsNameAge(other.nameLabel(l10n), other.age!),
          );
    return ConnectPanel(
      key: ValueKey('qa.friends.intro.${intro.id}'),
      padding: const EdgeInsets.all(ConnectMetrics.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(
                name: other?.name ?? '',
                photoUrl: other != null && other.photoUrls.isNotEmpty
                    ? other.photoUrls.first
                    : '',
              ),
              const SizedBox(width: AppLayout.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headline,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (other != null && other.city.isNotEmpty)
                      Text(
                        other.city,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (other?.isVerified ?? false)
                Icon(Icons.verified, color: theme.colorScheme.primary),
            ],
          ),
          if (intro.message.isNotEmpty) ...[
            const SizedBox(height: AppLayout.space2),
            Text(
              l10n.friendsQuoted(intro.message),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: AppLayout.space3),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: ValueKey('qa.friends.intro_decline.${intro.id}'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, AppLayout.minTapTarget),
                  ),
                  onPressed: busy ? null : () => onDecide(false),
                  child: Text(l10n.friendsIntroNoThanks),
                ),
              ),
              const SizedBox(width: AppLayout.space2),
              Expanded(
                child: FilledButton(
                  key: ValueKey('qa.friends.intro_accept.${intro.id}'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, AppLayout.minTapTarget),
                  ),
                  onPressed: busy ? null : () => onDecide(true),
                  child: Text(l10n.friendsIntroImIn),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VouchCard extends StatelessWidget {
  const _VouchCard({
    required this.vouch,
    required this.busy,
    required this.onDecide,
  });

  final FriendVouch vouch;
  final bool busy;
  final ValueChanged<bool> onDecide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return ConnectPanel(
      key: ValueKey('qa.friends.vouch.${vouch.id}'),
      padding: const EdgeInsets.all(ConnectMetrics.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.friendsVouchedForYou(vouch.voucherLabel(l10n)),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppLayout.space2),
          Text(
            l10n.friendsQuoted(vouch.text),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppLayout.space3),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: ValueKey('qa.friends.vouch_hide.${vouch.id}'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, AppLayout.minTapTarget),
                  ),
                  onPressed: busy ? null : () => onDecide(false),
                  child: Text(l10n.friendsVouchKeepPrivate),
                ),
              ),
              const SizedBox(width: AppLayout.space2),
              Expanded(
                child: FilledButton(
                  key: ValueKey('qa.friends.vouch_approve.${vouch.id}'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, AppLayout.minTapTarget),
                  ),
                  onPressed: busy ? null : () => onDecide(true),
                  child: Text(l10n.friendsVouchShowOnProfile),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
