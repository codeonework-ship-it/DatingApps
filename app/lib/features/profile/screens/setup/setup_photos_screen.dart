import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_widgets.dart';
import '../../providers/profile_setup_provider.dart';
import 'setup_about_screen.dart';
import 'setup_shared_widgets.dart';

/// Step 2 of 4 — photo gallery / camera picker with reorderable list.
///
/// Photos are uploaded to Supabase Storage then registered on the Go BFF via
/// [ProfileSetupNotifier.addPhotoFromGallery] / `addPhotoFromCamera`.
class SetupPhotosScreen extends ConsumerWidget {
  const SetupPhotosScreen({super.key});

  void _navigateNext(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const SetupAboutScreen()));
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSkipConfirm(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF3A2800),
        title: const Text(
          'Skip photos?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'You can add photos later from your profile. '
          'Profiles with photos get significantly more matches.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Add photos now',
              style: TextStyle(color: AppTheme.crystalGoldSoft),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.crystalGoldDeep,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _navigateNext(context);
            },
            child: const Text('Skip for now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draftAsync = ref.watch(profileSetupNotifierProvider);

    return draftAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        body: Center(
          child: SetupErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(profileSetupNotifierProvider),
          ),
        ),
      ),
      data: (draft) => Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
          child: SafeArea(
            child: Column(
              children: [
                // ── Header ─────────────────────────────────────────────
                SetupHeader(
                  currentStep: 2,
                  totalSteps: 4,
                  onBack: () => Navigator.of(context).pop(),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add your photos',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.3,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Optional — add more later',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.60),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      CountBadge(
                        current: draft.photos.length,
                        max: ValidationConstants.maxPhotos,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Scrollable content ──────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AppTheme.contentMaxWidth,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── Pick source ───────────────────────────
                            InfoCard(
                              icon: Icons.add_a_photo_outlined,
                              title: 'Choose source',
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _PickerButton(
                                      icon: Icons.photo_library_rounded,
                                      label: 'Gallery',
                                      onTap: () async {
                                        try {
                                          await ref
                                              .read(
                                                profileSetupNotifierProvider
                                                    .notifier,
                                              )
                                              .addPhotoFromGallery();
                                        } catch (e) {
                                          if (context.mounted) {
                                            _showError(context, e.toString());
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _PickerButton(
                                      icon: Icons.photo_camera_rounded,
                                      label: 'Camera',
                                      onTap: () async {
                                        try {
                                          await ref
                                              .read(
                                                profileSetupNotifierProvider
                                                    .notifier,
                                              )
                                              .addPhotoFromCamera();
                                        } catch (e) {
                                          if (context.mounted) {
                                            _showError(context, e.toString());
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // ── Tip banner ────────────────────────────
                            const SizedBox(height: 14),
                            TipBanner(
                              text: draft.photos.isEmpty
                                  ? 'Profiles with at least ${ValidationConstants.minPhotos} photos get 3× more matches.'
                                  : draft.photos.length <
                                        ValidationConstants.minPhotos
                                  ? 'Add ${ValidationConstants.minPhotos - draft.photos.length} more photo(s) to unlock full matching.'
                                  : 'Great! You can reorder photos by dragging.',
                            ),

                            // ── Photo list ────────────────────────────
                            if (draft.photos.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              InfoCard(
                                icon: Icons.collections_outlined,
                                title: 'Your photos  •  drag to reorder',
                                child: SizedBox(
                                  height: (draft.photos.length * 92.0).clamp(
                                    92,
                                    368,
                                  ),
                                  child: ReorderableListView.builder(
                                    buildDefaultDragHandles: false,
                                    itemCount: draft.photos.length,
                                    onReorder: (oldIndex, newIndex) => ref
                                        .read(
                                          profileSetupNotifierProvider.notifier,
                                        )
                                        .reorderPhotos(oldIndex, newIndex),
                                    itemBuilder: (context, index) {
                                      final photo = draft.photos[index];
                                      return _PhotoRow(
                                        key: ValueKey(photo.id),
                                        photo: photo,
                                        index: index,
                                        onDelete: () => ref
                                            .read(
                                              profileSetupNotifierProvider
                                                  .notifier,
                                            )
                                            .deletePhoto(photo),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 24),

                            // ── Next button ───────────────────────────
                            GlassButton(
                              label: 'Next  →',
                              shinyEffect: true,
                              onPressed: () {
                                if (draft.photos.length <
                                    ValidationConstants.minPhotos) {
                                  _showSkipConfirm(context);
                                  return;
                                }
                                _navigateNext(context);
                              },
                            ),

                            const SizedBox(height: 10),
                            Center(
                              child: TextButton(
                                onPressed: () => _showSkipConfirm(context),
                                child: Text(
                                  'Skip for now — add photos later',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.55),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
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

// ── Helper widgets ───────────────────────────────────────────────────────────

class _PickerButton extends StatelessWidget {
  const _PickerButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          border: Border.all(
            color: AppTheme.crystalGoldSoft.withValues(alpha: 0.35),
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: AppTheme.crystalGoldSoft),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoRow extends StatelessWidget {
  const _PhotoRow({
    required this.photo,
    required this.index,
    required this.onDelete,
    super.key,
  });
  final ProfilePhotoItem photo;
  final int index;
  final VoidCallback onDelete;

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
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              photo.photoUrl,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
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
              ),
            ),
          ),
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
