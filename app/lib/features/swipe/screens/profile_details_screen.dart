import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_runtime_config.dart';
import '../../../core/providers/runtime_feature_flags_provider.dart';
import '../../../core/providers/safety_actions_provider.dart';
import '../../../core/theme/cinematic_motion.dart';
import '../../../core/widgets/connect_page.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/widgets/profile_showcase.dart';
import '../../common/screens/moderation_appeals_screen.dart';
import '../../common/widgets/report_user_sheet.dart';
import '../../friends/friend_actions.dart';
import '../../profile/widgets/cinematic_profile.dart';
import '../../profile/widgets/profile_scenes.dart';
import '../models/discovery_profile.dart';
import '../providers/profile_details_provider.dart';

enum ProfileDetailsAction { none, love, message }

/// Another member's profile, as a title sequence: the main photo full-bleed
/// with their name over its dissolve, a film strip of the other photos, then
/// titled scenes (about, stories, interests, basics, lifestyle, trust), with
/// Message and Love in a floating dock.
///
/// The hero shows straight away from the card that was tapped; the scenes
/// and the dock arrive with the full profile. Closing returns the chosen
/// [ProfileDetailsAction] to the screen that opened it.
class ProfileDetailsScreen extends ConsumerStatefulWidget {
  const ProfileDetailsScreen({required this.profile, super.key});
  final DiscoveryProfile profile;

  @override
  ConsumerState<ProfileDetailsScreen> createState() =>
      _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends ConsumerState<ProfileDetailsScreen> {
  final ScrollController _scroll = ScrollController();
  bool _precached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precached) {
      return;
    }
    _precached = true;
    // Warm the hero so the title card opens on the photo, not on a fade.
    final first = _clean(widget.profile.photoUrls);
    if (first.isNotEmpty) {
      precacheImage(NetworkImage(first.first), context, onError: (_, _) {});
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Real photos only: the stock placeholder the API substitutes for an
  /// empty gallery is not this person, so it never stands in for them.
  static List<String> _clean(List<String> urls) {
    final placeholder = AppRuntimeConfig.placeholderProfileImageUrl;
    return urls
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty && url != placeholder)
        .toList();
  }

  List<String> _photosFor(ProfileDetails? details) {
    final fromDetails = details == null
        ? const <String>[]
        : _clean(details.photoUrls);
    return fromDetails.isNotEmpty
        ? fromDetails
        : _clean(widget.profile.photoUrls);
  }

  ProfileHeadline _headline(
    ProfileDetails? details,
    List<String> photos,
    AppLocalizations l10n,
  ) {
    final p = widget.profile;
    final badges = <String>[
      if (p.isSpotlight) l10n.memberProfileSpotlight,
      if (p.availabilityOverlaps) l10n.memberProfileFreeWhenYouAre,
      ...p.reasons.take(2),
    ];
    if (details != null) {
      return profileHeadlineFrom(
        details,
        photos: photos,
        logline: p.why,
        badges: badges,
      );
    }
    return ProfileHeadline(
      userId: p.id,
      name: p.name,
      age: p.age,
      profession: (p.profession ?? '').trim().isNotEmpty
          ? p.profession
          : p.education,
      isVerified: p.isVerified,
      photos: photos,
      logline: p.why,
      badges: badges,
    );
  }

