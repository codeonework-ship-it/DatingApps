import '../../blog/blog_screen.dart';
import '../../intentional_dating/profile_stories.dart';
import '../../../core/providers/runtime_feature_flags_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_runtime_config.dart';
import '../../../core/providers/safety_actions_provider.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../common/screens/moderation_appeals_screen.dart';
import '../../common/widgets/report_user_sheet.dart';
import '../../friends/friend_actions.dart';
import '../../friends/providers/friend_social_provider.dart';
import '../models/discovery_profile.dart';
import '../providers/profile_details_provider.dart';

enum ProfileDetailsAction { none, love, message }

class ProfileDetailsScreen extends ConsumerStatefulWidget {
  const ProfileDetailsScreen({required this.profile, super.key});
  final DiscoveryProfile profile;

  @override
  ConsumerState<ProfileDetailsScreen> createState() =>
      _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends ConsumerState<ProfileDetailsScreen> {
  var _expandedBio = false;
  final PageController _photoPageController = PageController();
  final ScrollController _profileScrollController = ScrollController();
  int _selectedPhotoIndex = 0;
  double _profileScrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _profileScrollController.addListener(() {
      if (!mounted) {
        return;
      }
      setState(() {
        _profileScrollOffset = _profileScrollController.offset;
      });
    });
  }

