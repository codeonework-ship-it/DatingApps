package mobile

import (
	"bytes"
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/go-chi/chi/v5"
)

type voicePlaybackGrant struct {
	IcebreakerID string `json:"icebreaker_id"`
	UserID       string `json:"user_id"`
	ExpiresAt    int64  `json:"exp"`
}

func (s *Server) signedVoicePlaybackURL(r *http.Request, icebreakerID, userID string) (string, time.Time, error) {
	secret := s.privateMediaSigningSecret()
	if len(secret) < 32 {
		return "", time.Time{}, errors.New("private media signing is unavailable")
	}
	ttl := time.Duration(s.cfg.PrivateMediaTokenTTLSeconds) * time.Second
	if ttl < 30*time.Second || ttl > 10*time.Minute {
		ttl = 2 * time.Minute
	}
	expiresAt := time.Now().UTC().Add(ttl)
	payload, _ := json.Marshal(voicePlaybackGrant{IcebreakerID: icebreakerID, UserID: userID, ExpiresAt: expiresAt.Unix()})
	encoded := base64.RawURLEncoding.EncodeToString(payload)
	mac := hmac.New(sha256.New, []byte(secret))
	_, _ = mac.Write([]byte(encoded))
	token := encoded + "." + base64.RawURLEncoding.EncodeToString(mac.Sum(nil))
	scheme := strings.TrimSpace(r.Header.Get("X-Forwarded-Proto"))
	if scheme == "" {
		scheme = "http"
		if r.TLS != nil {
			scheme = "https"
		}
	}
	host := strings.TrimSpace(strings.Split(r.Header.Get("X-Forwarded-Host"), ",")[0])
	if host == "" {
		host = r.Host
	}
	return fmt.Sprintf("%s://%s%s/media/voice/%s?token=%s", scheme, host, s.cfg.APIPrefix,
		icebreakerID, token), expiresAt, nil
}

func (s *Server) verifyVoicePlaybackToken(token, icebreakerID string) (voicePlaybackGrant, error) {
	parts := strings.Split(token, ".")
	if len(parts) != 2 {
		return voicePlaybackGrant{}, errors.New("invalid playback token")
	}
	mac := hmac.New(sha256.New, []byte(s.privateMediaSigningSecret()))
	_, _ = mac.Write([]byte(parts[0]))
	provided, err := base64.RawURLEncoding.DecodeString(parts[1])
	if err != nil || !hmac.Equal(provided, mac.Sum(nil)) {
		return voicePlaybackGrant{}, errors.New("invalid playback token")
	}
	payload, err := base64.RawURLEncoding.DecodeString(parts[0])
	if err != nil {
		return voicePlaybackGrant{}, errors.New("invalid playback token")
	}
	var grant voicePlaybackGrant
	if json.Unmarshal(payload, &grant) != nil || grant.IcebreakerID != icebreakerID || grant.UserID == "" || time.Now().Unix() >= grant.ExpiresAt {
		return voicePlaybackGrant{}, errors.New("expired or invalid playback token")
	}
	return grant, nil
}

func (s *Server) privateMediaSigningSecret() string {
	if configured := strings.TrimSpace(s.cfg.PrivateMediaSigningKey); configured != "" {
		return configured
	}
	environment := strings.ToLower(strings.TrimSpace(s.cfg.Environment))
	if environment != "production" && environment != "prod" && environment != "staging" && environment != "stage" {
		return "local-private-media-signing-key-change-me"
	}
	return ""
}

func (s *Server) serveVoicePlayback(w http.ResponseWriter, r *http.Request) {
	icebreakerID := strings.TrimSpace(chi.URLParam(r, "icebreakerID"))
	grant, err := s.verifyVoicePlaybackToken(strings.TrimSpace(r.URL.Query().Get("token")), icebreakerID)
	if err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	item, err := s.store.voiceIcebreakerForPlayback(icebreakerID, grant.UserID)
	if err != nil {
		writeError(w, http.StatusForbidden, err)
		return
	}
	var payload bytes.Buffer
	if err := s.copyPrivateMedia(r.Context(), &payload, item.AudioStoragePath); err != nil {
		writeError(w, http.StatusBadGateway, errors.New("voice recording is temporarily unavailable"))
		return
	}
	w.Header().Set("Content-Type", item.AudioMimeType)
	w.Header().Set("Cache-Control", "private, no-store")
	w.Header().Set("X-Content-Type-Options", "nosniff")
	w.Header().Set("Content-Length", strconv.Itoa(payload.Len()))
	_, _ = w.Write(payload.Bytes())
}

// copyPrivateMedia reads a stored object (voice, chapter/theme photos,
// evidence) through the configured media store.
func (s *Server) copyPrivateMedia(ctx context.Context, destination io.Writer, storagePath string) error {
	return s.copyPrivateMediaFromStore(ctx, destination, storagePath)
}

func (s *Server) recordVoiceModeration(ctx context.Context, icebreakerID, userID string, recording voiceRecordingMetadata, assessment providerAssessment) error {
	if s.store == nil || s.store.profileRepo == nil || s.store.profileRepo.pg == nil {
		return nil
	}
	_, err := s.store.profileRepo.pg.ExecContext(ctx, `
		INSERT INTO matching.voice_moderation_events(
		  icebreaker_id,user_id,content_sha256,provider,model_version,decision,
		  reason,confidence,provider_reference)
		VALUES($1::uuid,$2::uuid,$3,$4,NULLIF($5,''),$6,NULLIF($7,''),$8,NULLIF($9,''))`,
		icebreakerID, userID, recording.SHA256, assessment.Provider,
		assessment.ModelVersion, assessment.Decision, assessment.Reason,
		assessment.Confidence, assessment.ProviderRef)
	return err
}
