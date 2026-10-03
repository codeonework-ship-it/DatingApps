import '../../core/network/api_error_message.dart';
import '../../l10n/app_localizations.dart';
import 'gift_l10n.dart';

/// The match chat's error in the reader's language.
///
/// `MessageNotifier` keeps its errors as the English sentences it has always
/// produced (tests and logs read them), so the screen translates the known
/// ones here. Anything else is server text: English readers see it as sent
/// unless it looks technical; other languages get a translated generic
/// message (server text is English by policy).
String localizeChatError(AppLocalizations l, String error) {
  final fixed = <String, String>{
    'This match has ended.': l.chatErrorMatchEnded,
    'Failed to load messages. Please try again.': l.chatErrorLoadMessages,
    'Chat is locked until the quest is approved.': l.chatErrorLockedQuest,
    'Failed to send message.': l.chatErrorSendFailed,
    'Failed to delete message.': l.chatErrorDeleteFailed,
    'Delete window expired (24h).': l.chatErrorDeleteWindowExpired,
    'Only received gifts can be managed.': l.chatErrorOnlyReceivedGifts,
    'This gift is no longer available.': l.chatErrorGiftGone,
    'Could not report this gift. Please try again.':
        l.chatErrorGiftReportFailed,
    'Could not hide this gift. Please try again.': l.chatErrorGiftHideFailed,
    'Rose gifts are currently unavailable.': l.chatErrorGiftsUnavailable,
    'Not enough coins to send selected gift.':
        l.chatErrorNotEnoughCoinsSelected,
    'Your coins are on hold while we review a refunded purchase. '
            'Free gifts are still available.':
        l.chatErrorWalletFrozen,
    "You've sent a lot of gifts in a short time. Please try again later.":
        l.chatErrorGiftVelocity,
    "You've sent today's free gift. A new one is available after midnight "
            'UTC.':
        l.chatErrorFreeGiftUsed,
    'Gifts can only be sent in an active match.':
        l.chatErrorGiftNeedsActiveMatch,
    'This exclusive gift can only be sent once today.':
        l.chatErrorExclusiveGiftOnce,
    'Failed to send gift.': l.chatErrorGiftFailed,
    'User session not available.': l.chatErrorSessionUnavailable,
    'Conversation unavailable.': l.chatErrorConversationUnavailable,
  };
  final known = fixed[error];
  if (known != null) {
    return known;
  }
  final noCoins = _notEnoughCoins.firstMatch(error);
  if (noCoins != null) {
    return l.chatErrorNotEnoughCoins(
      localizedGiftName(l, serverName: noCoins.group(1)!),
    );
  }
  final unavailable = _giftUnavailable.firstMatch(error);
  if (unavailable != null) {
    return l.chatErrorGiftNotAvailable(
      localizedGiftName(l, serverName: unavailable.group(1)!),
    );
  }
  final english = l.localeName.split(RegExp('[_-]')).first == 'en';
  return english && !looksLikeTechnicalErrorText(error)
      ? error.trim()
      : l.commonSomethingWentWrongTryAgain;
}

final _notEnoughCoins = RegExp(r'^Not enough coins to send (.+)\.$');
final _giftUnavailable = RegExp(r'^(.+) is not available right now\.$');
