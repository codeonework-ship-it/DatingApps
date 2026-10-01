package config

import (
	"fmt"
	"net/url"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"
)

type Config struct {
	Environment string
	LogLevel    string

	APIPrefix            string
	MobileBFFUpstreamURL string

	APIGatewayAddr    string
	MobileBFFAddr     string
	AuthGRPCAddr      string
	ProfileGRPCAddr   string
	MatchingGRPCAddr  string
	ChatGRPCAddr      string
	AuthAdminAddr     string
	ProfileAdminAddr  string
	MatchingAdminAddr string
	ChatAdminAddr     string

	APIGatewayReadHeaderTimeoutSec   int
	MobileBFFReadHeaderTimeoutSec    int
	ShutdownTimeoutSec               int
	BFFRequestTimeoutSec             int
	BFFFastReadTimeoutMS             int
	BFFNormalReadTimeoutMS           int
	BFFWriteTimeoutMS                int
	GatewayReadyProbeTimeoutSec      int
	GatewayRateLimitRequests         int
	GatewayRateLimitWindowSec        int
	GatewayMaxInFlight               int
	GatewayRetryAfterSec             int
	GatewaySkipPostgresProbe         bool
	BFFMaxInFlight                   int
	BFFRetryAfterSec                 int
	BFFBulkheadAuthMaxInFlight       int
	BFFBulkheadProfileMaxInFlight    int
	BFFBulkheadMatchingMaxInFlight   int
	BFFBulkheadMessagingMaxInFlight  int
	BFFBulkheadEngagementMaxInFlight int
	BFFBulkheadAdminMaxInFlight      int
	IdempotencyTTLSeconds            int
	IdempotencyLeaseSeconds          int
	IdempotencyPollMilliseconds      int
	IdempotencyMaxResponseBytes      int

	AuthHTTPTimeoutSec       int
	SupabaseHTTPTimeoutSec   int
	ChatWorkerCount          int
	ChatWorkerQueueSize      int
	ChatRealtimeSchema       string
	ChatRealtimeTable        string
	ChatRealtimeMaxEvents    int
	ChatRealtimeLogLevel     string
	ChatRealtimeHeartbeatSec int

	SupabaseURL                      string
	SupabaseReadReplicaURL           string
	SupabaseAnonKey                  string
	SupabaseServiceRole              string
	UseLocalDB                       bool
	DatabaseURL                      string
	DatabaseHost                     string
	DatabasePort                     int
	DatabaseName                     string
	DatabaseUser                     string
	DatabasePassword                 string
	DatabaseSSLMode                  string
	PostgresStatementTimeoutMS       int
	PostgresLockTimeoutMS            int
	PostgresIdleTransactionTimeoutMS int
	PostgresPoolMaxConns             int
	PostgresPoolMinConns             int

	UserSchema                 string
	UsersTable                 string
	PreferencesTable           string
	PhotosTable                string
	MatchingSchema             string
	SwipesTable                string
	MatchesTable               string
	MessagesTable              string
	EngagementSchema           string
	UnlockStatesTable          string
	QuestTemplatesTable        string
	QuestWorkflowsTable        string
	GesturesTable              string
	GiftCatalogTable           string
	UserWalletsTable           string
	MatchGiftSendsTable        string
	GiftSpendActivitiesTable   string
	WalletCoinPurchasesTable   string
	GiftDailyEntitlementsTable string
	AdmirerGiftEscrowTable     string
	CommunityGroupsTable       string
	CommunityGroupMembersTable string
	CommunityGroupInvitesTable string
	GestureMinContentChars     int
	GestureMinWordCount        int
	GestureOriginalityPercent  int
	GestureProfanityTokens     []string

	DefaultProfileImageURL   string
	DefaultAvatarImageURL    string
	MockPhotoSeedURLTemplate string
	MockBlockedPhotoTemplate string
	// MediaStorage is the dedicated media storage section (local filesystem
	// layout + AWS S3 bucket/auth). See storage.go. The flat fields below are
	// kept in sync for existing callers.
	MediaStorage                    MediaStorageConfig
	UseAWSS3Storage                 bool
	FileStorageBackend              string
	MediaUploadsDir                 string
	MediaPublicBaseURL              string
	AWSS3Region                     string
	AWSS3Bucket                     string
	AWSS3Endpoint                   string
	AWSS3AccessKeyID                string
	AWSS3SecretAccessKey            string
	AWSS3PublicBaseURL              string
	AWSS3ProfilePhotosPrefix        string
	AWSS3ForcePathStyle             bool
	MediaModerationProvider         string
	MediaModerationRequired         bool
	MediaModerationMinConfidence    int
	MediaModerationReviewConfidence int
	MediaModerationRejectConfidence int
	MediaModerationRejectLabels     []string
	MediaModerationReviewLabels     []string
	AWSRekognitionEndpoint          string

	MockAuthEnabled      bool
	MockDataEnabled      bool
	MockAuthUsername     string
	MockAuthPassword     string
	MockUserID           string
	MockAccessToken      string
	MockRefreshToken     string
	MockFemaleUsersCount int
	MockMaleUsersCount   int
	MockMinAgeYears      int
	MockMaxAgeYears      int

	FeatureEngagementUnlockMVP      bool
	FeatureDigitalGestures          bool
	FeatureMiniActivities           bool
	FeatureTrustBadges              bool
	FeatureConversationRooms        bool
	FeatureExperimentFramework      bool
	FeatureExperimentMatchNudge     bool
	ExperimentMatchNudgeRolloutPct  int
	FeatureAssistedReviewAutomation bool
	AssistedReviewMinChars          int
	AssistedReviewMinWordCount      int
	DefaultUnlockPolicyVariant      string
	RequireDurableEngagementStore   bool
	FanoutWorkerCount               int
	FanoutQueueSize                 int
	NotificationWorkerCount         int
	NotificationBatchSize           int
	NotificationPollIntervalMS      int
	NotificationMaxAttempts         int
	NotificationPushProvider        string
	NotificationPushWebhookURL      string
	NotificationPushWebhookToken    string
	NotificationFCMProjectID        string
	NotificationFCMCredentialsFile  string
	NotificationFCMTokenURL         string
	NotificationFCMEndpoint         string
	NotificationAPNSTeamID          string
	NotificationAPNSKeyID           string
	NotificationAPNSBundleID        string
	NotificationAPNSPrivateKeyFile  string
	NotificationAPNSUseSandbox      bool
	NotificationAPNSEndpoint        string
	NotificationSLOMaxQueueDepth    int
	NotificationSLOMaxOldestAgeSec  int
	NotificationSLOMinSuccessPct    int
	SOSDeliveryProvider             string
	SOSDeliveryWebhookURL           string
	SOSDeliveryWebhookToken         string
	SOSDeliveryPollIntervalMS       int
	SOSDeliveryMaxAttempts          int
	// SOSDeliveryRequired makes startup fail when SOS commands are available
	// but no delivery provider is configured: an emergency alert that nobody
	// receives is worse than no SOS button. Defaults on in production-like
	// environments; set SOS_DELIVERY_REQUIRED=false only together with turning
	// the safety_sos_enabled flag off.
	SOSDeliveryRequired       bool
	MasterDataCacheTTLSeconds int

	// Payments (PEN-01). PaymentsProvider selects the processor used for card
	// checkout and auto-renewing subscriptions: "stripe", "sandbox" (local,
	// in-process, never charges a card) or "disabled".
	PaymentsProvider              string
	PaymentsPublicBaseURL         string
	PaymentsCurrency              string
	PaymentsSandboxWebhookSecret  string
	StripeSecretKey               string
	StripeWebhookSecret           string
	StripeAPIBaseURL              string
	BillingPastDueGraceDays       int
	BillingRenewalSweepSeconds    int
	BillingLocalActivationEnabled bool
	// ReleaseExcludedFlags are runtime flags the first-release contract
	// (documents/contracts/release_contract.v1.json, excluded_capabilities)
	// keeps off. Their routes are rejected and /config/flags reports them off
	// regardless of the database row. Defaults to FirstReleaseExcludedFlags in
	// production-like environments and to none elsewhere; RELEASE_EXCLUDED_FLAGS
	// overrides the list ("none" clears it).
	ReleaseExcludedFlags             []string
	BillingEnforceDailyLimits        bool
	CallTransportProvider            string
	CallRoomBaseURL                  string
	CallJWTIssuer                    string
	CallJWTAudience                  string
	CallJWTSecret                    string
	CallTokenTTLSeconds              int
	IdentityVerificationProvider     string
	IdentityVerificationRequired     bool
	IdentityVerificationWebhookURL   string
	IdentityVerificationWebhookToken string
	IdentityVerificationActorID      string
	VoiceModerationProvider          string
	VoiceModerationRequired          bool
	VoiceModerationWebhookURL        string
	VoiceModerationWebhookToken      string
	PrivateMediaSigningKey           string
	PrivateMediaTokenTTLSeconds      int
}

