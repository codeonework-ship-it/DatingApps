import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/app_layout.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../../core/widgets/qa_control.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/account_lifecycle_provider.dart';

/// Pause, export and deletion, in one place.
///
/// These three sit together because they are the same decision at different
/// strengths — step away, take a copy, leave for good — and a member weighing
/// deletion should see the reversible option in the same view rather than
/// discover it afterwards.
class AccountDataScreen extends ConsumerWidget {
  const AccountDataScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final lifecycleAsync = ref.watch(accountLifecycleProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountTitle)),
      body: PostLoginBackdrop(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppTheme.contentMaxWidth,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppLayout.space4),
                child: lifecycleAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => _LoadFailure(
                    onRetry: () =>
                        ref.read(accountLifecycleProvider.notifier).refresh(),
                  ),
                  data: (lifecycle) => SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (lifecycle.deletionScheduled)
                          _DeletionCountdown(lifecycle: lifecycle),
                        _PauseCard(lifecycle: lifecycle),
                        const SizedBox(height: AppLayout.space4),
                        const _ExportCard(),
                        const SizedBox(height: AppLayout.space4),
                        _DeleteCard(lifecycle: lifecycle),
                        const SizedBox(height: AppLayout.space8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.accountLoadFailed,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppLayout.space3),
          TextButton(
            key: const ValueKey('qa.account.retry'),
            onPressed: onRetry,
            child: Text(l10n.commonRetry),
          ),
        ],
      ),
    );
  }
}

/// Shown above everything else while a deletion is pending.
///
/// The countdown is the member's window to change their mind, so it leads the
/// screen rather than sitting inside the delete section they would have to go
/// looking for.
class _DeletionCountdown extends ConsumerWidget {
  const _DeletionCountdown({required this.lifecycle});
  final AccountLifecycle lifecycle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final days = lifecycle.daysUntilDeletion;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppLayout.space4),
      child: GlassContainer(
        padding: const EdgeInsets.all(AppLayout.space4),
        border: Border.all(color: AppTheme.danger.withValues(alpha: 0.5)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timer_outlined, color: AppTheme.danger),
                const SizedBox(width: AppLayout.space3),
                Expanded(
                  child: Text(
                    days > 0
                        ? l10n.accountDeletionIn(days)
                        : l10n.accountDeletionDue,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppLayout.space2),
            Text(
              l10n.accountDeletionCountdownBody,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppLayout.space3),
            QaControl(
              id: 'qa.account.cancel_deletion_button',
              child: FilledButton.icon(
                key: const ValueKey('qa.account.cancel_deletion_button'),
                onPressed: lifecycle.deletionCancellable
                    ? () => _cancel(context, ref)
                    : null,
                icon: const Icon(Icons.undo_rounded),
                label: Text(l10n.accountKeepMyAccount),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(accountLifecycleProvider.notifier).cancelDeletion();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.accountNotDeletedSnack)),
      );
    } on Object {
      messenger.showSnackBar(SnackBar(content: Text(l10n.accountCancelFailed)));
    }
  }
}

class _PauseCard extends ConsumerWidget {
  const _PauseCard({required this.lifecycle});
  final AccountLifecycle lifecycle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final paused = lifecycle.deactivated;
    return _SectionCard(
      actionQaId: 'qa.account.pause_toggle_button',
      icon: paused ? Icons.visibility_off_outlined : Icons.pause_circle_outline,
      title: paused ? l10n.accountHiddenTitle : l10n.accountTakeBreakTitle,
      body: paused ? l10n.accountHiddenBody : l10n.accountTakeBreakBody,
      action: FilledButton.icon(
        key: const ValueKey('qa.account.pause_toggle_button'),
        // Deleting members are already hidden; offering a pause toggle there
        // would present two controls for the same state.
        onPressed: lifecycle.deletionScheduled
            ? null
            : () => _toggle(context, ref, paused),
        icon: Icon(paused ? Icons.play_arrow_rounded : Icons.pause_rounded),
        label: Text(
          paused ? l10n.accountUnhideProfile : l10n.accountHideProfile,
        ),
      ),
    );
  }

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    bool currentlyPaused,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(accountLifecycleProvider.notifier);
    try {
      if (currentlyPaused) {
        await notifier.reactivate();
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.accountVisibleAgainSnack)),
        );
      } else {
        await notifier.deactivate();
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.accountNowHiddenSnack)),
        );
      }
    } on Object {
      messenger.showSnackBar(SnackBar(content: Text(l10n.accountUpdateFailed)));
    }
  }
}

class _ExportCard extends ConsumerStatefulWidget {
  const _ExportCard();

  @override
  ConsumerState<_ExportCard> createState() => _ExportCardState();
}

