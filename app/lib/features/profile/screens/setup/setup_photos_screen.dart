import 'package:flutter/foundation.dart';
import '../../../../core/platform/browser_context.dart';
import '../../../../core/platform/platform_photo.dart';

import 'package:flutter/material.dart';

import '../../../../core/network/api_error_message.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/layout/app_layout.dart';
import '../../../../core/widgets/glass_widgets.dart';
import '../../../../core/widgets/qa_id.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/profile_setup_provider.dart';
import 'setup_about_screen.dart';
import 'setup_shared_widgets.dart';

/// Step 2 of 4 — photo gallery / camera picker with reorderable list.
///
/// Uses [ConsumerStatefulWidget] + single stable [Scaffold] pattern to keep
/// the widget-tree identity stable across provider rebuilds.
///
/// Photos are uploaded directly to the Go BFF (multipart/form-data) which
/// stores them on disk and returns a public URL via `/v1/media/*`.
class SetupPhotosScreen extends ConsumerStatefulWidget {
  const SetupPhotosScreen({super.key, this.isSetupFlow = false});

  final bool isSetupFlow;

  @override
  ConsumerState<SetupPhotosScreen> createState() => _SetupPhotosScreenState();
}

class _SetupPhotosScreenState extends ConsumerState<SetupPhotosScreen> {
  bool _isPickingPhoto = false;

  /// A reorder or delete is waiting for the server. Another one started
  /// now would act on a list that is about to change (a double tap on "Set
  /// as profile picture" used to swap the photos back).
  bool _isUpdatingPhotos = false;

