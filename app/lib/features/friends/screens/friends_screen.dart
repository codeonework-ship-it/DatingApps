import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/app_layout.dart';
import '../../../core/providers/runtime_feature_flags_provider.dart';
import '../../../core/widgets/connect_page.dart';
import '../../../core/widgets/glass_widgets.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                      eyebrow: 'FRIENDS',
                      title: 'Your people',
                      subtitle:
                          'Friends can message, plan and make groups '
                          'together. Requests need a yes from both sides.',
                      leading: Navigator.of(context).canPop()
                          ? IconButton(
                              tooltip: 'Back',
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
                          label: const Text('Add friend'),
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
                          label: const Text('Create a group'),
                        ),
                      ],
                    ),
                    if (state.error != null || social.error != null) ...[
                      const SizedBox(height: AppLayout.space4),
                      Text(
                        state.error ?? social.error!,
                        style: TextStyle(color: colors.error),
                      ),
                    ],
                    if (incoming.isNotEmpty || outgoing.isNotEmpty)
                      ...section(
                        'REQUESTS',
                        title: incoming.isEmpty
                            ? 'Waiting on others'
                            : 'Waiting on you',
                        caption: 'Nothing is shared until both of you agree.',
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
                        'CHATS',
                        title: 'Conversations',
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
                                  subtitle: 'Friend',
                                );
                                ref.invalidate(socialChannelsProvider);
                              },
                            ),
                        ],
                      ),
                    if (introsEnabled && social.introsAwaitingMe.isNotEmpty)
                      ...section(
                        'INTROS',
                        title: 'Intros for you',
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
                        'VOUCHES',
                        title: 'Vouches waiting for your approval',
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
                      'FRIENDS',
                      title: accepted.isEmpty
                          ? 'No friends yet'
                          : accepted.length == 1
                          ? '1 friend'
                          : '${accepted.length} friends',
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
                              label: const Text('Introduce'),
                            )
                          : null,
                      children: [
                        if (state.isLoading && state.friends.isEmpty)
                          const Center(child: CircularProgressIndicator())
                        else if (accepted.isEmpty)
                          ConnectPanel(
                            child: Text(
                              'Find people you know by name or username, or '
                              'add someone from a match, a room or a group.',
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
                                name: f.friendName,
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
                        'ON YOUR PROFILE',
                        title: 'Vouches on your profile',
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
                                        Text('“${vouch.text}”'),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${vouch.voucherName} vouched '
                                          'for you',
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
                                    tooltip: 'Hide from profile',
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
                      'MORE',
                      title: 'Plans and introductions',
                      children: [
                        ConnectNavTile(
                          key: const ValueKey('qa.friends.plans_link'),
                          icon: Icons.event_available_rounded,
                          title: 'Date plans shared with you',
                          subtitle:
                              'Friends tell you when they plan a date and '
                              'when they check in afterwards.',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const PlansScreen(initialTab: 1),
                            ),
                          ),
                        ),
                        if (introsEnabled) ...[
                          ConnectNavTile(
                            icon: Icons.diversity_1_outlined,
                            title: 'Invite a friend who isn’t dating',
                            subtitle:
                                'Choose who can introduce you. Review or '
                                'withdraw permission anytime.',
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
                            title: 'Introductions, on your terms',
                            subtitle:
                                'Choose whether friends can introduce you and '
                                'what a preview shares.',
                            tint: colors.tertiary,
                            onTap: () => openDatingRhythm(context),
                          ),
                        ],
                      ],
                    ),
                    if (state.activities.isNotEmpty)
                      ...section(
                        'ACTIVITY',
                        title: 'With your friends',
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
                                          activity.title,
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
    switch (action) {
      case 'vouch':
        final sent = await showVouchSheet(context: context, friend: friend);
        if (sent == true && context.mounted) {
          showCommunitySnack(
            context,
            'Vouch sent. ${friend.friendName} approves it before it shows.',
          );
        }
      case 'intro':
        await _makeIntro(context, accepted, preselected: friend);
      case 'remove':
        final confirmed = await confirmCommunityAction(
          context,
          title: 'Remove ${friend.friendName}?',
          message:
              'You’ll stop being friends and your friend chat closes. They '
              'aren’t told.',
          action: 'Remove friend',
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
          name: friend.friendName,
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
        'Intro made. Both friends will hear from you.',
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
          (userId: f.friendUserId, name: f.friendName, photoUrl: f.photoUrl),
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
          const ConnectSectionHeader(
            label: 'ADD FRIEND',
            title: 'Find someone you know',
            caption:
                'Search by name or @username. They choose whether to '
                'accept.',
          ),
          if (hidden) ...[
            const SizedBox(height: AppLayout.space3),
            Text(
              'You’re hidden from friend search, so others can’t find you '
              'here. Change this in Privacy & Safety.',
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
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              labelText: 'Name or @username',
              helperText: 'Type at least 3 letters',
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
                        'Search is unavailable right now. Try again.',
                        style: TextStyle(color: colors.error),
                      ),
                    ),
                    data: (people) => people.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(AppLayout.space4),
                            child: Text(
                              'No one found for “$_query”.',
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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ConnectSectionHeader(
          label: 'NEW GROUP',
          title: 'Who’s in?',
          caption: 'Choose friends to invite. You can add more later.',
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
                  secondary: _Avatar(name: f.friendName, photoUrl: f.photoUrl),
                  title: Text(f.friendName),
                  subtitle: f.username.isEmpty ? null : Text('@${f.username}'),
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
                  ? 'Choose friends'
                  : 'Create a group with ${_selected.length}',
            ),
          ),
        ),
      ],
    ),
  );
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