func Load() (Config, error) {
	// The separate storage env file (STORAGE_CONFIG_FILE) is applied first so
	// every storage setting below can come from it.
	if err := ApplyStorageConfigFile(); err != nil {
		return Config{}, err
	}
	databaseHost := getOrDefault("DATABASE_HOST", getOrDefault("SUPABASE_DB_HOST", ""))
	databasePort := getInt("DATABASE_PORT", getInt("SUPABASE_DB_PORT", 5432))
	databaseName := getOrDefault("DATABASE_NAME", getOrDefault("SUPABASE_DB_NAME", "postgres"))
	databaseUser := getOrDefault("DATABASE_USER", getOrDefault("SUPABASE_DB_USER", "postgres"))
	databasePassword := getOrDefault("DATABASE_PASSWORD", getOrDefault("SUPABASE_DB_PASSWORD", ""))
	databaseSSLMode := getOrDefault("DATABASE_SSLMODE", getOrDefault("SUPABASE_DB_SSLMODE", "require"))

	databaseURL := getOrDefault("DATABASE_URL", getOrDefault("SUPABASE_DATABASE_URL", ""))
	useLocalDB := getOrDefault("USE_LOCAL_DB", "false") == "true"
	if useLocalDB {
		databaseURL = getOrDefault("LOCAL_DATABASE_URL", "postgresql://postgres:root%40123@localhost:5433/dating_app?sslmode=disable")
	} else if databaseURL == "" {
		databaseURL = getOrDefault("PROD_DATABASE_URL", buildPostgresURL(
			databaseHost,
			databasePort,
			databaseName,
			databaseUser,
			databasePassword,
			databaseSSLMode,
		))
	}

	supabaseURL := getOrDefault("SUPABASE_URL", deriveSupabaseURLFromDBHost(databaseHost))
	supabaseAnonKey := os.Getenv("SUPABASE_ANON_KEY")
	supabaseServiceRole := os.Getenv("SUPABASE_SERVICE_ROLE")

	cfg := Config{
		Environment:                      getOrDefault("ENVIRONMENT", "development"),
		LogLevel:                         getOrDefault("LOG_LEVEL", "debug"),
		APIPrefix:                        normalizePrefix(getOrDefault("API_PREFIX", "/v1")),
		APIGatewayAddr:                   getOrDefault("API_GATEWAY_ADDR", ":8080"),
		MobileBFFAddr:                    getOrDefault("MOBILE_BFF_ADDR", ":8081"),
		AuthGRPCAddr:                     getOrDefault("AUTH_SVC_GRPC_ADDR", ":9091"),
		ProfileGRPCAddr:                  getOrDefault("PROFILE_SVC_GRPC_ADDR", ":9092"),
		MatchingGRPCAddr:                 getOrDefault("MATCHING_SVC_GRPC_ADDR", ":9093"),
		ChatGRPCAddr:                     getOrDefault("CHAT_SVC_GRPC_ADDR", ":9094"),
		AuthAdminAddr:                    getOrDefault("AUTH_SVC_ADMIN_ADDR", ":10091"),
		ProfileAdminAddr:                 getOrDefault("PROFILE_SVC_ADMIN_ADDR", ":10092"),
		MatchingAdminAddr:                getOrDefault("MATCHING_SVC_ADMIN_ADDR", ":10093"),
		ChatAdminAddr:                    getOrDefault("CHAT_SVC_ADMIN_ADDR", ":10094"),
		APIGatewayReadHeaderTimeoutSec:   getInt("API_GATEWAY_READ_HEADER_TIMEOUT_SEC", 10),
		MobileBFFReadHeaderTimeoutSec:    getInt("MOBILE_BFF_READ_HEADER_TIMEOUT_SEC", 10),
		ShutdownTimeoutSec:               getInt("SHUTDOWN_TIMEOUT_SEC", 10),
		BFFRequestTimeoutSec:             getInt("BFF_REQUEST_TIMEOUT_SEC", 8),
		BFFFastReadTimeoutMS:             getInt("BFF_FAST_READ_TIMEOUT_MS", 750),
		BFFNormalReadTimeoutMS:           getInt("BFF_NORMAL_READ_TIMEOUT_MS", 3000),
		BFFWriteTimeoutMS:                getInt("BFF_WRITE_TIMEOUT_MS", 8000),
		GatewayReadyProbeTimeoutSec:      getInt("GATEWAY_READY_TIMEOUT_SEC", 2),
		GatewayRateLimitRequests:         getInt("GATEWAY_RATE_LIMIT_REQUESTS", 120),
		GatewayRateLimitWindowSec:        getInt("GATEWAY_RATE_LIMIT_WINDOW_SEC", 1),
		GatewayMaxInFlight:               getInt("GATEWAY_MAX_INFLIGHT", 2000),
		GatewayRetryAfterSec:             getInt("GATEWAY_RETRY_AFTER_SEC", 1),
		GatewaySkipPostgresProbe:         getBool("GATEWAY_SKIP_POSTGRES_PROBE", false),
		BFFMaxInFlight:                   getInt("BFF_MAX_INFLIGHT", 1500),
		BFFRetryAfterSec:                 getInt("BFF_RETRY_AFTER_SEC", 1),
		BFFBulkheadAuthMaxInFlight:       getInt("BFF_BULKHEAD_AUTH_MAX_INFLIGHT", 200),
		BFFBulkheadProfileMaxInFlight:    getInt("BFF_BULKHEAD_PROFILE_MAX_INFLIGHT", 300),
		BFFBulkheadMatchingMaxInFlight:   getInt("BFF_BULKHEAD_MATCHING_MAX_INFLIGHT", 400),
		BFFBulkheadMessagingMaxInFlight:  getInt("BFF_BULKHEAD_MESSAGING_MAX_INFLIGHT", 300),
		BFFBulkheadEngagementMaxInFlight: getInt("BFF_BULKHEAD_ENGAGEMENT_MAX_INFLIGHT", 300),
		BFFBulkheadAdminMaxInFlight:      getInt("BFF_BULKHEAD_ADMIN_MAX_INFLIGHT", 80),
		IdempotencyTTLSeconds:            getInt("IDEMPOTENCY_TTL_SECONDS", 600),
		IdempotencyLeaseSeconds:          getInt("IDEMPOTENCY_LEASE_SECONDS", 15),
		IdempotencyPollMilliseconds:      getInt("IDEMPOTENCY_POLL_MS", 25),
		IdempotencyMaxResponseBytes:      getInt("IDEMPOTENCY_MAX_RESPONSE_BYTES", 1048576),
		AuthHTTPTimeoutSec:               getInt("AUTH_HTTP_TIMEOUT_SEC", 12),
		SupabaseHTTPTimeoutSec:           getInt("SUPABASE_HTTP_TIMEOUT_SEC", 15),
		ChatWorkerCount:                  getInt("CHAT_WORKER_COUNT", 8),
		ChatWorkerQueueSize:              getInt("CHAT_WORKER_QUEUE_SIZE", 256),
		ChatRealtimeSchema:               getOrDefault("CHAT_REALTIME_SCHEMA", "public"),
		ChatRealtimeTable:                getOrDefault("CHAT_REALTIME_TABLE", "messages"),
		ChatRealtimeMaxEvents:            getInt("CHAT_REALTIME_MAX_EVENTS", 512),
		ChatRealtimeLogLevel:             getOrDefault("CHAT_REALTIME_LOG_LEVEL", "warn"),
		ChatRealtimeHeartbeatSec:         getInt("CHAT_REALTIME_HEARTBEAT_SEC", 25),
		SupabaseURL:                      supabaseURL,
		SupabaseReadReplicaURL:           strings.TrimSpace(getOrDefault("SUPABASE_READ_REPLICA_URL", "")),
		SupabaseAnonKey:                  supabaseAnonKey,
		SupabaseServiceRole:              supabaseServiceRole,
		UseLocalDB:                       useLocalDB,
		DatabaseURL:                      databaseURL,
		DatabaseHost:                     databaseHost,
		DatabasePort:                     databasePort,
		DatabaseName:                     databaseName,
		DatabaseUser:                     databaseUser,
		DatabasePassword:                 databasePassword,
		DatabaseSSLMode:                  databaseSSLMode,
		PostgresStatementTimeoutMS:       getInt("POSTGRES_STATEMENT_TIMEOUT_MS", 5000),
		PostgresLockTimeoutMS:            getInt("POSTGRES_LOCK_TIMEOUT_MS", 1000),
		PostgresIdleTransactionTimeoutMS: getInt("POSTGRES_IDLE_TRANSACTION_TIMEOUT_MS", 15000),
		PostgresPoolMaxConns:             getInt("POSTGRES_POOL_MAX_CONNS", 16),
		PostgresPoolMinConns:             getInt("POSTGRES_POOL_MIN_CONNS", 2),
		UserSchema:                       getOrDefault("USER_SCHEMA", getOrDefault("SUPABASE_USER_SCHEMA", "user_management")),
		UsersTable:                       getOrDefault("USERS_TABLE", getOrDefault("SUPABASE_USERS_TABLE", "users")),
		PreferencesTable:                 getOrDefault("PREFERENCES_TABLE", getOrDefault("SUPABASE_PREFERENCES_TABLE", "preferences")),
		PhotosTable:                      getOrDefault("PHOTOS_TABLE", getOrDefault("SUPABASE_PHOTOS_TABLE", "photos")),
		MatchingSchema:                   getOrDefault("MATCHING_SCHEMA", getOrDefault("SUPABASE_MATCHING_SCHEMA", "matching")),
		SwipesTable:                      getOrDefault("SUPABASE_SWIPES_TABLE", "swipes"),
		MatchesTable:                     getOrDefault("SUPABASE_MATCHES_TABLE", "matches"),
		MessagesTable:                    getOrDefault("SUPABASE_MESSAGES_TABLE", "messages"),
		EngagementSchema:                 getOrDefault("SUPABASE_ENGAGEMENT_SCHEMA", "matching"),
		UnlockStatesTable:                getOrDefault("SUPABASE_UNLOCK_STATES_TABLE", "match_unlock_states"),
		QuestTemplatesTable:              getOrDefault("SUPABASE_QUEST_TEMPLATES_TABLE", "match_quest_templates"),
		QuestWorkflowsTable:              getOrDefault("SUPABASE_QUEST_WORKFLOWS_TABLE", "match_quest_workflows"),
		GesturesTable:                    getOrDefault("SUPABASE_GESTURES_TABLE", "match_gestures"),
		GiftCatalogTable:                 getOrDefault("SUPABASE_GIFT_CATALOG_TABLE", "gift_catalog"),
		UserWalletsTable:                 getOrDefault("SUPABASE_USER_WALLETS_TABLE", "user_wallets"),
		MatchGiftSendsTable:              getOrDefault("SUPABASE_MATCH_GIFT_SENDS_TABLE", "match_gift_sends"),
		GiftSpendActivitiesTable:         getOrDefault("SUPABASE_GIFT_SPEND_ACTIVITIES_TABLE", "gift_spend_activities"),
		WalletCoinPurchasesTable:         getOrDefault("SUPABASE_WALLET_COIN_PURCHASES_TABLE", "wallet_coin_purchases"),
		GiftDailyEntitlementsTable:       getOrDefault("SUPABASE_GIFT_DAILY_ENTITLEMENTS_TABLE", "gift_daily_entitlements"),
		AdmirerGiftEscrowTable:           getOrDefault("SUPABASE_ADMIRER_GIFT_ESCROW_TABLE", "admirer_gift_escrow"),
		CommunityGroupsTable:             getOrDefault("SUPABASE_COMMUNITY_GROUPS_TABLE", "community_groups"),
		CommunityGroupMembersTable:       getOrDefault("SUPABASE_COMMUNITY_GROUP_MEMBERS_TABLE", "community_group_members"),
		CommunityGroupInvitesTable:       getOrDefault("SUPABASE_COMMUNITY_GROUP_INVITES_TABLE", "community_group_invites"),
		GestureMinContentChars:           getInt("GESTURE_MIN_CONTENT_CHARS", 40),
		GestureMinWordCount:              getInt("GESTURE_MIN_WORD_COUNT", 8),
		GestureOriginalityPercent:        getInt("GESTURE_ORIGINALITY_PERCENT", 65),
		GestureProfanityTokens:           getCSVOrDefault("GESTURE_PROFANITY_TOKENS", []string{"fuck", "shit", "bitch", "asshole", "bastard", "slut"}),
		DefaultProfileImageURL: getOrDefault(
			"DEFAULT_PROFILE_IMAGE_URL",
			"https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=900&q=80",
		),
		DefaultAvatarImageURL: getOrDefault(
			"DEFAULT_AVATAR_IMAGE_URL",
			"https://images.unsplash.com/photo-1521572267360-ee0c2909d518?auto=format&fit=crop&w=500&q=80",
		),
		MockPhotoSeedURLTemplate: getOrDefault(
			"MOCK_PHOTO_SEED_URL_TEMPLATE",
			"https://picsum.photos/seed/%s/720/960",
		),
		MockBlockedPhotoTemplate: getOrDefault(
			"MOCK_BLOCKED_PHOTO_URL_TEMPLATE",
			"https://picsum.photos/seed/%s/200/200",
		),
		UseAWSS3Storage: getBool(
			"USE_AWS_S3_STORAGE",
			false,
		),
		FileStorageBackend: getOrDefault(
			"FILE_STORAGE_BACKEND",
			"local_fs",
		),
		MediaUploadsDir: getOrDefault(
			"MEDIA_UPLOADS_DIR",
			".run/uploads/profile_photos",
		),
		MediaPublicBaseURL: getOrDefault(
			"MEDIA_PUBLIC_BASE_URL",
			"auto",
		),
		AWSS3Region: getOrDefault(
			"AWS_S3_REGION",
			"",
		),
		AWSS3Bucket: getOrDefault(
			"AWS_S3_BUCKET",
			"",
		),
		AWSS3Endpoint: getOrDefault(
			"AWS_S3_ENDPOINT",
			"",
		),
		AWSS3AccessKeyID: getOrDefault(
			"AWS_S3_ACCESS_KEY_ID",
			"",
		),
		AWSS3SecretAccessKey: getOrDefault(
			"AWS_S3_SECRET_ACCESS_KEY",
			"",
		),
		AWSS3PublicBaseURL: getOrDefault(
			"AWS_S3_PUBLIC_BASE_URL",
			"",
		),
		AWSS3ProfilePhotosPrefix: getOrDefault(
			"AWS_S3_PROFILE_PHOTOS_PREFIX",
			"profile-photos",
		),
		AWSS3ForcePathStyle: getBool(
			"AWS_S3_FORCE_PATH_STYLE",
			false,
		),
		MediaModerationProvider: normalizeMediaModerationProvider(
			getOrDefault("MEDIA_MODERATION_PROVIDER", "disabled"),
		),
		MediaModerationRequired: getBool(
			"MEDIA_MODERATION_REQUIRED",
			isProdLikeEnvironment(getOrDefault("ENVIRONMENT", "development")),
		),
		MediaModerationMinConfidence:    getPercentage("MEDIA_MODERATION_MIN_CONFIDENCE", 50),
		MediaModerationReviewConfidence: getPercentage("MEDIA_MODERATION_REVIEW_CONFIDENCE", 70),
		MediaModerationRejectConfidence: getPercentage("MEDIA_MODERATION_REJECT_CONFIDENCE", 90),
		MediaModerationRejectLabels: getCSVOrDefault("MEDIA_MODERATION_REJECT_LABELS", []string{
			"explicit nudity", "violence", "visually disturbing", "hate symbols", "drugs & tobacco",
		}),
		MediaModerationReviewLabels: getCSVOrDefault("MEDIA_MODERATION_REVIEW_LABELS", []string{
			"suggestive", "weapons", "alcohol", "gambling", "rude gestures",
		}),
		AWSRekognitionEndpoint:          strings.TrimRight(strings.TrimSpace(os.Getenv("AWS_REKOGNITION_ENDPOINT")), "/"),
		MockAuthEnabled:                 getBool("MOCK_AUTH_ENABLED", true),
		MockDataEnabled:                 getBool("MOCK_DATA_ENABLED", true),
		MockAuthUsername:                strings.ToLower(strings.TrimSpace(getOrDefault("MOCK_AUTH_USERNAME", "qa_user"))),
		MockAuthPassword:                getOrDefault("MOCK_AUTH_PASSWORD", "Password123!"),
		MockUserID:                      getOrDefault("MOCK_USER_ID", "mock-user-001"),
		MockAccessToken:                 getOrDefault("MOCK_ACCESS_TOKEN", "mock-access-token"),
		MockRefreshToken:                getOrDefault("MOCK_REFRESH_TOKEN", "mock-refresh-token"),
		MockFemaleUsersCount:            getInt("MOCK_FEMALE_USERS_COUNT", 100),
		MockMaleUsersCount:              getInt("MOCK_MALE_USERS_COUNT", 100),
		MockMinAgeYears:                 getInt("MOCK_MIN_AGE_YEARS", 18),
		MockMaxAgeYears:                 getInt("MOCK_MAX_AGE_YEARS", 45),
		FeatureEngagementUnlockMVP:      getBool("FEATURE_ENGAGEMENT_UNLOCK_MVP", true),
		FeatureDigitalGestures:          getBool("FEATURE_DIGITAL_GESTURES", true),
		FeatureMiniActivities:           getBool("FEATURE_MINI_ACTIVITIES", true),
		FeatureTrustBadges:              getBool("FEATURE_TRUST_BADGES", true),
		FeatureConversationRooms:        getBool("FEATURE_CONVERSATION_ROOMS", true),
		FeatureExperimentFramework:      getBool("FEATURE_EXPERIMENT_FRAMEWORK", false),
		FeatureExperimentMatchNudge:     getBool("FEATURE_EXPERIMENT_MATCH_NUDGE", true),
		ExperimentMatchNudgeRolloutPct:  getPercentage("EXPERIMENT_MATCH_NUDGE_ROLLOUT_PCT", 50),
		FeatureAssistedReviewAutomation: getBool("FEATURE_ASSISTED_REVIEW_AUTOMATION", false),
		AssistedReviewMinChars:          getInt("ASSISTED_REVIEW_MIN_CHARS", 120),
		AssistedReviewMinWordCount:      getInt("ASSISTED_REVIEW_MIN_WORD_COUNT", 20),
		DefaultUnlockPolicyVariant:      normalizeUnlockPolicyVariant(getOrDefault("DEFAULT_UNLOCK_POLICY_VARIANT", "require_quest_template")),
		RequireDurableEngagementStore: getBool(
			"REQUIRE_DURABLE_ENGAGEMENT_STORE",
			isProdLikeEnvironment(getOrDefault("ENVIRONMENT", "development")),
		),
		FanoutWorkerCount:              getInt("FANOUT_WORKER_COUNT", 8),
		FanoutQueueSize:                getInt("FANOUT_QUEUE_SIZE", 4096),
		NotificationWorkerCount:        getInt("NOTIFICATION_WORKER_COUNT", 2),
		NotificationBatchSize:          getInt("NOTIFICATION_BATCH_SIZE", 50),
		NotificationPollIntervalMS:     getInt("NOTIFICATION_POLL_INTERVAL_MS", 500),
		NotificationMaxAttempts:        getInt("NOTIFICATION_MAX_ATTEMPTS", 5),
		NotificationPushProvider:       normalizePushProvider(getOrDefault("NOTIFICATION_PUSH_PROVIDER", "disabled")),
		NotificationPushWebhookURL:     strings.TrimSpace(os.Getenv("NOTIFICATION_PUSH_WEBHOOK_URL")),
		NotificationPushWebhookToken:   strings.TrimSpace(os.Getenv("NOTIFICATION_PUSH_WEBHOOK_TOKEN")),
		NotificationFCMProjectID:       strings.TrimSpace(os.Getenv("NOTIFICATION_FCM_PROJECT_ID")),
		NotificationFCMCredentialsFile: strings.TrimSpace(getOrDefault("NOTIFICATION_FCM_CREDENTIALS_FILE", os.Getenv("GOOGLE_APPLICATION_CREDENTIALS"))),
		NotificationFCMTokenURL:        strings.TrimSpace(getOrDefault("NOTIFICATION_FCM_TOKEN_URL", "https://oauth2.googleapis.com/token")),
		NotificationFCMEndpoint:        strings.TrimSpace(getOrDefault("NOTIFICATION_FCM_ENDPOINT", "https://fcm.googleapis.com")),
		NotificationAPNSTeamID:         strings.TrimSpace(os.Getenv("NOTIFICATION_APNS_TEAM_ID")),
		NotificationAPNSKeyID:          strings.TrimSpace(os.Getenv("NOTIFICATION_APNS_KEY_ID")),
		NotificationAPNSBundleID:       strings.TrimSpace(os.Getenv("NOTIFICATION_APNS_BUNDLE_ID")),
		NotificationAPNSPrivateKeyFile: strings.TrimSpace(os.Getenv("NOTIFICATION_APNS_PRIVATE_KEY_FILE")),
		NotificationAPNSUseSandbox:     getBool("NOTIFICATION_APNS_USE_SANDBOX", false),
		NotificationAPNSEndpoint:       strings.TrimSpace(os.Getenv("NOTIFICATION_APNS_ENDPOINT")),
		NotificationSLOMaxQueueDepth:   getInt("NOTIFICATION_SLO_MAX_QUEUE_DEPTH", 1000),
		NotificationSLOMaxOldestAgeSec: getInt("NOTIFICATION_SLO_MAX_OLDEST_AGE_SEC", 30),
		NotificationSLOMinSuccessPct:   getPercentage("NOTIFICATION_SLO_MIN_SUCCESS_PCT", 99),
		SOSDeliveryProvider:            normalizeSOSDeliveryProvider(getOrDefault("SOS_DELIVERY_PROVIDER", "disabled")),
		SOSDeliveryWebhookURL:          strings.TrimSpace(os.Getenv("SOS_DELIVERY_WEBHOOK_URL")),
		SOSDeliveryWebhookToken:        strings.TrimSpace(os.Getenv("SOS_DELIVERY_WEBHOOK_TOKEN")),
		SOSDeliveryPollIntervalMS:      getInt("SOS_DELIVERY_POLL_INTERVAL_MS", 500),
		SOSDeliveryMaxAttempts:         getInt("SOS_DELIVERY_MAX_ATTEMPTS", 8),
		SOSDeliveryRequired: getBool("SOS_DELIVERY_REQUIRED",
			isProdLikeEnvironment(getOrDefault("ENVIRONMENT", "development"))),
		MasterDataCacheTTLSeconds:        getInt("MASTER_DATA_CACHE_TTL_SECONDS", 300),
		PaymentsProvider:                 normalizePaymentsProvider(getOrDefault("PAYMENTS_PROVIDER", defaultPaymentsProvider(getOrDefault("ENVIRONMENT", "development")))),
		PaymentsPublicBaseURL:            strings.TrimRight(getOrDefault("PAYMENTS_PUBLIC_BASE_URL", defaultPaymentsPublicBaseURL(getOrDefault("ENVIRONMENT", "development"))), "/"),
		PaymentsCurrency:                 strings.ToUpper(getOrDefault("PAYMENTS_CURRENCY", "INR")),
		PaymentsSandboxWebhookSecret:     getOrDefault("PAYMENTS_SANDBOX_WEBHOOK_SECRET", "whsec_sandbox_local_only"),
		StripeSecretKey:                  getOrDefault("STRIPE_SECRET_KEY", ""),
		StripeWebhookSecret:              getOrDefault("STRIPE_WEBHOOK_SECRET", ""),
		StripeAPIBaseURL:                 getOrDefault("STRIPE_API_BASE_URL", "https://api.stripe.com"),
		BillingPastDueGraceDays:          getInt("BILLING_PAST_DUE_GRACE_DAYS", 7),
		BillingRenewalSweepSeconds:       getInt("BILLING_RENEWAL_SWEEP_SECONDS", 300),
		BillingLocalActivationEnabled:    getBool("BILLING_LOCAL_ACTIVATION_ENABLED", false),
		ReleaseExcludedFlags:             releaseExcludedFlags(getOrDefault("ENVIRONMENT", "development")),
		BillingEnforceDailyLimits:        getBool("BILLING_ENFORCE_DAILY_LIMITS", true),
		CallTransportProvider:            normalizeCallTransportProvider(getOrDefault("CALL_TRANSPORT_PROVIDER", defaultCallTransportProvider(getOrDefault("ENVIRONMENT", "development")))),
		CallRoomBaseURL:                  strings.TrimRight(getOrDefault("CALL_ROOM_BASE_URL", defaultCallRoomBaseURL(getOrDefault("ENVIRONMENT", "development"))), "/"),
		CallJWTIssuer:                    strings.TrimSpace(os.Getenv("CALL_JWT_ISSUER")),
		CallJWTAudience:                  strings.TrimSpace(os.Getenv("CALL_JWT_AUDIENCE")),
		CallJWTSecret:                    strings.TrimSpace(os.Getenv("CALL_JWT_SECRET")),
		CallTokenTTLSeconds:              getInt("CALL_TOKEN_TTL_SECONDS", 300),
		IdentityVerificationProvider:     normalizeWebhookProvider(getOrDefault("IDENTITY_VERIFICATION_PROVIDER", "disabled")),
		IdentityVerificationRequired:     getBool("IDENTITY_VERIFICATION_REQUIRED", isProdLikeEnvironment(getOrDefault("ENVIRONMENT", "development"))),
		IdentityVerificationWebhookURL:   strings.TrimSpace(os.Getenv("IDENTITY_VERIFICATION_WEBHOOK_URL")),
		IdentityVerificationWebhookToken: strings.TrimSpace(os.Getenv("IDENTITY_VERIFICATION_WEBHOOK_TOKEN")),
		IdentityVerificationActorID:      strings.TrimSpace(os.Getenv("IDENTITY_VERIFICATION_ACTOR_ID")),
		VoiceModerationProvider:          normalizeWebhookProvider(getOrDefault("VOICE_MODERATION_PROVIDER", "disabled")),
		VoiceModerationRequired:          getBool("VOICE_MODERATION_REQUIRED", isProdLikeEnvironment(getOrDefault("ENVIRONMENT", "development"))),
		VoiceModerationWebhookURL:        strings.TrimSpace(os.Getenv("VOICE_MODERATION_WEBHOOK_URL")),
		VoiceModerationWebhookToken:      strings.TrimSpace(os.Getenv("VOICE_MODERATION_WEBHOOK_TOKEN")),
		PrivateMediaSigningKey:           getOrDefault("PRIVATE_MEDIA_SIGNING_KEY", defaultPrivateMediaSigningKey(getOrDefault("ENVIRONMENT", "development"))),
		PrivateMediaTokenTTLSeconds:      getInt("PRIVATE_MEDIA_TOKEN_TTL_SECONDS", 120),
	}
	cfg.MobileBFFUpstreamURL = getOrDefault("MOBILE_BFF_UPSTREAM_URL", "http://localhost"+cfg.MobileBFFAddr)
	cfg.FileStorageBackend = normalizeFileStorageBackend(cfg.FileStorageBackend, cfg.UseAWSS3Storage)
	cfg.UseAWSS3Storage = cfg.FileStorageBackend == "aws_s3"
	cfg.AWSS3ProfilePhotosPrefix = normalizeStoragePrefix(cfg.AWSS3ProfilePhotosPrefix)

	if cfg.UseLocalDB && strings.TrimSpace(cfg.DatabaseURL) == "" {
		return Config{}, fmt.Errorf("LOCAL_DATABASE_URL or DATABASE_URL is required when USE_LOCAL_DB=true")
	}
	if !cfg.UseLocalDB && cfg.SupabaseURL == "" {
		return Config{}, fmt.Errorf("SUPABASE_URL is required when USE_LOCAL_DB=false")
	}
	if !cfg.UseLocalDB && cfg.SupabaseAnonKey == "" && cfg.SupabaseServiceRole == "" {
		return Config{}, fmt.Errorf("SUPABASE_ANON_KEY or SUPABASE_SERVICE_ROLE is required")
	}
	if cfg.UseAWSS3Storage && strings.TrimSpace(cfg.AWSS3Bucket) == "" {
		return Config{}, fmt.Errorf("AWS_S3_BUCKET is required when aws_s3 storage backend is enabled")
	}
	mediaStorage, err := LoadMediaStorage(cfg.Environment)
	if err != nil {
		return Config{}, err
	}
	cfg.MediaStorage = mediaStorage
	cfg.FileStorageBackend = mediaStorage.Backend
	cfg.UseAWSS3Storage = mediaStorage.Backend == StorageBackendAWSS3
	if cfg.MediaModerationRequired && cfg.MediaModerationProvider == "disabled" {
		return Config{}, fmt.Errorf("MEDIA_MODERATION_PROVIDER must be configured when moderation is required")
	}
	if cfg.MediaModerationReviewConfidence > cfg.MediaModerationRejectConfidence {
		return Config{}, fmt.Errorf("MEDIA_MODERATION_REVIEW_CONFIDENCE cannot exceed MEDIA_MODERATION_REJECT_CONFIDENCE")
	}
	if cfg.IdempotencyTTLSeconds <= 0 || cfg.IdempotencyLeaseSeconds <= 0 ||
		cfg.IdempotencyPollMilliseconds <= 0 || cfg.IdempotencyMaxResponseBytes <= 0 {
		return Config{}, fmt.Errorf("idempotency TTL, lease, poll interval, and response limit must be positive")
	}
	if cfg.NotificationPushProvider == "webhook" && cfg.NotificationPushWebhookURL == "" {
		return Config{}, fmt.Errorf("NOTIFICATION_PUSH_WEBHOOK_URL is required when webhook push delivery is enabled")
	}
	if cfg.SOSDeliveryProvider == "webhook" && cfg.SOSDeliveryWebhookURL == "" {
		return Config{}, fmt.Errorf("SOS_DELIVERY_WEBHOOK_URL is required when emergency delivery is enabled")
	}
	if cfg.SOSDeliveryRequired && cfg.SOSDeliveryProvider == "disabled" {
		return Config{}, fmt.Errorf("SOS_DELIVERY_PROVIDER must be configured when SOS_DELIVERY_REQUIRED is true (the default in production-like environments)")
	}
	if cfg.CallTransportProvider == "jitsi_jwt" {
		if cfg.CallRoomBaseURL == "" || cfg.CallJWTIssuer == "" || cfg.CallJWTAudience == "" || len(cfg.CallJWTSecret) < 32 {
			return Config{}, fmt.Errorf("jitsi_jwt calls require CALL_ROOM_BASE_URL, issuer, audience, and a 32+ character secret")
		}
		if isProdLikeEnvironment(cfg.Environment) && !isHTTPSProviderURL(cfg.CallRoomBaseURL) {
			return Config{}, fmt.Errorf("production call transport requires an HTTPS room URL")
		}
	}
	if isProdLikeEnvironment(cfg.Environment) && cfg.CallTransportProvider == "public_jitsi" {
		return Config{}, fmt.Errorf("public_jitsi call transport is forbidden in production")
	}
	if cfg.IdentityVerificationProvider == "webhook" && (cfg.IdentityVerificationWebhookURL == "" || cfg.IdentityVerificationActorID == "") {
		return Config{}, fmt.Errorf("webhook verification requires IDENTITY_VERIFICATION_WEBHOOK_URL and provider actor id")
	}
	if cfg.IdentityVerificationProvider == "webhook" {
		if _, err := uuid.Parse(cfg.IdentityVerificationActorID); err != nil {
			return Config{}, fmt.Errorf("IDENTITY_VERIFICATION_ACTOR_ID must be a UUID")
		}
		if isProdLikeEnvironment(cfg.Environment) && !isHTTPSProviderURL(cfg.IdentityVerificationWebhookURL) {
			return Config{}, fmt.Errorf("production identity verification requires an HTTPS webhook URL")
		}
	}
	if cfg.IdentityVerificationRequired && cfg.IdentityVerificationProvider == "disabled" {
		return Config{}, fmt.Errorf("identity verification provider is required")
	}
	if cfg.VoiceModerationProvider == "webhook" && cfg.VoiceModerationWebhookURL == "" {
		return Config{}, fmt.Errorf("VOICE_MODERATION_WEBHOOK_URL is required for webhook moderation")
	}
	if cfg.VoiceModerationProvider == "webhook" && isProdLikeEnvironment(cfg.Environment) && !isHTTPSProviderURL(cfg.VoiceModerationWebhookURL) {
		return Config{}, fmt.Errorf("production voice moderation requires an HTTPS webhook URL")
	}
	if cfg.VoiceModerationRequired && cfg.VoiceModerationProvider == "disabled" {
		return Config{}, fmt.Errorf("voice moderation provider is required")
	}
	if cfg.VoiceModerationRequired && len(cfg.PrivateMediaSigningKey) < 32 {
		return Config{}, fmt.Errorf("PRIVATE_MEDIA_SIGNING_KEY must be at least 32 characters when voice moderation is required")
	}
	if cfg.NotificationPushProvider == "direct" {
		fcmConfigured := cfg.NotificationFCMProjectID != "" && cfg.NotificationFCMCredentialsFile != ""
		apnsConfigured := cfg.NotificationAPNSTeamID != "" && cfg.NotificationAPNSKeyID != "" && cfg.NotificationAPNSBundleID != "" && cfg.NotificationAPNSPrivateKeyFile != ""
		if !fcmConfigured && !apnsConfigured {
			return Config{}, fmt.Errorf("direct push delivery requires complete FCM or APNs provider configuration")
		}
		if fcmConfigured {
			if _, err := os.Stat(cfg.NotificationFCMCredentialsFile); err != nil {
				return Config{}, fmt.Errorf("FCM credentials file is unavailable: %w", err)
			}
		}
		if apnsConfigured {
			if _, err := os.Stat(cfg.NotificationAPNSPrivateKeyFile); err != nil {
				return Config{}, fmt.Errorf("APNs private key file is unavailable: %w", err)
			}
		}
	}

	if err := validatePaymentsConfig(cfg); err != nil {
		return Config{}, err
	}

	return cfg, nil
}

