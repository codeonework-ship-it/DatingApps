import 'package:flutter/material.dart';

/// A pinned top row with a close button for bottom sheets that open full
/// height, where the drag handle alone is easy to miss. The label is
/// Flutter's own "Close", so it is already translated in every locale.
class SheetCloseBar extends StatelessWidget {
  const SheetCloseBar({super.key, this.closeKey, this.title});

  final Key? closeKey;

  /// Optional title next to the button.
  final Widget? title;

  @override
  Widget build(BuildContext context) {
    final label = MaterialLocalizations.of(context).closeButtonTooltip;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 16, 4),
      child: Row(
        children: [
          IconButton(
            key: closeKey,
            tooltip: label,
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.close_rounded),
          ),
          if (title != null) ...[
            const SizedBox(width: 4),
            Expanded(
              child: DefaultTextStyle.merge(
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                child: title!,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
