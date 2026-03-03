package mobile

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"
)

func TestServer_TrustBadgesAssignmentAndHistory(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	userID := "trust-user-1"
	seedTrustEligibleUser(server, userID)

	req := httptest.NewRequest(http.MethodGet, "/v1/users/"+userID+"/trust-badges", nil)
	rec := httptest.NewRecorder()
	server.Handler().ServeHTTP(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("trust badges code = %d body=%s", rec.Code, rec.Body.String())
	}

	payload := decodeJSONMap(t, rec.Body.Bytes())
	badges, ok := payload["badges"].([]any)
	if !ok || len(badges) == 0 {
		t.Fatalf("expected badge list in payload")
	}

	if status := badgeStatusByCode(t, badges, trustBadgePromptCompleter); status != "active" {
		t.Fatalf("expected prompt completer active, got %q", status)
	}
	if status := badgeStatusByCode(t, badges, trustBadgeRespectfulCommunicator); status != "active" {
		t.Fatalf("expected respectful communicator active, got %q", status)
	}
	if status := badgeStatusByCode(t, badges, trustBadgeConsistentProfile); status != "active" {
		t.Fatalf("expected consistent profile active, got %q", status)
	}
	if status := badgeStatusByCode(t, badges, trustBadgeVerifiedActive); status != "active" {
		t.Fatalf("expected verified active badge active, got %q", status)
	}

	historyReq := httptest.NewRequest(
		http.MethodGet,
		"/v1/users/"+userID+"/trust-badges/history?limit=20",
		nil,
	)
	historyRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(historyRec, historyReq)
	if historyRec.Code != http.StatusOK {
		t.Fatalf("trust badge history code = %d body=%s", historyRec.Code, historyRec.Body.String())
	}

	historyPayload := decodeJSONMap(t, historyRec.Body.Bytes())
	history, ok := historyPayload["history"].([]any)
	if !ok || len(history) == 0 {
		t.Fatalf("expected non-empty trust badge history")
	}

	hasAwarded := false
	for _, entry := range history {
		item := toMap(t, entry)
		if stringValue(item["action"]) == "awarded" {
			hasAwarded = true
			break
		}
	}
	if !hasAwarded {
		t.Fatalf("expected at least one awarded history event")
	}
}

func TestServer_TrustBadgesRevokedOnUnsafeBehavior(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	userID := "trust-user-unsafe"
	seedTrustEligibleUser(server, userID)

	firstReq := httptest.NewRequest(http.MethodGet, "/v1/users/"+userID+"/trust-badges", nil)
	firstRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(firstRec, firstReq)
	if firstRec.Code != http.StatusOK {
		t.Fatalf("initial trust badges code = %d body=%s", firstRec.Code, firstRec.Body.String())
	}

	server.store.mu.Lock()
	server.store.reports = append(server.store.reports, moderationReport{
		ID:             "rep-unsafe-1",
		ReporterUserID: "moderator-1",
		ReportedUserID: userID,
		Reason:         "harassment",
		Status:         "resolved",
		Action:         "suspend_for_abuse",
		ReviewedBy:     "admin-1",
		ReviewedAt:     time.Now().UTC().Format(time.RFC3339),
		CreatedAt:      time.Now().UTC().Format(time.RFC3339),
	})
	server.store.mu.Unlock()

	req := httptest.NewRequest(http.MethodGet, "/v1/users/"+userID+"/trust-badges", nil)
	rec := httptest.NewRecorder()
	server.Handler().ServeHTTP(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("recompute trust badges code = %d body=%s", rec.Code, rec.Body.String())
	}

	payload := decodeJSONMap(t, rec.Body.Bytes())
	badges, ok := payload["badges"].([]any)
	if !ok || len(badges) == 0 {
		t.Fatalf("expected badges list")
	}

	for _, code := range []string{
		trustBadgePromptCompleter,
		trustBadgeRespectfulCommunicator,
		trustBadgeConsistentProfile,
		trustBadgeVerifiedActive,
	} {
		if status := badgeStatusByCode(t, badges, code); status != "revoked" {
			t.Fatalf("expected %s revoked, got %q", code, status)
		}
	}

	historyReq := httptest.NewRequest(http.MethodGet, "/v1/users/"+userID+"/trust-badges/history", nil)
	historyRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(historyRec, historyReq)
	if historyRec.Code != http.StatusOK {
		t.Fatalf("history code = %d body=%s", historyRec.Code, historyRec.Body.String())
	}

	historyPayload := decodeJSONMap(t, historyRec.Body.Bytes())
	history, ok := historyPayload["history"].([]any)
	if !ok || len(history) == 0 {
		t.Fatalf("expected history entries")
	}

	hasRevoked := false
	for _, entry := range history {
		item := toMap(t, entry)
		if stringValue(item["action"]) == "revoked" && strings.Contains(stringValue(item["reason"]), "unsafe") {
			hasRevoked = true
			break
		}
	}
	if !hasRevoked {
		t.Fatalf("expected revoked history entry with unsafe reason")
	}
}