func defaultCallRoomBaseURL(environment string) string {
	if isProdLikeEnvironment(environment) {
		return ""
	}
	return "https://meet.jit.si"
}

func defaultCallTransportProvider(environment string) string {
	if isProdLikeEnvironment(environment) {
		return "disabled"
	}
	return "public_jitsi"
}

func defaultPrivateMediaSigningKey(environment string) string {
	if isProdLikeEnvironment(environment) {
		return ""
	}
	return "local-private-media-signing-key-change-me"
}

func isHTTPSProviderURL(raw string) bool {
	parsed, err := url.Parse(strings.TrimSpace(raw))
	return err == nil && strings.EqualFold(parsed.Scheme, "https") && strings.TrimSpace(parsed.Host) != ""
}

// defaultPaymentsProvider keeps local development runnable without any
// provider credentials while refusing to guess in production.
func defaultPaymentsProvider(environment string) string {
	if isProdLikeEnvironment(environment) {
		return "disabled"
	}
	return "sandbox"
}

// defaultPaymentsPublicBaseURL is the API origin as the device sees it. The
// Android emulator reaches the host gateway through 10.0.2.2; production must
// set PAYMENTS_PUBLIC_BASE_URL explicitly.
func defaultPaymentsPublicBaseURL(environment string) string {
	if isProdLikeEnvironment(environment) {
		return ""
	}
	return "http://10.0.2.2:18080/v1"
}

