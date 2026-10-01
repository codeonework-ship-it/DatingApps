import 'package:flutter/material.dart';

import '../../../core/widgets/glass_widgets.dart';

/// Shown on the web while the hosted checkout runs in another tab.
/// Resolves `true` when the member says they have paid, `false` if they
/// cancelled, `null` if dismissed.
Future<bool?> showCheckoutWaitingSheet(
  BuildContext context, {
  required String title,
}) => showModalBottomSheet<bool?>(
  context: context,
  isDismissible: false,
  enableDrag: false,
  backgroundColor: Colors.transparent,
  builder: (sheetContext) => Padding(
    padding: const EdgeInsets.all(16),
    child: GlassContainer(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      borderRadius: const BorderRadius.all(Radius.circular(28)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: Theme.of(sheetContext).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Complete the checkout for $title in the new tab',
            textAlign: TextAlign.center,
            style: Theme.of(
              sheetContext,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Your card details are entered on the payment provider\'s secure '
            'page. Come back here when it says the payment is complete.',
            textAlign: TextAlign.center,
            style: Theme.of(sheetContext).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          GlassButton(
            label: 'Check confirmation',
            icon: Icons.check,
            onPressed: () => Navigator.of(sheetContext).pop(true),
          ),
          TextButton(
            onPressed: () => Navigator.of(sheetContext).pop(false),
            child: const Text('Back to account'),
          ),
        ],
      ),
    ),
  ),
);
