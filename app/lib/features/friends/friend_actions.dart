import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/layout/app_layout.dart';
import '../../core/network/api_error_message.dart';
import '../../core/providers/api_client_provider.dart';
import '../auth/providers/auth_provider.dart';
import '../social_chat/social_chat_data.dart';
import '../social_chat/social_chat_screen.dart';
import 'providers/friends_provider.dart';

/// Where a friend request started. Sent to the server so the friendship can
/// say "met in a room", and so each entry point can be measured.
enum FriendRequestSource { search, match, profile, room, group }

/// Sends a friend request to [userId] from [source].
///
/// Shared entry point for every "Add friend" action (Matches, profiles,
/// Conversation Rooms, groups). The Friends feature owns this file and may
/// extend it; callers in other features depend only on this function, the
/// enum above and [AddFriendButton].
///
/// If [userId] already asked to be friends, this accepts their request. An
/// accepted friendship is never downgraded. Throws when the server refuses
/// (blocked, 7-day cooldown after a decline, 30 requests a day).
Future<void> sendFriendRequest(
  WidgetRef ref,
  String userId, {
  required FriendRequestSource source,
}) async {
  final me = ref.read(authNotifierProvider).userId;
  if (me == null) {
    throw StateError('Sign in to add friends.');
  }
  await ref.read(friendsProvider.notifier).request(userId, source: source);
}

/// Where I stand with another member.
enum FriendRelation { none, outgoing, incoming, friends }

/// My relationship with a member, from my friends and requests.
final friendRelationProvider = Provider.autoDispose
    .family<FriendRelation, String>((ref, userId) {
      final connection = ref.watch(
        friendsProvider.select((s) => s.connectionWith(userId)),
      );
      if (connection == null) {
        return FriendRelation.none;
      }
      if (connection.isAccepted) {
        return FriendRelation.friends;
      }
      return connection.isIncoming
          ? FriendRelation.incoming
          : FriendRelation.outgoing;
    });

/// Opens (or creates) the conversation with an accepted friend.
Future<void> openFriendChat(
  BuildContext context,
  WidgetRef ref, {
  required String friendId,
  required String name,
}) async {
  try {
    final channel = await openFriendChannel(
      ref.read(apiClientProvider),
      friendId,
    );
    if (!context.mounted) {
      return;
    }
    await openSocialChat(
      context,
      channelId: channel.id,
      title: channel.title.isNotEmpty ? channel.title : name,
      subtitle: 'Friend',
      emptyText: 'Say hello. Only the two of you can see this conversation.',
    );
    ref.invalidate(socialChannelsProvider);
  } on Object catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            apiErrorMessage(e, fallback: 'Could not open the chat. Retry.'),
          ),
        ),
      );
    }
  }
}

/// How an [AddFriendButton] is drawn.
enum AddFriendStyle {
  /// A compact tonal button for member rows and cards.
  button,

  /// An icon button for app bars.
  icon,

  /// A list tile for option sheets.
  tile,
}

/// A status-aware friend action for another member: Add friend, Requested
/// (tap to cancel), Accept, or Message once you are friends. Drop it into
/// member lists (rooms, groups), sheets and profiles. Hidden for yourself.
class AddFriendButton extends ConsumerStatefulWidget {
  const AddFriendButton({
    required this.userId,
    required this.source,
    super.key,
    this.name = '',
    this.style = AddFriendStyle.button,
  });

  final String userId;
  final FriendRequestSource source;

  /// The member's name, for messages and the chat title.
  final String name;
  final AddFriendStyle style;

  @override
  ConsumerState<AddFriendButton> createState() => _AddFriendButtonState();
}

class _AddFriendButtonState extends ConsumerState<AddFriendButton> {
  bool _busy = false;

  String get _who => widget.name.trim().isEmpty ? 'this member' : widget.name;

  void _snack(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _run(FriendRelation relation) async {
    if (_busy) {
      return;
    }
    if (relation == FriendRelation.friends) {
      await openFriendChat(
        context,
        ref,
        friendId: widget.userId,
        name: widget.name,
      );
      return;
    }
    if (relation == FriendRelation.outgoing) {
      final cancel = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: const Text('Cancel your friend request?'),
          content: Text('$_who won’t see your request any more.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: const Text('Keep it'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialog, true),
              child: const Text('Cancel request'),
            ),
          ],
        ),
      );
      if (cancel != true) {
        return;
      }
    }
    setState(() => _busy = true);
    final notifier = ref.read(friendsProvider.notifier);
    try {
      switch (relation) {
        case FriendRelation.none:
          final result = await notifier.request(
            widget.userId,
            source: widget.source,
          );
          _snack(
            result?.isAccepted ?? false
                ? 'You and $_who are now friends.'
                : 'Friend request sent to $_who.',
          );
        case FriendRelation.incoming:
          await notifier.decideFriendRequest(widget.userId, accept: true);
          final error = ref.read(friendsProvider).error;
          _snack(error ?? 'You and $_who are now friends.');
        case FriendRelation.outgoing:
          await notifier.removeFriend(widget.userId);
          _snack(ref.read(friendsProvider).error ?? 'Request cancelled.');
        case FriendRelation.friends:
          break;
      }
    } on Object catch (e) {
      _snack(apiErrorMessage(e, fallback: 'Could not send the request.'));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(authNotifierProvider.select((s) => s.userId));
    if (widget.userId.isEmpty || widget.userId == me) {
      return const SizedBox.shrink();
    }
    final relation = ref.watch(friendRelationProvider(widget.userId));
    final (label, icon, caption) = switch (relation) {
      FriendRelation.none => (
        'Add friend',
        Icons.person_add_alt_1_outlined,
        'Friends can message and plan things together',
      ),
      FriendRelation.outgoing => (
        'Requested',
        Icons.schedule_rounded,
        'Waiting for $_who. Tap to cancel.',
      ),
      FriendRelation.incoming => (
        'Accept friend',
        Icons.how_to_reg_outlined,
        '$_who asked to be friends',
      ),
      FriendRelation.friends => (
        'Message',
        Icons.chat_bubble_outline_rounded,
        'You’re friends. Open your chat.',
      ),
    };
    final key = ValueKey('qa.add_friend.${widget.userId}');
    final onPressed = _busy ? null : () => _run(relation);
    final colors = Theme.of(context).colorScheme;
    const busyIndicator = SizedBox.square(
      dimension: 20,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
    switch (widget.style) {
      case AddFriendStyle.icon:
        return IconButton(
          key: key,
          tooltip: label,
          onPressed: onPressed,
          icon: _busy ? busyIndicator : Icon(icon),
        );
      case AddFriendStyle.tile:
        return ListTile(
          key: key,
          enabled: !_busy,
          leading: _busy ? busyIndicator : Icon(icon, color: colors.primary),
          title: Text(label),
          subtitle: Text(caption),
          onTap: onPressed,
        );
      case AddFriendStyle.button:
        final child = _busy ? busyIndicator : Icon(icon, size: 18);
        const style = ButtonStyle(
          minimumSize: WidgetStatePropertyAll(Size(0, AppLayout.minTapTarget)),
          padding: WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: AppLayout.space3),
          ),
          visualDensity: VisualDensity.compact,
        );
        return switch (relation) {
          FriendRelation.outgoing => OutlinedButton.icon(
            key: key,
            style: style,
            onPressed: onPressed,
            icon: child,
            label: Text(label),
          ),
          _ => FilledButton.tonalIcon(
            key: key,
            style: style,
            onPressed: onPressed,
            icon: child,
            label: Text(label),
          ),
        };
    }
  }
}
