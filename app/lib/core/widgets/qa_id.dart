import 'package:flutter/widgets.dart';

/// Gives [child] a stable automation id without touching what screen readers
/// say.
///
/// The id is a semantics identifier: Android exposes it as the view's
/// resource-id, iOS as accessibilityIdentifier and the web as
/// `flt-semantics-identifier`. Appium (qa/appium/helpers.py) and widget tests
/// (`find.bySemanticsIdentifier`) locate controls by it, while TalkBack and
/// VoiceOver keep announcing the control's own, localized label. Never put a
/// `qa.*` id in a semantics label.
///
/// With [label] (a localized field name such as "Height") the label, the id
/// and the control merge into one node, so a dropdown or text field is
/// announced with its name ("Height, 170 cm, button").
class QaId extends StatelessWidget {
  const QaId(this.id, {required this.child, this.label, super.key});

  final String id;
  final String? label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final label = this.label;
    if (label == null) {
      return Semantics(container: true, identifier: id, child: child);
    }
    return MergeSemantics(
      child: Semantics(identifier: id, label: label, child: child),
    );
  }
}
