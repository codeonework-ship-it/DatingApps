package mobile

import (
	"context"
	"errors"
	"fmt"
	"net/url"
	"strings"
	"time"

	"github.com/verified-dating/backend/internal/platform/config"
	"github.com/verified-dating/backend/internal/platform/supabase"
)

type engagementRepository struct {
	cfg config.Config
	db  *supabase.Client
}

func newEngagementRepository(cfg config.Config) *engagementRepository {
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
	return &engagementRepository{cfg: cfg, db: client}
}

func isEngagementRepoPersistenceUnavailable(err error) bool {
	if err == nil {
		return false
	}
	msg := strings.ToLower(err.Error())
	return strings.Contains(msg, "pgrst106") ||
		strings.Contains(msg, "pgrst205") ||
		strings.Contains(msg, "invalid schema") ||
		strings.Contains(msg, "could not find the table") ||
		strings.Contains(msg, "could not find the column")
}

func (r *engagementRepository) joinCircle(ctx context.Context, circleID, userID string, now time.Time) (circleMembership, error) {
	trimmedCircle := strings.TrimSpace(circleID)
	trimmedUser := strings.TrimSpace(userID)
	if trimmedCircle == "" || trimmedUser == "" {
		return circleMembership{}, errors.New("circle_id and user_id are required")
	}
	nowISO := now.UTC().Format(time.RFC3339)
	rows, err := r.db.Upsert(ctx, r.cfg.MatchingSchema, "circle_memberships", []map[string]any{{
		"circle_id":  trimmedCircle,
		"user_id":    trimmedUser,
		"role":       "member",
		"status":     "active",
		"joined_at":  nowISO,
		"updated_at": nowISO,
	}}, "circle_id,user_id")
	if err != nil {
		return circleMembership{}, err
	}
	if len(rows) == 0 {
		return circleMembership{CircleID: trimmedCircle, UserID: trimmedUser, JoinedAt: nowISO, IsJoined: true}, nil
	}
	return circleMembership{
		CircleID: strings.TrimSpace(toString(rows[0]["circle_id"])),
		UserID:   strings.TrimSpace(toString(rows[0]["user_id"])),
		JoinedAt: normalizeTimestampString(rows[0]["joined_at"]),
		IsJoined: strings.EqualFold(strings.TrimSpace(toString(rows[0]["status"])), "active"),
	}, nil
}

func (r *engagementRepository) isCircleMember(ctx context.Context, circleID, userID string) (bool, error) {
	trimmedCircle := strings.TrimSpace(circleID)
	trimmedUser := strings.TrimSpace(userID)
	if trimmedCircle == "" || trimmedUser == "" {
		return false, nil
	}
	params := url.Values{}
	params.Set("circle_id", "eq."+trimmedCircle)
	params.Set("user_id", "eq."+trimmedUser)
	params.Set("status", "eq.active")
	params.Set("limit", "1")
	params.Set("select", "id")
	rows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, "circle_memberships", params)
	if err != nil {
		return false, err
	}
	return len(rows) > 0, nil
}

func (r *engagementRepository) submitCircleChallengeEntry(
	ctx context.Context,
	circleID,
	userID,
	entryText,
	imageURL string,
	challenge circleChallenge,
	now time.Time,
) (circleChallengeEntry, error) {
	trimmedCircle := strings.TrimSpace(circleID)
	trimmedUser := strings.TrimSpace(userID)
	if trimmedCircle == "" || trimmedUser == "" {
		return circleChallengeEntry{}, errors.New("circle_id and user_id are required")
	}
	challengeStart := parseRFC3339OrZero(challenge.StartsAt)
	if challengeStart.IsZero() {
		challengeStart = startOfISOWeekUTC(now.UTC())
	}
	challengeDate := challengeStart.UTC().Format("2006-01-02")

	rows, err := r.db.Insert(ctx, r.cfg.MatchingSchema, "circle_challenge_entries", []map[string]any{{
		"circle_id":       trimmedCircle,
		"user_id":         trimmedUser,
		"challenge_date":  challengeDate,
		"submission_text": strings.TrimSpace(entryText),
		"media_url":       strings.TrimSpace(imageURL),
		"status":          "submitted",
		"created_at":      now.UTC().Format(time.RFC3339),
		"updated_at":      now.UTC().Format(time.RFC3339),
	}})
	if err != nil {
		if strings.Contains(strings.ToLower(err.Error()), "duplicate") || strings.Contains(strings.ToLower(err.Error()), "unique") {
			return circleChallengeEntry{}, errors.New("circle challenge already submitted for this week")
		}
		return circleChallengeEntry{}, err
	}
	if len(rows) == 0 {
		return circleChallengeEntry{}, errors.New("circle challenge persistence returned empty result")
	}
	return mapCircleChallengeEntryRow(rows[0], challenge), nil
}

