package mobile

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"
)

func TestServer_TrustFilterGetPatchPersistence(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	userID := "woman-user-1"

	getReq := httptest.NewRequest(http.MethodGet, "/v1/discovery/"+userID+"/filters/trust", nil)
	getRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(getRec, getReq)
	if getRec.Code != http.StatusOK {
		t.Fatalf("get trust filter code=%d body=%s", getRec.Code, getRec.Body.String())
	}
	getPayload := decodeJSONMap(t, getRec.Body.Bytes())
	initialFilter := toMap(t, getPayload["trust_filter"])
	if enabled, _ := initialFilter["enabled"].(bool); enabled {
		t.Fatalf("expected filter disabled by default")
	}

	patchBody := `{
		"enabled": true,
		"minimum_active_badges": 2,
		"required_badge_codes": ["verified_active", "respectful_communicator"]
	}`
	patchReq := httptest.NewRequest(
		http.MethodPatch,
		"/v1/discovery/"+userID+"/filters/trust",
		strings.NewReader(patchBody),
	)
	patchReq.Header.Set("Content-Type", "application/json")
	patchRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(patchRec, patchReq)
	if patchRec.Code != http.StatusOK {
		t.Fatalf("patch trust filter code=%d body=%s", patchRec.Code, patchRec.Body.String())
	}
	patchPayload := decodeJSONMap(t, patchRec.Body.Bytes())
	updatedFilter := toMap(t, patchPayload["trust_filter"])
	if enabled, _ := updatedFilter["enabled"].(bool); !enabled {
		t.Fatalf("expected filter enabled after patch")
	}
	if got := intValue(updatedFilter["minimum_active_badges"]); got != 2 {
		t.Fatalf("expected minimum_active_badges 2, got %d", got)
	}
	required, ok := updatedFilter["required_badge_codes"].([]any)
	if !ok || len(required) != 2 {
		t.Fatalf("expected two required badge codes")
	}
}

func TestServer_ApplyTrustFilterToRows(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	requester := "requester-woman"
	trustUser := "trusted-user"
	lowTrustUser := "low-trust-user"

	seedTrustEligibleUser(server, trustUser)
	seedLowTrustUser(server, lowTrustUser)

	_, err := server.store.upsertTrustFilterPreference(
		requester,
		true,
		2,
		[]string{trustBadgeRespectfulCommunicator},
	)
	if err != nil {
		t.Fatalf("upsert trust filter: %v", err)
	}

	rows := []any{
		map[string]any{"id": trustUser, "name": "Trusted"},
		map[string]any{"id": lowTrustUser, "name": "LowTrust"},
	}
	filtered, summary := server.applyTrustFilterToRows(rows, requester, "id")
	if len(filtered) != 1 {
		t.Fatalf("expected one filtered row, got %d", len(filtered))
	}
	first := toMap(t, filtered[0])
	if got := stringValue(first["id"]); got != trustUser {
		t.Fatalf("expected trusted user to remain, got %q", got)
	}
	if got := intValue(summary["filtered_out_count"]); got != 1 {
		t.Fatalf("expected filtered_out_count=1, got %d", got)
	}
}

func seedLowTrustUser(server *Server, userID string) {
	now := time.Now().UTC().Format(time.RFC3339)
	server.store.mu.Lock()
	defer server.store.mu.Unlock()

	server.store.profiles[userID] = profileDraft{
		UserID:            userID,
		Name:              "Low Trust User",
		DateOfBirth:       "1999-01-01",
		Gender:            "man",
		SeekingGenders:    []string{"woman"},
		MinAgeYears:       24,
		MaxAgeYears:       35,
		MaxDistanceKm:     25,
		Bio:               "...",
		ProfileCompletion: 40,
	}
	server.store.verification[userID] = verificationState{UserID: userID, Status: "pending", SubmittedAt: now}
	server.store.reports = append(server.store.reports, moderationReport{
		ID:             "rep-low-1",
		ReporterUserID: "moderator",
		ReportedUserID: userID,
		Reason:         "abuse",
		Status:         "resolved",
		Action:         "suspend_for_abuse",
		ReviewedBy:     "admin-1",
		ReviewedAt:     now,
		CreatedAt:      now,
	})
}

func intValue(value any) int {
	switch v := value.(type) {
	case int:
		return v
	case int32:
		return int(v)
	case int64:
		return int(v)
	case float32:
		return int(v)
	case float64:
		return int(v)
	default:
		return 0
	}
}
