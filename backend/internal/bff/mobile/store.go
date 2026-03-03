package mobile

import (
	"context"
	"crypto/sha1"
	"encoding/binary"
	"errors"
	"fmt"
	"sort"
	"strings"
	"sync"
	"time"
	"unicode"

	matchingdomain "github.com/verified-dating/backend/internal/modules/matching/domain"
	"github.com/verified-dating/backend/internal/platform/config"
)

type profileDraft struct {
	UserID             string         `json:"user_id"`
	PhoneNumber        string         `json:"phone_number"`
	Name               string         `json:"name"`
	DateOfBirth        string         `json:"date_of_birth,omitempty"`
	Gender             string         `json:"gender"`
	Photos             []profilePhoto `json:"photos"`
	Bio                string         `json:"bio"`
	HeightCm           *int           `json:"height_cm,omitempty"`
	Education          *string        `json:"education,omitempty"`
	Profession         *string        `json:"profession,omitempty"`
	IncomeRange        *string        `json:"income_range,omitempty"`
	SeekingGenders     []string       `json:"seeking_genders"`
	MinAgeYears        int            `json:"min_age_years"`
	MaxAgeYears        int            `json:"max_age_years"`
	MaxDistanceKm      int            `json:"max_distance_km"`
	EducationFilter    []string       `json:"education_filter"`
	SeriousOnly        bool           `json:"serious_only"`
	VerifiedOnly       bool           `json:"verified_only"`
	Country            *string        `json:"country,omitempty"`
	RegionState        *string        `json:"state,omitempty"`
	City               *string        `json:"city,omitempty"`
	InstagramHandle    *string        `json:"instagram_handle,omitempty"`
	Hobbies            []string       `json:"hobbies"`
	FavoriteBooks      []string       `json:"favorite_books"`
	FavoriteNovels     []string       `json:"favorite_novels"`
	FavoriteSongs      []string       `json:"favorite_songs"`
	ExtraCurriculars   []string       `json:"extra_curriculars"`
	AdditionalInfo     *string        `json:"additional_info,omitempty"`
	IntentTags         []string       `json:"intent_tags"`
	LanguageTags       []string       `json:"language_tags"`
	PetPreference      *string        `json:"pet_preference,omitempty"`
	DietPreference     *string        `json:"diet_preference,omitempty"`
	WorkoutFrequency   *string        `json:"workout_frequency,omitempty"`
	DietType           *string        `json:"diet_type,omitempty"`
	SleepSchedule      *string        `json:"sleep_schedule,omitempty"`
	TravelStyle        *string        `json:"travel_style,omitempty"`
	PoliticalComfort   *string        `json:"political_comfort_range,omitempty"`
	DealBreakerTags    []string       `json:"deal_breaker_tags"`
	Drinking           string         `json:"drinking"`
	Smoking            string         `json:"smoking"`
	Religion           *string        `json:"religion,omitempty"`
	MotherTongue       *string        `json:"mother_tongue,omitempty"`
	RelationshipStatus *string        `json:"relationship_status,omitempty"`
	PersonalityType    *string        `json:"personality_type,omitempty"`
	PartyLover         *bool          `json:"party_lover,omitempty"`
	HookupOnly         bool           `json:"hookup_only"`
	ProfileCompletion  int            `json:"profile_completion"`
}

type friendConnection struct {
	UserID     string `json:"user_id"`
	FriendID   string `json:"friend_user_id"`
	Status     string `json:"status"`
	CreatedAt  string `json:"created_at"`
	UpdatedAt  string `json:"updated_at"`
	FriendName string `json:"friend_name"`
}

type friendActivity struct {
	ID          string `json:"id"`
	UserID      string `json:"user_id"`
	FriendID    string `json:"friend_user_id"`
	Type        string `json:"type"`
	Title       string `json:"title"`
	Description string `json:"description"`
	CreatedAt   string `json:"created_at"`
}

type profilePhoto struct {
	ID       string `json:"id"`
	PhotoURL string `json:"photo_url"`
	Ordering int    `json:"ordering"`
}

type userSettings struct {
	UserID            string `json:"user_id"`
	ShowAge           bool   `json:"show_age"`
	ShowExactDistance bool   `json:"show_exact_distance"`
	ShowOnlineStatus  bool   `json:"show_online_status"`
	NotifyNewMatch    bool   `json:"notify_new_match"`
	NotifyNewMessage  bool   `json:"notify_new_message"`
	NotifyLikes       bool   `json:"notify_likes"`
	Theme             string `json:"theme"`
	UpdatedAt         string `json:"updated_at"`
}

type emergencyContact struct {
	ID          string `json:"id"`
	UserID      string `json:"user_id"`
	Name        string `json:"name"`
	PhoneNumber string `json:"phone_number"`
	Ordering    int    `json:"ordering"`
	AddedAt     string `json:"added_at"`
}

type blockedUser struct {
	ID       string `json:"id"`
	Name     string `json:"name"`
	PhotoURL string `json:"photo_url,omitempty"`
}

type verificationState struct {
	UserID          string `json:"user_id,omitempty"`
	Status          string `json:"status,omitempty"`
	RejectionReason string `json:"rejection_reason,omitempty"`
	SubmittedAt     string `json:"submitted_at,omitempty"`
	ReviewedAt      string `json:"reviewed_at,omitempty"`
	ReviewedBy      string `json:"reviewed_by,omitempty"`
}

type activityEvent struct {
	ID        string         `json:"id"`
	UserID    string         `json:"user_id,omitempty"`
	Actor     string         `json:"actor,omitempty"`
	Action    string         `json:"action"`
	Status    string         `json:"status"`
	Resource  string         `json:"resource,omitempty"`
	Details   map[string]any `json:"details,omitempty"`
	CreatedAt string         `json:"created_at"`
}

type videoCallSession struct {
	ID            string `json:"id"`
	MatchID       string `json:"match_id"`
	InitiatorID   string `json:"initiator_id"`
	RecipientID   string `json:"recipient_id"`
	Status        string `json:"status"`
	RoomID        string `json:"room_id"`
	StartedAt     string `json:"started_at"`
	EndedAt       string `json:"ended_at,omitempty"`
	DurationSec   int    `json:"duration_sec"`
	EndedByUserID string `json:"ended_by_user_id,omitempty"`
}

type activitySessionSummary struct {
	SessionID             string   `json:"session_id"`
	MatchID               string   `json:"match_id"`
	Status                string   `json:"status"`
	TotalParticipants     int      `json:"total_participants"`
	ResponsesSubmitted    int      `json:"responses_submitted"`
	ParticipantsCompleted []string `json:"participants_completed"`
	ParticipantsPending   []string `json:"participants_pending"`
	Insight               string   `json:"insight"`
	GeneratedAt           string   `json:"generated_at"`
}

type activitySession struct {
	ID              string                 `json:"id"`
	MatchID         string                 `json:"match_id"`
	ActivityType    string                 `json:"activity_type"`
	Status          string                 `json:"status"`
	InitiatorUserID string                 `json:"initiator_user_id"`
	ParticipantIDs  []string               `json:"participant_user_ids"`
	ResponsesByUser map[string][]string    `json:"responses_by_user"`
	StartedAt       string                 `json:"started_at"`
	ExpiresAt       string                 `json:"expires_at"`
	CompletedAt     string                 `json:"completed_at,omitempty"`
	TimedOutAt      string                 `json:"timed_out_at,omitempty"`
	LastResponseAt  string                 `json:"last_response_at,omitempty"`
	Summary         activitySessionSummary `json:"summary,omitempty"`
	Metadata        map[string]any         `json:"metadata,omitempty"`
}

type dailyPrompt struct {
	ID           string `json:"id"`
	PromptDate   string `json:"prompt_date"`
	Domain       string `json:"domain"`
	PromptText   string `json:"prompt_text"`
	MinChars     int    `json:"min_chars"`
	MaxChars     int    `json:"max_chars"`
	ResponseMode string `json:"response_mode"`
}

type dailyPromptAnswer struct {
	UserID          string `json:"user_id"`
	PromptID        string `json:"prompt_id"`
	PromptDate      string `json:"prompt_date"`
	AnswerText      string `json:"answer_text"`
	AnsweredAt      string `json:"answered_at"`
	UpdatedAt       string `json:"updated_at"`
	EditWindowUntil string `json:"edit_window_until"`
	IsEdited        bool   `json:"is_edited"`
	Normalized      string `json:"-"`
}

type dailyPromptStreak struct {
	UserID           string `json:"user_id"`
	CurrentDays      int    `json:"current_days"`
	LongestDays      int    `json:"longest_days"`
	LastAnsweredDate string `json:"last_answered_date,omitempty"`
	NextMilestone    int    `json:"next_milestone,omitempty"`
	MilestoneReached int    `json:"milestone_reached,omitempty"`
	UpdatedAt        string `json:"updated_at,omitempty"`
}

type dailyPromptSpark struct {
	ParticipantsToday int      `json:"participants_today"`
	SimilarCount      int      `json:"similar_answer_count"`
	SimilarUserIDs    []string `json:"similar_user_ids"`
}

type dailyPromptResponder struct {
	UserID      string `json:"user_id"`
	DisplayName string `json:"display_name"`
	PhotoURL    string `json:"photo_url,omitempty"`
	AnsweredAt  string `json:"answered_at,omitempty"`
}

type dailyPromptRespondersPage struct {
	PromptID   string                 `json:"prompt_id"`
	PromptDate string                 `json:"prompt_date"`
	Responders []dailyPromptResponder `json:"responders"`
	Total      int                    `json:"total"`
	Limit      int                    `json:"limit"`
	Offset     int                    `json:"offset"`
	HasMore    bool                   `json:"has_more"`
	NextOffset int                    `json:"next_offset"`
}

type dailyPromptView struct {
	Prompt dailyPrompt        `json:"prompt"`
	Answer *dailyPromptAnswer `json:"answer,omitempty"`
	Streak dailyPromptStreak  `json:"streak"`
	Spark  dailyPromptSpark   `json:"spark"`
}

type matchNudge struct {
	ID                 string `json:"id"`
	MatchID            string `json:"match_id"`
	UserID             string `json:"user_id"`
	CounterpartyUserID string `json:"counterparty_user_id"`
	NudgeType          string `json:"nudge_type"`
	SentAt             string `json:"sent_at"`
	ClickedAt          string `json:"clicked_at,omitempty"`
}

type conversationResumed struct {
	ID             string `json:"id"`
	MatchID        string `json:"match_id"`
	UserID         string `json:"user_id"`
	TriggerNudgeID string `json:"trigger_nudge_id,omitempty"`
	ResumedAt      string `json:"resumed_at"`
}

type circleChallenge struct {
	ID                 string `json:"id"`
	CircleID           string `json:"circle_id"`
	City               string `json:"city"`
	Topic              string `json:"topic"`
	PromptText         string `json:"prompt_text"`
	WeekKey            string `json:"week_key"`
	StartsAt           string `json:"starts_at"`
	EndsAt             string `json:"ends_at"`
	ParticipationCount int    `json:"participation_count"`
}

type circleChallengeEntry struct {
	ID          string `json:"id"`
	CircleID    string `json:"circle_id"`
	ChallengeID string `json:"challenge_id"`
	UserID      string `json:"user_id"`
	EntryText   string `json:"entry_text"`
	ImageURL    string `json:"image_url,omitempty"`
	SubmittedAt string `json:"submitted_at"`
}

type circleChallengeView struct {
	CircleID           string                `json:"circle_id"`
	Challenge          circleChallenge       `json:"challenge"`
	UserEntry          *circleChallengeEntry `json:"user_entry,omitempty"`
	ParticipationCount int                   `json:"participation_count"`
	IsJoined           bool                  `json:"is_joined"`
}

type circleMembership struct {
	CircleID string `json:"circle_id"`
	UserID   string `json:"user_id"`
	JoinedAt string `json:"joined_at"`
	IsJoined bool   `json:"is_joined"`
}

type voiceIcebreakerPrompt struct {
	ID         string `json:"id"`
	PromptText string `json:"prompt_text"`
}

type voiceIcebreaker struct {
	ID               string `json:"id"`
	MatchID          string `json:"match_id"`
	SenderUserID     string `json:"sender_user_id"`
	ReceiverUserID   string `json:"receiver_user_id"`
	PromptID         string `json:"prompt_id"`
	PromptText       string `json:"prompt_text"`
	Transcript       string `json:"transcript"`
	DurationSeconds  int    `json:"duration_seconds"`
	Status           string `json:"status"`
	ModerationStatus string `json:"moderation_status"`
	StartedAt        string `json:"started_at"`
	SentAt           string `json:"sent_at,omitempty"`
	LastPlayedAt     string `json:"last_played_at,omitempty"`
	PlayCount        int    `json:"play_count"`
}

type groupCoffeePollOption struct {
	ID           string `json:"id"`
	Day          string `json:"day"`
	TimeWindow   string `json:"time_window"`
	Neighborhood string `json:"neighborhood"`
	VotesCount   int    `json:"votes_count"`
}

type groupCoffeePoll struct {
	ID                 string                  `json:"id"`
	CreatorUserID      string                  `json:"creator_user_id"`
	ParticipantUserIDs []string                `json:"participant_user_ids"`
	Options            []groupCoffeePollOption `json:"options"`
	Status             string                  `json:"status"`
	DeadlineAt         string                  `json:"deadline_at"`
	FinalizedOptionID  string                  `json:"finalized_option_id,omitempty"`
	CreatedAt          string                  `json:"created_at"`
	FinalizedAt        string                  `json:"finalized_at,omitempty"`
}

type sosAlert struct {
	ID             string  `json:"id"`
	UserID         string  `json:"user_id"`
	MatchID        string  `json:"match_id,omitempty"`
	Latitude       float64 `json:"latitude,omitempty"`
	Longitude      float64 `json:"longitude,omitempty"`
	Message        string  `json:"message,omitempty"`
	EmergencyLevel string  `json:"emergency_level"`
	Status         string  `json:"status"`
	TriggeredAt    string  `json:"triggered_at"`
	ResolvedAt     string  `json:"resolved_at,omitempty"`
	ResolvedBy     string  `json:"resolved_by,omitempty"`
	ResolutionNote string  `json:"resolution_note,omitempty"`
}

type subscriptionPlan struct {
	ID             string   `json:"id"`
	Name           string   `json:"name"`
	MonthlyPrice   float64  `json:"monthly_price"`
	YearlyPrice    float64  `json:"yearly_price"`
	LikesPerDay    int      `json:"likes_per_day"`
	MessagesPerDay int      `json:"messages_per_day"`
	Features       []string `json:"features"`
	IsActive       bool     `json:"is_active"`
}

type userSubscription struct {
	ID              string `json:"id"`
	UserID          string `json:"user_id"`
	PlanID          string `json:"plan_id"`
	PlanName        string `json:"plan_name"`
	Status          string `json:"status"`
	BillingCycle    string `json:"billing_cycle"`
	StartDate       string `json:"start_date"`
	NextBillingDate string `json:"next_billing_date"`
	UpdatedAt       string `json:"updated_at"`
}

type paymentRecord struct {
	ID            string  `json:"id"`
	UserID        string  `json:"user_id"`
	PlanID        string  `json:"plan_id"`
	Amount        float64 `json:"amount"`
	Currency      string  `json:"currency"`
	Status        string  `json:"status"`
	PaymentMethod string  `json:"payment_method"`
	CreatedAt     string  `json:"created_at"`
}

type monetizationMatrixItem struct {
	FeatureCode           string `json:"feature_code"`
	Category              string `json:"category"`
	Access                string `json:"access"`
	RequiresSubscription  bool   `json:"requires_subscription"`
	BlocksCoreProgression bool   `json:"blocks_core_progression"`
	Description           string `json:"description"`
}

type moderationReport struct {
	ID             string `json:"id"`
	ReporterUserID string `json:"reporter_user_id"`
	ReportedUserID string `json:"reported_user_id"`
	Reason         string `json:"reason"`
	Description    string `json:"description,omitempty"`
	Status         string `json:"status"`
	Action         string `json:"action,omitempty"`
	ReviewedBy     string `json:"reviewed_by,omitempty"`
	ReviewedAt     string `json:"reviewed_at,omitempty"`
	CreatedAt      string `json:"created_at"`
}

type moderationAppeal struct {
	ID                 string `json:"id"`
	UserID             string `json:"user_id"`
	ReportID           string `json:"report_id,omitempty"`
	Reason             string `json:"reason"`
	Description        string `json:"description,omitempty"`
	Status             string `json:"status"`
	ResolutionReason   string `json:"resolution_reason,omitempty"`
	ReviewedBy         string `json:"reviewed_by,omitempty"`
	ReviewedAt         string `json:"reviewed_at,omitempty"`
	SLADeadlineAt      string `json:"sla_deadline_at"`
	NotificationPolicy string `json:"notification_policy"`
	CreatedAt          string `json:"created_at"`
	UpdatedAt          string `json:"updated_at"`
}

type questTemplateRequirement struct {
	MatchID       string `json:"match_id"`
	TemplateID    string `json:"template_id"`
	CreatorUserID string `json:"creator_user_id"`
	Prompt        string `json:"prompt_template"`
	MinChars      int    `json:"min_chars"`
	MaxChars      int    `json:"max_chars"`
	UpdatedAt     string `json:"updated_at"`
}

type questSubmissionWorkflow struct {
	MatchID         string `json:"match_id"`
	TemplateID      string `json:"template_id,omitempty"`
	UnlockState     string `json:"unlock_state"`
	Status          string `json:"status"`
	SubmitterUserID string `json:"submitter_user_id,omitempty"`
	ReviewerUserID  string `json:"reviewer_user_id,omitempty"`
	ResponseText    string `json:"response_text,omitempty"`
	ReviewReason    string `json:"review_reason,omitempty"`
	SubmittedAt     string `json:"submitted_at,omitempty"`
	ReviewedAt      string `json:"reviewed_at,omitempty"`
	CooldownUntil   string `json:"cooldown_until,omitempty"`
	AttemptCount    int    `json:"attempt_count"`
	WindowStartedAt string `json:"window_started_at,omitempty"`
}

const (
	questWorkflowStatusPending  = "pending"
	questWorkflowStatusApproved = "approved"
	questWorkflowStatusRejected = "rejected"
	questWorkflowStatusCooldown = "cooldown"

	autoReviewReasonPrefix = "assisted_auto_approve"

	unlockPolicyAllowWithoutTemplate = "allow_without_template"
	unlockPolicyRequireQuestTemplate = "require_quest_template"
	defaultQuestPromptTemplate       = "Share one value conflict and how you addressed it constructively."
	defaultQuestMinChars             = 20
	defaultQuestMaxChars             = 240

	questSubmissionWindow     = 1 * time.Hour
	questCooldownDuration     = 10 * time.Minute
	questRateLimitCooldown    = 15 * time.Minute
	questMaxAttemptsPerWindow = 5

	activitySessionStatusActive         = "active"
	activitySessionStatusCompleted      = "completed"
	activitySessionStatusTimedOut       = "timed_out"
	activitySessionStatusPartialTimeout = "partial_timeout"
	activitySessionDuration             = 120 * time.Second
	activitySessionReplayWindow         = 7 * 24 * time.Hour
	activitySessionMaxThisOrThatPerWeek = 2

	dailyPromptMinChars               = 1
	dailyPromptMaxChars               = 240
	dailyPromptEditWindow             = 10 * time.Minute
	matchNudgeDailyCap                = 2
	matchNudgeSafetyWindow            = 14 * 24 * time.Hour
	circleChallengeMinChars           = 3
	circleChallengeMaxChars           = 280
	voiceIcebreakerMinDurationSec     = 20
	voiceIcebreakerMaxDurationSec     = 45
	voiceIcebreakerMaxTranscriptChars = 500
	groupCoffeePollMinParticipants    = 2
	groupCoffeePollMaxParticipants    = 4
	groupCoffeePollMaxOptions         = 6

	appealStatusSubmitted       = "submitted"
	appealStatusUnderReview     = "under_review"
	appealStatusResolvedUpheld  = "resolved_upheld"
	appealStatusResolvedReverse = "resolved_reversed"
	appealSLADuration           = 48 * time.Hour
)

