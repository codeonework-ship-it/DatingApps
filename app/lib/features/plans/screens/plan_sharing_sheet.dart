import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/api_client_provider.dart';
import '../../../core/network/api_error_message.dart';
import '../models/date_plan.dart';

Future<void> showPlanSharingSheet(BuildContext context, DatePlan plan) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => PlanSharingSheet(plan: plan),
    );

class PlanSharingSheet extends ConsumerStatefulWidget {
  const PlanSharingSheet({super.key, required this.plan});
  final DatePlan plan;
  @override
  ConsumerState<PlanSharingSheet> createState() => _PlanSharingSheetState();
}

class _PlanSharingSheetState extends ConsumerState<PlanSharingSheet> {
  bool loading = true, saving = false;
  String? error;
  int version = 0;
  List<Map<String, dynamic>> contacts = [];
  Set<String> selected = {};
  String get path =>
      '/matches/${widget.plan.matchId}/plans/${widget.plan.id}/sharing';
  @override
  void initState() {
    super.initState();
    Future.microtask(load);
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final response = await ref.read(apiClientProvider).get<dynamic>(path);
      final body = (response.data as Map).cast<String, dynamic>();
      if (!mounted) return;
      setState(() {
        version = (body['version'] as num).toInt();
        contacts = (body['contacts'] as List)
            .whereType<Map<dynamic, dynamic>>()
            .map((v) => v.cast<String, dynamic>())
            .toList();
        selected = (body['contact_ids'] as List)
            .cast<String>()
            .where((id) => contacts.any((c) => c['id'] == id))
            .toSet();
      });
    } catch (e) {
      if (mounted)
        setState(
          () => error = apiErrorMessage(
            e,
            fallback: 'Unable to load sharing choices.',
          ),
        );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> save() async {
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await ref
          .read(apiClientProvider)
          .post<dynamic>(
            path,
            data: {
              'contact_ids': selected.toList(),
              'expected_version': version,
            },
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            selected.isEmpty
                ? 'Your contact sharing is off.'
                : 'Your selected contacts can now see this plan.',
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted)
        setState(
          () => error = apiErrorMessage(
            e,
            fallback: 'Unable to save. Reload choices before trying again.',
          ),
        );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * .9,
    ),
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Your plan. Your people.',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              IconButton(
                tooltip: 'Close sharing',
                onPressed: saving ? null : () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Sharing with contacts starts off. Choose up to 10 trusted friends for this plan. Your date chooses their own contacts.',
          ),
          const SizedBox(height: 20),
          if (loading)
            const Center(child: CircularProgressIndicator())
          else ...[
            if (contacts.isEmpty && error == null)
              const Text(
                'No eligible friends yet. Your plan is still available to you and your date.',
              ),
            for (final contact in contacts)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                key: ValueKey('qa.plan.contact.${contact['id']}'),
                title: Text(contact['name'] as String? ?? 'A friend'),
                value: selected.contains(contact['id']),
                onChanged: saving
                    ? null
                    : (value) => setState(() {
                        if (value == true && selected.length < 10) {
                          selected.add(contact['id'] as String);
                        } else {
                          selected.remove(contact['id']);
                        }
                      }),
              ),
            const SizedBox(height: 16),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selected.isEmpty
                          ? 'Preview · no contacts selected'
                          : 'Preview · ${selected.length} selected',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      selected.isEmpty
                          ? 'Your friends will receive no plan or check-in updates from you.'
                          : 'These contacts can see your date’s name, the time and place, plan status, and your check-in updates. They receive the current plan when you save.',
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Messages and private post-date feedback stay private. Removing a contact stops future updates and removes their in-app plan access. Updates already delivered to a device cannot be recalled.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (error != null) ...[
              Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              TextButton(
                onPressed: saving ? null : load,
                child: const Text('Reload sharing choices'),
              ),
            ],
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const ValueKey('qa.plan.sharing.save'),
                onPressed: saving || (contacts.isEmpty && error != null)
                    ? null
                    : save,
                child: Text(
                  saving
                      ? 'Saving…'
                      : selected.isEmpty
                      ? 'Keep contact sharing off'
                      : 'Share with selected contacts',
                ),
              ),
            ),
            if (selected.isNotEmpty)
              TextButton(
                onPressed: saving
                    ? null
                    : () => setState(() => selected.clear()),
                child: const Text('Deselect everyone'),
              ),
          ],
        ],
      ),
    ),
  );
}