func (r *engagementRepository) getCircleChallengeEntry(
	ctx context.Context,
	circleID,
	userID string,
	challenge circleChallenge,
	now time.Time,
) (*circleChallengeEntry, error) {
	challengeStart := parseRFC3339OrZero(challenge.StartsAt)
	if challengeStart.IsZero() {
		challengeStart = startOfISOWeekUTC(now.UTC())
	}
	challengeDate := challengeStart.UTC().Format("2006-01-02")
	params := url.Values{}
	params.Set("circle_id", "eq."+strings.TrimSpace(circleID))
	params.Set("user_id", "eq."+strings.TrimSpace(userID))
	params.Set("challenge_date", "eq."+challengeDate)
	params.Set("limit", "1")
	params.Set("select", "id,circle_id,user_id,challenge_date,submission_text,media_url,status,created_at")
	rows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, "circle_challenge_entries", params)
	if err != nil {
		return nil, err
	}
	if len(rows) == 0 {
		return nil, nil
	}
	entry := mapCircleChallengeEntryRow(rows[0], challenge)
	return &entry, nil
}

func (r *engagementRepository) countCircleChallengeEntries(ctx context.Context, circleID string, challenge circleChallenge, now time.Time) (int, error) {
	challengeStart := parseRFC3339OrZero(challenge.StartsAt)
	if challengeStart.IsZero() {
		challengeStart = startOfISOWeekUTC(now.UTC())
	}
	challengeDate := challengeStart.UTC().Format("2006-01-02")
	params := url.Values{}
	params.Set("circle_id", "eq."+strings.TrimSpace(circleID))
	params.Set("challenge_date", "eq."+challengeDate)
	params.Set("select", "id")
	rows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, "circle_challenge_entries", params)
	if err != nil {
		return 0, err
	}
	return len(rows), nil
}

func (r *engagementRepository) findVoiceIcebreakerByID(ctx context.Context, icebreakerID string) (voiceIcebreaker, error) {
	trimmedID := strings.TrimSpace(icebreakerID)
	if trimmedID == "" {
		return voiceIcebreaker{}, errors.New("icebreaker_id is required")
	}
	params := url.Values{}
	params.Set("id", "eq."+trimmedID)
	params.Set("limit", "1")
	params.Set("select", "id,match_id,sender_user_id,receiver_user_id,prompt_id,prompt_text,transcript,duration_seconds,status,moderation_status,created_at,sent_at,last_played_at,play_count")
	rows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, "voice_icebreakers", params)
	if err != nil {
		return voiceIcebreaker{}, err
	}
	if len(rows) == 0 {
		return voiceIcebreaker{}, nil
	}
	return mapVoiceIcebreakerRow(rows[0]), nil
}

func (r *engagementRepository) hasVoiceIcebreakerForToday(ctx context.Context, matchID, senderUserID string, now time.Time) (bool, error) {
	todayStart := now.UTC().Truncate(24 * time.Hour)
	params := url.Values{}
	params.Set("match_id", "eq."+strings.TrimSpace(matchID))
	params.Set("sender_user_id", "eq."+strings.TrimSpace(senderUserID))
	params.Set("created_at", "gte."+todayStart.Format(time.RFC3339))
	params.Set("limit", "1")
	params.Set("select", "id")
	rows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, "voice_icebreakers", params)
	if err != nil {
		return false, err
	}
	return len(rows) > 0, nil
}

