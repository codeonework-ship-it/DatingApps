package mobile

import (
	"context"
	"errors"
	"fmt"
	"net/url"
	"sort"
	"strings"
	"time"

	"github.com/verified-dating/backend/internal/platform/config"
	"github.com/verified-dating/backend/internal/platform/supabase"
)

type socialRepository struct {
	cfg config.Config
	db  *supabase.Client
}

func newSocialRepository(cfg config.Config) *socialRepository {
	apiKey := strings.TrimSpace(cfg.SupabaseServiceRole)
	if apiKey == "" {
		apiKey = strings.TrimSpace(cfg.SupabaseAnonKey)
	}
	if strings.TrimSpace(cfg.SupabaseURL) == "" || apiKey == "" {
		return nil
	}
	client := supabase.NewClient(
		cfg.SupabaseURL,
		cfg.SupabaseAnonKey,
		cfg.SupabaseServiceRole,
		time.Duration(cfg.SupabaseHTTPTimeoutSec)*time.Second,
	)
	client.SetReadBaseURL(cfg.SupabaseReadReplicaURL)
	return &socialRepository{cfg: cfg, db: client}
}

func isSocialRepoPersistenceUnavailable(err error) bool {
	if err == nil {
		return false
	}
	msg := strings.ToLower(err.Error())
	return strings.Contains(msg, "pgrst106") ||
		strings.Contains(msg, "pgrst205") ||
		strings.Contains(msg, "invalid schema") ||
		strings.Contains(msg, "could not find the table")
}

func (r *socialRepository) listFriends(ctx context.Context, userID string) ([]friendConnection, error) {
	trimmedUserID := strings.TrimSpace(userID)
	if trimmedUserID == "" {
		return nil, errors.New("user_id is required")
	}

	params := url.Values{}
	params.Set("user_id", "eq."+trimmedUserID)
	params.Set("status", "eq.accepted")
	params.Set("order", "updated_at.desc")
	params.Set("select", "user_id,friend_user_id,status,created_at,updated_at")
	rows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, "friend_connections", params)
	if err != nil {
		return nil, err
	}

	friendIDs := make([]string, 0, len(rows))
	for _, row := range rows {
		friendID := strings.TrimSpace(toString(row["friend_user_id"]))
		if friendID != "" {
			friendIDs = append(friendIDs, friendID)
		}
	}
	nameByID, err := r.loadUserNames(ctx, friendIDs)
	if err != nil {
		return nil, err
	}

	out := make([]friendConnection, 0, len(rows))
	for _, row := range rows {
		friendID := strings.TrimSpace(toString(row["friend_user_id"]))
		name := strings.TrimSpace(nameByID[friendID])
		if name == "" {
			name = "Friend"
		}
		out = append(out, friendConnection{
			UserID:     strings.TrimSpace(toString(row["user_id"])),
			FriendID:   friendID,
			Status:     strings.TrimSpace(toString(row["status"])),
			CreatedAt:  normalizeTimestampString(row["created_at"]),
			UpdatedAt:  normalizeTimestampString(row["updated_at"]),
			FriendName: name,
		})
	}
	return out, nil
}

func (r *socialRepository) addFriend(ctx context.Context, userID, friendUserID string, now time.Time) (friendConnection, error) {
	trimmedUserID := strings.TrimSpace(userID)
	trimmedFriendID := strings.TrimSpace(friendUserID)
	if trimmedUserID == "" || trimmedFriendID == "" {
		return friendConnection{}, errors.New("user_id and friend_user_id are required")
	}
	if trimmedUserID == trimmedFriendID {
		return friendConnection{}, errors.New("cannot add yourself as friend")
	}

	nowISO := now.UTC().Format(time.RFC3339)
	pair := []map[string]any{
		{
			"user_id":        trimmedUserID,
			"friend_user_id": trimmedFriendID,
			"status":         "accepted",
			"created_at":     nowISO,
			"updated_at":     nowISO,
		},
		{
			"user_id":        trimmedFriendID,
			"friend_user_id": trimmedUserID,
			"status":         "accepted",
			"created_at":     nowISO,
			"updated_at":     nowISO,
		},
	}
	if _, err := r.db.Upsert(ctx, r.cfg.MatchingSchema, "friend_connections", pair, "user_id,friend_user_id"); err != nil {
		return friendConnection{}, err
	}

	friendNames, err := r.loadUserNames(ctx, []string{trimmedFriendID})
	if err != nil {
		return friendConnection{}, err
	}

	if _, err := r.db.Insert(ctx, r.cfg.MatchingSchema, "friend_activity_feed", []map[string]any{{
		"user_id":        trimmedUserID,
		"friend_user_id": trimmedFriendID,
		"activity_type":  "friend_connected",
		"title":          "New Friend Added",
		"description":    "You can now join friend activities together.",
		"metadata":       map[string]any{},
		"created_at":     nowISO,
	}}); err != nil {
		return friendConnection{}, err
	}

	friendName := strings.TrimSpace(friendNames[trimmedFriendID])
	if friendName == "" {
		friendName = "Friend"
	}

	return friendConnection{
		UserID:     trimmedUserID,
		FriendID:   trimmedFriendID,
		Status:     "accepted",
		CreatedAt:  nowISO,
		UpdatedAt:  nowISO,
		FriendName: friendName,
	}, nil
}

