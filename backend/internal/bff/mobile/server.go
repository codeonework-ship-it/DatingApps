package mobile

import (
	"bufio"
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/url"
	"path"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/google/uuid"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"go.uber.org/zap"
	"google.golang.org/grpc"
	"google.golang.org/grpc/connectivity"
	"google.golang.org/grpc/credentials/insecure"

	adminapp "github.com/verified-dating/backend/internal/modules/admin/application"
	admininfra "github.com/verified-dating/backend/internal/modules/admin/infrastructure"
	authapp "github.com/verified-dating/backend/internal/modules/auth/application"
	authdomain "github.com/verified-dating/backend/internal/modules/auth/domain"
	authinfra "github.com/verified-dating/backend/internal/modules/auth/infrastructure"
	billingapp "github.com/verified-dating/backend/internal/modules/billing/application"
	billinginfra "github.com/verified-dating/backend/internal/modules/billing/infrastructure"
	callsapp "github.com/verified-dating/backend/internal/modules/calls/application"
	callsinfra "github.com/verified-dating/backend/internal/modules/calls/infrastructure"
	chatapp "github.com/verified-dating/backend/internal/modules/chat/application"
	chatinfra "github.com/verified-dating/backend/internal/modules/chat/infrastructure"
	engagementapp "github.com/verified-dating/backend/internal/modules/engagement/application"
	engagementinfra "github.com/verified-dating/backend/internal/modules/engagement/infrastructure"
	matchingapp "github.com/verified-dating/backend/internal/modules/matching/application"
	matchinginfra "github.com/verified-dating/backend/internal/modules/matching/infrastructure"
	profileapp "github.com/verified-dating/backend/internal/modules/profile/application"
	profileinfra "github.com/verified-dating/backend/internal/modules/profile/infrastructure"
	safetyapp "github.com/verified-dating/backend/internal/modules/safety/application"
	safetyinfra "github.com/verified-dating/backend/internal/modules/safety/infrastructure"
	verificationapp "github.com/verified-dating/backend/internal/modules/verification/application"
	verificationinfra "github.com/verified-dating/backend/internal/modules/verification/infrastructure"
	"github.com/verified-dating/backend/internal/platform/config"
	"github.com/verified-dating/backend/internal/platform/dataaccess"
	"github.com/verified-dating/backend/internal/platform/docs"
	"github.com/verified-dating/backend/internal/platform/mediastore"
	"github.com/verified-dating/backend/internal/platform/mediatr"
	"github.com/verified-dating/backend/internal/platform/observability"
)

type Server struct {
	cfg    config.Config
	log    *zap.Logger
	router chi.Router

	authConn                 *grpc.ClientConn
	profileConn              *grpc.ClientConn
	matchingConn             *grpc.ClientConn
	chatConn                 *grpc.ClientConn
	runtimeData              *dataaccess.Store
	store                    *runtimeStore
	masterData               *masterDataRepository
	termsAgreements          *termsAgreementRepository
	dailyPrompts             *dailyPromptRepository
	spotlight                *spotlightRepository
	activities               *activityRepository
	trust                    *trustRepository
	rooms                    *conversationRoomRepository
	realtime                 chatRealtimeEventStore
	realtimeAuthorizer       realtimeSessionAuthorizer
	notifications            *notificationRepository
	notificationWorker       *notificationDeliveryEngine
	sosDeliveryWorker        *sosDeliveryEngine
	accountErasureWorker     *accountErasureWorker
	trustRetentionWorker     *trustRetentionWorker
	datePlanSweepWorker      *datePlanSweepWorker
	analyticsSnapshotWorker  *analyticsSnapshotWorker
	datePlanUnlockOverride   func(matchID string) (bool, string)
	copilotProvider          copilotProvider
	xpAwardSpool             *xpAwardSpool
	progression              *levelProgressionRepository
	progressionWorker        *levelProjectionEngine
	billing                  *billingCheckoutService
	mediator                 *mediatr.Mediator
	bulkheads                map[string]chan struct{}
	idempotency              *idempotencyStore
	sharedIdempotency        *postgresIdempotencyStore
	fanout                   *asyncFanout
	media                    mediastore.Store
	mediaOnce                sync.Once
	mediaErr                 error
	mediaModerator           mediaModerator
	identityVerifier         identityVerificationProvider
	voiceModerator           voiceModerationProvider
	mediaCleanupCancel       context.CancelFunc
	mediaCleanupDone         chan struct{}
	idempotencyCleanupCancel context.CancelFunc
	idempotencyCleanupDone   chan struct{}
	httpMetrics              *observability.HTTPMetrics
}

const aliasRouteSunset = "Wed, 31 Dec 2026 23:59:59 GMT"

// Tests may enable the legacy in-memory compatibility path from a _test.go
// file. Production binaries cannot set this value.
var allowRuntimeMemoryFallback bool

// Tests may install a principal resolver so operator-authorized routes can be
// exercised without a live Postgres. Production binaries cannot set this value,
// so the only resolver they can ever use is the session-backed one.
var testPrincipalResolver func(*http.Request) (securityPrincipal, error)

