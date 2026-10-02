import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../core/network/api_error_message.dart';
import '../../core/providers/api_client_provider.dart';
import '../../core/widgets/glass_widgets.dart';
import '../auth/providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';
import '../common/widgets/activity_visuals.dart';
import '../common/widgets/community_actions.dart';
import 'photo_theme_widgets.dart';
import 'photo_themes_data.dart';
import 'photo_themes_screen.dart';

/// Everyone's photos for one theme, newest first, plus the member's own
/// "Share your photo" action.
class PhotoThemeGalleryScreen extends ConsumerStatefulWidget {
  const PhotoThemeGalleryScreen({required this.themeId, super.key});
  final String themeId;

  @override
  ConsumerState<PhotoThemeGalleryScreen> createState() =>
      _PhotoThemeGalleryScreenState();
}

class _PhotoThemeGalleryScreenState
    extends ConsumerState<PhotoThemeGalleryScreen> {
  final cursors = <String>[''];
  bool sharing = false;

  ThemeEntriesQuery query(String before) =>
      (theme: widget.themeId, before: before);

  void reload() {
    invalidatePhotoThemes(ref);
    setState(() {
      cursors
        ..clear()
        ..add('');
    });
  }

  Future<void> share() async {
    final l10n = AppLocalizations.of(context);
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 88,
    );
    if (file == null || !mounted) {
      return;
    }
    final details = await askEntryDetails(context);
    if (details == null || !mounted) {
      return;
    }
    setState(() => sharing = true);
    try {
      final bytes = await file.readAsBytes();
      if (bytes.length > 10 * 1024 * 1024) {
        throw StateError('Photo exceeds 10 MB.');
      }
      await uploadThemeEntry(
        ref.read(apiClientProvider),
        themeId: widget.themeId,
        entryId: const Uuid().v4(),
        bytes: bytes,
        filename: file.name,
        caption: details.caption,
        altText: details.alt,
        allowFeaturing: details.allowFeaturing,
      );
      if (!mounted) {
        return;
      }
      reload();
      showCommunitySnack(context, l10n.photoThemesSharedSnack);
    } on Object catch (e) {
      if (mounted) {
        showCommunitySnack(
          context,
          apiErrorMessage(e, fallback: l10n.photoThemesShareFailed),
        );
      }
    } finally {
      if (mounted) {
        setState(() => sharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authNotifierProvider.select((s) => s.userId));
    final l10n = AppLocalizations.of(context);
    final list = ref.watch(photoThemesProvider).valueOrNull;
    final pages = [
      for (final cursor in cursors)
        ref.watch(themeEntriesProvider(query(cursor))),
    ];
    final first = pages.first.valueOrNull;
    final theme =
        first?.theme ??
        list?.themes.where((t) => t.id == widget.themeId).firstOrNull;
    final eligible = list?.eligible ?? false;
    final shared = theme?.shared ?? false;
    final canShare = user != null && eligible && !shared && !sharing;
    final blockedReason = list == null
        ? null
        : !eligible
        ? (list.eligibilityMessage.isEmpty
              ? l10n.photoThemesEligibilityShare
              : list.eligibilityMessage)
        : shared
        ? l10n.photoThemesAlreadyShared
        : null;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(theme?.title ?? l10n.photoThemesThemeFallback),
      ),
      floatingActionButton: user == null
          ? null
          : FloatingActionButton.extended(
              onPressed: canShare ? share : null,
              tooltip: blockedReason ?? l10n.photoThemesShareTooltip,
              backgroundColor: canShare
                  ? scheme.primary
                  : scheme.surfaceContainerHighest,
              foregroundColor: canShare
                  ? scheme.onPrimary
                  : scheme.onSurfaceVariant,
              icon: Icon(
                shared
                    ? Icons.check_circle_outline
                    : Icons.add_a_photo_outlined,
              ),
              label: Text(
                shared
                    ? l10n.photoThemesYouShared
                    : l10n.photoThemesShareYourPhoto,
              ),
            ),
      body: PostLoginBackdrop(
        child: user == null
            ? Center(child: Text(l10n.photoThemesSignIn))
            : RefreshIndicator(
                onRefresh: () async {
                  reload();
                  await ref.read(themeEntriesProvider(query('')).future);
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
                  children: [
                    _PromptBanner(theme: theme, blockedReason: blockedReason),
                    if (sharing) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(),
                    ],
                    const SizedBox(height: 16),
                    _Grid(
                      pages: pages,
                      onRetry: reload,
                      onMore: (next) => setState(() => cursors.add(next)),
                      emptyTitle: theme == null
                          ? l10n.photoThemesNoPhotosYet
                          : l10n.photoThemesBeFirstFor(theme.title),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _PromptBanner extends StatelessWidget {
  const _PromptBanner({required this.theme, required this.blockedReason});
  final PhotoTheme? theme;
  final String? blockedReason;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final theme = this.theme;
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: activityGradient(scheme, 0),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Text(
                emojiForTheme(theme?.slug ?? ''),
                style: const TextStyle(fontSize: 40),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              theme?.prompt ?? l10n.photoThemesLoadingPrompt,
              style: text.titleLarge?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (theme != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
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
            ],
            if (blockedReason != null) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 20, color: scheme.onSurface),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      blockedReason!,
                      style: text.bodyMedium?.copyWith(color: scheme.onSurface),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({
    required this.pages,
    required this.onRetry,
    required this.onMore,
    required this.emptyTitle,
  });
  final List<AsyncValue<ThemeEntryPage>> pages;
  final VoidCallback onRetry;
  final ValueChanged<String> onMore;
  final String emptyTitle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final failed = pages.where((p) => p.hasError && !p.isLoading).firstOrNull;
    if (failed != null && pages.first.hasError) {
      return ActivityNotice(
        icon: Icons.cloud_off_outlined,
        title: l10n.photoThemesPhotosLoadFailed,
        message: apiErrorMessage(
          failed.error!,
          fallback: l10n.photoThemesCheckConnection,
        ),
        actionLabel: l10n.photoThemesTryAgain,
        onAction: onRetry,
      );
    }
    final seen = <String>{};
    final entries = [
      for (final page in pages)
        for (final entry in page.valueOrNull?.entries ?? const <ThemeEntry>[])
          if (seen.add(entry.id)) entry,
    ];
    final loading = pages.any((p) => p.isLoading);
    final next = pages.last.valueOrNull?.next ?? '';
    if (entries.isEmpty && !loading) {
      return ActivityNotice(
        icon: Icons.add_a_photo_outlined,
        title: emptyTitle,
        message: l10n.photoThemesEmptyMessage,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 720 ? 3 : 2;
            final width = (constraints.maxWidth - 12 * (columns - 1)) / columns;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final entry in entries)
                  SizedBox(
                    width: width,
                    child: ThemeEntryTile(
                      entry: entry,
                      onTap: () => showThemeEntrySheet(context, entry: entry),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        if (loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          )
        else if (failed != null)
          Center(
            child: TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.photoThemesMoreFailed),
            ),
          )
        else if (next.isNotEmpty)
          Center(
            child: OutlinedButton.icon(
              onPressed: () => onMore(next),
              icon: const Icon(Icons.expand_more),
              label: Text(l10n.photoThemesLoadMore),
            ),
          ),
      ],
    );
  }
}
