package mobile

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"net/http"
	"strings"
	"unicode/utf8"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
)

var allowedGiftReportReasons = map[string]bool{
	"unwanted": true, "harassment": true, "sexual_content": true,
	"scam": true, "other": true,
}

var errInvalidGiftReceiverIdentifiers = errors.New(
	"match, message, and receiver ids must be valid UUIDs",
)

type receivedGiftResource struct {
	GiftSendID string
	MessageID  string
	MatchID    string
	SenderID   string
	ReceiverID string
}

func validateGiftReport(reason, details string) error {
	if !allowedGiftReportReasons[strings.ToLower(strings.TrimSpace(reason))] {
		return errors.New("reason must be unwanted, harassment, sexual_content, scam, or other")
	}
	if utf8.RuneCountInString(strings.TrimSpace(details)) > 500 {
		return errors.New("details must be 500 characters or fewer")
	}
	return nil
}

func loadReceivedGift(
	ctx context.Context,
	queryer interface {
		QueryRowContext(context.Context, string, ...any) *sql.Row
	},
	matchID, messageID, receiverID string,
) (receivedGiftResource, error) {
	for _, value := range []string{matchID, messageID, receiverID} {
		if _, err := uuid.Parse(strings.TrimSpace(value)); err != nil {
			return receivedGiftResource{}, errInvalidGiftReceiverIdentifiers
		}
	}
	var item receivedGiftResource
	err := queryer.QueryRowContext(ctx, `
		SELECT s.id::text,m.id::text,m.match_id::text,
		       s.sender_user_id::text,s.receiver_user_id::text
		FROM matching.messages m
		JOIN matching.match_gift_sends s ON s.id=m.gift_send_id
		WHERE m.match_id=$1::uuid AND m.id=$2::uuid
		  AND s.receiver_user_id=$3::uuid AND COALESCE(m.is_deleted,FALSE)=FALSE`,
		matchID, messageID, receiverID).Scan(
		&item.GiftSendID, &item.MessageID, &item.MatchID,
		&item.SenderID, &item.ReceiverID,
	)
	return item, err
}

func publishGiftReceiverEventTx(
	ctx context.Context, tx *sql.Tx, eventName, receiverID string,
	item receivedGiftResource, payload map[string]any,
) error {
	encoded, err := json.Marshal(payload)
	if err != nil {
		return err
	}
	_, err = tx.ExecContext(ctx, `
		SELECT platform.publish_domain_event(
		  $1,1,'gift_send',$2,'mobile-bff.gift-receiver-controls',
		  $3::uuid,$3::uuid,NULL,NULL,$4,$5::jsonb,'{}'::jsonb,NOW()
		)`, eventName, item.GiftSendID, receiverID,
		"gift-receiver:"+eventName+":"+item.GiftSendID, string(encoded))
	return err
}

func (s *Server) hideReceivedGift(w http.ResponseWriter, r *http.Request) {
	principal, err := requestPrincipal(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	db, err := s.growthDB()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	tx, err := db.BeginTx(r.Context(), &sql.TxOptions{Isolation: sql.LevelReadCommitted})
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	defer func() { _ = tx.Rollback() }()
	item, err := loadReceivedGift(
		r.Context(), tx, chi.URLParam(r, "matchID"),
		chi.URLParam(r, "messageID"), principal.UserID,
	)
	if errors.Is(err, sql.ErrNoRows) {
		writeError(w, http.StatusNotFound, errors.New("received gift not found"))
		return
	}
	if errors.Is(err, errInvalidGiftReceiverIdentifiers) {
		writeError(w, http.StatusBadRequest, err)
		return
	}
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("gift visibility persistence is unavailable"))
		return
	}
	if _, err = tx.ExecContext(r.Context(), `
		INSERT INTO matching.gift_receiver_actions(
		  gift_send_id,receiver_user_id,hidden_at,created_at,updated_at
		) VALUES($1::uuid,$2::uuid,NOW(),NOW(),NOW())
		ON CONFLICT(gift_send_id) DO UPDATE
		SET hidden_at=COALESCE(matching.gift_receiver_actions.hidden_at,EXCLUDED.hidden_at),
		    updated_at=NOW()`, item.GiftSendID, principal.UserID); err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	if err = insertSecurityEventTx(
		r.Context(), tx, "gift.receiver_hidden", principal.UserID, "user",
		item.SenderID, "gift_send", item.GiftSendID,
		map[string]any{"match_id": item.MatchID, "message_id": item.MessageID},
	); err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	if err = publishGiftReceiverEventTx(
		r.Context(), tx, "gift.receiver_hidden", principal.UserID, item,
		map[string]any{"match_id": item.MatchID, "message_id": item.MessageID},
	); err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	if err = tx.Commit(); err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{
		"hidden": true, "message_id": item.MessageID, "gift_send_id": item.GiftSendID,
	})
}

