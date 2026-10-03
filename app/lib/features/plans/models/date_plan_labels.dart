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
  /// The match's name, or "Your match" in the member's language when the
  /// server sent none.
  String partnerLabel(AppLocalizations l10n) =>
      partnerName.trim().isEmpty ? l10n.matchesFallbackName : partnerName;

  /// The plan on one line in the member's language and date format:
  /// "Sa. 28. Sep. · 16:00–18:00 · Kaffee · Indiranagar".
  String localizedSummary(AppLocalizations l10n, {String? locale}) {
    final parts = <String>[
      describeDatePlanWindow(
        windowStart,
        windowEnd,
        locale: locale ?? l10n.localeName,
      ),
      datePlanVenueLabel(l10n, venueCategory),
      if (venueName.isNotEmpty) venueName,
      if (venueArea.isNotEmpty) venueArea,
    ];
    return parts.join(' · ');
  }
}

extension FriendPlanLabels on FriendPlan {
  /// The friend's name, or "A friend" in the member's language.
  String friendLabel(AppLocalizations l10n) =>
      friendName.trim().isEmpty ? l10n.planSharingFriendFallback : friendName;

  /// The friend's plan on one line, in the member's language.
  String localizedSummary(AppLocalizations l10n, {String? locale}) {
    final parts = <String>[
      describeDatePlanWindow(
        windowStart,
        windowEnd,
        locale: locale ?? l10n.localeName,
      ),
      datePlanVenueLabel(l10n, venueCategory),
      if (venueArea.isNotEmpty) venueArea,
    ];
    return parts.join(' · ');
  }
}

extension DatePlanShareGroupLabels on DatePlanShareGroup {
  /// The group's name, or "Group" in the member's language.
  String label(AppLocalizations l10n) =>
      name.trim().isEmpty ? l10n.groupsDetailTitleFallback : name;
}

/// A plan status in the member's language. Unknown statuses read as the wire
/// value with a capital letter, as before.
String datePlanStatusLabel(AppLocalizations l10n, String status) =>
    switch (status) {
      'proposed' => l10n.planStatusProposed,
      'accepted' => l10n.planStatusConfirmed,
      'cancelled' => l10n.plansNextCancelled,
      'declined' => l10n.planStatusDeclined,
      'expired' => l10n.planStatusExpired,
      'completed' => l10n.planStatusCompleted,
      'did_not_happen' => l10n.planStatusDidNotHappen,
      'disputed' => l10n.planStatusDisputed,
      '' => status,
      _ => status[0].toUpperCase() + status.substring(1).replaceAll('_', ' '),
    };

/// The fallback message for a failed plan request, in the member's language.
String datePlanFailureMessage(AppLocalizations l10n, DatePlanFailure failure) =>
    switch (failure) {
      DatePlanFailure.load => l10n.plansLoadFailed,
      DatePlanFailure.feed => l10n.plansFeedLoadFailed,
      DatePlanFailure.propose => l10n.planProposeFailed,
      DatePlanFailure.accept => l10n.planAcceptFailed,
      DatePlanFailure.decline => l10n.planDeclineFailed,
      DatePlanFailure.cancel => l10n.planCancelFailed,
      DatePlanFailure.checkin => l10n.planCheckinFailed,
      DatePlanFailure.debrief => l10n.debriefSaveFailed,
    };

/// A provider error for display: the server's own message when it sent one,
/// otherwise the request's fallback in the member's language.
String localizedDatePlanError(
  AppLocalizations l10n,
  String error,
  DatePlanFailure? failure,
) => failure == null ? error : datePlanFailureMessage(l10n, failure);
