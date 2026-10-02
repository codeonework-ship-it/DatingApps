import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/app_layout.dart';
import '../../../l10n/app_localizations.dart';
import '../models/graduation.dart';
import '../models/graduation_labels.dart';
import '../providers/graduation_provider.dart';

/// Opens the "we found each other" sheet for a match. Resolves to the created
/// proposal, or null when the member backed out or the request failed (the
/// error is shown inside the sheet).
Future<Graduation?> showProposeGraduationSheet({
  required BuildContext context,
  required String matchId,
  required String partnerName,
}) => showModalBottomSheet<Graduation?>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  useSafeArea: true,
  builder: (_) =>
      _ProposeGraduationSheet(matchId: matchId, partnerName: partnerName),
);

class _ProposeGraduationSheet extends ConsumerStatefulWidget {
  const _ProposeGraduationSheet({
    required this.matchId,
    required this.partnerName,
  });

  final String matchId;
  final String partnerName;

  @override
  ConsumerState<_ProposeGraduationSheet> createState() =>
      _ProposeGraduationSheetState();
}

class _ProposeGraduationSheetState
    extends ConsumerState<_ProposeGraduationSheet> {
  final _note = TextEditingController();
  bool _shareWithFriends = false;
  String? _error;
  bool _submitting = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    final notifier = ref.read(matchGraduationProvider(widget.matchId).notifier);
    final graduation = await notifier.propose(
      note: _note.text,
      shareWithFriends: _shareWithFriends,
    );
    if (!mounted) {
      return;
    }
    if (graduation == null) {
      final l10n = AppLocalizations.of(context);
      final state = ref.read(matchGraduationProvider(widget.matchId));
      setState(() {
        _submitting = false;
        _error = state.error == null
            ? l10n.graduationProposeFailed
            : localizedGraduationError(l10n, state.error!, state.failure);
      });
      return;
    }
    Navigator.of(context).pop(graduation);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.favorite_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: AppLayout.space3),
                Expanded(
                  child: Text(
                    l10n.graduationProposeTitle(widget.partnerName),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppLayout.space3),
            Text(
              l10n.graduationProposeBody(widget.partnerName),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppLayout.space4),
            TextField(
              key: const ValueKey('qa.graduation.note'),
              controller: _note,
              maxLength: 200,
              maxLines: 3,
              minLines: 2,
              decoration: InputDecoration(
                labelText: l10n.graduationNoteLabel,
                hintText: l10n.graduationNoteHint,
              ),
            ),
            const SizedBox(height: AppLayout.space2),
            SwitchListTile(
              key: const ValueKey('qa.graduation.share_switch'),
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.graduationTellFriends),
              subtitle: Text(l10n.graduationTellFriendsBody),
              value: _shareWithFriends,
              onChanged: (value) => setState(() => _shareWithFriends = value),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppLayout.space3),
              Text(
                _error!,
                key: const ValueKey('qa.graduation.error'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: AppLayout.space5),
            SizedBox(
              width: double.infinity,
              height: AppLayout.minTapTarget,
              child: FilledButton.icon(
                key: const ValueKey('qa.graduation.submit'),
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(l10n.graduationAskThem),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
