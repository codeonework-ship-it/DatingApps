/// Application-wide constants
library;

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

/// Supabase configuration constants (storage + table references).
class SupabaseConstants {
  /// Storage buckets
  static const String profilePhotosBucket = String.fromEnvironment(
    'SUPABASE_PROFILE_PHOTOS_BUCKET',
    defaultValue: 'profile_photos',
  );
  static const String verificationPhotosBucket = String.fromEnvironment(
    'SUPABASE_VERIFICATION_PHOTOS_BUCKET',
    defaultValue: 'verification_photos',
  );

  /// Phase 1 table references
  static const String usersTable = String.fromEnvironment(
    'SUPABASE_USERS_TABLE',
    defaultValue: 'user_management.users',
  );
  static const String preferencesTable = String.fromEnvironment(
    'SUPABASE_PREFERENCES_TABLE',
    defaultValue: 'user_management.preferences',
  );
  static const String photosTable = String.fromEnvironment(
    'SUPABASE_PHOTOS_TABLE',
    defaultValue: 'user_management.photos',
  );
  static const String swipesTable = String.fromEnvironment(
    'SUPABASE_SWIPES_TABLE',
    defaultValue: 'matching.swipes',
  );
  static const String matchesTable = String.fromEnvironment(
    'SUPABASE_MATCHES_TABLE',
    defaultValue: 'matching.matches',
  );
  static const String messagesTable = String.fromEnvironment(
    'SUPABASE_MESSAGES_TABLE',
    defaultValue: 'matching.messages',
  );
  static const String verificationsTable = String.fromEnvironment(
    'SUPABASE_VERIFICATIONS_TABLE',
    defaultValue: 'safety.verifications',
  );
  static const String reportsTable = String.fromEnvironment(
    'SUPABASE_REPORTS_TABLE',
    defaultValue: 'safety.reports',
  );
  static const String userSettingsTable = String.fromEnvironment(
    'SUPABASE_USER_SETTINGS_TABLE',
    defaultValue: 'user_management.userSettings',
  );
}

/// Validation Constants
class ValidationConstants {
  /// Password validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;

  /// Name validation
  static const int minNameLength = 2;
  static const int maxNameLength = 50;

  /// Bio validation
  static const int minBioLength = 10;
  static const int maxBioLength = 500;

  /// Profile photos
  static const int minPhotos = 2;
  static const int maxPhotos = 6;
  static const int maxPhotoSizeMB = 10;
}

/// Feature Flags
class FeatureFlags {
  static const bool enableBetaFeatures = bool.fromEnvironment(
    'ENABLE_BETA_FEATURES',
    defaultValue: false,
  );
  static const bool enableAnalytics = bool.fromEnvironment(
    'ENABLE_ANALYTICS',
    defaultValue: true,
  );
  static const bool enableCrashlytics = bool.fromEnvironment(
    'ENABLE_CRASHLYTICS',
    defaultValue: true,
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
