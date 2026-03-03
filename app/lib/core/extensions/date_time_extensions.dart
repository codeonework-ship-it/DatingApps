/// Extensions on [DateTime] for common operations
library;

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

  /// Format date as "dd/MM/yyyy"
  String get formattedDate => '$day/$month/$year';

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

  /// Get human readable time difference
  String getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else {
      return formattedDate;
    }
  }
}
