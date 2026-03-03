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
                        Text(
                          'Add at least ${ValidationConstants.minPhotos} photos',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ReorderableListView.builder(
                            itemCount: draft.photos.length,
                            onReorder: (oldIndex, newIndex) => ref
                                .read(profileSetupNotifierProvider.notifier)
                                .reorderPhotos(oldIndex, newIndex),
                            itemBuilder: (context, index) {
                              final photo = draft.photos[index];
                              return ListTile(
                                key: ValueKey(photo.id),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    photo.photoUrl,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                title: Text(
                                  index == 0
                                      ? 'Primary photo'
                                      : 'Photo ${index + 1}',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => ref
                                      .read(
                                        profileSetupNotifierProvider.notifier,
                                      )
                                      .deletePhoto(photo),
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
                          onPressed: () {
                            if (draft.photos.length <
                                ValidationConstants.minPhotos) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
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
