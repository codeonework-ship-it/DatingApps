/// Localised copy for graduation. Kept apart from `graduation.dart` so the
/// model stays pure Dart.
library;

import '../../../l10n/app_localizations.dart';
import 'graduation.dart';

/// The fallback message for a failed graduation or discovery-pause request,
/// in the member's language.
String graduationFailureMessage(
  AppLocalizations l10n,
  GraduationFailure failure,
) => switch (failure) {
  GraduationFailure.load => l10n.graduationLoadFailed,
  GraduationFailure.propose => l10n.graduationProposeFailed,
  GraduationFailure.confirm => l10n.graduationConfirmFailed,
  GraduationFailure.decline => l10n.graduationDeclineFailed,
  GraduationFailure.withdraw => l10n.graduationWithdrawFailed,
  GraduationFailure.pauseLoad => l10n.graduationPauseLoadFailed,
  GraduationFailure.pause => l10n.graduationPauseFailed,
  GraduationFailure.resume => l10n.graduationResumeFailed,
};

/// A provider error for display: the server's own message when it sent one,
/// otherwise the request's fallback in the member's language. Use with
/// `MatchGraduationState` and `DiscoveryPauseState` (`error`, `failure`).
String localizedGraduationError(
  AppLocalizations l10n,
  String error,
  GraduationFailure? failure,
) => failure == null ? error : graduationFailureMessage(l10n, failure);
