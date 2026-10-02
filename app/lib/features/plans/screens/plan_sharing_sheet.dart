import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/api_client_provider.dart';
import '../../../core/network/api_error_message.dart';
import '../../../l10n/app_localizations.dart';
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
            fallback: AppLocalizations.of(context).planSharingLoadFailed,
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
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            selected.isEmpty
                ? l10n.planSharingOffSnack
                : l10n.planSharingSavedSnack,
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted)
        setState(
          () => error = apiErrorMessage(
            e,
            fallback: AppLocalizations.of(context).planSharingSaveFailed,
          ),
        );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ConstrainedBox(
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
                    l10n.planSharingTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                IconButton(
                  tooltip: l10n.planSharingCloseTooltip,
                  onPressed: saving ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(l10n.planSharingIntro),
            const SizedBox(height: 20),
            if (loading)
              const Center(child: CircularProgressIndicator())
            else ...[
              if (contacts.isEmpty && error == null)
                Text(l10n.planSharingNoContacts),
              for (final contact in contacts)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  key: ValueKey('qa.plan.contact.${contact['id']}'),
                  title: Text(
                    contact['name'] as String? ??
                        l10n.planSharingFriendFallback,
                  ),
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
                            ? l10n.planSharingPreviewNone
                            : l10n.planSharingPreviewCount(selected.length),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        selected.isEmpty
                            ? l10n.planSharingPreviewOffBody
                            : l10n.planSharingPreviewOnBody,
                      ),
                      const SizedBox(height: 8),
                      Text(l10n.planSharingPrivacyNote),
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
                  child: Text(l10n.planSharingReload),
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
                        ? l10n.planSharingSaving
                        : selected.isEmpty
                        ? l10n.planSharingKeepOff
                        : l10n.planSharingShareSelected,
                  ),
                ),
              ),
              if (selected.isNotEmpty)
                TextButton(
                  onPressed: saving
                      ? null
                      : () => setState(() => selected.clear()),
                  child: Text(l10n.planSharingDeselectAll),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