func (r *engagementRepository) startVoiceIcebreaker(
	ctx context.Context,
	matchID,
	senderUserID,
	receiverUserID string,
	prompt voiceIcebreakerPrompt,
	now time.Time,
) (voiceIcebreaker, error) {
	rows, err := r.db.Insert(ctx, r.cfg.MatchingSchema, "voice_icebreakers", []map[string]any{{
		"match_id":          strings.TrimSpace(matchID),
		"sender_user_id":    strings.TrimSpace(senderUserID),
		"receiver_user_id":  strings.TrimSpace(receiverUserID),
		"prompt_id":         strings.TrimSpace(prompt.ID),
		"prompt_text":       strings.TrimSpace(prompt.PromptText),
		"transcript":        "",
		"duration_seconds":  0,
		"status":            "started",
		"moderation_status": "pending",
		"created_at":        now.UTC().Format(time.RFC3339),
		"updated_at":        now.UTC().Format(time.RFC3339),
		"play_count":        0,
	}})
	if err != nil {
		return voiceIcebreaker{}, err
	}
	if len(rows) == 0 {
		return voiceIcebreaker{}, errors.New("voice icebreaker persistence returned empty result")
	}
	return mapVoiceIcebreakerRow(rows[0]), nil
}

func (r *engagementRepository) sendVoiceIcebreaker(
	ctx context.Context,
	icebreakerID,
	transcript string,
	durationSeconds int,
	now time.Time,
) (voiceIcebreaker, error) {
	filters := url.Values{}
	filters.Set("id", "eq."+strings.TrimSpace(icebreakerID))
	rows, err := r.db.Update(ctx, r.cfg.MatchingSchema, "voice_icebreakers", map[string]any{
		"transcript":        strings.TrimSpace(transcript),
		"duration_seconds":  durationSeconds,
		"status":            "sent",
		"moderation_status": "approved",
		"sent_at":           now.UTC().Format(time.RFC3339),
		"updated_at":        now.UTC().Format(time.RFC3339),
	}, filters)
	if err != nil {
		return voiceIcebreaker{}, err
	}
	if len(rows) == 0 {
		return voiceIcebreaker{}, errors.New("voice icebreaker not found")
	}
	return mapVoiceIcebreakerRow(rows[0]), nil
}

func (r *engagementRepository) markVoiceIcebreakerPlayed(
	ctx context.Context,
	icebreakerID string,
	now time.Time,
) (voiceIcebreaker, error) {
	existing, err := r.findVoiceIcebreakerByID(ctx, icebreakerID)
	if err != nil {
		return voiceIcebreaker{}, err
	}
	if strings.TrimSpace(existing.ID) == "" {
		return voiceIcebreaker{}, errors.New("voice icebreaker not found")
	}
	filters := url.Values{}
	filters.Set("id", "eq."+strings.TrimSpace(icebreakerID))
	rows, err := r.db.Update(ctx, r.cfg.MatchingSchema, "voice_icebreakers", map[string]any{
		"status":         "played",
		"play_count":     existing.PlayCount + 1,
		"last_played_at": now.UTC().Format(time.RFC3339),
		"updated_at":     now.UTC().Format(time.RFC3339),
	}, filters)
	if err != nil {
		return voiceIcebreaker{}, err
	}
	if len(rows) == 0 {
		existing.Status = "played"
		existing.PlayCount++
		existing.LastPlayedAt = now.UTC().Format(time.RFC3339)
		return existing, nil
	}
	return mapVoiceIcebreakerRow(rows[0]), nil
}

