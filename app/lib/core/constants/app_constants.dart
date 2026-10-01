/// Application-wide constants
library;

import 'package:flutter/foundation.dart' show kDebugMode;

/// App version reported with crash reports. Pass
/// `--dart-define=APP_VERSION=x.y.z --dart-define=APP_BUILD_NUMBER=n` in
/// release builds; the defaults mirror `pubspec.yaml`.
class AppVersion {
  const AppVersion._();

  static const String name = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '0.1.0',
  );
  static const String buildNumber = String.fromEnvironment(
    'APP_BUILD_NUMBER',
    defaultValue: '1',
  );
}

/// API Configuration Constants
class ApiConstants {
  /// Base URL for BFF + gateway entrypoint.
  ///
  /// Override using:
  /// `--dart-define=API_BASE_URL=https://your-domain/v1`
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// API timeouts
  static const int connectTimeout = int.fromEnvironment(
    'API_CONNECT_TIMEOUT_MS',
    defaultValue: 30000,
  );
  static const int receiveTimeout = int.fromEnvironment(
    'API_RECEIVE_TIMEOUT_MS',
    defaultValue: 30000,
  );
  static const int sendTimeout = int.fromEnvironment(
    'API_SEND_TIMEOUT_MS',
    defaultValue: 30000,
  );

  /// Endpoints
  static const String authEndpoint = '/auth';
  static const String profileEndpoint = '/profile';
  static const String swipeEndpoint = '/swipe';
  static const String matchEndpoint = '/match';
  static const String verificationEndpoint = '/verification';
  static const String messagingEndpoint = '/messaging';
}

/// Validation Constants
class ValidationConstants {
  /// Password validation
  static const int minPasswordLength = 8;
  static const int maxPasswordBytes = 72;

  /// Name validation
  static const int minNameLength = 2;
  static const int maxNameLength = 50;

  /// Bio validation
  static const int minBioLength = 10;
  static const int maxBioLength = 500;

  /// Profile photos
  static const int minPhotos = 2;
  static const int maxPhotos = 5;
  static const int maxPhotoSizeMB = 10;

  /// Height range (centimetres)
  static const int minHeightCm = 100;
  static const int maxHeightCm = 250;
}

/// Selectable profile options shown in dropdown menus.
/// Centralised here so screens never hardcode display values.
class ProfileOptionsConstants {
  const ProfileOptionsConstants._();

  static const List<String> educationLevels = [
    'High School',
    "Bachelor's",
    "Master's",
    'PhD',
    'Other',
  ];

  static const List<String> incomeRanges = [
    'Prefer not to say',
    'Below ₹5L',
    '₹5L – ₹10L',
    '₹10L – ₹20L',
    '₹20L – ₹50L',
    '₹50L+',
  ];

  static const List<String> drinkingOptions = [
    'Never',
    'Socially',
    'Regularly',
  ];

  static const List<String> smokingOptions = [
    'Never',
    'Occasionally',
    'Regularly',
  ];

  static const List<String> religionOptions = [
    'Hindu',
    'Muslim',
    'Christian',
    'Sikh',
    'Buddhist',
    'Jain',
    'Jewish',
    'Spiritual',
    'Agnostic',
    'Atheist',
    'Other',
    'Prefer not to say',
  ];
}

/// Feature Flags
class FeatureFlags {
  static const bool enableBetaFeatures = bool.fromEnvironment(
    'ENABLE_BETA_FEATURES',
    defaultValue: false,
  );
  /// Self-hosted crash and error reporting (`POST /v1/client/errors`, see
  /// `core/telemetry/client_error_reporter.dart`). There is no Firebase
  /// Crashlytics or other third-party crash SDK. Product analytics is
  /// computed server-side from API traffic, so the app has no analytics flag.
  ///
  /// Off in debug builds unless `--dart-define=CLIENT_ERROR_REPORTING=true`;
  /// on in profile and release builds unless set to false. Members can still
  /// switch it off in Privacy & Safety.
  static const bool enableClientErrorReporting = bool.fromEnvironment(
    'CLIENT_ERROR_REPORTING',
    defaultValue: !kDebugMode,
  );
  static const bool enableSOS = bool.fromEnvironment(
    'ENABLE_SOS',
    defaultValue: true,
  );
  static const bool enableVideoCall = bool.fromEnvironment(
    'ENABLE_VIDEO_CALL',
    defaultValue: true,
  );
  static const bool enableBehaviorDetection = bool.fromEnvironment(
    'ENABLE_BEHAVIOR_DETECTION',
    defaultValue: true,
  );
}

/// Error Messages
class ErrorMessages {
  static const String networkError =
      'Network error. Please check your connection.';
  static const String serverError = 'Server error. Please try again later.';
  static const String authError = 'Authentication failed. Please log in again.';
  static const String verificationError =
      'Verification failed. Please try again.';
  static const String unknownError = 'An unexpected error occurred.';
  static const String validationError =
      'Please check your input and try again.';
}

/// Cache Duration Constants (in days)
class CacheDuration {
  static const int profileCache = 1;
  static const int swipeCache = 1;
  static const int verificationCache = 7;
  static const int matchCache = 1;
}

/// Application Sizes
class AppSizes {
  /// Padding/Margin
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  /// Border radius
  static const double radiusSm = 4;
  static const double radiusMd = 8;
  static const double radiusLg = 16;
  static const double radiusXl = 24;

  /// Icon sizes
  static const double iconSm = 16;
  static const double iconMd = 24;
  static const double iconLg = 32;
  static const double iconXl = 48;
}

/// Durations for animations
class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration slower = Duration(milliseconds: 800);
}
