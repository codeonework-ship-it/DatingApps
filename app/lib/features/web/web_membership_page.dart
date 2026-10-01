import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../payment/providers/subscription_provider.dart';

/// Read-only browser surface while the separately owned native checkout is
/// integrated. Never instantiate a native WebView in a web build.
class WebMembershipPage extends ConsumerStatefulWidget {
  const WebMembershipPage({super.key});

  @override
  ConsumerState<WebMembershipPage> createState() => _WebMembershipPageState();
}

class _WebMembershipPageState extends ConsumerState<WebMembershipPage> {
  String _cycle = 'monthly';

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(
      () => ref.read(subscriptionProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(subscriptionProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Membership')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'A little more possibility.',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              const Text(
                'Explore the current plans. Browser checkout is not available yet. No purchase or charge can be made from this page.',
              ),
              const SizedBox(height: 24),
              if (state.subscription != null) ...[
                Text(
                  'Your membership: ${state.subscription!.planName}',
                  style: theme.textTheme.titleMedium,
                ),
                Text('Status: ${state.subscription!.status}'),
                const SizedBox(height: 24),
              ],
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'monthly', label: Text('Monthly')),
                  ButtonSegment(value: 'yearly', label: Text('Yearly')),
                ],
                selected: {_cycle},
                onSelectionChanged: (value) =>
                    setState(() => _cycle = value.first),
              ),
              const SizedBox(height: 24),
              if (state.isLoading) const LinearProgressIndicator(),
              if (state.error != null) ...[
                Text(state.error!),
                TextButton(
                  onPressed: () =>
                      ref.read(subscriptionProvider.notifier).load(),
                  child: const Text('Retry'),
                ),
              ],
              for (final plan in state.plans)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(plan.name, style: theme.textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(
                          plan.isFree
                              ? 'Free'
                              : '₹${plan.priceFor(_cycle).toStringAsFixed(2)} / ${_cycle == 'yearly' ? 'year' : 'month'}',
                        ),
                        const SizedBox(height: 16),
                        for (final feature in plan.features)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text('• $feature'),
                          ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              const Text(
                'Catalogue prices are a preview. Membership never bypasses another person’s boundaries or conversation eligibility.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
