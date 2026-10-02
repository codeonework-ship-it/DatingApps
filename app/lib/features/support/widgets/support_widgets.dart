import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/widgets/connect_page.dart';
import '../../../l10n/app_localizations.dart';
import '../support_api.dart';
import '../support_models.dart';

/// Localised label for a category key; unknown keys fall back to "Other".
String supportCategoryLabel(AppLocalizations l10n, String key) => switch (key) {
  'account_login' => l10n.supportCategoryAccountLogin,
  'verification' => l10n.supportCategoryVerification,
  'payments_billing' => l10n.supportCategoryPaymentsBilling,
  'safety_harassment' => l10n.supportCategorySafetyHarassment,
  'matches_chat' => l10n.supportCategoryMatchesChat,
  'technical' => l10n.supportCategoryTechnical,
  'feature_request' => l10n.supportCategoryFeatureRequest,
  'privacy_data' => l10n.supportCategoryPrivacyData,
  _ => l10n.supportCategoryOther,
};

IconData supportCategoryIcon(String key) => switch (key) {
  'account_login' => Icons.login_rounded,
  'verification' => Icons.verified_user_outlined,
  'payments_billing' => Icons.receipt_long_outlined,
  'safety_harassment' => Icons.shield_outlined,
  'matches_chat' => Icons.forum_outlined,
  'technical' => Icons.bug_report_outlined,
  'feature_request' => Icons.lightbulb_outline_rounded,
  'privacy_data' => Icons.lock_outline_rounded,
  _ => Icons.help_outline_rounded,
};

String supportStatusLabel(AppLocalizations l10n, SupportStatus status) =>
    switch (status) {
      SupportStatus.open => l10n.supportStatusOpen,
      SupportStatus.pendingMember => l10n.supportStatusWaitingForYou,
      SupportStatus.onHold => l10n.supportStatusOnHold,
      SupportStatus.resolved => l10n.supportStatusResolved,
      SupportStatus.closed => l10n.supportStatusClosed,
    };

/// A member-readable explanation of a failed support call. Known server codes
/// get a localised message; anything else shows the server's own message so
/// a real failure is never disguised.
String supportErrorMessage(AppLocalizations l10n, Object error) {
  if (error is! SupportException) {
    return l10n.supportErrorGeneric;
  }
  if (error.offline) {
    return l10n.supportErrorOffline;
  }
  switch (error.code) {
    case 'FEATURE_DISABLED':
      return l10n.supportUnavailableTitle;
    case 'SUPPORT_RATE_LIMITED':
      final seconds = error.retryAfterSeconds;
      if (seconds == null || seconds <= 0) {
        return l10n.supportErrorRateLimitedGeneric;
      }
      return l10n.supportErrorRateLimited(
        ((seconds + 59) ~/ 60).clamp(1, 1440),
      );
    case 'SUPPORT_TOO_MANY_OPEN':
      return l10n.supportErrorTooManyOpen;
    case 'SUPPORT_TICKET_CLOSED':
      return l10n.supportErrorTicketClosed;
    case 'SUPPORT_REOPEN_WINDOW_PASSED':
      return l10n.supportErrorReopenWindowPassed;
    case 'SUPPORT_ALREADY_RATED':
      return l10n.supportErrorAlreadyRated;
    case 'SUPPORT_NOT_RESOLVED':
      return l10n.supportErrorNotResolved;
    case 'SUPPORT_ATTACHMENT_TYPE':
      return l10n.supportErrorAttachmentType;
  }
  if (error.statusCode == 415) {
    return l10n.supportErrorAttachmentType;
  }
  if (error.statusCode == 413) {
    return l10n.supportErrorAttachmentTooLarge;
  }
  if (error.statusCode == 404) {
    return l10n.supportErrorNotFound;
  }
  if (error.statusCode == 429) {
    return l10n.supportErrorRateLimitedGeneric;
  }
  return error.message.trim().isNotEmpty
      ? error.message.trim()
      : l10n.supportErrorGeneric;
}

bool supportFeatureDisabled(Object? error) =>
    error is SupportException && error.featureDisabled;

