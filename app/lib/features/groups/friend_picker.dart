import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_error_message.dart';
import 'group_launch.dart';
import 'group_widgets.dart';
import 'groups_data.dart';

/// Multi-selects friends. With [groupId], friends already in the group or
/// already invited are shown but cannot be picked. Returns the chosen friends,
/// or null when dismissed.
Future<List<GroupInvitee>?> pickGroupFriends(
  BuildContext context, {
  String groupId = '',
  List<GroupInvitee> selected = const [],
  String title = 'Choose friends',
  String confirmLabel = 'Done',
}) => showGroupSheet<List<GroupInvitee>>(
  context,
  GroupFriendPicker(
    groupId: groupId,
    initial: selected,
    title: title,
    confirmLabel: confirmLabel,
  ),
);

class GroupFriendPicker extends ConsumerStatefulWidget {
  const GroupFriendPicker({
    super.key,
    this.groupId = '',
    this.initial = const [],
    this.title = 'Choose friends',
    this.confirmLabel = 'Done',
  });
  final String groupId;
  final List<GroupInvitee> initial;
  final String title;
  final String confirmLabel;

  @override
  ConsumerState<GroupFriendPicker> createState() => _GroupFriendPickerState();
}

class _GroupFriendPickerState extends ConsumerState<GroupFriendPicker> {
  late final Map<String, GroupInvitee> chosen = {
    for (final f in widget.initial) f.userId: f,
  };
  String filter = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final friends = ref.watch(groupFriendsProvider(widget.groupId));
    return GroupSheetFrame(
      title: widget.title,
      subtitle: 'Only friends you’re connected with can be invited.',
      footer: FilledButton(
        onPressed: () => Navigator.of(context).pop(chosen.values.toList()),
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        child: Text(
          chosen.isEmpty
              ? widget.confirmLabel
              : '${widget.confirmLabel} (${chosen.length})',
        ),
      ),
      children: [
        TextField(
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search_rounded),
            labelText: 'Search friends',
          ),
          onChanged: (value) =>
              setState(() => filter = value.trim().toLowerCase()),
        ),
        const SizedBox(height: 12),
        friends.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => GroupNotice(
            icon: Icons.cloud_off_outlined,
            title: 'Friends could not load',
            message: apiErrorMessage(e, fallback: 'Please try again.'),
            actionLabel: 'Try again',
            onAction: () =>
                ref.invalidate(groupFriendsProvider(widget.groupId)),
          ),
          data: (list) {
            if (list.isEmpty) {
              return const GroupNotice(
                icon: Icons.people_outline_rounded,
                title: 'No friends yet',
                message:
                    'Add friends from Matches, profiles or rooms, then bring '
                    'them into a group.',
              );
            }
            final shown = [
              for (final f in list)
                if (filter.isEmpty || f.name.toLowerCase().contains(filter)) f,
            ];
            return Column(
              children: [
                for (final f in shown)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.trailing,
                    secondary: GroupAvatar(name: f.name, photoUrl: f.photoUrl),
                    title: Text(f.name.isEmpty ? 'Friend' : f.name),
                    subtitle: f.available
                        ? null
                        : Text(
                            f.status == 'member'
                                ? 'Already in this group'
                                : 'Invitation sent',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                    value: !f.available || chosen.containsKey(f.userId),
                    onChanged: f.available
                        ? (on) => setState(() {
                            if (on ?? false) {
                              chosen[f.userId] = (
                                userId: f.userId,
                                name: f.name,
                                photoUrl: f.photoUrl,
                              );
                            } else {
                              chosen.remove(f.userId);
                            }
                          })
                        : null,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
