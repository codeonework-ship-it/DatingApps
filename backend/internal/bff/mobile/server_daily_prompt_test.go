package mobile

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"
)

func TestServer_DailyPromptLifecycleAndMilestone(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	userID := "user-daily-1"
	yesterday := time.Now().UTC().AddDate(0, 0, -1).Format("2006-01-02")

	server.store.mu.Lock()
	server.store.dailyPromptStreaks[userID] = dailyPromptStreak{
		UserID:           userID,
		CurrentDays:      2,
		LongestDays:      2,
		LastAnsweredDate: yesterday,
	}
	server.store.mu.Unlock()

	getReq := httptest.NewRequest(http.MethodGet, "/v1/engagement/daily-prompt/"+userID, nil)
	getRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(getRec, getReq)
	if getRec.Code != http.StatusOK {
		t.Fatalf("get daily prompt code=%d body=%s", getRec.Code, getRec.Body.String())
	}

	getPayload := decodeJSONMap(t, getRec.Body.Bytes())
	view := toMap(t, getPayload["daily_prompt"])
	prompt := toMap(t, view["prompt"])
	promptID := stringValue(prompt["id"])
	promptDate := stringValue(prompt["prompt_date"])
	if promptID == "" || promptDate == "" {
		t.Fatalf("expected prompt id/date in daily prompt response")
	}

	server.store.mu.Lock()
	server.store.dailyPromptAnswers["user-daily-other"] = map[string]dailyPromptAnswer{
		promptDate: {
			UserID:          "user-daily-other",
			PromptID:        promptID,
			PromptDate:      promptDate,
			AnswerText:      "Consistency",
			AnsweredAt:      time.Now().UTC().Format(time.RFC3339),
			UpdatedAt:       time.Now().UTC().Format(time.RFC3339),
			EditWindowUntil: time.Now().UTC().Add(10 * time.Minute).Format(time.RFC3339),
			Normalized:      normalizeDailyPromptAnswer("Consistency"),
		},
	}
	server.store.mu.Unlock()

	submitBody := `{
		"prompt_id": "` + promptID + `",
		"answer_text": "Consistency"
	}`
	submitReq := httptest.NewRequest(
		http.MethodPost,
		"/v1/engagement/daily-prompt/"+userID+"/answer",
		strings.NewReader(submitBody),
	)
	submitReq.Header.Set("Content-Type", "application/json")
	submitRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(submitRec, submitReq)
	if submitRec.Code != http.StatusOK {
		t.Fatalf("submit daily prompt code=%d body=%s", submitRec.Code, submitRec.Body.String())
	}

	submitPayload := decodeJSONMap(t, submitRec.Body.Bytes())
	submitView := toMap(t, submitPayload["daily_prompt"])
	streak := toMap(t, submitView["streak"])
	spark := toMap(t, submitView["spark"])
	if got := int(streak["current_days"].(float64)); got != 3 {
		t.Fatalf("expected streak current_days=3, got %d", got)
	}
	if got := int(streak["milestone_reached"].(float64)); got != 3 {
		t.Fatalf("expected milestone_reached=3, got %d", got)
	}
	if got := int(spark["similar_answer_count"].(float64)); got != 1 {
		t.Fatalf("expected similar_answer_count=1, got %d", got)
	}

	server.store.mu.RLock()
	activities := server.store.listActivities(30)
	server.store.mu.RUnlock()
	assertActionSeen(t, activities, "daily_prompt_viewed")
	assertActionSeen(t, activities, "daily_prompt_answer_submitted")
	assertActionSeen(t, activities, "daily_prompt_streak_milestone")
}

