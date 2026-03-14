import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../providers/activity_session_provider.dart';

class ActivitySessionScreen extends ConsumerStatefulWidget {
  const ActivitySessionScreen({
    required this.matchId, required this.otherUserId, required this.otherUserName, super.key,
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('2-Minute This-or-That'),
        actions: [
          IconButton(
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
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.trustBlue,
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
                        backgroundColor: Colors.white,
                        blur: 0,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Complete this with ${widget.otherUserName}',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: AppTheme.textDark,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Answer all 8 rounds before time ends.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 12),
                            _CountdownPill(remainingSeconds: remainingSeconds),
                            if (state.status.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Status: ${state.status.replaceAll('_', ' ')}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppTheme.textHint),
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
                          state.error!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.errorRed),
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
                              : const Text('Submit Responses'),
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
                            child: const Text('Time is up — Load Summary'),
                          ),
                        ),
                      ],
                      if (state.status == 'active' &&
                          state.allQuestionsAnswered) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Responses sent. Waiting for the other participant to finish.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: state.isSummaryLoading
                                ? null
                                : notifier.loadSummary,
                            child: const Text('Refresh Summary'),
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
                                ).pop(_buildShareMessage(state.summary!))
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

String _buildShareMessage(ActivitySummary summary) {
  final status = summary.status.replaceAll('_', ' ');
  final completed = summary.participantsCompleted.length;
  final total = summary.totalParticipants;
  final insight = summary.insight.trim();
  return '2-Min This-or-That result: $status • $completed/$total completed${insight.isEmpty ? '' : ' • $insight'}';
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
            ? AppTheme.errorRed.withValues(alpha: 0.1)
            : AppTheme.trustBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Time left $minutes:$seconds',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: isUrgent ? AppTheme.errorRed : AppTheme.trustBlue,
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
  Widget build(BuildContext context) => GlassContainer(
    padding: const EdgeInsets.all(16),
    backgroundColor: Colors.white,
    blur: 0,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.textDark,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(question.prompt, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: question.options
              .map(
                (option) => ChoiceChip(
                  label: Text(option),
                  selected: selectedAnswer == option,
                  onSelected: enabled ? (_) => onSelected(option) : null,
                  selectedColor: AppTheme.trustBlue.withValues(alpha: 0.16),
                  labelStyle: TextStyle(
                    color: selectedAnswer == option
                        ? AppTheme.trustBlue
                        : AppTheme.textDark,
                    fontWeight: selectedAnswer == option
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ],
    ),
  );
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

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      backgroundColor: Colors.white,
      blur: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity Summary',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textDark,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Status: ${status.replaceAll('_', ' ')}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Participants completed: '
            '${summary?.participantsCompleted.length ?? 0}/'
            '${summary?.totalParticipants ?? 2}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            summary?.insight.isNotEmpty == true
                ? summary!.insight
                : 'Summary will appear once available.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (onShare != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onShare,
                icon: const Icon(Icons.share_outlined),
                label: const Text('Share Result to Chat'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
