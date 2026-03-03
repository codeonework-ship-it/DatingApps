import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../profile/providers/user_settings_provider.dart';
import 'blocked_users_screen.dart';
import 'emergency_contacts_screen.dart';
import 'moderation_appeals_screen.dart';

class PrivacySafetyScreen extends ConsumerWidget {
  const PrivacySafetyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(userSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & Safety')),
      body: PostLoginBackdrop(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppTheme.contentMaxWidth,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: settingsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => Center(
                    child: TextButton(
                      onPressed: () => ref.invalidate(userSettingsProvider),
                      child: const Text('Retry'),
                    ),
                  ),
                  data: (s) => GlassContainer(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.white.withValues(alpha: 0.9),
                    blur: 12,
                    borderRadius: const BorderRadius.all(Radius.circular(24)),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: const Text('Show age'),
                            subtitle: const Text(
                              'Control whether your age is visible',
                            ),
                            value: s.showAge,
                            onChanged: (v) => ref
                                .read(userSettingsProvider.notifier)
                                .patchSettings(showAge: v),
                          ),
                          SwitchListTile(
                            title: const Text('Show exact distance'),
                            subtitle: const Text(
                              'Show precise distance on your profile',
                            ),
                            value: s.showExactDistance,
                            onChanged: (v) => ref
                                .read(userSettingsProvider.notifier)
                                .patchSettings(showExactDistance: v),
                          ),
                          SwitchListTile(
                            title: const Text('Show online status'),
                            subtitle: const Text(
                              'Allow others to see if you are online',
                            ),
                            value: s.showOnlineStatus,
                            onChanged: (v) => ref
                                .read(userSettingsProvider.notifier)
                                .patchSettings(showOnlineStatus: v),
                          ),
                          const Divider(height: 24),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.contact_phone_outlined),
                            title: const Text('Emergency Contacts'),
                            subtitle: const Text(
                              'Manage trusted emergency contacts',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      const EmergencyContactsScreen(),
                                ),
                              );
                            },
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.block_outlined),
                            title: const Text('Blocked Users'),
                            subtitle: const Text('Review and unblock users'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const BlockedUsersScreen(),
                                ),
                              );
                            },
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.gavel_outlined),
                            title: const Text('Moderation Appeals'),
                            subtitle: const Text(
                              'Submit an appeal and track review status',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      const ModerationAppealsScreen(),
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
      ),
    );
  }
}
