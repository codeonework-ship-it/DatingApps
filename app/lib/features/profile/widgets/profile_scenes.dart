import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/cinematic_effects.dart';
import '../../../core/theme/cinematic_motion.dart';
import '../../../core/widgets/connect_page.dart';
import '../../../l10n/app_localizations.dart';
import '../../friends/models/friend_social.dart';
import '../../friends/providers/friend_social_provider.dart';
import '../../intentional_dating/profile_stories.dart';
import '../../swipe/providers/profile_details_provider.dart';
import '../data/india_master_data.dart';
import 'cinematic_profile.dart';

/// The "scenes" under a profile's title card: About (the bio as a pull
/// quote), stories, interests, the basics, lifestyle and trust. Each scene
/// is titled the Today way (tracked eyebrow over a serif title) and enters
/// with the shared cinematic stagger. Empty scenes are left out entirely,
/// and nothing is shown for a missing value.
class ProfileScenes extends StatelessWidget {
  const ProfileScenes({
    required this.details,
    super.key,
    this.showStories = false,
    this.afterStories,
    this.inCommon = const <String>[],
    this.readMoreKey,
  });

  final ProfileDetails details;

  /// Whether the stories scene may show (the intentional dating flag).
  final bool showStories;

  /// Shown straight after the stories scene (a link to their chapters).
  final Widget? afterStories;

  /// Shared preferences with the viewer, from the server.
  final List<String> inCommon;

  /// Automation key for the bio's "Read more" toggle.
  final Key? readMoreKey;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final d = details;
    final about = _clean(d.bio);
    final more = _clean(d.additionalInfo);

    final interests = <(String, List<String>)>[
      (l10n.memberProfileInCommon, inCommon),
      (
        l10n.memberProfileLookingFor,
        d.intentTags.map((tag) => _intent(l10n, tag)).toList(),
      ),
      (l10n.memberProfileHobbies, d.hobbies),
      (l10n.memberProfileActivities, d.extraCurriculars),
      (l10n.memberProfileSongs, d.favoriteSongs),
      (
        l10n.memberProfileBooks,
        {...d.favoriteBooks, ...d.favoriteNovels}.toList(),
      ),
      (l10n.memberProfileLanguages, d.languageTags),
    ].where((group) => group.$2.any((v) => v.trim().isNotEmpty)).toList();

    final place = [
      d.city,
      d.regionState,
      d.country,
    ].map(_clean).whereType<String>().toSet().join(', ');
    final basics = <ProfileFact>[
      if (d.heightCm != null && d.heightCm! > 0)
        ProfileFact(
          Icons.height_rounded,
          l10n.memberProfileFactHeight,
          l10n.memberProfileHeightCm(d.heightCm!),
        ),
      ?_fact(
        Icons.work_outline_rounded,
        l10n.memberProfileFactWork,
        d.profession,
      ),
      ?_option(
        l10n,
        Icons.school_outlined,
        l10n.memberProfileFactEducation,
        d.education,
      ),
      ?_fact(Icons.place_outlined, l10n.memberProfileFactLivesIn, place),
      ?_fact(
        Icons.translate_rounded,
        l10n.memberProfileFactMotherTongue,
        d.motherTongue,
      ),
      ?_option(
        l10n,
        Icons.self_improvement_rounded,
        l10n.memberProfileFactReligion,
        d.religion,
      ),
      ?_option(
        l10n,
        Icons.psychology_alt_outlined,
        l10n.memberProfileFactPersonality,
        d.personalityType,
      ),
      ?_option(
        l10n,
        Icons.favorite_border_rounded,
        l10n.memberProfileFactRelationship,
        d.relationshipStatus,
      ),
      ?_fact(
        Icons.alternate_email_rounded,
        l10n.memberProfileFactInstagram,
        d.instagramHandle,
      ),
    ];

