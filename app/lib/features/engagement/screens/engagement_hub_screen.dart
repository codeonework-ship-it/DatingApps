import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../providers/billing_coexistence_provider.dart';
import '../providers/daily_prompt_provider.dart';
import 'circle_challenges_screen.dart';
import 'conversation_rooms_screen.dart';
import 'daily_prompt_screen.dart';
import 'trust_badges_screen.dart';
import 'trust_filter_screen.dart';
import '../../friends/screens/friends_screen.dart';

class EngagementHubScreen extends ConsumerWidget {
  const EngagementHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matrixAsync = ref.watch(billingCoexistenceMatrixProvider);
    final dailyPromptState = ref.watch(dailyPromptProvider);
    final dailyPromptView = dailyPromptState.view;
    final dailyPromptSubtitle =
        dailyPromptState.isLoading && dailyPromptView == null
        ? 'Loading today\'s prompt'
        : dailyPromptView == null
        ? 'Answer one prompt daily and build your streak.'
        : dailyPromptView.answer == null
        ? '${dailyPromptView.spark.participantsToday} people replied today'
        : 'Streak ${dailyPromptView.streak.currentDays}d · ${dailyPromptView.spark.similarAnswerCount} similar replies';

    return Scaffold(
      body: PostLoginBackdrop(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GlassContainer(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.white.withValues(alpha: 0.78),
                blur: 10,
                borderRadius: const BorderRadius.all(Radius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Engagement',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: AppTheme.textDark,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Build stronger matches with trust and shared activities.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              matrixAsync.when(
                data: (matrix) {
                  final preview = matrix.monetizedFeatures
                      .take(3)
                      .map((item) => item.featureCode.replaceAll('_', ' '))
                      .join(', ');
                  return GlassContainer(
                    padding: const EdgeInsets.all(12),
                    backgroundColor: Colors.white.withValues(alpha: 0.78),
                    blur: 8,
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          matrix.coreProgressionNonBlocking
                              ? 'Core progression stays paywall-free.'
                              : 'Monetization policy is being updated.',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: AppTheme.textDark,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        if (preview.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Optional premium areas: $preview',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppTheme.textGrey),
                          ),
                        ],
                      ],
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              _premiumTile(
                context,
                icon: Icons.local_fire_department_outlined,
                title: 'Daily Prompt Streak',
                subtitle: dailyPromptSubtitle,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const DailyPromptScreen(),
                    ),
                  );
                },
              ),
              _premiumTile(
                context,
                icon: Icons.workspace_premium_rounded,
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
              _premiumTile(
                context,
                icon: Icons.tune_rounded,
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
              _premiumTile(
                context,
                icon: Icons.groups_2_outlined,
                title: 'Local Circle Challenges',
                subtitle: 'Join a city circle and submit this week\'s entry',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CircleChallengesScreen(),
                    ),
                  );
                },
              ),
              _premiumTile(
                context,
                icon: Icons.forum_rounded,
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
              _premiumTile(
                context,
                icon: Icons.people_alt_rounded,
                title: 'Friends & Activities',
                subtitle: 'Maintain friendships and friend engagement',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const FriendsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _premiumTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: GlassContainer(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      backgroundColor: Colors.white.withValues(alpha: 0.8),
      blur: 8,
      borderRadius: const BorderRadius.all(Radius.circular(18)),
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
          const SizedBox(width: 12),
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
                const SizedBox(height: 2),
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
            size: 14,
            color: AppTheme.textHint,
          ),
        ],
      ),
    ),
  );
}
