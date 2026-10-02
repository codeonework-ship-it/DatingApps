import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/connect_page.dart';
import '../../l10n/app_localizations.dart';
import '../auth/providers/auth_provider.dart';
import 'groups_data.dart';

/// Cover colour roles a group may pick, with their display labels; resolved
/// from the member's theme so every theme keeps its contrast.
Map<String, String> groupCoverColors(AppLocalizations l10n) => {
  'primary': l10n.groupsCoverColorTheme,
  'secondary': l10n.groupsCoverColorAccent,
  'tertiary': l10n.groupsCoverColorWarm,
};

/// The background and foreground for a cover colour role.
(Color, Color) groupCoverTones(ColorScheme colors, String role) =>
    switch (role) {
      'secondary' => (colors.secondaryContainer, colors.onSecondaryContainer),
      'tertiary' => (colors.tertiaryContainer, colors.onTertiaryContainer),
      _ => (colors.primaryContainer, colors.onPrimaryContainer),
    };

/// A rounded emoji tile in the group's cover colour.
class GroupCover extends StatelessWidget {
  const GroupCover({
    required this.emoji,
    required this.color,
    super.key,
    this.size = 56,
  });
  final String emoji;
  final String color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (background, _) = groupCoverTones(
      Theme.of(context).colorScheme,
      color,
    );
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(size * 0.32),
        ),
        child: Text(emoji, style: TextStyle(fontSize: size * 0.5)),
      ),
    );
  }
}

/// A group's cover photo, loaded through the authenticated API. Shows
/// [fallback] (the emoji cover) while loading, on errors and when the group
/// has no photo this member may see.
class GroupCoverPhoto extends ConsumerWidget {
  const GroupCoverPhoto({
    required this.group,
    required this.fallback,
    super.key,
    this.fit = BoxFit.cover,
  });
  final Group group;
  final Widget fallback;
  final BoxFit fit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider.select((s) => s.userId));
    if (user == null || !group.hasCoverPhoto) {
      return fallback;
    }
    final bytes = ref
        .watch(
          groupCoverPhotoProvider((
            user: user,
            group: group.id,
            cover: group.coverPhotoId,
          )),
        )
        .valueOrNull;
    if (bytes == null || bytes.isEmpty) {
      return fallback;
    }
    return ExcludeSemantics(
      child: Image.memory(
        bytes,
        key: ValueKey('groups.cover.photo.${group.coverPhotoId}'),
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}

/// The square cover on a group card: the photo when there is one, else the
/// emoji tile.
class GroupCoverThumb extends StatelessWidget {
  const GroupCoverThumb({required this.group, super.key, this.size = 56});
  final Group group;
  final double size;

  @override
  Widget build(BuildContext context) {
    final emoji = GroupCover(
      emoji: group.emoji,
      color: group.coverColor,
      size: size,
    );
    if (!group.hasCoverPhoto) {
      return emoji;
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.32),
      child: SizedBox(
        width: size,
        height: size,
        child: GroupCoverPhoto(group: group, fallback: emoji),
      ),
    );
  }
}

/// A wide banner of the group's cover photo with a bottom scrim so the
/// white caption over it keeps AA contrast on any photo. Without a photo it
/// shows the emoji cover in the group's colour role.
class GroupCoverBanner extends StatelessWidget {
  const GroupCoverBanner({
    required this.group,
    super.key,
    this.caption = '',
    this.badge,
  });
  final Group group;

  /// Text over the bottom of the photo, e.g. "📚 Books".
  final String caption;

