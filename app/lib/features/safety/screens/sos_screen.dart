import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/sos_provider.dart';

class SosScreen extends ConsumerStatefulWidget {
  const SosScreen({super.key});

  @override
  ConsumerState<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends ConsumerState<SosScreen> {
  final _messageController = TextEditingController();
  bool _messagePrefilled = false;
  String _level = 'high';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_messagePrefilled) {
      _messagePrefilled = true;
      _messageController.text = AppLocalizations.of(
        context,
      ).safetySosDefaultMessage;
    }
  }

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() => ref.read(sosProvider.notifier).loadAlerts());
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sosProvider);
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.safetySosTitle)),
      body: PostLoginBackdrop(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: ref.read(sosProvider.notifier).loadAlerts,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                GlassContainer(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(Icons.sos_rounded, size: 54, color: scheme.error),
                      const SizedBox(height: 12),
                      Text(
                        l10n.safetySosHeadline,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.safetySosIntro,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SegmentedButton<String>(
                        key: const ValueKey('qa.safety.sos_level'),
                        segments: [
                          ButtonSegment(
                            value: 'high',
                            label: Text(l10n.safetySosLevelUrgent),
                          ),
                          ButtonSegment(
                            value: 'critical',
                            label: Text(l10n.safetySosLevelCritical),
                          ),
                        ],
                        selected: {_level},
                        onSelectionChanged: (value) =>
                            setState(() => _level = value.first),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        key: const ValueKey('qa.safety.sos_message'),
                        controller: _messageController,
                        minLines: 2,
                        maxLines: 4,
                        maxLength: 500,
                        decoration: InputDecoration(
                          labelText: l10n.safetySosMessageLabel,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        key: const ValueKey('qa.safety.activate_sos'),
                        style: FilledButton.styleFrom(
                          backgroundColor: scheme.error,
                          foregroundColor: scheme.onError,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: state.isSending ? null : _confirmAndActivate,
                        icon: state.isSending
                            ? SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: scheme.onError,
                                ),
                              )
                            : const Icon(Icons.warning_amber_rounded),
                        label: Text(
                          state.isSending
                              ? l10n.safetySosActivating
                              : l10n.safetySosActivate,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.safetySosLocationNote,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (state.error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    localizedSosMessage(l10n, state.error!),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.error),
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  l10n.safetySosHistoryTitle,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                if (state.isLoading && state.alerts.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else if (state.alerts.isEmpty)
                  Text(
                    l10n.safetySosHistoryEmpty,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  )
                else
                  for (final alert in state.alerts)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlassContainer(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              alert.status == 'resolved'
                                  ? Icons.check_circle
                                  : Icons.warning_rounded,
                              color: alert.status == 'resolved'
                                  ? AppTheme.successGreen
                                  : scheme.error,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.safetySosHistoryHeading(
                                      _levelLabel(l10n, alert.emergencyLevel),
                                      _statusLabel(l10n, alert.status),
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  if (alert.message != null)
                                    Text(alert.message!),
                                  const SizedBox(height: 4),
                                  Text(
                                    alert.hasLocation
                                        ? l10n.safetySosHistoryMetaWithLocation(
                                            _dateLabel(
                                              alert.triggeredAt,
                                              locale,
                                            ),
                                          )
                                        : l10n.safetySosHistoryMetaNoLocation(
                                            _dateLabel(
                                              alert.triggeredAt,
                                              locale,
                                            ),
                                          ),
                                    style: TextStyle(
                                      color: scheme.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (alert.resolutionNote != null)
                                    Text(
                                      l10n.safetySosResolution(
                                        alert.resolutionNote!,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmAndActivate() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.safetySosConfirmTitle),
        content: Text(l10n.safetySosConfirmBody),
        actions: [
          TextButton(
            key: const ValueKey('qa.safety.sos_confirm.cancel'),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.safetySosCancel),
          ),
          FilledButton(
            key: const ValueKey('qa.safety.sos_confirm.activate'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.safetySosConfirmActivate),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final alert = await ref
        .read(sosProvider.notifier)
        .activate(emergencyLevel: _level, message: _messageController.text);
    if (!mounted || alert == null) return;
    final locationIncluded = ref.read(sosProvider).lastAlertIncludedLocation;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: AppTheme.successGreen),
        title: Text(l10n.safetySosActivatedTitle),
        content: Text(
          locationIncluded == true
              ? l10n.safetySosActivatedWithLocation
              : l10n.safetySosActivatedWithoutLocation,
        ),
        actions: [
          FilledButton(
            key: const ValueKey('qa.safety.sos_done'),
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.safetySosDone),
          ),
        ],
      ),
    );
  }
}

/// The provider's English message codes in the member's language; text from
/// the server is shown as is.
String localizedSosMessage(AppLocalizations l10n, String message) =>
    switch (message) {
      kSosSignInToViewMessage => l10n.safetySosSignInToView,
      kSosLoadFailedMessage => l10n.safetySosLoadFailed,
      kSosSignInToActivateMessage => l10n.safetySosSignInToActivate,
      kSosActivateFailedMessage => l10n.safetySosActivateFailed,
      _ => message,
    };

String _levelLabel(AppLocalizations l10n, String level) => switch (level) {
  'low' => l10n.safetySosAlertLevelLow,
  'medium' => l10n.safetySosAlertLevelMedium,
  'high' => l10n.safetySosAlertLevelHigh,
  'critical' => l10n.safetySosAlertLevelCritical,
  _ => level.toUpperCase(),
};

String _statusLabel(AppLocalizations l10n, String status) => switch (status) {
  'open' => l10n.safetySosAlertStatusOpen,
  'active' => l10n.safetySosAlertStatusActive,
  'acknowledged' => l10n.safetySosAlertStatusAcknowledged,
  'resolved' => l10n.safetySosAlertStatusResolved,
  _ => status,
};

/// English keeps its day/month/year 24-hour layout; other languages use
/// their own short date and time.
String _dateLabel(DateTime value, Locale locale) {
  final local = value.toLocal();
  if (locale.languageCode != 'en') {
    return DateFormat.yMd(locale.toString()).add_Hm().format(local);
  }
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/${local.year} '
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}