func (r *socialRepository) removeFriend(ctx context.Context, userID, friendUserID string) error {
	trimmedUserID := strings.TrimSpace(userID)
	trimmedFriendID := strings.TrimSpace(friendUserID)
	if trimmedUserID == "" || trimmedFriendID == "" {
		return errors.New("user id and friend user id are required")
	}

	first := url.Values{}
	first.Set("user_id", "eq."+trimmedUserID)
	first.Set("friend_user_id", "eq."+trimmedFriendID)
	if _, err := r.db.Delete(ctx, r.cfg.MatchingSchema, "friend_connections", first); err != nil {
		return err
	}

	second := url.Values{}
	second.Set("user_id", "eq."+trimmedFriendID)
	second.Set("friend_user_id", "eq."+trimmedUserID)
	_, err := r.db.Delete(ctx, r.cfg.MatchingSchema, "friend_connections", second)
	return err
}

func (r *socialRepository) listFriendActivities(ctx context.Context, userID string, limit int) ([]friendActivity, error) {
	trimmedUserID := strings.TrimSpace(userID)
	if trimmedUserID == "" {
		return nil, errors.New("user id is required")
	}
	if limit <= 0 || limit > 100 {
		limit = 20
	}

	params := url.Values{}
	params.Set("user_id", "eq."+trimmedUserID)
	params.Set("order", "created_at.desc")
	params.Set("limit", fmt.Sprintf("%d", limit))
	params.Set("select", "id,user_id,friend_user_id,activity_type,title,description,created_at")
	rows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, "friend_activity_feed", params)
	if err != nil {
		return nil, err
	}

	items := make([]friendActivity, 0, len(rows))
	for _, row := range rows {
		items = append(items, friendActivity{
			ID:          strings.TrimSpace(toString(row["id"])),
			UserID:      strings.TrimSpace(toString(row["user_id"])),
			FriendID:    strings.TrimSpace(toString(row["friend_user_id"])),
			Type:        strings.TrimSpace(toString(row["activity_type"])),
			Title:       strings.TrimSpace(toString(row["title"])),
			Description: strings.TrimSpace(toString(row["description"])),
			CreatedAt:   normalizeTimestampString(row["created_at"]),
		})
	}
	return items, nil
}

func (r *socialRepository) sendMatchNudge(
	ctx context.Context,
	matchID,
	userID,
	counterpartyUserID,
	nudgeType string,
	now time.Time,
) (matchNudge, error) {
	trimmedMatchID := strings.TrimSpace(matchID)
	trimmedUserID := strings.TrimSpace(userID)
	trimmedCounterparty := strings.TrimSpace(counterpartyUserID)
	trimmedNudgeType := strings.ToLower(strings.TrimSpace(nudgeType))

	if trimmedMatchID == "" || trimmedUserID == "" || trimmedCounterparty == "" {
		return matchNudge{}, errors.New("match_id, user_id, and counterparty_user_id are required")
	}
	if trimmedNudgeType == "" {
		trimmedNudgeType = "stalled_24h"
	}

	suppressed, err := r.isNudgeSuppressedBySafety(ctx, trimmedUserID, trimmedCounterparty, now.UTC())
	if err != nil {
		return matchNudge{}, err
	}
	if suppressed {
		return matchNudge{}, errors.New("match nudge suppressed due to safety state")
	}

	todayStart := now.UTC().Truncate(24 * time.Hour).Format(time.RFC3339)
	capParams := url.Values{}
	capParams.Set("user_id", "eq."+trimmedUserID)
	capParams.Set("created_at", "gte."+todayStart)
	capParams.Set("select", "id")
	capRows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, "match_nudges", capParams)
	if err != nil {
		return matchNudge{}, err
	}
	if len(capRows) >= matchNudgeDailyCap {
		return matchNudge{}, errors.New("daily nudge cap reached")
	}

	rows, err := r.db.Insert(ctx, r.cfg.MatchingSchema, "match_nudges", []map[string]any{{
		"match_id":             trimmedMatchID,
		"user_id":              trimmedUserID,
		"counterparty_user_id": trimmedCounterparty,
		"nudge_type":           trimmedNudgeType,
		"status":               "sent",
		"created_at":           now.UTC().Format(time.RFC3339),
		"metadata":             map[string]any{},
	}})
	if err != nil {
		return matchNudge{}, err
	}
	if len(rows) == 0 {
		return matchNudge{}, errors.New("match nudge persistence returned empty result")
	}
	return mapMatchNudgeRow(rows[0]), nil
}

