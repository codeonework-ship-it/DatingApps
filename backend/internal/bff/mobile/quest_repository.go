package mobile

import (
	"context"
	"errors"
	"fmt"
	"net/url"
	"strings"
	"time"

	matchingdomain "github.com/verified-dating/backend/internal/modules/matching/domain"
	"github.com/verified-dating/backend/internal/platform/config"
	"github.com/verified-dating/backend/internal/platform/supabase"
)

var errUnauthorizedQuestAction = errors.New("unauthorized quest action")

type questRepository struct {
	cfg config.Config
	db  *supabase.Client
}

func newQuestRepository(cfg config.Config) *questRepository {
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
	return &questRepository{cfg: cfg, db: client}
}

func (r *questRepository) getQuestTemplate(ctx context.Context, matchID string) (questTemplateRequirement, bool, error) {
	params := url.Values{}
	params.Set("match_id", "eq."+strings.TrimSpace(matchID))
	params.Set("limit", "1")
	rows, err := r.db.SelectRead(ctx, r.cfg.EngagementSchema, r.cfg.QuestTemplatesTable, params)
	if err != nil {
		return questTemplateRequirement{}, false, err
	}
	if len(rows) == 0 {
		return questTemplateRequirement{}, false, nil
	}
	item := mapQuestTemplateRow(rows[0])
	if item.MatchID == "" {
		return questTemplateRequirement{}, false, nil
	}
	return item, true, nil
}

func (r *questRepository) upsertQuestTemplate(
	ctx context.Context,
	matchID,
	creatorUserID,
	prompt string,
	minChars,
	maxChars int,
) (questTemplateRequirement, error) {
	now := time.Now().UTC()
	trimmedMatchID := strings.TrimSpace(matchID)
	trimmedCreator := strings.TrimSpace(creatorUserID)

	if err := r.validateMatchParticipant(ctx, trimmedMatchID, trimmedCreator); err != nil {
		return questTemplateRequirement{}, err
	}

	existing, found, err := r.getQuestTemplate(ctx, trimmedMatchID)
	if err != nil {
		return questTemplateRequirement{}, err
	}
	if found && existing.CreatorUserID != "" && existing.CreatorUserID != trimmedCreator {
		return questTemplateRequirement{}, errUnauthorizedQuestAction
	}

	templateID := "quest-template-" + trimmedMatchID
	if found && existing.TemplateID != "" {
		templateID = existing.TemplateID
	}
	template, err := matchingdomain.NewQuestTemplate(templateID, trimmedCreator, prompt, minChars, maxChars, now)
	if err != nil {
		return questTemplateRequirement{}, err
	}

	payload := []map[string]any{{
		"match_id":        trimmedMatchID,
		"template_id":     template.ID,
		"creator_user_id": template.CreatorID,
		"prompt_template": template.Prompt,
		"min_chars":       template.MinChars,
		"max_chars":       template.MaxChars,
		"updated_at":      now.Format(time.RFC3339),
	}}
	rows, err := r.db.Upsert(ctx, r.cfg.EngagementSchema, r.cfg.QuestTemplatesTable, payload, "match_id")
	if err != nil {
		return questTemplateRequirement{}, err
	}
	if len(rows) == 0 {
		return questTemplateRequirement{}, errors.New("quest template persistence returned empty result")
	}

	unlockState, _, err := r.getUnlockState(ctx, trimmedMatchID)
	if err != nil {
		return questTemplateRequirement{}, err
	}
	nextState := transitionUnlockState(unlockState, matchingdomain.ActionAssignQuest)
	if _, err := r.upsertUnlockState(ctx, trimmedMatchID, nextState); err != nil {
		return questTemplateRequirement{}, err
	}

	workflow, foundWorkflow, err := r.getQuestWorkflow(ctx, trimmedMatchID)
	if err != nil {
		return questTemplateRequirement{}, err
	}
	if !foundWorkflow {
		workflow = questSubmissionWorkflow{MatchID: trimmedMatchID}
	}
	workflow.TemplateID = template.ID
	workflow.UnlockState = nextState
	if workflow.Status == "" {
		workflow.Status = questWorkflowStatusPending
	}
	if _, err := r.upsertQuestWorkflow(ctx, workflow); err != nil {
		return questTemplateRequirement{}, err
	}

	return mapQuestTemplateRow(rows[0]), nil
}

