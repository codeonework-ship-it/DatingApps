package dataaccess

import (
	"context"
	"errors"
	"net/url"
	"strings"
	"time"

	"github.com/verified-dating/backend/internal/platform/config"
	"github.com/verified-dating/backend/internal/platform/postgresdata"
	"github.com/verified-dating/backend/internal/platform/supabase"
)

// Client is the storage transport consumed by runtime repositories. Local mode
// uses the pgx-backed implementation; hosted mode retains the HTTP client until
// its separate deployment migration is scheduled.
type Client interface {
	Select(context.Context, string, string, url.Values) ([]map[string]any, error)
	SelectRead(context.Context, string, string, url.Values) ([]map[string]any, error)
	Insert(context.Context, string, string, any) ([]map[string]any, error)
	Upsert(context.Context, string, string, any, string) ([]map[string]any, error)
	Update(context.Context, string, string, any, url.Values) ([]map[string]any, error)
	Delete(context.Context, string, string, url.Values) ([]map[string]any, error)
}

type Store struct {
	Client
	postgres *postgresdata.Client
	mode     string
}

func Open(ctx context.Context, cfg config.Config) (*Store, error) {
	if cfg.UseLocalDB {
		client, err := postgresdata.Open(ctx, cfg.DatabaseURL, postgresdata.Options{
			StatementTimeout:       time.Duration(cfg.PostgresStatementTimeoutMS) * time.Millisecond,
			LockTimeout:            time.Duration(cfg.PostgresLockTimeoutMS) * time.Millisecond,
			IdleTransactionTimeout: time.Duration(cfg.PostgresIdleTransactionTimeoutMS) * time.Millisecond,
			MaxConns:               int32(cfg.PostgresPoolMaxConns),
			MinConns:               int32(cfg.PostgresPoolMinConns),
			PoolName:               "dataaccess/runtime_store",
		})
		if err != nil {
			return nil, err
		}
		return &Store{Client: client, postgres: client, mode: "postgres"}, nil
	}

	apiKey := strings.TrimSpace(cfg.SupabaseServiceRole)
	if apiKey == "" {
		apiKey = strings.TrimSpace(cfg.SupabaseAnonKey)
	}
	if strings.TrimSpace(cfg.SupabaseURL) == "" || apiKey == "" {
		return nil, errors.New("remote data access is not configured")
	}
	client := supabase.NewClient(
		cfg.SupabaseURL,
		cfg.SupabaseAnonKey,
		cfg.SupabaseServiceRole,
		cfg.SupabaseHTTPTimeout(),
	)
	client.SetReadBaseURL(cfg.SupabaseReadReplicaURL)
	return &Store{Client: client, mode: "postgrest"}, nil
}

func (s *Store) Mode() string {
	if s == nil {
		return "unconfigured"
	}
	return s.mode
}

func (s *Store) Ping(ctx context.Context) error {
	if s == nil || s.Client == nil {
		return errors.New("data access is not configured")
	}
	if s.postgres != nil {
		return s.postgres.Ping(ctx)
	}
	return nil
}

func (s *Store) Close() {
	if s != nil && s.postgres != nil {
		s.postgres.Close()
	}
}
