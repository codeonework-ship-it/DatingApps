import 'package:flutter/material.dart' hide Title;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_error_message.dart';
import '../../core/providers/api_client_provider.dart';
import '../auth/providers/auth_provider.dart';
import '../common/widgets/community_actions.dart';
import 'club_widgets.dart';
import 'clubs_data.dart';

/// The member list, visible to members only. Owners promote and demote;
/// owners and moderators remove members.
Future<void> showClubMembersSheet(BuildContext context, Club club) =>
    showClubSheet<void>(context, _MembersSheet(club: club));

class _MembersSheet extends ConsumerStatefulWidget {
  const _MembersSheet({required this.club});
  final Club club;

  @override
  ConsumerState<_MembersSheet> createState() => _MembersSheetState();
}

class _MembersSheetState extends ConsumerState<_MembersSheet> {
  bool busy = false;

  List<(String, String)> actionsFor(ClubMember member, String? me) {
    final club = widget.club;
    if (member.userId == me || member.role == 'owner') {
      return const [];
    }
    return [
      if (club.isOwner && member.role == 'member')
        ('make_moderator', 'Make moderator'),
      if (club.isOwner && member.role == 'moderator')
        ('make_member', 'Make member'),
      if (club.isOwner || (club.canModerate && member.role == 'member'))
        ('remove', 'Remove from club'),
    ];
  }

  Future<void> act(ClubMember member, String action) async {
    if (action == 'remove' &&
        !await confirmCommunityAction(
          context,
          title: 'Remove ${member.name}?',
          message:
              'They leave the club and cannot rejoin. Their past posts stay '
              'in the discussion.',
          action: 'Remove',
        )) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() => busy = true);
    try {
      await ref
          .read(apiClientProvider)
          .post<dynamic>(
            '/clubs/${widget.club.id}/members/${member.userId}',
            data: {'action': action},
          );
      ref
        ..invalidate(clubMembersProvider(widget.club.id))
        ..invalidate(clubDetailProvider(widget.club.id))
        ..invalidate(clubsProvider);
    } on Object catch (e) {
      if (mounted) {
        showCommunitySnack(
          context,
          apiErrorMessage(e, fallback: 'That change could not be saved.'),
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
    final me = ref.watch(authNotifierProvider.select((s) => s.userId));
    final text = Theme.of(context).textTheme;
    return SheetFrame(
      title: 'Members',
      children: [
        if (busy) const LinearProgressIndicator(),
        ref
            .watch(clubMembersProvider(widget.club.id))
            .when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) =>
                  Text(apiErrorMessage(e, fallback: 'Members could not load.')),
              data: (members) => Column(
                children: [
                  for (final member in members)
                    Builder(
                      builder: (context) {
                        final actions = actionsFor(member, me);
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            child: Text(
                              member.name.isEmpty
                                  ? '?'
                                  : member.name.characters.first.toUpperCase(),
                            ),
                          ),
                          title: Text(
                            member.userId == me
                                ? '${member.name} (you)'
                                : member.name,
                          ),
                          subtitle: Text(
                            clubRoles[member.role] ?? 'Member',
                            style: text.bodyMedium,
                          ),
                          trailing: actions.isEmpty
                              ? null
                              : PopupMenuButton<String>(
                                  tooltip: 'Actions for ${member.name}',
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