  // ── Navigation helpers ──────────────────────────────────────────────────
  void _navigateNext() {
    if (!mounted) {
      return;
    }
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (widget.isSetupFlow) {
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => const SetupAboutScreen(isSetupFlow: true),
          ),
        );
      } else if (kIsWeb && !Navigator.of(context).canPop()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).profileSetupPhotosSaved),
          ),
        );
      } else {
        Navigator.of(context).pop();
      }
    });
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showMediaError(Object error) {
    if (!mounted) {
      return;
    }
    _showError(profileMediaErrorMessage(error, AppLocalizations.of(context)));
  }

  Future<void> _pickFromGallery() async {
    if (_isPickingPhoto) {
      return;
    }
    final draft = ref.read(profileSetupNotifierProvider).valueOrNull;
    if (draft != null && draft.photos.length >= ValidationConstants.maxPhotos) {
      _showError(
        AppLocalizations.of(
          context,
        ).profileSetupPhotosMaxReached(ValidationConstants.maxPhotos),
      );
      return;
    }
    setState(() => _isPickingPhoto = true);
    try {
      await ref
          .read(profileSetupNotifierProvider.notifier)
          .addPhotoFromGallery();
    } on Object catch (error) {
      _showMediaError(error);
    } finally {
      if (mounted) {
        setState(() => _isPickingPhoto = false);
      }
    }
  }

  Future<void> _pickFromCamera() async {
    if (_isPickingPhoto) {
      return;
    }
    final draft = ref.read(profileSetupNotifierProvider).valueOrNull;
    if (draft != null && draft.photos.length >= ValidationConstants.maxPhotos) {
      _showError(
        AppLocalizations.of(
          context,
        ).profileSetupPhotosMaxReached(ValidationConstants.maxPhotos),
      );
      return;
    }
    setState(() => _isPickingPhoto = true);
    try {
      await ref
          .read(profileSetupNotifierProvider.notifier)
          .addPhotoFromCamera();
    } on Object catch (error) {
      _showMediaError(error);
    } finally {
      if (mounted) {
        setState(() => _isPickingPhoto = false);
      }
    }
  }

  Future<void> _confirmDelete(ProfilePhotoItem photo) async {
    if (_isPickingPhoto) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.profileSetupRemovePhotoTitle),
        content: Text(l10n.profileSetupRemovePhotoBody),
        actions: [
          TextButton(
            key: const ValueKey('qa.setup.photos.cancel_delete'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.profileSetupCancel),
          ),
          FilledButton(
            key: const ValueKey('qa.setup.photos.confirm_delete'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.profileSetupRemove),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || _isUpdatingPhotos) {
      return;
    }
    _isUpdatingPhotos = true;
    try {
      await ref.read(profileSetupNotifierProvider.notifier).deletePhoto(photo);
    } on Object catch (error) {
      _showMediaError(error);
    } finally {
      _isUpdatingPhotos = false;
    }
  }

  Future<void> _reorderPhotos(int oldIndex, int newIndex) async {
    if (_isPickingPhoto || _isUpdatingPhotos || oldIndex == newIndex) {
      return;
    }
    _isUpdatingPhotos = true;
    try {
      await ref
          .read(profileSetupNotifierProvider.notifier)
          .reorderPhotos(oldIndex, newIndex);
    } on Object catch (error) {
      _showMediaError(error);
    } finally {
      _isUpdatingPhotos = false;
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final draftAsync = ref.watch(profileSetupNotifierProvider);
    final draft = draftAsync.valueOrNull;
    final photoCount = draft?.photos.length ?? 0;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: SafeArea(
          child: Column(
            children: [
              SetupHeader(
                currentStep: 2,
                totalSteps: 4,
                onBack: () {
                  if (kIsWeb && !Navigator.of(context).canPop()) {
                    setWebRoute('/profile');
                  } else {
                    Navigator.of(context).pop();
                  }
                },
              ),
              Expanded(
                child: draftAsync.when(
                  loading: () => Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: SetupErrorState(
                        message: apiErrorMessage(
                          e,
                          fallback: AppLocalizations.of(
                            context,
                          ).commonSomethingWentWrongTryAgain,
                        ),
                        onRetry: () =>
                            ref.invalidate(profileSetupNotifierProvider),
                      ),
                    ),
                  ),
                  data: (d) => _PhotoListBody(
                    draft: d,
                    photoCount: photoCount,
                    isSetupFlow: widget.isSetupFlow,
                    isPickingPhoto: _isPickingPhoto,
                    onPickGallery: _pickFromGallery,
                    onPickCamera: _pickFromCamera,
                    onDeletePhoto: _confirmDelete,
                    onReorder: _reorderPhotos,
                    onSetPrimary: (index) {
                      if (index == 0 || _isPickingPhoto) {
                        return;
                      }
                      _reorderPhotos(index, 0);
                    },
                    onNext: () {
                      if (d.photos.length < ValidationConstants.minPhotos) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(
                                context,
                              ).profileSetupPhotosMinRequired(
                                ValidationConstants.minPhotos,
                              ),
                            ),
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.error,
                          ),
                        );
                        return;
                      }
                      _navigateNext();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Photo list body — extracted StatelessWidget so the widget-tree identity
// remains stable when provider state changes (avoids unnecessary rebuilds
// of the outer Scaffold / SafeArea / Column shell).
// =============================================================================

class _PhotoListBody extends StatelessWidget {
  const _PhotoListBody({
    required this.draft,
    required this.photoCount,
    required this.isSetupFlow,
    required this.isPickingPhoto,
    required this.onPickGallery,
    required this.onPickCamera,
    required this.onDeletePhoto,
    required this.onReorder,
    required this.onSetPrimary,
    required this.onNext,
  });

  final ProfileDraft draft;
  final int photoCount;
  final bool isSetupFlow;
  final bool isPickingPhoto;
  final VoidCallback onPickGallery;
  final VoidCallback onPickCamera;
  final void Function(ProfilePhotoItem) onDeletePhoto;
  final void Function(int, int) onReorder;
  final void Function(int index) onSetPrimary;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
      children: [
        // ── Title row ────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.profileSetupPhotosTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.profileSetupPhotosSubtitle(
                      ValidationConstants.minPhotos,
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            CountBadge(current: photoCount, max: ValidationConstants.maxPhotos),
          ],
        ),
        const SizedBox(height: 16),

        // ── Pick source ──────────────────────────────────────
        InfoCard(
          icon: Icons.add_a_photo_outlined,
          title: l10n.profileSetupChooseSource,
          child: Row(
            children: [
              Expanded(
                child: _PickerButton(
                  icon: Icons.photo_library_rounded,
                  label: l10n.profileSetupGallery,
                  qaId: 'gallery',
                  isLoading: isPickingPhoto,
                  onTap: onPickGallery,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PickerButton(
                  icon: Icons.photo_camera_rounded,
                  label: l10n.profileSetupCamera,
                  qaId: 'camera',
                  isLoading: isPickingPhoto,
                  onTap: onPickCamera,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.profileSetupPhotoRequirements,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),

        // ── Tip banner ───────────────────────────────────────
        const SizedBox(height: 14),
        TipBanner(
          text: draft.photos.isEmpty
              ? l10n.profileSetupPhotosTipEmpty(ValidationConstants.minPhotos)
              : draft.photos.length < ValidationConstants.minPhotos
              ? l10n.profileSetupPhotosTipMore(
                  ValidationConstants.minPhotos - draft.photos.length,
                )
              : l10n.profileSetupPhotosTipDone,
        ),

        // ── Photo grid ───────────────────────────────────────
        if (draft.photos.isNotEmpty) ...[
          const SizedBox(height: 14),
          InfoCard(
            icon: Icons.collections_outlined,
            title: l10n.profileSetupYourPhotosHeading,
            // Sized by its rows: a fixed height clipped rows taller than
            // expected (a safety-review note, large text, long translations)
            // and, not being scrollable, left them out of reach.
            child: ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: draft.photos.length,
              onReorder: isPickingPhoto ? (_, _) {} : onReorder,
              itemBuilder: (context, index) {
                final photo = draft.photos[index];
                return _PhotoRow(
                  key: ValueKey(photo.id),
                  photo: photo,
                  index: index,
                  onDelete: () => onDeletePhoto(photo),
                  onSetPrimary: () => onSetPrimary(index),
                  enabled: !isPickingPhoto,
                );
              },
            ),
          ),
        ],

        const SizedBox(height: 24),

        // ── Next button ──────────────────────────────────────
        QaId(
          'qa.setup.photos.next_button',
          child: SizedBox(
            height: 54,
            width: double.infinity,
            child: GlassButton(
              key: const ValueKey('qa.setup.photos.next_button'),
              label: isSetupFlow
                  ? l10n.profileSetupContinueToAbout
                  : l10n.profileSetupSavePhotos,
              icon: Icons.arrow_forward_rounded,
              shinyEffect: true,
              textColor: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w800,
              onPressed: onNext,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Helper widgets ───────────────────────────────────────────────────────────

class _PickerButton extends StatelessWidget {
  const _PickerButton({
    required this.icon,
    required this.label,
    required this.qaId,
    required this.onTap,
    this.isLoading = false,
  });
  final IconData icon;
  final String label;

  /// Stable QA id segment ('gallery' / 'camera'), independent of the
  /// translated [label].
  final String qaId;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) => QaId(
    'qa.setup.photos.${qaId}_button',
    child: SizedBox(
      height: 58,
      child: GlassButton(
        key: ValueKey<String>('qa.setup.photos.${qaId}_button'),
        label: label,
        icon: icon,
        isLoading: isLoading,
        textColor: Theme.of(context).colorScheme.onSurface,
        fontWeight: FontWeight.w800,
        onPressed: isLoading ? null : onTap,
      ),
    ),
  );
}

/// Displays a photo thumbnail + label + delete button + drag handle.
///
/// Supports both network URLs (from Go BFF) and local file paths (optimistic
/// entries that haven't finished uploading yet).
class _PhotoRow extends StatelessWidget {
  const _PhotoRow({
    required this.photo,
    required this.index,
    required this.onDelete,
    required this.onSetPrimary,
    required this.enabled,
    super.key,
  });
  final ProfilePhotoItem photo;
  final int index;
  final VoidCallback onDelete;
  final VoidCallback onSetPrimary;
  final bool enabled;

  Widget _buildThumbnail(ColorScheme scheme) {
    final url = photo.photoUrl;
    // Network URL (from BFF /v1/media/...)
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: platformPhoto(
        url,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _brokenImage(scheme),
      ),
    );
  }

  Widget _brokenImage(ColorScheme scheme) => Container(
    width: 60,
    height: 60,
    decoration: BoxDecoration(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          photo.isHeic ? Icons.image_outlined : Icons.broken_image_outlined,
          size: 24,
          color: scheme.onSurfaceVariant,
        ),
        if (photo.isHeic)
          Text(
            'HEIC',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 9),
          ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _buildThumbnail(scheme),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  index == 0
                      ? l10n.profileSetupPrimaryPhoto
                      : l10n.profileSetupPhotoNumber(index + 1),
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  index == 0
                      ? l10n.profileSetupShownFirst
                      : l10n.profileSetupDragHandleHint,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                if (photo.moderationStatus != 'approved')
                  Padding(
                    padding: const EdgeInsets.only(top: AppLayout.space2),
                    child: Row(
                      children: [
                        Icon(
                          Icons.policy_outlined,
                          size: 14,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            photo.moderationStatus == 'review_required'
                                ? l10n.profileSetupAwaitingSafetyReview
                                : l10n.profileSetupSafetyCheckInProgress,
                            style: TextStyle(
                              color: scheme.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (index != 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: GestureDetector(
                      key: ValueKey<String>(
                        'qa.setup.photos.set_primary_${photo.id}',
                      ),
                      onTap: enabled ? onSetPrimary : null,
                      child: Text(
                        l10n.profileSetupSetAsProfilePicture,
                        style: TextStyle(
                          color: scheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      l10n.profileSetupProfilePictureSelected,
                      style: TextStyle(
                        color: scheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          QaId(
            'qa.setup.photos.delete_${photo.id}',
            child: IconButton(
              key: ValueKey<String>('qa.setup.photos.delete_${photo.id}'),
              icon: Icon(Icons.delete_outline, color: scheme.error),
              onPressed: enabled ? onDelete : null,
              tooltip: l10n.profileSetupRemovePhotoTooltip,
            ),
          ),
          QaId(
            'qa.setup.photos.reorder_${photo.id}',
            label: l10n.profileSetupReorderPhoto,
            child: IgnorePointer(
              ignoring: !enabled,
              child: ReorderableDragStartListener(
                key: ValueKey<String>('qa.setup.photos.reorder_${photo.id}'),
                index: index,
                child: Padding(
                  padding: const EdgeInsets.only(right: 4, left: 4),
                  child: Icon(
                    Icons.drag_handle,
                    color: scheme.onSurfaceVariant.withValues(
                      alpha: enabled ? 1.0 : 0.4,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
