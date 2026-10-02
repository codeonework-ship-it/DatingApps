package mobile

import (
	"errors"
	"fmt"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

// API-02: quest review business-rule violations are client errors with a
// clear message, never 502 "service temporarily unavailable".
func TestServer_QuestReviewRuleViolationsAreClientErrors(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	do := func(method, target, body string) *httptest.ResponseRecorder {
		t.Helper()
		req := httptest.NewRequest(method, target, strings.NewReader(body))
		req.Header.Set("Content-Type", "application/json")
		rec := httptest.NewRecorder()
		server.Handler().ServeHTTP(rec, req)
		return rec
	}

	if rec := do(http.MethodPost, "/v1/matches/match-api02/quest-workflow/review",
		`{"reviewer_user_id":"user-b","decision_status":"approved"}`); rec.Code != http.StatusNotFound {
		t.Fatalf("review with nothing submitted: code=%d body=%s", rec.Code, rec.Body.String())
	}

	if rec := do(http.MethodPut, "/v1/matches/match-api02/quest-template", `{
		"creator_user_id": "user-a",
		"prompt_template": "Share one value that shapes how you show up for people.",
		"min_chars": 20,
		"max_chars": 200
	}`); rec.Code != http.StatusOK {
		t.Fatalf("upsert template code=%d body=%s", rec.Code, rec.Body.String())
	}
	if rec := do(http.MethodPost, "/v1/matches/match-api02/quest-workflow/submit", `{
		"submitter_user_id": "user-b",
		"response_text": "Consistency: I show up when I said I would and I say so early when I can't."
	}`); rec.Code != http.StatusOK {
		t.Fatalf("submit code=%d body=%s", rec.Code, rec.Body.String())
	}

	self := do(http.MethodPost, "/v1/matches/match-api02/quest-workflow/review",
		`{"reviewer_user_id":"user-b","decision_status":"approved"}`)
	if self.Code != http.StatusForbidden {
		t.Fatalf("self review: code=%d body=%s", self.Code, self.Body.String())
	}
	selfPayload := decodeJSONMap(t, self.Body.Bytes())
	if got := stringValue(selfPayload["error_code"]); got != "QUEST_SELF_REVIEW" {
		t.Fatalf("self review error_code=%q", got)
	}
	if got := stringValue(selfPayload["error"]); !strings.Contains(got, "your own quest response") {
		t.Fatalf("self review message=%q", got)
	}

	if rec := do(http.MethodPost, "/v1/matches/match-api02/quest-workflow/review",
		`{"reviewer_user_id":"user-a","decision_status":"approved"}`); rec.Code != http.StatusOK {
		t.Fatalf("partner review code=%d body=%s", rec.Code, rec.Body.String())
	}

	again := do(http.MethodPost, "/v1/matches/match-api02/quest-workflow/review",
		`{"reviewer_user_id":"user-a","decision_status":"approved"}`)
	if again.Code != http.StatusConflict {
		t.Fatalf("review after approval: code=%d body=%s", again.Code, again.Body.String())
	}
	if got := stringValue(decodeJSONMap(t, again.Body.Bytes())["error_code"]); got != "QUEST_NOT_PENDING" {
		t.Fatalf("review after approval error_code=%q", got)
	}
}

func TestQuestWorkflowErrorStatus_WrappedErrorsKeepTheirStatus(t *testing.T) {
	cases := []struct {
		err    error
		status int
	}{
		{errQuestSelfReview, http.StatusForbidden},
		{errQuestNotPending, http.StatusConflict},
		{errQuestCooldown, http.StatusConflict},
		{errQuestRateLimited, http.StatusTooManyRequests},
		{errQuestSubmissionNotFound, http.StatusNotFound},
		{questResponseLengthError(20, 200), http.StatusBadRequest},
		{errUnauthorizedQuestAction, http.StatusForbidden},
	}
	for _, tc := range cases {
		wrapped := fmt.Errorf("review quest response failed: %w", tc.err)
		status, _, ok := questWorkflowErrorStatus(wrapped)
		if !ok || status != tc.status {
			t.Fatalf("%v: status=%d ok=%v, want %d", tc.err, status, ok, tc.status)
		}
	}
	if _, _, ok := questWorkflowErrorStatus(errors.New("dial tcp: connection refused")); ok {
		t.Fatalf("infrastructure errors must not be mapped to client errors")
	}
}
