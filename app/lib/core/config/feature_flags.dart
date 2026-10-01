/// Temporary development flags.
///
/// Enable local-only auth bypass via:
/// `--dart-define=USE_MOCK_AUTH=true`.
const bool kUseMockAuth = bool.fromEnvironment(
  'USE_MOCK_AUTH',
  defaultValue: false,
);

/// Development-only discovery data mode.
/// Enable with: `--dart-define=USE_MOCK_DISCOVERY_DATA=true`.
const bool kUseMockDiscoveryData = bool.fromEnvironment(
  'USE_MOCK_DISCOVERY_DATA',
  defaultValue: false,
);

/// Enables debug-only QA navigation and automation affordances.
///
/// Off by default: this gate exposes automation-only surfaces (such as the
/// QA verification upload entry in Settings) that must never reach a shipped
/// build. The Appium runner opts in explicitly with
/// `--dart-define=ENABLE_QA_AUTOMATION=true`.
const bool kEnableQaAutomation = bool.fromEnvironment(
  'ENABLE_QA_AUTOMATION',
  defaultValue: false,
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

const bool kFeatureRoseGiftTray = bool.fromEnvironment(
  'FEATURE_ROSE_GIFT_TRAY',
  defaultValue: true,
);

const bool kShowDeletedPlaceholderForSender = bool.fromEnvironment(
  'SHOW_DELETED_PLACEHOLDER_FOR_SENDER',
  defaultValue: true,
);

/// Optional UI testing helper.
/// Enable with: `--dart-define=USE_DUMMY_MATCHES=true`.
const bool kUseDummyMatches = bool.fromEnvironment(
  'USE_DUMMY_MATCHES',
  defaultValue: false,
);
