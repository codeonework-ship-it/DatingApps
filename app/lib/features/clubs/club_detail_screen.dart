import 'package:flutter/material.dart' hide Title;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_error_message.dart';
import '../../core/providers/api_client_provider.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../l10n/app_localizations.dart';
import '../auth/providers/auth_provider.dart';
import '../common/widgets/activity_visuals.dart';
import '../common/widgets/community_actions.dart';
import 'club_discussion.dart';
import 'club_members_sheet.dart';
import 'club_pick_sheet.dart';
import 'club_widgets.dart';
import 'clubs_data.dart';
import 'title_detail_screen.dart';

void _openTitle(BuildContext context, Title title) =>
    Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => TitleDetailScreen(titleId: title.id)),
    );

/// One club: its header, this week's pick, earlier picks and discussion.
class ClubDetailScreen extends ConsumerStatefulWidget {
  const ClubDetailScreen({required this.clubId, super.key});
  final String clubId;

  @override
  ConsumerState<ClubDetailScreen> createState() => _ClubDetailScreenState();
}

class _ClubDetailScreenState extends ConsumerState<ClubDetailScreen> {
  String? selectedId;
  bool busy = false;

  Future<void> membership(Club club, String action) async {
    final l10n = AppLocalizations.of(context);
    if (action == 'leave' &&
        !await confirmCommunityAction(
          context,
          title: l10n.clubsLeaveTitle(club.name),
          message: l10n.clubsLeaveMessage,
          action: l10n.clubsLeaveClub,
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
            '/clubs/${club.id}/membership',
            data: {'action': action},
          );
      invalidateClub(ref, club.id);
      if (mounted && action == 'join') {
        showCommunitySnack(context, l10n.clubsWelcome(club.name));
      }
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

  Future<void> setPick(Club club) async {
    final selection = await showSetPickSheet(context, club);
    if (selection == null || !mounted) {
      return;
    }
    invalidateClub(ref, club.id);
    setState(() => selectedId = selection.id);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider.select((s) => s.userId));
    final detail = user == null
        ? null
        : ref.watch(clubDetailProvider(widget.clubId));
    final club = detail?.valueOrNull?.club;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(club?.name ?? l10n.clubsClub),
        actions: [
          if (club != null)
            PopupMenuButton<String>(
              tooltip: l10n.clubsOptionsTooltip,
              onSelected: (value) {
                if (value == 'members') {
                  showClubMembersSheet(context, club);
                } else if (value == 'report') {
                  reportCommunityItem(context, ref, kind: 'club', id: club.id);
                }
              },
              itemBuilder: (_) => [
                if (club.isMember)
                  PopupMenuItem(
                    value: 'members',
                    child: Text(l10n.clubsMembers),
                  ),
                PopupMenuItem(
                  value: 'report',
                  child: Text(l10n.clubsReportClub),
                ),
              ],
            ),
        ],
      ),
      body: PostLoginBackdrop(
        child: detail == null
            ? Center(child: Text(l10n.clubsSignInToSee))
            : detail.when(
                // Keep the club (and the reader's place in the discussion)
                // while it reloads after a post, a join or a pull; spin only
                // when there is nothing to show yet.
                skipLoadingOnRefresh: detail.hasValue,
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ActivityNotice(
                      icon: Icons.cloud_off_outlined,
                      title: l10n.clubsDetailLoadErrorTitle,
                      message: apiErrorMessage(
                        e,
                        fallback: l10n.clubsDetailLoadErrorMessage,
                      ),
                      actionLabel: l10n.chatTryAgain,
                      onAction: () =>
                          ref.invalidate(clubDetailProvider(widget.clubId)),
                    ),
                  ),
                ),
                data: (data) => _body(context, data),
              ),
      ),
    );
  }

  Widget _body(BuildContext context, ClubDetail data) {
    final club = data.club;
    final current = club.currentSelection;
    final selected =
        data.selections.where((s) => s.id == selectedId).firstOrNull ??
        current ??
        data.selections.firstOrNull;
    final earlier = data.selections.where((s) => s.id != current?.id).toList();
    final l10n = AppLocalizations.of(context);
    return RefreshIndicator(
      onRefresh: () async {
        invalidateClub(ref, club.id);
        await ref.read(clubDetailProvider(club.id).future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
        children: [
          _ClubHeader(
            club: club,
            busy: busy,
            onJoin: () => membership(club, 'join'),
            onLeave: () => membership(club, 'leave'),
            onMembers: () => showClubMembersSheet(context, club),
          ),
          const SizedBox(height: 16),
          _PickCard(
            club: club,
            pick: current,
            onSetPick: () => setPick(club),
            onDiscuss: current == null
                ? null
                : () => setState(() => selectedId = current.id),
          ),
          if (earlier.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              l10n.clubsEarlierPicks,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            for (final pick in earlier)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: KindDisc(kind: pick.title.kind, size: 40),
                  title: Text(pick.title.title),
                  subtitle: Text(
                    l10n.clubsPickSubtitle(
                      weekLabel(l10n, pick.weekStart),
                      pick.postCount,
                    ),
                  ),
                  selected: pick.id == selected?.id,
                  onTap: () => _openTitle(context, pick.title),
                  trailing: club.isMember
                      ? IconButton(
                          tooltip: l10n.clubsOpenDiscussion,
                          onPressed: () => setState(() => selectedId = pick.id),
                          icon: const Icon(Icons.forum_outlined),
                        )
                      : null,
                ),
              ),
          ],
          const SizedBox(height: 24),
          if (!club.isMember)
            ActivityNotice(
              icon: Icons.forum_outlined,
              title: l10n.clubsJoinToSeeTitle,
              message: l10n.clubsJoinToSeeMessage,
            )
          else if (selected != null)
            ClubDiscussion(
              key: ValueKey(selected.id),
              club: club,
              selection: selected,
            ),
        ],
      ),
    );
  }
}