func (r *questRepository) listQuestTemplatesByMatchIDs(
	ctx context.Context,
	matchIDs []string,
) (map[string]questTemplateRequirement, error) {
	uniq := uniqueStrings(matchIDs)
	if len(uniq) == 0 {
		return map[string]questTemplateRequirement{}, nil
	}
	params := url.Values{}
	params.Set("match_id", "in."+buildInList(uniq))
	params.Set("select", "*")
	rows, err := r.db.SelectRead(ctx, r.cfg.EngagementSchema, r.cfg.QuestTemplatesTable, params)
	if err != nil {
		return nil, err
	}
	out := make(map[string]questTemplateRequirement, len(rows))
	for _, row := range rows {
		item := mapQuestTemplateRow(row)
		if item.MatchID != "" {
			out[item.MatchID] = item
		}
	}
	return out, nil
}

func (r *questRepository) getQuestWorkflow(ctx context.Context, matchID string) (questSubmissionWorkflow, bool, error) {
	params := url.Values{}
	params.Set("match_id", "eq."+strings.TrimSpace(matchID))
	params.Set("limit", "1")
	rows, err := r.db.SelectRead(ctx, r.cfg.EngagementSchema, r.cfg.QuestWorkflowsTable, params)
	if err != nil {
		return questSubmissionWorkflow{}, false, err
	}
	if len(rows) == 0 {
		return questSubmissionWorkflow{}, false, nil
	}
	workflow := mapQuestWorkflowRow(rows[0])
	if workflow.MatchID == "" {
		return questSubmissionWorkflow{}, false, nil
	}
	return normalizeQuestWorkflow(workflow), true, nil
}

func (r *questRepository) submitQuestResponse(
	ctx context.Context,
	matchID,
	submitterUserID,
	responseText string,
) (questSubmissionWorkflow, error) {
	now := time.Now().UTC()
	trimmedMatchID := strings.TrimSpace(matchID)
	trimmedSubmitter := strings.TrimSpace(submitterUserID)
	trimmedResponse := strings.TrimSpace(responseText)

	if err := r.validateMatchParticipant(ctx, trimmedMatchID, trimmedSubmitter); err != nil {
		return questSubmissionWorkflow{}, err
	}

	template, ok, err := r.getQuestTemplate(ctx, trimmedMatchID)
	if err != nil {
		return questSubmissionWorkflow{}, err
	}
	if !ok {
		return questSubmissionWorkflow{}, errors.New("quest template not found for match")
	}
	if len(trimmedResponse) < template.MinChars || len(trimmedResponse) > template.MaxChars {
		return questSubmissionWorkflow{}, fmt.Errorf(
			"response text must be between %d and %d characters",
			template.MinChars,
			template.MaxChars,
		)
	}

	workflow, found, err := r.getQuestWorkflow(ctx, trimmedMatchID)
	if err != nil {
		return questSubmissionWorkflow{}, err
	}
	if !found {
		workflow = questSubmissionWorkflow{MatchID: trimmedMatchID}
	}
	workflow.TemplateID = template.TemplateID

	if isCooldownActive(workflow, now) {
		workflow.Status = questWorkflowStatusCooldown
		if _, err := r.upsertQuestWorkflow(ctx, workflow); err != nil {
			return questSubmissionWorkflow{}, err
		}
		return questSubmissionWorkflow{}, errors.New("quest submission is in cooldown period")
	}

	windowStart := parseRFC3339OrZero(workflow.WindowStartedAt)
	if windowStart.IsZero() || now.Sub(windowStart) > questSubmissionWindow {
		workflow.AttemptCount = 0
		workflow.WindowStartedAt = now.Format(time.RFC3339)
	}
	if workflow.AttemptCount >= questMaxAttemptsPerWindow {
		workflow.Status = questWorkflowStatusCooldown
		workflow.CooldownUntil = now.Add(questRateLimitCooldown).Format(time.RFC3339)
		if _, err := r.upsertQuestWorkflow(ctx, workflow); err != nil {
			return questSubmissionWorkflow{}, err
		}
		return questSubmissionWorkflow{}, errors.New("quest submission rate limit exceeded")
	}

	unlockState, _, err := r.getUnlockState(ctx, trimmedMatchID)
	if err != nil {
		return questSubmissionWorkflow{}, err
	}
	nextState := transitionUnlockState(unlockState, matchingdomain.ActionSubmitQuest)
	if _, err := r.upsertUnlockState(ctx, trimmedMatchID, nextState); err != nil {
		return questSubmissionWorkflow{}, err
	}

	workflow.UnlockState = nextState
	workflow.Status = questWorkflowStatusPending
	workflow.SubmitterUserID = trimmedSubmitter
	workflow.ResponseText = trimmedResponse
	workflow.SubmittedAt = now.Format(time.RFC3339)
	workflow.ReviewerUserID = ""
	workflow.ReviewedAt = ""
	workflow.ReviewReason = ""
	workflow.CooldownUntil = ""
	workflow.AttemptCount++

	stored, err := r.upsertQuestWorkflow(ctx, workflow)
	if err != nil {
		return questSubmissionWorkflow{}, err
	}
	return normalizeQuestWorkflow(stored), nil
}

