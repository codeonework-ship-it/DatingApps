import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/glass_widgets.dart';
import '../../matching/providers/match_provider.dart';
import '../providers/match_nudge_provider.dart';

class MatchNudgesScreen extends ConsumerWidget {
  const MatchNudgesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = ref.watch(matchNotifierProvider);
    final nudges = ref.watch(matchNudgeProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Match nudges')),
      body: PostLoginBackdrop(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GlassContainer(
                padding: const EdgeInsets.all(16),
                backgroundColor: Theme.of(context).colorScheme.surface,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.notifications_active,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Send a gentle reminder to restart a quiet conversation. '
                        'Daily limits and safety rules are enforced by the server.',
                        style: TextStyle(height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (matches.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (matches.matches.isEmpty)
                const Center(child: Text('No matches available to nudge.'))
              else
                for (final match in matches.matches)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GlassContainer(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                            child: Text(
                              match.userName.isEmpty
                                  ? '?'
                                  : match.userName[0].toUpperCase(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  match.userName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  nudges.errorByMatchId[match.id] ??
                                      (nudges.sentByMatchId.containsKey(
                                            match.id,
                                          )
                                          ? 'Nudge sent in this session'
                                          : 'Ready to send'),
                                  style: TextStyle(
                                    color:
                                        nudges.errorByMatchId[match.id] != null
                                        ? Theme.of(context).colorScheme.error
                                        : Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          FilledButton.tonalIcon(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 40),
                            ),
                            onPressed: nudges.sendingMatchIds.contains(match.id)
                                ? null
                                : () async {
                                    final result = await ref
                                        .read(matchNudgeProvider.notifier)
                                        .send(
                                          matchId: match.id,
                                          counterpartyUserId: match.userId,
                                        );
                                    if (!context.mounted || result == null) {
                                      return;
                                    }
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Nudge sent to ${match.userName}.',
                                        ),
                                      ),
                                    );
                                  },
                            icon: nudges.sendingMatchIds.contains(match.id)
                                ? const SizedBox.square(
                                    dimension: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.waving_hand_outlined),
                            label: const Text('Nudge'),
                          ),
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
