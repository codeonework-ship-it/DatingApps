import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/runtime_feature_flags_provider.dart';
import '../../../core/theme/cinematic_effects.dart';
import '../../../core/widgets/connect_page.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../friends/screens/friends_screen.dart';
import '../../groups/group_launch.dart';
import '../../blog/blog_screen.dart';
import '../../city_pilot/city_pilot_screen.dart';
import '../../clubs/clubs_screen.dart';
import '../../photo_themes/photo_themes_screen.dart';
import '../engagement_l10n.dart';
import '../providers/billing_coexistence_provider.dart';
import '../providers/daily_prompt_provider.dart';
import 'circle_challenges_screen.dart';
import 'conversation_rooms_screen.dart';
import 'daily_prompt_screen.dart';
import 'group_coffee_polls_screen.dart';
import 'level_progression_screen.dart';
import 'trust_badges_screen.dart';
import 'trust_filter_screen.dart';
import 'voice_icebreakers_screen.dart';

class EngagementHubScreen extends ConsumerWidget {
  const EngagementHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matrixAsync = ref.watch(billingCoexistenceMatrixProvider);
    final runtimeFlags = ref
        .watch(runtimeFeatureFlagsProvider)
        .maybeWhen(
          data: (flags) => flags,
          orElse: () => RuntimeFeatureFlags.defaults,
        );
    final l = engagementL10n(context);
    final dailyPromptState = ref.watch(dailyPromptProvider);
    final dailyPromptView = dailyPromptState.view;
    final dailyPromptSubtitle =
        dailyPromptState.isLoading && dailyPromptView == null
        ? l.engagementHubPromptLoading
        : dailyPromptView == null
        ? l.engagementHubPromptIntro
        : dailyPromptView.answer == null
        ? l.engagementHubPromptRepliedToday(
            dailyPromptView.spark.participantsToday,
          )
        : l.engagementHubPromptStreakSummary(
            dailyPromptView.streak.currentDays,
            dailyPromptView.spark.similarAnswerCount,
          );

