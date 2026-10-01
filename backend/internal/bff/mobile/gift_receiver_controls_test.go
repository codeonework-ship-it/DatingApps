package mobile

import (
	"bytes"
	"context"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/go-chi/chi/v5"
)

func giftReceiverRequest(method, path, matchID, messageID, receiverID, body string) *http.Request {
	req := httptest.NewRequest(method, path, bytes.NewBufferString(body))
	req.Header.Set("Content-Type", "application/json")
	routeContext := chi.NewRouteContext()
	routeContext.URLParams.Add("matchID", matchID)
	routeContext.URLParams.Add("messageID", messageID)
	ctx := context.WithValue(req.Context(), chi.RouteCtxKey, routeContext)
	ctx = context.WithValue(ctx, securityPrincipalContextKey{}, securityPrincipal{
		UserID: receiverID,
		Roles:  map[string]bool{"user": true},
	})
	return req.WithContext(ctx)
}

func TestValidateGiftReport(t *testing.T) {
	if err := validateGiftReport("harassment", strings.Repeat("x", 500)); err != nil {
		t.Fatalf("valid report rejected: %v", err)
	}
	if err := validateGiftReport("unsupported", ""); err == nil {
		t.Fatal("unsupported reason accepted")
	}
	if err := validateGiftReport("other", strings.Repeat("x", 501)); err == nil {
		t.Fatal("overlong details accepted")
	}
}

func TestGiftReceiverCanHideAndReportButSenderCannotPostgres(t *testing.T) {
	f := newGiftLedgerFixture(t, 20)
	var hasControls bool
	if err := f.db.QueryRow(`SELECT to_regclass('matching.gift_receiver_actions') IS NOT NULL`).Scan(&hasControls); err != nil {
		t.Fatal(err)
	}
	if !hasControls {
		t.Skip("migration 083_gift_receiver_controls is not applied")
	}
	view, err := f.send("rose_sparkle", "receiver-controls")
	if err != nil {
		t.Fatalf("send: %v", err)
	}
	server := &Server{store: &runtimeStore{profileRepo: &profileRepository{pg: f.db}}}

	wrong := httptest.NewRecorder()
	server.hideReceivedGift(wrong, giftReceiverRequest(
		http.MethodPost, "/gift/hide", f.matchID, view.MessageID, f.sender, "",
	))
	if wrong.Code != http.StatusNotFound {
		t.Fatalf("sender hide status=%d body=%s", wrong.Code, wrong.Body.String())
	}

	hidden := httptest.NewRecorder()
	server.hideReceivedGift(hidden, giftReceiverRequest(
		http.MethodPost, "/gift/hide", f.matchID, view.MessageID, f.receiver, "",
	))
	if hidden.Code != http.StatusOK {
		t.Fatalf("receiver hide status=%d body=%s", hidden.Code, hidden.Body.String())
	}
	response := map[string]any{"messages": []any{
		map[string]any{"id": view.MessageID}, map[string]any{"id": "visible-message"},
	}}
	if err := server.filterHiddenReceivedGiftMessages(
		context.Background(), securityPrincipal{UserID: f.receiver}, f.matchID, response,
	); err != nil {
		t.Fatalf("filter hidden gift: %v", err)
	}
	visible := response["messages"].([]any)
	if len(visible) != 1 || toString(visible[0].(map[string]any)["id"]) != "visible-message" {
		t.Fatalf("visible messages=%#v", visible)
	}

	reported := httptest.NewRecorder()
	server.reportReceivedGift(reported, giftReceiverRequest(
		http.MethodPost, "/gift/report", f.matchID, view.MessageID, f.receiver,
		`{"reason":"harassment","details":"Repeated unwanted gift"}`,
	))
	if reported.Code != http.StatusCreated {
		t.Fatalf("receiver report status=%d body=%s", reported.Code, reported.Body.String())
	}
	var reportCount int
	if err := f.db.QueryRow(`SELECT COUNT(*) FROM matching.moderation_reports
		WHERE reporter_user_id=$1 AND reported_user_id=$2 AND match_id=$3`,
		f.receiver, f.sender, f.matchID).Scan(&reportCount); err != nil {
		t.Fatal(err)
	}
	if reportCount != 1 {
		t.Fatalf("report count=%d, want 1", reportCount)
	}

	replay := httptest.NewRecorder()
	server.reportReceivedGift(replay, giftReceiverRequest(
		http.MethodPost, "/gift/report", f.matchID, view.MessageID, f.receiver,
		`{"reason":"harassment"}`,
	))
	if replay.Code != http.StatusOK {
		t.Fatalf("report replay status=%d body=%s", replay.Code, replay.Body.String())
	}
	if err := f.db.QueryRow(`SELECT COUNT(*) FROM matching.moderation_reports
		WHERE reporter_user_id=$1 AND reported_user_id=$2 AND match_id=$3`,
		f.receiver, f.sender, f.matchID).Scan(&reportCount); err != nil {
		t.Fatal(err)
	}
	if reportCount != 1 {
		t.Fatalf("report replay created duplicates: %d", reportCount)
	}
	var hiddenEventCount, reportedEventCount int
	if err := f.db.QueryRow(`SELECT COUNT(*) FROM platform.domain_event_outbox
		WHERE aggregate_type='gift_send' AND aggregate_id=$1
		  AND event_name='gift.receiver_hidden'`, view.ID).Scan(&hiddenEventCount); err != nil {
		t.Fatal(err)
	}
	if err := f.db.QueryRow(`SELECT COUNT(*) FROM platform.domain_event_outbox
		WHERE aggregate_type='gift_send' AND aggregate_id=$1
		  AND event_name='gift.receiver_reported'`, view.ID).Scan(&reportedEventCount); err != nil {
		t.Fatal(err)
	}
	if hiddenEventCount != 1 || reportedEventCount != 1 {
		t.Fatalf("semantic events hidden=%d reported=%d", hiddenEventCount, reportedEventCount)
	}
}
