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

type dailyPromptRepository struct {
	cfg config.Config
	db  *supabase.Client
}

func newDailyPromptRepository(cfg config.Config) *dailyPromptRepository {
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
	return &dailyPromptRepository{cfg: cfg, db: client}
}

func isDailyPromptRepoPersistenceUnavailable(err error) bool {
	if err == nil {
		return false
	}
	msg := strings.ToLower(err.Error())
	return strings.Contains(msg, "pgrst106") ||
		strings.Contains(msg, "pgrst205") ||
		strings.Contains(msg, "invalid schema") ||
		strings.Contains(msg, "could not find the table")
}

func (r *dailyPromptRepository) getDailyPromptView(ctx context.Context, userID string, now time.Time) (dailyPromptView, error) {
	trimmedUserID := strings.TrimSpace(userID)
	if trimmedUserID == "" {
		return dailyPromptView{}, errors.New("user id is required")
	}

	promptTemplate := dailyPromptForDate(now.UTC())
	prompt, err := r.ensureDailyPrompt(ctx, promptTemplate)
	if err != nil {
		return dailyPromptView{}, err
	}

	answer, _ := r.getPromptAnswer(ctx, prompt.ID, trimmedUserID)
	streak, _ := r.getUserStreak(ctx, trimmedUserID)

	spark, err := r.buildSpark(ctx, prompt.ID, trimmedUserID, strings.TrimSpace(answer.Normalized))
	if err != nil {
		return dailyPromptView{}, err
	}

	view := dailyPromptView{
		Prompt: prompt,
		Streak: normalizeDailyPromptStreak(streak),
		Spark:  spark,
	}
	if strings.TrimSpace(answer.PromptID) != "" {
		answerCopy := answer
		view.Answer = &answerCopy
	}
	return view, nil
}

func (r *dailyPromptRepository) submitDailyPromptAnswer(
	ctx context.Context,
	userID,
	promptID,
	answerText string,
	now time.Time,
) (dailyPromptView, bool, error) {
	trimmedUserID := strings.TrimSpace(userID)
	trimmedPromptID := strings.TrimSpace(promptID)
	trimmedAnswer := strings.TrimSpace(answerText)
	if trimmedUserID == "" {
		return dailyPromptView{}, false, errors.New("user id is required")
	}
	if trimmedAnswer == "" {
		return dailyPromptView{}, false, errors.New("answer_text is required")
	}
	if len(trimmedAnswer) < dailyPromptMinChars || len(trimmedAnswer) > dailyPromptMaxChars {
		return dailyPromptView{}, false, fmt.Errorf(
			"answer_text must be between %d and %d characters",
			dailyPromptMinChars,
			dailyPromptMaxChars,
		)
	}

	promptTemplate := dailyPromptForDate(now.UTC())
	prompt, err := r.ensureDailyPrompt(ctx, promptTemplate)
	if err != nil {
		return dailyPromptView{}, false, err
	}

	if trimmedPromptID != "" && trimmedPromptID != prompt.ID && trimmedPromptID != promptTemplate.ID {
		return dailyPromptView{}, false, errors.New("prompt_id does not match today's prompt")
	}

	normalizedAnswer := normalizeDailyPromptAnswer(trimmedAnswer)
	if normalizedAnswer == "" {
		return dailyPromptView{}, false, errors.New("answer_text cannot be empty after normalization")
	}

	existing, hasExisting := r.getPromptAnswer(ctx, prompt.ID, trimmedUserID)
	isEdit := false

	if hasExisting {
		editWindowUntil := parseRFC3339OrZero(existing.EditWindowUntil)
		if editWindowUntil.IsZero() {
			answeredAt := parseRFC3339OrZero(existing.AnsweredAt)
			if answeredAt.IsZero() {
				answeredAt = now.UTC()
			}
			editWindowUntil = answeredAt.Add(dailyPromptEditWindow)
		}
		if now.UTC().After(editWindowUntil) {
			return dailyPromptView{}, false, errors.New("daily prompt edit window expired")
		}

		filters := url.Values{}
		filters.Set("prompt_id", "eq."+prompt.ID)
		filters.Set("user_id", "eq."+trimmedUserID)
		_, err = r.db.Update(ctx, r.cfg.MatchingSchema, "prompt_answers", map[string]any{
			"answer_text":       trimmedAnswer,
			"normalized_answer": normalizedAnswer,
			"updated_at":        now.UTC().Format(time.RFC3339),
			"is_edited":         true,
		}, filters)
		if err != nil {
			return dailyPromptView{}, false, err
		}
		isEdit = true
	} else {
		_, err = r.db.Insert(ctx, r.cfg.MatchingSchema, "prompt_answers", []map[string]any{{
			"prompt_id":         prompt.ID,
			"user_id":           trimmedUserID,
			"answer_date":       prompt.PromptDate,
			"answer_text":       trimmedAnswer,
			"normalized_answer": normalizedAnswer,
			"is_edited":         false,
			"edit_window_until": now.UTC().Add(dailyPromptEditWindow).Format(time.RFC3339),
			"created_at":        now.UTC().Format(time.RFC3339),
			"updated_at":        now.UTC().Format(time.RFC3339),
		}})
		if err != nil {
			if strings.Contains(strings.ToLower(err.Error()), "duplicate key") {
				hasExisting = true
			} else {
				return dailyPromptView{}, false, err
			}
		} else {
			if err := r.updateStreakForNewAnswer(ctx, trimmedUserID, prompt.PromptDate, now.UTC()); err != nil {
				return dailyPromptView{}, false, err
			}
		}
	}

	view, err := r.getDailyPromptView(ctx, trimmedUserID, now.UTC())
	if err != nil {
		return dailyPromptView{}, false, err
	}
	return view, isEdit, nil
}

