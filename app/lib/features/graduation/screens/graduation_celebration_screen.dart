import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/app_layout.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../models/graduation_labels.dart';
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
      final l10n = AppLocalizations.of(context);
      final state = ref.read(matchGraduationProvider(widget.matchId));
      setState(() {
        _submitting = false;
        _error = state.error == null
            ? l10n.graduationConfirmFailed
            : localizedGraduationError(l10n, state.error!, state.failure);
      });
      return;
    }
    Navigator.of(context).pop(graduation);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(matchGraduationProvider(widget.matchId));
    final graduation = state.graduation;
    final recordedShare = graduation?.shareWithFriends ?? false;
    final shareValue = _pending ? _shareWithFriends : recordedShare;
    final friendsTold = !_pending && (graduation?.friendRecipients ?? 0) > 0;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(l10n.graduationTitle),
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
                        l10n.graduationFoundEachOther,
                        key: const ValueKey('qa.graduation.celebration'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppLayout.space3),
                      Text(
                        l10n.graduationCelebrationBody(widget.partnerName),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppLayout.space5),
                      SwitchListTile(
                        key: const ValueKey('qa.graduation.celebration.share'),
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.graduationTellFriends),
                        subtitle: Text(
                          _pending
                              ? l10n.graduationTellFriendsBody
                              : friendsTold
                              ? l10n.graduationFriendsHaveBeenTold
                              : recordedShare
                              ? l10n.graduationFriendsAreTold
                              : l10n.graduationOnlyTwoOfYou,
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
                                ? l10n.graduationConfirmAndBack
                                : l10n.graduationBackToConnect,
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
