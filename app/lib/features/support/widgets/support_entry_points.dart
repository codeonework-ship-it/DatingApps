import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/connect_page.dart';
import '../../../l10n/app_localizations.dart';
import '../../common/screens/help_support_screen.dart';
import '../screens/support_ticket_form_screen.dart';
import '../support_api.dart';

/// Ways into support from the rest of the app.
///
///  * [SupportEntryTile]: "Help & Support" in Settings, with the number of
///    unread replies from the team.
///  * [SupportContactLink]: a "Contact support" link where something went
///    wrong (a payment error, the report sheet). Hidden while
///    `support_ticketing_enabled` is off, so it never leads to an error.

/// The Settings tile for the support centre. The FAQ always works, so the
/// tile is always shown; with requests switched on it carries a badge for
/// unread replies and says how many requests are open.
class SupportEntryTile extends ConsumerWidget {
  const SupportEntryTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    final enabled = ref.watch(supportEnabledProvider);
    // Only asked for when requests are on: no failing call while it is off.
    final summary = enabled
        ? ref.watch(supportTicketsProvider).valueOrNull
        : null;
    final unread = summary?.unreadTotal ?? 0;
    final open = summary?.openTotal ?? 0;
    final subtitle = unread > 0
        ? l10n.supportUnreadReplies(unread)
        : open > 0
        ? l10n.supportOpenRequests(open)
        : l10n.settingsHelpSupportSubtitle;
    return ConnectNavTile(
      icon: Icons.help,
      title: l10n.settingsHelpSupportTitle,
      subtitle: subtitle,
      trailing: unread > 0
          ? Semantics(
              label: l10n.supportUnreadReplies(unread),
              excludeSemantics: true,
              child: Badge(
                key: const Key('settings_support_unread_badge'),
                label: Text('$unread'),
                backgroundColor: colors.primary,
                textColor: colors.onPrimary,
              ),
            )
          : null,
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const HelpSupportScreen()),
        );
        if (enabled) {
          ref.invalidate(supportTicketsProvider);
        }
      },
    );
  }
}

/// A "Contact support" link that opens a new request about [category].
///
/// With [closeCurrent] the surrounding sheet or dialog is closed first (the
/// report sheet), then the form opens on the same navigator.
class SupportContactLink extends ConsumerWidget {
  const SupportContactLink({
    required this.label,
    required this.category,
    super.key,
    this.closeCurrent = false,
  });

  final String label;
  final String category;
  final bool closeCurrent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(supportEnabledProvider)) {
      return const SizedBox.shrink();
    }
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: TextButton.icon(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        onPressed: () {
          final navigator = Navigator.of(context);
          if (closeCurrent) {
            navigator.pop();
          }
          navigator.push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  SupportTicketFormScreen(initialCategory: category),
            ),
          );
        },
        icon: const Icon(Icons.support_agent_rounded, size: 20),
        label: Text(label),
      ),
    );
  }
}

/// A plain "Help & Support" button for screens outside the main navigation
/// (the start-up error screen). Opens the support centre, whose FAQ works
/// whether or not requests are switched on.
class SupportCentreButton extends StatelessWidget {
  const SupportCentreButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextButton.icon(
      key: const Key('support_centre_button'),
      style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const HelpSupportScreen()),
      ),
      icon: const Icon(Icons.help_outline_rounded, size: 20),
      label: Text(l10n.settingsHelpSupportTitle),
    );
  }
}
