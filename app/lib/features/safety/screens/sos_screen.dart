import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../providers/sos_provider.dart';

class SosScreen extends ConsumerStatefulWidget {
  const SosScreen({super.key});

  @override
  ConsumerState<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends ConsumerState<SosScreen> {
  final _messageController = TextEditingController(
    text: 'I need immediate assistance. Please check on me.',
  );
  String _level = 'high';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency SOS')),
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
                      Icon(
                        Icons.sos_rounded,
                        size: 54,
                        color: scheme.error,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Activate an emergency alert',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'If you are in immediate danger, contact local emergency '
                        'services first. This alert is recorded for the safety team.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'high', label: Text('Urgent')),
                          ButtonSegment(
                            value: 'critical',
                            label: Text('Critical'),
                          ),
                        ],
                        selected: {_level},
                        onSelectionChanged: (value) =>
                            setState(() => _level = value.first),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _messageController,
                        minLines: 2,
                        maxLines: 4,
                        maxLength: 500,
                        decoration: const InputDecoration(
                          labelText: 'Message for the safety team',
                          border: OutlineInputBorder(),
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
                          state.isSending ? 'Activating…' : 'Activate SOS',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Location is requested only for this alert. You can continue '
                        'if permission is denied.',
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
                    state.error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.error),
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  'Alert history',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                if (state.isLoading && state.alerts.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else if (state.alerts.isEmpty)
                  Text(
                    'No SOS alerts recorded.',
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
                                    '${alert.emergencyLevel.toUpperCase()} · ${alert.status}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  if (alert.message != null)
                                    Text(alert.message!),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_dateLabel(alert.triggeredAt)} · '
                                    '${alert.hasLocation ? 'location included' : 'no location'}',
                                    style: TextStyle(
                                      color: scheme.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (alert.resolutionNote != null)
                                    Text('Resolution: ${alert.resolutionNote}'),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Activate SOS now?'),
        content: const Text(
          'This creates an emergency alert for the safety team and attempts to '
          'attach your current location.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Activate'),
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
        title: const Text('SOS alert activated'),
        content: Text(
          locationIncluded == true
              ? 'Your alert and current location were recorded.'
              : 'Your alert was recorded without location. Location permission '
                    'was unavailable or declined.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

String _dateLabel(DateTime value) {
  final local = value.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/${local.year} '
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}