func TestServer_DailyPromptEditWindow(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	userID := "user-daily-2"
	getReq := httptest.NewRequest(http.MethodGet, "/v1/engagement/daily-prompt/"+userID, nil)
	getRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(getRec, getReq)
	if getRec.Code != http.StatusOK {
		t.Fatalf("get daily prompt code=%d body=%s", getRec.Code, getRec.Body.String())
	}
	getPayload := decodeJSONMap(t, getRec.Body.Bytes())
	view := toMap(t, getPayload["daily_prompt"])
	prompt := toMap(t, view["prompt"])
	promptID := stringValue(prompt["id"])
	promptDate := stringValue(prompt["prompt_date"])

	firstSubmitBody := `{
		"prompt_id": "` + promptID + `",
		"answer_text": "Shared values and consistency"
	}`
	firstSubmitReq := httptest.NewRequest(
		http.MethodPost,
		"/v1/engagement/daily-prompt/"+userID+"/answer",
		strings.NewReader(firstSubmitBody),
	)
	firstSubmitReq.Header.Set("Content-Type", "application/json")
	firstSubmitRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(firstSubmitRec, firstSubmitReq)
	if firstSubmitRec.Code != http.StatusOK {
		t.Fatalf("first submit code=%d body=%s", firstSubmitRec.Code, firstSubmitRec.Body.String())
	}

	secondSubmitBody := `{
		"prompt_id": "` + promptID + `",
		"answer_text": "Consistency with calm communication"
	}`
	secondSubmitReq := httptest.NewRequest(
		http.MethodPost,
		"/v1/engagement/daily-prompt/"+userID+"/answer",
		strings.NewReader(secondSubmitBody),
	)
	secondSubmitReq.Header.Set("Content-Type", "application/json")
	secondSubmitRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(secondSubmitRec, secondSubmitReq)
	if secondSubmitRec.Code != http.StatusOK {
		t.Fatalf("second submit code=%d body=%s", secondSubmitRec.Code, secondSubmitRec.Body.String())
	}
	secondSubmitPayload := decodeJSONMap(t, secondSubmitRec.Body.Bytes())
	secondView := toMap(t, secondSubmitPayload["daily_prompt"])
	answer := toMap(t, secondView["answer"])
	if got := boolValue(answer["is_edited"]); !got {
		t.Fatalf("expected is_edited=true after second submit")
	}

	server.store.mu.Lock()
	existing := server.store.dailyPromptAnswers[userID][promptDate]
	existing.EditWindowUntil = time.Now().UTC().Add(-1 * time.Minute).Format(time.RFC3339)
	server.store.dailyPromptAnswers[userID][promptDate] = existing
	server.store.mu.Unlock()

	thirdSubmitReq := httptest.NewRequest(
		http.MethodPost,
		"/v1/engagement/daily-prompt/"+userID+"/answer",
		strings.NewReader(secondSubmitBody),
	)
	thirdSubmitReq.Header.Set("Content-Type", "application/json")
	thirdSubmitRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(thirdSubmitRec, thirdSubmitReq)
	if thirdSubmitRec.Code != http.StatusConflict {
		t.Fatalf("expected 409 after edit window expiry, got %d body=%s", thirdSubmitRec.Code, thirdSubmitRec.Body.String())
	}
}

