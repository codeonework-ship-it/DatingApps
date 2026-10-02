import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/widgets/connect_page.dart';
import '../../l10n/app_localizations.dart';
import '../common/widgets/community_actions.dart';
import 'group_widgets.dart';
import 'groups_data.dart';

/// A cover photo the owner picked and confirmed, ready to upload.
typedef PickedGroupCover = ({Uint8List bytes, String filename});

/// Lets the owner choose a cover from their photos or the camera, then shows
/// it cropped to the banner the group will use before they confirm. Returns
/// null when they back out (or the photo is too large, with a message).
Future<PickedGroupCover?> pickGroupCover(
  BuildContext context,
  WidgetRef ref,
) async {
  final l10n = AppLocalizations.of(context);
  final source = await showGroupSheet<ImageSource>(
    context,
    GroupSheetFrame(
      title: l10n.groupsCoverSheetTitle,
      subtitle: l10n.groupsCoverSheetBody,
      children: [
        ListTile(
          key: const ValueKey('groups.cover.gallery'),
          contentPadding: EdgeInsets.zero,
          minTileHeight: 56,
          leading: const Icon(Icons.photo_library_outlined),
          title: Text(l10n.groupsCoverFromPhotos),
          onTap: () => Navigator.of(context).pop(ImageSource.gallery),
        ),
        ListTile(
          key: const ValueKey('groups.cover.camera'),
          contentPadding: EdgeInsets.zero,
          minTileHeight: 56,
          leading: const Icon(Icons.photo_camera_outlined),
          title: Text(l10n.groupsCoverTakePhoto),
          onTap: () => Navigator.of(context).pop(ImageSource.camera),
        ),
      ],
    ),
  );
  if (source == null || !context.mounted) {
    return null;
  }
  final file = await ref.read(groupCoverPickerProvider)(source);
  if (file == null || !context.mounted) {
    return null;
  }
  final bytes = await file.readAsBytes();
  if (!context.mounted) {
    return null;
  }
  if (bytes.length > groupCoverMaxBytes) {
    showCommunitySnack(context, l10n.groupsCoverTooLarge);
    return null;
  }
  final confirmed = await showGroupSheet<bool>(
    context,
    GroupSheetFrame(
      title: l10n.groupsCoverPreviewTitle,
      subtitle: l10n.groupsCoverPreviewBody,
      footer: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
              child: Text(l10n.groupsCancel),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              key: const ValueKey('groups.cover.confirm'),
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
              child: Text(l10n.groupsCoverUseThisPhoto),
            ),
          ),
        ],
      ),
      children: [GroupCoverPreview(bytes: bytes)],
    ),
  );
  if (confirmed != true) {
    return null;
  }
  return (bytes: bytes, filename: file.name.isEmpty ? 'cover.jpg' : file.name);
}

/// A picked photo cropped to the 3:1 banner, as groups will show it.
class GroupCoverPreview extends StatelessWidget {
  const GroupCoverPreview({required this.bytes, super.key});
  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(ConnectMetrics.cardRadius),
      child: AspectRatio(
        aspectRatio: 3,
        child: ColoredBox(
          color: colors.surfaceContainerHighest,
          child: Image.memory(
            bytes,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            semanticLabel: AppLocalizations.of(
              context,
            ).groupsCoverPreviewSemantics,
            errorBuilder: (_, _, _) => Center(
              child: Icon(
                Icons.image_not_supported_outlined,
                color: colors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Upload progress for a cover: a bar and "Uploading cover… 40%".
class GroupCoverProgress extends StatelessWidget {
  const GroupCoverProgress({required this.progress, super.key});

  /// 0–1, or null before the first bytes are sent.
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final percent = progress == null ? null : (progress! * 100).round();
    final label = percent == null || percent >= 100
        ? l10n.groupsCoverChecking
        : l10n.groupsCoverUploading(percent);
    return Semantics(
      liveRegion: true,
      label: label,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(
              key: const ValueKey('groups.cover.progress'),
              value: percent == null || percent >= 100 ? null : progress,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// What the owner sees after an upload.
String groupCoverUploadedMessage(AppLocalizations l10n, Group group) =>
    group.coverUnderReview
    ? l10n.groupsCoverUploadedReview
    : l10n.groupsCoverUpdated;
