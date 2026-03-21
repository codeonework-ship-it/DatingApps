package mobile

import (
	"context"
	"errors"
	"net/url"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/verified-dating/backend/internal/platform/config"
	"github.com/verified-dating/backend/internal/platform/supabase"
)

type verificationRepository struct {
	cfg config.Config
	db  *supabase.Client
}

func newVerificationRepository(cfg config.Config) *verificationRepository {
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
	return &verificationRepository{cfg: cfg, db: client}
}

func isVerificationRepoPersistenceUnavailable(err error) bool {
	if err == nil {
		return false
	}
	msg := strings.ToLower(err.Error())
	return strings.Contains(msg, "pgrst106") ||
		strings.Contains(msg, "pgrst205") ||
		strings.Contains(msg, "invalid schema") ||
		strings.Contains(msg, "could not find the table")
}

func (r *verificationRepository) getVerification(ctx context.Context, userID string) (verificationState, error) {
	trimmedUserID := strings.TrimSpace(userID)
	if trimmedUserID == "" {
		return verificationState{}, errors.New("user_id is required")
	}

	params := url.Values{}
	params.Set("user_id", "eq."+trimmedUserID)
	params.Set("limit", "1")
	params.Set("select", "user_id,status,rejection_reason,submitted_at,reviewed_at,reviewed_by")
	rows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, "verification_states", params)
	if err != nil {
		return verificationState{}, err
	}
	if len(rows) == 0 {
		return verificationState{UserID: trimmedUserID}, nil
	}
	return mapVerificationStateRow(rows[0]), nil
}

func (r *verificationRepository) submitVerification(ctx context.Context, userID string) (verificationState, error) {
	trimmedUserID := strings.TrimSpace(userID)
	if trimmedUserID == "" {
		return verificationState{}, errors.New("user_id is required")
	}
	nowISO := time.Now().UTC().Format(time.RFC3339)
	rows, err := r.db.Upsert(ctx, r.cfg.MatchingSchema, "verification_states", []map[string]any{{
		"user_id":          trimmedUserID,
		"status":           "pending",
		"submitted_at":     nowISO,
		"reviewed_at":      nil,
		"reviewed_by":      nil,
		"updated_at":       nowISO,
		"rejection_reason": nil,
	}}, "user_id")
	if err != nil {
		return verificationState{}, err
	}
	if len(rows) == 0 {
		return verificationState{UserID: trimmedUserID, Status: "pending", SubmittedAt: nowISO}, nil
	}
	return mapVerificationStateRow(rows[0]), nil
}

func (r *verificationRepository) reviewVerification(
	ctx context.Context,
	userID,
	status,
	rejectionReason,
	reviewedBy string,
) (verificationState, error) {
	trimmedUserID := strings.TrimSpace(userID)
	if trimmedUserID == "" {
		return verificationState{}, errors.New("user_id is required")
	}
	normalizedStatus := strings.ToLower(strings.TrimSpace(status))
	if normalizedStatus == "" {
		normalizedStatus = "pending"
	}

	existing, err := r.getVerification(ctx, trimmedUserID)
	if err != nil {
		return verificationState{}, err
	}
	if strings.TrimSpace(existing.UserID) == "" {
		return verificationState{}, errors.New("verification not found")
	}

	nowISO := time.Now().UTC().Format(time.RFC3339)
	filters := url.Values{}
	filters.Set("user_id", "eq."+trimmedUserID)
	rows, err := r.db.Update(ctx, r.cfg.MatchingSchema, "verification_states", map[string]any{
		"status":           normalizedStatus,
		"rejection_reason": strings.TrimSpace(rejectionReason),
		"reviewed_by":      nullableString(strings.TrimSpace(reviewedBy)),
		"reviewed_at":      nowISO,
		"updated_at":       nowISO,
	}, filters)
	if err != nil {
		return verificationState{}, err
	}
	if len(rows) == 0 {
		return verificationState{}, errors.New("verification not found")
	}
	return mapVerificationStateRow(rows[0]), nil
}

func (r *verificationRepository) listVerifications(ctx context.Context, status string, limit int) ([]verificationState, error) {
	if limit <= 0 || limit > 500 {
		limit = 100
	}
	normalizedStatus := strings.ToLower(strings.TrimSpace(status))

	params := url.Values{}
	if normalizedStatus != "" {
		params.Set("status", "eq."+normalizedStatus)
	}
	params.Set("limit", strconv.Itoa(limit))
	params.Set("order", "submitted_at.desc")
	params.Set("select", "user_id,status,rejection_reason,submitted_at,reviewed_at,reviewed_by")
	rows, err := r.db.SelectRead(ctx, r.cfg.MatchingSchema, "verification_states", params)
	if err != nil {
		return nil, err
	}
	out := make([]verificationState, 0, len(rows))
	for _, row := range rows {
		out = append(out, mapVerificationStateRow(row))
	}
	sort.Slice(out, func(i, j int) bool {
		return out[i].SubmittedAt > out[j].SubmittedAt
	})
	return out, nil
}

func mapVerificationStateRow(row map[string]any) verificationState {
	return verificationState{
		UserID:          strings.TrimSpace(toString(row["user_id"])),
		Status:          strings.TrimSpace(toString(row["status"])),
		RejectionReason: strings.TrimSpace(toString(row["rejection_reason"])),
		SubmittedAt:     normalizeTimestampString(row["submitted_at"]),
		ReviewedAt:      normalizeTimestampString(row["reviewed_at"]),
		ReviewedBy:      strings.TrimSpace(toString(row["reviewed_by"])),
	}
}

func nullableString(value string) any {
	if strings.TrimSpace(value) == "" {
		return nil
	}
	return strings.TrimSpace(value)
}
