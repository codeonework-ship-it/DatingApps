import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/glass_widgets.dart';
import '../providers/call_provider.dart';

class CallHistoryScreen extends ConsumerStatefulWidget {
  const CallHistoryScreen({super.key});

  @override
  ConsumerState<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends ConsumerState<CallHistoryScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() => ref.read(callProvider.notifier).loadHistory());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(callProvider);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Call history')),
      body: PostLoginBackdrop(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: ref.read(callProvider.notifier).loadHistory,
            child: state.isLoading && state.history.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (state.error != null)
                        _MessageCard(
                          icon: Icons.error_outline,
                          message: state.error!,
                          color: scheme.error,
                        ),
                      if (state.history.isEmpty && !state.isLoading)
                        _MessageCard(
                          icon: Icons.video_call_outlined,
                          message: 'No call sessions yet.',
                          color: scheme.primary,
                        ),
                      for (final session in state.history)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GlassContainer(
                            padding: const EdgeInsets.all(16),
                            backgroundColor: scheme.surface,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: scheme.primaryContainer,
                                  child: Icon(
                                    session.status == 'ended'
                                        ? Icons.call_end
                                        : Icons.video_call,
                                    color: session.status == 'ended'
                                        ? scheme.onSurfaceVariant
                                        : scheme.onPrimaryContainer,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _statusLabel(session),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _dateLabel(session.startedAt),
                                        style: TextStyle(
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      ),
                                      Text(
                                        'Match ${_shortId(session.matchId)}',
                                        style: TextStyle(
                                          color: scheme.onSurfaceVariant,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (session.status != 'ended')
                                  IconButton(
                                    tooltip: 'Join live room',
                                    onPressed: session.joinUrl == null
                                        ? null
                                        : () => ref
                                              .read(callProvider.notifier)
                                              .openLiveRoom(session),
                                    icon: const Icon(Icons.open_in_new_rounded),
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
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) => GlassContainer(
    padding: const EdgeInsets.all(20),
    backgroundColor: Theme.of(context).colorScheme.surface,
    child: Column(
      children: [
        Icon(icon, color: color, size: 36),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center),
      ],
    ),
  );
}

String _shortId(String value) =>
    value.length > 8 ? value.substring(0, 8) : value;

String _statusLabel(CallSession session) {
  if (session.status != 'ended') return 'Active call session';
  final minutes = session.durationSeconds ~/ 60;
  final seconds = session.durationSeconds % 60;
  return 'Ended · $minutes:${seconds.toString().padLeft(2, '0')}';
}

String _dateLabel(DateTime value) {
  final local = value.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/${local.year} · '
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}
