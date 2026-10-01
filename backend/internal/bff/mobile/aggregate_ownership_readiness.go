package mobile

import (
	"context"
	"strings"
	"time"
)

// aggregateOwnershipState reads platform.aggregate_ownership_health (migrations
// 078 and 085) for /readyz. Every durable aggregate — including billing,
// wallet and gift state — must be registered and backed by a real table. The
// second result is false when there is no database to ask.
func (s *Server) aggregateOwnershipState(parent context.Context) (string, bool) {
	if s.store == nil || s.store.profileRepo == nil || s.store.profileRepo.pg == nil {
		return "", false
	}
	ctx, cancel := context.WithTimeout(parent, 2*time.Second)
	defer cancel()
	var missing int
	var invalid, unregistered string
	err := s.store.profileRepo.pg.QueryRowContext(ctx, `
		SELECT missing_relations, array_to_string(invalid_aggregates, ','),
		       array_to_string(unregistered_required, ',')
		FROM platform.aggregate_ownership_health`).Scan(&missing, &invalid, &unregistered)
	if err != nil {
		// Older local schemas predate the registry; only a production-like
		// environment must have it.
		if isProductionLikeEnvironment(s.cfg.Environment) {
			return "unavailable", true
		}
		return "ready", true
	}
	if missing > 0 || unregistered != "" {
		return "invalid: missing=" + invalid + " unregistered=" + unregistered, true
	}
	return "ready", true
}

func isProductionLikeEnvironment(environment string) bool {
	switch strings.ToLower(strings.TrimSpace(environment)) {
	case "prod", "production", "stage", "staging":
		return true
	}
	return false
}

// memberActivityKPIs reads the durable DAU/MAU source (migration 087). Per the
// KPI contract an unreadable source is reported unavailable, never as zero.
func (s *Server) memberActivityKPIs(parent context.Context) map[string]any {
	out := map[string]any{
		"available":  false,
		"dau_window": "trailing 24 hours",
		"mau_window": "trailing 30 days",
		"definition": "unique authenticated members (operators excluded) with an authenticated request in the window",
		"source":     "platform.member_last_activity",
	}
	if s.store == nil || s.store.profileRepo == nil || s.store.profileRepo.pg == nil {
		return out
	}
	ctx, cancel := context.WithTimeout(parent, 2*time.Second)
	defer cancel()
	var dau, mau int64
	var computed time.Time
	if err := s.store.profileRepo.pg.QueryRowContext(ctx,
		`SELECT dau, mau, computed_at FROM platform.member_activity_kpis`).Scan(&dau, &mau, &computed); err != nil {
		return out
	}
	out["available"] = true
	out["dau"] = dau
	out["mau"] = mau
	out["computed_at"] = computed.UTC().Format(time.RFC3339)
	return out
}
