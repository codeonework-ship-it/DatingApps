import 'package:flutter/material.dart' hide Title;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/network/api_error_message.dart';
import '../../core/providers/api_client_provider.dart';
import '../../l10n/app_localizations.dart';
import 'club_widgets.dart';
import 'clubs_data.dart';

/// Creates a list (version 0) or renames an existing one.
Future<MemberList?> showListEditorSheet(
  BuildContext context, {
  MemberList? existing,
  String kind = 'book',
}) => showClubSheet<MemberList>(
  context,
  _ListEditor(existing: existing, kind: kind),
);

class _ListEditor extends ConsumerStatefulWidget {
  const _ListEditor({required this.kind, this.existing});
  final MemberList? existing;
  final String kind;

  @override
  ConsumerState<_ListEditor> createState() => _ListEditorState();
}

class _ListEditorState extends ConsumerState<_ListEditor> {
  late final String id = widget.existing?.id ?? const Uuid().v4();
  late final name = TextEditingController(text: widget.existing?.name ?? '');
  late String kind = widget.existing?.kind ?? widget.kind;
  late String audience = widget.existing?.audience ?? 'private';
  bool busy = false;
  String? error;

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final l10n = AppLocalizations.of(context);
    if (name.text.trim().isEmpty) {
      setState(() => error = l10n.clubsListNameRequired);
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
            '/clubs/lists/$id',
            data: {
              'name': name.text.trim(),
              'kind': kind,
              'audience': audience,
              'expected_version': widget.existing?.version ?? 0,
            },
          );
      final list = MemberList.fromJson((response.data as Map)['list'] as Map);
      ref.invalidate(myListsProvider);
      if (mounted) {
        Navigator.of(context).pop(list);
      }
    } on Object catch (e) {
      if (mounted) {
        setState(
          () => error = apiErrorMessage(e, fallback: l10n.clubsListNotSaved),
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
    final editing = widget.existing != null;
    final l10n = AppLocalizations.of(context);
    return SheetFrame(
      title: editing ? l10n.clubsEditList : l10n.clubsNewList,
      children: [
        TextField(
          controller: name,
          maxLength: 60,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: l10n.clubsListNameLabel,
            hintText: l10n.clubsListNameHint,
          ),
        ),
        const SizedBox(height: 8),
        if (!editing || (widget.existing?.items.isEmpty ?? true)) ...[
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
        ],
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
          child: Text(
            busy
                ? l10n.clubsSaving
                : (editing ? l10n.clubsSave : l10n.clubsCreateList),
          ),
        ),
      ],
    );
  }
}

/// Asks for a short note (≤280) about a title on a list.
Future<String?> askItemNote(BuildContext context, String initial) =>
    showDialog<String>(
      context: context,
      builder: (_) => _NoteDialog(initial: initial),
    );

class _NoteDialog extends StatefulWidget {
  const _NoteDialog({required this.initial});
  final String initial;

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  late final note = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.clubsYourNote),
      scrollable: true,
      content: TextField(
        controller: note,
        maxLength: 280,
        maxLines: 4,
        minLines: 1,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(labelText: l10n.clubsNoteLabel),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, note.text.trim()),
          child: Text(l10n.clubsSaveNote),
        ),
      ],
    );
  }
}
