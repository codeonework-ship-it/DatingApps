package mobile

import (
	"net/http"
	"sync"
	"testing"
)

// API-09: two members tapping "Add friend" on each other at the same moment
// deadlocked. Each request locked its own users row FOR UPDATE
// (lockBlogAuthor), then the pair lock; the first inserted its pending row,
// whose foreign key needs FOR KEY SHARE on the other member's users row — held
// FOR UPDATE by the second request, which was waiting on the pair lock. One of
// the two failed (lock timeout -> 503 live, or "deadlock detected").
func TestCrossingFriendRequestsBecomeOneFriendshipPostgres(t *testing.T) {
	f, s := newFriendFixture(t)
	pairs := [][2]string{
		{f.stranger, f.groupMate},
		{f.proposerFriend, f.inviteeFriend},
		{f.stranger, f.proposerFriend},
	}
	for _, pair := range pairs {
		a, b := pair[0], pair[1]
		var wg sync.WaitGroup
		start := make(chan struct{})
		codes := make([]int, 2)
		bodies := make([]map[string]any, 2)
		for i, from := range []string{a, b} {
			to := b
			if from == b {
				to = a
			}
			wg.Add(1)
			go func(i int, from, to string) {
				defer wg.Done()
				<-start
				codes[i], bodies[i] = friendRequestPG(t, s, from, to, "search")
			}(i, from, to)
		}
		close(start)
		wg.Wait()
		for i := range codes {
			if codes[i] != http.StatusOK {
				t.Fatalf("crossing requests %s<->%s: request %d -> %d %v", a, b, i, codes[i], bodies[i])
			}
		}
		rows := friendRows(t, f, a, b)
		if rows[a] != "accepted:search" || rows[b] != "accepted:search" {
			t.Fatalf("crossing requests must end as one accepted friendship, got %v", rows)
		}
	}
}