type dailyPromptTemplate struct {
	Code   string
	Domain string
	Text   string
}

var (
	dailyPromptMilestones = []int{3, 7}
	dailyPromptPool       = []dailyPromptTemplate{
		{
			Code:   "values_trust_boundaries",
			Domain: "values",
			Text:   "What is one boundary that helps you feel respected in a relationship?",
		},
		{
			Code:   "values_repair_conflict",
			Domain: "values",
			Text:   "How do you prefer to repair after a disagreement?",
		},
		{
			Code:   "lifestyle_weekend_energy",
			Domain: "lifestyle",
			Text:   "Which weekend rhythm feels most like you right now?",
		},
		{
			Code:   "lifestyle_social_battery",
			Domain: "lifestyle",
			Text:   "When your social battery is low, what helps you reset quickly?",
		},
		{
			Code:   "relationship_clarity",
			Domain: "relationship_style",
			Text:   "What does healthy communication look like to you on a busy week?",
		},
		{
			Code:   "relationship_affection",
			Domain: "relationship_style",
			Text:   "Which small gesture makes you feel most cared for?",
		},
	}
	circleChallengeTemplates = map[string]struct {
		City   string
		Topic  string
		Prompt string
	}{
		"circle-blr-books": {
			City:   "Bengaluru",
			Topic:  "Books",
			Prompt: "One quote that changed your week.",
		},
		"circle-blr-fitness": {
			City:   "Bengaluru",
			Topic:  "Fitness",
			Prompt: "This week's 20-min routine.",
		},
		"circle-blr-music": {
			City:   "Bengaluru",
			Topic:  "Music",
			Prompt: "Song currently on repeat + why.",
		},
	}
	voiceIcebreakerPromptCatalog = []voiceIcebreakerPrompt{
		{
			ID:         "voice-lite-calm-sunday",
			PromptText: "What does a calm Sunday look like for you?",
		},
	}
)

type memoryStore struct {
	mu                     sync.RWMutex
	cfg                    config.Config
	profiles               map[string]profileDraft
	settings               map[string]userSettings
	contacts               map[string][]emergencyContact
	blockedUsers           map[string]map[string]blockedUser
	verification           map[string]verificationState
	activities             []activityEvent
	activitySeq            uint64
	calls                  map[string]videoCallSession
	sosAlerts              map[string]sosAlert
	plans                  []subscriptionPlan
	subscriptions          map[string]userSubscription
	payments               map[string][]paymentRecord
	reports                []moderationReport
	appeals                []moderationAppeal
	trustMilestones        map[string]trustMilestone
	userBadges             map[string]map[string]trustBadge
	badgeHistory           map[string][]trustBadgeHistoryEvent
	trustFilters           map[string]trustFilterPreference
	rooms                  map[string]conversationRoomRecord
	roomParticipants       map[string]map[string]conversationRoomParticipant
	roomModerationActions  map[string][]conversationRoomModerationAction
	roomActiveBlocks       map[string]map[string]conversationRoomBlock
	friends                map[string]map[string]friendConnection
	friendActivities       map[string][]friendActivity
	activitySessions       map[string]activitySession
	dailyPromptAnswers     map[string]map[string]dailyPromptAnswer
	dailyPromptStreaks     map[string]dailyPromptStreak
	matchNudges            map[string][]matchNudge
	conversationResumes    map[string][]conversationResumed
	circleMembers          map[string]map[string]circleMembership
	circleChallengeEntries map[string]map[string]circleChallengeEntry
	voiceIcebreakers       map[string]voiceIcebreaker
	groupCoffeePolls       map[string]groupCoffeePoll
	groupCoffeePollVotes   map[string]map[string]string
	questTemplates         map[string]questTemplateRequirement
	questWorkflows         map[string]questSubmissionWorkflow
	matchGestures          map[string][]matchGesture
	questRepo              *questRepository
}

func newMemoryStore(cfg config.Config) *memoryStore {
	return &memoryStore{
		cfg:                    cfg,
		profiles:               make(map[string]profileDraft),
		settings:               make(map[string]userSettings),
		contacts:               make(map[string][]emergencyContact),
		blockedUsers:           make(map[string]map[string]blockedUser),
		verification:           make(map[string]verificationState),
		activities:             make([]activityEvent, 0, 512),
		calls:                  make(map[string]videoCallSession),
		sosAlerts:              make(map[string]sosAlert),
		plans:                  defaultSubscriptionPlans(),
		subscriptions:          make(map[string]userSubscription),
		payments:               make(map[string][]paymentRecord),
		reports:                make([]moderationReport, 0, 128),
		trustMilestones:        make(map[string]trustMilestone),
		userBadges:             make(map[string]map[string]trustBadge),
		badgeHistory:           make(map[string][]trustBadgeHistoryEvent),
		trustFilters:           make(map[string]trustFilterPreference),
		rooms:                  defaultConversationRoomRecords(),
		roomParticipants:       make(map[string]map[string]conversationRoomParticipant),
		roomModerationActions:  make(map[string][]conversationRoomModerationAction),
		roomActiveBlocks:       make(map[string]map[string]conversationRoomBlock),
		friends:                make(map[string]map[string]friendConnection),
		friendActivities:       make(map[string][]friendActivity),
		activitySessions:       make(map[string]activitySession),
		dailyPromptAnswers:     make(map[string]map[string]dailyPromptAnswer),
		dailyPromptStreaks:     make(map[string]dailyPromptStreak),
		matchNudges:            make(map[string][]matchNudge),
		conversationResumes:    make(map[string][]conversationResumed),
		circleMembers:          make(map[string]map[string]circleMembership),
		circleChallengeEntries: make(map[string]map[string]circleChallengeEntry),
		voiceIcebreakers:       make(map[string]voiceIcebreaker),
		groupCoffeePolls:       make(map[string]groupCoffeePoll),
		groupCoffeePollVotes:   make(map[string]map[string]string),
		questTemplates:         make(map[string]questTemplateRequirement),
		questWorkflows:         make(map[string]questSubmissionWorkflow),
		matchGestures:          make(map[string][]matchGesture),
		questRepo:              newQuestRepository(cfg),
	}
}

func isQuestRepoPersistenceUnavailable(err error) bool {
	if err == nil {
		return false
	}
	msg := strings.ToLower(err.Error())
	return strings.Contains(msg, "pgrst106") ||
		strings.Contains(msg, "pgrst205") ||
		strings.Contains(msg, "invalid schema") ||
		strings.Contains(msg, "could not find the table")
}

func (m *memoryStore) durableEngagementRequired() bool {
	return m != nil && m.cfg.RequireDurableEngagementStore
}

func (m *memoryStore) unlockPolicyVariant() string {
	if m == nil {
		return unlockPolicyRequireQuestTemplate
	}
	variant := strings.ToLower(strings.TrimSpace(m.cfg.DefaultUnlockPolicyVariant))
	if variant == unlockPolicyAllowWithoutTemplate {
		return unlockPolicyAllowWithoutTemplate
	}
	return unlockPolicyRequireQuestTemplate
}

func (m *memoryStore) requiresQuestTemplateByDefault() bool {
	return m.unlockPolicyVariant() == unlockPolicyRequireQuestTemplate
}

func (m *memoryStore) assistedReviewEnabled() bool {
	return m != nil && m.cfg.FeatureAssistedReviewAutomation
}

func (m *memoryStore) assistedReviewDecision(matchID, submitterUserID, responseText string) (bool, string, string) {
	template, hasTemplate := m.getQuestTemplate(strings.TrimSpace(matchID))
	if !hasTemplate {
		return false, "", ""
	}
	return m.assistedReviewDecisionWithTemplate(template, submitterUserID, responseText)
}

func (m *memoryStore) assistedReviewDecisionWithTemplate(template questTemplateRequirement, submitterUserID, responseText string) (bool, string, string) {
	if !m.assistedReviewEnabled() {
		return false, "", ""
	}

	trimmedResponse := strings.TrimSpace(responseText)
	if len(trimmedResponse) < m.cfg.AssistedReviewMinChars {
		return false, "", ""
	}
	if wordCount(trimmedResponse) < m.cfg.AssistedReviewMinWordCount {
		return false, "", ""
	}
	if containsStringToken(trimmedResponse, m.cfg.GestureProfanityTokens) {
		return false, "", ""
	}

	reviewerUserID := strings.TrimSpace(template.CreatorUserID)
	if reviewerUserID == "" || reviewerUserID == strings.TrimSpace(submitterUserID) {
		return false, "", ""
	}
	reason := fmt.Sprintf(
		"%s:min_chars=%d;min_words=%d;profanity_pass=true",
		autoReviewReasonPrefix,
		m.cfg.AssistedReviewMinChars,
		m.cfg.AssistedReviewMinWordCount,
	)
	return true, reviewerUserID, reason
}

func containsString(values []string, target string) bool {
	trimmedTarget := strings.TrimSpace(target)
	if trimmedTarget == "" {
		return false
	}
	for _, value := range values {
		if strings.TrimSpace(value) == trimmedTarget {
			return true
		}
	}
	return false
}

func (m *memoryStore) getQuestTemplate(matchID string) (questTemplateRequirement, bool) {
	if m.questRepo != nil {
		item, ok, err := m.questRepo.getQuestTemplate(context.Background(), matchID)
		if err == nil {
			if ok {
				m.mu.Lock()
				m.questTemplates[item.MatchID] = item
				m.mu.Unlock()
			}
			return item, ok
		}
		if m.durableEngagementRequired() {
			return questTemplateRequirement{}, false
		}
	}

	if m.durableEngagementRequired() {
		return questTemplateRequirement{}, false
	}

	m.mu.RLock()
	defer m.mu.RUnlock()

	item, ok := m.questTemplates[matchID]
	if !ok {
		return questTemplateRequirement{}, false
	}
	return item, true
}

func (m *memoryStore) upsertQuestTemplate(
	matchID,
	creatorUserID,
	prompt string,
	minChars,
	maxChars int,
) (questTemplateRequirement, error) {
	if m.questRepo != nil {
		item, err := m.questRepo.upsertQuestTemplate(
			context.Background(),
			matchID,
			creatorUserID,
			prompt,
			minChars,
			maxChars,
		)
		if err != nil {
			if m.durableEngagementRequired() || !isQuestRepoPersistenceUnavailable(err) {
				return questTemplateRequirement{}, err
			}
		}
		if err == nil {
			m.mu.Lock()
			m.questTemplates[item.MatchID] = item
			workflow, ok := m.questWorkflows[item.MatchID]
			if !ok {
				workflow = questSubmissionWorkflow{MatchID: item.MatchID}
			}
			workflow.TemplateID = item.TemplateID
			workflow.UnlockState = transitionUnlockState(workflow.UnlockState, matchingdomain.ActionAssignQuest)
			if workflow.Status == "" {
				workflow.Status = questWorkflowStatusPending
			}
			m.questWorkflows[item.MatchID] = workflow
			m.mu.Unlock()
			return item, nil
		}
	}

	if m.durableEngagementRequired() {
		return questTemplateRequirement{}, errors.New("durable quest persistence unavailable")
	}

	m.mu.Lock()
	defer m.mu.Unlock()

	now := time.Now().UTC()
	template, err := matchingdomain.NewQuestTemplate(
		"quest-template-"+matchID,
		creatorUserID,
		prompt,
		minChars,
		maxChars,
		now,
	)
	if err != nil {
		return questTemplateRequirement{}, err
	}

	item := questTemplateRequirement{
		MatchID:       strings.TrimSpace(matchID),
		TemplateID:    template.ID,
		CreatorUserID: template.CreatorID,
		Prompt:        template.Prompt,
		MinChars:      template.MinChars,
		MaxChars:      template.MaxChars,
		UpdatedAt:     template.UpdatedAt.Format(time.RFC3339),
	}
	m.questTemplates[item.MatchID] = item

	workflow := m.questWorkflows[item.MatchID]
	if workflow.MatchID == "" {
		workflow.MatchID = item.MatchID
	}
	workflow.TemplateID = item.TemplateID
	workflow.UnlockState = transitionUnlockState(workflow.UnlockState, matchingdomain.ActionAssignQuest)
	if workflow.Status == "" {
		workflow.Status = questWorkflowStatusPending
	}
	m.questWorkflows[item.MatchID] = workflow

	return item, nil
}

func (m *memoryStore) listQuestTemplatesByMatchIDs(matchIDs []string) map[string]questTemplateRequirement {
	if m.questRepo != nil {
		result, err := m.questRepo.listQuestTemplatesByMatchIDs(context.Background(), matchIDs)
		if err == nil {
			m.mu.Lock()
			for matchID, item := range result {
				m.questTemplates[matchID] = item
			}
			m.mu.Unlock()
			return result
		}
		if m.durableEngagementRequired() {
			return map[string]questTemplateRequirement{}
		}
	}

	if m.durableEngagementRequired() {
		return map[string]questTemplateRequirement{}
	}

	m.mu.RLock()
	defer m.mu.RUnlock()

	result := make(map[string]questTemplateRequirement, len(matchIDs))
	for _, matchID := range matchIDs {
		if item, ok := m.questTemplates[matchID]; ok {
			result[matchID] = item
		}
	}
	return result
}

func (m *memoryStore) getQuestWorkflow(matchID string) (questSubmissionWorkflow, bool) {
	if m.questRepo != nil {
		workflow, ok, err := m.questRepo.getQuestWorkflow(context.Background(), matchID)
		if err == nil {
			if ok {
				m.mu.Lock()
				m.questWorkflows[workflow.MatchID] = workflow
				m.mu.Unlock()
			}
			return workflow, ok
		}
		if m.durableEngagementRequired() {
			return questSubmissionWorkflow{}, false
		}
	}

	if m.durableEngagementRequired() {
		return questSubmissionWorkflow{}, false
	}

	m.mu.RLock()
	defer m.mu.RUnlock()

	workflow, ok := m.questWorkflows[matchID]
	if !ok {
		return questSubmissionWorkflow{}, false
	}
	return normalizeQuestWorkflow(workflow), true
}

func (m *memoryStore) submitQuestResponse(
	matchID,
	submitterUserID,
	responseText string,
) (questSubmissionWorkflow, error) {
	trimmedMatchID := strings.TrimSpace(matchID)
	trimmedSubmitter := strings.TrimSpace(submitterUserID)
	if trimmedMatchID == "" {
		return questSubmissionWorkflow{}, errors.New("match id is required")
	}
	if trimmedSubmitter == "" {
		return questSubmissionWorkflow{}, errors.New("submitter user id is required")
	}

	if m.requiresQuestTemplateByDefault() {
		if _, hasTemplate := m.getQuestTemplate(trimmedMatchID); !hasTemplate {
			if _, err := m.upsertQuestTemplate(
				trimmedMatchID,
				trimmedSubmitter,
				defaultQuestPromptTemplate,
				defaultQuestMinChars,
				defaultQuestMaxChars,
			); err != nil {
				return questSubmissionWorkflow{}, err
			}
		}
	}

	template, hasTemplate := m.getQuestTemplate(trimmedMatchID)

	if m.questRepo != nil {
		workflow, err := m.questRepo.submitQuestResponse(context.Background(), trimmedMatchID, trimmedSubmitter, responseText)
		if err != nil {
			if m.durableEngagementRequired() || !isQuestRepoPersistenceUnavailable(err) {
				return questSubmissionWorkflow{}, err
			}
		}
		if err == nil {
			m.mu.Lock()
			m.questWorkflows[workflow.MatchID] = workflow
			m.mu.Unlock()
			if hasTemplate {
				if shouldAutoApprove, reviewerUserID, reason := m.assistedReviewDecisionWithTemplate(template, trimmedSubmitter, responseText); shouldAutoApprove {
					autoReviewed, autoErr := m.reviewQuestResponse(trimmedMatchID, reviewerUserID, questWorkflowStatusApproved, reason)
					if autoErr == nil {
						return autoReviewed, nil
					}
				}
			}
			return workflow, nil
		}
	}

	if m.durableEngagementRequired() {
		return questSubmissionWorkflow{}, errors.New("durable quest persistence unavailable")
	}

	m.mu.Lock()
	defer m.mu.Unlock()

	now := time.Now().UTC()
	trimmedResponse := strings.TrimSpace(responseText)

	template, ok := m.questTemplates[trimmedMatchID]
	if !ok {
		return questSubmissionWorkflow{}, errors.New("quest template not found for match")
	}
	if len(trimmedResponse) < template.MinChars || len(trimmedResponse) > template.MaxChars {
		return questSubmissionWorkflow{}, fmt.Errorf(
			"response text must be between %d and %d characters",
			template.MinChars,
			template.MaxChars,
		)
	}

	workflow := m.questWorkflows[trimmedMatchID]
	if workflow.MatchID == "" {
		workflow.MatchID = trimmedMatchID
	}
	workflow.TemplateID = template.TemplateID

	if isCooldownActive(workflow, now) {
		workflow.Status = questWorkflowStatusCooldown
		m.questWorkflows[trimmedMatchID] = workflow
		return questSubmissionWorkflow{}, errors.New("quest submission is in cooldown period")
	}

	windowStart := parseRFC3339OrZero(workflow.WindowStartedAt)
	if windowStart.IsZero() || now.Sub(windowStart) > questSubmissionWindow {
		workflow.AttemptCount = 0
		workflow.WindowStartedAt = now.Format(time.RFC3339)
	}
	if workflow.AttemptCount >= questMaxAttemptsPerWindow {
		workflow.Status = questWorkflowStatusCooldown
		workflow.CooldownUntil = now.Add(questRateLimitCooldown).Format(time.RFC3339)
		m.questWorkflows[trimmedMatchID] = workflow
		return questSubmissionWorkflow{}, errors.New("quest submission rate limit exceeded")
	}

	workflow.UnlockState = transitionUnlockState(workflow.UnlockState, matchingdomain.ActionSubmitQuest)
	workflow.Status = questWorkflowStatusPending
	workflow.SubmitterUserID = trimmedSubmitter
	workflow.ResponseText = trimmedResponse
	workflow.SubmittedAt = now.Format(time.RFC3339)
	workflow.ReviewerUserID = ""
	workflow.ReviewedAt = ""
	workflow.ReviewReason = ""
	workflow.CooldownUntil = ""
	workflow.AttemptCount++

	m.questWorkflows[trimmedMatchID] = workflow
	normalized := normalizeQuestWorkflow(workflow)
	if shouldAutoApprove, reviewerUserID, reason := m.assistedReviewDecisionWithTemplate(template, trimmedSubmitter, trimmedResponse); shouldAutoApprove {
		autoReviewed, err := m.reviewQuestResponse(trimmedMatchID, reviewerUserID, questWorkflowStatusApproved, reason)
		if err == nil {
			return autoReviewed, nil
		}
	}
	return normalized, nil
}

