import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/glass_widgets.dart';
import '../../engagement/providers/moderation_appeals_provider.dart';

class ModerationAppealsScreen extends ConsumerStatefulWidget {
  const ModerationAppealsScreen({
    super.key,
    this.initialReason,
    this.initialReportId,
  });

  final String? initialReason;
  final String? initialReportId;

  @override
  ConsumerState<ModerationAppealsScreen> createState() =>
      _ModerationAppealsScreenState();
}

class _ModerationAppealsScreenState
    extends ConsumerState<ModerationAppealsScreen> {
  final _reasonController = TextEditingController();
  final _reportIdController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _reasonController.text = widget.initialReason?.trim() ?? '';
    _reportIdController.text = widget.initialReportId?.trim() ?? '';
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _reportIdController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appealsAsync = ref.watch(moderationAppealsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Moderation Appeals')),
      body: PostLoginBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                GlassContainer(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.white.withValues(alpha: 0.9),
                  blur: 12,
                  borderRadius: const BorderRadius.all(Radius.circular(24)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Submit an appeal',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _reasonController,
                        enabled: !_submitting,
                        decoration: const InputDecoration(
                          labelText: 'Reason',
                          hintText:
                              'Why should this moderation decision be reviewed?',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _reportIdController,
                        enabled: !_submitting,
                        decoration: const InputDecoration(
                          labelText: 'Report ID (optional)',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _descriptionController,
                        enabled: !_submitting,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Additional context (optional)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _submitting ? null : _onSubmitAppeal,
                          child: _submitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Submit appeal'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: appealsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, _) => Center(
                      child: TextButton(
                        onPressed: () =>
                            ref.invalidate(moderationAppealsProvider),
                        child: const Text('Retry'),
                      ),
                    ),
                    data: (appeals) {
                      if (appeals.isEmpty) {
                        return GlassContainer(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: Colors.white.withValues(alpha: 0.9),
                          blur: 12,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(24),
                          ),
                          child: const Center(
                            child: Text(
                              'No appeals submitted yet. Your submitted appeals will appear here with status updates.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () => ref
                            .read(moderationAppealsProvider.notifier)
                            .refresh(),
                        child: ListView.separated(
                          itemCount: appeals.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = appeals[index];
                            return GlassContainer(
                              padding: const EdgeInsets.all(12),
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.9,
                              ),
                              blur: 12,
                              borderRadius: const BorderRadius.all(
                                Radius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    appealStatusLabel(item.status),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(item.reason),
                                  if ((item.description ?? '')
                                      .trim()
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      item.description!,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Text(
                                    'Appeal ID: ${item.id}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelSmall,
                                  ),
                                  Text(
                                    'SLA deadline: ${item.slaDeadlineAt.isEmpty ? '-' : item.slaDeadlineAt}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelSmall,
                                  ),
                                  if ((item.reviewedBy ?? '').trim().isNotEmpty)
                                    Text(
                                      'Reviewed by: ${item.reviewedBy}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelSmall,
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onSubmitAppeal() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Reason is required.')));
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref
          .read(moderationAppealsProvider.notifier)
          .submitAppeal(
            reason: reason,
            reportId: _reportIdController.text.trim(),
            description: _descriptionController.text.trim(),
          );
      if (!mounted) {
        return;
      }
      _reasonController.clear();
      _reportIdController.clear();
      _descriptionController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appeal submitted successfully.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to submit appeal. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}
