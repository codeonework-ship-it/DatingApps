package mobile

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"path"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"go.uber.org/zap"
	"google.golang.org/grpc"
	"google.golang.org/grpc/connectivity"
	"google.golang.org/grpc/credentials/insecure"

	adminapp "github.com/verified-dating/backend/internal/modules/admin/application"
	admininfra "github.com/verified-dating/backend/internal/modules/admin/infrastructure"
	authapp "github.com/verified-dating/backend/internal/modules/auth/application"
	authinfra "github.com/verified-dating/backend/internal/modules/auth/infrastructure"
	billingapp "github.com/verified-dating/backend/internal/modules/billing/application"
	billinginfra "github.com/verified-dating/backend/internal/modules/billing/infrastructure"
	callsapp "github.com/verified-dating/backend/internal/modules/calls/application"
	callsinfra "github.com/verified-dating/backend/internal/modules/calls/infrastructure"
	chatapp "github.com/verified-dating/backend/internal/modules/chat/application"
	chatinfra "github.com/verified-dating/backend/internal/modules/chat/infrastructure"
	matchingapp "github.com/verified-dating/backend/internal/modules/matching/application"
	matchinginfra "github.com/verified-dating/backend/internal/modules/matching/infrastructure"
	profileapp "github.com/verified-dating/backend/internal/modules/profile/application"
	profileinfra "github.com/verified-dating/backend/internal/modules/profile/infrastructure"
	safetyapp "github.com/verified-dating/backend/internal/modules/safety/application"
	safetyinfra "github.com/verified-dating/backend/internal/modules/safety/infrastructure"
	verificationapp "github.com/verified-dating/backend/internal/modules/verification/application"
	verificationinfra "github.com/verified-dating/backend/internal/modules/verification/infrastructure"
	"github.com/verified-dating/backend/internal/platform/config"
	"github.com/verified-dating/backend/internal/platform/docs"
	"github.com/verified-dating/backend/internal/platform/mediatr"
	"github.com/verified-dating/backend/internal/platform/observability"
)

type Server struct {
	cfg    config.Config
	log    *zap.Logger
	router chi.Router

	authConn        *grpc.ClientConn
	profileConn     *grpc.ClientConn
	matchingConn    *grpc.ClientConn
	chatConn        *grpc.ClientConn
	store           *memoryStore
	masterData      *masterDataRepository
	termsAgreements *termsAgreementRepository
	mediator        *mediatr.Mediator
	bulkheads       map[string]chan struct{}
	idempotency     *idempotencyStore
	fanout          *asyncFanout
}

const aliasRouteSunset = "Wed, 31 Dec 2026 23:59:59 GMT"