func (m *memoryStore) reviewQuestResponse(
	matchID,
	reviewerUserID,
	decisionStatus,
	reviewReason string,
) (questSubmissionWorkflow, error) {
	if m.questRepo != nil {
		workflow, err := m.questRepo.reviewQuestResponse(
			context.Background(),
			matchID,
			reviewerUserID,
			decisionStatus,
			reviewReason,
		)
		if err != nil {
			if m.durableEngagementRequired() || !isQuestRepoPersistenceUnavailable(err) {
				return questSubmissionWorkflow{}, err
			}
		}
		if err == nil {
			m.mu.Lock()
			m.questWorkflows[workflow.MatchID] = workflow
			m.mu.Unlock()
			return workflow, nil
		}
	}

	if m.durableEngagementRequired() {
		return questSubmissionWorkflow{}, errors.New("durable quest persistence unavailable")
	}

	m.mu.Lock()
	defer m.mu.Unlock()

	now := time.Now().UTC()
	trimmedMatchID := strings.TrimSpace(matchID)
	trimmedReviewer := strings.TrimSpace(reviewerUserID)
	trimmedDecision := strings.ToLower(strings.TrimSpace(decisionStatus))
	trimmedReason := strings.TrimSpace(reviewReason)

	workflow, ok := m.questWorkflows[trimmedMatchID]
	if !ok || workflow.MatchID == "" {
		return questSubmissionWorkflow{}, errors.New("quest submission not found for match")
	}
	if workflow.Status != questWorkflowStatusPending {
		return questSubmissionWorkflow{}, errors.New("quest submission is not pending review")
	}

	workflow.ReviewerUserID = trimmedReviewer
	workflow.ReviewedAt = now.Format(time.RFC3339)

	switch trimmedDecision {
	case questWorkflowStatusApproved:
		workflow.Status = questWorkflowStatusApproved
		workflow.ReviewReason = trimmedReason
		workflow.CooldownUntil = ""
		workflow.UnlockState = transitionUnlockState(workflow.UnlockState, matchingdomain.ActionApproveQuest)
	case questWorkflowStatusRejected:
		workflow.Status = questWorkflowStatusRejected
		workflow.ReviewReason = trimmedReason
		workflow.CooldownUntil = now.Add(questCooldownDuration).Format(time.RFC3339)
		workflow.UnlockState = transitionUnlockState(workflow.UnlockState, matchingdomain.ActionRejectQuest)
	default:
		return questSubmissionWorkflow{}, errors.New("invalid decision status")
	}

	m.questWorkflows[trimmedMatchID] = workflow
	return normalizeQuestWorkflow(workflow), nil
}

func (m *memoryStore) listQuestWorkflowsByMatchIDs(matchIDs []string) map[string]questSubmissionWorkflow {
	if m.questRepo != nil {
		result, err := m.questRepo.listQuestWorkflowsByMatchIDs(context.Background(), matchIDs)
		if err == nil {
			m.mu.Lock()
			for matchID, workflow := range result {
				m.questWorkflows[matchID] = workflow
			}
			m.mu.Unlock()
			return result
		}
		if m.durableEngagementRequired() {
			return map[string]questSubmissionWorkflow{}
		}
	}

	if m.durableEngagementRequired() {
		return map[string]questSubmissionWorkflow{}
	}

	m.mu.RLock()
	defer m.mu.RUnlock()

	result := make(map[string]questSubmissionWorkflow, len(matchIDs))
	for _, matchID := range matchIDs {
		if workflow, ok := m.questWorkflows[matchID]; ok {
			result[matchID] = normalizeQuestWorkflow(workflow)
		}
	}
	return result
}

func (m *memoryStore) getMatchUnlockState(matchID string) (string, bool) {
	trimmedMatchID := strings.TrimSpace(matchID)
	if trimmedMatchID == "" {
		if m.requiresQuestTemplateByDefault() {
			return string(matchingdomain.UnlockStateQuestPending), true
		}
		return string(matchingdomain.UnlockStateMatched), false
	}

	template, hasTemplate := m.getQuestTemplate(trimmedMatchID)
	if !hasTemplate || template.MatchID == "" {
		if m.requiresQuestTemplateByDefault() {
			return string(matchingdomain.UnlockStateQuestPending), true
		}
		return string(matchingdomain.UnlockStateMatched), false
	}

	workflow, hasWorkflow := m.getQuestWorkflow(trimmedMatchID)
	if !hasWorkflow {
		return string(matchingdomain.UnlockStateQuestPending), true
	}
	workflow = normalizeQuestWorkflow(workflow)
	if workflow.UnlockState == "" {
		return string(matchingdomain.UnlockStateQuestPending), true
	}
	return workflow.UnlockState, true
}

func (m *memoryStore) listMatchUnlockStatesByMatchIDs(matchIDs []string) map[string]string {
	if m.questRepo != nil {
		states, err := m.questRepo.listUnlockStatesByMatchIDs(context.Background(), matchIDs)
		if err == nil {
			return states
		}
		if m.durableEngagementRequired() {
			return map[string]string{}
		}
	}

	if m.durableEngagementRequired() {
		return map[string]string{}
	}

	m.mu.RLock()
	defer m.mu.RUnlock()

	out := make(map[string]string, len(matchIDs))
	for _, matchID := range matchIDs {
		trimmed := strings.TrimSpace(matchID)
		if trimmed == "" {
			continue
		}
		if workflow, ok := m.questWorkflows[trimmed]; ok {
			normalized := normalizeQuestWorkflow(workflow)
			if normalized.UnlockState != "" {
				out[trimmed] = normalized.UnlockState
				continue
			}
		}
		if _, ok := m.questTemplates[trimmed]; ok {
			out[trimmed] = string(matchingdomain.UnlockStateQuestPending)
		}
	}
	return out
}

func (m *memoryStore) isChatUnlocked(matchID string) (bool, string, error) {
	trimmedMatchID := strings.TrimSpace(matchID)
	if trimmedMatchID == "" {
		return false, string(matchingdomain.UnlockStateMatched), errors.New("match id is required")
	}

	if m.durableEngagementRequired() {
		if m.questRepo == nil {
			return false, string(matchingdomain.UnlockStateRestricted), errors.New("durable quest persistence unavailable")
		}

		template, hasTemplate, err := m.questRepo.getQuestTemplate(context.Background(), trimmedMatchID)
		if err != nil {
			return false, string(matchingdomain.UnlockStateRestricted), err
		}
		if !hasTemplate || template.MatchID == "" {
			if m.requiresQuestTemplateByDefault() {
				return false, string(matchingdomain.UnlockStateQuestPending), nil
			}
			return true, string(matchingdomain.UnlockStateConversationUnlocked), nil
		}

		workflow, hasWorkflow, err := m.questRepo.getQuestWorkflow(context.Background(), trimmedMatchID)
		if err != nil {
			return false, string(matchingdomain.UnlockStateRestricted), err
		}
		if !hasWorkflow {
			return false, string(matchingdomain.UnlockStateQuestPending), nil
		}
		workflow = normalizeQuestWorkflow(workflow)
		if workflow.UnlockState == string(matchingdomain.UnlockStateConversationUnlocked) ||
			workflow.Status == questWorkflowStatusApproved {
			return true, string(matchingdomain.UnlockStateConversationUnlocked), nil
		}
		if workflow.UnlockState == "" {
			return false, string(matchingdomain.UnlockStateQuestPending), nil
		}
		return false, workflow.UnlockState, nil
	}

	template, hasTemplate := m.getQuestTemplate(trimmedMatchID)
	if !hasTemplate || template.MatchID == "" {
		if m.requiresQuestTemplateByDefault() {
			return false, string(matchingdomain.UnlockStateQuestPending), nil
		}
		return true, string(matchingdomain.UnlockStateConversationUnlocked), nil
	}

	workflow, hasWorkflow := m.getQuestWorkflow(trimmedMatchID)
	if !hasWorkflow {
		return false, string(matchingdomain.UnlockStateQuestPending), nil
	}
	workflow = normalizeQuestWorkflow(workflow)
	if workflow.UnlockState == string(matchingdomain.UnlockStateConversationUnlocked) ||
		workflow.Status == questWorkflowStatusApproved {
		return true, string(matchingdomain.UnlockStateConversationUnlocked), nil
	}
	if workflow.UnlockState == "" {
		return false, string(matchingdomain.UnlockStateQuestPending), nil
	}
	return false, workflow.UnlockState, nil
}

func normalizeQuestWorkflow(workflow questSubmissionWorkflow) questSubmissionWorkflow {
	now := time.Now().UTC()
	if isCooldownActive(workflow, now) {
		workflow.Status = questWorkflowStatusCooldown
	}
	if workflow.UnlockState == "" {
		workflow.UnlockState = string(matchingdomain.UnlockStateMatched)
	}
	return workflow
}

func isCooldownActive(workflow questSubmissionWorkflow, now time.Time) bool {
	if strings.TrimSpace(workflow.CooldownUntil) == "" {
		return false
	}
	cooldownUntil := parseRFC3339OrZero(workflow.CooldownUntil)
	return !cooldownUntil.IsZero() && now.Before(cooldownUntil)
}

func parseRFC3339OrZero(value string) time.Time {
	if strings.TrimSpace(value) == "" {
		return time.Time{}
	}
	parsed, err := time.Parse(time.RFC3339, value)
	if err != nil {
		return time.Time{}
	}
	return parsed.UTC()
}

func wordCount(value string) int {
	fields := strings.Fields(strings.TrimSpace(value))
	return len(fields)
}

func containsStringToken(value string, tokens []string) bool {
	lower := strings.ToLower(strings.TrimSpace(value))
	if lower == "" {
		return false
	}
	for _, token := range tokens {
		trimmedToken := strings.ToLower(strings.TrimSpace(token))
		if trimmedToken == "" {
			continue
		}
		if strings.Contains(lower, trimmedToken) {
			return true
		}
	}
	return false
}

func transitionUnlockState(current string, action matchingdomain.UnlockAction) string {
	state := matchingdomain.UnlockState(strings.TrimSpace(current))
	if !matchingdomain.IsValidState(state) {
		state = matchingdomain.UnlockStateMatched
	}
	next, err := matchingdomain.NextUnlockState(state, action)
	if err != nil {
		switch action {
		case matchingdomain.ActionAssignQuest, matchingdomain.ActionRejectQuest:
			return string(matchingdomain.UnlockStateQuestPending)
		case matchingdomain.ActionSubmitQuest:
			return string(matchingdomain.UnlockStateQuestUnderReview)
		case matchingdomain.ActionApproveQuest:
			return string(matchingdomain.UnlockStateConversationUnlocked)
		default:
			return string(state)
		}
	}
	return string(next)
}

func (m *memoryStore) getDraft(userID string) profileDraft {
	m.mu.Lock()
	defer m.mu.Unlock()
	draft, ok := m.profiles[userID]
	if !ok {
		draft = defaultDraft(userID)
		m.profiles[userID] = draft
	}
	return copyDraft(draft)
}

func (m *memoryStore) patchDraft(userID string, payload map[string]any) profileDraft {
	m.mu.Lock()
	defer m.mu.Unlock()

	draft, ok := m.profiles[userID]
	if !ok {
		draft = defaultDraft(userID)
	}

	if value := strings.TrimSpace(toString(payload["phone_number"])); value != "" {
		draft.PhoneNumber = value
	}
	if value := strings.TrimSpace(toString(payload["name"])); value != "" {
		draft.Name = value
	}
	if value := strings.TrimSpace(toString(payload["date_of_birth"])); value != "" {
		draft.DateOfBirth = value
	}
	if value := strings.TrimSpace(toString(payload["gender"])); value != "" {
		draft.Gender = value
	}
	if value, ok := payload["bio"].(string); ok {
		draft.Bio = strings.TrimSpace(value)
	}
	if value, ok := toInt(payload["height_cm"]); ok {
		draft.HeightCm = &value
	}
	if value, ok := toOptionalString(payload["education"]); ok {
		draft.Education = value
	}
	if value, ok := toOptionalString(payload["profession"]); ok {
		draft.Profession = value
	}
	if value, ok := toOptionalString(payload["income_range"]); ok {
		draft.IncomeRange = value
	}
	if value, ok := toStringSlice(payload["seeking_genders"]); ok && len(value) > 0 {
		draft.SeekingGenders = value
	}
	if value, ok := toInt(payload["min_age_years"]); ok {
		draft.MinAgeYears = value
	}
	if value, ok := toInt(payload["max_age_years"]); ok {
		draft.MaxAgeYears = value
	}
	if value, ok := toInt(payload["max_distance_km"]); ok {
		draft.MaxDistanceKm = value
	}
	if value, ok := toStringSlice(payload["education_filter"]); ok {
		draft.EducationFilter = value
	}
	if value, ok := payload["serious_only"].(bool); ok {
		draft.SeriousOnly = value
	}
	if value, ok := payload["verified_only"].(bool); ok {
		draft.VerifiedOnly = value
	}
	if value, ok := toOptionalString(payload["country"]); ok {
		draft.Country = value
	}
	if value, ok := toOptionalString(payload["state"]); ok {
		draft.RegionState = value
	}
	if value, ok := toOptionalString(payload["city"]); ok {
		draft.City = value
	}
	if value, ok := toOptionalString(payload["instagram_handle"]); ok {
		draft.InstagramHandle = value
	}
	if value, ok := toStringSlice(payload["hobbies"]); ok {
		draft.Hobbies = value
	}
	if value, ok := toStringSlice(payload["favorite_books"]); ok {
		draft.FavoriteBooks = value
	}
	if value, ok := toStringSlice(payload["favorite_novels"]); ok {
		draft.FavoriteNovels = value
	}
	if value, ok := toStringSlice(payload["favorite_songs"]); ok {
		draft.FavoriteSongs = value
	}
	if value, ok := toStringSlice(payload["extra_curriculars"]); ok {
		draft.ExtraCurriculars = value
	}
	if value, ok := toOptionalString(payload["additional_info"]); ok {
		draft.AdditionalInfo = value
	}
	if value, ok := toStringSlice(payload["intent_tags"]); ok {
		draft.IntentTags = value
	}
	if value, ok := toStringSlice(payload["language_tags"]); ok {
		draft.LanguageTags = value
	}
	if value, ok := toOptionalString(payload["pet_preference"]); ok {
		draft.PetPreference = value
	}
	if value, ok := toOptionalString(payload["diet_preference"]); ok {
		draft.DietPreference = value
	}
	if value, ok := toOptionalString(payload["workout_frequency"]); ok {
		draft.WorkoutFrequency = value
	}
	if value, ok := toOptionalString(payload["diet_type"]); ok {
		draft.DietType = value
	}
	if value, ok := toOptionalString(payload["sleep_schedule"]); ok {
		draft.SleepSchedule = value
	}
	if value, ok := toOptionalString(payload["travel_style"]); ok {
		draft.TravelStyle = value
	}
	if value, ok := toOptionalString(payload["political_comfort_range"]); ok {
		draft.PoliticalComfort = value
	}
	if value, ok := toStringSlice(payload["deal_breaker_tags"]); ok {
		draft.DealBreakerTags = value
	}
	if value := strings.TrimSpace(toString(payload["drinking"])); value != "" {
		draft.Drinking = value
	}
	if value := strings.TrimSpace(toString(payload["smoking"])); value != "" {
		draft.Smoking = value
	}
	if value, ok := toOptionalString(payload["religion"]); ok {
		draft.Religion = value
	}
	if value, ok := toOptionalString(payload["mother_tongue"]); ok {
		draft.MotherTongue = value
	}
	if value, ok := toOptionalString(payload["relationship_status"]); ok {
		draft.RelationshipStatus = value
	}
	if value, ok := toOptionalString(payload["personality_type"]); ok {
		draft.PersonalityType = value
	}
	if value, ok := payload["party_lover"].(bool); ok {
		draft.PartyLover = &value
	}
	if value, ok := payload["hookup_only"].(bool); ok {
		draft.HookupOnly = value
	}

	m.profiles[userID] = draft
	return copyDraft(draft)
}

func (m *memoryStore) addPhoto(userID string, photoURL string) profileDraft {
	m.mu.Lock()
	defer m.mu.Unlock()

	draft, ok := m.profiles[userID]
	if !ok {
		draft = defaultDraft(userID)
	}

	nextID := fmt.Sprintf("photo-%d", time.Now().UnixNano())
	if strings.TrimSpace(photoURL) == "" {
		photoURL = seedURL(m.cfg.MockPhotoSeedURLTemplate, nextID)
	}

	draft.Photos = append(draft.Photos, profilePhoto{
		ID:       nextID,
		PhotoURL: photoURL,
		Ordering: len(draft.Photos),
	})
	m.profiles[userID] = draft
	return copyDraft(draft)
}

func (m *memoryStore) deletePhoto(userID, photoID string) profileDraft {
	m.mu.Lock()
	defer m.mu.Unlock()

	draft, ok := m.profiles[userID]
	if !ok {
		draft = defaultDraft(userID)
	}

	filtered := make([]profilePhoto, 0, len(draft.Photos))
	for _, photo := range draft.Photos {
		if photo.ID == photoID {
			continue
		}
		filtered = append(filtered, photo)
	}
	for i := range filtered {
		filtered[i].Ordering = i
	}
	draft.Photos = filtered
	m.profiles[userID] = draft
	return copyDraft(draft)
}

func (m *memoryStore) reorderPhotos(userID string, photoIDs []string) profileDraft {
	m.mu.Lock()
	defer m.mu.Unlock()

	draft, ok := m.profiles[userID]
	if !ok {
		draft = defaultDraft(userID)
	}

	byID := make(map[string]profilePhoto, len(draft.Photos))
	for _, photo := range draft.Photos {
		byID[photo.ID] = photo
	}

	reordered := make([]profilePhoto, 0, len(draft.Photos))
	for _, photoID := range photoIDs {
		photo, ok := byID[photoID]
		if !ok {
			continue
		}
		reordered = append(reordered, photo)
		delete(byID, photoID)
	}
	for _, photo := range draft.Photos {
		if _, ok := byID[photo.ID]; ok {
			reordered = append(reordered, photo)
		}
	}
	for i := range reordered {
		reordered[i].Ordering = i
	}
	draft.Photos = reordered
	m.profiles[userID] = draft
	return copyDraft(draft)
}

func (m *memoryStore) completeProfile(userID string) (profileDraft, error) {
	m.mu.Lock()
	defer m.mu.Unlock()

	draft, ok := m.profiles[userID]
	if !ok {
		draft = defaultDraft(userID)
	}

	if len(strings.TrimSpace(draft.Name)) < 2 ||
		strings.TrimSpace(draft.DateOfBirth) == "" ||
		len(draft.Photos) < 2 ||
		len(strings.TrimSpace(draft.Bio)) < 10 {
		return profileDraft{}, errors.New("profile is incomplete")
	}

	draft.ProfileCompletion = 100
	m.profiles[userID] = draft
	return copyDraft(draft), nil
}

