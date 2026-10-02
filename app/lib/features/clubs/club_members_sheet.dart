import 'package:flutter/material.dart' hide Title;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_error_message.dart';
import '../../core/providers/api_client_provider.dart';
import '../../l10n/app_localizations.dart';
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

  List<(String, String)> actionsFor(
    AppLocalizations l10n,
    ClubMember member,
    String? me,
  ) {
    final club = widget.club;
    if (member.userId == me || member.role == 'owner') {
      return const [];
    }
    return [
      if (club.isOwner && member.role == 'member')
        ('make_moderator', l10n.clubsMakeModerator),
      if (club.isOwner && member.role == 'moderator')
        ('make_member', l10n.clubsMakeMember),
      if (club.isOwner || (club.canModerate && member.role == 'member'))
        ('remove', l10n.clubsRemoveFromClub),
    ];
  }

  Future<void> act(ClubMember member, String action) async {
    final l10n = AppLocalizations.of(context);
    if (action == 'remove' &&
        !await confirmCommunityAction(
          context,
          title: l10n.clubsRemoveMemberTitle(member.name),
          message: l10n.clubsRemoveMemberMessage,
          action: l10n.clubsRemove,
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
          apiErrorMessage(e, fallback: l10n.clubsChangeNotSaved),
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
    final l10n = AppLocalizations.of(context);
    return SheetFrame(
      title: l10n.clubsMembers,
      children: [
        if (busy) const LinearProgressIndicator(),
        ref
            .watch(clubMembersProvider(widget.club.id))
            .when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text(
                apiErrorMessage(e, fallback: l10n.clubsMembersLoadError),
              ),
              data: (members) => Column(
                children: [
                  for (final member in members)
                    Builder(
                      builder: (context) {
                        final actions = actionsFor(l10n, member, me);
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
                                ? l10n.clubsMemberYou(member.name)
                                : member.name,
                          ),
                          subtitle: Text(
                            clubRoleLabel(l10n, member.role),
                            style: text.bodyMedium,
                          ),
                          trailing: actions.isEmpty
                              ? null
                              : PopupMenuButton<String>(
                                  tooltip: l10n.clubsMemberActions(member.name),
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
