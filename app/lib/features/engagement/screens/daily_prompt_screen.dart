import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../engagement_l10n.dart';
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
    final l = engagementL10n(context);
    final state = ref.watch(dailyPromptProvider);
    final notifier = ref.read(dailyPromptProvider.notifier);
    final view = state.view;
    final answer = view?.answer;
    final scheme = Theme.of(context).colorScheme;

    if (answer != null && _syncedAnswer != answer.answerText) {
      _syncedAnswer = answer.answerText;
      _answerController.text = answer.answerText;
      _answerController.selection = TextSelection.collapsed(
        offset: _answerController.text.length,
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.engagementDailyPromptTitle)),
      body: PostLoginBackdrop(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: notifier.load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (state.isLoading && view == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 80),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          scheme.primary,
                        ),
                      ),
                    ),
                  )
                else if (view == null)
                  _InfoCard(
                    title: l.engagementDailyPromptUnavailable,
                    subtitle:
                        state.error ?? l.engagementDailyPromptPullToRefresh,
                    icon: Icons.error_outline_rounded,
                  )
                else ...[
                  _StreakCard(view: view),
                  const SizedBox(height: 10),
                  _InfoCard(
                    title: _domainLabel(l, view.prompt.domain),
                    subtitle: view.prompt.promptText,
                    icon: Icons.lightbulb_outline_rounded,
                  ),
                  const SizedBox(height: 10),
                  _InfoCard(
                    title: l.engagementDailyPromptSparkTitle,
                    subtitle: l.engagementDailyPromptSparkSummary(
                      view.spark.participantsToday,
                      view.spark.similarAnswerCount,
                    ),
                    icon: Icons.people_alt_outlined,
                  ),
                  const SizedBox(height: 10),
                  GlassContainer(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: scheme.surface,
                    blur: 8,
                    borderRadius: BorderRadius.circular(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.engagementDailyPromptYourAnswer,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          key: const ValueKey('qa.daily_prompt.answer'),
                          controller: _answerController,
                          minLines: 3,
                          maxLines: 4,
                          maxLength: view.prompt.maxChars,
                          enabled: answer == null || answer.canEdit,
                          decoration: InputDecoration(
                            hintText: l.engagementDailyPromptHint,
                            filled: true,
                            fillColor: scheme.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        if (answer != null) ...[
                          Text(
                            !answer.canEdit
                                ? l.engagementDailyPromptEditClosed
                                : answer.editWindowUntil == null
                                ? l.engagementDailyPromptEditOpenSoon
                                : l.engagementDailyPromptEditOpenUntil(
                                    _formatTime(answer.editWindowUntil!),
                                  ),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: answer.canEdit
                                      ? scheme.onSurfaceVariant
                                      : AppTheme.warningOrange,
                                ),
                          ),
                          if (answer.isEdited)
                            Text(
                              l.engagementDailyPromptEdited,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                        ],
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            key: const ValueKey('qa.daily_prompt.submit'),
                            onPressed:
                                state.isSubmitting ||
                                    (answer != null && !answer.canEdit)
                                ? null
                                : () => notifier.submitAnswer(
                                    _answerController.text,
                                  ),
                            child: state.isSubmitting
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        scheme.onPrimary,
                                      ),
                                    ),
                                  )
                                : Text(
                                    answer == null
                                        ? l.engagementDailyPromptSubmit
                                        : l.engagementDailyPromptUpdate,
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
                      ).textTheme.bodySmall?.copyWith(color: scheme.error),
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

  /// 24-hour local time (`HH:mm`) with the reader's digits.
  String _formatTime(DateTime value) => DateFormat.Hm(
    Localizations.localeOf(context).toString(),
  ).format(value.toLocal());
}

/// A known prompt topic in the reader's language; others as the code in
/// upper case.
String _domainLabel(AppLocalizations l, String domain) => switch (domain) {
  'values' => l.engagementDailyPromptDomainValues,
  'lifestyle' => l.engagementDailyPromptDomainLifestyle,
  'relationship_style' => l.engagementDailyPromptDomainRelationshipStyle,
  _ => domain.replaceAll('_', ' ').toUpperCase(),
};

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.view});

  final DailyPromptView view;

  @override
  Widget build(BuildContext context) {
    final l = engagementL10n(context);
    final streak = view.streak;
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      backgroundColor: Theme.of(context).colorScheme.surface,
      blur: 8,
      borderRadius: BorderRadius.circular(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.engagementDailyPromptStreakProgress,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatPill(
                text: l.engagementDailyPromptStatCurrent(
                  l.engagementDailyPromptDays(streak.currentDays),
                ),
              ),
              _StatPill(
                text: l.engagementDailyPromptStatBest(
                  l.engagementDailyPromptDays(streak.longestDays),
                ),
              ),
              _StatPill(
                text: l.engagementDailyPromptStatNext(
                  streak.nextMilestone > 0
                      ? l.engagementDailyPromptDays(streak.nextMilestone)
                      : l.engagementDailyPromptComplete,
                ),
              ),
            ],
          ),
          if (streak.milestoneReached > 0) ...[
            const SizedBox(height: 8),
            Text(
              l.engagementDailyPromptMilestone(streak.milestoneReached),
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
  const _StatPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      color: Theme.of(context).colorScheme.surface,
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Text(
      text,
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
    padding: const EdgeInsets.all(16),
    backgroundColor: Theme.of(context).colorScheme.surface,
    blur: 8,
    borderRadius: BorderRadius.circular(18),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).colorScheme.primaryContainer,
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
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
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
