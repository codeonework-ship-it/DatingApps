package observability

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/go-chi/chi/v5"
)

func TestRedactTextRemovesPersonalDataAndSecrets(t *testing.T) {
	cases := []struct {
		name      string
		in        string
		forbidden []string
		want      []string
	}{
		{"email", "login failed for priya.k+test@example.co.in today", []string{"priya", "example.co.in"}, []string{RedactedEmail}},
		{"phone", "OTP sent to +91 98765 43210", []string{"98765", "43210"}, []string{RedactedPhone}},
		{"phone plain", "call 9876543210 now", []string{"9876543210"}, nil},
		{"uuid", "profile 3fa85f64-5717-4562-b3fc-2c963f66afa6 missing", []string{"3fa85f64"}, []string{RedactedID}},
		{"bearer", "Authorization: Bearer abc.def-123_xyz", []string{"abc.def-123_xyz"}, []string{RedactedToken}},
		{"jwt", "token eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIn0.c2lnbmF0dXJlX3ZhbHVl expired", []string{"eyJhbGci"}, []string{RedactedToken}},
		{"secret pair", `{"password":"hunter22","refresh_token":"r1"}`, []string{"hunter22", `"r1"`}, nil},
		{"url query", "GET https://api.example.com/v1/discovery/42?city=Pune&lat=18.5 failed", []string{"city=Pune", "lat=18.5"}, []string{"https://api.example.com/v1/discovery/42"}},
		{"path query", "DioException /v1/profile/me?phone=9876543210", []string{"phone=", "9876543210"}, []string{"/v1/profile/me"}},
		{"ip", "connect to 192.168.10.24 refused", []string{"192.168.10.24"}, []string{RedactedIP}},
		{"card", "card 4242 4242 4242 4242 declined", []string{"4242 4242"}, []string{RedactedNumber}},
		{"long hex", "hash 9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08", []string{"9f86d081884c"}, []string{RedactedToken}},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			got := RedactText(tc.in)
			for _, bad := range tc.forbidden {
				if strings.Contains(got, bad) {
					t.Fatalf("RedactText(%q) = %q still contains %q", tc.in, got, bad)
				}
			}
			for _, good := range tc.want {
				if !strings.Contains(got, good) {
					t.Fatalf("RedactText(%q) = %q, want it to contain %q", tc.in, got, good)
				}
			}
		})
	}
}

func TestRedactTextKeepsDiagnosticDetail(t *testing.T) {
	stack := "#0      _AuthScreenState.build (package:verified_dating_app/features/auth/screens/auth_screen.dart:123:45)\n" +
		"#1      StatelessElement.build (package:flutter/src/widgets/framework.dart:5687:49)"
	if got := RedactText(stack); got != stack {
		t.Fatalf("stack frames must survive redaction unchanged:\n%s\n%s", stack, got)
	}
	message := "Null check operator used on a null value; password is required; status code: 404 at 2026-10-01T12:00:00Z"
	if got := RedactText(message); got != message {
		t.Fatalf("plain diagnostic text was altered: %q", got)
	}
	if got := RedactText(""); got != "" {
		t.Fatalf("empty stays empty, got %q", got)
	}
}

func TestStripPathIDs(t *testing.T) {
	cases := map[string]string{
		"/v1/profile/3fa85f64-5717-4562-b3fc-2c963f66afa6":          "/v1/profile/{id}",
		"/v1/discovery/42/today?city=Pune":                          "/v1/discovery/{id}/today",
		"/v1/admin/moderation/conversation-room-moderation-actions": "/v1/admin/moderation/conversation-room-moderation-actions",
		"/v1/auth/reset/a1B2c3D4e5F6g7H8i9J0k1L2":                   "/v1/auth/reset/{id}",
		"/v1/users/someone@example.com/agreements":                  "/v1/users/{id}/agreements",
		"/v1/billing/webhooks/stripe":                               "/v1/billing/webhooks/stripe",
		"/profile/<id>/photos/<token>":                              "/profile/{id}/photos/{id}",
		"":                                                          "",
	}
	for in, want := range cases {
		if got := StripPathIDs(in); got != want {
			t.Errorf("StripPathIDs(%q) = %q, want %q", in, got, want)
		}
	}
}

func TestRedactedRequestPathPrefersRouteTemplate(t *testing.T) {
	var seen string
	r := chi.NewRouter()
	r.Route("/v1", func(v1 chi.Router) {
		v1.Get("/profile/{userID}", func(w http.ResponseWriter, req *http.Request) {
			seen = RedactedRequestPath(req)
		})
	})
	r.ServeHTTP(httptest.NewRecorder(), httptest.NewRequest(http.MethodGet, "/v1/profile/3fa85f64-5717-4562-b3fc-2c963f66afa6?x=1", nil))
	if seen != "/v1/profile/{userID}" {
		t.Fatalf("route template expected, got %q", seen)
	}

	// Outside a router (or before routing) the id-stripped path is used.
	raw := httptest.NewRequest(http.MethodGet, "/v1/profile/3fa85f64-5717-4562-b3fc-2c963f66afa6?x=1", nil)
	if got := RedactedRequestPath(raw); got != "/v1/profile/{id}" {
		t.Fatalf("fallback path %q", got)
	}
	if RedactedRequestPath(nil) != "" {
		t.Fatal("nil request")
	}
}

func TestPseudonymizeIdentifier(t *testing.T) {
	a := PseudonymizeIdentifier("+919876543210")
	b := PseudonymizeIdentifier("  +919876543210 ")
	if a == "" || a != b {
		t.Fatalf("pseudonym must be stable and normalised: %q vs %q", a, b)
	}
	if strings.Contains(a, "9876") || !strings.HasPrefix(a, "id_") || len(a) != len("id_")+16 {
		t.Fatalf("pseudonym leaks or has the wrong shape: %q", a)
	}
	if PseudonymizeIdentifier("someone-else") == a {
		t.Fatal("different identifiers must not collide")
	}
	if PseudonymizeIdentifier("   ") != "" {
		t.Fatal("blank identifier stays blank")
	}
}
