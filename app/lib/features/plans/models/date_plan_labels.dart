/// Localised copy for date plans. Kept apart from `date_plan.dart` so the
/// model stays pure Dart (no Flutter import) and its English fallbacks keep
/// serving logs, tests and anything rendered outside a `Localizations` scope.
library;

import '../../../l10n/app_localizations.dart';
import 'date_plan.dart';

/// The venue category label in the member's language, keyed by the wire
/// category. Unknown categories read as "something else", like the model.
String datePlanVenueLabel(AppLocalizations l10n, String category) =>
    switch (category) {
      'coffee' => l10n.planVenueCoffee,
      'meal' => l10n.planVenueMeal,
      'drinks' => l10n.planVenueDrinks,
      'walk' => l10n.planVenueWalk,
      'activity' => l10n.planVenueActivity,
      'event' => l10n.planVenueEvent,
      'video_call' => l10n.planVenueVideoCall,
      _ => l10n.planVenueOther,
    };

extension DatePlanLabels on DatePlan {
  /// [DatePlan.summary] in the member's language and date format:
  /// "Sa. 28. Sep. · 16:00–18:00 · Kaffee · Indiranagar".
  String localizedSummary(AppLocalizations l10n, {String? locale}) {
    final parts = <String>[
      describeDatePlanWindow(windowStart, windowEnd, locale: locale),
      datePlanVenueLabel(l10n, venueCategory),
      if (venueName.isNotEmpty) venueName,
      if (venueArea.isNotEmpty) venueArea,
    ];
    return parts.join(' · ');
  }
}

extension FriendPlanLabels on FriendPlan {
  /// The friend's plan on one line, in the member's language.
  String localizedSummary(AppLocalizations l10n, {String? locale}) {
    final parts = <String>[
      describeDatePlanWindow(windowStart, windowEnd, locale: locale),
      datePlanVenueLabel(l10n, venueCategory),
      if (venueArea.isNotEmpty) venueArea,
    ];
    return parts.join(' · ');
  }
}
