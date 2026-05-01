package mobile

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestServer_BootstrapSignupCreatesDraftWithBasics(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	req := httptest.NewRequest(
		http.MethodPost,
		"/v1/auth/signup/bootstrap",
		strings.NewReader(`{"user_id":"signup-user-1","phone":"+91 98765 43210","name":"Priya","date_of_birth":"1998-03-10","gender":"F"}`),
	)
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()
	server.Handler().ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("bootstrap signup code=%d body=%s", rec.Code, rec.Body.String())
	}
	payload := decodeJSONMap(t, rec.Body.Bytes())
	if payload["success"] != true {
		t.Fatalf("expected success=true, payload=%v", payload)
	}
	if payload["created"] != true {
		t.Fatalf("expected created=true on first bootstrap")
	}
	draft := toMap(t, payload["draft"])
	if got := stringValue(draft["name"]); got != "Priya" {
		t.Fatalf("expected draft name Priya, got %q", got)
	}
	if got := stringValue(draft["phone_number"]); got != "+919876543210" {
		t.Fatalf("expected normalized phone, got %q", got)
	}
	if got := int(draft["profile_completion"].(float64)); got != 25 {
		t.Fatalf("expected profile_completion=25, got %d", got)
	}

	stored := server.store.getDraft("signup-user-1")
	if stored.Name != "Priya" || stored.DateOfBirth != "1998-03-10" || stored.Gender != "F" {
		t.Fatalf("stored draft basics mismatch: %+v", stored)
	}
}

func TestServer_BootstrapSignupDoesNotOverwriteExistingCompletedDraft(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	server.store.profiles["signup-user-2"] = profileDraft{
		UserID:            "signup-user-2",
		PhoneNumber:       "+919111111111",
		Name:              "Existing Name",
		DateOfBirth:       "1992-01-01",
		Gender:            "M",
		ProfileCompletion: 100,
	}

	req := httptest.NewRequest(
		http.MethodPost,
		"/v1/auth/signup/bootstrap",
		strings.NewReader(`{"user_id":"signup-user-2","phone":"+91 92222 22222","name":"New Name","date_of_birth":"1999-02-02","gender":"F"}`),
	)
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()
	server.Handler().ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("bootstrap signup code=%d body=%s", rec.Code, rec.Body.String())
	}
	payload := decodeJSONMap(t, rec.Body.Bytes())
	if payload["created"] != false {
		t.Fatalf("expected created=false for existing draft")
	}
	stored := server.store.getDraft("signup-user-2")
	if stored.Name != "Existing Name" || stored.DateOfBirth != "1992-01-01" || stored.Gender != "M" {
		t.Fatalf("signup bootstrap overwrote existing basics: %+v", stored)
	}
	if stored.ProfileCompletion != 100 {
		t.Fatalf("signup bootstrap regressed completion, got %d", stored.ProfileCompletion)
	}
}

func TestServer_BootstrapSignupRejectsUnderage(t *testing.T) {
	server := newQuestWorkflowTestServer(t)
	defer server.Close()

	req := httptest.NewRequest(
		http.MethodPost,
		"/v1/auth/signup/bootstrap",
		strings.NewReader(`{"user_id":"signup-user-3","phone":"+919876543210","name":"Teen","date_of_birth":"2012-01-01","gender":"F"}`),
	)
	req.Header.Set("Content-Type", "application/json")
	rec := httptest.NewRecorder()
	server.Handler().ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Fatalf("expected status 400, got code=%d body=%s", rec.Code, rec.Body.String())
	}
	payload := decodeJSONMap(t, rec.Body.Bytes())
	if !strings.Contains(strings.ToLower(stringValue(payload["error"])), "18") {
		t.Fatalf("expected underage error, payload=%v", payload)
	}
}