func (m *memoryStore) getSettings(userID string) userSettings {
	m.mu.Lock()
	defer m.mu.Unlock()

	settings, ok := m.settings[userID]
	if !ok {
		settings = defaultSettings(userID)
		m.settings[userID] = settings
	}
	return settings
}

func (m *memoryStore) patchSettings(userID string, payload map[string]any) userSettings {
	m.mu.Lock()
	defer m.mu.Unlock()

	settings, ok := m.settings[userID]
	if !ok {
		settings = defaultSettings(userID)
	}

	if value, ok := payload["show_age"].(bool); ok {
		settings.ShowAge = value
	}
	if value, ok := payload["show_exact_distance"].(bool); ok {
		settings.ShowExactDistance = value
	}
	if value, ok := payload["show_online_status"].(bool); ok {
		settings.ShowOnlineStatus = value
	}
	if value, ok := payload["notify_new_match"].(bool); ok {
		settings.NotifyNewMatch = value
	}
	if value, ok := payload["notify_new_message"].(bool); ok {
		settings.NotifyNewMessage = value
	}
	if value, ok := payload["notify_likes"].(bool); ok {
		settings.NotifyLikes = value
	}
	if value := strings.TrimSpace(toString(payload["theme"])); value != "" {
		settings.Theme = value
	}
	settings.UpdatedAt = time.Now().UTC().Format(time.RFC3339)

	m.settings[userID] = settings
	return settings
}

func (m *memoryStore) listEmergencyContacts(userID string) []emergencyContact {
	m.mu.RLock()
	defer m.mu.RUnlock()
	return copyContacts(m.contacts[userID])
}

func (m *memoryStore) addEmergencyContact(userID, name, phoneNumber string) ([]emergencyContact, error) {
	m.mu.Lock()
	defer m.mu.Unlock()

	items := m.contacts[userID]
	if len(items) >= 3 {
		return nil, errors.New("maximum 3 emergency contacts allowed")
	}
	items = append(items, emergencyContact{
		ID:          fmt.Sprintf("contact-%d", time.Now().UnixNano()),
		UserID:      userID,
		Name:        strings.TrimSpace(name),
		PhoneNumber: strings.TrimSpace(phoneNumber),
		Ordering:    len(items) + 1,
		AddedAt:     time.Now().UTC().Format(time.RFC3339),
	})
	m.contacts[userID] = items
	return copyContacts(items), nil
}

func (m *memoryStore) updateEmergencyContact(userID, contactID, name, phoneNumber string) ([]emergencyContact, error) {
	m.mu.Lock()
	defer m.mu.Unlock()

	items := m.contacts[userID]
	updated := false
	for i := range items {
		if items[i].ID != contactID {
			continue
		}
		items[i].Name = strings.TrimSpace(name)
		items[i].PhoneNumber = strings.TrimSpace(phoneNumber)
		updated = true
	}
	if !updated {
		return nil, errors.New("contact not found")
	}
	m.contacts[userID] = items
	return copyContacts(items), nil
}

func (m *memoryStore) deleteEmergencyContact(userID, contactID string) []emergencyContact {
	m.mu.Lock()
	defer m.mu.Unlock()

	items := m.contacts[userID]
	filtered := make([]emergencyContact, 0, len(items))
	for _, item := range items {
		if item.ID == contactID {
			continue
		}
		filtered = append(filtered, item)
	}
	for i := range filtered {
		filtered[i].Ordering = i + 1
	}
	m.contacts[userID] = filtered
	return copyContacts(filtered)
}

func (m *memoryStore) listBlockedUsers(userID string) []blockedUser {
	m.mu.RLock()
	defer m.mu.RUnlock()

	entries := m.blockedUsers[userID]
	out := make([]blockedUser, 0, len(entries))
	for _, item := range entries {
		out = append(out, item)
	}
	return out
}

func (m *memoryStore) blockUser(userID, blockedUserID string) {
	m.mu.Lock()
	defer m.mu.Unlock()

	if _, ok := m.blockedUsers[userID]; !ok {
		m.blockedUsers[userID] = make(map[string]blockedUser)
	}
	m.blockedUsers[userID][blockedUserID] = blockedUser{
		ID:       blockedUserID,
		Name:     "Blocked User",
		PhotoURL: seedURL(m.cfg.MockBlockedPhotoTemplate, blockedUserID),
	}
}

func (m *memoryStore) unblockUser(userID, blockedUserID string) {
	m.mu.Lock()
	defer m.mu.Unlock()

	entries := m.blockedUsers[userID]
	delete(entries, blockedUserID)
}

func (m *memoryStore) listFriends(userID string) []friendConnection {
	m.mu.RLock()
	defer m.mu.RUnlock()
	entries := m.friends[userID]
	out := make([]friendConnection, 0, len(entries))
	for _, item := range entries {
		out = append(out, item)
	}
	sort.SliceStable(out, func(i, j int) bool {
		return out[i].UpdatedAt > out[j].UpdatedAt
	})
	return out
}

func (m *memoryStore) addFriend(userID, friendUserID string) (friendConnection, error) {
	trimmedUserID := strings.TrimSpace(userID)
	trimmedFriendID := strings.TrimSpace(friendUserID)
	if trimmedUserID == "" || trimmedFriendID == "" {
		return friendConnection{}, errors.New("user_id and friend_user_id are required")
	}
	if trimmedUserID == trimmedFriendID {
		return friendConnection{}, errors.New("cannot add yourself as friend")
	}

	m.mu.Lock()
	defer m.mu.Unlock()

	now := time.Now().UTC().Format(time.RFC3339)
	if _, ok := m.friends[trimmedUserID]; !ok {
		m.friends[trimmedUserID] = make(map[string]friendConnection)
	}
	if _, ok := m.friends[trimmedFriendID]; !ok {
		m.friends[trimmedFriendID] = make(map[string]friendConnection)
	}

	friendName := "Friend"
	if draft, ok := m.profiles[trimmedFriendID]; ok {
		if strings.TrimSpace(draft.Name) != "" {
			friendName = strings.TrimSpace(draft.Name)
		}
	}

	connection := friendConnection{
		UserID:     trimmedUserID,
		FriendID:   trimmedFriendID,
		Status:     "accepted",
		CreatedAt:  now,
		UpdatedAt:  now,
		FriendName: friendName,
	}
	inverseFriendName := "Friend"
	if draft, ok := m.profiles[trimmedUserID]; ok {
		if strings.TrimSpace(draft.Name) != "" {
			inverseFriendName = strings.TrimSpace(draft.Name)
		}
	}
	inverse := friendConnection{
		UserID:     trimmedFriendID,
		FriendID:   trimmedUserID,
		Status:     "accepted",
		CreatedAt:  now,
		UpdatedAt:  now,
		FriendName: inverseFriendName,
	}

	m.friends[trimmedUserID][trimmedFriendID] = connection
	m.friends[trimmedFriendID][trimmedUserID] = inverse

	if _, ok := m.friendActivities[trimmedUserID]; !ok {
		m.friendActivities[trimmedUserID] = []friendActivity{}
	}
	if _, ok := m.friendActivities[trimmedFriendID]; !ok {
		m.friendActivities[trimmedFriendID] = []friendActivity{}
	}
	activityID := fmt.Sprintf("friend-activity-%d", time.Now().UnixNano())
	m.friendActivities[trimmedUserID] = append([]friendActivity{{
		ID:          activityID,
		UserID:      trimmedUserID,
		FriendID:    trimmedFriendID,
		Type:        "friend_connected",
		Title:       "New Friend Added",
		Description: "You can now join friend activities together.",
		CreatedAt:   now,
	}}, m.friendActivities[trimmedUserID]...)

	return connection, nil
}

func (m *memoryStore) removeFriend(userID, friendUserID string) {
	m.mu.Lock()
	defer m.mu.Unlock()
	if entries, ok := m.friends[userID]; ok {
		delete(entries, friendUserID)
	}
	if inverse, ok := m.friends[friendUserID]; ok {
		delete(inverse, userID)
	}
}

func (m *memoryStore) listFriendActivities(userID string, limit int) []friendActivity {
	if limit <= 0 || limit > 100 {
		limit = 20
	}
	m.mu.RLock()
	defer m.mu.RUnlock()
	items := append([]friendActivity{}, m.friendActivities[userID]...)
	if len(items) == 0 {
		now := time.Now().UTC().Format(time.RFC3339)
		items = []friendActivity{
			{
				ID:          "friend-default-1",
				UserID:      userID,
				FriendID:    "",
				Type:        "suggested_activity",
				Title:       "Plan a Friend Catch-up",
				Description: "Share one weekly highlight and one goal for next week.",
				CreatedAt:   now,
			},
		}
	}
	if len(items) > limit {
		items = items[:limit]
	}
	return items
}

func (m *memoryStore) getVerification(userID string) verificationState {
	m.mu.RLock()
	defer m.mu.RUnlock()
	if current, ok := m.verification[userID]; ok {
		return current
	}
	return verificationState{UserID: userID}
}

func (m *memoryStore) submitVerification(userID string) verificationState {
	m.mu.Lock()
	defer m.mu.Unlock()
	state := verificationState{
		UserID:      userID,
		Status:      "pending",
		SubmittedAt: time.Now().UTC().Format(time.RFC3339),
	}
	m.verification[userID] = state
	return state
}

func (m *memoryStore) reviewVerification(
	userID string,
	status string,
	rejectionReason string,
	reviewedBy string,
) (verificationState, error) {
	m.mu.Lock()
	defer m.mu.Unlock()

	current, ok := m.verification[userID]
	if !ok {
		return verificationState{}, errors.New("verification not found")
	}

	current.Status = status
	current.RejectionReason = strings.TrimSpace(rejectionReason)
	current.ReviewedBy = strings.TrimSpace(reviewedBy)
	current.ReviewedAt = time.Now().UTC().Format(time.RFC3339)
	m.verification[userID] = current
	return current, nil
}

func (m *memoryStore) listVerifications(status string, limit int) []verificationState {
	if limit <= 0 || limit > 500 {
		limit = 100
	}
	normalizedStatus := strings.ToLower(strings.TrimSpace(status))

	m.mu.RLock()
	defer m.mu.RUnlock()

	out := make([]verificationState, 0, len(m.verification))
	for _, item := range m.verification {
		if normalizedStatus != "" && strings.ToLower(item.Status) != normalizedStatus {
			continue
		}
		out = append(out, item)
	}

	sort.Slice(out, func(i, j int) bool {
		return out[i].SubmittedAt > out[j].SubmittedAt
	})
	if len(out) > limit {
		out = out[:limit]
	}
	return out
}

func (m *memoryStore) recordActivity(event activityEvent) {
	m.mu.Lock()
	defer m.mu.Unlock()

	m.activitySeq++
	event.ID = fmt.Sprintf("act-%d", m.activitySeq)
	if event.CreatedAt == "" {
		event.CreatedAt = time.Now().UTC().Format(time.RFC3339)
	}
	if event.Details == nil {
		event.Details = map[string]any{}
	}
	m.applyExperimentDimensions(&event)

	m.activities = append(m.activities, event)
	if len(m.activities) > 2000 {
		m.activities = m.activities[len(m.activities)-2000:]
	}
}

func (m *memoryStore) applyExperimentDimensions(event *activityEvent) {
	if m == nil || event == nil {
		return
	}
	if !m.cfg.FeatureExperimentFramework || !m.cfg.FeatureExperimentMatchNudge {
		return
	}
	if event.Details == nil {
		event.Details = map[string]any{}
	}
	if _, exists := event.Details["exp_match_nudge_variant"]; exists {
		return
	}
	subjectID := strings.TrimSpace(event.UserID)
	if subjectID == "" {
		actor := strings.TrimSpace(event.Actor)
		if actor != "" && !strings.EqualFold(actor, "system") {
			subjectID = actor
		}
	}
	if subjectID == "" {
		return
	}

	assignment := assignExperimentVariant(subjectID, "match_nudge_timing_v1", m.cfg.ExperimentMatchNudgeRolloutPct)
	event.Details["exp_match_nudge_key"] = "match_nudge_timing_v1"
	event.Details["exp_match_nudge_variant"] = assignment.Variant
	event.Details["exp_match_nudge_bucket"] = assignment.Bucket
}

type experimentAssignment struct {
	Variant string
	Bucket  int
}

func assignExperimentVariant(userID, experimentKey string, rolloutPct int) experimentAssignment {
	rollout := rolloutPct
	if rollout < 0 {
		rollout = 0
	}
	if rollout > 100 {
		rollout = 100
	}
	bucket := experimentBucket(userID, experimentKey)
	variant := "control"
	if bucket < rollout {
		variant = "treatment"
	}
	return experimentAssignment{
		Variant: variant,
		Bucket:  bucket,
	}
}

func experimentBucket(userID, experimentKey string) int {
	seed := strings.TrimSpace(userID) + ":" + strings.TrimSpace(experimentKey)
	hash := sha1.Sum([]byte(seed))
	value := binary.BigEndian.Uint32(hash[:4])
	return int(value % 100)
}

func (m *memoryStore) listActivities(limit int) []activityEvent {
	if limit <= 0 || limit > 1000 {
		limit = 100
	}

	m.mu.RLock()
	defer m.mu.RUnlock()

	total := len(m.activities)
	if total == 0 {
		return []activityEvent{}
	}
	if limit > total {
		limit = total
	}

	out := make([]activityEvent, 0, limit)
	for i := total - 1; i >= 0 && len(out) < limit; i-- {
		item := m.activities[i]
		copyDetails := make(map[string]any, len(item.Details))
		for key, value := range item.Details {
			copyDetails[key] = value
		}
		item.Details = copyDetails
		out = append(out, item)
	}
	return out
}

func (m *memoryStore) startActivitySession(matchID, initiatorUserID, participantUserID, activityType string, metadata map[string]any) (activitySession, error) {
	trimmedMatchID := strings.TrimSpace(matchID)
	trimmedInitiator := strings.TrimSpace(initiatorUserID)
	trimmedParticipant := strings.TrimSpace(participantUserID)
	trimmedType := strings.TrimSpace(activityType)
	if trimmedMatchID == "" || trimmedInitiator == "" || trimmedParticipant == "" {
		return activitySession{}, errors.New("match_id, initiator_user_id, and participant_user_id are required")
	}
	if trimmedInitiator == trimmedParticipant {
		return activitySession{}, errors.New("initiator and participant must be different users")
	}
	if trimmedType == "" {
		trimmedType = "co_op_prompt"
	}

	now := time.Now().UTC()
	expiresAt := now.Add(activitySessionDuration)

	m.mu.Lock()
	defer m.mu.Unlock()

	if trimmedType == "this_or_that" {
		attemptsInWindow := 0
		for _, existing := range m.activitySessions {
			if existing.MatchID != trimmedMatchID || existing.ActivityType != trimmedType {
				continue
			}
			startedAt := parseRFC3339OrZero(existing.StartedAt)
			if startedAt.IsZero() {
				continue
			}
			if now.Sub(startedAt) <= activitySessionReplayWindow {
				attemptsInWindow++
			}
		}
		if attemptsInWindow >= activitySessionMaxThisOrThatPerWeek {
			return activitySession{}, errors.New("weekly replay limit reached for this_or_that")
		}
	}

	m.activitySeq++
	sessionID := fmt.Sprintf("activity-%d", m.activitySeq)
	session := activitySession{
		ID:              sessionID,
		MatchID:         trimmedMatchID,
		ActivityType:    trimmedType,
		Status:          activitySessionStatusActive,
		InitiatorUserID: trimmedInitiator,
		ParticipantIDs:  []string{trimmedInitiator, trimmedParticipant},
		ResponsesByUser: map[string][]string{},
		StartedAt:       now.Format(time.RFC3339),
		ExpiresAt:       expiresAt.Format(time.RFC3339),
	}
	if len(metadata) > 0 {
		session.Metadata = make(map[string]any, len(metadata))
		for key, value := range metadata {
			session.Metadata[key] = value
		}
	}

	m.activitySessions[sessionID] = session
	return session, nil
}

func (m *memoryStore) submitActivitySessionResponses(sessionID, userID string, responses []string) (activitySession, error) {
	trimmedSessionID := strings.TrimSpace(sessionID)
	trimmedUserID := strings.TrimSpace(userID)
	if trimmedSessionID == "" || trimmedUserID == "" {
		return activitySession{}, errors.New("session_id and user_id are required")
	}

	trimmedResponses := make([]string, 0, len(responses))
	for _, item := range responses {
		value := strings.TrimSpace(item)
		if value == "" {
			continue
		}
		trimmedResponses = append(trimmedResponses, value)
	}
	if len(trimmedResponses) == 0 {
		return activitySession{}, errors.New("at least one response is required")
	}

	m.mu.Lock()
	defer m.mu.Unlock()

	session, ok := m.activitySessions[trimmedSessionID]
	if !ok {
		return activitySession{}, errors.New("activity session not found")
	}

	if !containsString(session.ParticipantIDs, trimmedUserID) {
		return activitySession{}, errors.New("user is not a participant in this activity session")
	}

	now := time.Now().UTC()
	m.finalizeActivityTimeoutIfNeededLocked(&session, now)
	if session.Status == activitySessionStatusTimedOut || session.Status == activitySessionStatusPartialTimeout {
		m.activitySessions[trimmedSessionID] = session
		return session, errors.New("activity session expired")
	}
	if session.Status == activitySessionStatusCompleted {
		return session, errors.New("activity session already completed")
	}

	if session.ResponsesByUser == nil {
		session.ResponsesByUser = map[string][]string{}
	}
	session.ResponsesByUser[trimmedUserID] = trimmedResponses
	session.LastResponseAt = now.Format(time.RFC3339)

	if len(session.ResponsesByUser) >= len(session.ParticipantIDs) {
		session.Status = activitySessionStatusCompleted
		session.CompletedAt = now.Format(time.RFC3339)
		session.Summary = m.buildActivitySummaryLocked(session, now)
	}

	m.activitySessions[trimmedSessionID] = session
	return session, nil
}

func (m *memoryStore) getActivitySessionSummary(sessionID string) (activitySessionSummary, activitySession, error) {
	trimmedSessionID := strings.TrimSpace(sessionID)
	if trimmedSessionID == "" {
		return activitySessionSummary{}, activitySession{}, errors.New("session_id is required")
	}

	m.mu.Lock()
	defer m.mu.Unlock()

	session, ok := m.activitySessions[trimmedSessionID]
	if !ok {
		return activitySessionSummary{}, activitySession{}, errors.New("activity session not found")
	}

	now := time.Now().UTC()
	m.finalizeActivityTimeoutIfNeededLocked(&session, now)
	if session.Summary.SessionID == "" {
		session.Summary = m.buildActivitySummaryLocked(session, now)
	}
	m.activitySessions[trimmedSessionID] = session

	return session.Summary, session, nil
}

