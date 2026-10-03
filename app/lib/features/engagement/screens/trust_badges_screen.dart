import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../matching/matching_l10n.dart';
import '../../matching/providers/trust_filter_provider.dart';
import '../engagement_l10n.dart';
import '../providers/trust_badges_provider.dart';

class TrustBadgesScreen extends ConsumerWidget {
  const TrustBadgesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = engagementL10n(context);
    final state = ref.watch(trustBadgesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTrustBadgesTitle)),
      body: RefreshIndicator(
        onRefresh: () => ref.read(trustBadgesProvider.notifier).load(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (state.isLoading && state.badges.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              _MilestoneCard(state: state),
              const SizedBox(height: 16),
              Text(
                l.engagementTrustBadgesEarned,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              if (state.badges.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(l.engagementTrustBadgesEmpty),
                  ),
                )
              else
                ...state.badges.map(
                  (badge) => Card(
                    child: ListTile(
                      title: Text(
                        localizedTrustBadgeLabel(
                          l,
                          TrustBadgeOption(
                            code: badge.code,
                            label: badge.label,
                          ),
                        ),
                      ),
                      subtitle: Text(
                        l.engagementTrustBadgesDetails(
                          badge.code,
                          badge.status,
                          badge.awardedAt,
                        ),
                      ),
                      isThreeLine: true,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                l.engagementTrustBadgesHistory,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              if (state.history.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(l.engagementTrustBadgesHistoryEmpty),
                  ),
                )
              else
                ...state.history.map(
                  (item) => Card(
                    child: ListTile(
                      title: Text(item.action),
                      subtitle: Text(
                        item.reason.isEmpty ? item.code : item.reason,
                      ),
                      trailing: SizedBox(
                        width: 90,
                        child: Text(
                          item.happenedAt.split('T').first,
                          maxLines: 2,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
            if (state.error != null) ...[
              const SizedBox(height: 16),
              Text(
                state.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({required this.state});

  final TrustBadgesState state;

  @override
  Widget build(BuildContext context) {
    final l = engagementL10n(context);
    if (state.milestones.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(l.engagementTrustBadgesMilestoneUnavailable),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.engagementTrustBadgesCurrentMilestone,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            for (final entry in state.milestones.entries)
              if (!_hiddenMilestoneKeys.contains(entry.key))
                Text(
                  l.engagementTrustMilestoneLine(
                    trustMilestoneLabel(l, entry.key),
                    _milestoneValue(l, entry.value),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

/// Bookkeeping fields the server sends with the scores; not for members.
const _hiddenMilestoneKeys = {'user_id', 'last_computed_at'};

/// A trust milestone's translated label. Unknown keys read as words
/// ("reply_speed_score" → "Reply speed"), never as snake_case.
String trustMilestoneLabel(AppLocalizations l, String key) => switch (key) {
  'profile_depth_score' => l.engagementTrustMilestoneProfileDepth,
  'communication_score' => l.engagementTrustMilestoneCommunication,
  'consistency_score' => l.engagementTrustMilestoneConsistency,
  'prompt_completion_score' => l.engagementTrustMilestonePromptCompletion,
  'activity_signal_count' => l.engagementTrustMilestoneActivitySignals,
  'unsafe_signal_count' => l.engagementTrustMilestoneUnsafeSignals,
  'report_risk_penalty' => l.engagementTrustMilestoneReportPenalty,
  'verification_consistent' => l.engagementTrustMilestoneVerification,
  'safety_score' => l.engagementTrustMilestoneSafety,
  _ => _humanizeMilestoneKey(key),
};

String _humanizeMilestoneKey(String key) {
  final words = key
      .replaceAll(RegExp(r'_(score|count)$'), '')
      .replaceAll(RegExp(r'[_\-]+'), ' ')
      .trim();
  return words.isEmpty
      ? key
      : '${words[0].toUpperCase()}${words.substring(1).toLowerCase()}';
}

String _milestoneValue(AppLocalizations l, Object? value) => switch (value) {
  true => l.commonYes,
  false => l.commonNo,
  null => '–',
  _ => '$value',
};
