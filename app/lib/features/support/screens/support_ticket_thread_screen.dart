import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/widgets/connect_page.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../support_api.dart';
import '../support_models.dart';
import '../widgets/support_widgets.dart';

/// One support request as a conversation with the support team.
///
/// Loading the ticket marks the team's replies as read on the server, so the
/// shared ticket list is refreshed afterwards to clear its badge.
class SupportTicketThreadScreen extends ConsumerStatefulWidget {
  const SupportTicketThreadScreen({
    required this.ticketId,
    super.key,
    this.initialThread,
  });

  final String ticketId;

  /// A thread the caller already has (e.g. straight after creating it).
  final SupportThread? initialThread;

  @override
  ConsumerState<SupportTicketThreadScreen> createState() =>
      _SupportTicketThreadScreenState();
}

class _SupportTicketThreadScreenState
    extends ConsumerState<SupportTicketThreadScreen> {
  final _reply = TextEditingController();
  final _ratingComment = TextEditingController();
  final _scroll = ScrollController();
  late final SupportAttachmentTray _tray;
  late SupportThread? _thread = widget.initialThread;
  Object? _loadError;
  bool _loading = false;
  bool _sending = false;
  bool _acting = false;
  int _rating = 0;

  /// Kept across a dropped connection so a retried reply is not posted
  /// twice; replaced once the server has answered.
  String _replyKey = const Uuid().v4();

  @override
  void initState() {
    super.initState();
    _tray = SupportAttachmentTray(
      ref.read(supportApiProvider),
      lookupAppLocalizations(const Locale('en')),
    );
    if (_thread == null) {
      _load();
    } else {
      _scrollToEnd();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tray.useLocalizations(AppLocalizations.of(context));
  }

  @override
  void dispose() {
    _reply.dispose();
    _ratingComment.dispose();
    _scroll.dispose();
    _tray.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final thread = await ref
          .read(supportApiProvider)
          .getTicket(widget.ticketId);
      if (!mounted) {
        return;
      }
      setState(() => _thread = thread);
      // The server has marked the replies read; refresh the unread badge.
      ref.invalidate(supportTicketsProvider);
      _scrollToEnd();
    } on Object catch (error) {
      if (mounted) {
        setState(() => _loadError = error);
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _attach() async {
    final files = await ref
        .read(supportImagePickerProvider)
        .pick(_tray.remaining);
    if (files.isNotEmpty && mounted) {
      await _tray.addFiles(files);
    }
  }

  Future<void> _send() async {
    final thread = _thread;
    final l10n = AppLocalizations.of(context);
    if (thread == null) {
      return;
    }
    final body = _reply.text.trim();
    if (_tray.uploading || _tray.hasFailures) {
      _snack(l10n.supportErrorUploadsPending);
      return;
    }
    final ids = _tray.uploadIds;
    if (body.isEmpty && ids.isEmpty) {
      return;
    }
    if (body.length > SupportLimits.bodyMax) {
      _snack(l10n.supportErrorDescriptionTooLong(SupportLimits.bodyMax));
      return;
    }
    setState(() => _sending = true);
    try {
      final result = await ref
          .read(supportApiProvider)
          .reply(
            thread.ticket.id,
            body: body,
            attachmentIds: ids,
            idempotencyKey: _replyKey,
          );
      _replyKey = const Uuid().v4();
      _reply.clear();
      _tray.clear();
      if (!mounted) {
        return;
      }
      setState(() {
        _thread = thread.copyWith(
          ticket: result.ticket,
          messages: [...thread.messages, result.message],
        );
      });
      ref.invalidate(supportTicketsProvider);
      _scrollToEnd();
    } on SupportException catch (error) {
      if (!error.offline) {
        _replyKey = const Uuid().v4();
      }
      if (mounted) {
        _snack(supportErrorMessage(l10n, error));
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _ticketAction(
    Future<SupportTicket> Function(SupportApi api, String id) action,
    String doneMessage,
  ) async {
    final thread = _thread;
    if (thread == null) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    setState(() => _acting = true);
    try {
      final ticket = await action(
        ref.read(supportApiProvider),
        thread.ticket.id,
      );
      if (!mounted) {
        return;
      }
      setState(() => _thread = thread.copyWith(ticket: ticket));
      ref.invalidate(supportTicketsProvider);
      _snack(doneMessage);
    } on Object catch (error) {
      if (mounted) {
        _snack(supportErrorMessage(l10n, error));
      }
    } finally {
      if (mounted) {
        setState(() => _acting = false);
      }
    }
  }

  Future<void> _confirmClose() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.supportCloseConfirmTitle),
        content: Text(l10n.supportCloseConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.supportCancel),
          ),
          FilledButton(
            key: const Key('support_close_confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.supportCloseTicket),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _ticketAction((api, id) => api.close(id), l10n.supportClosedSnack);
    }
  }

  Future<void> _reopen() {
    final l10n = AppLocalizations.of(context);
    return _ticketAction(
      (api, id) => api.reopen(id),
      l10n.supportReopenedSnack,
    );
  }

  Future<void> _rate() {
    final l10n = AppLocalizations.of(context);
    final rating = _rating;
    final comment = _ratingComment.text;
    return _ticketAction(
      (api, id) => api.rate(id, rating: rating, comment: comment),
      l10n.supportRatingSnack,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final thread = _thread;

    final Widget body;
    if (thread == null) {
      body = ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 48),
        children: [
          ConnectPageHeader(
            leading: const BackButton(),
            eyebrow: l10n.supportTicketsEyebrow,
            title: l10n.supportTicketsTitle,
          ),
          const SizedBox(height: ConnectMetrics.sectionGap),
          if (_loadError != null)
            supportFeatureDisabled(_loadError)
                ? const SupportUnavailablePanel()
                : SupportNotice(
                    icon: Icons.cloud_off_rounded,
                    title: l10n.supportThreadLoadErrorTitle,
                    message: supportErrorMessage(l10n, _loadError!),
                    action: TextButton.icon(
                      onPressed: _loading ? null : _load,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(l10n.supportTryAgain),
                    ),
                  )
          else
            const Center(child: CircularProgressIndicator()),
        ],
      );
    } else {
      body = Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _ThreadBody(
                thread: thread,
                controller: _scroll,
                acting: _acting,
                rating: _rating,
                ratingComment: _ratingComment,
                onRatingChanged: (value) => setState(() => _rating = value),
                onRate: _rate,
                onClose: _confirmClose,
                onReopen: _reopen,
              ),
            ),
          ),
          _Composer(
            enabled: thread.ticket.canReply,
            sending: _sending,
            controller: _reply,
            tray: _tray,
            onAttach: _attach,
            onSend: _send,
          ),
        ],
      );
    }

    return Scaffold(
      body: PostLoginBackdrop(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: body,
            ),
          ),
        ),
      ),
    );
  }
}

