package mobile

import (
	"database/sql"
	"encoding/json"
	"errors"
	"net/http"
	"strings"
)

func (s *Server) getOperationStatus(w http.ResponseWriter, r *http.Request) {
	if s.sharedIdempotency == nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("operation recovery is unavailable"))
		return
	}
	principal, ok := principalFromRequest(r)
	if !ok || strings.TrimSpace(principal.UserID) == "" {
		writeError(w, http.StatusUnauthorized, errors.New("valid bearer session is required"))
		return
	}
	method := strings.ToUpper(strings.TrimSpace(r.URL.Query().Get("method")))
	requestPath := strings.TrimSpace(r.URL.Query().Get("path"))
	idempotencyKey := strings.TrimSpace(r.URL.Query().Get("idempotency_key"))
	if method == "" || requestPath == "" || idempotencyKey == "" || len(idempotencyKey) > 255 ||
		!strings.HasPrefix(requestPath, s.cfg.APIPrefix+"/") {
		writeError(w, http.StatusBadRequest, errors.New("method, API path, and idempotency_key are required"))
		return
	}
	status, err := s.sharedIdempotency.status(r.Context(), method, requestPath, principal.UserID, idempotencyKey)
	if errors.Is(err, sql.ErrNoRows) {
		writeError(w, http.StatusNotFound, errors.New("operation record not found or expired"))
		return
	}
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("operation recovery is unavailable"))
		return
	}
	state := status.State
	if state == "processing" && status.LeaseExpired {
		state = "recovery_required"
	}
	payload := map[string]any{
		"operation_id": status.OperationID, "state": state,
		"updated_at": status.UpdatedAt.UTC().Format("2006-01-02T15:04:05.999999999Z07:00"),
	}
	if status.State == "completed" {
		payload["http_status"] = status.HTTPStatus
		payload["content_type"] = status.ContentType
		if strings.Contains(strings.ToLower(status.ContentType), "json") && len(status.Body) > 0 {
			var result any
			if json.Unmarshal(status.Body, &result) == nil {
				payload["result"] = result
			}
		}
	}
	writeJSON(w, http.StatusOK, payload)
}
