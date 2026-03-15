import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_widgets.dart';
import '../../providers/profile_setup_provider.dart';
import 'setup_about_screen.dart';

class SetupPhotosScreen extends ConsumerWidget {
  const SetupPhotosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draftAsync = ref.watch(profileSetupNotifierProvider);

    return draftAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => ref.invalidate(profileSetupNotifierProvider),
            child: const Text('Retry'),
          ),
        ),
      ),
      data: (draft) => Scaffold(
        appBar: AppBar(title: const Text('Photos')),
        body: Container(
          decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppTheme.contentMaxWidth,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GlassContainer(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.white.withValues(alpha: 0.95),
                    blur: 10,
                    borderRadius: const BorderRadius.all(Radius.circular(24)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Add at least ${ValidationConstants.minPhotos} photos',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.trustBlue.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${draft.photos.length}/${ValidationConstants.maxPhotos}',
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: AppTheme.textDark,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Drag to reorder. Your first photo becomes primary.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.textGrey),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: draft.photos.isEmpty
                              ? Center(
                                  child: Text(
                                    'No photos yet. Add from gallery or camera.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(color: AppTheme.textGrey),
                                  ),
                                )
                              : ReorderableListView.builder(
                                  itemCount: draft.photos.length,
                                  buildDefaultDragHandles: false,
                                  onReorder: (oldIndex, newIndex) => ref
                                      .read(
                                        profileSetupNotifierProvider.notifier,
                                      )
                                      .reorderPhotos(oldIndex, newIndex),
                                  itemBuilder: (context, index) {
                                    final photo = draft.photos[index];
                                    return Container(
                                      key: ValueKey(photo.id),
                                      margin: const EdgeInsets.only(bottom: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.86,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: AppTheme.trustBlue.withValues(
                                            alpha: 0.14,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Image.network(
                                                photo.photoUrl,
                                                width: 72,
                                                height: 72,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  index == 0
                                                      ? 'Primary photo'
                                                      : 'Photo ${index + 1}',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleSmall
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  index == 0
                                                      ? 'Shown first on your profile'
                                                      : 'Drag up to set as primary',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color:
                                                            AppTheme.textGrey,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete),
                                            onPressed: () => ref
                                                .read(
                                                  profileSetupNotifierProvider
                                                      .notifier,
                                                )
                                                .deletePhoto(photo),
                                          ),
                                          ReorderableDragStartListener(
                                            index: index,
                                            child: const Padding(
                                              padding: EdgeInsets.only(
                                                right: 10,
                                                left: 2,
                                              ),
                                              child: Icon(
                                                Icons.drag_handle,
                                                color: AppTheme.textGrey,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => ref
                                    .read(profileSetupNotifierProvider.notifier)
                                    .addPhotoFromGallery(),
                                icon: const Icon(Icons.photo_library),
                                label: const Text('Gallery'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => ref
                                    .read(profileSetupNotifierProvider.notifier)
                                    .addPhotoFromCamera(),
                                icon: const Icon(Icons.photo_camera),
                                label: const Text('Camera'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        GlassButton(
                          label: 'Next',
                          shinyEffect: true,
                          onPressed: () {
                            if (draft.photos.length <
                                ValidationConstants.minPhotos) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please add at least ${ValidationConstants.minPhotos} photos.',
                                  ),
                                ),
                              );
                              return;
                            }
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const SetupAboutScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
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
