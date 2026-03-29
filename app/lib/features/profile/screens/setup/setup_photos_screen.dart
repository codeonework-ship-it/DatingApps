import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_widgets.dart';
import '../../providers/profile_setup_provider.dart';
import 'setup_preferences_screen.dart';

class SetupPhotosScreen extends ConsumerWidget {
  const SetupPhotosScreen({super.key});

  void _navigateNext(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const SetupPreferencesScreen(isSetupFlow: true),
      ),
    );
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
      error: (_, __) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => ref.invalidate(profileSetupNotifierProvider),
            child: const Text('Retry'),
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 16, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Add your photos',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                            Text(
                              'Step 2 of 3  ·  Optional — add more later',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _CountBadge(
                        current: draft.photos.length,
                        max: ValidationConstants.maxPhotos,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Step progress bar ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _StepBar(step: 2, total: 3),
                ),

                const SizedBox(height: 16),

                // ── Scrollable content ──────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Pick source ───────────────────────────────
                        _PhotoCard(
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

                        // ── Tip banner ────────────────────────────────
                        const SizedBox(height: 14),
                        _TipBanner(
                          text: draft.photos.isEmpty
                              ? 'Profiles with at least ${ValidationConstants.minPhotos} photos get 3× more matches.'
                              : draft.photos.length <
                                    ValidationConstants.minPhotos
                              ? 'Add ${ValidationConstants.minPhotos - draft.photos.length} more photo(s) to unlock full matching.'
                              : 'Great! You can reorder photos by dragging.',
                        ),

                        // ── Photo list ────────────────────────────────
                        if (draft.photos.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _PhotoCard(
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
                                    .read(profileSetupNotifierProvider.notifier)
                                    .reorderPhotos(oldIndex, newIndex),
                                itemBuilder: (context, index) {
                                  final photo = draft.photos[index];
                                  return _PhotoRow(
                                    key: ValueKey(photo.id),
                                    photo: photo,
                                    index: index,
                                    onDelete: () => ref
                                        .read(
                                          profileSetupNotifierProvider.notifier,
                                        )
                                        .deletePhoto(photo),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // ── Next button ───────────────────────────────
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Helper widgets ───────────────────────────────────────────────────────────

/// Frosted‑glass card — mirrors _PrefCard in preferences screen.
class _PhotoCard extends StatelessWidget {
  const _PhotoCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        border: Border.all(
          color: AppTheme.crystalGoldSoft.withValues(alpha: 0.25),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.crystalGoldSoft, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.crystalGoldSoft,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _StepBar extends StatelessWidget {
  const _StepBar({required this.step, required this.total});
  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total * 2 - 1, (i) {
        if (i.isOdd) return const SizedBox(width: 6);
        final idx = i ~/ 2 + 1;
        final active = idx <= step;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: active
                  ? AppTheme.crystalGoldSoft
                  : Colors.white.withValues(alpha: 0.2),
            ),
          ),
        );
      }),
    );
  }
}

class _TipBanner extends StatelessWidget {
  const _TipBanner({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.crystalGoldSoft.withValues(alpha: 0.12),
        border: Border.all(
          color: AppTheme.crystalGoldSoft.withValues(alpha: 0.30),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 16,
            color: AppTheme.crystalGoldSoft,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.current, required this.max});
  final int current;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.crystalGoldSoft.withValues(alpha: 0.18),
        border: Border.all(
          color: AppTheme.crystalGoldSoft.withValues(alpha: 0.4),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$current / $max',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}

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
                child: Icon(
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