func (r *dailyPromptRepository) listDailyPromptResponders(
	ctx context.Context,
	userID string,
	now time.Time,
	limit,
	offset int,
) (dailyPromptRespondersPage, error) {
	trimmedUserID := strings.TrimSpace(userID)
	if trimmedUserID == "" {
		return dailyPromptRespondersPage{}, errors.New("user id is required")
	}
	if limit <= 0 {
		limit = 10
	} else if limit > 50 {
		limit = 50
	}
	if offset < 0 {
		offset = 0
	}

	promptTemplate := dailyPromptForDate(now.UTC())
	prompt, err := r.ensureDailyPrompt(ctx, promptTemplate)
	if err != nil {
		return dailyPromptRespondersPage{}, err
	}

	page := dailyPromptRespondersPage{
		PromptID:   prompt.ID,
		PromptDate: prompt.PromptDate,
		Responders: []dailyPromptResponder{},
		Limit:      limit,
		Offset:     offset,
		NextOffset: offset,
	}

	requesterAnswer, hasRequesterAnswer := r.getPromptAnswer(ctx, prompt.ID, trimmedUserID)
	if !hasRequesterAnswer {
		return page, nil
	}
	normalized := strings.TrimSpace(requesterAnswer.Normalized)
	if normalized == "" {
		return page, nil
	}

	params := url.Values{}
	params.Set("prompt_id", "eq."+prompt.ID)
	params.Set("normalized_answer", "eq."+normalized)
	params.Set("user_id", "neq."+trimmedUserID)
	params.Set("order", "created_at.desc")
	params.Set("select", "user_id,created_at")
	rows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, "prompt_answers", params)
	if err != nil {
		return dailyPromptRespondersPage{}, err
	}

	all := make([]dailyPromptResponder, 0, len(rows))
	userIDs := make([]string, 0, len(rows))
	for _, row := range rows {
		otherID := strings.TrimSpace(toString(row["user_id"]))
		if otherID == "" {
			continue
		}
		answeredAt := strings.TrimSpace(toString(row["created_at"]))
		all = append(all, dailyPromptResponder{UserID: otherID, AnsweredAt: answeredAt})
		userIDs = append(userIDs, otherID)
	}

	nameByUser, photoByUser, err := r.loadResponderProfiles(ctx, userIDs)
	if err != nil {
		return dailyPromptRespondersPage{}, err
	}

	for index := range all {
		otherID := all[index].UserID
		display := strings.TrimSpace(nameByUser[otherID])
		if display == "" {
			display = otherID
		}
		all[index].DisplayName = display
		photo := strings.TrimSpace(photoByUser[otherID])
		if photo == "" {
			photo = strings.TrimSpace(seedURL(r.cfg.MockPhotoSeedURLTemplate, otherID))
		}
		all[index].PhotoURL = photo
	}

	page.Total = len(all)
	if offset >= len(all) {
		return page, nil
	}
	end := offset + limit
	if end > len(all) {
		end = len(all)
	}
	page.Responders = append([]dailyPromptResponder{}, all[offset:end]...)
	page.HasMore = end < len(all)
	page.NextOffset = end
	return page, nil
}

