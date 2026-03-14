package config

import (
	"fmt"
	"net/url"
	"os"
	"strconv"
	"strings"
	"time"
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

	AuthHTTPTimeoutSec       int
	SupabaseHTTPTimeoutSec   int
	ChatWorkerCount          int
	ChatWorkerQueueSize      int
	ChatRealtimeSchema       string
	ChatRealtimeTable        string
	ChatRealtimeMaxEvents    int
	ChatRealtimeLogLevel     string
	ChatRealtimeHeartbeatSec int

	SupabaseURL            string
	SupabaseReadReplicaURL string
	SupabaseAnonKey        string
	SupabaseServiceRole    string
	DatabaseURL            string
	DatabaseHost           string
	DatabasePort           int
	DatabaseName           string
	DatabaseUser           string
	DatabasePassword       string
	DatabaseSSLMode        string

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
	MediaUploadsDir          string
	MediaPublicBaseURL       string

	MockOTPEnabled       bool
	MockOTPCode          string
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
	MasterDataCacheTTLSeconds       int
}

func Load() (Config, error) {
	databaseHost := getOrDefault("DATABASE_HOST", getOrDefault("SUPABASE_DB_HOST", ""))
	databasePort := getInt("DATABASE_PORT", getInt("SUPABASE_DB_PORT", 5432))
	databaseName := getOrDefault("DATABASE_NAME", getOrDefault("SUPABASE_DB_NAME", "postgres"))
	databaseUser := getOrDefault("DATABASE_USER", getOrDefault("SUPABASE_DB_USER", "postgres"))
	databasePassword := getOrDefault("DATABASE_PASSWORD", getOrDefault("SUPABASE_DB_PASSWORD", ""))
	databaseSSLMode := getOrDefault("DATABASE_SSLMODE", getOrDefault("SUPABASE_DB_SSLMODE", "require"))

	databaseURL := getOrDefault("DATABASE_URL", getOrDefault("SUPABASE_DATABASE_URL", ""))
	if databaseURL == "" {
		databaseURL = buildPostgresURL(
			databaseHost,
			databasePort,
			databaseName,
			databaseUser,
			databasePassword,
			databaseSSLMode,
		)
	}

	supabaseURL := getOrDefault("SUPABASE_URL", deriveSupabaseURLFromDBHost(databaseHost))

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
		SupabaseAnonKey:                  os.Getenv("SUPABASE_ANON_KEY"),
		SupabaseServiceRole:              os.Getenv("SUPABASE_SERVICE_ROLE"),
		DatabaseURL:                      databaseURL,
		DatabaseHost:                     databaseHost,
		DatabasePort:                     databasePort,
		DatabaseName:                     databaseName,
		DatabaseUser:                     databaseUser,
		DatabasePassword:                 databasePassword,
		DatabaseSSLMode:                  databaseSSLMode,
		UserSchema:                       getOrDefault("SUPABASE_USER_SCHEMA", "public"),
		UsersTable:                       getOrDefault("SUPABASE_USERS_TABLE", "users"),
		PreferencesTable:                 getOrDefault("SUPABASE_PREFERENCES_TABLE", "preferences"),
		PhotosTable:                      getOrDefault("SUPABASE_PHOTOS_TABLE", "photos"),
		MatchingSchema:                   getOrDefault("SUPABASE_MATCHING_SCHEMA", "public"),
		SwipesTable:                      getOrDefault("SUPABASE_SWIPES_TABLE", "swipes"),
		MatchesTable:                     getOrDefault("SUPABASE_MATCHES_TABLE", "matches"),
		MessagesTable:                    getOrDefault("SUPABASE_MESSAGES_TABLE", "messages"),
		EngagementSchema:                 getOrDefault("SUPABASE_ENGAGEMENT_SCHEMA", "public"),
		UnlockStatesTable:                getOrDefault("SUPABASE_UNLOCK_STATES_TABLE", "match_unlock_states"),
		QuestTemplatesTable:              getOrDefault("SUPABASE_QUEST_TEMPLATES_TABLE", "match_quest_templates"),
		QuestWorkflowsTable:              getOrDefault("SUPABASE_QUEST_WORKFLOWS_TABLE", "match_quest_workflows"),
		GesturesTable:                    getOrDefault("SUPABASE_GESTURES_TABLE", "match_gestures"),
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
		MediaUploadsDir: getOrDefault(
			"MEDIA_UPLOADS_DIR",
			".run/uploads/profile_photos",
		),
		MediaPublicBaseURL: getOrDefault(
			"MEDIA_PUBLIC_BASE_URL",
			"auto",
		),
		MockOTPEnabled:                  getBool("MOCK_OTP_ENABLED", true),
		MockOTPCode:                     getOrDefault("MOCK_OTP_CODE", "123456"),
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
		FanoutWorkerCount:         getInt("FANOUT_WORKER_COUNT", 8),
		FanoutQueueSize:           getInt("FANOUT_QUEUE_SIZE", 4096),
		MasterDataCacheTTLSeconds: getInt("MASTER_DATA_CACHE_TTL_SECONDS", 300),
	}
	cfg.MobileBFFUpstreamURL = getOrDefault("MOBILE_BFF_UPSTREAM_URL", "http://localhost"+cfg.MobileBFFAddr)

	if cfg.SupabaseURL == "" {
		return Config{}, fmt.Errorf("SUPABASE_URL is required (or provide SUPABASE_DB_HOST / DATABASE_HOST)")
	}
	if cfg.SupabaseAnonKey == "" && cfg.SupabaseServiceRole == "" {
		return Config{}, fmt.Errorf("SUPABASE_ANON_KEY or SUPABASE_SERVICE_ROLE is required")
	}

	return cfg, nil
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

func isProdLikeEnvironment(value string) bool {
	env := strings.ToLower(strings.TrimSpace(value))
	switch env {
	case "prod", "production", "stage", "staging":
		return true
	default:
		return false
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

func (c Config) GatewayReadyProbeTimeout() time.Duration {
	return time.Duration(c.GatewayReadyProbeTimeoutSec) * time.Second
}

func (c Config) GatewayRateLimitWindow() time.Duration {
	return time.Duration(c.GatewayRateLimitWindowSec) * time.Second
}

func (c Config) IdempotencyTTL() time.Duration {
	return time.Duration(c.IdempotencyTTLSeconds) * time.Second
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
