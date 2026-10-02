import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/glass_widgets.dart';
import '../../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    final appealsAsync = ref.watch(moderationAppealsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacyModerationAppeals)),
      body: PostLoginBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                GlassContainer(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surface.withValues(alpha: 0.9),
                  blur: 12,
                  borderRadius: const BorderRadius.all(Radius.circular(24)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.appealsSubmitTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _reasonController,
                        enabled: !_submitting,
                        decoration: InputDecoration(
                          labelText: l10n.appealsReasonLabel,
                          hintText: l10n.appealsReasonHint,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _reportIdController,
                        enabled: !_submitting,
                        decoration: InputDecoration(
                          labelText: l10n.appealsReportIdLabel,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _descriptionController,
                        enabled: !_submitting,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: l10n.appealsContextLabel,
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
                              : Text(l10n.appealsSubmit),
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
                        child: Text(l10n.commonRetry),
                      ),
                    ),
                    data: (appeals) {
                      if (appeals.isEmpty) {
                        return GlassContainer(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surface.withValues(alpha: 0.9),
                          blur: 12,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(24),
                          ),
                          child: Center(
                            child: Text(
                              l10n.appealsEmpty,
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
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.surface.withValues(alpha: 0.9),
                              blur: 12,
                              borderRadius: const BorderRadius.all(
                                Radius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    appealStatusLabel(item.status, l10n),
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
                                    l10n.appealsIdLine(item.id),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelSmall,
                                  ),
                                  Text(
                                    l10n.appealsSlaLine(
                                      item.slaDeadlineAt.isEmpty
                                          ? '-'
                                          : item.slaDeadlineAt,
                                    ),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelSmall,
                                  ),
                                  if ((item.reviewedBy ?? '').trim().isNotEmpty)
                                    Text(
                                      l10n.appealsReviewedBy(
                                        item.reviewedBy ?? '',
                                      ),
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
    final l10n = AppLocalizations.of(context);
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.appealsReasonRequired)));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.appealsSubmitted)));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.appealsSubmitFailed)));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}
