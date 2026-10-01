import 'package:flutter/foundation.dart';
import '../../../../core/platform/browser_context.dart';
import '../../../../core/platform/platform_photo.dart';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/layout/app_layout.dart';
import '../../../../core/widgets/glass_widgets.dart';
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Photos saved.')));
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

  Future<void> _pickFromGallery() async {
    if (_isPickingPhoto) {
      return;
    }
    final draft = ref.read(profileSetupNotifierProvider).valueOrNull;
    if (draft != null && draft.photos.length >= ValidationConstants.maxPhotos) {
      _showError(
        'You can upload up to ${ValidationConstants.maxPhotos} photos only.',
      );
      return;
    }
    setState(() => _isPickingPhoto = true);
    try {
      await ref
          .read(profileSetupNotifierProvider.notifier)
          .addPhotoFromGallery();
    } on Object catch (error) {
      _showError(profileMediaErrorMessage(error));
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
        'You can upload up to ${ValidationConstants.maxPhotos} photos only.',
      );
      return;
    }
    setState(() => _isPickingPhoto = true);
    try {
      await ref
          .read(profileSetupNotifierProvider.notifier)
          .addPhotoFromCamera();
    } on Object catch (error) {
      _showError(profileMediaErrorMessage(error));
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove this photo?'),
        content: const Text(
          'It will be removed from your profile and deleted from storage.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('qa.setup.photos.confirm_delete'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    try {
      await ref.read(profileSetupNotifierProvider.notifier).deletePhoto(photo);
    } on Object catch (error) {
      _showError(profileMediaErrorMessage(error));
    }
  }

  Future<void> _reorderPhotos(int oldIndex, int newIndex) async {
    if (_isPickingPhoto || oldIndex == newIndex) {
      return;
    }
    try {
      await ref
          .read(profileSetupNotifierProvider.notifier)
          .reorderPhotos(oldIndex, newIndex);
    } on Object catch (error) {
      _showError(profileMediaErrorMessage(error));
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
                        message: e.toString(),
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
                            content: const Text(
                              'Please upload at least '
                              '${ValidationConstants.minPhotos} photos '
                              'to continue.',
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
  Widget build(BuildContext context) => ListView(
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
                  'Add your photos',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Add at least ${ValidationConstants.minPhotos} photos '
                  'to get matches',
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
        title: 'Choose source',
        child: Row(
          children: [
            Expanded(
              child: _PickerButton(
                icon: Icons.photo_library_rounded,
                label: 'Gallery',
                isLoading: isPickingPhoto,
                onTap: onPickGallery,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PickerButton(
                icon: Icons.photo_camera_rounded,
                label: 'Camera',
                isLoading: isPickingPhoto,
                onTap: onPickCamera,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'JPEG, PNG, WebP or HEIC · 300×300 minimum · 10 MB each · 50 MB total',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),

      // ── Tip banner ───────────────────────────────────────
      const SizedBox(height: 14),
      TipBanner(
        text: draft.photos.isEmpty
            ? 'Add at least ${ValidationConstants.minPhotos} photos '
                  'to show different sides of you.'
            : draft.photos.length < ValidationConstants.minPhotos
            ? 'Add ${ValidationConstants.minPhotos - draft.photos.length}'
                  ' more photo(s) to unlock full matching.'
            : 'Great! You can reorder photos by dragging.',
      ),

      // ── Photo grid ───────────────────────────────────────
      if (draft.photos.isNotEmpty) ...[
        const SizedBox(height: 14),
        InfoCard(
          icon: Icons.collections_outlined,
          title: 'Your photos  •  drag to reorder',
          child: SizedBox(
            height: (draft.photos.length * 92.0).clamp(92.0, 368.0),
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
        ),
      ],

      const SizedBox(height: 24),

      // ── Next button ──────────────────────────────────────
      Semantics(
        label: 'qa.setup.photos.next_button',
        button: true,
        child: SizedBox(
          height: 54,
          width: double.infinity,
          child: GlassButton(
            key: const ValueKey('qa.setup.photos.next_button'),
            label: isSetupFlow ? 'Continue to About' : 'Save Photos',
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

// ── Helper widgets ───────────────────────────────────────────────────────────

class _PickerButton extends StatelessWidget {
  const _PickerButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'qa.setup.photos.${label.toLowerCase()}_button',
    button: true,
    child: SizedBox(
      height: 58,
      child: GlassButton(
        key: ValueKey<String>('qa.setup.photos.${label.toLowerCase()}_button'),
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
                  index == 0 ? 'Primary photo' : 'Photo ${index + 1}',
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  index == 0
                      ? 'Shown first on your profile'
                      : 'Drag handle to reorder',
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
                                ? 'Awaiting safety review'
                                : 'Safety check in progress',
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
                      onTap: enabled ? onSetPrimary : null,
                      child: Text(
                        'Set as profile picture',
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
                      'Profile picture selected',
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
          Semantics(
            label: 'qa.setup.photos.delete_${photo.id}',
            button: true,
            child: IconButton(
              key: ValueKey<String>('qa.setup.photos.delete_${photo.id}'),
              icon: Icon(Icons.delete_outline, color: scheme.error),
              onPressed: enabled ? onDelete : null,
              tooltip: 'Remove photo',
            ),
          ),
          Semantics(
            label: 'qa.setup.photos.reorder_${photo.id}',
            button: true,
            child: IgnorePointer(
              ignoring: !enabled,
              child: ReorderableDragStartListener(
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
