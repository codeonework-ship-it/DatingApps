import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_widgets.dart';
import '../../providers/profile_completion_provider.dart';
import '../../providers/profile_setup_provider.dart';
import 'setup_shared_widgets.dart';

/// Step 4 of 4 — preview how the profile will appear and complete setup.
///
/// Calls [ProfileSetupNotifier.completeProfile] which hits POST
/// `/profile/{userId}/complete` on the Go BFF.
class SetupPreviewScreen extends ConsumerStatefulWidget {
  const SetupPreviewScreen({super.key});

  @override
  ConsumerState<SetupPreviewScreen> createState() => _SetupPreviewScreenState();
}

class _SetupPreviewScreenState extends ConsumerState<SetupPreviewScreen> {
  final PageController _photoPageController = PageController();
  int _selectedPhotoIndex = 0;

  @override
  void dispose() {
    _photoPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draftAsync = ref.watch(profileSetupNotifierProvider);

    return draftAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        body: Center(
          child: SetupErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(profileSetupNotifierProvider),
          ),
        ),
      ),
      data: (draft) {
        final photoUrls = draft.photos
            .map((p) => p.photoUrl.trim())
            .where((u) => u.isNotEmpty)
            .toList();
        if (_selectedPhotoIndex >= photoUrls.length) {
          _selectedPhotoIndex = 0;
        }

        final pct = draft.profileCompletionPercent;

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
            child: SafeArea(
              child: Column(
                children: [
                  // ── Header ───────────────────────────────────────────
                  SetupHeader(
                    currentStep: 4,
                    totalSteps: 4,
                    onBack: () => Navigator.of(context).pop(),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Profile preview',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -0.3,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'How others see you',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.60,
                                      ),
                                    ),
                              ),
                            ],
                          ),
                        ),
                        CompletionBadge(percent: pct),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Scrollable content ───────────────────────────────
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: AppTheme.contentMaxWidth,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // ── Photo carousel ──────────────────────
                              if (photoUrls.isNotEmpty) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: SizedBox(
                                    height: 280,
                                    child: PageView.builder(
                                      controller: _photoPageController,
                                      onPageChanged: (index) {
                                        if (!mounted) return;
                                        setState(
                                          () => _selectedPhotoIndex = index,
                                        );
                                      },
                                      itemCount: photoUrls.length,
                                      itemBuilder: (context, index) =>
                                          Image.network(
                                            photoUrls[index],
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                Container(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.08),
                                                  child: const Icon(
                                                    Icons.broken_image_outlined,
                                                    color: Colors.white38,
                                                    size: 48,
                                                  ),
                                                ),
                                          ),
                                    ),
                                  ),
                                ),
                                if (photoUrls.length > 1) ...[
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      photoUrls.length,
                                      (i) => GestureDetector(
                                        onTap: () {
                                          _photoPageController.animateToPage(
                                            i,
                                            duration: const Duration(
                                              milliseconds: 220,
                                            ),
                                            curve: Curves.easeOut,
                                          );
                                          setState(
                                            () => _selectedPhotoIndex = i,
                                          );
                                        },
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 180,
                                          ),
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 3,
                                          ),
                                          width: _selectedPhotoIndex == i
                                              ? 20
                                              : 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            color: _selectedPhotoIndex == i
                                                ? AppTheme.crystalGoldSoft
                                                : Colors.white.withValues(
                                                    alpha: 0.3,
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ] else ...[
                                InfoCard(
                                  icon: Icons.photo_camera_outlined,
                                  title: 'No photos yet',
                                  child: Text(
                                    'You can add photos from your profile '
                                    'settings after completing setup.',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.7,
                                      ),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],

                              const SizedBox(height: 16),

                              // ── Name & bio ──────────────────────────
                              InfoCard(
                                icon: Icons.person_outline,
                                title: draft.name.isEmpty
                                    ? 'Your name'
                                    : draft.name,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (draft.bio.isNotEmpty) ...[
                                      Text(
                                        draft.bio,
                                        maxLines: 4,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.85,
                                          ),
                                          fontSize: 14,
                                          height: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        if (draft.gender.isNotEmpty)
                                          ProfileChip(
                                            icon: Icons.wc_outlined,
                                            label: draft.gender,
                                          ),
                                        if ((draft.religion ?? '').isNotEmpty)
                                          ProfileChip(
                                            icon: Icons.auto_awesome_outlined,
                                            label: draft.religion!,
                                          ),
                                        if (draft.drinking.isNotEmpty)
                                          ProfileChip(
                                            icon: Icons.local_bar_outlined,
                                            label: draft.drinking,
                                          ),
                                        if (draft.smoking.isNotEmpty)
                                          ProfileChip(
                                            icon: Icons.smoking_rooms_outlined,
                                            label: draft.smoking,
                                          ),
                                        if (draft.heightCm != null)
                                          ProfileChip(
                                            icon: Icons.height_outlined,
                                            label: '${draft.heightCm} cm',
                                          ),
                                        if ((draft.profession ?? '').isNotEmpty)
                                          ProfileChip(
                                            icon: Icons.work_outline,
                                            label: draft.profession!,
                                          ),
                                        if ((draft.education ?? '').isNotEmpty)
                                          ProfileChip(
                                            icon: Icons.school_outlined,
                                            label: draft.education!,
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 14),

                              // ── Completion notice ───────────────────
                              if (pct < 100)
                                TipBanner(
                                  text: pct >= 80
                                      ? 'Almost there! Complete a few more '
                                            'fields to maximise your reach.'
                                      : 'Complete your profile to get better '
                                            'match suggestions ($pct% done).',
                                ),

                              if (pct < 100) const SizedBox(height: 14),

                              // ── Complete button ─────────────────────
                              _CompleteButton(draft: draft),

                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Extracted "Complete & Start Matching" button with robust error handling.
///
/// Validates the draft locally before hitting the API, provides specific
/// failure messages, and ensures navigation never breaks on error.
class _CompleteButton extends ConsumerStatefulWidget {
  const _CompleteButton({required this.draft});
  final ProfileDraft draft;

  @override
  ConsumerState<_CompleteButton> createState() => _CompleteButtonState();
}

class _CompleteButtonState extends ConsumerState<_CompleteButton> {
  bool _isSubmitting = false;

  List<String> _validate() {
    final draft = widget.draft;
    final issues = <String>[];
    if (draft.name.trim().length < ValidationConstants.minNameLength) {
      issues.add('Name is required');
    }
    if (draft.dateOfBirth == null) {
      issues.add('Date of birth is required');
    }
    if (draft.photos.length < ValidationConstants.minPhotos) {
      issues.add(
        'At least ${ValidationConstants.minPhotos} photos required '
        '(you have ${draft.photos.length})',
      );
    }
    if (draft.bio.trim().length < ValidationConstants.minBioLength) {
      issues.add(
        'Bio must be at least ${ValidationConstants.minBioLength} characters',
      );
    }
    return issues;
  }

  Future<void> _complete() async {
    final issues = _validate();
    if (issues.isNotEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(issues.join('. ')),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(profileSetupNotifierProvider.notifier).completeProfile();
      ref.invalidate(profileCompletionProvider);
      if (!context.mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
    } on StateError catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } on DioException catch (e) {
      if (!context.mounted) return;
      final status = e.response?.statusCode;
      final detail = (e.response?.data is Map)
          ? (e.response!.data as Map)['error']?.toString()
          : null;
      final msg =
          detail ??
          (status != null
              ? 'Server returned $status. Please try again.'
              : 'Network error — check your connection and try again.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 4)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unexpected error: $e'),
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => _isSubmitting
      ? const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Center(
            child: SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.crystalGoldSoft,
                ),
              ),
            ),
          ),
        )
      : GlassButton(
          label: 'Complete & Start Matching',
          shinyEffect: true,
          onPressed: _complete,
        );
}
