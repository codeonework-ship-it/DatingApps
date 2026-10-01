import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/layout/app_layout.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_widgets.dart';
import '../providers/support_ticket_provider.dart';

class HelpSupportScreen extends ConsumerWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tickets = ref.watch(supportTicketsProvider);
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('create_support_ticket'),
        onPressed: () => _openTicketComposer(context, ref),
        icon: const Icon(Icons.edit_note_rounded),
        label: const Text('New ticket'),
      ),
      body: PostLoginBackdrop(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppTheme.contentMaxWidth,
              ),
              child: RefreshIndicator(
                onRefresh: () =>
                    ref.read(supportTicketsProvider.notifier).refresh(),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 104),
                  children: [
                    const _SupportHeader(),
                    const SizedBox(height: 18),
                    Text(
                      'Quick answers',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const _QuickAnswerGrid(),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Your support requests',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Refresh tickets',
                          onPressed: () => ref
                              .read(supportTicketsProvider.notifier)
                              .refresh(),
                          icon: const Icon(Icons.refresh_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    tickets.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(28),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (error, _) => _SupportState(
                        icon: Icons.cloud_off_rounded,
                        title: 'Tickets are unavailable',
                        body: error.toString().replaceFirst('Bad state: ', ''),
                        action: TextButton.icon(
                          onPressed: () => ref
                              .read(supportTicketsProvider.notifier)
                              .refresh(),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Try again'),
                        ),
                      ),
                      data: (items) => items.isEmpty
                          ? _SupportState(
                              icon: Icons.inbox_rounded,
                              title: 'No open conversations',
                              body:
                                  'Create a ticket and the support team will '
                                  'reply here. Safety requests are '
                                  'prioritized.',
                              action: FilledButton.icon(
                                onPressed: () =>
                                    _openTicketComposer(context, ref),
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Contact support'),
                              ),
                            )
                          : Column(
                              children: items
                                  .map(
                                    (ticket) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 10,
                                      ),
                                      child: _TicketCard(
                                        ticket: ticket,
                                        onTap: () => _openConversation(
                                          context,
                                          ref,
                                          ticket,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(AppLayout.space4),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest.withValues(
                          alpha: .62,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: colors.outlineVariant.withValues(alpha: .55),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.shield_outlined, color: colors.primary),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'If someone is in immediate danger, contact '
                              'local '
                              'emergency services. Support tickets do not '
                              'replace emergency help.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openTicketComposer(BuildContext context, WidgetRef ref) async {
    final subject = TextEditingController();
    final message = TextEditingController();
    var category = 'technical';
    var priority = 'normal';
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            4,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Start a support conversation',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Give us enough detail to act. Never include a password, '
                  'recovery code, card number, or identity document.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  key: const Key('support_category'),
                  initialValue: category,
                  decoration: const InputDecoration(
                    labelText: 'What do you need help with?',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'account', child: Text('Account')),
                    DropdownMenuItem(value: 'safety', child: Text('Safety')),
                    DropdownMenuItem(
                      value: 'technical',
                      child: Text('Technical issue'),
                    ),
                    DropdownMenuItem(value: 'billing', child: Text('Billing')),
                    DropdownMenuItem(
                      value: 'feedback',
                      child: Text('Feedback'),
                    ),
                  ],
                  onChanged: (value) => setState(() {
                    category = value ?? category;
                    if (category == 'safety') {
                      priority = 'high';
                    }
                  }),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey('support_priority_$priority'),
                  initialValue: priority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Low')),
                    DropdownMenuItem(value: 'normal', child: Text('Normal')),
                    DropdownMenuItem(value: 'high', child: Text('High')),
                    DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                  ],
                  onChanged: category == 'safety'
                      ? null
                      : (value) => setState(() => priority = value ?? priority),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('support_subject'),
                  controller: subject,
                  maxLength: 120,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    hintText: 'Briefly describe the issue',
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  key: const Key('support_message'),
                  controller: message,
                  minLines: 4,
                  maxLines: 8,
                  maxLength: 4000,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Details',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  key: const Key('submit_support_ticket'),
                  onPressed: () async {
                    final title = subject.text.trim();
                    final body = message.text.trim();
                    if (title.length < 5 || body.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Add a subject of at least 5 characters and a '
                            'message.',
                          ),
                        ),
                      );
                      return;
                    }
                    try {
                      await ref
                          .read(supportTicketsProvider.notifier)
                          .create(
                            category: category,
                            priority: priority,
                            subject: title,
                            body: body,
                          );
                      if (sheetContext.mounted) {
                        Navigator.pop(sheetContext, true);
                      }
                    } on Object catch (error) {
                      if (sheetContext.mounted) {
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                          SnackBar(
                            content: Text(
                              error.toString().replaceFirst('Bad state: ', ''),
                            ),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Send securely'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    // The modal future resolves when pop begins. Keep the controllers alive
    // until the route's exit animation has detached its editable fields.
    await Future<void>.delayed(const Duration(milliseconds: 400));
    subject.dispose();
    message.dispose();
    if (created == true && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Support ticket created.')));
    }
  }

  Future<void> _openConversation(
    BuildContext context,
    WidgetRef ref,
    SupportTicket ticket,
  ) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _SupportConversationSheet(ticket: ticket),
  );
}

class _SupportHeader extends StatelessWidget {
  const _SupportHeader();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      backgroundColor: colors.primaryContainer.withValues(alpha: .68),
      blur: 14,
      borderRadius: const BorderRadius.all(Radius.circular(24)),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: .16),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.support_agent_rounded,
              color: colors.primary,
              size: 29,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How can we help?',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'Track every request and reply in one private conversation.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

class _QuickAnswerGrid extends StatelessWidget {
  const _QuickAnswerGrid();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth >= 560
          ? (constraints.maxWidth - 10) / 2
          : constraints.maxWidth;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _QuickAnswer(
            width: width,
            icon: Icons.login_rounded,
            title: 'Login',
            body: 'Sign in with your unique username and password.',
          ),
          _QuickAnswer(
            width: width,
            icon: Icons.verified_user_outlined,
            title: 'Verification',
            body:
                'Identity verification is optional while the provider is '
                'paused.',
          ),
          _QuickAnswer(
            width: width,
            icon: Icons.report_outlined,
            title: 'Abuse',
            body:
                'Use Report on a profile or conversation for faster safety '
                'triage.',
          ),
          _QuickAnswer(
            width: width,
            icon: Icons.receipt_long_outlined,
            title: 'Billing',
            body: 'Include the transaction reference, never your card details.',
          ),
        ],
      );
    },
  );
}

