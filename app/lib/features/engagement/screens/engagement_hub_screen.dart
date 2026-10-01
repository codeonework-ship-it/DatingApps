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
    final dailyPromptState = ref.watch(dailyPromptProvider);
    final dailyPromptView = dailyPromptState.view;
    final dailyPromptSubtitle =
        dailyPromptState.isLoading && dailyPromptView == null
        ? 'Loading today\'s prompt'
        : dailyPromptView == null
        ? 'Answer one prompt daily and build your streak.'
        : dailyPromptView.answer == null
        ? '${dailyPromptView.spark.participantsToday} people replied today'
        : 'Streak ${dailyPromptView.streak.currentDays}d · '
              '${dailyPromptView.spark.similarAnswerCount} similar replies';

    final colors = Theme.of(context).colorScheme;
    void push(Widget screen) => Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => screen));
    final create = <Widget>[
      if (runtimeFlags.enabled('intentional_dating_enabled'))
        _tile(
          icon: Icons.menu_book_outlined,
          title: 'Blog · Open Chapters',
          subtitle: 'Read stories, share photos and write your own.',
          tint: colors.primary,
          onTap: () => openBlog(context),
        ),
      if (runtimeFlags.enabled('photo_themes_enabled'))
        _tile(
          icon: Icons.photo_library_outlined,
          title: 'Photo Themes',
          subtitle: 'Share one photo per prompt and see everyone’s.',
          tint: colors.secondary,
          onTap: () => openPhotoThemes(context),
        ),
      if (runtimeFlags.enabled('clubs_enabled'))
        _tile(
          icon: Icons.local_library_outlined,
          title: 'Book & Film Clubs',
          subtitle: 'Follow a weekly pick, talk it over, rate it.',
          tint: colors.tertiary,
          onTap: () => openClubs(context),
        ),
    ];
    final meet = <Widget>[
      _tile(
        icon: Icons.location_city_rounded,
        title: 'The City Pilot',
        subtitle: 'A small community. Conversations that become plans.',
        tint: colors.primary,
        onTap: () => push(const CityPilotScreen()),
      ),
      if (runtimeFlags.enabled('daily_prompts_enabled'))
        _tile(
          icon: Icons.local_fire_department_outlined,
          title: 'Daily Prompt Streak',
          subtitle: dailyPromptSubtitle,
          tint: colors.secondary,
          onTap: () => push(const DailyPromptScreen()),
        ),
      if (runtimeFlags.enabled('voice_icebreakers_enabled'))
        _tile(
          icon: Icons.groups_2_outlined,
          title: 'Guided Voice Icebreakers',
          subtitle: 'Send one guided 20-45s voice intro per match/day',
          tint: colors.tertiary,
          onTap: () => push(const VoiceIcebreakersScreen()),
        ),
      if (runtimeFlags.enabled('circles_enabled'))
        _tile(
          icon: Icons.groups_2_outlined,
          title: 'Local Circle Challenges',
          subtitle: 'Join a city circle and submit this week\'s entry',
          tint: colors.primary,
          onTap: () => push(const CircleChallengesScreen()),
        ),
      if (runtimeFlags.enabled('group_coffee_polls_enabled'))
        _tile(
          icon: Icons.coffee_outlined,
          title: 'Group Coffee Poll',
          subtitle: 'Create, vote, and finalize lightweight meetup polls',
          tint: colors.secondary,
          onTap: () => push(const GroupCoffeePollsScreen()),
        ),
      if (runtimeFlags.enabled('groups_enabled'))
        _tile(
          icon: Icons.diversity_3_rounded,
          title: 'Groups',
          subtitle: 'Lifestyle communities and private friend groups',
          tint: colors.tertiary,
          onTap: () => openGroups(context),
        ),
      if (runtimeFlags.enabled('rooms_enabled'))
        _tile(
          icon: Icons.forum_rounded,
          title: 'Conversation Rooms',
          subtitle: 'Live chat rooms: drop in, talk, make friends',
          tint: colors.primary,
          onTap: () => push(const ConversationRoomsScreen()),
        ),
      _tile(
        icon: Icons.people_alt_rounded,
        title: 'Friends & Introductions',
        subtitle: 'Invite a trusted friend, even if they aren’t dating',
        tint: colors.secondary,
        onTap: () => push(const FriendsScreen()),
      ),
    ];
    final progress = <Widget>[
      if (runtimeFlags.enabled('level_progression_enabled'))
        _tile(
          icon: Icons.auto_graph_rounded,
          title: 'Level & XP',
          subtitle:
              'Track meaningful activity, level rewards, and '
              'trust gates',
          tint: colors.primary,
          onTap: () => push(const LevelProgressionScreen()),
        ),
      _tile(
        icon: Icons.workspace_premium_rounded,
        title: 'Trust Badges',
        subtitle: 'See earned badges and trust history',
        tint: colors.tertiary,
        onTap: () => push(const TrustBadgesScreen()),
      ),
      _tile(
        icon: Icons.tune_rounded,
        title: 'Trust Filters',
        subtitle: 'Control trust requirements for discovery',
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
                        ? 'Core progression stays paywall-free.'
                        : 'Monetization policy is being updated.',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (preview.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Optional premium areas: $preview',
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
                    const ConnectPageHeader(
                      eyebrow: 'ENGAGE',
                      title: 'Make something together.',
                      subtitle:
                          'Build stronger matches with trust and shared '
                          'activities.',
                    ),
                    if (create.isNotEmpty)
                      ...section(
                        'CREATE & SHARE',
                        'Stories, photos and clubs that start real '
                            'conversations.',
                        create,
                      ),
                    ...section(
                      'MEET PEOPLE',
                      'Small groups, prompts and plans at your pace.',
                      meet,
                    ),
                    ...section(
                      'TRUST & PROGRESS',
                      'Your level, your badges and who can find you.',
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