    final lifestyle = <ProfileFact>[
      ?_option(
        l10n,
        Icons.local_bar_outlined,
        l10n.memberProfileFactDrinking,
        d.drinking,
      ),
      ?_option(
        l10n,
        Icons.smoke_free_rounded,
        l10n.memberProfileFactSmoking,
        d.smoking,
      ),
      ?_option(
        l10n,
        Icons.fitness_center_rounded,
        l10n.memberProfileFactWorkout,
        d.workoutFrequency,
        list: ProfileOptionList.workout,
      ),
      ?_option(
        l10n,
        Icons.restaurant_outlined,
        l10n.memberProfileFactDiet,
        d.dietPreference,
        list: ProfileOptionList.dietPreference,
      ),
      ?_option(
        l10n,
        Icons.eco_outlined,
        l10n.memberProfileFactDietType,
        d.dietType,
        list: ProfileOptionList.dietType,
      ),
      ?_option(
        l10n,
        Icons.bedtime_outlined,
        l10n.memberProfileFactSleep,
        d.sleepSchedule,
        list: ProfileOptionList.sleepSchedule,
      ),
      ?_option(
        l10n,
        Icons.flight_takeoff_rounded,
        l10n.memberProfileFactTravel,
        d.travelStyle,
        list: ProfileOptionList.travelStyle,
      ),
      ?_fact(Icons.pets_outlined, l10n.memberProfileFactPets, d.petPreference),
      ?_option(
        l10n,
        Icons.forum_outlined,
        l10n.memberProfileFactPolitics,
        d.politicalComfortRange,
        list: ProfileOptionList.politicalComfort,
      ),
      if (d.hookupOnly != null)
        ProfileFact(
          Icons.local_fire_department_outlined,
          l10n.memberProfileFactOpenToCasual,
          d.hookupOnly! ? l10n.commonYes : l10n.commonNo,
        ),
      if (d.partyLover)
        ProfileFact(
          Icons.celebration_outlined,
          l10n.memberProfileFactPartyLover,
          l10n.commonYes,
        ),
    ];
    final dealBreakers = d.dealBreakerTags
        .map(_humanize)
        .where((v) => v.isNotEmpty)
        .toList();

    var order = 0;
    Widget scene(Widget child) =>
        CinematicEntrance(index: order++, child: child);