func (r *questRepository) reviewQuestResponse(
	ctx context.Context,
	matchID,
	reviewerUserID,
	decisionStatus,
	reviewReason string,
) (questSubmissionWorkflow, error) {
	now := time.Now().UTC()
	trimmedMatchID := strings.TrimSpace(matchID)
	trimmedReviewer := strings.TrimSpace(reviewerUserID)
	trimmedDecision := strings.ToLower(strings.TrimSpace(decisionStatus))
	trimmedReason := strings.TrimSpace(reviewReason)

	if err := r.validateMatchParticipant(ctx, trimmedMatchID, trimmedReviewer); err != nil {
		return questSubmissionWorkflow{}, err
	}

	workflow, found, err := r.getQuestWorkflow(ctx, trimmedMatchID)
	if err != nil {
		return questSubmissionWorkflow{}, err
	}
	if !found || workflow.MatchID == "" {
		return questSubmissionWorkflow{}, errors.New("quest submission not found for match")
	}
	if workflow.Status != questWorkflowStatusPending {
		return questSubmissionWorkflow{}, errors.New("quest submission is not pending review")
	}
	if workflow.SubmitterUserID != "" && workflow.SubmitterUserID == trimmedReviewer {
		return questSubmissionWorkflow{}, errUnauthorizedQuestAction
	}

	workflow.ReviewerUserID = trimmedReviewer
	workflow.ReviewedAt = now.Format(time.RFC3339)

	action := matchingdomain.ActionRejectQuest
	switch trimmedDecision {
	case questWorkflowStatusApproved:
		workflow.Status = questWorkflowStatusApproved
		workflow.ReviewReason = trimmedReason
		workflow.CooldownUntil = ""
		action = matchingdomain.ActionApproveQuest
	case questWorkflowStatusRejected:
		workflow.Status = questWorkflowStatusRejected
		workflow.ReviewReason = trimmedReason
		workflow.CooldownUntil = now.Add(questCooldownDuration).Format(time.RFC3339)
		action = matchingdomain.ActionRejectQuest
	default:
		return questSubmissionWorkflow{}, errors.New("invalid decision status")
	}

	unlockState, _, err := r.getUnlockState(ctx, trimmedMatchID)
	if err != nil {
		return questSubmissionWorkflow{}, err
	}
	nextState := transitionUnlockState(unlockState, action)
	if _, err := r.upsertUnlockState(ctx, trimmedMatchID, nextState); err != nil {
		return questSubmissionWorkflow{}, err
	}
	workflow.UnlockState = nextState

	stored, err := r.upsertQuestWorkflow(ctx, workflow)
	if err != nil {
		return questSubmissionWorkflow{}, err
	}
	return normalizeQuestWorkflow(stored), nil
}

