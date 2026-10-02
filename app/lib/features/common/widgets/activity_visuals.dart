import 'dart:ui';

import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

/// Shared look for member activities (Photo Themes, Book & Film Clubs).
///
/// Every colour comes from the active [ColorScheme], so the cards follow
/// whichever theme preset the member picked.

/// A tinted gradient for card headers. [tone] picks the colour pair so
/// neighbouring cards do not all look the same.
LinearGradient activityGradient(ColorScheme scheme, int tone) {
  final pairs = <List<Color>>[
    [scheme.primaryContainer, scheme.tertiaryContainer],
    [scheme.secondaryContainer, scheme.primaryContainer],
    [scheme.tertiaryContainer, scheme.secondaryContainer],
  ];
  final pair = pairs[tone.abs() % pairs.length];
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: pair,
  );
}

/// The bold accent that goes with [activityGradient]'s [tone].
Color activityAccent(ColorScheme scheme, int tone) =>
    [scheme.primary, scheme.secondary, scheme.tertiary][tone.abs() % 3];

/// Big welcoming header used at the top of each activity screen.
class ActivityHero extends StatelessWidget {
  const ActivityHero({
    required this.icon,
    required this.title,
    required this.subtitle,
    super.key,
    this.tone = 0,
    this.footer,
  });
  final IconData icon;
  final String title, subtitle;
  final int tone;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final accent = activityAccent(scheme, tone);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: activityGradient(scheme, tone),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(icon, color: _onAccent(scheme, tone), size: 28),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: text.headlineSmall?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: text.bodyLarge?.copyWith(color: scheme.onSurface),
            ),
            if (footer != null) ...[const SizedBox(height: 16), footer!],
          ],
        ),
      ),
    );
  }
}

Color _onAccent(ColorScheme scheme, int tone) =>
    [scheme.onPrimary, scheme.onSecondary, scheme.onTertiary][tone.abs() % 3];

/// A small pill that pairs an icon with text, so nothing relies on colour.
class CountPill extends StatelessWidget {
  const CountPill({
    required this.icon,
    required this.label,
    super.key,
    this.emphasis = false,
  });
  final IconData icon;
  final String label;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = emphasis ? scheme.primary : scheme.surface;
    final foreground = emphasis ? scheme.onPrimary : scheme.onSurface;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: emphasis ? background : scheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: foreground),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A friendly card for empty, ineligible or failed states, with one action.
class ActivityNotice extends StatelessWidget {
  const ActivityNotice({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
    this.actionLabel,
    this.onAction,
  });
  final IconData icon;
  final String title, message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 40, color: scheme.primary),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Hides spoiler text behind a frosted card until the member taps it.
///
/// The hidden text is excluded from the accessibility tree too, so a screen
/// reader does not read the spoiler aloud before the member chooses to.
class SpoilerReveal extends StatefulWidget {
  const SpoilerReveal({required this.child, super.key, this.spoiler = true});
  final Widget child;
  final bool spoiler;

  @override
  State<SpoilerReveal> createState() => _SpoilerRevealState();
}

class _SpoilerRevealState extends State<SpoilerReveal> {
  bool revealed = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.spoiler || revealed) {
      return widget.child;
    }
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          ExcludeSemantics(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: double.infinity,
                  minHeight: 64,
                  maxHeight: 96,
                ),
                child: ClipRect(
                  child: Align(
                    alignment: Alignment.topLeft,
                    heightFactor: 1,
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Material(
              color: scheme.surface.withValues(alpha: 0.72),
              child: InkWell(
                onTap: () => setState(() => revealed = true),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        AppLocalizations.of(context).communitySpoiler,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
