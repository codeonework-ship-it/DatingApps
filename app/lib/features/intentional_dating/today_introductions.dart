import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_widgets.dart';
import '../../l10n/app_localizations.dart';
import '../graduation/providers/graduation_provider.dart';
import '../swipe/models/discovery_profile.dart';
import '../swipe/providers/curated_daily_set_provider.dart';
import '../walls/today_wall_data.dart';
import 'dating_rhythm.dart';
import 'profile_stories.dart';
import 'profile_story_nudge.dart';
import 'today_activities.dart';
import 'today_section.dart';
import 'today_wall.dart';

/// A finite set of real introductions, with reasons members can understand.
class TodayIntroductions extends ConsumerStatefulWidget {
  const TodayIntroductions({
    super.key,
    required this.onOpenProfile,
    required this.onBrowse,
    this.onOpenFilters,
    this.activeFilterChips = const [],
  });
  final ValueChanged<DiscoveryProfile> onOpenProfile;
  final VoidCallback onBrowse;
  final VoidCallback? onOpenFilters;
  final List<String> activeFilterChips;
  @override
  ConsumerState<TodayIntroductions> createState() => _TodayIntroductionsState();
}

class _TodayIntroductionsState extends ConsumerState<TodayIntroductions> {
  String? activity;
  Future<void> refresh() async {
    ref.invalidate(datingRhythmProvider);
    ref.invalidate(discoveryPauseProvider);
    ref.invalidate(todayWallProvider);
    ref.invalidate(coverOfWeekProvider);
    // The "Your story" card's count: stories edited elsewhere (another
    // device, the web app) show up on pull-to-refresh too.
    ref.invalidate(profileStoriesProvider);
    await ref.read(curatedDailySetProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(discoveryPauseProvider.select((state) => state.paused), (
      previous,
      next,
    ) {
      if (previous != next) ref.invalidate(curatedDailySetProvider);
    });
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final daily = ref.watch(curatedDailySetProvider);
    final rhythm = ref.watch(datingRhythmProvider);
    final pause = ref.watch(discoveryPauseProvider);
    final paused = pause.paused;
    final activities = daily.profiles.expand((p) => p.sharedActivities).toSet();
    // A refreshed set must never be hidden by a filter that no longer exists.
    final selected = activities.contains(activity) ? activity : null;
    final picks = daily.profiles
        .where((p) => selected == null || p.sharedActivities.contains(selected))
        .toList();
    final loading = daily.isLoading || rhythm.isLoading || pause.isLoading;
    final failed =
        daily.error != null || rhythm.hasError || pause.error != null;
    final showPicks =
        !paused && !loading && !failed && daily.profiles.isNotEmpty;
    return Scaffold(
      key: const ValueKey('qa.today.screen'),
      backgroundColor: theme.scaffoldBackgroundColor,
      // The same ground every tab uses, so a chosen look reaches Today too.
      body: PostLoginBackdrop(
        maxContentWidth: null,
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: refresh,
            child: LayoutBuilder(
              builder: (context, box) {
                final phone = box.maxWidth < 600;
                final gutter = phone ? 20.0 : 40.0;
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(gutter, 12, gutter, 40),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Header(
                            refreshing: daily.isLoading,
                            onRefresh: refresh,
                            onOpenFilters: widget.onOpenFilters,
                          ),
                          const SizedBox(height: 16),
                          _Hero(phone: phone),
                          // Cover of the Week and Today's wall bring their own
                          // top gap, so a hidden one leaves no hole.
                          const TodayCoverAndWall(),
                          const SizedBox(height: TodayMetrics.sectionGap),
                          const TodayActivities(),
                          const SizedBox(height: TodayMetrics.sectionGap),
                          TodaySectionHeader(label: l10n.todaySectionPace),
                          const SizedBox(height: TodayMetrics.cardGap),
                          TodayPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  alignment: WrapAlignment.spaceBetween,
                                  spacing: 24,
                                  runSpacing: 12,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.todayPaceTitle,
                                          style: theme.textTheme.titleMedium,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          l10n.todayPaceBody,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color: colors.onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                    OutlinedButton.icon(
                                      key: const ValueKey('qa.today.rhythm'),
                                      onPressed: () =>
                                          openDatingRhythm(context),
                                      icon: const Icon(Icons.tune_rounded),
                                      label: Text(l10n.todaySetRhythm),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: TodayMetrics.sectionGap),
                          TodaySectionHeader(label: l10n.todaySectionStory),
                          const SizedBox(height: TodayMetrics.cardGap),
                          const ProfileStoryNudge(),
                          const SizedBox(height: TodayMetrics.sectionGap),
                          TodaySectionHeader(
                            label: l10n.todaySectionIntroductions,
                            title: showPicks
                                ? l10n.todayIntroductionsTitle
                                : null,
                            caption: showPicks
                                ? l10n.todayIntroductionsCaption
                                : null,
                          ),
                          const SizedBox(height: TodayMetrics.cardGap),
                          if (widget.activeFilterChips.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: widget.activeFilterChips
                                    .map((label) => Chip(label: Text(label)))
                                    .toList(),
                              ),
                            ),
                          if (paused)
                            _Notice(
                              title: l10n.todayPausedTitle,
                              body: l10n.todayPausedBody,
                              action: l10n.todayManageRhythm,
                              onPressed: () => openDatingRhythm(context),
                            )
                          else if (loading)
                            Padding(
                              padding: const EdgeInsets.all(40),
                              child: Center(
                                child: CircularProgressIndicator(
                                  semanticsLabel:
                                      l10n.todayLoadingIntroductions,
                                ),
                              ),
                            )
                          else if (failed)
                            _Notice(
                              title: l10n.todayFailedTitle,
                              body: l10n.todayFailedBody,
                              action: l10n.todayTryAgain,
                              onPressed: refresh,
                            )
                          else if (daily.profiles.isEmpty)
                            _Notice(
                              title: l10n.todayEmptyTitle,
                              body: l10n.todayEmptyBody,
                              action: l10n.todayExploreProfiles,
                              onPressed: widget.onBrowse,
                            )
                          else ...[
                            if (activities.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    ChoiceChip(
                                      label: Text(l10n.todayAllIntroductions),
                                      selected: selected == null,
                                      onSelected: (_) =>
                                          setState(() => activity = null),
                                    ),
                                    for (final a in activities)
                                      ChoiceChip(
                                        key: ValueKey('qa.today.activity.$a'),
                                        label: Text(
                                          datingActivityLabel(l10n, a),
                                        ),
                                        selected: selected == a,
                                        onSelected: (_) => setState(
                                          () => activity = selected == a
                                              ? null
                                              : a,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            LayoutBuilder(
                              builder: (context, grid) {
                                final columns = grid.maxWidth >= 940
                                    ? 3
                                    : grid.maxWidth >= 620
                                    ? 2
                                    : 1;
                                const gap = 20.0;
                                final width =
                                    (grid.maxWidth - (columns - 1) * gap) /
                                    columns;
                                return Wrap(
                                  spacing: gap,
                                  runSpacing: gap,
                                  children: [
                                    for (final p in picks)
                                      SizedBox(
                                        width: width,
                                        child: _Introduction(
                                          profile: p,
                                          onOpen: () => widget.onOpenProfile(p),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                            TodayPanel(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.todayBreatheTitle,
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(l10n.todayBreatheBody),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: widget.onBrowse,
                                    child: Text(l10n.todayExploreMore),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// "TODAY" and the date on the left; refresh and filters on the right.
class _Header extends StatelessWidget {
  const _Header({
    required this.refreshing,
    required this.onRefresh,
    this.onOpenFilters,
  });
  final bool refreshing;
  final Future<void> Function() onRefresh;
  final VoidCallback? onOpenFilters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.todayLabel,
                style: theme.textTheme.labelMedium?.copyWith(
                  letterSpacing: 2.4,
                  fontWeight: FontWeight.w700,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                todayDateLabel(context, DateTime.now()),
                key: const ValueKey('qa.today.date'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: l10n.todayRefreshTooltip,
          onPressed: refreshing ? null : onRefresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
        if (onOpenFilters != null)
          IconButton(
            tooltip: l10n.todayDiscoveryPreferences,
            onPressed: onOpenFilters,
            icon: const Icon(Icons.tune_rounded),
          ),
      ],
    );
  }
}

/// "Wednesday, 1 October" in English, and the locale's own long weekday and
/// date form elsewhere ("Mittwoch, 1. Oktober"), falling back to English
/// when date symbols for that locale are not loaded.
String todayDateLabel(BuildContext context, DateTime date) {
  final locale = Localizations.maybeLocaleOf(context);
  try {
    if (locale == null || locale.languageCode == 'en') {
      return DateFormat('EEEE, d MMMM', locale?.toLanguageTag()).format(date);
    }
    return DateFormat.MMMMEEEEd(locale.toLanguageTag()).format(date);
  } on Object {
    return DateFormat('EEEE, d MMMM', 'en').format(date);
  }
}

/// The two-line serif headline and a one-line promise. Each headline line
/// stays on one line and scales down on narrow screens or at large text.
class _Hero extends StatelessWidget {
  const _Hero({required this.phone});
  final bool phone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              l10n.todayHeroTitle,
              maxLines: 2,
              style: theme.textTheme.displaySmall?.copyWith(
                fontFamily: AppTheme.displayFamily,
                fontSize: phone ? 32 : 44,
                height: 1.12,
                letterSpacing: -0.8,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.todayHeroSubtitle,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _Introduction extends StatelessWidget {
  const _Introduction({required this.profile, required this.onOpen});
  final DiscoveryProfile profile;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    Widget fallback() => ColoredBox(
      color: colors.primaryContainer,
      child: Center(
        child: Icon(
          Icons.person_outline_rounded,
          size: 72,
          color: colors.primary,
        ),
      ),
    );
    return Semantics(
      container: true,
      child: TodayPanel(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: AspectRatio(
                aspectRatio: 1.15,
                child: profile.photoUrls.isEmpty
                    ? fallback()
                    : Image.network(
                        profile.photoUrls.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => fallback(),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.displayName,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontFamily: AppTheme.displayFamily,
                    ),
                  ),
                  if (profile.subtitle.trim().isNotEmpty)
                    Text(
                      profile.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  if (profile.quickBio.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        profile.quickBio,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (profile.reasons.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text(
                      l10n.todayCommonGround,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.primary,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final reason in profile.reasons.take(3))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.check_rounded,
                              color: colors.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                reason,
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                  if (profile.sharedActivities.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _firstHelloIdea(l10n, profile.sharedActivities.first),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: ValueKey('qa.today.profile.${profile.id}'),
                      onPressed: onOpen,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: Text(l10n.todayMeetName(profile.name)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _firstHelloIdea(AppLocalizations l10n, String a) => switch (a) {
    'coffee' => l10n.todayFirstHelloCoffee,
    'walk' => l10n.todayFirstHelloWalk,
    'meal' => l10n.todayFirstHelloMeal,
    'video_call' => l10n.todayFirstHelloVideoCall,
    'event' => l10n.todayFirstHelloEvent,
    'drinks' => l10n.todayFirstHelloDrinks,
    _ => l10n.todayFirstHelloOther,
  };
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.title,
    required this.body,
    required this.action,
    required this.onPressed,
  });
  final String title, body, action;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => TodayPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Text(body),
        const SizedBox(height: 16),
        OutlinedButton(onPressed: onPressed, child: Text(action)),
      ],
    ),
  );
}