func NewServer(cfg config.Config, log *zap.Logger, httpMetrics *observability.HTTPMetrics) (*Server, error) {
	// Every real BFF process is durable. Tests that intentionally exercise the
	// compatibility store construct runtimeStore directly and never pass through
	// production composition. Repository errors must never fall through to RAM.
	if !allowRuntimeMemoryFallback {
		cfg.RequireDurableEngagementStore = true
	}
	var runtimeData *dataaccess.Store
	if cfg.UseLocalDB {
		ctx, cancel := context.WithTimeout(context.Background(), cfg.BFFRequestTimeout())
		defer cancel()
		var err error
		runtimeData, err = dataaccess.Open(ctx, cfg)
		if err != nil {
			return nil, fmt.Errorf("open native postgres runtime store: %w", err)
		}
	}
	constructed := false
	defer func() {
		if !constructed && runtimeData != nil {
			runtimeData.Close()
		}
	}()

	authConn, err := grpc.Dial(cfg.AuthGRPCAddr, grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		return nil, err
	}
	profileConn, err := grpc.Dial(cfg.ProfileGRPCAddr, grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		_ = authConn.Close()
		return nil, err
	}
	matchingConn, err := grpc.Dial(cfg.MatchingGRPCAddr, grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		_ = authConn.Close()
		_ = profileConn.Close()
		return nil, err
	}
	chatConn, err := grpc.Dial(cfg.ChatGRPCAddr, grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		_ = authConn.Close()
		_ = profileConn.Close()
		_ = matchingConn.Close()
		return nil, err
	}

	s := &Server{
		cfg:             cfg,
		log:             log,
		authConn:        authConn,
		profileConn:     profileConn,
		matchingConn:    matchingConn,
		chatConn:        chatConn,
		runtimeData:     runtimeData,
		store:           newRuntimeStore(cfg, clientFromStore(runtimeData)),
		masterData:      newMasterDataRepository(cfg, clientFromStore(runtimeData)),
		termsAgreements: newTermsAgreementRepository(cfg, clientFromStore(runtimeData)),
		dailyPrompts:    newDailyPromptRepository(cfg, clientFromStore(runtimeData)),
		spotlight:       newSpotlightRepository(cfg, clientFromStore(runtimeData)),
		activities:      newActivityRepository(cfg, clientFromStore(runtimeData)),
		trust:           newTrustRepository(cfg, clientFromStore(runtimeData)),
		rooms:           newConversationRoomRepository(cfg, clientFromStore(runtimeData)),
		mediator:        mediatr.New(),
		bulkheads:       newBulkheadLimiters(cfg),
		idempotency:     newIdempotencyStore(cfg.IdempotencyTTL()),
		httpMetrics:     httpMetrics,
	}
	s.fanout = newAsyncFanout(cfg, log, s.store)
	s.registerObservability()
	s.mediaModerator, err = newMediaModerator(cfg)
	if err != nil {
		_ = authConn.Close()
		_ = profileConn.Close()
		_ = matchingConn.Close()
		_ = chatConn.Close()
		return nil, fmt.Errorf("configure media moderation: %w", err)
	}
	s.identityVerifier = newIdentityVerificationProvider(cfg)
	s.voiceModerator = configuredVoiceModerationProvider(cfg)
	if s.store.profileRepo != nil {
		s.sharedIdempotency = newPostgresIdempotencyStore(s.store.profileRepo.pg, cfg)
		s.realtime = newChatRealtimeRepository(s.store.profileRepo.pg)
		s.realtimeAuthorizer = s.store.profileRepo
		s.notifications = newNotificationRepository(s.store.profileRepo.pg)
		s.notificationWorker = newNotificationDeliveryEngine(cfg, log, s.notifications, httpMetrics)
		s.sosDeliveryWorker = newSOSDeliveryEngine(cfg, log, s.store.safetyRepo)
		s.progression = newLevelProgressionRepository(s.store.profileRepo.pg)
		s.progressionWorker = newLevelProjectionEngine(s.progression, log, httpMetrics)
	}
	xpRewardsDisabled.Store(cfg.IsReleaseExcluded("level_progression_enabled"))
	if err := s.initMediaStore(context.Background()); err != nil {
		_ = authConn.Close()
		_ = profileConn.Close()
		_ = matchingConn.Close()
		_ = chatConn.Close()
		return nil, fmt.Errorf("configure media storage: %w", err)
	}
	if err := s.validateDurableEngagementReadiness(); err != nil {
		_ = authConn.Close()
		_ = profileConn.Close()
		_ = matchingConn.Close()
		_ = chatConn.Close()
		return nil, err
	}
	if err := s.validateNativePostgresReadiness(); err != nil {
		_ = authConn.Close()
		_ = profileConn.Close()
		_ = matchingConn.Close()
		_ = chatConn.Close()
		return nil, err
	}

	authGateway := authinfra.NewGRPCGateway(authConn)
	authService := authapp.NewService(authGateway, log)
	authapp.RegisterHandlers(s.mediator, authService)

	profileGateway := profileinfra.NewGRPCGateway(profileConn)
	profileService := profileapp.NewService(profileGateway, log)
	profileapp.RegisterRPCHandlers(s.mediator, profileService)
	profileStoreGateway := profileinfra.NewStoreGateway(
		func(userID string) any { return s.store.getDraft(userID) },
		func(userID string, payload map[string]any) any { return s.store.patchDraft(userID, payload) },
		func(userID string, photo profileapp.ProfilePhotoUploadInput) (any, error) {
			return s.store.addValidatedPhoto(userID, photo)
		},
		func(userID, photoID string) (any, error) { return s.store.deletePhotoDurable(userID, photoID) },
		func(userID string, photoIDs []string) (any, error) {
			return s.store.reorderPhotosDurable(userID, photoIDs)
		},
		func(userID string) (any, error) { return s.store.completeProfile(userID) },
		func(userID string) any { return s.store.getSettings(userID) },
		func(userID string, payload map[string]any) any { return s.store.patchSettings(userID, payload) },
		func(userID string) any { return s.store.listEmergencyContacts(userID) },
		func(userID, name, phoneNumber string) (any, error) {
			return s.store.addEmergencyContact(userID, name, phoneNumber)
		},
		func(userID, contactID, name, phoneNumber string) (any, error) {
			return s.store.updateEmergencyContact(userID, contactID, name, phoneNumber)
		},
		func(userID, contactID string) any { return s.store.deleteEmergencyContact(userID, contactID) },
		func(userID string) any { return s.store.listBlockedUsers(userID) },
	)
	profileStoreService := profileapp.NewService(profileStoreGateway, log)
	profileapp.RegisterStoreHandlers(s.mediator, profileStoreService)

	matchingGateway := matchinginfra.NewGRPCGateway(matchingConn)
	matchingService := matchingapp.NewService(matchingGateway, log)
	matchingapp.RegisterRPCHandlers(s.mediator, matchingService)
	matchingStoreGateway := matchinginfra.NewStoreGateway(
		func(matchID string) (any, bool) { return s.store.getQuestTemplate(matchID) },
		func(matchID, creatorUserID, prompt string, minChars, maxChars int) (any, error) {
			return s.store.upsertQuestTemplate(matchID, creatorUserID, prompt, minChars, maxChars)
		},
		func(matchID string) (any, bool) { return s.store.getQuestWorkflow(matchID) },
		func(matchID, submitterUserID, responseText string) (any, error) {
			return s.store.submitQuestResponse(matchID, submitterUserID, responseText)
		},
		func(matchID, reviewerUserID, decisionStatus, reviewReason string) (any, error) {
			return s.store.reviewQuestResponse(matchID, reviewerUserID, decisionStatus, reviewReason)
		},
		func(matchID string) any { return s.store.listMatchGestures(matchID) },
		func(matchID, senderUserID, receiverUserID, gestureType, contentText, tone string) (any, error) {
			return s.store.createMatchGesture(matchID, senderUserID, receiverUserID, gestureType, contentText, tone)
		},
		func(matchID, gestureID, reviewerUserID, decision, reason string) (any, error) {
			return s.store.decideMatchGesture(matchID, gestureID, reviewerUserID, decision, reason)
		},
		func(matchID, gestureID string) (any, error) {
			return s.store.getGestureScore(matchID, gestureID)
		},
	)
	matchingStoreService := matchingapp.NewService(matchingStoreGateway, log)
	matchingapp.RegisterStoreHandlers(s.mediator, matchingStoreService)

	chatGateway := chatinfra.NewGRPCGateway(chatConn)
	chatService := chatapp.NewService(chatGateway, log)
	chatapp.RegisterHandlers(s.mediator, chatService)

	safetyGateway := safetyinfra.NewStoreGateway(
		func(reporterUserID, reportedUserID, reason, description string) (any, error) {
			return s.store.createReport(reporterUserID, reportedUserID, reason, description)
		},
		func(userID, blockedUserID string) error {
			return s.store.blockUser(userID, blockedUserID)
		},
		func(userID, blockedUserID string) error {
			return s.store.unblockUser(userID, blockedUserID)
		},
		func(userID, matchID, level, message string, latitude, longitude float64) (any, error) {
			return s.store.createSOSAlert(userID, matchID, level, message, latitude, longitude)
		},
		func(userID string, limit int) any {
			return s.store.listSOSAlerts(userID, limit)
		},
		func(alertID, resolvedBy, note string) (any, error) {
			return s.store.resolveSOSAlert(alertID, resolvedBy, note)
		},
	)
	safetyService := safetyapp.NewService(safetyGateway, log)
	safetyapp.RegisterHandlers(s.mediator, safetyService)

	callsGateway := callsinfra.NewStoreGateway(
		func(matchID, initiatorID, recipientID string) (any, error) {
			return s.store.startVideoCall(matchID, initiatorID, recipientID)
		},
		func(callID, endedBy string) (any, error) {
			return s.store.endVideoCall(callID, endedBy)
		},
		func(userID string, limit int) any {
			return s.store.listVideoCalls(userID, limit)
		},
	)
	callsService := callsapp.NewService(callsGateway, log)
	callsapp.RegisterHandlers(s.mediator, callsService)

	engagementGateway := engagementinfra.NewStoreGateway(
		func(circleID, userID string) (any, error) {
			return s.store.getCircleChallengeView(circleID, userID, time.Now().UTC())
		},
		func(circleID, userID string) (any, error) {
			return s.store.joinCircle(circleID, userID, time.Now().UTC())
		},
		func(circleID, challengeID, userID, entryText, imageURL string) (any, any, error) {
			return s.store.submitCircleChallengeEntry(circleID, challengeID, userID, entryText, imageURL, time.Now().UTC())
		},
		func(userID string) (any, error) {
			return s.store.getDailyPromptView(userID, time.Now().UTC())
		},
		func(userID, promptID, answerText string) (any, bool, error) {
			return s.store.submitDailyPromptAnswer(userID, promptID, answerText, time.Now().UTC())
		},
		func(userID string, limit, offset int) (any, error) {
			return s.store.listDailyPromptResponders(userID, time.Now().UTC(), limit, offset)
		},
		func(matchID, userID, counterpartyUserID, nudgeType string) (any, error) {
			return s.store.sendMatchNudge(matchID, userID, counterpartyUserID, nudgeType, time.Now().UTC())
		},
		func(nudgeID, userID string) (any, error) {
			return s.store.markMatchNudgeClicked(nudgeID, userID, time.Now().UTC())
		},
		func(matchID, userID, triggerNudgeID string) (any, error) {
			return s.store.markConversationResumed(matchID, userID, triggerNudgeID, time.Now().UTC())
		},
		func() any {
			return s.store.listVoiceIcebreakerPrompts()
		},
		func(matchID, senderUserID, receiverUserID, promptID string) (any, error) {
			return s.store.startVoiceIcebreaker(matchID, senderUserID, receiverUserID, promptID, time.Now().UTC())
		},
		func(icebreakerID, senderUserID, transcript string, durationSeconds int) (any, error) {
			return s.store.sendVoiceIcebreaker(icebreakerID, senderUserID, transcript, durationSeconds, time.Now().UTC())
		},
		func(icebreakerID, userID string) (any, error) {
			return s.store.markVoiceIcebreakerPlayed(icebreakerID, userID, time.Now().UTC())
		},
		func(creatorUserID string, participantUserIDs []string, options []engagementapp.GroupCoffeeOptionInput, deadlineAt string) (any, error) {
			normalized := make([]groupCoffeePollOption, 0, len(options))
			for _, option := range options {
				normalized = append(normalized, groupCoffeePollOption{
					Day:          option.Day,
					TimeWindow:   option.TimeWindow,
					Neighborhood: option.Neighborhood,
				})
			}
			return s.store.createGroupCoffeePoll(creatorUserID, participantUserIDs, normalized, deadlineAt, time.Now().UTC())
		},
		func(userID, status string, limit int) any {
			return s.store.listGroupCoffeePolls(userID, status, limit)
		},
		func(pollID string) (any, bool) {
			return s.store.getGroupCoffeePoll(pollID)
		},
		func(pollID, userID, optionID string) (any, error) {
			return s.store.voteGroupCoffeePoll(pollID, userID, optionID)
		},
		func(pollID, userID string) (any, any, error) {
			return s.store.finalizeGroupCoffeePoll(pollID, userID, time.Now().UTC())
		},
		func(ownerUserID, name, city, topic, description, visibility string, inviteeUserIDs []string) (any, any, error) {
			return s.store.createCommunityGroup(ownerUserID, name, city, topic, description, visibility, inviteeUserIDs, time.Now().UTC())
		},
		func(userID, city, topic string, onlyJoined bool, limit int) any {
			return s.store.listCommunityGroups(userID, city, topic, onlyJoined, limit)
		},
		func(groupID, inviterUserID string, inviteeUserIDs []string) (any, error) {
			return s.store.createCommunityGroupInvites(groupID, inviterUserID, inviteeUserIDs, time.Now().UTC())
		},
		func(groupID, userID, decision string) (any, any, error) {
			return s.store.respondCommunityGroupInvite(groupID, userID, decision, time.Now().UTC())
		},
		func(userID, status string, limit int) any {
			return s.store.listCommunityGroupInvites(userID, status, limit)
		},
	)
	engagementService := engagementapp.NewService(engagementGateway, log)
	engagementapp.RegisterHandlers(s.mediator, engagementService)

	verificationGateway := verificationinfra.NewStoreGateway(
		func(userID string) (any, error) { return s.store.getVerificationResult(userID) },
		func(userID string) (any, error) { return s.store.submitVerificationResult(userID) },
		func(status string, limit int) (any, error) { return s.store.listVerificationsResult(status, limit) },
		func(userID, status, rejectionReason, reviewedBy string) (any, error) {
			return s.store.reviewVerification(userID, status, rejectionReason, reviewedBy)
		},
	)
	verificationService := verificationapp.NewService(verificationGateway, log)
	verificationapp.RegisterHandlers(s.mediator, verificationService)

	adminGateway := admininfra.NewStoreGateway(
		func(limit int) any { return s.store.listActivities(limit) },
		func(status string, limit int) any { return s.store.listReports(status, limit) },
		func(reportID, status, action, reviewedBy string) (any, error) {
			return s.store.actionReport(reportID, status, action, reviewedBy)
		},
		func() any { return s.store.adminAnalyticsOverview() },
		func(userID string) any { return s.store.userAnalytics(userID) },
	)
	adminService := adminapp.NewService(adminGateway, log)
	adminapp.RegisterHandlers(s.mediator, adminService)

	billingGateway := billinginfra.NewStoreGateway(
		func() any {
			return s.store.listSubscriptionPlans()
		},
		func(userID string) any {
			return s.store.getSubscription(userID)
		},
		func(userID, planID, billingCycle string) (any, any, error) {
			return s.store.subscribe(userID, planID, billingCycle)
		},
		func(userID string, limit int) any {
			return s.store.listPayments(userID, limit)
		},
	)
	billingService := billingapp.NewService(billingGateway, log)
	billingapp.RegisterHandlers(s.mediator, billingService)

	// Card checkout + auto-renew (PEN-01). Present whenever a payment provider
	// is configured; without durable billing persistence its endpoints fail
	// closed with 503 rather than inventing state in memory.
	billing, err := newBillingCheckoutService(cfg, log, s.store.billingRepo)
	if err != nil {
		return nil, fmt.Errorf("configure payments provider: %w", err)
	}
	s.billing = billing
	if s.billing != nil && s.billing.repo != nil {
		// One currency contract: a plan or coin package priced in another
		// currency would show a member mixed prices and settle in a currency
		// the reports do not sum. Refuse to start rather than sell it.
		ctx, cancel := context.WithTimeout(context.Background(), cfg.BFFRequestTimeout())
		mismatched, err := s.billing.repo.catalogCurrencyMismatch(ctx, cfg.PaymentsCurrency)
		cancel()
		if err != nil {
			return nil, fmt.Errorf("check billing catalog currency: %w", err)
		}
		if len(mismatched) > 0 {
			return nil, fmt.Errorf("billing catalog is not priced in %s: %s", cfg.PaymentsCurrency, strings.Join(mismatched, "; "))
		}
	}
	if s.billing != nil {
		s.billing.creditWallet = func(ctx context.Context, req walletCoinCreditRequest) error {
			wallet, purchase, err := s.store.creditPurchasedCoins(ctx, req)
			if err != nil {
				return err
			}
			s.store.recordActivity(activityEvent{
				UserID:   req.UserID,
				Actor:    "payment_provider:" + req.Provider,
				Action:   "wallet.coins.purchase",
				Status:   "success",
				Resource: "/billing/checkout",
				Details: map[string]any{
					"package_id":           req.PackageID,
					"provider":             req.Provider,
					"purchase_ref":         req.PurchaseRef,
					"coins":                req.Coins,
					"amount_minor":         req.AmountMinor,
					"currency":             req.Currency,
					"wallet_balance_after": wallet.CoinBalance,
					"idempotency_key":      req.IdempotencyKey,
					"purchase_id":          purchase.ID,
				},
			})
			return nil
		}
	}

	r := chi.NewRouter()
	r.Use(observability.CorrelationIDMiddleware(log))
	// Outermost after the correlation id so RED metrics and access logs also
	// see shed (429), unauthenticated (401) and recovered-panic (500) responses.
	r.Use(observability.RequestLoggingMiddleware(log, httpMetrics, "mobile_bff"))
	r.Use(observability.GlobalExceptionMiddleware(log))
	r.Use(observability.InflightSheddingMiddleware(log, "mobile_bff", cfg.BFFMaxInFlight, cfg.BFFRetryAfterSec))
	r.Use(s.bulkheadMiddleware)
	r.Use(s.securityMiddleware)
	r.Use(s.timeoutTierMiddleware)
	// Runtime flags are product policy, not presentation hints. Enforce them on
	// the server before a command can enter idempotency or mutate an aggregate.
	r.Use(s.featureFlagEnforcementMiddleware)
	// Mounted after securityMiddleware so the idempotency namespace uses the
	// verified principal rather than caller-supplied actor headers.
	r.Use(s.idempotencyMiddleware)
	// Mounted after securityMiddleware so the audited actor is the verified
	// principal rather than anything the caller supplied.
	r.Use(s.operatorAuditMiddleware)
	r.Use(s.activityMiddleware)

	r.Get("/healthz", s.healthz)
	r.Get("/readyz", s.readyz)
	r.Handle("/metrics", promhttp.Handler())
	r.Mount("/debug", middleware.Profiler())
	r.Get("/openapi.yaml", docs.OpenAPIHandler)
	r.Get("/docs", docs.SwaggerUIHandler("/openapi.yaml"))

	r.Route(cfg.APIPrefix, func(v1 chi.Router) {
		v1.Post("/auth/login", s.login)
		v1.Post("/auth/signup", s.signup)
		v1.Post("/auth/refresh", s.refreshAuthSession)
		v1.Post("/auth/logout", s.logout)
		v1.Post("/auth/sessions/revoke", s.revokeAuthSessions)
		v1.Post("/auth/password/change", s.changeAuthPassword)
		v1.Post("/auth/password/recover", s.recoverAuthPassword)
		v1.Post("/auth/recovery-code/rotate", s.rotateAuthRecoveryCode)
		v1.Post("/auth/recovery/assistance", s.requestAccountRecoveryAssistance)
		v1.Post("/auth/signup/bootstrap", s.bootstrapSignup)
		v1.Get("/auth/signup/workflow/{userID}", s.getSignupWorkflow)
		v1.Get("/users/{userID}/agreements/terms", s.getTermsAgreement)
		v1.Patch("/users/{userID}/agreements/terms", s.patchTermsAgreement)
		v1.Get("/discovery/{userID}", s.getDiscoveryCandidates)
		v1.Get("/discovery/{userID}/today", s.getCuratedDailySet)
		v1.Get("/discovery/{userID}/liked-me", s.listLikedMe)
		v1.Get("/master-data/preferences", s.getPreferenceMasterData)
		v1.Get("/config/flags", s.runtimeConfigFlags)
		v1.Get("/operations/status", s.getOperationStatus)
		v1.Get("/discovery/{userID}/filters/trust", s.getDiscoveryTrustFilter)
		v1.Patch("/discovery/{userID}/filters/trust", s.patchDiscoveryTrustFilter)
		v1.Post("/profile/views", s.recordProfileView)
		v1.Get("/profile/{userID}", s.getProfile)
		v1.Get("/profile/{userID}/summary", s.getProfileSummary)
		v1.Get("/profile/{userID}/viewers", s.listProfileViewers)
		v1.Put("/profile/{userID}", s.upsertProfile)
		v1.Get("/profile/{userID}/draft", s.getProfileDraft)
		v1.Patch("/profile/{userID}/draft", s.patchProfileDraft)
		v1.Post("/profile/{userID}/photos", s.addProfilePhoto)
		v1.Get("/media/*", s.serveUploadedMedia)
		v1.Delete("/profile/{userID}/photos/{photoID}", s.deleteProfilePhoto)
		v1.Post("/profile/{userID}/photos/reorder", s.reorderProfilePhotos)
		v1.Post("/profile/{userID}/complete", s.completeProfile)
		v1.Get("/account/{userID}/lifecycle", s.getAccountLifecycle)
		v1.Post("/account/{userID}/deactivate", s.deactivateAccount)
		v1.Post("/account/{userID}/reactivate", s.reactivateAccount)
		v1.Post("/account/{userID}/deletion", s.requestAccountDeletion)
		v1.Delete("/account/{userID}/deletion", s.cancelAccountDeletion)
		v1.Post("/account/{userID}/export", s.createAccountExport)
		v1.Get("/account/{userID}/export", s.getAccountExport)
		v1.Get("/account/{userID}/dating-preferences", s.datingPreferencesHandler)
		v1.Put("/account/{userID}/dating-preferences", s.datingPreferencesHandler)
		v1.Get("/matches/{matchID}/connection", s.getDatingConnection)
		v1.Get("/chapters/catalogue", s.chapterCatalogue)
		v1.Get("/blog/responses", s.blogResponsesHandler)
		v1.Post("/blog/responses", s.blogResponsesHandler)
		v1.Get("/blog/responses/{responseID}", s.blogResponsesHandler)
		v1.Post("/blog/responses/{responseID}", s.blogResponsesHandler)
		v1.Delete("/blog/responses/{responseID}", s.blogResponsesHandler)
		v1.Get("/blog/publications", s.blogPublicationsHandler)
		v1.Post("/blog/publications", s.blogPublicationsHandler)
		v1.Post("/blog/publications/{shareID}", s.blogPublicationsHandler)
		v1.Delete("/blog/publications/{shareID}", s.blogPublicationsHandler)
		v1.Get("/blog/public/{shareID}", s.blogPublicHandler)
		v1.Get("/blog/public/{shareID}/photos/{photoID}", s.blogPublicHandler)
		v1.Post("/blog/public/{shareID}/report", s.blogReportHandler)
		v1.Post("/blog/reports/{kind}/{contentID}", s.blogReportHandler)
		v1.Get("/blog/notices", s.blogNoticesHandler)
		v1.Post("/blog/notices/{caseID}/appeal", s.blogNoticesHandler)
		v1.Get("/admin/moderation/blog", s.blogReviewHandler)
		v1.Post("/admin/moderation/blog/{caseID}", s.blogReviewHandler)
		v1.Get("/admin/moderation/blog/{caseID}/photos/{photoID}", s.blogReviewHandler)
		v1.Get("/blog/posts", s.blogPostsHandler)
		v1.Get("/blog/posts/{postID}", s.blogPostsHandler)
		v1.Put("/blog/posts/{postID}", s.blogPostsHandler)
		v1.Delete("/blog/posts/{postID}", s.blogPostsHandler)
		v1.Get("/blog/posts/{postID}/photos/{photoID}", s.blogPhotoHandler)
		v1.Put("/blog/posts/{postID}/photos/{photoID}", s.blogPhotoHandler)
		v1.Delete("/blog/posts/{postID}/photos/{photoID}", s.blogPhotoHandler)
		v1.Post("/blog/posts/{postID}/report", s.reportBlogPost)
		// Likes, author-approved comments and Featured Stories (migration 108).
		v1.Get("/blog/featured", s.blogFeaturedHandler)
		v1.Get("/blog/topics", s.blogTopicsHandler)
		v1.Get("/blog/subscriptions", s.blogWritersHandler)
		v1.Put("/blog/authors/{authorID}/subscription", s.blogSubscriptionHandler)
		v1.Delete("/blog/authors/{authorID}/subscription", s.blogSubscriptionHandler)
		v1.Put("/blog/posts/{postID}/like", s.blogLikeHandler)
		v1.Delete("/blog/posts/{postID}/like", s.blogLikeHandler)
		v1.Get("/blog/posts/{postID}/comments", s.blogCommentsHandler)
		v1.Put("/blog/posts/{postID}/comments/{commentID}", s.blogCommentsHandler)
		v1.Delete("/blog/posts/{postID}/comments/{commentID}", s.blogCommentsHandler)
		v1.Post("/blog/posts/{postID}/comments/{commentID}/decision", s.blogCommentDecisionHandler)
		// Photo Themes (migration 107).
		v1.Get("/themes", s.photoThemesHandler)
		v1.Get("/themes/{themeID}/entries", s.photoThemeEntriesHandler)
		v1.Put("/themes/{themeID}/entries/{entryID}", s.photoThemeEntryHandler)
		v1.Delete("/themes/{themeID}/entries/{entryID}", s.photoThemeEntryHandler)
		v1.Get("/themes/{themeID}/entries/{entryID}/photo", s.photoThemeEntryHandler)
		v1.Get("/themes/wall", s.photoWallHandler)
		v1.Get("/walls/celebrations", s.wallCelebrationsHandler)
		v1.Get("/walls/today", s.todayWallHandler)
		v1.Post("/walls/views", s.contentViewsHandler)
		v1.Get("/themes/cover", s.coverOfWeekHandler)
		v1.Post("/walls/celebrations/{celebrationID}/seen", s.wallCelebrationsHandler)
		v1.Put("/themes/{themeID}/entries/{entryID}/like", s.photoEntryLikeHandler)
		v1.Delete("/themes/{themeID}/entries/{entryID}/like", s.photoEntryLikeHandler)
		v1.Post("/themes/{themeID}/entries/{entryID}/featuring", s.photoEntryFeaturingHandler)
		v1.Get("/themes/{themeID}/entries/{entryID}/comments", s.photoEntryCommentsHandler)
		v1.Put("/themes/{themeID}/entries/{entryID}/comments/{commentID}", s.photoEntryCommentsHandler)
		v1.Delete("/themes/{themeID}/entries/{entryID}/comments/{commentID}", s.photoEntryCommentsHandler)
		v1.Post("/themes/{themeID}/entries/{entryID}/comments/{commentID}/decision", s.photoEntryCommentDecisionHandler)
		v1.Get("/admin/engagement/photo-themes", s.adminPhotoThemesHandler)
		v1.Post("/admin/engagement/photo-themes", s.adminPhotoThemesHandler)
		// Book & Film Clubs (migration 107). Static segments win over {clubID}.
		v1.Get("/clubs", s.clubsHandler)
		v1.Get("/clubs/titles", s.clubTitlesHandler)
		v1.Get("/clubs/titles/{titleID}", s.clubTitleHandler)
		v1.Put("/clubs/titles/{titleID}", s.clubTitleHandler)
		v1.Put("/clubs/titles/{titleID}/reviews/{reviewID}", s.clubReviewHandler)
		v1.Delete("/clubs/reviews/{reviewID}", s.clubReviewHandler)
		v1.Get("/clubs/lists", s.clubListsHandler)
		v1.Put("/clubs/lists/{listID}", s.clubListHandler)
		v1.Delete("/clubs/lists/{listID}", s.clubListHandler)
		v1.Put("/clubs/lists/{listID}/items/{titleID}", s.clubListItemHandler)
		v1.Delete("/clubs/lists/{listID}/items/{titleID}", s.clubListItemHandler)
		v1.Get("/clubs/{clubID}", s.clubHandler)
		v1.Put("/clubs/{clubID}", s.clubHandler)
		v1.Post("/clubs/{clubID}/membership", s.clubMembershipHandler)
		v1.Get("/clubs/{clubID}/members", s.clubMembersHandler)
		v1.Post("/clubs/{clubID}/members/{userID}", s.clubMembersHandler)
		v1.Put("/clubs/{clubID}/selections/{weekStart}", s.clubSelectionHandler)
		v1.Get("/clubs/{clubID}/posts", s.clubPostsHandler)
		v1.Put("/clubs/{clubID}/posts/{postID}", s.clubPostHandler)
		v1.Delete("/clubs/{clubID}/posts/{postID}", s.clubPostHandler)
		v1.Post("/clubs/{clubID}/posts/{postID}/visibility", s.clubPostVisibilityHandler)
		v1.Get("/chapters/public/{shareID}", s.chapterPublicHandler)
		v1.Get("/chapters/publications", s.chapterPublicationHandler)
		v1.Post("/chapters/publications", s.chapterPublicationHandler)
		v1.Delete("/chapters/publications/{shareID}", s.chapterPublicationHandler)
		v1.Get("/chapters/comfort", s.comfortHandler)
		v1.Put("/chapters/comfort", s.comfortHandler)
		v1.Get("/matches/{matchID}/chapter", s.chapterPairHandler)
		v1.Post("/matches/{matchID}/chapter", s.chapterPairHandler)
		v1.Put("/matches/{matchID}/chapter/green-light", s.chapterPairHandler)
		v1.Post("/matches/{matchID}/moments", s.chemistryHandler)
		v1.Post("/matches/{matchID}/moments/{momentID}/answer", s.chemistryHandler)
		v1.Post("/matches/{matchID}/plans/{planID}/counter", s.counterDatePlan)
		v1.Get("/settings/{userID}", s.getSettings)
		v1.Patch("/settings/{userID}", s.patchSettings)
		v1.Get("/emergency-contacts/{userID}", s.listEmergencyContacts)
		v1.Post("/emergency-contacts/{userID}", s.addEmergencyContact)
		v1.Put("/emergency-contacts/{userID}/{contactID}", s.updateEmergencyContact)
		v1.Delete("/emergency-contacts/{userID}/{contactID}", s.deleteEmergencyContact)
		v1.Get("/blocked-users/{userID}", s.listBlockedUsers)
		v1.Get("/verification/{userID}", s.getVerification)
		v1.Post("/verification/{userID}/submit", s.submitVerification)
		v1.Post("/swipe", s.swipe)
		v1.Get("/matches/{userID}", s.listMatches)
		v1.Delete("/matches/{matchID}", s.unmatch)
		v1.Post("/matches/{matchID}/read", s.markMatchRead)
		v1.Get("/matches/{matchID}/unlock-state", s.getMatchUnlockState)
		v1.Post("/matches/{matchID}/unlock-requirements", s.withAliasDeprecation("/v1/matches/{matchID}/quest-template", s.upsertMatchQuestTemplate))
		v1.Get("/matches/{matchID}/quest-template", s.getMatchQuestTemplate)
		v1.Put("/matches/{matchID}/quest-template", s.upsertMatchQuestTemplate)
		v1.Get("/matches/{matchID}/quests", s.withAliasDeprecation("/v1/matches/{matchID}/quest-workflow", s.getMatchQuestWorkflow))
		v1.Get("/matches/{matchID}/quest-workflow", s.getMatchQuestWorkflow)
		v1.Post("/matches/{matchID}/quests/submit", s.withAliasDeprecation("/v1/matches/{matchID}/quest-workflow/submit", s.submitMatchQuestResponse))
		v1.Post("/matches/{matchID}/quest-workflow/submit", s.submitMatchQuestResponse)
		v1.Post("/matches/{matchID}/quests/{submissionID}/review", s.withAliasDeprecation("/v1/matches/{matchID}/quest-workflow/review", s.reviewMatchQuestResponse))
		v1.Post("/matches/{matchID}/quest-workflow/review", s.reviewMatchQuestResponse)
		v1.Get("/matches/{matchID}/timeline", s.listMatchTimeline)
		v1.Get("/matches/{matchID}/gestures", s.withAliasDeprecation("/v1/matches/{matchID}/timeline", s.listMatchTimeline))
		v1.Post("/matches/{matchID}/gestures", s.createMatchGesture)
		v1.Post("/matches/{matchID}/gestures/{gestureID}/respond", s.withAliasDeprecation("/v1/matches/{matchID}/gestures/{gestureID}/decision", s.decideMatchGesture))
		v1.Post("/matches/{matchID}/gestures/{gestureID}/decision", s.decideMatchGesture)
		v1.Get("/matches/{matchID}/gestures/{gestureID}/score", s.getGestureScore)
		v1.Get("/matches/{matchID}/voice-introductions", s.listVoiceIntroductions)
		v1.Get("/profile/{userID}/stories", s.profileStoriesHandler)
		v1.Put("/profile/{userID}/stories", s.profileStoriesHandler)
		v1.Get("/matches/{matchID}/plans", s.getMatchDatePlans)
		v1.Post("/matches/{matchID}/plans", s.proposeMatchDatePlan)
		v1.Get("/matches/{matchID}/plans/{planID}/sharing", s.datePlanSharingHandler)
		v1.Post("/matches/{matchID}/plans/{planID}/sharing", s.datePlanSharingHandler)
		v1.Post("/matches/{matchID}/plans/{planID}/decision", s.decideMatchDatePlan)
		v1.Post("/matches/{matchID}/plans/{planID}/cancel", s.cancelMatchDatePlan)
		v1.Post("/matches/{matchID}/plans/{planID}/checkin", s.checkinMatchDatePlan)
		v1.Post("/matches/{matchID}/plans/{planID}/debrief", s.debriefMatchDatePlan)
		v1.Post("/matches/{matchID}/copilot/draft", s.draftWithCopilot)
		v1.Get("/matches/{matchID}/trust", s.getConversationTrust)
		v1.Get("/matches/{matchID}/graduation", s.getMatchGraduation)
		v1.Post("/matches/{matchID}/graduation", s.proposeMatchGraduation)
		v1.Post("/matches/{matchID}/graduation/{graduationID}/decision", s.decideMatchGraduation)
		v1.Post("/matches/{matchID}/graduation/{graduationID}/withdraw", s.withdrawMatchGraduation)
		v1.Get("/account/{userID}/discovery/pause", s.getDiscoveryPause)
		v1.Post("/account/{userID}/discovery/pause", s.pauseDiscovery)
		v1.Post("/account/{userID}/discovery/resume", s.resumeDiscovery)
		v1.Get("/plans/{userID}", s.listMemberDatePlans)
		v1.Get("/chat/{matchID}/messages", s.listMessages)
		v1.Post("/chat/{matchID}/messages", s.sendMessage)
		v1.Delete("/chat/{matchID}/messages/{messageID}", s.deleteMessage)
		v1.Post("/chat/{matchID}/messages/{messageID}/gift/hide", s.hideReceivedGift)
		v1.Post("/chat/{matchID}/messages/{messageID}/gift/report", s.reportReceivedGift)
		v1.Get("/realtime/chat", s.streamChatEvents)
		v1.Get("/realtime/notifications", s.streamNotificationEvents)
		v1.Get("/notifications/{userID}", s.listNotifications)
		v1.Get("/notifications/{userID}/unread-count", s.getNotificationUnreadCount)
		v1.Get("/notifications/{userID}/preferences", s.getNotificationPreferences)
		v1.Patch("/notifications/{userID}/preferences", s.patchNotificationPreferences)
		v1.Post("/notifications/{userID}/devices", s.registerNotificationDevice)
		v1.Delete("/notifications/{userID}/devices/{deviceID}", s.unregisterNotificationDevice)
		v1.Post("/notifications/{userID}/read-all", s.markAllNotificationsRead)
		v1.Post("/notifications/{userID}/{notificationID}/read", s.markNotificationRead)
		v1.Delete("/notifications/{userID}/{notificationID}", s.dismissNotification)
		v1.Get("/chat/gifts", s.listRoseGifts)
		v1.Post("/chat/{matchID}/gifts/send", s.sendRoseGift)
		v1.Post("/chat/{matchID}/gifts/events", s.recordRoseGiftTelemetryEvent)
		v1.Get("/wallet/{userID}/coins", s.getWalletCoins)
		v1.Post("/wallet/{userID}/coins/buy", s.buyWalletCoins)
		v1.Post("/wallet/{userID}/coins/top-up", s.topUpWalletCoins)
		v1.Get("/wallet/{userID}/coins/audit", s.listWalletCoinAudit)
		v1.Post("/matches/{matchID}/activities/start", s.withAliasDeprecation("/v1/activities/sessions/start", s.startActivitySession))
		v1.Post("/activities/{sessionID}/responses", s.withAliasDeprecation("/v1/activities/sessions/{sessionID}/submit", s.submitActivitySession))
		v1.Get("/activities/{sessionID}/summary", s.withAliasDeprecation("/v1/activities/sessions/{sessionID}/summary", s.getActivitySessionSummary))
		v1.Post("/activities/sessions/start", s.startActivitySession)
		v1.Post("/activities/sessions/{sessionID}/submit", s.submitActivitySession)
		v1.Get("/activities/sessions/{sessionID}/summary", s.getActivitySessionSummary)
		v1.Get("/engagement/daily-prompt/{userID}", s.getDailyPrompt)
		v1.Post("/engagement/daily-prompt/{userID}/answer", s.submitDailyPromptAnswer)
		v1.Get("/engagement/daily-prompt/{userID}/responders", s.listDailyPromptResponders)
		v1.Post("/engagement/match-nudges/send", s.sendMatchNudge)
		v1.Post("/engagement/match-nudges/{nudgeID}/click", s.clickMatchNudge)
		v1.Post("/engagement/matches/{matchID}/resume", s.markConversationResumed)
		v1.Post("/engagement/circles/{circleID}/join", s.joinCircle)
		v1.Get("/engagement/circles/{circleID}/challenge", s.getCircleChallenge)
		v1.Post("/engagement/circles/{circleID}/challenge/entries", s.submitCircleChallenge)
		v1.Get("/engagement/voice-icebreakers/prompts", s.listVoiceIcebreakerPrompts)
		v1.Post("/engagement/voice-icebreakers/start", s.startVoiceIcebreaker)
		v1.Post("/engagement/voice-icebreakers/{icebreakerID}/send", s.sendVoiceIcebreaker)
		v1.Post("/engagement/voice-icebreakers/{icebreakerID}/play", s.playVoiceIcebreaker)
		v1.Get("/media/voice/{icebreakerID}", s.serveVoicePlayback)
		v1.Post("/engagement/group-coffee-polls", s.createGroupCoffeePoll)
		v1.Get("/engagement/group-coffee-polls", s.listGroupCoffeePolls)
		v1.Get("/engagement/group-coffee-polls/{pollID}", s.getGroupCoffeePoll)
		v1.Post("/engagement/group-coffee-polls/{pollID}/votes", s.voteGroupCoffeePoll)
		v1.Post("/engagement/group-coffee-polls/{pollID}/finalize", s.finalizeGroupCoffeePoll)
		v1.Post("/engagement/groups", s.createCommunityGroup)
		v1.Get("/engagement/groups", s.listCommunityGroups)
		v1.Post("/engagement/groups/{groupID}/invites", s.inviteCommunityGroupMembers)
		v1.Post("/engagement/groups/{groupID}/invites/respond", s.respondCommunityGroupInvite)
		v1.Get("/engagement/group-invites", s.listCommunityGroupInvites)
		// Lifestyle community groups and private friend groups (migration 118).
		v1.Get("/engagement/group-categories", s.listGroupCategoriesHandler)
		v1.Get("/engagement/group-friends", s.listGroupFriendsHandler)
		v1.Get("/engagement/groups/{groupID}", s.communityGroupHandler)
		v1.Patch("/engagement/groups/{groupID}", s.communityGroupHandler)
		v1.Delete("/engagement/groups/{groupID}", s.communityGroupHandler)
		v1.Post("/engagement/groups/{groupID}/join", s.joinCommunityGroupHandler)
		v1.Post("/engagement/groups/{groupID}/leave", s.leaveCommunityGroupHandler)
		v1.Get("/engagement/groups/{groupID}/members", s.communityGroupMembersHandler)
		v1.Post("/engagement/groups/{groupID}/members/{userID}", s.manageCommunityGroupMemberHandler)
		// Group cover photos (migration 121, group_covers.go).
		v1.Get("/engagement/groups/{groupID}/cover", s.groupCoverHandler)
		v1.Put("/engagement/groups/{groupID}/cover", s.groupCoverHandler)
		v1.Delete("/engagement/groups/{groupID}/cover", s.groupCoverHandler)
		v1.Get("/users/{userID}/trust-badges", s.getUserTrustBadges)
		v1.Get("/users/{userID}/vouches", s.getPublicVouches)
		v1.Get("/users/{userID}/trust-badges/history", s.listUserTrustBadgeHistory)
		v1.Get("/introducer/connections", s.introducerHandler)
		v1.Post("/introducer/invites", s.introducerHandler)
		v1.Delete("/introducer/invites", s.introducerHandler)
		v1.Post("/introducer/redeem", s.introducerHandler)
		v1.Post("/introducer/connections/{consentID}/approve", s.introducerHandler)
		v1.Delete("/introducer/connections/{consentID}", s.introducerHandler)
		// Shared chat for friends, Conversation Rooms and groups (migration 115).
		v1.Get("/social/channels", s.socialChannelsHandler)
		v1.Get("/social/channels/{channelID}", s.socialChannelHandler)
		v1.Get("/social/channels/{channelID}/messages", s.socialMessagesHandler)
		v1.Post("/social/channels/{channelID}/messages", s.socialMessagesHandler)
		v1.Delete("/social/channels/{channelID}/messages/{messageID}", s.socialMessageDeleteHandler)
		v1.Post("/social/channels/{channelID}/read", s.socialReadHandler)
		// Per-conversation notification mute (migration 119).
		v1.Put("/social/channels/{channelID}/mute", s.socialMuteHandler)
		v1.Delete("/social/channels/{channelID}/mute", s.socialMuteHandler)
		v1.Post("/social/friends/{friendID}/channel", s.socialFriendChannelHandler)
		v1.Get("/friends/{userID}", s.listFriends)
		v1.Post("/friends/{userID}", s.addFriend)
		v1.Post("/friends/{userID}/{friendUserID}/decision", s.decideFriendRequest)
		v1.Delete("/friends/{userID}/{friendUserID}", s.removeFriend)
		v1.Get("/friends/{userID}/activities", s.listFriendActivities)
		// Add-friend member search (migration 116).
		v1.Get("/friends/{userID}/search", s.searchFriendCandidates)
		// "Let people find me in friend search" (migration 120).
		v1.Get("/friends/{userID}/search-visibility", s.friendSearchVisibilityHandler)
		v1.Put("/friends/{userID}/search-visibility", s.friendSearchVisibilityHandler)
		v1.Get("/friends/{userID}/plans", s.listFriendDatePlans)
		v1.Get("/friends/{userID}/vouches", s.listFriendVouches)
		v1.Post("/friends/{userID}/vouches", s.writeFriendVouch)
		v1.Post("/friends/{userID}/vouches/{vouchID}/decision", s.decideFriendVouch)
		v1.Delete("/friends/{userID}/vouches/{vouchID}", s.withdrawFriendVouch)
		v1.Get("/friends/{userID}/intros", s.listFriendIntros)
		v1.Post("/friends/{userID}/intros", s.makeFriendIntro)
		v1.Post("/friends/{userID}/intros/{introID}/decision", s.decideFriendIntro)
		v1.Get("/rooms", s.listConversationRooms)
		v1.Post("/rooms/{roomID}/join", s.joinConversationRoom)
		v1.Post("/rooms/{roomID}/leave", s.leaveConversationRoom)
		v1.Post("/rooms/{roomID}/moderate", s.moderateConversationRoom)
		// Live chat rooms (migration 117, live_rooms.go).
		v1.Post("/rooms", s.createRoomHandler)
		v1.Get("/rooms/{roomID}", s.roomDetailHandler)
		v1.Get("/rooms/{roomID}/members", s.roomMembersHandler)
		v1.Post("/rooms/{roomID}/presence", s.roomPresenceHandler)
		v1.Post("/calls/start", s.startCall)
		v1.Post("/calls/{callID}/end", s.endCall)
		v1.Get("/calls/history/{userID}", s.listCallHistory)
		v1.Post("/safety/report", s.reportUser)
		v1.Get("/moderation/appeals", s.listModerationAppealsForUser)
		v1.Post("/moderation/appeals", s.submitModerationAppeal)
		v1.Get("/moderation/appeals/{appealID}", s.getModerationAppealStatus)
		v1.Post("/safety/block", s.blockUser)
		v1.Post("/safety/unblock", s.unblockUser)
		v1.Post("/safety/sos", s.triggerSOS)
		v1.Get("/safety/sos/{userID}", s.listSOS)
		v1.Post("/safety/sos/{alertID}/resolve", s.resolveSOS)
		v1.Get("/analytics/{userID}", s.userAnalytics)
		v1.Get("/billing/plans", s.listBillingPlans)
		v1.Get("/billing/account", s.getBillingAccount)
		v1.Get("/billing/coexistence-matrix", s.getBillingCoexistenceMatrix)
		v1.Get("/billing/subscription/{userID}", s.getBillingSubscription)
		v1.Post("/billing/subscribe", s.subscribePlan)
		v1.Get("/billing/payments/{userID}", s.listBillingPayments)
		v1.Get("/billing/coin-packages", s.listCoinPackages)
		v1.Post("/billing/checkout", s.createBillingCheckout)
		v1.Get("/billing/checkout/return", s.billingCheckoutReturn)
		v1.Get("/billing/checkout/{checkoutID}", s.getBillingCheckout)
		v1.Post("/billing/subscription/{userID}/cancel", s.cancelBillingSubscription)
		v1.Post("/billing/subscription/{userID}/resume", s.resumeBillingSubscription)
		v1.Post("/billing/subscription/{userID}/change-plan", s.changeBillingPlan)
		v1.Get("/billing/entitlements/{userID}", s.getBillingEntitlements)
		v1.Post("/billing/webhooks/{provider}", s.billingWebhook)
		v1.Get("/billing/sandbox/checkout/{sessionID}", s.sandboxCheckoutPage)
		v1.Post("/billing/sandbox/checkout/{sessionID}", s.sandboxCheckoutSubmit)
		v1.Post("/billing/sandbox/subscriptions/{userID}/simulate", s.sandboxSimulate)
		v1.Get("/progression/{userID}", s.getProgression)
		v1.Get("/progression/{userID}/ledger", s.listProgressionLedger)
		v1.Post("/progression/{userID}/rewards/claim", s.claimProgressionReward)
		// Deferred growth portfolio. The portfolio contract is always readable;
		// each member capability is independently fail-closed by server flags.
		v1.Get("/growth/portfolio", s.getGrowthPortfolio)
		v1.Get("/support/tickets", s.listSupportTickets)
		v1.Post("/support/tickets", s.createSupportTicket)
		v1.Get("/support/tickets/{ticketID}", s.getSupportTicket)
		v1.Post("/support/tickets/{ticketID}/messages", s.addSupportTicketMessage)
		v1.Get("/city-pilot", s.memberCityPilot)
		v1.Post("/city-pilot/membership", s.cityPilotMembership)
		v1.Delete("/city-pilot/membership", s.cityPilotMembership)
		v1.Post("/city-pilot/events/{eventID}/registration", s.cityPilotRegistration)
		v1.Delete("/city-pilot/events/{eventID}/registration", s.cityPilotRegistration)
		v1.Post("/city-pilot/events/{eventID}/feedback", s.cityPilotFeedback)
		v1.Get("/admin/growth/city-pilot", s.adminCityPilot)
		v1.Post("/admin/growth/city-pilot", s.adminSaveCityPilot)
		v1.Post("/admin/growth/city-pilot/{pilotID}/stage", s.adminTransitionCityPilot)
		v1.Get("/admin/growth/city-pilot/{pilotID}/experiences", s.adminPilotExperiences)
		v1.Post("/admin/growth/city-pilot/{pilotID}/experiences", s.adminCreatePilotExperience)
		v1.Post("/admin/growth/city-pilot/{pilotID}/experiences/{eventID}/cancel", s.adminCancelPilotExperience)
		v1.Get("/growth/events", s.listGrowthEvents)
		v1.Post("/growth/events/{eventID}/registration", s.registerGrowthEvent)
		v1.Delete("/growth/events/{eventID}/registration", s.cancelGrowthEventRegistration)
		v1.Get("/growth/referrals/me", s.getReferralCode)
		v1.Post("/growth/referrals/me", s.createReferralCode)
		v1.Post("/growth/referrals/redeem", s.redeemReferralCode)
		v1.Get("/growth/partnerships", s.listGrowthPartnerships)
		v1.Get("/growth/recommendations", s.listRecommendationEdges)
		v1.Put("/growth/imports/consents", s.upsertSocialImportConsent)
		v1.Delete("/growth/imports/consents/{provider}", s.revokeSocialImportConsent)
		v1.Get("/growth/history", s.getMemberGrowthHistory)
		v1.Post("/growth/history/preferences", s.capturePreferenceHistory)
		v1.Post("/growth/history/location-checkins", s.createLocationCheckin)
		v1.Delete("/growth/history", s.deleteMemberGrowthHistory)
		v1.Post("/growth/admirer-gifts", growthUnavailableHandler("admirer_gifts"))
		v1.Post("/growth/paid-xp", growthUnavailableHandler("paid_xp"))
		v1.Get("/admin/activities", s.listAdminActivities)
		v1.Get("/admin/audit-events", s.adminListAuditEvents)
		v1.Get("/admin/events", s.adminListDomainEvents)
		v1.Get("/admin/events/metrics", s.adminDomainEventMetrics)
		v1.Get("/admin/verifications", s.listAdminVerifications)
		v1.Post("/admin/verifications/{userID}/approve", s.approveVerification)
		v1.Post("/admin/verifications/{userID}/reject", s.rejectVerification)
		v1.Get("/admin/moderation/reports", s.listAdminReports)
		v1.Post("/admin/moderation/reports/{reportID}/action", s.actionAdminReport)
		v1.Get("/admin/moderation/media", s.listAdminMediaModeration)
		v1.Post("/admin/moderation/media/{photoID}/decision", s.decideAdminMediaModeration)
		v1.Get("/admin/moderation/media/{photoID}/content", s.serveAdminMediaModerationContent)
		v1.Get("/admin/moderation/group-covers", s.adminGroupCoversHandler)
		v1.Post("/admin/moderation/group-covers/{coverID}/decision", s.adminGroupCoverDecisionHandler)
		v1.Get("/admin/moderation/group-covers/{coverID}/content", s.adminGroupCoverContentHandler)
		v1.Get("/admin/moderation/appeals", s.listAdminModerationAppeals)
		v1.Post("/admin/moderation/appeals/{appealID}/action", s.actionAdminModerationAppeal)
		v1.Get("/admin/moderation/rooms", s.adminRoomsHandler)
		v1.Post("/admin/moderation/rooms/{roomID}/actions", s.adminRoomActionHandler)
		v1.Post("/admin/moderation/rooms/{roomID}/roles", s.adminRoomRoleHandler)
		v1.Get("/admin/moderation/rooms/{roomID}/members", s.adminRoomMembersHandler)
		v1.Get("/admin/analytics/overview", s.adminAnalyticsOverview)
		// Durable product analytics reports (migration 123; analyst read-only).
		v1.Get("/admin/analytics/kpis", s.adminAnalyticsKPIs)
		v1.Get("/admin/analytics/trends", s.adminAnalyticsTrends)
		v1.Get("/admin/analytics/funnel", s.adminAnalyticsFunnel)
		v1.Get("/admin/analytics/retention", s.adminAnalyticsRetention)
		v1.Get("/admin/analytics/engagement", s.adminAnalyticsEngagement)
		v1.Get("/admin/analytics/liquidity", s.adminAnalyticsLiquidity)
		v1.Get("/admin/analytics/safety", s.adminAnalyticsSafety)
		v1.Get("/admin/analytics/definitions", s.adminAnalyticsDefinitions)
		v1.Get("/admin/analytics/snapshots", s.adminAnalyticsSnapshots)
		v1.Post("/admin/analytics/snapshots/rebuild", s.adminAnalyticsRebuild)
		v1.Get("/admin/analytics/excluded-accounts", s.adminAnalyticsExcludedAccounts)
		v1.Post("/admin/analytics/excluded-accounts", s.adminAnalyticsExcludeAccount)
		v1.Delete("/admin/analytics/excluded-accounts/{memberID}", s.adminAnalyticsIncludeAccount)
		v1.Get("/admin/notifications/queue/metrics", s.adminNotificationQueueMetrics)
		// Gift catalog CRUD
		v1.Get("/admin/catalog/gifts", s.adminListCatalogGifts)
		v1.Post("/admin/catalog/gifts", s.adminCreateCatalogGift)
		v1.Put("/admin/catalog/gifts/{giftID}", s.adminUpdateCatalogGift)
		v1.Post("/admin/catalog/gifts/{giftID}/toggle", s.adminToggleCatalogGift)
		v1.Delete("/admin/catalog/gifts/{giftID}", s.adminDeleteCatalogGift)
		// User management
		v1.Get("/admin/users", s.adminListUsers)
		v1.Post("/admin/users", s.adminCreateUser)
		v1.Get("/admin/users/{userID}", s.adminGetUser)
		v1.Put("/admin/users/{userID}", s.adminUpdateUser)
		v1.Delete("/admin/users/{userID}", s.adminDeleteUser)
		v1.Post("/admin/users/{userID}/suspend", s.adminSuspendUser)
		v1.Post("/admin/users/{userID}/unsuspend", s.adminUnsuspendUser)
		v1.Post("/admin/users/{userID}/ban", s.adminBanUser)
		v1.Post("/admin/users/{userID}/unban", s.adminUnbanUser)
		v1.Post("/admin/users/{userID}/verify", s.adminForceVerifyUser)
		// Feature flags
		v1.Get("/admin/config/flags", s.adminListConfigFlags)
		v1.Put("/admin/config/flags/{key}", s.adminUpdateConfigFlag)
		// Engagement prompts
		v1.Get("/admin/engagement/prompts", s.adminListEngagementPrompts)
		v1.Get("/admin/engagement/nudges", s.adminListEngagementNudges)
		v1.Post("/admin/engagement/prompts", s.adminCreateEngagementPrompt)
		v1.Put("/admin/engagement/prompts/{promptID}", s.adminUpdateEngagementPrompt)
		v1.Post("/admin/engagement/prompts/{promptID}/activate", s.adminActivateEngagementPrompt)
		// Billing admin
		v1.Get("/admin/billing/plans", s.adminListBillingPlans)
		v1.Get("/admin/billing/coin-packages", s.adminListCoinPackages)
		v1.Post("/admin/billing/coin-packages", s.adminCreateCoinPackage)
		v1.Put("/admin/billing/coin-packages/{packageID}", s.adminUpdateCoinPackage)
		v1.Post("/admin/billing/coin-packages/{packageID}/toggle", s.adminToggleCoinPackage)
		v1.Get("/admin/billing/transactions", s.adminListBillingTransactions)
		v1.Get("/admin/billing/stats", s.adminBillingStats)
		v1.Post("/admin/billing/grant-coins", s.adminGrantCoins)
		v1.Get("/admin/billing/subscriptions", s.adminListSubscriptions)
		v1.Get("/admin/billing/payments", s.adminListPayments)
		v1.Get("/admin/billing/webhook-events", s.adminListBillingWebhookEvents)
		v1.Get("/admin/billing/reconciliation", s.adminBillingReconciliation)
		v1.Get("/admin/billing/revenue-analytics", s.adminRevenueAnalytics)
		s.registerBusinessReportRoutes(v1)
		// Wallet admin
		v1.Get("/admin/users/{userID}/wallet", s.adminGetWalletBalance)
		// Safety / SOS
		v1.Get("/admin/safety/sos-alerts", s.adminListSOSAlerts)
		v1.Post("/admin/safety/sos-alerts/{alertID}/resolve", s.adminResolveSOSAlert)
		v1.Get("/admin/progression", s.adminProgressionOverview)
		v1.Put("/admin/progression/policies/{source}", s.adminUpdateProgressionPolicy)
		v1.Get("/admin/progression/fraud", s.adminListProgressionFraud)
		v1.Put("/admin/progression/fraud-rules/{ruleCode}", s.adminUpdateProgressionFraudPolicy)
		v1.Post("/admin/progression/fraud/{caseID}/resolve", s.adminResolveProgressionFraud)
		v1.Post("/admin/progression/users/{userID}/adjust-xp", s.adminAdjustProgressionXP)
		v1.Put("/admin/progression/users/{userID}/control", s.adminSetProgressionControl)
		v1.Put("/admin/progression/experiments/{key}", s.adminUpdateProgressionExperiment)
		v1.Get("/admin/safety/account-recovery", s.adminListAccountRecoveryRequests)
		v1.Post("/admin/safety/gift-sends/{sendID}/reverse", s.adminReverseGiftSend)
		v1.Post("/admin/billing/gift-sends/{sendID}/reverse", s.adminReverseGiftSend)
		v1.Get("/admin/billing/wallets/frozen", s.adminListFrozenWallets)
		v1.Post("/admin/billing/wallets/{userID}/review", s.adminReviewFrozenWallet)
		v1.Get("/admin/billing/fraud/cases", s.adminListEconomyFraudCases)
		v1.Post("/admin/billing/fraud/cases/{caseID}/resolve", s.adminResolveEconomyFraudCase)
		v1.Get("/admin/billing/fraud/rules", s.adminListEconomyFraudRules)
		v1.Put("/admin/billing/fraud/rules/{ruleCode}", s.adminUpdateEconomyFraudRule)
		v1.Post("/admin/safety/account-recovery/{requestID}/resolve", s.adminResolveAccountRecoveryRequest)
		v1.Get("/admin/support/tickets", s.adminListSupportTickets)
		v1.Get("/admin/support/tickets/{ticketID}", s.adminGetSupportTicket)
		v1.Put("/admin/support/tickets/{ticketID}", s.adminUpdateSupportTicket)
		v1.Get("/admin/growth/fraud-graph", s.adminListFraudGraph)
		v1.Post("/admin/growth/fraud-graph/{edgeID}/resolve", s.adminResolveFraudGraphEdge)
		// Self-hosted client crash/error reporting (client_errors.go, migration
		// 122). Ingestion is open to signed-out screens; see isPublicSecurityPath.
		v1.Post("/client/errors", s.reportClientErrors)
		v1.Get("/admin/client-errors", s.adminListClientErrors)
		v1.Get("/admin/client-errors/{issueID}", s.adminGetClientError)
		v1.Post("/admin/client-errors/{issueID}/status", s.adminSetClientErrorStatus)
	})

	s.router = r
	s.startMediaLifecycleCleanup()
	s.startIdempotencyCleanup()
	if s.notificationWorker != nil {
		s.notificationWorker.Start(context.Background())
	}
	if s.sosDeliveryWorker != nil {
		s.sosDeliveryWorker.Start(context.Background())
	}
	if s.progressionWorker != nil {
		s.progressionWorker.Start(context.Background())
	}
	if s.billing != nil {
		s.billing.startSweep(context.Background())
	}
	// Scheduled deletions mature days after the request, so something has to
	// come back for them; without this the journey stops at "scheduled".
	if s.store != nil && s.store.profileRepo != nil && s.store.profileRepo.pg != nil {
		s.accountErasureWorker = newAccountErasureWorker(
			s.store.profileRepo, s.log, time.Hour, 25, s.deleteStoredMedia)
		s.accountErasureWorker.Start(context.Background())
	}
	// Retention classes of the trust-operations contract (revoked sessions,
	// identity evidence, SOS snapshots, 24-month audit history) and the SOS
	// delivery gauges, which must publish even with no SOS provider configured.
	if s.store != nil && s.store.profileRepo != nil && s.store.profileRepo.pg != nil {
		s.trustRetentionWorker = newTrustRetentionWorker(
			s.store.profileRepo.pg, s.log, s.httpMetrics, s.deleteStoredMedia, time.Hour)
		s.trustRetentionWorker.Start(context.Background())
	}
	// Date plans: expire unanswered proposals, remind members to check in and
	// escalate a missed check-in to the member's friends (migration 091).
	if s.store != nil && s.store.profileRepo != nil && s.store.profileRepo.pg != nil {
		s.datePlanSweepWorker = newDatePlanSweepWorker(s.store.profileRepo.pg, s.log, datePlanSweepInterval)
		s.datePlanSweepWorker.Start(context.Background())
	}
	// Product analytics: nightly durable snapshots (migration 123).
	if s.store != nil && s.store.profileRepo != nil && s.store.profileRepo.pg != nil {
		s.analyticsSnapshotWorker = newAnalyticsSnapshotWorker(s.store.profileRepo.pg, s.log, analyticsSnapshotInterval)
		s.analyticsSnapshotWorker.Start(context.Background())
	}
	// XP award intents that could not reach the database are spooled locally
	// and replayed into the repair queue (PEN-22).
	if s.progression != nil {
		s.xpAwardSpool = newXPAwardSpool(defaultXPAwardSpoolPath(), s.log)
		s.xpAwardSpool.Start(context.Background(), s.progression.enqueueAwardRepair)
	}
	constructed = true
	return s, nil
}