func normalizePaymentsProvider(value string) string {
	switch strings.ToLower(strings.TrimSpace(value)) {
	case "stripe":
		return "stripe"
	case "sandbox":
		return "sandbox"
	case "", "disabled", "none", "off":
		return "disabled"
	default:
		return strings.ToLower(strings.TrimSpace(value))
	}
}

// PaymentsEnabled reports whether card checkout is available at all.
func (c Config) PaymentsEnabled() bool {
	return c.PaymentsProvider == "stripe" || c.PaymentsProvider == "sandbox"
}

func validatePaymentsConfig(cfg Config) error {
	switch cfg.PaymentsProvider {
	case "disabled":
		return nil
	case "sandbox":
		if isProdLikeEnvironment(cfg.Environment) {
			return fmt.Errorf("PAYMENTS_PROVIDER=sandbox is not permitted in %s; it never charges a card", cfg.Environment)
		}
		if cfg.PaymentsPublicBaseURL == "" {
			return fmt.Errorf("PAYMENTS_PUBLIC_BASE_URL is required for the sandbox checkout page")
		}
		return nil
	case "stripe":
		if cfg.StripeSecretKey == "" || cfg.StripeWebhookSecret == "" {
			return fmt.Errorf("PAYMENTS_PROVIDER=stripe requires STRIPE_SECRET_KEY and STRIPE_WEBHOOK_SECRET")
		}
		if cfg.PaymentsPublicBaseURL == "" {
			return fmt.Errorf("PAYMENTS_PROVIDER=stripe requires PAYMENTS_PUBLIC_BASE_URL for checkout return pages")
		}
		if isProdLikeEnvironment(cfg.Environment) && strings.HasPrefix(cfg.StripeSecretKey, "sk_test_") {
			return fmt.Errorf("a Stripe test key cannot be used in %s", cfg.Environment)
		}
		return nil
	default:
		return fmt.Errorf("unsupported PAYMENTS_PROVIDER %q (stripe, sandbox or disabled)", cfg.PaymentsProvider)
	}
}

