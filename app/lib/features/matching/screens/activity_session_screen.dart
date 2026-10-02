import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/glass_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../matching_l10n.dart';
import '../providers/activity_session_provider.dart';

class ActivitySessionScreen extends ConsumerStatefulWidget {
  const ActivitySessionScreen({
    required this.matchId,
    required this.otherUserId,
    required this.otherUserName,
    super.key,
    this.enableShareToChat = false,
  });
  final String matchId;
  final String otherUserId;
  final String otherUserName;
  final bool enableShareToChat;

  @override
  ConsumerState<ActivitySessionScreen> createState() =>
      _ActivitySessionScreenState();
}

class _ActivitySessionScreenState extends ConsumerState<ActivitySessionScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_startFlow);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
        _autoLoadSummaryOnTimeout();
      }
    });
  }

  Future<void> _startFlow() async {
    final notifier = ref.read(
      activitySessionProvider((
        matchId: widget.matchId,
        otherUserId: widget.otherUserId,
      )).notifier,
    );
    await notifier.startSession();
  }

  Future<void> _autoLoadSummaryOnTimeout() async {
    final state = ref.read(
      activitySessionProvider((
        matchId: widget.matchId,
        otherUserId: widget.otherUserId,
      )),
    );
    final remaining = computeActivityRemainingSeconds(
      state.expiresAt,
      DateTime.now().toUtc(),
    );
    if (state.sessionId != null &&
        state.status == 'active' &&
        remaining == 0 &&
        !state.isSummaryLoading) {
      await ref
          .read(
            activitySessionProvider((
              matchId: widget.matchId,
              otherUserId: widget.otherUserId,
            )).notifier,
          )
          .loadSummary();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = activitySessionProvider((
      matchId: widget.matchId,
      otherUserId: widget.otherUserId,
    ));
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);

    final remainingSeconds = computeActivityRemainingSeconds(
      state.expiresAt,
      DateTime.now().toUtc(),
    );
    final isTimedOut =
        state.status == 'timed_out' || state.status == 'partial_timeout';
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.matchesActivityTitle),
        actions: [
          IconButton(
            tooltip: l10n.matchesActivityRestartTooltip,
            icon: const Icon(Icons.refresh),
            onPressed: state.isLoading || state.isSubmitting
                ? null
                : notifier.startSession,
          ),
        ],
      ),
      body: PostLoginBackdrop(
        child: SafeArea(
          child: state.isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GlassContainer(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        blur: 0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.matchesActivityCompleteWith(
                                widget.otherUserName,
                              ),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.matchesActivityInstructions,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 12),
                            _CountdownPill(remainingSeconds: remainingSeconds),
                            if (state.status.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                l10n.matchesActivityStatus(
                                  localizedActivityStatus(l10n, state.status),
                                ),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...state.questions.map(
                        (question) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _QuestionCard(
                            question: question,
                            selectedAnswer: state.selectedAnswers[question.id],
                            onSelected: (value) =>
                                notifier.selectAnswer(question.id, value),
                            enabled: !state.isTerminal && remainingSeconds > 0,
                          ),
                        ),
                      ),
                      if (state.error != null) ...[
                        Text(
                          localizeActivityError(l10n, state.error)!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              state.isSubmitting ||
                                  state.isTerminal ||
                                  remainingSeconds <= 0
                              ? null
                              : notifier.submitCurrentUserResponses,
                          child: state.isSubmitting
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).colorScheme.onPrimary,
                                    ),
                                  ),
                                )
                              : Text(l10n.matchesActivitySubmit),
                        ),
                      ),
                      if (remainingSeconds <= 0 && !state.isTerminal) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: state.isSummaryLoading
                                ? null
                                : notifier.loadSummary,
                            child: Text(l10n.matchesActivityTimeUpLoad),
                          ),
                        ),
                      ],
                      if (state.status == 'active' &&
                          state.allQuestionsAnswered) ...[
                        const SizedBox(height: 8),
                        Text(
                          l10n.matchesActivityWaiting,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: state.isSummaryLoading
                                ? null
                                : notifier.loadSummary,
                            child: Text(l10n.matchesActivityRefreshSummary),
                          ),
                        ),
                      ],
                      if (state.summary != null ||
                          isTimedOut ||
                          state.status == 'completed') ...[
                        const SizedBox(height: 16),
                        _SummaryCard(
                          summary: state.summary,
                          fallbackStatus: state.status,
                          onShare:
                              widget.enableShareToChat && state.summary != null
                              ? () => Navigator.of(
                                  context,
                                ).pop(_buildShareMessage(l10n, state.summary!))
                              : null,
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

String _buildShareMessage(AppLocalizations l10n, ActivitySummary summary) {
  final status = localizedActivityStatus(l10n, summary.status);
  final completed = summary.participantsCompleted.length;
  final total = summary.totalParticipants;
  final insight = summary.insight.trim();
  return insight.isEmpty
      ? l10n.matchesActivityShareMessage(status, completed, total)
      : l10n.matchesActivityShareMessageWithInsight(
          status,
          completed,
          total,
          insight,
        );
}

class _CountdownPill extends StatelessWidget {
  const _CountdownPill({required this.remainingSeconds});
  final int remainingSeconds;

  @override
  Widget build(BuildContext context) {
    final minutes = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');
    final isUrgent = remainingSeconds <= 30;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isUrgent
            ? Theme.of(context).colorScheme.errorContainer
            : Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        AppLocalizations.of(
          context,
        ).matchesActivityTimeLeft('$minutes:$seconds'),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: isUrgent
              ? Theme.of(context).colorScheme.onErrorContainer
              : Theme.of(context).colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.question,
    required this.selectedAnswer,
    required this.onSelected,
    required this.enabled,
  });
  final ActivityQuestion question;
  final String? selectedAnswer;
  final ValueChanged<String> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final text = localizedActivityQuestion(
      AppLocalizations.of(context),
      question,
    );
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      backgroundColor: Theme.of(context).colorScheme.surface,
      blur: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(text.prompt, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (index, option) in question.options.indexed)
                ChoiceChip(
                  label: Text(text.optionLabels[index]),
                  selected: selectedAnswer == option,
                  onSelected: enabled ? (_) => onSelected(option) : null,
                  selectedColor: Theme.of(context).colorScheme.primaryContainer,
                  labelStyle: TextStyle(
                    color: selectedAnswer == option
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight: selectedAnswer == option
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.summary,
    required this.fallbackStatus,
    this.onShare,
  });
  final ActivitySummary? summary;
  final String fallbackStatus;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final status = summary?.status.isNotEmpty == true
        ? summary!.status
        : fallbackStatus;
    final l10n = AppLocalizations.of(context);

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      backgroundColor: Theme.of(context).colorScheme.surface,
      blur: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.matchesActivitySummaryTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.matchesActivityStatus(localizedActivityStatus(l10n, status)),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.matchesActivityParticipantsCompleted(
              summary?.participantsCompleted.length ?? 0,
              summary?.totalParticipants ?? 2,
            ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            summary?.insight.isNotEmpty == true
                ? summary!.insight
                : l10n.matchesActivitySummaryPending,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (onShare != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onShare,
                icon: const Icon(Icons.share_outlined),
                label: Text(l10n.matchesActivityShareResult),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
