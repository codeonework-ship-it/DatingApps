import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_widgets.dart';
import '../../providers/profile_completion_provider.dart';
import '../../providers/profile_setup_provider.dart';

class SetupPreviewScreen extends ConsumerStatefulWidget {
  const SetupPreviewScreen({super.key});

  @override
  ConsumerState<SetupPreviewScreen> createState() => _SetupPreviewScreenState();
}

class _SetupPreviewScreenState extends ConsumerState<SetupPreviewScreen> {
  final PageController _photoPageController = PageController();
  int _selectedPhotoIndex = 0;

  @override
  void dispose() {
    _photoPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      data: (draft) {
        final photoUrls = draft.photos
            .map((photo) => photo.photoUrl.trim())
            .where((url) => url.isNotEmpty)
            .toList();
        if (_selectedPhotoIndex >= photoUrls.length) {
          _selectedPhotoIndex = 0;
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Preview')),
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
                      child: LayoutBuilder(
                        builder: (context, constraints) => SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Profile completeness: ${draft.profileCompletionPercent}%',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 12),
                                if (photoUrls.isNotEmpty)
                                  Column(
                                    children: [
                                      SizedBox(
                                        height: 220,
                                        child: PageView.builder(
                                          controller: _photoPageController,
                                          onPageChanged: (index) {
                                            if (!mounted) {
                                              return;
                                            }
                                            setState(
                                              () => _selectedPhotoIndex = index,
                                            );
                                          },
                                          itemCount: photoUrls.length,
                                          itemBuilder: (context, index) =>
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                child: Image.network(
                                                  photoUrls[index],
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                        ),
                                      ),
                                      if (photoUrls.length > 1) ...[
                                        const SizedBox(height: 10),
                                        SizedBox(
                                          height: 70,
                                          child: ListView.separated(
                                            scrollDirection: Axis.horizontal,
                                            itemCount: photoUrls.length,
                                            separatorBuilder: (_, _) =>
                                                const SizedBox(width: 10),
                                            itemBuilder: (context, index) {
                                              final selected =
                                                  _selectedPhotoIndex == index;
                                              return GestureDetector(
                                                onTap: () {
                                                  _photoPageController
                                                      .animateToPage(
                                                        index,
                                                        duration:
                                                            const Duration(
                                                              milliseconds: 220,
                                                            ),
                                                        curve: Curves.easeOut,
                                                      );
                                                  setState(
                                                    () => _selectedPhotoIndex =
                                                        index,
                                                  );
                                                },
                                                child: AnimatedContainer(
                                                  duration: const Duration(
                                                    milliseconds: 180,
                                                  ),
                                                  width: 60,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                    border: Border.all(
                                                      color: selected
                                                          ? AppTheme.primaryRed
                                                          : Colors.transparent,
                                                      width: 2,
                                                    ),
                                                  ),
                                                  clipBehavior: Clip.antiAlias,
                                                  child: Image.network(
                                                    photoUrls[index],
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                const SizedBox(height: 12),
                                Text(
                                  draft.name,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  draft.bio,
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 12),
                                _row('Gender', draft.gender),
                                _row('Drinking', draft.drinking),
                                _row('Smoking', draft.smoking),
                                _row('Religion', draft.religion ?? '—'),
                                const SizedBox(height: 16),
                                GlassButton(
                                  label: 'Complete',
                                  shinyEffect: true,
                                  onPressed: () async {
                                    try {
                                      await ref
                                          .read(
                                            profileSetupNotifierProvider
                                                .notifier,
                                          )
                                          .completeProfile();
                                      ref.invalidate(profileCompletionProvider);

                                      if (!context.mounted) return;
                                      Navigator.of(
                                        context,
                                      ).popUntil((r) => r.isFirst);
                                    } catch (_) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Please complete all required fields (min ${ValidationConstants.minPhotos} photos, bio, and basic info).',
                                          ),
                                        ),
                                      );
                                    }
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
            ),
          ),
        );
      },
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}