func (r *engagementRepository) createGroupCoffeePoll(
	ctx context.Context,
	creatorUserID string,
	participantUserIDs []string,
	options []groupCoffeePollOption,
	deadlineAt time.Time,
	now time.Time,
) (groupCoffeePoll, error) {
	pollRows, err := r.db.Insert(ctx, r.cfg.MatchingSchema, "group_coffee_polls", []map[string]any{{
		"creator_user_id": strings.TrimSpace(creatorUserID),
		"status":          "open",
		"deadline_at":     deadlineAt.UTC().Format(time.RFC3339),
		"created_at":      now.UTC().Format(time.RFC3339),
		"updated_at":      now.UTC().Format(time.RFC3339),
	}})
	if err != nil {
		return groupCoffeePoll{}, err
	}
	if len(pollRows) == 0 {
		return groupCoffeePoll{}, errors.New("group coffee poll persistence returned empty result")
	}
	pollID := strings.TrimSpace(toString(pollRows[0]["id"]))

	participantRows := make([]map[string]any, 0, len(participantUserIDs))
	for _, participantID := range participantUserIDs {
		trimmed := strings.TrimSpace(participantID)
		if trimmed == "" {
			continue
		}
		participantRows = append(participantRows, map[string]any{
			"poll_id":    pollID,
			"user_id":    trimmed,
			"created_at": now.UTC().Format(time.RFC3339),
		})
	}
	if len(participantRows) > 0 {
		if _, err := r.db.Upsert(ctx, r.cfg.MatchingSchema, "group_coffee_poll_participants", participantRows, "poll_id,user_id"); err != nil {
			return groupCoffeePoll{}, err
		}
	}

	optionRows := make([]map[string]any, 0, len(options))
	for index, option := range options {
		optionRows = append(optionRows, map[string]any{
			"poll_id":      pollID,
			"option_text":  buildCoffeeOptionText(option),
			"day":          strings.TrimSpace(option.Day),
			"time_window":  strings.TrimSpace(option.TimeWindow),
			"neighborhood": strings.TrimSpace(option.Neighborhood),
			"sort_order":   index,
			"created_at":   now.UTC().Format(time.RFC3339),
		})
	}
	if len(optionRows) > 0 {
		if _, err := r.db.Insert(ctx, r.cfg.MatchingSchema, "group_coffee_poll_options", optionRows); err != nil {
			return groupCoffeePoll{}, err
		}
	}

	poll, found, err := r.getGroupCoffeePollByID(ctx, pollID)
	if err != nil {
		return groupCoffeePoll{}, err
	}
	if !found {
		return groupCoffeePoll{}, errors.New("group coffee poll not found after create")
	}
	return poll, nil
}

func (r *engagementRepository) voteGroupCoffeePoll(ctx context.Context, pollID, userID, optionID string) (groupCoffeePoll, error) {
	trimmedPollID := strings.TrimSpace(pollID)
	trimmedUserID := strings.TrimSpace(userID)
	trimmedOptionID := strings.TrimSpace(optionID)

	participantParams := url.Values{}
	participantParams.Set("poll_id", "eq."+trimmedPollID)
	participantParams.Set("user_id", "eq."+trimmedUserID)
	participantParams.Set("limit", "1")
	participantParams.Set("select", "poll_id")
	participants, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, "group_coffee_poll_participants", participantParams)
	if err != nil {
		return groupCoffeePoll{}, err
	}
	if len(participants) == 0 {
		return groupCoffeePoll{}, errors.New("user is not a participant in this group coffee poll")
	}

	voteRows, err := r.db.Upsert(ctx, r.cfg.MatchingSchema, "group_coffee_poll_votes", []map[string]any{{
		"poll_id":    trimmedPollID,
		"option_id":  trimmedOptionID,
		"user_id":    trimmedUserID,
		"created_at": time.Now().UTC().Format(time.RFC3339),
	}}, "poll_id,user_id")
	if err != nil {
		return groupCoffeePoll{}, err
	}
	if len(voteRows) == 0 {
		return groupCoffeePoll{}, errors.New("vote was not persisted")
	}

	poll, found, err := r.getGroupCoffeePollByID(ctx, trimmedPollID)
	if err != nil {
		return groupCoffeePoll{}, err
	}
	if !found {
		return groupCoffeePoll{}, errors.New("group coffee poll not found")
	}
	return poll, nil
}