func NewServer(cfg config.Config, log *zap.Logger, httpMetrics *observability.HTTPMetrics) (*Server, error) {
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
		store:           newMemoryStore(cfg),
		masterData:      newMasterDataRepository(cfg),
		termsAgreements: newTermsAgreementRepository(cfg),
		mediator:        mediatr.New(),
		bulkheads:       newBulkheadLimiters(cfg),
		idempotency:     newIdempotencyStore(cfg.IdempotencyTTL()),
	}
	s.fanout = newAsyncFanout(cfg, log, s.store)
	if err := s.validateDurableEngagementReadiness(); err != nil {
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
		func(userID, photoURL string) any { return s.store.addPhoto(userID, photoURL) },
		func(userID, photoID string) any { return s.store.deletePhoto(userID, photoID) },
		func(userID string, photoIDs []string) any { return s.store.reorderPhotos(userID, photoIDs) },
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
			s.store.blockUser(userID, blockedUserID)
			return nil
		},
		func(userID, blockedUserID string) error {
			s.store.unblockUser(userID, blockedUserID)
			return nil
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

	verificationGateway := verificationinfra.NewStoreGateway(
		func(userID string) any { return s.store.getVerification(userID) },
		func(userID string) any { return s.store.submitVerification(userID) },
		func(status string, limit int) any { return s.store.listVerifications(status, limit) },
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

	r := chi.NewRouter()
	r.Use(observability.CorrelationIDMiddleware(log))
	r.Use(observability.GlobalExceptionMiddleware(log))
	r.Use(observability.InflightSheddingMiddleware(log, "mobile_bff", cfg.BFFMaxInFlight, cfg.BFFRetryAfterSec))
	r.Use(s.bulkheadMiddleware)
	r.Use(s.idempotencyMiddleware)
	r.Use(observability.RequestLoggingMiddleware(log, httpMetrics, "mobile_bff"))
	r.Use(s.activityMiddleware)

	r.Get("/healthz", s.healthz)
	r.Get("/readyz", s.readyz)
	r.Handle("/metrics", promhttp.Handler())
	r.Mount("/debug", middleware.Profiler())
	r.Get("/openapi.yaml", docs.OpenAPIHandler)
	r.Get("/docs", docs.SwaggerUIHandler("/openapi.yaml"))

	r.Route(cfg.APIPrefix, func(v1 chi.Router) {
		v1.Post("/auth/send-otp", s.sendOTP)
		v1.Post("/auth/verify-otp", s.verifyOTP)
		v1.Get("/users/{userID}/agreements/terms", s.getTermsAgreement)
		v1.Patch("/users/{userID}/agreements/terms", s.patchTermsAgreement)
		v1.Get("/discovery/{userID}", s.getDiscoveryCandidates)
		v1.Get("/master-data/preferences", s.getPreferenceMasterData)
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
		v1.Get("/chat/{matchID}/messages", s.listMessages)
		v1.Post("/chat/{matchID}/messages", s.sendMessage)
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
		v1.Get("/users/{userID}/trust-badges", s.getUserTrustBadges)
		v1.Get("/users/{userID}/trust-badges/history", s.listUserTrustBadgeHistory)
		v1.Get("/friends/{userID}", s.listFriends)
		v1.Post("/friends/{userID}", s.addFriend)
		v1.Delete("/friends/{userID}/{friendUserID}", s.removeFriend)
		v1.Get("/friends/{userID}/activities", s.listFriendActivities)
		v1.Get("/rooms", s.listConversationRooms)
		v1.Post("/rooms/{roomID}/join", s.joinConversationRoom)
		v1.Post("/rooms/{roomID}/leave", s.leaveConversationRoom)
		v1.Post("/rooms/{roomID}/moderate", s.moderateConversationRoom)
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
		v1.Get("/billing/coexistence-matrix", s.getBillingCoexistenceMatrix)
		v1.Get("/billing/subscription/{userID}", s.getBillingSubscription)
		v1.Post("/billing/subscribe", s.subscribePlan)
		v1.Get("/billing/payments/{userID}", s.listBillingPayments)
		v1.Get("/admin/activities", s.listAdminActivities)
		v1.Get("/admin/verifications", s.listAdminVerifications)
		v1.Post("/admin/verifications/{userID}/approve", s.approveVerification)
		v1.Post("/admin/verifications/{userID}/reject", s.rejectVerification)
		v1.Get("/admin/moderation/reports", s.listAdminReports)
		v1.Post("/admin/moderation/reports/{reportID}/action", s.actionAdminReport)
		v1.Get("/admin/moderation/appeals", s.listAdminModerationAppeals)
		v1.Post("/admin/moderation/appeals/{appealID}/action", s.actionAdminModerationAppeal)
		v1.Get("/admin/analytics/overview", s.adminAnalyticsOverview)
	})

	s.router = r
	return s, nil
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
	if s.cfg.FeatureMiniActivities {
		unsupported = append(unsupported, "mini_activities")
	}
	if s.cfg.FeatureTrustBadges {
		unsupported = append(unsupported, "trust_badges")
	}
	if s.cfg.FeatureConversationRooms {
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

		userID := strings.TrimSpace(chi.URLParam(r, "userID"))
		if userID == "" {
			userID = strings.TrimSpace(chi.URLParam(r, "matchID"))
		}
		if userID == "" {
			userID = strings.TrimSpace(r.URL.Query().Get("user_id"))
		}

		actor := strings.TrimSpace(r.Header.Get("X-Admin-User"))
		if actor == "" {
			actor = strings.TrimSpace(r.Header.Get("X-User-ID"))
		}
		if actor == "" {
			actor = "system"
		}

		details := mergeDetails(
			map[string]any{
				"method":       r.Method,
				"path":         r.URL.Path,
				"query":        r.URL.RawQuery,
				"status_code":  recorder.status,
				"duration_ms":  time.Since(start).Milliseconds(),
				"remote_addr":  r.RemoteAddr,
				"content_type": r.Header.Get("Content-Type"),
			},
			s.engagementTelemetryDetails(r.URL.Path),
		)
		details = mergeDetails(details, s.billingPolicyTelemetryDetails(r.URL.Path))

		s.enqueueNonCriticalActivity(activityEvent{
			UserID:   userID,
			Actor:    actor,
			Action:   r.Method + " " + r.URL.Path,
			Status:   statusLabel(recorder.status),
			Resource: r.URL.Path,
			Details:  details,
		})
	})
}

