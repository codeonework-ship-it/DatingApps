package mobile

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"unicode/utf8"

	"github.com/google/uuid"
)

func TestTemplateCopilotDraftsFromProfileFacts(t *testing.T) {
	provider := templateCopilot{}
	profile := map[string]any{
		"hobbies":     []any{"bouldering", "jazz"},
		"profession":  "Architect",
		"city":        "Bengaluru",
		"intent_tags": []any{"serious"},
	}
	for _, kind := range []string{"opener", "reply", "plan_idea"} {
		for _, tone := range []string{"warm", "playful", "direct"} {
			result, err := provider.Draft(context.Background(), copilotRequest{
				Kind: kind, Tone: tone, ViewerName: "Me", PartnerName: "Priya", Profile: profile,
				Recent: []copilotTurn{{FromViewer: false, Text: "Do you climb outdoors too?"}},
			})
			if err != nil {
				t.Fatalf("%s/%s: %v", kind, tone, err)
			}
			if result.Text == "" || utf8.RuneCountInString(result.Text) > copilotMaxDraftRunes {
				t.Fatalf("%s/%s draft length %d: %q", kind, tone, utf8.RuneCountInString(result.Text), result.Text)
			}
			if result.Provider != copilotProviderTemplate {
				t.Fatalf("provider=%s", result.Provider)
			}
		}
	}
	opener, _ := provider.Draft(context.Background(), copilotRequest{Kind: "opener", Tone: "warm", PartnerName: "Priya", Profile: profile})
	if !strings.Contains(opener.Text, "bouldering") || !strings.Contains(opener.Text, "Priya") {
		t.Fatalf("opener ignores profile facts: %q", opener.Text)
	}
	if clampDraft(strings.Repeat("a", 400)) == strings.Repeat("a", 400) {
		t.Fatal("clampDraft did not shorten a long draft")
	}
	if newCopilotProviderFromEnv() == nil {
		t.Fatal("provider from env must never be nil")
	}
}

