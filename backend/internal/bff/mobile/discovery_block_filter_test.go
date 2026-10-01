package mobile

import (
	"context"
	"errors"
	"net/url"
	"testing"

	"github.com/verified-dating/backend/internal/platform/config"
)

// blockedUsersDB serves only the blocked_users reads this filter performs.
type blockedUsersDB struct {
	read func(params url.Values) ([]map[string]any, error)
}

func (d *blockedUsersDB) SelectRead(
	_ context.Context, _, table string, params url.Values,
) ([]map[string]any, error) {
	if table != "blocked_users" {
		return nil, nil
	}
	return d.read(params)
}

func (d *blockedUsersDB) Select(
	ctx context.Context, schema, table string, params url.Values,
) ([]map[string]any, error) {
	return d.SelectRead(ctx, schema, table, params)
}

func (d *blockedUsersDB) Insert(
	context.Context, string, string, any,
) ([]map[string]any, error) {
	return nil, nil
}

func (d *blockedUsersDB) Upsert(
	context.Context, string, string, any, string,
) ([]map[string]any, error) {
	return nil, nil
}

func (d *blockedUsersDB) Update(
	context.Context, string, string, any, url.Values,
) ([]map[string]any, error) {
	return nil, nil
}

func (d *blockedUsersDB) Delete(
	context.Context, string, string, url.Values,
) ([]map[string]any, error) {
	return nil, nil
}

func blockFilterServer(
	t *testing.T,
	selectRead func(url.Values) ([]map[string]any, error),
) *Server {
	t.Helper()
	return &Server{
		store: &runtimeStore{
			profileRepo: &profileRepository{
				cfg: config.Config{UserSchema: "user_management"},
				db:  &blockedUsersDB{read: selectRead},
			},
		},
	}
}

func candidateIDs(t *testing.T, resp map[string]any) []string {
	t.Helper()
	rows, ok := resp["candidates"].([]any)
	if !ok {
		t.Fatalf("candidates missing or wrong type: %#v", resp["candidates"])
	}
	out := make([]string, 0, len(rows))
	for _, raw := range rows {
		row, _ := raw.(map[string]any)
		out = append(out, toString(row["id"]))
	}
	return out
}

// TestAttachBlockedFilteredDiscovery_RemovesBothDirections guards SAFE-002:
// blocking must apply to discovery, symmetrically.
func TestAttachBlockedFilteredDiscovery_RemovesBothDirections(t *testing.T) {
	server := blockFilterServer(t, func(params url.Values) ([]map[string]any, error) {
		switch {
		// Members this viewer blocked.
		case params.Get("user_id") == "eq.viewer":
			return []map[string]any{{"blocked_user_id": "i-blocked-them"}}, nil
		// Members who blocked this viewer.
		case params.Get("blocked_user_id") == "eq.viewer":
			return []map[string]any{{"user_id": "they-blocked-me"}}, nil
		}
		return nil, nil
	})

	resp := map[string]any{"candidates": []any{
		map[string]any{"id": "ordinary"},
		map[string]any{"id": "i-blocked-them"},
		map[string]any{"id": "they-blocked-me"},
	}}

	server.attachBlockedFilteredDiscovery(context.Background(), resp, "viewer")

	got := candidateIDs(t, resp)
	if len(got) != 1 || got[0] != "ordinary" {
		t.Fatalf(
			"discovery must drop blocks in both directions; kept %v. A member "+
				"who blocked someone must not be dealt their card, and must "+
				"not be dealt to them either.",
			got,
		)
	}
	summary, _ := resp["blocked_filter"].(map[string]any)
	if summary["applied"] != true || summary["filtered"] != 2 {
		t.Fatalf("expected an applied summary reporting 2 removals, got %#v", summary)
	}
}

// TestAttachBlockedFilteredDiscovery_FailsClosed checks the deck empties when
// the block list cannot be read, rather than being served unfiltered.
func TestAttachBlockedFilteredDiscovery_FailsClosed(t *testing.T) {
	server := blockFilterServer(t, func(url.Values) ([]map[string]any, error) {
		return nil, errors.New("blocked_users unavailable")
	})

	resp := map[string]any{"candidates": []any{
		map[string]any{"id": "ordinary"},
		map[string]any{"id": "another"},
	}}

	server.attachBlockedFilteredDiscovery(context.Background(), resp, "viewer")

	if got := candidateIDs(t, resp); len(got) != 0 {
		t.Fatalf(
			"an unreadable block list must empty the deck rather than serve it "+
				"unfiltered; kept %v",
			got,
		)
	}
	summary, _ := resp["blocked_filter"].(map[string]any)
	if summary["applied"] != false {
		t.Fatalf("expected the summary to record that the filter did not apply, got %#v", summary)
	}
}

// TestAttachBlockedFilteredDiscovery_NoBlocksLeavesDeckIntact ensures the
// common case is untouched.
func TestAttachBlockedFilteredDiscovery_NoBlocksLeavesDeckIntact(t *testing.T) {
	server := blockFilterServer(t, func(url.Values) ([]map[string]any, error) {
		return nil, nil
	})

	resp := map[string]any{"candidates": []any{
		map[string]any{"id": "a"},
		map[string]any{"id": "b"},
	}}

	server.attachBlockedFilteredDiscovery(context.Background(), resp, "viewer")

	if got := candidateIDs(t, resp); len(got) != 2 {
		t.Fatalf("expected both candidates retained, got %v", got)
	}
}
