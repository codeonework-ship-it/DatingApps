import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
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
  const SetupPhotosScreen({super.key});

  @override
  ConsumerState<SetupPhotosScreen> createState() => _SetupPhotosScreenState();
}

class _SetupPhotosScreenState extends ConsumerState<SetupPhotosScreen> {
  bool _isPickingPhoto = false;

  // ── Navigation helpers ──────────────────────────────────────────────────
  void _navigateNext() {
    if (!mounted) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => const SetupAboutScreen()),
      );
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    if (_isPickingPhoto) return;
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
    } catch (e) {
      _showError('Photo upload failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isPickingPhoto = false);
    }
  }

  Future<void> _pickFromCamera() async {
    if (_isPickingPhoto) return;
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
    } catch (e) {
      _showError('Photo upload failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isPickingPhoto = false);
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
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              SetupHeader(
                currentStep: 2,
                totalSteps: 4,
                onBack: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: draftAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.crystalGoldSoft,
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
                    isPickingPhoto: _isPickingPhoto,
                    onPickGallery: _pickFromGallery,
                    onPickCamera: _pickFromCamera,
                    onDeletePhoto: (photo) => ref
                        .read(profileSetupNotifierProvider.notifier)
                        .deletePhoto(photo),
                    onReorder: (oldIndex, newIndex) => ref
                        .read(profileSetupNotifierProvider.notifier)
                        .reorderPhotos(oldIndex, newIndex),
                    onSetPrimary: (int index) {
                      if (index == 0) {
                        return;
                      }
                      ref
                          .read(profileSetupNotifierProvider.notifier)
                          .reorderPhotos(index, 0);
                    },
                    onNext: () {
                      if (d.photos.length < ValidationConstants.minPhotos) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Please upload at least ${ValidationConstants.minPhotos} photos to continue.',
                            ),
                            backgroundColor: AppTheme.errorRed,
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
  final bool isPickingPhoto;
  final VoidCallback onPickGallery;
  final VoidCallback onPickCamera;
  final void Function(ProfilePhotoItem) onDeletePhoto;
  final void Function(int, int) onReorder;
  final void Function(int index) onSetPrimary;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
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
                    'Add your photos',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add at least ${ValidationConstants.minPhotos} photos to get matches',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.60),
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

        // ── Tip banner ───────────────────────────────────────
        const SizedBox(height: 14),
        TipBanner(
          text: draft.photos.isEmpty
              ? 'Profiles with at least ${ValidationConstants.minPhotos} '
                    'photos get 3× more matches.'
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
                onReorder: onReorder,
                itemBuilder: (context, index) {
                  final photo = draft.photos[index];
                  return _PhotoRow(
                    key: ValueKey(photo.id),
                    photo: photo,
                    index: index,
                    onDelete: () => onDeletePhoto(photo),
                    onSetPrimary: () => onSetPrimary(index),
                  );
                },
              ),
            ),
          ),
        ],

        const SizedBox(height: 24),

        // ── Next button ──────────────────────────────────────
        SizedBox(
          height: 54,
          width: double.infinity,
          child: GlassButton(
            label: 'Next',
            icon: Icons.arrow_forward_rounded,
            shinyEffect: true,
            textColor: AppTheme.textDark,
            fontWeight: FontWeight.w800,
            onPressed: onNext,
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
    required this.onTap,
    this.isLoading = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: GlassButton(
        label: label,
        icon: icon,
        isLoading: isLoading,
        textColor: AppTheme.textDark,
        fontWeight: FontWeight.w800,
        onPressed: isLoading ? null : onTap,
      ),
    );
  }
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
    super.key,
  });
  final ProfilePhotoItem photo;
  final int index;
  final VoidCallback onDelete;
  final VoidCallback onSetPrimary;

  Widget _buildThumbnail() {
    final url = photo.photoUrl;
    // Local file path (optimistic entry during upload)
    if (url.startsWith('/')) {
      final file = File(url);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            file,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _brokenImage(),
          ),
        );
      }
      return _brokenImage();
    }
    // Network URL (from BFF /v1/media/...)
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        url,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _brokenImage(),
      ),
    );
  }

  Widget _brokenImage() => Container(
    width: 60,
    height: 60,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Icon(
      Icons.broken_image_outlined,
      size: 28,
      color: Colors.white38,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(
          color: AppTheme.crystalGoldSoft.withValues(alpha: 0.20),
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _buildThumbnail(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  index == 0 ? 'Primary photo' : 'Photo ${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  index == 0
                      ? 'Shown first on your profile'
                      : 'Drag handle to reorder',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
                if (index != 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: GestureDetector(
                      onTap: onSetPrimary,
                      child: Text(
                        'Set as profile picture',
                        style: TextStyle(
                          color: AppTheme.crystalGoldSoft.withValues(
                            alpha: 0.95,
                          ),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Profile picture selected',
                      style: TextStyle(
                        color: AppTheme.crystalGoldSoft.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: onDelete,
            tooltip: 'Remove photo',
          ),
          ReorderableDragStartListener(
            index: index,
            child: Padding(
              padding: const EdgeInsets.only(right: 4, left: 2),
              child: Icon(
                Icons.drag_handle,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