func (s *Server) login(w http.ResponseWriter, r *http.Request) {
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	username := strings.TrimSpace(toString(payload["username"]))
	password := toString(payload["password"])

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(ctx, authapp.LoginCommandName, authapp.LoginCommand{Username: username, Password: password})
	if err != nil {
		if errors.Is(err, authapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusBadGateway, err)
		return
	}
	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected login response payload"))
		return
	}
	if success, _ := resp["success"].(bool); !success {
		message := strings.TrimSpace(toString(resp["error"]))
		if message == "" {
			message = "invalid username or password"
		}
		writeError(w, http.StatusUnauthorized, errors.New(message))
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) signup(w http.ResponseWriter, r *http.Request) {
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	if toString(payload["account_kind"]) == "introducer" {
		enabled, err := s.runtimeFeatureEnabled(r.Context(), "friend_intros_enabled", false)
		if err != nil || !enabled || s.cfg.IsReleaseExcluded("friend_intros_enabled") {
			writeError(w, http.StatusForbidden, errors.New("friend introductions are unavailable"))
			return
		}
	}
	username := strings.TrimSpace(toString(payload["username"]))
	password := toString(payload["password"])

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()
	respAny, err := s.mediator.Send(ctx, authapp.SignupCommandName, authapp.SignupCommand{Username: username, Password: password, AccountKind: toString(payload["account_kind"]), Name: toString(payload["name"]), DateOfBirth: toString(payload["date_of_birth"])})
	if err != nil {
		if errors.Is(err, authapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusBadGateway, err)
		return
	}
	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected signup response payload"))
		return
	}
	if success, _ := resp["success"].(bool); !success {
		message := strings.TrimSpace(toString(resp["error"]))
		if message == "" {
			message = "signup request was rejected"
		}
		code := http.StatusBadRequest
		if strings.Contains(strings.ToLower(message), "taken") {
			code = http.StatusConflict
		}
		writeError(w, code, errors.New(message))
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) Handler() http.Handler {
	return s.router
}

func (s *Server) validateDurableEngagementReadiness() error {
	if !s.cfg.RequireDurableEngagementStore {
		return nil
	}

	if (s.cfg.FeatureEngagementUnlockMVP || s.cfg.FeatureDigitalGestures) && s.store.questRepo == nil {
		return errors.New("durable engagement store required: quest/gesture persistence repository is unavailable")
	}

	unsupported := make([]string, 0, 3)
	if s.cfg.FeatureMiniActivities && s.activities == nil {
		unsupported = append(unsupported, "mini_activities")
	}
	if s.cfg.FeatureTrustBadges && s.trust == nil {
		unsupported = append(unsupported, "trust_badges")
	}
	if s.cfg.FeatureConversationRooms && s.rooms == nil {
		unsupported = append(unsupported, "conversation_rooms")
	}
	if len(unsupported) > 0 {
		return fmt.Errorf(
			"durable engagement store required but durable persistence is not implemented for features: %s",
			strings.Join(unsupported, ","),
		)
	}

	return nil
}

func (s *Server) validateNativePostgresReadiness() error {
	if !s.cfg.UseLocalDB {
		return nil
	}
	if s.runtimeData == nil || s.runtimeData.Mode() != "postgres" {
		return errors.New("native local mode requires the pgx runtime store")
	}
	missing := make([]string, 0)
	checks := []struct {
		name string
		ok   bool
	}{
		{"profile", s.store.profileRepo != nil},
		{"social", s.store.socialRepo != nil},
		{"verification", s.store.verificationRepo != nil},
		{"safety", s.store.safetyRepo != nil},
		{"engagement", s.store.engagementRepo != nil},
		{"quests", s.store.questRepo != nil},
		{"prompts", s.dailyPrompts != nil},
		{"activities", s.activities != nil},
		{"groups", s.store.communityGroupRepo != nil},
		{"gifts", s.store.giftsRepo != nil},
		{"spotlight", s.spotlight != nil},
		{"trust", s.trust != nil},
		{"rooms", s.rooms != nil},
		{"master_data", s.masterData != nil && s.masterData.db != nil},
		{"terms", s.termsAgreements != nil},
		{"admin", s.store.adminRepo != nil},
		{"billing", s.store.billingRepo != nil},
		{"chat_realtime", s.realtime != nil},
		{"progression", s.progression != nil},
	}
	for _, check := range checks {
		if !check.ok {
			missing = append(missing, check.name)
		}
	}
	if len(missing) > 0 {
		return fmt.Errorf("native postgres repositories unavailable: %s", strings.Join(missing, ","))
	}
	var scaleSchemaReady bool
	if err := s.store.profileRepo.pg.QueryRowContext(context.Background(), `
		SELECT to_regclass('platform.idempotency_records') IS NOT NULL
		   AND to_regclass('platform.idempotency_archive') IS NOT NULL
		   AND to_regclass('progression.xp_ledger') IS NOT NULL
		   AND to_regclass('progression.fraud_rule_policies') IS NOT NULL
		   AND to_regclass('progression.rollout_stage_history') IS NOT NULL
		   AND to_regclass('progression.production_health') IS NOT NULL
	`).Scan(&scaleSchemaReady); err != nil || !scaleSchemaReady {
		return errors.New("native postgres scale/progression schema unavailable: apply migrations through 079_progression_production_rollout")
	}
	return nil
}

func (s *Server) withAliasDeprecation(successorPath string, next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Deprecation", "true")
		w.Header().Set("Sunset", aliasRouteSunset)
		if strings.TrimSpace(successorPath) != "" {
			w.Header().Set("Link", fmt.Sprintf("<%s>; rel=\"successor-version\"", successorPath))
		}
		next.ServeHTTP(w, r)
	}
}

func (s *Server) activityMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		recorder := &responseStatusRecorder{
			ResponseWriter: w,
			status:         http.StatusOK,
		}

		next.ServeHTTP(recorder, r)

		if !strings.HasPrefix(r.URL.Path, s.cfg.APIPrefix) {
			return
		}
		// Request telemetry is minimised: route template instead of the
		// concrete path, no query string, no client IP (activity_repository.go).
		s.enqueueNonCriticalActivity(s.apiRequestActivityEvent(r, recorder.status, time.Since(start)))
	})
}

func (s *Server) withRequestTimeout(parent context.Context) (context.Context, context.CancelFunc) {
	return context.WithTimeout(parent, s.cfg.BFFRequestTimeout())
}

