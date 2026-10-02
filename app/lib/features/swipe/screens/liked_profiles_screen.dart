import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/glass_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/swipe_provider.dart';
import 'profile_details_screen.dart';

class LikedProfilesScreen extends ConsumerWidget {
  const LikedProfilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final state = ref.watch(swipeNotifierProvider);
    final likedProfiles = state.likedProfiles;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.discoverLikedProfilesTitle(likedProfiles.length)),
      ),
      body: ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          child: likedProfiles.isEmpty
              ? Center(
                  child: Text(
                    l10n.discoverNoLikedProfiles,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: likedProfiles.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final profile = likedProfiles[index];
                    final photoUrl = profile.photoUrls.isNotEmpty
                        ? profile.photoUrls.first
                        : '';

                    return GlassContainer(
                      padding: const EdgeInsets.all(12),
                      backgroundColor: scheme.surface,
                      border: Border.all(color: scheme.outlineVariant),
                      blur: 10,
                      borderRadius: BorderRadius.circular(16),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: photoUrl.isEmpty
                                ? Container(
                                    width: 60,
                                    height: 60,
                                    color: scheme.surfaceContainerHighest,
                                    child: Icon(
                                      Icons.person,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  )
                                : Image.network(
                                    photoUrl,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      width: 60,
                                      height: 60,
                                      color: scheme.surfaceContainerHighest,
                                      child: Icon(
                                        Icons.person,
                                        color: scheme.onSurfaceVariant,
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
                                  profile.displayName,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  profile.subtitle.trim().isEmpty
                                      ? l10n.discoverLikedProfileFallback
                                      : profile.subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            key: ValueKey(
                              'qa.liked_profiles.open.${profile.id}',
                            ),
                            icon: const Icon(Icons.chevron_right),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      ProfileDetailsScreen(profile: profile),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
