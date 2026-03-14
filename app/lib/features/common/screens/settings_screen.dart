import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../../engagement/screens/conversation_rooms_screen.dart';
import '../../engagement/screens/trust_badges_screen.dart';
import '../../engagement/screens/trust_filter_screen.dart';
import '../../friends/screens/friends_screen.dart';
import '../../profile/screens/setup/setup_basic_info_screen.dart';
import '../../profile/screens/setup/setup_photos_screen.dart';
import '../../profile/screens/setup/setup_preferences_screen.dart';
import '../screens/about_app_screen.dart';
import '../screens/help_support_screen.dart';
import '../screens/notification_settings_screen.dart';
import '../screens/privacy_safety_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottomClearance = MediaQuery.of(context).padding.bottom + 104;

    return Scaffold(
      body: PostLoginBackdrop(
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                floating: true,
                snap: true,
                elevation: 0,
                backgroundColor: Colors.transparent,
                title: Text(
                  'Settings',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Settings Content
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Profile Section
                    _buildSectionHeader(context, 'Profile'),
                    _buildSettingsTile(
                      context,
                      icon: Icons.person,
                      title: 'Edit Profile',
                      subtitle: 'Update your information',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const SetupBasicInfoScreen(),
                          ),
                        );
                      },
                    ),
                    _buildSettingsTile(
                      context,
                      icon: Icons.photo,
                      title: 'Photos',
                      subtitle: 'Manage your photos',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const SetupPhotosScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Preferences Section
                    _buildSectionHeader(context, 'Preferences'),
                    _buildSettingsTile(
                      context,
                      icon: Icons.favorite,
                      title: 'Dating Preferences',
                      subtitle: 'Age, location, interests',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const SetupPreferencesScreen(),
                          ),
                        );
                      },
                    ),
                    _buildSettingsTile(
                      context,
                      icon: Icons.notifications,
                      title: 'Notifications',
                      subtitle: 'Push & email notifications',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const NotificationSettingsScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Engagement Section
                    _buildSectionHeader(context, 'Engagement'),
                    _buildSettingsTile(
                      context,
                      icon: Icons.workspace_premium,
                      title: 'Trust Badges',
                      subtitle: 'See earned badges and trust history',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const TrustBadgesScreen(),
                          ),
                        );
                      },
                    ),
                    _buildSettingsTile(
                      context,
                      icon: Icons.tune,
                      title: 'Trust Filters',
                      subtitle: 'Control trust requirements for discovery',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const TrustFilterScreen(),
                          ),
                        );
                      },
                    ),
                    _buildSettingsTile(
                      context,
                      icon: Icons.forum,
                      title: 'Conversation Rooms',
                      subtitle: 'Browse, join, leave, and moderate rooms',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ConversationRoomsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildSettingsTile(
                      context,
                      icon: Icons.people,
                      title: 'Friends & Connections',
                      subtitle: 'Build and maintain friend connections',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const FriendsScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // App Section
                    _buildSectionHeader(context, 'App'),
                    _buildSettingsTile(
                      context,
                      icon: Icons.security,
                      title: 'Privacy & Safety',
                      subtitle: 'Manage your privacy settings',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const PrivacySafetyScreen(),
                          ),
                        );
                      },
                    ),
                    _buildSettingsTile(
                      context,
                      icon: Icons.help,
                      title: 'Help & Support',
                      subtitle: 'FAQ and contact support',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const HelpSupportScreen(),
                          ),
                        );
                      },
                    ),
                    _buildSettingsTile(
                      context,
                      icon: Icons.info,
                      title: 'About',
                      subtitle: 'App details and stack',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const AboutAppScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Logout Button
                    GlassButton(
                      label: 'Logout',
                      backgroundColor: AppTheme.errorRed,
                      onPressed: () {
                        showDialog<void>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Logout'),
                            content: const Text(
                              'Are you sure you want to logout?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  ref
                                      .read(authNotifierProvider.notifier)
                                      .logout();
                                },
                                child: const Text('Logout'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    SizedBox(height: bottomClearance),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12, top: 12),
    child: Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppTheme.trustBlue,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTheme.textDark,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      backgroundColor: Colors.white.withValues(alpha: 0.82),
      blur: AppTheme.glassBlurUltra,
      crystalEffect: true,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppTheme.trustBlue.withValues(alpha: 0.14),
            ),
            child: Icon(icon, color: AppTheme.trustBlue, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.textGrey),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            color: AppTheme.textHint,
            size: 14,
          ),
        ],
      ),
    ),
  );
}