func (s *Server) Close() {
	if s.billing != nil {
		s.billing.stop()
	}
	if s.progressionWorker != nil {
		s.progressionWorker.Close()
	}
	if s.notificationWorker != nil {
		s.notificationWorker.Close()
	}
	if s.sosDeliveryWorker != nil {
		s.sosDeliveryWorker.Close()
	}
	if s.accountErasureWorker != nil {
		s.accountErasureWorker.Stop()
	}
	if s.trustRetentionWorker != nil {
		s.trustRetentionWorker.Stop()
	}
	if s.datePlanSweepWorker != nil {
		s.datePlanSweepWorker.Stop()
	}
	if s.analyticsSnapshotWorker != nil {
		s.analyticsSnapshotWorker.Stop()
	}
	if s.xpAwardSpool != nil {
		s.xpAwardSpool.Stop()
	}
	if s.mediaCleanupCancel != nil {
		s.mediaCleanupCancel()
	}
	if s.mediaCleanupDone != nil {
		<-s.mediaCleanupDone
	}
	if s.idempotencyCleanupCancel != nil {
		s.idempotencyCleanupCancel()
	}
	if s.idempotencyCleanupDone != nil {
		<-s.idempotencyCleanupDone
	}
	if s.authConn != nil {
		_ = s.authConn.Close()
	}
	if s.profileConn != nil {
		_ = s.profileConn.Close()
	}
	if s.matchingConn != nil {
		_ = s.matchingConn.Close()
	}
	if s.chatConn != nil {
		_ = s.chatConn.Close()
	}
	if s.fanout != nil {
		s.fanout.Close()
	}
	if s.runtimeData != nil {
		s.runtimeData.Close()
	}
}

func (s *Server) healthz(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]any{"service": "mobile-bff", "status": "ok"})
}

func (s *Server) readyz(w http.ResponseWriter, r *http.Request) {
	ready := true
	deps := map[string]any{
		"auth":     s.connState(s.authConn),
		"profile":  s.connState(s.profileConn),
		"matching": s.connState(s.matchingConn),
		"chat":     s.connState(s.chatConn),
	}
	if s.runtimeData != nil {
		ctx, cancel := context.WithTimeout(r.Context(), 2*time.Second)
		err := s.runtimeData.Ping(ctx)
		cancel()
		if err != nil {
			deps["postgres"] = "unavailable"
			ready = false
		} else {
			deps["postgres"] = "ready"
		}
	}
	if state, ok := s.aggregateOwnershipState(r.Context()); ok {
		deps["aggregate_ownership"] = state
	}
	for _, value := range deps {
		if !isHealthyConnState(toString(value)) {
			ready = false
		}
	}

	status := http.StatusOK
	if !ready {
		status = http.StatusServiceUnavailable
	}
	writeJSON(w, status, map[string]any{
		"service": "mobile-bff",
		"status":  ternary(ready, "ready", "degraded"),
		"deps":    deps,
	})
}

func isHealthyConnState(state string) bool {
	switch state {
	case connectivity.Ready.String(), connectivity.Idle.String(), connectivity.Connecting.String(), "ready":
		return true
	default:
		return false
	}
}

func (s *Server) bootstrapSignup(w http.ResponseWriter, r *http.Request) {
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}

	input := signupBootstrapInput{
		UserID:      strings.TrimSpace(toString(payload["user_id"])),
		Username:    strings.ToLower(strings.TrimSpace(toString(payload["username"]))),
		Name:        strings.TrimSpace(toString(payload["name"])),
		DateOfBirth: strings.TrimSpace(toString(payload["date_of_birth"])),
		Gender:      normalizeSignupGender(toString(payload["gender"])),
	}
	if err := validateSignupBootstrapInput(input); err != nil {
		writeError(w, http.StatusBadRequest, err)
		return
	}
	if s.cfg.UseLocalDB {
		authenticatedUserID, err := s.store.profileRepo.userIDForAccessToken(r.Context(), r.Header.Get("Authorization"))
		if err != nil || authenticatedUserID != input.UserID {
			writeError(w, http.StatusUnauthorized, errors.New("valid signup session is required"))
			return
		}
	}

	draft, created, err := s.store.bootstrapSignup(input)
	if err != nil {
		if errors.Is(err, errSignupUsernameAlreadyExists) {
			writeError(w, http.StatusConflict, err)
			return
		}
		writeError(w, http.StatusBadGateway, err)
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"success":        true,
		"user_id":        input.UserID,
		"created":        created,
		"terms_required": true,
		"profile_status": map[string]any{
			"profile_completion":  draft.ProfileCompletion,
			"has_required_basics": strings.TrimSpace(draft.Name) != "" && strings.TrimSpace(draft.DateOfBirth) != "" && strings.TrimSpace(draft.Gender) != "",
		},
		"draft": draft,
	})
}

func (s *Server) getSignupWorkflow(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	if userID == "" || s.store.profileRepo == nil || s.store.profileRepo.pg == nil {
		writeError(w, http.StatusBadRequest, errors.New("local signup workflow is unavailable"))
		return
	}
	authenticatedUserID, err := s.store.profileRepo.userIDForAccessToken(r.Context(), r.Header.Get("Authorization"))
	if err != nil || authenticatedUserID != userID {
		writeError(w, http.StatusUnauthorized, errors.New("valid signup session is required"))
		return
	}
	status, err := s.store.profileRepo.getSignupWorkflow(r.Context(), userID)
	if err != nil {
		writeError(w, http.StatusNotFound, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"user_id":          status.UserID,
		"username":         status.Username,
		"state":            status.State,
		"current_activity": status.CurrentActivity,
		"lock_version":     status.LockVersion,
		"signup_required":  status.SignupRequired,
		"updated_at":       status.UpdatedAt,
	})
}

func normalizeSignupGender(input string) string {
	switch strings.ToLower(strings.TrimSpace(input)) {
	case "m", "male", "man":
		return "M"
	case "f", "female", "woman":
		return "F"
	case "other", "nonbinary", "non-binary":
		return "Other"
	default:
		return strings.TrimSpace(input)
	}
}

func validateSignupBootstrapInput(input signupBootstrapInput) error {
	if strings.TrimSpace(input.UserID) == "" {
		return errors.New("user_id is required")
	}
	if _, err := authdomain.NewUsername(input.Username); err != nil {
		return errors.New("valid username is required")
	}
	return validateProfileBasics(input.Name, input.DateOfBirth, input.Gender, time.Now().UTC())
}

func validateProfileBasics(name, dateOfBirth, gender string, now time.Time) error {
	if n := len([]rune(strings.TrimSpace(name))); n < 2 || n > 50 {
		return errors.New("name must be 2-50 characters")
	}
	if gender != "M" && gender != "F" && gender != "Other" {
		return errors.New("gender must be M, F, or Other")
	}
	dob, err := time.Parse("2006-01-02", strings.TrimSpace(dateOfBirth))
	if err != nil {
		return errors.New("date_of_birth must use YYYY-MM-DD")
	}
	now = now.UTC()
	age := now.Year() - dob.Year()
	if now.Month() < dob.Month() || (now.Month() == dob.Month() && now.Day() < dob.Day()) {
		age--
	}
	if age < 18 {
		return errors.New("user must be at least 18 years old")
	}
	if age > 80 {
		return errors.New("date_of_birth is outside supported age range")
	}
	return nil
}

func (s *Server) getProfile(w http.ResponseWriter, r *http.Request) {
	principal, ok := r.Context().Value(securityPrincipalContextKey{}).(securityPrincipal)
	if !ok || principal.UserID == "" {
		writeError(w, http.StatusUnauthorized, errors.New("valid bearer session is required"))
		return
	}
	if s.store == nil || s.store.profileRepo == nil || s.store.profileRepo.pg == nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("public profile persistence is unavailable"))
		return
	}
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	if _, err := uuid.Parse(userID); err != nil {
		writeError(w, http.StatusBadRequest, errors.New("valid profile id is required"))
		return
	}
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()
	profile, found, err := loadPublicProfile(ctx, s.store.profileRepo.pg, principal.UserID, userID)
	if err != nil {
		s.log.Error("public_profile_read_failed", zap.Error(err))
		writeError(w, http.StatusServiceUnavailable, errors.New("profile is temporarily unavailable"))
		return
	}
	if !found {
		// Do not distinguish nonexistent, blocked, restricted or unpublished users.
		writeError(w, http.StatusNotFound, errors.New("profile is unavailable"))
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"profile": profile, "found": true})
}

func (s *Server) getProfileSummary(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()
	respAny, err := s.mediator.Send(
		ctx,
		profileapp.GetProfileSummaryCommandName,
		profileapp.GetProfileSummaryCommand{UserID: userID},
	)
	if err != nil {
		if errors.Is(err, profileapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusBadGateway, err)
		return
	}
	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected get profile summary response payload"))
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) upsertProfile(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))

	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	profile, _ := payload["profile"].(map[string]any)
	if profile == nil {
		profile = map[string]any{}
	}
	profile["id"] = userID

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		profileapp.UpsertProfileCommandName,
		profileapp.UpsertProfileCommand{UserID: userID, Profile: profile},
	)
	if err != nil {
		if errors.Is(err, profileapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusBadGateway, err)
		return
	}
	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected upsert profile response payload"))
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) getDiscoveryCandidates(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	mode := strings.ToLower(strings.TrimSpace(r.URL.Query().Get("mode")))

	limit := 25
	if raw := r.URL.Query().Get("limit"); raw != "" {
		if parsed, err := strconv.Atoi(raw); err == nil && parsed > 0 && parsed <= 300 {
			limit = parsed
		}
	}
	requestedLimit := limit
	// Publication and blocking can remove candidates even without a manual
	// filter. Fetch a larger pool before applying those mandatory gates.
	limit = min(max(limit*6, 150), 300)

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		matchingapp.GetCandidatesCommandName,
		matchingapp.GetCandidatesCommand{UserID: userID, Limit: limit},
	)
	if err != nil {
		if errors.Is(err, matchingapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusBadGateway, err)
		return
	}
	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected discovery candidates response payload"))
		return
	}
	// Applied before trimming so the deck is filled to the requested limit
	// from members the viewer may actually see, rather than trimmed first and
	// then punched full of holes.
	s.attachBlockedFilteredDiscovery(ctx, resp, userID)
	if s.cfg.UseLocalDB || (s.store != nil && s.store.profileRepo != nil && s.store.profileRepo.pg != nil) {
		if s.store == nil || s.store.profileRepo == nil || s.store.profileRepo.pg == nil {
			writeError(w, http.StatusServiceUnavailable, errors.New("discovery publication persistence is unavailable"))
			return
		}
		if err := filterPublishedDiscovery(ctx, s.store.profileRepo.pg, userID, resp, s.buildAdvancedCriteria(userID, s.discoveryPreferenceQuery(userID, r.URL.Query()))); err != nil {
			s.log.Error("discovery_publication_failed", zap.Error(err))
			writeError(w, http.StatusServiceUnavailable, errors.New("discovery is temporarily unavailable"))
			return
		}
		// Graduated or manually paused members are dealt to nobody; a paused
		// viewer gets an empty deck with discovery_paused explaining why.
		s.attachPausedFilteredDiscovery(ctx, resp, userID)
	}
	if _, filtered := resp["advanced_filter"]; !filtered {
		s.attachAdvancedFilteredDiscovery(resp, userID, r.URL.Query())
	}
	s.attachTrustFilteredDiscovery(resp, userID)
	trimDiscoveryCandidates(resp, requestedLimit)
	s.attachSpotlightDiscoveryWithContext(r.Context(), resp, userID)

	applyDiscoveryMode(resp, mode)
	// Explainability chips: every candidate carries `reasons` (possibly
	// empty); today's curated set supplies them for its members.
	attachDiscoveryReasons(resp, s.curatedReasonsForDeck(ctx, userID))
	writeJSON(w, http.StatusOK, resp)
}

func applyDiscoveryMode(resp map[string]any, mode string) {
	if mode != "spotlight" {
		return
	}

	spotlightProfiles, ok := resp["spotlight_profiles"].([]any)
	if !ok {
		return
	}

	resp["candidates"] = spotlightProfiles
	resp["discovery_mode"] = "spotlight"
}

func (s *Server) swipe(w http.ResponseWriter, r *http.Request) {
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}

	if like, _ := payload["is_like"].(bool); like {
		if !s.enforceDailyQuota(w, r, s.requestUserID(r, toString(payload["user_id"])), "like") {
			return
		}
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(ctx, matchingapp.SwipeCommandName, matchingapp.SwipeCommand{Payload: payload})
	if err != nil {
		if errors.Is(err, matchingapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusBadGateway, err)
		return
	}
	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected swipe response payload"))
		return
	}
	targetUserID := strings.TrimSpace(toString(payload["target_user_id"]))
	isLike, _ := payload["is_like"].(bool)
	isMutualMatch := resp["mutual_match"] == true || strings.TrimSpace(toString(resp["match_id"])) != ""
	if s.spotlight != nil {
		if err := s.spotlight.recordSpotlightSwipeOutcome(r.Context(), targetUserID, isLike, isMutualMatch); err != nil {
			if !isSpotlightRepoPersistenceUnavailable(err) || s.cfg.RequireDurableEngagementStore {
				s.log.Warn("failed to persist spotlight swipe outcome", zap.Error(err))
			} else {
				s.store.recordSpotlightSwipeOutcome(targetUserID, isLike, isMutualMatch)
			}
		}
	} else {
		s.store.recordSpotlightSwipeOutcome(targetUserID, isLike, isMutualMatch)
	}
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) listMatches(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(ctx, matchingapp.ListMatchesCommandName, matchingapp.ListMatchesCommand{UserID: userID})
	if err != nil {
		if errors.Is(err, matchingapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusBadGateway, err)
		return
	}
	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected list matches response payload"))
		return
	}
	s.attachQuestTemplates(resp)
	s.attachQuestWorkflows(resp)
	s.attachUnlockStates(resp)
	s.attachAdvancedFilteredMatches(resp, userID, r.URL.Query())
	s.attachTrustFilteredMatches(resp, userID)
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) getMatchUnlockState(w http.ResponseWriter, r *http.Request) {
	matchID := strings.TrimSpace(chi.URLParam(r, "matchID"))
	if matchID == "" {
		writeError(w, http.StatusBadRequest, errors.New("match id is required"))
		return
	}

	unlockState, hasRequirement := s.store.getMatchUnlockState(matchID)
	chatUnlocked, _, err := s.store.isChatUnlocked(matchID)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"match_id":              matchID,
		"unlock_state":          unlockState,
		"has_requirement":       hasRequirement,
		"chat_unlocked":         chatUnlocked,
		"unlock_policy_variant": s.store.unlockPolicyVariant(),
	})
}

func (s *Server) getMatchQuestTemplate(w http.ResponseWriter, r *http.Request) {
	matchID := strings.TrimSpace(chi.URLParam(r, "matchID"))

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		matchingapp.GetQuestTemplateCommandName,
		matchingapp.GetQuestTemplateCommand{MatchID: matchID},
	)
	if err != nil {
		if errors.Is(err, matchingapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusBadGateway, err)
		return
	}
	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected quest template response payload"))
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) upsertMatchQuestTemplate(w http.ResponseWriter, r *http.Request) {
	matchID := strings.TrimSpace(chi.URLParam(r, "matchID"))
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}

	creatorUserID := strings.TrimSpace(toString(payload["creator_user_id"]))
	prompt := strings.TrimSpace(toString(payload["prompt_template"]))
	minChars, _ := toInt(payload["min_chars"])
	maxChars, _ := toInt(payload["max_chars"])

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		matchingapp.UpsertQuestTemplateCommandName,
		matchingapp.UpsertQuestTemplateCommand{
			MatchID:       matchID,
			CreatorUserID: creatorUserID,
			Prompt:        prompt,
			MinChars:      minChars,
			MaxChars:      maxChars,
		},
	)
	if err != nil {
		if errors.Is(err, matchingapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusBadGateway, err)
		return
	}
	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected upsert quest template response payload"))
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) getMatchQuestWorkflow(w http.ResponseWriter, r *http.Request) {
	matchID := strings.TrimSpace(chi.URLParam(r, "matchID"))

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		matchingapp.GetQuestWorkflowCommandName,
		matchingapp.GetQuestWorkflowCommand{MatchID: matchID},
	)
	if err != nil {
		if errors.Is(err, matchingapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusBadGateway, err)
		return
	}
	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected quest workflow response payload"))
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) submitMatchQuestResponse(w http.ResponseWriter, r *http.Request) {
	matchID := strings.TrimSpace(chi.URLParam(r, "matchID"))
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}

	submitterUserID := strings.TrimSpace(toString(payload["submitter_user_id"]))
	responseText := strings.TrimSpace(toString(payload["response_text"]))

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		matchingapp.SubmitQuestResponseCommandName,
		matchingapp.SubmitQuestResponseCommand{
			MatchID:         matchID,
			SubmitterUserID: submitterUserID,
			ResponseText:    responseText,
		},
	)
	if err != nil {
		if errors.Is(err, matchingapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusBadGateway, err)
		return
	}
	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected submit quest response payload"))
		return
	}
	details := map[string]any{
		"match_id":          matchID,
		"submitter_user_id": submitterUserID,
		"response_length":   len(responseText),
	}
	if workflowAny, exists := resp["quest_workflow"]; exists {
		if workflow, ok := workflowAny.(map[string]any); ok {
			details["unlock_state"] = toString(workflow["unlock_state"])
			details["workflow_status"] = toString(workflow["status"])
			reviewReason := toString(workflow["review_reason"])
			if reviewReason != "" {
				details["review_reason"] = reviewReason
			}
			if strings.HasPrefix(reviewReason, autoReviewReasonPrefix) {
				details["assisted_auto_approved"] = true
				s.enqueueNonCriticalActivity(activityEvent{
					UserID:   matchID,
					Actor:    submitterUserID,
					Action:   "quest.review.auto",
					Status:   "success",
					Resource: "/matches/" + matchID + "/quest-workflow/submit",
					Details: mergeDetails(
						map[string]any{
							"match_id":      matchID,
							"review_reason": reviewReason,
						},
						s.engagementTelemetryDetails(r.URL.Path),
					),
				})
			}
		}
	}
	s.enqueueNonCriticalActivity(activityEvent{
		UserID:   matchID,
		Actor:    submitterUserID,
		Action:   "quest.submit",
		Status:   "success",
		Resource: "/matches/" + matchID + "/quest-workflow/submit",
		Details:  mergeDetails(details, s.engagementTelemetryDetails(r.URL.Path)),
	})
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) reviewMatchQuestResponse(w http.ResponseWriter, r *http.Request) {
	matchID := strings.TrimSpace(chi.URLParam(r, "matchID"))
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}

	reviewerUserID := strings.TrimSpace(toString(payload["reviewer_user_id"]))
	decisionStatus := strings.TrimSpace(toString(payload["decision_status"]))
	reviewReason := strings.TrimSpace(toString(payload["review_reason"]))

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		matchingapp.ReviewQuestResponseCommandName,
		matchingapp.ReviewQuestResponseCommand{
			MatchID:        matchID,
			ReviewerUserID: reviewerUserID,
			DecisionStatus: decisionStatus,
			ReviewReason:   reviewReason,
		},
	)
	if err != nil {
		if errors.Is(err, matchingapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusBadGateway, err)
		return
	}
	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected review quest response payload"))
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) listMatchTimeline(w http.ResponseWriter, r *http.Request) {
	matchID := strings.TrimSpace(chi.URLParam(r, "matchID"))

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		matchingapp.ListGestureTimelineCommandName,
		matchingapp.ListGestureTimelineCommand{MatchID: matchID},
	)
	if err != nil {
		if errors.Is(err, matchingapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusBadGateway, err)
		return
	}
	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected list timeline response payload"))
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) createMatchGesture(w http.ResponseWriter, r *http.Request) {
	matchID := strings.TrimSpace(chi.URLParam(r, "matchID"))
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}

	senderUserID := strings.TrimSpace(toString(payload["sender_user_id"]))
	receiverUserID := strings.TrimSpace(toString(payload["receiver_user_id"]))
	gestureType := strings.TrimSpace(toString(payload["gesture_type"]))
	contentText := strings.TrimSpace(toString(payload["content_text"]))
	tone := strings.TrimSpace(toString(payload["tone"]))

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		matchingapp.CreateGestureCommandName,
		matchingapp.CreateGestureCommand{
			MatchID:        matchID,
			SenderUserID:   senderUserID,
			ReceiverUserID: receiverUserID,
			GestureType:    gestureType,
			ContentText:    contentText,
			Tone:           tone,
		},
	)
	if err != nil {
		if errors.Is(err, matchingapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusBadGateway, err)
		return
	}
	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected create gesture response payload"))
		return
	}
	s.store.recordActivity(activityEvent{
		UserID:   matchID,
		Actor:    senderUserID,
		Action:   "gesture.create",
		Status:   "success",
		Resource: "/matches/" + matchID + "/gestures",
		Details: map[string]any{
			"match_id":     matchID,
			"gesture_type": gestureType,
			"receiver_id":  receiverUserID,
		},
	})
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) decideMatchGesture(w http.ResponseWriter, r *http.Request) {
	matchID := strings.TrimSpace(chi.URLParam(r, "matchID"))
	gestureID := strings.TrimSpace(chi.URLParam(r, "gestureID"))
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}

	reviewerUserID := strings.TrimSpace(toString(payload["reviewer_user_id"]))
	decision := strings.TrimSpace(toString(payload["decision"]))
	reason := strings.TrimSpace(toString(payload["reason"]))

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		matchingapp.DecideGestureCommandName,
		matchingapp.DecideGestureCommand{
			MatchID:        matchID,
			GestureID:      gestureID,
			ReviewerUserID: reviewerUserID,
			Decision:       decision,
			Reason:         reason,
		},
	)
	if err != nil {
		if errors.Is(err, matchingapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusBadGateway, err)
		return
	}
	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected gesture decision response payload"))
		return
	}
	s.store.recordActivity(activityEvent{
		UserID:   matchID,
		Actor:    reviewerUserID,
		Action:   "gesture.decision",
		Status:   "success",
		Resource: "/matches/" + matchID + "/gestures/" + gestureID + "/decision",
		Details: map[string]any{
			"match_id":   matchID,
			"gesture_id": gestureID,
			"decision":   decision,
			"reason":     reason,
		},
	})
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) getGestureScore(w http.ResponseWriter, r *http.Request) {
	matchID := strings.TrimSpace(chi.URLParam(r, "matchID"))
	gestureID := strings.TrimSpace(chi.URLParam(r, "gestureID"))

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		matchingapp.GetGestureScoreCommandName,
		matchingapp.GetGestureScoreCommand{MatchID: matchID, GestureID: gestureID},
	)
	if err != nil {
		if errors.Is(err, matchingapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusBadGateway, err)
		return
	}
	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected gesture score response payload"))
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) attachQuestTemplates(resp map[string]any) {
	matchesRaw, ok := resp["matches"].([]any)
	if !ok || len(matchesRaw) == 0 {
		return
	}

	matchIDs := make([]string, 0, len(matchesRaw))
	for _, item := range matchesRaw {
		row, ok := item.(map[string]any)
		if !ok {
			continue
		}
		matchID := strings.TrimSpace(toString(row["id"]))
		if matchID == "" {
			continue
		}
		matchIDs = append(matchIDs, matchID)
	}

	if len(matchIDs) == 0 {
		return
	}

	templatesByMatchID := s.store.listQuestTemplatesByMatchIDs(matchIDs)
	if len(templatesByMatchID) == 0 {
		return
	}

	for idx, item := range matchesRaw {
		row, ok := item.(map[string]any)
		if !ok {
			continue
		}
		matchID := strings.TrimSpace(toString(row["id"]))
		template, found := templatesByMatchID[matchID]
		if !found {
			continue
		}
		row["quest_template"] = template
		matchesRaw[idx] = row
	}
	resp["matches"] = matchesRaw
}

func (s *Server) attachQuestWorkflows(resp map[string]any) {
	matchesRaw, ok := resp["matches"].([]any)
	if !ok || len(matchesRaw) == 0 {
		return
	}

	matchIDs := make([]string, 0, len(matchesRaw))
	for _, item := range matchesRaw {
		row, ok := item.(map[string]any)
		if !ok {
			continue
		}
		matchID := strings.TrimSpace(toString(row["id"]))
		if matchID == "" {
			continue
		}
		matchIDs = append(matchIDs, matchID)
	}

	if len(matchIDs) == 0 {
		return
	}

	workflowsByMatchID := s.store.listQuestWorkflowsByMatchIDs(matchIDs)
	if len(workflowsByMatchID) == 0 {
		return
	}

	for idx, item := range matchesRaw {
		row, ok := item.(map[string]any)
		if !ok {
			continue
		}
		matchID := strings.TrimSpace(toString(row["id"]))
		workflow, found := workflowsByMatchID[matchID]
		if !found {
			continue
		}
		row["quest_workflow"] = workflow
		if unlockState := strings.TrimSpace(toString(workflow.UnlockState)); unlockState != "" {
			row["unlock_state"] = unlockState
		}
		matchesRaw[idx] = row
	}
	resp["matches"] = matchesRaw
}

