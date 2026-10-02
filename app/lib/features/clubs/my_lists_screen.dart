import 'package:flutter/material.dart' hide Title;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_error_message.dart';
import '../../core/providers/api_client_provider.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.clubsMyLists)),
      floatingActionButton: user == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => showListEditorSheet(context),
              tooltip: l10n.clubsCreateNewListTooltip,
              icon: const Icon(Icons.playlist_add),
              label: Text(l10n.clubsNewList),
            ),
      body: PostLoginBackdrop(
        child: user == null
            ? Center(child: Text(l10n.clubsSignInToSeeLists))
            : RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(myListsProvider);
                  await ref.read(myListsProvider.future);
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
                  children: [
                    ActivityHero(
                      icon: Icons.bookmarks_outlined,
                      tone: 2,
                      title: l10n.clubsShelfTitle,
                      subtitle: l10n.clubsShelfSubtitle,
                    ),
                    const SizedBox(height: 16),
                    ref
                        .watch(myListsProvider)
                        .when(
                          // Keep the shelf (and the scroll position) while it
                          // reloads after a change; spin only when there is
                          // nothing to show yet.
                          skipLoadingOnRefresh: ref
                              .watch(myListsProvider)
                              .hasValue,
                          loading: () => const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (e, _) => ActivityNotice(
                            icon: Icons.cloud_off_outlined,
                            title: l10n.clubsListsLoadErrorTitle,
                            message: apiErrorMessage(
                              e,
                              fallback: l10n.clubsCheckConnection,
                            ),
                            actionLabel: l10n.chatTryAgain,
                            onAction: () => ref.invalidate(myListsProvider),
                          ),
                          data: (lists) => lists.isEmpty
                              ? ActivityNotice(
                                  icon: Icons.playlist_add,
                                  title: l10n.clubsFirstListTitle,
                                  message: l10n.clubsFirstListMessage,
                                  actionLabel: l10n.clubsNewList,
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
    final l10n = AppLocalizations.of(context);
    switch (action) {
      case 'edit':
        await showListEditorSheet(context, existing: list);
      case 'add':
        final title = await pickTitle(
          context,
          kind: list.kind,
          heading: l10n.clubsAddToNamed(list.name),
        );
        if (title == null || !mounted) {
          return;
        }
        await run(
          () => api.put<dynamic>(
            '/clubs/lists/${list.id}/items/${title.id}',
            data: {'note': list.noteFor(title.id)},
          ),
          failure: l10n.clubsAddToThisListFailed,
        );
      case 'delete':
        if (!await confirmCommunityAction(
          context,
          title: l10n.clubsDeleteListTitle(list.name),
          message: l10n.clubsDeleteListMessage,
          action: l10n.clubsDeleteList,
        )) {
          return;
        }
        await run(
          () => api.delete<dynamic>(
            '/clubs/lists/${list.id}',
            data: {'expected_version': list.version},
          ),
          failure: l10n.clubsListDeleteFailed,
        );
    }
  }

  Future<void> onItem(ListItem item, String action) async {
    final list = widget.list;
    final api = ref.read(apiClientProvider);
    final path = '/clubs/lists/${list.id}/items/${item.title.id}';
    final l10n = AppLocalizations.of(context);
    if (action == 'note') {
      final note = await askItemNote(context, item.note);
      if (note == null || !mounted) {
        return;
      }
      await run(
        () => api.put<dynamic>(path, data: {'note': note}),
        failure: l10n.clubsNoteNotSaved,
      );
    } else if (action == 'remove') {
      await run(
        () => api.delete<dynamic>(path),
        failure: l10n.clubsRemoveFailed,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = widget.list;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
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
                    tooltip: l10n.clubsListOptions,
                    enabled: !busy,
                    onSelected: onMenu,
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'add',
                        child: Text(l10n.clubsAddATitle),
                      ),
                      PopupMenuItem(
                        value: 'edit',
                        child: Text(l10n.clubsEditList),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(l10n.clubsDeleteList),
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
                  label: clubAudienceLabel(l10n, list.audience),
                ),
                CountPill(
                  icon: Icons.format_list_numbered,
                  label: l10n.clubsTitleCount(list.items.length),
                ),
              ],
            ),
          ),
          if (list.items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.clubsListEmpty, style: text.bodyMedium),
            ),
          for (final item in list.items)
            ListTile(
              title: Text(item.title.title),
              subtitle: item.title.byline.isEmpty && item.note.isEmpty
                  ? null
                  : Text(
                      [
                        if (item.title.byline.isNotEmpty) item.title.byline,
                        if (item.note.isNotEmpty)
                          l10n.clubsQuotedNote(item.note),
                      ].join('\n'),
                    ),
              isThreeLine: item.note.isNotEmpty && item.title.byline.isNotEmpty,
              onTap: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => TitleDetailScreen(titleId: item.title.id),
                ),
              ),
              trailing: PopupMenuButton<String>(
                tooltip: l10n.clubsItemOptions(item.title.title),
                enabled: !busy,
                onSelected: (action) => onItem(item, action),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'note',
                    child: Text(
                      item.note.isEmpty
                          ? l10n.clubsAddNote
                          : l10n.clubsEditNote,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'remove',
                    child: Text(l10n.clubsRemoveFromList),
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