    final colors = Theme.of(context).colorScheme;
    void push(Widget screen) => Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => screen));
    final create = <Widget>[
      if (runtimeFlags.enabled('intentional_dating_enabled'))
        _tile(
          icon: Icons.menu_book_outlined,
          title: l.engagementHubBlogTitle,
          subtitle: l.engagementHubBlogSubtitle,
          tint: colors.primary,
          onTap: () => openBlog(context),
        ),
      if (runtimeFlags.enabled('photo_themes_enabled'))
        _tile(
          icon: Icons.photo_library_outlined,
          title: l.engagementHubPhotoThemesTitle,
          subtitle: l.engagementHubPhotoThemesSubtitle,
          tint: colors.secondary,
          onTap: () => openPhotoThemes(context),
        ),
      if (runtimeFlags.enabled('clubs_enabled'))
        _tile(
          icon: Icons.local_library_outlined,
          title: l.engagementHubClubsTitle,
          subtitle: l.engagementHubClubsSubtitle,
          tint: colors.tertiary,
          onTap: () => openClubs(context),
        ),
    ];
    final meet = <Widget>[
      _tile(
        icon: Icons.location_city_rounded,
        title: l.engagementHubCityPilotTitle,
        subtitle: l.engagementHubCityPilotSubtitle,
        tint: colors.primary,
        onTap: () => push(const CityPilotScreen()),
      ),
      if (runtimeFlags.enabled('daily_prompts_enabled'))
        _tile(
          icon: Icons.local_fire_department_outlined,
          title: l.engagementDailyPromptTitle,
          subtitle: dailyPromptSubtitle,
          tint: colors.secondary,
          onTap: () => push(const DailyPromptScreen()),
        ),
      if (runtimeFlags.enabled('voice_icebreakers_enabled'))
        _tile(
          icon: Icons.groups_2_outlined,
          title: l.engagementHubVoiceTitle,
          subtitle: l.engagementHubVoiceSubtitle,
          tint: colors.tertiary,
          onTap: () => push(const VoiceIcebreakersScreen()),
        ),
      if (runtimeFlags.enabled('circles_enabled'))
        _tile(
          icon: Icons.groups_2_outlined,
          title: l.engagementCirclesTitle,
          subtitle: l.engagementHubCirclesSubtitle,
          tint: colors.primary,
          onTap: () => push(const CircleChallengesScreen()),
        ),
      if (runtimeFlags.enabled('group_coffee_polls_enabled'))
        _tile(
          icon: Icons.coffee_outlined,
          title: l.engagementHubCoffeeTitle,
          subtitle: l.engagementHubCoffeeSubtitle,
          tint: colors.secondary,
          onTap: () => push(const GroupCoffeePollsScreen()),
        ),
      if (runtimeFlags.enabled('groups_enabled'))
        _tile(
          icon: Icons.diversity_3_rounded,
          title: l.engagementHubGroupsTitle,
          subtitle: l.engagementHubGroupsSubtitle,
          tint: colors.tertiary,
          onTap: () => openGroups(context),
        ),
      if (runtimeFlags.enabled('rooms_enabled'))
        _tile(
          icon: Icons.forum_rounded,
          title: l.settingsConversationRoomsTitle,
          subtitle: l.engagementHubRoomsSubtitle,
          tint: colors.primary,
          onTap: () => push(const ConversationRoomsScreen()),
        ),
      _tile(
        icon: Icons.people_alt_rounded,
        title: l.engagementHubFriendsTitle,
        subtitle: l.engagementHubFriendsSubtitle,
        tint: colors.secondary,
        onTap: () => push(const FriendsScreen()),
      ),
    ];
    final progress = <Widget>[
      if (runtimeFlags.enabled('level_progression_enabled'))
        _tile(
          icon: Icons.auto_graph_rounded,
          title: l.engagementLevelTitle,
          subtitle: l.engagementHubLevelSubtitle,
          tint: colors.primary,
          onTap: () => push(const LevelProgressionScreen()),
        ),
      _tile(
        icon: Icons.workspace_premium_rounded,
        title: l.settingsTrustBadgesTitle,
        subtitle: l.settingsTrustBadgesSubtitle,
        tint: colors.tertiary,
        onTap: () => push(const TrustBadgesScreen()),
      ),
      _tile(
        icon: Icons.tune_rounded,
        title: l.settingsTrustFiltersTitle,
        subtitle: l.settingsTrustFiltersSubtitle,
        tint: colors.secondary,
        onTap: () => push(const TrustFilterScreen()),
      ),
      if (runtimeFlags.enabled('billing_enabled'))
        matrixAsync.when(
          data: (matrix) {
            final preview = matrix.monetizedFeatures
                .take(3)
                .map((item) => item.featureCode.replaceAll('_', ' '))
                .join(', ');
            return ConnectPanel(
              padding: const EdgeInsets.all(ConnectMetrics.padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    matrix.coreProgressionNonBlocking
                        ? l.engagementHubPaywallFree
                        : l.engagementHubPolicyUpdating,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (preview.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      l.engagementHubPremiumAreas(preview),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),
    ];

    // Tiles arrive in a short stagger the first time the tab is seen.
    var order = 0;
    List<Widget> section(String label, String caption, List<Widget> tiles) => [
      const SizedBox(height: ConnectMetrics.sectionGap),
      ConnectSectionHeader(label: label, caption: caption),
      const SizedBox(height: ConnectMetrics.cardGap),
      for (final tile in tiles)
        Padding(
          padding: const EdgeInsets.only(bottom: ConnectMetrics.cardGap),
          child: CinematicEntrance(index: order++, child: tile),
        ),
    ];

    return Scaffold(
      body: PostLoginBackdrop(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, box) {
              final gutter = ConnectMetrics.gutterFor(box.maxWidth);
              return CinematicStaggerScope(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(gutter, 12, gutter, 120),
                  children: [
                    ConnectPageHeader(
                      eyebrow: l.engagementHubEyebrow,
                      title: l.engagementHubTitle,
                      subtitle: l.engagementHubSubtitle,
                    ),
                    if (create.isNotEmpty)
                      ...section(
                        l.engagementHubSectionCreate,
                        l.engagementHubSectionCreateCaption,
                        create,
                      ),
                    ...section(
                      l.engagementHubSectionMeet,
                      l.engagementHubSectionMeetCaption,
                      meet,
                    ),
                    ...section(
                      l.engagementHubSectionProgress,
                      l.engagementHubSectionProgressCaption,
                      progress,
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

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color tint,
    required VoidCallback onTap,
  }) => ConnectNavTile(
    icon: icon,
    title: title,
    subtitle: subtitle,
    tint: tint,
    onTap: onTap,
  );
}
