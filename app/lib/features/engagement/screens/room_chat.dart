import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/cinematic_effects.dart';
import '../../../core/layout/app_layout.dart';
import '../../../core/network/api_error_message.dart';
import '../../../core/providers/safety_actions_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../common/widgets/community_actions.dart';
import '../../common/widgets/report_user_sheet.dart';
import '../../friends/friend_actions.dart';
import '../../social_chat/social_chat_l10n.dart';
import '../../social_chat/social_chat_screen.dart';
import '../providers/conversation_rooms_provider.dart';

/// A room's live chat: the shared chat screen with the room's topic and
/// "N here now" on top, the people in the room, Leave, and for hosts and
/// moderators the moderation actions. Tapping a name opens that member's
/// card with Add friend, report and block.

/// How often the open chat tells the server the member is still here. The
/// server counts someone as here now for two minutes after a heartbeat.
const roomHeartbeatInterval = Duration(seconds: 45);

IconData roomIcon(String key) => switch (key) {
  'night' => Icons.nightlight_round,
  'coffee' => Icons.local_cafe_outlined,
  'favorite' => Icons.favorite_border_rounded,
  'spa' => Icons.spa_outlined,
  'book' => Icons.menu_book_rounded,
  'restaurant' => Icons.restaurant_rounded,
  'music' => Icons.headphones_rounded,
  'movie' => Icons.movie_outlined,
  'pets' => Icons.pets_rounded,
  'games' => Icons.sports_esports_outlined,
  'travel' => Icons.explore_outlined,
  'run' => Icons.directions_run_rounded,
  'city' => Icons.location_city_rounded,
  'train' => Icons.train_outlined,
  'interests' => Icons.interests_outlined,
  'hiking' => Icons.hiking_rounded,
  _ => Icons.forum_outlined,
};

String roomRoleLabel(AppLocalizations l, String role) => switch (role) {
  'host' => l.roomsRoleHost,
  'moderator' => l.roomsRoleModerator,
  _ => '',
};

/// A room topic's name in the reader's language ([roomCategories] keys).
String roomCategoryLabel(AppLocalizations l, String key) => switch (key) {
  'talk' => l.roomsCategoryTalk,
  'interests' => l.roomsCategoryInterests,
  'active' => l.roomsCategoryActive,
  'city' => l.roomsCategoryCity,
  _ => l.roomsRoomFallback,
};

/// Opens [room]'s chat. The room must already be joined (it carries its
/// channel id). A member muted in the room reads along with the composer
/// closed (the shared chat screen shows why and reopens it when the mute
/// ends).
Future<void> openRoomChat(BuildContext context, ConversationRoom room) =>
    openSocialChat(
      context,
      channelId: room.channelId,
      title: room.title,
      subtitle: roomCategoryLabel(chatL10n(context), room.category),
      header: RoomPresenceHeader(room: room),
      actions: [
        _RoomPeopleButton(room: room),
        _RoomMenuButton(room: room),
      ],
      onSenderTap: (context, message) => showRoomMemberCard(
        context,
        room: room,
        userId: message.senderId,
        name: message.senderName,
        photoUrl: message.senderPhotoUrl,
      ),
      emptyText: chatL10n(context).roomsChatEmpty(room.title),
    );

/// The band above a room's messages: what the room is about and how many
/// people are here now. While it is on screen it sends the presence
/// heartbeat; when the member leaves the screen it tells the server they are
/// away. If the member is removed or the room closes, the chat closes.
class RoomPresenceHeader extends ConsumerStatefulWidget {
  const RoomPresenceHeader({required this.room, super.key});
  final ConversationRoom room;

  @override
  ConsumerState<RoomPresenceHeader> createState() => _RoomPresenceHeaderState();
}

class _RoomPresenceHeaderState extends ConsumerState<RoomPresenceHeader> {
  late final RoomsApi _api;
  late final ConversationRoomsNotifier _rooms;
  Timer? _timer;
  late int _hereNow = widget.room.hereNow;
  late int _members = widget.room.participantCount;
  bool _ended = false;

  @override
  void initState() {
    super.initState();
    _api = ref.read(roomsApiProvider);
    _rooms = ref.read(conversationRoomsProvider.notifier);
    Future<void>.microtask(_beat);
    _timer = Timer.periodic(roomHeartbeatInterval, (_) => _beat());
  }