func (m *memoryStore) getDailyPromptView(userID string, now time.Time) (dailyPromptView, error) {
	trimmedUserID := strings.TrimSpace(userID)
	if trimmedUserID == "" {
		return dailyPromptView{}, errors.New("user id is required")
	}

	prompt := dailyPromptForDate(now)

	m.mu.RLock()
	defer m.mu.RUnlock()

	return m.buildDailyPromptViewLocked(trimmedUserID, prompt), nil
}

func (m *memoryStore) submitDailyPromptAnswer(userID, promptID, answerText string, now time.Time) (dailyPromptView, bool, error) {
	trimmedUserID := strings.TrimSpace(userID)
	trimmedPromptID := strings.TrimSpace(promptID)
	trimmedAnswer := strings.TrimSpace(answerText)
	if trimmedUserID == "" {
		return dailyPromptView{}, false, errors.New("user id is required")
	}
	if trimmedAnswer == "" {
		return dailyPromptView{}, false, errors.New("answer_text is required")
	}
	if len(trimmedAnswer) < dailyPromptMinChars || len(trimmedAnswer) > dailyPromptMaxChars {
		return dailyPromptView{}, false, fmt.Errorf(
			"answer_text must be between %d and %d characters",
			dailyPromptMinChars,
			dailyPromptMaxChars,
		)
	}

	prompt := dailyPromptForDate(now)
	if trimmedPromptID != "" && trimmedPromptID != prompt.ID {
		return dailyPromptView{}, false, errors.New("prompt_id does not match today's prompt")
	}

	promptDate := prompt.PromptDate
	normalizedAnswer := normalizeDailyPromptAnswer(trimmedAnswer)
	if normalizedAnswer == "" {
		return dailyPromptView{}, false, errors.New("answer_text cannot be empty after normalization")
	}

	m.mu.Lock()
	defer m.mu.Unlock()

	userAnswers, ok := m.dailyPromptAnswers[trimmedUserID]
	if !ok {
		userAnswers = make(map[string]dailyPromptAnswer)
		m.dailyPromptAnswers[trimmedUserID] = userAnswers
	}

	existing, hasExisting := userAnswers[promptDate]
	isEdit := false
	if hasExisting {
		editWindowUntil := parseRFC3339OrZero(existing.EditWindowUntil)
		if editWindowUntil.IsZero() {
			answeredAt := parseRFC3339OrZero(existing.AnsweredAt)
			if answeredAt.IsZero() {
				answeredAt = now.UTC()
			}
			editWindowUntil = answeredAt.Add(dailyPromptEditWindow)
		}
		if now.UTC().After(editWindowUntil) {
			return dailyPromptView{}, false, errors.New("daily prompt edit window expired")
		}

		existing.AnswerText = trimmedAnswer
		existing.UpdatedAt = now.UTC().Format(time.RFC3339)
		existing.IsEdited = true
		existing.Normalized = normalizedAnswer
		userAnswers[promptDate] = existing
		isEdit = true
	} else {
		userAnswers[promptDate] = dailyPromptAnswer{
			UserID:          trimmedUserID,
			PromptID:        prompt.ID,
			PromptDate:      promptDate,
			AnswerText:      trimmedAnswer,
			AnsweredAt:      now.UTC().Format(time.RFC3339),
			UpdatedAt:       now.UTC().Format(time.RFC3339),
			EditWindowUntil: now.UTC().Add(dailyPromptEditWindow).Format(time.RFC3339),
			IsEdited:        false,
			Normalized:      normalizedAnswer,
		}

		updatedStreak, milestoneReached := m.updateDailyPromptStreakLocked(trimmedUserID, promptDate, now.UTC())
		if milestoneReached > 0 {
			updatedStreak.MilestoneReached = milestoneReached
			m.dailyPromptStreaks[trimmedUserID] = updatedStreak
		}
	}

	view := m.buildDailyPromptViewLocked(trimmedUserID, prompt)
	return view, isEdit, nil
}

func (m *memoryStore) buildDailyPromptViewLocked(userID string, prompt dailyPrompt) dailyPromptView {
	view := dailyPromptView{
		Prompt: prompt,
		Streak: normalizeDailyPromptStreak(m.dailyPromptStreaks[userID]),
		Spark:  dailyPromptSpark{SimilarUserIDs: []string{}},
	}

	if userAnswers, ok := m.dailyPromptAnswers[userID]; ok {
		if answer, hasAnswer := userAnswers[prompt.PromptDate]; hasAnswer {
			answerCopy := answer
			view.Answer = &answerCopy
			view.Spark = m.buildDailyPromptSparkLocked(
				userID,
				prompt.PromptDate,
				answer.Normalized,
			)
			return view
		}
	}

	view.Spark = m.buildDailyPromptSparkLocked(userID, prompt.PromptDate, "")
	return view
}

func (m *memoryStore) buildDailyPromptSparkLocked(userID, promptDate, normalizedAnswer string) dailyPromptSpark {
	spark := dailyPromptSpark{
		SimilarUserIDs: []string{},
	}
	if strings.TrimSpace(promptDate) == "" {
		return spark
	}

	normalizedAnswer = strings.TrimSpace(normalizedAnswer)
	for otherUserID, answersByDate := range m.dailyPromptAnswers {
		answer, ok := answersByDate[promptDate]
		if !ok {
			continue
		}
		spark.ParticipantsToday++
		if normalizedAnswer == "" {
			continue
		}
		if otherUserID == userID {
			continue
		}
		if strings.TrimSpace(answer.Normalized) != normalizedAnswer {
			continue
		}
		spark.SimilarCount++
		if len(spark.SimilarUserIDs) < 3 {
			spark.SimilarUserIDs = append(spark.SimilarUserIDs, otherUserID)
		}
	}
	return spark
}

func (m *memoryStore) listDailyPromptResponders(userID string, now time.Time, limit, offset int) (dailyPromptRespondersPage, error) {
	trimmedUserID := strings.TrimSpace(userID)
	if trimmedUserID == "" {
		return dailyPromptRespondersPage{}, errors.New("user id is required")
	}
	if limit <= 0 {
		limit = 10
	} else if limit > 50 {
		limit = 50
	}
	if offset < 0 {
		offset = 0
	}

	prompt := dailyPromptForDate(now.UTC())
	page := dailyPromptRespondersPage{
		PromptID:   prompt.ID,
		PromptDate: prompt.PromptDate,
		Responders: []dailyPromptResponder{},
		Limit:      limit,
		Offset:     offset,
		NextOffset: offset,
	}

	m.mu.RLock()
	defer m.mu.RUnlock()

	userAnswers, ok := m.dailyPromptAnswers[trimmedUserID]
	if !ok {
		return page, nil
	}
	userAnswer, hasUserAnswer := userAnswers[prompt.PromptDate]
	if !hasUserAnswer {
		return page, nil
	}
	normalizedAnswer := strings.TrimSpace(userAnswer.Normalized)
	if normalizedAnswer == "" {
		return page, nil
	}

	allResponders := make([]dailyPromptResponder, 0, 8)
	for otherUserID, answersByDate := range m.dailyPromptAnswers {
		if otherUserID == trimmedUserID {
			continue
		}
		otherAnswer, hasOtherAnswer := answersByDate[prompt.PromptDate]
		if !hasOtherAnswer {
			continue
		}
		if strings.TrimSpace(otherAnswer.Normalized) != normalizedAnswer {
			continue
		}
		if m.isNudgeSuppressedBySafetyLocked(trimmedUserID, otherUserID, now.UTC()) {
			continue
		}

		displayName := strings.TrimSpace(otherUserID)
		photoURL := strings.TrimSpace(seedURL(m.cfg.MockPhotoSeedURLTemplate, otherUserID))
		if profile, hasProfile := m.profiles[otherUserID]; hasProfile {
			if profileName := strings.TrimSpace(profile.Name); profileName != "" {
				displayName = profileName
			}
			for _, photo := range profile.Photos {
				if candidate := strings.TrimSpace(photo.PhotoURL); candidate != "" {
					photoURL = candidate
					break
				}
			}
		}

		allResponders = append(allResponders, dailyPromptResponder{
			UserID:      otherUserID,
			DisplayName: displayName,
			PhotoURL:    photoURL,
			AnsweredAt:  strings.TrimSpace(otherAnswer.AnsweredAt),
		})
	}

	sort.Slice(allResponders, func(i, j int) bool {
		return allResponders[i].AnsweredAt > allResponders[j].AnsweredAt
	})

	page.Total = len(allResponders)
	if offset >= len(allResponders) {
		return page, nil
	}
	end := offset + limit
	if end > len(allResponders) {
		end = len(allResponders)
	}
	page.Responders = append([]dailyPromptResponder{}, allResponders[offset:end]...)
	page.HasMore = end < len(allResponders)
	page.NextOffset = end

	return page, nil
}

func (m *memoryStore) updateDailyPromptStreakLocked(userID, promptDate string, now time.Time) (dailyPromptStreak, int) {
	streak := m.dailyPromptStreaks[userID]
	streak.UserID = userID
	streak.LastAnsweredDate = strings.TrimSpace(streak.LastAnsweredDate)

	if streak.LastAnsweredDate == promptDate {
		streak.NextMilestone = nextDailyPromptMilestone(streak.CurrentDays)
		streak.UpdatedAt = now.UTC().Format(time.RFC3339)
		m.dailyPromptStreaks[userID] = streak
		return streak, 0
	}

	previousDate := ""
	if parsed, err := time.Parse("2006-01-02", promptDate); err == nil {
		previousDate = parsed.AddDate(0, 0, -1).Format("2006-01-02")
	}

	if streak.LastAnsweredDate != "" && streak.LastAnsweredDate == previousDate {
		streak.CurrentDays++
	} else {
		streak.CurrentDays = 1
	}
	if streak.CurrentDays > streak.LongestDays {
		streak.LongestDays = streak.CurrentDays
	}
	streak.LastAnsweredDate = promptDate
	streak.NextMilestone = nextDailyPromptMilestone(streak.CurrentDays)
	streak.MilestoneReached = 0
	streak.UpdatedAt = now.UTC().Format(time.RFC3339)
	m.dailyPromptStreaks[userID] = streak

	for _, milestone := range dailyPromptMilestones {
		if streak.CurrentDays == milestone {
			return streak, milestone
		}
	}
	return streak, 0
}

func (m *memoryStore) sendMatchNudge(matchID, userID, counterpartyUserID, nudgeType string, now time.Time) (matchNudge, error) {
	trimmedMatchID := strings.TrimSpace(matchID)
	trimmedUserID := strings.TrimSpace(userID)
	trimmedCounterparty := strings.TrimSpace(counterpartyUserID)
	trimmedNudgeType := strings.ToLower(strings.TrimSpace(nudgeType))

	if trimmedMatchID == "" || trimmedUserID == "" || trimmedCounterparty == "" {
		return matchNudge{}, errors.New("match_id, user_id, and counterparty_user_id are required")
	}
	if trimmedNudgeType == "" {
		trimmedNudgeType = "stalled_24h"
	}

	m.mu.Lock()
	defer m.mu.Unlock()

	if m.isNudgeSuppressedBySafetyLocked(trimmedUserID, trimmedCounterparty, now.UTC()) {
		return matchNudge{}, errors.New("match nudge suppressed due to safety state")
	}

	today := now.UTC().Format("2006-01-02")
	sentToday := 0
	for _, matchItems := range m.matchNudges {
		for _, item := range matchItems {
			if item.UserID != trimmedUserID {
				continue
			}
			sentAt := parseRFC3339OrZero(item.SentAt)
			if sentAt.IsZero() {
				continue
			}
			if sentAt.Format("2006-01-02") == today {
				sentToday++
			}
		}
	}
	if sentToday >= matchNudgeDailyCap {
		return matchNudge{}, errors.New("daily nudge cap reached")
	}

	m.activitySeq++
	nudge := matchNudge{
		ID:                 fmt.Sprintf("nud-%d", m.activitySeq),
		MatchID:            trimmedMatchID,
		UserID:             trimmedUserID,
		CounterpartyUserID: trimmedCounterparty,
		NudgeType:          trimmedNudgeType,
		SentAt:             now.UTC().Format(time.RFC3339),
	}
	m.matchNudges[trimmedMatchID] = append(m.matchNudges[trimmedMatchID], nudge)
	return nudge, nil
}

func (m *memoryStore) markMatchNudgeClicked(nudgeID, userID string, now time.Time) (matchNudge, error) {
	trimmedNudgeID := strings.TrimSpace(nudgeID)
	trimmedUserID := strings.TrimSpace(userID)
	if trimmedNudgeID == "" || trimmedUserID == "" {
		return matchNudge{}, errors.New("nudge id and user_id are required")
	}

	m.mu.Lock()
	defer m.mu.Unlock()

	for matchID, items := range m.matchNudges {
		for index := range items {
			if items[index].ID != trimmedNudgeID {
				continue
			}
			if items[index].UserID != trimmedUserID {
				return matchNudge{}, errors.New("nudge does not belong to user")
			}
			if strings.TrimSpace(items[index].ClickedAt) == "" {
				items[index].ClickedAt = now.UTC().Format(time.RFC3339)
				m.matchNudges[matchID] = items
			}
			return items[index], nil
		}
	}

	return matchNudge{}, errors.New("nudge not found")
}

func (m *memoryStore) markConversationResumed(matchID, userID, triggerNudgeID string, now time.Time) (conversationResumed, error) {
	trimmedMatchID := strings.TrimSpace(matchID)
	trimmedUserID := strings.TrimSpace(userID)
	trimmedTrigger := strings.TrimSpace(triggerNudgeID)
	if trimmedMatchID == "" || trimmedUserID == "" {
		return conversationResumed{}, errors.New("match_id and user_id are required")
	}

	m.mu.Lock()
	defer m.mu.Unlock()

	if trimmedTrigger != "" {
		found := false
		for _, nudge := range m.matchNudges[trimmedMatchID] {
			if nudge.ID == trimmedTrigger && nudge.UserID == trimmedUserID {
				found = true
				break
			}
		}
		if !found {
			return conversationResumed{}, errors.New("trigger_nudge_id is invalid for match/user")
		}
	}

	m.activitySeq++
	item := conversationResumed{
		ID:             fmt.Sprintf("resume-%d", m.activitySeq),
		MatchID:        trimmedMatchID,
		UserID:         trimmedUserID,
		TriggerNudgeID: trimmedTrigger,
		ResumedAt:      now.UTC().Format(time.RFC3339),
	}
	m.conversationResumes[trimmedMatchID] = append(m.conversationResumes[trimmedMatchID], item)
	return item, nil
}

func (m *memoryStore) isNudgeSuppressedBySafetyLocked(userID, counterpartyUserID string, now time.Time) bool {
	if userID == "" || counterpartyUserID == "" {
		return true
	}
	if blockedByUser, ok := m.blockedUsers[userID]; ok {
		if _, isBlocked := blockedByUser[counterpartyUserID]; isBlocked {
			return true
		}
	}
	if blockedByCounterparty, ok := m.blockedUsers[counterpartyUserID]; ok {
		if _, isBlocked := blockedByCounterparty[userID]; isBlocked {
			return true
		}
	}

	cutoff := now.Add(-matchNudgeSafetyWindow)
	for _, report := range m.reports {
		if strings.EqualFold(strings.TrimSpace(report.Status), "rejected") {
			continue
		}
		createdAt := parseRFC3339OrZero(report.CreatedAt)
		if createdAt.IsZero() || createdAt.Before(cutoff) {
			continue
		}
		if report.ReporterUserID == userID && report.ReportedUserID == counterpartyUserID {
			return true
		}
		if report.ReporterUserID == counterpartyUserID && report.ReportedUserID == userID {
			return true
		}
	}

	return false
}

func (m *memoryStore) getCircleChallengeView(circleID, userID string, now time.Time) (circleChallengeView, error) {
	trimmedCircleID := strings.TrimSpace(circleID)
	trimmedUserID := strings.TrimSpace(userID)
	if trimmedCircleID == "" {
		return circleChallengeView{}, errors.New("circle_id is required")
	}

	challenge, err := circleChallengeForWeek(trimmedCircleID, now.UTC())
	if err != nil {
		return circleChallengeView{}, err
	}

	m.mu.RLock()
	defer m.mu.RUnlock()

	entriesByUser := m.circleChallengeEntries[challenge.ID]
	view := circleChallengeView{
		CircleID:           trimmedCircleID,
		Challenge:          challenge,
		ParticipationCount: len(entriesByUser),
		IsJoined:           m.isCircleMemberLocked(trimmedCircleID, trimmedUserID),
	}
	view.Challenge.ParticipationCount = view.ParticipationCount
	if trimmedUserID != "" {
		if entry, ok := entriesByUser[trimmedUserID]; ok {
			entryCopy := entry
			view.UserEntry = &entryCopy
		}
	}
	return view, nil
}

func (m *memoryStore) joinCircle(circleID, userID string, now time.Time) (circleMembership, error) {
	trimmedCircleID := strings.TrimSpace(circleID)
	trimmedUserID := strings.TrimSpace(userID)
	if trimmedCircleID == "" {
		return circleMembership{}, errors.New("circle_id is required")
	}
	if trimmedUserID == "" {
		return circleMembership{}, errors.New("user_id is required")
	}
	if _, err := circleChallengeForWeek(trimmedCircleID, now.UTC()); err != nil {
		return circleMembership{}, err
	}

	m.mu.Lock()
	defer m.mu.Unlock()

	membersByCircle := m.circleMembers[trimmedCircleID]
	if membersByCircle == nil {
		membersByCircle = make(map[string]circleMembership)
		m.circleMembers[trimmedCircleID] = membersByCircle
	}
	if existing, ok := membersByCircle[trimmedUserID]; ok {
		return existing, nil
	}

	membership := circleMembership{
		CircleID: trimmedCircleID,
		UserID:   trimmedUserID,
		JoinedAt: now.UTC().Format(time.RFC3339),
		IsJoined: true,
	}
	membersByCircle[trimmedUserID] = membership
	return membership, nil
}

func (m *memoryStore) isCircleMemberLocked(circleID, userID string) bool {
	trimmedCircleID := strings.TrimSpace(circleID)
	trimmedUserID := strings.TrimSpace(userID)
	if trimmedCircleID == "" || trimmedUserID == "" {
		return false
	}
	membersByCircle := m.circleMembers[trimmedCircleID]
	if membersByCircle == nil {
		return false
	}
	_, ok := membersByCircle[trimmedUserID]
	return ok
}