class _ExportCardState extends ConsumerState<_ExportCard> {
  bool _working = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _SectionCard(
      actionQaId: 'qa.account.export_button',
      icon: Icons.download_outlined,
      title: l10n.accountDownloadTitle,
      body: l10n.accountDownloadBody,
      action: FilledButton.icon(
        key: const ValueKey('qa.account.export_button'),
        onPressed: _working ? null : _export,
        icon: _working
            ? const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.download_rounded),
        label: Text(_working ? l10n.accountPreparing : l10n.accountPrepareData),
      ),
    );
  }

  Future<void> _export() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _working = true);
    try {
      final export = await ref
          .read(accountLifecycleProvider.notifier)
          .createExport();
      if (!mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (_) => _ExportDialog(export: export),
      );
    } on Object {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.accountPrepareFailed)),
      );
    } finally {
      if (mounted) {
        setState(() => _working = false);
      }
    }
  }
}

/// Shows the export and offers it to the clipboard.
///
/// Copying rather than writing a file: the app has no share or storage
/// permission for this, and a member who can see and copy the payload has the
/// data in hand without the app asking for access it otherwise never needs.
class _ExportDialog extends StatelessWidget {
  const _ExportDialog({required this.export});
  final Map<String, dynamic> export;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pretty = const JsonEncoder.withIndent('  ').convert(export);
    return AlertDialog(
      title: Text(l10n.accountYourData),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: SelectableText(
            pretty,
            key: const ValueKey('qa.account.export_text'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('qa.account.export_copy'),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: pretty));
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: Text(l10n.commonCopy),
        ),
        TextButton(
          key: const ValueKey('qa.account.export_close'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonClose),
        ),
      ],
    );
  }
}

class _DeleteCard extends ConsumerWidget {
  const _DeleteCard({required this.lifecycle});
  final AccountLifecycle lifecycle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return _SectionCard(
      actionQaId: 'qa.account.delete_button',
      icon: Icons.delete_forever_outlined,
      iconColor: AppTheme.danger,
      title: l10n.accountDeleteTitle,
      body: l10n.accountDeleteBody,
      action: OutlinedButton.icon(
        key: const ValueKey('qa.account.delete_button'),
        onPressed: lifecycle.deletionScheduled
            ? null
            : () => _confirm(context, ref),
        icon: const Icon(Icons.delete_outline_rounded),
        label: Text(
          lifecycle.deletionScheduled
              ? l10n.accountDeletionAlreadyScheduled
              : l10n.accountDeleteTitle,
        ),
        style: OutlinedButton.styleFrom(foregroundColor: AppTheme.danger),
      ),
    );
  }

  /// Deletion is confirmed in its own dialog rather than on a single tap.
  ///
  /// It is the only irreversible action in the app, and the dialog is also
  /// where the reversible alternative is offered — a member who wants to
  /// disappear usually wants to be hidden, not erased.
  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(accountLifecycleProvider.notifier);

    final choice = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.accountDeleteConfirmTitle),
        content: Text(l10n.accountDeleteConfirmBody),
        actions: [
          TextButton(
            key: const ValueKey('qa.account.delete_keep'),
            onPressed: () => Navigator.of(dialogContext).pop('cancel'),
            child: Text(l10n.accountKeepMyAccount),
          ),
          TextButton(
            key: const ValueKey('qa.account.delete_hide_instead'),
            onPressed: () => Navigator.of(dialogContext).pop('hide'),
            child: Text(l10n.accountHideInstead),
          ),
          QaControl(
            id: 'qa.account.delete_confirm_button',
            child: FilledButton(
              key: const ValueKey('qa.account.delete_confirm_button'),
              onPressed: () => Navigator.of(dialogContext).pop('delete'),
              style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
              child: Text(l10n.commonDelete),
            ),
          ),
        ],
      ),
    );

    try {
      if (choice == 'delete') {
        await notifier.requestDeletion();
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.accountDeletionScheduledSnack)),
        );
      } else if (choice == 'hide') {
        await notifier.deactivate();
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.accountNowHiddenSnack)),
        );
      }
    } on Object {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.commonSomethingWentWrongTryAgain)),
      );
    }
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.action,
    required this.actionQaId,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget action;

  /// Automation id for the action.
  ///
  /// A `ValueKey` is enough for widget tests but never reaches the
  /// accessibility tree, which is all UiAutomator can read. Both are kept: the
  /// key for tests in process, this semantics identifier (Android resource-id)
  /// for tests on a device. The button is still announced by its own text.
  final String actionQaId;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GlassContainer(
      padding: const EdgeInsets.all(AppLayout.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor ?? scheme.primary),
              const SizedBox(width: AppLayout.space3),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppLayout.space2),
          Text(body, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppLayout.space4),
          SizedBox(
            width: double.infinity,
            child: QaControl(id: actionQaId, child: action),
          ),
        ],
      ),
    );
  }
}
