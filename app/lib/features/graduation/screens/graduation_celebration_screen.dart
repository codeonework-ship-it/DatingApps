import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/app_layout.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../providers/graduation_provider.dart';

/// Full-screen "You found each other".
///
/// With [pendingGraduationId] set, the screen completes the confirmation: the
/// share toggle is live and "Back to Connect" sends the decision, popping
/// with the confirmed graduation. Without it, the screen is the celebration
/// after the fact: the toggle shows the viewer's recorded choice and the
/// button simply returns.
class GraduationCelebrationScreen extends ConsumerStatefulWidget {
  const GraduationCelebrationScreen({
    required this.matchId,
    required this.partnerName,
    this.pendingGraduationId,
    super.key,
  });

  final String matchId;
  final String partnerName;
  final String? pendingGraduationId;

  @override
  ConsumerState<GraduationCelebrationScreen> createState() =>
      _GraduationCelebrationScreenState();
}

class _GraduationCelebrationScreenState
    extends ConsumerState<GraduationCelebrationScreen> {
  bool _shareWithFriends = false;
  bool _submitting = false;
  String? _error;

  bool get _pending => widget.pendingGraduationId != null;

  Future<void> _done() async {
    final pendingId = widget.pendingGraduationId;
    if (pendingId == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final notifier = ref.read(matchGraduationProvider(widget.matchId).notifier);
    final graduation = await notifier.decide(
      graduationId: pendingId,
      confirm: true,
      shareWithFriends: _shareWithFriends,
    );
    if (!mounted) {
      return;
    }
    if (graduation == null) {
      setState(() {
        _submitting = false;
        _error =
            ref.read(matchGraduationProvider(widget.matchId)).error ??
            'Unable to confirm right now.';
      });
      return;
    }
    Navigator.of(context).pop(graduation);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(matchGraduationProvider(widget.matchId));
    final graduation = state.graduation;
    final recordedShare = graduation?.shareWithFriends ?? false;
    final shareValue = _pending ? _shareWithFriends : recordedShare;
    final friendsTold = !_pending && (graduation?.friendRecipients ?? 0) > 0;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text('Graduation'),
      ),
      body: PostLoginBackdrop(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppTheme.contentMaxWidth,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppLayout.space5),
                child: GlassContainer(
                  padding: const EdgeInsets.all(AppLayout.space6),
                  backgroundColor: theme.colorScheme.surface.withValues(
                    alpha: 0.92,
                  ),
                  blur: 12,
                  borderRadius: const BorderRadius.all(Radius.circular(28)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.successGreen.withValues(alpha: 0.14),
                        ),
                        child: const Icon(
                          Icons.celebration_rounded,
                          size: 48,
                          color: AppTheme.successGreen,
                        ),
                      ),
                      const SizedBox(height: AppLayout.space5),
                      Text(
                        'You found each other',
                        key: const ValueKey('qa.graduation.celebration'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppLayout.space3),
                      Text(
                        'You and ${widget.partnerName} are leaving Connect '
                        'together. You are both hidden from discovery, and '
                        'this chat stays open for as long as you like.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppLayout.space5),
                      SwitchListTile(
                        key: const ValueKey('qa.graduation.celebration.share'),
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Tell my friends'),
                        subtitle: Text(
                          _pending
                              ? 'Your accepted friends hear you found '
                                    'someone. They are not told who.'
                              : friendsTold
                              ? 'Your friends have been told.'
                              : recordedShare
                              ? 'Your friends are told.'
                              : 'Only the two of you know.',
                        ),
                        value: shareValue,
                        onChanged: _pending && !_submitting
                            ? (value) =>
                                  setState(() => _shareWithFriends = value)
                            : null,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: AppLayout.space3),
                        Text(
                          _error!,
                          key: const ValueKey(
                            'qa.graduation.celebration_error',
                          ),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppLayout.space5),
                      SizedBox(
                        height: AppLayout.minTapTarget,
                        child: FilledButton.icon(
                          key: const ValueKey('qa.graduation.celebration.done'),
                          onPressed: _submitting ? null : _done,
                          icon: _submitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.arrow_back_rounded),
                          label: Text(
                            _pending
                                ? 'Confirm and go back'
                                : 'Back to Connect',
                          ),
                        ),
                      ),
                    ],
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
