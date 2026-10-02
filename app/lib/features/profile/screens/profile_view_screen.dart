import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_runtime_config.dart';
import '../../../core/providers/runtime_feature_flags_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/cinematic_motion.dart';
import '../../../core/widgets/connect_page.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../../common/screens/main_navigation_screen.dart';
import '../../intentional_dating/profile_stories.dart';
import '../../matching/screens/matches_list_screen.dart';
import '../../swipe/providers/liked_me_provider.dart';
import '../../swipe/providers/profile_details_provider.dart';
import '../../swipe/screens/liked_me_screen.dart';
import '../../swipe/screens/liked_profiles_screen.dart';
import '../models/profile_models.dart';
import '../providers/profile_provider.dart';
import '../widgets/cinematic_profile.dart';
import '../widgets/profile_scenes.dart';
import '../widgets/profile_showcase.dart';
import 'edit_profile_screen.dart';
import 'profile_viewers_screen.dart';
import 'setup/setup_photos_screen.dart';

/// The member's own profile (the Profile tab): the same cinematic title
/// sequence other members see ("this is how you appear"), with the owner's
/// tools on top (completeness, edit profile, photos, stories, viewers) and
/// the private numbers behind the scenes (likes, matches, messages, who
/// noticed, preferences).
///
/// The preview is the published profile other members are served
/// (`/profile/{id}`); until it exists (or if it cannot load) it is built
/// from the member's own account summary.
class ProfileViewScreen extends ConsumerStatefulWidget {
  const ProfileViewScreen({super.key, this.isActive = true});

  /// Whether the Profile tab is the one on screen. The tab stack keeps this
  /// screen alive; coming back to it starts again at the title sequence
  /// instead of wherever the member last scrolled to.
  final bool isActive;

  @override
  ConsumerState<ProfileViewScreen> createState() => _ProfileViewScreenState();
}

class _ProfileViewScreenState extends ConsumerState<ProfileViewScreen> {
  static const double _statCardGap = 12;
  static const double _statCardHeight = 132;

  final ScrollController _scroll = ScrollController();

  @override
  void didUpdateWidget(covariant ProfileViewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive && _scroll.hasClients) {
      _scroll.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  static List<String> _clean(List<String> urls) {
    final placeholder = AppRuntimeConfig.placeholderProfileImageUrl;
    return urls
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty && url != placeholder)
        .toList();
  }

  /// What other members see, falling back to the account summary for
  /// anything the published profile does not carry (or before it exists).
  static ProfileDetails _preview(User user, ProfileDetails? public) {
    String? pick(String? own, String? published) =>
        (own ?? '').trim().isNotEmpty ? own : published;
    return ProfileDetails(
      userId: user.id,
      name: user.name.trim().isNotEmpty ? user.name : (public?.name ?? ''),
      dateOfBirth: user.dateOfBirth,
      publicAge: public?.publicAge,
      gender: user.gender,
      bio: pick(user.bio, public?.bio),
      additionalInfo: public?.additionalInfo,
      heightCm: user.heightCm ?? public?.heightCm,
      education: pick(user.education, public?.education),
      profession: pick(user.profession, public?.profession),
      drinking: pick(user.drinking, public?.drinking),
      smoking: pick(user.smoking, public?.smoking),
      religion: pick(user.religion, public?.religion),
      motherTongue: public?.motherTongue,
      relationshipStatus: public?.relationshipStatus,
      personalityType: public?.personalityType,
      partyLover: public?.partyLover ?? false,
      country: public?.country,
      regionState: public?.regionState,
      city: public?.city,
      instagramHandle: public?.instagramHandle,
      hobbies: public?.hobbies ?? const <String>[],
      favoriteBooks: public?.favoriteBooks ?? const <String>[],
      favoriteNovels: public?.favoriteNovels ?? const <String>[],
      favoriteSongs: public?.favoriteSongs ?? const <String>[],
      extraCurriculars: public?.extraCurriculars ?? const <String>[],
      intentTags: public?.intentTags ?? const <String>[],
      languageTags: public?.languageTags ?? const <String>[],
      isVerified:
          user.isVerified ||
          user.verificationBadge ||
          (public?.isVerified ?? false),
      photoUrls: public?.photoUrls ?? const <String>[],
      petPreference: public?.petPreference,
      dietPreference: public?.dietPreference,
      workoutFrequency: public?.workoutFrequency,
      dietType: public?.dietType,
      sleepSchedule: public?.sleepSchedule,
      travelStyle: public?.travelStyle,
      politicalComfortRange: public?.politicalComfortRange,
      hookupOnly: public?.hookupOnly,
      dealBreakerTags: public?.dealBreakerTags ?? const <String>[],
    );
  }

  void _refresh(String? userId) {
    ref.read(profileNotifierProvider.notifier).refresh();
    if (userId != null) {
      ref.invalidate(profileDetailsProvider(userId));
    }
  }

