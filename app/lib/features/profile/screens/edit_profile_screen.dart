import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../providers/profile_setup_provider.dart';
import 'setup/setup_about_screen.dart';
import 'setup/setup_photos_screen.dart';
import 'setup/setup_preferences_screen.dart';
import 'setup/setup_shared_widgets.dart';

class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                      label: 'Edit Profile',
                      child: const Text('Edit Profile'),
                    ),
                    actions: [
                      IconButton(
                        tooltip: 'Refresh profile',
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
                              message: error.toString(),
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
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _ProfileHero(draft: draft),
      const SizedBox(height: 16),
      _PhotoGallerySection(draft: draft),
      const SizedBox(height: 16),
      _InfoSection(
        title: 'About you',
        icon: Icons.person_outline_rounded,
        actionLabel: 'Edit about',
        onAction: () =>
            _open(context, const SetupAboutScreen(isSetupFlow: false)),
        rows: [
          _InfoRow('Name', draft.name),
          _InfoRow('Phone', draft.phoneNumber),
          _InfoRow('Date of birth', _formatDate(draft.dateOfBirth)),
          _InfoRow('Gender', _genderLabel(draft.gender)),
          _InfoRow('Bio', draft.bio),
          _InfoRow(
            'Height',
            draft.heightCm == null ? null : '${draft.heightCm} cm',
          ),
          _InfoRow('Education', draft.education),
          _InfoRow('Profession', draft.profession),
          _InfoRow('Income range', draft.incomeRange),
        ],
      ),
      const SizedBox(height: 16),
      _InfoSection(
        title: 'Location & social',
        icon: Icons.location_on_outlined,
        actionLabel: 'Edit preferences',
        onAction: () => _open(context, const SetupPreferencesScreen()),
        rows: [
          _InfoRow('Country', draft.country),
          _InfoRow('State', draft.regionState),
          _InfoRow('City', draft.city),
          _InfoRow('Instagram', draft.instagramHandle),
        ],
      ),
      const SizedBox(height: 16),
      _InfoSection(
        title: 'Dating preferences',
        icon: Icons.favorite_border_rounded,
        actionLabel: 'Edit preferences',
        onAction: () => _open(context, const SetupPreferencesScreen()),
        rows: [
          _InfoRow('Seeking', _join(draft.seekingGenders.map(_genderLabel))),
          _InfoRow('Age range', '${draft.minAgeYears}–${draft.maxAgeYears}'),
          _InfoRow('Max distance', '${draft.maxDistanceKm} km'),
          _InfoRow('Education filter', _join(draft.educationFilter)),
          _InfoRow('Serious only', draft.seriousOnly ? 'Yes' : 'No'),
          _InfoRow('Verified only', draft.verifiedOnly ? 'Yes' : 'No'),
          _InfoRow('Hookup only', draft.hookupOnly ? 'Yes' : 'No'),
          _InfoRow('Intent', _join(draft.intentTags)),
          _InfoRow('Languages', _join(draft.languageTags)),
          _InfoRow('Deal breakers', _join(draft.dealBreakerTags)),
        ],
      ),
      const SizedBox(height: 16),
      _InfoSection(
        title: 'Lifestyle',
        icon: Icons.spa_outlined,
        actionLabel: 'Edit preferences',
        onAction: () => _open(context, const SetupPreferencesScreen()),
        rows: [
          _InfoRow('Religion', draft.religion),
          _InfoRow('Mother tongue', draft.motherTongue),
          _InfoRow('Drinking', draft.drinking),
          _InfoRow('Smoking', draft.smoking),
          _InfoRow('Pets', draft.petPreference),
          _InfoRow('Diet preference', draft.dietPreference),
          _InfoRow('Diet type', draft.dietType),
          _InfoRow('Workout', draft.workoutFrequency),
          _InfoRow('Sleep schedule', draft.sleepSchedule),
          _InfoRow('Travel style', draft.travelStyle),
          _InfoRow('Politics comfort', draft.politicalComfortRange),
        ],
      ),
      const SizedBox(height: 16),
      _InfoSection(
        title: 'Interests & details',
        icon: Icons.auto_awesome_rounded,
        actionLabel: 'Edit preferences',
        onAction: () => _open(context, const SetupPreferencesScreen()),
        rows: [
          _InfoRow('Hobbies', _join(draft.hobbies)),
          _InfoRow('Books', _join(draft.favoriteBooks)),
          _InfoRow('Novels', _join(draft.favoriteNovels)),
          _InfoRow('Songs', _join(draft.favoriteSongs)),
          _InfoRow('Extra curriculars', _join(draft.extraCurriculars)),
          _InfoRow('Additional info', draft.additionalInfo),
        ],
      ),
    ],
  );

  static void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  static String? _formatDate(DateTime? date) {
    if (date == null) {
      return null;
    }
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
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

  static String _genderLabel(String value) {
    switch (value.trim().toUpperCase()) {
      case 'M':
      case 'MALE':
      case 'MAN':
        return 'Man';
      case 'F':
      case 'FEMALE':
      case 'WOMAN':
        return 'Woman';
      default:
        return value.trim().isEmpty ? 'Not set' : value;
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
                'Loading your saved profile',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Binding the information saved during account setup.',
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
                draft.name.trim().isEmpty ? 'Your profile' : draft.name.trim(),
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
                '${draft.profileCompletionPercent}% complete',
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
          title: 'Photo gallery',
          icon: Icons.photo_library_outlined,
          actionLabel: 'Manage photos',
          onAction: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const SetupPhotosScreen(isSetupFlow: false),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (draft.photos.isEmpty)
          Text(
            'No photos uploaded yet.',
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
                          'Primary',
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

  @override
  Widget build(BuildContext context) => GlassContainer(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
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
    required this.title,
    required this.icon,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final IconData icon;
  final String actionLabel;
  final VoidCallback onAction;

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
            row.displayValue,
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

  String get displayValue => isEmpty ? 'Not set' : value!.trim();
}
