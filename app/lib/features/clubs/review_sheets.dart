import 'package:flutter/material.dart' hide Title;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/network/api_error_message.dart';
import '../../core/providers/api_client_provider.dart';
import '../../l10n/app_localizations.dart';
import '../common/widgets/community_actions.dart';
import 'club_widgets.dart';
import 'clubs_data.dart';
import 'list_sheets.dart';

/// Writes or edits the member's one review of [title].
Future<TitleReview?> showReviewSheet(
  BuildContext context, {
  required Title title,
  TitleReview? existing,
}) => showClubSheet<TitleReview>(
  context,
  _ReviewSheet(title: title, existing: existing),
);

class _ReviewSheet extends ConsumerStatefulWidget {
  const _ReviewSheet({required this.title, this.existing});
  final Title title;
  final TitleReview? existing;

  @override
  ConsumerState<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends ConsumerState<_ReviewSheet> {
  late final String id = widget.existing?.id ?? const Uuid().v4();
  late final body = TextEditingController(text: widget.existing?.body ?? '');
  late int rating = widget.existing?.rating ?? 0;
  late bool spoilers = widget.existing?.hasSpoilers ?? false;
  late String audience = widget.existing?.audience ?? 'private';
  bool busy = false;
  String? error;

  @override
  void dispose() {
    body.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final l10n = AppLocalizations.of(context);
    if (rating < 1) {
      setState(() => error = l10n.clubsTapStarError);
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
            '/clubs/titles/${widget.title.id}/reviews/$id',
            data: {
              'rating': rating,
              'body': body.text.trim(),
              'has_spoilers': spoilers,
              'audience': audience,
              'expected_version': widget.existing?.version ?? 0,
            },
          );
      final review = TitleReview.fromJson(
        (response.data as Map)['review'] as Map,
      );
      if (mounted) {
        Navigator.of(context).pop(review);
      }
    } on Object catch (e) {
      if (mounted) {
        setState(
          () => error = apiErrorMessage(e, fallback: l10n.clubsReviewNotSaved),
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
      title: widget.existing == null
          ? l10n.clubsWriteReview
          : l10n.clubsEditYourReview,
      children: [
        Text(
          widget.title.title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        StarRating(
          rating: rating.toDouble(),
          onChanged: (value) => setState(() => rating = value),
        ),
        Text(
          rating == 0
              ? l10n.clubsTapStarToRate
              : l10n.clubsRatingOutOfFive(rating),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: body,
          maxLength: 4000,
          maxLines: 6,
          minLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: l10n.clubsReviewBodyLabel),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: spoilers,
          onChanged: (value) => setState(() => spoilers = value),
          title: Text(l10n.clubsContainsSpoilers),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.clubsWhoCanSee,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final value in clubAudiences)
              ChoiceChip(
                label: Text(clubAudienceLabel(l10n, value)),
                selected: audience == value,
                onSelected: (_) => setState(() => audience = value),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        FilledButton(
          onPressed: busy ? null : save,
          child: Text(busy ? l10n.clubsSaving : l10n.clubsSaveReview),
        ),
      ],
    );
  }
}

/// Adds [title] to one of the member's lists of the same kind.
Future<void> showAddToListSheet(BuildContext context, Title title) =>
    showClubSheet<void>(context, _AddToListSheet(title: title));

class _AddToListSheet extends ConsumerStatefulWidget {
  const _AddToListSheet({required this.title});
  final Title title;

  @override
  ConsumerState<_AddToListSheet> createState() => _AddToListSheetState();
}

class _AddToListSheetState extends ConsumerState<_AddToListSheet> {
  bool busy = false;

  Future<void> add(MemberList list) async {
    final l10n = AppLocalizations.of(context);
    setState(() => busy = true);
    try {
      await ref
          .read(apiClientProvider)
          .put<dynamic>(
            '/clubs/lists/${list.id}/items/${widget.title.id}',
            data: {'note': list.noteFor(widget.title.id)},
          );
      ref.invalidate(myListsProvider);
      if (mounted) {
        showCommunitySnack(context, l10n.clubsAddedToList(list.name));
        Navigator.of(context).pop();
      }
    } on Object catch (e) {
      if (mounted) {
        showCommunitySnack(
          context,
          apiErrorMessage(e, fallback: l10n.clubsAddToThatListFailed),
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
      title: l10n.clubsAddToAList,
      children: [
        if (busy) const LinearProgressIndicator(),
        ref
            .watch(myListsProvider)
            .when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) =>
                  Text(apiErrorMessage(e, fallback: l10n.clubsListsLoadError)),
              data: (lists) {
                final matching = lists
                    .where((l) => l.kind == widget.title.kind)
                    .toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (matching.isEmpty)
                      Text(
                        widget.title.kind == 'film'
                            ? l10n.clubsNoFilmLists
                            : l10n.clubsNoBookLists,
                      ),
                    for (final list in matching)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: KindDisc(kind: list.kind, size: 40),
                        title: Text(list.name),
                        subtitle: Text(l10n.clubsTitleCount(list.items.length)),
                        enabled: !busy,
                        onTap: () => add(list),
                      ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: busy
                          ? null
                          : () async {
                              final created = await showListEditorSheet(
                                context,
                                kind: widget.title.kind,
                              );
                              if (created != null) {
                                await add(created);
                              }
                            },
                      icon: const Icon(Icons.playlist_add),
                      label: Text(l10n.clubsNewList),
                    ),
                  ],
                );
              },
            ),
      ],
    );
  }
}
