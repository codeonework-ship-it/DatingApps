import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/glass_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../notifications/providers/notification_provider.dart';
import '../../notifications/screens/notification_inbox_screen.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationProvider);
    final preferences = state.preferences;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.notificationsTitle)),
      body: PostLoginBackdrop(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: GlassContainer(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: 0.9),
                      blur: 12,
                      borderRadius: const BorderRadius.all(Radius.circular(24)),
                      child: Column(
                        children: [
                          ListTile(
                            key: const ValueKey('qa.notifications.inbox'),
                            leading: const Icon(
                              Icons.notifications_active_rounded,
                            ),
                            title: Text(l10n.notificationsInboxTitle),
                            subtitle: Text(
                              state.unreadCount == 0
                                  ? l10n.notificationsInboxCaughtUp
                                  : l10n.notificationsInboxUnread(
                                      state.unreadCount,
                                    ),
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const NotificationInboxScreen(),
                              ),
                            ),
                          ),
                          const Divider(),
                          SwitchListTile(
                            key: const ValueKey('qa.notifications.in_app'),
                            title: Text(l10n.notificationsInAppTitle),
                            subtitle: Text(l10n.notificationsInAppSubtitle),
                            value: preferences.inApp,
                            onChanged: (v) => ref
                                .read(notificationProvider.notifier)
                                .updatePreferences(
                                  preferences.copyWith(inApp: v),
                                ),
                          ),
                          SwitchListTile(
                            key: const ValueKey('qa.notifications.push'),
                            title: Text(l10n.notificationsPushTitle),
                            subtitle: Text(l10n.notificationsPushSubtitle),
                            value: preferences.push,
                            onChanged: (v) => ref
                                .read(notificationProvider.notifier)
                                .updatePreferences(
                                  preferences.copyWith(push: v),
                                ),
                          ),
                          SwitchListTile(
                            key: const ValueKey('qa.notifications.new_matches'),
                            title: Text(l10n.notificationsNewMatchesTitle),
                            subtitle: Text(
                              l10n.notificationsNewMatchesSubtitle,
                            ),
                            value: preferences.newMatches,
                            onChanged: (v) => ref
                                .read(notificationProvider.notifier)
                                .updatePreferences(
                                  preferences.copyWith(newMatches: v),
                                ),
                          ),
                          SwitchListTile(
                            key: const ValueKey(
                              'qa.notifications.new_messages',
                            ),
                            title: Text(l10n.notificationsNewMessagesTitle),
                            subtitle: Text(
                              l10n.notificationsNewMessagesSubtitle,
                            ),
                            value: preferences.newMessages,
                            onChanged: (v) => ref
                                .read(notificationProvider.notifier)
                                .updatePreferences(
                                  preferences.copyWith(newMessages: v),
                                ),
                          ),
                          SwitchListTile(
                            key: const ValueKey('qa.notifications.likes'),
                            title: Text(l10n.notificationsLikesTitle),
                            subtitle: Text(l10n.notificationsLikesSubtitle),
                            value: preferences.likes,
                            onChanged: (v) => ref
                                .read(notificationProvider.notifier)
                                .updatePreferences(
                                  preferences.copyWith(likes: v),
                                ),
                          ),
                          SwitchListTile(
                            key: const ValueKey(
                              'qa.notifications.match_nudges',
                            ),
                            title: Text(l10n.notificationsMatchNudgesTitle),
                            subtitle: Text(
                              l10n.notificationsMatchNudgesSubtitle,
                            ),
                            value: preferences.matchNudges,
                            onChanged: (v) => ref
                                .read(notificationProvider.notifier)
                                .updatePreferences(
                                  preferences.copyWith(matchNudges: v),
                                ),
                          ),
                          SwitchListTile(
                            key: const ValueKey(
                              'qa.notifications.incoming_calls',
                            ),
                            title: Text(l10n.notificationsIncomingCallsTitle),
                            subtitle: Text(
                              l10n.notificationsIncomingCallsSubtitle,
                            ),
                            value: preferences.incomingCalls,
                            onChanged: (v) => ref
                                .read(notificationProvider.notifier)
                                .updatePreferences(
                                  preferences.copyWith(incomingCalls: v),
                                ),
                          ),
                          SwitchListTile(
                            key: const ValueKey('qa.notifications.safety'),
                            title: Text(l10n.notificationsSafetyTitle),
                            subtitle: Text(l10n.notificationsSafetySubtitle),
                            value: preferences.safety,
                            onChanged: (v) => ref
                                .read(notificationProvider.notifier)
                                .updatePreferences(
                                  preferences.copyWith(safety: v),
                                ),
                          ),
                          SwitchListTile(
                            key: const ValueKey(
                              'qa.notifications.friend_plans',
                            ),
                            title: Text(l10n.notificationsFriendPlansTitle),
                            subtitle: Text(
                              l10n.notificationsFriendPlansSubtitle,
                            ),
                            value: preferences.friendPlans,
                            onChanged: (v) => ref
                                .read(notificationProvider.notifier)
                                .updatePreferences(
                                  preferences.copyWith(friendPlans: v),
                                ),
                          ),
                          if (state.error != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                state.error!,
                                key: const ValueKey('qa.notifications.error'),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
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
