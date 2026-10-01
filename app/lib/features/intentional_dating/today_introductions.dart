import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/glass_widgets.dart';
import '../graduation/providers/graduation_provider.dart';
import '../swipe/models/discovery_profile.dart';
import '../swipe/providers/curated_daily_set_provider.dart';
import '../walls/today_wall_data.dart';
import 'dating_rhythm.dart';
import 'profile_stories.dart';
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
                          const TodaySectionHeader(label: 'YOUR PACE'),
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
                                          'What fits your week?',
                                          style: theme.textTheme.titleMedium,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Your pace, your kind of first date, '
                                          'optional availability.',
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
                                      label: const Text('Set your rhythm'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Divider(
                                  height: 24,
                                  color: colors.outlineVariant,
                                ),
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                  ),
                                  onPressed: () => openProfileStories(context),
                                  icon: const Icon(Icons.auto_stories_outlined),
                                  label: const Text(
                                    'Let your profile tell a little more of your '
                                    'story',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: TodayMetrics.sectionGap),
                          TodaySectionHeader(
                            label: 'TODAY’S INTRODUCTIONS',
                            title: showPicks
                                ? 'A few people to get to know'
                                : null,
                            caption: showPicks
                                ? 'Shared interests are a starting point. '
                                      'Chemistry is yours to discover.'
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
                              title: 'Take the time you need.',
                              body:
                                  'Introductions are paused. Your conversations are still here.',
                              action: 'Manage your rhythm',
                              onPressed: () => openDatingRhythm(context),
                            )
                          else if (loading)
                            const Padding(
                              padding: EdgeInsets.all(40),
                              child: Center(
                                child: CircularProgressIndicator(
                                  semanticsLabel: 'Loading introductions',
                                ),
                              ),
                            )
                          else if (failed)
                            _Notice(
                              title: 'Your introductions are taking a moment.',
                              body:
                                  'We couldn’t load the latest information. Please try again.',
                              action: 'Try again',
                              onPressed: refresh,
                            )
                          else if (daily.profiles.isEmpty)
                            _Notice(
                              title: 'A little breathing room.',
                              body:
                                  'There are no new introductions for your preferences right now. You can adjust your rhythm or explore profiles.',
                              action: 'Explore profiles',
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
                                      label: const Text('All introductions'),
                                      selected: selected == null,
                                      onSelected: (_) =>
                                          setState(() => activity = null),
                                    ),
                                    for (final a in activities)
                                      ChoiceChip(
                                        key: ValueKey('qa.today.activity.$a'),
                                        label: Text(datingActivities[a] ?? a),
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
                                    'A good connection has room to breathe.',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'These are today’s introductions. There is no countdown, and no need to decide on everyone.',
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: widget.onBrowse,
                                    child: const Text('Explore more profiles'),
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
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TODAY',
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
          tooltip: 'Refresh Today',
          onPressed: refreshing ? null : onRefresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
        if (onOpenFilters != null)
          IconButton(
            tooltip: 'Discovery preferences',
            onPressed: onOpenFilters,
            icon: const Icon(Icons.tune_rounded),
          ),
      ],
    );
  }
}

/// "Wednesday, 1 October" in the member's locale, falling back to English
/// when date symbols for that locale are not loaded.
String todayDateLabel(BuildContext context, DateTime date) {
  final locale = Localizations.maybeLocaleOf(context)?.toLanguageTag();
  try {
    return DateFormat('EEEE, d MMMM', locale).format(date);
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              'A little hello.\nRoom for something real.',
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
          'A few thoughtful introductions, at your pace.',
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
                      'A LITTLE COMMON GROUND',
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
                        'A first hello could be ${_activityLine(profile.sharedActivities.first)}.',
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
                      label: Text('Meet ${profile.name}'),
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

  String _activityLine(String a) => switch (a) {
    'coffee' => 'a coffee together',
    'walk' => 'a daytime walk',
    'meal' => 'a relaxed meal',
    'video_call' => 'a video hello',
    'event' => 'an event you both enjoy',
    'drinks' => 'a drink together',
    _ => 'something you both enjoy',
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