func (m *memoryStore) submitCircleChallengeEntry(
	circleID,
	challengeID,
	userID,
	entryText,
	imageURL string,
	now time.Time,
) (circleChallengeView, circleChallengeEntry, error) {
	trimmedCircleID := strings.TrimSpace(circleID)
	trimmedChallengeID := strings.TrimSpace(challengeID)
	trimmedUserID := strings.TrimSpace(userID)
	trimmedEntryText := strings.TrimSpace(entryText)
	trimmedImageURL := strings.TrimSpace(imageURL)

	if trimmedCircleID == "" || trimmedUserID == "" {
		return circleChallengeView{}, circleChallengeEntry{}, errors.New("circle_id and user_id are required")
	}
	if len(trimmedEntryText) < circleChallengeMinChars || len(trimmedEntryText) > circleChallengeMaxChars {
		return circleChallengeView{}, circleChallengeEntry{}, fmt.Errorf(
			"entry_text must be between %d and %d characters",
			circleChallengeMinChars,
			circleChallengeMaxChars,
		)
	}

	challenge, err := circleChallengeForWeek(trimmedCircleID, now.UTC())
	if err != nil {
		return circleChallengeView{}, circleChallengeEntry{}, err
	}
	if trimmedChallengeID != "" && trimmedChallengeID != challenge.ID {
		return circleChallengeView{}, circleChallengeEntry{}, errors.New("challenge_id does not match active challenge")
	}

	m.mu.Lock()
	defer m.mu.Unlock()

	entriesByUser, ok := m.circleChallengeEntries[challenge.ID]
	if !ok {
		entriesByUser = make(map[string]circleChallengeEntry)
		m.circleChallengeEntries[challenge.ID] = entriesByUser
	}
	if _, exists := entriesByUser[trimmedUserID]; exists {
		return circleChallengeView{}, circleChallengeEntry{}, errors.New("circle challenge already submitted for this week")
	}

	m.activitySeq++
	entry := circleChallengeEntry{
		ID:          fmt.Sprintf("circle-entry-%d", m.activitySeq),
		CircleID:    trimmedCircleID,
		ChallengeID: challenge.ID,
		UserID:      trimmedUserID,
		EntryText:   trimmedEntryText,
		ImageURL:    trimmedImageURL,
		SubmittedAt: now.UTC().Format(time.RFC3339),
	}
	entriesByUser[trimmedUserID] = entry

	view := circleChallengeView{
		CircleID:           trimmedCircleID,
		Challenge:          challenge,
		ParticipationCount: len(entriesByUser),
		UserEntry:          &entry,
	}
	view.Challenge.ParticipationCount = view.ParticipationCount
	return view, entry, nil
}

func (m *memoryStore) listVoiceIcebreakerPrompts() []voiceIcebreakerPrompt {
	items := make([]voiceIcebreakerPrompt, len(voiceIcebreakerPromptCatalog))
	copy(items, voiceIcebreakerPromptCatalog)
	return items
}

func (m *memoryStore) startVoiceIcebreaker(matchID, senderUserID, receiverUserID, promptID string, now time.Time) (voiceIcebreaker, error) {
	trimmedMatchID := strings.TrimSpace(matchID)
	trimmedSenderID := strings.TrimSpace(senderUserID)
	trimmedReceiverID := strings.TrimSpace(receiverUserID)
	trimmedPromptID := strings.TrimSpace(promptID)
	if trimmedMatchID == "" || trimmedSenderID == "" || trimmedReceiverID == "" {
		return voiceIcebreaker{}, errors.New("match_id, sender_user_id, and receiver_user_id are required")
	}
	if trimmedSenderID == trimmedReceiverID {
		return voiceIcebreaker{}, errors.New("sender and receiver cannot be the same")
	}

	prompt := resolveVoiceIcebreakerPrompt(trimmedPromptID)
	if prompt.ID == "" {
		return voiceIcebreaker{}, errors.New("prompt_id is invalid")
	}

	m.mu.Lock()
	defer m.mu.Unlock()

	if m.isNudgeSuppressedBySafetyLocked(trimmedSenderID, trimmedReceiverID, now.UTC()) {
		return voiceIcebreaker{}, errors.New("voice icebreaker suppressed due to safety state")
	}

	today := now.UTC().Format("2006-01-02")
	for _, item := range m.voiceIcebreakers {
		if item.MatchID != trimmedMatchID || item.SenderUserID != trimmedSenderID {
			continue
		}
		if strings.TrimSpace(item.StartedAt) == "" {
			continue
		}
		startedAt := parseRFC3339OrZero(item.StartedAt)
		if startedAt.IsZero() {
			continue
		}
		if startedAt.Format("2006-01-02") == today {
			return voiceIcebreaker{}, errors.New("voice icebreaker already created for this match today")
		}
	}

	m.activitySeq++
	icebreaker := voiceIcebreaker{
		ID:               fmt.Sprintf("voice-%d", m.activitySeq),
		MatchID:          trimmedMatchID,
		SenderUserID:     trimmedSenderID,
		ReceiverUserID:   trimmedReceiverID,
		PromptID:         prompt.ID,
		PromptText:       prompt.PromptText,
		Transcript:       "",
		DurationSeconds:  0,
		Status:           "started",
		ModerationStatus: "pending",
		StartedAt:        now.UTC().Format(time.RFC3339),
		PlayCount:        0,
	}
	m.voiceIcebreakers[icebreaker.ID] = icebreaker
	return icebreaker, nil
}

func (m *memoryStore) sendVoiceIcebreaker(icebreakerID, senderUserID, transcript string, durationSeconds int, now time.Time) (voiceIcebreaker, error) {
	trimmedIcebreakerID := strings.TrimSpace(icebreakerID)
	trimmedSenderID := strings.TrimSpace(senderUserID)
	trimmedTranscript := strings.TrimSpace(transcript)
	if trimmedIcebreakerID == "" || trimmedSenderID == "" {
		return voiceIcebreaker{}, errors.New("icebreaker_id and sender_user_id are required")
	}
	if durationSeconds < voiceIcebreakerMinDurationSec || durationSeconds > voiceIcebreakerMaxDurationSec {
		return voiceIcebreaker{}, fmt.Errorf("duration_seconds must be between %d and %d", voiceIcebreakerMinDurationSec, voiceIcebreakerMaxDurationSec)
	}
	if trimmedTranscript == "" {
		return voiceIcebreaker{}, errors.New("transcript is required")
	}
	if len(trimmedTranscript) > voiceIcebreakerMaxTranscriptChars {
		return voiceIcebreaker{}, fmt.Errorf("transcript exceeds max length of %d", voiceIcebreakerMaxTranscriptChars)
	}

	m.mu.Lock()
	defer m.mu.Unlock()

	item, ok := m.voiceIcebreakers[trimmedIcebreakerID]
	if !ok {
		return voiceIcebreaker{}, errors.New("voice icebreaker not found")
	}
	if item.SenderUserID != trimmedSenderID {
		return voiceIcebreaker{}, errors.New("voice icebreaker does not belong to sender")
	}
	if strings.TrimSpace(item.SentAt) != "" || item.Status == "sent" {
		return voiceIcebreaker{}, errors.New("voice icebreaker already sent")
	}

	item.Transcript = trimmedTranscript
	item.DurationSeconds = durationSeconds
	item.Status = "sent"
	item.ModerationStatus = "approved"
	item.SentAt = now.UTC().Format(time.RFC3339)
	m.voiceIcebreakers[trimmedIcebreakerID] = item
	return item, nil
}

func (m *memoryStore) markVoiceIcebreakerPlayed(icebreakerID, userID string, now time.Time) (voiceIcebreaker, error) {
	trimmedIcebreakerID := strings.TrimSpace(icebreakerID)
	trimmedUserID := strings.TrimSpace(userID)
	if trimmedIcebreakerID == "" || trimmedUserID == "" {
		return voiceIcebreaker{}, errors.New("icebreaker_id and user_id are required")
	}

	m.mu.Lock()
	defer m.mu.Unlock()

	item, ok := m.voiceIcebreakers[trimmedIcebreakerID]
	if !ok {
		return voiceIcebreaker{}, errors.New("voice icebreaker not found")
	}
	if item.Status != "sent" {
		return voiceIcebreaker{}, errors.New("voice icebreaker is not sent yet")
	}
	if trimmedUserID != item.ReceiverUserID && trimmedUserID != item.SenderUserID {
		return voiceIcebreaker{}, errors.New("user cannot play this voice icebreaker")
	}

	item.PlayCount++
	item.LastPlayedAt = now.UTC().Format(time.RFC3339)
	m.voiceIcebreakers[trimmedIcebreakerID] = item
	return item, nil
}

func (m *memoryStore) createGroupCoffeePoll(
	creatorUserID string,
	participantUserIDs []string,
	options []groupCoffeePollOption,
	deadlineAt string,
	now time.Time,
) (groupCoffeePoll, error) {
	trimmedCreator := strings.TrimSpace(creatorUserID)
	if trimmedCreator == "" {
		return groupCoffeePoll{}, errors.New("creator_user_id is required")
	}

	participants := make([]string, 0, len(participantUserIDs)+1)
	seenParticipants := map[string]struct{}{}
	participants = append(participants, trimmedCreator)
	seenParticipants[trimmedCreator] = struct{}{}
	for _, raw := range participantUserIDs {
		item := strings.TrimSpace(raw)
		if item == "" {
			continue
		}
		if _, exists := seenParticipants[item]; exists {
			continue
		}
		participants = append(participants, item)
		seenParticipants[item] = struct{}{}
	}
	if len(participants) < groupCoffeePollMinParticipants || len(participants) > groupCoffeePollMaxParticipants {
		return groupCoffeePoll{}, fmt.Errorf("participants must be between %d and %d users", groupCoffeePollMinParticipants, groupCoffeePollMaxParticipants)
	}

	normalizedOptions := make([]groupCoffeePollOption, 0, len(options))
	for idx, item := range options {
		day := strings.TrimSpace(item.Day)
		timeWindow := strings.TrimSpace(item.TimeWindow)
		neighborhood := strings.TrimSpace(item.Neighborhood)
		if day == "" || timeWindow == "" || neighborhood == "" {
			return groupCoffeePoll{}, errors.New("each option requires day, time_window, and neighborhood")
		}
		normalizedOptions = append(normalizedOptions, groupCoffeePollOption{
			ID:           fmt.Sprintf("opt-%d", idx+1),
			Day:          day,
			TimeWindow:   timeWindow,
			Neighborhood: neighborhood,
			VotesCount:   0,
		})
	}
	if len(normalizedOptions) == 0 || len(normalizedOptions) > groupCoffeePollMaxOptions {
		return groupCoffeePoll{}, fmt.Errorf("options must be between 1 and %d", groupCoffeePollMaxOptions)
	}

	parsedDeadline := parseRFC3339OrZero(deadlineAt)
	if parsedDeadline.IsZero() {
		parsedDeadline = now.UTC().Add(24 * time.Hour)
	}
	if !parsedDeadline.After(now.UTC()) {
		return groupCoffeePoll{}, errors.New("deadline_at must be in the future")
	}

	m.mu.Lock()
	defer m.mu.Unlock()

	m.activitySeq++
	poll := groupCoffeePoll{
		ID:                 fmt.Sprintf("coffee-poll-%d", m.activitySeq),
		CreatorUserID:      trimmedCreator,
		ParticipantUserIDs: participants,
		Options:            normalizedOptions,
		Status:             "open",
		DeadlineAt:         parsedDeadline.Format(time.RFC3339),
		CreatedAt:          now.UTC().Format(time.RFC3339),
	}
	m.groupCoffeePolls[poll.ID] = poll
	m.groupCoffeePollVotes[poll.ID] = make(map[string]string)
	return poll, nil
}

func (m *memoryStore) voteGroupCoffeePoll(pollID, userID, optionID string) (groupCoffeePoll, error) {
	trimmedPollID := strings.TrimSpace(pollID)
	trimmedUserID := strings.TrimSpace(userID)
	trimmedOptionID := strings.TrimSpace(optionID)
	if trimmedPollID == "" || trimmedUserID == "" || trimmedOptionID == "" {
		return groupCoffeePoll{}, errors.New("poll_id, user_id, and option_id are required")
	}

	m.mu.Lock()
	defer m.mu.Unlock()

	poll, ok := m.groupCoffeePolls[trimmedPollID]
	if !ok {
		return groupCoffeePoll{}, errors.New("group coffee poll not found")
	}
	if poll.Status != "open" {
		return groupCoffeePoll{}, errors.New("group coffee poll is not open")
	}
	if deadline := parseRFC3339OrZero(poll.DeadlineAt); !deadline.IsZero() && time.Now().UTC().After(deadline) {
		return groupCoffeePoll{}, errors.New("group coffee poll deadline has passed")
	}

	isParticipant := false
	for _, participant := range poll.ParticipantUserIDs {
		if participant == trimmedUserID {
			isParticipant = true
			break
		}
	}
	if !isParticipant {
		return groupCoffeePoll{}, errors.New("user is not a participant in this group coffee poll")
	}

	optionIndex := -1
	for index, option := range poll.Options {
		if option.ID == trimmedOptionID {
			optionIndex = index
			break
		}
	}
	if optionIndex < 0 {
		return groupCoffeePoll{}, errors.New("option_id is invalid")
	}

	votesByUser, ok := m.groupCoffeePollVotes[trimmedPollID]
	if !ok {
		votesByUser = make(map[string]string)
		m.groupCoffeePollVotes[trimmedPollID] = votesByUser
	}

	if previousOptionID, hasPrevious := votesByUser[trimmedUserID]; hasPrevious {
		if previousOptionID == trimmedOptionID {
			return poll, nil
		}
		for idx := range poll.Options {
			if poll.Options[idx].ID == previousOptionID && poll.Options[idx].VotesCount > 0 {
				poll.Options[idx].VotesCount--
				break
			}
		}
	}

	votesByUser[trimmedUserID] = trimmedOptionID
	poll.Options[optionIndex].VotesCount++
	m.groupCoffeePolls[trimmedPollID] = poll
	return poll, nil
}

func (m *memoryStore) finalizeGroupCoffeePoll(pollID, userID string, now time.Time) (groupCoffeePoll, groupCoffeePollOption, error) {
	trimmedPollID := strings.TrimSpace(pollID)
	trimmedUserID := strings.TrimSpace(userID)
	if trimmedPollID == "" || trimmedUserID == "" {
		return groupCoffeePoll{}, groupCoffeePollOption{}, errors.New("poll_id and user_id are required")
	}

	m.mu.Lock()
	defer m.mu.Unlock()

	poll, ok := m.groupCoffeePolls[trimmedPollID]
	if !ok {
		return groupCoffeePoll{}, groupCoffeePollOption{}, errors.New("group coffee poll not found")
	}
	if poll.CreatorUserID != trimmedUserID {
		return groupCoffeePoll{}, groupCoffeePollOption{}, errors.New("only creator can finalize group coffee poll")
	}
	if poll.Status == "finalized" {
		for _, option := range poll.Options {
			if option.ID == poll.FinalizedOptionID {
				return poll, option, nil
			}
		}
		return poll, groupCoffeePollOption{}, nil
	}

	selected := groupCoffeePollOption{}
	maxVotes := -1
	for _, option := range poll.Options {
		if option.VotesCount > maxVotes {
			selected = option
			maxVotes = option.VotesCount
		}
	}
	if selected.ID == "" {
		return groupCoffeePoll{}, groupCoffeePollOption{}, errors.New("group coffee poll has no options")
	}

	poll.Status = "finalized"
	poll.FinalizedOptionID = selected.ID
	poll.FinalizedAt = now.UTC().Format(time.RFC3339)
	m.groupCoffeePolls[trimmedPollID] = poll
	return poll, selected, nil
}

func (m *memoryStore) getGroupCoffeePoll(pollID string) (groupCoffeePoll, bool) {
	trimmedPollID := strings.TrimSpace(pollID)
	if trimmedPollID == "" {
		return groupCoffeePoll{}, false
	}

	m.mu.RLock()
	defer m.mu.RUnlock()

	poll, ok := m.groupCoffeePolls[trimmedPollID]
	if !ok {
		return groupCoffeePoll{}, false
	}

	pollCopy := poll
	pollCopy.ParticipantUserIDs = append([]string{}, poll.ParticipantUserIDs...)
	pollCopy.Options = append([]groupCoffeePollOption{}, poll.Options...)
	return pollCopy, true
}

func (m *memoryStore) listGroupCoffeePolls(userID, status string, limit int) []groupCoffeePoll {
	trimmedUserID := strings.TrimSpace(userID)
	trimmedStatus := strings.ToLower(strings.TrimSpace(status))
	if trimmedUserID == "" {
		return []groupCoffeePoll{}
	}
	if limit <= 0 {
		limit = 50
	} else if limit > 200 {
		limit = 200
	}

	m.mu.RLock()
	defer m.mu.RUnlock()

	out := make([]groupCoffeePoll, 0, len(m.groupCoffeePolls))
	for _, poll := range m.groupCoffeePolls {
		if trimmedStatus != "" && strings.ToLower(strings.TrimSpace(poll.Status)) != trimmedStatus {
			continue
		}
		included := false
		for _, participant := range poll.ParticipantUserIDs {
			if participant == trimmedUserID {
				included = true
				break
			}
		}
		if !included {
			continue
		}

		pollCopy := poll
		pollCopy.ParticipantUserIDs = append([]string{}, poll.ParticipantUserIDs...)
		pollCopy.Options = append([]groupCoffeePollOption{}, poll.Options...)
		out = append(out, pollCopy)
	}

	sort.Slice(out, func(i, j int) bool {
		return out[i].CreatedAt > out[j].CreatedAt
	})
	if len(out) > limit {
		out = out[:limit]
	}
	return out
}

func (m *memoryStore) finalizeActivityTimeoutIfNeededLocked(session *activitySession, now time.Time) {
	if session == nil {
		return
	}
	if session.Status != activitySessionStatusActive {
		return
	}
	expiresAt := parseRFC3339OrZero(session.ExpiresAt)
	if expiresAt.IsZero() || !now.After(expiresAt) {
		return
	}
	if len(session.ResponsesByUser) > 0 {
		session.Status = activitySessionStatusPartialTimeout
	} else {
		session.Status = activitySessionStatusTimedOut
	}
	session.TimedOutAt = now.Format(time.RFC3339)
	session.Summary = m.buildActivitySummaryLocked(*session, now)
}

func (m *memoryStore) buildActivitySummaryLocked(session activitySession, now time.Time) activitySessionSummary {
	completed := make([]string, 0, len(session.ResponsesByUser))
	pending := make([]string, 0, len(session.ParticipantIDs))
	for _, userID := range session.ParticipantIDs {
		if len(session.ResponsesByUser[userID]) > 0 {
			completed = append(completed, userID)
			continue
		}
		pending = append(pending, userID)
	}

	insight := "No responses were submitted."
	if len(completed) == len(session.ParticipantIDs) && len(completed) > 0 {
		insight = "Both participants completed the activity session."
	} else if len(completed) > 0 {
		insight = "Partial completion captured before the session closed."
	}

	return activitySessionSummary{
		SessionID:             session.ID,
		MatchID:               session.MatchID,
		Status:                session.Status,
		TotalParticipants:     len(session.ParticipantIDs),
		ResponsesSubmitted:    len(session.ResponsesByUser),
		ParticipantsCompleted: completed,
		ParticipantsPending:   pending,
		Insight:               insight,
		GeneratedAt:           now.Format(time.RFC3339),
	}
}

func (m *memoryStore) startVideoCall(matchID, initiatorID, recipientID string) (videoCallSession, error) {
	initiatorID = strings.TrimSpace(initiatorID)
	recipientID = strings.TrimSpace(recipientID)
	if initiatorID == "" || recipientID == "" {
		return videoCallSession{}, errors.New("initiator_id and recipient_id are required")
	}
	if initiatorID == recipientID {
		return videoCallSession{}, errors.New("initiator and recipient cannot be the same")
	}

	now := time.Now().UTC().Format(time.RFC3339)
	m.mu.Lock()
	defer m.mu.Unlock()

	m.activitySeq++
	callID := fmt.Sprintf("call-%d", m.activitySeq)
	session := videoCallSession{
		ID:          callID,
		MatchID:     strings.TrimSpace(matchID),
		InitiatorID: initiatorID,
		RecipientID: recipientID,
		Status:      "connected",
		RoomID:      "room-" + callID,
		StartedAt:   now,
	}
	m.calls[callID] = session
	return session, nil
}

