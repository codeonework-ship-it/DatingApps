import 'package:flutter/material.dart';

import '../../core/i18n/app_l10n.dart';
import '../../core/theme/app_theme.dart';
import 'reactions.dart';

/// Asks how the member feels about a chapter or photo. Returns the chosen
/// reaction id, an empty string to remove the member's reaction, or null when
/// dismissed.
Future<String?> showReactionPicker(
  BuildContext context, {
  required String current,
  required String noun,
}) => showModalBottomSheet<String>(
  context: context,
  showDragHandle: true,
  builder: (sheet) => ReactionPicker(current: current, noun: noun),
);

/// The picker sheet's content: six empathetic reactions, the current one
/// highlighted, and a way to take the reaction back.
class ReactionPicker extends StatelessWidget {
  const ReactionPicker({required this.current, required this.noun, super.key});

  /// The member's reaction id, or empty.
  final String current;

  /// "chapter" or "photo".
  final String noun;

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOrEnglish(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.wallsReactEyebrow,
              style: theme.textTheme.labelMedium?.copyWith(
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Semantics(
              header: true,
              child: Text(
                l10n.wallsReactQuestion(noun),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontFamily: AppTheme.displayFamily,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.wallsReactBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, box) {
                const gap = 8.0;
                final columns = box.maxWidth >= 520 ? 3 : 2;
                final width = (box.maxWidth - gap * (columns - 1)) / columns;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final r in empathyReactions)
                      SizedBox(
                        width: width,
                        child: _ReactionOption(
                          reaction: r,
                          selected: r.id == current,
                        ),
                      ),
                  ],
                );
              },
            ),
            if (current.isNotEmpty) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                key: const ValueKey('reaction.remove'),
                onPressed: () => Navigator.of(context).pop(''),
                icon: const Icon(Icons.undo_rounded),
                label: Text(l10n.wallsReactRemove),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReactionOption extends StatelessWidget {
  const _ReactionOption({required this.reaction, required this.selected});
  final EmpathyReaction reaction;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOrEnglish(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    const radius = BorderRadius.all(Radius.circular(16));
    return Semantics(
      button: true,
      selected: selected,
      label: localizedEmpathyLabel(l10n, reaction),
      excludeSemantics: true,
      child: Material(
        color: selected ? colors.primaryContainer : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: selected ? colors.primary : colors.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          key: ValueKey('reaction.option.${reaction.id}'),
          borderRadius: radius,
          onTap: () => Navigator.of(context).pop(reaction.id),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Text(reaction.emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      localizedEmpathyLabel(l10n, reaction),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? colors.onPrimaryContainer
                            : colors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// How readers reacted: the most-used reactions as small emoji pills with
/// counts, e.g. "🫶 3  🤝 2". Renders nothing when nobody reacted.
class ReactionSummary extends StatelessWidget {
  const ReactionSummary({required this.reactions, super.key, this.max = 3});
  final Map<String, int> reactions;
  final int max;

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOrEnglish(context);
    if (reactions.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final ranked = [
      for (final r in empathyReactions)
        if ((reactions[r.id] ?? 0) > 0) r,
    ]..sort((a, b) => reactions[b.id]!.compareTo(reactions[a.id]!));
    final shown = ranked.take(max).toList();
    final label = shown
        .map((r) => '${reactions[r.id]} ${localizedEmpathyLabel(l10n, r)}')
        .join(', ');
    return Semantics(
      label: l10n.wallsReactionsSemantics(label),
      excludeSemantics: true,
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          for (final r in shown)
            Tooltip(
              message: localizedEmpathyLabel(l10n, r),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Text(
                  '${r.emoji} ${reactions[r.id]}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