String _sourceLabel(String source) => switch (source) {
  'match' => 'From your matches',
  'profile' => 'Saw your profile',
  'room' => 'Met in a room',
  'group' => 'From a group',
  'search' => 'Found you by name',
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
    final detail = [
      if (incoming) 'Wants to be friends' else 'Request sent',
      if (_sourceLabel(friend.source).isNotEmpty) _sourceLabel(friend.source),
    ].join(' · ');
    const tall = Size(0, AppLayout.minTapTarget);
    return ConnectPanel(
      key: ValueKey('qa.friends.request.$id'),
      padding: const EdgeInsets.all(ConnectMetrics.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MemberLine(
            name: friend.friendName,
            photoUrl: friend.photoUrl,
            detail: detail,
            trailing: incoming
                ? const SizedBox.shrink()
                : OutlinedButton(
                    key: ValueKey('qa.friends.cancel.$id'),
                    style: OutlinedButton.styleFrom(minimumSize: tall),
                    onPressed: busy ? null : onCancel,
                    child: const Text('Cancel'),
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
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: AppLayout.space2),
                Expanded(
                  child: FilledButton(
                    key: ValueKey('qa.friends.accept.$id'),
                    style: FilledButton.styleFrom(minimumSize: tall),
                    onPressed: busy ? null : onAccept,
                    child: const Text('Accept'),
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
    final detail = [
      if (friend.username.isNotEmpty) '@${friend.username}',
      if (friend.city.isNotEmpty) friend.city,
    ].join(' · ');
    return ConnectPanel(
      key: ValueKey('qa.friends.friend.$id'),
      padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
      child: _MemberLine(
        name: friend.friendName,
        photoUrl: friend.photoUrl,
        detail: detail,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              key: ValueKey('qa.friends.message.$id'),
              tooltip: unread > 0
                  ? 'Message ${friend.friendName}, $unread unread'
                  : 'Message ${friend.friendName}',
              onPressed: onMessage,
              icon: Badge(
                isLabelVisible: unread > 0,
                label: Text('$unread'),
                child: const Icon(Icons.chat_bubble_outline_rounded),
              ),
            ),
            PopupMenuButton<String>(
              key: ValueKey('qa.friends.menu.$id'),
              tooltip: 'More for ${friend.friendName}',
              onSelected: onAction,
              itemBuilder: (_) => [
                if (introsEnabled) ...const [
                  PopupMenuItem(
                    value: 'vouch',
                    child: ListTile(
                      leading: Icon(Icons.verified_outlined),
                      title: Text('Vouch for them'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'intro',
                    child: ListTile(
                      leading: Icon(Icons.connect_without_contact_rounded),
                      title: Text('Introduce to a friend'),
                    ),
                  ),
                ],
                const PopupMenuItem(
                  value: 'remove',
                  child: ListTile(
                    leading: Icon(Icons.person_remove_outlined),
                    title: Text('Remove friend'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'block',
                  child: ListTile(
                    leading: Icon(Icons.block_rounded),
                    title: Text('Block'),
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
    return Semantics(
      button: true,
      label:
          (unread > 0
              ? 'Chat with ${channel.title}, $unread unread'
              : 'Chat with ${channel.title}') +
          (channel.muted ? ', notifications muted' : ''),
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
    final who = other == null
        ? 'someone'
        : other.age == null
        ? other.name
        : '${other.name}, ${other.age}';
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
                      '${intro.introducerName} thinks you should meet $who',
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
              '“${intro.message}”',
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
                  child: const Text('No thanks'),
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
                  child: const Text("I'm in"),
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
    return ConnectPanel(
      key: ValueKey('qa.friends.vouch.${vouch.id}'),
      padding: const EdgeInsets.all(ConnectMetrics.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${vouch.voucherName} vouched for you',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppLayout.space2),
          Text('“${vouch.text}”', style: theme.textTheme.bodyMedium),
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
                  child: const Text('Keep private'),
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
                  child: const Text('Show on my profile'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
