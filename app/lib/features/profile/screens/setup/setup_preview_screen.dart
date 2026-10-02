import '../../../../core/platform/browser_context.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/platform/platform_photo.dart';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_widgets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../common/screens/main_navigation_screen.dart';
import '../../providers/profile_completion_provider.dart';
import '../../providers/profile_setup_provider.dart';
import 'setup_shared_widgets.dart';

/// Step 4 of 4 — profile preview with photo carousel, attribute chips, and
/// a "Complete" button that calls [ProfileSetupNotifier.completeProfile].
class SetupPreviewScreen extends ConsumerStatefulWidget {
  const SetupPreviewScreen({super.key});

  @override
  ConsumerState<SetupPreviewScreen> createState() => _SetupPreviewScreenState();
}

class _SetupPreviewScreenState extends ConsumerState<SetupPreviewScreen> {
  final _pageController = PageController();
  int _currentPhoto = 0;
  bool _isCompleting = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  String? _validate(ProfileDraft draft, AppLocalizations l10n) {
    if (draft.name.trim().length < ValidationConstants.minNameLength) {
      return l10n.profileSetupNameRequired;
    }
    if (draft.dateOfBirth == null) {
      return l10n.profileSetupDobRequired;
    }
    if (draft.photos.length < ValidationConstants.minPhotos) {
      return l10n.profileSetupPhotosRequired(ValidationConstants.minPhotos);
    }
    if (draft.bio.trim().length < ValidationConstants.minBioLength) {
      return l10n.profileSetupBioTooShort(ValidationConstants.minBioLength);
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Complete profile
  // ---------------------------------------------------------------------------

  Future<void> _complete() async {
    final draft = ref.read(profileSetupNotifierProvider).valueOrNull;
    if (draft == null) {
      return;
    }

    final error = _validate(draft, AppLocalizations.of(context));
    if (error != null) {
      _snack(error);
      return;
    }

    setState(() => _isCompleting = true);
    try {
      await ref.read(profileSetupNotifierProvider.notifier).completeProfile();
      ref.invalidate(profileCompletionProvider);
      if (!mounted) {
        return;
      }
      ref.read(mainNavigationIndexProvider.notifier).state = 0;
      if (kIsWeb) {
        setWebRoute('/discover');
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      }
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const MainNavigationScreen()),
        (route) => false,
      );
    } on DioException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _isCompleting = false);
      final l10n = AppLocalizations.of(context);
      final msg = (e.response?.data is Map)
          ? ((e.response!.data as Map)['message'] ??
                l10n.profileSetupServerError)
          : l10n.profileSetupNetworkError;
      _snack(msg.toString());
    } on Exception catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isCompleting = false);
      _snack(AppLocalizations.of(context).profileSetupGenericError);
    }
  }

  void _snack(String msg) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---------------------------------------------------------------------------
  // Photo helpers
  // ---------------------------------------------------------------------------

  Widget _buildPhotoImage(String url) {
    return platformPhoto(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _photoPlaceholder(),
    );
  }

  Widget _photoPlaceholder() => Container(
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    child: Center(
      child: Icon(
        Icons.image_not_supported_rounded,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        size: 48,
      ),
    ),
  );

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final draftAsync = ref.watch(profileSetupNotifierProvider);

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: SafeArea(
          child: Column(
            children: [
              SetupHeader(
                currentStep: 4,
                totalSteps: 4,
                onBack: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: draftAsync.when(
                  loading: () => Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  error: (e, _) => SetupErrorState(
                    message: e.toString(),
                    onRetry: () => ref.invalidate(profileSetupNotifierProvider),
                  ),
                  data: (draft) => _PreviewBody(
                    draft: draft,
                    pageController: _pageController,
                    currentPhoto: _currentPhoto,
                    isCompleting: _isCompleting,
                    onPageChanged: (i) => setState(() => _currentPhoto = i),
                    onComplete: _complete,
                    buildPhotoImage: _buildPhotoImage,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Sub-widgets
// =============================================================================

class _PreviewBody extends StatelessWidget {
  const _PreviewBody({
    required this.draft,
    required this.pageController,
    required this.currentPhoto,
    required this.isCompleting,
    required this.onPageChanged,
    required this.onComplete,
    required this.buildPhotoImage,
  });

  final ProfileDraft draft;
  final PageController pageController;
  final int currentPhoto;
  final bool isCompleting;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onComplete;
  final Widget Function(String url) buildPhotoImage;

  int get _age {
    final dob = draft.dateOfBirth;
    if (dob == null) {
      return 0;
    }
    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.viewPaddingOf(context).bottom + 24;
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 8, 20, bottomPad),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppTheme.contentMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.profileSetupPreviewTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.profileSetupPreviewSubtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),

              // -- Photo carousel
              if (draft.photos.isNotEmpty) ...[
                FormCard(
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM),
                        child: AspectRatio(
                          aspectRatio: 3 / 4,
                          child: PageView.builder(
                            controller: pageController,
                            itemCount: draft.photos.length,
                            onPageChanged: onPageChanged,
                            itemBuilder: (_, i) =>
                                buildPhotoImage(draft.photos[i].photoUrl),
                          ),
                        ),
                      ),
                      if (draft.photos.length > 1) ...[
                        const SizedBox(height: 12),
                        _PhotoDots(
                          count: draft.photos.length,
                          current: currentPhoto,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // -- Name & age
              FormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.profileSetupNameAge(draft.name.trim(), _age),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: scheme.onSurface,
                          ),
                    ),
                    if (draft.bio.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        draft.bio,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // -- Details chips
              FormCard(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (draft.heightCm != null)
                      ProfileChip(
                        icon: Icons.height_rounded,
                        label: l10n.profileSetupHeightValue(draft.heightCm!),
                      ),
                    if (draft.education != null)
                      ProfileChip(
                        icon: Icons.school_rounded,
                        label: localizedProfileOption(l10n, draft.education!),
                      ),
                    if (draft.profession != null &&
                        draft.profession!.isNotEmpty)
                      ProfileChip(
                        icon: Icons.work_outline_rounded,
                        label: draft.profession!,
                      ),
                    if (draft.incomeRange != null)
                      ProfileChip(
                        icon: Icons.attach_money_rounded,
                        label: localizedProfileOption(l10n, draft.incomeRange!),
                      ),
                    ProfileChip(
                      icon: Icons.local_bar_rounded,
                      label: l10n.profileSetupDrinksChip(
                        localizedProfileOption(l10n, draft.drinking),
                      ),
                    ),
                    ProfileChip(
                      icon: Icons.smoking_rooms_rounded,
                      label: l10n.profileSetupSmokesChip(
                        localizedProfileOption(l10n, draft.smoking),
                      ),
                    ),
                    if (draft.religion != null)
                      ProfileChip(
                        icon: Icons.auto_awesome_rounded,
                        label: draft.religion!,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // -- Completion bar
              _CompletionBar(percent: draft.profileCompletionPercent / 100.0),
              const SizedBox(height: 24),

              // -- Complete button
              Semantics(
                label: 'qa.setup.preview.complete_button',
                button: true,
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: GlassButton(
                    key: const ValueKey('qa.setup.preview.complete_button'),
                    label: l10n.profileSetupCompleteProfile,
                    icon: Icons.check_circle_rounded,
                    shinyEffect: true,
                    isLoading: isCompleting,
                    onPressed: isCompleting ? null : onComplete,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Photo dots indicator
// -----------------------------------------------------------------------------

class _PhotoDots extends StatelessWidget {
  const _PhotoDots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(count, (i) {
      final isActive = i == current;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: isActive ? 20 : 8,
        height: 8,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: isActive
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outlineVariant,
        ),
      );
    }),
  );
}

// -----------------------------------------------------------------------------
// Completion bar
// -----------------------------------------------------------------------------

class _CompletionBar extends StatelessWidget {
  const _CompletionBar({required this.percent});

  final double percent;

  @override
  Widget build(BuildContext context) {
    final pct = (percent * 100).round();
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.pie_chart_rounded, size: 16, color: scheme.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                AppLocalizations.of(context).profileSetupCompletionPercent(pct),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: percent.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: scheme.outlineVariant,
            valueColor: AlwaysStoppedAnimation<Color>(
              pct >= 100 ? const Color(0xFF4CAF50) : scheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}
