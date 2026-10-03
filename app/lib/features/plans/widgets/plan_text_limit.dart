import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Caps a plan text field the way the BFF counts: Unicode code points
/// (runes). Flutter's `maxLength` counts grapheme clusters, so a skin-toned
/// or joined emoji (one grapheme, several code points) let members type text
/// the server then rejects as too long. Whole graphemes are kept, so an emoji
/// is never cut in half.
class PlanRuneLimit extends TextInputFormatter {
  const PlanRuneLimit(this.max);

  final int max;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.runes.length <= max || newValue.composing.isValid) {
      return newValue;
    }
    if (oldValue.text.runes.length >= max && oldValue.selection.isCollapsed) {
      return oldValue;
    }
    final kept = StringBuffer();
    var count = 0;
    for (final grapheme in newValue.text.characters) {
      final runes = grapheme.runes.length;
      if (count + runes > max) {
        break;
      }
      kept.write(grapheme);
      count += runes;
    }
    final text = kept.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(
        offset: newValue.selection.end.clamp(0, text.length),
      ),
    );
  }
}

/// A `buildCounter` that shows the code-point count next to [max], matching
/// [PlanRuneLimit] and the server's limit.
InputCounterWidgetBuilder planRuneCounter(
  TextEditingController controller,
  int max,
) => (context, {required currentLength, required isFocused, maxLength}) {
  final theme = Theme.of(context);
  return Text(
    '${controller.text.runes.length}/$max',
    style: theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    ),
  );
};