func (m *memoryStore) endVideoCall(callID, endedBy string) (videoCallSession, error) {
	callID = strings.TrimSpace(callID)
	if callID == "" {
		return videoCallSession{}, errors.New("call_id is required")
	}

	m.mu.Lock()
	defer m.mu.Unlock()

	session, ok := m.calls[callID]
	if !ok {
		return videoCallSession{}, errors.New("call not found")
	}
	if session.Status == "ended" {
		return session, nil
	}

	startedAt, _ := time.Parse(time.RFC3339, session.StartedAt)
	now := time.Now().UTC()
	duration := int(now.Sub(startedAt).Seconds())
	if duration < 0 {
		duration = 0
	}

	session.Status = "ended"
	session.EndedAt = now.Format(time.RFC3339)
	session.DurationSec = duration
	session.EndedByUserID = strings.TrimSpace(endedBy)
	m.calls[callID] = session
	return session, nil
}

func (m *memoryStore) listVideoCalls(userID string, limit int) []videoCallSession {
	userID = strings.TrimSpace(userID)
	if limit <= 0 || limit > 500 {
		limit = 100
	}

	m.mu.RLock()
	defer m.mu.RUnlock()

	out := make([]videoCallSession, 0, len(m.calls))
	for _, item := range m.calls {
		if item.InitiatorID == userID || item.RecipientID == userID {
			out = append(out, item)
		}
	}
	sort.Slice(out, func(i, j int) bool {
		return out[i].StartedAt > out[j].StartedAt
	})
	if len(out) > limit {
		out = out[:limit]
	}
	return out
}

func (m *memoryStore) createSOSAlert(
	userID, matchID, level, message string,
	latitude, longitude float64,
) (sosAlert, error) {
	userID = strings.TrimSpace(userID)
	if userID == "" {
		return sosAlert{}, errors.New("user_id is required")
	}
	normalizedLevel := strings.ToLower(strings.TrimSpace(level))
	if normalizedLevel == "" {
		normalizedLevel = "high"
	}
	if normalizedLevel != "low" && normalizedLevel != "medium" && normalizedLevel != "high" {
		return sosAlert{}, errors.New("emergency_level must be low, medium, or high")
	}

	m.mu.Lock()
	defer m.mu.Unlock()

	for _, item := range m.sosAlerts {
		if item.UserID == userID && item.Status == "active" {
			return sosAlert{}, errors.New("active sos alert already exists for user")
		}
	}

	m.activitySeq++
	alertID := fmt.Sprintf("sos-%d", m.activitySeq)
	now := time.Now().UTC().Format(time.RFC3339)
	alert := sosAlert{
		ID:             alertID,
		UserID:         userID,
		MatchID:        strings.TrimSpace(matchID),
		Latitude:       latitude,
		Longitude:      longitude,
		Message:        strings.TrimSpace(message),
		EmergencyLevel: normalizedLevel,
		Status:         "active",
		TriggeredAt:    now,
	}
	m.sosAlerts[alertID] = alert
	return alert, nil
}

func (m *memoryStore) resolveSOSAlert(alertID, resolvedBy, note string) (sosAlert, error) {
	alertID = strings.TrimSpace(alertID)
	if alertID == "" {
		return sosAlert{}, errors.New("alert_id is required")
	}

	m.mu.Lock()
	defer m.mu.Unlock()

	alert, ok := m.sosAlerts[alertID]
	if !ok {
		return sosAlert{}, errors.New("sos alert not found")
	}
	if alert.Status == "resolved" {
		return alert, nil
	}
	alert.Status = "resolved"
	alert.ResolvedAt = time.Now().UTC().Format(time.RFC3339)
	alert.ResolvedBy = strings.TrimSpace(resolvedBy)
	alert.ResolutionNote = strings.TrimSpace(note)
	m.sosAlerts[alertID] = alert
	return alert, nil
}

func (m *memoryStore) listSOSAlerts(userID string, limit int) []sosAlert {
	userID = strings.TrimSpace(userID)
	if limit <= 0 || limit > 500 {
		limit = 100
	}

	m.mu.RLock()
	defer m.mu.RUnlock()

	out := make([]sosAlert, 0, len(m.sosAlerts))
	for _, alert := range m.sosAlerts {
		if userID != "" && alert.UserID != userID {
			continue
		}
		out = append(out, alert)
	}
	sort.Slice(out, func(i, j int) bool {
		return out[i].TriggeredAt > out[j].TriggeredAt
	})
	if len(out) > limit {
		out = out[:limit]
	}
	return out
}

func (m *memoryStore) listSubscriptionPlans() []subscriptionPlan {
	m.mu.RLock()
	defer m.mu.RUnlock()
	out := make([]subscriptionPlan, len(m.plans))
	copy(out, m.plans)
	return out
}

func (m *memoryStore) getSubscription(userID string) userSubscription {
	userID = strings.TrimSpace(userID)
	m.mu.RLock()
	defer m.mu.RUnlock()
	if sub, ok := m.subscriptions[userID]; ok {
		return sub
	}
	now := time.Now().UTC().Format(time.RFC3339)
	return userSubscription{
		ID:              "sub-free-" + userID,
		UserID:          userID,
		PlanID:          "free",
		PlanName:        "Free",
		Status:          "active",
		BillingCycle:    "monthly",
		StartDate:       now,
		NextBillingDate: now,
		UpdatedAt:       now,
	}
}

func (m *memoryStore) subscribe(userID, planID, billingCycle string) (userSubscription, paymentRecord, error) {
	userID = strings.TrimSpace(userID)
	planID = strings.TrimSpace(planID)
	billingCycle = strings.ToLower(strings.TrimSpace(billingCycle))
	if userID == "" || planID == "" {
		return userSubscription{}, paymentRecord{}, errors.New("user_id and plan_id are required")
	}
	if billingCycle == "" {
		billingCycle = "monthly"
	}
	if billingCycle != "monthly" && billingCycle != "yearly" {
		return userSubscription{}, paymentRecord{}, errors.New("billing_cycle must be monthly or yearly")
	}

	m.mu.Lock()
	defer m.mu.Unlock()

	var selected *subscriptionPlan
	for i := range m.plans {
		if m.plans[i].ID == planID && m.plans[i].IsActive {
			selected = &m.plans[i]
			break
		}
	}
	if selected == nil {
		return userSubscription{}, paymentRecord{}, errors.New("subscription plan not found")
	}

	now := time.Now().UTC()
	next := now.AddDate(0, 1, 0)
	amount := selected.MonthlyPrice
	if billingCycle == "yearly" {
		next = now.AddDate(1, 0, 0)
		amount = selected.YearlyPrice
	}

	m.activitySeq++
	subID := fmt.Sprintf("sub-%d", m.activitySeq)
	sub := userSubscription{
		ID:              subID,
		UserID:          userID,
		PlanID:          selected.ID,
		PlanName:        selected.Name,
		Status:          "active",
		BillingCycle:    billingCycle,
		StartDate:       now.Format(time.RFC3339),
		NextBillingDate: next.Format(time.RFC3339),
		UpdatedAt:       now.Format(time.RFC3339),
	}
	m.subscriptions[userID] = sub

	m.activitySeq++
	payment := paymentRecord{
		ID:            fmt.Sprintf("pay-%d", m.activitySeq),
		UserID:        userID,
		PlanID:        selected.ID,
		Amount:        amount,
		Currency:      "INR",
		Status:        "completed",
		PaymentMethod: "mock",
		CreatedAt:     now.Format(time.RFC3339),
	}
	m.payments[userID] = append(m.payments[userID], payment)
	return sub, payment, nil
}

func (m *memoryStore) listPayments(userID string, limit int) []paymentRecord {
	userID = strings.TrimSpace(userID)
	if limit <= 0 || limit > 500 {
		limit = 100
	}
	m.mu.RLock()
	defer m.mu.RUnlock()
	items := m.payments[userID]
	if len(items) == 0 {
		return []paymentRecord{}
	}
	out := make([]paymentRecord, 0, len(items))
	for i := len(items) - 1; i >= 0; i-- {
		out = append(out, items[i])
	}
	if len(out) > limit {
		out = out[:limit]
	}
	return out
}

func (m *memoryStore) billingCoexistenceMatrix() map[string]any {
	matrixVersion := "2026-03-03"
	coreProgressionFeatures := []string{
		"quest_unlock_workflow",
		"chat_after_unlock",
		"digital_gestures",
		"mini_activities",
		"trust_badges",
		"conversation_rooms",
	}
	monetizedFeatures := []monetizationMatrixItem{
		{
			FeatureCode:           "profile_boosts",
			Category:              "visibility",
			Access:                "premium_optional",
			RequiresSubscription:  true,
			BlocksCoreProgression: false,
			Description:           "Increase profile discovery reach.",
		},
		{
			FeatureCode:           "cosmetic_personalization",
			Category:              "cosmetics",
			Access:                "premium_optional",
			RequiresSubscription:  true,
			BlocksCoreProgression: false,
			Description:           "Profile themes and cosmetic enhancements.",
		},
		{
			FeatureCode:           "advanced_analytics",
			Category:              "insights",
			Access:                "premium_optional",
			RequiresSubscription:  true,
			BlocksCoreProgression: false,
			Description:           "Enhanced engagement and trend insights.",
		},
	}

	out := make([]map[string]any, 0, len(monetizedFeatures))
	for _, item := range monetizedFeatures {
		out = append(out, map[string]any{
			"feature_code":            item.FeatureCode,
			"category":                item.Category,
			"access":                  item.Access,
			"requires_subscription":   item.RequiresSubscription,
			"blocks_core_progression": item.BlocksCoreProgression,
			"description":             item.Description,
		})
	}

	return map[string]any{
		"matrix_version":                matrixVersion,
		"core_progression_non_blocking": true,
		"core_progression_features":     coreProgressionFeatures,
		"monetized_features":            out,
	}
}

func (m *memoryStore) createReport(
	reporterUserID, reportedUserID, reason, description string,
) (moderationReport, error) {
	reporterUserID = strings.TrimSpace(reporterUserID)
	reportedUserID = strings.TrimSpace(reportedUserID)
	reason = strings.TrimSpace(reason)
	if reportedUserID == "" || reason == "" {
		return moderationReport{}, errors.New("reported_user_id and reason are required")
	}
	if reporterUserID == "" {
		reporterUserID = "unknown-reporter"
	}

	m.mu.Lock()
	defer m.mu.Unlock()

	m.activitySeq++
	report := moderationReport{
		ID:             fmt.Sprintf("rep-%d", m.activitySeq),
		ReporterUserID: reporterUserID,
		ReportedUserID: reportedUserID,
		Reason:         reason,
		Description:    strings.TrimSpace(description),
		Status:         "pending",
		CreatedAt:      time.Now().UTC().Format(time.RFC3339),
	}
	m.reports = append(m.reports, report)
	return report, nil
}

func (m *memoryStore) listReports(status string, limit int) []moderationReport {
	if limit <= 0 || limit > 500 {
		limit = 100
	}
	normalized := strings.ToLower(strings.TrimSpace(status))

	m.mu.RLock()
	defer m.mu.RUnlock()

	out := make([]moderationReport, 0, len(m.reports))
	for _, item := range m.reports {
		if normalized != "" && strings.ToLower(item.Status) != normalized {
			continue
		}
		out = append(out, item)
	}
	sort.Slice(out, func(i, j int) bool { return out[i].CreatedAt > out[j].CreatedAt })
	if len(out) > limit {
		out = out[:limit]
	}
	return out
}

func (m *memoryStore) actionReport(
	reportID, status, action, reviewedBy string,
) (moderationReport, error) {
	reportID = strings.TrimSpace(reportID)
	status = strings.ToLower(strings.TrimSpace(status))
	if reportID == "" || status == "" {
		return moderationReport{}, errors.New("report_id and status are required")
	}
	allowed := map[string]struct{}{
		"pending":      {},
		"under_review": {},
		"resolved":     {},
		"rejected":     {},
	}
	if _, ok := allowed[status]; !ok {
		return moderationReport{}, errors.New("invalid report status")
	}

	m.mu.Lock()
	defer m.mu.Unlock()

	for i := range m.reports {
		if m.reports[i].ID != reportID {
			continue
		}
		m.reports[i].Status = status
		m.reports[i].Action = strings.TrimSpace(action)
		m.reports[i].ReviewedBy = strings.TrimSpace(reviewedBy)
		m.reports[i].ReviewedAt = time.Now().UTC().Format(time.RFC3339)
		return m.reports[i], nil
	}
	return moderationReport{}, errors.New("report not found")
}

func (m *memoryStore) submitModerationAppeal(
	userID, reportID, reason, description string,
) (moderationAppeal, error) {
	trimmedUserID := strings.TrimSpace(userID)
	trimmedReason := strings.TrimSpace(reason)
	if trimmedUserID == "" || trimmedReason == "" {
		return moderationAppeal{}, errors.New("user_id and reason are required")
	}

	now := time.Now().UTC()

	m.mu.Lock()
	defer m.mu.Unlock()

	m.activitySeq++
	appeal := moderationAppeal{
		ID:                 fmt.Sprintf("apl-%d", m.activitySeq),
		UserID:             trimmedUserID,
		ReportID:           strings.TrimSpace(reportID),
		Reason:             trimmedReason,
		Description:        strings.TrimSpace(description),
		Status:             appealStatusSubmitted,
		SLADeadlineAt:      now.Add(appealSLADuration).Format(time.RFC3339),
		NotificationPolicy: "status_change_email_and_inbox",
		CreatedAt:          now.Format(time.RFC3339),
		UpdatedAt:          now.Format(time.RFC3339),
	}
	m.appeals = append(m.appeals, appeal)
	return appeal, nil
}

func (m *memoryStore) getModerationAppeal(appealID, requesterUserID string, admin bool) (moderationAppeal, error) {
	trimmedAppealID := strings.TrimSpace(appealID)
	if trimmedAppealID == "" {
		return moderationAppeal{}, errors.New("appeal_id is required")
	}
	trimmedRequester := strings.TrimSpace(requesterUserID)

	m.mu.RLock()
	defer m.mu.RUnlock()

	for _, item := range m.appeals {
		if item.ID != trimmedAppealID {
			continue
		}
		if admin || trimmedRequester == "" || item.UserID == trimmedRequester {
			return item, nil
		}
		return moderationAppeal{}, errors.New("appeal not found")
	}

	return moderationAppeal{}, errors.New("appeal not found")
}

func (m *memoryStore) listModerationAppeals(status string, limit int) []moderationAppeal {
	if limit <= 0 || limit > 500 {
		limit = 100
	}
	normalized := strings.ToLower(strings.TrimSpace(status))

	m.mu.RLock()
	defer m.mu.RUnlock()

	out := make([]moderationAppeal, 0, len(m.appeals))
	for _, item := range m.appeals {
		if normalized != "" && strings.ToLower(item.Status) != normalized {
			continue
		}
		out = append(out, item)
	}
	sort.Slice(out, func(i, j int) bool { return out[i].CreatedAt > out[j].CreatedAt })
	if len(out) > limit {
		out = out[:limit]
	}
	return out
}

func (m *memoryStore) listModerationAppealsForUser(userID, status string, limit int) []moderationAppeal {
	trimmedUserID := strings.TrimSpace(userID)
	if trimmedUserID == "" {
		return []moderationAppeal{}
	}
	if limit <= 0 || limit > 500 {
		limit = 100
	}
	normalized := strings.ToLower(strings.TrimSpace(status))

	m.mu.RLock()
	defer m.mu.RUnlock()

	out := make([]moderationAppeal, 0, len(m.appeals))
	for _, item := range m.appeals {
		if item.UserID != trimmedUserID {
			continue
		}
		if normalized != "" && strings.ToLower(item.Status) != normalized {
			continue
		}
		out = append(out, item)
	}
	sort.Slice(out, func(i, j int) bool { return out[i].CreatedAt > out[j].CreatedAt })
	if len(out) > limit {
		out = out[:limit]
	}
	return out
}

func (m *memoryStore) actionModerationAppeal(
	appealID, status, resolutionReason, reviewedBy string,
) (moderationAppeal, error) {
	trimmedAppealID := strings.TrimSpace(appealID)
	normalizedStatus := strings.ToLower(strings.TrimSpace(status))
	if trimmedAppealID == "" || normalizedStatus == "" {
		return moderationAppeal{}, errors.New("appeal_id and status are required")
	}
	allowed := map[string]struct{}{
		appealStatusSubmitted:       {},
		appealStatusUnderReview:     {},
		appealStatusResolvedUpheld:  {},
		appealStatusResolvedReverse: {},
	}
	if _, ok := allowed[normalizedStatus]; !ok {
		return moderationAppeal{}, errors.New("invalid appeal status")
	}

	now := time.Now().UTC().Format(time.RFC3339)

	m.mu.Lock()
	defer m.mu.Unlock()

	for i := range m.appeals {
		if m.appeals[i].ID != trimmedAppealID {
			continue
		}
		m.appeals[i].Status = normalizedStatus
		m.appeals[i].ResolutionReason = strings.TrimSpace(resolutionReason)
		m.appeals[i].ReviewedBy = strings.TrimSpace(reviewedBy)
		m.appeals[i].ReviewedAt = now
		m.appeals[i].UpdatedAt = now
		return m.appeals[i], nil
	}

	return moderationAppeal{}, errors.New("appeal not found")
}

func (m *memoryStore) userAnalytics(userID string) map[string]any {
	userID = strings.TrimSpace(userID)
	m.mu.RLock()
	defer m.mu.RUnlock()

	profileUpdates := 0
	swipes := 0
	messages := 0
	reportsFiled := 0
	reportsAgainst := 0
	for _, evt := range m.activities {
		if evt.UserID != userID {
			continue
		}
		if strings.Contains(evt.Resource, "/profile/") {
			profileUpdates++
		}
		if strings.HasSuffix(evt.Resource, "/swipe") {
			swipes++
		}
		if strings.Contains(evt.Resource, "/chat/") {
			messages++
		}
	}
	for _, rep := range m.reports {
		if rep.ReporterUserID == userID {
			reportsFiled++
		}
		if rep.ReportedUserID == userID {
			reportsAgainst++
		}
	}
	activeSOS := 0
	for _, alert := range m.sosAlerts {
		if alert.UserID == userID && alert.Status == "active" {
			activeSOS++
		}
	}
	subscription := m.getSubscription(userID)
	return map[string]any{
		"user_id":           userID,
		"profile_updates":   profileUpdates,
		"swipes":            swipes,
		"messages":          messages,
		"reports_filed":     reportsFiled,
		"reports_against":   reportsAgainst,
		"active_sos_alerts": activeSOS,
		"plan_name":         subscription.PlanName,
		"plan_id":           subscription.PlanID,
	}
}

