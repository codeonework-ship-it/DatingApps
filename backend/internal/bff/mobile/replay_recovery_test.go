package mobile

import "testing"

func TestCursorNeedsSnapshotOnlyWhenRetentionPassedCursor(t *testing.T) {
	state := replayCursorState{PrunedThrough: 42, Latest: 80}
	for _, tc := range []struct {
		name    string
		after   int64
		expired bool
	}{
		{name: "initial sync", after: 0, expired: false},
		{name: "lost retained range", after: 41, expired: true},
		{name: "exact high water is safe", after: 42, expired: false},
		{name: "current cursor", after: 80, expired: false},
	} {
		t.Run(tc.name, func(t *testing.T) {
			if got := cursorNeedsSnapshot(tc.after, state); got != tc.expired {
				t.Fatalf("cursorNeedsSnapshot(%d)=%v, want %v", tc.after, got, tc.expired)
			}
		})
	}
}
