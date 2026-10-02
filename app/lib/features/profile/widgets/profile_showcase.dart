import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_error_message.dart';
import '../../../core/providers/api_client_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/connect_page.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../../blog/blog_screen.dart';
import '../../photo_themes/photo_theme_widgets.dart';
import '../../photo_themes/photo_themes_data.dart';
import 'profile_scenes.dart';

/// A public chapter as it appears on a profile.
class ShowcaseChapter {
  const ShowcaseChapter({
    required this.id,
    required this.title,
    required this.excerpt,
    this.publishedAt,
    this.likeCount = 0,
    this.commentCount = 0,
  });

  factory ShowcaseChapter.fromJson(Map<dynamic, dynamic> json) =>
      ShowcaseChapter(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        excerpt: json['excerpt']?.toString() ?? '',
        publishedAt: DateTime.tryParse(json['published_at']?.toString() ?? ''),
        likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
        commentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
      );

  final String id;
  final String title;
  final String excerpt;
  final DateTime? publishedAt;
  final int likeCount;
  final int commentCount;
}

/// `GET /profile/{id}/showcase`: a member's public chapters and wall photos.
/// The server returns items to other members only with the owner's consent;
/// the owner gets a preview plus their consent in [enabled].
class ProfileShowcaseData {
  const ProfileShowcaseData({
    required this.enabled,
    required this.chapters,
    required this.photos,
  });

  factory ProfileShowcaseData.fromJson(Object? data) {
    final map = data is Map ? data : const <String, Object?>{};
    List<Map<dynamic, dynamic>> list(String key) =>
        (map[key] is List ? map[key] as List : const <Object?>[])
            .whereType<Map<dynamic, dynamic>>()
            .toList();
    return ProfileShowcaseData(
      enabled: map['enabled'] == true,
      chapters: list(
        'chapters',
      ).map(ShowcaseChapter.fromJson).where((c) => c.id.isNotEmpty).toList(),
      photos: list('photos').map(ThemeEntry.fromJson).toList(),
    );
  }

  final bool enabled;
  final List<ShowcaseChapter> chapters;
  final List<ThemeEntry> photos;

  bool get isEmpty => chapters.isEmpty && photos.isEmpty;
}

final profileShowcaseProvider = FutureProvider.autoDispose
    .family<ProfileShowcaseData, String>((ref, userId) async {
      ref.watch(authNotifierProvider.select((s) => s.userId));
      final response = await ref
          .read(apiClientProvider)
          .get<dynamic>('/profile/$userId/showcase');
      return ProfileShowcaseData.fromJson(response.data);
    });

/// `GET|PUT /profile/{me}/showcase/consent`: "Show my public chapters and
/// wall photos on my profile" (default off).
class ProfileShowcaseConsentNotifier extends AutoDisposeAsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final me = ref.watch(authNotifierProvider.select((s) => s.userId));
    if (me == null) {
      return false;
    }
    final response = await ref
        .watch(apiClientProvider)
        .get<dynamic>('/profile/$me/showcase/consent');
    return _visible(response.data);
  }

  static bool _visible(Object? data) => data is Map && data['visible'] == true;

  /// Saves the choice; the switch moves at once and returns if saving fails.
  Future<void> setVisible({required bool visible}) async {
    final me = ref.read(authNotifierProvider).userId;
    if (me == null) {
      return;
    }
    final previous = state;
    state = AsyncData(visible);
    try {
      final response = await ref
          .read(apiClientProvider)
          .put<dynamic>(
            '/profile/$me/showcase/consent',
            data: {'visible': visible},
          );
      state = AsyncData(_visible(response.data));
      ref.invalidate(profileShowcaseProvider(me));
    } on Object {
      state = previous;
      rethrow;
    }
  }
}

final profileShowcaseConsentProvider =
    AsyncNotifierProvider.autoDispose<ProfileShowcaseConsentNotifier, bool>(
      ProfileShowcaseConsentNotifier.new,
    );

/// Saves the consent and reports a failure in a snack bar.
Future<void> setProfileShowcaseConsent(
  BuildContext context,
  WidgetRef ref, {
  required bool visible,
}) async {
  final failed = AppLocalizations.of(context).profileShowcaseSaveFailed;
  try {
    await ref
        .read(profileShowcaseConsentProvider.notifier)
        .setVisible(visible: visible);
  } on Object catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e, fallback: failed))),
      );
    }
  }
}

