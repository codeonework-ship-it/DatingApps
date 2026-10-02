import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/layout/app_layout.dart';
import '../../../core/network/api_error_message.dart';
import '../../../core/providers/runtime_feature_flags_provider.dart';
import '../../../core/telemetry/client_error_reporter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../friends/providers/friends_provider.dart';
import '../../graduation/models/graduation_labels.dart';
import '../../graduation/providers/graduation_provider.dart';
import '../../profile/providers/user_settings_provider.dart';
import '../../safety/screens/sos_screen.dart';
import '../../profile/widgets/profile_showcase.dart';
import 'blocked_users_screen.dart';
import 'emergency_contacts_screen.dart';
import 'moderation_appeals_screen.dart';

class PrivacySafetyScreen extends ConsumerWidget {
  const PrivacySafetyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
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
      appBar: AppBar(title: Text(l10n.privacyTitle)),
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
                      child: Text(l10n.commonRetry),
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
                            title: Text(l10n.privacyShowAge),
                            subtitle: Text(l10n.privacyShowAgeSubtitle),
                            value: s.showAge,
                            onChanged: (v) => ref
                                .read(userSettingsProvider.notifier)
                                .patchSettings(showAge: v),
                          ),
                          SwitchListTile(
                            title: Text(l10n.privacyShowDistance),
                            subtitle: Text(l10n.privacyShowDistanceSubtitle),
                            value: s.showExactDistance,
                            onChanged: (v) => ref
                                .read(userSettingsProvider.notifier)
                                .patchSettings(showExactDistance: v),
                          ),
                          SwitchListTile(
                            title: Text(l10n.privacyShowOnline),
                            subtitle: Text(l10n.privacyShowOnlineSubtitle),
                            value: s.showOnlineStatus,
                            onChanged: (v) => ref
                                .read(userSettingsProvider.notifier)
                                .patchSettings(showOnlineStatus: v),
                          ),
                          const _FriendSearchTile(),
                          const _ProfileShowcaseTile(),
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
                              title: Text(l10n.privacyEmergencySos),
                              subtitle: Text(l10n.privacyEmergencySosSubtitle),
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
                            title: Text(l10n.privacyEmergencyContacts),
                            subtitle: Text(
                              l10n.privacyEmergencyContactsSubtitle,
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
                            title: Text(l10n.privacyBlockedUsers),
                            subtitle: Text(l10n.privacyBlockedUsersSubtitle),
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
                            title: Text(l10n.privacyModerationAppeals),
                            subtitle: Text(
                              l10n.privacyModerationAppealsSubtitle,
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
    final l10n = AppLocalizations.of(context);
    final setting = ref.watch(friendSearchVisibilityProvider);
    return SwitchListTile(
      key: const ValueKey('qa.privacy.friend_search'),
      title: Text(l10n.privacyFriendSearch),
      subtitle: Text(
        setting.hasError
            ? l10n.privacySettingLoadFailed
            : l10n.privacyFriendSearchSubtitle,
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
                          fallback: l10n.privacyChoiceSaveFailed,
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

/// "Show my public writing on my profile" (default off). On lets members see
/// the chapters shared with the community and the photos on the wall in a
/// section of the profile; nothing private or friends-only ever appears.
class _ProfileShowcaseTile extends ConsumerWidget {
  const _ProfileShowcaseTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final setting = ref.watch(profileShowcaseConsentProvider);
    return SwitchListTile(
      key: const ValueKey('qa.privacy.profile_showcase'),
      title: Text(l10n.privacyShowcase),
      subtitle: Text(
        setting.hasError
            ? l10n.privacySettingLoadFailed
            : l10n.privacyShowcaseSubtitle,
      ),
      value: setting.valueOrNull ?? false,
      onChanged: setting.hasValue
          ? (v) => setProfileShowcaseConsent(context, ref, visible: v)
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
    final l10n = AppLocalizations.of(context);
    final reporter = ref.watch(clientErrorReporterProvider);
    return ValueListenableBuilder<bool>(
      valueListenable: reporter.optIn,
      builder: (context, enabled, _) => SwitchListTile(
        key: const ValueKey('qa.privacy.crash_reports'),
        title: Text(l10n.privacyCrashReports),
        subtitle: Text(l10n.privacyCrashReportsSubtitle),
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
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(discoveryPauseProvider);
    final notifier = ref.read(discoveryPauseProvider.notifier);
    final theme = Theme.of(context);
    final paused = state.paused;
    final reason = state.pause?.isGraduation ?? false
        ? l10n.privacyGraduatedReason
        : paused
        ? l10n.privacyPausedReason
        : l10n.privacyActiveReason;
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
          title: Text(
            paused ? l10n.privacyDiscoveryPaused : l10n.privacyDiscoveryActive,
          ),
          subtitle: Text(
            state.error == null
                ? reason
                : localizedGraduationError(l10n, state.error!, state.failure),
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
                        child: Text(l10n.privacyResume),
                      )
                    : OutlinedButton(
                        key: const ValueKey('qa.graduation.discovery_pause'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, AppLayout.minTapTarget),
                        ),
                        onPressed: state.isMutating
                            ? null
                            : notifier.pauseDiscovery,
                        child: Text(l10n.privacyPause),
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