  /// A solid badge in the top corner, e.g. "Under review".
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (background, _) = groupCoverTones(colors, group.coverColor);
    final fallback = ColoredBox(
      color: background,
      child: Center(
        child: ExcludeSemantics(
          child: Text(group.emoji, style: const TextStyle(fontSize: 48)),
        ),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(ConnectMetrics.cardRadius),
      child: AspectRatio(
        aspectRatio: 3,
        child: Stack(
          fit: StackFit.expand,
          children: [
            GroupCoverPhoto(group: group, fallback: fallback),
            if (group.hasCoverPhoto && caption.isNotEmpty) ...[
              // Opaque enough at the text line for white text to pass AA
              // over a pure white photo.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.35, 0.7, 1],
                    colors: [
                      Color(0x00000000),
                      Color(0xB3000000),
                      Color(0xD9000000),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 12,
                child: Text(
                  caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            if (badge != null) Positioned(top: 12, left: 12, child: badge!),
          ],
        ),
      ),
    );
  }
}

/// A solid status badge for a cover, e.g. "Under review".
class GroupCoverBadge extends StatelessWidget {
  const GroupCoverBadge({required this.label, super.key, this.icon});
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: colors.onSecondaryContainer),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colors.onSecondaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// A member's photo, or their initial on a tinted disc.
class GroupAvatar extends StatelessWidget {
  const GroupAvatar({
    required this.name,
    required this.photoUrl,
    super.key,
    this.radius = 20,
  });
  final String name;
  final String photoUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final initial = name.trim().isEmpty
        ? '?'
        : name.trim().characters.first.toUpperCase();
    return CircleAvatar(
      radius: radius,
      backgroundColor: colors.secondaryContainer,
      foregroundImage: photoUrl.startsWith('http')
          ? NetworkImage(photoUrl)
          : null,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: radius * 0.8,
          fontWeight: FontWeight.w700,
          color: colors.onSecondaryContainer,
        ),
      ),
    );
  }
}

/// A small pill, e.g. "📚 Books" or "12 members".
class GroupPill extends StatelessWidget {
  const GroupPill({required this.label, super.key, this.emphasis = false});
  final String label;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: emphasis ? colors.primaryContainer : colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: emphasis ? colors.onPrimaryContainer : colors.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// A group row card: cover, name, category or kind, members and an optional
/// trailing action (Join, unread badge).
class GroupCard extends StatelessWidget {
  const GroupCard({
    required this.group,
    required this.onTap,
    super.key,
    this.trailing,
    this.muted = false,
  });
  final Group group;
  final VoidCallback onTap;
  final Widget? trailing;

  /// The member muted this group's chat notifications.
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final radius = BorderRadius.circular(ConnectMetrics.cardRadius);
    final caption = [
      if (group.removed) l10n.groupsCardRemoved,
      if (group.isCommunity && group.categoryTitle.isNotEmpty)
        group.categoryTitle
      else
        group.kindLabel(l10n),
      group.memberLabel(l10n),
      if (group.city.isNotEmpty) group.city,
    ].join(' · ');
    return Semantics(
      button: true,
      label: muted
          ? l10n.groupsCardSemanticsMuted(group.name, caption)
          : '${group.name}, $caption',
      excludeSemantics: trailing == null,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: radius,
            border: Border.all(color: colors.outlineVariant),
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 80),
              child: Padding(
                padding: const EdgeInsets.all(ConnectMetrics.padding),
                child: Row(
                  children: [
                    GroupCoverThumb(group: group),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  group.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: colors.onSurface,
                                  ),
                                ),
                              ),
                              if (muted) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.notifications_off_outlined,
                                  key: ValueKey('groups.muted.${group.id}'),
                                  size: 16,
                                  color: colors.onSurfaceVariant,
                                  semanticLabel: l10n.groupsNotificationsMuted,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            caption,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    trailing ??
                        Icon(
                          Icons.chevron_right_rounded,
                          color: colors.onSurfaceVariant,
                        ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// An unread-messages badge for a group card.
class GroupUnreadBadge extends StatelessWidget {
  const GroupUnreadBadge({required this.count, super.key});
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: AppLocalizations.of(context).groupsUnreadMessages(count),
      child: ExcludeSemantics(
        child: Container(
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            count > 99 ? '99+' : '$count',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colors.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

/// A quiet message panel for empty and error states.
class GroupNotice extends StatelessWidget {
  const GroupNotice({
    required this.title,
    required this.message,
    super.key,
    this.icon = Icons.groups_2_outlined,
    this.actionLabel,
    this.onAction,
  });
  final String title, message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return ConnectPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.primary),
          const SizedBox(height: 8),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

/// A bottom sheet frame in the Today look with a title and scrolling body.
Future<T?> showGroupSheet<T>(BuildContext context, Widget child) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => child,
    );

class GroupSheetFrame extends StatelessWidget {
  const GroupSheetFrame({
    required this.title,
    required this.children,
    super.key,
    this.subtitle,
    this.footer,
  });
  final String title;
  final String? subtitle;
  final List<Widget> children;

  /// Pinned under the scrolling body (e.g. the confirm button).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                children: children,
              ),
            ),
            if (footer != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: footer,
              ),
          ],
        ),
      ),
    );
  }
}
