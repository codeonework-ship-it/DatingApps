import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../celebrations/reward_burst.dart';
import '../providers/level_progression_provider.dart';

class LevelProgressionScreen extends ConsumerWidget {
  const LevelProgressionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(levelProgressionProvider);
    final view = state.view;
    return Scaffold(
      appBar: AppBar(title: const Text('Level & XP')),
      body: PostLoginBackdrop(
        child: SafeArea(
          top: false,
          child: RefreshIndicator(
            onRefresh: ref.read(levelProgressionProvider.notifier).load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                if (state.isLoading && view == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (view != null) ...[
                  _LevelHero(view: view),
                  if (view.frozen)
                    const _Notice(
                      icon: Icons.shield_outlined,
                      text:
                          'Progression is paused while an account safety '
                          'review is active.',
                    ),
                  if (!view.trustGateSatisfied && view.currentLevel >= 4)
                    const _Notice(
                      icon: Icons.verified_user_outlined,
                      text:
                          'Verify your profile and maintain a healthy account '
                          'to unlock trust-gated levels.',
                    ),
                  const SizedBox(height: 16),
                  const _SectionTitle(
                    title: 'Level path',
                    subtitle:
                        'XP comes from meaningful activity. Purchases never '
                        'increase your level.',
                  ),
                  ...view.levels.map(
                    (item) => _LevelRow(
                      definition: item,
                      currentLevel: view.currentLevel,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _SectionTitle(
                    title: 'Rewards',
                    subtitle:
                        'Earned rewards are cosmetic, convenience, or bounded '
                        'visibility benefits.',
                  ),
                  ...view.rewards.map(
                    (reward) => _RewardCard(
                      reward: reward,
                      unlocked: view.currentLevel >= reward.level,
                      trustSatisfied: view.trustGateSatisfied,
                      frozen: view.frozen,
                      claiming: state.claimingReward == reward.key,
                      onClaim: () async {
                        final claimed = await ref
                            .read(levelProgressionProvider.notifier)
                            .claimReward(reward.key);
                        if (context.mounted && claimed) {
                          unawaited(
                            showRewardBurst(
                              context,
                              RewardBurst.rewardClaimed(
                                reward.name,
                                description: reward.description,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _SectionTitle(
                    title: 'Recent XP',
                    subtitle:
                        'Your activity ledger is permanent and auditable.',
                  ),
                  if (state.ledger.isEmpty)
                    const _EmptyLedger()
                  else
                    ...state.ledger.map(_XPRow.new),
                ],
                if (state.error != null) ...[
                  const SizedBox(height: 12),
                  _ErrorCard(
                    message: state.error!,
                    onRetry: ref.read(levelProgressionProvider.notifier).load,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelHero extends StatelessWidget {
  const _LevelHero({required this.view});
  final LevelProgressionView view;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      backgroundColor: scheme.surface,
      border: Border.all(color: scheme.outlineVariant),
      blur: 12,
      borderRadius: const BorderRadius.all(Radius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: scheme.primaryContainer,
                child: Text(
                  '${view.currentLevel}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level ${view.currentLevel}',
                      style: TextStyle(color: scheme.primary),
                    ),
                    Text(
                      view.levelName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${view.totalXp} XP',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: (view.progressPercent / 100).clamp(0, 1),
              color: AppTheme.marigold,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            view.nextLevelXp == null
                ? 'Highest level reached'
                : '${view.currentLevelXp} XP in this level · '
                      '${view.progressPercent.toStringAsFixed(0)}%',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: GlassContainer(
      padding: const EdgeInsets.all(12),
      backgroundColor: AppTheme.marigold.withValues(alpha: 0.14),
      blur: 8,
      borderRadius: const BorderRadius.all(Radius.circular(14)),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.onSurface),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}

class _LevelRow extends StatelessWidget {
  const _LevelRow({required this.definition, required this.currentLevel});
  final LevelDefinition definition;
  final int currentLevel;
  @override
  Widget build(BuildContext context) {
    final reached = currentLevel >= definition.level;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassContainer(
        padding: const EdgeInsets.all(12),
        backgroundColor: Theme.of(context).colorScheme.surface,
        blur: 8,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: reached
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              foregroundColor: reached
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              child: Text('${definition.level}'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    definition.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${definition.thresholdXp} XP · '
                    '${definition.rewardSummary}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (definition.trustGate)
              const Tooltip(
                message: 'Trust-gated',
                child: Icon(Icons.verified_user_outlined, size: 20),
              ),
          ],
        ),
      ),
    );
  }
}

class _RewardCard extends StatelessWidget {
  const _RewardCard({
    required this.reward,
    required this.unlocked,
    required this.trustSatisfied,
    required this.frozen,
    required this.claiming,
    required this.onClaim,
  });
  final LevelReward reward;
  final bool unlocked;
  final bool trustSatisfied;
  final bool frozen;
  final bool claiming;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final canClaim =
        unlocked &&
        (!reward.trustRequired || trustSatisfied) &&
        !frozen &&
        !reward.claimed;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        backgroundColor: Theme.of(context).colorScheme.surface,
        blur: 8,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    reward.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  'Level ${reward.level}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(reward.description),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: canClaim && !claiming ? onClaim : null,
                icon: claiming
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        reward.claimed
                            ? Icons.check_rounded
                            : unlocked
                            ? Icons.redeem_rounded
                            : Icons.lock_outline_rounded,
                      ),
                label: Text(
                  reward.claimed
                      ? 'Claimed'
                      : unlocked
                      ? 'Claim'
                      : 'Locked',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _XPRow extends StatelessWidget {
  const _XPRow(this.entry);
  final XPEntry entry;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    leading: CircleAvatar(
      backgroundColor: entry.awardedXp >= 0
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.errorContainer,
      child: Icon(
        entry.awardedXp >= 0 ? Icons.add_rounded : Icons.remove_rounded,
        color: entry.awardedXp >= 0
            ? Theme.of(context).colorScheme.onPrimaryContainer
            : Theme.of(context).colorScheme.onErrorContainer,
      ),
    ),
    title: Text(_sourceLabel(entry.source)),
    subtitle: Text(
      entry.multiplier == 1
          ? 'Standard award'
          : '${entry.multiplier.toStringAsFixed(2)}× quality weighting',
    ),
    trailing: Text(
      '${entry.awardedXp >= 0 ? '+' : ''}${entry.awardedXp} XP',
      style: const TextStyle(fontWeight: FontWeight.w800),
    ),
  );
}

class _EmptyLedger extends StatelessWidget {
  const _EmptyLedger();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 20),
    child: Center(
      child: Text('Complete meaningful activities to earn your first XP.'),
    ),
  );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.errorContainer,
    child: ListTile(
      leading: const Icon(Icons.error_outline_rounded),
      title: Text(message),
      trailing: TextButton(onPressed: onRetry, child: const Text('Retry')),
    ),
  );
}

String _sourceLabel(String source) => source
    .split('_')
    .map(
      (word) =>
          word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1)}',
    )
    .join(' ');
