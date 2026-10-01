import 'package:flutter/material.dart' hide Title;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/network/api_error_message.dart';
import '../../core/providers/api_client_provider.dart';
import '../../core/widgets/glass_widgets.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book & Film Clubs'),
        actions: [
          IconButton(
            tooltip: 'My lists',
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
              tooltip: 'Start a book or film club',
              icon: const Icon(Icons.add),
              label: const Text('Start a club'),
            )
          : null,
      body: PostLoginBackdrop(
        child: user == null || page == null
            ? const Center(child: Text('Sign in to see clubs.'))
            : RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(clubsProvider(query));
                  await ref.read(clubsProvider(query).future);
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
                  children: [
                    const ActivityHero(
                      icon: Icons.local_library_outlined,
                      tone: 1,
                      title: 'Read it. Watch it. Talk about it.',
                      subtitle:
                          'Join a club, follow one pick a week and share '
                          'what you thought. Great taste is a great '
                          'conversation starter.',
                    ),
                    const SizedBox(height: 16),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'mine',
                          icon: Icon(Icons.groups_outlined),
                          label: Text('My clubs'),
                        ),
                        ButtonSegment(
                          value: 'discover',
                          icon: Icon(Icons.explore_outlined),
                          label: Text('Discover'),
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
                          '': 'All',
                          'book': 'Books',
                          'film': 'Films',
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
                        title: 'Clubs could not load',
                        message: apiErrorMessage(
                          e,
                          fallback: 'Please check your connection.',
                        ),
                        actionLabel: 'Try again',
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
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (!page.eligible) ...[
        const ActivityNotice(
          icon: Icons.lock_outline,
          title: 'You can look around',
          message:
              'Complete your profile with two approved photos to start or '
              'join a club.',
        ),
        const SizedBox(height: 16),
      ],
      if (page.clubs.isEmpty)
        ActivityNotice(
          icon: Icons.local_library_outlined,
          title: scope == 'mine'
              ? 'Your first club is waiting'
              : 'No clubs here yet',
          message: scope == 'mine'
              ? 'Find a club that reads or watches what you love, or start '
                    'your own.'
              : 'Be the first: start a club and pick something great for '
                    'this week.',
          actionLabel: scope == 'mine' ? 'Discover clubs' : null,
          onAction: scope == 'mine' ? onDiscover : null,
        )
      else
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 640 ? 2 : 1;
            final width = (constraints.maxWidth - 16 * (columns - 1)) / columns;
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

class ClubCard extends StatelessWidget {
  const ClubCard({required this.club, super.key});
  final Club club;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final pick = club.currentSelection;
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
                        label:
                            '${club.memberCount} '
                            'member${club.memberCount == 1 ? '' : 's'}',
                      ),
                      if (club.isMember)
                        CountPill(
                          icon: Icons.check_circle_outline,
                          label: club.isOwner
                              ? 'You run it'
                              : club.myRole == 'moderator'
                              ? 'You moderate'
                              : 'Joined ✓',
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
                      'No pick yet this week',
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
                        WeekPill(label: weekLabel(pick.weekStart)),
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
    if (name.text.trim().length < 3) {
      setState(() => error = 'Give your club a name of at least 3 letters.');
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
          () => error = apiErrorMessage(
            e,
            fallback: 'Your club could not be created.',
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => SheetFrame(
    title: 'Start a club',
    children: [
      SegmentedButton<String>(
        segments: [
          for (final entry in clubKinds.entries)
            ButtonSegment(
              value: entry.key,
              icon: Icon(kindIcon(entry.key)),
              label: Text(entry.value),
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
        decoration: const InputDecoration(
          labelText: 'Club name',
          hintText: 'Sunday Slow Reads',
        ),
      ),
      TextField(
        controller: description,
        maxLength: 500,
        maxLines: 4,
        minLines: 2,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: 'What is your club about? (optional)',
        ),
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
        label: Text(busy ? 'Creating…' : 'Create club'),
      ),
    ],
  );
}
