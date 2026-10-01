import 'package:flutter/material.dart' hide Title;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_error_message.dart';
import '../../core/providers/api_client_provider.dart';
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
  late final weeks = {
    mondayOf(DateTime.now()): 'This week',
    mondayOf(DateTime.now().add(const Duration(days: 7))): 'Next week',
  };
  late String week = weeks.keys.first;
  Title? title;
  bool busy = false;
  String? error;

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  Future<void> choose() async {
    final picked = await pickTitle(
      context,
      kind: widget.club.kind,
      heading: widget.club.kind == 'film' ? 'Choose a film' : 'Choose a book',
    );
    if (picked != null && mounted) {
      setState(() => title = picked);
    }
  }

  Future<void> save() async {
    final chosen = title;
    if (chosen == null) {
      setState(() => error = 'Choose a title first.');
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
          () => error = apiErrorMessage(
            e,
            fallback: 'The pick could not be saved.',
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
  Widget build(BuildContext context) {
    final chosen = title;
    return SheetFrame(
      title: 'Set the weekly pick',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in weeks.entries)
              ChoiceChip(
                label: Text(entry.value),
                selected: week == entry.key,
                onSelected: (_) => setState(() => week = entry.key),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (chosen == null)
          OutlinedButton.icon(
            onPressed: choose,
            icon: const Icon(Icons.search),
            label: Text(
              widget.club.kind == 'film' ? 'Choose a film' : 'Choose a book',
            ),
          )
        else
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: KindDisc(kind: chosen.kind, size: 40),
            title: Text(chosen.title),
            subtitle: chosen.byline.isEmpty ? null : Text(chosen.byline),
            trailing: TextButton(
              onPressed: choose,
              child: const Text('Change'),
            ),
          ),
        const SizedBox(height: 12),
        TextField(
          controller: note,
          maxLength: 280,
          maxLines: 3,
          minLines: 1,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'A note for the club (optional)',
            hintText: 'Why this one? Where to start?',
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
          child: Text(busy ? 'Saving…' : 'Save pick'),
        ),
      ],
    );
  }
}
