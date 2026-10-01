import 'package:flutter/widgets.dart';

/// Layout grid and responsive rules for the app.
///
/// Before this existed, only 9 of ~114 source files consulted the viewport at
/// all, and screen padding was written per-screen (24 here, 26 there, 16
/// elsewhere). That is what makes controls look subtly out of line from screen
/// to screen: nothing shares a ruler.
///
/// Everything below hangs off one 4pt base unit, which is what keeps optical
/// alignment consistent once the same values are reused everywhere.
class AppLayout {
  AppLayout._();

  // ==========================================================================
  // SPACING — a 4pt grid
  // ==========================================================================
  //
  // Use these instead of literals. Skipping steps is fine; inventing values
  // between them is what breaks vertical rhythm.

  /// 4 — hairline gaps, icon-to-label.
  static const double space1 = 4;

  /// 8 — inside a control.
  static const double space2 = 8;

  /// 12 — related items in a row.
  static const double space3 = 12;

  /// 16 — default gap between controls.
  static const double space4 = 16;

  /// 20 — screen gutter on compact.
  static const double space5 = 20;

  /// 24 — card padding.
  static const double space6 = 24;

  /// 32 — between groups.
  static const double space8 = 32;

  /// 40 — between sections.
  static const double space10 = 40;

  /// 56 — major break.
  static const double space14 = 56;

  // ==========================================================================
  // BREAKPOINTS — Material 3 window size classes
  // ==========================================================================
  //
  // These are the industry-standard cut points, so they line up with what
  // Android and iOS themselves consider a phone, a large phone/small tablet,
  // and a tablet.

  /// Phones in portrait. Below this width, content runs full-bleed to the
  /// gutters.
  static const double compactMaxWidth = 600;

  /// Large phones in landscape and small tablets.
  static const double mediumMaxWidth = 840;

  // ==========================================================================
  // ACCESSIBILITY
  // ==========================================================================

  /// Minimum hit target on every interactive control, per both the Material and
  /// Human Interface guidelines. Anything smaller is a defect, not a style.
  static const double minTapTarget = 48;
}

/// Which window size class the current viewport falls into.
enum AppWindowClass { compact, medium, expanded }

extension AppWindowClassX on AppWindowClass {
  bool get isCompact => this == AppWindowClass.compact;
  bool get isMedium => this == AppWindowClass.medium;
  bool get isExpanded => this == AppWindowClass.expanded;

  /// True for anything wider than a phone, where a full-bleed column would
  /// stretch text past a comfortable reading measure.
  bool get isWide => this != AppWindowClass.compact;
}

/// Viewport-derived layout metrics.
extension AppLayoutContext on BuildContext {
  AppWindowClass get windowClass {
    final width = MediaQuery.sizeOf(this).width;
    if (width < AppLayout.compactMaxWidth) {
      return AppWindowClass.compact;
    }
    if (width < AppLayout.mediumMaxWidth) {
      return AppWindowClass.medium;
    }
    return AppWindowClass.expanded;
  }

  /// The horizontal screen margin. Wider viewports get a wider gutter so the
  /// content block stays visually centred rather than clinging to the bezel.
  double get gutter {
    switch (windowClass) {
      case AppWindowClass.compact:
        return AppLayout.space5;
      case AppWindowClass.medium:
        return AppLayout.space8;
      case AppWindowClass.expanded:
        return AppLayout.space10;
    }
  }

  /// The widest the content column is allowed to grow.
  ///
  /// Unbounded on phones — there the gutters already constrain it. On tablets a
  /// cap is what stops a form turning into a single 1000px-wide line of inputs,
  /// which is the most common way an app "works" on tablet while looking
  /// obviously unconsidered.
  double get contentMaxWidth {
    switch (windowClass) {
      case AppWindowClass.compact:
        return double.infinity;
      case AppWindowClass.medium:
        return 640;
      case AppWindowClass.expanded:
        return 720;
    }
  }

  /// True when the user has dialled text size up far enough that fixed-height
  /// rows will clip. Layouts should switch to wrapping at this point.
  bool get isLargeTextScale =>
      MediaQuery.textScalerOf(this).scale(16) / 16 >= 1.3;
}

/// Centres its child in a gutter-padded column of at most [BuildContext
/// .contentMaxWidth].
///
/// This is the single place screen padding should come from. A screen that uses
/// it is aligned to the same ruler as every other screen, at every size.
class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({
    required this.child,
    super.key,
    this.padTop = false,
    this.padBottom = false,
    this.maxWidth,
  });

  final Widget child;

  /// Apply the gutter vertically as well. Off by default because most screens
  /// manage their own top/bottom rhythm.
  final bool padTop;
  final bool padBottom;

  /// Override the width cap for screens that genuinely want a wider measure,
  /// such as a media grid.
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final horizontal = context.gutter;
    final cap = maxWidth ?? context.contentMaxWidth;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontal,
        padTop ? horizontal : 0,
        horizontal,
        padBottom ? horizontal : 0,
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: cap),
          child: child,
        ),
      ),
    );
  }
}

/// Lays children out in a row on wide viewports and a column on compact ones.
///
/// Side-by-side controls are the single most common source of overflow on small
/// phones: a pair of buttons that fits at 430pt clips at 320pt. Switching axis
/// removes the failure instead of shrinking the text until it fits.
class ResponsiveRow extends StatelessWidget {
  const ResponsiveRow({
    required this.children,
    super.key,
    this.spacing = AppLayout.space3,
    this.forceColumn = false,
  });

  final List<Widget> children;
  final double spacing;

  /// Stay stacked regardless of width.
  final bool forceColumn;

  @override
  Widget build(BuildContext context) {
    final stacked = forceColumn || context.windowClass.isCompact;

    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(height: spacing),
            children[i],
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(width: spacing),
          Expanded(child: children[i]),
        ],
      ],
    );
  }
}
