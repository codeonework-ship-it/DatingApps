import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/layout/app_layout.dart';
import '../../../core/network/api_error_message.dart';
import '../../../core/providers/runtime_feature_flags_provider.dart';
import '../../../core/telemetry/client_error_reporter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../friends/providers/friends_provider.dart';
import '../../graduation/providers/graduation_provider.dart';
import '../../profile/providers/user_settings_provider.dart';
import '../../safety/screens/sos_screen.dart';
import 'blocked_users_screen.dart';
import 'emergency_contacts_screen.dart';
import 'moderation_appeals_screen.dart';

class PrivacySafetyScreen extends ConsumerWidget {
  const PrivacySafetyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(userSettingsProvider);
    final runtimeFlags = ref
        .watch(runtimeFeatureFlagsProvider)
        .maybeWhen(
          data: (flags) => flags,
          orElse: () => RuntimeFeatureFlags.defaults,
        );
    final sosEnabled =
        FeatureFlags.enableSOS && runtimeFlags.enabled('safety_sos_enabled');
    final graduationEnabled = runtimeFlags.enabled(
      'graduation_enabled',
      fallback: true,
    );

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
                          const _FriendSearchTile(),
                          if (graduationEnabled) const _DiscoveryPauseTile(),
                          const _CrashReportsTile(),
                          const Divider(height: 24),
                          if (sosEnabled)
                            ListTile(
                              key: const ValueKey('qa.safety.sos_journey'),
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                Icons.sos_rounded,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              title: const Text('Emergency SOS'),
                              subtitle: const Text(
                                'Activate an alert and review alert history',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const SosScreen(),
                                  ),
                                );
                              },
                            ),
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

/// "Let people find me in friend search" (default on). Off keeps the member
/// out of Add friend search; people who already see them can still add them.
class _FriendSearchTile extends ConsumerWidget {
  const _FriendSearchTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setting = ref.watch(friendSearchVisibilityProvider);
    return SwitchListTile(
      key: const ValueKey('qa.privacy.friend_search'),
      title: const Text('Let people find me in friend search'),
      subtitle: Text(
        setting.hasError
            ? 'This setting could not load. Open this page again to retry.'
            : 'Members can find you by name or @username in Add friend. '
                  'People you match or meet in rooms and groups can still '
                  'add you.',
      ),
      value: setting.valueOrNull ?? true,
      onChanged: setting.hasValue
          ? (v) async {
              try {
                await ref
                    .read(friendSearchVisibilityProvider.notifier)
                    .setVisible(visible: v);
              } on Object catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        apiErrorMessage(
                          e,
                          fallback: 'Your choice could not be saved.',
                        ),
                      ),
                    ),
                  );
                }
              }
            }
          : null,
    );
  }
}

/// "Share crash reports" (default on). Reports are anonymous and not linked
/// to the account, so this is a device preference stored locally rather than
/// an account setting. Off stops capture and deletes queued reports.
class _CrashReportsTile extends ConsumerWidget {
  const _CrashReportsTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reporter = ref.watch(clientErrorReporterProvider);
    return ValueListenableBuilder<bool>(
      valueListenable: reporter.optIn,
      builder: (context, enabled, _) => SwitchListTile(
        key: const ValueKey('qa.privacy.crash_reports'),
        title: const Text('Share crash reports'),
        subtitle: const Text(
          'Anonymous crash and error reports help us fix problems. No '
          'messages, photos or account details are included.',
        ),
        value: enabled,
        onChanged: (v) => reporter.setOptIn(enabled: v),
      ),
    );
  }
}

/// Shows whether the member is hidden from discovery (after a graduation or
/// by choice) and lets them pause or resume it.
class _DiscoveryPauseTile extends ConsumerWidget {
  const _DiscoveryPauseTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(discoveryPauseProvider);
    final notifier = ref.read(discoveryPauseProvider.notifier);
    final theme = Theme.of(context);
    final paused = state.paused;
    final reason = state.pause?.isGraduation ?? false
        ? 'You left Connect with your match. Nobody is dealt your card.'
        : paused
        ? 'Nobody is dealt your card until you resume.'
        : 'You are shown to other members in discovery.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          key: const ValueKey('qa.graduation.discovery_tile'),
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            paused ? Icons.pause_circle_outline : Icons.explore_outlined,
            color: paused ? AppTheme.warningOrange : theme.colorScheme.primary,
          ),
          title: Text(paused ? 'Discovery paused' : 'Discovery active'),
          subtitle: Text(
            state.error ?? reason,
            style: state.error != null
                ? theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  )
                : null,
          ),
          trailing: state.loaded
              ? paused
                    ? FilledButton.tonal(
                        key: const ValueKey('qa.graduation.discovery_resume'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, AppLayout.minTapTarget),
                        ),
                        onPressed: state.isMutating
                            ? null
                            : notifier.resumeDiscovery,
                        child: const Text('Resume'),
                      )
                    : OutlinedButton(
                        key: const ValueKey('qa.graduation.discovery_pause'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, AppLayout.minTapTarget),
                        ),
                        onPressed: state.isMutating
                            ? null
                            : notifier.pauseDiscovery,
                        child: const Text('Pause'),
                      )
              : const SizedBox(
                  width: AppLayout.space5,
                  height: AppLayout.space5,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
        ),
      ],
    );
  }
}