func (r *questRepository) listMatchGestures(ctx context.Context, matchID string) ([]matchGesture, error) {
	params := url.Values{}
	params.Set("match_id", "eq."+strings.TrimSpace(matchID))
	params.Set("order", "created_at.desc")
	rows, err := r.db.SelectRead(ctx, r.cfg.EngagementSchema, r.cfg.GesturesTable, params)
	if err != nil {
		return nil, err
	}
	out := make([]matchGesture, 0, len(rows))
	for _, row := range rows {
		item := mapGestureRow(row)
		if item.ID == "" {
			continue
		}
		out = append(out, item)
	}
	return out, nil
}

func (r *questRepository) createMatchGesture(ctx context.Context, gesture matchGesture) (matchGesture, error) {
	if err := r.validateMatchParticipant(ctx, gesture.MatchID, gesture.SenderUserID); err != nil {
		return matchGesture{}, err
	}
	if err := r.validateMatchParticipant(ctx, gesture.MatchID, gesture.ReceiverUserID); err != nil {
		return matchGesture{}, err
	}
	if gesture.SenderUserID == gesture.ReceiverUserID {
		return matchGesture{}, errors.New("sender and receiver must be different users")
	}

	payload := []map[string]any{{
		"id":                   strings.TrimSpace(gesture.ID),
		"match_id":             strings.TrimSpace(gesture.MatchID),
		"sender_user_id":       strings.TrimSpace(gesture.SenderUserID),
		"receiver_user_id":     strings.TrimSpace(gesture.ReceiverUserID),
		"gesture_type":         strings.TrimSpace(gesture.GestureType),
		"content_text":         strings.TrimSpace(gesture.ContentText),
		"tone":                 strings.TrimSpace(gesture.Tone),
		"status":               strings.TrimSpace(gesture.Status),
		"effort_score":         gesture.EffortScore,
		"minimum_quality_pass": gesture.MinimumQualityPass,
		"originality_pass":     gesture.OriginalityPass,
		"profanity_flagged":    gesture.ProfanityFlagged,
		"safety_flagged":       gesture.SafetyFlagged,
		"created_at":           nullableTimestamp(gesture.CreatedAt),
		"updated_at":           nullableTimestamp(gesture.UpdatedAt),
	}}

	rows, err := r.db.Insert(ctx, r.cfg.EngagementSchema, r.cfg.GesturesTable, payload)
	if err != nil {
		return matchGesture{}, err
	}
	if len(rows) == 0 {
		return matchGesture{}, errors.New("gesture persistence returned empty result")
	}
	return mapGestureRow(rows[0]), nil
}

func (r *questRepository) decideMatchGesture(
	ctx context.Context,
	matchID,
	gestureID,
	reviewerUserID,
	decision,
	reason string,
) (matchGesture, error) {
	item, err := r.getMatchGesture(ctx, matchID, gestureID)
	if err != nil {
		return matchGesture{}, err
	}
	if err := r.validateMatchParticipant(ctx, matchID, reviewerUserID); err != nil {
		return matchGesture{}, err
	}
	if item.ReceiverUserID != strings.TrimSpace(reviewerUserID) {
		return matchGesture{}, errUnauthorizedQuestAction
	}

	now := time.Now().UTC().Format(time.RFC3339)
	update := map[string]any{
		"status":              decisionToStatus(strings.ToLower(strings.TrimSpace(decision))),
		"decision_by_user_id": strings.TrimSpace(reviewerUserID),
		"decision_reason":     strings.TrimSpace(reason),
		"decision_at":         now,
		"updated_at":          now,
	}
	filters := url.Values{}
	filters.Set("id", "eq."+strings.TrimSpace(gestureID))
	filters.Set("match_id", "eq."+strings.TrimSpace(matchID))

	rows, err := r.db.Update(ctx, r.cfg.EngagementSchema, r.cfg.GesturesTable, update, filters)
	if err != nil {
		return matchGesture{}, err
	}
	if len(rows) == 0 {
		return matchGesture{}, errors.New("gesture decision update returned empty result")
	}
	return mapGestureRow(rows[0]), nil
}

