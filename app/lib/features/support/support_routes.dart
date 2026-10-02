import 'package:flutter/material.dart';

import '../common/screens/help_support_screen.dart';
import 'screens/support_ticket_thread_screen.dart';
import 'screens/support_tickets_screen.dart';

/// Opens a support notification's `action_route`:
///
///  * `/support/tickets/<ticketID>` opens that ticket's thread;
///  * `/support/tickets` opens "My tickets";
///  * `/support` opens the support centre.
///
/// Returns false when [route] is not a support route, so the caller can fall
/// back to its own handling.
bool openSupportRoute(BuildContext context, String? route) {
  final screen = supportScreenForRoute(route);
  if (screen == null) {
    return false;
  }
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  return true;
}

/// The screen for a support route, or null when [route] is not one.
Widget? supportScreenForRoute(String? route) {
  final path = Uri.tryParse(route?.trim() ?? '')?.path ?? '';
  final segments = path.split('/').where((s) => s.isNotEmpty).toList();
  if (segments.isEmpty || segments.first != 'support') {
    return null;
  }
  if (segments.length == 1) {
    return const HelpSupportScreen();
  }
  if (segments[1] != 'tickets' || segments.length > 3) {
    return null;
  }
  if (segments.length == 2) {
    return const SupportTicketsScreen();
  }
  return SupportTicketThreadScreen(ticketId: segments[2]);
}
