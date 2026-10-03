import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/app_layout.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../models/graduation.dart';
import '../models/graduation_labels.dart';
import '../providers/graduation_provider.dart';
import '../screens/graduation_celebration_screen.dart';

/// Buttons inside the banner meet the 48pt tap-target guideline.
const _tapTarget = Size(AppLayout.minTapTarget, AppLayout.minTapTarget);

/// The graduation banner at the top of a conversation. Shown only while a
/// proposal is open or once the pair has graduated; the entry point for a new
/// proposal lives in the match options sheet.
class GraduationBanner extends ConsumerWidget {
  const GraduationBanner({
    required this.matchId,
    required this.partnerName,
    super.key,
  });

  final String matchId;
  final String partnerName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(matchGraduationProvider(matchId));
    final graduation = state.graduation;
    if (!state.loaded || graduation == null) {
      return const SizedBox.shrink();
    }
    if (!graduation.isOpen && !graduation.isConfirmed) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(matchGraduationProvider(matchId).notifier);
    return Semantics(
      identifier: 'qa.graduation.banner.${graduation.status}',
      container: true,
      // The chat screen caps the banner's height; it scrolls inside that cap
      // at large text scales so the conversation stays usable.
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: GlassContainer(
          key: ValueKey('qa.graduation.banner.${graduation.status}'),
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          padding: const EdgeInsets.all(16),
          backgroundColor: theme.colorScheme.surface,
          blur: 10,
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    graduation.isConfirmed
                        ? Icons.celebration_rounded
                        : Icons.favorite_rounded,
                    color: graduation.isConfirmed
                        ? AppTheme.successGreen
                        : theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppLayout.space3),
                  Expanded(
                    child: Text(
                      _headline(l10n, graduation),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppLayout.space2),
              Text(
                _body(l10n, graduation),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (graduation.note.isNotEmpty && graduation.isOpen) ...[
                const SizedBox(height: AppLayout.space1),
                Text(
                  l10n.planQuotedNote(graduation.note),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              if (state.error != null) ...[
                const SizedBox(height: AppLayout.space2),
                Text(
                  localizedGraduationError(l10n, state.error!, state.failure),
                  key: const ValueKey('qa.graduation.banner_error'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: AppLayout.space3),
              _Actions(
                matchId: matchId,
                partnerName: partnerName,
                graduation: graduation,
                busy: state.isMutating,
                notifier: notifier,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _headline(AppLocalizations l10n, Graduation graduation) {
    if (graduation.isConfirmed) {
      return l10n.graduationFoundEachOther;
    }
    return graduation.viewerDecides
        ? l10n.graduationHeadlineDecide(partnerName)
        : l10n.graduationHeadlineWaiting(partnerName);
  }

  String _body(AppLocalizations l10n, Graduation graduation) {
    if (graduation.isConfirmed) {
      return l10n.graduationBodyConfirmed;
    }
    return graduation.viewerDecides
        ? l10n.graduationBodyDecide
        : l10n.graduationBodyWaiting;
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.matchId,
    required this.partnerName,
    required this.graduation,
    required this.busy,
    required this.notifier,
  });

  final String matchId;
  final String partnerName;
  final Graduation graduation;
  final bool busy;
  final MatchGraduationNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (graduation.isConfirmed) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          key: const ValueKey('qa.graduation.celebrate'),
          style: FilledButton.styleFrom(minimumSize: _tapTarget),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => GraduationCelebrationScreen(
                matchId: matchId,
                partnerName: partnerName,
              ),
            ),
          ),
          icon: const Icon(Icons.celebration_rounded),
          label: Text(l10n.graduationCelebrate),
        ),
      );
    }
    if (graduation.viewerDecides) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              key: const ValueKey('qa.graduation.decline'),
              style: OutlinedButton.styleFrom(minimumSize: _tapTarget),
              onPressed: busy
                  ? null
                  : () => notifier.decide(
                      graduationId: graduation.id,
                      confirm: false,
                    ),
              child: Text(l10n.graduationNotYet),
            ),
          ),
          const SizedBox(width: AppLayout.space2),
          Expanded(
            child: FilledButton(
              key: const ValueKey('qa.graduation.confirm'),
              style: FilledButton.styleFrom(minimumSize: _tapTarget),
              onPressed: busy
                  ? null
                  : () => Navigator.of(context).push(
                      MaterialPageRoute<Graduation?>(
                        builder: (_) => GraduationCelebrationScreen(
                          matchId: matchId,
                          partnerName: partnerName,
                          pendingGraduationId: graduation.id,
                        ),
                      ),
                    ),
              child: Text(l10n.graduationConfirm),
            ),
          ),
        ],
      );
    }
    return Row(
      children: [
        Expanded(
          child: Text(
            graduation.shareWithFriends
                ? l10n.graduationFriendsToldOnConfirm
                : l10n.graduationOnlyTwoOfYouForNow,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        TextButton(
          key: const ValueKey('qa.graduation.withdraw'),
          style: TextButton.styleFrom(minimumSize: _tapTarget),
          onPressed: busy
              ? null
              : () => notifier.withdraw(graduationId: graduation.id),
          child: Text(l10n.graduationWithdraw),
        ),
      ],
    );
  }
}
