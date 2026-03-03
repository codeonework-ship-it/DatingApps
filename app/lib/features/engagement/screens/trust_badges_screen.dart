import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/trust_badges_provider.dart';

class TrustBadgesScreen extends ConsumerWidget {
  const TrustBadgesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(trustBadgesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Trust Badges')),
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
              const Text(
                'Earned Badges',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              if (state.badges.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No badges yet. Complete activities to unlock trust badges.',
                    ),
                  ),
                )
              else
                ...state.badges.map(
                  (badge) => Card(
                    child: ListTile(
                      title: Text(badge.label),
                      subtitle: Text(
                        'Code: ${badge.code}\nStatus: ${badge.status} • Awarded ${badge.awardedAt}',
                      ),
                      isThreeLine: true,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              const Text(
                'Recent History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              if (state.history.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No trust history available yet.'),
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
                      trailing: Text(item.happenedAt),
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
    if (state.milestones.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Milestone status unavailable.'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Milestone',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...state.milestones.entries.map(
              (entry) => Text('${entry.key}: ${entry.value}'),
            ),
          ],
        ),
      ),
    );
  }
}
