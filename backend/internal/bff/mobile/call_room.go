package mobile

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"net/url"
	"strings"
	"time"
)

func (s *Server) decorateCallResponse(response map[string]any, userID string) {
	if session, ok := response["session"].(map[string]any); ok {
		s.decorateCallSession(session, userID)
	}
}

func (s *Server) decorateCallHistoryResponse(response map[string]any, userID string) {
	switch items := response["history"].(type) {
	case []map[string]any:
		for _, session := range items {
			s.decorateCallSession(session, userID)
		}
	case []any:
		for _, raw := range items {
			if session, ok := raw.(map[string]any); ok {
				s.decorateCallSession(session, userID)
			}
		}
	}
}

func (s *Server) decorateCallSession(session map[string]any, userID string) {
	if strings.EqualFold(strings.TrimSpace(toString(session["status"])), "ended") {
		return
	}
	roomID := strings.TrimSpace(toString(session["room_id"]))
	baseURL := strings.TrimRight(strings.TrimSpace(s.cfg.CallRoomBaseURL), "/")
	if roomID == "" || baseURL == "" {
		return
	}
	joinURL := baseURL + "/" + url.PathEscape(roomID)
	switch s.cfg.CallTransportProvider {
	case "jitsi_jwt":
		token, expiresAt, ok := s.callRoomToken(roomID, userID)
		if !ok {
			return
		}
		joinURL += "?jwt=" + url.QueryEscape(token)
		session["join_token_expires_at"] = expiresAt.Format(time.RFC3339)
	case "public_jitsi", "": // empty is limited to direct unit-test construction
	default:
		return
	}
	session["join_url"] = joinURL
}

func (s *Server) callRoomToken(roomID, userID string) (string, time.Time, bool) {
	secret := strings.TrimSpace(s.cfg.CallJWTSecret)
	if s.cfg.CallTransportProvider != "jitsi_jwt" || len(secret) < 32 || roomID == "" || userID == "" {
		return "", time.Time{}, false
	}
	now := time.Now().UTC()
	ttl := time.Duration(s.cfg.CallTokenTTLSeconds) * time.Second
	if ttl < time.Minute || ttl > 15*time.Minute {
		ttl = 5 * time.Minute
	}
	expiresAt := now.Add(ttl)
	header, _ := json.Marshal(map[string]any{"alg": "HS256", "typ": "JWT"})
	claims, _ := json.Marshal(map[string]any{
		"aud": s.cfg.CallJWTAudience, "iss": s.cfg.CallJWTIssuer,
		"sub": s.cfg.CallRoomBaseURL, "room": roomID,
		"iat": now.Unix(), "nbf": now.Add(-5 * time.Second).Unix(), "exp": expiresAt.Unix(),
		"context": map[string]any{"user": map[string]any{"id": userID, "moderator": false}},
	})
	encode := base64.RawURLEncoding.EncodeToString
	unsigned := encode(header) + "." + encode(claims)
	mac := hmac.New(sha256.New, []byte(secret))
	_, _ = mac.Write([]byte(unsigned))
	return unsigned + "." + encode(mac.Sum(nil)), expiresAt, true
}
