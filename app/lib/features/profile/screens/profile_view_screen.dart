import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../../core/extensions/date_time_extensions.dart';
import 'profile_viewers_screen.dart';
import '../providers/profile_provider.dart';

class ProfileViewScreen extends ConsumerWidget {
  const ProfileViewScreen({super.key});

  static const double _pagePadding = 16;
  static const double _sectionSpacing = 20;
  static const double _statCardGap = 12;
  static const double _statCardHeight = 132;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileNotifierProvider);
    final bottomClearance = MediaQuery.of(context).padding.bottom + 104;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textDark,
        actions: [
          IconButton(
            tooltip: 'Who viewed my profile',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ProfileViewersScreen(),
                ),
              );
            },
            icon: const Icon(Icons.remove_red_eye_outlined),
          ),
          IconButton(
            onPressed: () =>
                ref.read(profileNotifierProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: PostLoginBackdrop(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            _pagePadding,
            _pagePadding,
            _pagePadding,
            bottomClearance,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (profileState.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (profileState.error != null)
                GlassContainer(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.white.withValues(alpha: 0.84),
                  blur: 14,
                  crystalEffect: true,
                  child: Text(
                    profileState.error!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppTheme.errorRed),
                  ),
                )
              else if (profileState.user == null)
                GlassContainer(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.white.withValues(alpha: 0.84),
                  blur: 14,
                  crystalEffect: true,
                  child: const Text('No profile data found.'),
                )
              else
                GlassContainer(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.white.withValues(alpha: 0.84),
                  blur: 14,
                  crystalEffect: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About You',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      _buildProfileRow(
                        context,
                        'Age',
                        '${profileState.user!.dateOfBirth.age}',
                      ),
                      const SizedBox(height: 12),
                      _buildProfileRow(
                        context,
                        'Gender',
                        profileState.user!.gender,
                      ),
                      const SizedBox(height: 12),
                      _buildProfileRow(
                        context,
                        'Profession',
                        profileState.user!.profession ?? '—',
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: _sectionSpacing),
              if (!profileState.isLoading && profileState.user != null)
                GlassContainer(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.white.withValues(alpha: 0.84),
                  blur: 14,
                  crystalEffect: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Preferences',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      _buildProfileRow(
                        context,
                        'Seeking',
                        profileState.preferences == null
                            ? '—'
                            : profileState.preferences!.seekingGenders.join(
                                ', ',
                              ),
                      ),
                      const SizedBox(height: 12),
                      _buildProfileRow(
                        context,
                        'Age Range',
                        profileState.preferences == null
                            ? '—'
                            : '${profileState.preferences!.minAgeYears}-${profileState.preferences!.maxAgeYears}',
                      ),
                      const SizedBox(height: 12),
                      _buildProfileRow(
                        context,
                        'Distance',
                        profileState.preferences == null
                            ? '—'
                            : 'Within ${profileState.preferences!.maxDistanceKm} km',
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: _sectionSpacing),
              GlassButton(
                label: 'Who Viewed My Profile',
                icon: Icons.remove_red_eye_outlined,
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ProfileViewersScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SizedBox(
                      height: _statCardHeight,
                      child: _buildStatCard(
                        context,
                        icon: Icons.favorite,
                        value: '${profileState.likesCount}',
                        label: 'Likes',
                      ),
                    ),
                  ),
                  const SizedBox(width: _statCardGap),
                  Expanded(
                    child: SizedBox(
                      height: _statCardHeight,
                      child: _buildStatCard(
                        context,
                        icon: Icons.done,
                        value: '${profileState.matchesCount}',
                        label: 'Matches',
                      ),
                    ),
                  ),
                  const SizedBox(width: _statCardGap),
                  Expanded(
                    child: SizedBox(
                      height: _statCardHeight,
                      child: _buildStatCard(
                        context,
                        icon: Icons.message,
                        value: '${profileState.messagesCount}',
                        label: 'Messages',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileRow(BuildContext context, String label, String value) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryRed,
            ),
          ),
        ],
      );

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
  }) => GlassContainer(
    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
    backgroundColor: Colors.white.withValues(alpha: 0.84),
    blur: 14,
    crystalEffect: true,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.primaryRed, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppTheme.primaryRed),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textGrey),
          ),
        ],
      ),
    ),
  );
}
