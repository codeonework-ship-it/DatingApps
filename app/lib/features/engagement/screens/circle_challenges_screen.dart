import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../providers/circle_challenge_provider.dart';

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
    final state = ref.watch(circleChallengeProvider);
    final notifier = ref.read(circleChallengeProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Local Circle Challenges')),
      body: PostLoginBackdrop(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: notifier.load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (state.isLoading && state.items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.trustBlue,
                        ),
                      ),
                    ),
                  )
                else if (state.items.isEmpty)
                  _infoCard(
                    context,
                    title: 'No circles available',
                    subtitle: state.error ?? 'Please pull to refresh.',
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
                        padding: const EdgeInsets.all(14),
                        backgroundColor: Colors.white.withValues(alpha: 0.82),
                        blur: 12,
                        crystalEffect: true,
                        borderRadius: BorderRadius.circular(18),
                        shadows: [
                          BoxShadow(
                            color: AppTheme.trustBlue.withValues(alpha: 0.11),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item.topic} · ${item.city}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: AppTheme.textDark,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                                _pill(
                                  context,
                                  item.isJoined ? 'Joined' : 'Not joined',
                                  item.isJoined
                                      ? AppTheme.successGreen
                                      : AppTheme.warningOrange,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.promptText,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${item.participationCount} participants this week',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppTheme.textGrey),
                            ),
                            const SizedBox(height: 10),
                            if (!item.isJoined)
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: state.isSubmitting
                                      ? null
                                      : () => notifier.joinCircle(item.id),
                                  child: const Text('Join Circle'),
                                ),
                              ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: controller,
                              minLines: 2,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Weekly challenge response',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: state.isSubmitting
                                    ? null
                                    : () => notifier.submitEntry(
                                        circleId: item.id,
                                        challengeId: item.challengeId,
                                        entryText: controller.text,
                                      ),
                                child: const Text('Submit Entry'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      state.error!,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppTheme.errorRed),
                    ),
                  ),
              ],
            ),
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
    padding: const EdgeInsets.all(14),
    backgroundColor: Colors.white.withValues(alpha: 0.82),
    blur: 12,
    crystalEffect: true,
    borderRadius: BorderRadius.circular(18),
    shadows: [
      BoxShadow(
        color: AppTheme.trustBlue.withValues(alpha: 0.11),
        blurRadius: 16,
        offset: const Offset(0, 8),
      ),
    ],
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppTheme.textDark,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.textGrey),
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
