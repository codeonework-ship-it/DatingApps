/// Temporary development flags.
///
/// Enable local-only auth bypass via:
/// `--dart-define=USE_MOCK_AUTH=true`.
const bool kUseMockAuth = bool.fromEnvironment(
  'USE_MOCK_AUTH',
  defaultValue: false,
);

/// Temporary auth shortcut: bypass OTP verification step.
/// Disable with: `--dart-define=BYPASS_OTP_VALIDATION=false`.
const bool kBypassOtpValidation = bool.fromEnvironment(
  'BYPASS_OTP_VALIDATION',
  defaultValue: true,
);

const bool kFeatureEngagementUnlockMvp = bool.fromEnvironment(
  'FEATURE_ENGAGEMENT_UNLOCK_MVP',
  defaultValue: true,
);

const bool kFeatureDigitalGestures = bool.fromEnvironment(
  'FEATURE_DIGITAL_GESTURES',
  defaultValue: true,
);

const bool kFeatureMiniActivities = bool.fromEnvironment(
  'FEATURE_MINI_ACTIVITIES',
  defaultValue: true,
);

const bool kFeatureTrustBadges = bool.fromEnvironment(
  'FEATURE_TRUST_BADGES',
  defaultValue: true,
);

const bool kFeatureConversationRooms = bool.fromEnvironment(
  'FEATURE_CONVERSATION_ROOMS',
  defaultValue: true,
);
