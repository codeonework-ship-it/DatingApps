import 'package:flutter/material.dart';
import '../../intentional_dating/dating_rhythm.dart';
import '../models/date_plan.dart';

const planAtmospheres = <String, String>{
  'quiet': 'Quiet conversation',
  'relaxed': 'Relaxed & unhurried',
  'lively': 'A lively setting',
  'outdoors': 'Outdoors',
  'indoors': 'Indoors',
};
const planAccessibility = <String, String>{
  'step_free': 'Step-free access',
  'accessible_toilet': 'Accessible toilet',
  'seating': 'Seating available',
  'low_noise': 'Low background noise',
  'nearby_transit': 'Near public transport',
  'captions': 'Captions for a video date',
};

/// Shared plan choices, not certified venue attributes or medical information.
class PlanPreferencesSummary extends StatelessWidget {
  const PlanPreferencesSummary({super.key, required this.plan});
  final DatePlan plan;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 8),
      Text(
        'Budget · ${datingBudgets[plan.budgetPreference] ?? 'Let’s decide together'}',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      if (plan.atmospherePreferences.isNotEmpty) ...[
        const SizedBox(height: 6),
        Text(
          'Atmosphere · ${plan.atmospherePreferences.map((k) => planAtmospheres[k]).whereType<String>().join(' · ')}',
        ),
      ],
      if (plan.accessibilityPreferences.isNotEmpty) ...[
        const SizedBox(height: 10),
        Text(
          'To make this comfortable',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 6),
        for (final key in plan.accessibilityPreferences)
          if (planAccessibility[key] != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• ${planAccessibility[key]}'),
            ),
        const SizedBox(height: 4),
        const Text(
          'Preferences shared for this plan. Confirm these details with the venue or video service.',
        ),
      ],
    ],
  );
}
