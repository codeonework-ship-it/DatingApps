import '../../intentional_dating/profile_stories.dart';
import '../../blog/blog_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/feature_flags.dart';
import '../../../core/theme/theme_atmosphere.dart';
import '../../../core/theme/theme_presets.dart';
import '../../../core/widgets/connect_page.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/app_theme_provider.dart';
import 'account_data_screen.dart';
import '../../auth/screens/welcome_screen.dart';
import '../../engagement/screens/conversation_rooms_screen.dart';
import '../../engagement/screens/match_nudges_screen.dart';
import '../../engagement/screens/trust_badges_screen.dart';
import '../../engagement/screens/trust_filter_screen.dart';
import '../../calls/screens/call_history_screen.dart';
import '../../friends/screens/friends_screen.dart';
import '../../profile/screens/edit_profile_screen.dart';
import '../../profile/screens/setup/setup_photos_screen.dart';
import '../../profile/screens/setup/setup_preferences_screen.dart';
import '../../payment/screens/subscription_screen.dart';
import '../../verification/screens/verification_landing_screen.dart';
import '../../verification/screens/verification_upload_id_screen.dart';
import '../../intentional_dating/dating_rhythm.dart';
import '../../../core/providers/runtime_feature_flags_provider.dart';
import 'about_app_screen.dart';
import 'help_support_screen.dart';
import 'language_settings_screen.dart';
import 'notification_settings_screen.dart';
import 'privacy_safety_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final bottomClearance = MediaQuery.of(context).padding.bottom + 104;

    return Scaffold(
      body: PostLoginBackdrop(
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: ConnectPageHeader(
                    eyebrow: l10n.settingsEyebrow,
                    title: l10n.settingsTitle,
                    subtitle: l10n.settingsHeaderSubtitle,
                  ),
                ),
              ),

              // Settings Content
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Account first: who is signed in, and the way out, are
                    // never buried below every other setting.
                    ..._buildAccountSection(context, ref, l10n),
                    // The browser app is fixed to Today (webThemeLockedProvider).
                    if (!ref.watch(webThemeLockedProvider)) ...[
                      _buildSectionHeader(
                        context,
                        l10n.settingsThemeSection,
                        title: l10n.settingsThemeSectionTitle,
                        caption: l10n.settingsThemeSectionCaption,
                      ),
                      _buildThemeSelector(context, ref),
                    ],
                    if (ref
                            .watch(runtimeFeatureFlagsProvider)
                            .valueOrNull
                            ?.enabled(
                              'intentional_dating_enabled',
                              fallback: false,
                            ) ==
                        true)
                      _buildSectionHeader(
                        context,
                        l10n.settingsSectionYourStory,
                      ),
                    if (ref
                            .watch(runtimeFeatureFlagsProvider)
                            .valueOrNull
                            ?.enabled(
                              'intentional_dating_enabled',
                              fallback: false,
                            ) ??
                        false)
                      _buildSettingsTile(
                        context,
                        key: const ValueKey('qa.settings.dating_rhythm'),
                        icon: Icons.spa_outlined,
                        title: l10n.settingsDatingRhythmTitle,
                        subtitle: l10n.settingsDatingRhythmSubtitle,
                        onTap: () => openDatingRhythm(context),
                      ),
                    if (ref
                            .watch(runtimeFeatureFlagsProvider)
                            .valueOrNull
                            ?.enabled(
                              'intentional_dating_enabled',
                              fallback: false,
                            ) ==
                        true)
                      _buildSettingsTile(
                        context,
                        key: const ValueKey('qa.settings.profile_stories'),
                        icon: Icons.auto_stories_outlined,
                        title: l10n.settingsProfileStoriesTitle,
                        subtitle: l10n.settingsProfileStoriesSubtitle,
                        onTap: () => openProfileStories(context),
                      ),
                    if (ref
                            .watch(runtimeFeatureFlagsProvider)
                            .valueOrNull
                            ?.enabled(
                              'intentional_dating_enabled',
                              fallback: false,
                            ) ==
                        true)
                      _buildSettingsTile(
                        context,
                        key: const ValueKey('qa.settings.blog'),
                        icon: Icons.menu_book_outlined,
                        title: l10n.settingsBlogTitle,
                        subtitle: l10n.settingsBlogSubtitle,
                        onTap: () => openBlog(context),
                      ),
                    // Profile Section
                    _buildSectionHeader(context, l10n.settingsSectionProfile),
                    _buildSettingsTile(
                      context,
                      key: const ValueKey('qa.settings.edit_profile'),
                      icon: Icons.person,
                      title: l10n.settingsEditProfileTitle,
                      subtitle: l10n.settingsEditProfileSubtitle,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const EditProfileScreen(),
                          ),
                        );
                      },
                    ),
                    _buildSettingsTile(
                      context,
                      key: const ValueKey('qa.settings.photos'),
                      icon: Icons.photo,
                      title: l10n.settingsPhotosTitle,
                      subtitle: l10n.settingsPhotosSubtitle,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const SetupPhotosScreen(),
                          ),
                        );
                      },
                    ),
                    // Preferences Section
                    _buildSectionHeader(
                      context,
                      l10n.settingsSectionPreferences,
                    ),
                    _buildSettingsTile(
                      context,
                      key: const ValueKey('qa.settings.language'),
                      icon: Icons.language_rounded,
                      title: l10n.settingsLanguageTitle,
                      subtitle: l10n.settingsLanguageSubtitle,
                      semanticLabel: 'qa.settings.language',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const LanguageSettingsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildSettingsTile(
                      context,
                      key: const ValueKey('qa.settings.dating_preferences'),
                      icon: Icons.favorite,
                      title: l10n.settingsDatingPreferencesTitle,
                      subtitle: l10n.settingsDatingPreferencesSubtitle,
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
                      key: const ValueKey('qa.settings.account_data'),
                      icon: Icons.manage_accounts_outlined,
                      title: l10n.settingsAccountDataTitle,
                      subtitle: l10n.settingsAccountDataSubtitle,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const AccountDataScreen(),
                          ),
                        );
                      },
                    ),
                    _buildSettingsTile(
                      context,
                      key: const ValueKey('qa.settings.notifications'),
                      icon: Icons.notifications,
                      title: l10n.settingsNotificationsTitle,
                      subtitle: l10n.settingsNotificationsSubtitle,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const NotificationSettingsScreen(),
                          ),
                        );
                      },
                    ),
                    // Engagement Section
                    _buildSectionHeader(
                      context,
                      l10n.settingsSectionEngagement,
                    ),
                    _buildSettingsTile(
                      context,
                      key: const ValueKey('qa.settings.trust_badges'),
                      icon: Icons.workspace_premium,
                      title: l10n.settingsTrustBadgesTitle,
                      subtitle: l10n.settingsTrustBadgesSubtitle,
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
                      key: const ValueKey('qa.settings.trust_filters'),
                      icon: Icons.tune,
                      title: l10n.settingsTrustFiltersTitle,
                      subtitle: l10n.settingsTrustFiltersSubtitle,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const TrustFilterScreen(),
                          ),
                        );
                      },
                    ),
                    if ((ref.watch(runtimeFeatureFlagsProvider).valueOrNull ??
                            RuntimeFeatureFlags.defaults)
                        .enabled('rooms_enabled'))
                      _buildSettingsTile(
                        context,
                        key: const ValueKey('qa.settings.conversation_rooms'),
                        icon: Icons.forum,
                        title: l10n.settingsConversationRoomsTitle,
                        subtitle: l10n.settingsConversationRoomsSubtitle,
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
                      key: const ValueKey('qa.settings.friends'),
                      icon: Icons.people,
                      title: l10n.settingsFriendsTitle,
                      subtitle: l10n.settingsFriendsSubtitle,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const FriendsScreen(),
                          ),
                        );
                      },
                    ),
                    _buildSettingsTile(
                      context,
                      key: const ValueKey('qa.settings.call_history'),
                      icon: Icons.video_call_outlined,
                      title: l10n.settingsCallHistoryTitle,
                      subtitle: l10n.settingsCallHistorySubtitle,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const CallHistoryScreen(),
                          ),
                        );
                      },
                    ),
                    _buildSettingsTile(
                      context,
                      key: const ValueKey('qa.settings.match_nudges'),
                      icon: Icons.notifications_active_outlined,
                      title: l10n.settingsMatchNudgesTitle,
                      subtitle: l10n.settingsMatchNudgesSubtitle,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const MatchNudgesScreen(),
                          ),
                        );
                      },
                    ),
                    _buildSettingsTile(
                      context,
                      key: const ValueKey('qa.settings.subscriptions'),
                      icon: Icons.workspace_premium_outlined,
                      title: l10n.settingsSubscriptionsTitle,
                      subtitle: l10n.settingsSubscriptionsSubtitle,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const SubscriptionScreen(),
                          ),
                        );
                      },
                    ),
                    // App Section
                    _buildSectionHeader(context, l10n.settingsSectionApp),
                    _buildSettingsTile(
                      context,
                      key: const ValueKey('qa.settings.privacy_safety'),
                      icon: Icons.security,
                      title: l10n.settingsPrivacySafetyTitle,
                      subtitle: l10n.settingsPrivacySafetySubtitle,
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
                      key: const ValueKey(
                        'qa.settings.government_verification',
                      ),
                      icon: Icons.verified_user_rounded,
                      title: l10n.settingsGovernmentVerificationTitle,
                      subtitle: l10n.settingsGovernmentVerificationSubtitle,
                      semanticLabel: 'qa.settings.government_verification',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const VerificationLandingScreen(),
                          ),
                        );
                      },
                    ),
                    if (kEnableQaAutomation)
                      _buildSettingsTile(
                        context,
                        key: const ValueKey('qa.settings.verification_upload'),
                        icon: Icons.badge_outlined,
                        title: l10n.settingsQaVerificationUploadTitle,
                        subtitle: l10n.settingsQaVerificationUploadSubtitle,
                        semanticLabel: 'qa.settings.verification_upload',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  const VerificationUploadIdScreen(),
                            ),
                          );
                        },
                      ),
                    _buildSettingsTile(
                      context,
                      key: const ValueKey('qa.settings.help_support'),
                      icon: Icons.help,
                      title: l10n.settingsHelpSupportTitle,
                      subtitle: l10n.settingsHelpSupportSubtitle,
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
                      key: const ValueKey('qa.settings.about'),
                      icon: Icons.info,
                      title: l10n.settingsAboutTitle,
                      subtitle: l10n.settingsAboutSubtitle,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const AboutAppScreen(),
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

  /// The Account section: who is signed in, Sign out, and Sign out of all
  /// devices. Keeps the `qa.settings.logout` automation key.
  List<Widget> _buildAccountSection(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    final username =
        ref.watch(authNotifierProvider.select((s) => s.username))?.trim() ?? '';
    final error = Theme.of(context).colorScheme.error;
    return [
      _buildSectionHeader(
        context,
        l10n.settingsSectionAccount,
        caption: username.isEmpty ? null : l10n.settingsSignedInAs(username),
      ),
      _buildSettingsTile(
        context,
        key: const ValueKey('qa.settings.logout'),
        icon: Icons.logout_rounded,
        tint: error,
        title: l10n.settingsSignOut,
        subtitle: l10n.settingsSignOutSubtitle,
        onTap: () => _logout(context, ref),
      ),
      _buildSettingsTile(
        context,
        key: const ValueKey('qa.settings.logout_all'),
        icon: Icons.devices_other_rounded,
        tint: error,
        title: l10n.settingsSignOutAllTitle,
        subtitle: l10n.settingsSignOutAllSubtitle,
        onTap: () => _logoutAllDevices(context, ref),
      ),
    ];
  }

  /// Signs out on this device after the member confirms.
  ///
  /// Nothing is reset here: member data is tied to the signed-in member
  /// (see `watchSignedInUserId`), and inside the app the gate replaces this
  /// screen with Welcome as soon as the session ends, so `ref` must not be
  /// used after the sign-out starts.
  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await _confirmSignOut(
      context,
      key: 'qa.settings.logout',
      title: l10n.settingsSignOutConfirmTitle,
      body: l10n.settingsSignOutConfirmBody,
      action: l10n.settingsSignOut,
    );
    if (!confirmed || !context.mounted) return;
    final navigator = Navigator.of(context, rootNavigator: true);
    await ref.read(authNotifierProvider.notifier).logout();
    if (!context.mounted) return;
    await _showWelcome(context, navigator);
  }

  /// Ends every session of this member (all devices) after they confirm.
  /// When the server cannot do it the member stays signed in here and is
  /// told, rather than this device claiming the others were signed out.
  Future<void> _logoutAllDevices(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await _confirmSignOut(
      context,
      key: 'qa.settings.logout_all',
      title: l10n.settingsSignOutAllConfirmTitle,
      body: l10n.settingsSignOutAllConfirmBody,
      action: l10n.settingsSignOutAllConfirmAction,
    );
    if (!confirmed || !context.mounted) return;
    final navigator = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(context);
    final failed = l10n.settingsSignOutAllFailed;
    final signedOut = await ref
        .read(authNotifierProvider.notifier)
        .logoutAllDevices();
    if (!signedOut) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(failed)));
      return;
    }
    if (!context.mounted) return;
    await _showWelcome(context, navigator);
  }

  /// Outside the app gate (Settings pushed on its own) nothing replaces this
  /// screen when the session ends, so Welcome is shown here instead. Waits a
  /// frame first so that, inside the app, the gate has already swapped this
  /// screen for its own Welcome (and the gate is never removed).
  Future<void> _showWelcome(
    BuildContext context,
    NavigatorState navigator,
  ) async {
    await WidgetsBinding.instance.endOfFrame;
    if (!context.mounted || !navigator.mounted) return;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const WelcomeScreen()),
      (_) => false,
    );
  }

  Future<bool> _confirmSignOut(
    BuildContext context, {
    required String key,
    required String title,
    required String body,
    required String action,
  }) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        // A second tap while the dialog closes must not pop the screen
        // underneath it.
        void close(bool value) {
          if (ModalRoute.of(dialogContext)?.isCurrent ?? false) {
            Navigator.of(dialogContext).pop(value);
          }
        }

        return AlertDialog(
          key: ValueKey('$key.dialog'),
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              key: ValueKey('$key.cancel'),
              onPressed: () => close(false),
              child: Text(l10n.commonCancel),
            ),
            TextButton(
              key: ValueKey('$key.confirm'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(dialogContext).colorScheme.error,
              ),
              onPressed: () => close(true),
              child: Text(action),
            ),
          ],
        );
      },
    );
    return confirmed ?? false;
  }

  Future<void> _choosePreset(
    BuildContext context,
    WidgetRef ref,
    String presetId,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final failure = AppLocalizations.of(context).settingsThemeSaveFailed;
    try {
      await ref.read(appThemeProvider.notifier).selectPreset(presetId);
      final preset = ThemePresets.byId(presetId);
      if (preset != null && context.mounted) {
        await showThemeTitleCard(context, preset);
      }
    } on Object {
      messenger.showSnackBar(SnackBar(content: Text(failure)));
    }
  }

  /// Theme picker backed by the account's stored `settings.theme`.
  ///
  /// Presented inline rather than behind another screen: it is the one setting
  /// whose effect is visible the instant it is tapped. Each look is shown as a
  /// small Today page drawn in that look's own colours.
  Widget _buildThemeSelector(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selection = ref.watch(appThemeProvider);
    final selected = selection.mode;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final classicPreview = theme.brightness == Brightness.dark
        ? ThemePresets.realLifeNight
        : ThemePresets.realLife;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ConnectPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.palette_outlined, color: scheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.settingsAppearanceTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        l10n.settingsAppearanceSubtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Semantics(
              label: 'qa.settings.theme_selector',
              child: SegmentedButton<AppThemeChoice>(
                key: const ValueKey('qa.settings.theme_selector'),
                segments: AppThemeChoice.values
                    .map(
                      (choice) => ButtonSegment<AppThemeChoice>(
                        value: choice,
                        icon: Icon(choice.icon, size: 18),
                        label: Text(_themeChoiceLabel(l10n, choice)),
                      ),
                    )
                    .toList(growable: false),
                selected: {selected},
                showSelectedIcon: false,
                onSelectionChanged: (values) async {
                  final messenger = ScaffoldMessenger.of(context);
                  final failure = l10n.settingsThemeSaveFailed;
                  try {
                    await ref
                        .read(appThemeProvider.notifier)
                        .select(values.first);
                  } on Object {
                    messenger.showSnackBar(SnackBar(content: Text(failure)));
                  }
                },
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.settingsLooksTitle.toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              selection.isClassic
                  ? l10n.themeLooksTodayDescription
                  : localizedPresetTagline(l10n, selection.preset!),
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Semantics(
              label: 'qa.settings.theme_presets',
              // One swipeable strip keeps Settings short; every card is
              // built up front so each look stays reachable.
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (i, look) in [
                      (
                        ThemePresets.classicId,
                        l10n.settingsLooksClassicLabel,
                        classicPreview,
                        selection.isClassic,
                      ),
                      for (final preset in ThemePresets.themed)
                        (
                          preset.id,
                          preset.label,
                          preset,
                          selection.presetId == preset.id,
                        ),
                    ].indexed) ...[
                      if (i > 0) const SizedBox(width: 12),
                      SizedBox(
                        width: 136,
                        child: _ThemePreviewCard(
                          id: look.$1,
                          label: look.$2,
                          preview: look.$3,
                          selected: look.$4,
                          onTap: () => _choosePreset(context, ref, look.$1),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _themeChoiceLabel(AppLocalizations l10n, AppThemeChoice choice) =>
      switch (choice) {
        AppThemeChoice.light => l10n.settingsThemeLight,
        AppThemeChoice.dark => l10n.settingsThemeDark,
        AppThemeChoice.auto => l10n.settingsThemeMatchDevice,
      };

  /// Today's section header: an uppercase eyebrow, optional serif title and
  /// caption.
  Widget _buildSectionHeader(
    BuildContext context,
    String label, {
    String? title,
    String? caption,
  }) => Padding(
    padding: const EdgeInsets.only(top: ConnectMetrics.sectionGap, bottom: 12),
    child: ConnectSectionHeader(
      label: label.toUpperCase(),
      title: title,
      caption: caption,
    ),
  );

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? semanticLabel,
    Color? tint,
    Key? key,
  }) => Padding(
    key: key,
    padding: const EdgeInsets.only(bottom: ConnectMetrics.cardGap),
    child: ConnectNavTile(
      icon: icon,
      tint: tint,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      semanticLabel: semanticLabel,
    ),
  );
}

/// One look in the picker: a miniature Today page in that look's colours.
class _ThemePreviewCard extends StatelessWidget {
  const _ThemePreviewCard({
    required this.id,
    required this.label,
    required this.preview,
    required this.selected,
    required this.onTap,
  });

  final String id;
  final String label;
  final ThemePreset preview;
  final bool selected;
  final VoidCallback onTap;

  /// The miniature Today page drawn in the look's own colours.
  static Widget _previewPage(AppLocalizations l10n, ThemePreset p) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        l10n.settingsLookPreviewEyebrow,
        style: TextStyle(
          fontSize: 8,
          letterSpacing: 1.6,
          fontWeight: FontWeight.w700,
          color: p.primary,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        l10n.settingsLookPreviewHeadline,
        maxLines: 1,
        overflow: TextOverflow.clip,
        style: TextStyle(
          fontFamily: p.displayFamily,
          fontSize: 14,
          height: 1.1,
          color: p.ink,
        ),
      ),
      const Spacer(),
      Container(
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: p.paper,
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          border: Border.all(color: p.rule),
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: p.secondaryTint,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(child: Container(height: 4, color: p.rule)),
            const SizedBox(width: 4),
            Container(
              width: 20,
              height: 12,
              decoration: BoxDecoration(
                color: p.primary,
                borderRadius: const BorderRadius.all(Radius.circular(999)),
              ),
            ),
          ],
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final p = preview;
    const radius = BorderRadius.all(Radius.circular(16));
    return Semantics(
      label: 'qa.settings.theme_preset.$id',
      button: true,
      selected: selected,
      child: InkWell(
        key: ValueKey<String>('qa.settings.theme_preset.$id'),
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The miniature page.
              Container(
                height: 88,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  gradient: p.groundGradient,
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                ),
                // A themed look previews its own scene (snowfall, tracery,
                // roses...) behind the miniature page.
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (!ThemePresets.isEveryday(p))
                      // A still frame: eleven moving chips would be noise.
                      ExcludeSemantics(
                        child: ThemeAtmosphere(preset: p, ambient: false),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: _previewPage(AppLocalizations.of(context), p),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    if (selected)
                      Icon(Icons.check_circle, size: 16, color: scheme.primary),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