  @override
  void dispose() {
    _photoPageController.dispose();
    _profileScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailsAsync = ref.watch(profileDetailsProvider(widget.profile.id));
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          child: detailsAsync.when(
            loading: () => Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
              ),
            ),
            error: (_, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'This profile is unavailable right now.',
                    style: TextStyle(color: scheme.onSurface),
                  ),
                  TextButton(
                    onPressed: () => ref.invalidate(
                      profileDetailsProvider(widget.profile.id),
                    ),
                    child: const Text('Retry'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: const Text('Go back'),
                  ),
                ],
              ),
            ),
            data: (d) {
              final galleryPhotos = d.photoUrls.isEmpty
                  ? widget.profile.photoUrls
                  : d.photoUrls;
              final safeGalleryPhotos = galleryPhotos.isEmpty
                  ? <String>[AppRuntimeConfig.placeholderProfileImageUrl]
                  : galleryPhotos;
              if (_selectedPhotoIndex >= safeGalleryPhotos.length) {
                _selectedPhotoIndex = 0;
              }

              return Column(
                children: [
                  Expanded(
                    child: CustomScrollView(
                      controller: _profileScrollController,
                      slivers: [
                        SliverAppBar(
                          pinned: true,
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          leading: Semantics(
                            label: 'qa.profile_detail.back_button',
                            button: true,
                            child: IconButton(
                              key: const ValueKey(
                                'qa.profile_detail.back_button',
                              ),
                              icon: Icon(
                                Icons.arrow_back,
                                color: scheme.onSurface,
                              ),
                              onPressed: () => Navigator.of(
                                context,
                              ).pop(ProfileDetailsAction.none),
                            ),
                          ),
                          title: Text(
                            d.displayName,
                            style: TextStyle(color: scheme.onSurface),
                          ),
                          actions: [
                            AddFriendButton(
                              userId: d.userId,
                              name: d.name,
                              source: FriendRequestSource.profile,
                              style: AddFriendStyle.icon,
                            ),
                            Semantics(
                              label: 'qa.profile_detail.report_button',
                              button: true,
                              child: IconButton(
                                key: const ValueKey(
                                  'qa.profile_detail.report_button',
                                ),
                                icon: Icon(
                                  Icons.report,
                                  color: scheme.onSurface,
                                ),
                                onPressed: () async {
                                  final reportId = await showReportUserSheet(
                                    context: context,
                                    onSubmit:
                                        ({
                                          required reason,
                                          description,
                                        }) async => ref
                                            .read(safetyActionsProvider)
                                            .reportUser(
                                              reportedUserId: d.userId,
                                              reason: reason,
                                              description: description,
                                            ),
                                  );
                                  if (!context.mounted) {
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
                                              builder: (_) =>
                                                  ModerationAppealsScreen(
                                                    initialReason:
                                                        'Review moderation outcome for report on user ${d.userId}',
                                                    initialReportId: reportId,
                                                  ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Builder(
                              builder: (context) {
                                final progress = (_profileScrollOffset / 260)
                                    .clamp(0.0, 1.0);
                                final eased = Curves.easeInOutCubicEmphasized
                                    .transform(progress);
                                final tilt = eased * 0.28;
                                final yaw =
                                    0.06 *
                                    (1 - (progress - 0.5).abs() * 2).clamp(
                                      0.0,
                                      1.0,
                                    );
                                final scale = 1 - (eased * 0.16);
                                final lift = eased * 22;

                                return Transform(
                                  alignment: Alignment.topCenter,
                                  transform: Matrix4.identity()
                                    ..setEntry(3, 2, 0.0022)
                                    ..translate(0.0, -lift, -28 * eased)
                                    ..rotateX(-tilt)
                                    ..rotateY(yaw)
                                    ..scale(scale, scale),
                                  child: GlassContainer(
                                    padding: EdgeInsets.zero,
                                    backgroundColor: scheme.surface,
                                    blur: 10,
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(24),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          height: 404,
                                          child: Column(
                                            children: [
                                              Expanded(
                                                child: Stack(
                                                  children: [
                                                    Semantics(
                                                      label:
                                                          'qa.profile_detail.carousel',
                                                      child: PageView.builder(
                                                        key: const ValueKey(
                                                          'qa.profile_detail.carousel',
                                                        ),
                                                        controller:
                                                            _photoPageController,
                                                        onPageChanged: (index) {
                                                          if (!mounted) {
                                                            return;
                                                          }
                                                          setState(
                                                            () =>
                                                                _selectedPhotoIndex =
                                                                    index,
                                                          );
                                                        },
                                                        itemCount:
                                                            safeGalleryPhotos
                                                                .length,
                                                        itemBuilder: (context, index) {
                                                          final url =
                                                              safeGalleryPhotos[index];
                                                          return ClipRRect(
                                                            borderRadius:
                                                                const BorderRadius.vertical(
                                                                  top:
                                                                      Radius.circular(
                                                                        24,
                                                                      ),
                                                                ),
                                                            child: Stack(
                                                              fit: StackFit
                                                                  .expand,
                                                              children: [
                                                                Image.network(
                                                                  url,
                                                                  fit: BoxFit
                                                                      .cover,
                                                                  width: double
                                                                      .infinity,
                                                                  errorBuilder: (context, _, _) => Container(
                                                                    color: scheme
                                                                        .surfaceContainerHighest,
                                                                    child: Center(
                                                                      child: Icon(
                                                                        Icons
                                                                            .image,
                                                                        size:
                                                                            48,
                                                                        color: scheme
                                                                            .onSurfaceVariant,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                Positioned.fill(
                                                                  child: DecoratedBox(
                                                                    decoration: BoxDecoration(
                                                                      gradient: LinearGradient(
                                                                        begin: Alignment
                                                                            .topCenter,
                                                                        end: Alignment
                                                                            .bottomCenter,
                                                                        colors: [
                                                                          Colors.black.withValues(
                                                                            alpha:
                                                                                0.04,
                                                                          ),
                                                                          Colors.black.withValues(
                                                                            alpha:
                                                                                0.34,
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                    Positioned(
                                                      top: 12,
                                                      right: 12,
                                                      child: GlassContainer(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 12,
                                                              vertical: 8,
                                                            ),
                                                        backgroundColor: Colors
                                                            .white
                                                            .withValues(
                                                              alpha: 0.26,
                                                            ),
                                                        blur: 10,
                                                        child: Text(
                                                          '${_selectedPhotoIndex + 1}/${safeGalleryPhotos.length}',
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (safeGalleryPhotos.length > 1)
                                                Container(
                                                  height: 88,
                                                  width: double.infinity,
                                                  padding:
                                                      const EdgeInsets.fromLTRB(
                                                        16,
                                                        12,
                                                        16,
                                                        12,
                                                      ),
                                                  color: scheme
                                                      .surfaceContainerLow,
                                                  child: ListView.separated(
                                                    scrollDirection:
                                                        Axis.horizontal,
                                                    itemCount: safeGalleryPhotos
                                                        .length,
                                                    separatorBuilder: (_, _) =>
                                                        const SizedBox(
                                                          width: 10,
                                                        ),
                                                    itemBuilder: (context, index) {
                                                      final isSelected =
                                                          _selectedPhotoIndex ==
                                                          index;
                                                      return Semantics(
                                                        label:
                                                            'qa.profile_detail.thumbnail_$index',
                                                        button: true,
                                                        selected: isSelected,
                                                        child: GestureDetector(
                                                          key: ValueKey<String>(
                                                            'qa.profile_detail.thumbnail_$index',
                                                          ),
                                                          onTap: () {
                                                            _photoPageController
                                                                .animateToPage(
                                                                  index,
                                                                  duration:
                                                                      const Duration(
                                                                        milliseconds:
                                                                            220,
                                                                      ),
                                                                  curve: Curves
                                                                      .easeOut,
                                                                );
                                                            setState(
                                                              () =>
                                                                  _selectedPhotoIndex =
                                                                      index,
                                                            );
                                                          },
                                                          child: AnimatedContainer(
                                                            duration:
                                                                const Duration(
                                                                  milliseconds:
                                                                      180,
                                                                ),
                                                            width: isSelected
                                                                ? 72
                                                                : 58,
                                                            transform:
                                                                Matrix4.identity()
                                                                  ..translate(
                                                                    0.0,
                                                                    isSelected
                                                                        ? -3.0
                                                                        : 0.0,
                                                                  ),
                                                            decoration: BoxDecoration(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    14,
                                                                  ),
                                                              border: Border.all(
                                                                color:
                                                                    isSelected
                                                                    ? scheme
                                                                          .primary
                                                                    : scheme
                                                                          .outlineVariant,
                                                                width:
                                                                    isSelected
                                                                    ? 2.2
                                                                    : 1.4,
                                                              ),
                                                              boxShadow: [
                                                                BoxShadow(
                                                                  color: Colors
                                                                      .black
                                                                      .withValues(
                                                                        alpha:
                                                                            isSelected
                                                                            ? 0.22
                                                                            : 0.12,
                                                                      ),
                                                                  blurRadius:
                                                                      isSelected
                                                                      ? 10
                                                                      : 7,
                                                                  offset:
                                                                      const Offset(
                                                                        0,
                                                                        3,
                                                                      ),
                                                                ),
                                                              ],
                                                            ),
                                                            clipBehavior:
                                                                Clip.antiAlias,
                                                            child: Image.network(
                                                              safeGalleryPhotos[index],
                                                              fit: BoxFit.cover,
                                                              errorBuilder:
                                                                  (
                                                                    context,
                                                                    _,
                                                                    _,
                                                                  ) => Container(
                                                                    color: scheme
                                                                        .surfaceContainerHighest,
                                                                    child: Icon(
                                                                      Icons
                                                                          .image,
                                                                      size: 22,
                                                                      color: scheme
                                                                          .onSurfaceVariant,
                                                                    ),
                                                                  ),
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      d.name,
                                                      style: Theme.of(
                                                        context,
                                                      ).textTheme.headlineSmall,
                                                    ),
                                                  ),
                                                  if (d.isVerified)
                                                    const Icon(
                                                      Icons.verified,
                                                      color: Colors.blue,
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              if ((d.bio ?? '')
                                                  .trim()
                                                  .isNotEmpty) ...[
                                                Text(
                                                  d.bio!,
                                                  maxLines: _expandedBio
                                                      ? null
                                                      : 3,
                                                  overflow: _expandedBio
                                                      ? TextOverflow.visible
                                                      : TextOverflow.ellipsis,
                                                ),
                                                Semantics(
                                                  label:
                                                      'qa.profile_detail.read_more_button',
                                                  button: true,
                                                  child: TextButton(
                                                    key: const ValueKey(
                                                      'qa.profile_detail.read_more_button',
                                                    ),
                                                    onPressed: () => setState(
                                                      () => _expandedBio =
                                                          !_expandedBio,
                                                    ),
                                                    child: Text(
                                                      _expandedBio
                                                          ? 'Read less'
                                                          : 'Read more',
                                                    ),
                                                  ),
                                                ),
                                              ],
                                              _kv('About', d.additionalInfo),
                                              if (ref
                                                      .watch(
                                                        runtimeFeatureFlagsProvider,
                                                      )
                                                      .valueOrNull
                                                      ?.enabled(
                                                        'intentional_dating_enabled',
                                                        fallback: false,
                                                      ) ==
                                                  true)
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .stretch,
                                                  children: [
                                                    ProfileStoriesSection(
                                                      userId: widget.profile.id,
                                                    ),
                                                    OutlinedButton.icon(
                                                      icon: const Icon(
                                                        Icons
                                                            .menu_book_outlined,
                                                      ),
                                                      label: const Text(
                                                        'Read their chapters',
                                                      ),
                                                      onPressed: () => openBlog(
                                                        context,
                                                        authorId:
                                                            widget.profile.id,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              _kv(
                                                'Instagram',
                                                d.instagramHandle,
                                              ),
                                              _kv('Country', d.country),
                                              _kv('State', d.regionState),
                                              _kv('City', d.city),
                                              const SizedBox(height: 8),
                                              _kv('Profession', d.profession),
                                              _kv('Education', d.education),
                                              _kv(
                                                'Height',
                                                d.heightCm == null
                                                    ? null
                                                    : '${d.heightCm} cm',
                                              ),
                                              _kv('Drinking', d.drinking),
                                              _kv('Smoking', d.smoking),
                                              _kv('Religion', d.religion),
                                              _kv(
                                                'Mother Tongue',
                                                d.motherTongue,
                                              ),
                                              _kv(
                                                'Relationship Status',
                                                d.relationshipStatus,
                                              ),
                                              _kv(
                                                'Personality Type',
                                                d.personalityType,
                                              ),
                                              _kv(
                                                'Party Lover',
                                                d.partyLover ? 'Yes' : 'No',
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                'Lifestyle & Preferences',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                              const SizedBox(height: 6),
                                              _kv(
                                                'Pet Preference',
                                                d.petPreference,
                                              ),
                                              _kv(
                                                'Diet Preference',
                                                d.dietPreference,
                                              ),
                                              _kv('Diet Type', d.dietType),
                                              _kv(
                                                'Workout Frequency',
                                                d.workoutFrequency,
                                              ),
                                              _kv(
                                                'Sleep Schedule',
                                                d.sleepSchedule,
                                              ),
                                              _kv(
                                                'Travel Style',
                                                d.travelStyle,
                                              ),
                                              _kv(
                                                'Political Comfort',
                                                d.politicalComfortRange,
                                              ),
                                              _kv(
                                                'Open to Casual',
                                                d.hookupOnly == null
                                                    ? null
                                                    : (d.hookupOnly!
                                                          ? 'Yes'
                                                          : 'No'),
                                              ),
                                              _tagSection(
                                                'Deal Breakers',
                                                d.dealBreakerTags,
                                              ),
                                              _tagSection('Hobbies', d.hobbies),
                                              _tagSection(
                                                'Favorite Songs',
                                                d.favoriteSongs,
                                              ),
                                              _tagSection(
                                                'Favorite Books',
                                                d.favoriteBooks,
                                              ),
                                              _tagSection(
                                                'Favorite Novels',
                                                d.favoriteNovels,
                                              ),
                                              _tagSection(
                                                'Activities',
                                                d.extraCurriculars,
                                              ),
                                              _tagSection(
                                                'Intent Tags',
                                                d.intentTags,
                                              ),
                                              _tagSection(
                                                'Languages',
                                                d.languageTags,
                                              ),
                                              _VouchesSection(
                                                userId: widget.profile.id,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SliverPadding(
                          padding: EdgeInsets.only(bottom: 16),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 390;

                        final messageButton = Semantics(
                          label: 'qa.profile_detail.message_button',
                          button: true,
                          child: GlassButton(
                            key: const ValueKey(
                              'qa.profile_detail.message_button',
                            ),
                            label: 'Message',
                            icon: Icons.message_rounded,
                            onPressed: () => Navigator.of(
                              context,
                            ).pop(ProfileDetailsAction.message),
                          ),
                        );
                        final loveButton = Semantics(
                          label: 'qa.profile_detail.love_button',
                          button: true,
                          child: GlassButton(
                            key: const ValueKey(
                              'qa.profile_detail.love_button',
                            ),
                            label: 'Love',
                            icon: Icons.favorite_rounded,
                            onPressed: () => Navigator.of(
                              context,
                            ).pop(ProfileDetailsAction.love),
                          ),
                        );

                        if (compact) {
                          return Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: messageButton,
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: loveButton,
                              ),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(child: messageButton),
                            const SizedBox(width: 12),
                            Expanded(child: loveButton),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _kv(String label, String? value) {
    if (value == null || value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _tagSection(String label, List<String> values) {
    if (values.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: values
                .map(
                  (value) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(value),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

/// Approved vouches from the member's friends, shown with first names only.
class _VouchesSection extends ConsumerWidget {
  const _VouchesSection({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vouches = ref.watch(publicVouchesProvider(userId));
    return vouches.maybeWhen(
      data: (items) {
        if (items.isEmpty) {
          return const SizedBox.shrink();
        }
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            key: const ValueKey('qa.profile.vouches'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vouched for by friends',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              for (final vouch in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '“${vouch.text}” — ${vouch.voucherName}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