func (s *Server) attachUnlockStates(resp map[string]any) {
	matchesRaw, ok := resp["matches"].([]any)
	if !ok || len(matchesRaw) == 0 {
		return
	}

	matchIDs := make([]string, 0, len(matchesRaw))
	for _, item := range matchesRaw {
		row, ok := item.(map[string]any)
		if !ok {
			continue
		}
		matchID := strings.TrimSpace(toString(row["id"]))
		if matchID == "" {
			continue
		}
		matchIDs = append(matchIDs, matchID)
	}
	if len(matchIDs) == 0 {
		return
	}

	statesByMatchID := s.store.listMatchUnlockStatesByMatchIDs(matchIDs)
	for idx, item := range matchesRaw {
		row, ok := item.(map[string]any)
		if !ok {
			continue
		}
		if _, exists := row["unlock_state"]; exists {
			matchesRaw[idx] = row
			continue
		}
		matchID := strings.TrimSpace(toString(row["id"]))
		if state, found := statesByMatchID[matchID]; found && strings.TrimSpace(state) != "" {
			row["unlock_state"] = state
		} else {
			row["unlock_state"] = "matched"
		}
		matchesRaw[idx] = row
	}
	resp["matches"] = matchesRaw
}

func (s *Server) unmatch(w http.ResponseWriter, r *http.Request) {
	matchID := strings.TrimSpace(chi.URLParam(r, "matchID"))
	userID := strings.TrimSpace(r.URL.Query().Get("user_id"))
	if matchID == "" || userID == "" {
		writeError(w, http.StatusBadRequest, errors.New("match id and user id are required"))
		return
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		matchingapp.UnmatchCommandName,
		matchingapp.UnmatchCommand{MatchID: matchID, UserID: userID},
	)
	if err != nil {
		if errors.Is(err, matchingapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusBadGateway, err)
		return
	}
	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected unmatch response payload"))
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) markMatchRead(w http.ResponseWriter, r *http.Request) {
	matchID := strings.TrimSpace(chi.URLParam(r, "matchID"))
	if matchID == "" {
		writeError(w, http.StatusBadRequest, errors.New("match id is required"))
		return
	}

	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		matchingapp.MarkAsReadCommandName,
		matchingapp.MarkAsReadCommand{MatchID: matchID, Payload: payload},
	)
	if err != nil {
		if errors.Is(err, matchingapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusBadGateway, err)
		return
	}
	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected mark read response payload"))
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) listMessages(w http.ResponseWriter, r *http.Request) {
	matchID := strings.TrimSpace(chi.URLParam(r, "matchID"))

	limit := 50
	if raw := r.URL.Query().Get("limit"); raw != "" {
		if parsed, err := strconv.Atoi(raw); err == nil {
			limit = parsed
		}
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		chatapp.ListMessagesCommandName,
		chatapp.ListMessagesCommand{MatchID: matchID, Limit: limit},
	)
	if err != nil {
		if errors.Is(err, chatapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusBadGateway, err)
		return
	}
	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected list messages response payload"))
		return
	}
	if principal, authenticated := principalFromRequest(r); authenticated {
		s.attachAssistMarks(ctx, matchID, resp)
		if err = s.filterHiddenReceivedGiftMessages(ctx, principal, matchID, resp); err != nil {
			writeError(w, http.StatusServiceUnavailable, errors.New("gift visibility controls are unavailable"))
			return
		}
	}
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) sendMessage(w http.ResponseWriter, r *http.Request) {
	matchID := strings.TrimSpace(chi.URLParam(r, "matchID"))
	if matchID == "" {
		writeError(w, http.StatusBadRequest, errors.New("match id is required"))
		return
	}

	payload, ok := readJSON(w, r)
	if !ok {
		return
	}

	chatUnlocked, unlockState, err := s.store.isChatUnlocked(matchID)
	if err != nil {
		writeError(w, http.StatusBadGateway, err)
		return
	}
	if !chatUnlocked {
		s.enqueueNonCriticalActivity(activityEvent{
			UserID:   matchID,
			Actor:    strings.TrimSpace(toString(payload["sender_id"])),
			Action:   "chat.locked",
			Status:   "client_error",
			Resource: "/chat/" + matchID + "/messages",
			Details: mergeDetails(
				map[string]any{
					"match_id":     matchID,
					"unlock_state": unlockState,
				},
				s.engagementTelemetryDetails(r.URL.Path),
			),
		})

		writeJSON(w, http.StatusLocked, map[string]any{
			"success":               false,
			"error":                 "chat is locked until quest requirement is completed",
			"error_code":            "CHAT_LOCKED_REQUIREMENT_PENDING",
			"match_id":              matchID,
			"unlock_state":          unlockState,
			"unlock_policy_variant": s.store.unlockPolicyVariant(),
		})
		return
	}

	if !s.enforceDailyQuota(w, r, s.requestUserID(r, toString(payload["sender_id"])), "message") {
		return
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		chatapp.SendMessageCommandName,
		chatapp.SendMessageCommand{MatchID: matchID, Payload: payload},
	)
	if err != nil {
		if errors.Is(err, chatapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusBadGateway, err)
		return
	}
	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected send message response payload"))
		return
	}
	// A message that started as a copilot draft carries an honest mark.
	s.markAssistedMessageSend(ctx, matchID, s.requestUserID(r, toString(payload["sender_id"])), payload, resp)
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) deleteMessage(w http.ResponseWriter, r *http.Request) {
	matchID := strings.TrimSpace(chi.URLParam(r, "matchID"))
	messageID := strings.TrimSpace(chi.URLParam(r, "messageID"))
	if matchID == "" || messageID == "" {
		writeError(w, http.StatusBadRequest, errors.New("match id and message id are required"))
		return
	}

	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	requesterUserID := strings.TrimSpace(toString(payload["requester_user_id"]))
	if requesterUserID == "" {
		writeError(w, http.StatusBadRequest, errors.New("requester_user_id is required"))
		return
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		chatapp.DeleteMessageCommandName,
		chatapp.DeleteMessageCommand{
			MatchID: matchID,
			Payload: map[string]any{
				"message_id":        messageID,
				"requester_user_id": requesterUserID,
			},
		},
	)
	if err != nil {
		if errors.Is(err, chatapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusBadGateway, err)
		return
	}
	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected delete message response payload"))
		return
	}
	deleted, _ := resp["deleted"].(bool)
	reasonCode := strings.TrimSpace(toString(resp["reason_code"]))
	audit := s.store.trackMessageDeleteAudit(requesterUserID, deleted)
	s.store.recordActivity(activityEvent{
		UserID: requesterUserID,
		Actor:  requesterUserID,
		Action: "chat.message.delete",
		Status: func() string {
			if deleted {
				return "success"
			}
			return "client_error"
		}(),
		Resource: "/chat/" + matchID + "/messages/" + messageID,
		Details: mergeDetails(
			map[string]any{
				"match_id":    matchID,
				"message_id":  messageID,
				"deleted":     deleted,
				"reason_code": reasonCode,
			},
			audit,
		),
	})

	if !deleted {
		if reasonCode == "DELETE_WINDOW_EXPIRED" {
			writeJSON(w, http.StatusConflict, map[string]any{
				"deleted":     false,
				"message_id":  messageID,
				"reason_code": reasonCode,
				"error":       "delete window expired (24h)",
			})
			return
		}
		writeJSON(w, http.StatusNotFound, map[string]any{
			"deleted":     false,
			"message_id":  messageID,
			"reason_code": reasonCode,
			"error":       "message not found or not owned by requester",
		})
		return
	}

	writeJSON(w, http.StatusOK, mergeDetails(resp, audit))
}

func (s *Server) startActivitySession(w http.ResponseWriter, r *http.Request) {
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}

	matchID := strings.TrimSpace(toString(payload["match_id"]))
	initiatorUserID := strings.TrimSpace(toString(payload["initiator_user_id"]))
	participantUserID := strings.TrimSpace(toString(payload["participant_user_id"]))
	activityType := strings.TrimSpace(toString(payload["activity_type"]))
	metadata, _ := payload["metadata"].(map[string]any)

	var (
		session activitySession
		err     error
	)
	if s.activities != nil {
		session, err = s.activities.startActivitySession(
			r.Context(),
			matchID,
			initiatorUserID,
			participantUserID,
			activityType,
			metadata,
		)
		if err != nil && (!isActivityRepoPersistenceUnavailable(err) || s.cfg.RequireDurableEngagementStore) {
			writeError(w, http.StatusBadGateway, err)
			return
		}
	}
	if s.activities == nil || (err != nil && isActivityRepoPersistenceUnavailable(err) && !s.cfg.RequireDurableEngagementStore) {
		session, err = s.store.startActivitySession(
			matchID,
			initiatorUserID,
			participantUserID,
			activityType,
			metadata,
		)
	}
	if err != nil {
		writeError(w, http.StatusBadRequest, err)
		return
	}

	s.store.recordActivity(activityEvent{
		UserID:   matchID,
		Actor:    initiatorUserID,
		Action:   "activity.session.start",
		Status:   "success",
		Resource: "/activities/sessions/start",
		Details: map[string]any{
			"session_id":       session.ID,
			"participant_user": participantUserID,
			"activity_type":    session.ActivityType,
		},
	})

	s.store.recordActivity(activityEvent{
		UserID:   initiatorUserID,
		Actor:    initiatorUserID,
		Action:   "mini_activity_started",
		Status:   "success",
		Resource: "/activities/sessions/start",
		Details: map[string]any{
			"match_id":      session.MatchID,
			"session_id":    session.ID,
			"user_id":       initiatorUserID,
			"activity_type": session.ActivityType,
		},
	})

	writeJSON(w, http.StatusOK, map[string]any{
		"session": session,
	})
}

func (s *Server) submitActivitySession(w http.ResponseWriter, r *http.Request) {
	sessionID := strings.TrimSpace(chi.URLParam(r, "sessionID"))
	if sessionID == "" {
		writeError(w, http.StatusBadRequest, errors.New("session id is required"))
		return
	}

	payload, ok := readJSON(w, r)
	if !ok {
		return
	}

	userID := strings.TrimSpace(toString(payload["user_id"]))
	responses, _ := toStringSlice(payload["responses"])

	var (
		session activitySession
		err     error
	)
	if s.activities != nil {
		session, err = s.activities.submitActivitySessionResponses(r.Context(), sessionID, userID, responses)
		if err != nil && (!isActivityRepoPersistenceUnavailable(err) || s.cfg.RequireDurableEngagementStore) {
			errMsg := strings.ToLower(err.Error())
			if strings.Contains(errMsg, "expired") {
				writeError(w, http.StatusRequestTimeout, err)
				return
			}
			if strings.Contains(errMsg, "completed") {
				writeError(w, http.StatusConflict, err)
				return
			}
			if strings.Contains(errMsg, "not found") {
				writeError(w, http.StatusNotFound, err)
				return
			}
			writeError(w, http.StatusBadGateway, err)
			return
		}
	}
	if s.activities == nil || (err != nil && isActivityRepoPersistenceUnavailable(err) && !s.cfg.RequireDurableEngagementStore) {
		session, err = s.store.submitActivitySessionResponses(sessionID, userID, responses)
	}
	if err != nil {
		errMsg := strings.ToLower(err.Error())
		if strings.Contains(errMsg, "expired") {
			writeError(w, http.StatusRequestTimeout, err)
			return
		}
		if strings.Contains(errMsg, "completed") {
			writeError(w, http.StatusConflict, err)
			return
		}
		if strings.Contains(errMsg, "not found") {
			writeError(w, http.StatusNotFound, err)
			return
		}
		writeError(w, http.StatusBadRequest, err)
		return
	}

	s.store.recordActivity(activityEvent{
		UserID:   session.MatchID,
		Actor:    userID,
		Action:   "activity.session.submit",
		Status:   "success",
		Resource: "/activities/sessions/" + sessionID + "/submit",
		Details: map[string]any{
			"session_id":          sessionID,
			"responses_submitted": len(responses),
			"session_status":      session.Status,
		},
	})

	if session.Status == activitySessionStatusCompleted {
		s.store.recordActivity(activityEvent{
			UserID:   userID,
			Actor:    userID,
			Action:   "mini_activity_completed",
			Status:   "success",
			Resource: "/activities/sessions/" + sessionID + "/submit",
			Details: map[string]any{
				"match_id":            session.MatchID,
				"session_id":          sessionID,
				"user_id":             userID,
				"activity_type":       session.ActivityType,
				"responses_submitted": len(responses),
			},
		})
		s.awardProgression(r.Context(), xpAwardInput{
			UserID: userID, Source: "mini_activity_completed", SourceEventID: sessionID,
			IdempotencyKey: "mini_activity_completed:" + sessionID + ":" + userID,
			Metadata:       map[string]any{"activity_type": session.ActivityType, "match_id": session.MatchID},
		})
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"session": session,
	})
}

func (s *Server) getActivitySessionSummary(w http.ResponseWriter, r *http.Request) {
	sessionID := strings.TrimSpace(chi.URLParam(r, "sessionID"))
	if sessionID == "" {
		writeError(w, http.StatusBadRequest, errors.New("session id is required"))
		return
	}
	viewerUserID := strings.TrimSpace(r.URL.Query().Get("user_id"))

	var (
		summary activitySessionSummary
		session activitySession
		err     error
	)
	if s.activities != nil {
		summary, session, err = s.activities.getActivitySessionSummary(r.Context(), sessionID)
		if err != nil && (!isActivityRepoPersistenceUnavailable(err) || s.cfg.RequireDurableEngagementStore) {
			if strings.Contains(strings.ToLower(err.Error()), "not found") {
				writeError(w, http.StatusNotFound, err)
				return
			}
			writeError(w, http.StatusBadGateway, err)
			return
		}
	}
	if s.activities == nil || (err != nil && isActivityRepoPersistenceUnavailable(err) && !s.cfg.RequireDurableEngagementStore) {
		summary, session, err = s.store.getActivitySessionSummary(sessionID)
	}
	if err != nil {
		if strings.Contains(strings.ToLower(err.Error()), "not found") {
			writeError(w, http.StatusNotFound, err)
			return
		}
		writeError(w, http.StatusBadRequest, err)
		return
	}

	if viewerUserID != "" {
		s.store.recordActivity(activityEvent{
			UserID:   viewerUserID,
			Actor:    viewerUserID,
			Action:   "mini_activity_shared",
			Status:   "success",
			Resource: "/activities/sessions/" + sessionID + "/summary",
			Details: map[string]any{
				"match_id":       session.MatchID,
				"session_id":     sessionID,
				"user_id":        viewerUserID,
				"activity_type":  session.ActivityType,
				"summary_status": summary.Status,
			},
		})
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"summary": summary,
		"session": session,
	})
}

func (s *Server) getDailyPrompt(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	if userID == "" {
		writeError(w, http.StatusBadRequest, errors.New("user id is required"))
		return
	}
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		engagementapp.GetDailyPromptCommandName,
		engagementapp.GetDailyPromptCommand{UserID: userID},
	)
	if err != nil {
		if errors.Is(err, engagementapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		errMsg := strings.ToLower(err.Error())
		if strings.Contains(errMsg, "not found") {
			writeError(w, http.StatusNotFound, err)
			return
		}
		writeError(w, http.StatusBadRequest, err)
		return
	}

	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected get daily prompt response payload"))
		return
	}
	view, _ := resp["daily_prompt"].(map[string]any)
	prompt, _ := view["prompt"].(map[string]any)
	answer, hasAnswer := view["answer"]
	_, hasAnswered := answer.(map[string]any)
	if !hasAnswered {
		hasAnswered = hasAnswer && answer != nil
	}

	s.store.recordActivity(activityEvent{
		UserID:   userID,
		Actor:    userID,
		Action:   "daily_prompt_viewed",
		Status:   "success",
		Resource: "/engagement/daily-prompt/" + userID,
		Details: map[string]any{
			"user_id":      userID,
			"prompt_id":    toString(prompt["id"]),
			"prompt_date":  toString(prompt["prompt_date"]),
			"has_answered": hasAnswered,
		},
	})

	writeJSON(w, http.StatusOK, map[string]any{
		"daily_prompt": view,
	})
}

func (s *Server) submitDailyPromptAnswer(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	if userID == "" {
		writeError(w, http.StatusBadRequest, errors.New("user id is required"))
		return
	}

	payload, ok := readJSON(w, r)
	if !ok {
		return
	}

	promptID := strings.TrimSpace(toString(payload["prompt_id"]))
	answerText := strings.TrimSpace(toString(payload["answer_text"]))
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		engagementapp.SubmitDailyPromptAnswerCommandName,
		engagementapp.SubmitDailyPromptAnswerCommand{UserID: userID, PromptID: promptID, AnswerText: answerText},
	)
	if err != nil {
		errMsg := strings.ToLower(err.Error())
		if strings.Contains(errMsg, "edit window expired") {
			writeError(w, http.StatusConflict, err)
			return
		}
		if errors.Is(err, engagementapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusBadRequest, err)
		return
	}

	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected submit daily prompt response payload"))
		return
	}
	view, _ := resp["daily_prompt"].(map[string]any)
	isEdit, _ := resp["is_edit"].(bool)
	prompt, _ := view["prompt"].(map[string]any)
	streak, _ := view["streak"].(map[string]any)
	spark, _ := view["spark"].(map[string]any)

	s.store.recordActivity(activityEvent{
		UserID:   userID,
		Actor:    userID,
		Action:   "daily_prompt_answer_submitted",
		Status:   "success",
		Resource: "/engagement/daily-prompt/" + userID + "/answer",
		Details: map[string]any{
			"user_id":             userID,
			"prompt_id":           toString(prompt["id"]),
			"prompt_date":         toString(prompt["prompt_date"]),
			"is_edit":             isEdit,
			"current_streak_days": numericValue(streak["current_days"]),
			"participants_today":  numericValue(spark["participants_today"]),
		},
	})

	if numericValue(streak["milestone_reached"]) > 0 {
		s.store.recordActivity(activityEvent{
			UserID:   userID,
			Actor:    userID,
			Action:   "daily_prompt_streak_milestone",
			Status:   "success",
			Resource: "/engagement/daily-prompt/" + userID + "/answer",
			Details: map[string]any{
				"user_id":        userID,
				"streak_days":    numericValue(streak["current_days"]),
				"milestone":      numericValue(streak["milestone_reached"]),
				"prompt_date":    toString(prompt["prompt_date"]),
				"next_milestone": numericValue(streak["next_milestone"]),
			},
		})
	}
	if !isEdit {
		promptDate := toString(prompt["prompt_date"])
		s.awardProgression(r.Context(), xpAwardInput{
			UserID: userID, Source: "daily_prompt_submitted", SourceEventID: toString(prompt["id"]) + ":" + promptDate,
			IdempotencyKey: "daily_prompt_submitted:" + userID + ":" + promptDate,
			Metadata:       map[string]any{"prompt_id": toString(prompt["id"]), "prompt_date": promptDate},
		})
		milestone := int(numericValue(streak["milestone_reached"]))
		if milestone == 3 || milestone == 7 || milestone == 14 {
			source := "streak_" + strconv.Itoa(milestone)
			s.awardProgression(r.Context(), xpAwardInput{
				UserID: userID, Source: source, SourceEventID: promptDate,
				IdempotencyKey: source + ":" + userID + ":" + promptDate,
				Metadata:       map[string]any{"streak_days": milestone},
			})
		}
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"daily_prompt": view,
	})
}

func (s *Server) listDailyPromptResponders(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	if userID == "" {
		writeError(w, http.StatusBadRequest, errors.New("user id is required"))
		return
	}

	limit := 10
	if rawLimit := strings.TrimSpace(r.URL.Query().Get("limit")); rawLimit != "" {
		parsedLimit, err := strconv.Atoi(rawLimit)
		if err != nil {
			writeError(w, http.StatusBadRequest, errors.New("limit must be a valid integer"))
			return
		}
		limit = parsedLimit
	}

	offset := 0
	if rawOffset := strings.TrimSpace(r.URL.Query().Get("offset")); rawOffset != "" {
		parsedOffset, err := strconv.Atoi(rawOffset)
		if err != nil {
			writeError(w, http.StatusBadRequest, errors.New("offset must be a valid integer"))
			return
		}
		offset = parsedOffset
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		engagementapp.ListDailyPromptRespondersCommandName,
		engagementapp.ListDailyPromptRespondersCommand{UserID: userID, Limit: limit, Offset: offset},
	)
	if err != nil {
		if errors.Is(err, engagementapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusBadRequest, err)
		return
	}

	page, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected list daily prompt responders response payload"))
		return
	}
	responders := mapSlice(page["responders"])

	s.store.recordActivity(activityEvent{
		UserID:   userID,
		Actor:    userID,
		Action:   "daily_prompt_responders_listed",
		Status:   "success",
		Resource: "/engagement/daily-prompt/" + userID + "/responders",
		Details: map[string]any{
			"user_id":       userID,
			"prompt_id":     toString(page["prompt_id"]),
			"prompt_date":   toString(page["prompt_date"]),
			"limit":         numericValue(page["limit"]),
			"offset":        numericValue(page["offset"]),
			"returned":      len(responders),
			"total_matches": numericValue(page["total"]),
		},
	})

	writeJSON(w, http.StatusOK, map[string]any{
		"responders": responders,
		"pagination": map[string]any{
			"prompt_id":     page["prompt_id"],
			"prompt_date":   page["prompt_date"],
			"limit":         page["limit"],
			"offset":        page["offset"],
			"next_offset":   page["next_offset"],
			"has_more":      page["has_more"],
			"total_matches": page["total"],
		},
	})
}

func (s *Server) sendMatchNudge(w http.ResponseWriter, r *http.Request) {
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}

	matchID := strings.TrimSpace(toString(payload["match_id"]))
	userID := strings.TrimSpace(toString(payload["user_id"]))
	counterpartyUserID := strings.TrimSpace(toString(payload["counterparty_user_id"]))
	nudgeType := strings.TrimSpace(toString(payload["nudge_type"]))
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()
	if enabled, err := s.runtimeFeatureEnabled(ctx, "match_nudges_enabled", true); err != nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("match nudge configuration unavailable"))
		return
	} else if !enabled {
		writeError(w, http.StatusConflict, errors.New("match nudges are temporarily disabled"))
		return
	}

	respAny, err := s.mediator.Send(
		ctx,
		engagementapp.SendMatchNudgeCommandName,
		engagementapp.SendMatchNudgeCommand{
			MatchID:            matchID,
			UserID:             userID,
			CounterpartyUserID: counterpartyUserID,
			NudgeType:          nudgeType,
		},
	)
	if err != nil {
		errMsg := strings.ToLower(err.Error())
		switch {
		case strings.Contains(errMsg, "daily nudge cap"):
			writeError(w, http.StatusTooManyRequests, err)
			return
		case strings.Contains(errMsg, "safety state"):
			writeError(w, http.StatusConflict, err)
			return
		default:
			writeError(w, http.StatusBadRequest, err)
			return
		}
	}

	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected send match nudge response payload"))
		return
	}
	nudge, _ := resp["nudge"].(map[string]any)

	s.store.recordActivity(activityEvent{
		UserID:   toString(nudge["user_id"]),
		Actor:    "system",
		Action:   "match_nudge_sent",
		Status:   "success",
		Resource: "/engagement/match-nudges/send",
		Details: map[string]any{
			"match_id":   toString(nudge["match_id"]),
			"user_id":    toString(nudge["user_id"]),
			"nudge_type": toString(nudge["nudge_type"]),
			"nudge_id":   toString(nudge["id"]),
		},
	})

	writeJSON(w, http.StatusOK, map[string]any{
		"nudge": nudge,
	})
}

func (s *Server) clickMatchNudge(w http.ResponseWriter, r *http.Request) {
	nudgeID := strings.TrimSpace(chi.URLParam(r, "nudgeID"))
	if nudgeID == "" {
		writeError(w, http.StatusBadRequest, errors.New("nudge id is required"))
		return
	}

	payload, ok := readJSON(w, r)
	if !ok {
		return
	}

	userID := strings.TrimSpace(toString(payload["user_id"]))
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		engagementapp.ClickMatchNudgeCommandName,
		engagementapp.ClickMatchNudgeCommand{NudgeID: nudgeID, UserID: userID},
	)
	if err != nil {
		errMsg := strings.ToLower(err.Error())
		switch {
		case strings.Contains(errMsg, "not found"):
			writeError(w, http.StatusNotFound, err)
			return
		case strings.Contains(errMsg, "belong"):
			writeError(w, http.StatusForbidden, err)
			return
		default:
			writeError(w, http.StatusBadRequest, err)
			return
		}
	}

	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected click match nudge response payload"))
		return
	}
	nudge, _ := resp["nudge"].(map[string]any)

	s.store.recordActivity(activityEvent{
		UserID:   toString(nudge["user_id"]),
		Actor:    toString(nudge["user_id"]),
		Action:   "match_nudge_clicked",
		Status:   "success",
		Resource: "/engagement/match-nudges/" + nudgeID + "/click",
		Details: map[string]any{
			"match_id":   toString(nudge["match_id"]),
			"user_id":    toString(nudge["user_id"]),
			"nudge_type": toString(nudge["nudge_type"]),
			"nudge_id":   toString(nudge["id"]),
		},
	})

	writeJSON(w, http.StatusOK, map[string]any{
		"nudge": nudge,
	})
}