func getOrDefault(key, fallback string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return fallback
}

func getBool(key string, fallback bool) bool {
	value := os.Getenv(key)
	if value == "" {
		return fallback
	}
	parsed, err := strconv.ParseBool(value)
	if err != nil {
		return fallback
	}
	return parsed
}

func getInt(key string, fallback int) int {
	value := strings.TrimSpace(os.Getenv(key))
	if value == "" {
		return fallback
	}
	parsed, err := strconv.Atoi(value)
	if err != nil || parsed <= 0 {
		return fallback
	}
	return parsed
}

func getPercentage(key string, fallback int) int {
	value := strings.TrimSpace(os.Getenv(key))
	if value == "" {
		return fallback
	}
	parsed, err := strconv.Atoi(value)
	if err != nil {
		return fallback
	}
	if parsed < 0 {
		return 0
	}
	if parsed > 100 {
		return 100
	}
	return parsed
}

func normalizePrefix(v string) string {
	trimmed := strings.TrimSpace(v)
	if trimmed == "" {
		return "/v1"
	}
	if !strings.HasPrefix(trimmed, "/") {
		trimmed = "/" + trimmed
	}
	return strings.TrimRight(trimmed, "/")
}

func normalizeFileStorageBackend(value string, useAWSS3Storage bool) string {
	if useAWSS3Storage {
		return "aws_s3"
	}

	switch strings.ToLower(strings.TrimSpace(value)) {
	case "", "local", "local_fs", "filesystem":
		return "local_fs"
	case "aws", "aws_s3", "s3":
		return "aws_s3"
	default:
		return "local_fs"
	}
}

