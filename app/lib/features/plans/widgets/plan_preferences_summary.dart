import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../intentional_dating/dating_rhythm.dart';
import '../models/date_plan.dart';

/// en-US atmosphere labels keyed by wire id; widgets show
/// [planAtmosphereLabel] in the member's language.
const planAtmospheres = <String, String>{
  'quiet': 'Quiet conversation',
  'relaxed': 'Relaxed & unhurried',
  'lively': 'A lively setting',
  'outdoors': 'Outdoors',
  'indoors': 'Indoors',
};

/// en-US accessibility labels keyed by wire id; widgets show
/// [planAccessibilityLabel] in the member's language.
const planAccessibility = <String, String>{
  'step_free': 'Step-free access',
  'accessible_toilet': 'Accessible toilet',
  'seating': 'Seating available',
  'low_noise': 'Low background noise',
  'nearby_transit': 'Near public transport',
  'captions': 'Captions for a video date',
};

/// The atmosphere label in the member's language; null for an unknown id.
String? planAtmosphereLabel(AppLocalizations l10n, String id) => switch (id) {
  'quiet' => l10n.planAtmosphereQuiet,
  'relaxed' => l10n.planAtmosphereRelaxed,
  'lively' => l10n.planAtmosphereLively,
  'outdoors' => l10n.planAtmosphereOutdoors,
  'indoors' => l10n.planAtmosphereIndoors,
  _ => null,
};

/// The accessibility label in the member's language; null for an unknown id.
String? planAccessibilityLabel(AppLocalizations l10n, String id) =>
    switch (id) {
      'step_free' => l10n.planAccessStepFree,
      'accessible_toilet' => l10n.planAccessToilet,
      'seating' => l10n.planAccessSeating,
      'low_noise' => l10n.planAccessLowNoise,
      'nearby_transit' => l10n.planAccessTransit,
      'captions' => l10n.planAccessCaptions,
      _ => null,
    };

/// Shared plan choices, not certified venue attributes or medical information.
class PlanPreferencesSummary extends StatelessWidget {
  const PlanPreferencesSummary({super.key, required this.plan});
  final DatePlan plan;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          l10n.planBudgetLine(datingBudgetLabel(l10n, plan.budgetPreference)),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (plan.atmospherePreferences.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            l10n.planAtmosphereLine(
              plan.atmospherePreferences
                  .map((k) => planAtmosphereLabel(l10n, k))
                  .whereType<String>()
                  .join(' · '),
            ),
          ),
        ],
        if (plan.accessibilityPreferences.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            l10n.planComfortHeading,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 6),
          for (final key in plan.accessibilityPreferences)
            if (planAccessibilityLabel(l10n, key) case final label?)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $label'),
              ),
          const SizedBox(height: 4),
          Text(l10n.planPreferencesDisclaimer),
        ],
      ],
    );
  }
}
