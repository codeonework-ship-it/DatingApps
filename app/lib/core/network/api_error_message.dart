import 'package:dio/dio.dart';

import '../../l10n/app_localizations.dart';
import '../i18n/app_l10n.dart';

/// The member-facing message for a failed API call.
///
/// Order of preference:
/// 1. A known, specific `error_code` from the server maps to a translated
///    message (in every language, English included).
/// 2. In English, the server's own `error`/`message` text (trimmed), unless
///    it looks technical (exceptions, Go error chains, SQL, JSON, …). Server
///    text is English by policy, so other languages never show it.
/// 3. `TOO_MANY_REQUESTS`, the one status-derived code whose generic message
///    helps more than the caller's fallback.
/// 4. The caller's [fallback], which is already in the member's language.
///
/// Connection failures and timeouts map to a translated "can't connect"
/// message. Raw server text is never logged here; callers log the error.
String apiErrorMessage(Object error, {required String fallback}) {
  if (error is DioException) {
    final l10n = currentAppL10n();
    final data = error.response?.data;
    if (data is Map) {
      final code = (data['error_code'] ?? '').toString().trim().toUpperCase();
      final known = apiErrorCodeMessage(l10n, code);
      if (known != null) {
        return known;
      }
      final serverText = (data['error'] ?? data['message'] ?? '')
          .toString()
          .trim();
      if (serverText.isNotEmpty &&
          currentAppLocaleIsEnglish() &&
          !looksLikeTechnicalErrorText(serverText)) {
        return serverText;
      }
      final generic = _genericStatusCodeMessage(l10n, code);
      if (generic != null) {
        return generic;
      }
    }
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return l10n.networkOfflineTryAgain;
    }
  }
  return fallback;
}

/// The translated message for a specific server `error_code`, or null when
/// the code is unknown or only derived from the HTTP status (those leave the
/// caller's own, more specific message in charge).
String? apiErrorCodeMessage(AppLocalizations l, String? code) =>
    switch ((code ?? '').trim().toUpperCase()) {
      'FEATURE_DISABLED' ||
      'FEATURE_EXCLUDED_FROM_RELEASE' ||
      'FEATURE_POLICY_UNAVAILABLE' ||
      'GROWTH_LAUNCH_BLOCKED' => l.apiErrorFeatureUnavailable,
      'MATCH_BLOCKED' => l.apiErrorConversationUnavailable,
      'MEMBER_UNAVAILABLE' => l.apiErrorMemberUnavailable,
      'CHAT_LOCKED_REQUIREMENT_PENDING' => l.apiErrorChatLocked,
      'COPILOT_DAILY_LIMIT_REACHED' => l.apiErrorCopilotDailyLimit,
      'COPILOT_UNAVAILABLE' => l.apiErrorCopilotUnavailable,
      'COPILOT_PROFILE_UNAVAILABLE' => l.apiErrorCopilotProfileUnavailable,
      'DATE_PLAN_ALREADY_OPEN' => l.apiErrorDatePlanAlreadyOpen,
      'DATE_PLAN_MATCH_INACTIVE' => l.apiErrorDatePlanMatchInactive,
      'DATE_PLAN_NOT_OPEN' => l.apiErrorDatePlanNotOpen,
      'DATE_PLAN_CHECKIN_TOO_EARLY' => l.apiErrorDatePlanCheckInTooEarly,
      'DATE_PLAN_DEBRIEF_TOO_EARLY' => l.apiErrorDatePlanDebriefTooEarly,
      'SHARED_AVAILABILITY_CHANGED' => l.apiErrorSharedAvailabilityChanged,
      'GRADUATION_ALREADY_OPEN' => l.apiErrorGraduationAlreadyOpen,
      'GRADUATION_MATCH_INACTIVE' => l.apiErrorGraduationMatchInactive,
      'GRADUATION_NOT_OPEN' => l.apiErrorGraduationNotOpen,
      'GRADUATION_ALREADY_CONFIRMED' => l.apiErrorGraduationAlreadyConfirmed,
      'REPLAY_CURSOR_EXPIRED' => l.apiErrorOutOfDate,
      'IDEMPOTENCY_KEY_CONFLICT' ||
      'IDEMPOTENCY_KEY_REUSED' ||
      'COMMAND_OUTCOME_UNCERTAIN' => l.apiErrorOutcomeUncertain,
      'DELETION_ALREADY_SCHEDULED' => l.accountDeletionAlreadyScheduled,
      'INSUFFICIENT_COINS' => l.apiErrorInsufficientCoins,
      'PAYMENT_PROVIDER_REQUIRED' => l.apiErrorPaymentsUnavailable,
      'GIFT_UNAVAILABLE' => l.chatErrorGiftGone,
      'FREE_GIFT_DAILY_LIMIT_REACHED' => l.chatErrorFreeGiftUsed,
      'GIFT_VELOCITY_LIMIT' => l.chatErrorGiftVelocity,
      'WALLET_FROZEN' => l.chatErrorWalletFrozen,
      'CHANNEL_READ_ONLY' => l.apiErrorChannelReadOnly,
      'ROOM_CLOSED' || 'ROOM_NOT_ACTIVE' => l.roomsClosedSnack,
      'ROOM_CAPACITY_REACHED' => l.apiErrorRoomFull,
      'ROOM_BLOCKED_ACTIVE_SESSION' => l.apiErrorRoomRemoved,
      'ROOM_NOT_JOINED' => l.apiErrorRoomNotJoined,
      'DAILY_MESSAGE_LIMIT_REACHED' => l.apiErrorDailyMessageLimit,
      'DAILY_LIKE_LIMIT_REACHED' => l.apiErrorDailyLikeLimit,
      'FRIEND_REQUIRED' => l.apiErrorFriendRequired,
      'VOUCH_EXISTS' => l.apiErrorVouchExists,
      'INTRO_UNAVAILABLE' => l.apiErrorIntroUnavailable,
      'INTRO_ALREADY_OPEN' => l.apiErrorIntroAlreadyOpen,
      'INTRO_NOT_OPEN' => l.apiErrorIntroNotOpen,
      'QUEST_RATE_LIMITED' ||
      'COIN_ECONOMY_THROTTLED' => l.apiErrorTooManyTries,
      'QUEST_COOLDOWN' => l.apiErrorQuestCooldown,
      'QUEST_SELF_REVIEW' => l.apiErrorQuestSelfReview,
      'QUEST_NOT_A_PARTICIPANT' => l.apiErrorQuestNotParticipant,
      'UPSTREAM_SERVICE_ERROR' || 'REQUEST_SHEDDED' => l.apiErrorServiceBusy,
      _ => null,
    };