class _ThreadBody extends StatelessWidget {
  const _ThreadBody({
    required this.thread,
    required this.controller,
    required this.acting,
    required this.rating,
    required this.ratingComment,
    required this.onRatingChanged,
    required this.onRate,
    required this.onClose,
    required this.onReopen,
  });

  final SupportThread thread;
  final ScrollController controller;
  final bool acting;
  final int rating;
  final TextEditingController ratingComment;
  final ValueChanged<int> onRatingChanged;
  final VoidCallback onRate;
  final VoidCallback onClose;
  final VoidCallback onReopen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final ticket = thread.ticket;
    final opened = supportWhen(context, ticket.createdAt);
    return LayoutBuilder(
      builder: (context, box) {
        final gutter = ConnectMetrics.gutterFor(box.maxWidth);
        return ListView(
          controller: controller,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(gutter, 12, gutter, 24),
          children: [
            ConnectPageHeader(
              leading: const BackButton(),
              eyebrow: ticket.reference,
              title: ticket.subject,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SupportStatusChip(status: ticket.memberStatus),
                Text(
                  opened.isEmpty
                      ? supportCategoryLabel(l10n, ticket.category)
                      : l10n.supportTicketMeta(
                          supportCategoryLabel(l10n, ticket.category),
                          opened,
                        ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _StatusBanner(ticket: ticket),
            if (ticket.canClose || ticket.canReopen) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  if (ticket.canReopen)
                    FilledButton.tonalIcon(
                      key: const Key('support_reopen'),
                      onPressed: acting ? null : onReopen,
                      icon: const Icon(Icons.replay_rounded),
                      label: Text(l10n.supportReopen),
                    ),
                  if (ticket.canClose)
                    OutlinedButton.icon(
                      key: const Key('support_close'),
                      onPressed: acting ? null : onClose,
                      icon: const Icon(Icons.task_alt_rounded),
                      label: Text(l10n.supportCloseTicket),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            for (final message in thread.messages)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _MessageBubble(ticketId: ticket.id, message: message),
              ),
            if (ticket.canRate || ticket.satisfaction != null) ...[
              const SizedBox(height: 12),
              _RatingPanel(
                ticket: ticket,
                rating: rating,
                comment: ratingComment,
                busy: acting,
                onChanged: onRatingChanged,
                onSubmit: onRate,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.ticket});

  final SupportTicket ticket;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final merged = ticket.mergedIntoReference;
    final reopenUntil = ticket.reopenUntil;
    final (icon, message) = merged != null
        ? (Icons.merge_rounded, l10n.supportBannerMerged(merged))
        : switch (ticket.memberStatus) {
            SupportStatus.open => (
              Icons.schedule_rounded,
              l10n.supportBannerOpen,
            ),
            SupportStatus.pendingMember => (
              Icons.reply_rounded,
              l10n.supportBannerWaiting,
            ),
            SupportStatus.onHold => (
              Icons.pause_circle_outline_rounded,
              l10n.supportBannerOnHold,
            ),
            SupportStatus.resolved => (
              Icons.task_alt_rounded,
              l10n.supportBannerResolved,
            ),
            SupportStatus.closed =>
              ticket.canReopen && reopenUntil != null
                  ? (
                      Icons.lock_clock_outlined,
                      l10n.supportBannerClosedUntil(
                        MaterialLocalizations.of(
                          context,
                        ).formatMediumDate(reopenUntil),
                      ),
                    )
                  : (Icons.lock_outline_rounded, l10n.supportBannerClosed),
          };
    final waiting = ticket.memberStatus == SupportStatus.pendingMember;
    final background = waiting
        ? colors.tertiaryContainer
        : colors.surfaceContainerHighest;
    final foreground = waiting ? colors.onTertiaryContainer : colors.onSurface;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        key: const Key('support_status_banner'),
        padding: const EdgeInsets.all(ConnectMetrics.padding),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(ConnectMetrics.cardRadius),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: foreground),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.ticketId, required this.message});

  final String ticketId;
  final SupportMessage message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final when = supportWhen(context, message.createdAt);

    if (message.fromSystem) {
      return Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Text(
            when.isEmpty ? message.body : '${message.body} · $when',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    final mine = message.fromMember;
    final author = mine ? l10n.supportThreadYou : l10n.supportThreadAgentName;
    final background = mine ? colors.primaryContainer : colors.surface;
    final foreground = mine ? colors.onPrimaryContainer : colors.onSurface;
    final secondary = mine
        ? colors.onPrimaryContainer
        : colors.onSurfaceVariant;
    return Align(
      alignment: mine
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadiusDirectional.only(
              topStart: const Radius.circular(16),
              topEnd: const Radius.circular(16),
              bottomStart: Radius.circular(mine ? 16 : 4),
              bottomEnd: Radius.circular(mine ? 4 : 16),
            ),
            border: mine ? null : Border.all(color: colors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!mine) ...[
                    Icon(
                      Icons.support_agent_rounded,
                      size: 16,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Flexible(
                    child: Text(
                      when.isEmpty ? author : '$author · $when',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              if (message.body.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  message.body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: foreground,
                  ),
                ),
              ],
              if (message.attachments.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final attachment in message.attachments)
                      SupportAttachmentView(
                        ticketId: ticketId,
                        attachment: attachment,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RatingPanel extends StatelessWidget {
  const _RatingPanel({
    required this.ticket,
    required this.rating,
    required this.comment,
    required this.busy,
    required this.onChanged,
    required this.onSubmit,
  });

  final SupportTicket ticket;
  final int rating;
  final TextEditingController comment;
  final bool busy;
  final ValueChanged<int> onChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final given = ticket.satisfaction;

    if (given != null) {
      return ConnectPanel(
        key: const Key('support_rating_given'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConnectSectionHeader(label: l10n.supportRatedTitle.toUpperCase()),
            const SizedBox(height: 8),
            Semantics(
              label: l10n.supportRatedValue(given.rating),
              excludeSemantics: true,
              child: Row(
                children: [
                  for (var star = 1; star <= 5; star++)
                    Icon(
                      star <= given.rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: colors.primary,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.supportRatedValue(given.rating),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            if (given.comment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                given.comment,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ConnectPanel(
      key: const Key('support_rating_form'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConnectSectionHeader(
            label: l10n.supportRateTitle.toUpperCase(),
            caption: l10n.supportRateCaption,
          ),
          const SizedBox(height: 8),
          Wrap(
            children: [
              for (var star = 1; star <= 5; star++)
                IconButton(
                  key: Key('support_rate_$star'),
                  tooltip: l10n.supportRateStar(star),
                  isSelected: star <= rating,
                  onPressed: busy ? null : () => onChanged(star),
                  color: colors.primary,
                  selectedIcon: const Icon(Icons.star_rounded),
                  icon: const Icon(Icons.star_outline_rounded),
                ),
            ],
          ),
          if (rating > 0) ...[
            const SizedBox(height: 8),
            TextField(
              key: const Key('support_rating_comment'),
              controller: comment,
              maxLength: SupportLimits.ratingCommentMax,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: l10n.supportRateCommentLabel,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton(
                key: const Key('support_rating_submit'),
                onPressed: busy ? null : onSubmit,
                child: Text(l10n.supportRateSubmit),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.enabled,
    required this.sending,
    required this.controller,
    required this.tray,
    required this.onAttach,
    required this.onSend,
  });

  final bool enabled;
  final bool sending;
  final TextEditingController controller;
  final SupportAttachmentTray tray;
  final VoidCallback onAttach;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final active = enabled && !sending;
    return Material(
      color: colors.surface,
      child: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colors.outlineVariant)),
        ),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: ListenableBuilder(
          listenable: tray,
          builder: (context, _) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (tray.items.isNotEmpty) ...[
                SupportDraftAttachments(tray: tray),
                const SizedBox(height: 8),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    key: const Key('support_reply_attach'),
                    tooltip: l10n.supportAttachScreenshot,
                    onPressed: active && tray.remaining > 0 ? onAttach : null,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: TextField(
                      key: const Key('support_reply'),
                      controller: controller,
                      enabled: enabled,
                      minLines: 1,
                      maxLines: 5,
                      maxLength: SupportLimits.bodyMax,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: enabled
                            ? l10n.supportReplyHint
                            : l10n.supportReplyDisabledHint,
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    key: const Key('support_reply_send'),
                    tooltip: l10n.supportSendReply,
                    onPressed: active ? onSend : null,
                    icon: sending
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