func (r *dailyPromptRepository) ensureDailyPrompt(ctx context.Context, prompt dailyPrompt) (dailyPrompt, error) {
	payload := []map[string]any{{
		"prompt_date": prompt.PromptDate,
		"prompt_text": prompt.PromptText,
		"domain":      prompt.Domain,
	}}
	rows, err := r.db.Upsert(ctx, r.cfg.MatchingSchema, "daily_prompts", payload, "prompt_date")
	if err != nil {
		return dailyPrompt{}, err
	}
	if len(rows) == 0 {
		params := url.Values{}
		params.Set("prompt_date", "eq."+prompt.PromptDate)
		params.Set("limit", "1")
		params.Set("select", "id,prompt_date,prompt_text,domain")
		rows, err = r.db.SelectRead(ctx, r.cfg.MatchingSchema, "daily_prompts", params)
		if err != nil {
			return dailyPrompt{}, err
		}
		if len(rows) == 0 {
			return prompt, nil
		}
	}

	row := rows[0]
	prompt.ID = strings.TrimSpace(toString(row["id"]))
	if prompt.ID == "" {
		prompt.ID = prompt.PromptDate
	}
	if value := strings.TrimSpace(toString(row["prompt_text"])); value != "" {
		prompt.PromptText = value
	}
	if value := strings.TrimSpace(toString(row["domain"])); value != "" {
		prompt.Domain = value
	}
	if value := strings.TrimSpace(toString(row["prompt_date"])); value != "" {
		prompt.PromptDate = value
	}
	return prompt, nil
}

func (r *dailyPromptRepository) getPromptAnswer(ctx context.Context, promptID, userID string) (dailyPromptAnswer, bool) {
	params := url.Values{}
	params.Set("prompt_id", "eq."+strings.TrimSpace(promptID))
	params.Set("user_id", "eq."+strings.TrimSpace(userID))
	params.Set("limit", "1")
	params.Set("select", "prompt_id,user_id,answer_date,answer_text,normalized_answer,created_at,updated_at,edit_window_until,is_edited")
	rows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, "prompt_answers", params)
	if err != nil || len(rows) == 0 {
		return dailyPromptAnswer{}, false
	}
	row := rows[0]
	answer := dailyPromptAnswer{
		PromptID:        strings.TrimSpace(toString(row["prompt_id"])),
		UserID:          strings.TrimSpace(toString(row["user_id"])),
		PromptDate:      strings.TrimSpace(toString(row["answer_date"])),
		AnswerText:      strings.TrimSpace(toString(row["answer_text"])),
		AnsweredAt:      strings.TrimSpace(toString(row["created_at"])),
		UpdatedAt:       strings.TrimSpace(toString(row["updated_at"])),
		EditWindowUntil: strings.TrimSpace(toString(row["edit_window_until"])),
		IsEdited:        toBoolValue(row["is_edited"]),
		Normalized:      strings.TrimSpace(toString(row["normalized_answer"])),
	}
	if answer.PromptID == "" {
		return dailyPromptAnswer{}, false
	}
	return answer, true
}