func seedTrustEligibleUser(server *Server, userID string) {
	now := time.Now().UTC().Format(time.RFC3339)

	server.store.mu.Lock()
	defer server.store.mu.Unlock()

	server.store.profiles[userID] = profileDraft{
		UserID:            userID,
		Name:              "Trust User",
		DateOfBirth:       "1997-01-01",
		Bio:               "Intentional and respectful communicator.",
		Gender:            "woman",
		SeekingGenders:    []string{"man"},
		MinAgeYears:       26,
		MaxAgeYears:       35,
		MaxDistanceKm:     25,
		ProfileCompletion: 100,
		Photos: []profilePhoto{{
			ID:       "photo-1",
			PhotoURL: "https://example.com/photo.jpg",
			Ordering: 1,
		}},
	}
	server.store.verification[userID] = verificationState{
		UserID:     userID,
		Status:     "approved",
		ReviewedAt: now,
	}
	server.store.questWorkflows["match-trust-quest"] = questSubmissionWorkflow{
		MatchID:         "match-trust-quest",
		SubmitterUserID: userID,
		Status:          questWorkflowStatusApproved,
		SubmittedAt:     now,
		ReviewedAt:      now,
	}
	server.store.activitySessions["activity-trust-1"] = activitySession{
		ID:              "activity-trust-1",
		MatchID:         "match-trust-activity",
		ActivityType:    "co_op_prompt",
		Status:          activitySessionStatusCompleted,
		InitiatorUserID: userID,
		ParticipantIDs:  []string{userID, "partner-1"},
		ResponsesByUser: map[string][]string{
			userID: []string{"this_or_that:Coffee walk"},
		},
		StartedAt:   now,
		ExpiresAt:   now,
		CompletedAt: now,
	}
	server.store.matchGestures["match-trust-gesture"] = []matchGesture{
		{
			ID:                 "gesture-trust-1",
			MatchID:            "match-trust-gesture",
			SenderUserID:       userID,
			ReceiverUserID:     "partner-1",
			GestureType:        "thoughtful_opener",
			ContentText:        "I value consistency and thoughtful communication in relationships.",
			Tone:               "warm",
			Status:             "appreciated",
			EffortScore:        92,
			MinimumQualityPass: true,
			OriginalityPass:    true,
			ProfanityFlagged:   false,
			SafetyFlagged:      false,
			CreatedAt:          now,
			UpdatedAt:          now,
		},
	}

	server.store.activities = append(server.store.activities,
		activityEvent{UserID: userID, Actor: userID, Action: "gesture.create", Status: "success", Resource: "/matches/match-trust-gesture/gestures", CreatedAt: now},
		activityEvent{UserID: userID, Actor: userID, Action: "gesture.decision", Status: "success", Resource: "/matches/match-trust-gesture/gestures/gesture-trust-1/decision", CreatedAt: now},
		activityEvent{UserID: userID, Actor: userID, Action: "activity.session.submit", Status: "success", Resource: "/activities/sessions/activity-trust-1/submit", CreatedAt: now},
	)
}

func badgeStatusByCode(t *testing.T, badges []any, code string) string {
	t.Helper()
	for _, item := range badges {
		badge := toMap(t, item)
		if stringValue(badge["badge_code"]) == code {
			return stringValue(badge["status"])
		}
	}
	return ""
}
