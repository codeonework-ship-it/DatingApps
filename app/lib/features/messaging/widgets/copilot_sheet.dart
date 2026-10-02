import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/app_layout.dart';
import '../../social_chat/social_chat_l10n.dart';
import '../providers/copilot_provider.dart';

/// "Help me say it": drafts an opener, a reply or a date idea in the
/// member's voice. Resolves to the draft the member chose to use, or null.
Future<CopilotDraft?> showCopilotSheet({
  required BuildContext context,
  required String matchId,
  required String partnerName,
  required bool conversationStarted,
}) => showModalBottomSheet<CopilotDraft?>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  useSafeArea: true,
  builder: (_) => _CopilotSheet(
    matchId: matchId,
    partnerName: partnerName,
    conversationStarted: conversationStarted,
  ),
);

class _CopilotSheet extends ConsumerStatefulWidget {
  const _CopilotSheet({
    required this.matchId,
    required this.partnerName,
    required this.conversationStarted,
  });

  final String matchId;
  final String partnerName;
  final bool conversationStarted;

  @override
  ConsumerState<_CopilotSheet> createState() => _CopilotSheetState();
}

class _CopilotSheetState extends ConsumerState<_CopilotSheet> {
  late String _kind = widget.conversationStarted ? 'reply' : 'opener';
  String _tone = 'warm';
  CopilotDraft? _draft;
  String? _error;
  bool _loading = false;

  Map<String, String> _kinds(BuildContext context) {
    final l = chatL10n(context);
    return {
      'opener': l.chatCopilotKindOpener,
      'reply': l.chatCopilotKindReply,
      'plan_idea': l.chatCopilotKindDateIdea,
    };
  }

  Map<String, String> _tones(BuildContext context) {
    final l = chatL10n(context);
    return {
      'warm': l.chatCopilotToneWarm,
      'playful': l.chatCopilotTonePlayful,
      'direct': l.chatCopilotToneDirect,
    };
  }

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final draft = await ref
          .read(copilotClientProvider)
          .draft(matchId: widget.matchId, kind: _kind, tone: _tone);
      if (!mounted) {
        return;
      }
      setState(() {
        _draft = draft;
        _loading = false;
      });
    } on CopilotException catch (error) {
      if (!mounted) {
        return;
      }
      final l = chatL10n(context);
      setState(() {
        _error = switch (error.failure) {
          CopilotFailure.empty => l.chatCopilotEmpty,
          CopilotFailure.unavailable => l.chatCopilotUnavailable,
          null => error.message,
        };
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final draft = _draft;
    final l = chatL10n(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l.chatHelpMeSayIt,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppLayout.space2),
          Text(
            l.chatCopilotIntro(widget.partnerName),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppLayout.space4),
          Wrap(
            spacing: AppLayout.space2,
            children: [
              for (final entry in _kinds(context).entries)
                ChoiceChip(
                  key: ValueKey('qa.copilot.kind.${entry.key}'),
                  label: Text(entry.value),
                  selected: _kind == entry.key,
                  onSelected: (_) => setState(() => _kind = entry.key),
                ),
            ],
          ),
          const SizedBox(height: AppLayout.space2),
          Wrap(
            spacing: AppLayout.space2,
            children: [
              for (final entry in _tones(context).entries)
                ChoiceChip(
                  key: ValueKey('qa.copilot.tone.${entry.key}'),
                  label: Text(entry.value),
                  selected: _tone == entry.key,
                  onSelected: (_) => setState(() => _tone = entry.key),
                ),
            ],
          ),
          const SizedBox(height: AppLayout.space4),
          if (draft != null) ...[
            Container(
              key: const ValueKey('qa.copilot.draft'),
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(draft.text, style: theme.textTheme.bodyLarge),
            ),
            const SizedBox(height: AppLayout.space2),
            Text(
              l.chatCopilotDisclosure(draft.disclosure, draft.remainingToday),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppLayout.space3),
          ],
          if (_error != null) ...[
            Text(
              _error!,
              key: const ValueKey('qa.copilot.error'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppLayout.space3),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const ValueKey('qa.copilot.generate'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, AppLayout.minTapTarget),
                  ),
                  onPressed: _loading ? null : _generate,
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome_outlined),
                  label: Text(
                    draft == null
                        ? l.chatCopilotDraftIt
                        : l.chatCopilotTryAnother,
                  ),
                ),
              ),
              if (draft != null) ...[
                const SizedBox(width: AppLayout.space2),
                Expanded(
                  child: FilledButton.icon(
                    key: const ValueKey('qa.copilot.use'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, AppLayout.minTapTarget),
                    ),
                    onPressed: () => Navigator.of(context).pop(draft),
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(l.chatCopilotUseAndEdit),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