func (r *engagementRepository) finalizeGroupCoffeePoll(ctx context.Context, pollID, userID string, now time.Time) (groupCoffeePoll, groupCoffeePollOption, error) {
	poll, found, err := r.getGroupCoffeePollByID(ctx, pollID)
	if err != nil {
		return groupCoffeePoll{}, groupCoffeePollOption{}, err
	}
	if !found {
		return groupCoffeePoll{}, groupCoffeePollOption{}, errors.New("group coffee poll not found")
	}
	if poll.CreatorUserID != strings.TrimSpace(userID) {
		return groupCoffeePoll{}, groupCoffeePollOption{}, errors.New("only creator can finalize group coffee poll")
	}
	if poll.Status == "finalized" {
		selected := groupCoffeePollOption{}
		for _, option := range poll.Options {
			if option.ID == poll.FinalizedOptionID {
				selected = option
				break
			}
		}
		return poll, selected, nil
	}

	selected := groupCoffeePollOption{}
	maxVotes := -1
	for _, option := range poll.Options {
		if option.VotesCount > maxVotes {
			maxVotes = option.VotesCount
			selected = option
		}
	}
	if strings.TrimSpace(selected.ID) == "" {
		return groupCoffeePoll{}, groupCoffeePollOption{}, errors.New("group coffee poll has no options")
	}

	filters := url.Values{}
	filters.Set("id", "eq."+strings.TrimSpace(pollID))
	_, err = r.db.Update(ctx, r.cfg.MatchingSchema, "group_coffee_polls", map[string]any{
		"status":             "finalized",
		"selected_option_id": selected.ID,
		"updated_at":         now.UTC().Format(time.RFC3339),
	}, filters)
	if err != nil {
		return groupCoffeePoll{}, groupCoffeePollOption{}, err
	}

	updated, found, err := r.getGroupCoffeePollByID(ctx, pollID)
	if err != nil {
		return groupCoffeePoll{}, groupCoffeePollOption{}, err
	}
	if !found {
		return groupCoffeePoll{}, groupCoffeePollOption{}, errors.New("group coffee poll not found")
	}
	updated.FinalizedAt = now.UTC().Format(time.RFC3339)
	return updated, selected, nil
}

func (r *engagementRepository) getGroupCoffeePollByID(ctx context.Context, pollID string) (groupCoffeePoll, bool, error) {
	trimmedPollID := strings.TrimSpace(pollID)
	if trimmedPollID == "" {
		return groupCoffeePoll{}, false, nil
	}
	params := url.Values{}
	params.Set("id", "eq."+trimmedPollID)
	params.Set("limit", "1")
	params.Set("select", "id,creator_user_id,status,deadline_at,selected_option_id,created_at,updated_at")
	rows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, "group_coffee_polls", params)
	if err != nil {
		return groupCoffeePoll{}, false, err
	}
	if len(rows) == 0 {
		return groupCoffeePoll{}, false, nil
	}
	poll, err := r.assembleGroupCoffeePoll(ctx, rows[0])
	if err != nil {
		return groupCoffeePoll{}, false, err
	}
	return poll, true, nil
}

func (r *engagementRepository) listGroupCoffeePolls(ctx context.Context, userID, status string, limit int) ([]groupCoffeePoll, error) {
	trimmedUserID := strings.TrimSpace(userID)
	if trimmedUserID == "" {
		return []groupCoffeePoll{}, nil
	}
	if limit <= 0 {
		limit = 50
	} else if limit > 200 {
		limit = 200
	}

	participantParams := url.Values{}
	participantParams.Set("user_id", "eq."+trimmedUserID)
	participantParams.Set("order", "created_at.desc")
	participantParams.Set("select", "poll_id")
	participantRows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, "group_coffee_poll_participants", participantParams)
	if err != nil {
		return nil, err
	}
	pollIDs := make([]string, 0, len(participantRows))
	seen := map[string]struct{}{}
	for _, row := range participantRows {
		pollID := strings.TrimSpace(toString(row["poll_id"]))
		if pollID == "" {
			continue
		}
		if _, exists := seen[pollID]; exists {
			continue
		}
		seen[pollID] = struct{}{}
		pollIDs = append(pollIDs, pollID)
	}
	if len(pollIDs) == 0 {
		return []groupCoffeePoll{}, nil
	}

	pollParams := url.Values{}
	pollParams.Set("id", "in.("+strings.Join(pollIDs, ",")+")")
	pollParams.Set("order", "created_at.desc")
	pollParams.Set("select", "id,creator_user_id,status,deadline_at,selected_option_id,created_at,updated_at")
	if trimmedStatus := strings.TrimSpace(strings.ToLower(status)); trimmedStatus != "" {
		pollParams.Set("status", "eq."+trimmedStatus)
	}
	pollRows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, "group_coffee_polls", pollParams)
	if err != nil {
		return nil, err
	}
	out := make([]groupCoffeePoll, 0, len(pollRows))
	for _, row := range pollRows {
		poll, assembleErr := r.assembleGroupCoffeePoll(ctx, row)
		if assembleErr != nil {
			return nil, assembleErr
		}
		out = append(out, poll)
		if len(out) >= limit {
			break
		}
	}
	return out, nil
}

