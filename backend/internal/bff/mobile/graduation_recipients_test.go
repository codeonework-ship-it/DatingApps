package mobile

import (
	"testing"
)

// TestGraduationShareRecipientsFollowFriendSharingRulesPostgres guards GO-01:
// migration 099 stubbed the shared date-plan recipient function, which
// silently stopped graduation fan-out. Graduation now has its own recipient
// function (migration 128): the member's accepted friends, never the partner,
// never a blocked pair, never an inactive account. The date-plan function stays
// fail-closed.
func TestGraduationShareRecipientsFollowFriendSharingRulesPostgres(t *testing.T) {
	f := newGraduationFixture(t)
	var ready bool
	if err := f.db.QueryRow(`SELECT to_regprocedure('matching.graduation_share_recipients(uuid,uuid)') IS NOT NULL`).Scan(&ready); err != nil {
		t.Fatal(err)
	}
	if !ready {
		t.Skip("migration 128_graduation_friend_recipients is not applied")
	}

	recipients := func(member, partner string) []string {
		t.Helper()
		rows, err := f.db.Query(`SELECT recipient_user_id::text FROM matching.graduation_share_recipients($1,$2) ORDER BY 1`, member, partner)
		if err != nil {
			t.Fatal(err)
		}
		defer rows.Close()
		var out []string
		for rows.Next() {
			var id string
			if err := rows.Scan(&id); err != nil {
				t.Fatal(err)
			}
			out = append(out, id)
		}
		return out
	}

	if got := recipients(f.proposer, f.partner); len(got) != 1 || got[0] != f.proposerFriend {
		t.Fatalf("proposer recipients=%v, want only %s", got, f.proposerFriend)
	}

	// The partner is never told, even when also a friend.
	if _, err := f.db.Exec(`INSERT INTO matching.friend_connections (user_id, friend_user_id, status)
		VALUES ($1,$2,'accepted'),($2,$1,'accepted')`, f.proposer, f.partner); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		_, _ = f.db.Exec(`DELETE FROM matching.friend_connections WHERE (user_id=$1 AND friend_user_id=$2) OR (user_id=$2 AND friend_user_id=$1)`, f.proposer, f.partner)
	})
	if got := recipients(f.proposer, f.partner); len(got) != 1 || got[0] != f.proposerFriend {
		t.Fatalf("partner leaked into recipients: %v", got)
	}

	// A pending (not yet accepted) request is not a friendship.
	if _, err := f.db.Exec(`INSERT INTO matching.friend_connections (user_id, friend_user_id, status)
		VALUES ($1,$2,'pending')`, f.proposer, f.stranger); err != nil {
		t.Fatal(err)
	}
	if got := recipients(f.proposer, f.partner); len(got) != 1 {
		t.Fatalf("pending request counted as a friend: %v", got)
	}

	// A block in either direction removes the friend.
	if _, err := f.db.Exec(`INSERT INTO user_management.blocked_users (user_id, blocked_user_id) VALUES ($1,$2)`, f.proposerFriend, f.proposer); err != nil {
		t.Fatal(err)
	}
	if got := recipients(f.proposer, f.partner); len(got) != 0 {
		t.Fatalf("blocked friend still a recipient: %v", got)
	}
	if _, err := f.db.Exec(`DELETE FROM user_management.blocked_users WHERE user_id=$1 AND blocked_user_id=$2`, f.proposerFriend, f.proposer); err != nil {
		t.Fatal(err)
	}

	// An inactive account is not told.
	if _, err := f.db.Exec(`UPDATE user_management.users SET is_active=FALSE WHERE id=$1`, f.proposerFriend); err != nil {
		t.Fatal(err)
	}
	if got := recipients(f.proposer, f.partner); len(got) != 0 {
		t.Fatalf("inactive friend still a recipient: %v", got)
	}

	// Date plans stay private by default (099): the legacy shared function is
	// still fail-closed.
	var legacy int
	if err := f.db.QueryRow(`SELECT COUNT(*) FROM matching.date_plan_share_recipients($1,$2,'{}'::uuid[])`, f.partner, f.proposer).Scan(&legacy); err != nil {
		t.Fatal(err)
	}
	if legacy != 0 {
		t.Fatalf("date_plan_share_recipients is no longer fail-closed: %d", legacy)
	}
}
