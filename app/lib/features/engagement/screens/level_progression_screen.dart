import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../celebrations/reward_burst.dart';
import '../engagement_l10n.dart';
import '../providers/level_progression_provider.dart';

class LevelProgressionScreen extends ConsumerWidget {
  const LevelProgressionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = engagementL10n(context);
    final state = ref.watch(levelProgressionProvider);
    final view = state.view;
    return Scaffold(
      appBar: AppBar(title: Text(l.engagementLevelTitle)),
      body: PostLoginBackdrop(
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // With progress on screen, an error (a failed claim or
              // refresh) stays in view above it; it used to appear after the
              // last ledger row, off screen.
              if (state.error != null && view != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _ErrorCard(
                    message: state.error!,
                    onRetry: ref.read(levelProgressionProvider.notifier).load,
                  ),
                ),
              Expanded(
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
                          _Notice(
                            icon: Icons.shield_outlined,
                            text: l.engagementLevelFrozen,
                          ),
                        if (!view.trustGateSatisfied && view.currentLevel >= 4)
                          _Notice(
                            icon: Icons.verified_user_outlined,
                            text: l.engagementLevelTrustGate,
                          ),
                        const SizedBox(height: 16),
                        _SectionTitle(
                          title: l.engagementLevelPathTitle,
                          subtitle: l.engagementLevelPathSubtitle,
                        ),
                        ...view.levels.map(
                          (item) => _LevelRow(
                            definition: item,
                            currentLevel: view.currentLevel,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SectionTitle(
                          title: l.engagementLevelRewardsTitle,
                          subtitle: l.engagementLevelRewardsSubtitle,
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
                                      _rewardName(
                                        engagementL10n(context),
                                        reward,
                                      ),
                                      description: reward.description,
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SectionTitle(
                          title: l.engagementLevelRecentTitle,
                          subtitle: l.engagementLevelRecentSubtitle,
                        ),
                        if (state.ledger.isEmpty)
                          const _EmptyLedger()
                        else
                          ...state.ledger.map(_XPRow.new),
                      ],
                      if (state.error != null && view == null) ...[
                        const SizedBox(height: 12),
                        _ErrorCard(
                          message: state.error!,
                          onRetry: ref
                              .read(levelProgressionProvider.notifier)
                              .load,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
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
    final l = engagementL10n(context);
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
                      l.engagementLevelNumber(view.currentLevel),
                      style: TextStyle(color: scheme.primary),
                    ),
                    if (view.levelName.trim().isNotEmpty)
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
                l.engagementLevelXp(_count(l, view.totalXp)),
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
                ? l.engagementLevelHighest
                : l.engagementLevelProgress(
                    view.currentLevelXp,
                    NumberFormat.decimalPattern(
                      l.localeName,
                    ).format(view.progressPercent.round()),
                  ),
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
                    definition.name.trim().isEmpty
                        ? engagementL10n(
                            context,
                          ).engagementLevelNumber(definition.level)
                        : definition.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    engagementL10n(context).engagementLevelThreshold(
                      definition.thresholdXp,
                      definition.rewardSummary,
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (definition.trustGate)
              Tooltip(
                message: engagementL10n(context).engagementLevelTrustGated,
                child: const Icon(Icons.verified_user_outlined, size: 20),
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
    final l = engagementL10n(context);
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
                    _rewardName(l, reward),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                Text(
                  l.engagementLevelNumber(reward.level),
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
                key: ValueKey('qa.level.claim.${reward.key}'),
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
                      ? l.engagementLevelClaimed
                      : unlocked
                      ? l.engagementLevelClaim
                      : l.engagementLevelLocked,
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
  Widget build(BuildContext context) {
    final l = engagementL10n(context);
    return ListTile(
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
      title: Text(_sourceLabel(l, entry.source)),
      subtitle: Text(
        entry.multiplier == 1
            ? l.engagementLevelStandardAward
            : l.engagementLevelQualityWeighting(
                NumberFormat('0.00', l.localeName).format(entry.multiplier),
              ),
      ),
      trailing: Text(
        l.engagementLevelXp(
          '${entry.awardedXp >= 0 ? '+' : ''}${_count(l, entry.awardedXp)}',
        ),
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _EmptyLedger extends StatelessWidget {
  const _EmptyLedger();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Center(
      child: Text(engagementL10n(context).engagementLevelEmptyLedger),
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
      trailing: TextButton(
        key: const ValueKey('qa.level.retry'),
        onPressed: onRetry,
        child: Text(engagementL10n(context).commonRetry),
      ),
    ),
  );
}

/// A friendly name for a known XP ledger source; unknown sources are shown
/// as their code in title case.
String _sourceLabel(AppLocalizations l, String source) => switch (source) {
  'profile_completed' => l.engagementXpSourceProfileCompleted,
  'daily_prompt_submitted' => l.engagementXpSourceDailyPromptSubmitted,
  'mini_activity_completed' => l.engagementXpSourceMiniActivityCompleted,
  'circle_challenge_submitted' => l.engagementXpSourceCircleChallengeSubmitted,
  'voice_icebreaker_played' => l.engagementXpSourceVoiceIcebreakerPlayed,
  'streak_3' => l.engagementXpSourceStreak3,
  'streak_7' => l.engagementXpSourceStreak7,
  'streak_14' => l.engagementXpSourceStreak14,
  'admin_adjustment' => l.engagementXpSourceAdminAdjustment,
  _ =>
    source
        .split('_')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' '),
};

/// [value] with the member's digit grouping ("1,250" / "1.250").
String _count(AppLocalizations l, int value) =>
    NumberFormat.decimalPattern(l.localeName).format(value);

/// The reward's server name, or "Level 3 reward" in the member's language.
String _rewardName(AppLocalizations l, LevelReward reward) =>
    reward.name.trim().isEmpty
    ? l.engagementLevelRewardFallback(reward.level)
    : reward.name;
