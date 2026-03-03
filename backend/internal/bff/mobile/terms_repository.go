package mobile

import (
	"context"
	"errors"
	"net/url"
	"strings"
	"sync"
	"time"

	"github.com/verified-dating/backend/internal/platform/config"
	"github.com/verified-dating/backend/internal/platform/supabase"
)

type termsAgreementRecord struct {
	UserID          string `json:"user_id"`
	Accepted        bool   `json:"accepted"`
	AcceptedAt      string `json:"accepted_at,omitempty"`
	TermsVersion    string `json:"terms_version,omitempty"`
	UpdatedAt       string `json:"updated_at,omitempty"`
	PersistedInDB   bool   `json:"persisted_in_db"`
	PersistenceMode string `json:"persistence_mode"`
}

type termsAgreementRepository struct {
	cfg   config.Config
	db    *supabase.Client
	mu    sync.RWMutex
	local map[string]termsAgreementRecord
}

func newTermsAgreementRepository(cfg config.Config) *termsAgreementRepository {
	apiKey := strings.TrimSpace(cfg.SupabaseServiceRole)
	if apiKey == "" {
		apiKey = strings.TrimSpace(cfg.SupabaseAnonKey)
	}
	if strings.TrimSpace(cfg.SupabaseURL) == "" || apiKey == "" {
		return &termsAgreementRepository{
			cfg:   cfg,
			local: map[string]termsAgreementRecord{},
		}
	}

	client := supabase.NewClient(
		cfg.SupabaseURL,
		cfg.SupabaseAnonKey,
		cfg.SupabaseServiceRole,
		cfg.SupabaseHTTPTimeout(),
	)
	client.SetReadBaseURL(cfg.SupabaseReadReplicaURL)
	return &termsAgreementRepository{
		cfg:   cfg,
		db:    client,
		local: map[string]termsAgreementRecord{},
	}
}

func (r *termsAgreementRepository) getAgreement(
	ctx context.Context,
	userID string,
) (termsAgreementRecord, error) {
	trimmedUserID := strings.TrimSpace(userID)
	if trimmedUserID == "" {
		return termsAgreementRecord{}, errors.New("user id is required")
	}
	if r.db == nil {
		r.mu.RLock()
		record, ok := r.local[trimmedUserID]
		r.mu.RUnlock()
		if ok {
			return record, nil
		}
		return termsAgreementRecord{
			UserID:          trimmedUserID,
			Accepted:        false,
			PersistedInDB:   false,
			PersistenceMode: "memory",
		}, nil
	}

	params := url.Values{}
	params.Set("select", "id,terms_accepted,terms_accepted_at,terms_version")
	params.Set("id", "eq."+trimmedUserID)
	params.Set("limit", "1")

	rows, err := r.db.SelectRead(ctx, r.cfg.UserSchema, r.cfg.UsersTable, params)
	if err != nil {
		return termsAgreementRecord{}, err
	}
	if len(rows) == 0 {
		r.mu.RLock()
		record, ok := r.local[trimmedUserID]
		r.mu.RUnlock()
		if ok {
			return record, nil
		}
		return termsAgreementRecord{
			UserID:          trimmedUserID,
			Accepted:        false,
			PersistedInDB:   true,
			PersistenceMode: "database",
		}, nil
	}

	row := rows[0]
	accepted, _ := row["terms_accepted"].(bool)
	acceptedAt := strings.TrimSpace(toString(row["terms_accepted_at"]))
	termsVersion := strings.TrimSpace(toString(row["terms_version"]))

	return termsAgreementRecord{
		UserID:          trimmedUserID,
		Accepted:        accepted,
		AcceptedAt:      acceptedAt,
		TermsVersion:    termsVersion,
		UpdatedAt:       "",
		PersistedInDB:   true,
		PersistenceMode: "database",
	}, nil
}

func (r *termsAgreementRepository) updateAgreement(
	ctx context.Context,
	userID string,
	accepted bool,
	termsVersion string,
) (termsAgreementRecord, error) {
	trimmedUserID := strings.TrimSpace(userID)
	if trimmedUserID == "" {
		return termsAgreementRecord{}, errors.New("user id is required")
	}

	now := time.Now().UTC().Format(time.RFC3339)
	cleanVersion := strings.TrimSpace(termsVersion)
	if cleanVersion == "" {
		cleanVersion = "v1"
	}

	if r.db == nil {
		acceptedAt := ""
		if accepted {
			acceptedAt = now
		}
		record := termsAgreementRecord{
			UserID:          trimmedUserID,
			Accepted:        accepted,
			AcceptedAt:      acceptedAt,
			TermsVersion:    cleanVersion,
			UpdatedAt:       now,
			PersistedInDB:   false,
			PersistenceMode: "memory",
		}
		r.mu.Lock()
		r.local[trimmedUserID] = record
		r.mu.Unlock()
		return record, nil
	}

	payload := map[string]any{
		"terms_accepted":    accepted,
		"terms_version":     cleanVersion,
		"terms_accepted_at": nil,
	}
	if accepted {
		payload["terms_accepted_at"] = now
	}

	filters := url.Values{}
	filters.Set("id", "eq."+trimmedUserID)
	rows, err := r.db.Update(ctx, r.cfg.UserSchema, r.cfg.UsersTable, payload, filters)
	if err != nil {
		return termsAgreementRecord{}, err
	}
	if len(rows) == 0 {
		acceptedAt := ""
		if accepted {
			acceptedAt = now
		}
		record := termsAgreementRecord{
			UserID:          trimmedUserID,
			Accepted:        accepted,
			AcceptedAt:      acceptedAt,
			TermsVersion:    cleanVersion,
			UpdatedAt:       now,
			PersistedInDB:   false,
			PersistenceMode: "memory",
		}
		r.mu.Lock()
		r.local[trimmedUserID] = record
		r.mu.Unlock()
		return record, nil
	}

	row := rows[0]
	acceptedAt := strings.TrimSpace(toString(row["terms_accepted_at"]))
	storedVersion := strings.TrimSpace(toString(row["terms_version"]))
	if storedVersion == "" {
		storedVersion = cleanVersion
	}

	return termsAgreementRecord{
		UserID:          trimmedUserID,
		Accepted:        accepted,
		AcceptedAt:      acceptedAt,
		TermsVersion:    storedVersion,
		UpdatedAt:       now,
		PersistedInDB:   true,
		PersistenceMode: "database",
	}, nil
}
