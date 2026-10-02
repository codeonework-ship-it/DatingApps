import 'package:flutter/material.dart' hide Title;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/network/api_error_message.dart';
import '../../core/providers/api_client_provider.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../l10n/app_localizations.dart';
import '../auth/providers/auth_provider.dart';
import '../common/widgets/activity_visuals.dart';
import 'club_detail_screen.dart';
import 'club_widgets.dart';
import 'clubs_data.dart';
import 'my_lists_screen.dart';

Future<void> openClubs(BuildContext context) => Navigator.of(
  context,
).push<void>(MaterialPageRoute(builder: (_) => const ClubsScreen()));

/// Book & Film Clubs: the member's clubs and clubs to discover.
class ClubsScreen extends ConsumerStatefulWidget {
  const ClubsScreen({super.key, this.initialKind = ''});

  /// '' for all clubs, or 'book' / 'film' to open already filtered.
  final String initialKind;

  @override
  ConsumerState<ClubsScreen> createState() => _ClubsScreenState();
}

class _ClubsScreenState extends ConsumerState<ClubsScreen> {
  String scope = 'mine';
  late String kind = widget.initialKind;

  ClubsQuery get query => (scope: scope, kind: kind);

  Future<void> startClub() async {
    final club = await showClubSheet<Club>(context, const _StartClubSheet());
    if (club == null || !mounted) {
      return;
    }
    ref.invalidate(clubsProvider);
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => ClubDetailScreen(clubId: club.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider.select((s) => s.userId));
    final page = user == null ? null : ref.watch(clubsProvider(query));
    final eligible = page?.valueOrNull?.eligible ?? false;
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.clubsTitle),
        actions: [
          IconButton(
            tooltip: l10n.clubsMyLists,
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(builder: (_) => const MyListsScreen()),
            ),
            icon: const Icon(Icons.bookmarks_outlined),
          ),
        ],
      ),
      floatingActionButton: eligible
          ? FloatingActionButton.extended(
              onPressed: startClub,
              tooltip: l10n.clubsStartClubTooltip,
              icon: const Icon(Icons.add),
              label: Text(l10n.clubsStartClub),
            )
          : null,
      body: PostLoginBackdrop(
        child: user == null || page == null
            ? Center(child: Text(l10n.clubsSignInToSee))
            : RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(clubsProvider(query));
                  await ref.read(clubsProvider(query).future);
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
                  children: [
                    ActivityHero(
                      icon: Icons.local_library_outlined,
                      tone: 1,
                      title: l10n.clubsHeroTitle,
                      subtitle: l10n.clubsHeroSubtitle,
                    ),
                    const SizedBox(height: 16),
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment(
                          value: 'mine',
                          icon: const Icon(Icons.groups_outlined),
                          label: Text(l10n.clubsScopeMine),
                        ),
                        ButtonSegment(
                          value: 'discover',
                          icon: const Icon(Icons.explore_outlined),
                          label: Text(l10n.clubsScopeDiscover),
                        ),
                      ],
                      selected: {scope},
                      onSelectionChanged: (value) =>
                          setState(() => scope = value.first),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final entry in {
                          '': l10n.clubsFilterAll,
                          'book': l10n.clubsKindBooks,
                          'film': l10n.clubsKindFilms,
                        }.entries)
                          ChoiceChip(
                            avatar: entry.key.isEmpty
                                ? null
                                : Icon(kindIcon(entry.key), size: 18),
                            label: Text(entry.value),
                            selected: kind == entry.key,
                            onSelected: (_) => setState(() => kind = entry.key),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    page.when(
                      skipLoadingOnRefresh: false,
                      loading: () => const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => ActivityNotice(
                        icon: Icons.cloud_off_outlined,
                        title: l10n.clubsLoadErrorTitle,
                        message: apiErrorMessage(
                          e,
                          fallback: l10n.clubsCheckConnection,
                        ),
                        actionLabel: l10n.chatTryAgain,
                        onAction: () => ref.invalidate(clubsProvider(query)),
                      ),
                      data: (data) => _ClubList(
                        page: data,
                        scope: scope,
                        onDiscover: () => setState(() => scope = 'discover'),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _ClubList extends StatelessWidget {
  const _ClubList({
    required this.page,
    required this.scope,
    required this.onDiscover,
  });
  final ClubsPage page;
  final String scope;
  final VoidCallback onDiscover;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!page.eligible) ...[
          ActivityNotice(
            icon: Icons.lock_outline,
            title: l10n.clubsLookAroundTitle,
            message: l10n.clubsLookAroundMessage,
          ),
          const SizedBox(height: 16),
        ],
        if (page.clubs.isEmpty)
          ActivityNotice(
            icon: Icons.local_library_outlined,
            title: scope == 'mine'
                ? l10n.clubsEmptyMineTitle
                : l10n.clubsEmptyDiscoverTitle,
            message: scope == 'mine'
                ? l10n.clubsEmptyMineMessage
                : l10n.clubsEmptyDiscoverMessage,
            actionLabel: scope == 'mine' ? l10n.clubsDiscoverClubs : null,
            onAction: scope == 'mine' ? onDiscover : null,
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 640 ? 2 : 1;
              final width =
                  (constraints.maxWidth - 16 * (columns - 1)) / columns;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final club in page.clubs)
                    SizedBox(
                      width: width,
                      child: ClubCard(club: club),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}

class ClubCard extends StatelessWidget {
  const ClubCard({required this.club, super.key});
  final Club club;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final pick = club.currentSelection;
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push<void>(
          MaterialPageRoute(builder: (_) => ClubDetailScreen(clubId: club.id)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: kindGradient(scheme, club.kind),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    KindDisc(kind: club.kind),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        club.name,
                        style: text.titleLarge?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                          icon: Icons.check_circle_outline,
                          label: club.isOwner
                              ? l10n.clubsYouRunIt
                              : club.myRole == 'moderator'
                              ? l10n.clubsYouModerate
                              : l10n.clubsJoined,
                          emphasis: true,
                        ),
                    ],
                  ),
                  if (club.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      club.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (pick == null)
                    Text(
                      l10n.clubsNoPickThisWeek,
                      style: text.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        WeekPill(label: weekLabel(l10n, pick.weekStart)),
                        Text(
                          pick.title.title,
                          style: text.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
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
    );
  }
}

class _StartClubSheet extends ConsumerStatefulWidget {
  const _StartClubSheet();

  @override
  ConsumerState<_StartClubSheet> createState() => _StartClubSheetState();
}

class _StartClubSheetState extends ConsumerState<_StartClubSheet> {
  final name = TextEditingController();
  final description = TextEditingController();
  late final String id = const Uuid().v4();
  String kind = 'book';
  bool busy = false;
  String? error;

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    super.dispose();
  }

  Future<void> create() async {
    final l10n = AppLocalizations.of(context);
    if (name.text.trim().length < 3) {
      setState(() => error = l10n.clubsNameTooShort);
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final response = await ref
          .read(apiClientProvider)
          .put<dynamic>(
            '/clubs/$id',
            data: {
              'kind': kind,
              'name': name.text.trim(),
              'description': description.text.trim(),
              'expected_version': 0,
            },
          );
      final club = Club.fromJson((response.data as Map)['club'] as Map);
      if (mounted) {
        Navigator.of(context).pop(club);
      }
    } on Object catch (e) {
      if (mounted) {
        setState(
          () => error = apiErrorMessage(e, fallback: l10n.clubsCreateFailed),
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
    final l10n = AppLocalizations.of(context);
    return SheetFrame(
      title: l10n.clubsStartClub,
      children: [
        SegmentedButton<String>(
          segments: [
            for (final kind in clubKinds)
              ButtonSegment(
                value: kind,
                icon: Icon(kindIcon(kind)),
                label: Text(clubKindLabel(l10n, kind)),
              ),
          ],
          selected: {kind},
          onSelectionChanged: (value) => setState(() => kind = value.first),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: name,
          maxLength: 60,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: l10n.clubsNameLabel,
            hintText: l10n.clubsNameHint,
          ),
        ),
        TextField(
          controller: description,
          maxLength: 500,
          maxLines: 4,
          minLines: 2,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: l10n.clubsDescriptionLabel),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        FilledButton.icon(
          onPressed: busy ? null : create,
          icon: const Icon(Icons.celebration_outlined),
          label: Text(busy ? l10n.clubsCreating : l10n.clubsCreateClub),
        ),
      ],
    );
  }
}