func (r *socialRepository) markMatchNudgeClicked(ctx context.Context, nudgeID, userID string, now time.Time) (matchNudge, error) {
	trimmedNudgeID := strings.TrimSpace(nudgeID)
	trimmedUserID := strings.TrimSpace(userID)
	if trimmedNudgeID == "" || trimmedUserID == "" {
		return matchNudge{}, errors.New("nudge id and user_id are required")
	}

	existing, err := r.getMatchNudgeByID(ctx, trimmedNudgeID)
	if err != nil {
		return matchNudge{}, err
	}
	if strings.TrimSpace(existing.ID) == "" {
		return matchNudge{}, errors.New("nudge not found")
	}
	if existing.UserID != trimmedUserID {
		return matchNudge{}, errors.New("nudge does not belong to user")
	}

	if strings.TrimSpace(existing.ClickedAt) == "" {
		filters := url.Values{}
		filters.Set("id", "eq."+trimmedNudgeID)
		rows, updateErr := r.db.Update(ctx, r.cfg.MatchingSchema, "match_nudges", map[string]any{
			"status":     "clicked",
			"clicked_at": now.UTC().Format(time.RFC3339),
		}, filters)
		if updateErr != nil {
			return matchNudge{}, updateErr
		}
		if len(rows) > 0 {
			existing = mapMatchNudgeRow(rows[0])
		}
	}

	return existing, nil
}

func (r *socialRepository) markConversationResumed(
	ctx context.Context,
	matchID,
	userID,
	triggerNudgeID string,
	now time.Time,
) (conversationResumed, error) {
	trimmedMatchID := strings.TrimSpace(matchID)
	trimmedUserID := strings.TrimSpace(userID)
	trimmedTrigger := strings.TrimSpace(triggerNudgeID)
	if trimmedMatchID == "" || trimmedUserID == "" {
		return conversationResumed{}, errors.New("match_id and user_id are required")
	}

	if trimmedTrigger != "" {
		nudge, err := r.getMatchNudgeByID(ctx, trimmedTrigger)
		if err != nil {
			return conversationResumed{}, err
		}
		if strings.TrimSpace(nudge.ID) == "" || nudge.MatchID != trimmedMatchID || nudge.UserID != trimmedUserID {
			return conversationResumed{}, errors.New("trigger_nudge_id is invalid for match/user")
		}
	}

	payload := map[string]any{
		"match_id":   trimmedMatchID,
		"user_id":    trimmedUserID,
		"resumed_at": now.UTC().Format(time.RFC3339),
		"metadata":   map[string]any{},
	}
	if trimmedTrigger != "" {
		payload["trigger_nudge_id"] = trimmedTrigger
	}
	rows, err := r.db.Insert(ctx, r.cfg.MatchingSchema, "conversation_resumes", []map[string]any{payload})
	if err != nil {
		return conversationResumed{}, err
	}
	if len(rows) == 0 {
		return conversationResumed{}, errors.New("conversation resume persistence returned empty result")
	}
	return mapConversationResumedRow(rows[0]), nil
}

func (r *socialRepository) isNudgeSuppressedBySafety(ctx context.Context, userID, counterpartyUserID string, now time.Time) (bool, error) {
	if userID == "" || counterpartyUserID == "" {
		return true, nil
	}

	blockedByUser, err := r.isBlocked(ctx, userID, counterpartyUserID)
	if err != nil {
		return false, err
	}
	if blockedByUser {
		return true, nil
	}
	blockedByCounterparty, err := r.isBlocked(ctx, counterpartyUserID, userID)
	if err != nil {
		return false, err
	}
	if blockedByCounterparty {
		return true, nil
	}

	cutoff := now.Add(-matchNudgeSafetyWindow).Format(time.RFC3339)
	params := url.Values{}
	params.Set("status", "neq.rejected")
	params.Set("created_at", "gte."+cutoff)
	params.Set("select", "reporter_user_id,reported_user_id")
	rows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, "moderation_reports", params)
	if err != nil {
		return false, err
	}
	for _, row := range rows {
		reporter := strings.TrimSpace(toString(row["reporter_user_id"]))
		reported := strings.TrimSpace(toString(row["reported_user_id"]))
		if reporter == userID && reported == counterpartyUserID {
			return true, nil
		}
		if reporter == counterpartyUserID && reported == userID {
			return true, nil
		}
	}

	return false, nil
}

