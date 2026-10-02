import '../../swipe/providers/curated_daily_set_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../matching/matching_l10n.dart';
import '../../matching/providers/trust_filter_provider.dart';
import '../engagement_l10n.dart';

class TrustFilterScreen extends ConsumerStatefulWidget {
  const TrustFilterScreen({super.key});

  @override
  ConsumerState<TrustFilterScreen> createState() => _TrustFilterScreenState();
}

class _TrustFilterScreenState extends ConsumerState<TrustFilterScreen> {
  bool? _enabled;
  int? _minimumBadges;
  Set<String>? _requiredBadgeCodes;

  @override
  Widget build(BuildContext context) {
    final l = engagementL10n(context);
    final state = ref.watch(trustFilterNotifierProvider);
    final notifier = ref.read(trustFilterNotifierProvider.notifier);

    final enabled = _enabled ?? state.enabled;
    final minimumBadges = _minimumBadges ?? state.minimumActiveBadges;
    final requiredBadgeCodes =
        _requiredBadgeCodes ?? state.requiredBadgeCodes.toSet();

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTrustFiltersTitle)),
      body: RefreshIndicator(
        onRefresh: notifier.load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (state.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              SwitchListTile(
                key: const ValueKey('qa.trust_filter.enabled'),
                value: enabled,
                title: Text(l.engagementTrustFiltersEnable),
                subtitle: Text(l.engagementTrustFiltersEnableSubtitle),
                onChanged: state.isSaving
                    ? null
                    : (value) => setState(() => _enabled = value),
              ),
              const SizedBox(height: 12),
              Text(l.engagementTrustFiltersMinimum(minimumBadges)),
              Slider(
                key: const ValueKey('qa.trust_filter.minimum'),
                min: 0,
                max: 4,
                divisions: 4,
                value: minimumBadges.toDouble(),
                onChanged: state.isSaving
                    ? null
                    : (value) => setState(() => _minimumBadges = value.toInt()),
              ),
              const SizedBox(height: 8),
              Text(
                l.engagementTrustFiltersRequired,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ...state.availableBadges.map(
                (badge) => CheckboxListTile(
                  key: ValueKey('qa.trust_filter.badge.${badge.code}'),
                  value: requiredBadgeCodes.contains(badge.code),
                  title: Text(localizedTrustBadgeLabel(l, badge)),
                  onChanged: state.isSaving
                      ? null
                      : (checked) {
                          final next = Set<String>.from(requiredBadgeCodes);
                          if (checked == true) {
                            next.add(badge.code);
                          } else {
                            next.remove(badge.code);
                          }
                          setState(() => _requiredBadgeCodes = next);
                        },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  key: const ValueKey('qa.trust_filter.save'),
                  onPressed: state.isSaving
                      ? null
                      : () async {
                          await notifier.save(
                            enabled: enabled,
                            minimumActiveBadges: minimumBadges,
                            requiredBadgeCodes: requiredBadgeCodes.toList(
                              growable: false,
                            ),
                          );
                          ref.invalidate(curatedDailySetProvider);
                          if (context.mounted &&
                              ref.read(trustFilterNotifierProvider).error ==
                                  null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l.engagementTrustFiltersSaved),
                              ),
                            );
                          }
                        },
                  child: state.isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l.engagementTrustFiltersSave),
                ),
              ),
            ],
            if (state.error != null) ...[
              const SizedBox(height: 12),
              Text(
                localizeTrustFilterError(l, state.error)!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