func (m *memoryStore) adminAnalyticsOverview() map[string]any {
	m.mu.RLock()
	defer m.mu.RUnlock()

	verificationPending := 0
	for _, item := range m.verification {
		if item.Status == "pending" {
			verificationPending++
		}
	}

	reportsPending := 0
	for _, item := range m.reports {
		if item.Status == "pending" || item.Status == "under_review" {
			reportsPending++
		}
	}

	appealsPending := 0
	appealsUnderReview := 0
	appealsResolved := 0
	appealNotificationsConfigured := 0
	for _, appeal := range m.appeals {
		switch appeal.Status {
		case appealStatusSubmitted:
			appealsPending++
		case appealStatusUnderReview:
			appealsUnderReview++
		case appealStatusResolvedUpheld, appealStatusResolvedReverse:
			appealsResolved++
		}
		if strings.TrimSpace(appeal.NotificationPolicy) != "" {
			appealNotificationsConfigured++
		}
	}

	activeSOS := 0
	for _, item := range m.sosAlerts {
		if item.Status == "active" {
			activeSOS++
		}
	}

	paidSubs := 0
	for _, sub := range m.subscriptions {
		if sub.PlanID != "free" && sub.Status == "active" {
			paidSubs++
		}
	}

	unlockAttempts := 0
	unlockCompletions := 0
	unlockAttemptsByPolicy := map[string]int{}
	chatLocksByPolicy := map[string]int{}
	billingEventCount := 0
	billingPolicyDimensionCount := 0
	for _, workflow := range m.questWorkflows {
		if workflow.AttemptCount > 0 {
			unlockAttempts += workflow.AttemptCount
		}
		if workflow.Status == questWorkflowStatusApproved || workflow.UnlockState == "conversation_unlocked" {
			unlockCompletions++
		}
	}
	for _, event := range m.activities {
		variant := strings.TrimSpace(toString(event.Details["unlock_policy_variant"]))
		resource := strings.ToLower(strings.TrimSpace(event.Resource))
		action := strings.ToLower(strings.TrimSpace(event.Action))
		if strings.Contains(resource, "/billing/") {
			billingEventCount++
			if strings.TrimSpace(toString(event.Details["monetization_matrix_version"])) != "" {
				billingPolicyDimensionCount++
			}
		}
		if variant == "" {
			continue
		}
		if strings.Contains(resource, "/quest-workflow/submit") {
			unlockAttemptsByPolicy[variant]++
		}
		if action == "chat.locked" {
			chatLocksByPolicy[variant]++
		}
	}

	totalGestures := 0
	acceptedGestures := 0
	for _, gestures := range m.matchGestures {
		for _, gesture := range gestures {
			if gesture.Status == "sent" {
				continue
			}
			totalGestures++
			if gesture.Status == "appreciated" {
				acceptedGestures++
			}
		}
	}

	totalActivities := len(m.activitySessions)
	completedActivities := 0
	for _, session := range m.activitySessions {
		if session.Status == activitySessionStatusCompleted {
			completedActivities++
		}
	}

	totalDailyPromptAnswers := 0
	activePromptStreakUsers := 0
	for _, answersByDate := range m.dailyPromptAnswers {
		totalDailyPromptAnswers += len(answersByDate)
	}
	for _, streak := range m.dailyPromptStreaks {
		if streak.CurrentDays > 0 {
			activePromptStreakUsers++
		}
	}

	totalReports := len(m.reports)
	interactionCount := len(m.activities)
	reportRatePerThousand := 0.0
	if interactionCount > 0 {
		reportRatePerThousand = float64(totalReports) * 1000.0 / float64(interactionCount)
	}

	featureFlags := map[string]bool{
		"engagement_unlock_mvp":  m.cfg.FeatureEngagementUnlockMVP,
		"digital_gestures":       m.cfg.FeatureDigitalGestures,
		"mini_activities":        m.cfg.FeatureMiniActivities,
		"trust_badges":           m.cfg.FeatureTrustBadges,
		"conversation_rooms":     m.cfg.FeatureConversationRooms,
		"experiment_framework":   m.cfg.FeatureExperimentFramework,
		"experiment_match_nudge": m.cfg.FeatureExperimentMatchNudge,
	}

	funnelMetrics := map[string]any{
		"unlock_attempt_count":             unlockAttempts,
		"unlock_completion_count":          unlockCompletions,
		"unlock_completion_rate":           safeRatePercent(unlockCompletions, unlockAttempts),
		"unlock_attempt_count_by_policy":   unlockAttemptsByPolicy,
		"chat_lock_count_by_policy":        chatLocksByPolicy,
		"gesture_decision_count":           totalGestures,
		"gesture_acceptance_count":         acceptedGestures,
		"gesture_acceptance_rate":          safeRatePercent(acceptedGestures, totalGestures),
		"activity_session_count":           totalActivities,
		"activity_completion_count":        completedActivities,
		"activity_completion_rate":         safeRatePercent(completedActivities, totalActivities),
		"daily_prompt_answer_count":        totalDailyPromptAnswers,
		"daily_prompt_active_streak_users": activePromptStreakUsers,
		"report_count":                     totalReports,
		"interaction_count":                interactionCount,
		"report_rate_per_1k_interactions":  reportRatePerThousand,
		"appeal_resolution_count":          appealsResolved,
	}

	dashboardPanels := []string{
		"unlock_completion_rate",
		"unlock_attempt_count_by_policy",
		"chat_lock_count_by_policy",
		"gesture_acceptance_rate",
		"activity_completion_rate",
		"daily_prompt_answer_count",
		"report_rate_per_1k_interactions",
		"appeal_resolution_count",
	}

	eventTaxonomy := map[string]any{
		"version": "engagement_unlock.v2026-03-03",
		"events": []map[string]any{
			{
				"name":                "quest.submit",
				"required_properties": []string{"match_id", "submitter_user_id", "unlock_policy_variant"},
			},
			{
				"name":                "quest.review.auto",
				"required_properties": []string{"match_id", "decision_status", "review_reason"},
			},
			{
				"name":                "chat.locked",
				"required_properties": []string{"match_id", "unlock_state", "unlock_policy_variant"},
			},
			{
				"name":                "appeal.submitted",
				"required_properties": []string{"appeal_id", "user_id", "status", "sla_deadline_at"},
			},
			{
				"name":                "appeal.resolved",
				"required_properties": []string{"appeal_id", "status", "reviewed_by"},
			},
			{
				"name":                "daily_prompt_viewed",
				"required_properties": []string{"user_id", "prompt_id", "prompt_date"},
			},
			{
				"name":                "daily_prompt_answer_submitted",
				"required_properties": []string{"user_id", "prompt_id", "prompt_date", "current_streak_days"},
			},
			{
				"name":                "daily_prompt_streak_milestone",
				"required_properties": []string{"user_id", "streak_days", "milestone"},
			},
			{
				"name":                "match_nudge_sent",
				"required_properties": []string{"match_id", "user_id", "nudge_type"},
			},
			{
				"name":                "match_nudge_clicked",
				"required_properties": []string{"match_id", "user_id", "nudge_type"},
			},
			{
				"name":                "conversation_resumed",
				"required_properties": []string{"match_id", "user_id"},
			},
			{
				"name":                "circle_challenge_viewed",
				"required_properties": []string{"circle_id", "user_id", "challenge_id"},
			},
			{
				"name":                "circle_challenge_submitted",
				"required_properties": []string{"circle_id", "user_id", "challenge_id"},
			},
			{
				"name":                "voice_icebreaker_started",
				"required_properties": []string{"match_id", "user_id", "prompt_id"},
			},
			{
				"name":                "voice_icebreaker_sent",
				"required_properties": []string{"match_id", "user_id", "prompt_id", "duration_seconds"},
			},
			{
				"name":                "voice_icebreaker_played",
				"required_properties": []string{"match_id", "user_id", "icebreaker_id"},
			},
			{
				"name":                "intro_event_created",
				"required_properties": []string{"intro_event_id", "user_id", "event_type"},
			},
			{
				"name":                "intro_event_voted",
				"required_properties": []string{"intro_event_id", "user_id", "option_id", "event_type"},
			},
			{
				"name":                "intro_event_finalized",
				"required_properties": []string{"intro_event_id", "user_id", "selected_option_id", "event_type"},
			},
		},
	}

	dataQualityChecks := map[string]any{
		"staging_event_completeness": map[string]any{
			"unlock_policy_variant_coverage_pct": safeRatePercent(
				billingPolicyDimensionCount,
				billingEventCount,
			),
			"appeal_notification_policy_coverage_pct": safeRatePercent(
				appealNotificationsConfigured,
				len(m.appeals),
			),
			"checks_passed": appealNotificationsConfigured == len(m.appeals),
		},
	}

	matrix := m.billingCoexistenceMatrix()
	monetizedItems, _ := matrix["monetized_features"].([]map[string]any)
	if monetizedItems == nil {
		if generic, ok := matrix["monetized_features"].([]any); ok {
			monetizedItems = make([]map[string]any, 0, len(generic))
			for _, item := range generic {
				if typed, ok := item.(map[string]any); ok {
					monetizedItems = append(monetizedItems, typed)
				}
			}
		}
	}
	blockedFeatureCodes := make([]string, 0, len(monetizedItems))
	for _, item := range monetizedItems {
		if blocked, _ := item["blocks_core_progression"].(bool); blocked {
			featureCode := strings.TrimSpace(toString(item["feature_code"]))
			if featureCode != "" {
				blockedFeatureCodes = append(blockedFeatureCodes, featureCode)
			}
		}
	}

	policyCompliance := map[string]any{
		"matrix_version":                    strings.TrimSpace(toString(matrix["matrix_version"])),
		"core_progression_non_blocking":     matrix["core_progression_non_blocking"] == true,
		"blocked_core_feature_count":        len(blockedFeatureCodes),
		"blocked_core_feature_codes":        blockedFeatureCodes,
		"billing_event_count":               billingEventCount,
		"billing_policy_dimension_coverage": safeRatePercent(billingPolicyDimensionCount, billingEventCount),
	}

	return map[string]any{
		"pending_verifications":          verificationPending,
		"pending_reports":                reportsPending,
		"pending_appeals":                appealsPending,
		"appeals_under_review":           appealsUnderReview,
		"active_sos_alerts":              activeSOS,
		"active_paid_subs":               paidSubs,
		"unlock_policy_variant":          m.unlockPolicyVariant(),
		"dashboard_panels":               dashboardPanels,
		"event_taxonomy":                 eventTaxonomy,
		"data_quality_checks":            dataQualityChecks,
		"monetization_policy_compliance": policyCompliance,
		"feature_flags":                  featureFlags,
		"funnel_metrics":                 funnelMetrics,
		"total_calls":                    len(m.calls),
		"total_payments": func() int {
			total := 0
			for _, items := range m.payments {
				total += len(items)
			}
			return total
		}(),
	}
}

func safeRatePercent(numerator, denominator int) float64 {
	if denominator <= 0 || numerator <= 0 {
		return 0
	}
	return (float64(numerator) / float64(denominator)) * 100.0
}

func circleChallengeForWeek(circleID string, now time.Time) (circleChallenge, error) {
	template, ok := circleChallengeTemplates[strings.TrimSpace(circleID)]
	if !ok {
		return circleChallenge{}, errors.New("circle not found")
	}

	utcNow := now.UTC()
	year, week := utcNow.ISOWeek()
	weekKey := fmt.Sprintf("%d-W%02d", year, week)
	startsAt := startOfISOWeekUTC(utcNow)
	endsAt := startsAt.AddDate(0, 0, 7).Add(-1 * time.Second)

	return circleChallenge{
		ID:                 fmt.Sprintf("%s-%s", strings.TrimSpace(circleID), weekKey),
		CircleID:           strings.TrimSpace(circleID),
		City:               template.City,
		Topic:              template.Topic,
		PromptText:         template.Prompt,
		WeekKey:            weekKey,
		StartsAt:           startsAt.Format(time.RFC3339),
		EndsAt:             endsAt.Format(time.RFC3339),
		ParticipationCount: 0,
	}, nil
}

func startOfISOWeekUTC(now time.Time) time.Time {
	utcNow := now.UTC()
	weekday := int(utcNow.Weekday())
	if weekday == 0 {
		weekday = 7
	}
	start := utcNow.AddDate(0, 0, -(weekday - 1))
	return time.Date(start.Year(), start.Month(), start.Day(), 0, 0, 0, 0, time.UTC)
}

func resolveVoiceIcebreakerPrompt(promptID string) voiceIcebreakerPrompt {
	trimmedPromptID := strings.TrimSpace(promptID)
	if trimmedPromptID == "" {
		if len(voiceIcebreakerPromptCatalog) > 0 {
			return voiceIcebreakerPromptCatalog[0]
		}
		return voiceIcebreakerPrompt{}
	}

	for _, item := range voiceIcebreakerPromptCatalog {
		if item.ID == trimmedPromptID {
			return item
		}
	}
	return voiceIcebreakerPrompt{}
}

func dailyPromptForDate(now time.Time) dailyPrompt {
	dateKey := now.UTC().Format("2006-01-02")
	index := 0
	if len(dailyPromptPool) > 0 {
		hash := 0
		for _, char := range dateKey {
			hash += int(char)
		}
		index = hash % len(dailyPromptPool)
	}
	template := dailyPromptTemplate{
		Code:   "values_default",
		Domain: "values",
		Text:   "What is one value you practiced today?",
	}
	if len(dailyPromptPool) > 0 {
		template = dailyPromptPool[index]
	}
	return dailyPrompt{
		ID:           fmt.Sprintf("daily-%s-%s", dateKey, template.Code),
		PromptDate:   dateKey,
		Domain:       template.Domain,
		PromptText:   template.Text,
		MinChars:     dailyPromptMinChars,
		MaxChars:     dailyPromptMaxChars,
		ResponseMode: "text",
	}
}

func nextDailyPromptMilestone(currentDays int) int {
	for _, milestone := range dailyPromptMilestones {
		if currentDays < milestone {
			return milestone
		}
	}
	return 0
}

func normalizeDailyPromptStreak(streak dailyPromptStreak) dailyPromptStreak {
	out := streak
	out.NextMilestone = nextDailyPromptMilestone(streak.CurrentDays)
	return out
}

func normalizeDailyPromptAnswer(answer string) string {
	trimmed := strings.TrimSpace(strings.ToLower(answer))
	if trimmed == "" {
		return ""
	}

	var builder strings.Builder
	builder.Grow(len(trimmed))
	lastWasSpace := false
	for _, char := range trimmed {
		if unicode.IsLetter(char) || unicode.IsNumber(char) {
			builder.WriteRune(char)
			lastWasSpace = false
			continue
		}
		if unicode.IsSpace(char) {
			if !lastWasSpace {
				builder.WriteRune(' ')
				lastWasSpace = true
			}
		}
	}
	return strings.TrimSpace(builder.String())
}

func defaultSubscriptionPlans() []subscriptionPlan {
	return []subscriptionPlan{
		{
			ID:             "free",
			Name:           "Free",
			MonthlyPrice:   0,
			YearlyPrice:    0,
			LikesPerDay:    15,
			MessagesPerDay: 30,
			Features: []string{
				"Basic discovery",
				"Standard messaging",
			},
			IsActive: true,
		},
		{
			ID:             "premium",
			Name:           "Premium",
			MonthlyPrice:   499,
			YearlyPrice:    4990,
			LikesPerDay:    100,
			MessagesPerDay: 500,
			Features: []string{
				"Advanced filters",
				"Priority profile boost",
				"Read receipts",
			},
			IsActive: true,
		},
		{
			ID:             "vip",
			Name:           "VIP",
			MonthlyPrice:   999,
			YearlyPrice:    9990,
			LikesPerDay:    500,
			MessagesPerDay: 2000,
			Features: []string{
				"Everything in Premium",
				"Profile concierge",
				"Priority support",
			},
			IsActive: true,
		},
	}
}

func defaultDraft(userID string) profileDraft {
	return profileDraft{
		UserID:            userID,
		Gender:            "M",
		Photos:            []profilePhoto{},
		SeekingGenders:    []string{"M", "F"},
		MinAgeYears:       18,
		MaxAgeYears:       60,
		MaxDistanceKm:     50,
		EducationFilter:   []string{},
		SeriousOnly:       true,
		VerifiedOnly:      false,
		Hobbies:           []string{},
		FavoriteBooks:     []string{},
		FavoriteNovels:    []string{},
		FavoriteSongs:     []string{},
		ExtraCurriculars:  []string{},
		IntentTags:        []string{},
		LanguageTags:      []string{},
		DealBreakerTags:   []string{},
		Drinking:          "Never",
		Smoking:           "Never",
		HookupOnly:        false,
		ProfileCompletion: 0,
	}
}

func defaultSettings(userID string) userSettings {
	return userSettings{
		UserID:            userID,
		ShowAge:           true,
		ShowExactDistance: false,
		ShowOnlineStatus:  true,
		NotifyNewMatch:    true,
		NotifyNewMessage:  true,
		NotifyLikes:       true,
		Theme:             "auto",
		UpdatedAt:         time.Now().UTC().Format(time.RFC3339),
	}
}

func copyDraft(in profileDraft) profileDraft {
	out := in
	out.Photos = append([]profilePhoto{}, in.Photos...)
	out.SeekingGenders = append([]string{}, in.SeekingGenders...)
	out.EducationFilter = append([]string{}, in.EducationFilter...)
	out.Hobbies = append([]string{}, in.Hobbies...)
	out.FavoriteBooks = append([]string{}, in.FavoriteBooks...)
	out.FavoriteNovels = append([]string{}, in.FavoriteNovels...)
	out.FavoriteSongs = append([]string{}, in.FavoriteSongs...)
	out.ExtraCurriculars = append([]string{}, in.ExtraCurriculars...)
	out.IntentTags = append([]string{}, in.IntentTags...)
	out.LanguageTags = append([]string{}, in.LanguageTags...)
	out.DealBreakerTags = append([]string{}, in.DealBreakerTags...)
	return out
}

func copyContacts(in []emergencyContact) []emergencyContact {
	out := make([]emergencyContact, len(in))
	copy(out, in)
	return out
}

func toInt(value any) (int, bool) {
	switch typed := value.(type) {
	case int:
		return typed, true
	case int32:
		return int(typed), true
	case int64:
		return int(typed), true
	case float32:
		return int(typed), true
	case float64:
		return int(typed), true
	default:
		return 0, false
	}
}

func toStringSlice(value any) ([]string, bool) {
	raw, ok := value.([]any)
	if !ok {
		return nil, false
	}
	out := make([]string, 0, len(raw))
	for _, item := range raw {
		str := strings.TrimSpace(toString(item))
		if str == "" {
			continue
		}
		out = append(out, str)
	}
	return out, true
}

func toOptionalString(value any) (*string, bool) {
	if value == nil {
		return nil, true
	}
	str := strings.TrimSpace(toString(value))
	if str == "" {
		return nil, true
	}
	return &str, true
}

func seedURL(template, seed string) string {
	trimmed := strings.TrimSpace(template)
	if trimmed == "" {
		trimmed = "https://picsum.photos/seed/%s/200/200"
	}
	if strings.Contains(trimmed, "%s") {
		return fmt.Sprintf(trimmed, seed)
	}
	return trimmed
}