func (s *Server) markConversationResumed(w http.ResponseWriter, r *http.Request) {
	matchID := strings.TrimSpace(chi.URLParam(r, "matchID"))
	if matchID == "" {
		writeError(w, http.StatusBadRequest, errors.New("match id is required"))
		return
	}

	payload, ok := readJSON(w, r)
	if !ok {
		return
	}

	userID := strings.TrimSpace(toString(payload["user_id"]))
	triggerNudgeID := strings.TrimSpace(toString(payload["trigger_nudge_id"]))
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		engagementapp.MarkConversationResumedCommandName,
		engagementapp.MarkConversationResumedCommand{MatchID: matchID, UserID: userID, TriggerNudgeID: triggerNudgeID},
	)
	if err != nil {
		errMsg := strings.ToLower(err.Error())
		if strings.Contains(errMsg, "invalid") {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusBadRequest, err)
		return
	}

	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected mark conversation resumed response payload"))
		return
	}
	resumed, _ := resp["conversation"].(map[string]any)

	s.store.recordActivity(activityEvent{
		UserID:   toString(resumed["user_id"]),
		Actor:    toString(resumed["user_id"]),
		Action:   "conversation_resumed",
		Status:   "success",
		Resource: "/engagement/matches/" + matchID + "/resume",
		Details: map[string]any{
			"match_id":         toString(resumed["match_id"]),
			"user_id":          toString(resumed["user_id"]),
			"trigger_nudge_id": toString(resumed["trigger_nudge_id"]),
		},
	})

	writeJSON(w, http.StatusOK, map[string]any{
		"conversation": resumed,
	})
}

func (s *Server) getCircleChallenge(w http.ResponseWriter, r *http.Request) {
	circleID := strings.TrimSpace(chi.URLParam(r, "circleID"))
	userID := strings.TrimSpace(r.URL.Query().Get("user_id"))
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		engagementapp.GetCircleChallengeCommandName,
		engagementapp.GetCircleChallengeCommand{CircleID: circleID, UserID: userID},
	)
	if err != nil {
		if errors.Is(err, engagementapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		if strings.Contains(strings.ToLower(err.Error()), "not found") {
			writeError(w, http.StatusNotFound, err)
			return
		}
		writeError(w, http.StatusBadRequest, err)
		return
	}

	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected get circle challenge response payload"))
		return
	}
	view, _ := resp["circle_challenge"].(map[string]any)
	challenge, _ := view["challenge"].(map[string]any)

	s.store.recordActivity(activityEvent{
		UserID:   userID,
		Actor:    userID,
		Action:   "circle_challenge_viewed",
		Status:   "success",
		Resource: "/engagement/circles/" + circleID + "/challenge",
		Details: map[string]any{
			"circle_id":    toString(view["circle_id"]),
			"user_id":      userID,
			"challenge_id": toString(challenge["id"]),
		},
	})
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) joinCircle(w http.ResponseWriter, r *http.Request) {
	circleID := strings.TrimSpace(chi.URLParam(r, "circleID"))

	payload, ok := readJSON(w, r)
	if !ok {
		return
	}

	userID := strings.TrimSpace(toString(payload["user_id"]))
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		engagementapp.JoinCircleCommandName,
		engagementapp.JoinCircleCommand{CircleID: circleID, UserID: userID},
	)
	if err != nil {
		if errors.Is(err, engagementapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		if strings.Contains(strings.ToLower(err.Error()), "not found") {
			writeError(w, http.StatusNotFound, err)
			return
		}
		writeError(w, http.StatusBadRequest, err)
		return
	}

	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected join circle response payload"))
		return
	}
	membership, _ := resp["membership"].(map[string]any)

	s.store.recordActivity(activityEvent{
		UserID:   userID,
		Actor:    userID,
		Action:   "circle_joined",
		Status:   "success",
		Resource: "/engagement/circles/" + circleID + "/join",
		Details: map[string]any{
			"circle_id": toString(membership["circle_id"]),
			"user_id":   toString(membership["user_id"]),
			"joined_at": membership["joined_at"],
		},
	})
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) submitCircleChallenge(w http.ResponseWriter, r *http.Request) {
	circleID := strings.TrimSpace(chi.URLParam(r, "circleID"))

	payload, ok := readJSON(w, r)
	if !ok {
		return
	}

	challengeID := strings.TrimSpace(toString(payload["challenge_id"]))
	userID := strings.TrimSpace(toString(payload["user_id"]))
	entryText := strings.TrimSpace(toString(payload["entry_text"]))
	imageURL := strings.TrimSpace(toString(payload["image_url"]))

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		engagementapp.SubmitCircleChallengeCommandName,
		engagementapp.SubmitCircleChallengeCommand{
			CircleID:    circleID,
			ChallengeID: challengeID,
			UserID:      userID,
			EntryText:   entryText,
			ImageURL:    imageURL,
		},
	)
	if err != nil {
		if errors.Is(err, engagementapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		errMsg := strings.ToLower(err.Error())
		switch {
		case strings.Contains(errMsg, "already submitted"):
			writeError(w, http.StatusConflict, err)
			return
		case strings.Contains(errMsg, "not found"):
			writeError(w, http.StatusNotFound, err)
			return
		default:
			writeError(w, http.StatusBadRequest, err)
			return
		}
	}

	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected submit circle challenge response payload"))
		return
	}
	view, _ := resp["circle_challenge"].(map[string]any)
	entry, _ := resp["entry"].(map[string]any)
	challenge, _ := view["challenge"].(map[string]any)

	s.store.recordActivity(activityEvent{
		UserID:   userID,
		Actor:    userID,
		Action:   "circle_challenge_submitted",
		Status:   "success",
		Resource: "/engagement/circles/" + circleID + "/challenge/entries",
		Details: map[string]any{
			"circle_id":           toString(view["circle_id"]),
			"user_id":             userID,
			"challenge_id":        toString(challenge["id"]),
			"challenge_entry_id":  toString(entry["id"]),
			"participation_count": view["participation_count"],
		},
	})
	s.awardProgression(r.Context(), xpAwardInput{
		UserID: userID, Source: "circle_challenge_submitted", SourceEventID: toString(entry["id"]),
		IdempotencyKey: "circle_challenge_submitted:" + toString(entry["id"]),
		Metadata:       map[string]any{"circle_id": circleID, "challenge_id": challengeID},
	})

	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) listVoiceIcebreakerPrompts(w http.ResponseWriter, _ *http.Request) {
	ctx, cancel := s.withRequestTimeout(context.Background())
	defer cancel()

	respAny, err := s.mediator.Send(ctx, engagementapp.ListVoicePromptsCommandName, engagementapp.ListVoicePromptsCommand{})
	if err != nil {
		writeError(w, http.StatusBadRequest, err)
		return
	}
	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected list voice prompts response payload"))
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) startVoiceIcebreaker(w http.ResponseWriter, r *http.Request) {
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}

	matchID := strings.TrimSpace(toString(payload["match_id"]))
	senderUserID := strings.TrimSpace(toString(payload["sender_user_id"]))
	receiverUserID := strings.TrimSpace(toString(payload["receiver_user_id"]))
	promptID := strings.TrimSpace(toString(payload["prompt_id"]))
	if !s.requireLocalSignupUser(w, r, senderUserID) {
		return
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		engagementapp.StartVoiceIcebreakerCommandName,
		engagementapp.StartVoiceIcebreakerCommand{
			MatchID:        matchID,
			SenderUserID:   senderUserID,
			ReceiverUserID: receiverUserID,
			PromptID:       promptID,
		},
	)
	if err != nil {
		if errors.Is(err, engagementapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		errMsg := strings.ToLower(err.Error())
		switch {
		case strings.Contains(errMsg, "already created"):
			writeError(w, http.StatusConflict, err)
			return
		case strings.Contains(errMsg, "safety state"):
			writeError(w, http.StatusConflict, err)
			return
		default:
			writeError(w, http.StatusBadRequest, err)
			return
		}
	}
	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected start voice icebreaker response payload"))
		return
	}
	item, _ := resp["voice_icebreaker"].(map[string]any)

	s.store.recordActivity(activityEvent{
		UserID:   toString(item["sender_user_id"]),
		Actor:    toString(item["sender_user_id"]),
		Action:   "voice_icebreaker_started",
		Status:   "success",
		Resource: "/engagement/voice-icebreakers/start",
		Details: map[string]any{
			"match_id":  toString(item["match_id"]),
			"user_id":   toString(item["sender_user_id"]),
			"prompt_id": toString(item["prompt_id"]),
		},
	})

	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) sendVoiceIcebreaker(w http.ResponseWriter, r *http.Request) {
	icebreakerID := strings.TrimSpace(chi.URLParam(r, "icebreakerID"))
	if icebreakerID == "" {
		writeError(w, http.StatusBadRequest, errors.New("icebreaker id is required"))
		return
	}

	if !strings.HasPrefix(strings.ToLower(strings.TrimSpace(r.Header.Get("Content-Type"))), "multipart/form-data") {
		writeError(w, http.StatusUnsupportedMediaType, errors.New("voice messages must include multipart audio content"))
		return
	}
	if err := r.ParseMultipartForm(maxVoiceRecordingBytes + (1 << 20)); err != nil {
		writeError(w, http.StatusRequestEntityTooLarge, errors.New("voice message exceeds the upload limit"))
		return
	}
	senderUserID := strings.TrimSpace(r.FormValue("sender_user_id"))
	transcript := strings.TrimSpace(r.FormValue("transcript"))
	durationSeconds, durationErr := strconv.Atoi(strings.TrimSpace(r.FormValue("duration_seconds")))
	if durationErr != nil {
		writeError(w, http.StatusBadRequest, errors.New("duration_seconds is required"))
		return
	}
	if durationSeconds < voiceIcebreakerMinDurationSec || durationSeconds > voiceIcebreakerMaxDurationSec {
		writeError(w, http.StatusBadRequest, fmt.Errorf("duration_seconds must be between %d and %d", voiceIcebreakerMinDurationSec, voiceIcebreakerMaxDurationSec))
		return
	}
	if !s.requireLocalSignupUser(w, r, senderUserID) {
		return
	}
	recording, err := s.persistVoiceRecording(r, icebreakerID, senderUserID)
	if err != nil {
		writeError(w, mediaUploadHTTPStatus(err), err)
		return
	}
	moderation, err := s.voiceModerator.Assess(r.Context(), icebreakerID, transcript, recording)
	if err != nil {
		_ = s.deleteStoredMedia(recording.StoragePath)
		writeError(w, http.StatusServiceUnavailable, errors.New("voice moderation provider is temporarily unavailable"))
		return
	}
	if recordErr := s.recordVoiceModeration(r.Context(), icebreakerID, senderUserID, recording, moderation); recordErr != nil {
		_ = s.deleteStoredMedia(recording.StoragePath)
		writeError(w, http.StatusBadGateway, errors.New("voice moderation result could not be recorded"))
		return
	}
	if moderation.Decision != "approved" {
		_ = s.deleteStoredMedia(recording.StoragePath)
		message := "Voice recording requires review and was not sent."
		if moderation.Decision == "rejected" {
			message = "Voice recording did not pass moderation."
		}
		writeError(w, http.StatusUnprocessableEntity, errors.New(message))
		return
	}
	if err := s.store.attachVoiceRecording(icebreakerID, senderUserID, recording); err != nil {
		_ = s.deleteStoredMedia(recording.StoragePath)
		writeError(w, http.StatusConflict, err)
		return
	}
	cleanup := func() {
		s.store.detachVoiceRecording(icebreakerID)
		_ = s.deleteStoredMedia(recording.StoragePath)
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		engagementapp.SendVoiceIcebreakerCommandName,
		engagementapp.SendVoiceIcebreakerCommand{
			IcebreakerID:    icebreakerID,
			SenderUserID:    senderUserID,
			Transcript:      transcript,
			DurationSeconds: durationSeconds,
		},
	)
	if err != nil {
		cleanup()
		if errors.Is(err, engagementapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		errMsg := strings.ToLower(err.Error())
		switch {
		case strings.Contains(errMsg, "not found"):
			writeError(w, http.StatusNotFound, err)
			return
		case strings.Contains(errMsg, "already sent"):
			writeError(w, http.StatusConflict, err)
			return
		default:
			writeError(w, http.StatusBadRequest, err)
			return
		}
	}
	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected send voice icebreaker response payload"))
		return
	}
	item, _ := resp["voice_icebreaker"].(map[string]any)

	s.store.recordActivity(activityEvent{
		UserID:   toString(item["sender_user_id"]),
		Actor:    toString(item["sender_user_id"]),
		Action:   "voice_icebreaker_sent",
		Status:   "success",
		Resource: "/engagement/voice-icebreakers/" + icebreakerID + "/send",
		Details: map[string]any{
			"match_id":         toString(item["match_id"]),
			"user_id":          toString(item["sender_user_id"]),
			"prompt_id":        toString(item["prompt_id"]),
			"duration_seconds": item["duration_seconds"],
		},
	})

	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) playVoiceIcebreaker(w http.ResponseWriter, r *http.Request) {
	icebreakerID := strings.TrimSpace(chi.URLParam(r, "icebreakerID"))
	if icebreakerID == "" {
		writeError(w, http.StatusBadRequest, errors.New("icebreaker id is required"))
		return
	}

	payload, ok := readJSON(w, r)
	if !ok {
		return
	}

	userID := strings.TrimSpace(toString(payload["user_id"]))
	if _, err := s.store.voiceIcebreakerForPlayback(icebreakerID, userID); err != nil {
		writeError(w, http.StatusForbidden, err)
		return
	}
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		engagementapp.PlayVoiceIcebreakerCommandName,
		engagementapp.PlayVoiceIcebreakerCommand{IcebreakerID: icebreakerID, UserID: userID},
	)
	if err != nil {
		if errors.Is(err, engagementapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		errMsg := strings.ToLower(err.Error())
		switch {
		case strings.Contains(errMsg, "not found"):
			writeError(w, http.StatusNotFound, err)
			return
		case strings.Contains(errMsg, "cannot play"):
			writeError(w, http.StatusForbidden, err)
			return
		default:
			writeError(w, http.StatusBadRequest, err)
			return
		}
	}
	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected play voice icebreaker response payload"))
		return
	}
	item, _ := resp["voice_icebreaker"].(map[string]any)
	audioURL, audioExpiresAt, audioErr := s.signedVoicePlaybackURL(r, icebreakerID, userID)
	if audioErr != nil {
		writeError(w, http.StatusServiceUnavailable, audioErr)
		return
	}
	if _, playbackErr := s.store.voiceIcebreakerForPlayback(icebreakerID, userID); playbackErr != nil {
		writeError(w, http.StatusForbidden, playbackErr)
		return
	}
	item["audio_url"] = audioURL
	item["audio_expires_at"] = audioExpiresAt.Format(time.RFC3339)

	s.store.recordActivity(activityEvent{
		UserID:   userID,
		Actor:    userID,
		Action:   "voice_icebreaker_played",
		Status:   "success",
		Resource: "/engagement/voice-icebreakers/" + icebreakerID + "/play",
		Details: map[string]any{
			"match_id":      toString(item["match_id"]),
			"user_id":       userID,
			"icebreaker_id": toString(item["id"]),
		},
	})
	senderUserID := toString(item["sender_user_id"])
	s.awardProgression(r.Context(), xpAwardInput{
		UserID: senderUserID, Source: "voice_icebreaker_played", SourceEventID: icebreakerID,
		IdempotencyKey: "voice_icebreaker_played:" + icebreakerID,
		Metadata:       map[string]any{"played_by": userID, "match_id": toString(item["match_id"])},
	})

	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) createGroupCoffeePoll(w http.ResponseWriter, r *http.Request) {
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}

	creatorUserID := strings.TrimSpace(toString(payload["creator_user_id"]))
	deadlineAt := strings.TrimSpace(toString(payload["deadline_at"]))

	participantUserIDs, _ := toStringSlice(payload["participant_user_ids"])

	rawOptions, ok := payload["options"].([]any)
	if !ok {
		writeError(w, http.StatusBadRequest, errors.New("options are required"))
		return
	}
	options := make([]groupCoffeePollOption, 0, len(rawOptions))
	for _, raw := range rawOptions {
		item, ok := raw.(map[string]any)
		if !ok {
			continue
		}
		options = append(options, groupCoffeePollOption{
			Day:          strings.TrimSpace(toString(item["day"])),
			TimeWindow:   strings.TrimSpace(toString(item["time_window"])),
			Neighborhood: strings.TrimSpace(toString(item["neighborhood"])),
		})
	}

	moduleOptions := make([]engagementapp.GroupCoffeeOptionInput, 0, len(options))
	for _, option := range options {
		moduleOptions = append(moduleOptions, engagementapp.GroupCoffeeOptionInput{
			Day:          option.Day,
			TimeWindow:   option.TimeWindow,
			Neighborhood: option.Neighborhood,
		})
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		engagementapp.CreateGroupCoffeePollCommandName,
		engagementapp.CreateGroupCoffeePollCommand{
			CreatorUserID:      creatorUserID,
			ParticipantUserIDs: participantUserIDs,
			Options:            moduleOptions,
			DeadlineAt:         deadlineAt,
		},
	)
	if err != nil {
		if errors.Is(err, engagementapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusBadRequest, err)
		return
	}
	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected create group coffee poll response payload"))
		return
	}
	poll, _ := resp["poll"].(map[string]any)
	participantList, _ := poll["participant_user_ids"].([]any)

	s.store.recordActivity(activityEvent{
		UserID:   creatorUserID,
		Actor:    creatorUserID,
		Action:   "intro_event_created",
		Status:   "success",
		Resource: "/engagement/group-coffee-polls",
		Details: map[string]any{
			"intro_event_id": toString(poll["id"]),
			"user_id":        creatorUserID,
			"event_type":     "group_coffee_poll",
			"participants":   len(participantList),
		},
	})

	s.store.recordActivity(activityEvent{
		UserID:   creatorUserID,
		Actor:    creatorUserID,
		Action:   "group_poll_created",
		Status:   "success",
		Resource: "/engagement/group-coffee-polls",
		Details: map[string]any{
			"poll_id":      toString(poll["id"]),
			"user_id":      creatorUserID,
			"participants": len(participantList),
		},
	})

	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) listGroupCoffeePolls(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(r.URL.Query().Get("user_id"))
	if userID == "" {
		writeError(w, http.StatusBadRequest, errors.New("user_id is required"))
		return
	}

	status := strings.TrimSpace(r.URL.Query().Get("status"))
	limit := 50
	if raw := strings.TrimSpace(r.URL.Query().Get("limit")); raw != "" {
		parsed, err := strconv.Atoi(raw)
		if err != nil {
			writeError(w, http.StatusBadRequest, errors.New("limit must be an integer"))
			return
		}
		limit = parsed
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		engagementapp.ListGroupCoffeePollsCommandName,
		engagementapp.ListGroupCoffeePollsCommand{UserID: userID, Status: status, Limit: limit},
	)
	if err != nil {
		if errors.Is(err, engagementapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusBadRequest, err)
		return
	}
	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected list group coffee polls response payload"))
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) getGroupCoffeePoll(w http.ResponseWriter, r *http.Request) {
	pollID := strings.TrimSpace(chi.URLParam(r, "pollID"))
	if pollID == "" {
		writeError(w, http.StatusBadRequest, errors.New("poll id is required"))
		return
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		engagementapp.GetGroupCoffeePollCommandName,
		engagementapp.GetGroupCoffeePollCommand{PollID: pollID},
	)
	if err != nil {
		if errors.Is(err, engagementapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		if strings.Contains(strings.ToLower(err.Error()), "not found") {
			writeError(w, http.StatusNotFound, err)
			return
		}
		writeError(w, http.StatusBadRequest, err)
		return
	}
	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected get group coffee poll response payload"))
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) voteGroupCoffeePoll(w http.ResponseWriter, r *http.Request) {
	pollID := strings.TrimSpace(chi.URLParam(r, "pollID"))
	if pollID == "" {
		writeError(w, http.StatusBadRequest, errors.New("poll id is required"))
		return
	}

	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	userID := strings.TrimSpace(toString(payload["user_id"]))
	optionID := strings.TrimSpace(toString(payload["option_id"]))

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		engagementapp.VoteGroupCoffeePollCommandName,
		engagementapp.VoteGroupCoffeePollCommand{PollID: pollID, UserID: userID, OptionID: optionID},
	)
	if err != nil {
		if errors.Is(err, engagementapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		errMsg := strings.ToLower(err.Error())
		switch {
		case strings.Contains(errMsg, "not found"):
			writeError(w, http.StatusNotFound, err)
			return
		case strings.Contains(errMsg, "not a participant"):
			writeError(w, http.StatusForbidden, err)
			return
		default:
			writeError(w, http.StatusBadRequest, err)
			return
		}
	}
	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected vote group coffee poll response payload"))
		return
	}
	poll, _ := resp["poll"].(map[string]any)

	s.store.recordActivity(activityEvent{
		UserID:   userID,
		Actor:    userID,
		Action:   "intro_event_voted",
		Status:   "success",
		Resource: "/engagement/group-coffee-polls/" + pollID + "/votes",
		Details: map[string]any{
			"intro_event_id": toString(poll["id"]),
			"user_id":        userID,
			"option_id":      optionID,
			"event_type":     "group_coffee_poll",
		},
	})

	s.store.recordActivity(activityEvent{
		UserID:   userID,
		Actor:    userID,
		Action:   "group_poll_voted",
		Status:   "success",
		Resource: "/engagement/group-coffee-polls/" + pollID + "/votes",
		Details: map[string]any{
			"poll_id":   toString(poll["id"]),
			"user_id":   userID,
			"option_id": optionID,
		},
	})

	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) finalizeGroupCoffeePoll(w http.ResponseWriter, r *http.Request) {
	pollID := strings.TrimSpace(chi.URLParam(r, "pollID"))
	if pollID == "" {
		writeError(w, http.StatusBadRequest, errors.New("poll id is required"))
		return
	}

	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	userID := strings.TrimSpace(toString(payload["user_id"]))

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		engagementapp.FinalizeGroupCoffeePollCommandName,
		engagementapp.FinalizeGroupCoffeePollCommand{PollID: pollID, UserID: userID},
	)
	if err != nil {
		if errors.Is(err, engagementapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		errMsg := strings.ToLower(err.Error())
		switch {
		case strings.Contains(errMsg, "not found"):
			writeError(w, http.StatusNotFound, err)
			return
		case strings.Contains(errMsg, "only creator"):
			writeError(w, http.StatusForbidden, err)
			return
		default:
			writeError(w, http.StatusBadRequest, err)
			return
		}
	}
	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected finalize group coffee poll response payload"))
		return
	}
	poll, _ := resp["poll"].(map[string]any)
	selectedOption, _ := resp["selected_option"].(map[string]any)

	s.store.recordActivity(activityEvent{
		UserID:   userID,
		Actor:    userID,
		Action:   "intro_event_finalized",
		Status:   "success",
		Resource: "/engagement/group-coffee-polls/" + pollID + "/finalize",
		Details: map[string]any{
			"intro_event_id":        toString(poll["id"]),
			"user_id":               userID,
			"event_type":            "group_coffee_poll",
			"selected_option_id":    toString(selectedOption["id"]),
			"selected_day":          toString(selectedOption["day"]),
			"selected_time_window":  toString(selectedOption["time_window"]),
			"selected_neighborhood": toString(selectedOption["neighborhood"]),
		},
	})

	s.store.recordActivity(activityEvent{
		UserID:   userID,
		Actor:    userID,
		Action:   "group_poll_finalized",
		Status:   "success",
		Resource: "/engagement/group-coffee-polls/" + pollID + "/finalize",
		Details: map[string]any{
			"poll_id":               toString(poll["id"]),
			"user_id":               userID,
			"selected_option_id":    toString(selectedOption["id"]),
			"selected_day":          toString(selectedOption["day"]),
			"selected_time_window":  toString(selectedOption["time_window"]),
			"selected_neighborhood": toString(selectedOption["neighborhood"]),
		},
	})

	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) startCall(w http.ResponseWriter, r *http.Request) {
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}

	matchID := strings.TrimSpace(toString(payload["match_id"]))
	initiatorID := strings.TrimSpace(toString(payload["initiator_user_id"]))
	recipientID := strings.TrimSpace(toString(payload["recipient_user_id"]))
	if !s.requireLocalSignupUser(w, r, initiatorID) {
		return
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		callsapp.StartCallCommandName,
		callsapp.StartCallCommand{
			MatchID:         matchID,
			InitiatorUserID: initiatorID,
			RecipientUserID: recipientID,
		},
	)
	if err != nil {
		if errors.Is(err, callsapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		if strings.Contains(strings.ToLower(err.Error()), "active match") ||
			strings.Contains(strings.ToLower(err.Error()), "unavailable for this match") {
			writeError(w, http.StatusConflict, err)
			return
		}
		writeError(w, http.StatusBadGateway, err)
		return
	}

	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected start call response payload"))
		return
	}
	s.decorateCallResponse(resp, initiatorID)
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) endCall(w http.ResponseWriter, r *http.Request) {
	callID := strings.TrimSpace(chi.URLParam(r, "callID"))
	if callID == "" {
		writeError(w, http.StatusBadRequest, errors.New("call id is required"))
		return
	}

	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	endedBy := strings.TrimSpace(toString(payload["ended_by_user_id"]))
	if !s.requireLocalSignupUser(w, r, endedBy) {
		return
	}
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		callsapp.EndCallCommandName,
		callsapp.EndCallCommand{CallID: callID, EndedByUserID: endedBy},
	)
	if err != nil {
		if errors.Is(err, callsapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		if strings.Contains(strings.ToLower(err.Error()), "not found") {
			writeError(w, http.StatusNotFound, err)
			return
		}
		if strings.Contains(strings.ToLower(err.Error()), "call participant") {
			writeError(w, http.StatusForbidden, err)
			return
		}
		writeError(w, http.StatusBadGateway, err)
		return
	}

	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected end call response payload"))
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) listCallHistory(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	if userID == "" {
		writeError(w, http.StatusBadRequest, errors.New("user id is required"))
		return
	}
	if !s.requireLocalSignupUser(w, r, userID) {
		return
	}
	limit := 100
	if raw := strings.TrimSpace(r.URL.Query().Get("limit")); raw != "" {
		if parsed, err := strconv.Atoi(raw); err == nil {
			limit = parsed
		}
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		callsapp.ListCallHistoryCommandName,
		callsapp.ListCallHistoryCommand{UserID: userID, Limit: limit},
	)
	if err != nil {
		if errors.Is(err, callsapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusBadGateway, err)
		return
	}

	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected call history response payload"))
		return
	}
	s.decorateCallHistoryResponse(resp, userID)
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) triggerSOS(w http.ResponseWriter, r *http.Request) {
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	userID := strings.TrimSpace(toString(payload["user_id"]))
	matchID := strings.TrimSpace(toString(payload["match_id"]))
	level := strings.TrimSpace(toString(payload["emergency_level"]))
	message := strings.TrimSpace(toString(payload["message"]))
	latitude, _ := toFloat64(payload["latitude"])
	longitude, _ := toFloat64(payload["longitude"])

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		safetyapp.TriggerSOSCommandName,
		safetyapp.TriggerSOSCommand{
			UserID:         userID,
			MatchID:        matchID,
			EmergencyLevel: level,
			Message:        message,
			Latitude:       latitude,
			Longitude:      longitude,
		},
	)
	if err != nil {
		if errors.Is(err, safetyapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusBadGateway, err)
		return
	}

	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected trigger sos response payload"))
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) listSOS(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	if userID == "" {
		writeError(w, http.StatusBadRequest, errors.New("user id is required"))
		return
	}
	limit := 100
	if raw := strings.TrimSpace(r.URL.Query().Get("limit")); raw != "" {
		if parsed, err := strconv.Atoi(raw); err == nil {
			limit = parsed
		}
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		safetyapp.ListSOSCommandName,
		safetyapp.ListSOSCommand{UserID: userID, Limit: limit},
	)
	if err != nil {
		if errors.Is(err, safetyapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusBadGateway, err)
		return
	}

	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected list sos response payload"))
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) resolveSOS(w http.ResponseWriter, r *http.Request) {
	alertID := strings.TrimSpace(chi.URLParam(r, "alertID"))
	if alertID == "" {
		writeError(w, http.StatusBadRequest, errors.New("alert id is required"))
		return
	}

	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	resolvedBy := strings.TrimSpace(toString(payload["resolved_by"]))
	note := strings.TrimSpace(toString(payload["resolution_note"]))

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		safetyapp.ResolveSOSCommandName,
		safetyapp.ResolveSOSCommand{AlertID: alertID, ResolvedBy: resolvedBy, ResolutionNote: note},
	)
	if err != nil {
		if errors.Is(err, safetyapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		if strings.Contains(strings.ToLower(err.Error()), "not found") {
			writeError(w, http.StatusNotFound, err)
			return
		}
		writeError(w, http.StatusBadGateway, err)
		return
	}

	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected resolve sos response payload"))
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) userAnalytics(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	if userID == "" {
		writeError(w, http.StatusBadRequest, errors.New("user id is required"))
		return
	}
	// A support view, not a member feature: it counts reports filed against
	// the member. Only support operators may read it (server_security.go
	// leaves "analytics" out of the self-owned roots for this reason).
	if principal, ok := principalFromRequest(r); !ok ||
		!(principal.Roles["admin"] || principal.Roles["trust_safety"] || principal.Roles["moderator"]) {
		writeError(w, http.StatusForbidden, errors.New("member analytics are available to support operators only"))
		return
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(ctx, adminapp.UserAnalyticsCommandName, adminapp.UserAnalyticsCommand{UserID: userID})
	if err != nil {
		if errors.Is(err, adminapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusBadGateway, err)
		return
	}

	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected user analytics response payload"))
		return
	}
	resp["data_source"] = "process_local_runtime_store"
	resp["data_note"] = "Counted from this BFF instance's in-memory activity since it started; not durable and empty when Postgres is configured."
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) listBillingPlans(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(ctx, billingapp.ListPlansCommandName, billingapp.ListPlansCommand{})
	if err != nil {
		if errors.Is(err, billingapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusBadGateway, err)
		return
	}

	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected billing plans response payload"))
		return
	}
	resp["coexistence_matrix"] = s.store.billingCoexistenceMatrix()
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) getBillingCoexistenceMatrix(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, map[string]any{
		"coexistence_matrix": s.store.billingCoexistenceMatrix(),
	})
}

