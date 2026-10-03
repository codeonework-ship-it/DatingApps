import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../engagement_l10n.dart';
import '../providers/circle_challenge_provider.dart';

/// The server refuses entries longer than this (`circleChallengeMaxChars`).
const kCircleEntryMaxChars = 280;

class CircleChallengesScreen extends ConsumerStatefulWidget {
  const CircleChallengesScreen({super.key});

  @override
  ConsumerState<CircleChallengesScreen> createState() =>
      _CircleChallengesScreenState();
}

class _CircleChallengesScreenState
    extends ConsumerState<CircleChallengesScreen> {
  final Map<String, TextEditingController> _controllers =
      <String, TextEditingController>{};

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = engagementL10n(context);
    final state = ref.watch(circleChallengeProvider);
    final notifier = ref.read(circleChallengeProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l.engagementCirclesTitle)),
      body: PostLoginBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              // Errors stay in view above the list: a failed Join or Submit
              // on a lower card used to report below the last card, off
              // screen. With no circles the empty card shows the error.
              if (state.error != null && state.items.isNotEmpty)
                Padding(
                  key: const ValueKey('qa.circles.error'),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Text(
                    state.error!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: notifier.load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (state.isLoading && state.items.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 80),
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        )
                      else if (state.items.isEmpty)
                        _infoCard(
                          context,
                          title: l.engagementCirclesEmptyTitle,
                          subtitle:
                              state.error ?? l.engagementCirclesPullToRefresh,
                        )
                      else ...[
                        ...state.items.map((item) {
                          final controller = _controllerFor(
                            item.id,
                            item.userEntryText,
                          );
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GlassContainer(
                              padding: const EdgeInsets.all(16),
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.surface,
                              blur: 12,
                              crystalEffect: true,
                              borderRadius: BorderRadius.circular(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.city.trim().isEmpty
                                              ? item.topic
                                              : '${item.topic} · ${item.city}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                      _pill(
                                        context,
                                        item.isJoined
                                            ? l.engagementCirclesJoined
                                            : l.engagementCirclesNotJoined,
                                        item.isJoined
                                            ? AppTheme.successGreen
                                            : AppTheme.warningOrange,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    item.promptText,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    l.engagementCirclesParticipants(
                                      item.participationCount,
                                    ),
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                  const SizedBox(height: 10),
                                  if (!item.isJoined)
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton(
                                        key: ValueKey(
                                          'qa.circles.join.${item.id}',
                                        ),
                                        onPressed: state.isSubmitting
                                            ? null
                                            : () =>
                                                  notifier.joinCircle(item.id),
                                        child: Text(l.engagementCirclesJoin),
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    key: ValueKey(
                                      'qa.circles.response.${item.id}',
                                    ),
                                    controller: controller,
                                    minLines: 2,
                                    maxLines: 3,
                                    maxLength: kCircleEntryMaxChars,
                                    decoration: InputDecoration(
                                      labelText:
                                          l.engagementCirclesResponseLabel,
                                      border: const OutlineInputBorder(),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      key: ValueKey(
                                        'qa.circles.submit.${item.id}',
                                      ),
                                      onPressed: state.isSubmitting
                                          ? null
                                          : () => notifier.submitEntry(
                                              circleId: item.id,
                                              challengeId: item.challengeId,
                                              entryText: controller.text,
                                            ),
                                      child: Text(l.engagementCirclesSubmit),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
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

  Widget _pill(BuildContext context, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      label,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: color,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _infoCard(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) => GlassContainer(
    padding: const EdgeInsets.all(16),
    backgroundColor: Theme.of(context).colorScheme.surface,
    blur: 12,
    crystalEffect: true,
    borderRadius: BorderRadius.circular(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );

  TextEditingController _controllerFor(String circleID, String? initialText) {
    final existing = _controllers[circleID];
    if (existing != null) {
      if ((initialText ?? '').trim().isNotEmpty &&
          existing.text.trim().isEmpty) {
        existing.text = initialText!.trim();
      }
      return existing;
    }
    final next = TextEditingController(text: (initialText ?? '').trim());
    _controllers[circleID] = next;
    return next;
  }
}
