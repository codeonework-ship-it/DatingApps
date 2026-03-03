package supabase

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	"github.com/gorilla/websocket"
	"go.uber.org/zap"
)

type RealtimeEventHandler func(map[string]any)

type RealtimeClient struct {
	url               string
	apiKey            string
	log               *zap.Logger
	logLevel          string
	heartbeatInterval time.Duration
	conn              *websocket.Conn
	ref               uint64
	handlers          map[string]RealtimeEventHandler
	mu                sync.RWMutex
}

func NewRealtimeClient(
	supabaseURL,
	apiKey string,
	log *zap.Logger,
	logLevel string,
	heartbeatInterval time.Duration,
) *RealtimeClient {
	base := strings.TrimRight(supabaseURL, "/")
	realtimeURL := strings.Replace(base, "https://", "wss://", 1)
	realtimeURL = strings.Replace(realtimeURL, "http://", "ws://", 1)
	realtimeURL = realtimeURL + "/realtime/v1/websocket"
	if strings.TrimSpace(logLevel) == "" {
		logLevel = "warn"
	}
	if heartbeatInterval <= 0 {
		heartbeatInterval = 25 * time.Second
	}

	return &RealtimeClient{
		url:               realtimeURL,
		apiKey:            apiKey,
		log:               log,
		logLevel:          logLevel,
		heartbeatInterval: heartbeatInterval,
		handlers:          make(map[string]RealtimeEventHandler),
	}
}

func (c *RealtimeClient) Connect(ctx context.Context) error {
	u, err := url.Parse(c.url)
	if err != nil {
		return err
	}

	q := u.Query()
	q.Set("apikey", c.apiKey)
	q.Set("log_level", c.logLevel)
	u.RawQuery = q.Encode()

	headers := http.Header{}
	headers.Set("apikey", c.apiKey)
	headers.Set("Authorization", "Bearer "+c.apiKey)

	conn, _, err := websocket.DefaultDialer.DialContext(ctx, u.String(), headers)
	if err != nil {
		return err
	}
	c.conn = conn
	c.log.Info("supabase_realtime_connected", zap.String("url", u.String()))

	go c.heartbeatLoop(ctx)
	go c.readLoop(ctx)

	return nil
}

func (c *RealtimeClient) SubscribeToTable(schema, table string, handler RealtimeEventHandler) error {
	if c.conn == nil {
		return fmt.Errorf("realtime connection is not established")
	}

	topic := fmt.Sprintf("realtime:%s:%s", schema, table)

	c.mu.Lock()
	c.handlers[topic] = handler
	c.mu.Unlock()

	joinPayload := map[string]any{
		"topic": topic,
		"event": "phx_join",
		"payload": map[string]any{
			"config": map[string]any{
				"broadcast": map[string]any{"self": false},
				"presence":  map[string]any{"key": ""},
				"postgres_changes": []map[string]any{{
					"event":  "*",
					"schema": schema,
					"table":  table,
				}},
			},
		},
		"ref": c.nextRef(),
	}

	return c.conn.WriteJSON(joinPayload)
}

func (c *RealtimeClient) heartbeatLoop(ctx context.Context) {
	ticker := time.NewTicker(c.heartbeatInterval)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			if c.conn == nil {
				return
			}
			heartbeat := map[string]any{
				"topic":   "phoenix",
				"event":   "heartbeat",
				"payload": map[string]any{},
				"ref":     c.nextRef(),
			}
			if err := c.conn.WriteJSON(heartbeat); err != nil {
				c.log.Warn("supabase_realtime_heartbeat_failed", zap.Error(err))
				return
			}
		}
	}
}

func (c *RealtimeClient) readLoop(ctx context.Context) {
	for {
		select {
		case <-ctx.Done():
			return
		default:
		}

		if c.conn == nil {
			return
		}

		_, data, err := c.conn.ReadMessage()
		if err != nil {
			c.log.Warn("supabase_realtime_read_failed", zap.Error(err))
			return
		}

		var envelope map[string]any
		if err := json.Unmarshal(data, &envelope); err != nil {
			c.log.Warn("supabase_realtime_decode_failed", zap.Error(err))
			continue
		}

		topic, _ := envelope["topic"].(string)
		event, _ := envelope["event"].(string)
		if event != "postgres_changes" {
			continue
		}

		c.mu.RLock()
		handler := c.handlers[topic]
		c.mu.RUnlock()
		if handler != nil {
			handler(envelope)
		}
	}
}

func (c *RealtimeClient) Close() error {
	if c.conn == nil {
		return nil
	}
	return c.conn.Close()
}

func (c *RealtimeClient) nextRef() string {
	next := atomic.AddUint64(&c.ref, 1)
	return fmt.Sprintf("%d", next)
}
