import 'package:flutter/material.dart' hide Title;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_error_message.dart';
import '../../core/providers/api_client_provider.dart';
import '../../core/widgets/glass_widgets.dart';
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
    if (action == 'leave' &&
        !await confirmCommunityAction(
          context,
          title: 'Leave ${club.name}?',
          message: 'You can rejoin later while the club is open.',
          action: 'Leave club',
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
        showCommunitySnack(context, 'Welcome to ${club.name}!');
      }
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
    return Scaffold(
      appBar: AppBar(
        title: Text(club?.name ?? 'Club'),
        actions: [
          if (club != null)
            PopupMenuButton<String>(
              tooltip: 'Club options',
              onSelected: (value) {
                if (value == 'members') {
                  showClubMembersSheet(context, club);
                } else if (value == 'report') {
                  reportCommunityItem(context, ref, kind: 'club', id: club.id);
                }
              },
              itemBuilder: (_) => [
                if (club.isMember)
                  const PopupMenuItem(value: 'members', child: Text('Members')),
                const PopupMenuItem(
                  value: 'report',
                  child: Text('Report club'),
                ),
              ],
            ),
        ],
      ),
      body: PostLoginBackdrop(
        child: detail == null
            ? const Center(child: Text('Sign in to see clubs.'))
            : detail.when(
                skipLoadingOnRefresh: false,
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ActivityNotice(
                      icon: Icons.cloud_off_outlined,
                      title: 'This club could not load',
                      message: apiErrorMessage(
                        e,
                        fallback: 'It may have closed. Please try again.',
                      ),
                      actionLabel: 'Try again',
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
              'Earlier picks',
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
                    '${weekLabel(pick.weekStart)} · ${pick.postCount} '
                    'post${pick.postCount == 1 ? '' : 's'}',
                  ),
                  selected: pick.id == selected?.id,
                  onTap: () => _openTitle(context, pick.title),
                  trailing: club.isMember
                      ? IconButton(
                          tooltip: 'Open the discussion',
                          onPressed: () => setState(() => selectedId = pick.id),
                          icon: const Icon(Icons.forum_outlined),
                        )
                      : null,
                ),
              ),
          ],
          const SizedBox(height: 24),
          if (!club.isMember)
            const ActivityNotice(
              icon: Icons.forum_outlined,
              title: 'Join to see the discussion',
              message:
                  'Members talk about each pick together. Join the club to '
                  'read along and add your thoughts.',
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
                  label:
                      '${club.memberCount} '
                      'member${club.memberCount == 1 ? '' : 's'}',
                ),
                if (club.isMember)
                  CountPill(
                    icon: Icons.verified_outlined,
                    label: 'You: ${clubRoles[club.myRole] ?? 'Member'}',
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
                'This club was removed by moderation.',
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
                    label: const Text('Join club'),
                  )
                else ...[
                  OutlinedButton.icon(
                    onPressed: onMembers,
                    icon: const Icon(Icons.people_outline),
                    label: const Text('Members'),
                  ),
                  TextButton.icon(
                    onPressed: busy ? null : onLeave,
                    icon: const Icon(Icons.logout),
                    label: const Text('Leave club'),
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
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const WeekPill(label: 'This week'),
            const SizedBox(height: 12),
            if (pick == null)
              Text(
                club.canModerate
                    ? 'No pick yet. Choose something great for everyone.'
                    : 'No pick yet. Check back soon.',
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
                Text('“${pick.note}”', style: text.bodyLarge),
              ],
              const SizedBox(height: 8),
              Text(
                '${pick.postCount} post${pick.postCount == 1 ? '' : 's'} '
                'in the discussion',
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
                      label: const Text('Set this week’s pick'),
                    ),
                  if (pick != null && club.isMember && onDiscuss != null)
                    TextButton.icon(
                      onPressed: onDiscuss,
                      icon: const Icon(Icons.forum_outlined),
                      label: const Text('Discuss this pick'),
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
