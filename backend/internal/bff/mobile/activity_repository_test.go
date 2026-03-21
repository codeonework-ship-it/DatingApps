package mobile

import "testing"

func TestMapActivityEventRow_MapsReportingPayload(t *testing.T) {
	row := map[string]any{
		"id":            "evt-1",
		"event_name":    "daily_prompt_answer_submitted",
		"user_id":       "11111111-1111-1111-1111-111111111111",
		"actor_user_id": "22222222-2222-2222-2222-222222222222",
		"created_at":    "2026-03-21T12:00:00Z",
		"payload": map[string]any{
			"status":   "success",
			"resource": "/engagement/daily-prompt/11111111-1111-1111-1111-111111111111/answer",
			"details": map[string]any{
				"prompt_id": "prompt-2026-03-21",
				"match_id":  "33333333-3333-3333-3333-333333333333",
			},
		},
	}

	event := mapActivityEventRow(row)
	if event.ID != "evt-1" {
		t.Fatalf("expected id evt-1, got %q", event.ID)
	}
	if event.Action != "daily_prompt_answer_submitted" {
		t.Fatalf("expected action daily_prompt_answer_submitted, got %q", event.Action)
	}
	if event.Actor != "22222222-2222-2222-2222-222222222222" {
		t.Fatalf("expected actor from actor_user_id, got %q", event.Actor)
	}
	if event.Resource != "/engagement/daily-prompt/11111111-1111-1111-1111-111111111111/answer" {
		t.Fatalf("expected resource to be mapped from payload")
	}
	if event.Status != "success" {
		t.Fatalf("expected status success, got %q", event.Status)
	}
	if event.Details["prompt_id"] != "prompt-2026-03-21" {
		t.Fatalf("expected details.prompt_id to round-trip")
	}
}

func TestMapActivityEventRow_FallsBackToPayloadActor(t *testing.T) {
	row := map[string]any{
		"id":         "evt-2",
		"event_name": "match_nudge_sent",
		"user_id":    "11111111-1111-1111-1111-111111111111",
		"created_at": "2026-03-21T12:10:00Z",
		"payload": map[string]any{
			"status": "success",
			"actor":  "system",
		},
	}

	event := mapActivityEventRow(row)
	if event.Actor != "system" {
		t.Fatalf("expected actor fallback from payload.actor, got %q", event.Actor)
	}
}

func TestNullableEventUUID_ValidatesUUIDFormat(t *testing.T) {
	if value := nullableEventUUID(""); value != nil {
		t.Fatalf("expected nil for empty uuid")
	}
	if value := nullableEventUUID("not-a-uuid"); value != nil {
		t.Fatalf("expected nil for invalid uuid")
	}
	valid := "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"
	if value := nullableEventUUID(valid); value != "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa" {
		t.Fatalf("expected lowercased valid uuid, got %#v", value)
	}
}
