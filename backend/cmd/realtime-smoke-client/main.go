package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/gorilla/websocket"
)

func main() {
	endpoint := strings.TrimSpace(os.Getenv("REALTIME_URL"))
	token := strings.TrimSpace(os.Getenv("ACCESS_TOKEN"))
	expectedType := strings.TrimSpace(os.Getenv("EXPECTED_EVENT_TYPE"))
	expectedMatch := strings.TrimSpace(os.Getenv("EXPECTED_MATCH_ID"))
	if endpoint == "" || token == "" || expectedType == "" {
		fatal("REALTIME_URL, ACCESS_TOKEN, and EXPECTED_EVENT_TYPE are required")
	}
	timeoutSeconds := 15
	if parsed, err := strconv.Atoi(strings.TrimSpace(os.Getenv("TIMEOUT_SECONDS"))); err == nil && parsed > 0 {
		timeoutSeconds = parsed
	}

	header := http.Header{}
	header.Set("Authorization", "Bearer "+token)
	conn, _, err := websocket.DefaultDialer.Dial(endpoint, header)
	if err != nil {
		fatal(err.Error())
	}
	defer conn.Close()
	_ = conn.SetReadDeadline(time.Now().Add(time.Duration(timeoutSeconds) * time.Second))

	for {
		var event map[string]any
		if err := conn.ReadJSON(&event); err != nil {
			fatal(err.Error())
		}
		raw, _ := json.Marshal(event)
		fmt.Println(string(raw))
		eventType := strings.TrimSpace(fmt.Sprint(event["type"]))
		if eventType == "<nil>" || eventType == "" {
			eventType = strings.TrimSpace(fmt.Sprint(event["event_type"]))
		}
		if eventType != expectedType {
			continue
		}
		matchID := strings.TrimSpace(fmt.Sprint(event["match_id"]))
		if matchID == "<nil>" {
			if payload, ok := event["payload"].(map[string]any); ok {
				matchID = strings.TrimSpace(fmt.Sprint(payload["match_id"]))
			}
		}
		if expectedMatch == "" || matchID == expectedMatch {
			return
		}
	}
}

func fatal(message string) {
	fmt.Fprintln(os.Stderr, message)
	os.Exit(1)
}