  Future<void> _beat() async {
    if (_ended) {
      return;
    }
    try {
      final room = await _api.presence(widget.room.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _hereNow = room.hereNow;
        _members = room.participantCount;
      });
      _rooms.updateRoom(room);
    } on RoomActionException catch (e) {
      if (!mounted || !e.endsVisit) {
        return;
      }
      _ended = true;
      _timer?.cancel();
      final messenger = ScaffoldMessenger.maybeOf(context);
      await Navigator.of(context).maybePop();
      messenger?.showSnackBar(SnackBar(content: Text(e.message)));
      unawaited(_rooms.loadRooms());
    } on Object {
      // A missed heartbeat only delays the count; the next one catches up.
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (!_ended) {
      unawaited(
        _api
            .presence(widget.room.id, away: true)
            .then<void>((_) {}, onError: (Object _) {}),
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final room = widget.room;
    final l = chatL10n(context);
    final here = l.roomsHereNow(_hereNow);
    final inRoom = l.roomsInTheRoom(_members);
    return Semantics(
      container: true,
      label: '${room.title}. $here. $inRoom.',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(bottom: BorderSide(color: colors.outlineVariant)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppLayout.space4,
            AppLayout.space3,
            AppLayout.space4,
            AppLayout.space3,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  roomIcon(room.iconKey),
                  size: 20,
                  color: colors.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: AppLayout.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (room.description.isNotEmpty)
                      Text(
                        room.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                    const SizedBox(height: AppLayout.space1),
                    Row(
                      children: [
                        LiveDot(active: _hereNow > 0),
                        const SizedBox(width: AppLayout.space2),
                        Flexible(
                          child: Text(
                            '$here · $inRoom',
                            key: const ValueKey('room.chat.presence'),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small dot: filled when people are here now.
class LiveDot extends StatelessWidget {
  const LiveDot({required this.active, super.key});
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dot = Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? colors.primary : Colors.transparent,
        border: Border.all(
          color: active ? colors.primary : colors.outline,
          width: 1.5,
        ),
      ),
    );
    // A live room breathes softly (still under reduced motion and Calm).
    return active ? CinematicGlowPulse(radius: 6, child: dot) : dot;
  }
}

class _RoomPeopleButton extends StatelessWidget {
  const _RoomPeopleButton({required this.room});
  final ConversationRoom room;

  @override
  Widget build(BuildContext context) => IconButton(
    key: const ValueKey('room.chat.people'),
    tooltip: chatL10n(context).roomsPeopleTooltip,
    icon: const Icon(Icons.people_alt_outlined),
    onPressed: () => showRoomMembersSheet(context, room),
  );
}

class _RoomMenuButton extends ConsumerWidget {
  const _RoomMenuButton({required this.room});
  final ConversationRoom room;

  Future<void> _leave(BuildContext context, WidgetRef ref) async {
    final l = chatL10n(context);
    final ok = await confirmCommunityAction(
      context,
      title: l.roomsLeaveTitle(room.title),
      message: l.roomsLeaveBody,
      action: l.roomsLeaveAction,
    );
    if (!ok || !context.mounted) {
      return;
    }
    try {
      await ref.read(conversationRoomsProvider.notifier).leaveRoom(room.id);
      if (context.mounted) {
        await Navigator.of(context).maybePop();
      }
    } on Object catch (e) {
      if (context.mounted) {
        showCommunitySnack(
          context,
          apiErrorMessage(e, fallback: l.roomsLeaveFailed),
        );
      }
    }
  }

  Future<void> _close(BuildContext context, WidgetRef ref) async {
    final l = chatL10n(context);
    final ok = await confirmCommunityAction(
      context,
      title: l.roomsCloseTitle(room.title),
      message: l.roomsCloseBody,
      action: l.roomsCloseAction,
    );
    if (!ok || !context.mounted) {
      return;
    }
    try {
      await ref.read(roomsApiProvider).moderate(room.id, action: 'close_room');
      unawaited(ref.read(conversationRoomsProvider.notifier).loadRooms());
      if (context.mounted) {
        await Navigator.of(context).maybePop();
      }
    } on Object catch (e) {
      if (context.mounted) {
        showCommunitySnack(
          context,
          apiErrorMessage(e, fallback: l.roomsCloseFailed),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = chatL10n(context);
    return PopupMenuButton<String>(
      key: const ValueKey('room.chat.menu'),
      tooltip: l.roomsMenuTooltip,
      onSelected: (choice) {
        switch (choice) {
          case 'people':
            showRoomMembersSheet(context, room);
          case 'moderate':
            showRoomMembersSheet(context, room, moderating: true);
          case 'leave':
            _leave(context, ref);
          case 'close':
            _close(context, ref);
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(value: 'people', child: Text(l.roomsMenuPeople)),
        if (room.canModerate)
          PopupMenuItem(value: 'moderate', child: Text(l.roomsMenuModerate)),
        PopupMenuItem(value: 'leave', child: Text(l.roomsLeaveAction)),
        if (room.isHost && !room.alwaysOn)
          PopupMenuItem(value: 'close', child: Text(l.roomsCloseAction)),
      ],
    );
  }
}

/// The people in a room: hosts first, then who is here now. Each row has
/// Add friend; tapping a row opens the member card.
Future<void> showRoomMembersSheet(
  BuildContext context,
  ConversationRoom room, {
  bool moderating = false,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (sheet) => FractionallySizedBox(
    heightFactor: 0.8,
    child: _RoomMembersSheet(room: room, moderating: moderating),
  ),
);

class _RoomMembersSheet extends ConsumerWidget {
  const _RoomMembersSheet({required this.room, required this.moderating});
  final ConversationRoom room;
  final bool moderating;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final members = ref.watch(roomMembersProvider(room.id));
    final l = chatL10n(context);
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppLayout.space5,
              0,
              AppLayout.space5,
              AppLayout.space2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    moderating
                        ? l.roomsModerateTitle(room.title)
                        : l.roomsMenuPeople,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: AppLayout.space1),
                Text(
                  moderating ? l.roomsModerateIntro : l.roomsPeopleIntro,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: members.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppLayout.space6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        apiErrorMessage(e, fallback: l.roomsMembersLoadFailed),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppLayout.space3),
                      FilledButton(
                        onPressed: () =>
                            ref.invalidate(roomMembersProvider(room.id)),
                        child: Text(l.chatTryAgain),
                      ),
                    ],
                  ),
                ),
              ),
              data: (list) => ListView.builder(
                key: const ValueKey('room.members.list'),
                padding: const EdgeInsets.only(bottom: AppLayout.space6),
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final m = list[i];
                  final role = roomRoleLabel(l, m.role);
                  final status = [
                    if (role.isNotEmpty) role,
                    if (m.friendStatus == 'friends') l.roomsStatusFriend,
                    if (m.hereNow)
                      l.roomsStatusHereNow
                    else
                      l.roomsStatusInRoom,
                    if (m.isMuted)
                      l.roomsStatusMutedUntil(chatWhen(context, m.mutedUntil!)),
                  ].join(' · ');
                  return ListTile(
                    key: ValueKey('room.member.${m.userId}'),
                    minTileHeight: AppLayout.minTapTarget + AppLayout.space4,
                    leading: RoomAvatar(
                      name: m.displayName,
                      photoUrl: m.photoUrl,
                      here: m.hereNow,
                    ),
                    title: Text(
                      m.isMe ? l.roomsYouSuffix(m.displayName) : m.displayName,
                    ),
                    subtitle: Text(status),
                    trailing: m.isMe
                        ? null
                        : AddFriendButton(
                            userId: m.userId,
                            name: m.displayName,
                            source: FriendRequestSource.room,
                            style: AddFriendStyle.icon,
                          ),
                    onTap: m.isMe
                        ? null
                        : () => showRoomMemberCard(
                            context,
                            room: room,
                            userId: m.userId,
                            name: m.displayName,
                            photoUrl: m.photoUrl,
                          ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RoomAvatar extends StatelessWidget {
  const RoomAvatar({
    required this.name,
    super.key,
    this.photoUrl = '',
    this.here = false,
    this.radius = 20,
  });
  final String name, photoUrl;
  final bool here;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final initial = name.trim().isEmpty
        ? '?'
        : name.trim().characters.first.toUpperCase();
    return ExcludeSemantics(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: radius,
            backgroundColor: colors.primaryContainer,
            foregroundImage: photoUrl.startsWith('http')
                ? NetworkImage(photoUrl)
                : null,
            child: Text(
              initial,
              style: TextStyle(color: colors.onPrimaryContainer),
            ),
          ),
          if (here)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: colors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.surface, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A member's card in a room: Add friend, report, block, and for hosts and
/// moderators Warn and Remove.
Future<void> showRoomMemberCard(
  BuildContext context, {
  required ConversationRoom room,
  required String userId,
  String name = '',
  String photoUrl = '',
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (sheet) => _RoomMemberCard(
    room: room,
    userId: userId,
    name: name,
    photoUrl: photoUrl,
  ),
);

class _RoomMemberCard extends ConsumerStatefulWidget {
  const _RoomMemberCard({
    required this.room,
    required this.userId,
    required this.name,
    required this.photoUrl,
  });
  final ConversationRoom room;
  final String userId, name, photoUrl;

  @override
  ConsumerState<_RoomMemberCard> createState() => _RoomMemberCardState();
}

class _RoomMemberCardState extends ConsumerState<_RoomMemberCard> {
  bool _busy = false;

  RoomMember? _member(List<RoomMember>? list) {
    for (final m in list ?? const <RoomMember>[]) {
      if (m.userId == widget.userId) {
        return m;
      }
    }
    return null;
  }

  /// Hosts act on moderators and participants; moderators only on
  /// participants; nobody on a host or themselves.
  bool _canModerate(RoomMember? target) {
    final room = widget.room;
    if (!room.canModerate || target == null || target.isMe) {
      return false;
    }
    if (target.role == 'host') {
      return false;
    }
    if (room.myRole == 'moderator' && target.role == 'moderator') {
      return false;
    }
    return true;
  }

  Future<void> _moderate(String action, String name) async {
    final l = chatL10n(context);
    final remove = action == 'remove_user';
    final ok = await confirmCommunityAction(
      context,
      title: remove ? l.roomsRemoveTitle(name) : l.roomsWarnTitle(name),
      message: remove
          ? (widget.room.alwaysOn
                ? l.roomsRemoveBodyAlwaysOn(name)
                : l.roomsRemoveBodyHosted(name))
          : l.roomsWarnBody(name),
      action: remove ? l.roomsRemoveAction : l.roomsWarnAction,
    );
    if (!ok || !mounted) {
      return;
    }
    await _send(
      action: action,
      done: remove ? l.roomsRemovedDone(name) : l.roomsWarnedDone(name),
    );
  }

  /// Mute: pick how long (10 minutes, an hour, or the rest of the session);
  /// muted members keep reading but can't post.
  Future<void> _mute(String name) async {
    final l = chatL10n(context);
    final alwaysOn = widget.room.alwaysOn;
    final duration = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheet) {
        final theme = Theme.of(sheet);
        ListTile option(String value, String label) => ListTile(
          key: ValueKey('room.mute.$value'),
          leading: const Icon(Icons.timer_outlined),
          title: Text(label),
          onTap: () => Navigator.pop(sheet, value),
        );
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppLayout.space6,
                    0,
                    AppLayout.space6,
                    AppLayout.space2,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          l.roomsMuteSheetTitle(name),
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(height: AppLayout.space1),
                      Text(
                        l.roomsMuteSheetBody(name),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                option('10m', l.roomsMuteTenMinutes),
                option('1h', l.roomsMuteOneHour),
                option(
                  'session',
                  alwaysOn ? l.roomsMuteOneDay : l.roomsMuteUntilEnd,
                ),
              ],
            ),
          ),
        );
      },
    );
    if (duration == null || !mounted) {
      return;
    }
    await _send(
      action: 'mute_user',
      duration: duration,
      done: l.roomsMutedDone(name),
    );
  }

  Future<void> _unmute(String name) => _send(
    action: 'unmute_user',
    done: chatL10n(context).roomsUnmutedDone(name),
  );

  Future<void> _send({
    required String action,
    required String done,
    String duration = '',
  }) async {
    final fallback = chatL10n(context).roomsModerationFailed;
    setState(() => _busy = true);
    try {
      await ref
          .read(roomsApiProvider)
          .moderate(
            widget.room.id,
            action: action,
            targetUserId: widget.userId,
            duration: duration,
          );
      ref.invalidate(roomMembersProvider(widget.room.id));
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      showCommunitySnack(context, done);
    } on Object catch (e) {
      if (mounted) {
        showCommunitySnack(context, apiErrorMessage(e, fallback: fallback));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _report(String name) async {
    await showReportUserSheet(
      context: context,
      onSubmit: ({required reason, description}) => ref
          .read(safetyActionsProvider)
          .reportUser(
            reportedUserId: widget.userId,
            reason: reason,
            description: [
              'Reported from the room "${widget.room.title}".',
              if (description != null && description.trim().isNotEmpty)
                description.trim(),
            ].join(' '),
          ),
    );
  }

  Future<void> _block(String name) async {
    final blocked = await blockCommunityMember(
      context,
      ref,
      userId: widget.userId,
      name: name,
    );
    if (!blocked || !mounted) {
      return;
    }
    ref.invalidate(roomMembersProvider(widget.room.id));
    final done = chatL10n(context).roomsBlockedDone(name);
    Navigator.of(context).pop();
    showCommunitySnack(context, done);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final members = ref.watch(roomMembersProvider(widget.room.id));
    final l = chatL10n(context);
    final member = _member(members.valueOrNull);
    final name = (member?.displayName.isNotEmpty ?? false)
        ? member!.displayName
        : (widget.name.trim().isEmpty ? l.chatMember : widget.name.trim());
    final photo = member?.photoUrl.isNotEmpty ?? false
        ? member!.photoUrl
        : widget.photoUrl;
    final role = roomRoleLabel(l, member?.role ?? '');
    final muted = member?.isMuted ?? false;
    final status = [
      if (role.isNotEmpty) role,
      if (member != null)
        member.hereNow ? l.roomsStatusHereNow : l.roomsStatusInRoom,
      if (member == null && members.hasValue) l.roomsStatusGone,
      if (muted)
        l.roomsStatusMutedUntil(chatWhen(context, member!.mutedUntil!)),
    ].join(' · ');
    final isMe = member?.isMe ?? false;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppLayout.space5,
          0,
          AppLayout.space5,
          AppLayout.space5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                RoomAvatar(
                  name: name,
                  photoUrl: photo,
                  here: member?.hereNow ?? false,
                  radius: 28,
                ),
                const SizedBox(width: AppLayout.space4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(name, style: theme.textTheme.titleLarge),
                      ),
                      if (status.isNotEmpty)
                        Text(
                          status,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (!isMe) ...[
              const SizedBox(height: AppLayout.space4),
              AddFriendButton(
                userId: widget.userId,
                name: name,
                source: FriendRequestSource.room,
              ),
              const SizedBox(height: AppLayout.space2),
              Wrap(
                spacing: AppLayout.space2,
                runSpacing: AppLayout.space2,
                children: [
                  TextButton.icon(
                    key: const ValueKey('room.member.report'),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, AppLayout.minTapTarget),
                    ),
                    onPressed: _busy ? null : () => _report(name),
                    icon: const Icon(Icons.flag_outlined),
                    label: Text(l.roomsReport),
                  ),
                  TextButton.icon(
                    key: const ValueKey('room.member.block'),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, AppLayout.minTapTarget),
                    ),
                    onPressed: _busy ? null : () => _block(name),
                    icon: const Icon(Icons.block_rounded),
                    label: Text(l.roomsBlock),
                  ),
                ],
              ),
            ],
            if (_canModerate(member)) ...[
              const SizedBox(height: AppLayout.space3),
              const Divider(height: 1),
              const SizedBox(height: AppLayout.space3),
              Text(
                l.roomsModerateEyebrow,
                style: theme.textTheme.labelMedium?.copyWith(
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: AppLayout.space2),
              Wrap(
                spacing: AppLayout.space2,
                runSpacing: AppLayout.space2,
                children: [
                  OutlinedButton.icon(
                    key: const ValueKey('room.member.warn'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, AppLayout.minTapTarget),
                    ),
                    onPressed: _busy
                        ? null
                        : () => _moderate('warn_user', name),
                    icon: const Icon(Icons.campaign_outlined),
                    label: Text(l.roomsWarn),
                  ),
                  if (muted)
                    OutlinedButton.icon(
                      key: const ValueKey('room.member.unmute'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, AppLayout.minTapTarget),
                      ),
                      onPressed: _busy ? null : () => _unmute(name),
                      icon: const Icon(Icons.volume_up_outlined),
                      label: Text(l.roomsUnmute),
                    )
                  else
                    OutlinedButton.icon(
                      key: const ValueKey('room.member.mute'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, AppLayout.minTapTarget),
                      ),
                      onPressed: _busy ? null : () => _mute(name),
                      icon: const Icon(Icons.volume_off_outlined),
                      label: Text(l.roomsMute),
                    ),
                  OutlinedButton.icon(
                    key: const ValueKey('room.member.remove'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, AppLayout.minTapTarget),
                      foregroundColor: colors.error,
                    ),
                    onPressed: _busy
                        ? null
                        : () => _moderate('remove_user', name),
                    icon: const Icon(Icons.person_remove_outlined),
                    label: Text(l.roomsRemoveFromRoom),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
