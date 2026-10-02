import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/connect_page.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../support_api.dart';
import '../support_models.dart';
import '../widgets/support_widgets.dart';
import 'support_ticket_form_screen.dart';
import 'support_ticket_thread_screen.dart';

/// "My tickets": every request the member has raised, active first.
class SupportTicketsScreen extends ConsumerWidget {
  const SupportTicketsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tickets = ref.watch(supportTicketsProvider);
    final disabled = supportFeatureDisabled(tickets.error);

    Future<void> refresh() =>
        ref.read(supportTicketsProvider.notifier).refresh();

    Future<void> openNew() => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SupportTicketFormScreen()),
    );

    Widget section(String label, List<SupportTicket> items) => Padding(
      padding: const EdgeInsets.only(top: ConnectMetrics.sectionGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConnectSectionHeader(label: label),
          const SizedBox(height: ConnectMetrics.cardGap),
          for (final ticket in items)
            Padding(
              padding: const EdgeInsets.only(bottom: ConnectMetrics.cardGap),
              child: SupportTicketCard(ticket: ticket),
            ),
        ],
      ),
    );

    Widget spaced(Widget child) => Padding(
      padding: const EdgeInsets.only(top: ConnectMetrics.sectionGap),
      child: child,
    );

    final List<Widget> content;
    if (tickets.isLoading && !tickets.hasValue && !tickets.hasError) {
      content = const [
        Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    } else if (disabled) {
      content = [spaced(const SupportUnavailablePanel())];
    } else if (tickets.hasError && !tickets.hasValue) {
      content = [
        spaced(
          SupportNotice(
            icon: Icons.cloud_off_rounded,
            title: l10n.supportTicketsLoadErrorTitle,
            message: supportErrorMessage(l10n, tickets.error!),
            action: TextButton.icon(
              onPressed: refresh,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.supportTryAgain),
            ),
          ),
        ),
      ];
    } else {
      final all = tickets.valueOrNull?.tickets ?? const <SupportTicket>[];
      final active = all.where((t) => t.memberStatus.isActive).toList();
      final finished = all.where((t) => !t.memberStatus.isActive).toList();
      content = all.isEmpty
          ? [
              spaced(
                SupportNotice(
                  key: const Key('support_tickets_empty'),
                  icon: Icons.inbox_outlined,
                  title: l10n.supportTicketsEmptyTitle,
                  message: l10n.supportTicketsEmptyBody,
                  action: FilledButton.icon(
                    onPressed: openNew,
                    icon: const Icon(Icons.add_rounded),
                    label: Text(l10n.supportContactTitle),
                  ),
                ),
              ),
            ]
          : [
              if (active.isNotEmpty)
                section(l10n.supportTicketsActiveSection, active),
              if (finished.isNotEmpty)
                section(l10n.supportTicketsClosedSection, finished),
            ];
    }

    return Scaffold(
      floatingActionButton: disabled
          ? null
          : FloatingActionButton.extended(
              key: const Key('support_new_ticket'),
              onPressed: openNew,
              icon: const Icon(Icons.edit_note_rounded),
              label: Text(l10n.supportNewTicket),
            ),
      body: PostLoginBackdrop(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, box) {
              final gutter = ConnectMetrics.gutterFor(box.maxWidth);
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: RefreshIndicator(
                    onRefresh: refresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(gutter, 12, gutter, 104),
                      children: [
                        ConnectPageHeader(
                          leading: const BackButton(),
                          eyebrow: l10n.supportTicketsEyebrow,
                          title: l10n.supportTicketsTitle,
                          subtitle: l10n.supportTicketsSubtitle,
                        ),
                        ...content,
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

/// One request in "My tickets".
class SupportTicketCard extends ConsumerWidget {
  const SupportTicketCard({required this.ticket, super.key});

  final SupportTicket ticket;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final status = supportStatusLabel(l10n, ticket.memberStatus);
    final category = supportCategoryLabel(l10n, ticket.category);
    final when = supportWhen(context, ticket.activityAt);
    final unread = ticket.unreadCount;
    final radius = BorderRadius.circular(ConnectMetrics.cardRadius);
    final semanticsLabel = [
      ticket.reference,
      ticket.subject,
      l10n.supportStatusSemantics(status),
      category,
      if (when.isNotEmpty) l10n.supportTicketUpdated(when),
      if (unread > 0) l10n.supportUnreadReplies(unread),
    ].join('. ');

    return Semantics(
      button: true,
      label: semanticsLabel,
      excludeSemantics: true,
      onTap: () => _open(context, ref),
      child: Material(
        color: colors.surface,
        borderRadius: radius,
        child: InkWell(
          key: Key('support_ticket_${ticket.id}'),
          borderRadius: radius,
          onTap: () => _open(context, ref),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: colors.outlineVariant),
            ),
            padding: const EdgeInsets.all(ConnectMetrics.padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ticket.reference,
                        style: theme.textTheme.labelMedium?.copyWith(
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w700,
                          color: colors.primary,
                        ),
                      ),
                    ),
                    SupportStatusChip(status: ticket.memberStatus),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        ticket.subject,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: unread > 0
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                    if (unread > 0) ...[
                      const SizedBox(width: 8),
                      Badge(
                        key: const Key('support_ticket_unread'),
                        label: Text('$unread'),
                        backgroundColor: colors.primary,
                        textColor: colors.onPrimary,
                      ),
                    ],
                  ],
                ),
                if (ticket.lastMessagePreview.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    ticket.lastMessagePreview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Icon(
                      supportCategoryIcon(ticket.category),
                      size: 16,
                      color: colors.onSurfaceVariant,
                    ),
                    Text(
                      category,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    if (when.isNotEmpty)
                      Text(
                        '· ${l10n.supportTicketUpdated(when)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    if (unread > 0)
                      Text(
                        '· ${l10n.supportUnreadReplies(unread)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SupportTicketThreadScreen(ticketId: ticket.id),
      ),
    );
  }
}
