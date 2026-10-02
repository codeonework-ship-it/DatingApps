import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/providers/api_client_provider.dart';
import '../../core/network/api_error_message.dart';
import '../../l10n/app_localizations.dart';
import '../plans/providers/plans_provider.dart';
import '../auth/providers/auth_provider.dart';
import '../first_chapter/chapter_studio_screen.dart';

// Bounded reconciliation while the conversation is visible; domain events
// remain authoritative on the server. The timer stops when nobody watches.
final datingConnectionProvider = StreamProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, matchId) {
      ref.watch(authNotifierProvider.select((s) => s.userId));
      final stream = StreamController<Map<String, dynamic>>();
      var disposed = false;
      var loading = false;
      String? lastPlanRevision;
      Future<void> refresh() async {
        if (disposed || loading) return;
        loading = true;
        try {
          final response = await ref
              .read(apiClientProvider)
              .get<dynamic>('/matches/$matchId/connection');
          if (!disposed) {
            final data = (response.data as Map).cast<String, dynamic>();
            final revision = data['plan_revision']?.toString();
            if (lastPlanRevision != null &&
                revision != lastPlanRevision &&
                !ref.read(matchPlansProvider(matchId)).isMutating) {
              unawaited(ref.read(matchPlansProvider(matchId).notifier).load());
            }
            lastPlanRevision = revision;
            stream.add(data);
          }
        } catch (e, st) {
          if (!disposed) stream.addError(e, st);
        } finally {
          loading = false;
        }
      }

      unawaited(refresh());
      final timer = Timer.periodic(
        const Duration(seconds: 20),
        (_) => refresh(),
      );
      ref.onDispose(() {
        disposed = true;
        timer.cancel();
        unawaited(stream.close());
      });
      return stream.stream;
    });