func (s *Server) getBillingSubscription(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		billingapp.GetSubscriptionCommandName,
		billingapp.GetSubscriptionCommand{UserID: userID},
	)
	if err != nil {
		if errors.Is(err, billingapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusBadGateway, err)
		return
	}

	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected billing subscription response payload"))
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) subscribePlan(w http.ResponseWriter, r *http.Request) {
	// With a payment provider configured, subscriptions come from settled
	// card checkouts only. Local activation stays available solely for
	// provider-less development stacks that opt in explicitly.
	if s.billing != nil && !s.cfg.BillingLocalActivationEnabled {
		writeError(w, http.StatusConflict, errCheckoutRequired)
		return
	}
	// Provider-less activation grants a paid plan with no payment; only an
	// explicitly local environment may do that.
	if s.billing == nil && !config.IsLocalEnvironment(s.cfg.Environment) {
		writeError(w, http.StatusConflict, errCheckoutRequired)
		return
	}
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	userID := strings.TrimSpace(toString(payload["user_id"]))
	planID := strings.TrimSpace(toString(payload["plan_id"]))
	billingCycle := strings.TrimSpace(toString(payload["billing_cycle"]))

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		billingapp.SubscribePlanCommandName,
		billingapp.SubscribePlanCommand{UserID: userID, PlanID: planID, BillingCycle: billingCycle},
	)
	if err != nil {
		if errors.Is(err, billingapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusBadGateway, err)
		return
	}

	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected billing subscribe response payload"))
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) listBillingPayments(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	limit := 100
	if raw := strings.TrimSpace(r.URL.Query().Get("limit")); raw != "" {
		if parsed, err := strconv.Atoi(raw); err == nil {
			limit = parsed
		}
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		billingapp.ListPaymentsCommandName,
		billingapp.ListPaymentsCommand{UserID: userID, Limit: limit},
	)
	if err != nil {
		if errors.Is(err, billingapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusBadGateway, err)
		return
	}

	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected billing payments response payload"))
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) getProfileDraft(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	if userID == "" {
		writeError(w, http.StatusBadRequest, errors.New("user id is required"))
		return
	}
	if !s.requireLocalSignupUser(w, r, userID) {
		return
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(ctx, profileapp.GetProfileDraftCommandName, profileapp.GetProfileDraftCommand{UserID: userID})
	if err != nil {
		if errors.Is(err, profileapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusBadGateway, err)
		return
	}

	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected profile draft response payload"))
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) patchProfileDraft(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	if userID == "" {
		writeError(w, http.StatusBadRequest, errors.New("user id is required"))
		return
	}
	if !s.requireLocalSignupUser(w, r, userID) {
		return
	}

	payload, ok := readJSON(w, r)
	if !ok {
		return
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		profileapp.PatchProfileDraftCommandName,
		profileapp.PatchProfileDraftCommand{UserID: userID, Payload: payload},
	)
	if err != nil {
		if errors.Is(err, profileapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusBadGateway, err)
		return
	}

	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected patch profile draft response payload"))
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) addProfilePhoto(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	if userID == "" {
		writeError(w, http.StatusBadRequest, errors.New("user id is required"))
		return
	}
	if !s.requireLocalSignupUser(w, r, userID) {
		return
	}

	var upload profileapp.ProfilePhotoUploadInput
	contentType := strings.ToLower(strings.TrimSpace(r.Header.Get("Content-Type")))
	if strings.HasPrefix(contentType, "multipart/form-data") {
		validated, err := s.persistUploadedPhoto(r, userID)
		if err != nil {
			writeError(w, mediaUploadHTTPStatus(err), err)
			return
		}
		upload = profileapp.ProfilePhotoUploadInput{
			ID:                     validated.ID,
			PhotoURL:               validated.PhotoURL,
			StoragePath:            validated.StoragePath,
			OriginalFilename:       validated.OriginalFilename,
			MimeType:               validated.MimeType,
			WidthPx:                validated.WidthPx,
			HeightPx:               validated.HeightPx,
			SizeBytes:              validated.SizeBytes,
			ContentSHA256:          validated.ContentSHA256,
			ModerationStatus:       validated.Moderation.Status,
			ModerationProvider:     validated.Moderation.Provider,
			ModerationModelVersion: validated.Moderation.ModelVersion,
			ModerationReason:       validated.Moderation.Reason,
			ModerationLabelsJSON:   validated.ModerationLabels,
			ModerationConfidence:   validated.MaxConfidence,
			ModerationDurationMS:   validated.Moderation.DurationMS,
		}
	} else {
		writeError(
			w,
			http.StatusUnsupportedMediaType,
			errors.New("profile photos must be uploaded as multipart image content"),
		)
		return
	}

	if upload.PhotoURL == "" {
		writeError(w, http.StatusBadRequest, errors.New("photo_url is required"))
		return
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		profileapp.AddProfilePhotoCommandName,
		profileapp.AddProfilePhotoCommand{UserID: userID, Photo: upload},
	)
	if err != nil {
		if errors.Is(err, profileapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		if strings.Contains(strings.ToLower(err.Error()), "photo quota") ||
			strings.Contains(strings.ToLower(err.Error()), "storage quota") {
			_ = s.deleteStoredMedia(upload.StoragePath)
			writeError(w, http.StatusConflict, err)
			return
		}
		_ = s.deleteStoredMedia(upload.StoragePath)
		writeError(w, http.StatusBadGateway, err)
		return
	}

	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected add profile photo response payload"))
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) serveUploadedMedia(w http.ResponseWriter, r *http.Request) {
	relativePath := strings.TrimPrefix(path.Clean("/"+chi.URLParam(r, "*")), "/")
	if relativePath == "" || strings.Contains(relativePath, "..") {
		writeError(w, http.StatusBadRequest, errors.New("invalid media path"))
		return
	}
	if s.store == nil || s.store.profileRepo == nil || s.store.profileRepo.pg == nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("media authorization is unavailable"))
		return
	}
	var record mediaAccessRecord
	err := sql.ErrNoRows
	for _, storagePath := range s.profileMediaStorageKeys(relativePath) {
		record, err = s.store.profileRepo.mediaAccessByStoragePathPostgres(r.Context(), storagePath)
		if err == nil {
			break
		}
	}
	if err != nil || record.ModerationStatus != mediaModerationApproved {
		writeError(w, http.StatusNotFound, errors.New("media not found"))
		return
	}
	s.serveStoredMedia(w, r, record)
}

func (s *Server) persistUploadedPhoto(r *http.Request, userID string) (validatedPhotoUpload, error) {
	if err := r.ParseMultipartForm(12 << 20); err != nil {
		return validatedPhotoUpload{}, fmt.Errorf("invalid multipart payload: %w", err)
	}

	file, header, err := r.FormFile("image")
	if err != nil {
		file, header, err = r.FormFile("file")
		if err != nil {
			return validatedPhotoUpload{}, errors.New("image file is required")
		}
	}
	defer file.Close()

	safeUserID := sanitizePathSegment(userID)
	content, err := io.ReadAll(io.LimitReader(file, maxProfilePhotoBytes+1))
	if err != nil {
		return validatedPhotoUpload{}, fmt.Errorf("failed to read image payload: %w", err)
	}
	upload, err := validateProfilePhoto(header.Filename, content)
	if err != nil {
		return validatedPhotoUpload{}, err
	}
	if s.mediaModerator == nil {
		return validatedPhotoUpload{}, newMediaUploadError(
			http.StatusServiceUnavailable,
			"Photo moderation is temporarily unavailable.",
		)
	}
	moderation, err := s.mediaModerator.Moderate(r.Context(), upload)
	if err != nil {
		s.log.Warn("profile photo moderation failed", zap.Error(err), zap.String("user_id", userID))
		return validatedPhotoUpload{}, newMediaUploadError(
			http.StatusServiceUnavailable,
			"Photo moderation is temporarily unavailable. Please retry.",
		)
	}
	upload.Moderation = moderation
	upload.ModerationLabels, err = json.Marshal(moderation.Labels)
	if err != nil {
		return validatedPhotoUpload{}, fmt.Errorf("encode photo moderation labels: %w", err)
	}
	for _, label := range moderation.Labels {
		if label.Confidence > upload.MaxConfidence {
			upload.MaxConfidence = label.Confidence
		}
	}
	if moderation.Status == mediaModerationRejected {
		if s.store != nil && s.store.profileRepo != nil && s.store.profileRepo.pg != nil {
			if auditErr := s.store.profileRepo.recordRejectedMediaModerationPostgres(
				r.Context(), userID, upload,
			); auditErr != nil {
				s.log.Error("rejected photo moderation audit failed", zap.Error(auditErr), zap.String("user_id", userID))
				return validatedPhotoUpload{}, newMediaUploadError(
					http.StatusServiceUnavailable,
					"Photo moderation is temporarily unavailable. Please retry.",
				)
			}
		}
		return validatedPhotoUpload{}, newMediaUploadError(
			http.StatusUnprocessableEntity,
			"This photo does not meet the profile media policy.",
		)
	}
	filename := upload.ID + upload.Extension
	storageNamespace := "approved"
	if moderation.Status != mediaModerationApproved {
		storageNamespace = "quarantine"
	}
	storageUserPath := path.Join(storageNamespace, safeUserID)

	upload.StoragePath, err = s.storeMedia(r.Context(), storageUserPath, filename, upload.MimeType, content)
	if err == nil {
		upload.PhotoURL = s.mediaURLForStoragePath(r, upload.StoragePath)
	}
	return upload, err
}

func (s *Server) resolveMediaPublicBaseURL(r *http.Request) string {
	raw := strings.TrimSpace(s.cfg.MediaPublicBaseURL)
	normalized := strings.TrimRight(raw, "/")
	if normalized != "" && !strings.EqualFold(normalized, "auto") {
		return normalized
	}

	return requestBaseURL(r, defaultGatewayHost(s.cfg.APIGatewayAddr))
}

func detectUploadContentType(headerContentType, filename string, content []byte) string {
	if normalized := strings.TrimSpace(headerContentType); normalized != "" {
		return normalized
	}
	if detected := strings.TrimSpace(http.DetectContentType(content)); detected != "" {
		return detected
	}
	switch normalizeImageExtension(filename) {
	case ".png":
		return "image/png"
	case ".webp":
		return "image/webp"
	default:
		return "image/jpeg"
	}
}

func escapeURLPath(value string) string {
	segments := strings.Split(strings.Trim(strings.ReplaceAll(value, "\\", "/"), "/"), "/")
	for index, segment := range segments {
		segments[index] = url.PathEscape(segment)
	}
	return strings.Join(segments, "/")
}

func requestBaseURL(r *http.Request, fallbackHost string) string {
	host := strings.TrimSpace(r.Header.Get("X-Forwarded-Host"))
	if host == "" {
		host = strings.TrimSpace(r.Host)
	}
	if host == "" {
		host = strings.TrimSpace(fallbackHost)
	}
	if host == "" {
		host = "localhost"
	}

	scheme := strings.TrimSpace(r.Header.Get("X-Forwarded-Proto"))
	if scheme == "" {
		if r.TLS != nil {
			scheme = "https"
		} else {
			scheme = "http"
		}
	}

	return scheme + "://" + host
}

func defaultGatewayHost(addr string) string {
	normalized := strings.TrimSpace(addr)
	if normalized == "" {
		return ""
	}
	if strings.HasPrefix(normalized, ":") {
		return "localhost" + normalized
	}
	if strings.Contains(normalized, "://") {
		parsed, err := url.Parse(normalized)
		if err == nil && strings.TrimSpace(parsed.Host) != "" {
			return strings.TrimSpace(parsed.Host)
		}
	}
	return normalized
}

var disallowedSegmentChars = regexp.MustCompile(`[^a-zA-Z0-9_-]`)

func sanitizePathSegment(value string) string {
	trimmed := strings.TrimSpace(value)
	if trimmed == "" {
		return "user"
	}
	cleaned := disallowedSegmentChars.ReplaceAllString(trimmed, "_")
	if cleaned == "" {
		return "user"
	}
	return cleaned
}

func normalizeImageExtension(filename string) string {
	ext := strings.ToLower(strings.TrimSpace(filepath.Ext(filename)))
	switch ext {
	case ".jpg", ".jpeg", ".png", ".webp":
		return ext
	default:
		return ".jpg"
	}
}

func (s *Server) deleteProfilePhoto(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	photoID := strings.TrimSpace(chi.URLParam(r, "photoID"))
	if userID == "" || photoID == "" {
		writeError(w, http.StatusBadRequest, errors.New("user id and photo id are required"))
		return
	}
	if !s.requireLocalSignupUser(w, r, userID) {
		return
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	storagePath := ""
	if s.store != nil && s.store.profileRepo != nil && s.store.profileRepo.pg != nil {
		path, err := s.store.profileRepo.profilePhotoStoragePathPostgres(ctx, userID, photoID)
		if err != nil {
			if errors.Is(err, sql.ErrNoRows) {
				writeError(w, http.StatusNotFound, errors.New("profile photo not found"))
				return
			}
			writeError(w, http.StatusBadGateway, err)
			return
		}
		storagePath = path
	}

	respAny, err := s.mediator.Send(
		ctx,
		profileapp.DeleteProfilePhotoCommandName,
		profileapp.DeleteProfilePhotoCommand{UserID: userID, PhotoID: photoID},
	)
	if err != nil {
		if errors.Is(err, profileapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusBadGateway, err)
		return
	}

	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected delete profile photo response payload"))
		return
	}
	if storagePath != "" && s.store != nil && s.store.profileRepo != nil {
		if err := s.deleteStoredMedia(storagePath); err != nil {
			s.log.Warn("profile photo object deletion deferred")
		} else if s.store.profileRepo.pg != nil {
			_ = ignoreMissingMediaRow(s.store.profileRepo.markMediaDeletedPostgres(ctx, photoID))
		}
	}
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) reorderProfilePhotos(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	if userID == "" {
		writeError(w, http.StatusBadRequest, errors.New("user id is required"))
		return
	}
	if !s.requireLocalSignupUser(w, r, userID) {
		return
	}

	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	photoIDs, ok := toStringSlice(payload["photo_ids"])
	if !ok || len(photoIDs) == 0 {
		writeError(w, http.StatusBadRequest, errors.New("photo_ids are required"))
		return
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		profileapp.ReorderProfilePhotosCommandName,
		profileapp.ReorderProfilePhotosCommand{UserID: userID, PhotoIDs: photoIDs},
	)
	if err != nil {
		if errors.Is(err, profileapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusBadGateway, err)
		return
	}

	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected reorder photos response payload"))
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) completeProfile(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	if userID == "" {
		writeError(w, http.StatusBadRequest, errors.New("user id is required"))
		return
	}
	if !s.requireLocalSignupUser(w, r, userID) {
		return
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		profileapp.CompleteProfileCommandName,
		profileapp.CompleteProfileCommand{UserID: userID},
	)
	if err != nil {
		if errors.Is(err, profileapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusBadGateway, err)
		return
	}

	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected complete profile response payload"))
		return
	}

	s.store.recordActivity(activityEvent{
		UserID:   userID,
		Actor:    userID,
		Action:   "profile.completed",
		Status:   "success",
		Resource: "/v1/profile/" + userID + "/complete",
		Details: map[string]any{
			"completion": 100,
		},
	})
	s.awardProgression(r.Context(), xpAwardInput{
		UserID: userID, Source: "profile_completed", SourceEventID: userID,
		IdempotencyKey: "profile_completed:" + userID,
		Metadata:       map[string]any{"completion": 100},
	})
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) recordProfileView(w http.ResponseWriter, r *http.Request) {
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}

	viewerUserID := strings.TrimSpace(toString(payload["viewer_user_id"]))
	viewedUserID := strings.TrimSpace(toString(payload["viewed_user_id"]))
	if viewerUserID == "" || viewedUserID == "" {
		writeError(w, http.StatusBadRequest, errors.New("viewer_user_id and viewed_user_id are required"))
		return
	}
	if viewerUserID == viewedUserID {
		writeJSON(w, http.StatusOK, map[string]any{"success": true})
		return
	}

	s.enqueueNonCriticalActivity(activityEvent{
		UserID:   viewedUserID,
		Actor:    viewerUserID,
		Action:   "profile.viewed",
		Status:   "success",
		Resource: "/profile/" + viewedUserID + "/viewers",
		Details: map[string]any{
			"viewer_user_id": viewerUserID,
			"viewed_user_id": viewedUserID,
		},
	})

	writeJSON(w, http.StatusOK, map[string]any{"success": true})
}

func (s *Server) listProfileViewers(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	if userID == "" {
		writeError(w, http.StatusBadRequest, errors.New("user id is required"))
		return
	}

	limit := 50
	if raw := strings.TrimSpace(r.URL.Query().Get("limit")); raw != "" {
		if parsed, err := strconv.Atoi(raw); err == nil && parsed > 0 {
			if parsed > 200 {
				parsed = 200
			}
			limit = parsed
		}
	}

	events := s.store.listActivities(2000)
	seen := make(map[string]struct{}, limit)
	viewers := make([]map[string]any, 0, limit)

	for _, item := range events {
		if item.Action != "profile.viewed" {
			continue
		}
		if item.Status != "success" {
			continue
		}
		details := item.Details
		if details == nil {
			continue
		}
		viewedUserID := strings.TrimSpace(toString(details["viewed_user_id"]))
		if viewedUserID != userID {
			continue
		}
		viewerUserID := strings.TrimSpace(toString(details["viewer_user_id"]))
		if viewerUserID == "" {
			continue
		}
		if _, exists := seen[viewerUserID]; exists {
			continue
		}

		seen[viewerUserID] = struct{}{}
		draft := s.store.getDraft(viewerUserID)
		viewerName := strings.TrimSpace(draft.Name)
		if viewerName == "" {
			viewerName = "User"
		}
		photoURL := ""
		if len(draft.Photos) > 0 {
			photoURL = strings.TrimSpace(draft.Photos[0].PhotoURL)
		}

		viewers = append(viewers, map[string]any{
			"user_id":   viewerUserID,
			"name":      viewerName,
			"photo_url": photoURL,
			"viewed_at": item.CreatedAt,
		})
		if len(viewers) >= limit {
			break
		}
	}

	writeJSON(w, http.StatusOK, map[string]any{"viewers": viewers})
}

