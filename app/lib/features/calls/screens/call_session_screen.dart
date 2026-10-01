import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/call_provider.dart';

class CallSessionScreen extends ConsumerStatefulWidget {
  const CallSessionScreen({
    required this.matchId,
    required this.recipientUserId,
    required this.recipientName,
    super.key,
  });

  final String matchId;
  final String recipientUserId;
  final String recipientName;

  @override
  ConsumerState<CallSessionScreen> createState() => _CallSessionScreenState();
}

class _CallSessionScreenState extends ConsumerState<CallSessionScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref
          .read(callProvider.notifier)
          .startCall(
            matchId: widget.matchId,
            recipientUserId: widget.recipientUserId,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(callProvider);
    final scheme = Theme.of(context).colorScheme;
    return PopScope(
      canPop: state.activeSession == null,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          return;
        }
        await _endAndClose();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF101936),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          title: const Text('Call session'),
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Spacer(),
                        CircleAvatar(
                          radius: 54,
                          backgroundColor: scheme.primary.withValues(
                            alpha: .28,
                          ),
                          child: Text(
                            widget.recipientName.isEmpty
                                ? '?'
                                : widget.recipientName[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 42,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          widget.recipientName,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.isStarting
                              ? 'Starting secure session…'
                              : state.activeSession != null
                              ? 'Session active'
                              : 'Session unavailable',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        if (state.error != null) ...[
                          const SizedBox(height: 20),
                          Text(
                            state.error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFFFFA9B1)),
                          ),
                        ],
                        const SizedBox(height: 20),
                        const Text(
                          'The live room opens in a secure provider window. Use that room’s microphone, camera, and leave controls during the call.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white54, height: 1.4),
                        ),
                        const Spacer(),
                        if (state.activeSession != null)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _ControlButton(
                                icon: Icons.open_in_new_rounded,
                                label: 'Join live room',
                                color: scheme.primary,
                                foregroundColor: scheme.onPrimary,
                                onPressed: state.activeSession!.joinUrl == null
                                    ? null
                                    : () => ref
                                          .read(callProvider.notifier)
                                          .openLiveRoom(state.activeSession!),
                              ),
                              _ControlButton(
                                icon: Icons.call_end,
                                label: 'End',
                                color: scheme.error,
                                foregroundColor: scheme.onError,
                                onPressed: state.isEnding ? null : _endAndClose,
                              ),
                            ],
                          )
                        else if (!state.isStarting)
                          FilledButton.icon(
                            onPressed: () => ref
                                .read(callProvider.notifier)
                                .startCall(
                                  matchId: widget.matchId,
                                  recipientUserId: widget.recipientUserId,
                                ),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Try again'),
                          ),
                        const SizedBox(height: 24),
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

  Future<void> _endAndClose() async {
    final ended = await ref.read(callProvider.notifier).endCall();
    if (mounted && (ended || ref.read(callProvider).activeSession == null)) {
      Navigator.of(context).pop();
    }
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color = const Color(0xFF354367),
    this.foregroundColor = Colors.white,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      IconButton.filled(
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: color,
          foregroundColor: foregroundColor,
          minimumSize: const Size(56, 56),
        ),
        icon: Icon(icon),
      ),
      const SizedBox(height: 6),
      Text(label, style: const TextStyle(color: Colors.white70)),
    ],
  );
}
