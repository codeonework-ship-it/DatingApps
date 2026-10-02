import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_error_message.dart';
import '../../core/widgets/glass_widgets.dart';
import '../auth/providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';
import '../common/widgets/activity_visuals.dart';
import 'photo_theme_gallery_screen.dart';
import 'photo_themes_data.dart';

/// An emoji for each seeded prompt; new prompts fall back to a camera.
const photoThemeEmoji = <String, String>{
  'perfect-sunday': '☀️',
  'something-i-made': '🎨',
  'view-i-love': '🌆',
  'comfort-food': '🍜',
  'where-i-feel-like-me': '📍',
  'little-ritual': '☕',
};

String emojiForTheme(String slug) => photoThemeEmoji[slug] ?? '📸';

Future<void> openPhotoThemes(BuildContext context) => Navigator.of(
  context,
).push<void>(MaterialPageRoute(builder: (_) => const PhotoThemesScreen()));

/// Every active photo prompt. One photo per prompt, shared with signed-in
/// members who can take part.
class PhotoThemesScreen extends ConsumerWidget {
  const PhotoThemesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider.select((s) => s.userId));
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.photoThemesTitle)),
      body: PostLoginBackdrop(
        child: user == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(l10n.photoThemesSignIn),
                ),
              )
            : RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(photoThemesProvider);
                  await ref.read(photoThemesProvider.future);
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
                  children: [
                    ActivityHero(
                      icon: Icons.photo_library_outlined,
                      title: l10n.photoThemesHeroTitle,
                      subtitle: l10n.photoThemesHeroSubtitle,
                    ),
                    const SizedBox(height: 16),
                    ref
                        .watch(photoThemesProvider)
                        .when(
                          skipLoadingOnRefresh: false,
                          loading: () => const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (e, _) => ActivityNotice(
                            icon: Icons.cloud_off_outlined,
                            title: l10n.photoThemesLoadFailed,
                            message: apiErrorMessage(
                              e,
                              fallback: l10n.photoThemesCheckConnection,
                            ),
                            actionLabel: l10n.photoThemesTryAgain,
                            onAction: () => ref.invalidate(photoThemesProvider),
                          ),
                          data: (list) => _ThemeList(list: list),
                        ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _ThemeList extends StatelessWidget {
  const _ThemeList({required this.list});
  final PhotoThemeList list;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!list.eligible) ...[
          ActivityNotice(
            icon: Icons.lock_outline,
            title: l10n.photoThemesLookAround,
            message: list.eligibilityMessage.isEmpty
                ? l10n.photoThemesEligibilityShareOwn
                : list.eligibilityMessage,
          ),
          const SizedBox(height: 16),
        ],
        if (list.themes.isEmpty)
          ActivityNotice(
            icon: Icons.photo_camera_outlined,
            title: l10n.photoThemesNewPromptsTitle,
            message: l10n.photoThemesNewPromptsBody,
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 640 ? 2 : 1;
              final width =
                  (constraints.maxWidth - 16 * (columns - 1)) / columns;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final (index, theme) in list.themes.indexed)
                    SizedBox(
                      width: width,
                      child: PhotoThemeCard(theme: theme, tone: index),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}

class PhotoThemeCard extends StatelessWidget {
  const PhotoThemeCard({required this.theme, super.key, this.tone = 0});
  final PhotoTheme theme;
  final int tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => PhotoThemeGalleryScreen(themeId: theme.id),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: activityGradient(scheme, tone),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ExcludeSemantics(
                      child: Text(
                        emojiForTheme(theme.slug),
                        style: const TextStyle(fontSize: 36),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        theme.title,
                        style: text.titleLarge?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(theme.prompt, style: text.bodyLarge),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      CountPill(
                        icon: Icons.photo_outlined,
                        label: l10n.photoThemesSharedCount(theme.entryCount),
                      ),
                      if (theme.shared)
                        CountPill(
                          icon: Icons.check_circle_outline,
                          label: l10n.photoThemesYouShared,
                          emphasis: true,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    theme.entryCount == 0
                        ? l10n.photoThemesBeFirst
                        : l10n.photoThemesSeeEveryone,
                    style: text.labelLarge?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
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
}