func (s *Server) getSettings(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	if userID == "" {
		writeError(w, http.StatusBadRequest, errors.New("user id is required"))
		return
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(ctx, profileapp.GetSettingsCommandName, profileapp.GetSettingsCommand{UserID: userID})
	if err != nil {
		if errors.Is(err, profileapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusBadGateway, err)
		return
	}

	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected get settings response payload"))
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) patchSettings(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	if userID == "" {
		writeError(w, http.StatusBadRequest, errors.New("user id is required"))
		return
	}

	payload, ok := readJSON(w, r)
	if !ok {
		return
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		profileapp.PatchSettingsCommandName,
		profileapp.PatchSettingsCommand{UserID: userID, Payload: payload},
	)
	if err != nil {
		if errors.Is(err, profileapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusBadGateway, err)
		return
	}

	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected patch settings response payload"))
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) listEmergencyContacts(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	if userID == "" {
		writeError(w, http.StatusBadRequest, errors.New("user id is required"))
		return
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		profileapp.ListEmergencyContactsCommandName,
		profileapp.ListEmergencyContactsCommand{UserID: userID},
	)
	if err != nil {
		if errors.Is(err, profileapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusBadGateway, err)
		return
	}

	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected list emergency contacts response payload"))
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) addEmergencyContact(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	if userID == "" {
		writeError(w, http.StatusBadRequest, errors.New("user id is required"))
		return
	}

	payload, ok := readJSON(w, r)
	if !ok {
		return
	}

	name := strings.TrimSpace(toString(payload["name"]))
	phoneNumber := strings.TrimSpace(toString(payload["phone_number"]))
	if name == "" || phoneNumber == "" {
		writeError(w, http.StatusBadRequest, errors.New("name and phone_number are required"))
		return
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		profileapp.AddEmergencyContactCommandName,
		profileapp.AddEmergencyContactCommand{UserID: userID, Name: name, PhoneNumber: phoneNumber},
	)
	if err != nil {
		if errors.Is(err, profileapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusBadGateway, err)
		return
	}

	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected add emergency contact response payload"))
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) updateEmergencyContact(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	contactID := strings.TrimSpace(chi.URLParam(r, "contactID"))
	if userID == "" || contactID == "" {
		writeError(w, http.StatusBadRequest, errors.New("user id and contact id are required"))
		return
	}

	payload, ok := readJSON(w, r)
	if !ok {
		return
	}

	name := strings.TrimSpace(toString(payload["name"]))
	phoneNumber := strings.TrimSpace(toString(payload["phone_number"]))
	if name == "" || phoneNumber == "" {
		writeError(w, http.StatusBadRequest, errors.New("name and phone_number are required"))
		return
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		profileapp.UpdateEmergencyContactCommandName,
		profileapp.UpdateEmergencyContactCommand{
			UserID:      userID,
			ContactID:   contactID,
			Name:        name,
			PhoneNumber: phoneNumber,
		},
	)
	if err != nil {
		if errors.Is(err, profileapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		if strings.Contains(strings.ToLower(err.Error()), "not found") {
			writeError(w, http.StatusNotFound, err)
			return
		}
		writeError(w, http.StatusBadGateway, err)
		return
	}

	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected update emergency contact response payload"))
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) deleteEmergencyContact(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	contactID := strings.TrimSpace(chi.URLParam(r, "contactID"))
	if userID == "" || contactID == "" {
		writeError(w, http.StatusBadRequest, errors.New("user id and contact id are required"))
		return
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		profileapp.DeleteEmergencyContactCommandName,
		profileapp.DeleteEmergencyContactCommand{UserID: userID, ContactID: contactID},
	)
	if err != nil {
		if errors.Is(err, profileapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusBadGateway, err)
		return
	}

	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected delete emergency contact response payload"))
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) listBlockedUsers(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	if userID == "" {
		writeError(w, http.StatusBadRequest, errors.New("user id is required"))
		return
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(ctx, profileapp.ListBlockedUsersCommandName, profileapp.ListBlockedUsersCommand{UserID: userID})
	if err != nil {
		if errors.Is(err, profileapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusBadGateway, err)
		return
	}

	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected blocked users response payload"))
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) getVerification(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	if userID == "" {
		writeError(w, http.StatusBadRequest, errors.New("user id is required"))
		return
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		verificationapp.GetVerificationCommandName,
		verificationapp.GetVerificationCommand{UserID: userID},
	)
	if err != nil {
		if errors.Is(err, verificationapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusBadGateway, err)
		return
	}

	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected get verification response payload"))
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) submitVerification(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	if userID == "" {
		writeError(w, http.StatusBadRequest, errors.New("user id is required"))
		return
	}
	if !s.requireLocalSignupUser(w, r, userID) {
		return
	}
	if !strings.HasPrefix(strings.ToLower(strings.TrimSpace(r.Header.Get("Content-Type"))), "multipart/form-data") {
		writeError(w, http.StatusUnsupportedMediaType, errors.New("identity evidence must be uploaded as multipart image content"))
		return
	}
	evidence, storedPaths, providerBundle, err := s.persistVerificationEvidence(r, userID)
	if err != nil {
		writeError(w, mediaUploadHTTPStatus(err), err)
		return
	}
	cleanup := func() {
		for _, storagePath := range storedPaths {
			_ = s.deleteStoredMedia(storagePath)
		}
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()
	assessment, err := s.identityVerifier.Assess(ctx, userID, providerBundle)
	if err != nil {
		cleanup()
		writeError(w, http.StatusServiceUnavailable, errors.New("identity verification provider is temporarily unavailable"))
		return
	}
	evidence["provider_assessment"] = map[string]any{
		"decision": assessment.Decision, "reason": assessment.Reason,
		"confidence": assessment.Confidence, "provider": assessment.Provider,
		"provider_reference": assessment.ProviderRef, "model_version": assessment.ModelVersion,
		"assessed_at": assessment.AssessedAtUTC,
	}

	respAny, err := s.mediator.Send(
		ctx,
		verificationapp.SubmitVerificationCommandName,
		verificationapp.SubmitVerificationCommand{UserID: userID},
	)
	if err != nil {
		cleanup()
		if errors.Is(err, verificationapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusBadGateway, err)
		return
	}
	attached, err := s.store.attachVerificationEvidence(userID, evidence)
	if err != nil {
		cleanup()
		writeError(w, http.StatusBadGateway, err)
		return
	}

	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected submit verification response payload"))
		return
	}
	resp["evidence_received"] = attached.EvidenceReceived
	resp["provider_decision"] = assessment.Decision
	if assessment.Decision == "approved" || assessment.Decision == "rejected" {
		reason := strings.TrimSpace(assessment.Reason)
		if assessment.Decision == "rejected" && reason == "" {
			reason = "Identity evidence could not be verified."
		}
		reviewed, reviewErr := s.store.reviewVerification(
			userID, assessment.Decision, reason, s.cfg.IdentityVerificationActorID,
		)
		if reviewErr != nil {
			writeError(w, http.StatusBadGateway, errors.New("provider decision could not be committed"))
			return
		}
		resp["status"] = reviewed.Status
		resp["rejection_reason"] = reviewed.RejectionReason
	}
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) listAdminActivities(w http.ResponseWriter, r *http.Request) {
	limit := 100
	if raw := strings.TrimSpace(r.URL.Query().Get("limit")); raw != "" {
		if parsed, err := strconv.Atoi(raw); err == nil {
			limit = parsed
		}
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(ctx, adminapp.ListActivitiesCommandName, adminapp.ListActivitiesCommand{Limit: limit})
	if err != nil {
		if errors.Is(err, adminapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusBadGateway, err)
		return
	}

	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected admin activities response payload"))
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) listAdminVerifications(w http.ResponseWriter, r *http.Request) {
	limit := 100
	if raw := strings.TrimSpace(r.URL.Query().Get("limit")); raw != "" {
		if parsed, err := strconv.Atoi(raw); err == nil {
			limit = parsed
		}
	}
	status := strings.TrimSpace(r.URL.Query().Get("status"))

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		verificationapp.ListVerificationsCommandName,
		verificationapp.ListVerificationsCommand{Status: status, Limit: limit},
	)
	if err != nil {
		if errors.Is(err, verificationapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusBadGateway, err)
		return
	}

	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected admin verifications response payload"))
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) approveVerification(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	if userID == "" {
		writeError(w, http.StatusBadRequest, errors.New("user id is required"))
		return
	}

	reviewedBy := strings.TrimSpace(r.Header.Get("X-Admin-User"))
	if reviewedBy == "" {
		reviewedBy = "control-panel"
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		verificationapp.ApproveVerificationCommandName,
		verificationapp.ApproveVerificationCommand{UserID: userID, ReviewedBy: reviewedBy},
	)
	if err != nil {
		if errors.Is(err, verificationapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		if strings.Contains(strings.ToLower(err.Error()), "not found") {
			writeError(w, http.StatusNotFound, err)
			return
		}
		writeError(w, http.StatusBadGateway, err)
		return
	}

	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected approve verification response payload"))
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) rejectVerification(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	if userID == "" {
		writeError(w, http.StatusBadRequest, errors.New("user id is required"))
		return
	}

	reason := ""
	contentType := strings.ToLower(strings.TrimSpace(r.Header.Get("Content-Type")))
	if strings.Contains(contentType, "application/json") {
		payload, ok := readJSON(w, r)
		if !ok {
			return
		}
		reason = strings.TrimSpace(toString(payload["rejection_reason"]))
	} else {
		if err := r.ParseForm(); err != nil {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		reason = strings.TrimSpace(r.FormValue("rejection_reason"))
	}
	if reason == "" {
		writeError(w, http.StatusBadRequest, errors.New("rejection_reason is required"))
		return
	}

	reviewedBy := strings.TrimSpace(r.Header.Get("X-Admin-User"))
	if reviewedBy == "" {
		reviewedBy = "control-panel"
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		verificationapp.RejectVerificationCommandName,
		verificationapp.RejectVerificationCommand{UserID: userID, RejectionReason: reason, ReviewedBy: reviewedBy},
	)
	if err != nil {
		if errors.Is(err, verificationapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		if strings.Contains(strings.ToLower(err.Error()), "not found") {
			writeError(w, http.StatusNotFound, err)
			return
		}
		writeError(w, http.StatusBadGateway, err)
		return
	}

	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected reject verification response payload"))
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) listAdminReports(w http.ResponseWriter, r *http.Request) {
	limit := 100
	if raw := strings.TrimSpace(r.URL.Query().Get("limit")); raw != "" {
		if parsed, err := strconv.Atoi(raw); err == nil {
			limit = parsed
		}
	}
	status := strings.TrimSpace(r.URL.Query().Get("status"))

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		adminapp.ListReportsCommandName,
		adminapp.ListReportsCommand{Status: status, Limit: limit},
	)
	if err != nil {
		if errors.Is(err, adminapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusBadGateway, err)
		return
	}

	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected admin reports response payload"))
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) actionAdminReport(w http.ResponseWriter, r *http.Request) {
	reportID := strings.TrimSpace(chi.URLParam(r, "reportID"))
	if reportID == "" {
		writeError(w, http.StatusBadRequest, errors.New("report id is required"))
		return
	}

	payload, ok := readJSON(w, r)
	if !ok {
		return
	}

	status := strings.TrimSpace(toString(payload["status"]))
	action := strings.TrimSpace(toString(payload["action"]))
	reviewedBy := strings.TrimSpace(r.Header.Get("X-Admin-User"))
	if reviewedBy == "" {
		reviewedBy = strings.TrimSpace(toString(payload["reviewed_by"]))
	}
	if reviewedBy == "" {
		reviewedBy = "control-panel"
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		adminapp.ActionReportCommandName,
		adminapp.ActionReportCommand{ReportID: reportID, Status: status, Action: action, ReviewedBy: reviewedBy},
	)
	if err != nil {
		if errors.Is(err, adminapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		statusCode := http.StatusBadGateway
		if strings.Contains(strings.ToLower(err.Error()), "not found") {
			statusCode = http.StatusNotFound
		}
		writeError(w, statusCode, err)
		return
	}

	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected action admin report response payload"))
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) submitModerationAppeal(w http.ResponseWriter, r *http.Request) {
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}

	userID := strings.TrimSpace(toString(payload["user_id"]))
	if userID == "" {
		userID = strings.TrimSpace(r.Header.Get("X-User-ID"))
	}
	reportID := strings.TrimSpace(toString(payload["report_id"]))
	reason := strings.TrimSpace(toString(payload["reason"]))
	description := strings.TrimSpace(toString(payload["description"]))

	appeal, err := s.store.submitModerationAppeal(userID, reportID, reason, description)
	if err != nil {
		writeError(w, http.StatusBadRequest, err)
		return
	}

	s.enqueueNonCriticalActivity(activityEvent{
		UserID:   appeal.UserID,
		Actor:    appeal.UserID,
		Action:   "appeal.submitted",
		Status:   "success",
		Resource: "/v1/moderation/appeals",
		Details: map[string]any{
			"appeal_id":           appeal.ID,
			"report_id":           appeal.ReportID,
			"status":              appeal.Status,
			"sla_deadline_at":     appeal.SLADeadlineAt,
			"notification_policy": appeal.NotificationPolicy,
		},
	})

	writeJSON(w, http.StatusOK, map[string]any{"appeal": appeal, "success": true})
}

func (s *Server) listModerationAppealsForUser(w http.ResponseWriter, r *http.Request) {
	limit := 100
	if raw := strings.TrimSpace(r.URL.Query().Get("limit")); raw != "" {
		if parsed, err := strconv.Atoi(raw); err == nil {
			limit = parsed
		}
	}
	status := strings.TrimSpace(r.URL.Query().Get("status"))
	userID := strings.TrimSpace(r.URL.Query().Get("user_id"))
	if userID == "" {
		userID = strings.TrimSpace(r.Header.Get("X-User-ID"))
	}
	if userID == "" {
		writeError(w, http.StatusBadRequest, errors.New("user_id is required"))
		return
	}

	appeals := s.store.listModerationAppealsForUser(userID, status, limit)
	writeJSON(w, http.StatusOK, map[string]any{"appeals": appeals})
}

func (s *Server) getModerationAppealStatus(w http.ResponseWriter, r *http.Request) {
	appealID := strings.TrimSpace(chi.URLParam(r, "appealID"))
	if appealID == "" {
		writeError(w, http.StatusBadRequest, errors.New("appeal id is required"))
		return
	}
	requesterUserID := strings.TrimSpace(r.Header.Get("X-User-ID"))
	if requesterUserID == "" {
		requesterUserID = strings.TrimSpace(r.URL.Query().Get("user_id"))
	}

	appeal, err := s.store.getModerationAppeal(appealID, requesterUserID, false)
	if err != nil {
		writeError(w, http.StatusNotFound, err)
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"appeal":  appeal,
		"status":  appeal.Status,
		"success": true,
	})
}

func (s *Server) listAdminModerationAppeals(w http.ResponseWriter, r *http.Request) {
	limit := 100
	if raw := strings.TrimSpace(r.URL.Query().Get("limit")); raw != "" {
		if parsed, err := strconv.Atoi(raw); err == nil {
			limit = parsed
		}
	}
	status := strings.TrimSpace(r.URL.Query().Get("status"))

	appeals := s.store.listModerationAppeals(status, limit)
	writeJSON(w, http.StatusOK, map[string]any{"appeals": appeals})
}

func (s *Server) actionAdminModerationAppeal(w http.ResponseWriter, r *http.Request) {
	appealID := strings.TrimSpace(chi.URLParam(r, "appealID"))
	if appealID == "" {
		writeError(w, http.StatusBadRequest, errors.New("appeal id is required"))
		return
	}

	payload, ok := readJSON(w, r)
	if !ok {
		return
	}

	status := strings.TrimSpace(toString(payload["status"]))
	resolutionReason := strings.TrimSpace(toString(payload["resolution_reason"]))
	reviewedBy := strings.TrimSpace(r.Header.Get("X-Admin-User"))
	if reviewedBy == "" {
		reviewedBy = strings.TrimSpace(toString(payload["reviewed_by"]))
	}
	if reviewedBy == "" {
		reviewedBy = "control-panel"
	}

	appeal, err := s.store.actionModerationAppeal(appealID, status, resolutionReason, reviewedBy)
	if err != nil {
		statusCode := http.StatusBadRequest
		if strings.Contains(strings.ToLower(err.Error()), "not found") {
			statusCode = http.StatusNotFound
		}
		writeError(w, statusCode, err)
		return
	}

	s.enqueueNonCriticalActivity(activityEvent{
		UserID:   appeal.UserID,
		Actor:    reviewedBy,
		Action:   "appeal.resolved",
		Status:   "success",
		Resource: "/v1/admin/moderation/appeals/" + appealID + "/action",
		Details: map[string]any{
			"appeal_id":           appeal.ID,
			"status":              appeal.Status,
			"reviewed_by":         appeal.ReviewedBy,
			"resolution_reason":   appeal.ResolutionReason,
			"notification_policy": appeal.NotificationPolicy,
		},
	})

	writeJSON(w, http.StatusOK, map[string]any{"appeal": appeal, "success": true})
}

func (s *Server) adminAnalyticsOverview(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(ctx, adminapp.AnalyticsOverviewCommandName, adminapp.AnalyticsOverviewCommand{})
	if err != nil {
		if errors.Is(err, adminapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusBadGateway, err)
		return
	}

	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected admin analytics overview response payload"))
		return
	}
	if metrics, ok := resp["metrics"].(map[string]any); ok {
		if s.fanout != nil {
			metrics["queue_metrics"] = s.fanout.QueueMetrics()
			metrics["precomputed_aggregates"] = s.fanout.AggregateSnapshot()
		}
		metrics["member_activity"] = s.memberActivityKPIs(ctx)
		// funnel_metrics and the other runtime counters come from this
		// instance's in-memory activity: per process, reset on restart and
		// empty when Postgres is configured. The durable reports live under
		// /v1/admin/analytics/{kpis,trends,funnel,retention,engagement,liquidity,safety}.
		metrics["runtime_metrics_scope"] = map[string]any{
			"source":   "process_local_runtime_store",
			"durable":  false,
			"fields":   []string{"funnel_metrics"},
			"use":      "/v1/admin/analytics/kpis",
			"guidance": "Do not report these counters; they are per instance and reset on restart.",
		}
	}
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) reportUser(w http.ResponseWriter, r *http.Request) {
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	reporterUserID := strings.TrimSpace(toString(payload["reporter_user_id"]))
	if reporterUserID == "" {
		reporterUserID = strings.TrimSpace(r.Header.Get("X-User-ID"))
	}
	reportedUserID := strings.TrimSpace(toString(payload["reported_user_id"]))
	reason := strings.TrimSpace(toString(payload["reason"]))
	description := strings.TrimSpace(toString(payload["description"]))

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		safetyapp.ReportUserCommandName,
		safetyapp.ReportUserCommand{
			ReporterUserID: reporterUserID,
			ReportedUserID: reportedUserID,
			Reason:         reason,
			Description:    description,
		},
	)
	if err != nil {
		if errors.Is(err, safetyapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusBadGateway, err)
		return
	}

	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected report user response payload"))
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) blockUser(w http.ResponseWriter, r *http.Request) {
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	userID := strings.TrimSpace(toString(payload["user_id"]))
	blockedUserID := strings.TrimSpace(toString(payload["blocked_user_id"]))

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		safetyapp.BlockUserCommandName,
		safetyapp.BlockUserCommand{UserID: userID, BlockedUserID: blockedUserID},
	)
	if err != nil {
		if errors.Is(err, safetyapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusBadGateway, err)
		return
	}

	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected block user response payload"))
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) unblockUser(w http.ResponseWriter, r *http.Request) {
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	userID := strings.TrimSpace(toString(payload["user_id"]))
	blockedUserID := strings.TrimSpace(toString(payload["blocked_user_id"]))

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		safetyapp.UnblockUserCommandName,
		safetyapp.UnblockUserCommand{UserID: userID, BlockedUserID: blockedUserID},
	)
	if err != nil {
		if errors.Is(err, safetyapp.ErrValidation) {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusBadGateway, err)
		return
	}

	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected unblock user response payload"))
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

func readJSON(w http.ResponseWriter, r *http.Request) (map[string]any, bool) {
	defer r.Body.Close()
	var payload map[string]any
	if err := json.NewDecoder(r.Body).Decode(&payload); err != nil {
		writeError(w, http.StatusBadRequest, err)
		return nil, false
	}
	if payload == nil {
		payload = map[string]any{}
	}
	return payload, true
}

func writeJSON(w http.ResponseWriter, status int, payload map[string]any) {
	if payload == nil {
		payload = map[string]any{}
	}

	correlationID := strings.TrimSpace(w.Header().Get(observability.CorrelationIDHeader))
	if correlationID != "" {
		if _, exists := payload["correlation_id"]; !exists {
			payload["correlation_id"] = correlationID
		}
		w.Header().Set(observability.CorrelationIDHeader, correlationID)
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(payload)
}

func writeError(w http.ResponseWriter, status int, err error) {
	errorCode := strings.ToUpper(strings.ReplaceAll(http.StatusText(status), " ", "_"))
	if errorCode == "" {
		errorCode = "UNKNOWN_ERROR"
	}

	writeJSON(w, status, map[string]any{
		"success":    false,
		"error":      err.Error(),
		"error_code": errorCode,
	})
}

type responseStatusRecorder struct {
	http.ResponseWriter
	status int
}

func (s *responseStatusRecorder) WriteHeader(code int) {
	s.status = code
	s.ResponseWriter.WriteHeader(code)
}

func (s *responseStatusRecorder) Hijack() (net.Conn, *bufio.ReadWriter, error) {
	hijacker, ok := s.ResponseWriter.(http.Hijacker)
	if !ok {
		return nil, nil, http.ErrNotSupported
	}
	return hijacker.Hijack()
}

func statusLabel(status int) string {
	switch {
	case status >= 200 && status <= 299:
		return "success"
	case status >= 400 && status <= 499:
		return "client_error"
	case status >= 500:
		return "server_error"
	default:
		return "unknown"
	}
}

func (s *Server) engagementTelemetryDetails(path string) map[string]any {
	trimmedPath := strings.TrimSpace(path)
	if trimmedPath == "" {
		return nil
	}
	if !isEngagementTelemetryPath(trimmedPath) {
		return nil
	}
	variant := unlockPolicyRequireQuestTemplate
	if s != nil && s.store != nil {
		variant = s.store.unlockPolicyVariant()
	}
	return map[string]any{
		"unlock_policy_variant": variant,
	}
}

func isEngagementTelemetryPath(path string) bool {
	path = strings.ToLower(strings.TrimSpace(path))
	if path == "" {
		return false
	}
	if strings.Contains(path, "/engagement/") {
		return true
	}
	return strings.Contains(path, "/unlock-state") ||
		strings.Contains(path, "/quest-") ||
		strings.Contains(path, "/gestures") ||
		strings.Contains(path, "/activities") ||
		strings.Contains(path, "/chat/")
}

func (s *Server) billingPolicyTelemetryDetails(path string) map[string]any {
	trimmedPath := strings.TrimSpace(path)
	if trimmedPath == "" || !isBillingTelemetryPath(trimmedPath) {
		return nil
	}
	if s == nil || s.store == nil {
		return nil
	}
	matrix := s.store.billingCoexistenceMatrix()
	version := strings.TrimSpace(toString(matrix["matrix_version"]))
	coreNonBlocking, _ := matrix["core_progression_non_blocking"].(bool)
	return map[string]any{
		"monetization_matrix_version":   version,
		"core_progression_non_blocking": coreNonBlocking,
	}
}

func isBillingTelemetryPath(path string) bool {
	path = strings.ToLower(strings.TrimSpace(path))
	if path == "" {
		return false
	}
	return strings.Contains(path, "/billing/")
}

func mergeDetails(primary, extra map[string]any) map[string]any {
	out := make(map[string]any, len(primary)+len(extra))
	for key, value := range primary {
		out[key] = value
	}
	for key, value := range extra {
		if _, exists := out[key]; exists {
			continue
		}
		out[key] = value
	}
	return out
}

func (s *Server) connState(conn *grpc.ClientConn) string {
	if conn == nil {
		return connectivity.Shutdown.String()
	}
	return conn.GetState().String()
}

func ternary(condition bool, whenTrue, whenFalse string) string {
	if condition {
		return whenTrue
	}
	return whenFalse
}

func toString(value any) string {
	if typed, ok := value.(string); ok {
		return typed
	}
	return ""
}

func numericValue(value any) int {
	parsed, ok := toInt(value)
	if !ok {
		return 0
	}
	return parsed
}

func toFloat64(value any) (float64, bool) {
	switch typed := value.(type) {
	case float64:
		return typed, true
	case float32:
		return float64(typed), true
	case int:
		return float64(typed), true
	case int32:
		return float64(typed), true
	case int64:
		return float64(typed), true
	case json.Number:
		parsed, err := typed.Float64()
		if err != nil {
			return 0, false
		}
		return parsed, true
	case string:
		trimmed := strings.TrimSpace(typed)
		if trimmed == "" {
			return 0, false
		}
		parsed, err := strconv.ParseFloat(trimmed, 64)
		if err != nil {
			return 0, false
		}
		return parsed, true
	default:
		return 0, false
	}
}
