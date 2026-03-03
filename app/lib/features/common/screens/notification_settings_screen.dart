import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/glass_widgets.dart';
import '../../profile/providers/user_settings_provider.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(userSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: PostLoginBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: settingsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
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
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('New matches'),
                      subtitle: const Text('Get notified when you match'),
                      value: s.notifyNewMatch,
                      onChanged: (v) => ref
                          .read(userSettingsProvider.notifier)
                          .patchSettings(notifyNewMatch: v),
                    ),
                    SwitchListTile(
                      title: const Text('New messages'),
                      subtitle: const Text('Get notified for chat messages'),
                      value: s.notifyNewMessage,
                      onChanged: (v) => ref
                          .read(userSettingsProvider.notifier)
                          .patchSettings(notifyNewMessage: v),
                    ),
                    SwitchListTile(
                      title: const Text('Likes'),
                      subtitle: const Text(
                        'Get notified when someone likes you',
                      ),
                      value: s.notifyLikes,
                      onChanged: (v) => ref
                          .read(userSettingsProvider.notifier)
                          .patchSettings(notifyLikes: v),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
