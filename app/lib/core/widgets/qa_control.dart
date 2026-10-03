import 'package:flutter/material.dart';

import 'glass_widgets.dart';

/// Gives a single control a stable automation id and, when the control shows
/// no text of its own, a localized spoken label.
///
/// The id is a semantics identifier (Android resource-id, iOS
/// accessibilityIdentifier, web `flt-semantics-identifier`), never a label, so
/// screen readers keep announcing words a member understands. Everything under
/// [child] is merged into one node: the id, the [label], the control's own
/// text, its role, state (checked, value, enabled) and actions all sit on the
/// node that exactly covers the control. Appium therefore reads and taps the
/// real control by resource-id, and TalkBack/VoiceOver stop on it once.
///
/// Use it for one actionable control (a button, switch, slider, dropdown or
/// list tile). For a card or region holding several controls use `QaId`
/// (lib/core/widgets/qa_id.dart), which keeps the children as separate nodes.
class QaControl extends StatelessWidget {
  const QaControl({
    required this.id,
    required this.child,
    this.label,
    this.button = false,
    this.enabled,
    super.key,
  });

  /// The `qa.*` automation id.
  final String id;

  /// Localized spoken name, for controls whose child carries no text (icon
  /// buttons, switches, sliders). Leave null when the child shows its label.
  final String? label;

  /// Marks a custom tappable (a GestureDetector or InkWell) as a button.
  /// Material buttons already say so themselves.
  final bool button;

  /// Enabled state of the merged node. Read from common material controls
  /// when left null; pass it for a custom control that can be disabled.
  final bool? enabled;

  final Widget child;

  /// Whether [child] is a control that can be disabled, and if so whether it
  /// is enabled now.
  ///
  /// Merging puts the control's own enabled flag one level down; the merged
  /// node repeats it so tools that read the node's own flags (accessibility
  /// guideline checks, which skip disabled controls) see the same state a
  /// screen reader announces.
  static bool? _enabledOf(Widget child) => switch (child) {
    ButtonStyleButton() => child.enabled,
    IconButton(:final onPressed) => onPressed != null,
    GlassButton(:final onPressed) => onPressed != null,
    ListTile(:final enabled) => enabled,
    Switch(:final onChanged) => onChanged != null,
    Slider(:final onChanged) => onChanged != null,
    _ => null,
  };

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Semantics(
      identifier: id,
      label: label,
      button: button ? true : null,
      enabled: enabled ?? _enabledOf(child),
      child: child,
    ),
  );
}
