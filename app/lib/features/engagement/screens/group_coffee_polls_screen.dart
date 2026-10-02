import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/glass_widgets.dart';
import '../../../l10n/app_localizations.dart';
import '../engagement_l10n.dart';
import '../providers/group_coffee_poll_provider.dart';

class GroupCoffeePollsScreen extends ConsumerStatefulWidget {
  const GroupCoffeePollsScreen({super.key});

  @override
  ConsumerState<GroupCoffeePollsScreen> createState() =>
      _GroupCoffeePollsScreenState();
}

class _GroupCoffeePollsScreenState
    extends ConsumerState<GroupCoffeePollsScreen> {
  final TextEditingController _participantsController = TextEditingController();
  final TextEditingController _deadlineController = TextEditingController();

  final TextEditingController _dayOneController = TextEditingController(
    text: 'Saturday',
  );
  final TextEditingController _timeOneController = TextEditingController(
    text: '10:00-12:00',
  );
  final TextEditingController _areaOneController = TextEditingController(
    text: 'Indiranagar',
  );

  final TextEditingController _dayTwoController = TextEditingController(
    text: 'Sunday',
  );
  final TextEditingController _timeTwoController = TextEditingController(
    text: '11:00-13:00',
  );
  final TextEditingController _areaTwoController = TextEditingController(
    text: 'Koramangala',
  );

  final TextEditingController _actorUserController = TextEditingController();

  @override
  void dispose() {
    _participantsController.dispose();
    _deadlineController.dispose();
    _dayOneController.dispose();
    _timeOneController.dispose();
    _areaOneController.dispose();
    _dayTwoController.dispose();
    _timeTwoController.dispose();
    _areaTwoController.dispose();
    _actorUserController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = engagementL10n(context);
    final state = ref.watch(groupCoffeePollProvider);
    final notifier = ref.read(groupCoffeePollProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l.engagementCoffeeTitle)),
      body: PostLoginBackdrop(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: notifier.load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _card(
                  context,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.engagementCoffeeCreateHeading,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l.engagementCoffeeCreateHint,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _card(
                  context,
                  child: Column(
                    children: [
                      TextField(
                        controller: _participantsController,
                        decoration: InputDecoration(
                          labelText: l.engagementCoffeeParticipantsLabel,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _deadlineController,
                        decoration: InputDecoration(
                          labelText: l.engagementCoffeeDeadlineLabel,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _optionInputs(
                        context,
                        title: l.engagementCoffeeOptionNumber(1),
                        day: _dayOneController,
                        time: _timeOneController,
                        area: _areaOneController,
                      ),
                      const SizedBox(height: 10),
                      _optionInputs(
                        context,
                        title: l.engagementCoffeeOptionNumber(2),
                        day: _dayTwoController,
                        time: _timeTwoController,
                        area: _areaTwoController,
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: state.isSubmitting
                              ? null
                              : () => notifier.createPoll(
                                  participantUserIds: _participantsController
                                      .text
                                      .split(',')
                                      .map((item) => item.trim())
                                      .where((item) => item.isNotEmpty)
                                      .toList(growable: false),
                                  deadlineAt: _deadlineController.text.trim(),
                                  options: <Map<String, String>>[
                                    <String, String>{
                                      'day': _dayOneController.text.trim(),
                                      'time_window': _timeOneController.text
                                          .trim(),
                                      'neighborhood': _areaOneController.text
                                          .trim(),
                                    },
                                    <String, String>{
                                      'day': _dayTwoController.text.trim(),
                                      'time_window': _timeTwoController.text
                                          .trim(),
                                      'neighborhood': _areaTwoController.text
                                          .trim(),
                                    },
                                  ],
                                ),
                          child: Text(l.engagementCoffeeCreate),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _card(
                  context,
                  child: TextField(
                    controller: _actorUserController,
                    decoration: InputDecoration(
                      labelText: l.engagementCoffeeActorLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (state.isLoading && state.polls.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (state.polls.isEmpty)
                  _card(
                    context,
                    child: Text(
                      l.engagementCoffeeEmpty,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                else
                  ...state.polls.map(
                    (poll) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _card(
                        context,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.engagementCoffeePollId(poll.id),
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l.engagementCoffeeStatus(
                                _statusLabel(l, poll.status),
                              ),
                            ),
                            Text(
                              l.engagementCoffeeParticipants(
                                poll.participantUserIds.join(', '),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...poll.options.map(
                              (option) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        l.engagementCoffeeOptionSummary(
                                          option.day,
                                          option.timeWindow,
                                          option.neighborhood,
                                          option.votesCount,
                                        ),
                                      ),
                                    ),
                                    OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        minimumSize: const Size(0, 40),
                                      ),
                                      onPressed: state.isSubmitting
                                          ? null
                                          : () => notifier.vote(
                                              pollId: poll.id,
                                              optionId: option.id,
                                              userId: _actorUserController.text,
                                            ),
                                      child: Text(l.engagementCoffeeVote),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (poll.status == 'open')
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: state.isSubmitting
                                      ? null
                                      : () => notifier.finalize(
                                          pollId: poll.id,
                                          userId: _actorUserController.text,
                                        ),
                                  child: Text(l.engagementCoffeeFinalize),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (state.error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    state.error!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _optionInputs(
    BuildContext context, {
    required String title,
    required TextEditingController day,
    required TextEditingController time,
    required TextEditingController area,
  }) {
    final l = engagementL10n(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: day,
          decoration: InputDecoration(
            labelText: l.engagementCoffeeDayLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: time,
          decoration: InputDecoration(
            labelText: l.engagementCoffeeTimeLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: area,
          decoration: InputDecoration(
            labelText: l.engagementCoffeeAreaLabel,
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  /// A known poll status in the reader's language; other values as sent.
  String _statusLabel(AppLocalizations l, String status) => switch (status) {
    'open' => l.engagementCoffeeStatusOpen,
    'finalized' => l.engagementCoffeeStatusFinalized,
    _ => status,
  };

  Widget _card(BuildContext context, {required Widget child}) => GlassContainer(
    padding: const EdgeInsets.all(16),
    backgroundColor: Theme.of(context).colorScheme.surface,
    blur: 12,
    crystalEffect: true,
    borderRadius: BorderRadius.circular(18),
    child: child,
  );
}
