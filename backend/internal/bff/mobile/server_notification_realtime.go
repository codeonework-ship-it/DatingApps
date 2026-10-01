package mobile

import (
	"errors"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/gorilla/websocket"
	"go.uber.org/zap"
)

func (s *Server) streamNotificationEvents(w http.ResponseWriter, r *http.Request) {
	if s.notifications == nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("notification persistence is unavailable"))
		return
	}
	principal, ok := principalFromRequest(r)
	if !ok || strings.TrimSpace(principal.UserID) == "" {
		writeError(w, http.StatusUnauthorized, errors.New("valid bearer session is required"))
		return
	}
	after := int64(0)
	if raw := strings.TrimSpace(r.URL.Query().Get("after")); raw != "" {
		parsed, err := strconv.ParseInt(raw, 10, 64)
		if err != nil || parsed < 0 {
			writeError(w, http.StatusBadRequest, errors.New("after must be a non-negative notification sequence"))
			return
		}
		after = parsed
	}
	if s.rejectExpiredReplayCursor(w, r, "notifications", principal.UserID, after, s.notifications) {
		return
	}
	conn, err := chatRealtimeUpgrader.Upgrade(w, r, nil)
	if err != nil {
		s.log.Warn("notification_realtime_upgrade_failed", zap.Error(err))
		return
	}
	defer conn.Close()
	conn.SetReadLimit(4096)
	_ = conn.SetReadDeadline(time.Now().Add(chatRealtimePongWait))
	conn.SetPongHandler(func(string) error { return conn.SetReadDeadline(time.Now().Add(chatRealtimePongWait)) })
	closed := make(chan struct{})
	go func() {
		defer close(closed)
		for {
			if _, _, err := conn.ReadMessage(); err != nil {
				return
			}
		}
	}()
	if err := conn.WriteJSON(map[string]any{
		"type": "stream.connected", "sequence": after,
		"payload": map[string]any{"resume_after": after, "stream": "notifications"},
	}); err != nil {
		return
	}
	poll := time.NewTicker(chatRealtimePollInterval)
	ping := time.NewTicker(chatRealtimePingInterval)
	defer poll.Stop()
	defer ping.Stop()
	for {
		if s.realtimeAuthorizer != nil {
			if err := s.realtimeAuthorizer.authorizeRealtimeSession(r.Context(), principal); err != nil {
				_ = conn.WriteControl(websocket.CloseMessage,
					websocket.FormatCloseMessage(websocket.ClosePolicyViolation, "session revoked"),
					time.Now().Add(2*time.Second))
				return
			}
		}
		events, err := s.notifications.list(r.Context(), principal.UserID, after, 100)
		if err != nil {
			s.log.Warn("notification_realtime_delivery_failed", zap.String("user_id", principal.UserID), zap.Error(err))
			return
		}
		for _, event := range events {
			if err := conn.WriteJSON(event); err != nil {
				return
			}
			after = event.Sequence
		}
		select {
		case <-r.Context().Done():
			return
		case <-closed:
			return
		case <-poll.C:
		case <-ping.C:
			if err := conn.WriteControl(websocket.PingMessage, nil, time.Now().Add(5*time.Second)); err != nil {
				return
			}
		}
	}
}