// TestCopilotDraftsMarksAndTrustPostgres covers migration 097 end to end:
// drafts are rate limited per day, a sent message can carry an assisted mark,
// the message list exposes it to both members, and conversation trust reports
// verification and badges.
func TestCopilotDraftsMarksAndTrustPostgres(t *testing.T) {
	f := newFriendSocialFixture(t)
	var ready bool
	if err := f.db.QueryRow(`SELECT to_regclass('matching.copilot_drafts') IS NOT NULL`).Scan(&ready); err != nil || !ready {
		t.Skip("migration 097_conversation_trust_and_copilot is not applied")
	}
	ctx := context.Background()
	matchID := uuid.NewString()
	if _, err := f.db.ExecContext(ctx, `INSERT INTO matching.matches (id, user_id_1, user_id_2)
		VALUES ($1, LEAST($2::uuid,$3::uuid), GREATEST($2::uuid,$3::uuid))`, matchID, f.alice, f.bob); err != nil {
		t.Fatalf("seed match: %v", err)
	}
	t.Cleanup(func() { _, _ = f.db.Exec(`DELETE FROM matching.matches WHERE id=$1`, matchID) })
	server := &Server{
		store:                  &runtimeStore{profileRepo: &profileRepository{pg: f.db}},
		copilotProvider:        templateCopilot{},
		datePlanUnlockOverride: func(string) (bool, string) { return true, "conversation_unlocked" },
	}

	draft := func(userID, body string) *httptest.ResponseRecorder {
		rec := httptest.NewRecorder()
		server.draftWithCopilot(rec, datePlanRequest(http.MethodPost, "/copilot/draft", matchID, "", userID, body))
		return rec
	}
	// A stranger cannot draft into someone else's conversation.
	if rec := draft(f.stranger, `{"kind":"opener"}`); rec.Code != http.StatusForbidden {
		t.Fatalf("stranger draft status=%d body=%s", rec.Code, rec.Body.String())
	}
	if rec := draft(f.alice, `{"kind":"poem"}`); rec.Code != http.StatusBadRequest {
		t.Fatalf("bad kind status=%d", rec.Code)
	}
	first := draft(f.alice, `{"kind":"opener","tone":"playful"}`)
	if first.Code != http.StatusOK {
		t.Fatalf("draft status=%d body=%s", first.Code, first.Body.String())
	}
	var body struct {
		Draft copilotDraftView `json:"draft"`
	}
	if err := json.Unmarshal(first.Body.Bytes(), &body); err != nil {
		t.Fatal(err)
	}
	if body.Draft.ID == "" || !strings.Contains(body.Draft.Text, "Bob") || body.Draft.Remaining != copilotDailyDraftLimit-1 {
		t.Fatalf("draft view = %+v", body.Draft)
	}
	if body.Draft.Disclosure == "" {
		t.Fatal("draft must carry the disclosure")
	}
	// Daily limit.
	for i := 1; i < copilotDailyDraftLimit; i++ {
		if rec := draft(f.alice, `{"kind":"reply"}`); rec.Code != http.StatusOK {
			t.Fatalf("draft %d status=%d body=%s", i, rec.Code, rec.Body.String())
		}
	}
	if rec := draft(f.alice, `{"kind":"reply"}`); rec.Code != http.StatusTooManyRequests {
		t.Fatalf("over limit status=%d body=%s", rec.Code, rec.Body.String())
	}

	// A message sent from the draft is marked, and the list shows it.
	messageID := uuid.NewString()
	if _, err := f.db.ExecContext(ctx, `INSERT INTO matching.messages (id, match_id, sender_id, text)
		VALUES ($1,$2,$3,'Hi Bob!')`, messageID, matchID, f.alice); err != nil {
		t.Fatalf("seed message: %v", err)
	}
	t.Cleanup(func() { _, _ = f.db.Exec(`DELETE FROM matching.messages WHERE id=$1`, messageID) })
	payload := map[string]any{"sender_id": f.alice, "text": "Hi Bob!", "assist_draft_id": body.Draft.ID}
	response := map[string]any{"accepted": true, "message_id": messageID}
	server.markAssistedMessageSend(ctx, matchID, f.alice, payload, response)
	if response["composed_with_assist"] != true {
		t.Fatalf("send response not marked: %v", response)
	}
	// The mark refuses to attach to a message the sender did not write.
	svc := newCopilotService(f.db, templateCopilot{})
	if err := svc.markAssisted(ctx, matchID, messageID, f.bob, ""); err == nil {
		t.Fatal("mark for the wrong sender accepted")
	}
	list := map[string]any{"messages": []any{
		map[string]any{"id": messageID, "text": "Hi Bob!"},
		map[string]any{"id": uuid.NewString(), "text": "plain"},
	}}
	server.attachAssistMarks(ctx, matchID, list)
	items := list["messages"].([]any)
	if items[0].(map[string]any)["composed_with_assist"] != true || items[1].(map[string]any)["composed_with_assist"] != false {
		t.Fatalf("assist marks on list = %v", list)
	}
	var usedAt bool
	if err := f.db.QueryRow(`SELECT used_at IS NOT NULL FROM matching.copilot_drafts WHERE id=$1::uuid`, body.Draft.ID).Scan(&usedAt); err != nil || !usedAt {
		t.Fatalf("draft not marked used: %v %v", usedAt, err)
	}

	// Conversation trust.
	if _, err := f.db.ExecContext(ctx, `UPDATE user_management.users SET is_verified=TRUE WHERE id IN ($1,$2)`, f.alice, f.bob); err != nil {
		t.Fatalf("verify members: %v", err)
	}
	if _, err := f.db.ExecContext(ctx, `INSERT INTO matching.user_trust_badges (user_id, badge_code, status, score, awarded_at)
		VALUES ($1,'shows_up','active',100,NOW())`, f.bob); err != nil {
		t.Fatalf("seed badge: %v", err)
	}
	trust := httptest.NewRecorder()
	server.getConversationTrust(trust, datePlanRequest(http.MethodGet, "/trust", matchID, "", f.alice, ""))
	if trust.Code != http.StatusOK {
		t.Fatalf("trust status=%d body=%s", trust.Code, trust.Body.String())
	}
	var trustBody struct {
		Trust conversationTrustView `json:"trust"`
	}
	if err := json.Unmarshal(trust.Body.Bytes(), &trustBody); err != nil {
		t.Fatal(err)
	}
	if !trustBody.Trust.HumanVerified || trustBody.Trust.AssistedMessages != 1 || len(trustBody.Trust.PartnerBadges) != 1 {
		t.Fatalf("trust view = %+v", trustBody.Trust)
	}
	outsider := httptest.NewRecorder()
	server.getConversationTrust(outsider, datePlanRequest(http.MethodGet, "/trust", matchID, "", f.stranger, ""))
	if outsider.Code != http.StatusForbidden {
		t.Fatalf("outsider trust status=%d", outsider.Code)
	}
}
