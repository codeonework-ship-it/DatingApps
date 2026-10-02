import '../../l10n/app_localizations.dart';

/// English fallback messages the discovery providers put in their state.
///
/// Providers have no `BuildContext`, so they keep storing these exact English
/// strings (tests and the server contract match on them) and widgets turn
/// them into the member's language with `localizeDiscoverMessage`. Messages
/// that came from the server are shown as they are.
abstract final class DiscoverMessages {
  static const loginToDiscover = 'Please login to discover profiles.';
  static const loadProfiles = 'Failed to load profiles. Please try again.';
  static const sessionUnavailable =
      'User session not available. Please login again.';
  static const likeRetry = 'Unable to like right now. Please try again.';
  static const like = 'Unable to like right now.';
  static const passRetry = 'Unable to pass right now. Please try again.';
  static const loadLikedMe = 'Could not load who liked you. Please try again.';
  static const answerInFlight = 'Already sending your answer.';
  static const answer = 'Could not send your answer. Please try again.';
}

/// Localises a known [DiscoverMessages] fallback; any other text (server
/// supplied) is returned unchanged.
String localizeDiscoverMessage(AppLocalizations l10n, String message) {
  switch (message) {
    case DiscoverMessages.loginToDiscover:
      return l10n.discoverErrorLoginToDiscover;
    case DiscoverMessages.loadProfiles:
      return l10n.discoverErrorLoadProfiles;
    case DiscoverMessages.sessionUnavailable:
      return l10n.discoverErrorSessionUnavailable;
    case DiscoverMessages.likeRetry:
      return l10n.discoverErrorLikeRetry;
    case DiscoverMessages.like:
      return l10n.discoverErrorLike;
    case DiscoverMessages.passRetry:
      return l10n.discoverErrorPassRetry;
    case DiscoverMessages.loadLikedMe:
      return l10n.discoverErrorLoadLikedMe;
    case DiscoverMessages.answerInFlight:
      return l10n.discoverErrorAnswerInFlight;
    case DiscoverMessages.answer:
      return l10n.discoverErrorAnswer;
  }
  return message;
}
