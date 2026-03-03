/// Extensions on [String] for common operations
library;

extension StringExtensions on String {
  /// Gets first letter capitalized
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  /// Capitalizes first letter of each word
  String get capitalizeWords =>
      split(' ').map((word) => word.capitalize).join(' ');

  /// Check if string is a valid email
  bool get isValidEmail {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(this);
  }

  /// Check if string is a valid phone number
  bool get isValidPhoneNumber {
    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{10,}$');
    return phoneRegex.hasMatch(this);
  }

  /// Check if string is a valid password
  /// Requirements: min 8 chars, at least 1 uppercase, 1 lowercase, 1 digit
  bool get isValidPassword {
    final passwordRegex = RegExp(
      r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)[A-Za-z\d@$!%*?&]{8,}$',
    );
    return passwordRegex.hasMatch(this);
  }

  /// Truncate string to specified length with ellipsis
  String truncate({required int length, String ellipsis = '...'}) {
    if (this.length <= length) return this;
    return '${substring(0, length - ellipsis.length)}$ellipsis';
  }

  /// Remove all whitespace
  String get removeWhitespace => replaceAll(RegExp(r'\s+'), '');

  /// Check if string is null or empty
  bool get isNullOrEmpty => trim().isEmpty;

  /// Get initials from string
  String getInitials({int limit = 2}) => split(' ')
      .map((word) => word.isNotEmpty ? word[0] : '')
      .take(limit)
      .join()
      .toUpperCase();
}
