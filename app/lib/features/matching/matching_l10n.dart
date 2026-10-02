import '../../l10n/app_localizations.dart';
import 'providers/activity_session_provider.dart';
import 'providers/gesture_timeline_provider.dart';
import 'providers/match_provider.dart';
import 'providers/trust_filter_provider.dart';

/// Translations for user-facing text produced by the matching providers.
///
/// Providers have no BuildContext, so they store their own English fallback
/// messages (the `k…` constants), which double as codes. These helpers turn a
/// known code into the reader's language and pass anything else (server
/// messages, user content) through unchanged.

String? localizeMatchesError(AppLocalizations l10n, String? error) =>
    switch (error) {
      kMatchesLoginRequiredError => l10n.matchesErrorLoginRequired,
      kMatchesLoadError => l10n.matchesErrorLoadFailed,
      kMatchesUnmatchError => l10n.matchesErrorUnmatchFailed,
      kMatchesMarkReadError => l10n.matchesErrorMarkReadFailed,
      _ => error,
    };

/// A match's display name, translating the "no name" placeholder.
String localizedMatchName(AppLocalizations l10n, String name) =>
    name == kMatchUnknownName ? l10n.matchesUnknownName : name;

/// A conversation preview, translating the "no message yet" placeholder.
String localizedMatchPreview(AppLocalizations l10n, String lastMessage) =>
    lastMessage == kMatchEmptyLastMessage ? l10n.matchesSayHi : lastMessage;

String? localizeActivityError(AppLocalizations l10n, String? error) =>
    switch (error) {
      kActivitySessionUnavailableError => l10n.matchesErrorSessionUnavailable,
      kActivityStartError => l10n.matchesActivityErrorStart,
      kActivityNotReadyError => l10n.matchesActivityErrorNotReady,
      kActivityAnswerAllError => l10n.matchesActivityErrorAnswerAll,
      kActivityTimeUpNotice => l10n.matchesActivityErrorTimeUp,
      kActivitySubmitError => l10n.matchesActivityErrorSubmit,
      kActivitySummaryError => l10n.matchesActivityErrorSummary,
      _ => error,
    };

/// Activity session status (a server wire value such as `timed_out`) as a
/// lower-case word. Unknown values fall back to the readable wire value.
String localizedActivityStatus(AppLocalizations l10n, String status) =>
    switch (status) {
      'active' => l10n.matchesActivityStatusActive,
      'timed_out' => l10n.matchesActivityStatusTimedOut,
      'partial_timeout' => l10n.matchesActivityStatusPartialTimeout,
      'completed' => l10n.matchesActivityStatusCompleted,
      _ => status.replaceAll('_', ' '),
    };

/// Translated title, prompt and option labels for one of the built-in
/// this-or-that questions. Option *values* (sent to the server) stay English;
/// only the labels change. Unknown questions are shown as they are.
({String title, String prompt, List<String> optionLabels})
localizedActivityQuestion(AppLocalizations l10n, ActivityQuestion question) {
  final built = _activityQuestionText(l10n)[question.id];
  if (built == null || built.options.length != question.options.length) {
    return (
      title: question.title,
      prompt: question.prompt,
      optionLabels: question.options,
    );
  }
  return (
    title: l10n.matchesActivityRound(built.round),
    prompt: built.prompt,
    optionLabels: built.options,
  );
}

Map<String, ({int round, String prompt, List<String> options})>
_activityQuestionText(AppLocalizations l10n) => {
  'this_or_that_01': (
    round: 1,
    prompt: l10n.matchesActivityQ1Prompt,
    options: [l10n.matchesActivityQ1OptionA, l10n.matchesActivityQ1OptionB],
  ),
  'this_or_that_02': (
    round: 2,
    prompt: l10n.matchesActivityQ2Prompt,
    options: [l10n.matchesActivityQ2OptionA, l10n.matchesActivityQ2OptionB],
  ),
  'this_or_that_03': (
    round: 3,
    prompt: l10n.matchesActivityQ3Prompt,
    options: [l10n.matchesActivityQ3OptionA, l10n.matchesActivityQ3OptionB],
  ),
  'this_or_that_04': (
    round: 4,
    prompt: l10n.matchesActivityQ4Prompt,
    options: [l10n.matchesActivityQ4OptionA, l10n.matchesActivityQ4OptionB],
  ),
  'this_or_that_05': (
    round: 5,
    prompt: l10n.matchesActivityQ5Prompt,
    options: [l10n.matchesActivityQ5OptionA, l10n.matchesActivityQ5OptionB],
  ),
  'this_or_that_06': (
    round: 6,
    prompt: l10n.matchesActivityQ6Prompt,
    options: [l10n.matchesActivityQ6OptionA, l10n.matchesActivityQ6OptionB],
  ),
  'this_or_that_07': (
    round: 7,
    prompt: l10n.matchesActivityQ7Prompt,
    options: [l10n.matchesActivityQ7OptionA, l10n.matchesActivityQ7OptionB],
  ),
  'this_or_that_08': (
    round: 8,
    prompt: l10n.matchesActivityQ8Prompt,
    options: [l10n.matchesActivityQ8OptionA, l10n.matchesActivityQ8OptionB],
  ),
};

String? localizeTrustFilterError(AppLocalizations l10n, String? error) =>
    switch (error) {
      kTrustFilterLoadError => l10n.matchesTrustErrorLoad,
      kTrustFilterSaveError => l10n.matchesTrustErrorSave,
      _ => error,
    };

/// Trust badge name by its stable code; unknown codes keep the server label.
String localizedTrustBadgeLabel(
  AppLocalizations l10n,
  TrustBadgeOption badge,
) => switch (badge.code) {
  'prompt_completer' => l10n.matchesTrustBadgePromptCompleter,
  'respectful_communicator' => l10n.matchesTrustBadgeRespectful,
  'consistent_profile' => l10n.matchesTrustBadgeConsistent,
  'verified_active' => l10n.matchesTrustBadgeVerifiedActive,
  _ => badge.label,
};

String? localizeGestureTimelineError(AppLocalizations l10n, String? error) =>
    switch (error) {
      kMatchingSessionUnavailableError => l10n.matchesErrorSessionUnavailable,
      kGestureLoadError => l10n.matchesGestureErrorLoad,
      kGesturePendingError => l10n.matchesGestureErrorPending,
      kGestureSendError => l10n.matchesGestureErrorSend,
      kGestureUpdateError => l10n.matchesGestureErrorUpdate,
      _ => error,
    };
