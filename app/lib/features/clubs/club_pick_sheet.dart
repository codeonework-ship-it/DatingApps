import 'package:flutter/material.dart' hide Title;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_error_message.dart';
import '../../core/providers/api_client_provider.dart';
import '../../l10n/app_localizations.dart';
import 'club_widgets.dart';
import 'clubs_data.dart';
import 'title_picker.dart';

/// Owners and moderators choose the pick for this week or next week:
/// `PUT /clubs/{id}/selections/{monday}`.
Future<Selection?> showSetPickSheet(BuildContext context, Club club) =>
    showClubSheet<Selection>(context, _SetPickSheet(club: club));

class _SetPickSheet extends ConsumerStatefulWidget {
  const _SetPickSheet({required this.club});
  final Club club;

  @override
  ConsumerState<_SetPickSheet> createState() => _SetPickSheetState();
}

class _SetPickSheetState extends ConsumerState<_SetPickSheet> {
  final note = TextEditingController();

  /// This week's and next week's Mondays.
  late final weeks = [
    mondayOf(DateTime.now()),
    mondayOf(DateTime.now().add(const Duration(days: 7))),
  ];
  late String week = weeks.first;
  Title? title;
  bool busy = false;
  String? error;

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  String chooseLabel(AppLocalizations l10n) =>
      widget.club.kind == 'film' ? l10n.clubsChooseFilm : l10n.clubsChooseBook;

  Future<void> choose() async {
    final picked = await pickTitle(
      context,
      kind: widget.club.kind,
      heading: chooseLabel(AppLocalizations.of(context)),
    );
    if (picked != null && mounted) {
      setState(() => title = picked);
    }
  }

  Future<void> save() async {
    final chosen = title;
    final l10n = AppLocalizations.of(context);
    if (chosen == null) {
      setState(() => error = l10n.clubsChooseTitleFirst);
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
            '/clubs/${widget.club.id}/selections/$week',
            data: {'title_id': chosen.id, 'note': note.text.trim()},
          );
      final selection = Selection.fromJson(
        (response.data as Map)['selection'] as Map,
      );
      if (mounted) {
        Navigator.of(context).pop(selection);
      }
    } on Object catch (e) {
      if (mounted) {
        setState(
          () => error = apiErrorMessage(e, fallback: l10n.clubsPickNotSaved),
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
    final chosen = title;
    final l10n = AppLocalizations.of(context);
    return SheetFrame(
      title: l10n.clubsSetWeeklyPick,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (index, monday) in weeks.indexed)
              ChoiceChip(
                label: Text(
                  index == 0 ? l10n.clubsWeekThis : l10n.clubsWeekNext,
                ),
                selected: week == monday,
                onSelected: (_) => setState(() => week = monday),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (chosen == null)
          OutlinedButton.icon(
            onPressed: choose,
            icon: const Icon(Icons.search),
            label: Text(chooseLabel(l10n)),
          )
        else
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: KindDisc(kind: chosen.kind, size: 40),
            title: Text(chosen.title),
            subtitle: chosen.byline.isEmpty ? null : Text(chosen.byline),
            trailing: TextButton(
              onPressed: choose,
              child: Text(l10n.clubsChange),
            ),
          ),
        const SizedBox(height: 12),
        TextField(
          controller: note,
          maxLength: 280,
          maxLines: 3,
          minLines: 1,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: l10n.clubsPickNoteLabel,
            hintText: l10n.clubsPickNoteHint,
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
        FilledButton(
          onPressed: busy ? null : save,
          child: Text(busy ? l10n.clubsSaving : l10n.clubsSavePick),
        ),
      ],
    );
  }
}
