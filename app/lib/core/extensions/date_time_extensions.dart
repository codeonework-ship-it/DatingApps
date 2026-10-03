/// Extensions on [DateTime] for common operations
library;

import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';

extension DateTimeExtensions on DateTime {
  /// Get age from birthdate
  int get age {
    final today = DateTime.now();
    var calculatedAge = today.year - year;
    if (today.month < month || (today.month == month && today.day < day)) {
      calculatedAge--;
    }
    return calculatedAge;
  }

  /// Format date as "HH:mm"
  String get formattedTime =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  /// Check if date is today
  bool get isToday {
    final today = DateTime.now();
    return year == today.year && month == today.month && day == today.day;
  }

  /// Check if date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Human readable time since this moment in the member's language
  /// ([l10n] is `AppLocalizations.of(context)`): "vor 3 Stunden", then the
  /// date in the locale's numeric order after a month.
  String getTimeAgo(AppLocalizations l10n) {
    final difference = DateTime.now().difference(this);
    if (difference.inSeconds < 60) {
      return l10n.timeAgoJustNow;
    } else if (difference.inMinutes < 60) {
      return l10n.timeAgoMinutes(difference.inMinutes);
    } else if (difference.inHours < 24) {
      return l10n.timeAgoHours(difference.inHours);
    } else if (difference.inDays < 7) {
      return l10n.timeAgoDays(difference.inDays);
    } else if (difference.inDays < 30) {
      return l10n.timeAgoWeeks((difference.inDays / 7).floor());
    }
    return DateFormat.yMd(l10n.localeName).format(this);
  }
}