func normalizeStoragePrefix(value string) string {
	normalized := strings.Trim(strings.ReplaceAll(strings.TrimSpace(value), "\\", "/"), "/")
	if normalized == "." {
		return ""
	}
	return normalized
}

func getCSVOrDefault(key string, fallback []string) []string {
	raw := strings.TrimSpace(os.Getenv(key))
	if raw == "" {
		out := make([]string, len(fallback))
		copy(out, fallback)
		return out
	}
	parts := strings.Split(raw, ",")
	out := make([]string, 0, len(parts))
	seen := make(map[string]struct{}, len(parts))
	for _, item := range parts {
		token := strings.ToLower(strings.TrimSpace(item))
		if token == "" {
			continue
		}
		if _, ok := seen[token]; ok {
			continue
		}
		seen[token] = struct{}{}
		out = append(out, token)
	}
	if len(out) == 0 {
		copyFallback := make([]string, len(fallback))
		copy(copyFallback, fallback)
		return copyFallback
	}
	return out
}

// FirstReleaseExcludedFlags maps the release contract's excluded capabilities
// to runtime flags: real_money_billing and coin_purchases (billing), digital
// gifts, the quest unlock workflow, live calls, voice icebreakers, the identity
// verified badge and XP progression. Production push is excluded separately by
// its provider defaulting to disabled.
var FirstReleaseExcludedFlags = []string{
	"intentional_dating_enabled",
	"billing_enabled",
	"gifts_enabled",
	"quest_workflow_v2_enabled",
	"calls_enabled",
	"voice_icebreakers_enabled",
	"identity_verification_enabled",
	"level_progression_enabled",
}

