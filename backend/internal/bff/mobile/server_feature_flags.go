package mobile

import (
	"errors"
	"net/http"
	"strings"
)

func (s *Server) featureFlagEnforcementMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Safety reports, appeals and publication withdrawal survive feature pauses.
		path := strings.TrimPrefix(r.URL.Path, s.cfg.APIPrefix)
		if r.Method == http.MethodDelete && (strings.HasPrefix(path, "/blog/publications/") || strings.HasPrefix(path, "/blog/responses/")) {
			next.ServeHTTP(w, r)
			return
		}
		if strings.HasPrefix(path, "/blog/notices") || strings.HasPrefix(path, "/blog/reports/") || (strings.HasPrefix(path, "/blog/") && strings.HasSuffix(path, "/report")) || (r.Method == http.MethodGet && path == "/blog/publications") {
			next.ServeHTTP(w, r)
			return
		}
		// Authors can remove their posts or read their own journal during a pause.
		if strings.HasPrefix(r.URL.Path, s.cfg.APIPrefix+"/blog/posts") &&
			(r.Method == http.MethodDelete ||
				(r.Method == http.MethodGet && r.URL.Path == s.cfg.APIPrefix+"/blog/posts" && r.URL.Query().Get("scope") == "mine")) {
			next.ServeHTTP(w, r)
			return
		}
		// Members can always remove their own activity content, even while
		// Photo Themes or Clubs are paused.
		if r.Method == http.MethodDelete && (strings.HasPrefix(path, "/themes/") || strings.HasPrefix(path, "/clubs/")) {
			next.ServeHTTP(w, r)
			return
		}
		// Privacy withdrawal remains available if the creative feature is paused.
		if (r.Method == http.MethodDelete && strings.HasPrefix(r.URL.Path, s.cfg.APIPrefix+"/chapters/publications/")) ||
			(r.Method == http.MethodGet && r.URL.Path == s.cfg.APIPrefix+"/chapters/publications") {
			next.ServeHTTP(w, r)
			return
		}
		key := featureFlagForRoute(s.cfg.APIPrefix, r.URL.Path)
		if key == "" {
			next.ServeHTTP(w, r)
			return
		}
		// The release contract outranks the runtime flag: an excluded
		// capability stays off even if an operator switches its row on.
		if s.cfg.IsReleaseExcluded(key) {
			writeJSON(w, http.StatusForbidden, map[string]any{
				"success": false, "error": "feature is not part of this release",
				"error_code": "FEATURE_EXCLUDED_FROM_RELEASE", "feature_flag": key,
			})
			return
		}
		// Core capabilities default on when their row is missing; deferred
		// growth modules (migration 080) default off so a missing or
		// unapplied migration cannot expose an unaccepted workflow.
		enabled, err := s.runtimeFeatureEnabled(r.Context(), key, !defaultOffFeatureFlags[key])
		if err != nil {
			writeJSON(w, http.StatusServiceUnavailable, map[string]any{
				"success": false, "error": "feature policy is unavailable",
				"error_code": "FEATURE_POLICY_UNAVAILABLE", "feature_flag": key,
			})
			return
		}
		if !enabled {
			writeJSON(w, http.StatusForbidden, map[string]any{
				"success": false, "error": errors.New("feature is disabled by runtime policy").Error(),
				"error_code": "FEATURE_DISABLED", "feature_flag": key,
			})
			return
		}
		next.ServeHTTP(w, r)
	})
}

// defaultOffFeatureFlags are the deferred-portfolio switches (migration 080).
var defaultOffFeatureFlags = map[string]bool{
	"city_pilot_enabled":            true,
	"support_ticketing_enabled":     true,
	"referrals_enabled":             true,
	"growth_events_enabled":         true,
	"partnerships_enabled":          true,
	"social_imports_enabled":        true,
	"member_history_enabled":        true,
	"recommendation_graph_enabled":  true,
	"fraud_graph_enabled":           true,
	"admirer_gifts_enabled":         true,
	"expanded_gift_economy_enabled": true,
	"paid_xp_enabled":               true,
}

