import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_error_message.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/profile_setup_provider.dart';
import 'setup/setup_about_screen.dart';
import 'setup/setup_photos_screen.dart';
import 'setup/setup_preferences_screen.dart';
import 'setup/setup_shared_widgets.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  @override
  void initState() {
    super.initState();
    // The draft provider stays alive across the setup screens so in-progress
    // edits survive moving between them. Opening Edit Profile is a fresh
    // start, so reload what the server has (changes made elsewhere, on
    // another device or in another session); the last draft stays on screen
    // while it loads.
    Future.microtask(() {
      // Only a draft cached from earlier can be stale; a first open is
      // already fetching.
      if (mounted && ref.read(profileSetupNotifierProvider).hasValue) {
        ref.invalidate(profileSetupNotifierProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final draftAsync = ref.watch(profileSetupNotifierProvider);
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom + 28;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PostLoginBackdrop(
            child: SafeArea(
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: true,
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                    title: Semantics(
                      label: AppLocalizations.of(context).profileEditTitle,
                      child: Text(
                        AppLocalizations.of(context).profileEditTitle,
                      ),
                    ),
                    actions: [
                      IconButton(
                        key: const ValueKey('qa.edit_profile.refresh'),
                        tooltip: AppLocalizations.of(
                          context,
                        ).profileEditRefreshTooltip,
                        onPressed: () =>
                            ref.invalidate(profileSetupNotifierProvider),
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding),
                    sliver: draftAsync.when(
                      loading: () => const SliverFillRemaining(
                        hasScrollBody: false,
                        child: _ProfileLoadingState(),
                      ),
                      error: (error, _) => SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: SetupErrorState(
                              message: apiErrorMessage(
                                error,
                                fallback: AppLocalizations.of(
                                  context,
                                ).commonSomethingWentWrongTryAgain,
                              ),
                              onRetry: () =>
                                  ref.invalidate(profileSetupNotifierProvider),
                            ),
                          ),
                        ),
                      ),
                      data: (draft) => SliverToBoxAdapter(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: AppTheme.contentMaxWidth,
                            ),
                            child: _EditProfileContent(draft: draft),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditProfileContent extends StatelessWidget {
  const _EditProfileContent({required this.draft});

  final ProfileDraft draft;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final yes = l10n.profileEditYes;
    final no = l10n.profileEditNo;
    String? option(String? value) =>
        value == null ? null : localizedProfileOption(l10n, value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProfileHero(draft: draft),
        const SizedBox(height: 16),
        _PhotoGallerySection(draft: draft),
        const SizedBox(height: 16),
        _InfoSection(
          actionKey: const ValueKey('qa.edit_profile.about_you'),
          title: l10n.profileEditAboutYou,
          icon: Icons.person_outline_rounded,
          actionLabel: l10n.profileEditEditAbout,
          onAction: () =>
              _open(context, const SetupAboutScreen(isSetupFlow: false)),
          rows: [
            _InfoRow(l10n.profileEditName, draft.name),
            _InfoRow(l10n.profileEditPhone, draft.phoneNumber),
            _InfoRow(
              l10n.profileEditDateOfBirth,
              _formatDate(context, draft.dateOfBirth),
            ),
            _InfoRow(l10n.profileEditGender, _genderLabel(l10n, draft.gender)),
            _InfoRow(l10n.profileSetupBioLabel, draft.bio),
            _InfoRow(
              l10n.profileEditHeight,
              draft.heightCm == null
                  ? null
                  : l10n.profileSetupHeightValue(draft.heightCm!),
            ),
            _InfoRow(l10n.profileSetupEducationLabel, option(draft.education)),
            _InfoRow(l10n.profileSetupProfessionLabel, draft.profession),
            _InfoRow(l10n.profileEditIncomeRange, option(draft.incomeRange)),
          ],
        ),
        const SizedBox(height: 16),
        _InfoSection(
          actionKey: const ValueKey('qa.edit_profile.location_social'),
          title: l10n.profileEditLocationSocial,
          icon: Icons.location_on_outlined,
          actionLabel: l10n.profileEditEditPreferences,
          onAction: () => _open(context, const SetupPreferencesScreen()),
          rows: [
            _InfoRow(l10n.profileSetupCountry, draft.country),
            _InfoRow(l10n.profileEditState, draft.regionState),
            _InfoRow(l10n.profileSetupCity, draft.city),
            _InfoRow(l10n.profileEditInstagram, draft.instagramHandle),
          ],
        ),
        const SizedBox(height: 16),
        _InfoSection(
          actionKey: const ValueKey('qa.edit_profile.dating_preferences'),
          title: l10n.profileEditDatingPreferences,
          icon: Icons.favorite_border_rounded,
          actionLabel: l10n.profileEditEditPreferences,
          onAction: () => _open(context, const SetupPreferencesScreen()),
          rows: [
            _InfoRow(
              l10n.profileEditSeeking,
              _join(draft.seekingGenders.map((g) => _genderLabel(l10n, g))),
            ),
            _InfoRow(
              l10n.profileEditAgeRange,
              l10n.profileEditAgeRangeValue(
                draft.minAgeYears,
                draft.maxAgeYears,
              ),
            ),
            _InfoRow(
              l10n.profileEditMaxDistance,
              l10n.profileSetupDistanceValue(draft.maxDistanceKm),
            ),
            _InfoRow(
              l10n.profileEditEducationFilter,
              _join(
                draft.educationFilter.map(
                  (v) => localizedProfileOption(l10n, v),
                ),
              ),
            ),
            _InfoRow(l10n.profileEditSeriousOnly, draft.seriousOnly ? yes : no),
            _InfoRow(
              l10n.profileEditVerifiedOnly,
              draft.verifiedOnly ? yes : no,
            ),
            _InfoRow(l10n.profileEditHookupOnly, draft.hookupOnly ? yes : no),
            _InfoRow(l10n.profileEditIntent, _join(draft.intentTags)),
            _InfoRow(l10n.profileEditLanguages, _join(draft.languageTags)),
            _InfoRow(
              l10n.profileEditDealBreakers,
              _join(draft.dealBreakerTags),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _InfoSection(
          actionKey: const ValueKey('qa.edit_profile.lifestyle'),
          title: l10n.profileSetupLifestyleTitle,
          icon: Icons.spa_outlined,
          actionLabel: l10n.profileEditEditPreferences,
          onAction: () => _open(context, const SetupPreferencesScreen()),
          rows: [
            _InfoRow(l10n.profileEditReligion, draft.religion),
            _InfoRow(l10n.profileSetupMotherTongue, draft.motherTongue),
            _InfoRow(l10n.profileSetupDrinkingLabel, option(draft.drinking)),
            _InfoRow(l10n.profileSetupSmokingLabel, option(draft.smoking)),
            _InfoRow(l10n.profileEditPets, draft.petPreference),
            _InfoRow(l10n.profileSetupDietPreference, draft.dietPreference),
            _InfoRow(l10n.profileSetupDietType, draft.dietType),
            _InfoRow(l10n.profileEditWorkout, draft.workoutFrequency),
            _InfoRow(l10n.profileSetupSleepSchedule, draft.sleepSchedule),
            _InfoRow(l10n.profileSetupTravelStyle, draft.travelStyle),
            _InfoRow(
              l10n.profileEditPoliticsComfort,
              draft.politicalComfortRange,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _InfoSection(
          actionKey: const ValueKey('qa.edit_profile.interests_details'),
          title: l10n.profileEditInterestsDetails,
          icon: Icons.auto_awesome_rounded,
          actionLabel: l10n.profileEditEditPreferences,
          onAction: () => _open(context, const SetupPreferencesScreen()),
          rows: [
            _InfoRow(l10n.profileEditHobbies, _join(draft.hobbies)),
            _InfoRow(l10n.profileEditBooks, _join(draft.favoriteBooks)),
            _InfoRow(l10n.profileEditNovels, _join(draft.favoriteNovels)),
            _InfoRow(l10n.profileEditSongs, _join(draft.favoriteSongs)),
            _InfoRow(
              l10n.profileEditExtraCurriculars,
              _join(draft.extraCurriculars),
            ),
            _InfoRow(l10n.profileEditAdditionalInfo, draft.additionalInfo),
          ],
        ),
      ],
    );
  }

  static void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  /// English keeps the long-standing dd/MM/yyyy; other locales use their
  /// own numeric date order.
  static String? _formatDate(BuildContext context, DateTime? date) {
    if (date == null) {
      return null;
    }
    final locale = Localizations.localeOf(context).toString();
    final format = locale.startsWith('en')
        ? DateFormat('dd/MM/yyyy', locale)
        : DateFormat.yMd(locale);
    return format.format(date);
  }

  static String? _join(Iterable<String> values) {
    final cleaned = values
        .map((v) => v.trim())
        .where((v) => v.isNotEmpty)
        .toList();
    if (cleaned.isEmpty) {
      return null;
    }
    return cleaned.join(', ');
  }

  static String _genderLabel(AppLocalizations l10n, String value) {
    switch (value.trim().toUpperCase()) {
      case 'M':
      case 'MALE':
      case 'MAN':
        return l10n.profileSetupGenderMan;
      case 'F':
      case 'FEMALE':
      case 'WOMAN':
        return l10n.profileSetupGenderWoman;
      case 'OTHER':
        return l10n.profileSetupGenderOther;
      default:
        return value.trim().isEmpty ? l10n.profileEditNotSet : value;
    }
  }
}

class _ProfileLoadingState extends StatelessWidget {
  const _ProfileLoadingState();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: GlassContainer(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 34,
                height: 34,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context).profileEditLoadingTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                AppLocalizations.of(context).profileEditLoadingBody,
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

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.draft});

  final ProfileDraft draft;

  @override
  Widget build(BuildContext context) => GlassContainer(
    padding: const EdgeInsets.all(20),
    child: Row(
      children: [
        _Avatar(
          photoUrl: draft.photos.isEmpty ? null : draft.photos.first.photoUrl,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                draft.name.trim().isEmpty
                    ? AppLocalizations.of(context).profileEditYourProfile
                    : draft.name.trim(),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                [draft.city, draft.regionState, draft.country]
                    .where((value) => value != null && value.trim().isNotEmpty)
                    .join(', '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 7,
                  value: draft.profileCompletionPercent / 100,
                  backgroundColor: Theme.of(context).colorScheme.outlineVariant,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                AppLocalizations.of(
                  context,
                ).profileEditPercentComplete(draft.profileCompletionPercent),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: Container(
      width: 84,
      height: 104,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
      child: photoUrl == null || photoUrl!.isEmpty
          ? Icon(
              Icons.person_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 42,
            )
          : Image.network(
              photoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.person_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 42,
              ),
            ),
    ),
  );
}

class _PhotoGallerySection extends StatelessWidget {
  const _PhotoGallerySection({required this.draft});

  final ProfileDraft draft;

  @override
  Widget build(BuildContext context) => GlassContainer(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          actionKey: const ValueKey('qa.edit_profile.photo_gallery'),
          title: AppLocalizations.of(context).profileEditPhotoGallery,
          icon: Icons.photo_library_outlined,
          actionLabel: AppLocalizations.of(context).profileEditManagePhotos,
          onAction: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const SetupPhotosScreen(isSetupFlow: false),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (draft.photos.isEmpty)
          Text(
            AppLocalizations.of(context).profileEditNoPhotos,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.70),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: draft.photos.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.78,
            ),
            itemBuilder: (context, index) => ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    draft.photos[index].photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.12),
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (index == 0)
                    Positioned(
                      left: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          AppLocalizations.of(context).profileEditPrimaryBadge,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.actionKey,
    required this.title,
    required this.icon,
    required this.actionLabel,
    required this.onAction,
    required this.rows,
  });

  final String title;
  final IconData icon;
  final String actionLabel;
  final VoidCallback onAction;
  final List<_InfoRow> rows;

  /// Automation key for the section's edit action.
  final Key actionKey;

  @override
  Widget build(BuildContext context) => GlassContainer(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          actionKey: actionKey,
          title: title,
          icon: icon,
          actionLabel: actionLabel,
          onAction: onAction,
        ),
        const SizedBox(height: 12),
        ...rows.map((row) => _ProfileInfoRow(row: row)),
      ],
    ),
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.actionKey,
    required this.title,
    required this.icon,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final IconData icon;
  final String actionLabel;
  final VoidCallback onAction;

  /// Automation key for the edit action.
  final Key actionKey;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final heading = Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      );
      final action = TextButton(
        key: actionKey,
        onPressed: onAction,
        child: Text(
          actionLabel,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
      if (constraints.maxWidth < 360) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            heading,
            Align(alignment: Alignment.centerRight, child: action),
          ],
        );
      }
      return Row(
        children: [
          Expanded(child: heading),
          action,
        ],
      );
    },
  );
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({required this.row});

  final _InfoRow row;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 124,
          child: Text(
            row.label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.58),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            row.isEmpty
                ? AppLocalizations.of(context).profileEditNotSet
                : row.value!.trim(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(
                alpha: row.isEmpty ? 0.45 : 0.90,
              ),
              fontWeight: row.isEmpty ? FontWeight.w500 : FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _InfoRow {
  const _InfoRow(this.label, this.value);

  final String label;
  final String? value;

  bool get isEmpty => value == null || value!.trim().isEmpty;
}