func (r *engagementRepository) startVideoCall(ctx context.Context, matchID, initiatorID, recipientID string, now time.Time) (videoCallSession, error) {
	trimmedMatchID := strings.TrimSpace(matchID)
	trimmedInitiator := strings.TrimSpace(initiatorID)
	trimmedRecipient := strings.TrimSpace(recipientID)
	if trimmedInitiator == "" || trimmedRecipient == "" {
		return videoCallSession{}, errors.New("initiator_id and recipient_id are required")
	}
	if trimmedInitiator == trimmedRecipient {
		return videoCallSession{}, errors.New("initiator and recipient cannot be the same")
	}
	rows, err := r.db.Insert(ctx, r.cfg.MatchingSchema, "video_call_sessions", []map[string]any{{
		"match_id":     trimmedMatchID,
		"initiator_id": trimmedInitiator,
		"recipient_id": trimmedRecipient,
		"status":       "started",
		"started_at":   now.UTC().Format(time.RFC3339),
		"metadata":     map[string]any{},
	}})
	if err != nil {
		return videoCallSession{}, err
	}
	if len(rows) == 0 {
		return videoCallSession{}, errors.New("video call persistence returned empty result")
	}
	session := mapVideoCallSessionRow(rows[0])
	if strings.TrimSpace(session.RoomID) == "" {
		session.RoomID = "room-" + session.ID
		filters := url.Values{}
		filters.Set("id", "eq."+session.ID)
		_, _ = r.db.Update(ctx, r.cfg.MatchingSchema, "video_call_sessions", map[string]any{
			"metadata": map[string]any{"room_id": session.RoomID},
		}, filters)
	}
	return session, nil
}

func (r *engagementRepository) endVideoCall(ctx context.Context, callID, endedBy string, now time.Time) (videoCallSession, error) {
	session, err := r.getVideoCallByID(ctx, callID)
	if err != nil {
		return videoCallSession{}, err
	}
	if strings.TrimSpace(session.ID) == "" {
		return videoCallSession{}, errors.New("call not found")
	}
	if session.Status == "ended" {
		return session, nil
	}
	startedAt := parseRFC3339OrZero(session.StartedAt)
	duration := int(now.UTC().Sub(startedAt).Seconds())
	if duration < 0 {
		duration = 0
	}
	metadata := map[string]any{"room_id": session.RoomID, "duration_sec": duration}
	filters := url.Values{}
	filters.Set("id", "eq."+strings.TrimSpace(callID))
	rows, updateErr := r.db.Update(ctx, r.cfg.MatchingSchema, "video_call_sessions", map[string]any{
		"status":   "ended",
		"ended_at": now.UTC().Format(time.RFC3339),
		"ended_by": strings.TrimSpace(endedBy),
		"metadata": metadata,
	}, filters)
	if updateErr != nil {
		return videoCallSession{}, updateErr
	}
	if len(rows) == 0 {
		session.Status = "ended"
		session.EndedAt = now.UTC().Format(time.RFC3339)
		session.EndedByUserID = strings.TrimSpace(endedBy)
		session.DurationSec = duration
		return session, nil
	}
	updated := mapVideoCallSessionRow(rows[0])
	if updated.DurationSec == 0 {
		updated.DurationSec = duration
	}
	return updated, nil
}

func (r *engagementRepository) listVideoCalls(ctx context.Context, userID string, limit int) ([]videoCallSession, error) {
	trimmedUserID := strings.TrimSpace(userID)
	if trimmedUserID == "" {
		return []videoCallSession{}, nil
	}
	if limit <= 0 || limit > 500 {
		limit = 100
	}
	params := url.Values{}
	params.Set("or", fmt.Sprintf("(initiator_id.eq.%s,recipient_id.eq.%s)", trimmedUserID, trimmedUserID))
	params.Set("order", "started_at.desc")
	params.Set("limit", fmt.Sprintf("%d", limit))
	params.Set("select", "id,match_id,initiator_id,recipient_id,status,started_at,ended_at,ended_by,metadata")
	rows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, "video_call_sessions", params)
	if err != nil {
		return nil, err
	}
	out := make([]videoCallSession, 0, len(rows))
	for _, row := range rows {
		out = append(out, mapVideoCallSessionRow(row))
	}
	return out, nil
}