/// "Writing & moments" on a profile: the member's public chapters and wall
/// photos. Other members see it only when the owner opted in and there is
/// something public; the owner sees a preview with the switch.
class ProfileShowcaseScene extends ConsumerWidget {
  const ProfileShowcaseScene({
    required this.userId,
    super.key,
    this.isOwner = false,
  });

  final String userId;
  final bool isOwner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(profileShowcaseProvider(userId)).valueOrNull;
    if (data == null || data.isEmpty || (!isOwner && !data.enabled)) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    return ProfileScene(
      key: const ValueKey('qa.profile.showcase'),
      label: l10n.profileShowcaseLabel,
      title: isOwner
          ? l10n.profileShowcaseTitleSelf
          : l10n.profileShowcaseTitleOther,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isOwner) ...[
            const _ConsentCard(),
            const SizedBox(height: ConnectMetrics.cardGap),
          ],
          if (data.chapters.isNotEmpty) ...[
            _SubHeading(l10n.profileShowcaseChapters),
            for (final chapter in data.chapters)
              Padding(
                padding: const EdgeInsets.only(bottom: ConnectMetrics.cardGap),
                child: _ChapterCard(chapter: chapter),
              ),
          ],
          if (data.photos.isNotEmpty) ...[
            _SubHeading(l10n.profileShowcasePhotos),
            SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: data.photos.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: ConnectMetrics.cardGap),
                itemBuilder: (context, i) => SizedBox(
                  width: 150,
                  child: ThemeEntryTile(
                    entry: data.photos[i],
                    onTap: () =>
                        showThemeEntrySheet(context, entry: data.photos[i]),
                  ),
                ),
              ),
            ),
            const SizedBox(height: ConnectMetrics.cardGap),
          ],
          if (!isOwner && data.chapters.isNotEmpty)
            ConnectNavTile(
              key: const ValueKey('qa.profile.showcase.read_all'),
              icon: Icons.menu_book_outlined,
              title: l10n.profileShowcaseReadAll,
              onTap: () => openBlog(context, authorId: userId),
            ),
        ],
      ),
    );
  }
}

class _SubHeading extends StatelessWidget {
  const _SubHeading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({required this.chapter});
  final ShowcaseChapter chapter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final date = chapter.publishedAt == null
        ? null
        : DateFormat.yMMMd(
            Localizations.localeOf(context).toLanguageTag(),
          ).format(chapter.publishedAt!.toLocal());
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ConnectMetrics.cardRadius),
        side: BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openBlogPost(context, chapter.id),
        child: Padding(
          padding: const EdgeInsets.all(ConnectMetrics.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                chapter.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontFamily: AppTheme.displayFamily,
                ),
              ),
              if (chapter.excerpt.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  chapter.excerpt,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (date != null)
                    Text(
                      date,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  _Count(
                    icon: Icons.favorite_border_rounded,
                    value: chapter.likeCount,
                  ),
                  _Count(
                    icon: Icons.chat_bubble_outline_rounded,
                    value: chapter.commentCount,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.icon, required this.value});
  final IconData icon;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          '$value',
          style: theme.textTheme.labelMedium?.copyWith(color: color),
        ),
      ],
    );
  }
}

/// The owner's switch, with what it means in either state.
class _ConsentCard extends ConsumerWidget {
  const _ConsentCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final consent = ref.watch(profileShowcaseConsentProvider);
    final on = consent.valueOrNull ?? false;
    return ConnectPanel(
      color: on ? colors.surface : colors.secondaryContainer,
      padding: const EdgeInsets.symmetric(
        horizontal: ConnectMetrics.padding,
        vertical: 8,
      ),
      child: SwitchListTile(
        key: const ValueKey('qa.profile.showcase.consent'),
        contentPadding: EdgeInsets.zero,
        secondary: Icon(
          on ? Icons.public_rounded : Icons.lock_outline_rounded,
          color: colors.primary,
        ),
        title: Text(
          on ? l10n.profileShowcaseSwitch : l10n.profileShowcaseHiddenTitle,
        ),
        subtitle: Text(
          on ? l10n.profileShowcaseShownBody : l10n.profileShowcaseHiddenBody,
        ),
        value: on,
        onChanged: consent.hasValue
            ? (v) => setProfileShowcaseConsent(context, ref, visible: v)
            : null,
      ),
    );
  }
}