func TestServer_DailyPromptRespondersPaginationAndSafety(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	userID := "user-daily-responders-main"
	getReq := httptest.NewRequest(http.MethodGet, "/v1/engagement/daily-prompt/"+userID, nil)
	getRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(getRec, getReq)
	if getRec.Code != http.StatusOK {
		t.Fatalf("get daily prompt code=%d body=%s", getRec.Code, getRec.Body.String())
	}
	getPayload := decodeJSONMap(t, getRec.Body.Bytes())
	view := toMap(t, getPayload["daily_prompt"])
	prompt := toMap(t, view["prompt"])
	promptID := stringValue(prompt["id"])
	promptDate := stringValue(prompt["prompt_date"])

	submitBody := `{"prompt_id":"` + promptID + `","answer_text":"Consistency"}`
	submitReq := httptest.NewRequest(http.MethodPost, "/v1/engagement/daily-prompt/"+userID+"/answer", strings.NewReader(submitBody))
	submitReq.Header.Set("Content-Type", "application/json")
	submitRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(submitRec, submitReq)
	if submitRec.Code != http.StatusOK {
		t.Fatalf("submit daily prompt code=%d body=%s", submitRec.Code, submitRec.Body.String())
	}

	now := time.Now().UTC()
	server.store.mu.Lock()
	server.store.profiles["user-daily-responders-a"] = profileDraft{UserID: "user-daily-responders-a", Name: "Ava", Photos: []profilePhoto{{PhotoURL: "https://example.com/a.jpg", Ordering: 1}}}
	server.store.profiles["user-daily-responders-b"] = profileDraft{UserID: "user-daily-responders-b", Name: "Ben", Photos: []profilePhoto{{PhotoURL: "https://example.com/b.jpg", Ordering: 1}}}
	server.store.profiles["user-daily-responders-c"] = profileDraft{UserID: "user-daily-responders-c", Name: "Cara", Photos: []profilePhoto{{PhotoURL: "https://example.com/c.jpg", Ordering: 1}}}
	server.store.dailyPromptAnswers["user-daily-responders-a"] = map[string]dailyPromptAnswer{
		promptDate: {
			UserID:          "user-daily-responders-a",
			PromptID:        promptID,
			PromptDate:      promptDate,
			AnswerText:      "Consistency",
			AnsweredAt:      now.Add(-2 * time.Minute).Format(time.RFC3339),
			UpdatedAt:       now.Add(-2 * time.Minute).Format(time.RFC3339),
			EditWindowUntil: now.Add(8 * time.Minute).Format(time.RFC3339),
			Normalized:      normalizeDailyPromptAnswer("Consistency"),
		},
	}
	server.store.dailyPromptAnswers["user-daily-responders-b"] = map[string]dailyPromptAnswer{
		promptDate: {
			UserID:          "user-daily-responders-b",
			PromptID:        promptID,
			PromptDate:      promptDate,
			AnswerText:      "Consistency",
			AnsweredAt:      now.Add(-1 * time.Minute).Format(time.RFC3339),
			UpdatedAt:       now.Add(-1 * time.Minute).Format(time.RFC3339),
			EditWindowUntil: now.Add(9 * time.Minute).Format(time.RFC3339),
			Normalized:      normalizeDailyPromptAnswer("Consistency"),
		},
	}
	server.store.dailyPromptAnswers["user-daily-responders-c"] = map[string]dailyPromptAnswer{
		promptDate: {
			UserID:          "user-daily-responders-c",
			PromptID:        promptID,
			PromptDate:      promptDate,
			AnswerText:      "Consistency",
			AnsweredAt:      now.Add(-30 * time.Second).Format(time.RFC3339),
			UpdatedAt:       now.Add(-30 * time.Second).Format(time.RFC3339),
			EditWindowUntil: now.Add(10 * time.Minute).Format(time.RFC3339),
			Normalized:      normalizeDailyPromptAnswer("Consistency"),
		},
	}
	server.store.dailyPromptAnswers["user-daily-responders-other"] = map[string]dailyPromptAnswer{
		promptDate: {
			UserID:          "user-daily-responders-other",
			PromptID:        promptID,
			PromptDate:      promptDate,
			AnswerText:      "Spontaneity",
			AnsweredAt:      now.Add(-45 * time.Second).Format(time.RFC3339),
			UpdatedAt:       now.Add(-45 * time.Second).Format(time.RFC3339),
			EditWindowUntil: now.Add(10 * time.Minute).Format(time.RFC3339),
			Normalized:      normalizeDailyPromptAnswer("Spontaneity"),
		},
	}
	server.store.mu.Unlock()

	server.store.blockUser(userID, "user-daily-responders-c")

	firstReq := httptest.NewRequest(http.MethodGet, "/v1/engagement/daily-prompt/"+userID+"/responders?limit=1&offset=0", nil)
	firstRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(firstRec, firstReq)
	if firstRec.Code != http.StatusOK {
		t.Fatalf("first responders page code=%d body=%s", firstRec.Code, firstRec.Body.String())
	}
	firstPayload := decodeJSONMap(t, firstRec.Body.Bytes())
	firstResponders := firstPayload["responders"].([]any)
	if len(firstResponders) != 1 {
		t.Fatalf("expected first page responders=1, got %d", len(firstResponders))
	}
	firstPagination := toMap(t, firstPayload["pagination"])
	if !boolValue(firstPagination["has_more"]) {
		t.Fatalf("expected has_more=true for first page")
	}
	if got := int(firstPagination["total_matches"].(float64)); got != 2 {
		t.Fatalf("expected total_matches=2, got %d", got)
	}
	if got := stringValue(toMap(t, firstResponders[0])["user_id"]); got != "user-daily-responders-b" {
		t.Fatalf("expected newest responder user-daily-responders-b, got %q", got)
	}

	secondReq := httptest.NewRequest(http.MethodGet, "/v1/engagement/daily-prompt/"+userID+"/responders?limit=1&offset=1", nil)
	secondRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(secondRec, secondReq)
	if secondRec.Code != http.StatusOK {
		t.Fatalf("second responders page code=%d body=%s", secondRec.Code, secondRec.Body.String())
	}
	secondPayload := decodeJSONMap(t, secondRec.Body.Bytes())
	secondResponders := secondPayload["responders"].([]any)
	if len(secondResponders) != 1 {
		t.Fatalf("expected second page responders=1, got %d", len(secondResponders))
	}
	secondPagination := toMap(t, secondPayload["pagination"])
	if boolValue(secondPagination["has_more"]) {
		t.Fatalf("expected has_more=false for second page")
	}
	if got := stringValue(toMap(t, secondResponders[0])["user_id"]); got != "user-daily-responders-a" {
		t.Fatalf("expected second responder user-daily-responders-a, got %q", got)
	}
}

func TestServer_DailyPromptRespondersInvalidPagination(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	userID := "user-daily-responders-invalid"

	badLimitReq := httptest.NewRequest(http.MethodGet, "/v1/engagement/daily-prompt/"+userID+"/responders?limit=bad", nil)
	badLimitRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(badLimitRec, badLimitReq)
	if badLimitRec.Code != http.StatusBadRequest {
		t.Fatalf("expected 400 for invalid limit, got %d body=%s", badLimitRec.Code, badLimitRec.Body.String())
	}

	badOffsetReq := httptest.NewRequest(http.MethodGet, "/v1/engagement/daily-prompt/"+userID+"/responders?offset=bad", nil)
	badOffsetRec := httptest.NewRecorder()
	server.Handler().ServeHTTP(badOffsetRec, badOffsetReq)
	if badOffsetRec.Code != http.StatusBadRequest {
		t.Fatalf("expected 400 for invalid offset, got %d body=%s", badOffsetRec.Code, badOffsetRec.Body.String())
	}
}

func assertActionSeen(t *testing.T, events []activityEvent, action string) {
	t.Helper()
	for _, item := range events {
		if strings.TrimSpace(item.Action) == action {
			return
		}
	}
	t.Fatalf("expected action %q in activity events", action)
}
