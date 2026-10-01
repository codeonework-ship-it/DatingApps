import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A compact wordmark that stays legible at navigation and welcome sizes.
///
/// The mark follows the active palette, including saved cinematic themes.
class ConnectBrand extends StatelessWidget {
  const ConnectBrand({super.key, this.onDark = false});
  final bool onDark;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.14),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          Icons.all_inclusive_rounded,
          size: 24,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
      const SizedBox(width: 10),
      Flexible(
        child: Text(
          'connect',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: AppTheme.uiFamily,
            fontSize: 27,
            height: 1,
            letterSpacing: -1.2,
            fontWeight: FontWeight.w700,
            color: onDark
                ? AppTheme.inkOnDark
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    ],
  );
}
