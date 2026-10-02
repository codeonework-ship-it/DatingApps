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

// primaryPoolMaxConns sizes the profile repository's pool, which carries
// almost every request's SQL (sessions, roles, idempotency, realtime, social,
// notifications). It used to be hard-capped at 16, so raising
// POSTGRES_POOL_MAX_CONNS (as the runbooks advise) could only lower it; under
// load requests queued on that pool (verified_dating_db_pool_wait_seconds_total).
// It now follows POSTGRES_POOL_MAX_CONNS, never below the old 16.
func primaryPoolMaxConns(cfg config.Config) int32 {
	if cfg.PostgresPoolMaxConns > 16 {
		return int32(cfg.PostgresPoolMaxConns)
	}
	return 16
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
