import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/connect_page.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../../support/screens/support_ticket_form_screen.dart';
import '../../support/screens/support_tickets_screen.dart';
import '../../support/support_api.dart';
import '../../support/widgets/support_widgets.dart';

/// The support centre: quick answers first, then a way to contact the team
/// and follow every request in "My tickets".
class HelpSupportScreen extends ConsumerWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tickets = ref.watch(supportTicketsProvider);
    final disabled = supportFeatureDisabled(tickets.error);
    final summary = tickets.valueOrNull;
    final unread = summary?.unreadTotal ?? 0;
    final open = summary?.openTotal ?? 0;

    Widget section(String label, Widget child, {String? title}) => Padding(
      padding: const EdgeInsets.only(top: ConnectMetrics.sectionGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConnectSectionHeader(label: label, title: title),
          const SizedBox(height: ConnectMetrics.cardGap),
          child,
        ],
      ),
    );

    final String ticketsSubtitle;
    if (unread > 0) {
      ticketsSubtitle = l10n.supportUnreadReplies(unread);
    } else if (open > 0) {
      ticketsSubtitle = l10n.supportOpenRequests(open);
    } else {
      ticketsSubtitle = l10n.supportMyTicketsSubtitle;
    }

    return Scaffold(
      body: PostLoginBackdrop(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, box) {
              final gutter = ConnectMetrics.gutterFor(box.maxWidth);
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: RefreshIndicator(
                    onRefresh: () =>
                        ref.read(supportTicketsProvider.notifier).refresh(),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(gutter, 12, gutter, 48),
                      children: [
                        ConnectPageHeader(
                          leading: Navigator.of(context).canPop()
                              ? const BackButton()
                              : null,
                          eyebrow: l10n.supportCentreEyebrow,
                          title: l10n.supportCentreTitle,
                          subtitle: l10n.supportCentreSubtitle,
                        ),
                        section(
                          l10n.supportContactSection,
                          disabled
                              ? const SupportUnavailablePanel()
                              : Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    ConnectNavTile(
                                      key: const Key('create_support_ticket'),
                                      icon: Icons.support_agent_rounded,
                                      title: l10n.supportContactTitle,
                                      subtitle: l10n.supportContactSubtitle,
                                      onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute<void>(
                                          builder: (_) =>
                                              const SupportTicketFormScreen(),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      height: ConnectMetrics.cardGap,
                                    ),
                                    ConnectNavTile(
                                      key: const Key('support_my_tickets'),
                                      icon: Icons.forum_outlined,
                                      title: l10n.supportMyTicketsTitle,
                                      subtitle: ticketsSubtitle,
                                      trailing: unread > 0
                                          ? Semantics(
                                              label: l10n.supportUnreadReplies(
                                                unread,
                                              ),
                                              excludeSemantics: true,
                                              child: Badge(
                                                key: const Key(
                                                  'support_unread_badge',
                                                ),
                                                label: Text('$unread'),
                                                backgroundColor: colors.primary,
                                                textColor: colors.onPrimary,
                                              ),
                                            )
                                          : null,
                                      onTap: () async {
                                        await Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (_) =>
                                                const SupportTicketsScreen(),
                                          ),
                                        );
                                        ref.invalidate(supportTicketsProvider);
                                      },
                                    ),
                                  ],
                                ),
                        ),
                        section(
                          l10n.supportQuickAnswersSection,
                          const _QuickAnswerGrid(),
                        ),
                        const SizedBox(height: ConnectMetrics.sectionGap),
                        ConnectPanel(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.shield_outlined,
                                color: colors.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  l10n.supportEmergencyNote,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colors.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _QuickAnswerGrid extends StatelessWidget {
  const _QuickAnswerGrid();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final answers = [
      (
        Icons.login_rounded,
        l10n.supportFaqLoginTitle,
        l10n.supportFaqLoginBody,
      ),
      (
        Icons.verified_user_outlined,
        l10n.supportFaqVerificationTitle,
        l10n.supportFaqVerificationBody,
      ),
      (
        Icons.report_outlined,
        l10n.supportFaqAbuseTitle,
        l10n.supportFaqAbuseBody,
      ),
      (
        Icons.receipt_long_outlined,
        l10n.supportFaqBillingTitle,
        l10n.supportFaqBillingBody,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth >= 560
            ? (constraints.maxWidth - ConnectMetrics.cardGap) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: ConnectMetrics.cardGap,
          runSpacing: ConnectMetrics.cardGap,
          children: [
            for (final (icon, title, body) in answers)
              SizedBox(
                width: width,
                child: _QuickAnswer(icon: icon, title: title, body: body),
              ),
          ],
        );
      },
    );
  }
}

class _QuickAnswer extends StatelessWidget {
  const _QuickAnswer({
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return ConnectPanel(
      padding: const EdgeInsets.all(ConnectMetrics.padding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
