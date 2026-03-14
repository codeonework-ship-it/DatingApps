package mobile

import "testing"

func TestIsHealthyConnState(t *testing.T) {
	tests := []struct {
		name     string
		state    string
		expected bool
	}{
		{name: "ready", state: "READY", expected: true},
		{name: "idle", state: "IDLE", expected: true},
		{name: "connecting", state: "CONNECTING", expected: true},
		{name: "transient failure", state: "TRANSIENT_FAILURE", expected: false},
		{name: "shutdown", state: "SHUTDOWN", expected: false},
		{name: "unknown", state: "UNKNOWN", expected: false},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			if got := isHealthyConnState(tc.state); got != tc.expected {
				t.Fatalf("isHealthyConnState(%q) = %v, want %v", tc.state, got, tc.expected)
			}
		})
	}
}