func (r *dailyPromptRepository) getUserStreak(ctx context.Context, userID string) (dailyPromptStreak, bool) {
	params := url.Values{}
	params.Set("user_id", "eq."+strings.TrimSpace(userID))
	params.Set("limit", "1")
	params.Set("select", "user_id,current_streak,best_streak,last_activity_date,milestone_reached,updated_at")
	rows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, "user_streaks", params)
	if err != nil || len(rows) == 0 {
		return dailyPromptStreak{UserID: strings.TrimSpace(userID)}, false
	}
	row := rows[0]
	currentDays, _ := toInt(row["current_streak"])
	bestDays, _ := toInt(row["best_streak"])
	milestoneReached, _ := toInt(row["milestone_reached"])
	streak := dailyPromptStreak{
		UserID:           strings.TrimSpace(toString(row["user_id"])),
		CurrentDays:      currentDays,
		LongestDays:      bestDays,
		LastAnsweredDate: strings.TrimSpace(toString(row["last_activity_date"])),
		MilestoneReached: milestoneReached,
		UpdatedAt:        strings.TrimSpace(toString(row["updated_at"])),
	}
	if streak.UserID == "" {
		streak.UserID = strings.TrimSpace(userID)
	}
	return streak, true
}

func (r *dailyPromptRepository) updateStreakForNewAnswer(ctx context.Context, userID, promptDate string, now time.Time) error {
	streak, _ := r.getUserStreak(ctx, userID)
	streak.UserID = strings.TrimSpace(userID)
	streak.LastAnsweredDate = strings.TrimSpace(streak.LastAnsweredDate)

	if streak.LastAnsweredDate == promptDate {
		streak.NextMilestone = nextDailyPromptMilestone(streak.CurrentDays)
		streak.UpdatedAt = now.UTC().Format(time.RFC3339)
		return r.upsertStreak(ctx, streak)
	}

	previousDate := ""
	if parsed, err := time.Parse("2006-01-02", promptDate); err == nil {
		previousDate = parsed.AddDate(0, 0, -1).Format("2006-01-02")
	}

	if streak.LastAnsweredDate != "" && streak.LastAnsweredDate == previousDate {
		streak.CurrentDays++
	} else {
		streak.CurrentDays = 1
	}
	if streak.CurrentDays > streak.LongestDays {
		streak.LongestDays = streak.CurrentDays
	}
	streak.LastAnsweredDate = promptDate
	streak.NextMilestone = nextDailyPromptMilestone(streak.CurrentDays)
	streak.MilestoneReached = 0
	for _, milestone := range dailyPromptMilestones {
		if streak.CurrentDays == milestone {
			streak.MilestoneReached = milestone
			break
		}
	}
	streak.UpdatedAt = now.UTC().Format(time.RFC3339)
	return r.upsertStreak(ctx, streak)
}

func (r *dailyPromptRepository) upsertStreak(ctx context.Context, streak dailyPromptStreak) error {
	_, err := r.db.Upsert(ctx, r.cfg.MatchingSchema, "user_streaks", []map[string]any{{
		"user_id":            streak.UserID,
		"streak_type":        "daily_prompt",
		"current_streak":     streak.CurrentDays,
		"best_streak":        streak.LongestDays,
		"last_activity_date": nullableDateValue(streak.LastAnsweredDate),
		"milestone_reached":  nullableIntValue(streak.MilestoneReached),
		"updated_at":         time.Now().UTC().Format(time.RFC3339),
	}}, "user_id")
	return err
}

