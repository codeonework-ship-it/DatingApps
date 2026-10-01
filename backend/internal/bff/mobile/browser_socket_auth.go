package mobile

import (
	"github.com/gorilla/websocket"
	"net/http"
	"strings"
)

// Browser sockets cannot set Authorization. Accept the opaque session only in
// the upgrade protocol header on our two same-origin streams. Never accept a
// URL token, echo the credential, or broaden other endpoints' authentication.
func browserSocketAuthorization(r *http.Request, prefix string) string {
	if r.Method != http.MethodGet || !websocket.IsWebSocketUpgrade(r) ||
		r.Header.Get("Origin") == "" || !sameHostWebSocketOrigin(r) {
		return ""
	}
	if r.URL.Path != prefix+"/realtime/chat" && r.URL.Path != prefix+"/realtime/notifications" {
		return ""
	}
	token := ""
	version := false
	for _, protocol := range websocket.Subprotocols(r) {
		if protocol == "connect.v1" {
			version = true
		}
		if strings.HasPrefix(protocol, "bearer.") {
			if token != "" {
				return ""
			}
			token = strings.TrimPrefix(protocol, "bearer.")
			if len(token) < 20 || len(token) > 256 || strings.ContainsAny(token, " \t\r\n") {
				return ""
			}
		}
	}
	if !version || token == "" {
		return ""
	}
	return "Bearer " + token
}