func (s *Server) reportReceivedGift(w http.ResponseWriter, r *http.Request) {
	principal, err := requestPrincipal(r)
	if err != nil {
		writeError(w, http.StatusUnauthorized, err)
		return
	}
	payload, ok := readJSON(w, r)
	if !ok {
		return
	}
	reason := strings.ToLower(strings.TrimSpace(toString(payload["reason"])))
	details := strings.TrimSpace(toString(payload["details"]))
	if err = validateGiftReport(reason, details); err != nil {
		writeError(w, http.StatusBadRequest, err)
		return
	}
	db, err := s.growthDB()
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	tx, err := db.BeginTx(r.Context(), &sql.TxOptions{Isolation: sql.LevelSerializable})
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	defer func() { _ = tx.Rollback() }()
	item, err := loadReceivedGift(
		r.Context(), tx, chi.URLParam(r, "matchID"),
		chi.URLParam(r, "messageID"), principal.UserID,
	)
	if errors.Is(err, sql.ErrNoRows) {
		writeError(w, http.StatusNotFound, errors.New("received gift not found"))
		return
	}
	if errors.Is(err, errInvalidGiftReceiverIdentifiers) {
		writeError(w, http.StatusBadRequest, err)
		return
	}
	if err != nil {
		writeError(w, http.StatusServiceUnavailable, errors.New("gift reporting persistence is unavailable"))
		return
	}
	if _, err = tx.ExecContext(r.Context(), `
		INSERT INTO matching.gift_receiver_actions(
		  gift_send_id,receiver_user_id,hidden_at,created_at,updated_at
		) VALUES($1::uuid,$2::uuid,NOW(),NOW(),NOW())
		ON CONFLICT(gift_send_id) DO UPDATE
		SET hidden_at=COALESCE(matching.gift_receiver_actions.hidden_at,EXCLUDED.hidden_at),
		    updated_at=NOW()`, item.GiftSendID, principal.UserID); err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	var existingReport sql.NullString
	if err = tx.QueryRowContext(r.Context(), `
		SELECT moderation_report_id::text
		FROM matching.gift_receiver_actions
		WHERE gift_send_id=$1::uuid FOR UPDATE`, item.GiftSendID).Scan(&existingReport); err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	if existingReport.Valid {
		if err = tx.Commit(); err != nil {
			writeError(w, http.StatusServiceUnavailable, err)
			return
		}
		writeJSON(w, http.StatusOK, map[string]any{
			"reported": true, "hidden": true, "message_id": item.MessageID,
			"gift_send_id": item.GiftSendID, "report_id": existingReport.String,
		})
		return
	}
	var reportID string
	description := "Gift send " + item.GiftSendID + " in message " + item.MessageID
	if details != "" {
		description += ": " + details
	}
	if err = tx.QueryRowContext(r.Context(), `
		INSERT INTO matching.moderation_reports(
		  reporter_user_id,reported_user_id,match_id,reason,description,status
		) VALUES($1::uuid,$2::uuid,$3::uuid,$4,$5,'pending')
		RETURNING id::text`, principal.UserID, item.SenderID, item.MatchID,
		"gift_"+reason, description).Scan(&reportID); err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	if _, err = tx.ExecContext(r.Context(), `
		UPDATE matching.gift_receiver_actions
		SET reported_at=NOW(),report_reason=$2,report_details=NULLIF($3,''),
		    moderation_report_id=$4::uuid,updated_at=NOW()
		WHERE gift_send_id=$1::uuid`, item.GiftSendID, reason, details, reportID); err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	if err = insertSecurityEventTx(
		r.Context(), tx, "gift.receiver_reported", principal.UserID, "user",
		item.SenderID, "gift_send", item.GiftSendID,
		map[string]any{
			"match_id": item.MatchID, "message_id": item.MessageID,
			"reason": reason, "moderation_report_id": reportID,
		},
	); err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	if err = publishGiftReceiverEventTx(
		r.Context(), tx, "gift.receiver_reported", principal.UserID, item,
		map[string]any{
			"match_id": item.MatchID, "message_id": item.MessageID,
			"reason": reason, "moderation_report_id": reportID,
		},
	); err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	if err = tx.Commit(); err != nil {
		writeError(w, http.StatusServiceUnavailable, err)
		return
	}
	writeJSON(w, http.StatusCreated, map[string]any{
		"reported": true, "hidden": true, "message_id": item.MessageID,
		"gift_send_id": item.GiftSendID, "report_id": reportID,
	})
}

func (s *Server) filterHiddenReceivedGiftMessages(
	ctx context.Context, principal securityPrincipal, matchID string, response map[string]any,
) error {
	if strings.TrimSpace(principal.UserID) == "" {
		return nil
	}
	db, err := s.growthDB()
	if err != nil {
		return err
	}
	rows, err := db.QueryContext(ctx, `
		SELECT m.id::text
		FROM matching.gift_receiver_actions a
		JOIN matching.match_gift_sends s ON s.id=a.gift_send_id
		JOIN matching.messages m ON m.gift_send_id=s.id
		WHERE a.receiver_user_id=$1::uuid AND s.match_id=$2::uuid
		  AND a.hidden_at IS NOT NULL`, principal.UserID, matchID)
	if err != nil {
		return err
	}
	defer rows.Close()
	hidden := map[string]bool{}
	for rows.Next() {
		var messageID string
		if err = rows.Scan(&messageID); err != nil {
			return err
		}
		hidden[messageID] = true
	}
	if err = rows.Err(); err != nil {
		return err
	}
	items, ok := response["messages"].([]any)
	if !ok {
		return nil
	}
	visible := make([]any, 0, len(items))
	for _, raw := range items {
		item, ok := raw.(map[string]any)
		if !ok || !hidden[strings.TrimSpace(toString(item["id"]))] {
			visible = append(visible, raw)
		}
	}
	response["messages"] = visible
	return nil
}