func featureFlagForRoute(apiPrefix, requestPath string) string {
	path := strings.TrimPrefix(requestPath, strings.TrimSuffix(apiPrefix, "/"))
	path = strings.TrimPrefix(path, "/")
	if path == "" || strings.HasPrefix(path, "admin/") || strings.HasPrefix(path, "config/") {
		return ""
	}
	switch {
	case path == "themes" || strings.HasPrefix(path, "themes/"):
		return "photo_themes_enabled"
	case path == "clubs" || strings.HasPrefix(path, "clubs/"):
		return "clubs_enabled"
	case strings.HasPrefix(path, "blog/"):
		return "intentional_dating_enabled"
	case strings.HasPrefix(path, "chapters/") || (strings.HasPrefix(path, "matches/") && strings.Contains(path, "/chapter")):
		return "intentional_dating_enabled"
	case path == "chat/gifts" || (strings.HasPrefix(path, "chat/") && strings.Contains(path, "/gifts/")):
		return "gifts_enabled"
	case (strings.HasPrefix(path, "matches/") && strings.HasSuffix(path, "/voice-introductions")) || strings.HasPrefix(path, "engagement/voice-icebreakers/") || strings.HasPrefix(path, "media/voice/"):
		return "voice_icebreakers_enabled"
	case path == "rooms" || strings.HasPrefix(path, "rooms/"):
		return "rooms_enabled"
	case strings.HasPrefix(path, "social/"):
		return "social_chat_enabled"
	case strings.HasPrefix(path, "calls/"):
		return "calls_enabled"
	case strings.HasPrefix(path, "billing/"):
		return "billing_enabled"
	case strings.HasPrefix(path, "wallet/") && strings.HasSuffix(path, "/coins/buy"):
		// A coin purchase is billing; balance and audit reads stay available.
		return "billing_enabled"
	case strings.HasPrefix(path, "verification/") && strings.HasSuffix(path, "/submit"):
		return "identity_verification_enabled"
	case strings.HasPrefix(path, "engagement/daily-prompt/"):
		return "daily_prompts_enabled"
	case strings.HasPrefix(path, "engagement/circles/"):
		return "circles_enabled"
	case strings.HasPrefix(path, "engagement/match-nudges/"):
		return "match_nudges_enabled"
	case strings.HasPrefix(path, "engagement/group-coffee-polls"):
		return "group_coffee_polls_enabled"
	case path == "engagement/groups" || strings.HasPrefix(path, "engagement/groups/") ||
		path == "engagement/group-invites" || path == "engagement/group-categories" || path == "engagement/group-friends":
		return "groups_enabled"
	case strings.HasPrefix(path, "safety/sos"):
		return "safety_sos_enabled"
	case strings.HasPrefix(path, "matches/") &&
		(strings.Contains(path, "/quest-template") || strings.Contains(path, "/quests") ||
			strings.Contains(path, "/quest-workflow") || strings.HasSuffix(path, "/unlock-requirements")):
		return "quest_workflow_v2_enabled"
	case (strings.HasPrefix(path, "profile/") && strings.HasSuffix(path, "/stories")) ||
		(strings.HasPrefix(path, "account/") && strings.HasSuffix(path, "/dating-preferences")) ||
		(strings.HasPrefix(path, "matches/") && (strings.HasSuffix(path, "/connection") || strings.Contains(path, "/moments"))):
		return "intentional_dating_enabled"
	case (strings.HasPrefix(path, "friends/") && (strings.Contains(path, "/vouches") || strings.Contains(path, "/intros"))) ||
		(strings.HasPrefix(path, "users/") && strings.HasSuffix(path, "/vouches")):
		return "friend_intros_enabled"
	case strings.HasPrefix(path, "matches/") && strings.Contains(path, "/copilot"):
		return "copilot_enabled"
	case strings.HasPrefix(path, "plans/") ||
		(strings.HasPrefix(path, "matches/") && strings.Contains(path, "/plans")) ||
		(strings.HasPrefix(path, "friends/") && strings.HasSuffix(path, "/plans")):
		return "date_plans_enabled"
	case (strings.HasPrefix(path, "matches/") && strings.Contains(path, "/graduation")) ||
		(strings.HasPrefix(path, "account/") && strings.Contains(path, "/discovery")):
		return "graduation_enabled"
	case strings.HasPrefix(path, "discovery/") && strings.HasSuffix(path, "/today"):
		return "curated_daily_set_enabled"
	case strings.HasPrefix(path, "matches/") && strings.Contains(path, "/gestures"):
		return "digital_gestures_enabled"
	case strings.HasPrefix(path, "progression/"):
		return "level_progression_enabled"
	case path == "support/tickets" || strings.HasPrefix(path, "support/tickets/"):
		return "support_ticketing_enabled"
	case strings.HasPrefix(path, "growth/referrals"):
		return "referrals_enabled"
	case strings.HasPrefix(path, "growth/events"):
		return "growth_events_enabled"
	case strings.HasPrefix(path, "growth/partnerships"):
		return "partnerships_enabled"
	case strings.HasPrefix(path, "growth/imports"):
		return "social_imports_enabled"
	case strings.HasPrefix(path, "growth/history"):
		return "member_history_enabled"
	case strings.HasPrefix(path, "growth/recommendations"):
		return "recommendation_graph_enabled"
	case strings.HasPrefix(path, "growth/admirer-gifts"):
		return "admirer_gifts_enabled"
	case strings.HasPrefix(path, "growth/paid-xp"):
		return "paid_xp_enabled"
	default:
		return ""
	}
}