/// Codes the server derives from the HTTP status text (`writeError`). Only
/// those with a message that helps more than the caller's fallback are
/// mapped; BAD_REQUEST, UNAUTHORIZED (a wrong password at sign-in is one),
/// NOT_FOUND, CONFLICT, FORBIDDEN, 5xx … keep the caller's specific fallback.
String? _genericStatusCodeMessage(AppLocalizations l, String code) =>
    switch (code) {
      'TOO_MANY_REQUESTS' => l.apiErrorTooManyTries,
      _ => null,
    };

final _technicalPatterns = <RegExp>[
  RegExp('exception', caseSensitive: false),
  RegExp(r'\berror:', caseSensitive: false),
  RegExp(r'\bpanic\b|goroutine|nil pointer|stack ?trace', caseSensitive: false),
  RegExp(r'#\d+\s'),
  RegExp(r'\bat \S+\.(dart|go|java|kt|js|ts):\d+'),
  RegExp(r'\.go:\d+'),
  RegExp(r'dial tcp|connection refused|connection reset|broken pipe|\bEOF\b'),
  RegExp(r'context deadline|context canceled|deadline exceeded'),
  RegExp(r'rpc error|upstream|x509|tls:|i/o timeout', caseSensitive: false),
  RegExp(
    r'\bsql\b|sqlstate|\bpq:|duplicate key|violates .*constraint',
    caseSensitive: false,
  ),
  // Upper-case SQL only: "Select a photo from your gallery" is fine.
  RegExp(r'\b(SELECT|INSERT|UPDATE|DELETE)\b.+\b(FROM|INTO|SET|WHERE)\b'),
  RegExp(r'json:|invalid character|unexpected end', caseSensitive: false),
  RegExp(r'[{}<>]|%!|\[\]|\bnull\b|\bnil\b'),
  // snake_case identifiers (field names, codes) are not member language.
  RegExp(r'\b[a-z0-9]+_[a-z0-9_]+\b'),
  // A Go wrapped chain such as "load profile failed: query: timeout".
  RegExp(r'^[^:]+:\s[^:]+:\s'),
  RegExp(r'\bfailed:\s', caseSensitive: false),
];

/// True when [text] reads like a developer error rather than a sentence
/// written for members (exception text, stack frames, Go error chains, SQL,
/// JSON, format verbs, network internals, very long dumps).
bool looksLikeTechnicalErrorText(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) {
    return true;
  }
  if (trimmed.length > 240 || trimmed.contains('\n')) {
    return true;
  }
  return _technicalPatterns.any((pattern) => pattern.hasMatch(trimmed));
}

/// [apiErrorMessage] for a reply the server actually sent; a request that
/// never got a reply (offline, timeout) keeps the caller's own [fallback].
///
/// For providers whose screens already explain an unreachable server in
/// their own words: they get the translated error codes and the English-only,
/// never-technical server text without changing what offline looks like.
String serverErrorMessage(Object error, {required String fallback}) =>
    error is DioException && error.response == null
    ? fallback
    : apiErrorMessage(error, fallback: fallback);