func (r *engagementRepository) getVideoCallByID(ctx context.Context, callID string) (videoCallSession, error) {
	trimmedCallID := strings.TrimSpace(callID)
	if trimmedCallID == "" {
		return videoCallSession{}, errors.New("call_id is required")
	}
	params := url.Values{}
	params.Set("id", "eq."+trimmedCallID)
	params.Set("limit", "1")
	params.Set("select", "id,match_id,initiator_id,recipient_id,status,started_at,ended_at,ended_by,metadata")
	rows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, "video_call_sessions", params)
	if err != nil {
		return videoCallSession{}, err
	}
	if len(rows) == 0 {
		return videoCallSession{}, nil
	}
	return mapVideoCallSessionRow(rows[0]), nil
}

func mapCircleChallengeEntryRow(row map[string]any, challenge circleChallenge) circleChallengeEntry {
	return circleChallengeEntry{
		ID:          strings.TrimSpace(toString(row["id"])),
		CircleID:    strings.TrimSpace(toString(row["circle_id"])),
		ChallengeID: strings.TrimSpace(challenge.ID),
		UserID:      strings.TrimSpace(toString(row["user_id"])),
		EntryText:   strings.TrimSpace(toString(row["submission_text"])),
		ImageURL:    strings.TrimSpace(toString(row["media_url"])),
		SubmittedAt: normalizeTimestampString(row["created_at"]),
	}
}

func mapVideoCallSessionRow(row map[string]any) videoCallSession {
	metadata, _ := row["metadata"].(map[string]any)
	roomID := ""
	durationSec := 0
	if metadata != nil {
		roomID = strings.TrimSpace(toString(metadata["room_id"]))
		if value, ok := toInt(metadata["duration_sec"]); ok {
			durationSec = value
		}
	}
	if roomID == "" {
		roomID = "room-" + strings.TrimSpace(toString(row["id"]))
	}
	if durationSec == 0 {
		startedAt := parseRFC3339OrZero(normalizeTimestampString(row["started_at"]))
		endedAt := parseRFC3339OrZero(normalizeTimestampString(row["ended_at"]))
		if !startedAt.IsZero() && !endedAt.IsZero() {
			delta := int(endedAt.Sub(startedAt).Seconds())
			if delta > 0 {
				durationSec = delta
			}
		}
	}
	return videoCallSession{
		ID:            strings.TrimSpace(toString(row["id"])),
		MatchID:       strings.TrimSpace(toString(row["match_id"])),
		InitiatorID:   strings.TrimSpace(toString(row["initiator_id"])),
		RecipientID:   strings.TrimSpace(toString(row["recipient_id"])),
		Status:        strings.TrimSpace(toString(row["status"])),
		RoomID:        roomID,
		StartedAt:     normalizeTimestampString(row["started_at"]),
		EndedAt:       normalizeTimestampString(row["ended_at"]),
		DurationSec:   durationSec,
		EndedByUserID: strings.TrimSpace(toString(row["ended_by"])),
	}
}

func mapVoiceIcebreakerRow(row map[string]any) voiceIcebreaker {
	playCount, _ := toInt(row["play_count"])
	durationSeconds, _ := toInt(row["duration_seconds"])
	promptID := strings.TrimSpace(toString(row["prompt_id"]))
	promptText := strings.TrimSpace(toString(row["prompt_text"]))
	if promptText == "" {
		promptText = resolveVoiceIcebreakerPrompt(promptID).PromptText
	}
	return voiceIcebreaker{
		ID:               strings.TrimSpace(toString(row["id"])),
		MatchID:          strings.TrimSpace(toString(row["match_id"])),
		SenderUserID:     strings.TrimSpace(toString(row["sender_user_id"])),
		ReceiverUserID:   strings.TrimSpace(toString(row["receiver_user_id"])),
		PromptID:         promptID,
		PromptText:       promptText,
		Transcript:       strings.TrimSpace(toString(row["transcript"])),
		DurationSeconds:  durationSeconds,
		Status:           strings.TrimSpace(toString(row["status"])),
		ModerationStatus: strings.TrimSpace(toString(row["moderation_status"])),
		StartedAt:        normalizeTimestampString(row["created_at"]),
		SentAt:           normalizeTimestampString(row["sent_at"]),
		LastPlayedAt:     normalizeTimestampString(row["last_played_at"]),
		PlayCount:        playCount,
	}
}

