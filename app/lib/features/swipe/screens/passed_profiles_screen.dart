import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../providers/swipe_provider.dart';
import 'profile_details_screen.dart';

class PassedProfilesScreen extends ConsumerWidget {
  const PassedProfilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(swipeNotifierProvider);
    final passedProfiles = state.passedProfiles;

    return Scaffold(
      appBar: AppBar(title: const Text('Passed Profiles')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: passedProfiles.isEmpty
              ? const Center(
                  child: Text(
                    'No passed profiles yet',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: passedProfiles.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final profile = passedProfiles[index];
                    final photoUrl = profile.photoUrls.isNotEmpty
                        ? profile.photoUrls.first
                        : '';

                    return GlassContainer(
                      padding: const EdgeInsets.all(12),
                      backgroundColor: Colors.white.withValues(alpha: 0.9),
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
                                    color: Colors.grey.shade300,
                                    child: const Icon(Icons.person),
                                  )
                                : Image.network(
                                    photoUrl,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey.shade300,
                                      child: const Icon(Icons.person),
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${profile.name}, ${profile.age}',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  profile.subtitle.trim().isEmpty
                                      ? 'Saved for later'
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