/// A short, localised time: the time of day for today, otherwise the date.
String supportWhen(BuildContext context, DateTime? at) {
  if (at == null) {
    return '';
  }
  final material = MaterialLocalizations.of(context);
  final now = DateTime.now();
  if (at.year == now.year && at.month == now.month && at.day == now.day) {
    return material.formatTimeOfDay(
      TimeOfDay.fromDateTime(at),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
  }
  return material.formatMediumDate(at);
}

/// Status pill. Read by screen readers as "Status: Waiting for you".
class SupportStatusChip extends StatelessWidget {
  const SupportStatusChip({required this.status, super.key});

  final SupportStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final (background, foreground) = switch (status) {
      SupportStatus.open => (
        colors.primaryContainer,
        colors.onPrimaryContainer,
      ),
      SupportStatus.pendingMember => (
        colors.tertiaryContainer,
        colors.onTertiaryContainer,
      ),
      SupportStatus.resolved => (
        colors.secondaryContainer,
        colors.onSecondaryContainer,
      ),
      SupportStatus.onHold || SupportStatus.closed => (
        colors.surfaceContainerHighest,
        colors.onSurface,
      ),
    };
    final label = supportStatusLabel(l10n, status);
    return Semantics(
      container: true,
      label: l10n.supportStatusSemantics(label),
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// A quiet panel with an icon, a title, a message and an optional action.
class SupportNotice extends StatelessWidget {
  const SupportNotice({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return ConnectPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: colors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (action != null) ...[
            const SizedBox(height: 12),
            Align(alignment: AlignmentDirectional.centerEnd, child: action),
          ],
        ],
      ),
    );
  }
}

/// Shown when the server reports `FEATURE_DISABLED`.
class SupportUnavailablePanel extends StatelessWidget {
  const SupportUnavailablePanel({super.key, this.action});

  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SupportNotice(
      key: const Key('support_unavailable'),
      icon: Icons.support_agent_rounded,
      title: l10n.supportUnavailableTitle,
      message: l10n.supportUnavailableBody,
      action: action,
    );
  }
}

/// An attachment on a sent message: an image thumbnail (bytes fetched with
/// the member's session) or a file tile.
class SupportAttachmentView extends ConsumerWidget {
  const SupportAttachmentView({
    required this.ticketId,
    required this.attachment,
    super.key,
  });

