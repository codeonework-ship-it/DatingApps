import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/couture.dart';

/// The Today look, shared by every screen: a flat ground, a tracked eyebrow
/// over a serif title, quiet paper cards with a hairline border, and colours
/// that come only from the member's chosen theme.

/// The one ruler the app's pages are built on, taken from Today.
abstract final class ConnectMetrics {
  /// Between sections.
  static const double sectionGap = 32;

  /// Between a section header and its content, and between cards.
  static const double cardGap = 12;

  /// Inside compact cards (grid tiles, carousel cards).
  static const double padding = 16;

  /// Inside panels and feature cards.
  static const double paddingLarge = 20;

  /// Cards: tiles, panels, carousel cards.
  static const double cardRadius = 20;

  /// Feature cards.
  static const double featureRadius = 24;

  /// Side gutter on phones and on wider screens.
  static double gutterFor(double width) => width < 600 ? 20 : 40;
}

/// A page header in the Today style: an uppercase eyebrow, a serif headline,
/// an optional one-line promise and optional actions beside the eyebrow.
class ConnectPageHeader extends StatelessWidget {
  const ConnectPageHeader({
    required this.eyebrow,
    required this.title,
    super.key,
    this.subtitle,
    this.actions = const [],
    this.leading,
  });

  /// Uppercase eyebrow, e.g. "SETTINGS".
  final String eyebrow;
  final String title;
  final String? subtitle;
  final List<Widget> actions;

  /// Optional control before the eyebrow, such as a back button.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final phone = MediaQuery.sizeOf(context).width < 600;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 4)],
            const CoutureRule(width: 20),
            Expanded(
              child: Text(
                eyebrow,
                style: theme.textTheme.labelMedium?.copyWith(
                  letterSpacing: 2.4,
                  fontWeight: FontWeight.w700,
                  color: colors.primary,
                ),
              ),
            ),
            ...actions,
          ],
        ),
        SizedBox(height: actions.isEmpty && leading == null ? 8 : 0),
        Semantics(
          header: true,
          child: Text(
            title,
            style: theme.textTheme.displaySmall?.copyWith(
              fontFamily: AppTheme.displayFamily,
              fontSize: phone ? 32 : 44,
              height: 1.12,
              letterSpacing: -0.8,
              color: colors.onSurface,
            ),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// The section header used by every section: a small tracked eyebrow, an
/// optional serif title, an optional caption, and an optional trailing
/// action aligned to the eyebrow.
class ConnectSectionHeader extends StatelessWidget {
  const ConnectSectionHeader({
    required this.label,
    super.key,
    this.title,
    this.caption,
    this.trailing,
  });

  /// Uppercase eyebrow, e.g. "YOUR PACE".
  final String label;
  final String? title;
  final String? caption;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CoutureRule(),
            Flexible(
              child: Semantics(
                header: title == null,
                child: Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                    color: colors.primary,
                  ),
                ),
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
              style: theme.textTheme.headlineSmall?.copyWith(
                fontFamily: AppTheme.displayFamily,
                height: 1.2,
              ),
            ),
          ),
        ],
        if (caption != null) ...[
          const SizedBox(height: 4),
          Text(
            caption!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
    if (trailing == null) {
      return text;
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: text),
        const SizedBox(width: 8),
        trailing!,
      ],
    );
  }
}

/// A quiet surface card with the card radius and the look's bevelled
/// hairline (see [Couture]).
class ConnectPanel extends StatelessWidget {
  const ConnectPanel({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(ConnectMetrics.paddingLarge),
    this.radius = ConnectMetrics.cardRadius,
    this.color,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final corners = BorderRadius.circular(radius);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: Couture.panel(context, radius: corners, color: color),
      foregroundDecoration: Couture.panelRim(context, radius: corners),
      padding: padding,
      child: child,
    );
  }
}

/// A tappable row card: a tinted round icon, a title and a caption, and a
/// chevron. Used for lists of destinations (Settings, Engage).
class ConnectNavTile extends StatelessWidget {
  const ConnectNavTile({
    required this.icon,
    required this.title,
    required this.onTap,
    super.key,
    this.subtitle,
    this.tint,
    this.trailing,
    this.semanticLabel,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  /// Icon colour; the theme's primary by default.
  final Color? tint;
  final Widget? trailing;

  /// Overrides the accessibility label (used by automation).
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final accent = tint ?? colors.primary;
    final radius = BorderRadius.circular(ConnectMetrics.cardRadius);
    final preset = Couture.presetOf(context);
    final tile = Material(
      color: Colors.transparent,
      child: Ink(
        decoration: preset == null
            ? BoxDecoration(
                color: colors.surface,
                borderRadius: radius,
                border: Border.all(color: colors.outlineVariant),
              )
            : ShapeDecoration(
                gradient: Couture.satin(preset),
                color: Couture.satin(preset) == null ? preset.paper : null,
                shape: Couture.rim(preset, radius: radius),
              ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ConnectMetrics.padding,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      // A ring in the look's trim, like a set stone.
                      border: preset == null
                          ? null
                          : Border.all(
                              color: preset.trim.withValues(alpha: 0.38),
                            ),
                    ),
                    child: Icon(icon, color: accent, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.onSurface,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
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
    );
    if (semanticLabel == null) {
      return Semantics(button: true, child: tile);
    }
    return Semantics(
      label: semanticLabel,
      button: true,
      onTap: onTap,
      child: tile,
    );
  }
}
