import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/app_layout.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../models/graduation.dart';
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
    final notifier = ref.read(matchGraduationProvider(matchId).notifier);
    return Semantics(
      label: 'qa.graduation.banner.${graduation.status}',
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
                      _headline(graduation),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppLayout.space2),
              Text(
                _body(graduation),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (graduation.note.isNotEmpty && graduation.isOpen) ...[
                const SizedBox(height: AppLayout.space1),
                Text(
                  '“${graduation.note}”',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              if (state.error != null) ...[
                const SizedBox(height: AppLayout.space2),
                Text(
                  state.error!,
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

  String _headline(Graduation graduation) {
    if (graduation.isConfirmed) {
      return 'You found each other';
    }
    return graduation.viewerDecides
        ? '$partnerName wants to leave Connect together'
        : 'Waiting for $partnerName';
  }

  String _body(Graduation graduation) {
    if (graduation.isConfirmed) {
      return 'You are both hidden from discovery. This chat stays open.';
    }
    return graduation.viewerDecides
        ? 'Confirm and you both leave discovery. Your chat stays.'
        : 'You asked to leave together. They can confirm or decline.';
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
          label: const Text('Celebrate'),
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
              child: const Text('Not yet'),
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
              child: const Text('Confirm'),
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
                ? 'Your friends are told once they confirm.'
                : 'Only the two of you know for now.',
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
          child: const Text('Withdraw'),
        ),
      ],
    );
  }
}