  final String ticketId;
  final SupportAttachment attachment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    if (!attachment.isImage) {
      return _FileTile(attachment: attachment);
    }
    final bytes = ref.watch(
      supportAttachmentBytesProvider((
        ticketId: ticketId,
        attachmentId: attachment.id,
      )),
    );
    final radius = BorderRadius.circular(12);
    return Semantics(
      label: l10n.supportAttachmentImage(attachment.filename),
      button: bytes.hasValue,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: 96,
        child: Material(
          color: colors.surfaceContainerHighest,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: bytes.when(
            loading: () => const Center(
              child: SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (_, _) => Tooltip(
              message: l10n.supportAttachmentLoadFailed,
              child: Icon(
                Icons.broken_image_outlined,
                color: colors.onSurfaceVariant,
              ),
            ),
            data: (data) => InkWell(
              onTap: () => _showFullImage(context, data, attachment.filename),
              child: Image.memory(
                data,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => Icon(
                  Icons.broken_image_outlined,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> _showFullImage(
    BuildContext context,
    Uint8List bytes,
    String name,
  ) => showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      insetPadding: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          InteractiveViewer(child: Image.memory(bytes, semanticLabel: name)),
          PositionedDirectional(
            top: 4,
            end: 4,
            child: IconButton.filledTonal(
              tooltip: MaterialLocalizations.of(
                dialogContext,
              ).closeButtonTooltip,
              onPressed: () => Navigator.of(dialogContext).pop(),
              icon: const Icon(Icons.close_rounded),
            ),
          ),
        ],
      ),
    ),
  );
}

class _FileTile extends StatelessWidget {
  const _FileTile({required this.attachment});

  final SupportAttachment attachment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 48, maxWidth: 240),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.picture_as_pdf_outlined, color: colors.primary),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  attachment.filename,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface,
                  ),
                ),
                Text(
                  formatSupportFileSize(attachment.sizeBytes),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String formatSupportFileSize(int bytes) {
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  if (bytes >= 1024) {
    return '${(bytes / 1024).round()} KB';
  }
  return '$bytes B';
}

enum SupportUploadState { uploading, done, failed }

/// One screenshot chosen for a ticket or reply, uploaded as soon as it is
/// picked so a bad file is reported straight away.
class SupportDraftAttachment {
  SupportDraftAttachment({required this.bytes, required this.filename});

  final Uint8List bytes;
  final String filename;
  SupportUploadState state = SupportUploadState.uploading;
  String? uploadId;
  String? error;
}

/// The screenshots attached to a draft and their uploads.
class SupportAttachmentTray extends ChangeNotifier {
  SupportAttachmentTray(this._api, this._l10n);

  final SupportApi _api;
  AppLocalizations _l10n;
  final items = <SupportDraftAttachment>[];
  bool _disposed = false;

  // ignore: use_setters_to_change_properties
  void useLocalizations(AppLocalizations value) => _l10n = value;

  int get remaining => SupportLimits.attachmentsPerMessage - items.length;

  bool get uploading =>
      items.any((item) => item.state == SupportUploadState.uploading);

  bool get hasFailures =>
      items.any((item) => item.state == SupportUploadState.failed);

  List<String> get uploadIds => [
    for (final item in items)
      if (item.uploadId != null) item.uploadId!,
  ];

  Future<void> addFiles(List<XFile> files) async {
    final added = <SupportDraftAttachment>[];
    for (final file in files.take(remaining)) {
      final bytes = await file.readAsBytes();
      final type = sniffSupportImageType(bytes);
      final extension = type == 'image/png' ? 'png' : 'jpg';
      final item = SupportDraftAttachment(
        bytes: bytes,
        filename: 'screenshot-${items.length + added.length + 1}.$extension',
      );
      added.add(item);
    }
    if (added.isEmpty) {
      return;
    }
    items.addAll(added);
    _notify();
    await Future.wait(added.map(_upload));
  }

  Future<void> retry(SupportDraftAttachment item) => _upload(item);

  void remove(SupportDraftAttachment item) {
    items.remove(item);
    _notify();
  }

  void clear() {
    items.clear();
    _notify();
  }

  Future<void> _upload(SupportDraftAttachment item) async {
    item
      ..state = SupportUploadState.uploading
      ..error = null;
    _notify();
    try {
      final upload = await _api.uploadAttachment(
        bytes: item.bytes,
        filename: item.filename,
        // Unknown bytes are sent as-is; the server answers 415 and the member
        // sees that real error.
        contentType:
            sniffSupportImageType(item.bytes) ?? 'application/octet-stream',
      );
      item
        ..uploadId = upload.id
        ..state = SupportUploadState.done;
    } on Object catch (error) {
      item
        ..state = SupportUploadState.failed
        ..error = supportErrorMessage(_l10n, error);
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Thumbnails of the screenshots in a draft, each removable, failed ones
/// retryable.
class SupportDraftAttachments extends StatelessWidget {
  const SupportDraftAttachments({required this.tray, super.key});

  final SupportAttachmentTray tray;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return ListenableBuilder(
      listenable: tray,
      builder: (context, _) {
        if (tray.items.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in tray.items)
                  SizedBox(
                    width: 96,
                    height: 96,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            item.bytes,
                            fit: BoxFit.cover,
                            semanticLabel: item.filename,
                            errorBuilder: (_, _, _) => ColoredBox(
                              color: colors.surfaceContainerHighest,
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                        if (item.state == SupportUploadState.uploading)
                          Semantics(
                            label: l10n.supportAttachmentUploading,
                            child: ColoredBox(
                              color: colors.surface.withValues(alpha: 0.6),
                              child: const Center(
                                child: SizedBox.square(
                                  dimension: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (item.state == SupportUploadState.failed)
                          PositionedDirectional(
                            start: 0,
                            bottom: 0,
                            child: IconButton.filled(
                              style: IconButton.styleFrom(
                                backgroundColor: colors.error,
                                foregroundColor: colors.onError,
                              ),
                              tooltip: l10n.supportRetryUpload,
                              onPressed: () => tray.retry(item),
                              icon: const Icon(Icons.refresh_rounded),
                            ),
                          ),
                        PositionedDirectional(
                          top: 0,
                          end: 0,
                          child: IconButton.filledTonal(
                            tooltip: l10n.supportRemoveAttachment(
                              item.filename,
                            ),
                            onPressed: () => tray.remove(item),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            for (final item in tray.items)
              if (item.state == SupportUploadState.failed && item.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${item.filename}: ${item.error}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.error,
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}