  Future<void> _report(String userId) async {
    // The report id may legitimately be null, so it cannot tell a sent
    // report from a dismissed sheet; only confirm what was actually sent.
    var submitted = false;
    final reportId = await showReportUserSheet(
      context: context,
      onSubmit: ({required reason, description}) async {
        final id = await ref
            .read(safetyActionsProvider)
            .reportUser(
              reportedUserId: userId,
              reason: reason,
              description: description,
            );
        submitted = true;
        return id;
      },
    );
    if (!mounted || !submitted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Report submitted.'),
        action: SnackBarAction(
          label: 'Appeal',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ModerationAppealsScreen(
                  initialReason:
                      'Review moderation outcome for report on user $userId',
                  initialReportId: reportId,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final detailsAsync = ref.watch(profileDetailsProvider(widget.profile.id));
    final details = detailsAsync.valueOrNull;
    final photos = _photosFor(details);
    final headline = _headline(details, photos, l10n);
    final storiesOn =
        ref
            .watch(runtimeFeatureFlagsProvider)
            .valueOrNull
            ?.enabled('intentional_dating_enabled', fallback: false) ==
        true;
    final me = ref.watch(authNotifierProvider.select((s) => s.userId));
    final loaded = detailsAsync.hasValue && !detailsAsync.hasError;
    // Room under the scenes for the floating dock (taller when its two
    // buttons stack for very large text).
    final bigText = MediaQuery.textScalerOf(context).scale(16) / 16 >= 1.6;
    final dockClearance =
        MediaQuery.paddingOf(context).bottom + (bigText ? 220 : 128);

    Future<int?> openGallery(int index) => openProfileGallery(
      context,
      userId: headline.userId,
      name: headline.name,
      photos: photos,
      initialIndex: index,
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
            final heroKey = photos.length > 1
                ? 'qa.profile_detail.thumbnail_0'
                : 'qa.profile_detail.carousel';
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
                        eyebrow: l10n.memberProfileIntroducing,
                        photoHeight: photoHeight,
                        photoKey: ValueKey<String>(heroKey),
                        photoSemanticsLabel: heroKey,
                        onOpenPhoto: () => openGallery(0),
                        footer: detailsAsync.isLoading && details == null
                            ? const _SceneLoader()
                            : null,
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
                            carouselKey: const ValueKey(
                              'qa.profile_detail.carousel',
                            ),
                            carouselSemanticsLabel:
                                'qa.profile_detail.carousel',
                            frameKeyPrefix: 'qa.profile_detail.thumbnail_',
                          ),
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: ProfileContentColumn(
                        child: switch (detailsAsync) {
                          // valueOrNull: `value` rethrows in the error state.
                          AsyncValue(valueOrNull: final value?) when loaded =>
                            ProfileScenes(
                              details: value,
                              showStories: storiesOn,
                              inCommon: widget.profile.sharedActivities,
                              readMoreKey: const ValueKey(
                                'qa.profile_detail.read_more_button',
                              ),
                              // Their public chapters and wall photos, only
                              // with their consent (server-enforced).
                              afterStories: ProfileShowcaseScene(
                                userId: widget.profile.id,
                              ),
                            ),
                          AsyncValue(hasError: true) => _UnavailablePanel(
                            onRetry: () => ref.invalidate(
                              profileDetailsProvider(widget.profile.id),
                            ),
                            onBack: () => Navigator.of(context).maybePop(),
                          ),
                          _ => const SizedBox.shrink(),
                        },
                      ),
                    ),
                    SliverToBoxAdapter(child: SizedBox(height: dockClearance)),
                  ],
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: ProfileTopBar(
                    controller: _scroll,
                    collapseAt: photoHeight,
                    title: headline.displayName,
                    leading: ProfileBarButton(
                      buttonKey: const ValueKey(
                        'qa.profile_detail.back_button',
                      ),
                      semanticsLabel: 'qa.profile_detail.back_button',
                      icon: Icons.arrow_back_rounded,
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).backButtonTooltip,
                      onPressed: () =>
                          Navigator.of(context).pop(ProfileDetailsAction.none),
                    ),
                    actions: [
                      if (headline.userId.isNotEmpty && headline.userId != me)
                        ProfileBarDisc(
                          child: AddFriendButton(
                            userId: headline.userId,
                            name: headline.name,
                            source: FriendRequestSource.profile,
                            style: AddFriendStyle.icon,
                          ),
                        ),
                      ProfileBarButton(
                        buttonKey: const ValueKey(
                          'qa.profile_detail.report_button',
                        ),
                        semanticsLabel: 'qa.profile_detail.report_button',
                        icon: Icons.flag_outlined,
                        tooltip: l10n.memberProfileReport,
                        onPressed: () =>
                            _report(details?.userId ?? widget.profile.id),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _ActionDock(
                    visible: loaded,
                    messageLabel: l10n.memberProfileMessage,
                    loveLabel: l10n.memberProfileLove,
                    onMessage: () =>
                        Navigator.of(context).pop(ProfileDetailsAction.message),
                    onLove: () =>
                        Navigator.of(context).pop(ProfileDetailsAction.love),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SceneLoader extends StatelessWidget {
  const _SceneLoader();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: SizedBox.square(
      dimension: 24,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
          Theme.of(context).colorScheme.primary,
        ),
      ),
    ),
  );
}

class _UnavailablePanel extends StatelessWidget {
  const _UnavailablePanel({required this.onRetry, required this.onBack});

  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: ConnectMetrics.sectionGap),
      child: ConnectPanel(
        child: Column(
          children: [
            Icon(
              Icons.visibility_off_outlined,
              size: 32,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'This profile is unavailable right now.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                TextButton(onPressed: onRetry, child: const Text('Retry')),
                TextButton(onPressed: onBack, child: const Text('Go back')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Message and Love in a floating pill above the safe area. It rises in
/// once the profile has loaded (instantly under reduced motion).
class _ActionDock extends StatelessWidget {
  const _ActionDock({
    required this.visible,
    required this.messageLabel,
    required this.loveLabel,
    required this.onMessage,
    required this.onLove,
  });

  final bool visible;
  final String messageLabel;
  final String loveLabel;
  final VoidCallback onMessage;
  final VoidCallback onLove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final still = CinematicLevel.of(context) == CinematicLevel.still;
    final duration = still ? Duration.zero : const Duration(milliseconds: 480);
    // On the narrowest phones the labels need the icons' room.
    final narrow = MediaQuery.sizeOf(context).width < 360;
    final message = Semantics(
      label: 'qa.profile_detail.message_button',
      button: true,
      child: GlassButton(
        key: const ValueKey('qa.profile_detail.message_button'),
        label: messageLabel,
        icon: narrow ? null : Icons.chat_bubble_outline_rounded,
        backgroundColor: scheme.secondaryContainer,
        textColor: scheme.onSecondaryContainer,
        onPressed: onMessage,
      ),
    );
    final love = Semantics(
      label: 'qa.profile_detail.love_button',
      button: true,
      child: GlassButton(
        key: const ValueKey('qa.profile_detail.love_button'),
        label: loveLabel,
        icon: narrow ? null : Icons.favorite_rounded,
        onPressed: onLove,
      ),
    );
    return IgnorePointer(
      ignoring: !visible,
      child: ExcludeSemantics(
        excluding: !visible,
        child: AnimatedSlide(
          offset: visible ? Offset.zero : const Offset(0, 1.4),
          duration: duration,
          curve: CinematicMotion.settle,
          child: AnimatedOpacity(
            opacity: visible ? 1 : 0,
            duration: duration,
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.only(bottom: 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.surface.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(color: scheme.outlineVariant),
                        boxShadow: [
                          BoxShadow(
                            color: scheme.shadow.withValues(alpha: 0.16),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: LayoutBuilder(
                          builder: (context, box) {
                            // Very large text on a narrow phone: stack the
                            // two so neither label is cut short.
                            final scale =
                                MediaQuery.textScalerOf(context).scale(16) / 16;
                            if (scale >= 1.6 && box.maxWidth < 400) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  message,
                                  const SizedBox(height: 8),
                                  love,
                                ],
                              );
                            }
                            return Row(
                              children: [
                                Expanded(child: message),
                                const SizedBox(width: 8),
                                Expanded(child: love),
                              ],
                            );
                          },
                        ),
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
