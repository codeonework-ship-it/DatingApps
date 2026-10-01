package mobile

import (
	"strings"
	"time"

	"github.com/verified-dating/backend/internal/platform/config"
	"github.com/verified-dating/backend/internal/platform/dataaccess"
	"github.com/verified-dating/backend/internal/platform/postgresdata"
	"github.com/verified-dating/backend/internal/platform/supabase"
)

func postgresOptions(cfg config.Config, maxConns, minConns int32) postgresdata.Options {
	if cfg.PostgresPoolMaxConns > 0 && maxConns > int32(cfg.PostgresPoolMaxConns) {
		maxConns = int32(cfg.PostgresPoolMaxConns)
	}
	if minConns > maxConns {
		minConns = maxConns
	}
	return postgresdata.Options{
		StatementTimeout:       time.Duration(cfg.PostgresStatementTimeoutMS) * time.Millisecond,
		LockTimeout:            time.Duration(cfg.PostgresLockTimeoutMS) * time.Millisecond,
		IdleTransactionTimeout: time.Duration(cfg.PostgresIdleTransactionTimeoutMS) * time.Millisecond,
		MaxConns:               maxConns,
		MinConns:               minConns,
	}
}

type repositoryDB = dataaccess.Client

func clientFromStore(store *dataaccess.Store) repositoryDB {
	if store == nil {
		return nil
	}
	return store.Client
}

func repositoryDBFor(cfg config.Config, supplied []repositoryDB) repositoryDB {
	if len(supplied) > 0 && supplied[0] != nil {
		return supplied[0]
	}
	// Native local mode receives one process-wide pgx pool from Server.
	if cfg.UseLocalDB {
		return nil
	}
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
		cfg.SupabaseHTTPTimeout(),
	)
	client.SetReadBaseURL(cfg.SupabaseReadReplicaURL)
	return client
}
