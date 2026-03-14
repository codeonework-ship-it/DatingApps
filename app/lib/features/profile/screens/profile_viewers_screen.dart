import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../providers/profile_viewers_provider.dart';

class ProfileViewersScreen extends ConsumerWidget {
  const ProfileViewersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewersAsync = ref.watch(profileViewersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Viewed My Profile'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textDark,
      ),
      body: PostLoginBackdrop(
        child: viewersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Failed to load profile viewers.'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(profileViewersProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (viewers) {
            if (viewers.isEmpty) {
              return const Center(
                child: GlassContainer(
                  padding: EdgeInsets.all(16),
                  child: Text('No one has viewed your profile yet.'),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              itemCount: viewers.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = viewers[index];
                final subtitle = item.viewedAt.trim().isEmpty
                    ? 'Viewed recently'
                    : 'Viewed at ${item.viewedAt}';

                return GlassContainer(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppTheme.primaryRed.withValues(
                          alpha: 0.15,
                        ),
                        backgroundImage: item.photoUrl.isNotEmpty
                            ? NetworkImage(item.photoUrl)
                            : null,
                        child: item.photoUrl.isEmpty
                            ? const Icon(
                                Icons.person,
                                color: AppTheme.primaryRed,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name.isEmpty ? item.userId : item.name,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppTheme.textGrey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