    return CinematicStaggerScope(
      key: ValueKey('profile-scenes-${d.userId}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (about != null || more != null)
            scene(
              ProfileScene(
                label: l10n.memberProfileSceneAbout,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (about != null)
                      ProfilePullQuote(text: about, readMoreKey: readMoreKey),
                    if (about != null && more != null)
                      const SizedBox(height: 16),
                    if (more != null)
                      Text(
                        more,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.55,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          if (showStories)
            scene(
              ProfileStoriesSection(
                userId: d.userId,
                frame: (context, stories) => ProfileScene(
                  label: l10n.memberProfileSceneStories,
                  title: l10n.memberProfileSceneStoriesTitle,
                  child: stories,
                ),
              ),
            ),
          ?afterStories,
          if (interests.isNotEmpty)
            scene(
              ProfileScene(
                label: l10n.memberProfileSceneInterests,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < interests.length; i++) ...[
                      if (i > 0) const SizedBox(height: 20),
                      ProfileChipGroup(
                        label: interests[i].$1,
                        values: interests[i].$2,
                        emphasis: i == 0,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          if (basics.isNotEmpty)
            scene(
              ProfileScene(
                label: l10n.memberProfileSceneBasics,
                child: ProfileFactsGrid(facts: basics),
              ),
            ),
          if (lifestyle.isNotEmpty || dealBreakers.isNotEmpty)
            scene(
              ProfileScene(
                label: l10n.memberProfileSceneLifestyle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (lifestyle.isNotEmpty)
                      ProfileFactsGrid(facts: lifestyle),
                    if (lifestyle.isNotEmpty && dealBreakers.isNotEmpty)
                      const SizedBox(height: 20),
                    if (dealBreakers.isNotEmpty)
                      ProfileChipGroup(
                        label: l10n.memberProfileDealBreakers,
                        values: dealBreakers,
                      ),
                  ],
                ),
              ),
            ),
          scene(ProfileTrustScene(userId: d.userId, isVerified: d.isVerified)),
        ],
      ),
    );
  }

  static String? _clean(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty || text.toLowerCase() == 'null' ? null : text;
  }

  static ProfileFact? _fact(IconData icon, String label, String? value) {
    final text = _clean(value);
    return text == null ? null : ProfileFact(icon, label, text);
  }

  /// A fact whose value is a stored option ('Night owl'), shown with its
  /// label in the member's language.
  static ProfileFact? _option(
    AppLocalizations l10n,
    IconData icon,
    String label,
    String? value, {
    ProfileOptionList list = ProfileOptionList.general,
  }) {
    final text = _clean(value);
    return text == null
        ? null
        : ProfileFact(icon, label, profileOptionLabel(l10n, text, list: list));
  }

  /// An intent code (`long_term`) as words, translated when known.
  static String _intent(AppLocalizations l10n, String raw) {
    final code = raw.trim();
    final label = profileOptionLabel(
      l10n,
      code,
      list: ProfileOptionList.intent,
    );
    return label == code ? _humanize(code) : label;
  }

  /// `long_term` → `Long term`.
  static String _humanize(String raw) {
    final text = raw.trim().replaceAll('_', ' ');
    if (text.isEmpty) {
      return text;
    }
    return text[0].toUpperCase() + text.substring(1);
  }
}

/// One titled scene: a tracked eyebrow, an optional serif title, then the
/// content, with the section rhythm of the Today look.
class ProfileScene extends StatelessWidget {
  const ProfileScene({
    required this.label,
    required this.child,
    super.key,
    this.title,
    this.caption,
    this.trailing,
  });

  final String label;
  final String? title;
  final String? caption;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: ConnectMetrics.sectionGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 2,
                margin: const EdgeInsets.only(right: 8),
                color: scheme.primary,
              ),
              Expanded(
                child: ConnectSectionHeader(
                  label: label.toUpperCase(),
                  trailing: trailing,
                ),
              ),
            ],
          ),
          if (title != null) ...[
            const SizedBox(height: 4),
            Semantics(
              header: true,
              child: Text(
                title!,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontFamily: AppTheme.displayFamily,
                  height: 1.2,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ],
          if (caption != null) ...[
            const SizedBox(height: 4),
            Text(
              caption!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

/// The bio as a large serif pull quote, folded after a few lines with a
/// "Read more" toggle when it runs long.
class ProfilePullQuote extends StatefulWidget {
  const ProfilePullQuote({
    required this.text,
    super.key,
    this.readMoreKey,
    this.foldedLines = 5,
  });

  final String text;
  final Key? readMoreKey;
  final int foldedLines;

  @override
  State<ProfilePullQuote> createState() => _ProfilePullQuoteState();
}

class _ProfilePullQuoteState extends State<ProfilePullQuote> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 600;
    final style = theme.textTheme.headlineSmall?.copyWith(
      fontFamily: AppTheme.displayFamily,
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.w400,
      fontSize: wide ? 28 : 23,
      height: 1.4,
      color: scheme.onSurface,
    );
    return LayoutBuilder(
      builder: (context, box) {
        const indent = 20.0;
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: widget.foldedLines,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: (box.maxWidth - indent).clamp(0, double.infinity));
        final overflows = painter.didExceedMaxLines;
        painter.dispose();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // An oversized opening quote hanging over the rule, like a
            // pull quote in a printed programme.
            ExcludeSemantics(
              child: SizedBox(
                height: 32,
                child: OverflowBox(
                  alignment: Alignment.topLeft,
                  maxHeight: 96,
                  child: Transform.translate(
                    offset: const Offset(-4, -8),
                    child: Text(
                      '“',
                      textScaler: TextScaler.noScaling,
                      style: TextStyle(
                        fontFamily: AppTheme.displayFamily,
                        fontSize: 80,
                        height: 1,
                        color: scheme.primary.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.only(left: indent - 4),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: scheme.primary.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
              ),
              child: AnimatedSize(
                duration: CinematicLevel.of(context) == CinematicLevel.still
                    ? Duration.zero
                    : const Duration(milliseconds: 280),
                alignment: Alignment.topLeft,
                child: Text(
                  widget.text,
                  maxLines: _expanded ? null : widget.foldedLines,
                  overflow: _expanded
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                  style: style,
                ),
              ),
            ),
            if (overflows || _expanded)
              Semantics(
                // The automation handle, only where a key asks for one.
                label: switch (widget.readMoreKey) {
                  ValueKey<String>(:final value) => value,
                  _ => null,
                },
                button: true,
                child: Padding(
                  // Lines the label up with the quote above it.
                  padding: const EdgeInsets.only(left: 4),
                  child: TextButton(
                    key: widget.readMoreKey,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onPressed: () => setState(() => _expanded = !_expanded),
                    child: Text(
                      _expanded
                          ? l10n.memberProfileReadLess
                          : l10n.memberProfileReadMore,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// One fact in a [ProfileFactsGrid].
@immutable
class ProfileFact {
  const ProfileFact(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;
}

/// Facts as an even grid of quiet tiles: an icon, a small label and the
/// value. Two columns on phones, three on wider screens, one when the text
/// is very large.
class ProfileFactsGrid extends StatelessWidget {
  const ProfileFactsGrid({required this.facts, super.key});

  final List<ProfileFact> facts;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
      final columns = scale >= 1.6
          ? 1
          : box.maxWidth >= 560
          ? 3
          : 2;
      const gap = 12.0;
      final rows = <List<ProfileFact>>[];
      for (var i = 0; i < facts.length; i += columns) {
        rows.add(facts.sublist(i, (i + columns).clamp(0, facts.length)));
      }
      return Column(
        children: [
          for (var r = 0; r < rows.length; r++) ...[
            if (r > 0) const SizedBox(height: gap),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var c = 0; c < columns; c++) ...[
                    if (c > 0) const SizedBox(width: gap),
                    Expanded(
                      child: c < rows[r].length
                          ? _FactTile(fact: rows[r][c])
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      );
    },
  );
}

class _FactTile extends StatelessWidget {
  const _FactTile({required this.fact});

  final ProfileFact fact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      container: true,
      label: '${fact.label}: ${fact.value}',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(fact.icon, size: 20, color: scheme.primary),
              const SizedBox(height: 8),
              Text(
                fact.label.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                fact.value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A labelled group of pills (hobbies, languages...).
class ProfileChipGroup extends StatelessWidget {
  const ProfileChipGroup({
    required this.label,
    required this.values,
    super.key,
    this.emphasis = false,
  });

  final String label;
  final List<String> values;

  /// Filled pills for the group that matters most (shared interests).
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final items = values.map((v) => v.trim()).where((v) => v.isNotEmpty);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final value in items)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: emphasis ? scheme.primaryContainer : scheme.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: emphasis
                        ? scheme.primary.withValues(alpha: 0.4)
                        : scheme.outlineVariant,
                  ),
                ),
                child: Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: emphasis
                        ? scheme.onPrimaryContainer
                        : scheme.onSurface,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Verification and vouches from friends. Hidden when there is neither.
class ProfileTrustScene extends ConsumerWidget {
  const ProfileTrustScene({
    required this.userId,
    required this.isVerified,
    super.key,
  });

  final String userId;
  final bool isVerified;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vouches =
        ref.watch(publicVouchesProvider(userId)).valueOrNull ??
        const <PublicVouch>[];
    if (!isVerified && vouches.isEmpty) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    return ProfileScene(
      label: l10n.memberProfileSceneTrust,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isVerified)
            ConnectPanel(
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.verified_rounded, color: scheme.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.memberProfileVerifiedTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.memberProfileVerifiedBody,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (vouches.isNotEmpty) ...[
            if (isVerified) const SizedBox(height: ConnectMetrics.cardGap),
            Column(
              key: const ValueKey('qa.profile.vouches'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.memberProfileVouchesTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                for (final vouch in vouches)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ConnectPanel(
                      padding: const EdgeInsets.all(16),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '“${vouch.text}”',
                              style: TextStyle(
                                fontFamily: AppTheme.displayFamily,
                                fontStyle: FontStyle.italic,
                                fontSize: 18,
                                height: 1.4,
                                color: scheme.onSurface,
                              ),
                            ),
                            TextSpan(
                              text: '\n— ${vouch.voucherName}',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// A headline for the hero from full profile details.
ProfileHeadline profileHeadlineFrom(
  ProfileDetails details, {
  required List<String> photos,
  String? logline,
  List<String> badges = const <String>[],
}) {
  final place = details.city?.trim().isNotEmpty == true
      ? details.city!.trim()
      : (details.regionState ?? details.country)?.trim();
  return ProfileHeadline(
    userId: details.userId,
    name: details.name,
    age: details.age,
    profession: details.profession,
    place: place,
    isVerified: details.isVerified,
    photos: photos,
    logline: logline,
    badges: badges,
  );
}