func releaseExcludedFlags(environment string) []string {
	raw, set := os.LookupEnv("RELEASE_EXCLUDED_FLAGS")
	if !set {
		if isProdLikeEnvironment(environment) {
			return append([]string(nil), FirstReleaseExcludedFlags...)
		}
		return nil
	}
	if strings.EqualFold(strings.TrimSpace(raw), "none") {
		return nil
	}
	var out []string
	for _, key := range strings.Split(raw, ",") {
		if key = strings.TrimSpace(key); key != "" {
			out = append(out, key)
		}
	}
	return out
}

// IsReleaseExcluded reports whether a runtime flag is held off by the release
// contract in this environment.
func (c Config) IsReleaseExcluded(flag string) bool {
	flag = strings.TrimSpace(flag)
	for _, key := range c.ReleaseExcludedFlags {
		if key == flag {
			return true
		}
	}
	return false
}

// IsLocalEnvironment is true only for explicitly named developer and test
// environments. An unset environment defaults to "development" at load time;
// an unrecognised name is not local, so shortcuts gated on this fail closed.
func IsLocalEnvironment(value string) bool {
	switch strings.ToLower(strings.TrimSpace(value)) {
	case "development", "dev", "local", "test", "testing":
		return true
	default:
		return false
	}
}

func isProdLikeEnvironment(value string) bool {
	env := strings.ToLower(strings.TrimSpace(value))
	switch env {
	case "prod", "production", "stage", "staging":
		return true
	default:
		return false
	}
}

