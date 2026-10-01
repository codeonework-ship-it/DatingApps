package mobile

import (
	"net/http/httptest"
	"testing"
)

func TestNotificationCursorValidatesResumeAndPageBounds(t *testing.T) {
	req := httptest.NewRequest("GET", "/v1/notifications/user-1?after=42&limit=100", nil)
	after, limit, err := notificationCursor(req)
	if err != nil || after != 42 || limit != 100 {
		t.Fatalf("after=%d limit=%d err=%v", after, limit, err)
	}

	for _, rawURL := range []string{
		"/v1/notifications/user-1?after=-1",
		"/v1/notifications/user-1?after=not-a-number",
		"/v1/notifications/user-1?limit=0",
		"/v1/notifications/user-1?limit=201",
	} {
		if _, _, err := notificationCursor(httptest.NewRequest("GET", rawURL, nil)); err == nil {
			t.Fatalf("expected cursor validation error for %s", rawURL)
		}
	}
}

func TestNotificationRoutesAreOwnedByAuthenticatedUser(t *testing.T) {
	const userID = "11111111-1111-4111-8111-111111111111"
	if !pathOwnedByPrincipal("/v1", "/v1/notifications/"+userID+"/preferences", "PATCH", userID) {
		t.Fatal("expected own notification preferences to be accessible")
	}
	if pathOwnedByPrincipal("/v1", "/v1/notifications/22222222-2222-4222-8222-222222222222", "GET", userID) {
		t.Fatal("expected another user's inbox to be rejected")
	}
}
