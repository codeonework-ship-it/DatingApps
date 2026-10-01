package mobile

import (
	"net/http/httptest"
	"testing"
)

func TestBrowserSocketAuthorizationBoundaries(t *testing.T) {
	token := "opaque-session-token-1234567890"
	for _, tc := range []struct {
		name, path, origin, protocols, upgrade string
		want                                   bool
	}{
		{"chat", "/v1/realtime/chat", "https://connect.test", "connect.v1, bearer." + token, "websocket", true},
		{"notifications", "/v1/realtime/notifications", "https://connect.test", "connect.v1, bearer." + token, "websocket", true},
		{"cross origin", "/v1/realtime/chat", "https://attacker.test", "connect.v1, bearer." + token, "websocket", false},
		{"no origin", "/v1/realtime/chat", "", "connect.v1, bearer." + token, "websocket", false},
		{"ordinary http", "/v1/realtime/chat", "https://connect.test", "connect.v1, bearer." + token, "", false},
		{"other endpoint", "/v1/admin/users", "https://connect.test", "connect.v1, bearer." + token, "websocket", false},
		{"no version", "/v1/realtime/chat", "https://connect.test", "bearer." + token, "websocket", false},
		{"duplicate token", "/v1/realtime/chat", "https://connect.test", "connect.v1, bearer." + token + ", bearer." + token, "websocket", false},
		{"url token ignored", "/v1/realtime/chat?access_token=" + token, "https://connect.test", "connect.v1", "websocket", false},
	} {
		t.Run(tc.name, func(t *testing.T) {
			r := httptest.NewRequest("GET", "https://connect.test"+tc.path, nil)
			r.Header.Set("Origin", tc.origin)
			r.Header.Set("Connection", "Upgrade")
			r.Header.Set("Upgrade", tc.upgrade)
			r.Header.Set("Sec-WebSocket-Protocol", tc.protocols)
			got := browserSocketAuthorization(r, "/v1")
			if (got != "") != tc.want {
				t.Fatalf("acceptance=%v want=%v", got != "", tc.want)
			}
			if tc.want && got != "Bearer "+token {
				t.Fatal("unexpected authorization")
			}
		})
	}
}