class _ClubHeader extends StatelessWidget {
  const _ClubHeader({
    required this.club,
    required this.busy,
    required this.onJoin,
    required this.onLeave,
    required this.onMembers,
  });
  final Club club;
  final bool busy;
  final VoidCallback onJoin, onLeave, onMembers;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: kindGradient(scheme, club.kind),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                KindDisc(kind: club.kind, size: 56),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    club.name,
                    style: text.headlineSmall?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                KindBadge(kind: club.kind),
                CountPill(
                  icon: Icons.people_outline,
                  label: l10n.clubsMemberCount(club.memberCount),
                ),
                if (club.isMember)
                  CountPill(
                    icon: Icons.verified_outlined,
                    label: l10n.clubsYouRole(clubRoleLabel(l10n, club.myRole)),
                    emphasis: true,
                  ),
              ],
            ),
            if (club.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                club.description,
                style: text.bodyLarge?.copyWith(color: scheme.onSurface),
              ),
            ],
            if (club.moderationState == 'removed') ...[
              const SizedBox(height: 12),
              Text(
                l10n.clubsRemovedByModeration,
                style: text.bodyMedium?.copyWith(color: scheme.error),
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (!club.isMember)
                  FilledButton.icon(
                    onPressed: busy ? null : onJoin,
                    icon: const Icon(Icons.group_add_outlined),
                    label: Text(l10n.clubsJoinClub),
                  )
                else ...[
                  OutlinedButton.icon(
                    onPressed: onMembers,
                    icon: const Icon(Icons.people_outline),
                    label: Text(l10n.clubsMembers),
                  ),
                  TextButton.icon(
                    onPressed: busy ? null : onLeave,
                    icon: const Icon(Icons.logout),
                    label: Text(l10n.clubsLeaveClub),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PickCard extends StatelessWidget {
  const _PickCard({
    required this.club,
    required this.pick,
    required this.onSetPick,
    required this.onDiscuss,
  });
  final Club club;
  final Selection? pick;
  final VoidCallback onSetPick;
  final VoidCallback? onDiscuss;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final pick = this.pick;
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WeekPill(label: l10n.clubsWeekThis),
            const SizedBox(height: 12),
            if (pick == null)
              Text(
                club.canModerate
                    ? l10n.clubsNoPickModerator
                    : l10n.clubsNoPickMember,
                style: text.bodyLarge,
              )
            else ...[
              InkWell(
                onTap: () => _openTitle(context, pick.title),
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          pick.title.title,
                          style: text.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: scheme.primary,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right, color: scheme.primary),
                    ],
                  ),
                ),
              ),
              if (pick.title.byline.isNotEmpty)
                Text(pick.title.byline, style: text.bodyLarge),
              const SizedBox(height: 8),
              RatingSummary(title: pick.title),
              if (pick.note.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(l10n.clubsQuotedNote(pick.note), style: text.bodyLarge),
              ],
              const SizedBox(height: 8),
              Text(
                l10n.clubsPostsInDiscussion(pick.postCount),
                style: text.bodyMedium,
              ),
            ],
            if (club.canModerate || (pick != null && club.isMember)) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  if (club.canModerate)
                    OutlinedButton.icon(
                      onPressed: onSetPick,
                      icon: const Icon(Icons.edit_calendar_outlined),
                      label: Text(l10n.clubsSetThisWeeksPick),
                    ),
                  if (pick != null && club.isMember && onDiscuss != null)
                    TextButton.icon(
                      onPressed: onDiscuss,
                      icon: const Icon(Icons.forum_outlined),
                      label: Text(l10n.clubsDiscussThisPick),
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
