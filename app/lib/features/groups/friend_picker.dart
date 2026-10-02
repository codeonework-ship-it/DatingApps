import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_error_message.dart';
import '../../l10n/app_localizations.dart';
import 'group_launch.dart';
import 'group_widgets.dart';
import 'groups_data.dart';

/// Multi-selects friends. With [groupId], friends already in the group or
/// already invited are shown but cannot be picked. Returns the chosen friends,
/// or null when dismissed. [title] defaults to "Choose friends" and
/// [confirmLabel] to "Done".
Future<List<GroupInvitee>?> pickGroupFriends(
  BuildContext context, {
  String groupId = '',
  List<GroupInvitee> selected = const [],
  String? title,
  String? confirmLabel,
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
    this.title,
    this.confirmLabel,
  });
  final String groupId;
  final List<GroupInvitee> initial;

  /// Defaults to "Choose friends".
  final String? title;

  /// Defaults to "Done".
  final String? confirmLabel;

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
    final l10n = AppLocalizations.of(context);
    final friends = ref.watch(groupFriendsProvider(widget.groupId));
    final confirmLabel = widget.confirmLabel ?? l10n.groupsDone;
    return GroupSheetFrame(
      title: widget.title ?? l10n.groupsChooseFriends,
      subtitle: l10n.groupsPickerSubtitle,
      footer: FilledButton(
        onPressed: () => Navigator.of(context).pop(chosen.values.toList()),
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        child: Text(
          chosen.isEmpty ? confirmLabel : '$confirmLabel (${chosen.length})',
        ),
      ),
      children: [
        TextField(
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search_rounded),
            labelText: l10n.groupsSearchFriends,
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
            title: l10n.groupsFriendsFailed,
            message: apiErrorMessage(e, fallback: l10n.groupsPleaseTryAgain),
            actionLabel: l10n.chatTryAgain,
            onAction: () =>
                ref.invalidate(groupFriendsProvider(widget.groupId)),
          ),
          data: (list) {
            if (list.isEmpty) {
              return GroupNotice(
                icon: Icons.people_outline_rounded,
                title: l10n.groupsNoFriendsTitle,
                message: l10n.groupsNoFriendsBody,
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
                    title: Text(
                      f.name.isEmpty ? l10n.groupsFriendFallback : f.name,
                    ),
                    subtitle: f.available
                        ? null
                        : Text(
                            f.status == 'member'
                                ? l10n.groupsAlreadyMember
                                : l10n.groupsInvitationSent,
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
