import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/date_time_extensions.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/connect_page.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../common/screens/main_navigation_screen.dart';
import '../../matching/screens/matches_list_screen.dart';
import '../../swipe/providers/liked_me_provider.dart';
import '../../swipe/screens/liked_me_screen.dart';
import '../../swipe/screens/liked_profiles_screen.dart';
import '../providers/profile_provider.dart';
import 'profile_viewers_screen.dart';

class ProfileViewScreen extends ConsumerWidget {
  const ProfileViewScreen({super.key});

  static const double _statCardGap = 12;
  static const double _statCardHeight = 132;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileNotifierProvider);
    final likedMeCount = ref.watch(likedMeProvider.select((s) => s.count));
    final bottomClearance = MediaQuery.of(context).padding.bottom + 104;

    final colors = Theme.of(context).colorScheme;
    final user = profileState.user;
    final prefs = profileState.preferences;
    Future<void> openViewers() => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ProfileViewersScreen()),
    );

    Widget statusCard({
      required IconData icon,
      required String message,
      Widget? action,
    }) => ConnectPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: colors.onSurfaceVariant, size: 40),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
          if (action != null) ...[const SizedBox(height: 16), action],
        ],
      ),
    );

    return Scaffold(
      body: PostLoginBackdrop(
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, box) {
              final gutter = ConnectMetrics.gutterFor(box.maxWidth);
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  gutter,
                  12,
                  gutter,
                  bottomClearance,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ConnectPageHeader(
                      eyebrow: 'YOUR PROFILE',
                      title: 'My Profile',
                      subtitle: 'How you show up, and who has noticed.',
                      actions: [
                        IconButton(
                          tooltip: 'Who viewed my profile',
                          onPressed: openViewers,
                          icon: const Icon(Icons.remove_red_eye_outlined),
                        ),
                        IconButton(
                          tooltip: 'Refresh profile',
                          onPressed: () => ref
                              .read(profileNotifierProvider.notifier)
                              .refresh(),
                          icon: const Icon(Icons.refresh_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: ConnectMetrics.sectionGap),
                    const ConnectSectionHeader(
                      label: 'YOUR CONNECTIONS',
                      caption: 'People you liked, matched and talk to.',
                    ),
                    const SizedBox(height: ConnectMetrics.cardGap),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: _statCardHeight,
                            child: _buildStatCard(
                              context,
                              icon: Icons.favorite_rounded,
                              tint: colors.secondary,
                              value: '${profileState.likesCount}',
                              label: 'You liked',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const LikedProfilesScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: _statCardGap),
                        Expanded(
                          child: SizedBox(
                            height: _statCardHeight,
                            child: _buildStatCard(
                              context,
                              icon: Icons.done_rounded,
                              tint: colors.primary,
                              value: '${profileState.matchesCount}',
                              label: 'Matches',
                              onTap: () =>
                                  _openMatchesTab(ref, MatchesView.people),
                            ),
                          ),
                        ),
                        const SizedBox(width: _statCardGap),
                        Expanded(
                          child: SizedBox(
                            height: _statCardHeight,
                            child: _buildStatCard(
                              context,
                              icon: Icons.chat_bubble_outline_rounded,
                              tint: colors.tertiary,
                              value: '${profileState.messagesCount}',
                              label: 'Messages',
                              onTap: () => _openMatchesTab(
                                ref,
                                MatchesView.conversations,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: ConnectMetrics.sectionGap),
                    const ConnectSectionHeader(
                      label: 'WHO HAS NOTICED',
                      caption: 'Likes and views from members near you.',
                    ),
                    const SizedBox(height: ConnectMetrics.cardGap),
                    ConnectNavTile(
                      key: const ValueKey('qa.profile.who_liked_me'),
                      icon: Icons.favorite_border_rounded,
                      tint: colors.secondary,
                      title: likedMeCount > 0
                          ? 'Who Liked Me ($likedMeCount)'
                          : 'Who Liked Me',
                      subtitle: 'Members who liked your profile.',
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const LikedMeScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: ConnectMetrics.cardGap),
                    ConnectNavTile(
                      icon: Icons.remove_red_eye_outlined,
                      title: 'Who Viewed My Profile',
                      subtitle: 'Recent visits to your profile.',
                      onTap: openViewers,
                    ),
                    const SizedBox(height: ConnectMetrics.sectionGap),
                    const ConnectSectionHeader(label: 'ABOUT YOU'),
                    const SizedBox(height: ConnectMetrics.cardGap),
                    if (profileState.isLoading)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 48),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colors.primary,
                            ),
                          ),
                        ),
                      )
                    else if (profileState.error != null)
                      statusCard(
                        icon: Icons.error_outline_rounded,
                        message: profileState.error!,
                        action: GlassButton(
                          label: 'Retry',
                          onPressed: () => ref
                              .read(profileNotifierProvider.notifier)
                              .refresh(),
                        ),
                      )
                    else if (user == null)
                      statusCard(
                        icon: Icons.person_outline_rounded,
                        message: 'No profile data found.',
                      )
                    else ...[
                      ConnectPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildProfileRow(
                              context,
                              'Age',
                              '${user.dateOfBirth.age}',
                            ),
                            const SizedBox(height: 12),
                            _buildProfileRow(context, 'Gender', user.gender),
                            const SizedBox(height: 12),
                            _buildProfileRow(
                              context,
                              'Profession',
                              user.profession ?? '—',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: ConnectMetrics.sectionGap),
                      const ConnectSectionHeader(label: 'YOUR PREFERENCES'),
                      const SizedBox(height: ConnectMetrics.cardGap),
                      ConnectPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildProfileRow(
                              context,
                              'Seeking',
                              prefs == null
                                  ? '—'
                                  : prefs.seekingGenders.join(', '),
                            ),
                            const SizedBox(height: 12),
                            _buildProfileRow(
                              context,
                              'Age Range',
                              prefs == null
                                  ? '—'
                                  : '${prefs.minAgeYears}-${prefs.maxAgeYears}',
                            ),
                            const SizedBox(height: 12),
                            _buildProfileRow(
                              context,
                              'Distance',
                              prefs == null
                                  ? '—'
                                  : 'Within ${prefs.maxDistanceKm} km',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Matches and conversations live on the Matches tab, so these tiles switch
  /// tabs instead of pushing a duplicate screen. The sub-view is set first so
  /// the tab opens on the right list.
  void _openMatchesTab(WidgetRef ref, MatchesView view) {
    ref.read(matchesViewProvider.notifier).state = view;
    ref.read(mainNavigationIndexProvider.notifier).state = 1;
  }

  Widget _buildProfileRow(BuildContext context, String label, String value) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      );

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required Color tint,
    required String value,
    required String label,
    VoidCallback? onTap,
  }) => Semantics(
    button: onTap != null,
    label: onTap == null ? null : 'Open $label',
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: GlassContainer(
        // Tighter vertically on a narrow viewport: three tiles across a 320pt
        // phone leave roughly 90pt each, which is not enough for generous
        // padding plus an icon plus two lines of wrapped text. The tile has a
        // fixed height and centres its content, so padding only sets the
        // overflow margin, not the look.
        padding: EdgeInsets.symmetric(
          vertical: MediaQuery.sizeOf(context).width < 380 ? 8 : 12,
          horizontal: 8,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: tint,
                size: MediaQuery.sizeOf(context).width < 380 ? 22 : 28,
              ),
              SizedBox(height: MediaQuery.sizeOf(context).width < 380 ? 4 : 8),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontFamily: AppTheme.displayFamily,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: MediaQuery.sizeOf(context).width < 380 ? 2 : 4),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