func (r *questRepository) getMatchGesture(ctx context.Context, matchID, gestureID string) (matchGesture, error) {
	params := url.Values{}
	params.Set("id", "eq."+strings.TrimSpace(gestureID))
	params.Set("match_id", "eq."+strings.TrimSpace(matchID))
	params.Set("limit", "1")
	rows, err := r.db.SelectRead(ctx, r.cfg.EngagementSchema, r.cfg.GesturesTable, params)
	if err != nil {
		return matchGesture{}, err
	}
	if len(rows) == 0 {
		return matchGesture{}, errors.New("gesture not found")
	}
	return mapGestureRow(rows[0]), nil
}

func (r *questRepository) listQuestWorkflowsByMatchIDs(
	ctx context.Context,
	matchIDs []string,
) (map[string]questSubmissionWorkflow, error) {
	uniq := uniqueStrings(matchIDs)
	if len(uniq) == 0 {
		return map[string]questSubmissionWorkflow{}, nil
	}
	params := url.Values{}
	params.Set("match_id", "in."+buildInList(uniq))
	params.Set("select", "*")
	rows, err := r.db.SelectRead(ctx, r.cfg.EngagementSchema, r.cfg.QuestWorkflowsTable, params)
	if err != nil {
		return nil, err
	}
	out := make(map[string]questSubmissionWorkflow, len(rows))
	for _, row := range rows {
		workflow := normalizeQuestWorkflow(mapQuestWorkflowRow(row))
		if workflow.MatchID != "" {
			out[workflow.MatchID] = workflow
		}
	}
	return out, nil
}

func (r *questRepository) getUnlockState(ctx context.Context, matchID string) (string, bool, error) {
	params := url.Values{}
	params.Set("match_id", "eq."+strings.TrimSpace(matchID))
	params.Set("limit", "1")
	rows, err := r.db.SelectRead(ctx, r.cfg.EngagementSchema, r.cfg.UnlockStatesTable, params)
	if err != nil {
		return "", false, err
	}
	if len(rows) == 0 {
		return string(matchingdomain.UnlockStateMatched), false, nil
	}
	state := asString(rows[0], "unlock_state")
	if state == "" {
		state = string(matchingdomain.UnlockStateMatched)
	}
	return state, true, nil
}

func (r *questRepository) listUnlockStatesByMatchIDs(
	ctx context.Context,
	matchIDs []string,
) (map[string]string, error) {
	uniq := uniqueStrings(matchIDs)
	if len(uniq) == 0 {
		return map[string]string{}, nil
	}
	params := url.Values{}
	params.Set("match_id", "in."+buildInList(uniq))
	params.Set("select", "match_id,unlock_state")
	rows, err := r.db.SelectRead(ctx, r.cfg.EngagementSchema, r.cfg.UnlockStatesTable, params)
	if err != nil {
		return nil, err
	}
	out := make(map[string]string, len(rows))
	for _, row := range rows {
		matchID := asString(row, "match_id")
		state := asString(row, "unlock_state")
		if matchID != "" {
			if state == "" {
				state = string(matchingdomain.UnlockStateMatched)
			}
			out[matchID] = state
		}
	}
	return out, nil
}