func (s *Server) withRequestTimeout(parent context.Context) (context.Context, context.CancelFunc) {
	return context.WithTimeout(parent, s.cfg.BFFRequestTimeout())
}

func (s *Server) Close() {
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
}

func (s *Server) healthz(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]any{"service": "mobile-bff", "status": "ok"})
}

func (s *Server) readyz(w http.ResponseWriter, _ *http.Request) {
	ready := true
	deps := map[string]any{
		"auth":     s.connState(s.authConn),
		"profile":  s.connState(s.profileConn),
		"matching": s.connState(s.matchingConn),
		"chat":     s.connState(s.chatConn),
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
	case connectivity.Ready.String(), connectivity.Idle.String(), connectivity.Connecting.String():
		return true
	default:
		return false
	}
}

func (s *Server) sendOTP(w http.ResponseWriter, r *http.Request) {
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	email := strings.TrimSpace(toString(payload["email"]))
	if email == "" {
		email = strings.TrimSpace(toString(payload["phone"]))
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(ctx, authapp.SendOTPCommandName, authapp.SendOTPCommand{Email: email})
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
		writeError(w, http.StatusBadGateway, errors.New("unexpected send otp response payload"))
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) verifyOTP(w http.ResponseWriter, r *http.Request) {
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	email := strings.TrimSpace(toString(payload["email"]))
	if email == "" {
		email = strings.TrimSpace(toString(payload["phone"]))
	}
	otp := strings.TrimSpace(toString(payload["otp"]))

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(ctx, authapp.VerifyOTPCommandName, authapp.VerifyOTPCommand{Email: email, OTP: otp})
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
		writeError(w, http.StatusBadGateway, errors.New("unexpected verify otp response payload"))
		return
	}
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) getProfile(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(ctx, profileapp.GetProfileCommandName, profileapp.GetProfileCommand{UserID: userID})
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
		writeError(w, http.StatusBadGateway, errors.New("unexpected get profile response payload"))
		return
	}
	writeJSON(w, http.StatusOK, resp)
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
		if parsed, err := strconv.Atoi(raw); err == nil {
			limit = parsed
		}
	}

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
	s.attachAdvancedFilteredDiscovery(resp, userID, r.URL.Query())
	s.attachTrustFilteredDiscovery(resp, userID)
	s.attachSpotlightDiscovery(resp, userID)
	applyDiscoveryMode(resp, mode)
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
	s.store.recordSpotlightSwipeOutcome(targetUserID, isLike, isMutualMatch)
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
	writeJSON(w, http.StatusOK, resp)
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

	session, err := s.store.startActivitySession(
		matchID,
		initiatorUserID,
		participantUserID,
		activityType,
		metadata,
	)
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

	session, err := s.store.submitActivitySessionResponses(sessionID, userID, responses)
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

	summary, session, err := s.store.getActivitySessionSummary(sessionID)
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

	view, err := s.store.getDailyPromptView(userID, time.Now().UTC())
	if err != nil {
		writeError(w, http.StatusBadRequest, err)
		return
	}

	s.store.recordActivity(activityEvent{
		UserID:   userID,
		Actor:    userID,
		Action:   "daily_prompt_viewed",
		Status:   "success",
		Resource: "/engagement/daily-prompt/" + userID,
		Details: map[string]any{
			"user_id":      userID,
			"prompt_id":    view.Prompt.ID,
			"prompt_date":  view.Prompt.PromptDate,
			"has_answered": view.Answer != nil,
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

	view, isEdit, err := s.store.submitDailyPromptAnswer(
		userID,
		promptID,
		answerText,
		time.Now().UTC(),
	)
	if err != nil {
		errMsg := strings.ToLower(err.Error())
		if strings.Contains(errMsg, "edit window expired") {
			writeError(w, http.StatusConflict, err)
			return
		}
		writeError(w, http.StatusBadRequest, err)
		return
	}

	s.store.recordActivity(activityEvent{
		UserID:   userID,
		Actor:    userID,
		Action:   "daily_prompt_answer_submitted",
		Status:   "success",
		Resource: "/engagement/daily-prompt/" + userID + "/answer",
		Details: map[string]any{
			"user_id":             userID,
			"prompt_id":           view.Prompt.ID,
			"prompt_date":         view.Prompt.PromptDate,
			"is_edit":             isEdit,
			"current_streak_days": view.Streak.CurrentDays,
			"participants_today":  view.Spark.ParticipantsToday,
		},
	})

	if view.Streak.MilestoneReached > 0 {
		s.store.recordActivity(activityEvent{
			UserID:   userID,
			Actor:    userID,
			Action:   "daily_prompt_streak_milestone",
			Status:   "success",
			Resource: "/engagement/daily-prompt/" + userID + "/answer",
			Details: map[string]any{
				"user_id":        userID,
				"streak_days":    view.Streak.CurrentDays,
				"milestone":      view.Streak.MilestoneReached,
				"prompt_date":    view.Prompt.PromptDate,
				"next_milestone": view.Streak.NextMilestone,
			},
		})
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

	page, err := s.store.listDailyPromptResponders(userID, time.Now().UTC(), limit, offset)
	if err != nil {
		writeError(w, http.StatusBadRequest, err)
		return
	}

	s.store.recordActivity(activityEvent{
		UserID:   userID,
		Actor:    userID,
		Action:   "daily_prompt_responders_listed",
		Status:   "success",
		Resource: "/engagement/daily-prompt/" + userID + "/responders",
		Details: map[string]any{
			"user_id":       userID,
			"prompt_id":     page.PromptID,
			"prompt_date":   page.PromptDate,
			"limit":         page.Limit,
			"offset":        page.Offset,
			"returned":      len(page.Responders),
			"total_matches": page.Total,
		},
	})

	writeJSON(w, http.StatusOK, map[string]any{
		"responders": page.Responders,
		"pagination": map[string]any{
			"prompt_id":     page.PromptID,
			"prompt_date":   page.PromptDate,
			"limit":         page.Limit,
			"offset":        page.Offset,
			"next_offset":   page.NextOffset,
			"has_more":      page.HasMore,
			"total_matches": page.Total,
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

	nudge, err := s.store.sendMatchNudge(matchID, userID, counterpartyUserID, nudgeType, time.Now().UTC())
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

	s.store.recordActivity(activityEvent{
		UserID:   nudge.UserID,
		Actor:    "system",
		Action:   "match_nudge_sent",
		Status:   "success",
		Resource: "/engagement/match-nudges/send",
		Details: map[string]any{
			"match_id":   nudge.MatchID,
			"user_id":    nudge.UserID,
			"nudge_type": nudge.NudgeType,
			"nudge_id":   nudge.ID,
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
	nudge, err := s.store.markMatchNudgeClicked(nudgeID, userID, time.Now().UTC())
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

	s.store.recordActivity(activityEvent{
		UserID:   nudge.UserID,
		Actor:    nudge.UserID,
		Action:   "match_nudge_clicked",
		Status:   "success",
		Resource: "/engagement/match-nudges/" + nudgeID + "/click",
		Details: map[string]any{
			"match_id":   nudge.MatchID,
			"user_id":    nudge.UserID,
			"nudge_type": nudge.NudgeType,
			"nudge_id":   nudge.ID,
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
	resumed, err := s.store.markConversationResumed(matchID, userID, triggerNudgeID, time.Now().UTC())
	if err != nil {
		errMsg := strings.ToLower(err.Error())
		if strings.Contains(errMsg, "invalid") {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		writeError(w, http.StatusBadRequest, err)
		return
	}

	s.store.recordActivity(activityEvent{
		UserID:   resumed.UserID,
		Actor:    resumed.UserID,
		Action:   "conversation_resumed",
		Status:   "success",
		Resource: "/engagement/matches/" + matchID + "/resume",
		Details: map[string]any{
			"match_id":         resumed.MatchID,
			"user_id":          resumed.UserID,
			"trigger_nudge_id": resumed.TriggerNudgeID,
		},
	})

	writeJSON(w, http.StatusOK, map[string]any{
		"conversation": resumed,
	})
}

func (s *Server) getCircleChallenge(w http.ResponseWriter, r *http.Request) {
	circleID := strings.TrimSpace(chi.URLParam(r, "circleID"))
	if circleID == "" {
		writeError(w, http.StatusBadRequest, errors.New("circle id is required"))
		return
	}

	userID := strings.TrimSpace(r.URL.Query().Get("user_id"))
	view, err := s.store.getCircleChallengeView(circleID, userID, time.Now().UTC())
	if err != nil {
		if strings.Contains(strings.ToLower(err.Error()), "not found") {
			writeError(w, http.StatusNotFound, err)
			return
		}
		writeError(w, http.StatusBadRequest, err)
		return
	}

	s.store.recordActivity(activityEvent{
		UserID:   userID,
		Actor:    userID,
		Action:   "circle_challenge_viewed",
		Status:   "success",
		Resource: "/engagement/circles/" + circleID + "/challenge",
		Details: map[string]any{
			"circle_id":    view.CircleID,
			"user_id":      userID,
			"challenge_id": view.Challenge.ID,
		},
	})

	writeJSON(w, http.StatusOK, map[string]any{
		"circle_challenge": view,
	})
}

func (s *Server) joinCircle(w http.ResponseWriter, r *http.Request) {
	circleID := strings.TrimSpace(chi.URLParam(r, "circleID"))
	if circleID == "" {
		writeError(w, http.StatusBadRequest, errors.New("circle id is required"))
		return
	}

	payload, ok := readJSON(w, r)
	if !ok {
		return
	}

	userID := strings.TrimSpace(toString(payload["user_id"]))
	membership, err := s.store.joinCircle(circleID, userID, time.Now().UTC())
	if err != nil {
		if strings.Contains(strings.ToLower(err.Error()), "not found") {
			writeError(w, http.StatusNotFound, err)
			return
		}
		writeError(w, http.StatusBadRequest, err)
		return
	}

	s.store.recordActivity(activityEvent{
		UserID:   userID,
		Actor:    userID,
		Action:   "circle_joined",
		Status:   "success",
		Resource: "/engagement/circles/" + circleID + "/join",
		Details: map[string]any{
			"circle_id": membership.CircleID,
			"user_id":   membership.UserID,
			"joined_at": membership.JoinedAt,
		},
	})

	writeJSON(w, http.StatusOK, map[string]any{
		"membership": membership,
	})
}

func (s *Server) submitCircleChallenge(w http.ResponseWriter, r *http.Request) {
	circleID := strings.TrimSpace(chi.URLParam(r, "circleID"))
	if circleID == "" {
		writeError(w, http.StatusBadRequest, errors.New("circle id is required"))
		return
	}

	payload, ok := readJSON(w, r)
	if !ok {
		return
	}

	challengeID := strings.TrimSpace(toString(payload["challenge_id"]))
	userID := strings.TrimSpace(toString(payload["user_id"]))
	entryText := strings.TrimSpace(toString(payload["entry_text"]))
	imageURL := strings.TrimSpace(toString(payload["image_url"]))

	view, entry, err := s.store.submitCircleChallengeEntry(
		circleID,
		challengeID,
		userID,
		entryText,
		imageURL,
		time.Now().UTC(),
	)
	if err != nil {
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

	s.store.recordActivity(activityEvent{
		UserID:   userID,
		Actor:    userID,
		Action:   "circle_challenge_submitted",
		Status:   "success",
		Resource: "/engagement/circles/" + circleID + "/challenge/entries",
		Details: map[string]any{
			"circle_id":           view.CircleID,
			"user_id":             userID,
			"challenge_id":        view.Challenge.ID,
			"challenge_entry_id":  entry.ID,
			"participation_count": view.ParticipationCount,
		},
	})

	writeJSON(w, http.StatusOK, map[string]any{
		"circle_challenge": view,
		"entry":            entry,
	})
}

func (s *Server) listVoiceIcebreakerPrompts(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]any{
		"prompts": s.store.listVoiceIcebreakerPrompts(),
	})
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

	item, err := s.store.startVoiceIcebreaker(matchID, senderUserID, receiverUserID, promptID, time.Now().UTC())
	if err != nil {
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

	s.store.recordActivity(activityEvent{
		UserID:   item.SenderUserID,
		Actor:    item.SenderUserID,
		Action:   "voice_icebreaker_started",
		Status:   "success",
		Resource: "/engagement/voice-icebreakers/start",
		Details: map[string]any{
			"match_id":  item.MatchID,
			"user_id":   item.SenderUserID,
			"prompt_id": item.PromptID,
		},
	})

	writeJSON(w, http.StatusOK, map[string]any{
		"voice_icebreaker": item,
	})
}

func (s *Server) sendVoiceIcebreaker(w http.ResponseWriter, r *http.Request) {
	icebreakerID := strings.TrimSpace(chi.URLParam(r, "icebreakerID"))
	if icebreakerID == "" {
		writeError(w, http.StatusBadRequest, errors.New("icebreaker id is required"))
		return
	}

	payload, ok := readJSON(w, r)
	if !ok {
		return
	}

	senderUserID := strings.TrimSpace(toString(payload["sender_user_id"]))
	transcript := strings.TrimSpace(toString(payload["transcript"]))
	durationSeconds, hasDuration := toInt(payload["duration_seconds"])
	if !hasDuration {
		writeError(w, http.StatusBadRequest, errors.New("duration_seconds is required"))
		return
	}

	item, err := s.store.sendVoiceIcebreaker(icebreakerID, senderUserID, transcript, durationSeconds, time.Now().UTC())
	if err != nil {
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

	s.store.recordActivity(activityEvent{
		UserID:   item.SenderUserID,
		Actor:    item.SenderUserID,
		Action:   "voice_icebreaker_sent",
		Status:   "success",
		Resource: "/engagement/voice-icebreakers/" + icebreakerID + "/send",
		Details: map[string]any{
			"match_id":         item.MatchID,
			"user_id":          item.SenderUserID,
			"prompt_id":        item.PromptID,
			"duration_seconds": item.DurationSeconds,
		},
	})

	writeJSON(w, http.StatusOK, map[string]any{
		"voice_icebreaker": item,
	})
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
	item, err := s.store.markVoiceIcebreakerPlayed(icebreakerID, userID, time.Now().UTC())
	if err != nil {
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

	s.store.recordActivity(activityEvent{
		UserID:   userID,
		Actor:    userID,
		Action:   "voice_icebreaker_played",
		Status:   "success",
		Resource: "/engagement/voice-icebreakers/" + icebreakerID + "/play",
		Details: map[string]any{
			"match_id":      item.MatchID,
			"user_id":       userID,
			"icebreaker_id": item.ID,
		},
	})

	writeJSON(w, http.StatusOK, map[string]any{
		"voice_icebreaker": item,
	})
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

	poll, err := s.store.createGroupCoffeePoll(creatorUserID, participantUserIDs, options, deadlineAt, time.Now().UTC())
	if err != nil {
		writeError(w, http.StatusBadRequest, err)
		return
	}

	s.store.recordActivity(activityEvent{
		UserID:   creatorUserID,
		Actor:    creatorUserID,
		Action:   "intro_event_created",
		Status:   "success",
		Resource: "/engagement/group-coffee-polls",
		Details: map[string]any{
			"intro_event_id": poll.ID,
			"user_id":        creatorUserID,
			"event_type":     "group_coffee_poll",
			"participants":   len(poll.ParticipantUserIDs),
		},
	})

	s.store.recordActivity(activityEvent{
		UserID:   creatorUserID,
		Actor:    creatorUserID,
		Action:   "group_poll_created",
		Status:   "success",
		Resource: "/engagement/group-coffee-polls",
		Details: map[string]any{
			"poll_id":      poll.ID,
			"user_id":      creatorUserID,
			"participants": len(poll.ParticipantUserIDs),
		},
	})

	writeJSON(w, http.StatusOK, map[string]any{"poll": poll})
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

	polls := s.store.listGroupCoffeePolls(userID, status, limit)
	writeJSON(w, http.StatusOK, map[string]any{"polls": polls})
}

func (s *Server) getGroupCoffeePoll(w http.ResponseWriter, r *http.Request) {
	pollID := strings.TrimSpace(chi.URLParam(r, "pollID"))
	if pollID == "" {
		writeError(w, http.StatusBadRequest, errors.New("poll id is required"))
		return
	}

	poll, ok := s.store.getGroupCoffeePoll(pollID)
	if !ok {
		writeError(w, http.StatusNotFound, errors.New("group coffee poll not found"))
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{"poll": poll})
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

	poll, err := s.store.voteGroupCoffeePoll(pollID, userID, optionID)
	if err != nil {
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

	s.store.recordActivity(activityEvent{
		UserID:   userID,
		Actor:    userID,
		Action:   "intro_event_voted",
		Status:   "success",
		Resource: "/engagement/group-coffee-polls/" + pollID + "/votes",
		Details: map[string]any{
			"intro_event_id": poll.ID,
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
			"poll_id":   poll.ID,
			"user_id":   userID,
			"option_id": optionID,
		},
	})

	writeJSON(w, http.StatusOK, map[string]any{"poll": poll})
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

	poll, selectedOption, err := s.store.finalizeGroupCoffeePoll(pollID, userID, time.Now().UTC())
	if err != nil {
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

	s.store.recordActivity(activityEvent{
		UserID:   userID,
		Actor:    userID,
		Action:   "intro_event_finalized",
		Status:   "success",
		Resource: "/engagement/group-coffee-polls/" + pollID + "/finalize",
		Details: map[string]any{
			"intro_event_id":        poll.ID,
			"user_id":               userID,
			"event_type":            "group_coffee_poll",
			"selected_option_id":    selectedOption.ID,
			"selected_day":          selectedOption.Day,
			"selected_time_window":  selectedOption.TimeWindow,
			"selected_neighborhood": selectedOption.Neighborhood,
		},
	})

	s.store.recordActivity(activityEvent{
		UserID:   userID,
		Actor:    userID,
		Action:   "group_poll_finalized",
		Status:   "success",
		Resource: "/engagement/group-coffee-polls/" + pollID + "/finalize",
		Details: map[string]any{
			"poll_id":               poll.ID,
			"user_id":               userID,
			"selected_option_id":    selectedOption.ID,
			"selected_day":          selectedOption.Day,
			"selected_time_window":  selectedOption.TimeWindow,
			"selected_neighborhood": selectedOption.Neighborhood,
		},
	})

	writeJSON(w, http.StatusOK, map[string]any{
		"poll":            poll,
		"selected_option": selectedOption,
	})
}

func (s *Server) startCall(w http.ResponseWriter, r *http.Request) {
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}

	matchID := strings.TrimSpace(toString(payload["match_id"]))
	initiatorID := strings.TrimSpace(toString(payload["initiator_user_id"]))
	recipientID := strings.TrimSpace(toString(payload["recipient_user_id"]))

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
		writeError(w, http.StatusBadGateway, err)
		return
	}

	resp, ok := respAny.(map[string]any)
	if !ok {
		writeError(w, http.StatusBadGateway, errors.New("unexpected start call response payload"))
		return
	}
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

	var photoURL string
	contentType := strings.ToLower(strings.TrimSpace(r.Header.Get("Content-Type")))
	if strings.HasPrefix(contentType, "multipart/form-data") {
		uploadedURL, err := s.persistUploadedPhoto(r, userID)
		if err != nil {
			writeError(w, http.StatusBadRequest, err)
			return
		}
		photoURL = uploadedURL
	} else {
		payload, ok := readJSON(w, r)
		if !ok {
			return
		}
		photoURL = strings.TrimSpace(toString(payload["photo_url"]))
	}

	if photoURL == "" {
		writeError(w, http.StatusBadRequest, errors.New("photo_url is required"))
		return
	}

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		profileapp.AddProfilePhotoCommandName,
		profileapp.AddProfilePhotoCommand{UserID: userID, PhotoURL: photoURL},
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

	rootDir := filepath.Clean(strings.TrimSpace(s.cfg.MediaUploadsDir))
	if rootDir == "" {
		rootDir = filepath.Clean(".run/uploads/profile_photos")
	}

	targetPath := filepath.Clean(filepath.Join(rootDir, filepath.FromSlash(relativePath)))
	rootPrefix := rootDir + string(os.PathSeparator)
	if targetPath != rootDir && !strings.HasPrefix(targetPath, rootPrefix) {
		writeError(w, http.StatusForbidden, errors.New("forbidden media path"))
		return
	}

	if _, err := os.Stat(targetPath); err != nil {
		if errors.Is(err, os.ErrNotExist) {
			writeError(w, http.StatusNotFound, errors.New("media not found"))
			return
		}
		writeError(w, http.StatusInternalServerError, err)
		return
	}

	http.ServeFile(w, r, targetPath)
}

func (s *Server) persistUploadedPhoto(r *http.Request, userID string) (string, error) {
	if err := r.ParseMultipartForm(12 << 20); err != nil {
		return "", fmt.Errorf("invalid multipart payload: %w", err)
	}

	file, header, err := r.FormFile("image")
	if err != nil {
		file, header, err = r.FormFile("file")
		if err != nil {
			return "", errors.New("image file is required")
		}
	}
	defer file.Close()

	ext := normalizeImageExtension(header.Filename)
	filename := fmt.Sprintf("%d%s", time.Now().UnixNano(), ext)
	safeUserID := sanitizePathSegment(userID)

	rootDir := filepath.Clean(strings.TrimSpace(s.cfg.MediaUploadsDir))
	if rootDir == "" {
		rootDir = filepath.Clean(".run/uploads/profile_photos")
	}
	userDir := filepath.Join(rootDir, safeUserID)
	if err := os.MkdirAll(userDir, 0o755); err != nil {
		return "", fmt.Errorf("failed to create upload directory: %w", err)
	}

	targetPath := filepath.Clean(filepath.Join(userDir, filename))
	userPrefix := filepath.Clean(userDir) + string(os.PathSeparator)
	if !strings.HasPrefix(targetPath, userPrefix) {
		return "", errors.New("invalid upload target")
	}

	output, err := os.Create(targetPath)
	if err != nil {
		return "", fmt.Errorf("failed to create upload file: %w", err)
	}
	defer output.Close()

	if _, err := io.Copy(output, io.LimitReader(file, 10<<20)); err != nil {
		return "", fmt.Errorf("failed to persist image: %w", err)
	}

	baseURL := s.resolveMediaPublicBaseURL(r)

	relativeURL := fmt.Sprintf("%s/media/%s/%s", s.cfg.APIPrefix, url.PathEscape(safeUserID), url.PathEscape(filename))
	return baseURL + relativeURL, nil
}

func (s *Server) resolveMediaPublicBaseURL(r *http.Request) string {
	raw := strings.TrimSpace(s.cfg.MediaPublicBaseURL)
	normalized := strings.TrimRight(raw, "/")
	if normalized != "" && !strings.EqualFold(normalized, "auto") {
		return normalized
	}

	return requestBaseURL(r, defaultGatewayHost(s.cfg.APIGatewayAddr))
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

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

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
	writeJSON(w, http.StatusOK, resp)
}

func (s *Server) reorderProfilePhotos(w http.ResponseWriter, r *http.Request) {
	userID := strings.TrimSpace(chi.URLParam(r, "userID"))
	if userID == "" {
		writeError(w, http.StatusBadRequest, errors.New("user id is required"))
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

	ctx, cancel := s.withRequestTimeout(r.Context())
	defer cancel()

	respAny, err := s.mediator.Send(
		ctx,
		verificationapp.SubmitVerificationCommandName,
		verificationapp.SubmitVerificationCommand{UserID: userID},
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
		writeError(w, http.StatusBadGateway, errors.New("unexpected submit verification response payload"))
		return
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