class _QuickAnswer extends StatelessWidget {
  const _QuickAnswer({
    required this.width,
    required this.icon,
    required this.title,
    required this.body,
  });
  final double width;
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: GlassContainer(
      padding: const EdgeInsets.all(AppLayout.space4),
      backgroundColor: Theme.of(
        context,
      ).colorScheme.surface.withValues(alpha: .82),
      blur: 10,
      borderRadius: const BorderRadius.all(Radius.circular(18)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket, required this.onTap});
  final SupportTicket ticket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final active = ticket.status == 'open' || ticket.status == 'in_progress';
    return Semantics(
      button: true,
      label: 'Open support ticket ${ticket.subject}',
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: GlassContainer(
          padding: const EdgeInsets.all(AppLayout.space4),
          backgroundColor: colors.surface.withValues(alpha: .86),
          blur: 10,
          borderRadius: const BorderRadius.all(Radius.circular(18)),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: (active ? colors.primary : colors.secondary)
                      .withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  active ? Icons.forum_outlined : Icons.task_alt_rounded,
                  color: active ? colors.primary : colors.secondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.subject,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_label(ticket.category)} · ${ticket.messageCount} '
                      '${ticket.messageCount == 1 ? 'message' : 'messages'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppLayout.space3,
                  vertical: AppLayout.space1,
                ),
                decoration: BoxDecoration(
                  color: (active ? colors.primary : colors.secondary)
                      .withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _label(ticket.status),
                  style: TextStyle(
                    color: active ? colors.primary : colors.secondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _label(String value) => value
      .split('_')
      .map(
        (part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}',
      )
      .join(' ');
}

class _SupportConversationSheet extends ConsumerStatefulWidget {
  const _SupportConversationSheet({required this.ticket});
  final SupportTicket ticket;

  @override
  ConsumerState<_SupportConversationSheet> createState() =>
      _SupportConversationSheetState();
}

class _SupportConversationSheetState
    extends ConsumerState<_SupportConversationSheet> {
  final _reply = TextEditingController();
  late Future<SupportConversation> _conversation;
  var _sending = false;

  @override
  void initState() {
    super.initState();
    _conversation = ref
        .read(supportTicketsProvider.notifier)
        .loadConversation(widget.ticket);
  }

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      18,
      0,
      18,
      MediaQuery.viewInsetsOf(context).bottom + 20,
    ),
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * .72,
      child: FutureBuilder<SupportConversation>(
        future: _conversation,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return _SupportState(
              icon: Icons.cloud_off_rounded,
              title: 'Conversation unavailable',
              body:
                  snapshot.error?.toString().replaceFirst('Bad state: ', '') ??
                  'Try again in a moment.',
              action: TextButton.icon(
                onPressed: () => setState(() {
                  _conversation = ref
                      .read(supportTicketsProvider.notifier)
                      .loadConversation(widget.ticket);
                }),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            );
          }
          final conversation = snapshot.requireData;
          final canReply = conversation.ticket.status != 'closed';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                conversation.ticket.subject,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                '${conversation.ticket.category} · '
                '${conversation.ticket.status.replaceAll('_', ' ')}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: conversation.messages.isEmpty
                    ? const Center(child: Text('No messages yet.'))
                    : ListView.separated(
                        itemCount: conversation.messages.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final message = conversation.messages[index];
                          final fromSupport = message.authorRole == 'support';
                          return Align(
                            alignment: fromSupport
                                ? Alignment.centerLeft
                                : Alignment.centerRight,
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 520),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: fromSupport
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.surfaceContainerHighest
                                    : Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fromSupport ? 'Support' : 'You',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(message.body),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              if (canReply) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('support_reply'),
                        controller: _reply,
                        maxLength: 4000,
                        minLines: 1,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Reply to support',
                          counterText: '',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      key: const Key('send_support_reply'),
                      tooltip: 'Send reply',
                      onPressed: _sending
                          ? null
                          : () => _sendReply(conversation),
                      icon: _sending
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    ),
  );

  Future<void> _sendReply(SupportConversation conversation) async {
    if (_reply.text.trim().isEmpty) {
      return;
    }
    setState(() => _sending = true);
    try {
      final updated = await ref
          .read(supportTicketsProvider.notifier)
          .reply(conversation, _reply.text);
      _reply.clear();
      if (mounted) {
        setState(() {
          _sending = false;
          _conversation = Future.value(updated);
        });
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Bad state: ', '')),
          ),
        );
      }
    }
  }
}

class _SupportState extends StatelessWidget {
  const _SupportState({
    required this.icon,
    required this.title,
    required this.body,
    required this.action,
  });
  final IconData icon;
  final String title;
  final String body;
  final Widget action;

  @override
  Widget build(BuildContext context) => GlassContainer(
    padding: const EdgeInsets.all(AppLayout.space6),
    backgroundColor: Theme.of(
      context,
    ).colorScheme.surface.withValues(alpha: .84),
    blur: 10,
    borderRadius: const BorderRadius.all(Radius.circular(20)),
    child: Column(
      children: [
        Icon(icon, size: 34, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 10),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 5),
        Text(
          body,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        action,
      ],
    ),
  );
}