func normalizePushProvider(value string) string {
	switch strings.ToLower(strings.TrimSpace(value)) {
	case "direct", "webhook":
		return strings.ToLower(strings.TrimSpace(value))
	default:
		return "disabled"
	}
}

func normalizeSOSDeliveryProvider(value string) string {
	if strings.EqualFold(strings.TrimSpace(value), "webhook") {
		return "webhook"
	}
	return "disabled"
}

func normalizeWebhookProvider(value string) string {
	if strings.EqualFold(strings.TrimSpace(value), "webhook") {
		return "webhook"
	}
	return "disabled"
}

func normalizeCallTransportProvider(value string) string {
	switch strings.ToLower(strings.TrimSpace(value)) {
	case "public_jitsi", "jitsi_jwt":
		return strings.ToLower(strings.TrimSpace(value))
	default:
		return "disabled"
	}
}

func normalizeMediaModerationProvider(value string) string {
	switch strings.ToLower(strings.TrimSpace(value)) {
	case "aws_rekognition":
		return "aws_rekognition"
	default:
		return "disabled"
	}
}

func normalizeUnlockPolicyVariant(value string) string {
	switch strings.ToLower(strings.TrimSpace(value)) {
	case "allow_without_template", "require_quest_template":
		return strings.ToLower(strings.TrimSpace(value))
	default:
		return "require_quest_template"
	}
}

func deriveSupabaseURLFromDBHost(host string) string {
	host = strings.TrimSpace(strings.ToLower(host))
	if host == "" {
		return ""
	}
	const prefix = "db."
	const suffix = ".supabase.co"
	if !strings.HasPrefix(host, prefix) || !strings.HasSuffix(host, suffix) {
		return ""
	}
	projectRef := strings.TrimSuffix(strings.TrimPrefix(host, prefix), suffix)
	if projectRef == "" {
		return ""
	}
	return "https://" + projectRef + ".supabase.co"
}

func buildPostgresURL(host string, port int, database, user, password, sslMode string) string {
	host = strings.TrimSpace(host)
	if host == "" {
		return ""
	}
	if port <= 0 {
		port = 5432
	}
	database = strings.TrimSpace(database)
	if database == "" {
		database = "postgres"
	}
	user = strings.TrimSpace(user)
	if user == "" {
		user = "postgres"
	}
	sslMode = strings.TrimSpace(sslMode)
	if sslMode == "" {
		sslMode = "require"
	}

	credentials := url.QueryEscape(user)
	if password != "" {
		credentials += ":" + url.QueryEscape(password)
	}

	return fmt.Sprintf(
		"postgresql://%s@%s:%d/%s?sslmode=%s",
		credentials,
		host,
		port,
		url.PathEscape(database),
		url.QueryEscape(sslMode),
	)
}

func (c Config) APIGatewayReadHeaderTimeout() time.Duration {
	return time.Duration(c.APIGatewayReadHeaderTimeoutSec) * time.Second
}

func (c Config) MobileBFFReadHeaderTimeout() time.Duration {
	return time.Duration(c.MobileBFFReadHeaderTimeoutSec) * time.Second
}

func (c Config) ShutdownTimeout() time.Duration {
	return time.Duration(c.ShutdownTimeoutSec) * time.Second
}

func (c Config) BFFRequestTimeout() time.Duration {
	return time.Duration(c.BFFRequestTimeoutSec) * time.Second
}

func (c Config) BFFFastReadTimeout() time.Duration {
	return time.Duration(c.BFFFastReadTimeoutMS) * time.Millisecond
}

func (c Config) BFFNormalReadTimeout() time.Duration {
	return time.Duration(c.BFFNormalReadTimeoutMS) * time.Millisecond
}

func (c Config) BFFWriteTimeout() time.Duration {
	return time.Duration(c.BFFWriteTimeoutMS) * time.Millisecond
}

func (c Config) GatewayReadyProbeTimeout() time.Duration {
	return time.Duration(c.GatewayReadyProbeTimeoutSec) * time.Second
}

func (c Config) GatewayRateLimitWindow() time.Duration {
	return time.Duration(c.GatewayRateLimitWindowSec) * time.Second
}

func (c Config) IdempotencyTTL() time.Duration {
	return time.Duration(c.IdempotencyTTLSeconds) * time.Second
}

func (c Config) IdempotencyLease() time.Duration {
	return time.Duration(c.IdempotencyLeaseSeconds) * time.Second
}

func (c Config) IdempotencyPollInterval() time.Duration {
	return time.Duration(c.IdempotencyPollMilliseconds) * time.Millisecond
}

func (c Config) AuthHTTPTimeout() time.Duration {
	return time.Duration(c.AuthHTTPTimeoutSec) * time.Second
}

func (c Config) SupabaseHTTPTimeout() time.Duration {
	return time.Duration(c.SupabaseHTTPTimeoutSec) * time.Second
}

func (c Config) ChatRealtimeHeartbeat() time.Duration {
	return time.Duration(c.ChatRealtimeHeartbeatSec) * time.Second
}

func (c Config) MasterDataCacheTTL() time.Duration {
	return time.Duration(c.MasterDataCacheTTLSeconds) * time.Second
}
