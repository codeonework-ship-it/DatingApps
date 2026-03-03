import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../providers/daily_prompt_provider.dart';

class DailyPromptScreen extends ConsumerStatefulWidget {
  const DailyPromptScreen({super.key});

  @override
  ConsumerState<DailyPromptScreen> createState() => _DailyPromptScreenState();
}

class _DailyPromptScreenState extends ConsumerState<DailyPromptScreen> {
  final _answerController = TextEditingController();
  String? _syncedAnswer;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dailyPromptProvider);
    final notifier = ref.read(dailyPromptProvider.notifier);
    final view = state.view;
    final answer = view?.answer;

    if (answer != null && _syncedAnswer != answer.answerText) {
      _syncedAnswer = answer.answerText;
      _answerController.text = answer.answerText;
      _answerController.selection = TextSelection.collapsed(
        offset: _answerController.text.length,
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Prompt Streak')),
      body: PostLoginBackdrop(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: notifier.load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (state.isLoading && view == null)
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
                else if (view == null)
                  _InfoCard(
                    title: 'Daily prompt unavailable',
                    subtitle:
                        state.error ?? 'Pull to refresh or try again in a bit.',
                    icon: Icons.error_outline_rounded,
                  )
                else ...[
                  _StreakCard(view: view),
                  const SizedBox(height: 10),
                  _InfoCard(
                    title: view.prompt.domain
                        .replaceAll('_', ' ')
                        .toUpperCase(),
                    subtitle: view.prompt.promptText,
                    icon: Icons.lightbulb_outline_rounded,
                  ),
                  const SizedBox(height: 10),
                  _InfoCard(
                    title: 'Compatibility Spark',
                    subtitle:
                        '${view.spark.participantsToday} replied today · ${view.spark.similarAnswerCount} similar answers',
                    icon: Icons.people_alt_outlined,
                  ),
                  const SizedBox(height: 10),
                  GlassContainer(
                    padding: const EdgeInsets.all(14),
                    backgroundColor: Colors.white.withValues(alpha: 0.84),
                    blur: 8,
                    borderRadius: BorderRadius.circular(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your answer',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: AppTheme.textDark,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _answerController,
                          minLines: 3,
                          maxLines: 4,
                          maxLength: view.prompt.maxChars,
                          enabled: answer == null || answer.canEdit,
                          decoration: InputDecoration(
                            hintText: 'Type your response in under 60 seconds.',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        if (answer != null) ...[
                          Text(
                            answer.canEdit
                                ? 'Edit window open until ${_formatTime(answer.editWindowUntil)}'
                                : 'Edit window closed for today.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: answer.canEdit
                                      ? AppTheme.textGrey
                                      : AppTheme.warningOrange,
                                ),
                          ),
                          if (answer.isEdited)
                            Text(
                              'Edited',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppTheme.textHint),
                            ),
                        ],
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                state.isSubmitting ||
                                    (answer != null && !answer.canEdit)
                                ? null
                                : () => notifier.submitAnswer(
                                    _answerController.text,
                                  ),
                            child: state.isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(
                                    answer == null
                                        ? 'Submit Daily Answer'
                                        : 'Update Answer',
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (state.error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      state.error!,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppTheme.errorRed),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime? value) {
    if (value == null) {
      return 'soon';
    }
    final local = value.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.view});

  final DailyPromptView view;

  @override
  Widget build(BuildContext context) {
    final streak = view.streak;
    return GlassContainer(
      padding: const EdgeInsets.all(14),
      backgroundColor: Colors.white.withValues(alpha: 0.85),
      blur: 8,
      borderRadius: BorderRadius.circular(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Streak Progress',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppTheme.textDark,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatPill(label: 'Current', value: '${streak.currentDays}d'),
              _StatPill(label: 'Best', value: '${streak.longestDays}d'),
              _StatPill(
                label: 'Next',
                value: streak.nextMilestone > 0
                    ? '${streak.nextMilestone}d'
                    : 'Complete',
              ),
            ],
          ),
          if (streak.milestoneReached > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Milestone unlocked: ${streak.milestoneReached}-day streak',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.successGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      color: Colors.white,
      border: Border.all(color: AppTheme.textHint.withValues(alpha: 0.25)),
    ),
    child: Text(
      '$label: $value',
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
    ),
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) => GlassContainer(
    padding: const EdgeInsets.all(14),
    backgroundColor: Colors.white.withValues(alpha: 0.83),
    blur: 8,
    borderRadius: BorderRadius.circular(18),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: AppTheme.trustBlue.withValues(alpha: 0.14),
          ),
          child: Icon(icon, color: AppTheme.trustBlue, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
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
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.textGrey),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