func (r *questRepository) upsertUnlockState(ctx context.Context, matchID, unlockState string) (string, error) {
	payload := []map[string]any{{
		"match_id":     strings.TrimSpace(matchID),
		"unlock_state": strings.TrimSpace(unlockState),
		"updated_at":   time.Now().UTC().Format(time.RFC3339),
	}}
	rows, err := r.db.Upsert(ctx, r.cfg.EngagementSchema, r.cfg.UnlockStatesTable, payload, "match_id")
	if err != nil {
		return "", err
	}
	if len(rows) == 0 {
		return strings.TrimSpace(unlockState), nil
	}
	out := asString(rows[0], "unlock_state")
	if out == "" {
		out = strings.TrimSpace(unlockState)
	}
	return out, nil
}

func (r *questRepository) upsertQuestWorkflow(
	ctx context.Context,
	workflow questSubmissionWorkflow,
) (questSubmissionWorkflow, error) {
	payload := []map[string]any{{
		"match_id":          strings.TrimSpace(workflow.MatchID),
		"template_id":       strings.TrimSpace(workflow.TemplateID),
		"unlock_state":      strings.TrimSpace(workflow.UnlockState),
		"status":            strings.TrimSpace(workflow.Status),
		"submitter_user_id": nullableUUID(workflow.SubmitterUserID),
		"reviewer_user_id":  nullableUUID(workflow.ReviewerUserID),
		"response_text":     strings.TrimSpace(workflow.ResponseText),
		"review_reason":     strings.TrimSpace(workflow.ReviewReason),
		"submitted_at":      nullableTimestamp(workflow.SubmittedAt),
		"reviewed_at":       nullableTimestamp(workflow.ReviewedAt),
		"cooldown_until":    nullableTimestamp(workflow.CooldownUntil),
		"attempt_count":     workflow.AttemptCount,
		"window_started_at": nullableTimestamp(workflow.WindowStartedAt),
		"updated_at":        time.Now().UTC().Format(time.RFC3339),
	}}
	rows, err := r.db.Upsert(ctx, r.cfg.EngagementSchema, r.cfg.QuestWorkflowsTable, payload, "match_id")
	if err != nil {
		return questSubmissionWorkflow{}, err
	}
	if len(rows) == 0 {
		return normalizeQuestWorkflow(workflow), nil
	}
	return normalizeQuestWorkflow(mapQuestWorkflowRow(rows[0])), nil
}

func (r *questRepository) validateMatchParticipant(ctx context.Context, matchID, userID string) error {
	if strings.TrimSpace(matchID) == "" || strings.TrimSpace(userID) == "" {
		return errUnauthorizedQuestAction
	}
	params := url.Values{}
	params.Set("id", "eq."+strings.TrimSpace(matchID))
	params.Set("select", "userId1,userId2")
	params.Set("limit", "1")
	rows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, r.cfg.MatchesTable, params)
	if err != nil {
		return err
	}
	if len(rows) == 0 {
		return errUnauthorizedQuestAction
	}
	userID1 := asString(rows[0], "userId1", "userid1")
	userID2 := asString(rows[0], "userId2", "userid2")
	if userID != userID1 && userID != userID2 {
		return errUnauthorizedQuestAction
	}
	return nil
}

func mapQuestTemplateRow(row map[string]any) questTemplateRequirement {
	return questTemplateRequirement{
		MatchID:       asString(row, "match_id", "matchId"),
		TemplateID:    asString(row, "template_id", "templateId"),
		CreatorUserID: asString(row, "creator_user_id", "creatorUserId"),
		Prompt:        asString(row, "prompt_template", "promptTemplate"),
		MinChars:      asInt(row, "min_chars", "minChars"),
		MaxChars:      asInt(row, "max_chars", "maxChars"),
		UpdatedAt:     asString(row, "updated_at", "updatedAt"),
	}
}

