package mobile

import (
	"context"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/verified-dating/backend/internal/platform/config"
)

func TestIdentityProviderUploadsValidatedEvidenceBytes(t *testing.T) {
	var authorization, userID, document, selfie string
	provider := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		authorization = r.Header.Get("Authorization")
		if err := r.ParseMultipartForm(1 << 20); err != nil {
			t.Fatal(err)
		}
		userID = r.FormValue("user_id")
		readPart := func(name string) string {
			file, _, err := r.FormFile(name)
			if err != nil {
				t.Fatal(err)
			}
			defer file.Close()
			body, _ := io.ReadAll(file)
			return string(body)
		}
		document, selfie = readPart("id_document"), readPart("selfie")
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`{"decision":"approved","confidence":98.5,"provider_reference":"case-1"}`))
	}))
	defer provider.Close()

	client := &providerReviewClient{provider: "webhook", endpoint: provider.URL, token: "secret", client: provider.Client()}
	assessment, err := client.Assess(context.Background(), "user-1", verificationEvidenceBundle{
		IDDocument: providerEvidenceFile{Filename: "id.jpg", MimeType: "image/jpeg", Content: []byte("document")},
		Selfie:     providerEvidenceFile{Filename: "selfie.jpg", MimeType: "image/jpeg", Content: []byte("selfie")},
	})
	if err != nil {
		t.Fatal(err)
	}
	if authorization != "Bearer secret" || userID != "user-1" || document != "document" || selfie != "selfie" {
		t.Fatalf("unexpected provider request auth=%q user=%q document=%q selfie=%q", authorization, userID, document, selfie)
	}
	if assessment.Decision != "approved" || assessment.ProviderRef != "case-1" {
		t.Fatalf("unexpected assessment: %#v", assessment)
	}
}

func TestVoiceProviderRejectsUnsupportedDecision(t *testing.T) {
	provider := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		_, _ = w.Write([]byte(`{"decision":"maybe"}`))
	}))
	defer provider.Close()
	client := &providerReviewClient{provider: "webhook", endpoint: provider.URL, client: provider.Client()}
	adapter := voiceProviderAdapter{client: client}
	_, err := adapter.Assess(context.Background(), "voice-1", "transcript", voiceRecordingMetadata{
		MimeType: "audio/webm", SHA256: "abc", Content: []byte("audio"),
	})
	if err == nil || !strings.Contains(err.Error(), "unsupported decision") {
		t.Fatalf("expected fail-closed decision validation, got %v", err)
	}
}

func TestVoiceProviderDoesNotAutoApproveWhenDisabledInProduction(t *testing.T) {
	provider := configuredVoiceModerationProvider(config.Config{
		Environment:             "production",
		VoiceModerationProvider: "disabled",
	})
	assessment, err := provider.Assess(context.Background(), "voice-1", "transcript", voiceRecordingMetadata{})
	if err != nil {
		t.Fatal(err)
	}
	if assessment.Decision != "manual_review" {
		t.Fatalf("disabled production moderation must fail closed, got %#v", assessment)
	}
}

func TestVoicePlaybackGrantRejectsTamperingAndExpiry(t *testing.T) {
	server := &Server{cfg: configForPlaybackTest()}
	request := httptest.NewRequest(http.MethodGet, "http://api.example.test/v1/engagement/voice-icebreakers/voice-1/play", nil)
	playbackURL, expiresAt, err := server.signedVoicePlaybackURL(request, "voice-1", "user-1")
	if err != nil || !expiresAt.After(time.Now()) {
		t.Fatalf("grant err=%v expiry=%s", err, expiresAt)
	}
	token := strings.Split(playbackURL, "token=")[1]
	grant, err := server.verifyVoicePlaybackToken(token, "voice-1")
	if err != nil || grant.UserID != "user-1" {
		t.Fatalf("grant=%#v err=%v", grant, err)
	}
	if _, err := server.verifyVoicePlaybackToken(token+"x", "voice-1"); err == nil {
		t.Fatal("tampered playback grant must fail")
	}
}

func configForPlaybackTest() config.Config {
	return config.Config{
		APIPrefix: "/v1", PrivateMediaSigningKey: "0123456789abcdef0123456789abcdef",
		PrivateMediaTokenTTLSeconds: 120,
	}
}