class DatingConnectionCard extends ConsumerWidget {
  const DatingConnectionCard({required this.matchId, super.key});
  final String matchId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(datingConnectionProvider(matchId));
    return state.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
      data: (data) {
        final slow = data['partner_pace_status'] == 'slow_week';
        final colors = Theme.of(context).colorScheme;
        final l10n = AppLocalizations.of(context);
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Card(
            margin: EdgeInsets.zero,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: Icon(
                    slow ? Icons.spa_outlined : Icons.auto_awesome_outlined,
                    color: colors.primary,
                  ),
                  title: Text(
                    slow
                        ? l10n.datingConnectionSlowTitle
                        : switch (data['chapter_status']) {
                            'your_turn' => l10n.datingConnectionYourTurn,
                            'complete' => l10n.datingConnectionComplete,
                            'waiting' => l10n.datingConnectionWaiting,
                            _ => l10n.datingConnectionCreate,
                          },
                  ),
                  subtitle: Text(
                    slow
                        ? l10n.datingConnectionSlowBody
                        : l10n.datingConnectionBody,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => openChapterStudio(context, matchId: matchId),
                ),
                // Secondary: the private "A little chemistry" moment. First
                // Chapter Studio stays the card's main action.
                Divider(height: 1, color: colors.outlineVariant),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: TextButton.icon(
                    key: const ValueKey('qa.connection.chemistry'),
                    onPressed: () =>
                        showChemistrySheet(context, matchId: matchId),
                    icon: const Icon(Icons.favorite_border_rounded),
                    label: Text(l10n.chemistryCardEntry),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Opens the private chemistry moment for [matchId] as a bottom sheet.
Future<void> showChemistrySheet(
  BuildContext context, {
  required String matchId,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  useSafeArea: true,
  builder: (_) => ChemistrySheet(matchId: matchId),
);

class ChemistrySheet extends ConsumerStatefulWidget {
  const ChemistrySheet({required this.matchId, super.key});
  final String matchId;
  @override
  ConsumerState<ChemistrySheet> createState() => _ChemistrySheetState();
}

class _ChemistrySheetState extends ConsumerState<ChemistrySheet> {
  bool busy = false;
  String? error;
  String? pendingId;
  String? pendingPrompt;
  Future<void> send(String path, Map<String, dynamic> data) async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref.read(apiClientProvider).post<dynamic>(path, data: data);
      pendingId = null;
      pendingPrompt = null;
      ref.invalidate(datingConnectionProvider(widget.matchId));
      ref.invalidate(matchPlansProvider(widget.matchId));
    } catch (e) {
      if (mounted)
        setState(
          () => error = apiErrorMessage(e, fallback: l10n.chemistrySaveFailed),
        );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(datingConnectionProvider(widget.matchId));
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .8,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.chemistryTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(l10n.chemistryIntro),
              const SizedBox(height: 20),
              state.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => TextButton(
                  onPressed: () =>
                      ref.invalidate(datingConnectionProvider(widget.matchId)),
                  child: Text(l10n.chemistryRetry),
                ),
                data: (data) {
                  final moment = data['moment'] as Map?;
                  final status = moment?['status'];
                  final options =
                      (moment?['options'] as Map?)?.cast<String, dynamic>() ??
                      {};
                  final reasons =
                      (data['reasons'] as List?)?.cast<String>() ?? [];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (reasons.isNotEmpty) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final reason in reasons)
                              Chip(label: Text(reason)),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (status == 'revealed') ...[
                        Text(
                          l10n.chemistryRevealedTitle,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.person_outline),
                          title: Text(l10n.chemistryYouPicked),
                          subtitle: Text(
                            options[moment?['my_answer']]?.toString() ?? '',
                          ),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.favorite_outline),
                          title: Text(l10n.chemistryMatchPicked),
                          subtitle: Text(
                            options[moment?['partner_answer']]?.toString() ??
                                '',
                          ),
                        ),
                        Text(l10n.chemistryRevealedBody),
                        const SizedBox(height: 20),
                      ],
                      if (status == 'waiting') ...[
                        const Icon(Icons.lock_outline, size: 32),
                        const SizedBox(height: 12),
                        Text(l10n.chemistryWaitingBody),
                        const SizedBox(height: 8),
                        Text(
                          l10n.chemistryYourChoice(
                            '${options[moment?['my_answer']] ?? ''}',
                          ),
                        ),
                      ],
                      if (status == 'open') ...[
                        Text(
                          _promptLabel(
                            l10n,
                            moment?['prompt']?.toString() ?? '',
                          ),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        for (final option in options.entries)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: busy
                                    ? null
                                    : () => send(
                                        '/matches/${widget.matchId}/moments/${moment?['id']}/answer',
                                        {'answer': option.key},
                                      ),
                                child: Text(option.value.toString()),
                              ),
                            ),
                          ),
                      ],
                      if (moment == null ||
                          status == 'expired' ||
                          status == 'revealed') ...[
                        Text(
                          status == 'revealed'
                              ? l10n.chemistryAnotherMoment
                              : l10n.chemistryChooseMoment,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        for (final prompt in {
                          'sunday': l10n.chemistryPromptSunday,
                          'adventure': l10n.chemistryPromptAdventure,
                          'first_date': l10n.chemistryPromptFirstDate,
                        }.entries)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: busy
                                    ? null
                                    : () {
                                        if (pendingPrompt != prompt.key) {
                                          pendingId = const Uuid().v4();
                                          pendingPrompt = prompt.key;
                                        }
                                        send(
                                          '/matches/${widget.matchId}/moments',
                                          {
                                            'id': pendingId,
                                            'prompt': prompt.key,
                                          },
                                        );
                                      },
                                child: Text(prompt.value),
                              ),
                            ),
                          ),
                      ],
                    ],
                  );
                },
              ),
              if (error != null)
                Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              if (busy)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: LinearProgressIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _promptLabel(AppLocalizations l10n, String prompt) => switch (prompt) {
    'sunday' => l10n.chemistryQuestionSunday,
    'adventure' => l10n.chemistryQuestionAdventure,
    _ => l10n.chemistryQuestionFirstDate,
  };
}
