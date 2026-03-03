import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../matching/providers/trust_filter_provider.dart';

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
    final state = ref.watch(trustFilterNotifierProvider);
    final notifier = ref.read(trustFilterNotifierProvider.notifier);

    final enabled = _enabled ?? state.enabled;
    final minimumBadges = _minimumBadges ?? state.minimumActiveBadges;
    final requiredBadgeCodes =
        _requiredBadgeCodes ?? state.requiredBadgeCodes.toSet();

    return Scaffold(
      appBar: AppBar(title: const Text('Trust Filters')),
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
                value: enabled,
                title: const Text('Enable trust filters'),
                subtitle: const Text(
                  'Hide profiles that do not meet your trust requirements',
                ),
                onChanged: state.isSaving
                    ? null
                    : (value) => setState(() => _enabled = value),
              ),
              const SizedBox(height: 12),
              Text('Minimum active badges: $minimumBadges'),
              Slider(
                min: 0,
                max: 4,
                divisions: 4,
                value: minimumBadges.toDouble(),
                onChanged: state.isSaving
                    ? null
                    : (value) => setState(() => _minimumBadges = value.toInt()),
              ),
              const SizedBox(height: 8),
              const Text(
                'Required badges',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ...state.availableBadges.map(
                (badge) => CheckboxListTile(
                  value: requiredBadgeCodes.contains(badge.code),
                  title: Text(badge.label),
                  subtitle: Text(badge.code),
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
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Trust filters saved.'),
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
                      : const Text('Save Trust Filters'),
                ),
              ),
            ],
            if (state.error != null) ...[
              const SizedBox(height: 12),
              Text(
                state.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
