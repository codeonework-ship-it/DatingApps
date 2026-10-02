package mobile

import (
	"context"
	"errors"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"time"

	"github.com/gorilla/websocket"
	"go.uber.org/zap"
)

const (
	chatRealtimePollInterval = 400 * time.Millisecond
	chatRealtimePongWait     = 60 * time.Second
	chatRealtimePingInterval = 20 * time.Second
)

var chatRealtimeUpgrader = websocket.Upgrader{
	HandshakeTimeout: 5 * time.Second,
	Subprotocols:     []string{"connect.v1"},
	ReadBufferSize:   1024,
	WriteBufferSize:  4096,
	CheckOrigin:      sameHostWebSocketOrigin,
}

func sameHostWebSocketOrigin(r *http.Request) bool {
	origin := strings.TrimSpace(r.Header.Get("Origin"))
	if origin == "" {
		return true
	}
	parsed, err := url.Parse(origin)
	if err != nil {
		return false
	}
	expected := strings.TrimSpace(r.Header.Get("X-Forwarded-Host"))
	if expected == "" {
		expected = strings.TrimSpace(r.Host)
	}
	return strings.EqualFold(parsed.Host, expected)
}

func (s *Server) streamChatEvents(w http.ResponseWriter, r *http.Request) {
	if s.realtime == nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("chat realtime persistence is unavailable"))
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
			writeError(w, http.StatusBadRequest, errors.New("after must be a non-negative realtime sequence"))
			return
		}
		after = parsed
	}
	if reader, ok := s.realtime.(replayCursorStateReader); ok &&
		s.rejectExpiredReplayCursor(w, r, "chat", principal.UserID, after, reader) {
		return
	}

	conn, err := chatRealtimeUpgrader.Upgrade(w, r, nil)
	if err != nil {
		s.log.Warn("chat_realtime_upgrade_failed", zap.Error(err))
		return
	}
	defer conn.Close()
	conn.SetReadLimit(4096)
	_ = conn.SetReadDeadline(time.Now().Add(chatRealtimePongWait))
	conn.SetPongHandler(func(string) error {
		return conn.SetReadDeadline(time.Now().Add(chatRealtimePongWait))
	})

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
		"type":     "stream.connected",
		"sequence": after,
		"payload":  map[string]any{"resume_after": after},
	}); err != nil {
		return
	}

	// With the shared wake hub the socket reads the database only when the hub
	// saw new events for this member (plus a slow fallback poll); without it
	// (tests, no database) it keeps the original fixed-interval poll.
	wake, unsubscribe := s.chatWake.subscribe(principal.UserID)
	defer unsubscribe()
	pollEvery := chatRealtimePollInterval
	if s.chatWake != nil {
		pollEvery = realtimeFallbackPollInterval
	}
	poll := time.NewTicker(pollEvery)
	ping := time.NewTicker(chatRealtimePingInterval)
	defer poll.Stop()
	defer ping.Stop()
	connectedAt := time.Now()

	for {
		if s.realtimeAuthorizer != nil {
			if err := s.realtimeAuthorizer.authorizeRealtimeSession(r.Context(), principal); err != nil {
				_ = conn.WriteControl(websocket.CloseMessage,
					websocket.FormatCloseMessage(websocket.ClosePolicyViolation, "session revoked"),
					time.Now().Add(2*time.Second))
				return
			}
		}
		polledThrough := wake.Seq()
		latest, err := s.writePendingChatEvents(r.Context(), conn, principal.UserID, after, connectedAt)
		if err != nil {
			s.log.Warn("chat_realtime_delivery_failed", zap.String("user_id", principal.UserID), zap.Error(err))
			return
		}
		after = latest

		if !waitForRealtimePoll(r.Context(), conn, closed, poll.C, ping.C, wake, after, polledThrough, s.chatWake != nil) {
			return
		}
	}
}

// waitForRealtimePoll blocks until the socket should read its events again.
// It returns false when the socket must close. Pings never cause a database
// read when a wake hub drives the socket.
func waitForRealtimePoll(
	ctx context.Context,
	conn *websocket.Conn,
	closed <-chan struct{},
	poll, ping <-chan time.Time,
	wake *realtimeWakeSub,
	after, polledThrough int64,
	hubDriven bool,
) bool {
	for {
		select {
		case <-ctx.Done():
			return false
		case <-closed:
			return false
		case <-poll:
			return true
		case <-wake.C():
			if realtimeWakePollDue(wake, after, polledThrough) {
				return true
			}
		case <-ping:
			if err := conn.WriteControl(websocket.PingMessage, nil, time.Now().Add(5*time.Second)); err != nil {
				return false
			}
			if !hubDriven {
				return true
			}
		}
	}
}

func (s *Server) writePendingChatEvents(
	ctx context.Context,
	conn *websocket.Conn,
	userID string,
	after int64,
	connectedAt time.Time,
) (int64, error) {
	events, err := s.realtime.listEvents(ctx, userID, after, 100)
	if err != nil {
		return after, err
	}
	latest := after
	for _, event := range events {
		if err := conn.WriteJSON(event); err != nil {
			return latest, err
		}
		// Only live events: replaying a backlog after reconnect is not lag.
		if occurredAt, parseErr := time.Parse(time.RFC3339Nano, event.OccurredAt); parseErr == nil && !occurredAt.Before(connectedAt) {
			s.httpMetrics.ObserveRealtimeDelivery(realtimeStreamChat, occurredAt)
		}
		latest = event.Sequence
		deliveryCtx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
		err := s.realtime.markDelivered(deliveryCtx, userID, event.Sequence)
		cancel()
		if err != nil {
			s.log.Warn(
				"chat_realtime_delivery_checkpoint_failed",
				zap.String("user_id", userID),
				zap.Int64("sequence", event.Sequence),
				zap.Error(err),
			)
		}
	}
	return latest, nil
}
