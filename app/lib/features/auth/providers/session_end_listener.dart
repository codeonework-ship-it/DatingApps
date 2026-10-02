import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform/browser_context.dart';
import '../../notifications/providers/notification_provider.dart';
import 'auth_provider.dart';

/// Reacts to the member's session ending, whether they signed out or the
/// server revoked it. Call from the root auth gate's `build`.
///
/// - Any change of signed-in member drops the notification feed, which closes
///   its realtime socket and stops reconnect attempts with an old credential.
/// - When the server ended the session ([kSessionExpiredMessage]), screens
///   pushed above the gate are closed so the sign-in screen is visible; the
///   browser goes to `#/signin` (whose form shows the notice) and the phone
///   app shows the notice on its welcome screen.
void listenForSessionEnd(WidgetRef ref, BuildContext context) {
  ref.listen<String?>(authNotifierProvider.select((s) => s.userId), (
    previous,
    next,
  ) {
    if (previous != next) ref.invalidate(notificationProvider);
  });
  ref.listen<AuthState>(authNotifierProvider, (previous, next) {
    final expired =
        previous?.isAuthenticated == true &&
        !next.isAuthenticated &&
        next.error == kSessionExpiredMessage;
    if (!expired) return;
    Navigator.maybeOf(context)?.popUntil((route) => route.isFirst);
    if (kIsWeb) {
      setWebRoute('/signin');
      return;
    }
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text(kSessionExpiredMessage)));
  });
}
