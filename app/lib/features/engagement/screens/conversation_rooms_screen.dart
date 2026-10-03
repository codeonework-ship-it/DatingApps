import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/app_layout.dart';
import '../../../core/widgets/connect_page.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../common/widgets/community_actions.dart';
import '../../social_chat/social_chat_l10n.dart';
import '../providers/conversation_rooms_provider.dart';
import 'room_chat.dart';

/// Rooms: live chat rooms in the Today look. Always-on topic rooms anyone can
/// drop into, rooms members host, and the rooms you are in. Tapping a room
/// joins it and opens its chat; from there people add each other as friends.
class ConversationRoomsScreen extends ConsumerStatefulWidget {
  const ConversationRoomsScreen({super.key});

  @override
  ConsumerState<ConversationRoomsScreen> createState() =>
      _ConversationRoomsScreenState();
}

class _ConversationRoomsScreenState
    extends ConsumerState<ConversationRoomsScreen> {
  String _entering = '';

  Future<void> _enter(ConversationRoom room) async {
    if (_entering.isNotEmpty) {
      return;
    }
    final l = chatL10n(context);
    if (room.isClosed) {
      showCommunitySnack(context, l.roomsClosedSnack);
      return;
    }
    setState(() => _entering = room.id);
    try {
      final joined = await ref
          .read(conversationRoomsProvider.notifier)
          .joinRoom(room.id);
      if (!mounted) {
        return;
      }
      if (joined.channelId.isEmpty) {
        showCommunitySnack(context, l.roomsChatNotOpen);
        return;
      }
      await openRoomChat(context, joined);
      if (mounted) {
        await ref.read(conversationRoomsProvider.notifier).loadRooms();
      }
    } on RoomActionException catch (e) {
      if (mounted) {
        showCommunitySnack(context, e.message);
      }
    } on Object {
      if (mounted) {
        showCommunitySnack(context, l.roomsJoinFailed);
      }
    } finally {
      if (mounted) {
        setState(() => _entering = '');
      }
    }
  }

  Future<void> _startRoom() async {
    final room = await showModalBottomSheet<ConversationRoom>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _StartRoomSheet(),
    );
    if (room != null && mounted && room.channelId.isNotEmpty) {
      await openRoomChat(context, room);
      if (mounted) {
        await ref.read(conversationRoomsProvider.notifier).loadRooms();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(conversationRoomsProvider);
    final notifier = ref.read(conversationRoomsProvider.notifier);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l = chatL10n(context);
    // A refresh that fails while rooms are on screen keeps them, and says so
    // (an empty list shows the error in place instead).
    ref.listen<String?>(conversationRoomsProvider.select((s) => s.error), (
      previous,
      next,
    ) {
      if (next != null &&
          next != previous &&
          ref.read(conversationRoomsProvider).rooms.isNotEmpty) {
        showCommunitySnack(context, next);
      }
    });
    final hereTotal = state.rooms.fold<int>(0, (n, r) => n + r.hereNow);
    final liveRooms = state.liveNow;
    final joinedIds = {for (final r in state.joined) r.id};

    List<Widget> section(
      String label,
      List<Widget> children, {
      String? title,
      String? caption,
    }) => [
      const SizedBox(height: ConnectMetrics.sectionGap),
      ConnectSectionHeader(label: label, title: title, caption: caption),
      const SizedBox(height: ConnectMetrics.cardGap),
      for (final child in children)
        Padding(
          padding: const EdgeInsets.only(bottom: ConnectMetrics.cardGap),
          child: child,
        ),
    ];

    Widget tile(ConversationRoom room) => _RoomTile(
      room: room,
      busy: _entering == room.id,
      onTap: () => _enter(room),
    );

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('rooms.start'),
        onPressed: _startRoom,
        icon: const Icon(Icons.add_comment_outlined),
        label: Text(l.roomsStartRoom),
      ),
      body: PostLoginBackdrop(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, box) {
              final gutter = ConnectMetrics.gutterFor(box.maxWidth);
              return RefreshIndicator(
                onRefresh: notifier.loadRooms,
                child: ListView(
                  key: const ValueKey('rooms.list'),
                  padding: EdgeInsets.fromLTRB(gutter, 12, gutter, 120),
                  children: [
                    ConnectPageHeader(
                      eyebrow: l.roomsEyebrow,
                      title: l.roomsTitle,
                      subtitle: l.roomsSubtitle,
                      leading: Navigator.of(context).canPop()
                          ? IconButton(
                              key: const ValueKey('qa.rooms.back'),
                              tooltip: MaterialLocalizations.of(
                                context,
                              ).backButtonTooltip,
                              icon: const Icon(Icons.arrow_back_rounded),
                              onPressed: () => Navigator.of(context).maybePop(),
                            )
                          : null,
                    ),
                    if (state.rooms.isNotEmpty) ...[
                      const SizedBox(height: AppLayout.space3),
                      Row(
                        children: [
                          LiveDot(active: hereTotal > 0),
                          const SizedBox(width: AppLayout.space2),
                          Expanded(
                            child: Text(
                              _presenceSummary(l, hereTotal, liveRooms.length),
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (state.isLoading && state.rooms.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    if (state.error != null && state.rooms.isEmpty)
                      ...section(l.roomsSectionRooms, [
                        ConnectPanel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                state.error!,
                                style: theme.textTheme.bodyLarge,
                              ),
                              const SizedBox(height: AppLayout.space3),
                              FilledButton(
                                key: const ValueKey('qa.rooms.retry'),
                                onPressed: notifier.loadRooms,
                                child: Text(l.chatTryAgain),
                              ),
                            ],
                          ),
                        ),
                      ]),
                    if (state.joined.isNotEmpty)
                      ...section(l.roomsSectionYours, [
                        for (final r in state.joined) tile(r),
                      ], caption: l.roomsYoursCaption),
                    if (liveRooms.isNotEmpty)
                      ...section(l.roomsSectionLive, [
                        for (final r in liveRooms.where(
                          (r) => !joinedIds.contains(r.id),
                        ))
                          tile(r),
                      ], title: l.roomsLiveTitle),
                    if (state.rooms.isNotEmpty) ...[
                      ...section(
                        l.roomsSectionBrowse,
                        [],
                        title: l.roomsBrowseTitle,
                        caption: l.roomsBrowseCaption,
                      ),
                      _CategoryChips(
                        selected: state.category,
                        friendOnly: state.friendOnly,
                        onCategory: notifier.setCategory,
                        onFriendOnly: (on) => notifier.setFriendOnly(value: on),
                      ),
                      const SizedBox(height: ConnectMetrics.cardGap),
                      if (state.browsable.isEmpty)
                        ConnectPanel(
                          child: Text(
                            state.friendOnly
                                ? l.roomsNoFriendsHere
                                : l.roomsNoRoomsInTopic,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      for (final r in state.browsable)
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: ConnectMetrics.cardGap,
                          ),
                          child: tile(r),
                        ),
                    ],
                    if (state.upcoming.isNotEmpty)
                      ...section(l.roomsSectionComingUp, [
                        for (final r in state.upcoming) tile(r),
                      ], caption: l.roomsComingUpCaption),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.selected,
    required this.friendOnly,
    required this.onCategory,
    required this.onFriendOnly,
  });
  final String selected;
  final bool friendOnly;
  final ValueChanged<String> onCategory;
  final ValueChanged<bool> onFriendOnly;

  @override
  Widget build(BuildContext context) {
    final l = chatL10n(context);
    return Wrap(
      spacing: AppLayout.space2,
      runSpacing: AppLayout.space2,
      children: [
        ChoiceChip(
          key: const ValueKey('rooms.category.all'),
          label: Text(l.roomsCategoryAll),
          selected: selected.isEmpty,
          onSelected: (_) => onCategory(''),
        ),
        for (final key in roomCategories)
          ChoiceChip(
            key: ValueKey('rooms.category.$key'),
            label: Text(roomCategoryLabel(l, key)),
            selected: selected == key,
            onSelected: (_) => onCategory(key),
          ),
        FilterChip(
          key: const ValueKey('rooms.friends_here'),
          avatar: const Icon(Icons.people_alt_outlined, size: 18),
          label: Text(l.roomsFriendsHereChip),
          selected: friendOnly,
          onSelected: onFriendOnly,
        ),
      ],
    );
  }
}

String _presenceSummary(AppLocalizations l, int here, int rooms) => here == 0
    ? l.roomsQuiet
    : l.roomsChattingIn(l.roomsPeopleCount(here), l.roomsRoomCount(rooms));

String _startsLabel(BuildContext context, DateTime at) {
  final l = chatL10n(context);
  final now = DateTime.now();
  final time = TimeOfDay.fromDateTime(at).format(context);
  final sameDay =
      at.year == now.year && at.month == now.month && at.day == now.day;
  if (sameDay) {
    return l.roomsStartsAt(time);
  }
  return l.roomsStartsOn(
    MaterialLocalizations.of(context).formatMediumDate(at),
    time,
  );
}

class _RoomTile extends StatelessWidget {
  const _RoomTile({
    required this.room,
    required this.onTap,
    required this.busy,
  });
  final ConversationRoom room;
  final VoidCallback onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final radius = BorderRadius.circular(ConnectMetrics.cardRadius);
    final l = chatL10n(context);
    final facts = <String>[
      if (room.lifecycleState == 'scheduled' && room.startsAt != null)
        _startsLabel(context, room.startsAt!)
      else
        l.roomsHereNow(room.hereNow),
      l.roomsInTheRoom(room.participantCount),
      if (room.friendsHere > 0) l.roomsFriendsHere(room.friendsHere),
      if (room.roomType == 'member' && room.hostName.isNotEmpty)
        room.isHost ? l.roomsHostedByYou : l.roomsHostedBy(room.hostName),
    ];
    final action = room.isParticipant
        ? l.roomsActionOpen
        : room.isFull
        ? l.roomsActionFull
        : l.roomsActionJoin;
    return Semantics(
      button: true,
      label:
          '${room.title}. ${room.description}. ${facts.join('. ')}. '
          '$action.',
      excludeSemantics: true,
      onTap: busy ? null : onTap,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: radius,
            border: Border.all(
              color: room.isParticipant
                  ? colors.primary
                  : colors.outlineVariant,
            ),
          ),
          child: InkWell(
            key: ValueKey('rooms.tile.${room.id}'),
            borderRadius: radius,
            onTap: busy ? null : onTap,
            child: Padding(
              padding: const EdgeInsets.all(ConnectMetrics.padding),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      roomIcon(room.iconKey),
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: AppLayout.space4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          room.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.onSurface,
                          ),
                        ),
                        if (room.description.isNotEmpty) ...[
                          const SizedBox(height: AppLayout.space1),
                          Text(
                            room.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppLayout.space2),
                        Row(
                          children: [
                            LiveDot(active: room.isLive && room.hereNow > 0),
                            const SizedBox(width: AppLayout.space2),
                            Expanded(
                              child: Text(
                                facts.join(' · '),
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
                  const SizedBox(width: AppLayout.space2),
                  if (busy)
                    const SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Text(
                      action,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Start a room you host: a name, a line about it, a topic and how long.
class _StartRoomSheet extends ConsumerStatefulWidget {
  const _StartRoomSheet();

  @override
  ConsumerState<_StartRoomSheet> createState() => _StartRoomSheetState();
}

class _StartRoomSheetState extends ConsumerState<_StartRoomSheet> {
  final _title = TextEditingController();
  final _about = TextEditingController();
  String _category = 'talk';
  int _minutes = 60;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _about.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_title.text.trim().length < 3) {
      setState(() => _error = chatL10n(context).roomsStartNameTooShort);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final room = await ref
          .read(conversationRoomsProvider.notifier)
          .createRoom(
            title: _title.text,
            description: _about.text,
            category: _category,
            durationMinutes: _minutes,
          );
      if (mounted) {
        Navigator.of(context).pop(room);
      }
    } on RoomActionException catch (e) {
      if (mounted) {
        setState(() => _error = e.message);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l = chatL10n(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppLayout.space5,
          0,
          AppLayout.space5,
          MediaQuery.viewInsetsOf(context).bottom + AppLayout.space5,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  l.roomsStartRoom,
                  style: theme.textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: AppLayout.space1),
              Text(
                l.roomsStartIntro,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppLayout.space4),
              TextField(
                key: const ValueKey('rooms.start.title'),
                controller: _title,
                maxLength: 60,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l.roomsStartNameLabel,
                  hintText: l.roomsStartNameHint,
                ),
              ),
              TextField(
                key: const ValueKey('rooms.start.about'),
                controller: _about,
                maxLength: 280,
                minLines: 1,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: l.roomsStartAboutLabel),
              ),
              const SizedBox(height: AppLayout.space2),
              Text(l.roomsStartTopic, style: theme.textTheme.labelLarge),
              const SizedBox(height: AppLayout.space2),
              Wrap(
                spacing: AppLayout.space2,
                runSpacing: AppLayout.space2,
                children: [
                  for (final key in roomCategories)
                    ChoiceChip(
                      key: ValueKey('qa.rooms.start.category.$key'),
                      label: Text(roomCategoryLabel(l, key)),
                      selected: _category == key,
                      onSelected: (_) => setState(() => _category = key),
                    ),
                ],
              ),
              const SizedBox(height: AppLayout.space4),
              Text(l.roomsStartHowLong, style: theme.textTheme.labelLarge),
              const SizedBox(height: AppLayout.space2),
              SegmentedButton<int>(
                key: const ValueKey('qa.rooms.start.length'),
                segments: [
                  ButtonSegment(value: 30, label: Text(l.roomsLength30Min)),
                  ButtonSegment(value: 60, label: Text(l.roomsLength1Hour)),
                  ButtonSegment(value: 120, label: Text(l.roomsLength2Hours)),
                ],
                selected: {_minutes},
                onSelectionChanged: (v) => setState(() => _minutes = v.first),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppLayout.space3),
                Text(
                  _error!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.error,
                  ),
                ),
              ],
              const SizedBox(height: AppLayout.space5),
              FilledButton(
                key: const ValueKey('rooms.start.submit'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(AppLayout.minTapTarget),
                ),
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l.roomsStartNow),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
