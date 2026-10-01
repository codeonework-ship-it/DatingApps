package mobile

import (
	"context"
	"net/url"
	"strings"
)

// attachBlockedFilteredDiscovery removes blocked members from a discovery deck.
//
// SAFE-002 requires blocking to apply to discovery, but the exclusion set built
// while assembling candidates covered only self, already-swiped and already-
// matched members. The single-profile read has always excluded blocks in both
// directions; discovery did not, so a member could block someone and still be
// dealt their card — and be dealt to them in turn.
//
// Blocking is symmetric here for the same reason it is symmetric in the profile
// read: the blocking member must not see the blocked one, and the blocked one
// must not be handed a route back to the person who blocked them.
//
// A failure to resolve the block list removes the whole deck rather than
// serving an unfiltered one. Discovery degrading to empty is recoverable; the
// safety rule being silently skipped is not.
func (s *Server) attachBlockedFilteredDiscovery(
	ctx context.Context,
	resp map[string]any,
	userID string,
) {
	rows, ok := resp["candidates"].([]any)
	if !ok || len(rows) == 0 {
		return
	}
	blocked, err := s.blockedCounterpartIDs(ctx, userID)
	if err != nil {
		resp["candidates"] = []any{}
		resp["blocked_filter"] = map[string]any{
			"applied":  false,
			"error":    "blocked list unavailable",
			"filtered": len(rows),
		}
		return
	}
	if len(blocked) == 0 {
		return
	}

	kept := make([]any, 0, len(rows))
	for _, raw := range rows {
		row, isMap := raw.(map[string]any)
		if !isMap {
			kept = append(kept, raw)
			continue
		}
		if _, hidden := blocked[candidateIdentity(row)]; hidden {
			continue
		}
		kept = append(kept, raw)
	}
	resp["candidates"] = kept
	resp["blocked_filter"] = map[string]any{
		"applied":  true,
		"filtered": len(rows) - len(kept),
	}
}

// candidateIdentity reads whichever id spelling the candidate row carries.
func candidateIdentity(row map[string]any) string {
	for _, key := range []string{"id", "user_id", "userId"} {
		if value := strings.TrimSpace(toString(row[key])); value != "" && value != "<nil>" {
			return value
		}
	}
	return ""
}

// blockedCounterpartIDs returns every member on either side of a block with the
// given user.
func (s *Server) blockedCounterpartIDs(
	ctx context.Context,
	userID string,
) (map[string]struct{}, error) {
	trimmed := strings.TrimSpace(userID)
	blocked := map[string]struct{}{}
	if trimmed == "" || s.store == nil || s.store.profileRepo == nil {
		return blocked, nil
	}
	repo := s.store.profileRepo

	// Two reads rather than one OR: the filter API cannot express a disjunction
	// across different columns.
	directions := []struct{ match, collect string }{
		{match: "user_id", collect: "blocked_user_id"},
		{match: "blocked_user_id", collect: "user_id"},
	}
	for _, direction := range directions {
		params := url.Values{}
		params.Set(direction.match, "eq."+trimmed)
		params.Set("select", direction.collect)
		rows, err := repo.db.SelectRead(ctx, repo.cfg.UserSchema, "blocked_users", params)
		if err != nil {
			return nil, err
		}
		for _, row := range rows {
			id := strings.TrimSpace(toString(row[direction.collect]))
			if id != "" && id != "<nil>" {
				blocked[id] = struct{}{}
			}
		}
	}
	return blocked, nil
}