func buildCoffeeOptionText(option groupCoffeePollOption) string {
	day := strings.TrimSpace(option.Day)
	timeWindow := strings.TrimSpace(option.TimeWindow)
	neighborhood := strings.TrimSpace(option.Neighborhood)
	if day == "" && timeWindow == "" && neighborhood == "" {
		return ""
	}
	return strings.Join([]string{day, timeWindow, neighborhood}, " | ")
}

func parseCoffeeOptionText(optionText string) (string, string, string) {
	parts := strings.Split(optionText, "|")
	if len(parts) < 3 {
		trimmed := strings.TrimSpace(optionText)
		return trimmed, "", ""
	}
	return strings.TrimSpace(parts[0]), strings.TrimSpace(parts[1]), strings.TrimSpace(parts[2])
}

func (r *engagementRepository) assembleGroupCoffeePoll(ctx context.Context, pollRow map[string]any) (groupCoffeePoll, error) {
	pollID := strings.TrimSpace(toString(pollRow["id"]))

	participantParams := url.Values{}
	participantParams.Set("poll_id", "eq."+pollID)
	participantParams.Set("order", "created_at.asc")
	participantParams.Set("select", "user_id")
	participantRows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, "group_coffee_poll_participants", participantParams)
	if err != nil {
		return groupCoffeePoll{}, err
	}
	participants := make([]string, 0, len(participantRows))
	for _, row := range participantRows {
		userID := strings.TrimSpace(toString(row["user_id"]))
		if userID != "" {
			participants = append(participants, userID)
		}
	}

	optionParams := url.Values{}
	optionParams.Set("poll_id", "eq."+pollID)
	optionParams.Set("order", "sort_order.asc")
	optionParams.Set("select", "id,option_text,day,time_window,neighborhood,sort_order")
	optionRows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, "group_coffee_poll_options", optionParams)
	if err != nil {
		return groupCoffeePoll{}, err
	}

	voteParams := url.Values{}
	voteParams.Set("poll_id", "eq."+pollID)
	voteParams.Set("select", "option_id")
	voteRows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, "group_coffee_poll_votes", voteParams)
	if err != nil {
		return groupCoffeePoll{}, err
	}
	votesByOption := map[string]int{}
	for _, row := range voteRows {
		optionID := strings.TrimSpace(toString(row["option_id"]))
		if optionID != "" {
			votesByOption[optionID]++
		}
	}

	options := make([]groupCoffeePollOption, 0, len(optionRows))
	for _, row := range optionRows {
		day := strings.TrimSpace(toString(row["day"]))
		timeWindow := strings.TrimSpace(toString(row["time_window"]))
		neighborhood := strings.TrimSpace(toString(row["neighborhood"]))
		if day == "" || timeWindow == "" || neighborhood == "" {
			parsedDay, parsedWindow, parsedNeighborhood := parseCoffeeOptionText(toString(row["option_text"]))
			if day == "" {
				day = parsedDay
			}
			if timeWindow == "" {
				timeWindow = parsedWindow
			}
			if neighborhood == "" {
				neighborhood = parsedNeighborhood
			}
		}
		optionID := strings.TrimSpace(toString(row["id"]))
		options = append(options, groupCoffeePollOption{
			ID:           optionID,
			Day:          day,
			TimeWindow:   timeWindow,
			Neighborhood: neighborhood,
			VotesCount:   votesByOption[optionID],
		})
	}

	return groupCoffeePoll{
		ID:                 pollID,
		CreatorUserID:      strings.TrimSpace(toString(pollRow["creator_user_id"])),
		ParticipantUserIDs: participants,
		Options:            options,
		Status:             strings.TrimSpace(toString(pollRow["status"])),
		DeadlineAt:         normalizeTimestampString(pollRow["deadline_at"]),
		FinalizedOptionID:  strings.TrimSpace(toString(pollRow["selected_option_id"])),
		CreatedAt:          normalizeTimestampString(pollRow["created_at"]),
		FinalizedAt:        normalizeTimestampString(pollRow["updated_at"]),
	}, nil
}
