package mobile

import (
	"reflect"
	"testing"
)

func TestXPAwardRepairPayloadRoundTrip(t *testing.T) {
	input := xpAwardInput{
		UserID: "user-1", Source: "mini_activity_completed", SourceEventID: "session-1",
		IdempotencyKey: "mini_activity_completed:session-1:user-1", ActorType: "system",
		Metadata: map[string]any{"match_id": "match-1"},
	}
	if got := newXPAwardRepairPayload(input).awardInput(); !reflect.DeepEqual(got, input) {
		t.Fatalf("repair payload changed command: got=%#v want=%#v", got, input)
	}
}