func (r *socialRepository) isBlocked(ctx context.Context, userID, blockedUserID string) (bool, error) {
	params := url.Values{}
	params.Set("user_id", "eq."+strings.TrimSpace(userID))
	params.Set("blocked_user_id", "eq."+strings.TrimSpace(blockedUserID))
	params.Set("limit", "1")
	params.Set("select", "id")
	rows, err := r.db.SelectRead(ctx, r.cfg.UserSchema, "blocked_users", params)
	if err != nil {
		return false, err
	}
	return len(rows) > 0, nil
}

func (r *socialRepository) getMatchNudgeByID(ctx context.Context, nudgeID string) (matchNudge, error) {
	params := url.Values{}
	params.Set("id", "eq."+strings.TrimSpace(nudgeID))
	params.Set("limit", "1")
	params.Set("select", "id,match_id,user_id,counterparty_user_id,nudge_type,created_at,clicked_at")
	rows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, "match_nudges", params)
	if err != nil {
		return matchNudge{}, err
	}
	if len(rows) == 0 {
		return matchNudge{}, nil
	}
	return mapMatchNudgeRow(rows[0]), nil
}

func (r *socialRepository) loadUserNames(ctx context.Context, userIDs []string) (map[string]string, error) {
	trimmed := make([]string, 0, len(userIDs))
	seen := map[string]struct{}{}
	for _, userID := range userIDs {
		id := strings.TrimSpace(userID)
		if id == "" {
			continue
		}
		if _, ok := seen[id]; ok {
			continue
		}
		seen[id] = struct{}{}
		trimmed = append(trimmed, id)
	}
	if len(trimmed) == 0 {
		return map[string]string{}, nil
	}

	params := url.Values{}
	params.Set("id", "in.("+strings.Join(trimmed, ",")+")")
	params.Set("select", "id,name")
	rows, err := r.db.SelectRead(ctx, r.cfg.UserSchema, r.cfg.UsersTable, params)
	if err != nil {
		return nil, err
	}

	nameByID := make(map[string]string, len(rows))
	for _, row := range rows {
		id := strings.TrimSpace(toString(row["id"]))
		if id == "" {
			continue
		}
		nameByID[id] = strings.TrimSpace(toString(row["name"]))
	}
	return nameByID, nil
}

func mapMatchNudgeRow(row map[string]any) matchNudge {
	return matchNudge{
		ID:                 strings.TrimSpace(toString(row["id"])),
		MatchID:            strings.TrimSpace(toString(row["match_id"])),
		UserID:             strings.TrimSpace(toString(row["user_id"])),
		CounterpartyUserID: strings.TrimSpace(toString(row["counterparty_user_id"])),
		NudgeType:          strings.TrimSpace(toString(row["nudge_type"])),
		SentAt:             normalizeTimestampString(row["created_at"]),
		ClickedAt:          normalizeTimestampString(row["clicked_at"]),
	}
}

func mapConversationResumedRow(row map[string]any) conversationResumed {
	return conversationResumed{
		ID:             strings.TrimSpace(toString(row["id"])),
		MatchID:        strings.TrimSpace(toString(row["match_id"])),
		UserID:         strings.TrimSpace(toString(row["user_id"])),
		TriggerNudgeID: strings.TrimSpace(toString(row["trigger_nudge_id"])),
		ResumedAt:      normalizeTimestampString(row["resumed_at"]),
	}
}

func normalizeTimestampString(value any) string {
	raw := strings.TrimSpace(toString(value))
	if raw == "" {
		return ""
	}
	if parsed, err := time.Parse(time.RFC3339, raw); err == nil {
		return parsed.UTC().Format(time.RFC3339)
	}
	if parsed, err := time.Parse("2006-01-02T15:04:05.999999Z07:00", raw); err == nil {
		return parsed.UTC().Format(time.RFC3339)
	}
	return raw
}

func sortFriendConnectionsByUpdatedAt(items []friendConnection) {
	sort.SliceStable(items, func(i, j int) bool {
		return items[i].UpdatedAt > items[j].UpdatedAt
	})
}
