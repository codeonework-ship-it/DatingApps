package mobile

import (
	"strings"
	"testing"
)

func TestEventFilterSQLUsesBoundArguments(t *testing.T) {
	malicious := "matching.messages.created' OR TRUE --"
	where, args := eventFilterSQL(map[string][]string{
		"event_name":     {malicious},
		"aggregate_type": {"matching.messages"},
		"after_sequence": {"42"},
	})
	if strings.Contains(where, malicious) {
		t.Fatal("event filter interpolated caller input")
	}
	if where != "TRUE AND event_name = $1 AND aggregate_type = $2 AND sequence_id > $3" {
		t.Fatalf("unexpected event filter: %s", where)
	}
	if len(args) != 3 || args[0] != malicious || args[1] != "matching.messages" || args[2] != int64(42) {
		t.Fatalf("unexpected event filter arguments: %#v", args)
	}
}
