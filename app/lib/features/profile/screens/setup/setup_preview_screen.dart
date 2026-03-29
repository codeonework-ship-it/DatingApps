import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_widgets.dart';
import '../../providers/profile_completion_provider.dart';
import '../../providers/profile_setup_provider.dart';

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
      error: (_, _) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => ref.invalidate(profileSetupNotifierProvider),
            child: const Text('Retry'),
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 14, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new,
                              color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Profile preview',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Step 3 of 3  ·  How others see you',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Completion badge
                        _CompletionBadge(percent: pct),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Step bar ─────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _StepBar(step: 3, total: 3),
                  ),

                  const SizedBox(height: 14),

                  // ── Scrollable content ───────────────────────────────
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── Photo carousel ──────────────────────────
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
                                        () => _selectedPhotoIndex = index);
                                  },
                                  itemCount: photoUrls.length,
                                  itemBuilder: (context, index) =>
                                      Image.network(
                                    photoUrls[index],
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
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
                                        duration:
                                            const Duration(milliseconds: 220),
                                        curve: Curves.easeOut,
                                      );
                                      setState(() => _selectedPhotoIndex = i);
                                    },
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 180),
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 3),
                                      width:
                                          _selectedPhotoIndex == i ? 20 : 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(4),
                                        color: _selectedPhotoIndex == i
                                            ? AppTheme.crystalGoldSoft
                                            : Colors.white
                                                .withValues(alpha: 0.3),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ] else ...[
                            // No-photo placeholder
                            _PreviewCard(
                              icon: Icons.photo_camera_outlined,
                              title: 'No photos yet',
                              child: Text(
                                'You can add photos from your profile settings after completing setup.',
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 14),
                              ),
                            ),
                          ],

                          const SizedBox(height: 16),

                          // ── Name & bio ──────────────────────────────
                          _PreviewCard(
                            icon: Icons.person_outline,
                            title: draft.name.isEmpty ? 'Your name' : draft.name,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (draft.bio.isNotEmpty) ...[
                                  Text(
                                    draft.bio,
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.85),
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
                                      _Chip(
                                          icon: Icons.wc_outlined,
                                          label: draft.gender),
                                    if ((draft.religion ?? '').isNotEmpty)
                                      _Chip(
                                          icon: Icons.auto_awesome_outlined,
                                          label: draft.religion!),
                                    if ((draft.drinking).isNotEmpty)
                                      _Chip(
                                          icon: Icons.local_bar_outlined,
                                          label: draft.drinking),
                                    if ((draft.smoking).isNotEmpty)
                                      _Chip(
                                          icon: Icons.smoking_rooms_outlined,
                                          label: draft.smoking),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // ── Completion notice ───────────────────────
                          if (pct < 100)
                            _TipBanner(
                              text: pct >= 80
                                  ? 'Almost there! Complete a few more fields to maximise your reach.'
                                  : 'Complete your profile to get better match suggestions ($pct% done).',
                            ),

                          if (pct < 100) const SizedBox(height: 14),

                          // ── Complete button ─────────────────────────
                          GlassButton(
                            label: 'Complete & Start Matching',
                            shinyEffect: true,
                            onPressed: () async {
                              try {
                                await ref
                                    .read(profileSetupNotifierProvider.notifier)
                                    .completeProfile();
                                ref.invalidate(profileCompletionProvider);
                                if (!context.mounted) return;
                                Navigator.of(context)
                                    .popUntil((r) => r.isFirst);
                              } catch (_) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please complete all required fields '
                                      '(min ${ValidationConstants.minPhotos} photos, bio, and basic info).',
                                    ),
                                  ),
                                );
                              }
                            },
                          ),

                          const SizedBox(height: 24),
                        ],
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

// ── Helper widgets ───────────────────────────────────────────────────────────

/// Frosted-glass card matching _PrefCard / _PhotoCard pattern.
class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        border: Border.all(
          color: AppTheme.crystalGoldSoft.withValues(alpha: 0.25),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.crystalGoldSoft, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.crystalGoldSoft,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _CompletionBadge extends StatelessWidget {
  const _CompletionBadge({required this.percent});
  final int percent;

  @override
  Widget build(BuildContext context) {
    final color = percent >= 80
        ? AppTheme.crystalGoldSoft
        : percent >= 50
            ? Colors.orangeAccent
            : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$percent%',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _StepBar extends StatelessWidget {
  const _StepBar({required this.step, required this.total});
  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total * 2 - 1, (i) {
        if (i.isOdd) return const SizedBox(width: 6);
        final idx = i ~/ 2 + 1;
        final active = idx <= step;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: active
                  ? AppTheme.crystalGoldSoft
                  : Colors.white.withValues(alpha: 0.2),
            ),
          ),
        );
      }),
    );
  }
}

class _TipBanner extends StatelessWidget {
  const _TipBanner({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.crystalGoldSoft.withValues(alpha: 0.12),
        border: Border.all(
            color: AppTheme.crystalGoldSoft.withValues(alpha: 0.30)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline,
              size: 16, color: AppTheme.crystalGoldSoft),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        border: Border.all(
            color: AppTheme.crystalGoldSoft.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.crystalGoldSoft),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
                color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