  /// Opens an owner tool, then refreshes the preview so edits show at once.
  Future<void> _openTool(Widget screen, String? userId) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => screen));
    if (mounted) {
      _refresh(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileNotifierProvider);
    final likedMeCount = ref.watch(likedMeProvider.select((s) => s.count));
    final authId = ref.watch(authNotifierProvider.select((s) => s.userId));
    final l10n = AppLocalizations.of(context);
    final bottomClearance = MediaQuery.paddingOf(context).bottom + 104;
    // The stat tiles grow with large text instead of clipping their label.
    final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
    final statHeight =
        _statCardHeight * (1 + (textScale - 1).clamp(0.0, 2.0) * 0.4);

    final colors = Theme.of(context).colorScheme;
    final user = profileState.user;
    final prefs = profileState.preferences;
    final userId = user?.id ?? authId;
    final public = userId == null
        ? null
        : ref.watch(profileDetailsProvider(userId)).valueOrNull;
    final preview = user == null ? null : _preview(user, public);
    final photos = _clean(public?.photoUrls ?? const <String>[]);
    final storiesOn =
        ref
            .watch(runtimeFeatureFlagsProvider)
            .valueOrNull
            ?.enabled('intentional_dating_enabled', fallback: false) ==
        true;
    final headline = preview == null
        ? ProfileHeadline(
            userId: userId ?? '',
            name: l10n.memberProfileMine,
            photos: const <String>[],
          )
        : profileHeadlineFrom(preview, photos: photos);

    Future<void> openViewers() =>
        _openTool(const ProfileViewersScreen(), userId);
    Future<int?> openGallery(int index) => openProfileGallery(
      context,
      userId: headline.userId,
      name: headline.name,
      photos: photos,
      initialIndex: index,
    );

    Widget statusCard({
      required IconData icon,
      required String message,
      Widget? action,
    }) => ConnectPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: colors.onSurfaceVariant, size: 40),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
          if (action != null) ...[const SizedBox(height: 16), action],
        ],
      ),
    );

    return Scaffold(
      body: PostLoginBackdrop(
        maxContentWidth: null,
        child: LayoutBuilder(
          builder: (context, box) {
            final photoHeight = profileHeroPhotoHeight(
              width: box.maxWidth,
              viewportHeight: box.maxHeight,
            );
            return Stack(
              fit: StackFit.expand,
              children: [
                CustomScrollView(
                  controller: _scroll,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(
                      child: CinematicProfileHero(
                        headline: headline,
                        eyebrow: l10n.memberProfileStarring,
                        photoHeight: photoHeight,
                        onOpenPhoto: preview == null
                            ? null
                            : () => openGallery(0),
                        footer: profileState.isLoading && user == null
                            ? SizedBox.square(
                                dimension: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    colors.primary,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: ProfileContentColumn(
                        child: Padding(
                          padding: const EdgeInsets.only(
                            top: ConnectMetrics.sectionGap,
                          ),
                          child: _OwnerConsole(
                            completion: user?.profileCompletion,
                            storiesOn: storiesOn,
                            onEdit: () =>
                                _openTool(const EditProfileScreen(), userId),
                            onPhotos: () =>
                                _openTool(const SetupPhotosScreen(), userId),
                            onStories: () async {
                              await openProfileStories(context);
                              if (mounted && userId != null) {
                                ref.invalidate(profileStoriesProvider(userId));
                              }
                            },
                            onViewers: openViewers,
                          ),
                        ),
                      ),
                    ),
                    if (photos.length > 1)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(
                            top: ConnectMetrics.sectionGap,
                          ),
                          child: ProfilePhotoReel(
                            userId: headline.userId,
                            name: headline.name,
                            photos: photos,
                            onOpen: openGallery,
                          ),
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: ProfileContentColumn(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (preview != null)
                              ProfileScenes(
                                details: preview,
                                showStories: storiesOn,
                                afterStories: userId == null
                                    ? null
                                    : ProfileShowcaseScene(
                                        userId: userId,
                                        isOwner: true,
                                      ),
                              )
                            else if (!profileState.isLoading) ...[
                              const SizedBox(height: ConnectMetrics.sectionGap),
                              if (profileState.error != null)
                                statusCard(
                                  icon: Icons.error_outline_rounded,
                                  message: _errorMessage(l10n, profileState),
                                  action: GlassButton(
                                    label: l10n.commonRetry,
                                    onPressed: () => _refresh(userId),
                                  ),
                                )
                              else
                                statusCard(
                                  icon: Icons.person_outline_rounded,
                                  message: l10n.memberProfileNoData,
                                ),
                            ],
                            const SizedBox(height: ConnectMetrics.sectionGap),
                            _BehindTheScenes(
                              title: l10n.memberProfileBehindTheScenes,
                              caption: l10n.memberProfileOnlyYou,
                            ),
                            const SizedBox(height: ConnectMetrics.sectionGap),
                            ConnectSectionHeader(
                              label: l10n.memberProfileConnectionsTitle
                                  .toUpperCase(),
                              caption: l10n.memberProfileConnectionsCaption,
                            ),
                            const SizedBox(height: ConnectMetrics.cardGap),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: statHeight,
                                    child: _buildStatCard(
                                      context,
                                      icon: Icons.favorite_rounded,
                                      tint: colors.secondary,
                                      value: '${profileState.likesCount}',
                                      label: l10n.memberProfileStatLiked,
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) =>
                                                const LikedProfilesScreen(),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: _statCardGap),
                                Expanded(
                                  child: SizedBox(
                                    height: statHeight,
                                    child: _buildStatCard(
                                      context,
                                      icon: Icons.done_rounded,
                                      tint: colors.primary,
                                      value: '${profileState.matchesCount}',
                                      label: l10n.memberProfileStatMatches,
                                      onTap: () =>
                                          _openMatchesTab(MatchesView.people),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: _statCardGap),
                                Expanded(
                                  child: SizedBox(
                                    height: statHeight,
                                    child: _buildStatCard(
                                      context,
                                      icon: Icons.chat_bubble_outline_rounded,
                                      tint: colors.tertiary,
                                      value: '${profileState.messagesCount}',
                                      label: l10n.memberProfileStatMessages,
                                      onTap: () => _openMatchesTab(
                                        MatchesView.conversations,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: ConnectMetrics.sectionGap),
                            ConnectSectionHeader(
                              label: l10n.memberProfileNoticedTitle
                                  .toUpperCase(),
                              caption: l10n.memberProfileNoticedCaption,
                            ),
                            const SizedBox(height: ConnectMetrics.cardGap),
                            ConnectNavTile(
                              key: const ValueKey('qa.profile.who_liked_me'),
                              icon: Icons.favorite_border_rounded,
                              tint: colors.secondary,
                              title: likedMeCount > 0
                                  ? l10n.memberProfileWhoLikedMeCount(
                                      likedMeCount,
                                    )
                                  : l10n.memberProfileWhoLikedMe,
                              subtitle: l10n.memberProfileWhoLikedMeSubtitle,
                              onTap: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const LikedMeScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: ConnectMetrics.cardGap),
                            ConnectNavTile(
                              icon: Icons.remove_red_eye_outlined,
                              title: l10n.memberProfileWhoViewedTitle,
                              subtitle: l10n.memberProfileWhoViewedSubtitle,
                              onTap: openViewers,
                            ),
                            if (user != null) ...[
                              const SizedBox(height: ConnectMetrics.sectionGap),
                              ConnectSectionHeader(
                                label: l10n.memberProfilePreferencesTitle
                                    .toUpperCase(),
                              ),
                              const SizedBox(height: ConnectMetrics.cardGap),
                              ConnectPanel(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildProfileRow(
                                      context,
                                      l10n.memberProfilePrefSeeking,
                                      prefs == null
                                          ? '—'
                                          : prefs.seekingGenders.join(', '),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildProfileRow(
                                      context,
                                      l10n.filterAgeRange,
                                      prefs == null
                                          ? '—'
                                          : '${prefs.minAgeYears}-'
                                                '${prefs.maxAgeYears}',
                                    ),
                                    const SizedBox(height: 12),
                                    _buildProfileRow(
                                      context,
                                      l10n.memberProfilePrefDistance,
                                      prefs == null
                                          ? '—'
                                          : l10n.memberProfileWithinKm(
                                              prefs.maxDistanceKm,
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            SizedBox(height: bottomClearance),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: ProfileTopBar(
                    controller: _scroll,
                    collapseAt: photoHeight,
                    title: headline.name,
                    actions: [
                      ProfileBarButton(
                        icon: Icons.remove_red_eye_outlined,
                        tooltip: l10n.memberProfileWhoViewedTooltip,
                        onPressed: openViewers,
                      ),
                      ProfileBarButton(
                        icon: Icons.refresh_rounded,
                        tooltip: l10n.memberProfileRefreshTooltip,
                        onPressed: () => _refresh(userId),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// The load error in the member's language; a message from the server is
  /// shown as sent.
  static String _errorMessage(AppLocalizations l10n, ProfileState state) =>
      switch (state.issue) {
        ProfileLoadIssue.notSignedIn => l10n.memberProfileSignInToView,
        ProfileLoadIssue.noProfile => l10n.memberProfileNoData,
        ProfileLoadIssue.loadFailed => l10n.memberProfileLoadFailed,
        ProfileLoadIssue.server || null => state.error ?? '',
      };

  /// Matches and conversations live on the Matches tab, so these tiles switch
  /// tabs instead of pushing a duplicate screen. The sub-view is set first so
  /// the tab opens on the right list.
  void _openMatchesTab(MatchesView view) {
    ref.read(matchesViewProvider.notifier).state = view;
    ref.read(mainNavigationIndexProvider.notifier).state = 1;
  }

  Widget _buildProfileRow(BuildContext context, String label, String value) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      );

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required Color tint,
    required String value,
    required String label,
    VoidCallback? onTap,
  }) => Semantics(
    button: onTap != null,
    label: onTap == null
        ? null
        : AppLocalizations.of(context).memberProfileOpenStat(label),
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: GlassContainer(
        // Tighter vertically on a narrow viewport: three tiles across a 320pt
        // phone leave roughly 90pt each, which is not enough for generous
        // padding plus an icon plus two lines of wrapped text. The tile has a
        // fixed height and centres its content, so padding only sets the
        // overflow margin, not the look.
        padding: EdgeInsets.symmetric(
          vertical: MediaQuery.sizeOf(context).width < 380 ? 8 : 12,
          horizontal: 8,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: tint,
                size: MediaQuery.sizeOf(context).width < 380 ? 22 : 28,
              ),
              SizedBox(height: MediaQuery.sizeOf(context).width < 380 ? 4 : 8),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontFamily: AppTheme.displayFamily,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: MediaQuery.sizeOf(context).width < 380 ? 2 : 4),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// The owner's director's chair: how complete the profile is, and the
/// tools that change what members see.
class _OwnerConsole extends StatelessWidget {
  const _OwnerConsole({
    required this.completion,
    required this.storiesOn,
    required this.onEdit,
    required this.onPhotos,
    required this.onStories,
    required this.onViewers,
  });

  /// 0–100, or null while the account is loading.
  final int? completion;
  final bool storiesOn;
  final VoidCallback onEdit;
  final VoidCallback onPhotos;
  final VoidCallback onStories;
  final VoidCallback onViewers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final percent = completion?.clamp(0, 100);
    final still = CinematicLevel.of(context) == CinematicLevel.still;
    final tools = <(Key, IconData, String, VoidCallback)>[
      (
        const ValueKey('qa.profile.tool.edit'),
        Icons.edit_outlined,
        l10n.memberProfileToolEdit,
        onEdit,
      ),
      (
        const ValueKey('qa.profile.tool.photos'),
        Icons.photo_library_outlined,
        l10n.memberProfileToolPhotos,
        onPhotos,
      ),
      if (storiesOn)
        (
          const ValueKey('qa.profile.tool.stories'),
          Icons.auto_stories_outlined,
          l10n.memberProfileToolStories,
          onStories,
        ),
      (
        const ValueKey('qa.profile.tool.viewers'),
        Icons.visibility_outlined,
        l10n.memberProfileToolViewers,
        onViewers,
      ),
    ];
    return ConnectPanel(
      key: const ValueKey('qa.profile.owner_console'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.memberProfileOwnerTitle.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.memberProfileOwnerCaption,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          if (percent != null) ...[
            const SizedBox(height: 16),
            Semantics(
              label: l10n.memberProfileCompleteness(percent),
              value: '$percent%',
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.memberProfileCompleteness(percent),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                        Text(
                          '$percent%',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontFamily: AppTheme.displayFamily,
                            color: scheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: percent / 100),
                      duration: still
                          ? Duration.zero
                          : const Duration(milliseconds: 900),
                      curve: CinematicMotion.settle,
                      builder: (context, value, _) => ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: value,
                          minHeight: 8,
                          color: scheme.primary,
                          backgroundColor: scheme.surfaceContainerHighest,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      percent >= 100
                          ? l10n.memberProfileCompletenessDone
                          : l10n.memberProfileCompletenessHint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, box) {
              const gap = 8.0;
              final tileWidth = (box.maxWidth - gap) / 2;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final (key, icon, label, onTap) in tools)
                    SizedBox(
                      width: tileWidth,
                      child: OutlinedButton.icon(
                        key: key,
                        onPressed: onTap,
                        icon: Icon(icon, size: 20),
                        label: Text(label, textAlign: TextAlign.center),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 52),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          foregroundColor: scheme.onSurface,
                          iconColor: scheme.primary,
                          side: BorderSide(color: scheme.outlineVariant),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// A divider into the owner-only part of the page.
class _BehindTheScenes extends StatelessWidget {
  const _BehindTheScenes({required this.title, required this.caption});

  final String title;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(color: scheme.outlineVariant, height: 1),
        const SizedBox(height: ConnectMetrics.sectionGap),
        Row(
          children: [
            Icon(Icons.lock_outline_rounded, size: 18, color: scheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontFamily: AppTheme.displayFamily,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          caption,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