func (r *dailyPromptRepository) buildSpark(
	ctx context.Context,
	promptID,
	userID,
	normalizedAnswer string,
) (dailyPromptSpark, error) {
	params := url.Values{}
	params.Set("prompt_id", "eq."+strings.TrimSpace(promptID))
	params.Set("select", "user_id,normalized_answer")
	rows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, "prompt_answers", params)
	if err != nil {
		return dailyPromptSpark{}, err
	}

	spark := dailyPromptSpark{SimilarUserIDs: []string{}}
	trimmedNormalized := strings.TrimSpace(normalizedAnswer)
	for _, row := range rows {
		otherID := strings.TrimSpace(toString(row["user_id"]))
		if otherID == "" {
			continue
		}
		spark.ParticipantsToday++
		if trimmedNormalized == "" {
			continue
		}
		if otherID == strings.TrimSpace(userID) {
			continue
		}
		if strings.TrimSpace(toString(row["normalized_answer"])) != trimmedNormalized {
			continue
		}
		spark.SimilarCount++
		if len(spark.SimilarUserIDs) < 3 {
			spark.SimilarUserIDs = append(spark.SimilarUserIDs, otherID)
		}
	}
	return spark, nil
}

func (r *dailyPromptRepository) loadResponderProfiles(
	ctx context.Context,
	userIDs []string,
) (map[string]string, map[string]string, error) {
	uniq := uniqueStrings(userIDs)
	if len(uniq) == 0 {
		return map[string]string{}, map[string]string{}, nil
	}

	nameByUser := make(map[string]string, len(uniq))
	photoByUser := make(map[string]string, len(uniq))

	userParams := url.Values{}
	userParams.Set("id", "in."+buildInList(uniq))
	userParams.Set("select", "id,name")
	users, err := r.db.SelectRead(ctx, r.cfg.UserSchema, r.cfg.UsersTable, userParams)
	if err != nil {
		return nil, nil, err
	}
	for _, row := range users {
		id := strings.TrimSpace(toString(row["id"]))
		if id == "" {
			continue
		}
		nameByUser[id] = strings.TrimSpace(toString(row["name"]))
	}

	photoParams := url.Values{}
	photoParams.Set("user_id", "in."+buildInList(uniq))
	photoParams.Set("select", "user_id,photo_url,ordering")
	photoParams.Set("order", "user_id.asc,ordering.asc")
	photos, err := r.db.SelectRead(ctx, r.cfg.UserSchema, r.cfg.PhotosTable, photoParams)
	if err != nil {
		return nil, nil, err
	}

	type orderedPhoto struct {
		url      string
		ordering int
	}
	photoCandidates := make(map[string]orderedPhoto, len(uniq))
	for _, row := range photos {
		id := strings.TrimSpace(toString(row["user_id"]))
		photoURL := strings.TrimSpace(toString(row["photo_url"]))
		if id == "" || photoURL == "" {
			continue
		}
		ordering, _ := toInt(row["ordering"])
		prev, exists := photoCandidates[id]
		if !exists || ordering < prev.ordering {
			photoCandidates[id] = orderedPhoto{url: photoURL, ordering: ordering}
		}
	}

	for userID, candidate := range photoCandidates {
		photoByUser[userID] = candidate.url
	}

	return nameByUser, photoByUser, nil
}

func nullableDateValue(value string) any {
	trimmed := strings.TrimSpace(value)
	if trimmed == "" {
		return nil
	}
	return trimmed
}

func nullableIntValue(value int) any {
	if value <= 0 {
		return nil
	}
	return value
}

func toBoolValue(value any) bool {
	switch typed := value.(type) {
	case bool:
		return typed
	case string:
		trimmed := strings.TrimSpace(strings.ToLower(typed))
		return trimmed == "true" || trimmed == "t" || trimmed == "1"
	default:
		return false
	}
}

func sortRespondersByAnsweredAtDesc(responders []dailyPromptResponder) {
	sort.Slice(responders, func(i, j int) bool {
		return responders[i].AnsweredAt > responders[j].AnsweredAt
	})
}