func mapQuestWorkflowRow(row map[string]any) questSubmissionWorkflow {
	return questSubmissionWorkflow{
		MatchID:         asString(row, "match_id", "matchId"),
		TemplateID:      asString(row, "template_id", "templateId"),
		UnlockState:     asString(row, "unlock_state", "unlockState"),
		Status:          asString(row, "status"),
		SubmitterUserID: asString(row, "submitter_user_id", "submitterUserId"),
		ReviewerUserID:  asString(row, "reviewer_user_id", "reviewerUserId"),
		ResponseText:    asString(row, "response_text", "responseText"),
		ReviewReason:    asString(row, "review_reason", "reviewReason"),
		SubmittedAt:     asString(row, "submitted_at", "submittedAt"),
		ReviewedAt:      asString(row, "reviewed_at", "reviewedAt"),
		CooldownUntil:   asString(row, "cooldown_until", "cooldownUntil"),
		AttemptCount:    asInt(row, "attempt_count", "attemptCount"),
		WindowStartedAt: asString(row, "window_started_at", "windowStartedAt"),
	}
}

func mapGestureRow(row map[string]any) matchGesture {
	return matchGesture{
		ID:                 asString(row, "id"),
		MatchID:            asString(row, "match_id", "matchId"),
		SenderUserID:       asString(row, "sender_user_id", "senderUserId"),
		ReceiverUserID:     asString(row, "receiver_user_id", "receiverUserId"),
		GestureType:        asString(row, "gesture_type", "gestureType"),
		ContentText:        asString(row, "content_text", "contentText"),
		Tone:               asString(row, "tone"),
		Status:             asString(row, "status"),
		EffortScore:        asInt(row, "effort_score", "effortScore"),
		MinimumQualityPass: asBool(row, "minimum_quality_pass", "minimumQualityPass"),
		OriginalityPass:    asBool(row, "originality_pass", "originalityPass"),
		ProfanityFlagged:   asBool(row, "profanity_flagged", "profanityFlagged"),
		SafetyFlagged:      asBool(row, "safety_flagged", "safetyFlagged"),
		DecisionByUserID:   asString(row, "decision_by_user_id", "decisionByUserId"),
		DecisionReason:     asString(row, "decision_reason", "decisionReason"),
		DecisionAt:         asString(row, "decision_at", "decisionAt"),
		CreatedAt:          asString(row, "created_at", "createdAt"),
		UpdatedAt:          asString(row, "updated_at", "updatedAt"),
	}
}

func asString(row map[string]any, keys ...string) string {
	for _, key := range keys {
		if value, ok := row[key]; ok {
			s, ok := value.(string)
			if ok {
				return strings.TrimSpace(s)
			}
		}
	}
	return ""
}

func asInt(row map[string]any, keys ...string) int {
	for _, key := range keys {
		value, ok := row[key]
		if !ok {
			continue
		}
		switch typed := value.(type) {
		case float64:
			return int(typed)
		case int:
			return typed
		case int64:
			return int(typed)
		}
	}
	return 0
}

func asBool(row map[string]any, keys ...string) bool {
	for _, key := range keys {
		value, ok := row[key]
		if !ok {
			continue
		}
		switch typed := value.(type) {
		case bool:
			return typed
		}
	}
	return false
}

func uniqueStrings(values []string) []string {
	if len(values) == 0 {
		return []string{}
	}
	seen := map[string]struct{}{}
	out := make([]string, 0, len(values))
	for _, raw := range values {
		trimmed := strings.TrimSpace(raw)
		if trimmed == "" {
			continue
		}
		if _, ok := seen[trimmed]; ok {
			continue
		}
		seen[trimmed] = struct{}{}
		out = append(out, trimmed)
	}
	return out
}

func buildInList(values []string) string {
	if len(values) == 0 {
		return "()"
	}
	return "(" + strings.Join(values, ",") + ")"
}

func nullableTimestamp(value string) any {
	trimmed := strings.TrimSpace(value)
	if trimmed == "" {
		return nil
	}
	return trimmed
}

func nullableUUID(value string) any {
	trimmed := strings.TrimSpace(value)
	if trimmed == "" {
		return nil
	}
	return trimmed
}
