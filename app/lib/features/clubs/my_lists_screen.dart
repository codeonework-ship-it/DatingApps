import 'package:flutter/material.dart' hide Title;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_error_message.dart';
import '../../core/providers/api_client_provider.dart';
import '../../core/widgets/glass_widgets.dart';
import '../auth/providers/auth_provider.dart';
import '../common/widgets/activity_visuals.dart';
import '../common/widgets/community_actions.dart';
import 'club_widgets.dart';
import 'clubs_data.dart';
import 'list_sheets.dart';
import 'title_detail_screen.dart';
import 'title_picker.dart';

/// The member's own book and film lists.
class MyListsScreen extends ConsumerWidget {
  const MyListsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider.select((s) => s.userId));
    return Scaffold(
      appBar: AppBar(title: const Text('My lists')),
      floatingActionButton: user == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => showListEditorSheet(context),
              tooltip: 'Create a new list',
              icon: const Icon(Icons.playlist_add),
              label: const Text('New list'),
            ),
      body: PostLoginBackdrop(
        child: user == null
            ? const Center(child: Text('Sign in to see your lists.'))
            : RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(myListsProvider);
                  await ref.read(myListsProvider.future);
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
                  children: [
                    const ActivityHero(
                      icon: Icons.bookmarks_outlined,
                      tone: 2,
                      title: 'Your shelf',
                      subtitle:
                          'Keep track of what you loved and what is next. '
                          'Share a list, or keep it just for you.',
                    ),
                    const SizedBox(height: 16),
                    ref
                        .watch(myListsProvider)
                        .when(
                          skipLoadingOnRefresh: false,
                          loading: () => const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (e, _) => ActivityNotice(
                            icon: Icons.cloud_off_outlined,
                            title: 'Your lists could not load',
                            message: apiErrorMessage(
                              e,
                              fallback: 'Please check your connection.',
                            ),
                            actionLabel: 'Try again',
                            onAction: () => ref.invalidate(myListsProvider),
                          ),
                          data: (lists) => lists.isEmpty
                              ? ActivityNotice(
                                  icon: Icons.playlist_add,
                                  title: 'Start your first list',
                                  message:
                                      'Favourite films, books to read next, '
                                      'comfort rewatches: it is up to you.',
                                  actionLabel: 'New list',
                                  onAction: () => showListEditorSheet(context),
                                )
                              : Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    for (final list in lists)
                                      MemberListCard(list: list),
                                  ],
                                ),
                        ),
                  ],
                ),
              ),
      ),
    );
  }
}

class MemberListCard extends ConsumerStatefulWidget {
  const MemberListCard({required this.list, super.key});
  final MemberList list;

  @override
  ConsumerState<MemberListCard> createState() => _MemberListCardState();
}

class _MemberListCardState extends ConsumerState<MemberListCard> {
  bool busy = false;

  Future<void> run(
    Future<void> Function() action, {
    required String failure,
  }) async {
    setState(() => busy = true);
    try {
      await action();
      ref.invalidate(myListsProvider);
    } on Object catch (e) {
      if (mounted) {
        showCommunitySnack(context, apiErrorMessage(e, fallback: failure));
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  Future<void> onMenu(String action) async {
    final list = widget.list;
    final api = ref.read(apiClientProvider);
    switch (action) {
      case 'edit':
        await showListEditorSheet(context, existing: list);
      case 'add':
        final title = await pickTitle(
          context,
          kind: list.kind,
          heading: 'Add to ${list.name}',
        );
        if (title == null || !mounted) {
          return;
        }
        await run(
          () => api.put<dynamic>(
            '/clubs/lists/${list.id}/items/${title.id}',
            data: {'note': ''},
          ),
          failure: 'It could not be added to this list.',
        );
      case 'delete':
        if (!await confirmCommunityAction(
          context,
          title: 'Delete ${list.name}?',
          message: 'The list and its notes are removed. This cannot be undone.',
          action: 'Delete list',
        )) {
          return;
        }
        await run(
          () => api.delete<dynamic>(
            '/clubs/lists/${list.id}',
            data: {'expected_version': list.version},
          ),
          failure: 'The list could not be deleted. Reload and retry.',
        );
    }
  }

  Future<void> onItem(ListItem item, String action) async {
    final list = widget.list;
    final api = ref.read(apiClientProvider);
    final path = '/clubs/lists/${list.id}/items/${item.title.id}';
    if (action == 'note') {
      final note = await askItemNote(context, item.note);
      if (note == null || !mounted) {
        return;
      }
      await run(
        () => api.put<dynamic>(path, data: {'note': note}),
        failure: 'Your note could not be saved.',
      );
    } else if (action == 'remove') {
      await run(
        () => api.delete<dynamic>(path),
        failure: 'It could not be removed.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = widget.list;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: kindGradient(scheme, list.kind),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
              child: Row(
                children: [
                  KindDisc(kind: list.kind, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      list.name,
                      style: text.titleLarge?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'List options',
                    enabled: !busy,
                    onSelected: onMenu,
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'add', child: Text('Add a title')),
                      PopupMenuItem(value: 'edit', child: Text('Edit list')),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete list'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (busy) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                KindBadge(kind: list.kind, suffix: 'list'),
                CountPill(
                  icon: list.audience == 'private'
                      ? Icons.lock_outline
                      : list.audience == 'friends'
                      ? Icons.people_outline
                      : Icons.public,
                  label: clubAudiences[list.audience] ?? 'Only me',
                ),
                CountPill(
                  icon: Icons.format_list_numbered,
                  label:
                      '${list.items.length} '
                      'title${list.items.length == 1 ? '' : 's'}',
                ),
              ],
            ),
          ),
          if (list.items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Nothing here yet. Use “Add a title” from the list menu.',
                style: text.bodyMedium,
              ),
            ),
          for (final item in list.items)
            ListTile(
              title: Text(item.title.title),
              subtitle: item.title.byline.isEmpty && item.note.isEmpty
                  ? null
                  : Text(
                      [
                        if (item.title.byline.isNotEmpty) item.title.byline,
                        if (item.note.isNotEmpty) '“${item.note}”',
                      ].join('\n'),
                    ),
              isThreeLine: item.note.isNotEmpty && item.title.byline.isNotEmpty,
              onTap: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => TitleDetailScreen(titleId: item.title.id),
                ),
              ),
              trailing: PopupMenuButton<String>(
                tooltip: 'Options for ${item.title.title}',
                enabled: !busy,
                onSelected: (action) => onItem(item, action),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'note',
                    child: Text(item.note.isEmpty ? 'Add a note' : 'Edit note'),
                  ),
                  const PopupMenuItem(
                    value: 'remove',
                    child: Text('Remove from list'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
